defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationReservation.DirectionRouting.RouteMap.Inputs do
  @moduledoc false

  alias __MODULE__.ValueListMaps

  def build(
        direction_counts,
        contact_ids_by_direction,
        reservation_hold_ids_by_direction,
        reservation_hold_contact_ids_by_direction
      ) do
    %{
      direction_counts: empty_map_if_nil(direction_counts),
      contact_ids_by_direction: ValueListMaps.from(contact_ids_by_direction) || %{},
      reservation_hold_ids_by_direction:
        ValueListMaps.from(reservation_hold_ids_by_direction) || %{},
      reservation_hold_contact_ids_by_direction:
        ValueListMaps.from(reservation_hold_contact_ids_by_direction) || %{}
    }
  end

  defp empty_map_if_nil(%{} = map), do: map
  defp empty_map_if_nil(_map), do: %{}
end
