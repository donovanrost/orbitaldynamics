defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContentionResolution do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContentionResolution.Summary

  def replay(refresh_or_artifact, source_report_summary)
      when is_function(source_report_summary, 1) do
    branch_resolution_summary = source_report_summary_branch_family(refresh_or_artifact)

    resolution_summary =
      branch_resolution_summary ||
        refresh_or_artifact
        |> source_report_summary.()
        |> get_in(["source_reports", "contact_contention_resolution_report"]) ||
        %{}

    {summary_source, replay_scope} =
      if branch_resolution_summary do
        {
          "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.contact_contention_resolution_report",
          "contact_contention_resolution_candidate_source_report_summary_only"
        }
      else
        {
          "candidate_refresh.source_report_provenance.contact_contention_resolution_report",
          "contact_contention_resolution_source_report_provenance_only"
        }
      end

    summary(resolution_summary, summary_source, replay_scope)
  end

  def summary(resolution_summary, summary_source, replay_scope) do
    Summary.summary(resolution_summary, summary_source, replay_scope)
  end

  defp source_report_summary_branch_family(refresh_or_artifact) do
    SourceReportSummary.branch_family(
      refresh_or_artifact,
      "contact_contention_resolution_report",
      &InputProvenance.build/1
    )
  end
end
