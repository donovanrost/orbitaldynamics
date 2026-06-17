defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffObservationPointingLookupFields do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.TimelineDiffObservationPointingTelemetryFields

  def match_status(row, field, callbacks) do
    status =
      callback!(callbacks, :timeline_diff_first_string).(row, [
        field,
        "replacement_#{field}",
        ["replacement_activity_context", field],
        "source_#{field}",
        ["source_activity_context", field]
      ])

    callback!(callbacks, :normalized_status_token).(status)
  end

  def planned_pointing_target_id(row, callbacks) do
    callback!(callbacks, :timeline_diff_first_string).(row, [
      "planned_pointing_target_id",
      "source_pointing_target_id",
      ["source_activity_context", "pointing_target_id"],
      ["source_activity_context", "pointing_target", "id"],
      ["source_activity_context", "pointing_target", "target_id"]
    ])
  end

  def realized_pointing_target_id(row, callbacks) do
    callback!(callbacks, :timeline_diff_first_string).(row, [
      "realized_pointing_target_id",
      "replacement_pointing_target_id",
      ["replacement_activity_context", "pointing_target_id"],
      ["replacement_activity_context", "pointing_target", "id"],
      ["replacement_activity_context", "pointing_target", "target_id"]
    ])
  end

  def planned_pointing_mode(row, callbacks) do
    status =
      callback!(callbacks, :timeline_diff_first_string).(row, [
        "planned_pointing_mode",
        "source_pointing_mode",
        ["source_activity_context", "pointing_mode"]
      ])

    callback!(callbacks, :normalized_status_token).(status)
  end

  def realized_pointing_mode(row, callbacks) do
    status =
      callback!(callbacks, :timeline_diff_first_string).(row, [
        "realized_pointing_mode",
        "replacement_pointing_mode",
        ["replacement_activity_context", "pointing_mode"]
      ])

    callback!(callbacks, :normalized_status_token).(status)
  end

  def pointing_status(row, callbacks) do
    TimelineDiffObservationPointingTelemetryFields.pointing_status(row, callbacks)
  end

  def pointing_error_deg(row, callbacks) do
    TimelineDiffObservationPointingTelemetryFields.pointing_error_deg(row, callbacks)
  end

  def pointing_model(row, callbacks) do
    TimelineDiffObservationPointingTelemetryFields.pointing_model(row, callbacks)
  end

  def pointing_source(row, callbacks) do
    TimelineDiffObservationPointingTelemetryFields.pointing_source(row, callbacks)
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
