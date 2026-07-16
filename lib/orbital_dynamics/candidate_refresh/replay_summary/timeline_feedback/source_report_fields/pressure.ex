defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineFeedback.SourceReportFields.Pressure do
  @moduledoc false

  def source_report_fields(summary) do
    %{
      "source_report_timeline_feedback_branch_local_timeline_feedback_pressure" =>
        Map.get(summary, "branch_local_timeline_feedback_pressure"),
      "source_report_timeline_feedback_branch_local_feedback_input_pressure" =>
        Map.get(summary, "branch_local_feedback_input_pressure"),
      "source_report_timeline_feedback_branch_local_activity_routing_pressure" =>
        Map.get(summary, "branch_local_activity_routing_pressure"),
      "source_report_timeline_feedback_branch_local_match_review_pressure" =>
        Map.get(summary, "branch_local_match_review_pressure"),
      "source_report_timeline_feedback_branch_local_import_review_pressure" =>
        Map.get(summary, "branch_local_import_review_pressure"),
      "source_report_timeline_feedback_branch_local_station_reservation_pressure" =>
        Map.get(summary, "branch_local_station_reservation_pressure")
    }
  end
end
