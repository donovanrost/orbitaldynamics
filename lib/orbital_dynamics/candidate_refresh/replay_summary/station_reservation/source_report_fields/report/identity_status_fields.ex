defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Report.IdentityStatusFields do
  @moduledoc false

  alias __MODULE__.Expiration
  alias __MODULE__.Identity
  alias __MODULE__.MatchStatus
  alias __MODULE__.ReservationStatus
  alias __MODULE__.ReservedBy

  def match_status_counts(report) do
    MatchStatus.match_status_counts(report)
  end

  def status_counts(report) do
    ReservationStatus.status_counts(report)
  end

  def ids(reports) do
    Identity.ids(reports)
  end

  def ids_by_match_status(report) do
    MatchStatus.ids_by_match_status(report)
  end

  def affected_contact_ids(reports) do
    Identity.affected_contact_ids(reports)
  end

  def contact_ids_by_match_status(report) do
    MatchStatus.contact_ids_by_match_status(report)
  end

  def contact_ids_by_status(report) do
    ReservationStatus.contact_ids_by_status(report)
  end

  def ids_by_status(report) do
    ReservationStatus.ids_by_status(report)
  end

  def reserved_by_counts(report) do
    ReservedBy.reserved_by_counts(report)
  end

  def contact_ids_by_reserved_by(report) do
    ReservedBy.contact_ids_by_reserved_by(report)
  end

  def ids_by_reserved_by(report) do
    ReservedBy.ids_by_reserved_by(report)
  end

  def expires_at_s(reports) do
    Expiration.expires_at_s(reports)
  end
end
