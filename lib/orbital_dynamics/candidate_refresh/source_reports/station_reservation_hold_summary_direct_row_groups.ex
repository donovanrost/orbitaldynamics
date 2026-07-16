defmodule OrbitalDynamics.CandidateRefresh.SourceReports.StationReservationHoldSummaryDirectRowGroups do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.StationReservationHoldSummaryDirectRowEvidence

  alias OrbitalDynamics.CandidateRefresh.SourceReports.StationReservationHoldSummaryDirectRowGroupValues

  def hold_row_count(rows) do
    StationReservationHoldSummaryDirectRowEvidence.hold_row_count(rows)
  end

  def expiration_evidence_count(rows) do
    StationReservationHoldSummaryDirectRowEvidence.expiration_evidence_count(rows)
  end

  def status_counts(rows) do
    StationReservationHoldSummaryDirectRowGroupValues.status_counts(rows)
  end

  def reservation_hold_ids(rows) do
    StationReservationHoldSummaryDirectRowGroupValues.reservation_hold_ids(rows)
  end

  def affected_contact_ids(rows) do
    StationReservationHoldSummaryDirectRowGroupValues.affected_contact_ids(rows)
  end

  def expires_at_s(rows) do
    StationReservationHoldSummaryDirectRowEvidence.expires_at_s(rows)
  end
end
