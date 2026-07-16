defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ModelAcceptance.CountFields.RowCounts.RowValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      count_source_report_values: 1
    ]

  def rows(report) do
    report
    |> Map.get("rows", [])
    |> Enum.map(&EncodedValue.stringify_keys/1)
  end

  def count(rows), do: length(rows)

  def unknown_model_count(rows), do: status_count_by(rows, &validation_level/1, "unknown")

  def status_count(rows, status), do: status_count_by(rows, &status/1, status)

  def validation_level_counts(rows) do
    rows
    |> Enum.map(&validation_level/1)
    |> count_source_report_values()
  end

  defp status_count_by(rows, value_fun, expected_value) do
    Enum.count(rows, &(value_fun.(&1) == expected_value))
  end

  defp status(row), do: Map.get(row, "status") || "unknown"

  defp validation_level(row), do: Map.get(row, "validation_level") || "unknown"
end
