defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ProviderCounteroffer.RowMetrics do
  @moduledoc false

  alias __MODULE__.CountFields
  alias __MODULE__.Measurements
  alias __MODULE__.Rows

  def fields(reports) do
    reports
    |> CountFields.fields()
    |> Map.merge(Measurements.fields(reports))
  end

  def row_counts(report, top_level_field, row_field) do
    Rows.count_by_field(report, top_level_field, row_field)
  end

  def ids_by_row_field(report, row_field) do
    Rows.ids_by_field(report, row_field)
  end
end
