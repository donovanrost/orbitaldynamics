defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ResourceProjection.Summary.ResourcePressureFields do
  @moduledoc false

  def fields(projection_summary) do
    %{
      "resource_pressure_status_counts" =>
        Map.get(projection_summary, "resource_pressure_status_counts", %{}),
      "ground_station_counts" => Map.get(projection_summary, "ground_station_counts", %{}),
      "resource_projection_spacecraft_counts" =>
        Map.get(projection_summary, "resource_projection_spacecraft_counts", %{}),
      "resource_pressure_type_counts" =>
        Map.get(projection_summary, "resource_pressure_type_counts", %{}),
      "resource_pressure_activity_id_counts" =>
        Map.get(projection_summary, "resource_pressure_activity_id_counts", %{}),
      "resource_pressure_activity_ids_by_status" =>
        Map.get(projection_summary, "resource_pressure_activity_ids_by_status", %{}),
      "resource_pressure_activity_ids_by_type" =>
        Map.get(projection_summary, "resource_pressure_activity_ids_by_type", %{}),
      "resource_pressure_activity_ids_by_ground_station" =>
        Map.get(projection_summary, "resource_pressure_activity_ids_by_ground_station", %{}),
      "resource_pressure_activity_ids_by_spacecraft" =>
        Map.get(projection_summary, "resource_pressure_activity_ids_by_spacecraft", %{}),
      "resource_pressure_direction_counts" =>
        Map.get(projection_summary, "resource_pressure_direction_counts", %{}),
      "resource_pressure_directions" =>
        Map.get(projection_summary, "resource_pressure_directions", []),
      "resource_pressure_activity_ids_by_direction" =>
        Map.get(projection_summary, "resource_pressure_activity_ids_by_direction", %{}),
      "resource_pressure_direction_routing" =>
        Map.get(projection_summary, "resource_pressure_direction_routing", %{}),
      "resource_pressure_ground_station_ids_by_type" =>
        Map.get(projection_summary, "resource_pressure_ground_station_ids_by_type"),
      "resource_pressure_source_window_ids_by_status" =>
        Map.get(projection_summary, "resource_pressure_source_window_ids_by_status"),
      "resource_pressure_source_window_ids_by_type" =>
        Map.get(projection_summary, "resource_pressure_source_window_ids_by_type"),
      "resource_pressure_station_calendar_entry_ids_by_status" =>
        Map.get(projection_summary, "resource_pressure_station_calendar_entry_ids_by_status"),
      "resource_pressure_station_calendar_entry_ids_by_type" =>
        Map.get(projection_summary, "resource_pressure_station_calendar_entry_ids_by_type"),
      "resource_pressure_station_calendar_provider_ids_by_status" =>
        Map.get(projection_summary, "resource_pressure_station_calendar_provider_ids_by_status"),
      "resource_pressure_station_calendar_provider_ids_by_type" =>
        Map.get(projection_summary, "resource_pressure_station_calendar_provider_ids_by_type"),
      "resource_pressure_station_calendar_provider_entry_ids_by_status" =>
        Map.get(
          projection_summary,
          "resource_pressure_station_calendar_provider_entry_ids_by_status"
        ),
      "resource_pressure_station_calendar_provider_entry_ids_by_type" =>
        Map.get(
          projection_summary,
          "resource_pressure_station_calendar_provider_entry_ids_by_type"
        ),
      "invalid_activity_input_ids" => Map.get(projection_summary, "invalid_activity_input_ids"),
      "invalid_resource_summary_input_ids" =>
        Map.get(projection_summary, "invalid_resource_summary_input_ids")
    }
  end
end
