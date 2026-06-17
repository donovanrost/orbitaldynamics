defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffObservationLightingEclipseFields do
  @moduledoc false

  def eclipse_overlap_fraction(row, callbacks) do
    callback!(callbacks, :timeline_diff_first_number).(row, [
      "realized_eclipse_overlap_fraction",
      "replacement_realized_eclipse_overlap_fraction",
      ["replacement_activity_context", "realized_eclipse_overlap_fraction"],
      ["replacement_activity_context", "eclipse_overlap_fraction"],
      "eclipse_overlap_fraction",
      "replacement_eclipse_overlap_fraction",
      "source_realized_eclipse_overlap_fraction",
      ["source_activity_context", "realized_eclipse_overlap_fraction"],
      ["source_activity_context", "eclipse_overlap_fraction"]
    ])
  end

  def eclipse_overlap_s(row, callbacks) do
    callback!(callbacks, :timeline_diff_first_number).(row, [
      "realized_eclipse_overlap_s",
      "replacement_realized_eclipse_overlap_s",
      ["replacement_activity_context", "realized_eclipse_overlap_s"],
      ["replacement_activity_context", "eclipse_overlap_s"],
      "eclipse_overlap_s",
      "replacement_eclipse_overlap_s",
      "source_realized_eclipse_overlap_s",
      ["source_activity_context", "realized_eclipse_overlap_s"],
      ["source_activity_context", "eclipse_overlap_s"]
    ])
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
