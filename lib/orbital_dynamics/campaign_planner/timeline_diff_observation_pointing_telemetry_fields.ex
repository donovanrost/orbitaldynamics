defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffObservationPointingTelemetryFields do
  @moduledoc false

  def pointing_status(row, callbacks) do
    status =
      callback!(callbacks, :timeline_diff_first_string).(row, [
        "realized_pointing_status",
        "replacement_realized_pointing_status",
        ["replacement_activity_context", "realized_pointing_status"],
        ["replacement_activity_context", "pointing_status"],
        "pointing_status",
        "replacement_pointing_status",
        "source_realized_pointing_status",
        ["source_activity_context", "realized_pointing_status"],
        ["source_activity_context", "pointing_status"]
      ])

    callback!(callbacks, :normalized_status_token).(status)
  end

  def pointing_error_deg(row, callbacks) do
    callback!(callbacks, :timeline_diff_first_number).(row, [
      "realized_pointing_error_deg",
      "replacement_realized_pointing_error_deg",
      ["replacement_activity_context", "realized_pointing_error_deg"],
      ["replacement_activity_context", "pointing_error_deg"],
      "pointing_error_deg",
      "replacement_pointing_error_deg",
      "source_realized_pointing_error_deg",
      ["source_activity_context", "realized_pointing_error_deg"],
      ["source_activity_context", "pointing_error_deg"]
    ])
  end

  def pointing_model(row, callbacks) do
    callback!(callbacks, :timeline_diff_first_string).(row, [
      "pointing_model",
      "realized_pointing_model",
      "replacement_pointing_model",
      ["replacement_activity_context", "pointing_model"],
      "source_pointing_model",
      ["source_activity_context", "pointing_model"]
    ])
  end

  def pointing_source(row, callbacks) do
    callback!(callbacks, :timeline_diff_first_string).(row, [
      "pointing_source",
      "realized_pointing_source",
      "replacement_pointing_source",
      ["replacement_activity_context", "pointing_source"],
      "source_pointing_source",
      ["source_activity_context", "pointing_source"]
    ])
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
