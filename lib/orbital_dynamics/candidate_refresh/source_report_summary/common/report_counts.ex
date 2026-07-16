defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.ReportCounts do
  @moduledoc false

  alias __MODULE__.NumericSums
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.NumericValue

  def sum_report_count(reports, counter) do
    reports
    |> Enum.map(counter)
    |> Enum.map(&report_count/1)
    |> Enum.sum()
  end

  def sum_report_numeric_values(reports, counter) do
    NumericSums.from_reports(reports, counter)
  end

  def report_count(value) do
    case NumericValue.value(value) do
      value when is_number(value) and value > 0 -> ceil(value)
      _value -> 0
    end
  end

  def numeric_report_count(report, field), do: NumericValue.value(Map.get(report, field)) || 0
end
