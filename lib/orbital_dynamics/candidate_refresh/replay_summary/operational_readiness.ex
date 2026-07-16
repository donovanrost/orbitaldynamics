defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.OperationalReadiness do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance
  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelinePublicationContext

  alias __MODULE__.Summary

  def replay(refresh_or_artifact, source_report_summary)
      when is_function(source_report_summary, 1) do
    branch_readiness_summary = source_report_summary_branch_family(refresh_or_artifact)

    readiness_summary =
      branch_readiness_summary ||
        refresh_or_artifact
        |> source_report_summary.()
        |> get_in(["source_reports", "operational_readiness_report"]) ||
        %{}

    {summary_source, replay_scope} =
      if branch_readiness_summary do
        {
          "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.operational_readiness_report",
          "operational_readiness_candidate_source_report_summary_only"
        }
      else
        {
          "candidate_refresh.source_report_provenance.operational_readiness_report",
          "operational_readiness_source_report_provenance_only"
        }
      end

    timeline_publication_context = TimelinePublicationContext.fields(readiness_summary, true)

    summary(
      readiness_summary,
      summary_source,
      replay_scope,
      timeline_publication_context
    )
  end

  def pressure_fields(readiness_summary) do
    Summary.pressure_fields(readiness_summary)
  end

  def summary(readiness_summary, summary_source, replay_scope, timeline_publication_context) do
    Summary.summary(readiness_summary, summary_source, replay_scope, timeline_publication_context)
  end

  defp source_report_summary_branch_family(refresh_or_artifact) do
    SourceReportSummary.branch_family(
      refresh_or_artifact,
      "operational_readiness_report",
      &InputProvenance.build/1
    )
  end
end
