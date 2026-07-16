defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferImportReadinessReportFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferImportReadinessReportValues,
    as: Values

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferImportReadinessStatusFields

  def report_fields(%{} = summary, rows) when is_list(rows) do
    %{
      "rows" => rows,
      "counteroffer_count" => Values.counteroffer_count(summary, rows),
      "reviewable_count" => Values.reviewable_count(summary, rows),
      "counteroffer_cost_delta_count" => Values.counteroffer_cost_delta_count(summary, rows),
      "counteroffer_cost_delta_total" => Values.counteroffer_cost_delta_total(summary, rows),
      "timing_shift_counteroffer_count" => Values.timing_shift_counteroffer_count(summary, rows),
      "counteroffer_lock_deadline_count" => Values.counteroffer_lock_deadline_count(rows),
      "earliest_counteroffer_lock_deadline_s" =>
        Values.earliest_counteroffer_lock_deadline_s(rows),
      "counteroffer_status_counts" => Values.counteroffer_status_counts(rows),
      "required_operator_action_counts" => Values.required_operator_action_counts(rows)
    }
    |> Map.merge(ProviderCounterofferImportReadinessStatusFields.fields(summary, rows))
  end
end
