defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ResourceFilter.SourceReportFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ResourceFilter
  alias __MODULE__.Blocking
  alias __MODULE__.Direction
  alias __MODULE__.Identity
  alias __MODULE__.Suppression

  def source_report_fields(source_reports) do
    summary =
      source_reports
      |> Map.get("resource_filter_report", %{})
      |> ResourceFilter.summary(
        "candidate_refresh.source_report_provenance.resource_filter_report",
        "resource_filter_source_report_provenance_only"
      )

    %{
      "source_report_resource_filter_branch_local_resource_filter_pressure" =>
        Map.get(summary, "branch_local_resource_filter_pressure"),
      "source_report_resource_filter_branch_local_candidate_suppression_pressure" =>
        Map.get(summary, "branch_local_candidate_suppression_pressure"),
      "source_report_resource_filter_branch_local_invalid_resource_summary_pressure" =>
        Map.get(summary, "branch_local_invalid_resource_summary_pressure"),
      "source_report_resource_filter_branch_local_resource_blocking_pressure" =>
        Map.get(summary, "branch_local_resource_blocking_pressure")
    }
  end

  def source_report_summary_fields(source_reports) do
    source_reports
    |> source_report_fields()
    |> Map.merge(source_report_identity_fields(source_reports))
    |> Map.merge(source_report_suppression_fields(source_reports))
    |> Map.merge(source_report_blocking_fields(source_reports))
    |> Map.merge(source_report_direction_fields(source_reports))
  end

  def source_report_identity_fields(source_reports) do
    Identity.fields(source_reports)
  end

  def source_report_suppression_fields(source_reports) do
    Suppression.fields(source_reports)
  end

  def source_report_blocking_fields(source_reports) do
    Blocking.fields(source_reports)
  end

  def source_report_direction_fields(source_reports) do
    Direction.fields(source_reports)
  end
end
