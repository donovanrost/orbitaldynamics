defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineTransitionApplication.SourceReportFields.Pressure do
  @moduledoc false

  def source_report_fields(summary) do
    %{
      "source_report_timeline_transition_application_branch_local_timeline_transition_application_pressure" =>
        Map.get(summary, "branch_local_timeline_transition_application_pressure"),
      "source_report_timeline_transition_application_branch_local_selected_activity_pressure" =>
        Map.get(summary, "branch_local_selected_activity_pressure"),
      "source_report_timeline_transition_application_branch_local_review_required_pressure" =>
        Map.get(summary, "branch_local_review_required_pressure"),
      "source_report_timeline_transition_application_branch_local_preserved_transition_pressure" =>
        Map.get(summary, "branch_local_preserved_transition_pressure"),
      "source_report_timeline_transition_application_branch_local_duplicate_identity_pressure" =>
        Map.get(summary, "branch_local_duplicate_identity_pressure"),
      "source_report_timeline_transition_application_branch_local_operator_review_pressure" =>
        Map.get(summary, "branch_local_operator_review_pressure")
    }
  end
end
