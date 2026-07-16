defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.StationReservation do
  @moduledoc false

  alias __MODULE__.Summary

  def match_status_counts(report) do
    Summary.match_status_counts(report)
  end

  def contact_ids_by_match_status(report) do
    Summary.contact_ids_by_match_status(report)
  end

  def ids_by_match_status(report) do
    Summary.ids_by_match_status(report)
  end

  def status_counts(report) do
    Summary.status_counts(report)
  end

  def reserved_by_counts(report) do
    Summary.reserved_by_counts(report)
  end

  def ids(report) do
    Summary.ids(report)
  end

  def contact_ids_by_status(report) do
    Summary.contact_ids_by_status(report)
  end

  def contact_ids_by_reserved_by(report) do
    Summary.contact_ids_by_reserved_by(report)
  end

  def ids_by_status(report) do
    Summary.ids_by_status(report)
  end

  def ids_by_reserved_by(report) do
    Summary.ids_by_reserved_by(report)
  end

  def expires_at_s(report) do
    Summary.expires_at_s(report)
  end

  def expiration_now_s(report),
    do: Summary.expiration_now_s(report)

  def expiration_status_counts(report) do
    Summary.expiration_status_counts(report)
  end

  def active_contact_count(report) do
    Summary.active_contact_count(report)
  end

  def expired_contact_count(report) do
    Summary.expired_contact_count(report)
  end

  def declared_expiration_contact_count(report) do
    Summary.declared_expiration_contact_count(report)
  end

  def missing_expiration_contact_count(report) do
    Summary.missing_expiration_contact_count(report)
  end

  def earliest_expires_at_s(report) do
    Summary.earliest_expires_at_s(report)
  end

  def contact_ids_by_expiration_status(report) do
    Summary.contact_ids_by_expiration_status(report)
  end

  def ids_by_expiration_status(report) do
    Summary.ids_by_expiration_status(report)
  end
end
