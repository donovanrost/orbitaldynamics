defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields
  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.Summary

  def replay(refresh_or_artifact, callbacks) do
    source_report_summary = Keyword.fetch!(callbacks, :source_report_summary)

    source_report_summary_branch_family =
      Keyword.fetch!(callbacks, :source_report_summary_branch_family)

    branch_link_summary =
      source_report_summary_branch_family.(refresh_or_artifact, "link_capacity_report")

    link_summary =
      branch_link_summary ||
        refresh_or_artifact
        |> source_report_summary.()
        |> get_in(["source_reports", "link_capacity_report"]) ||
        %{}

    {summary_source, replay_scope} =
      if branch_link_summary do
        {
          "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.link_capacity_report",
          "link_capacity_candidate_source_report_summary_only"
        }
      else
        {
          "candidate_refresh.source_report_provenance.link_capacity_report",
          "link_capacity_source_report_provenance_only"
        }
      end

    summary(link_summary, summary_source, replay_scope)
  end

  def source_report_fields(source_reports) do
    source_reports
    |> Map.get("link_capacity_report", %{})
    |> summary(
      "candidate_refresh.source_report_provenance.link_capacity_report",
      "link_capacity_source_report_provenance_only"
    )
    |> SourceReportFields.source_report_fields()
  end

  def source_report_summary_fields(source_reports) do
    pressure_fields = source_report_fields(source_reports)

    SourceReportFields.source_report_summary_fields(source_reports, pressure_fields)
  end

  def source_report_identity_fields(source_reports),
    do: SourceReportFields.source_report_identity_fields(source_reports)

  def source_report_throughput_fields(source_reports),
    do: SourceReportFields.source_report_throughput_fields(source_reports)

  def source_report_routing_fields(source_reports),
    do: SourceReportFields.source_report_routing_fields(source_reports)

  def summary(link_summary, summary_source, replay_scope),
    do: Summary.summary(link_summary, summary_source, replay_scope)
end
