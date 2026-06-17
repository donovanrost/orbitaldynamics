defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineActivityPrecondition.SourceReportFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineActivityPrecondition
  alias __MODULE__.Flattened

  def source_report_fields(source_reports) do
    summary =
      source_reports
      |> Map.get("timeline_activity_precondition_summary", %{})
      |> TimelineActivityPrecondition.summary(
        "candidate_refresh.source_report_provenance.timeline_activity_precondition_summary",
        "timeline_activity_precondition_summary_source_report_provenance_only"
      )

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
    |> Map.merge(Flattened.source_report_fields(source_reports))
  end
end
