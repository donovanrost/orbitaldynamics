defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.TimelineDiffFields.SourceFields.BaseFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.TimelineDiffFields.ChangeCounts.RowCounts.Rows

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.TimelineDiffFields.SourceMetadata.TrustBoundaryFields

  def values(report) do
    trust_boundaries = TrustBoundaryFields.values(report)

    %{
      "source" => "timeline_diff_report.rows",
      "source_report_contract" => Map.get(report, "schema_contract", "timeline_diff_report.v1"),
      "source_report_count" => 1,
      "source_report_row_count" => Rows.row_count(report),
      "input_keys" =>
        report
        |> OperationalFeedback.timeline_diff_report_feedback()
        |> OperationalFeedback.data_keys(),
      "trust_boundary_status" => TrustBoundaryFields.status_from_values(trust_boundaries),
      "trust_boundaries" => trust_boundaries
    }
  end
end
