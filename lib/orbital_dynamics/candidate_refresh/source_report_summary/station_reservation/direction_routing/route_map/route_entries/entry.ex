defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationReservation.DirectionRouting.RouteMap.RouteEntries.Entry do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      compact_map: 1
    ]

  def build(direction, inputs) do
    %{
      "contact_count" => Map.get(inputs.direction_counts, direction),
      "contact_ids" => Map.get(inputs.contact_ids_by_direction, direction, []),
      "reservation_hold_ids" => Map.get(inputs.reservation_hold_ids_by_direction, direction, []),
      "reservation_hold_contact_ids" =>
        Map.get(inputs.reservation_hold_contact_ids_by_direction, direction, [])
    }
    |> compact_map()
  end
end
