defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ObjectiveGap.ObjectiveSatisfaction.RowValues.GapCounts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ObjectiveGap.ObjectiveSatisfaction.RowValues.GapTypes

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ObjectiveGap.ObjectiveSatisfaction.RowValues.NormalizedRows

  alias OrbitalDynamics.CandidateRefresh.SourceObjectives.ObjectiveSatisfaction,
    as: ObjectiveSatisfactionSourceObjectives

  def gap_row_count(report) do
    report
    |> rows()
    |> Enum.count(&ObjectiveSatisfactionSourceObjectives.gap_status?(&1["status"]))
  end

  def downlink_gap_row_count(report) do
    report
    |> rows()
    |> Enum.count(&GapTypes.downlink_gap?/1)
  end

  def target_gap_row_count(report) do
    report
    |> rows()
    |> Enum.count(&GapTypes.target_gap?/1)
  end

  def collection_latency_gap_row_count(report) do
    report
    |> rows()
    |> Enum.count(&GapTypes.collection_latency_gap?/1)
  end

  defp rows(report), do: NormalizedRows.values(report)
end
