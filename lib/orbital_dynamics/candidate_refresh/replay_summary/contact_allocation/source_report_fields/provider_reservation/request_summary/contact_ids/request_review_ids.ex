defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.ProviderReservation.RequestSummary.ContactIds.RequestReviewIds do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.ProviderReservation.RequestSummary.Rows

  import Rows,
    only: [
      contact_ids_by_direction_and_station: 1,
      group_key: 2,
      grouped_contact_ids: 1,
      map_value_lists: 1,
      nested_map_value_lists: 1,
      request_summary_rows?: 1,
      rows_for_summary: 1,
      sorted_non_empty_values: 1,
      summary_contact_id: 1
    ]

  def provider_contact_ids(report, fallback_field, filter) do
    rows = rows_for_summary(report)
    filtered_rows = Enum.filter(rows, filter)

    cond do
      request_summary_rows?(report) and rows != [] ->
        filtered_rows
        |> Enum.map(&summary_contact_id/1)
        |> sorted_non_empty_values()

      filtered_rows == [] ->
        report
        |> Map.get(fallback_field, [])
        |> List.wrap()
        |> sorted_non_empty_values()

      true ->
        filtered_rows
        |> Enum.map(&summary_contact_id/1)
        |> sorted_non_empty_values()
    end
  end

  def contact_ids_by_direction_and_station(report, fallback_fields, filter) do
    rows = rows_for_summary(report)
    filtered_rows = Enum.filter(rows, filter)

    cond do
      request_summary_rows?(report) and rows != [] ->
        contact_ids_by_direction_and_station(filtered_rows)

      filtered_rows == [] ->
        fallback_fields
        |> Enum.find_value(fn fallback_field ->
          report
          |> Map.get(fallback_field)
          |> nested_map_value_lists()
        end)

      true ->
        contact_ids_by_direction_and_station(filtered_rows)
    end
  end

  def contact_ids_by_field(report, fallback_fields, field, filter) do
    rows = rows_for_summary(report)
    filtered_rows = Enum.filter(rows, filter)

    cond do
      request_summary_rows?(report) and rows != [] ->
        filtered_rows
        |> Enum.map(fn row -> {group_key(row, field), summary_contact_id(row)} end)
        |> grouped_contact_ids()

      filtered_rows == [] ->
        fallback_fields
        |> Enum.find_value(fn fallback_field ->
          report
          |> Map.get(fallback_field)
          |> map_value_lists()
        end)

      true ->
        filtered_rows
        |> Enum.map(fn row -> {group_key(row, field), summary_contact_id(row)} end)
        |> grouped_contact_ids()
    end
  end
end
