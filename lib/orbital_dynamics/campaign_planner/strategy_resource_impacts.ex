defmodule OrbitalDynamics.CampaignPlanner.StrategyResourceImpacts do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    BranchOperationalFeedback,
    DownlinkActivityNormalization,
    DownlinkObjectiveRequirements,
    MissionStateResourceSources,
    OperationalFeedbackNormalization,
    ScalarValues,
    StrategyMetrics,
    ValueEncoding
  }

  def build(candidate_plan, branch, request) do
    resources =
      request.mission_state
      |> Map.get("resources", %{})
      |> ValueEncoding.stringify_keys()

    activities = Map.get(candidate_plan, "activities", [])
    downlinks = Enum.filter(activities, &DownlinkActivityNormalization.downlink?/1)
    observations = Enum.filter(activities, &(&1["type"] == "observe"))

    fuel_margin_source =
      MissionStateResourceSources.lowest_margin_source(request.mission_state, "fuel_margin")

    power_margin_source =
      MissionStateResourceSources.lowest_margin_source(request.mission_state, "power_margin")

    storage_margin_source =
      MissionStateResourceSources.lowest_margin_source(request.mission_state, "storage_margin")

    downlink_margin_source =
      MissionStateResourceSources.lowest_margin_source(request.mission_state, "downlink_margin")

    thermal_margin_source =
      MissionStateResourceSources.lowest_margin_source(request.mission_state, "thermal_margin_c")

    fuel_margin =
      branch_resource_margin(branch, "fuel_margin") ||
        resource_source_margin(fuel_margin_source, "fuel_margin") ||
        resource_margin(resources, "fuel_margin")

    power_margin =
      branch_resource_margin(branch, "power_margin") ||
        resource_source_margin(power_margin_source, "power_margin") ||
        resource_margin(resources, "power_margin")

    storage_margin =
      branch_resource_margin(branch, "storage_margin") ||
        resource_source_margin(storage_margin_source, "storage_margin") ||
        storage_margin(resources, observations)

    downlink_margin =
      branch_resource_margin(branch, "downlink_margin") ||
        resource_source_margin(downlink_margin_source, "downlink_margin") ||
        downlink_margin(resources, downlinks, request)

    thermal_margin =
      branch_resource_margin(branch, "thermal_margin_c") ||
        resource_source_margin(thermal_margin_source, "thermal_margin_c") ||
        resource_margin(resources, "thermal_margin_c")

    thermal_margin_threshold =
      branch_resource_margin_threshold(branch, "thermal_margin_c") ||
        request.mission_state
        |> get_in([
          "candidate_refresh_defaults",
          "resource_filter_policy",
          "min_activity_thermal_margin_c"
        ])
        |> ScalarValues.numeric_or_nil()

    spacecraft_availability =
      branch_spacecraft_availability(branch) ||
        resource_spacecraft_availability(request.mission_state) ||
        spacecraft_availability(request.mission_state)

    payload_availability =
      branch_resource_availability(branch, "payload_available") ||
        resource_boolean_availability(request.mission_state, "payload_available") ||
        payload_availability(request.mission_state)

    antenna_availability =
      branch_resource_availability(branch, "antenna_available") ||
        resource_boolean_availability(request.mission_state, "antenna_available") ||
        antenna_availability(request.mission_state)

    risk_indicators =
      []
      |> maybe_resource_risk(
        "fuel_margin_low",
        fuel_margin,
        0.25,
        "fuel margin below thin-model threshold"
      )
      |> maybe_resource_risk(
        "power_margin_low",
        power_margin,
        0.2,
        "power margin below thin-model threshold"
      )
      |> maybe_resource_risk(
        "storage_margin_low",
        storage_margin,
        0.2,
        "onboard storage margin below thin-model threshold"
      )
      |> maybe_resource_risk(
        "downlink_capacity_low",
        downlink_margin,
        0.75,
        "downlink capacity margin below required completion target"
      )
      |> maybe_resource_risk(
        "thermal_margin_low",
        thermal_margin,
        thermal_margin_threshold,
        "thermal margin below externally supplied policy threshold"
      )
      |> maybe_resource_risk(
        "spacecraft_availability_low",
        spacecraft_availability,
        1.0,
        "one or more spacecraft unavailable or degraded"
      )
      |> maybe_resource_risk(
        "payload_availability_low",
        payload_availability,
        1.0,
        "payload availability reduced by mission state"
      )
      |> maybe_resource_risk(
        "antenna_availability_low",
        antenna_availability,
        1.0,
        "antenna availability reduced by mission state"
      )

    score_adjustment =
      resource_margin_score(fuel_margin, 0.25) +
        resource_margin_score(power_margin, 0.2) +
        resource_margin_score(storage_margin, 0.2) +
        resource_margin_score(downlink_margin, 0.75) +
        resource_margin_score(thermal_margin, thermal_margin_threshold) +
        resource_margin_score(spacecraft_availability, 1.0) +
        resource_margin_score(payload_availability, 1.0) +
        resource_margin_score(antenna_availability, 1.0)

    warnings =
      Enum.map(risk_indicators, fn risk -> risk["reason"] end)

    %{
      "model" => "thin_mission_state_resource_summary",
      "fuel_margin" => fuel_margin,
      "power_margin" => power_margin,
      "storage_margin" => storage_margin,
      "downlink_capacity_margin" => downlink_margin,
      "thermal_margin_c" => thermal_margin,
      "spacecraft_availability" => spacecraft_availability,
      "payload_availability" => payload_availability,
      "antenna_availability" => antenna_availability,
      "fuel_preservation_mode" =>
        Enum.any?(branch["events"], &(&1["type"] == "fuel_preservation_mode")),
      "score_adjustment" => score_adjustment,
      "risk_indicators" => risk_indicators,
      "warnings" => warnings
    }
  end

  defp resource_margin(resources, key) do
    case ScalarValues.numeric_or_nil(Map.get(resources, key)) do
      value when is_number(value) -> value
      _value -> nil
    end
  end

  defp resource_source_margin(nil, _field), do: nil

  defp resource_source_margin(source, field) do
    case ScalarValues.numeric_or_nil(Map.get(source, field)) do
      value when is_number(value) -> value
      _value -> nil
    end
  end

  defp branch_resource_margin(branch, field) do
    branch
    |> Map.get("events", [])
    |> Enum.map(&ValueEncoding.stringify_keys/1)
    |> Enum.find_value(fn event ->
      if event["type"] == "resource_margin_pressure" and event["resource_field"] == field do
        ScalarValues.numeric_or_nil(event[field])
      end
    end)
  end

  defp branch_resource_margin_threshold(branch, field) do
    branch
    |> Map.get("events", [])
    |> Enum.map(&ValueEncoding.stringify_keys/1)
    |> Enum.find_value(fn event ->
      if event["type"] == "resource_margin_pressure" and event["resource_field"] == field do
        ScalarValues.numeric_or_nil(event["#{field}_threshold"])
      end
    end)
  end

  defp branch_spacecraft_availability(branch) do
    branch
    |> Map.get("events", [])
    |> Enum.map(&ValueEncoding.stringify_keys/1)
    |> Enum.any?(fn event ->
      event["type"] == "degraded_spacecraft" or
        (event["type"] == "resource_availability_constraint" and
           event["resource_field"] in ["spacecraft_available", "spacecraft_availability"] and
           event["available"] == false)
    end)
    |> case do
      true -> 0.0
      false -> nil
    end
  end

  defp storage_margin(resources, observations) do
    storage_capacity_mb = ScalarValues.numeric_or_nil(Map.get(resources, "storage_capacity_mb"))
    storage_used_mb = ScalarValues.numeric_or_nil(Map.get(resources, "storage_used_mb"))

    cond do
      is_number(ScalarValues.numeric_or_nil(Map.get(resources, "storage_margin"))) ->
        ScalarValues.numeric_or_nil(Map.get(resources, "storage_margin"))

      is_number(storage_capacity_mb) and storage_capacity_mb > 0.0 and is_number(storage_used_mb) ->
        produced_mb =
          observations
          |> Enum.map(
            &(get_in(&1, ["metadata", "estimated_storage_mb"]) ||
                Map.get(&1, "estimated_storage_mb", 0.0))
          )
          |> Enum.sum()

        max(
          (storage_capacity_mb - storage_used_mb - produced_mb) /
            storage_capacity_mb,
          0.0
        )

      true ->
        nil
    end
  end

  defp downlink_margin(resources, downlinks, request) do
    downlink_capacity_mb = ScalarValues.numeric_or_nil(Map.get(resources, "downlink_capacity_mb"))

    cond do
      is_number(ScalarValues.numeric_or_nil(Map.get(resources, "downlink_margin"))) ->
        ScalarValues.numeric_or_nil(Map.get(resources, "downlink_margin"))

      is_number(downlink_capacity_mb) and
          DownlinkObjectiveRequirements.objective?(request.mission_state) ->
        required_contacts =
          max(
            DownlinkObjectiveRequirements.required_contacts(
              request.mission_state,
              request.prior_plan
            ),
            1
          )

        planned_contacts = max(length(downlinks), 1)
        min(downlink_capacity_mb / required_contacts / planned_contacts, 1.0)

      DownlinkObjectiveRequirements.objective?(request.mission_state) ->
        StrategyMetrics.downlink_completion_ratio(downlinks, request)

      true ->
        nil
    end
  end

  defp resource_spacecraft_availability(mission_state) do
    if resource_availability_source_present?(mission_state, "degraded") or
         resource_availability_source_present?(mission_state, "mode") or
         resource_availability_source_present?(mission_state, "spacecraft_available") do
      source_inputs =
        mission_state
        |> MissionStateResourceSources.summary_inputs()
        |> Enum.map(&OperationalFeedbackNormalization.normalize_resource_availability_aliases/1)

      summaries =
        mission_state
        |> MissionStateResourceSources.metric_sources()
        |> Enum.map(&OperationalFeedbackNormalization.normalize_resource_availability_aliases/1)
        |> Enum.zip(source_inputs)
        |> Enum.filter(fn {_summary, source_input} ->
          resource_spacecraft_availability_summary?(source_input)
        end)
        |> Enum.map(fn {summary, _source_input} -> summary end)

      if summaries == [] do
        nil
      else
        available =
          Enum.count(summaries, fn summary ->
            summary = ValueEncoding.stringify_keys(summary)

            Map.get(summary, "spacecraft_available", true) != false and
              Map.get(summary, "mode", "nominal") not in ["degraded", "degraded_mode", "safe"] and
              not ScalarValues.truthy?(Map.get(summary, "degraded"))
          end)

        available / length(summaries)
      end
    end
  end

  defp resource_spacecraft_availability_summary?(summary) do
    Map.has_key?(summary, "spacecraft_available") or Map.has_key?(summary, "degraded") or
      Map.has_key?(summary, "mode")
  end

  defp resource_boolean_availability(mission_state, field) do
    if resource_availability_source_present?(mission_state, field) do
      values =
        mission_state
        |> MissionStateResourceSources.metric_sources()
        |> Enum.map(&OperationalFeedbackNormalization.normalize_resource_availability_aliases/1)
        |> Enum.map(&Map.get(&1, field))
        |> Enum.filter(&is_boolean/1)

      if values == [] do
        nil
      else
        Enum.count(values, & &1) / length(values)
      end
    end
  end

  defp resource_availability_source_present?(mission_state, field) do
    MissionStateResourceSources.explicit_summaries?(mission_state) or
      mission_state
      |> Map.get("resources", %{})
      |> ValueEncoding.stringify_keys()
      |> resource_source_has_field?(field)
  end

  defp resource_source_has_field?(resources, field) when is_map(resources) do
    normalized_resources =
      OperationalFeedbackNormalization.normalize_resource_availability_aliases(resources)

    Map.has_key?(normalized_resources, field) or
      resources
      |> MissionStateResourceSources.nested_sources()
      |> Enum.any?(fn
        %{} = source ->
          source
          |> OperationalFeedbackNormalization.normalize_resource_availability_aliases()
          |> Map.has_key?(field)

        _source ->
          false
      end)
  end

  defp resource_source_has_field?(_resources, _field), do: false

  defp branch_resource_availability(branch, field) do
    branch
    |> Map.get("events", [])
    |> Enum.map(&ValueEncoding.stringify_keys/1)
    |> Enum.any?(fn event ->
      branch_resource_unavailable_event?(event, field)
    end)
    |> case do
      true -> 0.0
      false -> nil
    end
  end

  defp branch_resource_unavailable_event?(
         %{"type" => "resource_availability_constraint"} = event,
         field
       ) do
    event["resource_field"] == field and event["available"] == false
  end

  defp branch_resource_unavailable_event?(%{"type" => "degraded_spacecraft"} = event, field) do
    incompatible_types =
      (Map.get(event, "incompatible_activity_types") ||
         Map.get(event, "suppressed_activity_types") || [])
      |> BranchOperationalFeedback.normalize_incompatible_activity_types()

    case field do
      "payload_available" ->
        "observe" in incompatible_types

      "antenna_available" ->
        Enum.any?(incompatible_types, &(&1 in ["downlink", "planned_contact"]))

      _field ->
        false
    end
  end

  defp branch_resource_unavailable_event?(_event, _field), do: false

  defp spacecraft_availability(mission_state) do
    states = Map.get(mission_state, "spacecraft_states", [])

    if states == [] do
      1.0
    else
      available =
        Enum.count(states, fn state ->
          state =
            state
            |> ValueEncoding.stringify_keys()
            |> OperationalFeedbackNormalization.normalize_resource_availability_aliases()
            |> OperationalFeedbackNormalization.copy_resource_availability_status_alias(
              "spacecraft_available",
              "status"
            )

          Map.get(state, "spacecraft_available", true) != false and
            Map.get(state, "mode", "nominal") not in ["degraded", "degraded_mode", "safe"] and
            not ScalarValues.truthy?(Map.get(state, "degraded"))
        end)

      available / length(states)
    end
  end

  defp payload_availability(mission_state) do
    states = Map.get(mission_state, "spacecraft_states", [])

    if states == [] do
      1.0
    else
      available =
        Enum.count(states, fn state ->
          state =
            state
            |> ValueEncoding.stringify_keys()
            |> OperationalFeedbackNormalization.normalize_resource_availability_aliases()

          Map.get(state, "payload_available", true) != false and
            not ScalarValues.truthy?(Map.get(state, "payload_degraded"))
        end)

      available / length(states)
    end
  end

  defp antenna_availability(mission_state) do
    states = Map.get(mission_state, "spacecraft_states", [])

    if states == [] do
      1.0
    else
      available =
        Enum.count(states, fn state ->
          state =
            state
            |> ValueEncoding.stringify_keys()
            |> OperationalFeedbackNormalization.normalize_resource_availability_aliases()

          Map.get(state, "antenna_available", true) != false and
            not ScalarValues.truthy?(Map.get(state, "antenna_degraded"))
        end)

      available / length(states)
    end
  end

  defp maybe_resource_risk(risks, _type, nil, _threshold, _reason), do: risks
  defp maybe_resource_risk(risks, _type, _value, nil, _reason), do: risks

  defp maybe_resource_risk(risks, type, value, threshold, reason) when value < threshold do
    [%{"type" => type, "severity" => "medium", "reason" => reason, "value" => value} | risks]
  end

  defp maybe_resource_risk(risks, _type, _value, _threshold, _reason), do: risks

  defp resource_margin_score(nil, _threshold), do: 0.0
  defp resource_margin_score(_value, nil), do: 0.0

  defp resource_margin_score(value, threshold) when value < threshold,
    do: -(threshold - value) * 100.0

  defp resource_margin_score(value, threshold), do: min(value - threshold, 1.0) * 10.0
end
