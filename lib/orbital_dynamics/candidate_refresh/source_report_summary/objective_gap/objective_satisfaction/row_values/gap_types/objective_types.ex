defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ObjectiveGap.ObjectiveSatisfaction.RowValues.GapTypes.ObjectiveTypes do
  @moduledoc false

  alias OrbitalDynamics.CollectionLatencyObjectiveType
  alias OrbitalDynamics.TargetObservationObjectiveType

  def downlink_gap do
    [
      "downlink_completion",
      "required_downlink_completion"
    ]
  end

  def target_gap do
    ["target_coverage", "coverage", "priority_commitment", "target_revisit"] ++
      TargetObservationObjectiveType.aliases()
  end

  def collection_latency_gap, do: CollectionLatencyObjectiveType.aliases()
end
