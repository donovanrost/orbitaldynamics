defmodule OrbitalDynamics.Schema.CampaignArtifactValidation do
  @moduledoc false

  alias OrbitalDynamics.Schema.{
    CadenceImportValidation,
    CampaignPlanContracts,
    CampaignRegistryContracts,
    CampaignRepairContracts,
    CampaignStrategyContracts,
    CandidateRejectionValidation,
    CommandWindowValidation,
    ContactAllocationValidation,
    ContactIntentValidation,
    ContactReportValidation,
    DecisionSupportValidation,
    LinkCapacityValidation,
    OperationalReadinessValidation,
    OperationalTimelineValidation,
    OperatorReviewValidation,
    PlanChangeRegistryContracts,
    PlanDeltaContracts,
    PolicyValidation,
    ProposedContactContracts,
    ProposedContactRegistryContracts,
    ProviderCounterofferValidation,
    RealizedStateValidation,
    RefreshBudgetReportContracts,
    ResourceValidation,
    SchemaOperationsValidation,
    StationReservationValidation,
    StrategyManeuverRegistryContracts,
    TimelineArtifactValidation,
    TimelineContextValidation,
    TimelineSourceValidation,
    TimelineTransitionValidation,
    ValidationArtifactValidation
  }

  @campaign_plan "campaign_plan.v1"
  @campaign_repair "campaign_repair.v2"
  @campaign_strategy "campaign_strategy.v3"
  @strategy_branch "strategy_branch.v1"
  @strategy_recommendation "strategy_recommendation.v1"
  @plan_delta "plan_delta.v1"
  @proposed_contact "proposed_contact.v1"

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [expect_equal: 5, require_fields: 4]

  def validate_plan(issues, artifact),
    do:
      CampaignPlanContracts.validate(
        issues,
        artifact,
        required_fields(@campaign_plan),
        plan_callbacks()
      )

  def validate_repair(issues, artifact),
    do:
      CampaignRepairContracts.validate(
        issues,
        artifact,
        required_fields(@campaign_repair),
        repair_callbacks()
      )

  def validate_strategy(issues, artifact) do
    CampaignStrategyContracts.validate(
      issues,
      artifact,
      required_fields(@campaign_strategy),
      &OrbitalDynamics.Schema.OperationalFeedbackContracts.validate/3,
      &validate_branch/3,
      &validate_recommendation/3,
      &DecisionSupportValidation.validate_optional_branch_comparison_report/2,
      &DecisionSupportValidation.validate_optional_ranking_comparison_report/2,
      &OperatorReviewValidation.validate_optional_package/2
    )
  end

  def validate_branch_artifact(issues, path, branch) do
    issues
    |> require_fields(path, branch, required_fields(@strategy_branch))
    |> expect_equal(path, branch, "schema_contract", @strategy_branch)
    |> validate_branch(path, branch)
  end

  def validate_recommendation_artifact(issues, path, recommendation) do
    issues
    |> require_fields(
      path,
      recommendation,
      required_fields(StrategyManeuverRegistryContracts, @strategy_recommendation)
    )
    |> validate_recommendation(path, recommendation)
  end

  def validate_delta_artifact(issues, path, delta) do
    issues
    |> require_fields(
      path,
      delta,
      required_fields(PlanChangeRegistryContracts, @plan_delta)
    )
    |> PlanDeltaContracts.validate(path, delta)
  end

  def validate_proposed_contact_artifact(issues, path, contact) do
    issues
    |> require_fields(
      path,
      contact,
      required_fields(ProposedContactRegistryContracts, @proposed_contact)
    )
    |> ProposedContactContracts.validate(path, contact)
  end

  def validate_branch(issues, path, branch) do
    OrbitalDynamics.Schema.StrategyBranchContracts.validate(
      issues,
      path,
      branch,
      &OrbitalDynamics.Schema.BranchEventContracts.validate_event/3,
      &ResourceValidation.validate_optional_resource_projection_report/3,
      &PolicyValidation.validate_decision/3,
      &PolicyValidation.validate_approval_requirement/3
    )
  end

  def validate_recommendation(issues, path, recommendation) do
    OrbitalDynamics.Schema.StrategyRecommendationContracts.validate(
      issues,
      path,
      recommendation,
      &OrbitalDynamics.Schema.BranchEventContracts.validate_summary_fields/3,
      &OrbitalDynamics.Schema.ScopedDownlinkContextContracts.validate/3
    )
  end

  defp plan_callbacks do
    [
      require_fields: &OrbitalDynamics.Schema.PrimitiveValidation.require_fields/4,
      validate_stable_ids: &OrbitalDynamics.Schema.StableIdValidation.validate_stable_ids/4,
      expect_equal: &OrbitalDynamics.Schema.PrimitiveValidation.expect_equal/5,
      expect_type: &OrbitalDynamics.Schema.PrimitiveValidation.expect_type/5,
      expect_optional_type: &OrbitalDynamics.Schema.PrimitiveValidation.expect_optional_type/5,
      validate_optional_contact_contention_report:
        &ContactReportValidation.validate_optional_contention_report/2,
      validate_optional_contact_contention_resolution_report:
        &ContactReportValidation.validate_optional_contention_resolution_report/2,
      validate_optional_station_calendar_report:
        &StationReservationValidation.validate_optional_calendar_report/2,
      validate_optional_objective_tradeoff_report:
        &DecisionSupportValidation.validate_optional_objective_tradeoff_report/2,
      validate_optional_objective_satisfaction_report:
        &DecisionSupportValidation.validate_optional_objective_satisfaction_report/2,
      validate_optional_operational_timeline_report:
        &OperationalTimelineValidation.validate_optional_report/2,
      validate_optional_timeline_transition_application_report:
        &TimelineTransitionValidation.validate_optional_timeline_transition_application_report/3,
      validate_optional_operator_review_package:
        &OperatorReviewValidation.validate_optional_package/2,
      validate_optional_operational_readiness_report:
        &OperationalReadinessValidation.validate_optional_operational_readiness_report/3,
      validate_optional_quality_gate_report:
        &OperationalReadinessValidation.validate_optional_quality_gate_report/3,
      validate_optional_optimizer_contract:
        &DecisionSupportValidation.validate_optional_optimizer_contract/2,
      validate_optional_constraint_report:
        &DecisionSupportValidation.validate_optional_constraint_report/2,
      validate_optional_contact_allocation_report:
        &ContactAllocationValidation.validate_optional_report/2,
      validate_optional_cadence_import_manifest:
        &CadenceImportValidation.validate_optional_manifest/2,
      validate_optional_command_window_report:
        &CommandWindowValidation.validate_optional_report/2,
      validate_optional_link_capacity_report: &LinkCapacityValidation.validate_optional_report/2,
      validate_optional_resource_projection_report:
        &ResourceValidation.validate_optional_resource_projection_report/3,
      validate_optional_resource_projection_flow_summary:
        &ResourceValidation.validate_optional_resource_projection_flow_summary/3,
      validate_optional_timeline_activity_precondition_summaries:
        &TimelineSourceValidation.validate_optional_timeline_activity_precondition_summaries/3,
      validate_optional_timeline_integrity_report:
        &TimelineSourceValidation.validate_optional_timeline_integrity_report/3,
      validate_optional_resource_filter_report:
        &ResourceValidation.validate_optional_resource_filter_report/3,
      validate_optional_score_term_report:
        &DecisionSupportValidation.validate_optional_score_term_report/2,
      validate_rows: &OrbitalDynamics.Schema.CollectionValidation.validate_rows/4,
      validate_activity: &OrbitalDynamics.Schema.ActivityContracts.validate/3,
      validate_proposed_contact: &OrbitalDynamics.Schema.ProposedContactContracts.validate/3,
      validate_contact_intent: &OrbitalDynamics.Schema.ContactIntentContracts.validate/3,
      validate_optional_contact_filter_report:
        &ContactReportValidation.validate_optional_filter_report/2
    ]
  end

  defp repair_callbacks do
    [
      require_fields: &OrbitalDynamics.Schema.PrimitiveValidation.require_fields/4,
      validate_stable_ids: &OrbitalDynamics.Schema.StableIdValidation.validate_stable_ids/4,
      expect_equal: &OrbitalDynamics.Schema.PrimitiveValidation.expect_equal/5,
      expect_type: &OrbitalDynamics.Schema.PrimitiveValidation.expect_type/5,
      expect_optional_type: &OrbitalDynamics.Schema.PrimitiveValidation.expect_optional_type/5,
      expect_one_of: &OrbitalDynamics.Schema.PrimitiveValidation.expect_one_of/5,
      validate_optional_stable_ids:
        &OrbitalDynamics.Schema.StableIdValidation.validate_optional_stable_ids/4,
      validate_realized_state_snapshot:
        &OrbitalDynamics.Schema.RealizedStateSnapshotContracts.validate/3,
      validate_optional_source_realized_state_snapshot:
        &RealizedStateValidation.validate_optional_snapshot/3,
      validate_rows: &OrbitalDynamics.Schema.CollectionValidation.validate_rows/4,
      validate_optional_rows:
        &OrbitalDynamics.Schema.CollectionValidation.validate_optional_rows/4,
      validate_activity: &OrbitalDynamics.Schema.ActivityContracts.validate/3,
      validate_policy_rule_match: &PolicyValidation.validate_rule_match/3,
      validate_contact_intent: &OrbitalDynamics.Schema.ContactIntentContracts.validate/3,
      validate_optional_contact_intent_summary:
        &ContactIntentValidation.validate_optional_summary/3,
      validate_resource_summary: &OrbitalDynamics.Schema.ResourceSummaryContracts.validate/3,
      validate_optional_contact_filter_report:
        &ContactReportValidation.validate_optional_filter_report/3,
      validate_optional_resource_filter_report:
        &ResourceValidation.validate_optional_resource_filter_report/3,
      validate_optional_resource_filter_summary:
        &ResourceValidation.validate_optional_resource_filter_summary/3,
      validate_optional_resource_projection_report:
        &ResourceValidation.validate_optional_resource_projection_report/3,
      validate_optional_resource_projection_flow_summary:
        &ResourceValidation.validate_optional_resource_projection_flow_summary/3,
      validate_optional_timeline_feedback_report:
        &TimelineArtifactValidation.validate_optional_timeline_feedback_report/3,
      validate_optional_timeline_diff_report:
        &TimelineArtifactValidation.validate_optional_timeline_diff_report/3,
      validate_optional_timeline_diff_summary:
        &TimelineArtifactValidation.validate_optional_timeline_diff_summary/3,
      validate_optional_timeline_integrity_report:
        &TimelineSourceValidation.validate_optional_timeline_integrity_report/3,
      validate_optional_timeline_dependency_impact_summary:
        &TimelineArtifactValidation.validate_optional_timeline_dependency_impact_summary/3,
      validate_optional_timeline_lifecycle_state_summary:
        &TimelineArtifactValidation.validate_optional_timeline_lifecycle_state_summary/3,
      validate_optional_timeline_activity_precondition_summaries:
        &TimelineSourceValidation.validate_optional_timeline_activity_precondition_summaries/3,
      validate_optional_timeline_activity_lifecycle_states:
        &TimelineSourceValidation.validate_optional_timeline_activity_lifecycle_states/3,
      validate_optional_timeline_preservation_report:
        &TimelineSourceValidation.validate_optional_timeline_preservation_report/3,
      validate_optional_source_operational_timeline_report:
        &OperationalTimelineValidation.validate_optional_report_at_path/3,
      validate_optional_operational_timeline_report:
        &OperationalTimelineValidation.validate_optional_report/2,
      validate_optional_timeline_transition_application_report:
        &TimelineTransitionValidation.validate_optional_timeline_transition_application_report/3,
      validate_optional_timeline_transition_application_summary_source:
        &TimelineTransitionValidation.validate_optional_timeline_transition_application_summary_source/3,
      validate_optional_source_command_window_report:
        &CommandWindowValidation.validate_optional_report_at_path/3,
      validate_optional_source_maneuver_review_report:
        &DecisionSupportValidation.validate_optional_maneuver_review_artifact/3,
      validate_optional_command_window_report:
        &CommandWindowValidation.validate_optional_report/2,
      validate_optional_operator_review_package:
        &OperatorReviewValidation.validate_optional_package/2,
      validate_optional_cadence_import_manifest:
        &CadenceImportValidation.validate_optional_manifest/2,
      validate_optional_operational_readiness_report:
        &OperationalReadinessValidation.validate_optional_operational_readiness_report/3,
      validate_optional_operational_import_eligibility_summary:
        &OperationalReadinessValidation.validate_optional_operational_import_eligibility_summary/3,
      validate_optional_operational_readiness_gate_summary:
        &OperationalReadinessValidation.validate_optional_operational_readiness_gate_summary/3,
      validate_optional_operational_execution_boundary_summary:
        &OperationalReadinessValidation.validate_optional_operational_execution_boundary_summary/3,
      validate_optional_operational_quality_gate_summary:
        &OperationalReadinessValidation.validate_optional_operational_quality_gate_summary/3,
      validate_optional_operational_quality_gate_unavailable_resource_summary:
        &OperationalReadinessValidation.validate_optional_operational_quality_gate_unavailable_resource_summary/3,
      validate_optional_operational_quality_gate_operator_training_summary:
        &OperationalReadinessValidation.validate_optional_operational_quality_gate_operator_training_summary/3,
      validate_optional_operational_quality_gate_schema_validation_summary:
        &OperationalReadinessValidation.validate_optional_operational_quality_gate_schema_validation_summary/3,
      validate_optional_operational_quality_gate_import_readiness_summary:
        &OperationalReadinessValidation.validate_optional_operational_quality_gate_import_readiness_summary/3,
      validate_optional_quality_gate_report:
        &OperationalReadinessValidation.validate_optional_quality_gate_report/3,
      validate_optional_schema_validation_report:
        &SchemaOperationsValidation.validate_optional_schema_validation_report/3,
      validate_optional_schema_validation_batch_report:
        &SchemaOperationsValidation.validate_optional_schema_validation_batch_report/3,
      validate_optional_model_acceptance_report:
        &ValidationArtifactValidation.validate_optional_model_acceptance_report/3,
      validate_optional_safety_case_summary:
        &ValidationArtifactValidation.validate_optional_safety_case_summary/3,
      validate_optional_provider_counteroffer_report:
        &ProviderCounterofferValidation.validate_optional_report/3,
      validate_optional_provider_counteroffer_review_summary:
        &ProviderCounterofferValidation.validate_optional_review_summary/3,
      validate_optional_provider_counteroffer_plan_impact_summary:
        &ProviderCounterofferValidation.validate_optional_plan_impact_summary/3,
      validate_optional_provider_counteroffer_import_readiness_summary:
        &ProviderCounterofferValidation.validate_optional_import_readiness_summary/3,
      validate_optional_objective_tradeoff_report:
        &DecisionSupportValidation.validate_optional_objective_tradeoff_report/2,
      validate_optional_source_objective_tradeoff_report:
        &DecisionSupportValidation.validate_optional_objective_tradeoff_report_at/3,
      validate_optional_constraint_report:
        &DecisionSupportValidation.validate_optional_constraint_report/2,
      validate_optional_source_constraint_report:
        &DecisionSupportValidation.validate_optional_constraint_report_at/3,
      validate_optional_source_objective_satisfaction_report:
        &DecisionSupportValidation.validate_optional_objective_satisfaction_report_at/3,
      validate_optional_contact_allocation_report:
        &ContactAllocationValidation.validate_optional_report/2,
      validate_optional_score_term_report:
        &DecisionSupportValidation.validate_optional_score_term_report/2,
      validate_optional_source_score_term_report:
        &DecisionSupportValidation.validate_optional_score_term_report_at/3,
      validate_optional_link_capacity_report: &LinkCapacityValidation.validate_optional_report/2,
      validate_optional_source_link_capacity_report:
        &LinkCapacityValidation.validate_optional_report_at/3,
      validate_optional_source_link_capacity_summary:
        &LinkCapacityValidation.validate_optional_summary_at/3,
      validate_optional_source_relay_data_path_summary:
        &LinkCapacityValidation.validate_optional_relay_data_path_summary_at/3,
      validate_optional_candidate_diff_report:
        &OrbitalDynamics.Schema.CandidateDiffContracts.validate_optional_report/3,
      validate_optional_candidate_rejection_report:
        &CandidateRejectionValidation.validate_optional_report/3,
      validate_optional_freshness_report:
        &OrbitalDynamics.Schema.FreshnessReportContracts.validate_optional/3,
      validate_optional_refresh_budget_report: &RefreshBudgetReportContracts.validate_optional/3,
      validate_optional_source_contact_allocation_report:
        &ContactAllocationValidation.validate_optional_report_at/3,
      validate_optional_source_contact_allocation_summary:
        &ContactAllocationValidation.validate_optional_summary/3,
      validate_optional_source_contact_allocation_station_pressure_summary:
        &ContactAllocationValidation.validate_optional_station_pressure_summary/3,
      validate_optional_source_contact_allocation_reservation_conflict_summary:
        &ContactAllocationValidation.validate_optional_reservation_conflict_summary/3,
      validate_optional_source_contact_allocation_capacity_pack_summary:
        &ContactAllocationValidation.validate_optional_capacity_pack_summary/3,
      validate_optional_source_contact_allocation_provider_reservation_request_summary:
        &ContactAllocationValidation.validate_optional_provider_reservation_request_summary/3,
      validate_optional_source_contact_contention_report:
        &ContactReportValidation.validate_optional_contention_report/3,
      validate_optional_source_contact_contention_resolution_report:
        &ContactReportValidation.validate_optional_contention_resolution_report/3,
      validate_optional_source_contact_contention_resolution_summary:
        &ContactReportValidation.validate_optional_contention_resolution_summary/3,
      validate_optional_source_station_reservation_report:
        &StationReservationValidation.validate_optional_report/3,
      validate_optional_source_station_reservation_review_summary:
        &StationReservationValidation.validate_optional_review_summary/3,
      validate_optional_source_station_reservation_hold_import_readiness_summary:
        &StationReservationValidation.validate_optional_hold_import_readiness_summary/3,
      validate_optional_source_station_reservation_hold_summary:
        &StationReservationValidation.validate_optional_hold_summary/3,
      validate_optional_source_station_calendar_precedence_summary:
        &StationReservationValidation.validate_optional_calendar_precedence_summary/3,
      validate_optional_source_station_calendar_provider:
        &StationReservationValidation.validate_optional_calendar_provider/3,
      validate_optional_station_calendar_report:
        &StationReservationValidation.validate_optional_calendar_report/3,
      validate_plan_delta: &OrbitalDynamics.Schema.PlanDeltaContracts.validate/3,
      validate_approval_requirement: &PolicyValidation.validate_approval_requirement/3,
      validate_policy_decision: &PolicyValidation.validate_decision/3,
      require_nested: &OrbitalDynamics.Schema.PrimitiveValidation.require_nested/4,
      validate_optional_timeline_protection_summary:
        &TimelineContextValidation.validate_optional_timeline_protection_summary/4,
      expect_field_equals_with_message:
        &OrbitalDynamics.Schema.PrimitiveValidation.expect_field_equals/6
    ]
  end

  defp required_fields(contract_name) do
    required_fields(CampaignRegistryContracts, contract_name)
  end

  defp required_fields(registry_module, contract_name) do
    registry_module.contracts()
    |> OrbitalDynamics.Schema.Registry.fetch!(contract_name)
    |> Map.fetch!("required_fields")
  end
end
