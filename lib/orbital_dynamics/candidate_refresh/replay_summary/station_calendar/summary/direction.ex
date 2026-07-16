defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.Summary.Direction do
  @moduledoc false

  @list_route_fields [
    "contact_ids",
    "station_calendar_entry_ids",
    "station_reservation_ids",
    "station_capacity_fractions",
    "provider_contention_group_ids",
    "provider_contention_source_entry_ids",
    "provider_contention_provider_ids",
    "provider_contention_provider_entry_ids",
    "provider_contention_capacity_fractions"
  ]

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
      "direction_routing" =>
        station_summary
        |> Map.get("direction_routing", %{})
        |> normalize_direction_routing()
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

  defp normalize_direction_routing(%{} = direction_routing) do
    Map.new(direction_routing, fn {direction, route} ->
      {direction, normalize_route(route)}
    end)
  end

  defp normalize_direction_routing(_direction_routing), do: %{}

  defp normalize_route(%{} = route) do
    Enum.reduce(@list_route_fields, route, fn field, acc ->
      Map.update(acc, field, [], &normalize_route_list/1)
    end)
  end

  defp normalize_route(_route), do: %{}

  defp normalize_route_list(%{}), do: []
  defp normalize_route_list(values) when is_list(values), do: values
  defp normalize_route_list(nil), do: []
  defp normalize_route_list(value), do: [value]
end
