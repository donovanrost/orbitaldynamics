defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineFeedback.SourceFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineFeedback.SourceReport.Metadata

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      report_station_reservation_evidence_count: 1,
      report_station_reservation_expiration_evidence_count: 1,
      sum_report_count: 2
    ]

  def fields(sources, reports) do
    trust_boundaries = Metadata.trust_boundaries(reports)

    %{
      "paths" => Enum.map(sources, fn {path, _report} -> path end),
      "contract" => "timeline_feedback_report.v1",
      "count" => length(sources),
      "station_reservation_evidence_row_count" =>
        sum_report_count(
          reports,
          &report_station_reservation_evidence_count/1
        ),
      "station_reservation_expiration_evidence_row_count" =>
        sum_report_count(
          reports,
          &report_station_reservation_expiration_evidence_count/1
        ),
      "trust_boundary_status" => Metadata.status_from_boundaries(trust_boundaries),
      "trust_boundaries" => trust_boundaries
    }
  end
end
