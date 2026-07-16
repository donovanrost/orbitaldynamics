defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ValidationSafetyCase.SummaryFields.EvidenceFields do
  @moduledoc false

  alias __MODULE__.Aggregates

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ValidationSafetyCase.SummaryFields.{
    CountFields,
    EvidenceRows
  }

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      count_report_field_values: 2,
      source_report_trust_boundaries: 1,
      source_report_trust_boundary_status: 1,
      sum_report_count: 2
    ]

  def fields(reports) do
    %{
      "row_count" => sum_report_count(reports, &evidence_count/1),
      "status_counts" => count_report_field_values(reports, "status"),
      "evidence_status_counts" => Aggregates.evidence_status_counts(reports),
      "input_contract_counts" => Aggregates.input_contract_counts(reports),
      "evidence_refs_by_status" => Aggregates.evidence_refs_by(reports, "status"),
      "evidence_refs_by_contract" => Aggregates.evidence_refs_by(reports, "schema_contract"),
      "trust_boundary_status" => source_report_trust_boundary_status(reports),
      "trust_boundaries" => source_report_trust_boundaries(reports)
    }
  end

  defp evidence_count(report) do
    EvidenceRows.evidence_count(report, fn -> CountFields.fallback_count(report) end)
  end
end
