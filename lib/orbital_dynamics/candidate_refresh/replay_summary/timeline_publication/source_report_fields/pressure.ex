defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelinePublication.SourceReportFields.Pressure do
  @moduledoc false

  def source_report_fields(summary) do
    %{
      "source_report_timeline_publication_branch_local_timeline_publication_pressure" =>
        Map.get(summary, "branch_local_timeline_publication_pressure"),
      "source_report_timeline_publication_branch_local_dependency_pressure" =>
        Map.get(summary, "branch_local_timeline_publication_dependency_pressure"),
      "source_report_timeline_publication_branch_local_changed_field_pressure" =>
        Map.get(summary, "branch_local_timeline_publication_changed_field_pressure"),
      "source_report_timeline_publication_branch_local_invalidation_pressure" =>
        Map.get(summary, "branch_local_timeline_publication_invalidation_pressure"),
      "source_report_timeline_publication_branch_local_review_pressure" =>
        Map.get(summary, "branch_local_timeline_publication_review_pressure")
    }
  end
end
