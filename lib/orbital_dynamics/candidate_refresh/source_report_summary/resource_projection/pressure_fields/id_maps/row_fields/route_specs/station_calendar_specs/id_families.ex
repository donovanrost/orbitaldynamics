defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureFields.IdMaps.RowFields.RouteSpecs.StationCalendarSpecs.IdFamilies do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.RowIdentities

  def values do
    [
      {"resource_pressure_station_calendar_entry_ids",
       &RowIdentities.station_calendar_entry_ids/1},
      {"resource_pressure_station_calendar_provider_ids",
       &RowIdentities.station_calendar_provider_ids/1},
      {"resource_pressure_station_calendar_provider_entry_ids",
       &RowIdentities.station_calendar_provider_entry_ids/1}
    ]
  end
end
