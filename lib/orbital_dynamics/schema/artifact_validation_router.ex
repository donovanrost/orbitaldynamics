defmodule OrbitalDynamics.Schema.ArtifactValidationRouter do
  @moduledoc false

  alias OrbitalDynamics.Schema.{
    ActivityArtifactValidation,
    CadenceImportValidation,
    CampaignArtifactValidation,
    CapabilityCatalogValidation,
    CandidateRefreshExecutionContracts,
    CandidateRejectionValidation,
    CommandWindowValidation,
    ContactAllocationValidation,
    ContactIntentValidation,
    ContactReportValidation,
    DecisionSupportValidation,
    ExecutionReproducibilityValidation,
    LinkCapacityValidation,
    ModelCapabilityValidation,
    OperationalReadinessValidation,
    OperatorReviewValidation,
    PolicyValidation,
    ProviderCounterofferValidation,
    RealizedStateValidation,
    ResourceValidation,
    ResultArtifactValidation,
    SchemaOperationsValidation,
    StateRefreshArtifactValidation,
    StationReservationValidation,
    StudyResultValidation,
    TimelineArtifactValidation,
    ValidationArtifactValidation,
    ValidationPolicyValidation
  }

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [require_fields: 4]

  def validate("activity_template.v1", _contract, artifact) do
    ActivityArtifactValidation.validate_template([], "$", artifact)
  end

  def validate("planned_activity.v1", _contract, artifact) do
    ActivityArtifactValidation.validate_planned([], "$", artifact)
  end

  def validate("proposed_contact.v1", _contract, artifact) do
    CampaignArtifactValidation.validate_proposed_contact_artifact([], "$", artifact)
  end

  def validate("contact_intent.v1", _contract, artifact) do
    ContactIntentValidation.validate_intent([], "$", artifact)
  end

  def validate("contact_intent_summary.v1", _contract, artifact) do
    ContactIntentValidation.validate_summary([], "$", artifact)
  end

  def validate("candidate_activity.v1", _contract, artifact) do
    StateRefreshArtifactValidation.validate([], "$", artifact, "candidate_activity.v1")
  end

  def validate("candidate_diff_report.v1", _contract, artifact) do
    OrbitalDynamics.Schema.CandidateDiffContracts.validate_optional_report([], "$", artifact)
  end

  def validate("downlink_link_budget.v1", _contract, artifact) do
    OrbitalDynamics.Schema.DownlinkLinkBudgetContracts.validate([], "$", artifact)
  end

  def validate("link_capacity_report.v1", _contract, artifact) do
    LinkCapacityValidation.validate_report([], "$", artifact)
  end

  def validate("link_capacity_summary.v1", _contract, artifact) do
    LinkCapacityValidation.validate_summary([], "$", artifact)
  end

  def validate("relay_data_path_summary.v1", _contract, artifact) do
    LinkCapacityValidation.validate_relay_data_path_summary([], "$", artifact)
  end

  def validate("contact_contention_report.v1", _contract, artifact) do
    ContactReportValidation.validate_contention_artifact([], "$", artifact)
  end

  def validate("contact_contention_resolution_report.v1", _contract, artifact) do
    ContactReportValidation.validate_contention_resolution_artifact([], "$", artifact)
  end

  def validate("contact_contention_resolution_summary.v1", _contract, artifact) do
    ContactReportValidation.validate_contention_resolution_summary_artifact([], "$", artifact)
  end

  def validate("contact_allocation_report.v1", _contract, artifact) do
    ContactAllocationValidation.validate_report_artifact([], "$", artifact)
  end

  def validate("contact_allocation_summary.v1", _contract, artifact) do
    ContactAllocationValidation.validate_summary_artifact([], "$", artifact)
  end

  def validate("contact_allocation_reservation_conflict_summary.v1", _contract, artifact) do
    ContactAllocationValidation.validate_reservation_conflict_artifact([], "$", artifact)
  end

  def validate("contact_allocation_station_pressure_summary.v1", _contract, artifact) do
    ContactAllocationValidation.validate_station_pressure_artifact([], "$", artifact)
  end

  def validate("contact_allocation_capacity_pack_summary.v1", _contract, artifact) do
    ContactAllocationValidation.validate_capacity_pack_artifact([], "$", artifact)
  end

  def validate(
        "contact_allocation_provider_reservation_request_summary.v1",
        _contract,
        artifact
      ) do
    ContactAllocationValidation.validate_provider_reservation_request_artifact(
      [],
      "$",
      artifact
    )
  end

  def validate("station_calendar_provider.v1", _contract, artifact) do
    StationReservationValidation.validate_calendar_provider_artifact([], "$", artifact)
  end

  def validate("station_calendar_report.v1", _contract, artifact) do
    StationReservationValidation.validate_calendar_report_artifact([], "$", artifact)
  end

  def validate("station_calendar_precedence_summary.v1", _contract, artifact) do
    StationReservationValidation.validate_calendar_precedence_artifact([], "$", artifact)
  end

  def validate("station_reservation_report.v1", _contract, artifact) do
    StationReservationValidation.validate_report_artifact([], "$", artifact)
  end

  def validate("station_reservation_review_summary.v1", _contract, artifact) do
    StationReservationValidation.validate_review_artifact([], "$", artifact)
  end

  def validate("station_reservation_hold_summary.v1", _contract, artifact) do
    StationReservationValidation.validate_hold_artifact([], "$", artifact)
  end

  def validate(
        "station_reservation_hold_import_readiness_summary.v1",
        _contract,
        artifact
      ) do
    StationReservationValidation.validate_hold_import_artifact([], "$", artifact)
  end

  def validate("provider_counteroffer_report.v1", _contract, artifact) do
    ProviderCounterofferValidation.validate_report([], "$", artifact)
  end

  def validate("provider_counteroffer_review_summary.v1", _contract, artifact) do
    ProviderCounterofferValidation.validate_review_summary([], "$", artifact)
  end

  def validate("provider_counteroffer_import_readiness_summary.v1", _contract, artifact) do
    ProviderCounterofferValidation.validate_import_readiness_summary([], "$", artifact)
  end

  def validate("provider_counteroffer_plan_impact_summary.v1", _contract, artifact) do
    ProviderCounterofferValidation.validate_plan_impact_summary([], "$", artifact)
  end

  def validate("resource_summary.v1", _contract, artifact) do
    ResourceValidation.validate_artifact([], "$", artifact, "resource_summary.v1")
  end

  def validate("resource_state_trace.v1", _contract, artifact) do
    OrbitalDynamics.Schema.ResourceStateTraceContracts.validate([], "$", artifact)
  end

  def validate("resource_projection_report.v1", _contract, artifact) do
    ResourceValidation.validate_artifact([], "$", artifact, "resource_projection_report.v1")
  end

  def validate("resource_projection_flow_summary.v1", _contract, artifact) do
    ResourceValidation.validate_artifact([], "$", artifact, "resource_projection_flow_summary.v1")
  end

  def validate("contact_filter_report.v1", _contract, artifact) do
    ContactReportValidation.validate_filter_artifact([], "$", artifact)
  end

  def validate("resource_filter_report.v1", _contract, artifact) do
    ResourceValidation.validate_artifact([], "$", artifact, "resource_filter_report.v1")
  end

  def validate("resource_filter_summary.v1", _contract, artifact) do
    ResourceValidation.validate_artifact([], "$", artifact, "resource_filter_summary.v1")
  end

  def validate("realized_activity.v1", _contract, artifact) do
    RealizedStateValidation.validate_activity([], "$", artifact)
  end

  def validate("realized_state_snapshot.v1", _contract, artifact) do
    RealizedStateValidation.validate_snapshot([], "$", artifact)
  end

  def validate("timeline_feedback_report.v1", _contract, artifact) do
    TimelineArtifactValidation.validate([], "$", artifact, "timeline_feedback_report.v1")
  end

  def validate("candidate_rejection_report.v1", _contract, artifact) do
    CandidateRejectionValidation.validate_report_artifact([], "$", artifact)
  end

  def validate("plan_delta.v1", _contract, artifact) do
    CampaignArtifactValidation.validate_delta_artifact([], "$", artifact)
  end

  def validate("approval_requirement.v1", _contract, artifact) do
    PolicyValidation.validate_artifact([], "$", artifact, "approval_requirement.v1")
  end

  def validate("authority_context.v1", _contract, artifact) do
    PolicyValidation.validate_artifact([], "$", artifact, "authority_context.v1")
  end

  def validate("policy_decision.v1", _contract, artifact) do
    PolicyValidation.validate_artifact([], "$", artifact, "policy_decision.v1")
  end

  def validate("policy_bundle.v1", _contract, artifact) do
    PolicyValidation.validate_artifact([], "$", artifact, "policy_bundle.v1")
  end

  def validate("operator_review_package.v1", _contract, artifact) do
    []
    |> OperatorReviewValidation.validate_package("$", artifact)
  end

  def validate("cadence_import_manifest.v1", _contract, artifact) do
    CadenceImportValidation.validate_manifest_artifact([], "$", artifact)
  end

  def validate("operational_readiness_report.v1", _contract, artifact) do
    OperationalReadinessValidation.validate_artifact(
      [],
      "$",
      artifact,
      "operational_readiness_report.v1"
    )
  end

  def validate("operational_import_eligibility_summary.v1", _contract, artifact) do
    OperationalReadinessValidation.validate_artifact(
      [],
      "$",
      artifact,
      "operational_import_eligibility_summary.v1"
    )
  end

  def validate("operational_readiness_gate_summary.v1", _contract, artifact) do
    OperationalReadinessValidation.validate_artifact(
      [],
      "$",
      artifact,
      "operational_readiness_gate_summary.v1"
    )
  end

  def validate("operational_execution_boundary_summary.v1", _contract, artifact) do
    OperationalReadinessValidation.validate_artifact(
      [],
      "$",
      artifact,
      "operational_execution_boundary_summary.v1"
    )
  end

  def validate("operational_quality_gate_summary.v1", _contract, artifact) do
    OperationalReadinessValidation.validate_artifact(
      [],
      "$",
      artifact,
      "operational_quality_gate_summary.v1"
    )
  end

  def validate(
        "operational_quality_gate_unavailable_resource_summary.v1",
        _contract,
        artifact
      ) do
    OperationalReadinessValidation.validate_artifact(
      [],
      "$",
      artifact,
      "operational_quality_gate_unavailable_resource_summary.v1"
    )
  end

  def validate(
        "operational_quality_gate_operator_training_summary.v1",
        _contract,
        artifact
      ) do
    OperationalReadinessValidation.validate_artifact(
      [],
      "$",
      artifact,
      "operational_quality_gate_operator_training_summary.v1"
    )
  end

  def validate(
        "operational_quality_gate_schema_validation_summary.v1",
        _contract,
        artifact
      ) do
    OperationalReadinessValidation.validate_artifact(
      [],
      "$",
      artifact,
      "operational_quality_gate_schema_validation_summary.v1"
    )
  end

  def validate(
        "operational_quality_gate_import_readiness_summary.v1",
        _contract,
        artifact
      ) do
    OperationalReadinessValidation.validate_artifact(
      [],
      "$",
      artifact,
      "operational_quality_gate_import_readiness_summary.v1"
    )
  end

  def validate("quality_gate_report.v1", _contract, artifact) do
    OperationalReadinessValidation.validate_artifact(
      [],
      "$",
      artifact,
      "quality_gate_report.v1"
    )
  end

  def validate("environment_model_capability.v1", _contract, artifact) do
    ModelCapabilityValidation.validate([], "$", artifact, "environment_model_capability.v1")
  end

  def validate("environment_provider_capability.v1", _contract, artifact) do
    ModelCapabilityValidation.validate([], "$", artifact, "environment_provider_capability.v1")
  end

  def validate("subsystem_model_capability.v1", _contract, artifact) do
    ModelCapabilityValidation.validate([], "$", artifact, "subsystem_model_capability.v1")
  end

  def validate("schema_validation_report.v1", _contract, artifact) do
    SchemaOperationsValidation.validate([], "$", artifact, "schema_validation_report.v1")
  end

  def validate("schema_validation_batch_report.v1", _contract, artifact) do
    SchemaOperationsValidation.validate([], "$", artifact, "schema_validation_batch_report.v1")
  end

  def validate("schema_migration_report.v1", _contract, artifact) do
    SchemaOperationsValidation.validate([], "$", artifact, "schema_migration_report.v1")
  end

  def validate("campaign_request_lint.v1", _contract, artifact) do
    SchemaOperationsValidation.validate([], "$", artifact, "campaign_request_lint.v1")
  end

  def validate("study_manifest_lint.v1", _contract, artifact) do
    SchemaOperationsValidation.validate([], "$", artifact, "study_manifest_lint.v1")
  end

  def validate("strategy_branch.v1", _contract, artifact) do
    CampaignArtifactValidation.validate_branch_artifact([], "$", artifact)
  end

  def validate("study_benchmark.v1", _contract, artifact) do
    StudyResultValidation.validate([], "$", artifact, "study_benchmark.v1")
  end

  def validate("manifest_field_reference.v1", _contract, artifact) do
    StudyResultValidation.validate([], "$", artifact, "manifest_field_reference.v1")
  end

  def validate("validation_tolerance_policy.v1", _contract, artifact) do
    ValidationPolicyValidation.validate([], "$", artifact, "validation_tolerance_policy.v1")
  end

  def validate("backend_acceptance_policy.v1", _contract, artifact) do
    ValidationPolicyValidation.validate([], "$", artifact, "backend_acceptance_policy.v1")
  end

  def validate("capability_catalog.v1", _contract, artifact) do
    CapabilityCatalogValidation.validate([], "$", artifact)
  end

  def validate("result_artifact.v1", _contract, artifact) do
    ResultArtifactValidation.validate([], "$", artifact)
  end

  def validate("strategy_recommendation.v1", _contract, artifact) do
    CampaignArtifactValidation.validate_recommendation_artifact([], "$", artifact)
  end

  def validate("maneuver_recommendation.v1", _contract, artifact) do
    DecisionSupportValidation.validate_maneuver_recommendation_artifact([], "$", artifact)
  end

  def validate("maneuver_review_report.v1", _contract, artifact) do
    DecisionSupportValidation.validate_maneuver_review_artifact([], "$", artifact)
  end

  def validate("execution_report.v1", _contract, artifact) do
    ExecutionReproducibilityValidation.validate([], "$", artifact, "execution_report.v1")
  end

  def validate("monte_carlo_reproducibility_report.v1", _contract, artifact) do
    ExecutionReproducibilityValidation.validate(
      [],
      "$",
      artifact,
      "monte_carlo_reproducibility_report.v1"
    )
  end

  def validate("objective_tradeoff_report.v1", _contract, artifact) do
    DecisionSupportValidation.validate_objective_tradeoff_report([], "$", artifact)
  end

  def validate("objective_satisfaction_report.v1", _contract, artifact) do
    DecisionSupportValidation.validate_objective_satisfaction_report([], "$", artifact)
  end

  def validate("ranking_comparison_report.v1", _contract, artifact) do
    DecisionSupportValidation.validate_ranking_comparison_report([], "$", artifact)
  end

  def validate("pareto_frontier_report.v1", _contract, artifact) do
    DecisionSupportValidation.validate_pareto_frontier_report([], "$", artifact)
  end

  def validate("local_search_optimization_certificate.v1", _contract, artifact) do
    OrbitalDynamics.Schema.LocalSearchOptimizationCertificateContracts.validate([], "$", artifact)
  end

  def validate("operational_timeline_report.v1", _contract, artifact) do
    TimelineArtifactValidation.validate([], "$", artifact, "operational_timeline_report.v1")
  end

  def validate("timeline_diff_report.v1", _contract, artifact) do
    TimelineArtifactValidation.validate([], "$", artifact, "timeline_diff_report.v1")
  end

  def validate("timeline_diff_summary.v1", _contract, artifact) do
    TimelineArtifactValidation.validate([], "$", artifact, "timeline_diff_summary.v1")
  end

  def validate("timeline_integrity_report.v1", _contract, artifact) do
    TimelineArtifactValidation.validate([], "$", artifact, "timeline_integrity_report.v1")
  end

  def validate("timeline_dependency_impact_summary.v1", _contract, artifact) do
    TimelineArtifactValidation.validate(
      [],
      "$",
      artifact,
      "timeline_dependency_impact_summary.v1"
    )
  end

  def validate("timeline_publication_summary.v1", _contract, artifact) do
    TimelineArtifactValidation.validate([], "$", artifact, "timeline_publication_summary.v1")
  end

  def validate("timeline_activity_state.v1", _contract, artifact) do
    TimelineArtifactValidation.validate([], "$", artifact, "timeline_activity_state.v1")
  end

  def validate("timeline_activity_precondition_summary.v1", _contract, artifact) do
    TimelineArtifactValidation.validate(
      [],
      "$",
      artifact,
      "timeline_activity_precondition_summary.v1"
    )
  end

  def validate("timeline_activity_status_state.v1", _contract, artifact) do
    TimelineArtifactValidation.validate([], "$", artifact, "timeline_activity_status_state.v1")
  end

  def validate("timeline_activity_approval_state.v1", _contract, artifact) do
    TimelineArtifactValidation.validate([], "$", artifact, "timeline_activity_approval_state.v1")
  end

  def validate("timeline_activity_lifecycle_state.v1", _contract, artifact) do
    TimelineArtifactValidation.validate([], "$", artifact, "timeline_activity_lifecycle_state.v1")
  end

  def validate("timeline_preservation_report.v1", _contract, artifact) do
    TimelineArtifactValidation.validate([], "$", artifact, "timeline_preservation_report.v1")
  end

  def validate("timeline_preservation_status.v1", _contract, artifact) do
    TimelineArtifactValidation.validate([], "$", artifact, "timeline_preservation_status.v1")
  end

  def validate("timeline_lifecycle_state_summary.v1", _contract, artifact) do
    TimelineArtifactValidation.validate([], "$", artifact, "timeline_lifecycle_state_summary.v1")
  end

  def validate("timeline_transition_application_report.v1", _contract, artifact) do
    TimelineArtifactValidation.validate(
      [],
      "$",
      artifact,
      "timeline_transition_application_report.v1"
    )
  end

  def validate("timeline_revision.v1", _contract, artifact) do
    OrbitalDynamics.Schema.TimelineRevisionContracts.validate([], "$", artifact)
  end

  def validate("timeline_transition_application_summary.v1", _contract, artifact) do
    TimelineArtifactValidation.validate(
      [],
      "$",
      artifact,
      "timeline_transition_application_summary.v1"
    )
  end

  def validate("command_window_report.v1", _contract, artifact) do
    CommandWindowValidation.validate_report([], "$", artifact)
  end

  def validate("branch_comparison_report.v1", _contract, artifact) do
    DecisionSupportValidation.validate_branch_comparison_report([], "$", artifact)
  end

  def validate("optimizer_contract.v1", _contract, artifact) do
    DecisionSupportValidation.validate_optimizer_contract([], "$", artifact)
  end

  def validate("constraint_report.v1", _contract, artifact) do
    DecisionSupportValidation.validate_constraint_report([], "$", artifact)
  end

  def validate("score_term_report.v1", _contract, artifact) do
    DecisionSupportValidation.validate_score_term_report([], "$", artifact)
  end

  def validate("accepted_planning_state.v1", _contract, artifact) do
    StateRefreshArtifactValidation.validate([], "$", artifact, "accepted_planning_state.v1")
  end

  def validate("spacecraft_state_estimate.v1", _contract, artifact) do
    StateRefreshArtifactValidation.validate([], "$", artifact, "spacecraft_state_estimate.v1")
  end

  def validate("maneuver_execution_delta.v1", _contract, artifact) do
    StateRefreshArtifactValidation.validate([], "$", artifact, "maneuver_execution_delta.v1")
  end

  def validate("candidate_refresh.v1", _contract, artifact) do
    StateRefreshArtifactValidation.validate([], "$", artifact, "candidate_refresh.v1")
  end

  def validate("candidate_refresh_execution.v1", _contract, artifact) do
    CandidateRefreshExecutionContracts.validate_standalone([], artifact)
  end

  def validate("candidate_diff_row.v1", _contract, artifact) do
    StateRefreshArtifactValidation.validate([], "$", artifact, "candidate_diff_row.v1")
  end

  def validate("freshness_report.v1", _contract, artifact) do
    StateRefreshArtifactValidation.validate([], "$", artifact, "freshness_report.v1")
  end

  def validate("invalidated_candidate.v1", _contract, artifact) do
    StateRefreshArtifactValidation.validate([], "$", artifact, "invalidated_candidate.v1")
  end

  def validate("refresh_budget_report.v1", _contract, artifact) do
    StateRefreshArtifactValidation.validate([], "$", artifact, "refresh_budget_report.v1")
  end

  def validate("refreshed_window.v1", _contract, artifact) do
    StateRefreshArtifactValidation.validate([], "$", artifact, "refreshed_window.v1")
  end

  def validate("remaining_horizon.v1", _contract, artifact) do
    StateRefreshArtifactValidation.validate([], "$", artifact, "remaining_horizon.v1")
  end

  def validate("source_window_lineage.v1", _contract, artifact) do
    StateRefreshArtifactValidation.validate([], "$", artifact, "source_window_lineage.v1")
  end

  def validate("validation_reference_fixture_report.v1", _contract, artifact) do
    ValidationArtifactValidation.validate(
      [],
      "$",
      artifact,
      "validation_reference_fixture_report.v1"
    )
  end

  def validate("validation_reference_report.v1", _contract, artifact) do
    ValidationArtifactValidation.validate([], "$", artifact, "validation_reference_report.v1")
  end

  def validate("validation_check.v1", _contract, artifact) do
    ValidationArtifactValidation.validate([], "$", artifact, "validation_check.v1")
  end

  def validate("validation_record.v1", _contract, artifact) do
    ValidationArtifactValidation.validate([], "$", artifact, "validation_record.v1")
  end

  def validate("model_acceptance_report.v1", _contract, artifact) do
    ValidationArtifactValidation.validate([], "$", artifact, "model_acceptance_report.v1")
  end

  def validate("validation_safety_case_summary.v1", _contract, artifact) do
    ValidationArtifactValidation.validate(
      [],
      "$",
      artifact,
      "validation_safety_case_summary.v1"
    )
  end

  def validate("campaign_plan.v1", _contract, artifact) do
    CampaignArtifactValidation.validate_plan([], artifact)
  end

  def validate("campaign_plan_search_trace.v1", contract, artifact) do
    OrbitalDynamics.Schema.CampaignPlanSearchContracts.validate_trace(
      [],
      "$",
      artifact,
      contract["required_fields"]
    )
  end

  def validate("campaign_repair.v2", _contract, artifact) do
    CampaignArtifactValidation.validate_repair([], artifact)
  end

  def validate("campaign_strategy.v3", _contract, artifact) do
    CampaignArtifactValidation.validate_strategy([], artifact)
  end

  def validate(_name, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
  end
end
