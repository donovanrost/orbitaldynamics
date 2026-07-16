defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalTimeline.SourceReport.ReportCounts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalTimeline.IntegrityFields
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalTimeline.RowFields

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      report_station_reservation_evidence_count: 1,
      report_station_reservation_expiration_evidence_count: 1
    ]

  def fields(report) do
    %{
      "source_report_row_count" => RowFields.row_count(report),
      "source_contact_feedback_count" => RowFields.contact_count(report),
      "source_command_feedback_count" => RowFields.command_count(report),
      "source_maneuver_feedback_count" => RowFields.maneuver_count(report),
      "source_observation_feedback_count" => RowFields.observation_count(report),
      "source_station_throughput_feedback_count" => RowFields.station_throughput_count(report),
      "source_station_reservation_evidence_row_count" =>
        report_station_reservation_evidence_count(report),
      "source_station_reservation_expiration_evidence_row_count" =>
        report_station_reservation_expiration_evidence_count(report),
      "source_timeline_integrity_issue_count" => IntegrityFields.integrity_issue_count(report),
      "source_dependency_integrity_issue_count" => IntegrityFields.dependency_issue_count(report),
      "source_exclusivity_integrity_issue_count" =>
        IntegrityFields.exclusivity_issue_count(report),
      "source_required_operator_action_counts" =>
        RowFields.source_required_operator_action_counts(report)
    }
  end
end
