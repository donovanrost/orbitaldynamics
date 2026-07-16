defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StorageDownlinkPressure.SourceReportFields.Pressure do
  @moduledoc false

  def source_report_fields(summary) do
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
        Map.get(summary, "branch_local_resource_activity_pressure")
    }
  end
end
