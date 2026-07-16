defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ResourceProjectionFlowSummaryPressureFields do
  @moduledoc false

  def from_summary(summary) do
    %{
      "resource_pressure_status" => Map.get(summary, "resource_pressure_status"),
      "resource_pressure_types" => Map.get(summary, "resource_pressure_types"),
      "resource_pressure_ground_station_ids_by_type" =>
        Map.get(summary, "resource_pressure_ground_station_ids_by_type"),
      "resource_pressure_source_window_ids_by_type" =>
        Map.get(summary, "resource_pressure_source_window_ids_by_type"),
      "resource_pressure_station_calendar_entry_ids_by_type" =>
        Map.get(summary, "resource_pressure_station_calendar_entry_ids_by_type"),
      "resource_pressure_station_calendar_provider_ids_by_type" =>
        Map.get(summary, "resource_pressure_station_calendar_provider_ids_by_type"),
      "resource_pressure_station_calendar_provider_entry_ids_by_type" =>
        Map.get(summary, "resource_pressure_station_calendar_provider_entry_ids_by_type")
    }
  end
end
