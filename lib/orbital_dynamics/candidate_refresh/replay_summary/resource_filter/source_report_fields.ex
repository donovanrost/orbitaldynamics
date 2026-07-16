defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ResourceFilter.SourceReportFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ResourceFilter
  alias __MODULE__.Blocking
  alias __MODULE__.Direction
  alias __MODULE__.Identity
  alias __MODULE__.Pressure
  alias __MODULE__.Suppression

  def source_report_fields(source_reports) do
    summary =
      source_reports
      |> Map.get("resource_filter_report", %{})
      |> ResourceFilter.summary(
        "candidate_refresh.source_report_provenance.resource_filter_report",
        "resource_filter_source_report_provenance_only"
      )

    Pressure.source_report_fields(summary)
  end

  def source_report_summary_fields(source_reports) do
    source_reports
    |> source_report_fields()
    |> Map.merge(Identity.fields(source_reports))
    |> Map.merge(Suppression.fields(source_reports))
    |> Map.merge(Blocking.fields(source_reports))
    |> Map.merge(Direction.fields(source_reports))
  end
end
