defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ValidationSafetyCase.SummaryFields.EvidenceFields.Aggregates.CountValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ValidationSafetyCase.SummaryFields.{
    EvidenceRows,
    FallbackSummary
  }

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1
    ]

  def evidence_status_counts(reports) do
    reports
    |> Enum.map(&EvidenceRows.evidence_status_counts/1)
    |> merge_count_maps()
  end

  def input_contract_counts(reports) do
    reports
    |> Enum.map(&input_contract_counts_for_report/1)
    |> merge_count_maps()
  end

  defp input_contract_counts_for_report(report) do
    EvidenceRows.input_contract_counts(report, fn ->
      FallbackSummary.input_contract_counts(report)
    end)
  end
end
