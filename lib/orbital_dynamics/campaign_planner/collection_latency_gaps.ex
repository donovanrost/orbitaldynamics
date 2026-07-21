defmodule OrbitalDynamics.CampaignPlanner.CollectionLatencyGaps do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.ActivityIdentity
  alias OrbitalDynamics.CampaignPlanner.ActivityTiming
  alias OrbitalDynamics.CampaignPlanner.CollectionLatencyDownlinks
  alias OrbitalDynamics.CampaignPlanner.CollectionLatencyIdentity
  alias OrbitalDynamics.CampaignPlanner.CollectionLatencyMaps
  alias OrbitalDynamics.CampaignPlanner.CollectionLatencyObjectives
  alias OrbitalDynamics.CampaignPlanner.DownlinkActivityNormalization
  alias OrbitalDynamics.CampaignPlanner.DownlinkActivityThroughput
  alias OrbitalDynamics.CampaignPlanner.DownlinkObjectiveRequirements
  alias OrbitalDynamics.CampaignPlanner.FeedbackNumericValues
  alias OrbitalDynamics.CampaignPlanner.ProviderResultValues
  alias OrbitalDynamics.CampaignPlanner.PriorActivityContext
  alias OrbitalDynamics.CampaignPlanner.RealizedActivitySuccessValues
  alias OrbitalDynamics.CampaignPlanner.RealizedDownlinkEvents
  alias OrbitalDynamics.CampaignPlanner.RealizedDownlinkDemandFeedback
  alias OrbitalDynamics.CampaignPlanner.RepairRealizedState
  alias OrbitalDynamics.CampaignPlanner.TargetObjectiveRealizedObservations
  alias OrbitalDynamics.CollectionLatencyObjectiveType

  @realized_completion_statuses ~w(completed executed)
  @realized_failure_statuses ~w(missed failed canceled cancelled rejected)
  @realized_feedback_match_statuses ~w(matched)
  @realized_statuses @realized_completion_statuses ++ @realized_failure_statuses ++ ~w(delayed)

  def gaps(objective, activities, mission_state, prior_plan) do
    max_latency_s = CollectionLatencyObjectives.limit_s(objective)
    required_downlink_mb = objective_required_downlink_mb(objective)

    no_data_observation_ids =
      realized_observation_without_collected_data_ids(mission_state, prior_plan)

    realized_downlinks =
      mission_state
      |> realized_downlink_events(prior_plan)
      |> Enum.filter(&downlink_match?(&1, objective))

    downlinks =
      activities
      |> Enum.filter(&downlink_activity?/1)

    activities
    |> Enum.filter(&CollectionLatencyIdentity.observation_match?(&1, objective))
    |> Enum.reject(&MapSet.member?(no_data_observation_ids, &1["id"]))
    |> Enum.map(fn observation ->
      feedback =
        downlink_feedback(objective, observation, max_latency_s, realized_downlinks)

      missed_ids = MapSet.new(feedback["source_activity_ids"])
      available_downlinks = Enum.reject(downlinks, &MapSet.member?(missed_ids, &1["id"]))

      latency =
        CollectionLatencyDownlinks.next_latency_s(
          observation,
          available_downlinks,
          objective
        )

      planned_latency_downlinks =
        CollectionLatencyDownlinks.planned_downlinks(
          observation,
          available_downlinks,
          objective,
          max_latency_s
        )

      planned_downlink_mb =
        planned_latency_downlinks
        |> Enum.map(&DownlinkActivityThroughput.mb/1)
        |> Enum.sum()

      if is_nil(latency) or latency > max_latency_s or
           CollectionLatencyDownlinks.volume_gap?(planned_downlink_mb, required_downlink_mb) do
        gap_event(
          objective,
          observation,
          max_latency_s,
          latency,
          feedback,
          planned_downlink_mb,
          length(planned_latency_downlinks),
          required_downlink_mb
        )
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.sort_by(&{&1["ends_at_s"], &1["source_activity_id"]})
  end

  defp realized_observation_without_collected_data_ids(mission_state, prior_plan) do
    failure_ids =
      mission_state
      |> realized_observation_events(prior_plan)
      |> Enum.map(& &1["id"])

    no_data_ids =
      mission_state
      |> Map.get("realized_activities", [])
      |> Enum.map(&CollectionLatencyMaps.stringify_keys/1)
      |> PriorActivityContext.enrich(prior_plan)
      |> Enum.filter(&realized_observation_without_collected_data?/1)
      |> Enum.map(& &1["id"])

    (failure_ids ++ no_data_ids)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> MapSet.new()
  end

  defp realized_observation_without_collected_data?(activity) do
    type = Map.get(activity, "type") || Map.get(activity, "activity_type")
    demand_mb = observation_downlink_demand_mb(activity)

    type == "observe" and observation_success_value(activity) == 0.0 and
      (is_nil(demand_mb) or demand_mb <= 0.0)
  end

  defp downlink_feedback(objective, observation, max_latency_s, realized_downlinks) do
    event = CollectionLatencyDownlinks.event(objective, observation)

    realized =
      realized_downlinks
      |> Enum.filter(&CollectionLatencyDownlinks.event_match?(&1, event))
      |> Enum.filter(fn downlink ->
        latency_s = activity_start(downlink) - activity_end(observation)
        latency_s >= 0.0 and latency_s <= max_latency_s
      end)

    %{
      "source_activity_ids" =>
        realized
        |> Enum.map(& &1["id"])
        |> Enum.reject(&(&1 in [nil, ""]))
        |> Enum.uniq()
        |> Enum.sort(),
      "statuses" =>
        realized
        |> Enum.map(& &1["status"])
        |> Enum.reject(&(&1 in [nil, ""]))
        |> Enum.uniq()
        |> Enum.sort(),
      "contact_results" =>
        realized
        |> Enum.flat_map(&ProviderResultValues.values(&1["contact_result"]))
        |> Enum.uniq()
        |> Enum.sort()
    }
  end

  defp downlink_match?(downlink, objective) do
    station_id = ground_station_id(objective)
    scenario_id = Map.get(objective, "scenario_id")

    downlink_activity?(downlink) and
      (is_nil(station_id) or ground_station_id(downlink) == station_id) and
      (is_nil(scenario_id) or downlink["scenario_id"] == scenario_id)
  end

  defp gap_event(
         objective,
         observation,
         max_latency_s,
         planned_latency_s,
         feedback,
         planned_downlink_mb,
         planned_contacts,
         required_downlink_mb
       ) do
    observation_end_s = activity_end(observation)

    CollectionLatencyMaps.compact_map(%{
      "type" => "downlink_completion_gap",
      "objective_type" => CollectionLatencyObjectiveType.canonical(objective["type"]),
      "objective_id" => objective["id"],
      "latency_objective" => true,
      "target_id" => observation["target_id"],
      "scenario_id" => Map.get(objective, "scenario_id") || observation["scenario_id"],
      "ground_station_id" => ground_station_id(objective),
      "collection_id" =>
        CollectionLatencyIdentity.identity_value(objective, observation, "collection_id"),
      "product_id" =>
        CollectionLatencyIdentity.identity_value(objective, observation, "product_id"),
      "product_ids" => CollectionLatencyIdentity.product_ids(objective, observation),
      "payload_id" =>
        CollectionLatencyIdentity.identity_value(objective, observation, "payload_id"),
      "instrument_id" =>
        CollectionLatencyIdentity.identity_value(objective, observation, "instrument_id"),
      "starts_at_s" => observation_end_s,
      "ends_at_s" => observation_end_s + max_latency_s,
      "required_contacts" => 1,
      "planned_contacts" => planned_contacts,
      "required_downlink_mb" => required_downlink_mb,
      "planned_downlink_mb" => planned_downlink_mb,
      "max_latency_s" => max_latency_s,
      "planned_latency_s" => planned_latency_s,
      "source_activity_id" => observation["id"],
      "source_activity_ids" => [observation["id"]],
      "realized_status" => join_or_nil(feedback["statuses"]),
      "contact_result" => join_or_nil(feedback["contact_results"]),
      "missed_downlink_activity_id" => List.first(feedback["source_activity_ids"]),
      "missed_downlink_activity_ids" => feedback["source_activity_ids"],
      "derivation_reasons" =>
        ["collection_latency_gap"] ++
          Enum.map(feedback["statuses"], &"realized_downlink_#{&1}") ++
          Enum.map(feedback["contact_results"], &"realized_downlink_contact_result_#{&1}")
    })
  end

  defp objective_required_downlink_mb(%{} = objective) do
    DownlinkObjectiveRequirements.required_mb(
      objective,
      downlink_objective_requirement_callbacks()
    )
  end

  defp objective_required_downlink_mb(_objective), do: nil

  defp activity_start(activity),
    do: ActivityTiming.activity_start(activity, activity_timing_callbacks())

  defp activity_end(activity),
    do: ActivityTiming.activity_end(activity, activity_timing_callbacks())

  defp activity_raw_start(activity),
    do: ActivityTiming.activity_raw_start(activity, activity_timing_callbacks())

  defp activity_raw_end(activity),
    do: ActivityTiming.activity_raw_end(activity, activity_timing_callbacks())

  defp activity_timing_callbacks, do: [numeric_or_nil: &numeric_or_nil/1]

  defp ground_station_id(activity), do: ActivityIdentity.ground_station_id(activity)

  defp downlink_activity?(activity) do
    DownlinkActivityNormalization.downlink?(
      activity,
      downlink_activity_normalization_callbacks()
    )
  end

  defp downlink_activity_normalization_callbacks,
    do: [
      activity_ground_station_id: &ground_station_id/1,
      activity_raw_start: &activity_raw_start/1,
      activity_raw_end: &activity_raw_end/1
    ]

  defp observation_downlink_demand_mb(activity) do
    RealizedDownlinkDemandFeedback.observation_mb(
      activity,
      observation_downlink_demand_callbacks()
    )
  end

  defp observation_downlink_demand_callbacks,
    do: [
      feedback_value_missing?: &feedback_value_missing?/1,
      numeric_or_nil: &numeric_or_nil/1
    ]

  defp feedback_value_missing?(nil), do: true
  defp feedback_value_missing?(""), do: true
  defp feedback_value_missing?(_value), do: false

  defp observation_success_value(activity) do
    RealizedActivitySuccessValues.observation(
      activity,
      realized_activity_success_value_callbacks()
    )
  end

  defp realized_activity_success_value_callbacks,
    do: [
      json_boolean_value: &json_boolean_value/1,
      provider_result_success_value: &ProviderResultValues.success_value/1,
      completed_fraction_success_value: &completed_fraction_success_value/2,
      failure_statuses: @realized_failure_statuses,
      completion_statuses: @realized_completion_statuses
    ]

  defp completed_fraction_success_value(activity, default) do
    FeedbackNumericValues.completed_fraction_success_value(
      activity,
      default,
      observation_feedback_numeric_callbacks()
    )
  end

  defp observation_feedback_numeric_callbacks,
    do: [
      feedback_value_missing?: &feedback_value_missing?/1,
      numeric_or_nil: &numeric_or_nil/1
    ]

  defp json_boolean_value(value) when is_boolean(value), do: value

  defp json_boolean_value(value) when is_number(value) do
    cond do
      value == 1 -> true
      value == 0 -> false
      true -> nil
    end
  end

  defp json_boolean_value(value) when is_binary(value) do
    case String.downcase(String.trim(value)) do
      "true" -> true
      "1" -> true
      "false" -> false
      "0" -> false
      _value -> nil
    end
  end

  defp json_boolean_value(_value), do: nil

  defp realized_observation_events(mission_state, prior_plan) do
    TargetObjectiveRealizedObservations.events(
      mission_state,
      prior_plan,
      target_objective_realized_observation_callbacks()
    )
  end

  defp target_objective_realized_observation_callbacks,
    do: [
      failure_statuses: @realized_failure_statuses,
      numeric_or_nil: &numeric_or_nil/1
    ]

  defp realized_downlink_events(mission_state, prior_plan) do
    RealizedDownlinkEvents.events(
      mission_state,
      prior_plan,
      realized_downlink_event_callbacks()
    )
  end

  defp realized_downlink_event_callbacks,
    do: [
      downlink_activity?: &downlink_activity?/1,
      normalize_realized_status_value: &RepairRealizedState.normalize_status_value/1,
      normalize_realized_activity_status: &normalize_realized_activity_status/2,
      provider_result_success_value: &ProviderResultValues.success_value/1,
      realized_failure_statuses: @realized_failure_statuses,
      realized_completion_statuses: @realized_completion_statuses
    ]

  defp normalize_realized_activity_status(status, realized_status) do
    RepairRealizedState.activity_status(
      status,
      realized_status,
      realized_activity_status_callbacks()
    )
  end

  defp realized_activity_status_callbacks,
    do: [
      realized_statuses: @realized_statuses,
      feedback_match_statuses: @realized_feedback_match_statuses
    ]

  defp downlink_objective_requirement_callbacks,
    do: [objective_number_from_fields: &objective_number_from_fields/2]

  defp join_or_nil([]), do: nil
  defp join_or_nil(values), do: Enum.join(values, ",")

  defp objective_number_from_fields(objective, fields) do
    Enum.find_value(fields, fn field ->
      case numeric_or_nil(Map.get(objective, field)) do
        value when is_number(value) -> value
        _value -> nil
      end
    end)
  end

  defp numeric_or_nil(nil), do: nil
  defp numeric_or_nil(value) when is_integer(value) or is_float(value), do: value

  defp numeric_or_nil(value) when is_binary(value) do
    case Float.parse(value) do
      {number, ""} -> number
      _error -> nil
    end
  end

  defp numeric_or_nil(_value), do: nil
end
