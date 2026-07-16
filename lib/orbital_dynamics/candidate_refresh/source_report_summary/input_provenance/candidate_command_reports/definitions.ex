defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.CandidateCommandReports.Definitions do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary

  def definitions do
    [
      %{
        key: "candidate_diff_report",
        mode: :deduplicated,
        source: :source_candidate_diff_reports,
        summary: &SourceReportSummary.CandidateDiffRejection.candidate_diff_report_input_summary/1
      },
      %{
        key: "candidate_rejection_report",
        mode: :deduplicated,
        source: :source_candidate_rejection_reports,
        summary:
          &SourceReportSummary.CandidateDiffRejection.candidate_rejection_report_input_summary/1
      },
      %{
        key: "command_window_report",
        source: :source_command_window_reports,
        summary: &SourceReportSummary.CommandManeuverReview.command_window_report_input_summary/1
      },
      %{
        key: "maneuver_review_report",
        source: :source_maneuver_review_reports,
        summary: &SourceReportSummary.CommandManeuverReview.maneuver_review_report_input_summary/1
      }
    ]
  end
end
