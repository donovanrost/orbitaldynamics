defmodule OrbitalDynamics.CampaignPlanner.CollectionLatencySatisfaction do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.ActivityIdentity
  alias OrbitalDynamics.CampaignPlanner.ActivityTiming
  alias OrbitalDynamics.CampaignPlanner.DownlinkActivityNormalization
  alias OrbitalDynamics.CampaignPlanner.DownlinkActivityThroughput
  alias OrbitalDynamics.CampaignPlanner.CollectionLatencyDownlinks
  alias OrbitalDynamics.CampaignPlanner.CollectionLatencyIdentity
  alias OrbitalDynamics.CampaignPlanner.CollectionLatencyMaps
  alias OrbitalDynamics.CampaignPlanner.CollectionLatencyObjectives
  alias OrbitalDynamics.CampaignPlanner.DownlinkObjectiveRequirements

  def put(satisfaction, activities, mission_state) do
    objectives = objectives(mission_state)

    if objectives == [] do
      satisfaction
    else
      rows =
        objectives
        |> Enum.flat_map(&rows(activities, &1))
        |> Enum.sort_by(&{&1["source_activity_id"], &1["objective_id"] || ""})

      satisfied_count = Enum.count(rows, &(&1["status"] == "satisfied"))
      total_count = length(rows)

      Map.put(satisfaction, "collection_latency", %{
        "objective_count" => length(objectives),
        "observation_count" => total_count,
        "satisfied_observation_count" => satisfied_count,
        "unsatisfied_observation_count" => total_count - satisfied_count,
        "ratio" => if(total_count > 0, do: satisfied_count / total_count, else: 1.0),
        "rows" => rows
      })
    end
  end

  defp objectives(mission_state) do
    mission_state
    |> Map.get("objectives", [])
    |> Enum.map(&CollectionLatencyMaps.stringify_keys/1)
    |> Enum.filter(&CollectionLatencyObjectives.objective?/1)
  end

  defp rows(activities, objective) do
    max_latency_s = CollectionLatencyObjectives.limit_s(objective)
    required_downlink_mb = objective_required_downlink_mb(objective)

    observations =
      Enum.filter(activities, &CollectionLatencyIdentity.observation_match?(&1, objective))

    downlinks = Enum.filter(activities, &downlink_activity?/1)

    observations
    |> Enum.map(fn observation ->
      latency_s =
        CollectionLatencyDownlinks.next_latency_s(
          observation,
          downlinks,
          objective
        )

      planned_downlinks =
        CollectionLatencyDownlinks.planned_downlinks(
          observation,
          downlinks,
          objective,
          max_latency_s
        )

      planned_downlink_mb =
        planned_downlinks
        |> Enum.map(&DownlinkActivityThroughput.mb/1)
        |> Enum.sum()

      latency_met? = is_number(latency_s) and latency_s <= max_latency_s

      volume_met? =
        not CollectionLatencyDownlinks.volume_gap?(planned_downlink_mb, required_downlink_mb)

      %{
        "objective_id" => Map.get(objective, "id"),
        "source_activity_id" => observation["id"],
        "target_id" => observation["target_id"],
        "scenario_id" => observation["scenario_id"],
        "collection_id" =>
          CollectionLatencyIdentity.identity_value(objective, observation, "collection_id"),
        "product_id" =>
          CollectionLatencyIdentity.identity_value(objective, observation, "product_id"),
        "product_ids" => CollectionLatencyIdentity.product_ids(objective, observation),
        "payload_id" =>
          CollectionLatencyIdentity.identity_value(objective, observation, "payload_id"),
        "instrument_id" =>
          CollectionLatencyIdentity.identity_value(objective, observation, "instrument_id"),
        "status" => if(latency_met? and volume_met?, do: "satisfied", else: "unsatisfied"),
        "max_latency_s" => max_latency_s,
        "planned_latency_s" => latency_s,
        "required_downlink_mb" => required_downlink_mb,
        "planned_downlink_mb" => planned_downlink_mb,
        "planned_contacts" => length(planned_downlinks)
      }
      |> CollectionLatencyMaps.compact_map()
    end)
  end

  defp objective_required_downlink_mb(%{} = objective) do
    DownlinkObjectiveRequirements.required_mb(
      objective,
      downlink_objective_requirement_callbacks()
    )
  end

  defp objective_required_downlink_mb(_objective), do: nil

  defp downlink_objective_requirement_callbacks,
    do: [objective_number_from_fields: &objective_number_from_fields/2]

  defp objective_number_from_fields(objective, fields) do
    Enum.find_value(fields, fn field ->
      case numeric_or_nil(Map.get(objective, field)) do
        value when is_number(value) -> value
        _value -> nil
      end
    end)
  end

  defp downlink_activity?(activity) do
    DownlinkActivityNormalization.downlink?(
      activity,
      downlink_activity_normalization_callbacks()
    )
  end

  defp downlink_activity_normalization_callbacks,
    do: [
      activity_ground_station_id: &ActivityIdentity.ground_station_id/1,
      activity_raw_start: &activity_raw_start/1,
      activity_raw_end: &activity_raw_end/1
    ]

  defp activity_raw_start(activity),
    do: ActivityTiming.activity_raw_start(activity, activity_timing_callbacks())

  defp activity_raw_end(activity),
    do: ActivityTiming.activity_raw_end(activity, activity_timing_callbacks())

  defp activity_timing_callbacks, do: [numeric_or_nil: &numeric_or_nil/1]

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
