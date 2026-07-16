defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDependencyImpact.IdFields.ValueCounts.Values do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDependencyImpact.Rows
  alias __MODULE__.FieldValues

  def report_values(report, fields) do
    Enum.flat_map(fields, &FieldValues.values(report, &1))
  end

  def unique_report_values(report, fields) do
    report
    |> report_values(fields)
    |> Enum.uniq()
  end

  def row_values(report, fields) do
    report
    |> Rows.rows()
    |> Enum.flat_map(fn row -> Enum.flat_map(fields, &FieldValues.values(row, &1)) end)
  end

  def unique_row_values(report, fields) do
    report
    |> Rows.rows()
    |> Enum.flat_map(fn row ->
      fields
      |> Enum.flat_map(&FieldValues.values(row, &1))
      |> Enum.uniq()
    end)
  end
end
