defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffObservationAttitudeTelemetryFields do
  @moduledoc false

  def attitude_status(row, callbacks) do
    status =
      callback!(callbacks, :timeline_diff_first_string).(row, [
        "realized_attitude_status",
        "replacement_realized_attitude_status",
        ["replacement_activity_context", "realized_attitude_status"],
        ["replacement_activity_context", "attitude_status"],
        "attitude_status",
        "replacement_attitude_status",
        "source_realized_attitude_status",
        ["source_activity_context", "realized_attitude_status"],
        ["source_activity_context", "attitude_status"]
      ])

    callback!(callbacks, :normalized_status_token).(status)
  end

  def attitude_error_deg(row, callbacks) do
    callback!(callbacks, :timeline_diff_first_number).(row, [
      "realized_attitude_error_deg",
      "replacement_realized_attitude_error_deg",
      ["replacement_activity_context", "realized_attitude_error_deg"],
      ["replacement_activity_context", "attitude_error_deg"],
      "attitude_error_deg",
      "replacement_attitude_error_deg",
      "source_realized_attitude_error_deg",
      ["source_activity_context", "realized_attitude_error_deg"],
      ["source_activity_context", "attitude_error_deg"]
    ])
  end

  def attitude_model(row, callbacks) do
    callback!(callbacks, :timeline_diff_first_string).(row, [
      "attitude_model",
      "realized_attitude_model",
      "replacement_attitude_model",
      ["replacement_activity_context", "attitude_model"],
      "source_attitude_model",
      ["source_activity_context", "attitude_model"]
    ])
  end

  def attitude_source(row, callbacks) do
    callback!(callbacks, :timeline_diff_first_string).(row, [
      "attitude_source",
      "realized_attitude_source",
      "replacement_attitude_source",
      ["replacement_activity_context", "attitude_source"],
      "source_attitude_source",
      ["source_activity_context", "attitude_source"]
    ])
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
