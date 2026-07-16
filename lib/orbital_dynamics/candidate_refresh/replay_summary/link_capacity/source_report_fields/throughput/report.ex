defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Throughput.Report do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Throughput.Report.Rows,
    only: [
      count_or_row_count: 3,
      explicit_count_map: 2,
      link_capacity_summary_source?: 1,
      numeric_map_or_summary: 3,
      numeric_value: 1,
      positive_number_value?: 1,
      relay_data_path_summary_source?: 1,
      rows_for_summary: 1,
      spacecraft_id: 1,
      station_id: 1,
      summary_integer: 2
    ]

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Counts

  def row_count(report) do
    cond do
      link_capacity_summary_source?(report) ->
        summary_integer(report, "station_count")

      relay_data_path_summary_source?(report) ->
        summary_integer(report, "route_count")

      is_list(Map.get(report, "rows")) ->
        length(Map.get(report, "rows"))

      true ->
        1
    end
  end

  def selected_shortfall_row_count(report) do
    count_or_row_count(
      report,
      "shortfall_ground_station_ids",
      fn report ->
        report
        |> rows_for_summary()
        |> Enum.count(&positive_number_value?(Map.get(&1, "selected_downlink_shortfall_mb")))
      end
    )
  end

  def actual_shortfall_row_count(report) do
    count_or_row_count(
      report,
      "actual_shortfall_ground_station_ids",
      fn report ->
        report
        |> rows_for_summary()
        |> Enum.count(&positive_number_value?(Map.get(&1, "actual_downlink_shortfall_mb")))
      end
    )
  end

  def actual_throughput_row_count(report) do
    count_or_row_count(
      report,
      "actual_throughput_contact_ids",
      fn report ->
        report
        |> rows_for_summary()
        |> Enum.count(&positive_number_value?(Map.get(&1, "actual_throughput_mb")))
      end
    )
  end

  def capacity_adjusted_throughput_row_count(report) do
    count_or_row_count(
      report,
      "capacity_adjusted_throughput_mb_by_ground_station_id",
      fn report ->
        report
        |> rows_for_summary()
        |> Enum.count(&(numeric_value(Map.get(&1, "capacity_adjusted_throughput_mb")) != nil))
      end
    )
  end

  def numeric_total(report, field) do
    values =
      report
      |> rows_for_summary()
      |> Enum.map(&(Map.get(&1, field) |> numeric_value()))
      |> Enum.filter(&is_number/1)

    case values do
      [] -> nil
      values -> Enum.sum(values)
    end
  end

  def numeric_values_by_ground_station(report, field) do
    summary_field = "#{field}_by_ground_station_id"

    numeric_map_or_summary(report, summary_field, field)
  end

  def ground_station_counts(report) do
    if link_capacity_summary_source?(report) do
      report
      |> Map.get("ground_station_ids")
      |> Counts.normalized_values()
    else
      report
      |> rows_for_summary()
      |> Enum.map(fn row -> Map.put(row, "ground_station_id", station_id(row)) end)
      |> Counts.normalized_rows("ground_station_id")
    end
  end

  def spacecraft_counts(report) do
    report
    |> rows_for_summary()
    |> Enum.map(fn row -> Map.put(row, "spacecraft_id", spacecraft_id(row)) end)
    |> Counts.normalized_rows("spacecraft_id")
    |> case do
      nil -> explicit_count_map(report, "spacecraft_counts")
      spacecraft_counts -> spacecraft_counts
    end
  end
end
