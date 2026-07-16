defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationReservation.DirectionRouting.RouteMap do
  @moduledoc false

  alias __MODULE__.RouteEntries

  def build(
        direction_counts,
        contact_ids_by_direction,
        reservation_hold_ids_by_direction,
        reservation_hold_contact_ids_by_direction
      ) do
    RouteEntries.build(
      direction_counts,
      contact_ids_by_direction,
      reservation_hold_ids_by_direction,
      reservation_hold_contact_ids_by_direction
    )
  end
end
