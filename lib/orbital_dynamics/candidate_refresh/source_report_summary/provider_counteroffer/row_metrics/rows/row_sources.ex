defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ProviderCounteroffer.RowMetrics.Rows.RowSources do
  @moduledoc false

  alias __MODULE__.EncodedRowFields
  alias __MODULE__.ReportRows

  def raw_rows(report) do
    ReportRows.raw(report)
  end

  def count_by_field(report, top_level_field, row_field) do
    case ReportRows.encoded(report) do
      [] -> Map.get(report, top_level_field)
      rows -> EncodedRowFields.count_by_field(rows, row_field)
    end
  end

  def ids_by_field(report, row_field) do
    report
    |> ReportRows.encoded()
    |> EncodedRowFields.ids_by_field(row_field)
  end
end
