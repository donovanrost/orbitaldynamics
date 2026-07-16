defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ModelAcceptance.CountFields.RowCounts do
  @moduledoc false

  alias __MODULE__.ReportValues

  def summary_row_count(report) do
    ReportValues.summary_row_count(report)
  end

  def model_count(report) do
    ReportValues.model_count(report)
  end

  def unknown_model_count(report) do
    ReportValues.unknown_model_count(report)
  end

  def status_count(report, status) do
    ReportValues.status_count(report, status)
  end

  def validation_level_counts(report) do
    ReportValues.validation_level_counts(report)
  end
end
