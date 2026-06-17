defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffObservationAttitudeLookupFields do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.TimelineDiffObservationAttitudeTelemetryFields

  def planned_attitude_target_id(row, callbacks) do
    callback!(callbacks, :timeline_diff_first_string).(row, [
      "planned_attitude_target_id",
      "source_attitude_target_id",
      ["source_activity_context", "attitude_target_id"],
      ["source_activity_context", "attitude_target", "id"],
      ["source_activity_context", "attitude_target", "target_id"]
    ])
  end

  def realized_attitude_target_id(row, callbacks) do
    callback!(callbacks, :timeline_diff_first_string).(row, [
      "realized_attitude_target_id",
      "replacement_attitude_target_id",
      ["replacement_activity_context", "attitude_target_id"],
      ["replacement_activity_context", "attitude_target", "id"],
      ["replacement_activity_context", "attitude_target", "target_id"]
    ])
  end

  def planned_attitude_mode(row, callbacks) do
    status =
      callback!(callbacks, :timeline_diff_first_string).(row, [
        "planned_attitude_mode",
        "source_attitude_mode",
        ["source_activity_context", "attitude_mode"]
      ])

    callback!(callbacks, :normalized_status_token).(status)
  end

  def realized_attitude_mode(row, callbacks) do
    status =
      callback!(callbacks, :timeline_diff_first_string).(row, [
        "realized_attitude_mode",
        "replacement_attitude_mode",
        ["replacement_activity_context", "attitude_mode"]
      ])

    callback!(callbacks, :normalized_status_token).(status)
  end

  def attitude_status(row, callbacks) do
    TimelineDiffObservationAttitudeTelemetryFields.attitude_status(row, callbacks)
  end

  def attitude_error_deg(row, callbacks) do
    TimelineDiffObservationAttitudeTelemetryFields.attitude_error_deg(row, callbacks)
  end

  def attitude_model(row, callbacks) do
    TimelineDiffObservationAttitudeTelemetryFields.attitude_model(row, callbacks)
  end

  def attitude_source(row, callbacks) do
    TimelineDiffObservationAttitudeTelemetryFields.attitude_source(row, callbacks)
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
