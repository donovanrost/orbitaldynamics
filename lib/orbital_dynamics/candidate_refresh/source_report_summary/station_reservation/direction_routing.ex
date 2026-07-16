defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationReservation.DirectionRouting do
  @moduledoc false

  alias __MODULE__.{FieldValues, RouteMap}

  def fields(reports, hold_summary) do
    values = FieldValues.from(reports, hold_summary)

    %{
      "direction_counts" => values.direction_counts,
      "contact_ids_by_direction" => values.contact_ids_by_direction,
      "direction_routing" =>
        RouteMap.build(
          values.direction_counts,
          values.contact_ids_by_direction,
          values.reservation_hold_ids_by_direction,
          values.reservation_hold_contact_ids_by_direction
        )
    }
  end
end
