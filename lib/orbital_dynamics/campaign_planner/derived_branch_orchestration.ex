defmodule OrbitalDynamics.CampaignPlanner.DerivedBranchOrchestration do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    BranchCollection,
    CadenceImportPressureBranches,
    CollectionLatencyBranches,
    DerivedActivityPressureBranches,
    DerivedBranchCollection,
    DerivedContactPressureBranches,
    DerivedDegradedSpacecraftBranches,
    DerivedGroundNetworkBranches,
    DerivedObjectivePressureBranches,
    DerivedOperationalReviewPressureBranches,
    DerivedResourcePressureBranches,
    DerivedReviewReadinessPressureBranches,
    DerivedStationPressureBranches,
    DerivedTimelinePressureBranches,
    DownlinkConstrainedBranches,
    FuelPreservationBranches,
    LinkCapacityPressureBranches,
    LinkCapacitySourceReports,
    OperationalFeedbackBranches,
    TargetObjectiveBranches
  }

  def merge(
        branches,
        _prior_plan,
        _mission_state,
        _operational_feedback,
        _operational_feedback_provenance,
        %{"derive_branches" => false}
      ),
      do: branches

  def merge(
        branches,
        prior_plan,
        mission_state,
        operational_feedback,
        operational_feedback_provenance,
        policy
      ) do
    individual_derived =
      []
      |> Kernel.++(DerivedDegradedSpacecraftBranches.build(mission_state))
      |> Kernel.++(DerivedGroundNetworkBranches.build(mission_state, prior_plan))
      |> Kernel.++(DerivedStationPressureBranches.build(prior_plan, mission_state))
      |> Kernel.++(
        OperationalFeedbackBranches.branches(
          mission_state,
          prior_plan,
          operational_feedback,
          operational_feedback_provenance,
          policy
        )
      )
      |> Kernel.++(DerivedResourcePressureBranches.build(prior_plan, mission_state, policy))
      |> Kernel.++(DerivedContactPressureBranches.build(prior_plan, mission_state))
      |> Kernel.++(DerivedReviewReadinessPressureBranches.build(prior_plan, mission_state))
      |> Kernel.++(prior_link_capacity(prior_plan))
      |> Kernel.++(mission_link_capacity(mission_state))
      |> Kernel.++(DerivedObjectivePressureBranches.build(prior_plan, mission_state))
      |> Kernel.++(DerivedTimelinePressureBranches.build(prior_plan, mission_state, policy))
      |> Kernel.++(DerivedActivityPressureBranches.build(prior_plan, mission_state))
      |> Kernel.++(
        DerivedOperationalReviewPressureBranches.build(prior_plan, mission_state, policy)
      )
      |> Kernel.++(CadenceImportPressureBranches.from_prior_plan(prior_plan, policy))
      |> Kernel.++(CadenceImportPressureBranches.from_mission_state(mission_state, policy))
      |> Kernel.++(FuelPreservationBranches.build(mission_state, policy))
      |> Kernel.++(TargetObjectiveBranches.build(mission_state, prior_plan, policy))
      |> Kernel.++(CollectionLatencyBranches.build(mission_state, prior_plan))
      |> Kernel.++(DownlinkConstrainedBranches.build(mission_state, prior_plan, policy))
      |> BranchCollection.dedupe_contact_intent_pressure()

    DerivedBranchCollection.merge(branches, individual_derived, policy)
  end

  defp prior_link_capacity(prior_plan) do
    prior_plan
    |> LinkCapacitySourceReports.prior_plan_reports()
    |> LinkCapacityPressureBranches.from_reports()
    |> LinkCapacityPressureBranches.disambiguate()
  end

  defp mission_link_capacity(mission_state) do
    mission_state
    |> LinkCapacitySourceReports.reports()
    |> LinkCapacityPressureBranches.from_reports()
    |> LinkCapacityPressureBranches.disambiguate()
  end
end
