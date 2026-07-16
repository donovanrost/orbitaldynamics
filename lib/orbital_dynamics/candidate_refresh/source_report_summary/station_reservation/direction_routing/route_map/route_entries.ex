defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationReservation.DirectionRouting.RouteMap.RouteEntries do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationReservation.DirectionRouting.RouteMap.Inputs
  alias __MODULE__.{DirectionKeys, Entry}

  def build(
        direction_counts,
        contact_ids_by_direction,
        reservation_hold_ids_by_direction,
        reservation_hold_contact_ids_by_direction
      ) do
    inputs =
      Inputs.build(
        direction_counts,
        contact_ids_by_direction,
        reservation_hold_ids_by_direction,
        reservation_hold_contact_ids_by_direction
      )

    inputs
    |> DirectionKeys.values()
    |> Map.new(fn direction ->
      {direction, Entry.build(direction, inputs)}
    end)
    |> non_empty_map()
  end

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
