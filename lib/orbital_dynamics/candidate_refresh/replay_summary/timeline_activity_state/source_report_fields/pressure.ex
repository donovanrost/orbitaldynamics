defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineActivityState.SourceReportFields.Pressure do
  @moduledoc false

  def source_report_fields(summary) do
    %{
      "source_report_timeline_activity_state_branch_local_timeline_activity_state_pressure" =>
        Map.get(summary, "branch_local_timeline_activity_state_pressure"),
      "source_report_timeline_activity_state_branch_local_review_pressure" =>
        Map.get(summary, "branch_local_activity_state_review_pressure"),
      "source_report_timeline_activity_state_branch_local_action_pressure" =>
        Map.get(summary, "branch_local_activity_state_action_pressure"),
      "source_report_timeline_activity_state_branch_local_routing_pressure" =>
        Map.get(summary, "branch_local_activity_state_routing_pressure")
    }
  end
end
