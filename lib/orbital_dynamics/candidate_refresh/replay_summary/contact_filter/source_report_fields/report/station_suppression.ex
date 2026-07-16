defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactFilter.SourceReportFields.Report.StationSuppression do
  @moduledoc false

  alias __MODULE__.CountFields
  alias __MODULE__.IdMaps

  defdelegate station_suppression_count(report), to: CountFields
  defdelegate station_suppression_ground_station_counts(report), to: CountFields
  defdelegate station_suppression_availability_counts(report), to: CountFields
  defdelegate station_suppression_status_counts(report), to: CountFields

  defdelegate station_suppression_contact_ids_by_ground_station(report), to: IdMaps
  defdelegate station_suppression_contact_ids_by_availability(report), to: IdMaps
  defdelegate station_suppression_contact_ids_by_status(report), to: IdMaps
  defdelegate station_suppression_station_calendar_entry_ids_by_ground_station(report), to: IdMaps
  defdelegate station_suppression_station_calendar_entry_ids_by_availability(report), to: IdMaps
  defdelegate station_suppression_station_calendar_entry_ids_by_status(report), to: IdMaps

  defdelegate station_suppression_station_calendar_provider_entry_ids_by_ground_station(report),
    to: IdMaps

  defdelegate station_suppression_station_calendar_provider_entry_ids_by_availability(report),
    to: IdMaps

  defdelegate station_suppression_station_calendar_provider_entry_ids_by_status(report),
    to: IdMaps

  defdelegate station_suppression_station_reservation_ids_by_ground_station(report), to: IdMaps
  defdelegate station_suppression_station_reservation_ids_by_availability(report), to: IdMaps
  defdelegate station_suppression_station_reservation_ids_by_status(report), to: IdMaps
end
