defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Allocation.StationPressure.Summary.GroupingFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Counts

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Allocation.StationPressure.Summary.Rows
  alias __MODULE__.Direction

  import Rows,
    only: [
      availability_values: 1,
      group_key: 2,
      grouped_contact_counts: 1,
      grouped_contact_ids: 1,
      id_map_counts: 1,
      map_value_lists: 1,
      merge_string_list_maps: 1,
      rows: 1,
      summary_contact_id: 1
    ]

  def ground_station_counts(report) do
    case rows(report) do
      [] ->
        [
          Map.get(report, "station_pressure_contact_ids_by_ground_station_id"),
          Map.get(report, "station_pressure_contact_ids_by_ground_station")
        ]
        |> merge_string_list_maps()
        |> id_map_counts()

      rows ->
        Counts.normalized_rows(rows, "ground_station_id")
    end
  end

  def contact_ids_by_ground_station(report) do
    case rows(report) do
      [] ->
        [
          Map.get(report, "station_pressure_contact_ids_by_ground_station_id"),
          Map.get(report, "station_pressure_contact_ids_by_ground_station")
        ]
        |> merge_string_list_maps()

      rows ->
        rows
        |> Enum.map(fn row -> {group_key(row, "ground_station_id"), summary_contact_id(row)} end)
        |> grouped_contact_ids()
    end
  end

  def availability_counts(report) do
    case rows(report) do
      [] ->
        report
        |> Map.get("station_pressure_contact_ids_by_availability")
        |> id_map_counts()

      rows ->
        rows
        |> Enum.flat_map(fn row ->
          row
          |> availability_values()
          |> Enum.map(&{&1, summary_contact_id(row)})
        end)
        |> grouped_contact_counts()
    end
  end

  def contact_ids_by_availability(report) do
    case rows(report) do
      [] ->
        report
        |> Map.get("station_pressure_contact_ids_by_availability")
        |> map_value_lists()

      rows ->
        rows
        |> Enum.flat_map(fn row ->
          row
          |> availability_values()
          |> Enum.map(&{&1, summary_contact_id(row)})
        end)
        |> grouped_contact_ids()
    end
  end

  def status_counts(report) do
    case rows(report) do
      [] ->
        report
        |> Map.get("station_pressure_contact_ids_by_status")
        |> id_map_counts()

      rows ->
        Counts.normalized_rows(rows, "station_calendar_status")
    end
  end

  def contact_ids_by_status(report) do
    case rows(report) do
      [] ->
        report
        |> Map.get("station_pressure_contact_ids_by_status")
        |> map_value_lists()

      rows ->
        rows
        |> Enum.map(fn row ->
          {group_key(row, "station_calendar_status"), summary_contact_id(row)}
        end)
        |> grouped_contact_ids()
    end
  end

  defdelegate direction_counts(report), to: Direction
  defdelegate contact_ids_by_direction(report), to: Direction
  defdelegate contact_ids_by_direction_and_station(report), to: Direction
end
