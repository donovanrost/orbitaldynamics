defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineLifecycleState.SourceReportFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineLifecycleState
  alias __MODULE__.Flattened

  def source_report_fields(source_reports) do
    summary =
      source_reports
      |> Map.get("timeline_lifecycle_state_summary", %{})
      |> TimelineLifecycleState.summary(
        "candidate_refresh.source_report_provenance.timeline_lifecycle_state_summary",
        "timeline_lifecycle_state_source_report_provenance_only"
      )

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
    |> Map.merge(Flattened.source_report_fields(source_reports))
  end
end
