defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContention do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance

  alias __MODULE__.Summary

  def replay(refresh_or_artifact) do
    branch_contention_summary = source_report_summary_branch_family(refresh_or_artifact)

    contention_summary =
      branch_contention_summary ||
        refresh_or_artifact
        |> SourceReportSummary.build()
        |> get_in(["source_reports", "contact_contention_report"]) ||
        %{}

    {summary_source, replay_scope} =
      if branch_contention_summary do
        {
          "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.contact_contention_report",
          "contact_contention_candidate_source_report_summary_only"
        }
      else
        {
          "candidate_refresh.source_report_provenance.contact_contention_report",
          "contact_contention_source_report_provenance_only"
        }
      end

    summary(contention_summary, summary_source, replay_scope)
  end

  def summary(contention_summary, summary_source, replay_scope) do
    Summary.summary(contention_summary, summary_source, replay_scope)
  end

  defp source_report_summary_branch_family(refresh_or_artifact) do
    SourceReportSummary.branch_family(
      refresh_or_artifact,
      "contact_contention_report",
      &InputProvenance.build/1
    )
  end
end
