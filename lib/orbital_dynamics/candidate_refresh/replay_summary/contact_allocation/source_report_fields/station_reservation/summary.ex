defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.StationReservation.Summary do
  @moduledoc false

  alias __MODULE__.Expiration
  alias __MODULE__.ReservationMaps

  def match_status_counts(report) do
    ReservationMaps.match_status_counts(report)
  end

  def contact_ids_by_match_status(report) do
    ReservationMaps.contact_ids_by_match_status(report)
  end

  def ids_by_match_status(report) do
    ReservationMaps.ids_by_match_status(report)
  end

  def status_counts(report) do
    ReservationMaps.status_counts(report)
  end

  def reserved_by_counts(report) do
    ReservationMaps.reserved_by_counts(report)
  end

  def ids(report) do
    ReservationMaps.ids(report)
  end

  def contact_ids_by_status(report) do
    ReservationMaps.contact_ids_by_status(report)
  end

  def contact_ids_by_reserved_by(report) do
    ReservationMaps.contact_ids_by_reserved_by(report)
  end

  def ids_by_status(report) do
    ReservationMaps.ids_by_status(report)
  end

  def ids_by_reserved_by(report) do
    ReservationMaps.ids_by_reserved_by(report)
  end

  def expires_at_s(report) do
    Expiration.expires_at_s(report)
  end

  def expiration_now_s(report),
    do: Expiration.expiration_now_s(report)

  def expiration_status_counts(report) do
    Expiration.expiration_status_counts(report)
  end

  def active_contact_count(report) do
    Expiration.active_contact_count(report)
  end

  def expired_contact_count(report) do
    Expiration.expired_contact_count(report)
  end

  def declared_expiration_contact_count(report) do
    Expiration.declared_expiration_contact_count(report)
  end

  def missing_expiration_contact_count(report) do
    Expiration.missing_expiration_contact_count(report)
  end

  def earliest_expires_at_s(report) do
    Expiration.earliest_expires_at_s(report)
  end

  def contact_ids_by_expiration_status(report) do
    Expiration.contact_ids_by_expiration_status(report)
  end

  def ids_by_expiration_status(report) do
    Expiration.ids_by_expiration_status(report)
  end
end
