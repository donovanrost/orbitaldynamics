defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ModelAcceptance.CountFields.RowCounts.ReportValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ModelAcceptance.CountFields.CompactCounts

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ModelAcceptance.CountFields.RowCounts.CountWithRows

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ModelAcceptance.CountFields.RowCounts.RowValues

  def summary_row_count(report) do
    count(report, summary_count("row_count"), &RowValues.count/1)
  end

  def model_count(report) do
    count(report, summary_count("model_count"), &RowValues.count/1)
  end

  def unknown_model_count(report) do
    count(report, validation_level_count("unknown"), &RowValues.unknown_model_count/1)
  end

  def status_count(report, status) do
    count(report, status_count(status), &RowValues.status_count(&1, status))
  end

  def validation_level_counts(report) do
    count(report, &CompactCounts.validation_level_counts/1, &RowValues.validation_level_counts/1)
  end

  defp count(report, compact_count_fun, row_count_fun) do
    CountWithRows.count(report, compact_count_fun, row_count_fun)
  end

  defp summary_count(field), do: &CompactCounts.summary_count(&1, field)

  defp status_count(status), do: &CompactCounts.status_count(&1, status)

  defp validation_level_count(level), do: &CompactCounts.validation_level_count(&1, level)
end
