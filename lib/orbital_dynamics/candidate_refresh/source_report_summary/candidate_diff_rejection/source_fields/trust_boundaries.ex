defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CandidateDiffRejection.SourceFields.TrustBoundaries do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.CandidateDiffRejection.{
    CandidateDiffFields,
    CandidateRejectionFields
  }

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      normalize_trust_boundaries: 1,
      source_report_trust_boundaries: 1,
      source_report_trust_boundary_status: 1
    ]

  def candidate_diff_status(reports), do: source_report_trust_boundary_status(reports)

  def candidate_diff(reports) do
    reports
    |> source_report_trust_boundaries()
    |> Kernel.++(CandidateDiffFields.row_trust_boundaries(reports))
    |> normalize_trust_boundaries()
  end

  def candidate_rejection_status(reports) do
    case candidate_rejection(reports) do
      [] -> "missing"
      _trust_boundaries -> "declared"
    end
  end

  def candidate_rejection(reports) do
    reports
    |> source_report_trust_boundaries()
    |> Kernel.++(CandidateRejectionFields.row_trust_boundaries(reports))
    |> normalize_trust_boundaries()
  end
end
