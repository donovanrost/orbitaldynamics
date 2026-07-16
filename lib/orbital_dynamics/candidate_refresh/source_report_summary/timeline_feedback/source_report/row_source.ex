defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineFeedback.SourceReport.RowSource do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineFeedback.RowMetrics

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineFeedback.SourceReport.Metadata

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      compact_map: 1,
      report_station_reservation_evidence_count: 1,
      report_station_reservation_expiration_evidence_count: 1
    ]

  def source(report) do
    feedback = OrbitalDynamics.TimelineFeedback.operational_feedback(report)
    trust_boundaries = Metadata.trust_boundaries(report)

    %{
      "source" => "timeline_feedback_report.rows",
      "source_report_contract" =>
        Map.get(report, "schema_contract", "timeline_feedback_report.v1"),
      "source_report_count" => 1,
      "source_report_row_count" => RowMetrics.row_count(report),
      "input_keys" => RowMetrics.input_keys_from_feedback(feedback),
      "trust_boundary_status" => Metadata.status_from_boundaries(trust_boundaries),
      "trust_boundaries" => trust_boundaries,
      "source_station_reservation_evidence_row_count" =>
        report_station_reservation_evidence_count(report),
      "source_station_reservation_expiration_evidence_row_count" =>
        report_station_reservation_expiration_evidence_count(report)
    }
    |> Map.merge(RowMetrics.source_count_fields(report))
    |> compact_map()
  end
end
