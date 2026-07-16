defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ValidationSafetyCase.SummaryFields.EvidenceRows do
  @moduledoc false

  alias __MODULE__.Counts
  alias __MODULE__.RefGroups
  alias __MODULE__.Rows

  def evidence_count(report, fallback) do
    Counts.evidence_count(evidence_rows(report), fallback)
  end

  def evidence_status_count(report, status, fallback) do
    Counts.evidence_status_count(evidence_rows(report), status, fallback)
  end

  def evidence_field_sum(report, field, fallback) do
    Counts.evidence_field_sum(evidence_rows(report), field, fallback)
  end

  def input_contract_counts(report, fallback) do
    Counts.input_contract_counts(evidence_rows(report), fallback)
  end

  def evidence_status_counts(report) do
    Counts.evidence_status_counts(evidence_rows(report), report)
  end

  def refs_by(report, field) do
    RefGroups.refs_by(report, field, evidence_rows(report))
  end

  defp evidence_rows(report), do: Rows.evidence_rows(report)
end
