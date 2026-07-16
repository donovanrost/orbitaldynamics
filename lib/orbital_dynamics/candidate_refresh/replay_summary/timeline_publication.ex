defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelinePublication do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance

  alias __MODULE__.Summary

  def replay(refresh_or_artifact, source_report_summary)
      when is_function(source_report_summary, 1) do
    branch_publication_summary = source_report_summary_branch_family(refresh_or_artifact)

    publication_summary =
      branch_publication_summary ||
        refresh_or_artifact
        |> source_report_summary.()
        |> get_in(["source_reports", "timeline_publication_summary"]) ||
        %{}

    {summary_source, replay_scope} =
      if branch_publication_summary do
        {
          "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_publication_summary",
          "timeline_publication_candidate_source_report_summary_only"
        }
      else
        {
          "candidate_refresh.source_report_provenance.timeline_publication_summary",
          "timeline_publication_source_report_provenance_only"
        }
      end

    summary(publication_summary, summary_source, replay_scope)
  end

  def summary(publication_summary, summary_source, replay_scope) do
    Summary.summary(publication_summary, summary_source, replay_scope)
  end

  defp source_report_summary_branch_family(refresh_or_artifact) do
    SourceReportSummary.branch_family(
      refresh_or_artifact,
      "timeline_publication_summary",
      &InputProvenance.build/1
    )
  end
end
