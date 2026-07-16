defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ProviderCounteroffer.SourceReportFields.Pressure do
  @moduledoc false

  def source_report_fields(summary) do
    %{
      "source_report_provider_counteroffer_branch_local_counteroffer_pressure" =>
        Map.get(summary, "branch_local_counteroffer_pressure"),
      "source_report_provider_counteroffer_branch_local_review_pressure" =>
        Map.get(summary, "branch_local_counteroffer_review_pressure"),
      "source_report_provider_counteroffer_branch_local_cost_pressure" =>
        Map.get(summary, "branch_local_counteroffer_cost_pressure"),
      "source_report_provider_counteroffer_branch_local_timing_pressure" =>
        Map.get(summary, "branch_local_counteroffer_timing_pressure"),
      "source_report_provider_counteroffer_branch_local_lock_pressure" =>
        Map.get(summary, "branch_local_counteroffer_lock_pressure"),
      "source_report_provider_counteroffer_branch_local_import_readiness_pressure" =>
        Map.get(summary, "branch_local_counteroffer_import_readiness_pressure"),
      "source_report_provider_counteroffer_branch_local_plan_impact_pressure" =>
        Map.get(summary, "branch_local_plan_impact_pressure")
    }
  end
end
