defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ValidationSafetyCase.SummaryFields.EvidenceRows.Counts do
  @moduledoc false

  alias __MODULE__.RowCounts

  def evidence_count([], fallback), do: fallback.()
  def evidence_count(rows, _fallback), do: RowCounts.evidence_count(rows)

  def evidence_status_count([], _status, fallback), do: fallback.()

  def evidence_status_count(rows, status, _fallback) do
    RowCounts.evidence_status_count(rows, status)
  end

  def evidence_field_sum([], _field, fallback), do: fallback.()

  def evidence_field_sum(rows, field, _fallback) do
    RowCounts.evidence_field_sum(rows, field)
  end

  def input_contract_counts([], fallback), do: fallback.()
  def input_contract_counts(rows, _fallback), do: RowCounts.input_contract_counts(rows)

  def evidence_status_counts([], report), do: Map.get(report, "evidence_status_counts")
  def evidence_status_counts(rows, _report), do: RowCounts.evidence_status_counts(rows)
end
