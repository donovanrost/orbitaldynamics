defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineTransitionApplication do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance

  alias __MODULE__.Summary

  def replay(refresh_or_artifact) do
    branch_transition_summary = source_report_summary_branch_family(refresh_or_artifact)

    transition_summary =
      branch_transition_summary ||
        refresh_or_artifact
        |> SourceReportSummary.build()
        |> get_in(["source_reports", "timeline_transition_application_report"]) ||
        %{}

    {summary_source, replay_scope} =
      if branch_transition_summary do
        {
          "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_transition_application_report",
          "timeline_transition_application_candidate_source_report_summary_only"
        }
      else
        {
          "candidate_refresh.source_report_provenance.timeline_transition_application_report",
          "timeline_transition_application_source_report_provenance_only"
        }
      end

    summary(transition_summary, summary_source, replay_scope)
  end

  def summary(transition_summary, summary_source, replay_scope) do
    Summary.summary(transition_summary, summary_source, replay_scope)
  end

  defp source_report_summary_branch_family(refresh_or_artifact) do
    SourceReportSummary.branch_family(
      refresh_or_artifact,
      "timeline_transition_application_report",
      &InputProvenance.build/1
    )
  end
end
