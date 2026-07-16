defmodule OrbitalDynamics.CandidateRefresh.ResourceFiltering do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ValueEncoding
  alias OrbitalDynamics.{ResourceFilter, ResourceSummary}

  def summary_inputs(refresh, operational_feedback) do
    {summaries, invalid_summaries} =
      refresh
      |> refresh_resource_summaries()
      |> normalize_resource_summary_inputs()

    {summaries, feedback_invalid_summaries} =
      summaries
      |> apply_resource_feedback_overrides(operational_feedback.(refresh))
      |> normalize_resource_summary_inputs()

    {summaries, summaries ++ invalid_summaries ++ feedback_invalid_summaries}
  end

  def refresh_resource_summaries(refresh) do
    [
      Map.get(refresh, "resource_summaries", []),
      get_in(refresh, ["mission_state", "resource_summaries"]) || [],
      get_in(refresh, ["accepted_planning_state", "resource_summaries"]) || []
    ]
    |> Enum.flat_map(&List.wrap/1)
  end

  def summary_inputs_invalid_count(resource_filter_report) do
    Map.get(resource_filter_report, "invalid_resource_summary_input_count", 0)
  end

  def apply_filters(candidates, refresh, [], [], _spacecraft_identity_by_scenario) do
    ResourceFilter.filter_candidates(candidates, [],
      policy: Map.get(refresh, "resource_filter_policy", %{}),
      approval_policy: Map.get(refresh, "approval_policy")
    )
  end

  def apply_filters(
        candidates,
        refresh,
        summaries,
        filter_summaries,
        spacecraft_identity_by_scenario
      ) do
    candidates
    |> add_resource_spacecraft_ids(refresh, summaries, spacecraft_identity_by_scenario)
    |> ResourceFilter.filter_candidates(filter_summaries,
      policy: Map.get(refresh, "resource_filter_policy", %{}),
      approval_policy: Map.get(refresh, "approval_policy")
    )
  end

  defp normalize_resource_summary_inputs(summaries) when is_list(summaries) do
    summaries
    |> Enum.map(&normalize_resource_summary_input/1)
    |> Enum.split_with(fn
      {:valid, _summary} -> true
      {:invalid, _summary} -> false
    end)
    |> then(fn {valid, invalid} ->
      {
        Enum.map(valid, fn {:valid, summary} -> summary end),
        Enum.map(invalid, fn {:invalid, summary} -> summary end)
      }
    end)
  end

  defp normalize_resource_summary_inputs(nil), do: {[], []}

  defp normalize_resource_summary_inputs(summaries), do: {[], [summaries]}

  defp normalize_resource_summary_input(%ResourceSummary{} = summary),
    do: {:valid, ResourceSummary.to_map(summary)}

  defp normalize_resource_summary_input(%{} = summary) do
    {:valid, summary |> ResourceSummary.from_map!() |> ResourceSummary.to_map()}
  rescue
    ArgumentError -> {:invalid, stringify_keys(summary)}
  end

  defp normalize_resource_summary_input(summary), do: {:invalid, summary}

  defp apply_resource_feedback_overrides(summaries, feedback) do
    feedback = stringify_keys(feedback || %{})
    margin_overrides = Map.get(feedback, "resource_margin_overrides", %{})
    availability_overrides = Map.get(feedback, "resource_availability_overrides", %{})

    if margin_overrides == %{} and availability_overrides == %{} do
      summaries
    else
      override_ids =
        [margin_overrides, availability_overrides]
        |> Enum.flat_map(&Map.keys/1)
        |> Enum.reject(&(&1 in [nil, ""]))
        |> Enum.uniq()

      {summaries, existing_ids} =
        Enum.map_reduce(summaries, MapSet.new(), fn summary, ids ->
          spacecraft_id = Map.get(summary, "spacecraft_id")

          {
            apply_resource_feedback_override(
              summary,
              margin_overrides,
              availability_overrides,
              operational_feedback_trust_boundary(feedback)
            ),
            if(spacecraft_id, do: MapSet.put(ids, spacecraft_id), else: ids)
          }
        end)

      missing_summaries =
        override_ids
        |> Enum.reject(&MapSet.member?(existing_ids, &1))
        |> Enum.map(fn spacecraft_id ->
          %{"schema_contract" => "resource_summary.v1", "spacecraft_id" => spacecraft_id}
          |> apply_resource_feedback_override(
            margin_overrides,
            availability_overrides,
            operational_feedback_trust_boundary(feedback)
          )
        end)

      summaries ++ missing_summaries
    end
  end

  defp apply_resource_feedback_override(
         summary,
         margin_overrides,
         availability_overrides,
         feedback_trust_boundary
       ) do
    spacecraft_id = Map.get(summary, "spacecraft_id")

    margin_override =
      margin_overrides
      |> Map.get(spacecraft_id, %{})
      |> OrbitalDynamics.CandidateRefresh.OperationalFeedback.normalize_resource_margin_aliases()

    availability_override = Map.get(availability_overrides, spacecraft_id, %{})

    summary
    |> merge_resource_feedback_fields(margin_override, [
      "fuel_margin",
      "power_margin",
      "storage_margin",
      "downlink_margin",
      "thermal_margin_c",
      "battery_capacity_wh",
      "battery_energy_used_wh",
      "battery_state_of_charge"
    ])
    |> drop_stale_resource_feedback_derivation_inputs(margin_override)
    |> merge_resource_feedback_boolean_fields(availability_override, [
      "payload_available",
      "antenna_available",
      "degraded"
    ])
    |> merge_resource_feedback_activity_type_fields(availability_override)
    |> merge_resource_mode_feedback(availability_override)
    |> merge_spacecraft_availability_feedback(availability_override)
    |> maybe_mark_resource_feedback_source(
      margin_override,
      availability_override,
      feedback_trust_boundary
    )
  end

  defp merge_resource_feedback_fields(summary, overrides, fields) when is_map(overrides) do
    overrides = stringify_keys(overrides)

    Enum.reduce(fields, summary, fn field, acc ->
      case Map.get(overrides, field) do
        value when is_boolean(value) ->
          Map.put(acc, field, value)

        value ->
          case ValueEncoding.numeric_value(value) do
            number when is_number(number) -> Map.put(acc, field, number)
            nil -> acc
          end
      end
    end)
  end

  defp merge_resource_feedback_fields(summary, _overrides, _fields), do: summary

  defp drop_stale_resource_feedback_derivation_inputs(summary, overrides)
       when is_map(overrides) do
    overrides = stringify_keys(overrides)

    summary
    |> maybe_drop_storage_derivation_inputs(overrides)
    |> maybe_drop_battery_derivation_inputs(overrides)
  end

  defp drop_stale_resource_feedback_derivation_inputs(summary, _overrides), do: summary

  defp maybe_drop_storage_derivation_inputs(summary, %{"storage_margin" => _margin}) do
    Map.drop(summary, ["storage_capacity_mb", "storage_used_mb"])
  end

  defp maybe_drop_storage_derivation_inputs(summary, _overrides), do: summary

  defp maybe_drop_battery_derivation_inputs(
         summary,
         %{"battery_state_of_charge" => _state} = overrides
       ) do
    if Map.has_key?(overrides, "battery_capacity_wh") and
         Map.has_key?(overrides, "battery_energy_used_wh") do
      summary
    else
      Map.drop(summary, ["battery_capacity_wh", "battery_energy_used_wh"])
    end
  end

  defp maybe_drop_battery_derivation_inputs(summary, _overrides), do: summary

  defp merge_resource_feedback_boolean_fields(summary, overrides, fields)
       when is_map(overrides) do
    overrides = stringify_keys(overrides)

    Enum.reduce(fields, summary, fn field, acc ->
      case boolean_value(Map.get(overrides, field)) do
        bool when is_boolean(bool) -> Map.put(acc, field, bool)
        nil -> acc
      end
    end)
  end

  defp merge_resource_feedback_boolean_fields(summary, _overrides, _fields), do: summary

  defp merge_resource_feedback_activity_type_fields(summary, overrides) when is_map(overrides) do
    overrides = stringify_keys(overrides)

    Enum.reduce(["suppressed_activity_types", "incompatible_activity_types"], summary, fn field,
                                                                                          acc ->
      case Map.get(overrides, field) do
        nil -> acc
        value -> Map.put(acc, field, value)
      end
    end)
  end

  defp merge_resource_feedback_activity_type_fields(summary, _overrides), do: summary

  defp merge_resource_mode_feedback(summary, overrides) when is_map(overrides) do
    overrides = stringify_keys(overrides)

    case Map.get(overrides, "mode") do
      mode when is_binary(mode) and mode != "" ->
        summary
        |> Map.put("mode", mode)
        |> maybe_mark_degraded_mode(mode)

      _mode ->
        summary
    end
  end

  defp merge_resource_mode_feedback(summary, _overrides), do: summary

  defp maybe_mark_degraded_mode(summary, mode) when mode in ["degraded", "degraded_mode", "safe"],
    do: Map.put(summary, "degraded", true)

  defp maybe_mark_degraded_mode(summary, _mode), do: summary

  defp merge_spacecraft_availability_feedback(summary, overrides) when is_map(overrides) do
    overrides = stringify_keys(overrides)

    if boolean_value(Map.get(overrides, "spacecraft_available")) == false or
         boolean_value(Map.get(overrides, "spacecraft_availability")) == false do
      summary
      |> Map.put("spacecraft_available", false)
      |> Map.put("payload_available", false)
      |> Map.put("antenna_available", false)
      |> Map.put("degraded", true)
    else
      summary
    end
  end

  defp merge_spacecraft_availability_feedback(summary, _overrides), do: summary

  defp maybe_mark_resource_feedback_source(
         summary,
         margin_override,
         availability_override,
         feedback_trust_boundary
       ) do
    if resource_feedback_override_applied?(margin_override) or
         resource_feedback_override_applied?(availability_override) do
      summary
      |> Map.put("source_quality", "operational_feedback")
      |> Map.update("provenance", %{}, fn
        provenance when is_map(provenance) -> provenance
        _provenance -> %{}
      end)
      |> put_in(["provenance", "resource_feedback_source"], "operational_feedback")
      |> put_in(
        ["provenance", "trust_boundary"],
        resource_feedback_trust_boundary(summary, feedback_trust_boundary)
      )
    else
      summary
    end
  end

  defp resource_feedback_trust_boundary(summary, "operational_feedback") do
    Map.get(summary, "trust_boundary") ||
      get_in(summary, ["provenance", "trust_boundary"]) ||
      "operational_feedback"
  end

  defp resource_feedback_trust_boundary(_summary, trust_boundary), do: trust_boundary

  defp operational_feedback_trust_boundary(%{"trust_boundary" => trust_boundary})
       when is_binary(trust_boundary) and trust_boundary != "",
       do: trust_boundary

  defp operational_feedback_trust_boundary(%{
         "provenance" => %{"trust_boundary" => trust_boundary}
       })
       when is_binary(trust_boundary) and trust_boundary != "",
       do: trust_boundary

  defp operational_feedback_trust_boundary(_feedback), do: "operational_feedback"

  defp resource_feedback_override_applied?(override) when is_map(override) do
    override
    |> Map.values()
    |> Enum.any?(&(is_number(&1) or is_boolean(&1) or nonempty_binary?(&1)))
  end

  defp resource_feedback_override_applied?(_override), do: false

  defp nonempty_binary?(value), do: is_binary(value) and value != ""

  defp add_resource_spacecraft_ids(
         candidates,
         refresh,
         summaries,
         spacecraft_identity_by_scenario
       ) do
    summary_ids =
      summaries
      |> Enum.map(&Map.get(&1, "spacecraft_id"))
      |> Enum.reject(&is_nil/1)
      |> MapSet.new()

    spacecraft_by_scenario = spacecraft_identity_by_scenario.(refresh)

    Enum.map(candidates, fn candidate ->
      spacecraft_id = Map.get(spacecraft_by_scenario, candidate["scenario_id"])

      if is_nil(candidate["spacecraft_id"]) and MapSet.member?(summary_ids, spacecraft_id) do
        Map.put(candidate, "spacecraft_id", spacecraft_id)
      else
        candidate
      end
    end)
  end

  defp stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp boolean_value(value) when is_boolean(value), do: value

  defp boolean_value(value) when is_number(value) do
    cond do
      value == 1 -> true
      value == 0 -> false
      true -> nil
    end
  end

  defp boolean_value(value) when is_binary(value) do
    case String.downcase(String.trim(value)) do
      value when value in ["true", "1"] -> true
      value when value in ["false", "0"] -> false
      _value -> nil
    end
  end

  defp boolean_value(_value), do: nil

  defp encode_value(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), encode_value(value)} end)
  end

  defp encode_value(values) when is_list(values) do
    if Keyword.keyword?(values) do
      Map.new(values, fn {key, value} -> {encode_value(key), encode_value(value)} end)
    else
      Enum.map(values, &encode_value/1)
    end
  end

  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
