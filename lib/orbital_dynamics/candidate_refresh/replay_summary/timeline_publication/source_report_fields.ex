defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelinePublication.SourceReportFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelinePublication
  alias __MODULE__.Flattened

  def source_report_fields(source_reports) do
    summary =
      source_reports
      |> Map.get("timeline_publication_summary", %{})
      |> TimelinePublication.summary(
        "candidate_refresh.source_report_provenance.timeline_publication_summary",
        "timeline_publication_source_report_provenance_only"
      )

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
    |> Map.merge(Flattened.source_report_fields(source_reports))
  end

  def source_report_dependency_id_fields(source_reports) do
    Flattened.dependency_id_fields(source_reports)
  end
end
