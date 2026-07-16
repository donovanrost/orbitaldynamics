defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferImportReadinessGroupingValues do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [sorted_string_values: 1]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferImportReadinessRowValues,
    as: RowValues

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferImportReadinessStatusCounts

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferImportReadinessSummaryFallbacks,
    as: SummaryFallbacks

  defdelegate import_readiness_status_counts(summary, rows),
    to: ProviderCounterofferImportReadinessStatusCounts

  defdelegate import_classification_counts(summary, rows),
    to: ProviderCounterofferImportReadinessStatusCounts

  def row_counts_or_summary_counts(summary, [], summary_field, _row_field) do
    SummaryFallbacks.row_counts_or_summary_counts(summary, [], summary_field, nil)
  end

  def row_counts_or_summary_counts(_summary, rows, _summary_field, row_field) do
    RowValues.count_rows(rows, row_field)
  end

  def row_ids_or_summary_ids(summary, [], summary_field, _row_field) do
    SummaryFallbacks.row_ids_or_summary_ids(summary, [], summary_field, nil)
  end

  def row_ids_or_summary_ids(_summary, rows, _summary_field, row_field) do
    RowValues.row_ids_by_field(rows, row_field)
  end

  def review_counteroffer_ids(summary, []) do
    sorted_string_values(Map.get(summary, "review_counteroffer_ids", []))
  end

  def review_counteroffer_ids(_summary, rows), do: RowValues.review_ids_from_rows(rows)

  def no_import_required_counteroffer_ids(summary, []) do
    sorted_string_values(Map.get(summary, "no_import_required_counteroffer_ids", []))
  end

  def no_import_required_counteroffer_ids(_summary, rows) do
    RowValues.no_import_required_ids_from_rows(rows)
  end
end
