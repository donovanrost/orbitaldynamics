defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Report.Rows.ValueMaps do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Counts

  alias __MODULE__.ByValues
  alias __MODULE__.DirectionCounts
  alias __MODULE__.GroupedPairs
  alias __MODULE__.Normalization
  alias __MODULE__.ValueLists

  def contact_ids_by_values(rows, grouping_fields) do
    ByValues.contact_ids_by_values(rows, grouping_fields)
  end

  def ids_by_values(rows, grouping_fields) do
    ByValues.ids_by_values(rows, grouping_fields)
  end

  def count_rows(rows, field), do: Counts.normalized_rows(rows, field)
  def count_values(values), do: Counts.encoded_values(values)

  def grouped_ids(pairs) do
    GroupedPairs.grouped_ids(pairs)
  end

  def grouped_id_counts(pairs) do
    GroupedPairs.grouped_id_counts(pairs)
  end

  def map_value_lists(value), do: ValueLists.map_value_lists(value)

  def normalize_direction_count_map(counts),
    do: DirectionCounts.normalize_direction_count_map(counts)

  def sorted_string_values(values), do: ValueLists.sorted_string_values(values)

  def normalize_number_list(value), do: Normalization.normalize_number_list(value)

  def report_count(value), do: Normalization.report_count(value)

  def numeric_report_count(report, field), do: Normalization.numeric_report_count(report, field)
end
