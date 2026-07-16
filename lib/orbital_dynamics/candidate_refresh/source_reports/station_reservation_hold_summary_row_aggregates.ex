defmodule OrbitalDynamics.CandidateRefresh.SourceReports.StationReservationHoldSummaryRowAggregates do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReports.StationReservationHoldSummaryRowValues,
    only: [
      count_source_report_rows: 2
    ]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.StationReservationHoldSummaryRowGroups

  def fields(affected_rows, provider_rows) do
    all_rows = affected_rows ++ provider_rows

    reservation_hold_ids =
      StationReservationHoldSummaryRowGroups.reservation_hold_ids(all_rows) || []

    %{
      "reservation_hold_count" => length(reservation_hold_ids),
      "affected_contact_reservation_hold_count" =>
        StationReservationHoldSummaryRowGroups.hold_row_count(affected_rows),
      "provider_calendar_contention_hold_count" =>
        StationReservationHoldSummaryRowGroups.hold_row_count(provider_rows),
      "reservation_hold_review_status" => hold_review_status(affected_rows, provider_rows),
      "reservation_hold_expiration_count" =>
        StationReservationHoldSummaryRowGroups.expiration_evidence_count(all_rows),
      "earliest_reservation_hold_expires_at_s" =>
        all_rows
        |> StationReservationHoldSummaryRowGroups.expires_at_s()
        |> List.wrap()
        |> Enum.min(fn -> nil end),
      "reservation_hold_expiration_status_counts" =>
        count_source_report_rows(all_rows, "station_reservation_expiration_status"),
      "reservation_hold_status_counts" =>
        StationReservationHoldSummaryRowGroups.status_counts(all_rows),
      "reservation_hold_ids" => reservation_hold_ids,
      "reservation_hold_ids_by_expiration_status" =>
        StationReservationHoldSummaryRowGroups.ids_by_expiration_status(all_rows),
      "reservation_hold_ids_by_status" =>
        StationReservationHoldSummaryRowGroups.ids_by_status(all_rows),
      "reservation_hold_ids_by_reserved_by" =>
        StationReservationHoldSummaryRowGroups.ids_by_reserved_by(all_rows),
      "reservation_hold_ids_by_row_type" =>
        StationReservationHoldSummaryRowGroups.ids_by_row_type(all_rows),
      "reservation_hold_contact_ids_by_expiration_status" =>
        StationReservationHoldSummaryRowGroups.contact_ids_by_expiration_status(affected_rows),
      "review_contact_ids" =>
        StationReservationHoldSummaryRowGroups.affected_contact_ids(affected_rows)
    }
  end

  defp hold_review_status([], []), do: nil
  defp hold_review_status(_affected_rows, _provider_rows), do: "review_required"
end
