defmodule OrbitalDynamics.CandidateRefresh.SourceReports.StationReservationHoldSummaryRowGroupFields do
  @moduledoc false

  def contact_id_fields do
    [
      "contact_id",
      "source_contact_id",
      "candidate_id"
    ]
  end

  def reservation_id_fields do
    [
      "station_reservation_id",
      "station_calendar_reservation_ids",
      "reservation_id",
      "reservation_ids"
    ]
  end

  def reservation_status_fields do
    [
      "station_reservation_status",
      "station_calendar_reservation_statuses",
      "reservation_status",
      "reservation_statuses"
    ]
  end

  def reservation_reserved_by_fields do
    [
      "station_reserved_by",
      "station_calendar_reserved_by",
      "reserved_by",
      "reserved_bys"
    ]
  end

  def reservation_expires_at_fields do
    [
      "station_reservation_expires_at_s",
      "station_calendar_reservation_expires_at_s",
      "reservation_expires_at_s",
      "reservation_expires_at"
    ]
  end
end
