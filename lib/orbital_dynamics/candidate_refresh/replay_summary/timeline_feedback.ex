defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineFeedback do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance

  alias __MODULE__.Summary

  def replay(refresh_or_artifact) do
    branch_feedback_summary = source_report_summary_branch_family(refresh_or_artifact)

    feedback_summary =
      branch_feedback_summary ||
        refresh_or_artifact
        |> SourceReportSummary.build()
        |> get_in(["source_reports", "timeline_feedback_report"]) ||
        %{}

    {summary_source, replay_scope} =
      if branch_feedback_summary do
        {
          "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_feedback_report",
          "timeline_feedback_candidate_source_report_summary_only"
        }
      else
        {
          "candidate_refresh.source_report_provenance.timeline_feedback_report",
          "timeline_feedback_source_report_provenance_only"
        }
      end

    summary(feedback_summary, summary_source, replay_scope)
  end

  def summary(feedback_summary, summary_source, replay_scope) do
    Summary.summary(feedback_summary, summary_source, replay_scope)
  end

  defp source_report_summary_branch_family(refresh_or_artifact) do
    SourceReportSummary.branch_family(
      refresh_or_artifact,
      "timeline_feedback_report",
      &InputProvenance.build/1
    )
  end
end
