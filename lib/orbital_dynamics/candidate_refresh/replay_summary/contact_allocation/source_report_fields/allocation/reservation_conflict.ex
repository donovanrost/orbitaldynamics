defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Allocation.ReservationConflict do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Counts
  alias __MODULE__.Rows

  import Common, only: [merge_nested_string_list_maps: 1]

  import Rows,
    only: [
      contact_ids_by_direction_and_station_from_rows: 1,
      fallback_contact_count: 1,
      group_key: 2,
      grouped_contact_counts: 1,
      grouped_contact_ids: 1,
      id_map_counts: 1,
      map_value_lists: 1,
      rows: 1,
      sorted_non_empty_values: 1,
      stable_id_or_nil: 1,
      summary_contact_id: 1,
      summary_direction: 1
    ]

  def contact_count(report) do
    case rows(report) do
      [] -> fallback_contact_count(report)
      rows -> length(rows)
    end
  end

  def contact_ids(report) do
    case rows(report) do
      [] ->
        report
        |> Map.get("reservation_conflict_contact_ids", [])
        |> List.wrap()
        |> sorted_non_empty_values()

      rows ->
        rows
        |> Enum.map(&summary_contact_id/1)
        |> sorted_non_empty_values()
    end
  end

  def match_status_counts(report) do
    case rows(report) do
      [] -> Map.get(report, "reservation_conflict_match_status_counts")
      rows -> Counts.normalized_rows(rows, "station_reservation_match_status")
    end
  end

  def contact_ids_by_match_status(report) do
    case rows(report) do
      [] ->
        report
        |> Map.get("reservation_conflict_contact_ids_by_match_status")
        |> map_value_lists()

      rows ->
        rows
        |> Enum.map(fn row ->
          {group_key(row, "station_reservation_match_status"), summary_contact_id(row)}
        end)
        |> grouped_contact_ids()
    end
  end

  def reservation_ids_by_match_status(report) do
    case rows(report) do
      [] ->
        report
        |> Map.get("reservation_conflict_reservation_ids_by_match_status")
        |> map_value_lists()

      rows ->
        rows
        |> Enum.map(fn row ->
          {group_key(row, "station_reservation_match_status"),
           stable_id_or_nil(row["station_reservation_id"])}
        end)
        |> grouped_contact_ids()
    end
  end

  def direction_counts(report) do
    case rows(report) do
      [] ->
        report
        |> Map.get("reservation_conflict_contact_ids_by_direction")
        |> id_map_counts()

      rows ->
        rows
        |> Enum.map(fn row -> {summary_direction(row), summary_contact_id(row)} end)
        |> grouped_contact_counts()
    end
  end

  def contact_ids_by_direction(report) do
    case rows(report) do
      [] ->
        report
        |> Map.get("reservation_conflict_contact_ids_by_direction")
        |> map_value_lists()

      rows ->
        rows
        |> Enum.map(fn row -> {summary_direction(row), summary_contact_id(row)} end)
        |> grouped_contact_ids()
    end
  end

  def contact_ids_by_direction_and_station(report) do
    case rows(report) do
      [] ->
        [
          "reservation_conflict_contact_ids_by_direction_and_ground_station",
          "reservation_conflict_contact_ids_by_direction_and_ground_station_id"
        ]
        |> Enum.map(&Map.get(report, &1))
        |> merge_nested_string_list_maps()

      rows ->
        contact_ids_by_direction_and_station_from_rows(rows)
    end
  end
end
