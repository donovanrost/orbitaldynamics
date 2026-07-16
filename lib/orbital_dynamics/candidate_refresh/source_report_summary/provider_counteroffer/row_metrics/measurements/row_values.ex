defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ProviderCounteroffer.RowMetrics.Measurements.RowValues do
  @moduledoc false

  alias __MODULE__.CostDelta
  alias __MODULE__.Timing

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ProviderCounteroffer.RowMetrics.Rows

  def cost_delta_count(report) do
    CostDelta.count(report)
  end

  def cost_delta_total(report) do
    CostDelta.total(report)
  end

  def timing_shift_count(report) do
    Timing.shift_count(report)
  end

  def timing_delta_count(report, field) do
    Timing.delta_count(report, field)
  end

  def lock_deadline_count(report) do
    report
    |> Rows.raw_rows()
    |> Enum.count(&is_number(Map.get(&1, "provider_counteroffer_lock_deadline_s")))
  end

  def lock_deadline_values(report) do
    report
    |> Rows.raw_rows()
    |> Enum.map(&Rows.row_numeric_value(&1, "provider_counteroffer_lock_deadline_s"))
  end
end
