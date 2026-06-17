defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ResourceProjection do
  @moduledoc false

  alias __MODULE__.SourceReportFields
  alias __MODULE__.Summary

  def replay(refresh_or_artifact, callbacks) do
    source_report_summary = Keyword.fetch!(callbacks, :source_report_summary)

    source_report_summary_branch_family =
      Keyword.fetch!(callbacks, :source_report_summary_branch_family)

    branch_projection_summary =
      source_report_summary_branch_family.(refresh_or_artifact, "resource_projection_report")

    projection_summary =
      branch_projection_summary ||
        refresh_or_artifact
        |> source_report_summary.()
        |> get_in(["source_reports", "resource_projection_report"]) ||
        %{}

    {summary_source, replay_scope} =
      if branch_projection_summary do
        {
          "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.resource_projection_report",
          "resource_projection_candidate_source_report_summary_only"
        }
      else
        {
          "candidate_refresh.source_report_provenance.resource_projection_report",
          "resource_projection_source_report_provenance_only"
        }
      end

    summary(projection_summary, summary_source, replay_scope)
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

  def source_report_source_metadata_fields(source_reports) do
    SourceReportFields.source_report_source_metadata_fields(source_reports)
  end

  def source_report_invalid_input_fields(source_reports) do
    SourceReportFields.source_report_invalid_input_fields(source_reports)
  end

  def source_report_pressure_routing_fields(source_reports) do
    SourceReportFields.source_report_pressure_routing_fields(source_reports)
  end

  def source_report_pressure_evidence_fields(source_reports) do
    SourceReportFields.source_report_pressure_evidence_fields(source_reports)
  end

  def summary(projection_summary, summary_source, replay_scope) do
    Summary.summary(projection_summary, summary_source, replay_scope)
  end
end
