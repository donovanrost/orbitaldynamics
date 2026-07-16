defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ProviderCounteroffer.RowMetrics.Measurements.RowValues.CostDelta do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ProviderCounteroffer.RowMetrics.Rows

  @field "provider_counteroffer_cost_delta"

  def count(report) do
    report
    |> Rows.raw_rows()
    |> Enum.count(&is_number(Map.get(&1, @field)))
  end

  def total(report) do
    report
    |> Rows.raw_rows()
    |> Enum.map(&Map.get(&1, @field))
    |> Enum.filter(&is_number/1)
    |> Enum.sum()
  end
end
