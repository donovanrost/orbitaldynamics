defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ProviderCounteroffer do
  @moduledoc false

  alias __MODULE__.SourceReportFields
  alias __MODULE__.Summary

  def replay(refresh_or_artifact, callbacks) do
    source_report_summary = Keyword.fetch!(callbacks, :source_report_summary)

    source_report_summary_branch_family =
      Keyword.fetch!(callbacks, :source_report_summary_branch_family)

    branch_counteroffer_summary =
      source_report_summary_branch_family.(refresh_or_artifact, "provider_counteroffer_report")

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

  def source_report_fields(source_reports) do
    SourceReportFields.source_report_fields(source_reports)
  end

  def source_report_summary_fields(source_reports) do
    SourceReportFields.source_report_summary_fields(source_reports)
  end

  def source_report_identity_and_core_fields(source_reports) do
    SourceReportFields.source_report_identity_and_core_fields(source_reports)
  end

  def source_report_review_import_fields(source_reports) do
    SourceReportFields.source_report_review_import_fields(source_reports)
  end

  def source_report_plan_impact_fields(source_reports) do
    SourceReportFields.source_report_plan_impact_fields(source_reports)
  end
end
