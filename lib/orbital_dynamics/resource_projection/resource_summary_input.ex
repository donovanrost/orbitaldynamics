defmodule OrbitalDynamics.ResourceProjection.ResourceSummaryInput do
  @moduledoc false

  @stable_id_pattern ~r/^[A-Za-z0-9][A-Za-z0-9._:@-]*$/
  @resource_availability_value_aliases %{
    "payload_available" => ["payload_available?"],
    "antenna_available" => ["antenna_available?"],
    "spacecraft_available" => ["spacecraft_available?", "spacecraft_availability"]
  }
  @resource_availability_status_aliases %{
    "payload_available" => ["payload_status"],
    "antenna_available" => ["antenna_status"],
    "spacecraft_available" => ["spacecraft_status"]
  }
  @resource_degraded_aliases ["degraded?"]
  @resource_margin_aliases %{
    "storage_margin" => ["storage_capacity_margin"],
    "downlink_margin" => ["downlink_capacity_margin"],
    "battery_state_of_charge" => ["battery_soc"]
  }
  @resource_source_quality_aliases [
    ["resource_source_quality"],
    ["provenance", "source_quality"],
    ["provenance", "resource_source_quality"],
    ["provenance", "quality"]
  ]
  @resource_trust_boundary_aliases [
    ["resource_trust_boundary"],
    ["provenance", "trust_boundary"],
    ["provenance", "resource_trust_boundary"]
  ]
  @resource_availability_true_tokens ~w(true yes y available nominal operational enabled 1)
  @resource_availability_false_tokens ~w(false no n unavailable offline down outage maintenance disabled 0)
  @station_calendar_direction_aliases %{
    "cmd" => "command",
    "commanding" => "command",
    "commands" => "command",
    "sband_command" => "command",
    "s_band_command" => "command",
    "uplink" => "command",
    "up" => "command",
    "up_link" => "command",
    "dl" => "downlink",
    "down" => "downlink",
    "downlinking" => "downlink",
    "down_link" => "downlink",
    "x_band_downlink" => "downlink",
    "track" => "tracking",
    "track_ing" => "tracking",
    "tracking_pass" => "tracking",
    "health" => "health_check",
    "healthcheck" => "health_check",
    "health_check_window" => "health_check"
  }
  @resource_activity_type_aliases Map.merge(@station_calendar_direction_aliases, %{
                                    "uplink_command" => "command"
                                  })

  def normalize(summaries) when is_list(summaries) do
    {invalid_summaries, summaries} =
      summaries
      |> Enum.with_index(1)
      |> Enum.map(&normalize_summary_input/1)
      |> Enum.split_with(&invalid_resource_summary_input?/1)

    {review_summaries, summaries} = split_review_gated_resource_summary_scopes(summaries)
    {invalid_summaries ++ review_summaries, summaries}
  end

  def projection_scope_ids(activity, summaries)
      when is_map(activity) and is_list(summaries) do
    activity = stringify_keys(activity)
    {_invalid_summaries, summaries} = normalize(summaries)
    summary_count = length(summaries)

    summaries
    |> Enum.filter(fn summary ->
      projection_activities(summary, [activity], summary_count) != []
    end)
    |> Enum.map(&projection_spacecraft_id(&1, summary_count))
    |> Enum.uniq()
    |> Enum.sort()
  end

  def projection_scope_ids(_activity, _summaries), do: []

  def projection_activities(%{} = summary, activities, 1) when is_list(activities) do
    if Map.get(summary, "spacecraft_id") in [nil, ""] do
      activities
    else
      projection_activities(summary, activities, :scoped)
    end
  end

  def projection_activities(%{} = summary, activities, _summary_count)
      when is_list(activities) do
    spacecraft_id = summary["spacecraft_id"]

    Enum.filter(activities, fn activity ->
      Map.get(activity, "spacecraft_id") == spacecraft_id or
        Map.get(activity, "scenario_id") == spacecraft_id
    end)
  end

  def projection_spacecraft_id(%{"spacecraft_id" => spacecraft_id}, _summary_count)
      when spacecraft_id not in [nil, ""],
      do: spacecraft_id

  def projection_spacecraft_id(_summary, 1), do: "all_spacecraft"
  def projection_spacecraft_id(_summary, _summary_count), do: "unscoped_resource_summary"

  defp normalize_summary_input({summary, index}) when is_map(summary) do
    summary =
      summary
      |> stringify_keys()
      |> normalize_resource_provenance_aliases()
      |> normalize_resource_availability_aliases()
      |> normalize_resource_margin_aliases()
      |> normalize_resource_activity_type_lists()
      |> normalize_resource_summary_numbers()
      |> put_spacecraft_alias()

    case resource_summary_input_issue(summary) do
      nil -> normalize_summary_battery_fields(summary)
      reason -> invalid_resource_summary_input(summary, index, reason)
    end
  end

  defp normalize_summary_input({summary, index}) do
    invalid_resource_summary_input(
      %{"raw_input" => inspect(summary)},
      index,
      "invalid_resource_summary_shape"
    )
  end

  defp resource_summary_input_issue(summary) do
    [
      resource_summary_spacecraft_id_issue(summary),
      resource_summary_non_negative_issue(summary),
      resource_summary_unit_interval_issue(summary),
      resource_summary_derived_margin_issue(summary)
    ]
    |> Enum.find(& &1)
  end

  defp normalize_resource_provenance_aliases(summary) do
    summary
    |> put_resource_provenance_alias("source_quality", @resource_source_quality_aliases)
    |> put_resource_provenance_alias("trust_boundary", @resource_trust_boundary_aliases)
  end

  defp put_resource_provenance_alias(summary, canonical_field, aliases) do
    cond do
      present_value?(Map.get(summary, canonical_field)) ->
        summary

      alias_value = Enum.find_value(aliases, &resource_provenance_alias_value(summary, &1)) ->
        Map.put(summary, canonical_field, alias_value)

      true ->
        summary
    end
  end

  defp resource_provenance_alias_value(summary, path) when is_list(path) do
    summary
    |> get_in(path)
    |> present_value_or_nil()
  end

  defp resource_provenance_alias_value(summary, field) do
    summary
    |> Map.get(field)
    |> present_value_or_nil()
  end

  defp present_value_or_nil(value), do: if(present_value?(value), do: value, else: nil)
  defp present_value?(value), do: value not in [nil, ""]

  defp resource_summary_spacecraft_id_issue(%{"spacecraft_id" => spacecraft_id})
       when spacecraft_id not in [nil, ""] do
    if stable_id?(spacecraft_id), do: nil, else: "invalid_spacecraft_id"
  end

  defp resource_summary_spacecraft_id_issue(_summary), do: nil

  defp put_spacecraft_alias(%{} = summary) do
    case Map.get(summary, "spacecraft_id") || Map.get(summary, "satellite_id") ||
           nested_spacecraft_id(summary) do
      value when value in [nil, ""] -> summary
      value -> Map.put_new(summary, "spacecraft_id", value)
    end
  end

  defp nested_spacecraft_id(summary) do
    Enum.find_value(["spacecraft", "satellite"], fn field ->
      spacecraft_identity_value(Map.get(summary, field))
    end)
  end

  defp spacecraft_identity_value(%{} = spacecraft) do
    Enum.find_value(["spacecraft_id", "satellite_id", "id"], fn field ->
      spacecraft_identity_value(Map.get(spacecraft, field))
    end)
  end

  defp spacecraft_identity_value(value), do: value

  defp resource_summary_non_negative_issue(summary) do
    Enum.find_value(
      ~w(battery_capacity_wh battery_energy_used_wh battery_energy_generated_wh storage_capacity_mb storage_used_mb downlink_capacity_mb),
      fn field ->
        case Map.get(summary, field) do
          value when is_number(value) and value < 0.0 -> "negative_#{field}"
          value when is_number(value) or is_nil(value) -> nil
          _value -> "invalid_#{field}"
        end
      end
    )
  end

  defp resource_summary_unit_interval_issue(summary) do
    Enum.find_value(
      ~w(fuel_margin power_margin battery_state_of_charge storage_margin downlink_margin),
      fn field ->
        case Map.get(summary, field) do
          value when is_number(value) and value >= 0.0 and value <= 1.0 -> nil
          value when is_number(value) -> "invalid_#{field}"
          nil -> nil
          _value -> "invalid_#{field}"
        end
      end
    )
  end

  defp resource_summary_derived_margin_issue(summary) do
    resource_summary_derived_margin_issue(
      summary,
      "battery_state_of_charge",
      "battery_capacity_wh",
      "battery_energy_used_wh"
    ) ||
      resource_summary_derived_margin_issue(
        summary,
        "storage_margin",
        "storage_capacity_mb",
        "storage_used_mb"
      )
  end

  defp resource_summary_derived_margin_issue(summary, margin_field, capacity_field, used_field) do
    margin = Map.get(summary, margin_field)
    capacity = Map.get(summary, capacity_field)
    used = Map.get(summary, used_field)

    if is_number(margin) and is_number(capacity) and capacity > 0 and is_number(used) do
      expected = max((capacity - used) / capacity, 0.0)

      if abs(margin - expected) <= 1.0e-9 do
        nil
      else
        "stale_#{margin_field}"
      end
    end
  end

  defp invalid_resource_summary_input(summary, index, reason) do
    resource_summary_id = invalid_resource_summary_id(summary, index)

    %{
      "id" => "resource_projection:invalid_resource_summary:#{resource_summary_id}",
      "resource_summary_id" => resource_summary_id,
      "spacecraft_id" => stable_id_or_nil(summary["spacecraft_id"]),
      "required_operator_action" => "review_invalid_resource_projection_summary",
      "approval_status" => "operator_review_required",
      "review_status" => "operator_review_required",
      "invalid_resource_summary_input" => true,
      "invalid_resource_summary_input_reason" => reason,
      "source_resource_summary" => summary
    }
    |> compact_map()
  end

  defp invalid_resource_summary_id(%{"spacecraft_id" => spacecraft_id}, index)
       when spacecraft_id not in [nil, ""] do
    stable_id_or_nil(spacecraft_id) || "resource_summary:#{index}"
  end

  defp invalid_resource_summary_id(_summary, index), do: "resource_summary:#{index}"

  defp invalid_resource_summary_input?(%{"invalid_resource_summary_input" => true}), do: true
  defp invalid_resource_summary_input?(_summary), do: false

  defp split_review_gated_resource_summary_scopes(summaries) do
    summary_counts = Enum.frequencies_by(summaries, &resource_summary_scope_key/1)
    summary_count = length(summaries)

    summaries
    |> Enum.reduce({[], [], %{}}, fn summary, {invalid, valid, duplicate_indexes} ->
      key = resource_summary_scope_key(summary)
      count = Map.fetch!(summary_counts, key)

      cond do
        count > 1 ->
          index = Map.get(duplicate_indexes, key, 0) + 1
          duplicate = duplicate_resource_summary_input(summary, key, index, count)

          {[duplicate | invalid], valid, Map.put(duplicate_indexes, key, index)}

        mixed_wildcard_resource_summary_scope?(key, summary_count) ->
          invalid_summary = mixed_wildcard_resource_summary_input(summary)

          {[invalid_summary | invalid], valid, duplicate_indexes}

        true ->
          {invalid, [summary | valid], duplicate_indexes}
      end
    end)
    |> then(fn {invalid, valid, _duplicate_indexes} ->
      {Enum.reverse(invalid), Enum.reverse(valid)}
    end)
  end

  defp resource_summary_scope_key(%{"spacecraft_id" => spacecraft_id})
       when spacecraft_id not in [nil, ""],
       do: spacecraft_id

  defp resource_summary_scope_key(_summary), do: "*"

  defp duplicate_resource_summary_input(summary, key, index, count) do
    resource_summary_id = duplicate_resource_summary_id(key, index)

    %{
      "id" => "resource_projection:invalid_resource_summary:#{resource_summary_id}",
      "resource_summary_id" => resource_summary_id,
      "spacecraft_id" => stable_id_or_nil(summary["spacecraft_id"]),
      "required_operator_action" => "review_invalid_resource_projection_summary",
      "approval_status" => "operator_review_required",
      "review_status" => "operator_review_required",
      "invalid_resource_summary_input" => true,
      "invalid_resource_summary_input_reason" => "duplicate_resource_summary_scope",
      "duplicate_resource_summary_scope" => true,
      "resource_summary_key" => duplicate_resource_summary_key(key),
      "duplicate_resource_summary_index" => index,
      "duplicate_resource_summary_count" => count,
      "source_resource_summary" => summary
    }
    |> compact_map()
  end

  defp duplicate_resource_summary_id("*", index), do: "all_spacecraft:duplicate:#{index}"
  defp duplicate_resource_summary_id(key, index), do: "#{key}:duplicate:#{index}"

  defp duplicate_resource_summary_key("*"), do: "all_spacecraft"
  defp duplicate_resource_summary_key(key), do: key

  defp mixed_wildcard_resource_summary_scope?("*", summary_count), do: summary_count > 1
  defp mixed_wildcard_resource_summary_scope?(_key, _summary_count), do: false

  defp mixed_wildcard_resource_summary_input(summary) do
    resource_summary_id = "all_spacecraft:mixed_scope"

    %{
      "id" => "resource_projection:invalid_resource_summary:#{resource_summary_id}",
      "resource_summary_id" => resource_summary_id,
      "required_operator_action" => "review_invalid_resource_projection_summary",
      "approval_status" => "operator_review_required",
      "review_status" => "operator_review_required",
      "invalid_resource_summary_input" => true,
      "invalid_resource_summary_input_reason" => "mixed_wildcard_resource_summary_scope",
      "mixed_wildcard_resource_summary_scope" => true,
      "resource_summary_key" => "all_spacecraft",
      "source_resource_summary" => summary
    }
    |> compact_map()
  end

  defp normalize_summary_battery_fields(summary) do
    battery_capacity_wh = Map.get(summary, "battery_capacity_wh")
    battery_energy_used_wh = Map.get(summary, "battery_energy_used_wh")
    battery_state_of_charge = Map.get(summary, "battery_state_of_charge")

    derived_state_of_charge =
      cond do
        is_number(battery_state_of_charge) ->
          battery_state_of_charge * 1.0

        is_number(battery_capacity_wh) and battery_capacity_wh > 0 and
            is_number(battery_energy_used_wh) ->
          ((battery_capacity_wh - battery_energy_used_wh) / battery_capacity_wh)
          |> max(0.0)
          |> min(1.0)

        true ->
          nil
      end

    summary
    |> maybe_put("battery_state_of_charge", derived_state_of_charge)
    |> maybe_put("power_margin", Map.get(summary, "power_margin") || derived_state_of_charge)
  end

  defp normalize_resource_summary_numbers(summary) do
    summary
    |> normalize_number_fields(~w(
      battery_capacity_wh
      battery_energy_used_wh
      battery_energy_generated_wh
      storage_capacity_mb
      storage_used_mb
      downlink_capacity_mb
      fuel_margin
      power_margin
      battery_state_of_charge
      storage_margin
      downlink_margin
    ))
  end

  defp normalize_resource_availability_aliases(summary) do
    summary
    |> copy_resource_availability_aliases(@resource_availability_value_aliases)
    |> copy_resource_availability_status_aliases(@resource_availability_status_aliases)
    |> copy_resource_availability_aliases(%{"degraded" => @resource_degraded_aliases})
    |> normalize_resource_availability_boolean_values()
  end

  defp normalize_resource_margin_aliases(summary) do
    Enum.reduce(@resource_margin_aliases, summary, fn {canonical_key, aliases}, acc ->
      Enum.reduce(aliases, acc, fn alias_key, acc ->
        copy_resource_margin_alias(acc, canonical_key, alias_key)
      end)
    end)
  end

  defp copy_resource_margin_alias(summary, canonical_key, alias_key) do
    case {Map.get(summary, canonical_key), Map.get(summary, alias_key)} do
      {nil, value} when value not in [nil, ""] -> Map.put(summary, canonical_key, value)
      _values -> summary
    end
  end

  defp normalize_resource_activity_type_lists(summary) do
    summary
    |> normalize_resource_activity_type_list("suppressed_activity_types")
    |> normalize_resource_activity_type_list("incompatible_activity_types")
  end

  defp normalize_resource_activity_type_list(summary, field) do
    case resource_activity_type_list(Map.get(summary, field)) do
      [] -> Map.delete(summary, field)
      values -> Map.put(summary, field, values)
    end
  end

  defp resource_activity_type_list(values) when is_list(values) do
    values
    |> Enum.flat_map(&resource_activity_type_list/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp resource_activity_type_list(%{} = value) do
    ["type", "activity_type", "direction"]
    |> Enum.flat_map(&resource_activity_type_list(Map.get(value, &1)))
  end

  defp resource_activity_type_list(value) when is_binary(value) do
    value
    |> String.split(",", trim: true)
    |> Enum.map(&normalize_resource_activity_token/1)
    |> Enum.reject(&is_nil/1)
  end

  defp resource_activity_type_list(nil), do: []

  defp resource_activity_type_list(value) when is_atom(value),
    do: value |> Atom.to_string() |> resource_activity_type_list()

  defp resource_activity_type_list(_value), do: []

  defp normalize_resource_activity_token(value) when is_binary(value) do
    value
    |> normalized_direction_token()
    |> case do
      nil ->
        nil

      token when is_map_key(@resource_activity_type_aliases, token) ->
        Map.fetch!(@resource_activity_type_aliases, token)

      token ->
        token
    end
  end

  defp normalized_direction_token(value) do
    value
    |> to_string()
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
    |> case do
      "" -> nil
      "nil" -> nil
      token -> token
    end
  end

  defp normalize_resource_availability_boolean_values(summary) do
    Enum.reduce(
      ["payload_available", "antenna_available", "spacecraft_available", "degraded"],
      summary,
      fn field, acc ->
        case resource_availability_boolean_value(Map.get(acc, field)) do
          value when is_boolean(value) -> Map.put(acc, field, value)
          nil -> acc
        end
      end
    )
  end

  defp copy_resource_availability_alias(summary, canonical_key, alias_key) do
    summary =
      if Map.has_key?(summary, canonical_key) or not Map.has_key?(summary, alias_key) do
        summary
      else
        Map.put(summary, canonical_key, Map.get(summary, alias_key))
      end

    Map.delete(summary, alias_key)
  end

  defp copy_resource_availability_aliases(summary, aliases_by_field) do
    Enum.reduce(aliases_by_field, summary, fn {canonical_key, aliases}, acc ->
      Enum.reduce(aliases, acc, fn alias_key, acc ->
        copy_resource_availability_alias(acc, canonical_key, alias_key)
      end)
    end)
  end

  defp copy_resource_availability_status_alias(summary, canonical_key, alias_key) do
    alias_value = resource_availability_boolean_value(Map.get(summary, alias_key))

    if Map.has_key?(summary, canonical_key) or not is_boolean(alias_value) do
      summary
    else
      Map.put(summary, canonical_key, alias_value)
    end
  end

  defp copy_resource_availability_status_aliases(summary, aliases_by_field) do
    Enum.reduce(aliases_by_field, summary, fn {canonical_key, aliases}, acc ->
      Enum.reduce(aliases, acc, fn alias_key, acc ->
        copy_resource_availability_status_alias(acc, canonical_key, alias_key)
      end)
    end)
  end

  defp resource_availability_boolean_value(value) when is_boolean(value), do: value

  defp resource_availability_boolean_value(value) when is_number(value) do
    cond do
      value == 1 -> true
      value == 0 -> false
      true -> nil
    end
  end

  defp resource_availability_boolean_value(value) when is_binary(value) do
    case String.downcase(String.trim(value)) do
      value when value in @resource_availability_true_tokens -> true
      value when value in @resource_availability_false_tokens -> false
      _value -> nil
    end
  end

  defp resource_availability_boolean_value(_value), do: nil

  defp normalize_number_fields(map, fields) do
    Enum.reduce(fields, map, fn field, acc ->
      if Map.has_key?(acc, field) do
        case numeric_or_nil(Map.get(acc, field)) do
          value when is_number(value) -> Map.put(acc, field, value)
          _value -> acc
        end
      else
        acc
      end
    end)
  end

  defp stable_id?(value) when is_atom(value) and not is_nil(value) do
    value
    |> Atom.to_string()
    |> stable_id?()
  end

  defp stable_id?("nil"), do: false
  defp stable_id?(value) when is_binary(value), do: Regex.match?(@stable_id_pattern, value)
  defp stable_id?(value) when is_integer(value), do: value |> Integer.to_string() |> stable_id?()
  defp stable_id?(_value), do: false

  defp stable_id_or_nil(nil), do: nil
  defp stable_id_or_nil("nil"), do: nil
  defp stable_id_or_nil(value) when is_binary(value), do: if(stable_id?(value), do: value)

  defp stable_id_or_nil(value) when is_atom(value),
    do: value |> Atom.to_string() |> stable_id_or_nil()

  defp stable_id_or_nil(value) when is_integer(value),
    do: value |> Integer.to_string() |> stable_id_or_nil()

  defp stable_id_or_nil(_value), do: nil

  defp numeric_or_nil(value) when is_integer(value) or is_float(value), do: value * 1.0

  defp numeric_or_nil(value) when is_binary(value) do
    value = String.trim(value)

    case Float.parse(value) do
      {number, ""} -> number
      _result -> nil
    end
  end

  defp numeric_or_nil(_value), do: nil

  defp stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_key(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value) when is_boolean(value), do: value
  defp stringify_keys(nil), do: nil
  defp stringify_keys(value) when is_atom(value), do: Atom.to_string(value)
  defp stringify_keys(value), do: value

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp encode_key(key) when is_atom(key), do: Atom.to_string(key)
  defp encode_key(key), do: key
end
