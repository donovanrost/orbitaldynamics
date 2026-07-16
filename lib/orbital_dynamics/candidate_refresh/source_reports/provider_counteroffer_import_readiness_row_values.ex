defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferImportReadinessRowValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferImportReadinessRowClassifications,
    as: RowClassifications

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferImportReadinessNumericRows,
    as: NumericRows

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferImportReadinessRowGroups,
    as: RowGroups

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferImportReadinessRowNormalization,
    as: RowNormalization

  def timing_shift_rows(rows) do
    NumericRows.timing_shift_rows(rows)
  end

  def numeric_value_count(rows, field) do
    NumericRows.numeric_value_count(rows, field)
  end

  def numeric_value_sum(rows, field) do
    NumericRows.numeric_value_sum(rows, field)
  end

  def numeric_value_min(rows, field) do
    NumericRows.numeric_value_min(rows, field)
  end

  def row_ids_by_field(rows, row_field) do
    RowGroups.row_ids_by_field(rows, row_field)
  end

  def review_ids_from_rows(rows) do
    RowClassifications.review_ids_from_rows(rows)
  end

  def no_import_required_ids_from_rows(rows) do
    RowClassifications.no_import_required_ids_from_rows(rows)
  end

  def import_readiness_status_counts_from_rows(rows) do
    RowClassifications.import_readiness_status_counts_from_rows(rows)
  end

  def import_classification_counts_from_rows(rows) do
    RowClassifications.import_classification_counts_from_rows(rows)
  end

  def count_rows(rows, field) do
    RowGroups.count_rows(rows, field)
  end

  def stringify_keys(value), do: RowNormalization.stringify_keys(value)

  def numeric_value(value), do: NumericRows.numeric_value(value)
end
