defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactFilter.SourceFields.BaseFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactFilter.SourceReportFields.Report

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactFilter.SourceFields.TrustBoundaries

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      sum_report_count: 2
    ]

  def fields(sources, reports) do
    %{
      "paths" => Enum.map(sources, fn {path, _report} -> path end),
      "contract" => "contact_filter_report.v1",
      "count" => length(sources),
      "row_count" => sum_report_count(reports, &Report.row_count/1),
      "suppressed_candidate_count" =>
        sum_report_count(reports, &Report.suppressed_candidate_count/1),
      "trust_boundary_status" => TrustBoundaries.status(reports),
      "trust_boundaries" => TrustBoundaries.values(reports)
    }
  end
end
