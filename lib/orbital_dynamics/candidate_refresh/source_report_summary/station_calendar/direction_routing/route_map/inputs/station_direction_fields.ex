defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationCalendar.DirectionRouting.RouteMap.Inputs.StationDirectionFields do
  @moduledoc false

  def values(station_direction_fields) do
    %{
      direction_counts: station_direction_fields["direction_counts"],
      contact_ids_by_direction: station_direction_fields["contact_ids_by_direction"],
      station_calendar_entry_ids_by_direction:
        station_direction_fields["station_calendar_entry_ids_by_direction"],
      station_reservation_ids_by_direction:
        station_direction_fields["station_reservation_ids_by_direction"],
      station_capacity_fractions_by_direction:
        station_direction_fields["station_capacity_fractions_by_direction"]
    }
  end
end
