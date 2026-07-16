defmodule OrbitalDynamics.CampaignPlanner.DerivedBranchCollection do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    BranchCollection,
    ContactAllocationPressureBranches,
    ContactContentionPressureBranches,
    ContactFilterPressureBranches,
    DerivedCombinedBranches,
    DerivedDegradedSpacecraftBranches,
    DerivedGroundNetworkBranches,
    MissionStateResourceConstraintBranches,
    ObjectivePressureBranchIds,
    ResourceFilterPressureBranches,
    ResourceProjectionPressureBranches,
    StrategyBranchNormalization,
    TimelinePressureBranchIds
  }

  def merge(branches, individual_derived, policy) do
    derived =
      [BranchCollection.baseline()]
      |> Kernel.++(individual_derived)
      |> Kernel.++(DerivedCombinedBranches.build(individual_derived, policy))
      |> Enum.map(&StrategyBranchNormalization.normalize_branch/1)

    explicit_ids = MapSet.new(Enum.map(branches, & &1["id"]))

    appended =
      derived
      |> Enum.reject(&MapSet.member?(explicit_ids, &1["id"]))
      |> ResourceProjectionPressureBranches.disambiguate()
      |> ResourceFilterPressureBranches.disambiguate()
      |> ContactFilterPressureBranches.disambiguate()
      |> ContactContentionPressureBranches.disambiguate()
      |> ContactAllocationPressureBranches.disambiguate()
      |> ObjectivePressureBranchIds.disambiguate_score_term_pressure_branch_ids()
      |> ObjectivePressureBranchIds.disambiguate_objective_satisfaction_pressure_branch_ids()
      |> ObjectivePressureBranchIds.disambiguate_objective_tradeoff_pressure_branch_ids()
      |> ObjectivePressureBranchIds.disambiguate_constraint_pressure_branch_ids()
      |> TimelinePressureBranchIds.disambiguate_timeline_integrity_pressure_branch_ids()
      |> TimelinePressureBranchIds.disambiguate_timeline_dependency_impact_pressure_branch_ids()
      |> TimelinePressureBranchIds.disambiguate_timeline_publication_pressure_branch_ids()
      |> TimelinePressureBranchIds.disambiguate_timeline_lifecycle_state_pressure_branch_ids()
      |> TimelinePressureBranchIds.disambiguate_timeline_activity_lifecycle_state_pressure_branch_ids()
      |> TimelinePressureBranchIds.disambiguate_timeline_activity_precondition_pressure_branch_ids()
      |> TimelinePressureBranchIds.disambiguate_timeline_preservation_pressure_branch_ids()
      |> TimelinePressureBranchIds.disambiguate_timeline_diff_pressure_branch_ids()
      |> TimelinePressureBranchIds.disambiguate_review_replay_pressure_branch_ids()
      |> DerivedDegradedSpacecraftBranches.disambiguate()
      |> DerivedGroundNetworkBranches.disambiguate()
      |> MissionStateResourceConstraintBranches.disambiguate()

    (branches ++ appended)
    |> BranchCollection.dedupe()
    |> Enum.sort_by(& &1["id"])
  end
end
