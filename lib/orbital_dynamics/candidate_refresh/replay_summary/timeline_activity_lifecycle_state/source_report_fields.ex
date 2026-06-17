defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineActivityLifecycleState.SourceReportFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineActivityLifecycleState
  alias __MODULE__.Flattened

  def source_report_fields(source_reports) do
    summary =
      source_reports
      |> Map.get("timeline_activity_lifecycle_state", %{})
      |> TimelineActivityLifecycleState.summary(
        "candidate_refresh.source_report_provenance.timeline_activity_lifecycle_state",
        "timeline_activity_lifecycle_state_source_report_provenance_only"
      )

    %{
      "source_report_timeline_activity_lifecycle_state_branch_local_timeline_activity_lifecycle_state_pressure" =>
        Map.get(summary, "branch_local_timeline_activity_lifecycle_state_pressure"),
      "source_report_timeline_activity_lifecycle_state_branch_local_review_pressure" =>
        Map.get(summary, "branch_local_activity_lifecycle_review_pressure"),
      "source_report_timeline_activity_lifecycle_state_branch_local_action_pressure" =>
        Map.get(summary, "branch_local_activity_lifecycle_action_pressure"),
      "source_report_timeline_activity_lifecycle_state_branch_local_routing_pressure" =>
        Map.get(summary, "branch_local_activity_lifecycle_routing_pressure")
    }
    |> Map.merge(Flattened.source_report_fields(source_reports))
  end
end
