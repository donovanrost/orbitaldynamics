defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ResourceProjection.Summary.Pressure do
  @moduledoc false

  def fields(
        resource_pressure_fields,
        projected_resource_count,
        invalid_activity_input_count,
        invalid_resource_summary_input_count
      ) do
    resource_pressure_status_counts =
      Map.get(resource_pressure_fields, "resource_pressure_status_counts", %{})

    ground_station_counts = Map.get(resource_pressure_fields, "ground_station_counts", %{})

    spacecraft_counts =
      Map.get(resource_pressure_fields, "resource_projection_spacecraft_counts", %{})

    resource_pressure_type_counts =
      Map.get(resource_pressure_fields, "resource_pressure_type_counts", %{})

    resource_pressure_activity_id_counts =
      Map.get(resource_pressure_fields, "resource_pressure_activity_id_counts", %{})

    resource_pressure_activity_ids_by_status =
      Map.get(resource_pressure_fields, "resource_pressure_activity_ids_by_status", %{})

    resource_pressure_activity_ids_by_type =
      Map.get(resource_pressure_fields, "resource_pressure_activity_ids_by_type", %{})

    resource_pressure_activity_ids_by_ground_station =
      Map.get(resource_pressure_fields, "resource_pressure_activity_ids_by_ground_station", %{})

    resource_pressure_activity_ids_by_spacecraft =
      Map.get(resource_pressure_fields, "resource_pressure_activity_ids_by_spacecraft", %{})

    resource_pressure_direction_counts =
      Map.get(resource_pressure_fields, "resource_pressure_direction_counts", %{})

    resource_pressure_directions =
      Map.get(resource_pressure_fields, "resource_pressure_directions", [])

    resource_pressure_activity_ids_by_direction =
      Map.get(resource_pressure_fields, "resource_pressure_activity_ids_by_direction", %{})

    resource_pressure_direction_routing =
      Map.get(resource_pressure_fields, "resource_pressure_direction_routing", %{})

    resource_pressure_ground_station_ids_by_type =
      Map.get(resource_pressure_fields, "resource_pressure_ground_station_ids_by_type")

    resource_pressure_source_window_ids_by_status =
      Map.get(resource_pressure_fields, "resource_pressure_source_window_ids_by_status")

    resource_pressure_source_window_ids_by_type =
      Map.get(resource_pressure_fields, "resource_pressure_source_window_ids_by_type")

    resource_pressure_station_calendar_entry_ids_by_status =
      Map.get(resource_pressure_fields, "resource_pressure_station_calendar_entry_ids_by_status")

    resource_pressure_station_calendar_entry_ids_by_type =
      Map.get(resource_pressure_fields, "resource_pressure_station_calendar_entry_ids_by_type")

    resource_pressure_station_calendar_provider_ids_by_status =
      Map.get(
        resource_pressure_fields,
        "resource_pressure_station_calendar_provider_ids_by_status"
      )

    resource_pressure_station_calendar_provider_ids_by_type =
      Map.get(resource_pressure_fields, "resource_pressure_station_calendar_provider_ids_by_type")

    resource_pressure_station_calendar_provider_entry_ids_by_status =
      Map.get(
        resource_pressure_fields,
        "resource_pressure_station_calendar_provider_entry_ids_by_status"
      )

    resource_pressure_station_calendar_provider_entry_ids_by_type =
      Map.get(
        resource_pressure_fields,
        "resource_pressure_station_calendar_provider_entry_ids_by_type"
      )

    invalid_activity_input_ids = Map.get(resource_pressure_fields, "invalid_activity_input_ids")

    invalid_resource_summary_input_ids =
      Map.get(resource_pressure_fields, "invalid_resource_summary_input_ids")

    resource_routing_pressure =
      map_size(resource_pressure_status_counts) > 0 or map_size(resource_pressure_type_counts) > 0 or
        map_size(ground_station_counts) > 0 or map_size(spacecraft_counts) > 0 or
        map_size(resource_pressure_activity_id_counts) > 0 or
        map_size(resource_pressure_activity_ids_by_status) > 0 or
        map_size(resource_pressure_activity_ids_by_type) > 0 or
        map_size(resource_pressure_activity_ids_by_ground_station) > 0 or
        map_size(resource_pressure_activity_ids_by_spacecraft) > 0 or
        map_size(resource_pressure_direction_counts) > 0 or
        length(List.wrap(resource_pressure_directions)) > 0 or
        map_size(resource_pressure_activity_ids_by_direction) > 0 or
        map_size(resource_pressure_direction_routing) > 0 or
        map_size(resource_pressure_ground_station_ids_by_type || %{}) > 0 or
        map_size(resource_pressure_source_window_ids_by_status || %{}) > 0 or
        map_size(resource_pressure_source_window_ids_by_type || %{}) > 0 or
        map_size(resource_pressure_station_calendar_entry_ids_by_status || %{}) > 0 or
        map_size(resource_pressure_station_calendar_entry_ids_by_type || %{}) > 0 or
        map_size(resource_pressure_station_calendar_provider_ids_by_status || %{}) > 0 or
        map_size(resource_pressure_station_calendar_provider_ids_by_type || %{}) > 0 or
        map_size(resource_pressure_station_calendar_provider_entry_ids_by_status || %{}) > 0 or
        map_size(resource_pressure_station_calendar_provider_entry_ids_by_type || %{}) > 0

    invalid_input_pressure =
      invalid_activity_input_count + invalid_resource_summary_input_count > 0 or
        invalid_activity_input_ids not in [nil, []] or
        invalid_resource_summary_input_ids not in [nil, []]

    activity_pressure =
      map_size(resource_pressure_activity_id_counts) > 0 or
        map_size(resource_pressure_activity_ids_by_status) > 0 or
        map_size(resource_pressure_activity_ids_by_type) > 0 or
        map_size(resource_pressure_activity_ids_by_ground_station) > 0 or
        map_size(resource_pressure_activity_ids_by_spacecraft) > 0 or
        map_size(resource_pressure_activity_ids_by_direction) > 0

    %{
      "branch_local_resource_projection_pressure" =>
        projected_resource_count > 0 or invalid_input_pressure or resource_routing_pressure,
      "branch_local_projected_resource_pressure" =>
        projected_resource_count > 0 or resource_routing_pressure,
      "branch_local_invalid_resource_projection_pressure" => invalid_input_pressure,
      "branch_local_activity_pressure" => activity_pressure
    }
  end
end
