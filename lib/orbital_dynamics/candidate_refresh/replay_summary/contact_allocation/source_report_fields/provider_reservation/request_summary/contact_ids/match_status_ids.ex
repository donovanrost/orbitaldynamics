defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.ProviderReservation.RequestSummary.ContactIds.MatchStatusIds do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.ProviderReservation.RequestSummary.Rows

  import Rows,
    only: [
      candidate_row?: 1,
      group_key: 2,
      grouped_contact_ids: 1,
      map_value_lists: 1,
      request_ready_row?: 1,
      request_row?: 1,
      request_summary_rows?: 1,
      rows_for_summary: 1,
      station_reservation_ids: 1,
      summary_contact_id: 1
    ]

  def request_contact_ids_by_match_status(report) do
    contact_ids_by_match_status(
      report,
      "provider_reservation_request_contact_ids_by_match_status",
      &request_row?/1
    )
  end

  def review_contact_ids_by_match_status(report) do
    contact_ids_by_match_status(
      report,
      "provider_reservation_review_contact_ids_by_match_status",
      fn row -> candidate_row?(row) and not request_ready_row?(row) end
    )
  end

  def request_ids_by_match_status(report) do
    ids_by_match_status(
      report,
      "provider_reservation_request_ids_by_match_status",
      &request_row?/1
    )
  end

  def review_ids_by_match_status(report) do
    ids_by_match_status(
      report,
      "provider_reservation_review_ids_by_match_status",
      fn row -> candidate_row?(row) and not request_ready_row?(row) end
    )
  end

  defp contact_ids_by_match_status(report, fallback_field, filter) do
    rows = rows_for_summary(report)
    filtered_rows = Enum.filter(rows, filter)

    cond do
      request_summary_rows?(report) and rows != [] ->
        contact_ids_by_match_status_from_rows(filtered_rows)

      filtered_rows == [] ->
        report
        |> Map.get(fallback_field)
        |> map_value_lists()

      true ->
        contact_ids_by_match_status_from_rows(filtered_rows)
    end
  end

  defp contact_ids_by_match_status_from_rows(rows) do
    rows
    |> Enum.map(fn row ->
      {group_key(row, "station_reservation_match_status"), summary_contact_id(row)}
    end)
    |> grouped_contact_ids()
  end

  defp ids_by_match_status(report, fallback_field, filter) do
    rows = rows_for_summary(report)
    filtered_rows = Enum.filter(rows, filter)

    cond do
      request_summary_rows?(report) and rows != [] ->
        ids_by_match_status_from_rows(filtered_rows)

      filtered_rows == [] ->
        report
        |> Map.get(fallback_field)
        |> map_value_lists()

      true ->
        ids_by_match_status_from_rows(filtered_rows)
    end
  end

  defp ids_by_match_status_from_rows(rows) do
    rows
    |> Enum.flat_map(fn row ->
      row
      |> station_reservation_ids()
      |> Enum.map(fn reservation_id ->
        {group_key(row, "station_reservation_match_status"), reservation_id}
      end)
    end)
    |> grouped_contact_ids()
  end
end
