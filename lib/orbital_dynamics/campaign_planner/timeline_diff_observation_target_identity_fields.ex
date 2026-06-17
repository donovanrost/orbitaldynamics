defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffObservationTargetIdentityFields do
  @moduledoc false

  def observation_target_match_status(row, callbacks) do
    explicit_observation_target_match_status(row, callbacks) ||
      callback!(callbacks, :timeline_diff_match_status).(
        planned_observation_target_id(row, callbacks),
        realized_observation_target_id(row, callbacks)
      )
  end

  def explicit_observation_target_match_status(row, callbacks) do
    callback!(callbacks, :timeline_diff_first_string).(row, [
      "target_match_status",
      "replacement_target_match_status",
      ["replacement_activity_context", "target_match_status"],
      "source_target_match_status",
      ["source_activity_context", "target_match_status"]
    ])
    |> callback!(callbacks, :normalized_status_token).()
  end

  def planned_observation_target_id(row, callbacks) do
    callback!(callbacks, :timeline_diff_first_stable_id).(row, [
      "planned_target_id",
      "source_planned_target_id",
      "source_target_id",
      ["source_activity_context", "planned_target_id"],
      ["source_activity_context", "target_id"],
      ["source_activity_context", "target", "target_id"],
      ["source_activity_context", "target", "id"],
      ["source_target", "target_id"],
      ["source_target", "id"]
    ])
  end

  def realized_observation_target_id(row, callbacks) do
    callback!(callbacks, :timeline_diff_first_stable_id).(row, [
      "realized_target_id",
      "replacement_realized_target_id",
      "replacement_target_id",
      ["replacement_activity_context", "realized_target_id"],
      ["replacement_activity_context", "target_id"],
      ["replacement_activity_context", "target", "target_id"],
      ["replacement_activity_context", "target", "id"],
      ["replacement_target", "target_id"],
      ["replacement_target", "id"]
    ])
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
