defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.Report.StatusAvailabilityFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Counts

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1,
      merge_string_list_maps: 1
    ]

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.Report.Rows,
    only: [
      capacity_fractions_by_values: 2,
      contact_ids_by_values: 2,
      entry_ids_by_values: 2,
      reservation_ids_by_values: 2,
      rows_with_availability: 1,
      rows_with_ground_station_id: 1
    ]

  def capacity_fractions_by_status(report) do
    report
    |> Map.get("affected_contacts", [])
    |> capacity_fractions_by_values(["station_calendar_status"])
  end

  def capacity_fractions_by_ground_station(report) do
    report
    |> Map.get("affected_contacts", [])
    |> rows_with_ground_station_id()
    |> capacity_fractions_by_values(["ground_station_id"])
  end

  def capacity_fractions_by_availability(report) do
    report
    |> Map.get("affected_contacts", [])
    |> rows_with_availability()
    |> capacity_fractions_by_values(["affected_contact_availability"])
  end

  def contact_ids_by_status(report) do
    row_map =
      report
      |> Map.get("affected_contacts", [])
      |> contact_ids_by_values(["station_calendar_status"])

    merge_string_list_maps([
      row_map,
      Map.get(report, "affected_contact_ids_by_applied_availability", %{})
    ])
  end

  def contact_ids_by_ground_station(report) do
    report
    |> Map.get("affected_contacts", [])
    |> rows_with_ground_station_id()
    |> contact_ids_by_values(["ground_station_id"])
  end

  def contact_ids_by_availability(report) do
    row_map =
      report
      |> Map.get("affected_contacts", [])
      |> rows_with_availability()
      |> contact_ids_by_values(["affected_contact_availability"])

    merge_string_list_maps([
      row_map,
      Map.get(report, "affected_contact_ids_by_applied_availability", %{})
    ])
  end

  def entry_ids_by_status(report) do
    report
    |> Map.get("affected_contacts", [])
    |> entry_ids_by_values(["station_calendar_status"])
  end

  def entry_ids_by_ground_station(report) do
    report
    |> Map.get("affected_contacts", [])
    |> rows_with_ground_station_id()
    |> entry_ids_by_values(["ground_station_id"])
  end

  def entry_ids_by_availability(report) do
    report
    |> Map.get("affected_contacts", [])
    |> rows_with_availability()
    |> entry_ids_by_values(["affected_contact_availability"])
  end

  def reservation_ids_by_status(report) do
    report
    |> Map.get("affected_contacts", [])
    |> reservation_ids_by_values(["station_calendar_status"])
  end

  def reservation_ids_by_ground_station(report) do
    report
    |> Map.get("affected_contacts", [])
    |> rows_with_ground_station_id()
    |> reservation_ids_by_values(["ground_station_id"])
  end

  def reservation_ids_by_availability(report) do
    report
    |> Map.get("affected_contacts", [])
    |> rows_with_availability()
    |> reservation_ids_by_values(["affected_contact_availability"])
  end

  def status_counts(report) do
    row_counts =
      report
      |> Map.get("affected_contacts", [])
      |> Counts.normalized_rows("station_calendar_status")
      |> case do
        nil -> %{}
        counts -> counts
      end

    merge_count_maps([row_counts, Map.get(report, "applied_availability_counts", %{})])
  end

  def affected_contact_ground_station_counts(report) do
    report
    |> Map.get("affected_contacts", [])
    |> rows_with_ground_station_id()
    |> Counts.normalized_rows("ground_station_id")
  end

  def affected_contact_availability_counts(report) do
    row_counts =
      report
      |> Map.get("affected_contacts", [])
      |> rows_with_availability()
      |> Counts.normalized_rows("affected_contact_availability")

    merge_count_maps([row_counts, Map.get(report, "applied_availability_counts", %{})])
  end
end
