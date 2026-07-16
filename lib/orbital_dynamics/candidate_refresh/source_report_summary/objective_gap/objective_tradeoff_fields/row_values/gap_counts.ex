defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ObjectiveGap.ObjectiveTradeoffFields.RowValues.GapCounts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceObjectives.ObjectiveTradeoff,
    as: ObjectiveTradeoffSourceObjectives

  def downlink_gap_row_count(rows) do
    Enum.count(rows, &ObjectiveTradeoffSourceObjectives.downlink_gap?/1)
  end

  def target_gap_row_count(rows) do
    Enum.count(rows, &ObjectiveTradeoffSourceObjectives.target_gap?/1)
  end

  def collection_latency_gap_row_count(rows) do
    Enum.count(rows, &ObjectiveTradeoffSourceObjectives.collection_latency_gap?/1)
  end
end
