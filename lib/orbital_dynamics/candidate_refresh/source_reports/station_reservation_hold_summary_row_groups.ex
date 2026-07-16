defmodule OrbitalDynamics.CandidateRefresh.SourceReports.StationReservationHoldSummaryRowGroups do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.StationReservationHoldSummaryDirectRowGroups
  alias OrbitalDynamics.CandidateRefresh.SourceReports.StationReservationHoldSummaryIdGroups

  def hold_row_count(rows) do
    StationReservationHoldSummaryDirectRowGroups.hold_row_count(rows)
  end

  def expiration_evidence_count(rows) do
    StationReservationHoldSummaryDirectRowGroups.expiration_evidence_count(rows)
  end

  def status_counts(rows) do
    StationReservationHoldSummaryDirectRowGroups.status_counts(rows)
  end

  def reservation_hold_ids(rows) do
    StationReservationHoldSummaryDirectRowGroups.reservation_hold_ids(rows)
  end

  def affected_contact_ids(rows) do
    StationReservationHoldSummaryDirectRowGroups.affected_contact_ids(rows)
  end

  def ids_by_status(rows) do
    StationReservationHoldSummaryIdGroups.ids_by_status(rows)
  end

  def ids_by_reserved_by(rows) do
    StationReservationHoldSummaryIdGroups.ids_by_reserved_by(rows)
  end

  def expires_at_s(rows) do
    StationReservationHoldSummaryDirectRowGroups.expires_at_s(rows)
  end

  def contact_ids_by_expiration_status(rows) do
    StationReservationHoldSummaryIdGroups.contact_ids_by_expiration_status(rows)
  end

  def ids_by_expiration_status(rows) do
    StationReservationHoldSummaryIdGroups.ids_by_expiration_status(rows)
  end

  def ids_by_row_type(rows) do
    StationReservationHoldSummaryIdGroups.ids_by_row_type(rows)
  end
end
