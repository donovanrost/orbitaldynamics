defmodule OrbitalDynamics.CampaignPlanner.BranchEventApplication do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ActivityIdentity,
    ActivityTiming,
    BranchEventNormalizer,
    BranchOperationalFeedback,
    BranchRefreshGroundNetwork,
    DerivedDegradedSpacecraftBranches,
    DownlinkActivityNormalization,
    PriorActivityContext,
    RepairActivityIdentity,
    RepairRealizedState,
    ScalarValues,
    ValueEncoding
  }

  def apply_plan(prior_plan, branch) do
    Enum.reduce(branch["events"], prior_plan, fn event, plan ->
      case event["type"] do
        type when type in ["ground_station_outage", "ground_station_reserved"] ->
          update_candidate_activities(plan, fn activities ->
            Enum.reject(activities, &ground_station_event_match?(&1, event))
          end)

        "reduced_downlink_capacity" ->
          update_candidate_activities(plan, fn activities ->
            Enum.map(activities, &apply_downlink_capacity(&1, event))
          end)

        _type ->
          plan
      end
    end)
  end

  def apply_realized(realized_state, prior_plan, branch) do
    Enum.reduce(branch["events"], realized_state, fn event, state ->
      case event["type"] do
        type when type in ["ground_station_outage", "ground_station_reserved"] ->
          prior_plan
          |> PriorActivityContext.activities()
          |> Enum.filter(&ground_station_event_match?(&1, event))
          |> Enum.reduce(state, fn activity, acc ->
            add_realized_activity(
              acc,
              %{
                "id" => ActivityIdentity.activity_id(ValueEncoding.stringify_keys(activity)),
                "status" => "missed",
                "reason" => branch_ground_station_event_reason(type)
              }
              |> Map.merge(branch_ground_station_realized_context(event, type))
            )
          end)

        "degraded_spacecraft" ->
          add_spacecraft_state(state, %{
            "scenario_id" => spacecraft_id(event),
            "mode" => degraded_mode(event),
            "incompatible_activity_types" =>
              event
              |> degradation_activity_types()
              |> BranchOperationalFeedback.normalize_incompatible_activity_types()
          })

        "missed_maneuver" ->
          add_realized_activity(state, %{
            "id" => event["activity_id"],
            "status" => "missed",
            "reason" => "branch_missed_maneuver"
          })

        "delayed_maneuver" ->
          add_realized_activity(state, %{
            "id" => event["activity_id"],
            "status" => "delayed",
            "actual_starts_at_s" => event["actual_starts_at_s"],
            "actual_ends_at_s" => event["actual_ends_at_s"] || event["actual_starts_at_s"],
            "reason" => "branch_delayed_maneuver"
          })

        _type ->
          state
      end
    end)
  end

  defp branch_ground_station_event_reason("ground_station_reserved"),
    do: "branch_ground_station_reserved"

  defp branch_ground_station_event_reason(_type), do: "branch_ground_station_outage"

  defp branch_ground_station_realized_context(event, type) do
    %{
      "ground_station_id" => BranchEventNormalizer.ground_station_id(event),
      "station_availability" => branch_ground_station_event_availability(type),
      "station_calendar_entry_id" => event["station_calendar_entry_id"],
      "station_calendar_provider_id" => event["station_calendar_provider_id"],
      "station_calendar_provider_entry_id" => event["station_calendar_provider_entry_id"],
      "station_calendar_directions" => event["station_calendar_directions"],
      "station_calendar_status" => event["station_calendar_status"],
      "station_contention_status" =>
        if(type == "ground_station_reserved", do: "reserved_overlap"),
      "station_reservation_id" => event["station_reservation_id"] || event["reservation_id"],
      "station_reserved_by" => event["station_reserved_by"] || event["reserved_by"],
      "station_reservation_status" =>
        event["station_reservation_status"] || event["reservation_status"],
      "station_reservation_match_status" => event["station_reservation_match_status"],
      "station_calendar_trust_boundary_status" => event["station_calendar_trust_boundary_status"],
      "trust_boundary" => event["trust_boundary"],
      "provenance" => event["provenance"]
    }
    |> ValueEncoding.compact_map()
  end

  defp branch_ground_station_event_availability("ground_station_reserved"), do: "reserved"
  defp branch_ground_station_event_availability(_type), do: "unavailable"

  defp update_candidate_activities(plan, fun) do
    Map.update(plan, "candidate_activities", [], fn activities ->
      activities
      |> Enum.map(&ValueEncoding.stringify_keys/1)
      |> fun.()
    end)
  end

  defp apply_downlink_capacity(activity, event) do
    activity = ValueEncoding.stringify_keys(activity)

    if DownlinkActivityNormalization.downlink?(activity) and
         branch_event_activity_match?(activity, event) and event_overlap?(activity, event) do
      fraction = BranchRefreshGroundNetwork.ground_network_capacity_fraction(event)
      score = candidate_score(activity) * fraction

      activity
      |> Map.put("score", score)
      |> Map.put("capacity_fraction", fraction)
      |> put_station_capacity(fraction)
      |> Map.update("score_terms", %{}, fn terms ->
        Map.put(terms, "capacity_factor", fraction)
      end)
    else
      activity
    end
  end

  defp put_station_capacity(activity, 1.0), do: activity

  defp put_station_capacity(activity, capacity_fraction) do
    activity
    |> Map.put("station_capacity_fraction", capacity_fraction)
    |> Map.update(
      "throughput_model",
      %{"station_capacity_fraction" => capacity_fraction},
      fn model ->
        Map.put(model, "station_capacity_fraction", capacity_fraction)
      end
    )
  end

  defp ground_station_event_match?(activity, event) do
    activity = ValueEncoding.stringify_keys(activity)

    station_event_suppressed_activity?(activity) and branch_event_activity_match?(activity, event) and
      event_overlap?(activity, event)
  end

  defp station_event_suppressed_activity?(activity) do
    type = Map.get(activity, "type") || Map.get(activity, "activity_type")
    direction = activity_direction(activity)

    DownlinkActivityNormalization.downlink?(activity) or
      type in ["tracking", "health_check"] or
      (type in ["planned_contact", "contact"] and direction in ["tracking", "health_check"])
  end

  defp branch_event_activity_match?(activity, event) do
    event_station_id = BranchEventNormalizer.ground_station_id(event)

    station_match? =
      is_nil(event_station_id) or
        RepairActivityIdentity.ground_station_id(activity) == event_station_id

    scenario_match? =
      is_nil(event["scenario_id"]) or activity["scenario_id"] == event["scenario_id"]

    station_match? and scenario_match?
  end

  defp event_overlap?(activity, event) do
    event_start = Map.get(event, "starts_at_s", ActivityTiming.activity_start(activity))
    event_end = Map.get(event, "ends_at_s", ActivityTiming.activity_end(activity))

    ActivityTiming.activity_start(activity) < event_end and
      event_start < ActivityTiming.activity_end(activity)
  end

  def merge_realized_state(realized_state, overrides) do
    overrides = RepairRealizedState.normalize(overrides || %{})

    %{
      "activities" =>
        merge_by_id(
          Map.get(realized_state, "activities", []),
          Map.get(overrides, "activities", [])
        ),
      "spacecraft_states" =>
        merge_spacecraft_states(
          Map.get(realized_state, "spacecraft_states", []),
          Map.get(overrides, "spacecraft_states", [])
        ),
      "metadata" =>
        Map.merge(Map.get(realized_state, "metadata", %{}), Map.get(overrides, "metadata", %{}))
    }
  end

  def mission_state_repair_state(mission_state) do
    %{
      "activities" => Map.get(mission_state, "realized_activities", []),
      "spacecraft_states" =>
        mission_state
        |> DerivedDegradedSpacecraftBranches.states()
        |> merge_spacecraft_states([]),
      "metadata" => %{
        "mission_state_snapshot_id" => Map.get(mission_state, "snapshot_id")
      }
    }
  end

  defp degradation_activity_types(degradation) do
    explicit =
      Map.get(degradation, "incompatible_activity_types") ||
        Map.get(degradation, "suppressed_activity_types")

    cond do
      explicit not in [nil, []] ->
        explicit

      Map.get(degradation, "spacecraft_available") == false or
          Map.get(degradation, "spacecraft_availability") == false ->
        ["downlink", "observe", "planned_contact"]

      true ->
        ["observe"]
    end
  end

  def degraded_mode(event) do
    case ValueEncoding.encode_value(Map.get(event, "mode", "degraded")) do
      value when value in [nil, ""] -> "degraded"
      value -> value
    end
  end

  def spacecraft_id(event) do
    case ValueEncoding.encode_value(
           Map.get(event, "spacecraft_id") || Map.get(event, "scenario_id")
         ) do
      value when value in [nil, ""] -> nil
      value -> value
    end
  end

  defp merge_by_id(left, right) do
    (left ++ right)
    |> Enum.map(&ValueEncoding.stringify_keys/1)
    |> Enum.sort_by(&{&1["id"], &1["status"] || "", &1["reason"] || ""})
  end

  defp merge_spacecraft_states(left, right) do
    (left ++ right)
    |> RepairRealizedState.spacecraft_states()
    |> elem(0)
    |> Map.new(fn item -> {Map.get(item, "scenario_id"), item} end)
    |> Map.values()
    |> Enum.sort_by(& &1["scenario_id"])
  end

  defp add_realized_activity(realized_state, activity) do
    activity = RepairRealizedState.activity(activity)

    Map.update!(realized_state, "activities", fn activities ->
      merge_by_id(activities, [activity])
    end)
  end

  defp add_spacecraft_state(realized_state, spacecraft_state) do
    spacecraft_state = ValueEncoding.stringify_keys(spacecraft_state)

    Map.update!(realized_state, "spacecraft_states", fn states ->
      merge_spacecraft_states(states, [spacecraft_state])
    end)
  end

  defp activity_direction(activity),
    do: ScalarValues.normalized_status_token(Map.get(activity, "direction"))

  defp candidate_score(candidate),
    do: ScalarValues.numeric_or_nil(Map.get(candidate, "score")) || 0.0
end
