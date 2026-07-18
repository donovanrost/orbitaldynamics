defmodule OrbitalDynamics.CampaignPlanner.DerivedReviewReadinessPressureBranches do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    CandidateDiffPressureEvents,
    CandidateRejectionPressureEvents,
    CandidateReviewSourceReports,
    ModelAcceptancePressureEvents,
    ModelAcceptanceSourceReports,
    OperationalReadinessPressureEvents,
    OperationalReadinessSourceReports,
    ProviderCounterofferPressureEvents,
    ProviderCounterofferSourceReports,
    QualityGatePressureEvents,
    QualityGateSourceReports,
    RefreshBudgetPressureEvents,
    RefreshFreshnessPressureEvents,
    RefreshSourceReports,
    SchemaValidationPressureEvents,
    SchemaValidationSourceReports,
    ValidationSafetyCasePressureEvents,
    ValidationSafetyCaseSourceReports
  }

  def build(prior_plan, mission_state) do
    []
    |> Kernel.++(candidate_diff(mission_state))
    |> Kernel.++(candidate_rejection(mission_state))
    |> Kernel.++(provider_counteroffer(mission_state))
    |> Kernel.++(schema_validation(mission_state))
    |> Kernel.++(prior_operational_readiness(prior_plan))
    |> Kernel.++(mission_operational_readiness(mission_state))
    |> Kernel.++(prior_quality_gate(prior_plan))
    |> Kernel.++(mission_quality_gate(mission_state))
    |> Kernel.++(model_acceptance(mission_state))
    |> Kernel.++(validation_safety_case(mission_state))
    |> Kernel.++(refresh_budget(mission_state))
    |> Kernel.++(refresh_freshness(mission_state))
  end

  defp candidate_diff(mission_state) do
    mission_state
    |> CandidateReviewSourceReports.candidate_diff_reports()
    |> CandidateReviewSourceReports.candidate_diff_pressure_rows()
    |> Enum.flat_map(fn {row, source_path, index} ->
      CandidateDiffPressureEvents.pressure_branch(row, source_path, index)
    end)
  end

  defp candidate_rejection(mission_state) do
    mission_state
    |> CandidateReviewSourceReports.candidate_rejection_reports()
    |> CandidateReviewSourceReports.candidate_rejection_pressure_rows()
    |> Enum.flat_map(fn {row, source_path, index} ->
      CandidateRejectionPressureEvents.pressure_branch(row, source_path, index)
    end)
  end

  defp provider_counteroffer(mission_state) do
    mission_state
    |> ProviderCounterofferSourceReports.pressure_sources()
    |> ProviderCounterofferSourceReports.pressure_rows()
    |> Enum.flat_map(fn {row, source_path, index} ->
      ProviderCounterofferPressureEvents.pressure_branch(row, source_path, index)
    end)
  end

  defp schema_validation(mission_state) do
    mission_state
    |> SchemaValidationSourceReports.schema_validation_reports()
    |> SchemaValidationPressureEvents.pressure_branches_from_sources()
  end

  defp prior_operational_readiness(prior_plan) do
    prior_plan
    |> OperationalReadinessSourceReports.prior_plan_pressure_sources()
    |> OperationalReadinessPressureEvents.pressure_branches_from_sources()
  end

  defp mission_operational_readiness(mission_state) do
    mission_state
    |> OperationalReadinessSourceReports.pressure_sources()
    |> OperationalReadinessPressureEvents.pressure_branches_from_sources()
  end

  defp prior_quality_gate(prior_plan) do
    prior_plan
    |> QualityGateSourceReports.prior_plan_pressure_sources()
    |> QualityGatePressureEvents.pressure_branches_from_sources()
  end

  defp mission_quality_gate(mission_state) do
    mission_state
    |> QualityGateSourceReports.pressure_sources()
    |> QualityGatePressureEvents.pressure_branches_from_sources()
  end

  defp model_acceptance(mission_state) do
    mission_state
    |> ModelAcceptanceSourceReports.model_acceptance_reports()
    |> ModelAcceptancePressureEvents.pressure_branches_from_sources()
  end

  defp validation_safety_case(mission_state) do
    mission_state
    |> ValidationSafetyCaseSourceReports.validation_safety_case_summaries()
    |> ValidationSafetyCasePressureEvents.pressure_branches_from_sources()
  end

  defp refresh_budget(mission_state) do
    mission_state
    |> RefreshSourceReports.refresh_budget_reports()
    |> RefreshSourceReports.pressure_rows()
    |> Enum.flat_map(fn {report, source_path, index} ->
      RefreshBudgetPressureEvents.pressure_branch(report, source_path, index)
    end)
  end

  defp refresh_freshness(mission_state) do
    mission_state
    |> RefreshSourceReports.freshness_reports()
    |> RefreshFreshnessPressureEvents.pressure_branches_from_sources()
  end
end
