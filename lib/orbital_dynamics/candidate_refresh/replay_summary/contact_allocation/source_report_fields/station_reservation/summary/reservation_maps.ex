defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.StationReservation.Summary.ReservationMaps do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.StationReservation.Summary.Rows
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Counts

  import Rows,
    only: [
      group_key: 2,
      grouped_contact_ids: 1,
      map_value_lists: 1,
      rows: 1,
      sorted_non_empty_values: 1,
      stable_id_or_nil: 1,
      summary_contact_id: 1
    ]

  def match_status_counts(report) do
    case rows(report) do
      [] -> Map.get(report, "station_reservation_match_status_counts")
      rows -> Counts.normalized_rows(rows, "station_reservation_match_status")
    end
  end

  def contact_ids_by_match_status(report) do
    contact_ids_by_field(
      report,
      "station_reservation_contact_ids_by_match_status",
      "station_reservation_match_status"
    )
  end

  def ids_by_match_status(report) do
    ids_by_field(
      report,
      "station_reservation_ids_by_match_status",
      "station_reservation_match_status"
    )
  end

  def status_counts(report) do
    case rows(report) do
      [] -> Map.get(report, "station_reservation_status_counts")
      rows -> Counts.normalized_rows(rows, "station_reservation_status")
    end
  end

  def reserved_by_counts(report) do
    case rows(report) do
      [] -> Map.get(report, "station_reserved_by_counts")
      rows -> Counts.normalized_rows(rows, "station_reserved_by")
    end
  end

  def ids(report) do
    case rows(report) do
      [] ->
        report
        |> Map.get("station_reservation_ids", [])
        |> List.wrap()
        |> sorted_non_empty_values()

      rows ->
        rows
        |> Enum.map(&stable_id_or_nil(&1["station_reservation_id"]))
        |> sorted_non_empty_values()
    end
  end

  def contact_ids_by_status(report) do
    contact_ids_by_field(
      report,
      "station_reservation_contact_ids_by_status",
      "station_reservation_status"
    )
  end

  def contact_ids_by_reserved_by(report) do
    contact_ids_by_field(
      report,
      "station_reservation_contact_ids_by_reserved_by",
      "station_reserved_by"
    )
  end

  def ids_by_status(report) do
    ids_by_field(report, "station_reservation_ids_by_status", "station_reservation_status")
  end

  def ids_by_reserved_by(report) do
    ids_by_field(report, "station_reservation_ids_by_reserved_by", "station_reserved_by")
  end

  defp contact_ids_by_field(report, fallback_field, group_field) do
    case rows(report) do
      [] ->
        report
        |> Map.get(fallback_field)
        |> map_value_lists()

      rows ->
        rows
        |> Enum.map(fn row -> {group_key(row, group_field), summary_contact_id(row)} end)
        |> grouped_contact_ids()
    end
  end

  defp ids_by_field(report, fallback_field, group_field) do
    case rows(report) do
      [] ->
        report
        |> Map.get(fallback_field)
        |> map_value_lists()

      rows ->
        rows
        |> Enum.map(fn row ->
          {group_key(row, group_field), stable_id_or_nil(row["station_reservation_id"])}
        end)
        |> grouped_contact_ids()
    end
  end
end
