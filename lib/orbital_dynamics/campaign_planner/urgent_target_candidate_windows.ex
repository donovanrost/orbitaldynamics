defmodule OrbitalDynamics.CampaignPlanner.UrgentTargetCandidateWindows do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{ActivityTiming, ValueEncoding}

  def windows(event, request, source_candidate_activities),
    do: windows(event, request, source_candidate_activities, default_callbacks())

  def windows(event, request, source_candidate_activities, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    dedupe_by_id = Keyword.fetch!(callbacks, :dedupe_by_id)
    target_id = event["target_id"] || event["id"] || "urgent_target"

    event_windows =
      event
      |> Map.get("candidate_windows", [])
      |> Enum.map(&event_window(&1, target_id, callbacks))

    plan_windows =
      request.prior_plan
      |> Map.get("candidate_activities", [])
      |> Enum.map(&stringify_keys.(&1))
      |> Enum.filter(&(&1["type"] == "observe" and &1["target_id"] == target_id))

    source_windows =
      source_candidate_activities
      |> Enum.map(&stringify_keys.(&1))
      |> Enum.filter(&(&1["type"] == "observe" and &1["target_id"] == target_id))

    (event_windows ++ plan_windows ++ source_windows)
    |> dedupe_by_id.()
    |> Enum.filter(&window_match?(&1, event, callbacks))
  end

  def window_match?(candidate, event), do: window_match?(candidate, event, default_callbacks())

  def window_match?(candidate, event, callbacks) do
    activity_start = Keyword.fetch!(callbacks, :activity_start)
    activity_end = Keyword.fetch!(callbacks, :activity_end)
    starts_at_s = Map.get(event, "starts_at_s") || Map.get(event, "start_s")
    ends_at_s = Map.get(event, "ends_at_s") || Map.get(event, "end_s")

    (not is_number(starts_at_s) or activity_start.(candidate) >= starts_at_s) and
      (not is_number(ends_at_s) or activity_end.(candidate) <= ends_at_s)
  end

  def spacecraft_match?(activity, event) do
    allowed =
      event["spacecraft_constraints"] || event["allowed_scenario_ids"] ||
        event["allowed_spacecraft_ids"]

    scenario_id = event["scenario_id"]

    cond do
      is_binary(scenario_id) -> activity["scenario_id"] == scenario_id
      is_list(allowed) -> activity["scenario_id"] in allowed
      true -> true
    end
  end

  defp default_callbacks,
    do: [
      stringify_keys: &ValueEncoding.stringify_keys/1,
      activity_start: &ActivityTiming.activity_start/1,
      activity_end: &ActivityTiming.activity_end/1,
      dedupe_by_id: &dedupe_by_id/1
    ]

  defp event_window(window, target_id, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    activity_start = Keyword.fetch!(callbacks, :activity_start)
    activity_end = Keyword.fetch!(callbacks, :activity_end)

    window
    |> stringify_keys.()
    |> Map.put_new("type", "observe")
    |> Map.put_new("target_id", target_id)
    |> Map.put_new("id", "urgent_candidate_#{target_id}_#{Map.get(window, "starts_at_s", 0.0)}")
    |> Map.put_new(
      "source_window",
      Map.put(stringify_keys.(window), "type", "mission_state_candidate_window")
    )
    |> Map.put_new("duration_s", activity_end.(window) - activity_start.(window))
  end

  defp dedupe_by_id(items) do
    items
    |> Map.new(&{&1["id"], &1})
    |> Map.values()
    |> Enum.sort_by(& &1["id"])
  end
end
