defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.DirectionReport.Rows do
  @moduledoc false

  alias __MODULE__.DirectionPairs
  alias __MODULE__.SummaryValues
  alias __MODULE__.SummaryValues.GroupedIds

  def direction_contact_pairs(row) do
    DirectionPairs.direction_contact_pairs(row)
  end

  def direction_source_window_pairs(row) do
    DirectionPairs.direction_source_window_pairs(row)
  end

  def direction_station_calendar_entry_pairs(row) do
    DirectionPairs.direction_station_calendar_entry_pairs(row)
  end

  def direction_station_calendar_provider_entry_pairs(row) do
    DirectionPairs.direction_station_calendar_provider_entry_pairs(row)
  end

  def row_direction(row) do
    DirectionPairs.row_direction(row)
  end

  def rows_for_summary(report), do: SummaryValues.rows_for_summary(report)

  def explicit_string_list_map(report, field) do
    SummaryValues.explicit_string_list_map(report, field)
  end

  def grouped_source_report_ids(pairs) do
    GroupedIds.grouped_source_report_ids(pairs)
  end

  def grouped_source_report_id_counts(pairs) do
    GroupedIds.grouped_source_report_id_counts(pairs)
  end

  def numeric_value(value), do: SummaryValues.numeric_value(value)

  def non_empty_map(map), do: GroupedIds.non_empty_map(map)
end
