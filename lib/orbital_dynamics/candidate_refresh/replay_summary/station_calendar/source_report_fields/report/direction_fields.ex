defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.Report.DirectionFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Counts

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.Report.Rows,
    only: [
      affected_contact_rows_with_directions: 1,
      capacity_fractions_by_values: 2,
      contact_ids_by_values: 2,
      entry_ids_by_values: 2,
      reservation_ids_by_values: 2,
      row_directions: 1
    ]

  def direction_counts(report) do
    report
    |> Map.get("affected_contacts", [])
    |> Enum.flat_map(&row_directions/1)
    |> Counts.normalized_values()
  end

  def contact_ids_by_direction(report) do
    report
    |> affected_contact_rows_with_directions()
    |> contact_ids_by_values(["station_calendar_direction"])
  end

  def entry_ids_by_direction(report) do
    report
    |> affected_contact_rows_with_directions()
    |> entry_ids_by_values(["station_calendar_direction"])
  end

  def reservation_ids_by_direction(report) do
    report
    |> affected_contact_rows_with_directions()
    |> reservation_ids_by_values(["station_calendar_direction"])
  end

  def capacity_fractions_by_direction(report) do
    report
    |> affected_contact_rows_with_directions()
    |> capacity_fractions_by_values(["station_calendar_direction"])
  end
end
