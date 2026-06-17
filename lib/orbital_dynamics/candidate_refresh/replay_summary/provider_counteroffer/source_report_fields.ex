defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ProviderCounteroffer.SourceReportFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ProviderCounteroffer
  alias __MODULE__.IdentityCore
  alias __MODULE__.PlanImpact
  alias __MODULE__.ReviewImport

  def source_report_fields(source_reports) do
    summary =
      source_reports
      |> Map.get("provider_counteroffer_report", %{})
      |> ProviderCounteroffer.summary(
        "candidate_refresh.source_report_provenance.provider_counteroffer_report",
        "provider_counteroffer_source_report_provenance_only"
      )

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

  def source_report_summary_fields(source_reports) do
    source_reports
    |> source_report_fields()
    |> Map.merge(source_report_identity_and_core_fields(source_reports))
    |> Map.merge(source_report_review_import_fields(source_reports))
    |> Map.merge(source_report_plan_impact_fields(source_reports))
  end

  def source_report_identity_and_core_fields(source_reports) do
    IdentityCore.fields(source_reports)
  end

  def source_report_review_import_fields(source_reports) do
    ReviewImport.fields(source_reports)
  end

  def source_report_plan_impact_fields(source_reports) do
    PlanImpact.fields(source_reports)
  end
end
