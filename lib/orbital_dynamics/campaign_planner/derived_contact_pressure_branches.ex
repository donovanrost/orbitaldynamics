defmodule OrbitalDynamics.CampaignPlanner.DerivedContactPressureBranches do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ContactAllocationReportPressureBranches,
    ContactAllocationSourceReports,
    ContactAllocationSummaryPressureBranches,
    ContactContentionPressureBranches,
    ContactContentionSourceReports,
    ContactFilterPressureBranches,
    ContactFilterSourceReports
  }

  def build(prior_plan, mission_state) do
    []
    |> Kernel.++(prior_contact_filter(prior_plan))
    |> Kernel.++(mission_contact_filter(mission_state))
    |> Kernel.++(mission_contact_contention(mission_state))
    |> Kernel.++(prior_contact_contention_resolution(prior_plan))
    |> Kernel.++(mission_contact_contention_resolution(mission_state))
    |> Kernel.++(prior_contact_allocation(prior_plan))
    |> Kernel.++(prior_contact_allocation_summary(prior_plan))
    |> Kernel.++(mission_contact_allocation(mission_state))
    |> Kernel.++(mission_contact_allocation_summary(mission_state))
  end

  defp prior_contact_filter(prior_plan) do
    prior_plan
    |> ContactFilterSourceReports.prior_plan_reports()
    |> ContactFilterPressureBranches.from_reports()
  end

  defp mission_contact_filter(mission_state) do
    mission_state
    |> ContactFilterSourceReports.reports()
    |> ContactFilterPressureBranches.from_reports()
  end

  defp mission_contact_contention(mission_state) do
    mission_state
    |> ContactContentionSourceReports.contention_reports()
    |> ContactContentionPressureBranches.conflicts_from_reports()
  end

  defp prior_contact_contention_resolution(prior_plan) do
    prior_plan
    |> ContactContentionSourceReports.prior_resolution_reports()
    |> ContactContentionPressureBranches.resolutions_from_reports()
  end

  defp mission_contact_contention_resolution(mission_state) do
    mission_state
    |> ContactContentionSourceReports.resolution_reports()
    |> ContactContentionPressureBranches.resolutions_from_reports()
  end

  defp prior_contact_allocation(prior_plan) do
    prior_plan
    |> ContactAllocationSourceReports.prior_plan_reports()
    |> ContactAllocationReportPressureBranches.build()
  end

  defp prior_contact_allocation_summary(prior_plan) do
    prior_plan
    |> ContactAllocationSourceReports.prior_plan_pressure_summaries()
    |> ContactAllocationSummaryPressureBranches.build()
  end

  defp mission_contact_allocation(mission_state) do
    mission_state
    |> ContactAllocationSourceReports.reports()
    |> ContactAllocationReportPressureBranches.build()
  end

  defp mission_contact_allocation_summary(mission_state) do
    mission_state
    |> ContactAllocationSourceReports.pressure_summaries()
    |> ContactAllocationSummaryPressureBranches.build()
  end
end
