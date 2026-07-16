defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferSummaryBaseFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferSummaryBaseMetrics

  def fields(summary, rows, model) do
    %{
      "schema_contract" => "provider_counteroffer_report.v1",
      "model" => model,
      "source" => Map.get(summary, "source"),
      "source_summary_model" => Map.get(summary, "model"),
      "source_summary_schema_contract" => Map.get(summary, "schema_contract"),
      "source_artifact_type" => Map.get(summary, "source_artifact_type"),
      "source_counteroffer_artifact_type" =>
        Map.get(summary, "source_counteroffer_artifact_type"),
      "source_artifact_id" => Map.get(summary, "source_artifact_id"),
      "trust_boundary" => Map.get(summary, "trust_boundary"),
      "rows" => rows,
      "counteroffer_count" =>
        ProviderCounterofferSummaryBaseMetrics.counteroffer_count(summary, rows),
      "reviewable_count" =>
        ProviderCounterofferSummaryBaseMetrics.reviewable_count(summary, rows),
      "counteroffer_cost_delta_count" =>
        ProviderCounterofferSummaryBaseMetrics.counteroffer_cost_delta_count(summary, rows),
      "counteroffer_cost_delta_total" =>
        ProviderCounterofferSummaryBaseMetrics.counteroffer_cost_delta_total(summary, rows),
      "timing_shift_counteroffer_count" =>
        ProviderCounterofferSummaryBaseMetrics.timing_shift_counteroffer_count(summary, rows),
      "counteroffer_lock_deadline_count" =>
        ProviderCounterofferSummaryBaseMetrics.counteroffer_lock_deadline_count(rows),
      "earliest_counteroffer_lock_deadline_s" =>
        ProviderCounterofferSummaryBaseMetrics.earliest_counteroffer_lock_deadline_s(rows)
    }
  end
end
