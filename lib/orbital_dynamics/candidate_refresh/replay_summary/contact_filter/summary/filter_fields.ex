defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactFilter.Summary.FilterFields do
  @moduledoc false

  def fields(filter_summary) do
    %{
      "invalid_contact_input_ids" => Map.get(filter_summary, "invalid_contact_input_ids"),
      "suppressed_reason_counts" => Map.get(filter_summary, "suppressed_reason_counts", %{}),
      "contact_ids_by_suppressed_reason" =>
        Map.get(filter_summary, "contact_ids_by_suppressed_reason", %{}),
      "direction_counts" => Map.get(filter_summary, "direction_counts", %{}),
      "directions" => Map.get(filter_summary, "directions", []),
      "contact_ids_by_direction" => Map.get(filter_summary, "contact_ids_by_direction", %{}),
      "direction_routing" => Map.get(filter_summary, "direction_routing", %{}),
      "station_suppression_ground_station_counts" =>
        Map.get(filter_summary, "station_suppression_ground_station_counts", %{}),
      "station_suppression_availability_counts" =>
        Map.get(filter_summary, "station_suppression_availability_counts", %{}),
      "station_suppression_status_counts" =>
        Map.get(filter_summary, "station_suppression_status_counts", %{}),
      "station_suppression_contact_ids_by_ground_station" =>
        Map.get(filter_summary, "station_suppression_contact_ids_by_ground_station", %{}),
      "station_suppression_contact_ids_by_availability" =>
        Map.get(filter_summary, "station_suppression_contact_ids_by_availability", %{}),
      "station_suppression_contact_ids_by_status" =>
        Map.get(filter_summary, "station_suppression_contact_ids_by_status", %{}),
      "station_suppression_station_calendar_entry_ids_by_ground_station" =>
        Map.get(
          filter_summary,
          "station_suppression_station_calendar_entry_ids_by_ground_station",
          %{}
        ),
      "station_suppression_station_calendar_entry_ids_by_availability" =>
        Map.get(
          filter_summary,
          "station_suppression_station_calendar_entry_ids_by_availability",
          %{}
        ),
      "station_suppression_station_calendar_entry_ids_by_status" =>
        Map.get(filter_summary, "station_suppression_station_calendar_entry_ids_by_status", %{}),
      "station_suppression_station_calendar_provider_entry_ids_by_ground_station" =>
        Map.get(
          filter_summary,
          "station_suppression_station_calendar_provider_entry_ids_by_ground_station",
          %{}
        ),
      "station_suppression_station_calendar_provider_entry_ids_by_availability" =>
        Map.get(
          filter_summary,
          "station_suppression_station_calendar_provider_entry_ids_by_availability",
          %{}
        ),
      "station_suppression_station_calendar_provider_entry_ids_by_status" =>
        Map.get(
          filter_summary,
          "station_suppression_station_calendar_provider_entry_ids_by_status",
          %{}
        ),
      "station_suppression_station_reservation_ids_by_ground_station" =>
        Map.get(
          filter_summary,
          "station_suppression_station_reservation_ids_by_ground_station",
          %{}
        ),
      "station_suppression_station_reservation_ids_by_availability" =>
        Map.get(
          filter_summary,
          "station_suppression_station_reservation_ids_by_availability",
          %{}
        ),
      "station_suppression_station_reservation_ids_by_status" =>
        Map.get(filter_summary, "station_suppression_station_reservation_ids_by_status", %{})
    }
  end
end
