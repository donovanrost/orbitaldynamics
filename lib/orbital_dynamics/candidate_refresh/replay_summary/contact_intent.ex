defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactIntent do
  @moduledoc false

  alias __MODULE__.SourceReportFields
  alias __MODULE__.Summary

  def replay(refresh_or_artifact, callbacks) do
    source_report_summary = Keyword.fetch!(callbacks, :source_report_summary)

    source_report_summary_branch_family =
      Keyword.fetch!(callbacks, :source_report_summary_branch_family)

    branch_intent_summary =
      source_report_summary_branch_family.(refresh_or_artifact, "contact_intent")

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

  def source_report_fields(source_reports) do
    SourceReportFields.source_report_fields(source_reports)
  end

  def summary(intent_summary, summary_source, replay_scope) do
    Summary.summary(intent_summary, summary_source, replay_scope)
  end
end
