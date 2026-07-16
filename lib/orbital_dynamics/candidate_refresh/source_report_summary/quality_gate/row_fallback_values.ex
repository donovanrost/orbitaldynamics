defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.RowFallbackValues do
  @moduledoc false

  alias __MODULE__.{ReportValues, RowFallbacks}

  def count(report, field) do
    RowFallbacks.count(report, field)
  end

  def count_map(report, field) do
    RowFallbacks.count_map(report, field)
  end

  def string_list(report, field) do
    ReportValues.string_list(report, field)
  end

  def string_list_map(report, field) do
    ReportValues.string_list_map(report, field)
  end

  def row_string_list(report, field) do
    RowFallbacks.string_list(report, field)
  end

  def row_string_list_map(report, field) do
    RowFallbacks.string_list_map(report, field)
  end
end
