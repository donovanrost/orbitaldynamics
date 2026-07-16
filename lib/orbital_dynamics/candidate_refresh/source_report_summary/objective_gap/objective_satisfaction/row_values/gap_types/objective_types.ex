defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ObjectiveGap.ObjectiveSatisfaction.RowValues.GapTypes.ObjectiveTypes do
  @moduledoc false

  def downlink_gap do
    [
      "downlink_completion",
      "required_downlink_completion"
    ]
  end

  def target_gap do
    [
      "target_coverage",
      "coverage",
      "target_commitment",
      "priority_commitment",
      "target_observation",
      "target_revisit"
    ]
  end

  def collection_latency_gap do
    [
      "collection_latency",
      "collection_downlink_latency",
      "data_latency"
    ]
  end
end
