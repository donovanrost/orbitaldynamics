defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.Summary.ReservationCapacityStatus do
  @moduledoc false

  @availability_pressure_fields [
    "station_calendar_status_counts",
    "affected_contact_availability_counts",
    "contact_ids_by_status",
    "contact_ids_by_availability",
    "station_calendar_entry_ids_by_status",
    "station_calendar_entry_ids_by_availability",
    "station_reservation_ids_by_status",
    "station_reservation_ids_by_availability",
    "reserved_by_counts",
    "contact_ids_by_reserved_by",
    "station_calendar_entry_ids_by_reserved_by",
    "station_reservation_ids_by_reserved_by",
    "station_reservation_expires_at_s",
    "earliest_station_reservation_expires_at_s",
    "station_capacity_fractions",
    "minimum_station_capacity_fraction",
    "station_capacity_fractions_by_status",
    "station_capacity_fractions_by_ground_station",
    "station_capacity_fractions_by_availability"
  ]

  def fields(station_summary) do
    %{
      "reserved_by_counts" => Map.get(station_summary, "reserved_by_counts", %{}),
      "contact_ids_by_reserved_by" => Map.get(station_summary, "contact_ids_by_reserved_by", %{}),
      "station_calendar_entry_ids_by_reserved_by" =>
        Map.get(station_summary, "station_calendar_entry_ids_by_reserved_by", %{}),
      "station_reservation_ids_by_reserved_by" =>
        Map.get(station_summary, "station_reservation_ids_by_reserved_by", %{}),
      "station_reservation_expires_at_s" =>
        Map.get(station_summary, "station_reservation_expires_at_s", []),
      "earliest_station_reservation_expires_at_s" =>
        Map.get(station_summary, "earliest_station_reservation_expires_at_s"),
      "station_capacity_fractions" => Map.get(station_summary, "station_capacity_fractions", []),
      "minimum_station_capacity_fraction" =>
        Map.get(station_summary, "minimum_station_capacity_fraction"),
      "station_capacity_fractions_by_status" =>
        Map.get(station_summary, "station_capacity_fractions_by_status", %{}),
      "station_capacity_fractions_by_ground_station" =>
        Map.get(station_summary, "station_capacity_fractions_by_ground_station", %{}),
      "station_capacity_fractions_by_availability" =>
        Map.get(station_summary, "station_capacity_fractions_by_availability", %{}),
      "contact_ids_by_status" => Map.get(station_summary, "contact_ids_by_status", %{}),
      "contact_ids_by_ground_station" =>
        Map.get(station_summary, "contact_ids_by_ground_station", %{}),
      "contact_ids_by_availability" =>
        Map.get(station_summary, "contact_ids_by_availability", %{}),
      "station_calendar_entry_ids_by_status" =>
        Map.get(station_summary, "station_calendar_entry_ids_by_status", %{}),
      "station_calendar_entry_ids_by_ground_station" =>
        Map.get(station_summary, "station_calendar_entry_ids_by_ground_station", %{}),
      "station_calendar_entry_ids_by_availability" =>
        Map.get(station_summary, "station_calendar_entry_ids_by_availability", %{}),
      "station_reservation_ids_by_status" =>
        Map.get(station_summary, "station_reservation_ids_by_status", %{}),
      "station_reservation_ids_by_ground_station" =>
        Map.get(station_summary, "station_reservation_ids_by_ground_station", %{}),
      "station_reservation_ids_by_availability" =>
        Map.get(station_summary, "station_reservation_ids_by_availability", %{}),
      "station_calendar_status_counts" =>
        Map.get(station_summary, "station_calendar_status_counts", %{}),
      "affected_contact_ground_station_counts" =>
        Map.get(station_summary, "affected_contact_ground_station_counts", %{}),
      "affected_contact_availability_counts" =>
        Map.get(station_summary, "affected_contact_availability_counts", %{})
    }
  end

  def pressure?(replay) do
    Enum.any?(replay, fn {_field, value} -> present?(value) end)
  end

  def availability_pressure?(replay) do
    Enum.any?(@availability_pressure_fields, &(replay |> Map.get(&1) |> present?()))
  end

  defp present?(value) when is_map(value), do: map_size(value) > 0
  defp present?(value) when is_list(value), do: value != []
  defp present?(nil), do: false
  defp present?(_value), do: true
end
