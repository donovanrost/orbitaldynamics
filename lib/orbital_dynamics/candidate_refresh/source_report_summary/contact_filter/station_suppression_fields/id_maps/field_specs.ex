defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactFilter.StationSuppressionFields.IdMaps.FieldSpecs do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactFilter.SourceReportFields.Report

  def values do
    [
      {"station_suppression_contact_ids_by_ground_station",
       &Report.station_suppression_contact_ids_by_ground_station/1},
      {"station_suppression_contact_ids_by_availability",
       &Report.station_suppression_contact_ids_by_availability/1},
      {"station_suppression_contact_ids_by_status",
       &Report.station_suppression_contact_ids_by_status/1},
      {"station_suppression_station_calendar_entry_ids_by_ground_station",
       &Report.station_suppression_station_calendar_entry_ids_by_ground_station/1},
      {"station_suppression_station_calendar_entry_ids_by_availability",
       &Report.station_suppression_station_calendar_entry_ids_by_availability/1},
      {"station_suppression_station_calendar_entry_ids_by_status",
       &Report.station_suppression_station_calendar_entry_ids_by_status/1},
      {"station_suppression_station_calendar_provider_entry_ids_by_ground_station",
       &Report.station_suppression_station_calendar_provider_entry_ids_by_ground_station/1},
      {"station_suppression_station_calendar_provider_entry_ids_by_availability",
       &Report.station_suppression_station_calendar_provider_entry_ids_by_availability/1},
      {"station_suppression_station_calendar_provider_entry_ids_by_status",
       &Report.station_suppression_station_calendar_provider_entry_ids_by_status/1},
      {"station_suppression_station_reservation_ids_by_ground_station",
       &Report.station_suppression_station_reservation_ids_by_ground_station/1},
      {"station_suppression_station_reservation_ids_by_availability",
       &Report.station_suppression_station_reservation_ids_by_availability/1},
      {"station_suppression_station_reservation_ids_by_status",
       &Report.station_suppression_station_reservation_ids_by_status/1}
    ]
  end
end
