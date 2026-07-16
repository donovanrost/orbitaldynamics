defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineIntegrity.SourceReportFields.Pressure do
  @moduledoc false

  def source_report_fields(summary) do
    %{
      "source_report_timeline_integrity_branch_local_timeline_integrity_pressure" =>
        Map.get(summary, "branch_local_timeline_integrity_pressure"),
      "source_report_timeline_integrity_branch_local_timeline_integrity_review_pressure" =>
        Map.get(summary, "branch_local_timeline_integrity_review_pressure"),
      "source_report_timeline_integrity_branch_local_dependency_integrity_pressure" =>
        Map.get(summary, "branch_local_dependency_integrity_pressure"),
      "source_report_timeline_integrity_branch_local_exclusivity_integrity_pressure" =>
        Map.get(summary, "branch_local_exclusivity_integrity_pressure")
    }
  end
end
