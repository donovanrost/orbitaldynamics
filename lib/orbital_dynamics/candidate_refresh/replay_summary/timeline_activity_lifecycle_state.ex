defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineActivityLifecycleState do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance

  alias __MODULE__.Summary

  def replay(refresh_or_artifact) do
    source_summary = SourceReportSummary.build(refresh_or_artifact)

    branch_lifecycle_summary = source_report_summary_branch_family(refresh_or_artifact)

    lifecycle_summary =
      branch_lifecycle_summary ||
        get_in(source_summary, ["source_reports", "timeline_activity_lifecycle_state"]) || %{}

    {summary_source, replay_scope} =
      if branch_lifecycle_summary do
        {
          "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_activity_lifecycle_state",
          "timeline_activity_lifecycle_state_candidate_source_report_summary_only"
        }
      else
        {
          "candidate_refresh.source_report_provenance.timeline_activity_lifecycle_state",
          "timeline_activity_lifecycle_state_source_report_provenance_only"
        }
      end

    summary(lifecycle_summary, summary_source, replay_scope)
  end

  def summary(lifecycle_summary, summary_source, replay_scope) do
    Summary.summary(lifecycle_summary, summary_source, replay_scope)
  end

  defp source_report_summary_branch_family(refresh_or_artifact) do
    SourceReportSummary.branch_family(
      refresh_or_artifact,
      "timeline_activity_lifecycle_state",
      &InputProvenance.build/1
    )
  end
end
