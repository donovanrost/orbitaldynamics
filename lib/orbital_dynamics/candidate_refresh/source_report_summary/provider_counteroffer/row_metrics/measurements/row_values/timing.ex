defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ProviderCounteroffer.RowMetrics.Measurements.RowValues.Timing do
  @moduledoc false

  alias __MODULE__.FieldSpecs

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ProviderCounteroffer.RowMetrics.Rows

  def shift_count(report) do
    report
    |> Rows.raw_rows()
    |> Enum.count(&timing_shift?/1)
  end

  def delta_count(report, field) do
    report
    |> Rows.raw_rows()
    |> Enum.count(&(Rows.row_numeric_value(&1, field) |> is_number()))
  end

  defp timing_shift?(row) do
    Enum.any?(FieldSpecs.timing_delta_fields(), fn field ->
      case Rows.row_numeric_value(row, field) do
        nil -> false
        value -> value != 0.0
      end
    end)
  end
end
