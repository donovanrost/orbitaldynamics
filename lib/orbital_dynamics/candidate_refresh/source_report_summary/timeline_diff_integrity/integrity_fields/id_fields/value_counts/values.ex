defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.IntegrityFields.IdFields.ValueCounts.Values do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [source_field_values: 2, source_rows: 1]

  def report_values(source, fields) do
    Enum.flat_map(fields, &source_field_values(source, &1))
  end

  def unique_report_values(source, fields) do
    source
    |> report_values(fields)
    |> Enum.uniq()
  end

  def row_values(report, fields) do
    report
    |> source_rows()
    |> Enum.flat_map(&report_values(&1, fields))
  end

  def unique_row_values(report, fields) do
    report
    |> source_rows()
    |> Enum.flat_map(fn row ->
      row
      |> report_values(fields)
      |> Enum.uniq()
    end)
  end
end
