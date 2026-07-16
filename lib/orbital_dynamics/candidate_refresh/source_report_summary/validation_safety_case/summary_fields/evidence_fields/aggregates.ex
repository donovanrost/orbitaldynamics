defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ValidationSafetyCase.SummaryFields.EvidenceFields.Aggregates do
  @moduledoc false

  alias __MODULE__.CountValues
  alias __MODULE__.RefValues

  def evidence_status_counts(reports) do
    CountValues.evidence_status_counts(reports)
  end

  def input_contract_counts(reports) do
    CountValues.input_contract_counts(reports)
  end

  def evidence_refs_by(reports, field) do
    RefValues.evidence_refs_by(reports, field)
  end
end
