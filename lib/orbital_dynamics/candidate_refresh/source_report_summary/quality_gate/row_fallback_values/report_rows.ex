defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.RowFallbackValues.ReportRows do
  @moduledoc false

  alias __MODULE__.AggregateValues
  alias __MODULE__.Rows

  def values(report) do
    Rows.values(report)
  end

  def count(rows, field) do
    AggregateValues.count(rows, field)
  end

  def count_map(rows, field) do
    AggregateValues.count_map(rows, field)
  end

  def string_list(rows, field) do
    AggregateValues.string_list(rows, field)
  end

  def string_list_map(rows, field) do
    AggregateValues.string_list_map(rows, field)
  end
end
