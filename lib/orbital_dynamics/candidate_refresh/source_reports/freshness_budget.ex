defmodule OrbitalDynamics.CandidateRefresh.SourceReports.FreshnessBudget do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.Freshness
  alias OrbitalDynamics.CandidateRefresh.SourceReports.FreshnessBudgetTraversal
  alias OrbitalDynamics.CandidateRefresh.SourceReports.RefreshBudget

  def freshness_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    FreshnessBudgetTraversal.reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun,
      Freshness,
      "freshness_report"
    )
  end

  def refresh_budget_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    FreshnessBudgetTraversal.reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun,
      RefreshBudget,
      "refresh_budget_report"
    )
  end
end
