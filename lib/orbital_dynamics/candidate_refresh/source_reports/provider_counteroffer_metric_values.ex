defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferMetricValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferImportReadinessRowValues,
    as: RowValues

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferSummaryCountFallbacks,
    as: CountFallbacks

  def counteroffer_count(summary, rows), do: summary_count(summary, "counteroffer_count", rows)

  def reviewable_count(summary, rows) do
    summary_count(summary, "reviewable_count", Enum.count(rows, &(&1["reviewable"] == true)))
  end

  def counteroffer_cost_delta_count(summary, rows) do
    summary_count(
      summary,
      "counteroffer_cost_delta_count",
      RowValues.numeric_value_count(rows, "provider_counteroffer_cost_delta")
    )
  end

  def row_counteroffer_cost_delta_total(summary, []) do
    RowValues.numeric_value(Map.get(summary, "counteroffer_cost_delta_total")) || 0.0
  end

  def row_counteroffer_cost_delta_total(_summary, rows) do
    RowValues.numeric_value_sum(rows, "provider_counteroffer_cost_delta")
  end

  def summary_or_row_counteroffer_cost_delta_total(summary, rows) do
    RowValues.numeric_value(Map.get(summary, "counteroffer_cost_delta_total")) ||
      RowValues.numeric_value_sum(rows, "provider_counteroffer_cost_delta")
  end

  def timing_shift_counteroffer_count(summary, rows) do
    summary_count(summary, "timing_shift_counteroffer_count", RowValues.timing_shift_rows(rows))
  end

  def counteroffer_lock_deadline_count(rows) do
    RowValues.numeric_value_count(rows, "provider_counteroffer_lock_deadline_s")
  end

  def earliest_counteroffer_lock_deadline_s(rows) do
    RowValues.numeric_value_min(rows, "provider_counteroffer_lock_deadline_s")
  end

  defp summary_count(summary, field, rows_or_count) do
    CountFallbacks.summary_count(summary, field, rows_or_count)
  end
end
