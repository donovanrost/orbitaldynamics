defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineIntegrity do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance

  alias __MODULE__.Summary

  def replay(refresh_or_artifact) do
    branch_integrity_summary = source_report_summary_branch_family(refresh_or_artifact)

    integrity_summary =
      branch_integrity_summary ||
        refresh_or_artifact
        |> SourceReportSummary.build()
        |> get_in(["source_reports", "timeline_integrity_report"]) ||
        %{}

    {summary_source, replay_scope} =
      if branch_integrity_summary do
        {
          "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_integrity_report",
          "timeline_integrity_candidate_source_report_summary_only"
        }
      else
        {
          "candidate_refresh.source_report_provenance.timeline_integrity_report",
          "timeline_integrity_source_report_provenance_only"
        }
      end

    summary(integrity_summary, summary_source, replay_scope)
  end

  def summary(integrity_summary, summary_source, replay_scope) do
    Summary.summary(integrity_summary, summary_source, replay_scope)
  end

  defp source_report_summary_branch_family(refresh_or_artifact) do
    SourceReportSummary.branch_family(
      refresh_or_artifact,
      "timeline_integrity_report",
      &InputProvenance.build/1
    )
  end
end
