defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.StationReservationEvidence.FieldSets do
  @moduledoc false

  def reservation_fields do
    ["station_reservation_id", "station_calendar_reservation_ids"]
  end

  def expiration_fields do
    [
      "station_reservation_expires_at_s",
      "reservation_expires_at_s",
      "station_calendar_reservation_expires_at_s"
    ]
  end
end
