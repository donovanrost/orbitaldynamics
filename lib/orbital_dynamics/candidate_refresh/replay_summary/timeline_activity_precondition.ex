defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineActivityPrecondition do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance

  alias __MODULE__.Summary

  def replay(refresh_or_artifact, source_report_summary)
      when is_function(source_report_summary, 1) do
    source_summary = source_report_summary.(refresh_or_artifact)

    branch_precondition_summary = source_report_summary_branch_family(refresh_or_artifact)

    precondition_summary =
      branch_precondition_summary ||
        get_in(source_summary, ["source_reports", "timeline_activity_precondition_summary"]) ||
        %{}

    {summary_source, replay_scope} =
      if branch_precondition_summary do
        {
          "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_activity_precondition_summary",
          "timeline_activity_precondition_candidate_source_report_summary_only"
        }
      else
        {
          "candidate_refresh.source_report_provenance.timeline_activity_precondition_summary",
          "timeline_activity_precondition_summary_source_report_provenance_only"
        }
      end

    summary(precondition_summary, summary_source, replay_scope)
  end

  def summary(precondition_summary, summary_source, replay_scope) do
    Summary.summary(precondition_summary, summary_source, replay_scope)
  end

  defp source_report_summary_branch_family(refresh_or_artifact) do
    SourceReportSummary.branch_family(
      refresh_or_artifact,
      "timeline_activity_precondition_summary",
      &InputProvenance.build/1
    )
  end
end
