defmodule OrbitalDynamics.CampaignPlanner.OperationalFeedbackPlanningContext do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    BranchRefreshGroundNetwork,
    CommandActivityClassification,
    PriorActivityContext,
    RealizedFeedbackContext,
    ScalarValues,
    ValueEncoding
  }

  def ground_station_ids(mission_state, prior_plan, callbacks \\ default_callbacks()) do
    mission_state_ids =
      [
        Map.get(mission_state, "ground_stations", []),
        Map.get(mission_state, "ground_network", [])
      ]
      |> List.flatten()
      |> Enum.map(&stringify_keys(&1, callbacks))
      |> Enum.map(&ground_network_station_id(&1, callbacks))

    plan_ids =
      [
        prior_plan_activities(prior_plan, callbacks),
        prior_plan_candidate_activities(prior_plan, callbacks),
        prior_plan_proposed_contacts(prior_plan, callbacks)
      ]
      |> List.flatten()
      |> Enum.map(&stringify_keys(&1, callbacks))
      |> Enum.map(&Map.get(&1, "ground_station_id"))

    (mission_state_ids ++ plan_ids)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  def command_activities(prior_plan, callbacks \\ default_callbacks()) do
    prior_plan
    |> prior_plan_activities(callbacks)
    |> Enum.map(&stringify_keys(&1, callbacks))
    |> Enum.filter(&command_activity?(&1, callbacks))
    |> sort_activities()
  end

  def maneuver_activities(prior_plan, callbacks \\ default_callbacks()) do
    prior_plan
    |> prior_plan_activities(callbacks)
    |> Enum.map(&stringify_keys(&1, callbacks))
    |> Enum.filter(&maneuver_activity?(&1, callbacks))
    |> sort_activities()
  end

  def target_ids(mission_state, prior_plan, callbacks \\ default_callbacks()) do
    mission_target_ids =
      [
        Map.get(mission_state, "targets", []),
        Map.get(mission_state, "objectives", [])
      ]
      |> List.flatten()
      |> Enum.map(&stringify_keys(&1, callbacks))
      |> Enum.map(&(Map.get(&1, "target_id") || Map.get(&1, "id")))

    plan_target_ids =
      [
        prior_plan_activities(prior_plan, callbacks),
        prior_plan_candidate_activities(prior_plan, callbacks)
      ]
      |> List.flatten()
      |> Enum.map(&stringify_keys(&1, callbacks))
      |> Enum.map(&Map.get(&1, "target_id"))

    (mission_target_ids ++ plan_target_ids)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  def target_priorities(mission_state, prior_plan, callbacks \\ default_callbacks()) do
    [
      Map.get(mission_state, "targets", []),
      Map.get(mission_state, "objectives", []),
      prior_plan_candidate_activities(prior_plan, callbacks),
      prior_plan_activities(prior_plan, callbacks)
    ]
    |> List.flatten()
    |> Enum.map(&stringify_keys(&1, callbacks))
    |> Enum.reduce(%{}, fn item, acc ->
      target_id = Map.get(item, "target_id") || Map.get(item, "id")

      priority =
        numeric_or_nil(Map.get(item, "priority") || Map.get(item, "target_priority"), callbacks)

      if target_id in [nil, ""] or not is_number(priority) do
        acc
      else
        Map.put_new(acc, target_id, priority)
      end
    end)
  end

  def maneuver_feedback_keys(activity) do
    [
      Map.get(activity, "id"),
      Map.get(activity, "activity_id"),
      Map.get(activity, "planned_activity_id"),
      RealizedFeedbackContext.explicit_timeline_id(activity),
      Map.get(activity, "scenario_id")
    ]
    |> RealizedFeedbackContext.identity_keys()
  end

  def maneuver_feedback_scope(activity, feedback_key) do
    cond do
      feedback_key == Map.get(activity, "id") -> "activity"
      feedback_key == Map.get(activity, "activity_id") -> "activity"
      feedback_key == Map.get(activity, "planned_activity_id") -> "planned_activity"
      feedback_key == RealizedFeedbackContext.explicit_timeline_id(activity) -> "timeline"
      feedback_key == Map.get(activity, "scenario_id") -> "scenario"
      true -> "unknown"
    end
  end

  def command_feedback_keys(activity) do
    [
      Map.get(activity, "id"),
      Map.get(activity, "activity_id"),
      Map.get(activity, "planned_activity_id"),
      RealizedFeedbackContext.explicit_timeline_id(activity),
      Map.get(activity, "scenario_id")
    ]
    |> RealizedFeedbackContext.identity_keys()
  end

  def command_feedback_scope(activity, feedback_key) do
    cond do
      feedback_key == RealizedFeedbackContext.explicit_timeline_id(activity) ->
        "timeline"

      feedback_key == Map.get(activity, "scenario_id") ->
        "scenario"

      true ->
        "activity"
    end
  end

  defp sort_activities(activities) do
    Enum.sort_by(activities, fn activity ->
      {Map.get(activity, "id") || Map.get(activity, "activity_id") || "",
       Map.get(activity, "scenario_id") || ""}
    end)
  end

  defp stringify_keys(value, callbacks) do
    callbacks
    |> Keyword.fetch!(:stringify_keys)
    |> then(& &1.(value))
  end

  defp ground_network_station_id(station, callbacks) do
    callbacks
    |> Keyword.fetch!(:ground_network_station_id)
    |> then(& &1.(station))
  end

  defp prior_plan_activities(prior_plan, callbacks) do
    callbacks
    |> Keyword.fetch!(:prior_plan_activities)
    |> then(& &1.(prior_plan))
  end

  defp prior_plan_candidate_activities(prior_plan, callbacks) do
    callbacks
    |> Keyword.fetch!(:prior_plan_candidate_activities)
    |> then(& &1.(prior_plan))
  end

  defp prior_plan_proposed_contacts(prior_plan, callbacks) do
    callbacks
    |> Keyword.fetch!(:prior_plan_proposed_contacts)
    |> then(& &1.(prior_plan))
  end

  defp command_activity?(activity, callbacks) do
    callbacks
    |> Keyword.fetch!(:command_activity?)
    |> then(& &1.(activity))
  end

  defp maneuver_activity?(activity, callbacks) do
    callbacks
    |> Keyword.fetch!(:maneuver_activity?)
    |> then(& &1.(activity))
  end

  defp numeric_or_nil(value, callbacks) do
    callbacks
    |> Keyword.fetch!(:numeric_or_nil)
    |> then(& &1.(value))
  end

  defp default_callbacks do
    [
      command_activity?: &CommandActivityClassification.command?/1,
      ground_network_station_id: &BranchRefreshGroundNetwork.ground_network_station_id/1,
      maneuver_activity?: &maneuver_activity?/1,
      numeric_or_nil: &ScalarValues.numeric_or_nil/1,
      prior_plan_activities: &PriorActivityContext.activities/1,
      prior_plan_candidate_activities: &PriorActivityContext.candidate_activities/1,
      prior_plan_proposed_contacts: &PriorActivityContext.proposed_contacts/1,
      stringify_keys: &ValueEncoding.stringify_keys/1
    ]
  end

  defp maneuver_activity?(activity), do: activity["type"] in ["maneuver", "impulsive_burn"]
end
