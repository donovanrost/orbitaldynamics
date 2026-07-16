defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineActivityPrecondition.SourceReportFields.Pressure do
  @moduledoc false

  def source_report_fields(summary) do
    %{
      "source_report_timeline_activity_precondition_branch_local_timeline_activity_precondition_pressure" =>
        Map.get(summary, "branch_local_timeline_activity_precondition_pressure"),
      "source_report_timeline_activity_precondition_branch_local_review_pressure" =>
        Map.get(summary, "branch_local_activity_precondition_review_pressure"),
      "source_report_timeline_activity_precondition_branch_local_dependency_pressure" =>
        Map.get(summary, "branch_local_activity_precondition_dependency_pressure"),
      "source_report_timeline_activity_precondition_branch_local_exclusivity_pressure" =>
        Map.get(summary, "branch_local_activity_precondition_exclusivity_pressure"),
      "source_report_timeline_activity_precondition_branch_local_invalid_input_pressure" =>
        Map.get(summary, "branch_local_activity_precondition_invalid_input_pressure"),
      "source_report_timeline_activity_precondition_branch_local_routing_pressure" =>
        Map.get(summary, "branch_local_activity_precondition_routing_pressure")
    }
  end
end
