defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ProviderCounteroffer do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance

  alias __MODULE__.Summary

  def replay(refresh_or_artifact, source_report_summary)
      when is_function(source_report_summary, 1) do
    branch_counteroffer_summary = source_report_summary_branch_family(refresh_or_artifact)

    counteroffer_summary =
      branch_counteroffer_summary ||
        refresh_or_artifact
        |> source_report_summary.()
        |> get_in(["source_reports", "provider_counteroffer_report"]) ||
        %{}

    {summary_source, replay_scope} =
      if branch_counteroffer_summary do
        {
          "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_activity_state",
          "provider_counteroffer_candidate_source_report_summary_only"
        }
      else
        {
          "candidate_refresh.source_report_provenance.provider_counteroffer_report",
          "provider_counteroffer_source_report_provenance_only"
        }
      end

    summary(counteroffer_summary, summary_source, replay_scope)
  end

  def summary(counteroffer_summary, summary_source, replay_scope) do
    Summary.summary(counteroffer_summary, summary_source, replay_scope)
  end

  defp source_report_summary_branch_family(refresh_or_artifact) do
    SourceReportSummary.branch_family(
      refresh_or_artifact,
      "provider_counteroffer_report",
      &InputProvenance.build/1
    )
  end
end
