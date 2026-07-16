defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.Report.AggregateFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Counts

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      sorted_string_values: 1
    ]

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.Report.Rows,
    only: [
      ids_by_reserved_by: 2,
      normalize_number_list: 1,
      precedence_contact_ids: 1,
      row_capacity_fractions: 1,
      row_entry_ids: 1,
      row_reservation_expires_at_s: 1,
      row_reservation_ids: 1,
      row_reserved_by_values: 1,
      row_values: 2,
      stringify_keys: 1
    ]

  def affected_contact_ids(reports) do
    reports
    |> Enum.flat_map(fn report ->
      row_ids =
        report
        |> Map.get("affected_contacts", [])
        |> Enum.flat_map(fn row ->
          row
          |> stringify_keys()
          |> row_values(["contact_id", "source_contact_id", "candidate_id"])
        end)

      row_ids ++ precedence_contact_ids(report)
    end)
    |> sorted_string_values()
  end

  def affected_station_calendar_entry_ids(reports) do
    reports
    |> Enum.flat_map(fn report ->
      report
      |> Map.get("affected_contacts", [])
      |> Enum.flat_map(&row_entry_ids/1)
    end)
    |> Enum.uniq()
    |> Enum.sort()
  end

  def affected_station_reservation_ids(reports) do
    reports
    |> Enum.flat_map(fn report ->
      report
      |> Map.get("affected_contacts", [])
      |> Enum.flat_map(&row_reservation_ids/1)
    end)
    |> Enum.uniq()
    |> Enum.sort()
  end

  def reserved_by_counts(report) do
    report
    |> Map.get("affected_contacts", [])
    |> Enum.flat_map(&row_reserved_by_values/1)
    |> Counts.normalized_values()
  end

  def contact_ids_by_reserved_by(report) do
    report
    |> Map.get("affected_contacts", [])
    |> ids_by_reserved_by(fn row ->
      row
      |> row_values(["contact_id", "source_contact_id", "candidate_id"])
      |> sorted_string_values()
    end)
  end

  def entry_ids_by_reserved_by(report) do
    report
    |> Map.get("affected_contacts", [])
    |> ids_by_reserved_by(&row_entry_ids/1)
  end

  def reservation_ids_by_reserved_by(report) do
    report
    |> Map.get("affected_contacts", [])
    |> ids_by_reserved_by(&row_reservation_ids/1)
  end

  def reservation_expires_at_s(reports) do
    reports
    |> Enum.flat_map(fn report ->
      report
      |> Map.get("affected_contacts", [])
      |> Enum.flat_map(&row_reservation_expires_at_s/1)
    end)
    |> normalize_number_list()
  end

  def capacity_fractions(reports) do
    reports
    |> Enum.flat_map(fn report ->
      report
      |> Map.get("affected_contacts", [])
      |> Enum.flat_map(&row_capacity_fractions/1)
    end)
    |> normalize_number_list()
  end
end
