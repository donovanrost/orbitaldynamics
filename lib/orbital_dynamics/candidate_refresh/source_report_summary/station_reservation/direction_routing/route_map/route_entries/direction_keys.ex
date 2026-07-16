defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationReservation.DirectionRouting.RouteMap.RouteEntries.DirectionKeys do
  @moduledoc false

  def values(inputs) do
    [
      map_keys(inputs.direction_counts),
      map_keys(inputs.contact_ids_by_direction),
      map_keys(inputs.reservation_hold_ids_by_direction),
      map_keys(inputs.reservation_hold_contact_ids_by_direction)
    ]
    |> List.flatten()
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp map_keys(%{} = map), do: Map.keys(map)
  defp map_keys(_map), do: []
end
