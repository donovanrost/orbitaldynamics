defmodule OrbitalDynamics.CandidateRefresh.SourceReports.StationScheduleReservationDirectReportSourceFields do
  @moduledoc false

  @source_fields [
    "source_station_reservation_report",
    "station_reservation_report",
    "source_station_reservation_review_summary",
    "station_reservation_review_summary",
    "source_station_reservation_hold_summary",
    "station_reservation_hold_summary",
    "source_station_reservation_hold_import_readiness_summary",
    "station_reservation_hold_import_readiness_summary"
  ]

  def scoped_sources(refresh, scope) do
    Enum.map(@source_fields, fn field ->
      {"#{scope}.#{field}", get_in(refresh, [scope, field])}
    end)
  end

  def root_sources(refresh) do
    Enum.map(@source_fields, fn field ->
      {field, Map.get(refresh, field)}
    end)
  end
end
