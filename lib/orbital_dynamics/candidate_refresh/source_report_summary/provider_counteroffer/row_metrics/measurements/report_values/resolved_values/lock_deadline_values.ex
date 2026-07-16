defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ProviderCounteroffer.RowMetrics.Measurements.ReportValues.ResolvedValues.LockDeadlineValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.NumericValue

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ProviderCounteroffer.RowMetrics.Measurements.RowValues

  def values(report) do
    [
      NumericValue.value(Map.get(report, "earliest_counteroffer_lock_deadline_s"))
      | RowValues.lock_deadline_values(report)
    ]
  end

  def earliest(reports) do
    reports
    |> Enum.flat_map(&values/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.min(fn -> nil end)
  end
end
