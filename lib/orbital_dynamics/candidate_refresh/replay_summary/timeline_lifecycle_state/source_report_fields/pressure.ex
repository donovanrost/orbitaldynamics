defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineLifecycleState.SourceReportFields.Pressure do
  @moduledoc false

  def source_report_fields(summary) do
    %{
      "source_report_timeline_lifecycle_state_branch_local_timeline_lifecycle_state_pressure" =>
        Map.get(summary, "branch_local_timeline_lifecycle_state_pressure"),
      "source_report_timeline_lifecycle_state_branch_local_lifecycle_review_pressure" =>
        Map.get(summary, "branch_local_lifecycle_review_pressure"),
      "source_report_timeline_lifecycle_state_branch_local_lifecycle_recordable_pressure" =>
        Map.get(summary, "branch_local_lifecycle_recordable_pressure"),
      "source_report_timeline_lifecycle_state_branch_local_lifecycle_preservation_pressure" =>
        Map.get(summary, "branch_local_lifecycle_preservation_pressure")
    }
  end
end
