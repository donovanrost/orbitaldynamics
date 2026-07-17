defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactFilter do
  @moduledoc false

  alias __MODULE__.Summary
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance

  def replay(refresh_or_artifact) do
    branch_filter_summary = source_report_summary_branch_family(refresh_or_artifact)

    filter_summary =
      branch_filter_summary ||
        refresh_or_artifact
        |> SourceReportSummary.build()
        |> get_in(["source_reports", "contact_filter_report"]) ||
        %{}

    {summary_source, replay_scope} =
      if branch_filter_summary do
        {
          "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.contact_filter_report",
          "contact_filter_candidate_source_report_summary_only"
        }
      else
        {
          "candidate_refresh.source_report_provenance.contact_filter_report",
          "contact_filter_source_report_provenance_only"
        }
      end

    summary(filter_summary, summary_source, replay_scope)
  end

  def summary(filter_summary, summary_source, replay_scope) do
    Summary.summary(filter_summary, summary_source, replay_scope)
  end

  defp source_report_summary_branch_family(refresh_or_artifact) do
    SourceReportSummary.branch_family(
      refresh_or_artifact,
      "contact_filter_report",
      &InputProvenance.build/1
    )
  end
end
