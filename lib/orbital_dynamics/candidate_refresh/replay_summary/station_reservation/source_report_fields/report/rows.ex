defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Report.Rows do
  @moduledoc false

  alias __MODULE__.DirectionPairs
  alias __MODULE__.HoldImportReadiness
  alias __MODULE__.RowValues
  alias __MODULE__.ValueMaps

  def single_value_count(value) do
    RowValues.single_value_count(value)
  end

  def hold_ids_by_direction_from_rows(report) do
    DirectionPairs.hold_ids_by_direction_from_rows(report)
  end

  def hold_contact_ids_by_direction_from_rows(report) do
    DirectionPairs.hold_contact_ids_by_direction_from_rows(report)
  end

  def hold_import_readiness_row_count_map(report, fields) do
    HoldImportReadiness.hold_import_readiness_row_count_map(report, fields)
  end

  def hold_import_readiness_row_id_map(report, fields) do
    HoldImportReadiness.hold_import_readiness_row_id_map(report, fields)
  end

  def hold_import_readiness_row_contact_id_map(report, fields) do
    HoldImportReadiness.hold_import_readiness_row_contact_id_map(report, fields)
  end

  def direction_contact_pairs(report) do
    DirectionPairs.direction_contact_pairs(report)
  end

  def contact_ids_by_values(rows, grouping_fields) do
    ValueMaps.contact_ids_by_values(rows, grouping_fields)
  end

  def ids_by_values(rows, grouping_fields) do
    ValueMaps.ids_by_values(rows, grouping_fields)
  end

  def evidence_row?(row) do
    RowValues.evidence_row?(row)
  end

  def expiration_evidence_row?(row) do
    RowValues.expiration_evidence_row?(row)
  end

  def report_rows(report) do
    RowValues.report_rows(report)
  end

  def row_values(row, fields) do
    RowValues.row_values(row, fields)
  end

  def count_rows(rows, field), do: ValueMaps.count_rows(rows, field)
  def count_values(values), do: ValueMaps.count_values(values)

  def grouped_ids(pairs), do: ValueMaps.grouped_ids(pairs)

  def grouped_id_counts(pairs), do: ValueMaps.grouped_id_counts(pairs)

  def map_value_lists(value), do: ValueMaps.map_value_lists(value)

  def normalize_direction_count_map(counts), do: ValueMaps.normalize_direction_count_map(counts)

  def sorted_string_values(values), do: ValueMaps.sorted_string_values(values)

  def normalize_number_list(values), do: ValueMaps.normalize_number_list(values)

  def report_count(value), do: ValueMaps.report_count(value)

  def numeric_report_count(report, field), do: ValueMaps.numeric_report_count(report, field)

  def stable_id_or_nil(value), do: RowValues.stable_id_or_nil(value)

  def non_empty?(value), do: RowValues.non_empty?(value)

  def stringify_keys(value), do: RowValues.stringify_keys(value)
end
