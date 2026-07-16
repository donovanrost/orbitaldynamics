defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferSummaryBaseMetrics do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferMetricValues

  defdelegate counteroffer_count(summary, rows), to: ProviderCounterofferMetricValues

  defdelegate reviewable_count(summary, rows), to: ProviderCounterofferMetricValues

  defdelegate counteroffer_cost_delta_count(summary, rows), to: ProviderCounterofferMetricValues

  def counteroffer_cost_delta_total(summary, rows) do
    ProviderCounterofferMetricValues.summary_or_row_counteroffer_cost_delta_total(summary, rows)
  end

  defdelegate timing_shift_counteroffer_count(summary, rows), to: ProviderCounterofferMetricValues

  defdelegate counteroffer_lock_deadline_count(rows), to: ProviderCounterofferMetricValues

  defdelegate earliest_counteroffer_lock_deadline_s(rows), to: ProviderCounterofferMetricValues
end
