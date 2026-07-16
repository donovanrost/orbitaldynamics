defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ProviderCounteroffer.RowMetrics.Measurements.ReportValues do
  @moduledoc false

  alias __MODULE__.ResolvedValues

  def cost_delta_count(report) do
    ResolvedValues.cost_delta_count(report)
  end

  def cost_delta_total(report) do
    ResolvedValues.cost_delta_total(report)
  end

  def timing_shift_count(report) do
    ResolvedValues.timing_shift_count(report)
  end

  def timing_delta_count(report, field), do: ResolvedValues.timing_delta_count(report, field)

  def lock_deadline_count(report) do
    ResolvedValues.lock_deadline_count(report)
  end

  def earliest_lock_deadline_s(reports) do
    ResolvedValues.earliest_lock_deadline_s(reports)
  end
end
