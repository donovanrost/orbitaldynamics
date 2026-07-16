defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StorageDownlinkPressure.SourceReportFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StorageDownlinkPressure.Summary
  alias __MODULE__.Pressure

  def source_report_summary_fields(source_reports) do
    summary = Summary.summary(source_reports)

    summary
    |> Pressure.source_report_fields()
    |> Map.merge(%{
      "source_report_storage_downlink_pressure_capacity_adjusted_throughput_row_count" =>
        Map.get(summary, "capacity_adjusted_throughput_row_count"),
      "source_report_storage_downlink_pressure_capacity_adjusted_throughput_mb_by_ground_station" =>
        Map.get(summary, "capacity_adjusted_throughput_mb_by_ground_station"),
      "source_report_storage_downlink_pressure_capacity_adjusted_throughput_mb_by_direction" =>
        Map.get(summary, "capacity_adjusted_throughput_mb_by_direction"),
      "source_report_storage_downlink_pressure_selected_capacity_adjusted_throughput_mb_by_ground_station" =>
        Map.get(summary, "selected_capacity_adjusted_throughput_mb_by_ground_station"),
      "source_report_storage_downlink_pressure_unused_capacity_adjusted_throughput_mb_by_ground_station" =>
        Map.get(summary, "unused_capacity_adjusted_throughput_mb_by_ground_station"),
      "source_report_storage_downlink_pressure_resource_pressure_station_calendar_provider_ids_by_type" =>
        Map.get(summary, "resource_pressure_station_calendar_provider_ids_by_type"),
      "source_report_storage_downlink_pressure_resource_pressure_station_calendar_provider_entry_ids_by_type" =>
        Map.get(summary, "resource_pressure_station_calendar_provider_entry_ids_by_type")
    })
  end
end
