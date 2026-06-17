defmodule OrbitalDynamics.CampaignPlanner.BranchOperationalFeedback do
  @moduledoc false

  def derive(branch, operational_feedback, opts) when is_list(opts) do
    events =
      branch
      |> Map.get("events", [])
      |> Enum.map(&stringify_keys/1)

    base_feedback =
      operational_feedback
      |> Kernel.||(%{})
      |> normalize_operational_feedback(opts)
      |> prune_branch_downlink_gap_source_feedback(events, opts)

    events
    |> Enum.reduce(base_feedback, fn event, feedback ->
      apply_branch_feedback_event(event, feedback, opts)
    end)
    |> put_branch_event_feedback_trust_boundary(events)
  end

  defp normalize_operational_feedback(feedback, opts) do
    opts
    |> Keyword.fetch!(:normalize_operational_feedback)
    |> then(& &1.(feedback))
  end

  defp normalize_resource_margin_aliases(entry, opts) do
    opts
    |> Keyword.fetch!(:normalize_resource_margin_aliases)
    |> then(& &1.(entry))
  end

  defp normalize_resource_availability_aliases(entry, opts) do
    opts
    |> Keyword.fetch!(:normalize_resource_availability_aliases)
    |> then(& &1.(entry))
  end

  defp branch_event_spacecraft_id(event, opts) do
    opts
    |> Keyword.fetch!(:branch_event_spacecraft_id)
    |> then(& &1.(event))
  end

  defp event_ground_station_id(event, opts) do
    opts
    |> Keyword.fetch!(:event_ground_station_id)
    |> then(& &1.(event))
  end

  defp prune_branch_downlink_gap_source_feedback(feedback, events, opts) do
    events
    |> Enum.reduce(feedback, fn event, feedback ->
      if event["type"] == "downlink_completion_gap" and event["feedback_source"] not in [nil, ""] do
        key = station_feedback_key(event, opts)

        if get_in(feedback, ["downlink_demand_context", key, "feedback_source"]) ==
             event["feedback_source"] do
          feedback
          |> update_in(["downlink_demand_mb"], &Map.delete(&1 || %{}, key))
          |> update_in(["downlink_demand_sources"], &Map.delete(&1 || %{}, key))
          |> update_in(["downlink_demand_context"], &Map.delete(&1 || %{}, key))
        else
          feedback
        end
      else
        feedback
      end
    end)
  end

  defp put_branch_event_feedback_trust_boundary(feedback, events) do
    trust_boundaries =
      events
      |> Enum.map(
        &(Map.get(&1, "trust_boundary") || get_in(&1, ["provenance", "trust_boundary"]))
      )
      |> Enum.reject(&(&1 in [nil, ""]))
      |> Enum.uniq()

    case {Map.get(feedback, "trust_boundary"), trust_boundaries} do
      {existing, _trust_boundaries} when existing not in [nil, ""] -> feedback
      {_missing, [trust_boundary]} -> Map.put(feedback, "trust_boundary", trust_boundary)
      _other -> feedback
    end
  end

  defp apply_branch_feedback_event(
         %{"type" => "station_throughput_feedback"} = event,
         feedback,
         opts
       ) do
    put_branch_feedback_factor(
      feedback,
      "station_throughput_factor",
      station_feedback_key(event, opts),
      branch_event_weighted_unit_feedback_value(event, "station_throughput_factor")
    )
  end

  defp apply_branch_feedback_event(
         %{"type" => "contact_success_feedback"} = event,
         feedback,
         opts
       ) do
    put_branch_feedback_factor(
      feedback,
      "contact_success_rate",
      station_feedback_key(event, opts),
      branch_event_weighted_unit_feedback_value(event, "contact_success_factor")
    )
  end

  defp apply_branch_feedback_event(
         %{"type" => "observation_success_feedback"} = event,
         feedback,
         _opts
       ) do
    feedback
    |> put_branch_feedback_factor(
      "observation_success_rate",
      event["target_id"],
      branch_event_weighted_unit_feedback_value(event, "observation_success_factor")
    )
    |> put_branch_feedback_factor(
      "image_quality_score",
      event["target_id"],
      branch_event_weighted_unit_feedback_value(event, "image_quality_score")
    )
    |> put_branch_feedback_string(
      "image_quality_status",
      event["target_id"],
      event["image_quality_status"]
    )
    |> put_branch_feedback_string(
      "image_quality_source",
      event["target_id"],
      event["image_quality_source"]
    )
    |> put_branch_feedback_factor(
      "cloud_cover_fraction",
      event["target_id"],
      branch_event_weighted_unit_feedback_value(event, "cloud_cover_fraction")
    )
    |> put_branch_feedback_factor(
      "blur_score",
      event["target_id"],
      branch_event_weighted_unit_feedback_value(event, "blur_score")
    )
  end

  defp apply_branch_feedback_event(
         %{"type" => "target_priority_feedback"} = event,
         feedback,
         _opts
       ) do
    put_branch_feedback_factor(
      feedback,
      "target_priority_overrides",
      event["target_id"],
      branch_event_weighted_nonnegative_feedback_value(event, "priority")
    )
  end

  defp apply_branch_feedback_event(
         %{"type" => "maneuver_success_feedback"} = event,
         feedback,
         _opts
       ) do
    feedback
    |> put_branch_feedback_factor(
      "maneuver_success_rate",
      maneuver_feedback_event_key(event),
      branch_event_weighted_unit_feedback_value(event, "maneuver_success_factor")
    )
    |> put_branch_feedback_factor(
      "maneuver_success_rate",
      event["activity_id"],
      branch_event_weighted_unit_feedback_value(event, "maneuver_success_factor")
    )
  end

  defp apply_branch_feedback_event(
         %{"type" => "maneuver_execution_uncertainty_feedback"} = event,
         feedback,
         _opts
       ) do
    feedback
    |> put_branch_feedback_entry(
      "maneuver_execution_uncertainty",
      maneuver_feedback_event_key(event),
      maneuver_execution_uncertainty_event_feedback(event)
    )
    |> put_branch_feedback_entry(
      "maneuver_execution_uncertainty",
      event["activity_id"],
      maneuver_execution_uncertainty_event_feedback(event)
    )
  end

  defp apply_branch_feedback_event(
         %{"type" => "command_success_feedback"} = event,
         feedback,
         _opts
       ) do
    feedback
    |> put_branch_feedback_factor(
      "command_success_rate",
      command_feedback_event_key(event),
      branch_event_weighted_unit_feedback_value(event, "command_success_factor")
    )
    |> put_branch_feedback_factor(
      "command_success_rate",
      event["activity_id"],
      branch_event_weighted_unit_feedback_value(event, "command_success_factor")
    )
  end

  defp apply_branch_feedback_event(
         %{"type" => "downlink_demand_feedback"} = event,
         feedback,
         opts
       ) do
    feedback
    |> put_branch_feedback_override(
      "downlink_demand_mb",
      station_feedback_key(event, opts),
      branch_event_weighted_nonnegative_feedback_value(event, "required_downlink_mb")
    )
    |> put_branch_feedback_downlink_sources(event, opts)
  end

  defp apply_branch_feedback_event(%{"type" => "downlink_completion_gap"} = event, feedback, opts) do
    feedback
    |> put_branch_feedback_factor(
      "downlink_demand_mb",
      station_feedback_key(event, opts),
      branch_event_weighted_nonnegative_feedback_value(event, "required_downlink_mb")
    )
    |> put_branch_feedback_downlink_sources(event, opts)
    |> put_branch_feedback_downlink_context(event, opts)
  end

  defp apply_branch_feedback_event(
         %{"type" => "resource_margin_pressure"} = event,
         feedback,
         opts
       ) do
    spacecraft_id = branch_event_spacecraft_id(event, opts)
    field = event["resource_field"]

    if spacecraft_id in [nil, ""] or
         field not in [
           "fuel_margin",
           "power_margin",
           "storage_margin",
           "downlink_margin",
           "thermal_margin_c"
         ] or
         not is_number(Map.get(event, field)) do
      feedback
    else
      entry =
        event
        |> Map.take(resource_margin_feedback_fields())
        |> Map.put(field, Map.get(event, field))
        |> normalize_resource_margin_aliases(opts)
        |> compact_map()

      merge_branch_feedback_entry(feedback, "resource_margin_overrides", spacecraft_id, entry)
    end
  end

  defp apply_branch_feedback_event(
         %{"type" => "resource_availability_constraint"} = event,
         feedback,
         opts
       ) do
    spacecraft_id = branch_event_spacecraft_id(event, opts)
    field = event["resource_field"]

    if spacecraft_id in [nil, ""] or
         field not in ["spacecraft_available", "payload_available", "antenna_available"] or
         event["available"] != false do
      feedback
    else
      entry =
        event
        |> Map.take(resource_availability_feedback_fields())
        |> Map.put(field, false)
        |> normalize_resource_availability_aliases(opts)
        |> compact_map()

      merge_branch_feedback_entry(
        feedback,
        "resource_availability_overrides",
        spacecraft_id,
        entry
      )
    end
  end

  defp apply_branch_feedback_event(%{"type" => "degraded_spacecraft"} = event, feedback, opts) do
    spacecraft_id = branch_event_spacecraft_id(event, opts)

    if spacecraft_id in [nil, ""] do
      feedback
    else
      entry =
        event
        |> degraded_spacecraft_feedback_entry()
        |> compact_map()

      merge_branch_feedback_entry(
        feedback,
        "resource_availability_overrides",
        spacecraft_id,
        entry
      )
    end
  end

  defp apply_branch_feedback_event(_event, feedback, _opts), do: feedback

  defp branch_event_weighted_unit_feedback_value(event, field) do
    value = Map.get(event, field)

    case branch_event_feedback_confidence_weight(event) do
      weight when is_number(value) and is_number(weight) ->
        1.0 - (1.0 - clamp_unit_interval(value)) * weight

      _weight ->
        value
    end
  end

  defp branch_event_weighted_nonnegative_feedback_value(event, field) do
    value = Map.get(event, field)

    case branch_event_feedback_confidence_weight(event) do
      weight when is_number(value) and is_number(weight) ->
        max(value, 0.0) * weight

      _weight ->
        value
    end
  end

  def branch_event_feedback_confidence_weight(event) do
    [
      event["feedback_weight"],
      event["feedback_sample_weight"],
      event["sample_weight"],
      event["confidence_weight"]
    ]
    |> Enum.find(&is_number/1)
    |> case do
      value when is_number(value) -> clamp_unit_interval(value)
      _value -> nil
    end
  end

  defp resource_margin_feedback_fields do
    [
      "fuel_margin",
      "power_margin",
      "storage_margin",
      "downlink_margin",
      "thermal_margin_c",
      "battery_capacity_wh",
      "battery_energy_used_wh",
      "battery_state_of_charge"
    ]
  end

  defp resource_availability_feedback_fields do
    [
      "spacecraft_available",
      "payload_available",
      "antenna_available",
      "degraded",
      "mode",
      "incompatible_activity_types"
    ]
  end

  defp degraded_spacecraft_feedback_entry(event) do
    incompatible_types =
      (Map.get(event, "incompatible_activity_types") ||
         Map.get(event, "suppressed_activity_types") || ["observe"])
      |> normalize_incompatible_activity_types()

    %{
      "mode" => degraded_event_mode(event),
      "degraded" => true,
      "spacecraft_available" =>
        if(
          "spacecraft_available_feedback_false" in Map.get(event, "derivation_reasons", []) or
            "spacecraft_availability_feedback_false" in Map.get(event, "derivation_reasons", []),
          do: false
        ),
      "payload_available" => not Enum.member?(incompatible_types, "observe"),
      "antenna_available" =>
        not Enum.any?(incompatible_types, &(&1 in ["downlink", "planned_contact"])),
      "incompatible_activity_types" => incompatible_types
    }
  end

  def normalize_incompatible_activity_types(values) when is_list(values) do
    values
    |> Enum.map(&encode_value/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  def normalize_incompatible_activity_types(value) when is_binary(value) or is_atom(value) do
    case encode_value(value) do
      value when value in [nil, ""] -> ["observe"]
      value -> [value]
    end
  end

  def normalize_incompatible_activity_types(_values), do: ["observe"]

  defp degraded_event_mode(%{"mode" => mode}) when mode not in [nil, ""], do: encode_value(mode)

  defp degraded_event_mode(%{"degraded_mode" => mode}) when mode not in [nil, ""],
    do: encode_value(mode)

  defp degraded_event_mode(_event), do: "degraded"

  defp put_branch_feedback_factor(feedback, _field, key, _value) when key in [nil, ""],
    do: feedback

  defp put_branch_feedback_factor(feedback, field, key, value) when is_number(value) do
    factors =
      case Map.get(feedback, field) do
        %{} = existing -> existing
        _other -> %{}
      end

    Map.put(
      feedback,
      field,
      put_branch_feedback_value(factors, field, encode_value(key), value)
    )
  end

  defp put_branch_feedback_factor(feedback, _field, _key, _value), do: feedback

  defp put_branch_feedback_downlink_sources(feedback, event, opts) do
    key = station_feedback_key(event, opts)
    sources = branch_feedback_downlink_sources(event)

    if key in [nil, ""] or sources == [] do
      feedback
    else
      source_map =
        feedback
        |> Map.get("downlink_demand_sources", %{})
        |> case do
          %{} = existing -> existing
          _existing -> %{}
        end
        |> Map.update(key, sources, fn existing ->
          existing
          |> List.wrap()
          |> Kernel.++(sources)
          |> Enum.map(&encode_value/1)
          |> Enum.reject(&(&1 in [nil, ""]))
          |> Enum.uniq()
          |> Enum.sort()
        end)

      Map.put(feedback, "downlink_demand_sources", source_map)
    end
  end

  defp put_branch_feedback_downlink_context(feedback, event, opts) do
    key = station_feedback_key(event, opts)

    context =
      event
      |> Map.take([
        "collection_id",
        "product_id",
        "product_ids",
        "payload_id",
        "instrument_id",
        "target_id",
        "source_activity_id",
        "source_activity_ids",
        "missed_downlink_activity_id",
        "missed_downlink_activity_ids",
        "objective_id",
        "objective_type",
        "latency_objective",
        "max_latency_s",
        "planned_latency_s",
        "feedback_source",
        "feedback_scope",
        "trust_boundary"
      ])
      |> compact_map()

    if key in [nil, ""] or context == %{} do
      feedback
    else
      context_map =
        feedback
        |> Map.get("downlink_demand_context", %{})
        |> stringify_keys()
        |> Map.put(key, context)

      Map.put(feedback, "downlink_demand_context", context_map)
    end
  end

  defp branch_feedback_downlink_sources(event) do
    [
      event["downlink_demand_source"],
      event["downlink_demand_sources"],
      event["downlink_completion_source"],
      event["downlink_completion_sources"]
    ]
    |> List.flatten()
    |> Enum.map(&encode_value/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp put_branch_feedback_entry(feedback, _field, key, _entry) when key in [nil, ""],
    do: feedback

  defp put_branch_feedback_entry(feedback, field, key, %{} = entry) do
    entries =
      case Map.get(feedback, field) do
        %{} = existing -> existing
        _other -> %{}
      end

    Map.put(feedback, field, Map.put(entries, encode_value(key), entry))
  end

  defp put_branch_feedback_entry(feedback, _field, _key, _entry), do: feedback

  defp put_branch_feedback_string(feedback, _field, key, _value) when key in [nil, ""],
    do: feedback

  defp put_branch_feedback_string(feedback, field, key, value) do
    case encode_value(value) do
      value when is_binary(value) and value != "" ->
        entries =
          case Map.get(feedback, field) do
            %{} = existing -> existing
            _other -> %{}
          end

        Map.put(feedback, field, Map.put(entries, encode_value(key), value))

      _value ->
        feedback
    end
  end

  defp merge_branch_feedback_entry(feedback, _field, key, _entry) when key in [nil, ""],
    do: feedback

  defp merge_branch_feedback_entry(feedback, field, key, %{} = entry) do
    entries =
      case Map.get(feedback, field) do
        %{} = existing -> existing
        _other -> %{}
      end

    Map.put(
      feedback,
      field,
      Map.update(entries, encode_value(key), entry, fn
        %{} = existing -> Map.merge(existing, entry)
        _existing -> entry
      end)
    )
  end

  defp merge_branch_feedback_entry(feedback, _field, _key, _entry), do: feedback

  defp maneuver_execution_uncertainty_event_feedback(event) do
    %{
      "execution_uncertainty_status" => event["execution_uncertainty_status"],
      "execution_uncertainty" => event["execution_uncertainty"],
      "timing_3sigma_s" => event["timing_3sigma_s"],
      "delta_v_3sigma_km_s" => event["delta_v_3sigma_km_s"],
      "delta_v_3sigma_magnitude_km_s" => event["delta_v_3sigma_magnitude_km_s"],
      "execution_uncertainty_source" => event["execution_uncertainty_source"]
    }
    |> compact_map()
  end

  defp put_branch_feedback_override(feedback, _field, key, _value) when key in [nil, ""],
    do: feedback

  defp put_branch_feedback_override(feedback, field, key, value) when is_number(value) do
    factors =
      case Map.get(feedback, field) do
        %{} = existing -> existing
        _other -> %{}
      end

    Map.put(
      feedback,
      field,
      Map.put(factors, encode_value(key), branch_feedback_value(field, value))
    )
  end

  defp put_branch_feedback_override(feedback, _field, _key, _value), do: feedback

  defp put_branch_feedback_value(factors, "downlink_demand_mb", key, value) do
    demand = branch_feedback_value("downlink_demand_mb", value)

    Map.update(factors, key, demand, fn
      existing when is_number(existing) -> max(existing, 0.0) + demand
      _existing -> demand
    end)
  end

  defp put_branch_feedback_value(factors, field, key, value) do
    Map.put(factors, key, branch_feedback_value(field, value))
  end

  defp branch_feedback_value(field, value)
       when field in [
              "station_throughput_factor",
              "contact_success_rate",
              "observation_success_rate",
              "image_quality_score",
              "cloud_cover_fraction",
              "blur_score",
              "maneuver_success_rate",
              "command_success_rate"
            ] do
    value
    |> max(0.0)
    |> min(1.0)
  end

  defp branch_feedback_value(_field, value), do: max(value, 0.0)

  defp station_feedback_key(%{"feedback_scope" => "default"}, _opts), do: "default"

  defp station_feedback_key(event, opts) do
    event_ground_station_id(event, opts) || "default"
  end

  defp command_feedback_event_key(%{"feedback_scope" => "default"}), do: "default"

  defp command_feedback_event_key(event) do
    Map.get(event, "feedback_key") || Map.get(event, "activity_id") || "default"
  end

  defp maneuver_feedback_event_key(%{"feedback_scope" => "default"}), do: "default"

  defp maneuver_feedback_event_key(event) do
    Map.get(event, "feedback_key") || Map.get(event, "activity_id") || "default"
  end

  defp clamp_unit_interval(value), do: value |> max(0.0) |> min(1.0)

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp encode_value(%_{} = struct), do: struct |> Map.from_struct() |> encode_value()

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
