defmodule OrbitalDynamics.CampaignPlanner.TargetObjectiveSchedule do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    PriorActivityContext,
    TargetObjectiveRealizedObservations,
    UrgentTargetCandidateWindows
  }

  def scheduled_counts(prior_plan, mission_state),
    do: scheduled_counts(prior_plan, mission_state, default_callbacks())

  def scheduled_counts(prior_plan, mission_state, callbacks) do
    realized_observation_events = Keyword.fetch!(callbacks, :realized_observation_events)

    missed_by_target =
      mission_state
      |> realized_observation_events.(prior_plan)
      |> Enum.map(& &1["target_id"])
      |> Enum.reject(&(&1 in [nil, ""]))
      |> Enum.frequencies()

    prior_plan
    |> Map.get("activities", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.filter(&(&1["type"] == "observe"))
    |> Enum.map(& &1["target_id"])
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.frequencies()
    |> Map.new(fn {target_id, count} ->
      {target_id, max(count - Map.get(missed_by_target, target_id, 0), 0)}
    end)
  end

  def scheduled_count(objective, prior_plan, mission_state, scheduled_target_counts),
    do:
      scheduled_count(
        objective,
        prior_plan,
        mission_state,
        scheduled_target_counts,
        default_callbacks()
      )

  def scheduled_count(objective, prior_plan, mission_state, scheduled_target_counts, callbacks) do
    target_id = Map.get(objective, "target_id") || Map.get(objective, "id")

    if scoped_objective?(objective) do
      realized_observation_events = Keyword.fetch!(callbacks, :realized_observation_events)
      prior_plan_activities = Keyword.fetch!(callbacks, :prior_plan_activities)

      missed_ids =
        mission_state
        |> realized_observation_events.(prior_plan)
        |> Enum.filter(&activity_match?(&1, objective, callbacks))
        |> Enum.map(& &1["id"])
        |> Enum.reject(&(&1 in [nil, ""]))
        |> MapSet.new()

      prior_plan
      |> prior_plan_activities.()
      |> Enum.map(&stringify_keys/1)
      |> Enum.reject(&MapSet.member?(missed_ids, &1["id"]))
      |> Enum.count(&activity_match?(&1, objective, callbacks))
    else
      Map.get(scheduled_target_counts, target_id, 0)
    end
  end

  def scoped_observation_count(activities, event),
    do: scoped_observation_count(activities, event, default_callbacks())

  def scoped_observation_count(activities, event, callbacks) do
    activities
    |> Enum.map(&stringify_keys/1)
    |> Enum.count(&activity_match?(&1, event, callbacks))
  end

  def activity_match?(activity, objective),
    do: activity_match?(activity, objective, default_callbacks())

  def activity_match?(activity, objective, callbacks) do
    urgent_target_spacecraft_match? = Keyword.fetch!(callbacks, :urgent_target_spacecraft_match?)
    target_event_window_match? = Keyword.fetch!(callbacks, :target_event_window_match?)
    target_id = Map.get(objective, "target_id") || Map.get(objective, "id")

    activity["type"] == "observe" and
      (is_nil(target_id) or activity["target_id"] == target_id) and
      urgent_target_spacecraft_match?.(activity, objective) and
      target_event_window_match?.(activity, objective)
  end

  defp default_callbacks,
    do: [
      realized_observation_events: &TargetObjectiveRealizedObservations.events/2,
      prior_plan_activities: &PriorActivityContext.activities/1,
      urgent_target_spacecraft_match?: &UrgentTargetCandidateWindows.spacecraft_match?/2,
      target_event_window_match?: &UrgentTargetCandidateWindows.window_match?/2
    ]

  defp scoped_objective?(objective) do
    Enum.any?(
      ["scenario_id", "starts_at_s", "start_s", "ends_at_s", "end_s"],
      &Map.has_key?(objective, &1)
    )
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
