defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ObjectiveGap.ScoreTermFields.GapCounts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.NormalizedToken

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ObjectiveGap.ScoreTermFields.RowValues

  alias OrbitalDynamics.CandidateRefresh.SourceObjectives.ScoreTerm,
    as: ScoreTermSourceObjectives

  def downlink_gap_row_count(report) do
    gap_row_count(report, &ScoreTermSourceObjectives.downlink_gap?/1)
  end

  def target_gap_row_count(report) do
    gap_row_count(report, &ScoreTermSourceObjectives.target_gap?/1)
  end

  def collection_latency_gap_row_count(report) do
    gap_row_count(report, &ScoreTermSourceObjectives.collection_latency_gap?/1)
  end

  defp gap_row_count(report, predicate) do
    report
    |> RowValues.rows()
    |> Enum.count(fn row ->
      row
      |> ScoreTermSourceObjectives.key()
      |> NormalizedToken.value()
      |> predicate.()
    end)
  end
end
