defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContention do
  @moduledoc false

  alias __MODULE__.SourceReportFields
  alias __MODULE__.Summary

  def replay(refresh_or_artifact, callbacks) do
    source_report_summary = Keyword.fetch!(callbacks, :source_report_summary)

    source_report_summary_branch_family =
      Keyword.fetch!(callbacks, :source_report_summary_branch_family)

    branch_contention_summary =
      source_report_summary_branch_family.(refresh_or_artifact, "contact_contention_report")

    contention_summary =
      branch_contention_summary ||
        refresh_or_artifact
        |> source_report_summary.()
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

  def source_report_fields(refresh_or_artifact, source_reports, callbacks) do
    source_report_summary_branch_family =
      Keyword.fetch!(callbacks, :source_report_summary_branch_family)

    branch_contention_summary =
      source_report_summary_branch_family.(refresh_or_artifact, "contact_contention_report")

    contention_summary =
      branch_contention_summary || Map.get(source_reports, "contact_contention_report", %{})

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

    summary = summary(contention_summary, summary_source, replay_scope)

    SourceReportFields.source_report_fields(source_reports, summary)
  end

  def summary(contention_summary, summary_source, replay_scope) do
    Summary.summary(contention_summary, summary_source, replay_scope)
  end
end
