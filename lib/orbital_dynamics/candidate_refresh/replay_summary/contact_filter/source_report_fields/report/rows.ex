defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactFilter.SourceReportFields.Report.Rows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Counts
  alias __MODULE__.RowValues
  alias __MODULE__.StationSuppressionGroups
  alias __MODULE__.ValueMaps

  def invalid_input_row?(row) do
    RowValues.invalid_input_row?(row)
  end

  def suppressed_reason_contact_pairs(report) do
    RowValues.suppressed_reason_contact_pairs(report)
  end

  def direction_contact_pairs(report) do
    RowValues.direction_contact_pairs(report)
  end

  def row_contact_id(row) do
    RowValues.row_contact_id(row)
  end

  def suppressed_candidate_rows(report) do
    RowValues.suppressed_candidate_rows(report)
  end

  def station_suppression_contact_ids_by(rows, key_fun) do
    StationSuppressionGroups.contact_ids_by(rows, key_fun)
  end

  def station_suppression_ids_by(rows, key_fun, id_fun) do
    StationSuppressionGroups.ids_by(rows, key_fun, id_fun)
  end

  def row_station_calendar_entry_id(row) do
    RowValues.row_station_calendar_entry_id(row)
  end

  def row_station_calendar_provider_entry_id(row) do
    RowValues.row_station_calendar_provider_entry_id(row)
  end

  def row_station_reservation_id(row) do
    RowValues.row_station_reservation_id(row)
  end

  def station_suppression_rows(report) do
    RowValues.station_suppression_rows(report)
  end

  def row_availability(row) do
    RowValues.row_availability(row)
  end

  def row_status(row) do
    RowValues.row_status(row)
  end

  def count_rows(rows, field), do: Counts.normalized_rows(rows, field)

  def grouped_ids(pairs), do: ValueMaps.grouped_ids(pairs)

  def grouped_id_counts(pairs), do: ValueMaps.grouped_id_counts(pairs)

  def map_value_lists(value), do: ValueMaps.map_value_lists(value)

  def normalize_direction_count_map(counts), do: ValueMaps.normalize_direction_count_map(counts)

  def sorted_string_values(values), do: ValueMaps.sorted_string_values(values)

  def numeric_report_count(report, field), do: ValueMaps.numeric_report_count(report, field)

  def nested_station_id(candidate) do
    StationSuppressionGroups.nested_station_id(candidate)
  end

  def stable_id_or_nil(nil), do: nil
  def stable_id_or_nil(value), do: RowValues.stable_id_or_nil(value)

  def stringify_keys(value), do: RowValues.stringify_keys(value)
end
