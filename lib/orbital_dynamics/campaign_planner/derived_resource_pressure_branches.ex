defmodule OrbitalDynamics.CampaignPlanner.DerivedResourcePressureBranches do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    MissionStateResourceConstraintBranches,
    ResourceFilterPressureBranches,
    ResourceFilterSourceReports,
    ResourceProjectionPressureBranches,
    ResourceProjectionSourceReports
  }

  def build(prior_plan, mission_state, policy) do
    []
    |> Kernel.++(MissionStateResourceConstraintBranches.power(mission_state, policy))
    |> Kernel.++(MissionStateResourceConstraintBranches.thermal(mission_state, policy))
    |> Kernel.++(MissionStateResourceConstraintBranches.payload(mission_state))
    |> Kernel.++(MissionStateResourceConstraintBranches.antenna(mission_state))
    |> Kernel.++(prior_resource_projection(prior_plan, policy))
    |> Kernel.++(mission_resource_projection(mission_state, policy))
    |> Kernel.++(prior_resource_filter(prior_plan))
    |> Kernel.++(mission_resource_filter(mission_state))
  end

  defp prior_resource_projection(prior_plan, policy) do
    prior_plan
    |> ResourceProjectionSourceReports.prior_plan_reports()
    |> ResourceProjectionPressureBranches.from_reports(policy)
  end

  defp mission_resource_projection(mission_state, policy) do
    mission_state
    |> ResourceProjectionSourceReports.reports()
    |> ResourceProjectionPressureBranches.from_reports(policy)
  end

  defp prior_resource_filter(prior_plan) do
    prior_plan
    |> ResourceFilterSourceReports.prior_plan_reports()
    |> ResourceFilterPressureBranches.from_reports()
  end

  defp mission_resource_filter(mission_state) do
    mission_state
    |> ResourceFilterSourceReports.reports()
    |> ResourceFilterPressureBranches.from_reports()
  end
end
