defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineDependencyImpact.SourceReportFields.Pressure do
  @moduledoc false

  def source_report_fields(summary) do
    %{
      "source_report_timeline_dependency_impact_branch_local_timeline_dependency_impact_pressure" =>
        Map.get(summary, "branch_local_timeline_dependency_impact_pressure"),
      "source_report_timeline_dependency_impact_branch_local_changed_source_pressure" =>
        Map.get(summary, "branch_local_changed_source_pressure"),
      "source_report_timeline_dependency_impact_branch_local_dependency_pressure" =>
        Map.get(summary, "branch_local_dependency_pressure"),
      "source_report_timeline_dependency_impact_branch_local_exclusivity_pressure" =>
        Map.get(summary, "branch_local_exclusivity_pressure"),
      "source_report_timeline_dependency_impact_branch_local_dependent_activity_pressure" =>
        Map.get(summary, "branch_local_dependent_activity_pressure"),
      "source_report_timeline_dependency_impact_branch_local_operator_review_pressure" =>
        Map.get(summary, "branch_local_operator_review_pressure")
    }
  end
end
