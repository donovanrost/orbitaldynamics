defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineIntegrity do
  @moduledoc false

  alias __MODULE__.SourceReportFields
  alias __MODULE__.Summary

  def replay(refresh_or_artifact, callbacks) do
    source_report_summary = Keyword.fetch!(callbacks, :source_report_summary)

    source_report_summary_branch_family =
      Keyword.fetch!(callbacks, :source_report_summary_branch_family)

    branch_integrity_summary =
      source_report_summary_branch_family.(refresh_or_artifact, "timeline_integrity_report")

    integrity_summary =
      branch_integrity_summary ||
        refresh_or_artifact
        |> source_report_summary.()
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

  def source_report_fields(source_reports) do
    SourceReportFields.source_report_fields(source_reports)
  end

  def summary(integrity_summary, summary_source, replay_scope) do
    Summary.summary(integrity_summary, summary_source, replay_scope)
  end
end
