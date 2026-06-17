defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields do
  @moduledoc false

  alias __MODULE__.Routing
  alias __MODULE__.Throughput

  import __MODULE__.Aggregation

  def source_report_fields(summary) do
    %{
      "source_report_link_capacity_branch_local_link_capacity_pressure" =>
        Map.get(summary, "branch_local_link_capacity_pressure"),
      "source_report_link_capacity_branch_local_capacity_adjusted_throughput_pressure" =>
        Map.get(summary, "branch_local_capacity_adjusted_throughput_pressure"),
      "source_report_link_capacity_branch_local_downlink_shortfall_pressure" =>
        Map.get(summary, "branch_local_downlink_shortfall_pressure"),
      "source_report_link_capacity_branch_local_actual_throughput_pressure" =>
        Map.get(summary, "branch_local_actual_throughput_pressure")
    }
  end

  def source_report_summary_fields(source_reports, pressure_fields) do
    pressure_fields
    |> Map.merge(source_report_identity_fields(source_reports))
    |> Map.merge(source_report_throughput_fields(source_reports))
    |> Map.merge(source_report_routing_fields(source_reports))
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

  def source_report_throughput_fields(source_reports) do
    Throughput.source_report_throughput_fields(source_reports)
  end

  def source_report_routing_fields(source_reports) do
    Routing.source_report_routing_fields(source_reports)
  end
end
