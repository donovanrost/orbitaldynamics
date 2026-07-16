defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.GroundStationReport.Rows do
  @moduledoc false

  alias __MODULE__.SummaryValues
  alias __MODULE__.SummaryValues.GroupedIds
  alias __MODULE__.StationPairs

  def ground_station_contact_pairs(row) do
    StationPairs.ground_station_contact_pairs(row)
  end

  def ground_station_source_window_pairs(row) do
    StationPairs.ground_station_source_window_pairs(row)
  end

  def ground_station_station_calendar_entry_pairs(row) do
    StationPairs.ground_station_station_calendar_entry_pairs(row)
  end

  def ground_station_station_calendar_provider_entry_pairs(row) do
    StationPairs.ground_station_station_calendar_provider_entry_pairs(row)
  end

  def string_list_map_or_summary(report, summary_field, row_fun) do
    SummaryValues.string_list_map_or_summary(report, summary_field, row_fun)
  end

  def rows_for_summary(%{"rows" => rows}) when is_list(rows),
    do: SummaryValues.rows_for_summary(%{"rows" => rows})

  def rows_for_summary(%{} = report), do: SummaryValues.rows_for_summary(report)

  def explicit_string_list_map(report, field) do
    SummaryValues.explicit_string_list_map(report, field)
  end

  def grouped_source_report_ids(pairs) do
    GroupedIds.grouped_source_report_ids(pairs)
  end
end
