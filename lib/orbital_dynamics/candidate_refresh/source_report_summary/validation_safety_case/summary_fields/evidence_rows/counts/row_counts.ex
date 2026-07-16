defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ValidationSafetyCase.SummaryFields.EvidenceRows.Counts.RowCounts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ValidationSafetyCase.SummaryFields.EvidenceRows.Rows

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      count_source_report_values: 1,
      numeric_report_count: 2,
      sum_report_count: 2
    ]

  def evidence_count(rows), do: length(rows)

  def evidence_status_count(rows, status) do
    Enum.count(rows, &(Rows.evidence_status(&1) == status))
  end

  def evidence_field_sum(rows, field) do
    sum_report_count(rows, &numeric_report_count(&1, field))
  end

  def input_contract_counts(rows) do
    rows
    |> Enum.map(&Rows.evidence_contract/1)
    |> count_source_report_values()
  end

  def evidence_status_counts(rows) do
    rows
    |> Enum.map(&Rows.evidence_status/1)
    |> count_source_report_values()
  end
end
