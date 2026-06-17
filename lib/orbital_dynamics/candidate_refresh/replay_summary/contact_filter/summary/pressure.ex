defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactFilter.Summary.Pressure do
  @moduledoc false

  def fields(
        filter_fields,
        suppressed_candidate_count,
        invalid_contact_input_count,
        station_suppression_count
      ) do
    invalid_contact_input_ids = Map.get(filter_fields, "invalid_contact_input_ids")
    suppressed_reason_counts = Map.get(filter_fields, "suppressed_reason_counts", %{})

    contact_ids_by_suppressed_reason =
      Map.get(filter_fields, "contact_ids_by_suppressed_reason", %{})

    direction_counts = Map.get(filter_fields, "direction_counts", %{})
    directions = Map.get(filter_fields, "directions", [])
    contact_ids_by_direction = Map.get(filter_fields, "contact_ids_by_direction", %{})
    direction_routing = Map.get(filter_fields, "direction_routing", %{})

    station_suppression_ground_station_counts =
      Map.get(filter_fields, "station_suppression_ground_station_counts", %{})

    station_suppression_availability_counts =
      Map.get(filter_fields, "station_suppression_availability_counts", %{})

    station_suppression_status_counts =
      Map.get(filter_fields, "station_suppression_status_counts", %{})

    station_suppression_contact_ids_by_ground_station =
      Map.get(filter_fields, "station_suppression_contact_ids_by_ground_station", %{})

    station_suppression_contact_ids_by_availability =
      Map.get(filter_fields, "station_suppression_contact_ids_by_availability", %{})

    station_suppression_contact_ids_by_status =
      Map.get(filter_fields, "station_suppression_contact_ids_by_status", %{})

    station_suppression_station_calendar_entry_ids_by_ground_station =
      Map.get(
        filter_fields,
        "station_suppression_station_calendar_entry_ids_by_ground_station",
        %{}
      )

    station_suppression_station_calendar_entry_ids_by_availability =
      Map.get(
        filter_fields,
        "station_suppression_station_calendar_entry_ids_by_availability",
        %{}
      )

    station_suppression_station_calendar_entry_ids_by_status =
      Map.get(filter_fields, "station_suppression_station_calendar_entry_ids_by_status", %{})

    station_suppression_station_calendar_provider_entry_ids_by_ground_station =
      Map.get(
        filter_fields,
        "station_suppression_station_calendar_provider_entry_ids_by_ground_station",
        %{}
      )

    station_suppression_station_calendar_provider_entry_ids_by_availability =
      Map.get(
        filter_fields,
        "station_suppression_station_calendar_provider_entry_ids_by_availability",
        %{}
      )

    station_suppression_station_calendar_provider_entry_ids_by_status =
      Map.get(
        filter_fields,
        "station_suppression_station_calendar_provider_entry_ids_by_status",
        %{}
      )

    station_suppression_station_reservation_ids_by_ground_station =
      Map.get(
        filter_fields,
        "station_suppression_station_reservation_ids_by_ground_station",
        %{}
      )

    station_suppression_station_reservation_ids_by_availability =
      Map.get(filter_fields, "station_suppression_station_reservation_ids_by_availability", %{})

    station_suppression_station_reservation_ids_by_status =
      Map.get(filter_fields, "station_suppression_station_reservation_ids_by_status", %{})

    candidate_suppression_pressure =
      suppressed_candidate_count > 0 or map_size(suppressed_reason_counts) > 0 or
        map_size(contact_ids_by_suppressed_reason) > 0 or map_size(direction_counts) > 0 or
        length(List.wrap(directions)) > 0 or map_size(contact_ids_by_direction) > 0 or
        map_size(direction_routing) > 0

    invalid_contact_input_pressure =
      invalid_contact_input_count > 0 or invalid_contact_input_ids not in [nil, []]

    station_suppression_pressure =
      station_suppression_count > 0 or map_size(station_suppression_ground_station_counts) > 0 or
        map_size(station_suppression_availability_counts) > 0 or
        map_size(station_suppression_status_counts) > 0 or
        map_size(station_suppression_contact_ids_by_ground_station) > 0 or
        map_size(station_suppression_contact_ids_by_availability) > 0 or
        map_size(station_suppression_contact_ids_by_status) > 0 or
        map_size(station_suppression_station_calendar_entry_ids_by_ground_station) > 0 or
        map_size(station_suppression_station_calendar_entry_ids_by_availability) > 0 or
        map_size(station_suppression_station_calendar_entry_ids_by_status) > 0 or
        map_size(station_suppression_station_calendar_provider_entry_ids_by_ground_station) > 0 or
        map_size(station_suppression_station_calendar_provider_entry_ids_by_availability) > 0 or
        map_size(station_suppression_station_calendar_provider_entry_ids_by_status) > 0 or
        map_size(station_suppression_station_reservation_ids_by_ground_station) > 0 or
        map_size(station_suppression_station_reservation_ids_by_availability) > 0 or
        map_size(station_suppression_station_reservation_ids_by_status) > 0

    %{
      "branch_local_contact_filter_pressure" =>
        candidate_suppression_pressure or invalid_contact_input_pressure or
          station_suppression_pressure,
      "branch_local_candidate_suppression_pressure" => candidate_suppression_pressure,
      "branch_local_invalid_contact_input_pressure" => invalid_contact_input_pressure,
      "branch_local_station_suppression_pressure" => station_suppression_pressure
    }
  end
end
