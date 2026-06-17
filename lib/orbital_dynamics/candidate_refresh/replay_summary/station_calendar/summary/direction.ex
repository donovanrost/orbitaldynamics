defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.Summary.Direction do
  @moduledoc false

  def fields(station_summary) do
    %{
      "affected_contact_ids" => Map.get(station_summary, "affected_contact_ids", []),
      "affected_station_calendar_entry_ids" =>
        Map.get(station_summary, "affected_station_calendar_entry_ids", []),
      "affected_station_reservation_ids" =>
        Map.get(station_summary, "affected_station_reservation_ids", []),
      "direction_counts" => Map.get(station_summary, "direction_counts", %{}),
      "contact_ids_by_direction" => Map.get(station_summary, "contact_ids_by_direction", %{}),
      "station_calendar_entry_ids_by_direction" =>
        Map.get(station_summary, "station_calendar_entry_ids_by_direction", %{}),
      "station_reservation_ids_by_direction" =>
        Map.get(station_summary, "station_reservation_ids_by_direction", %{}),
      "station_capacity_fractions_by_direction" =>
        Map.get(station_summary, "station_capacity_fractions_by_direction", %{}),
      "direction_routing" => Map.get(station_summary, "direction_routing", %{})
    }
  end

  def pressure?(replay) do
    affected_contact_pressure?(replay) or present?(replay["direction_routing"])
  end

  def affected_contact_pressure?(replay) do
    [
      "affected_contact_ids",
      "affected_station_calendar_entry_ids",
      "affected_station_reservation_ids",
      "direction_counts",
      "contact_ids_by_direction",
      "station_calendar_entry_ids_by_direction",
      "station_reservation_ids_by_direction",
      "station_capacity_fractions_by_direction"
    ]
    |> Enum.any?(&(replay |> Map.get(&1) |> present?()))
  end

  defp present?(value) when is_map(value), do: map_size(value) > 0
  defp present?(value) when is_list(value), do: value != []
  defp present?(nil), do: false
  defp present?(_value), do: true
end
