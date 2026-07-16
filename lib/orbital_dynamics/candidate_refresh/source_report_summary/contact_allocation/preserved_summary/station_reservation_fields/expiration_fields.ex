defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PreservedSummary.StationReservationFields.ExpirationFields do
  @moduledoc false

  alias __MODULE__.{StatusMaps, TimestampValues}

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      numeric_report_count: 2
    ]

  def fields(summary) do
    %{
      "station_reservation_expires_at_s" => TimestampValues.expires_at_s(summary),
      "station_reservation_expiration_now_s" => TimestampValues.expiration_now_s(summary),
      "station_reservation_expiration_status_counts" => StatusMaps.counts(summary),
      "station_reservation_active_contact_count" =>
        numeric_report_count(summary, "station_reservation_active_contact_count"),
      "station_reservation_expired_contact_count" =>
        numeric_report_count(summary, "station_reservation_expired_contact_count"),
      "station_reservation_declared_expiration_contact_count" =>
        numeric_report_count(summary, "station_reservation_declared_expiration_contact_count"),
      "station_reservation_missing_expiration_contact_count" =>
        numeric_report_count(summary, "station_reservation_missing_expiration_contact_count"),
      "earliest_station_reservation_expires_at_s" =>
        TimestampValues.earliest_expires_at_s(summary),
      "station_reservation_contact_ids_by_expiration_status" => StatusMaps.contact_ids(summary),
      "station_reservation_ids_by_expiration_status" => StatusMaps.reservation_ids(summary)
    }
  end
end
