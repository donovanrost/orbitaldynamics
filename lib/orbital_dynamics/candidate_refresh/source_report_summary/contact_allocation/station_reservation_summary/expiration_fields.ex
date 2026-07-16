defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.StationReservationSummary.ExpirationFields do
  @moduledoc false

  alias __MODULE__.Aggregates
  alias __MODULE__.CountFields

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.StationReservation

  def fields(reports) do
    %{
      "station_reservation_expires_at_s" =>
        Aggregates.numeric_list_merge(reports, &StationReservation.expires_at_s/1),
      "station_reservation_expiration_status_counts" =>
        Aggregates.count_map_merge(reports, &StationReservation.expiration_status_counts/1),
      "station_reservation_contact_ids_by_expiration_status" =>
        Aggregates.string_list_map_merge(
          reports,
          &StationReservation.contact_ids_by_expiration_status/1
        ),
      "station_reservation_ids_by_expiration_status" =>
        Aggregates.string_list_map_merge(reports, &StationReservation.ids_by_expiration_status/1),
      "station_reservation_expiration_now_s" =>
        Aggregates.min_report_value(reports, &StationReservation.expiration_now_s/1),
      "earliest_station_reservation_expires_at_s" =>
        Aggregates.min_report_value(reports, &StationReservation.earliest_expires_at_s/1)
    }
    |> Map.merge(CountFields.fields(reports))
  end
end
