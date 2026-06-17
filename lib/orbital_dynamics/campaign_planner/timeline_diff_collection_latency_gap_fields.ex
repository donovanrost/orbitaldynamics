defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffCollectionLatencyGapFields do
  @moduledoc false

  def explicit_s(row, callbacks) do
    callback!(callbacks, :timeline_diff_first_number).(row, [
      "collection_latency_gap_s",
      "latency_gap_s",
      "delivery_latency_gap_s",
      "collection_latency_shortfall_s",
      "late_delivery_s",
      "replacement_collection_latency_gap_s",
      "replacement_latency_gap_s",
      "replacement_delivery_latency_gap_s",
      "replacement_collection_latency_shortfall_s",
      "replacement_late_delivery_s",
      ["replacement_activity_context", "collection_latency_gap_s"],
      ["replacement_activity_context", "latency_gap_s"],
      ["replacement_activity_context", "delivery_latency_gap_s"],
      ["replacement_activity_context", "collection_latency_shortfall_s"],
      ["replacement_activity_context", "late_delivery_s"],
      "source_collection_latency_gap_s",
      "source_latency_gap_s",
      "source_delivery_latency_gap_s",
      "source_collection_latency_shortfall_s",
      "source_late_delivery_s",
      ["source_activity_context", "collection_latency_gap_s"],
      ["source_activity_context", "latency_gap_s"],
      ["source_activity_context", "delivery_latency_gap_s"],
      ["source_activity_context", "collection_latency_shortfall_s"],
      ["source_activity_context", "late_delivery_s"]
    ])
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
