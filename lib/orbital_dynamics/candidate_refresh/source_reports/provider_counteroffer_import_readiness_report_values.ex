defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferImportReadinessReportValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferImportReadinessGroupingValues,
    as: GroupingValues

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferImportReadinessMetricValues,
    as: MetricValues

  defdelegate counteroffer_count(summary, rows), to: MetricValues

  defdelegate reviewable_count(summary, rows), to: MetricValues

  defdelegate counteroffer_cost_delta_count(summary, rows), to: MetricValues

  defdelegate counteroffer_cost_delta_total(summary, rows), to: MetricValues

  defdelegate timing_shift_counteroffer_count(summary, rows), to: MetricValues

  defdelegate counteroffer_lock_deadline_count(rows), to: MetricValues

  defdelegate earliest_counteroffer_lock_deadline_s(rows), to: MetricValues

  defdelegate counteroffer_status_counts(rows), to: MetricValues

  defdelegate required_operator_action_counts(rows), to: MetricValues

  defdelegate import_readiness_status_counts(summary, rows), to: GroupingValues

  defdelegate import_classification_counts(summary, rows), to: GroupingValues

  defdelegate row_counts_or_summary_counts(summary, rows, summary_field, row_field),
    to: GroupingValues

  defdelegate row_ids_or_summary_ids(summary, rows, summary_field, row_field),
    to: GroupingValues

  defdelegate review_counteroffer_ids(summary, rows), to: GroupingValues

  defdelegate no_import_required_counteroffer_ids(summary, rows), to: GroupingValues
end
