defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Allocation.StationPressure.Summary.GroupingFields.Direction do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Allocation.StationPressure.Summary.Rows,
    only: [
      contact_ids_by_direction_and_station_from_rows: 1,
      grouped_contact_counts: 1,
      grouped_contact_ids: 1,
      id_map_counts: 1,
      map_value_lists: 1,
      nested_map_value_lists: 1,
      rows: 1,
      summary_contact_id: 1,
      summary_direction: 1
    ]

  def direction_counts(report) do
    case rows(report) do
      [] ->
        report
        |> Map.get("station_pressure_contact_ids_by_direction")
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
        |> Map.get("station_pressure_contact_ids_by_direction")
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
          "station_pressure_contact_ids_by_direction_and_ground_station",
          "station_pressure_contact_ids_by_direction_and_ground_station_id"
        ]
        |> Enum.find_value(fn field ->
          report
          |> Map.get(field)
          |> nested_map_value_lists()
        end)

      rows ->
        contact_ids_by_direction_and_station_from_rows(rows)
    end
  end
end
