defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.OperationalTimeline do
  @moduledoc false

  alias __MODULE__.SourceReportFields
  alias __MODULE__.Summary

  def replay(refresh_or_artifact, callbacks) do
    source_report_summary = Keyword.fetch!(callbacks, :source_report_summary)

    source_report_summary_branch_family =
      Keyword.fetch!(callbacks, :source_report_summary_branch_family)

    branch_timeline_summary =
      source_report_summary_branch_family.(refresh_or_artifact, "operational_timeline_report")

    timeline_summary =
      branch_timeline_summary ||
        refresh_or_artifact
        |> source_report_summary.()
        |> get_in(["source_reports", "operational_timeline_report"]) ||
        %{}

    {summary_source, replay_scope} =
      if branch_timeline_summary do
        {
          "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.operational_timeline_report",
          "operational_timeline_candidate_source_report_summary_only"
        }
      else
        {
          "candidate_refresh.source_report_provenance.operational_timeline_report",
          "operational_timeline_source_report_provenance_only"
        }
      end

    summary(timeline_summary, summary_source, replay_scope)
  end

  def source_report_fields(source_reports) do
    summary =
      source_reports
      |> Map.get("operational_timeline_report", %{})
      |> summary(
        "candidate_refresh.source_report_provenance.operational_timeline_report",
        "operational_timeline_source_report_provenance_only"
      )

    SourceReportFields.source_report_fields(source_reports, summary)
  end

  def summary(timeline_summary, summary_source, replay_scope) do
    Summary.summary(timeline_summary, summary_source, replay_scope)
  end
end
