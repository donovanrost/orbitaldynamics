defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactFilter do
  @moduledoc false

  alias __MODULE__.SourceReportFields
  alias __MODULE__.Summary

  def replay(refresh_or_artifact, callbacks) do
    source_report_summary = Keyword.fetch!(callbacks, :source_report_summary)

    source_report_summary_branch_family =
      Keyword.fetch!(callbacks, :source_report_summary_branch_family)

    branch_filter_summary =
      source_report_summary_branch_family.(refresh_or_artifact, "contact_filter_report")

    filter_summary =
      branch_filter_summary ||
        refresh_or_artifact
        |> source_report_summary.()
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

  def source_report_fields(source_reports) do
    SourceReportFields.source_report_fields(source_reports)
  end

  def source_report_summary_fields(source_reports) do
    SourceReportFields.source_report_summary_fields(source_reports)
  end

  def source_report_identity_fields(source_reports) do
    SourceReportFields.source_report_identity_fields(source_reports)
  end

  def source_report_suppression_fields(source_reports) do
    SourceReportFields.source_report_suppression_fields(source_reports)
  end

  def source_report_direction_fields(source_reports) do
    SourceReportFields.source_report_direction_fields(source_reports)
  end

  def source_report_station_suppression_fields(source_reports) do
    SourceReportFields.source_report_station_suppression_fields(source_reports)
  end

  def summary(filter_summary, summary_source, replay_scope) do
    Summary.summary(filter_summary, summary_source, replay_scope)
  end
end
