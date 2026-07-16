defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationCalendar.StationFields.IdMaps.FieldSpecs do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.Report,
    as: StationCalendarReport

  def all do
    [
      {"contact_ids_by_reserved_by", &StationCalendarReport.contact_ids_by_reserved_by/1},
      {"station_calendar_entry_ids_by_reserved_by",
       &StationCalendarReport.entry_ids_by_reserved_by/1},
      {"station_reservation_ids_by_reserved_by",
       &StationCalendarReport.reservation_ids_by_reserved_by/1},
      {"contact_ids_by_status", &StationCalendarReport.contact_ids_by_status/1},
      {"contact_ids_by_ground_station", &StationCalendarReport.contact_ids_by_ground_station/1},
      {"contact_ids_by_availability", &StationCalendarReport.contact_ids_by_availability/1},
      {"station_calendar_entry_ids_by_status", &StationCalendarReport.entry_ids_by_status/1},
      {"station_calendar_entry_ids_by_ground_station",
       &StationCalendarReport.entry_ids_by_ground_station/1},
      {"station_calendar_entry_ids_by_availability",
       &StationCalendarReport.entry_ids_by_availability/1},
      {"station_reservation_ids_by_status", &StationCalendarReport.reservation_ids_by_status/1},
      {"station_reservation_ids_by_ground_station",
       &StationCalendarReport.reservation_ids_by_ground_station/1},
      {"station_reservation_ids_by_availability",
       &StationCalendarReport.reservation_ids_by_availability/1}
    ]
  end
end
