defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.ProviderReservation.RequestSummary.ContactIds.NoRequestIds do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.ProviderReservation.RequestSummary.Rows

  import Rows,
    only: [
      candidate_rows: 1,
      contact_ids_by_direction_and_station: 1,
      grouped_contact_ids: 1,
      map_value_lists: 1,
      nested_map_value_lists: 1,
      no_request_rows: 1,
      request_summary_rows?: 1,
      rows_for_summary: 1,
      sorted_non_empty_values: 1,
      summary_contact_id: 1,
      summary_direction: 1
    ]

  def no_request_contact_ids(report) do
    rows = rows_for_summary(report)

    if request_summary_rows?(report) and rows != [] do
      rows
      |> no_request_rows()
      |> Enum.map(&summary_contact_id/1)
      |> sorted_non_empty_values()
    else
      explicit_ids =
        report
        |> Map.get("provider_reservation_no_request_contact_ids", [])
        |> List.wrap()
        |> sorted_non_empty_values()

      if not is_nil(explicit_ids) do
        explicit_ids
      else
        case candidate_rows(report) do
          [] ->
            []

          _candidate_rows ->
            rows
            |> no_request_rows()
            |> Enum.map(&summary_contact_id/1)
            |> sorted_non_empty_values()
        end
      end
    end
  end

  def no_request_contact_ids_by_direction(report) do
    rows = rows_for_summary(report)

    if request_summary_rows?(report) and rows != [] do
      rows
      |> no_request_rows()
      |> Enum.map(fn row -> {summary_direction(row), summary_contact_id(row)} end)
      |> grouped_contact_ids()
    else
      explicit =
        report
        |> Map.get("provider_reservation_no_request_contact_ids_by_direction")
        |> map_value_lists()

      if not is_nil(explicit) do
        explicit
      else
        case candidate_rows(report) do
          [] ->
            nil

          _candidate_rows ->
            rows
            |> no_request_rows()
            |> Enum.map(fn row -> {summary_direction(row), summary_contact_id(row)} end)
            |> grouped_contact_ids()
        end
      end
    end
  end

  def no_request_contact_ids_by_direction_and_station(report) do
    rows = rows_for_summary(report)

    if request_summary_rows?(report) and rows != [] do
      rows
      |> no_request_rows()
      |> contact_ids_by_direction_and_station()
    else
      explicit =
        [
          "provider_reservation_no_request_contact_ids_by_direction_and_ground_station_id",
          "provider_reservation_no_request_contact_ids_by_direction_and_ground_station"
        ]
        |> Enum.find_value(fn field ->
          report
          |> Map.get(field)
          |> nested_map_value_lists()
        end)

      if not is_nil(explicit) do
        explicit
      else
        case candidate_rows(report) do
          [] -> nil
          _candidate_rows -> rows |> no_request_rows() |> contact_ids_by_direction_and_station()
        end
      end
    end
  end
end
