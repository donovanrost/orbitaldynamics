defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ProviderCounteroffer.RowMetrics.Measurements.ReportValues.ResolvedValues do
  @moduledoc false

  alias __MODULE__.FallbackValues
  alias __MODULE__.LockDeadlineValues

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ProviderCounteroffer.RowMetrics.Measurements.RowValues

  def cost_delta_count(report) do
    FallbackValues.count(report, "counteroffer_cost_delta_count", &RowValues.cost_delta_count/1)
  end

  def cost_delta_total(report) do
    FallbackValues.total(report, "counteroffer_cost_delta_total", &RowValues.cost_delta_total/1)
  end

  def timing_shift_count(report) do
    FallbackValues.count(
      report,
      "timing_shift_counteroffer_count",
      &RowValues.timing_shift_count/1
    )
  end

  def timing_delta_count(report, field), do: RowValues.timing_delta_count(report, field)

  def lock_deadline_count(report) do
    FallbackValues.count(
      report,
      "counteroffer_lock_deadline_count",
      &RowValues.lock_deadline_count/1
    )
  end

  def earliest_lock_deadline_s(reports) do
    LockDeadlineValues.earliest(reports)
  end
end
