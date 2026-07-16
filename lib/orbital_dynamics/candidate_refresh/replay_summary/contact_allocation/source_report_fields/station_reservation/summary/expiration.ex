defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.StationReservation.Summary.Expiration do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Counts

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.StationReservation.Summary.Rows

  import Common, only: [numeric_report_count: 2]

  import Rows,
    only: [
      expiration_rows: 1,
      grouped_contact_ids: 1,
      map_value_lists: 1,
      normalize_number_list: 1,
      numeric_value: 1,
      rows: 1,
      stable_id_or_nil: 1,
      station_reservation_expires_at_s: 1,
      summary_contact_id: 1
    ]

  def expires_at_s(report) do
    case rows(report) do
      [] ->
        report
        |> Map.get("station_reservation_expires_at_s")
        |> normalize_number_list()

      rows ->
        rows
        |> Enum.map(&station_reservation_expires_at_s/1)
        |> normalize_number_list()
    end
  end

  def expiration_now_s(report),
    do: Rows.expiration_now_s(report)

  def expiration_status_counts(report) do
    case expiration_rows(report) do
      [] -> Map.get(report, "station_reservation_expiration_status_counts")
      rows -> Counts.normalized_rows(rows, "station_reservation_expiration_status")
    end
  end

  def active_contact_count(report) do
    case expiration_rows(report) do
      [] -> numeric_report_count(report, "station_reservation_active_contact_count")
      rows -> Enum.count(rows, &(&1["station_reservation_expiration_status"] == "active"))
    end
  end

  def expired_contact_count(report) do
    case expiration_rows(report) do
      [] -> numeric_report_count(report, "station_reservation_expired_contact_count")
      rows -> Enum.count(rows, &(&1["station_reservation_expiration_status"] == "expired"))
    end
  end

  def declared_expiration_contact_count(report) do
    case expiration_rows(report) do
      [] -> numeric_report_count(report, "station_reservation_declared_expiration_contact_count")
      rows -> Enum.count(rows, &(&1["station_reservation_expiration_status"] == "declared"))
    end
  end

  def missing_expiration_contact_count(report) do
    case expiration_rows(report) do
      [] -> numeric_report_count(report, "station_reservation_missing_expiration_contact_count")
      rows -> Enum.count(rows, &(&1["station_reservation_expiration_status"] == "missing"))
    end
  end

  def earliest_expires_at_s(report) do
    case expiration_rows(report) do
      [] ->
        numeric_value(Map.get(report, "earliest_station_reservation_expires_at_s")) ||
          report
          |> Map.get("station_reservation_expires_at_s")
          |> normalize_number_list()
          |> List.wrap()
          |> Enum.min(fn -> nil end)

      rows ->
        rows
        |> Enum.map(& &1["station_reservation_summary_expires_at_s"])
        |> Enum.reject(&is_nil/1)
        |> Enum.min(fn -> nil end)
    end
  end

  def contact_ids_by_expiration_status(report) do
    case expiration_rows(report) do
      [] ->
        report
        |> Map.get("station_reservation_contact_ids_by_expiration_status")
        |> map_value_lists()

      rows ->
        rows
        |> Enum.map(fn row ->
          {row["station_reservation_expiration_status"], summary_contact_id(row)}
        end)
        |> grouped_contact_ids()
    end
  end

  def ids_by_expiration_status(report) do
    case expiration_rows(report) do
      [] ->
        report
        |> Map.get("station_reservation_ids_by_expiration_status")
        |> map_value_lists()

      rows ->
        rows
        |> Enum.map(fn row ->
          {row["station_reservation_expiration_status"],
           stable_id_or_nil(row["station_reservation_id"])}
        end)
        |> grouped_contact_ids()
    end
  end
end
