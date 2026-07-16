defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineDiff.SourceReportFields.Pressure do
  @moduledoc false

  def source_report_fields(summary) do
    %{
      "source_report_timeline_diff_branch_local_timeline_diff_pressure" =>
        Map.get(summary, "branch_local_timeline_diff_pressure"),
      "source_report_timeline_diff_branch_local_duplicate_identity_pressure" =>
        Map.get(summary, "branch_local_duplicate_identity_pressure"),
      "source_report_timeline_diff_branch_local_removed_activity_pressure" =>
        Map.get(summary, "branch_local_removed_activity_pressure"),
      "source_report_timeline_diff_branch_local_changed_activity_pressure" =>
        Map.get(summary, "branch_local_changed_activity_pressure"),
      "source_report_timeline_diff_branch_local_activity_routing_pressure" =>
        Map.get(summary, "branch_local_activity_routing_pressure"),
      "source_report_timeline_diff_branch_local_operator_review_pressure" =>
        Map.get(summary, "branch_local_operator_review_pressure")
    }
  end
end
