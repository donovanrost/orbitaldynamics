defmodule OrbitalDynamics.CandidateRefresh.SourceReports.StationReservationHoldSummaryIdGroups do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.StationReservationHoldSummaryRowGroupFields
  alias OrbitalDynamics.CandidateRefresh.SourceReports.StationReservationHoldSummaryRowGroupMaps

  def ids_by_status(rows) do
    ids_by_values(rows, StationReservationHoldSummaryRowGroupFields.reservation_status_fields())
  end

  def ids_by_reserved_by(rows) do
    ids_by_values(
      rows,
      StationReservationHoldSummaryRowGroupFields.reservation_reserved_by_fields()
    )
  end

  def contact_ids_by_expiration_status(rows) do
    contact_ids_by_values(rows, ["station_reservation_expiration_status"])
  end

  def ids_by_expiration_status(rows) do
    ids_by_values(rows, ["station_reservation_expiration_status"])
  end

  def ids_by_row_type(rows) do
    ids_by_values(rows, ["reservation_review_row_type"])
  end

  defp contact_ids_by_values(rows, grouping_fields) do
    StationReservationHoldSummaryRowGroupMaps.contact_ids_by_values(
      rows,
      StationReservationHoldSummaryRowGroupFields.contact_id_fields(),
      grouping_fields
    )
  end

  defp ids_by_values(rows, grouping_fields) do
    StationReservationHoldSummaryRowGroupMaps.reservation_ids_by_values(
      rows,
      StationReservationHoldSummaryRowGroupFields.reservation_id_fields(),
      grouping_fields
    )
  end
end
