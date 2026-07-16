defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Allocation.StationPressure.Summary.Precedence do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Counts

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Allocation.StationPressure.Summary.Rows

  import Rows,
    only: [
      group_key: 2,
      grouped_contact_ids: 1,
      id_map_counts: 1,
      map_value_lists: 1,
      rows: 1,
      summary_contact_id: 1
    ]

  def precedence_availability_counts(report) do
    case rows(report) do
      [] ->
        report
        |> Map.get("station_pressure_contact_ids_by_precedence_availability")
        |> id_map_counts()

      rows ->
        Counts.normalized_rows(rows, "station_calendar_precedence_availability")
    end
  end

  def contact_ids_by_precedence_availability(report) do
    case rows(report) do
      [] ->
        report
        |> Map.get("station_pressure_contact_ids_by_precedence_availability")
        |> map_value_lists()

      rows ->
        rows
        |> Enum.map(fn row ->
          {group_key(row, "station_calendar_precedence_availability"), summary_contact_id(row)}
        end)
        |> grouped_contact_ids()
    end
  end

  def precedence_rank_counts(report) do
    case rows(report) do
      [] ->
        report
        |> Map.get("station_pressure_contact_ids_by_precedence_rank")
        |> id_map_counts()

      rows ->
        rows
        |> Enum.map(fn row ->
          Map.update(row, "station_calendar_precedence_rank", nil, &to_string/1)
        end)
        |> Counts.normalized_rows("station_calendar_precedence_rank")
    end
  end

  def contact_ids_by_precedence_rank(report) do
    case rows(report) do
      [] ->
        report
        |> Map.get("station_pressure_contact_ids_by_precedence_rank")
        |> map_value_lists()

      rows ->
        rows
        |> Enum.map(fn row ->
          row = Map.update(row, "station_calendar_precedence_rank", nil, &to_string/1)
          {group_key(row, "station_calendar_precedence_rank"), summary_contact_id(row)}
        end)
        |> grouped_contact_ids()
    end
  end
end
