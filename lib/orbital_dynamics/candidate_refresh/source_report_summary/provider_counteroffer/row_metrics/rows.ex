defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ProviderCounteroffer.RowMetrics.Rows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.NumericValue

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ProviderCounteroffer.RowMetrics.Rows.RowSources

  def row_count_from_rows(report), do: length(raw_rows(report))

  def raw_rows(report), do: RowSources.raw_rows(report)

  def row_numeric_value(row, field) do
    row
    |> Map.get(field)
    |> NumericValue.value()
  end

  def count_by_field(report, top_level_field, row_field),
    do: RowSources.count_by_field(report, top_level_field, row_field)

  def ids_by_field(report, row_field), do: RowSources.ids_by_field(report, row_field)
end
