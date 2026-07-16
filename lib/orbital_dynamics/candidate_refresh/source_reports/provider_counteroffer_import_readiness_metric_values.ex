defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferImportReadinessMetricValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferImportReadinessRowValues,
    as: RowValues

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferMetricValues,
    as: MetricValues

  defdelegate counteroffer_count(summary, rows), to: MetricValues

  defdelegate reviewable_count(summary, rows), to: MetricValues

  defdelegate counteroffer_cost_delta_count(summary, rows), to: MetricValues

  def counteroffer_cost_delta_total(summary, rows),
    do: MetricValues.row_counteroffer_cost_delta_total(summary, rows)

  defdelegate timing_shift_counteroffer_count(summary, rows), to: MetricValues

  defdelegate counteroffer_lock_deadline_count(rows), to: MetricValues

  defdelegate earliest_counteroffer_lock_deadline_s(rows), to: MetricValues

  def counteroffer_status_counts(rows) do
    RowValues.count_rows(rows, "provider_counteroffer_status")
  end

  def required_operator_action_counts(rows),
    do: RowValues.count_rows(rows, "required_operator_action")
end
