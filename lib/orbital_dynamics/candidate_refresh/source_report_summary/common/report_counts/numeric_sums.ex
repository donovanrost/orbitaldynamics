defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.ReportCounts.NumericSums do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.NumericValue

  def from_reports(reports, counter) do
    reports
    |> Enum.map(counter)
    |> Enum.map(&NumericValue.value/1)
    |> Enum.filter(&is_number/1)
    |> sum_values()
  end

  defp sum_values([]), do: nil
  defp sum_values(values), do: Enum.sum(values)
end
