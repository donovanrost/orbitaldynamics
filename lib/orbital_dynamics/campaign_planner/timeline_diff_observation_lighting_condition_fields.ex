defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffObservationLightingConditionFields do
  @moduledoc false

  def lighting_condition_match_status(row, callbacks) do
    status =
      callback!(callbacks, :timeline_diff_first_string).(row, [
        "lighting_condition_match_status",
        "replacement_lighting_condition_match_status",
        ["replacement_activity_context", "lighting_condition_match_status"],
        "source_lighting_condition_match_status",
        ["source_activity_context", "lighting_condition_match_status"]
      ])

    callback!(callbacks, :normalized_status_token).(status)
  end

  def planned_lighting_condition(row, callbacks) do
    status =
      callback!(callbacks, :timeline_diff_first_string).(row, [
        "planned_lighting_condition",
        "source_lighting_condition",
        ["source_activity_context", "lighting_condition"]
      ])

    callback!(callbacks, :normalized_status_token).(status)
  end

  def realized_lighting_condition(row, callbacks) do
    status =
      callback!(callbacks, :timeline_diff_first_string).(row, [
        "realized_lighting_condition",
        "replacement_lighting_condition",
        ["replacement_activity_context", "realized_lighting_condition"],
        ["replacement_activity_context", "lighting_condition"],
        "lighting_condition",
        "replacement_realized_lighting_condition"
      ])

    callback!(callbacks, :normalized_status_token).(status)
  end

  def lighting_condition_detail(row, callbacks) do
    status =
      callback!(callbacks, :timeline_diff_first_string).(row, [
        "lighting_condition_detail",
        "realized_lighting_condition_detail",
        "replacement_lighting_condition_detail",
        ["replacement_activity_context", "realized_lighting_condition_detail"],
        ["replacement_activity_context", "lighting_condition_detail"],
        "source_lighting_condition_detail",
        ["source_activity_context", "lighting_condition_detail"]
      ])

    callback!(callbacks, :normalized_status_token).(status)
  end

  def lighting_condition_model(row, callbacks) do
    callback!(callbacks, :timeline_diff_first_string).(row, [
      "lighting_condition_model",
      "realized_lighting_condition_model",
      "replacement_lighting_condition_model",
      ["replacement_activity_context", "lighting_condition_model"],
      "source_lighting_condition_model",
      ["source_activity_context", "lighting_condition_model"]
    ])
  end

  def lighting_detail_model(row, callbacks) do
    callback!(callbacks, :timeline_diff_first_string).(row, [
      "lighting_detail_model",
      "realized_lighting_detail_model",
      "replacement_lighting_detail_model",
      ["replacement_activity_context", "lighting_detail_model"],
      "source_lighting_detail_model",
      ["source_activity_context", "lighting_detail_model"]
    ])
  end

  def lighting_confidence(row, callbacks) do
    callback!(callbacks, :timeline_diff_first_string).(row, [
      "lighting_confidence",
      "realized_lighting_confidence",
      "replacement_lighting_confidence",
      ["replacement_activity_context", "lighting_confidence"],
      "source_lighting_confidence",
      ["source_activity_context", "lighting_confidence"]
    ])
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
