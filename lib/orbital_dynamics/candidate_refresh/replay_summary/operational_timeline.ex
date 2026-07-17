defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.OperationalTimeline do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance

  alias __MODULE__.Summary

  def replay(refresh_or_artifact) do
    branch_timeline_summary = source_report_summary_branch_family(refresh_or_artifact)

    timeline_summary =
      branch_timeline_summary ||
        refresh_or_artifact
        |> SourceReportSummary.build()
        |> get_in(["source_reports", "operational_timeline_report"]) ||
        %{}

    {summary_source, replay_scope} =
      if branch_timeline_summary do
        {
          "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.operational_timeline_report",
          "operational_timeline_candidate_source_report_summary_only"
        }
      else
        {
          "candidate_refresh.source_report_provenance.operational_timeline_report",
          "operational_timeline_source_report_provenance_only"
        }
      end

    summary(timeline_summary, summary_source, replay_scope)
  end

  def summary(timeline_summary, summary_source, replay_scope) do
    Summary.summary(timeline_summary, summary_source, replay_scope)
  end

  defp source_report_summary_branch_family(refresh_or_artifact) do
    SourceReportSummary.branch_family(
      refresh_or_artifact,
      "operational_timeline_report",
      &InputProvenance.build/1
    )
  end
end
