defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.StationReservationSummary.ExpirationFields.CountFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.StationReservation

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      sum_report_count: 2
    ]

  def fields(reports) do
    %{
      "station_reservation_active_contact_count" =>
        sum_report_count(reports, &StationReservation.active_contact_count/1),
      "station_reservation_expired_contact_count" =>
        sum_report_count(reports, &StationReservation.expired_contact_count/1),
      "station_reservation_declared_expiration_contact_count" =>
        sum_report_count(reports, &StationReservation.declared_expiration_contact_count/1),
      "station_reservation_missing_expiration_contact_count" =>
        sum_report_count(reports, &StationReservation.missing_expiration_contact_count/1)
    }
  end
end
