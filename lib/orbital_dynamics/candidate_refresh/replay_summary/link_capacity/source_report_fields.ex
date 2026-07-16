defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.Summary
  alias __MODULE__.Pressure
  alias __MODULE__.Routing
  alias __MODULE__.Throughput

  import __MODULE__.Aggregation

  def source_report_fields(summary), do: Pressure.source_report_pressure_fields(summary)

  def source_report_summary_fields(source_reports) do
    source_reports
    |> Map.get("link_capacity_report", %{})
    |> Summary.summary(
      "candidate_refresh.source_report_provenance.link_capacity_report",
      "link_capacity_source_report_provenance_only"
    )
    |> source_report_fields()
    |> Map.merge(source_report_identity_fields(source_reports))
    |> Map.merge(Throughput.source_report_throughput_fields(source_reports))
    |> Map.merge(Routing.source_report_routing_fields(source_reports))
  end

  def source_report_identity_fields(source_reports) do
    %{
      "source_report_link_capacity_contract" =>
        source_report_family_field(source_reports, "contract"),
      "source_report_link_capacity_count" =>
        source_report_family_identity_count(source_reports, "count"),
      "source_report_link_capacity_row_count" =>
        source_report_family_identity_count(source_reports, "row_count"),
      "source_report_link_capacity_paths" =>
        source_report_family_identity_field(source_reports, "paths")
    }
  end
end
