defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactIntent do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance

  alias __MODULE__.Summary

  def replay(refresh_or_artifact, source_report_summary)
      when is_function(source_report_summary, 1) do
    branch_intent_summary = source_report_summary_branch_family(refresh_or_artifact)

    intent_summary =
      branch_intent_summary ||
        refresh_or_artifact
        |> source_report_summary.()
        |> get_in(["source_reports", "contact_intent"]) ||
        %{}

    {summary_source, replay_scope} =
      if branch_intent_summary do
        {
          "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.contact_intent",
          "contact_intent_candidate_source_report_summary_only"
        }
      else
        {
          "candidate_refresh.source_report_provenance.contact_intent",
          "contact_intent_source_report_provenance_only"
        }
      end

    summary(intent_summary, summary_source, replay_scope)
  end

  def summary(intent_summary, summary_source, replay_scope) do
    Summary.summary(intent_summary, summary_source, replay_scope)
  end

  defp source_report_summary_branch_family(refresh_or_artifact) do
    SourceReportSummary.branch_family(
      refresh_or_artifact,
      "contact_intent",
      &InputProvenance.build/1
    )
  end
end
