defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StorageDownlinkPressure do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StorageDownlinkPressure.Summary

  def replay(refresh_or_artifact, callbacks) do
    source_report_summary = Keyword.fetch!(callbacks, :source_report_summary)

    source_reports =
      refresh_or_artifact
      |> source_report_summary.()
      |> Map.get("source_reports", %{})

    summary(source_reports)
  end

  def source_report_fields(source_reports) do
    summary = summary(source_reports)

    %{
      "source_report_storage_downlink_pressure_branch_local_storage_downlink_pressure" =>
        Map.get(summary, "branch_local_storage_downlink_pressure"),
      "source_report_storage_downlink_pressure_branch_local_storage_pressure" =>
        Map.get(summary, "branch_local_storage_pressure"),
      "source_report_storage_downlink_pressure_branch_local_downlink_pressure" =>
        Map.get(summary, "branch_local_downlink_pressure"),
      "source_report_storage_downlink_pressure_branch_local_capacity_pack_pressure" =>
        Map.get(summary, "branch_local_capacity_pack_pressure"),
      "source_report_storage_downlink_pressure_branch_local_downlink_shortfall_pressure" =>
        Map.get(summary, "branch_local_downlink_shortfall_pressure"),
      "source_report_storage_downlink_pressure_branch_local_capacity_adjusted_throughput_pressure" =>
        Map.get(summary, "branch_local_capacity_adjusted_throughput_pressure"),
      "source_report_storage_downlink_pressure_branch_local_actual_throughput_pressure" =>
        Map.get(summary, "branch_local_actual_throughput_pressure"),
      "source_report_storage_downlink_pressure_branch_local_resource_activity_pressure" =>
        Map.get(summary, "branch_local_resource_activity_pressure"),
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
    }
  end

  def summary(source_reports) do
    Summary.summary(source_reports)
  end
end
