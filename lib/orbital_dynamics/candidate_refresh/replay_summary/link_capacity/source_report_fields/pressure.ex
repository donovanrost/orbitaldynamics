defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Pressure do
  @moduledoc false

  def source_report_pressure_fields(summary) do
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
end
