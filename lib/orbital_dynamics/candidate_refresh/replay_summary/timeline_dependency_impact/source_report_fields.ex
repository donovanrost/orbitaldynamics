defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineDependencyImpact.SourceReportFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineDependencyImpact
  alias __MODULE__.Flattened

  def source_report_fields(source_reports) do
    summary =
      source_reports
      |> Map.get("timeline_dependency_impact_summary", %{})
      |> TimelineDependencyImpact.summary(
        "candidate_refresh.source_report_provenance.timeline_dependency_impact_summary",
        "timeline_dependency_impact_source_report_provenance_only"
      )

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
    |> Map.merge(Flattened.fields(source_reports))
  end
end
