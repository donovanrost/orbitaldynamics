defmodule OrbitalDynamics.Schema.JsonSchemaPropertyRouter do
  @moduledoc false
  alias OrbitalDynamics.Schema.{
    CampaignArtifactPropertyRouter,
    CandidateRefreshPropertyRouter,
    FilterResourcePropertyRouter,
    ReferencePolicyPropertyRouter,
    ResultArtifactPropertyRouter,
    StrategyPlanningPropertyRouter,
    TimelineReportPropertyRouter,
    ValidationPropertyRouter
  }

  import OrbitalDynamics.Schema.JsonSchemaPropertySupport,
    only: [context_value: 2, fallback: 4, provider: 3]

  def property(field, "activity_template.v1" = contract_name, contract, context) do
    ReferencePolicyPropertyRouter.property(field, contract_name, contract, context)
  end

  def property(field, "policy_bundle.v1" = contract_name, contract, context) do
    ReferencePolicyPropertyRouter.property(field, contract_name, contract, context)
  end

  def property(field, "policy_decision.v1" = contract_name, contract, context) do
    ReferencePolicyPropertyRouter.property(field, contract_name, contract, context)
  end

  def property(field, "capability_catalog.v1" = contract_name, contract, context) do
    ReferencePolicyPropertyRouter.property(field, contract_name, contract, context)
  end

  def property(field, "accepted_planning_state.v1" = contract_name, contract, context) do
    ReferencePolicyPropertyRouter.property(field, contract_name, contract, context)
  end

  def property(field, "manifest_field_reference.v1" = contract_name, contract, context) do
    ReferencePolicyPropertyRouter.property(field, contract_name, contract, context)
  end

  def property(field, "candidate_diff_report.v1" = contract_name, contract, context) do
    CandidateRefreshPropertyRouter.property(field, contract_name, contract, context)
  end

  def property(field, contract_name, contract, context)
      when contract_name in [
             "candidate_diff_row.v1",
             "invalidated_candidate.v1",
             "source_window_lineage.v1"
           ] do
    CandidateRefreshPropertyRouter.property(field, contract_name, contract, context)
  end

  def property(field, contract_name, contract, context)
      when contract_name in [
             "freshness_report.v1",
             "refresh_budget_report.v1",
             "refreshed_window.v1",
             "remaining_horizon.v1"
           ] do
    CandidateRefreshPropertyRouter.property(field, contract_name, contract, context)
  end

  def property(field, "campaign_plan.v1" = contract_name, contract, context) do
    CampaignArtifactPropertyRouter.property(
      field,
      contract_name,
      contract,
      context,
      fn property_field, property_contract_name, property_contract ->
        property(property_field, property_contract_name, property_contract, context)
      end
    )
  end

  def property(field, "campaign_repair.v2" = contract_name, contract, context) do
    CampaignArtifactPropertyRouter.property(
      field,
      contract_name,
      contract,
      context,
      fn property_field, property_contract_name, property_contract ->
        property(property_field, property_contract_name, property_contract, context)
      end
    )
  end

  def property(field, "realized_state_snapshot.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.ManeuverArtifactPropertyDispatch.realized_state_snapshot(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {fn -> provider(context, :realized_activity_json_schema, []) end,
       fn -> provider(context, :realized_spacecraft_state_json_schema, []) end,
       fn -> provider(context, :realized_state_snapshot_metadata_json_schema, []) end,
       &OrbitalDynamics.CampaignPlanner.realized_state_snapshot_model_limits/0}
    )
  end

  def property(field, "timeline_feedback_report.v1" = contract_name, contract, context) do
    TimelineReportPropertyRouter.property(field, contract_name, contract, context)
  end

  def property(field, "timeline_integrity_report.v1" = contract_name, contract, context) do
    TimelineReportPropertyRouter.property(field, contract_name, contract, context)
  end

  def property(
        field,
        "timeline_dependency_impact_summary.v1" = contract_name,
        contract,
        context
      ) do
    TimelineReportPropertyRouter.property(field, contract_name, contract, context)
  end

  def property(field, "timeline_publication_summary.v1" = contract_name, contract, context) do
    TimelineReportPropertyRouter.property(field, contract_name, contract, context)
  end

  def property(field, "timeline_activity_state.v1" = contract_name, contract, context) do
    TimelineReportPropertyRouter.property(field, contract_name, contract, context)
  end

  def property(
        field,
        "timeline_activity_precondition_summary.v1" = contract_name,
        contract,
        context
      ) do
    TimelineReportPropertyRouter.property(field, contract_name, contract, context)
  end

  def property(field, "execution_report.v1" = contract_name, contract, context) do
    ResultArtifactPropertyRouter.property(
      field,
      contract_name,
      contract,
      context,
      fn embedded_contract_name -> embedded(embedded_contract_name, context) end
    )
  end

  def property(field, "result_artifact.v1" = contract_name, contract, context) do
    ResultArtifactPropertyRouter.property(
      field,
      contract_name,
      contract,
      context,
      fn embedded_contract_name -> embedded(embedded_contract_name, context) end
    )
  end

  def property(field, "resource_summary.v1" = contract_name, contract, context) do
    ResultArtifactPropertyRouter.property(
      field,
      contract_name,
      contract,
      context,
      fn embedded_contract_name -> embedded(embedded_contract_name, context) end
    )
  end

  def property(field, "contact_intent.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.ContactPlanningPropertyDispatch.intent(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {fn -> provider(context, :approval_requirement_json_schema, []) end,
       fn -> provider(context, :policy_decision_rule_match_json_schema, []) end,
       fn -> provider(context, :policy_decision_json_schema, []) end,
       fn -> provider(context, :contact_intent_model_limits, []) end,
       fn -> provider(context, :timeline_integrity_issue_types, []) end}
    )
  end

  def property(field, "contact_intent_summary.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.ContactPlanningPropertyDispatch.summary(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {"contact_intent_summary.v1", context_value(context, :stable_id_pattern),
       fn -> provider(context, :contact_intent_model_limits, []) end,
       fn -> provider(context, :contact_intent_summary_assumptions_json_schema, []) end}
    )
  end

  def property(field, "approval_requirement.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.PolicyArtifactPropertyDispatch.approval_requirement(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {context_value(context, :stable_id_pattern),
       fn -> provider(context, :policy_decision_rule_match_json_schema, []) end,
       fn -> provider(context, :activity_context_json_schema, []) end,
       fn -> provider(context, :policy_escalation_json_schema, []) end}
    )
  end

  def property(
        field,
        contract_name,
        contract,
        context
      )
      when contract_name in [
             "validation_reference_fixture_report.v1",
             "validation_reference_report.v1",
             "validation_record.v1",
             "validation_check.v1"
           ] do
    ValidationPropertyRouter.property(field, contract_name, contract, context)
  end

  def property(field, contract_name, contract, context)
      when contract_name in ["model_acceptance_report.v1", "validation_safety_case_summary.v1"] do
    ValidationPropertyRouter.property(field, contract_name, contract, context)
  end

  def property(field, contract_name, contract, context)
      when contract_name in ["schema_validation_report.v1", "schema_validation_batch_report.v1"] do
    ValidationPropertyRouter.property(field, contract_name, contract, context)
  end

  def property(field, "schema_migration_report.v1" = contract_name, contract, context) do
    ValidationPropertyRouter.property(field, contract_name, contract, context)
  end

  def property(field, contract_name, contract, context)
      when contract_name in ["campaign_request_lint.v1", "study_manifest_lint.v1"] do
    ValidationPropertyRouter.property(field, contract_name, contract, context)
  end

  def property(field, "strategy_branch.v1" = contract_name, contract, context) do
    StrategyPlanningPropertyRouter.property(field, contract_name, contract, context)
  end

  def property(field, "optimizer_contract.v1" = contract_name, contract, context) do
    StrategyPlanningPropertyRouter.property(field, contract_name, contract, context)
  end

  def property(field, contract_name, contract, context)
      when contract_name in [
             "environment_model_capability.v1",
             "environment_provider_capability.v1",
             "subsystem_model_capability.v1"
           ] do
    StrategyPlanningPropertyRouter.property(field, contract_name, contract, context)
  end

  def property(field, "monte_carlo_reproducibility_report.v1" = contract_name, contract, context) do
    StrategyPlanningPropertyRouter.property(field, contract_name, contract, context)
  end

  def property(field, "strategy_recommendation.v1" = contract_name, contract, context) do
    StrategyPlanningPropertyRouter.property(field, contract_name, contract, context)
  end

  def property(field, "realized_activity.v1", contract, context) do
    OrbitalDynamics.Schema.RealizedActivityJsonSchema.dispatch_property(field, contract,
      focused_property:
        OrbitalDynamics.Schema.RealizedActivityJsonSchema.property_fun_from_context(
          stable_id_pattern: context_value(context, :stable_id_pattern),
          numeric_triplet_schema: &OrbitalDynamics.Schema.CommonJsonSchema.numeric_triplet/0,
          ground_station_schema: fn ->
            provider(context, :ground_station_identity_json_schema, [])
          end,
          spacecraft_schema: fn -> provider(context, :spacecraft_identity_json_schema, []) end,
          target_schema: fn -> provider(context, :target_identity_json_schema, []) end
        ),
      execution_uncertainty_schema: fn ->
        provider(context, :execution_uncertainty_json_schema, [])
      end,
      number_or_string_schema: &OrbitalDynamics.Schema.CommonJsonSchema.number_or_string/0,
      default_property: fn field, contract ->
        fallback(field, "realized_activity.v1", contract, context)
      end
    )
  end

  def property(field, "maneuver_recommendation.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.ManeuverArtifactPropertyDispatch.recommendation(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {"maneuver_recommendation.v1", context_value(context, :stable_id_pattern),
       &OrbitalDynamics.Schema.CommonJsonSchema.numeric_triplet/0,
       fn -> provider(context, :maneuver_recommendation_model_limits, []) end}
    )
  end

  def property(field, contract_name, contract, context)
      when contract_name in [
             "provider_counteroffer_report.v1",
             "provider_counteroffer_review_summary.v1",
             "provider_counteroffer_import_readiness_summary.v1",
             "provider_counteroffer_plan_impact_summary.v1"
           ] do
    OrbitalDynamics.Schema.ProviderCounterofferPropertyDispatch.property(
      field,
      contract_name,
      contract,
      contracts: %{
        report: "provider_counteroffer_report.v1",
        review_summary: "provider_counteroffer_review_summary.v1",
        import_readiness_summary: "provider_counteroffer_import_readiness_summary.v1",
        plan_impact_summary: "provider_counteroffer_plan_impact_summary.v1"
      },
      row_schema: fn -> provider(context, :provider_counteroffer_row_json_schema, []) end,
      models: &OrbitalDynamics.Schema.ProviderCounterofferReportJsonSchema.models/0,
      stable_id_pattern: context_value(context, :stable_id_pattern),
      default_property: fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end
    )
  end

  def property(field, "candidate_rejection_report.v1" = contract_name, contract, context) do
    TimelineReportPropertyRouter.property(field, contract_name, contract, context)
  end

  def property(field, contract_name, contract, context)
      when contract_name in [
             "operational_timeline_report.v1",
             "timeline_diff_report.v1",
             "timeline_diff_summary.v1"
           ] do
    TimelineReportPropertyRouter.property(field, contract_name, contract, context)
  end

  def property(field, contract_name, contract, context)
      when contract_name in [
             "timeline_activity_status_state.v1",
             "timeline_activity_approval_state.v1",
             "timeline_activity_lifecycle_state.v1"
           ] do
    TimelineReportPropertyRouter.property(field, contract_name, contract, context)
  end

  def property(field, contract_name, contract, context)
      when contract_name in ["timeline_preservation_report.v1", "timeline_preservation_status.v1"] do
    TimelineReportPropertyRouter.property(field, contract_name, contract, context)
  end

  def property(field, "timeline_lifecycle_state_summary.v1" = contract_name, contract, context) do
    TimelineReportPropertyRouter.property(field, contract_name, contract, context)
  end

  def property(field, contract_name, contract, context)
      when contract_name in [
             "timeline_transition_application_report.v1",
             "timeline_transition_application_summary.v1"
           ] do
    TimelineReportPropertyRouter.property(field, contract_name, contract, context)
  end

  def property(field, "command_window_report.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.GroundNetworkPropertyRouter.property(
      field,
      contract_name,
      contract,
      context
    )
  end

  def property(field, "station_calendar_precedence_summary.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.GroundNetworkPropertyRouter.property(
      field,
      contract_name,
      contract,
      context
    )
  end

  def property(field, "station_reservation_report.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.GroundNetworkPropertyRouter.property(
      field,
      contract_name,
      contract,
      context
    )
  end

  def property(field, "station_calendar_report.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.GroundNetworkPropertyRouter.property(
      field,
      contract_name,
      contract,
      context
    )
  end

  def property(field, contract_name, contract, context)
      when contract_name in [
             "station_reservation_review_summary.v1",
             "station_reservation_hold_summary.v1",
             "station_reservation_hold_import_readiness_summary.v1"
           ] do
    OrbitalDynamics.Schema.GroundNetworkPropertyRouter.property(
      field,
      contract_name,
      contract,
      context
    )
  end

  def property(field, "station_calendar_provider.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.GroundNetworkPropertyRouter.property(
      field,
      contract_name,
      contract,
      context
    )
  end

  def property(field, contract_name, contract, context)
      when contract_name in ["link_capacity_report.v1", "link_capacity_summary.v1"] do
    OrbitalDynamics.Schema.GroundNetworkPropertyRouter.property(
      field,
      contract_name,
      contract,
      context
    )
  end

  def property(field, "relay_data_path_summary.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.GroundNetworkPropertyRouter.property(
      field,
      contract_name,
      contract,
      context
    )
  end

  def property(field, "contact_allocation_report.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.GroundNetworkPropertyRouter.property(
      field,
      contract_name,
      contract,
      context
    )
  end

  def property(field, contract_name, contract, context)
      when contract_name in [
             "contact_allocation_summary.v1",
             "contact_allocation_reservation_conflict_summary.v1",
             "contact_allocation_station_pressure_summary.v1",
             "contact_allocation_capacity_pack_summary.v1",
             "contact_allocation_provider_reservation_request_summary.v1"
           ] do
    OrbitalDynamics.Schema.GroundNetworkPropertyRouter.property(
      field,
      contract_name,
      contract,
      context
    )
  end

  def property(field, contract_name, contract, context)
      when contract_name in ["contact_filter_report.v1", "resource_filter_report.v1"] do
    FilterResourcePropertyRouter.property(field, contract_name, contract, context)
  end

  def property(field, contract_name, contract, context)
      when contract_name in [
             "resource_projection_report.v1",
             "resource_projection_flow_summary.v1"
           ] do
    FilterResourcePropertyRouter.property(field, contract_name, contract, context)
  end

  def property(field, contract_name, contract, context)
      when contract_name in [
             "contact_contention_report.v1",
             "contact_contention_resolution_report.v1",
             "contact_contention_resolution_summary.v1"
           ] do
    FilterResourcePropertyRouter.property(field, contract_name, contract, context)
  end

  def property(field, contract_name, contract, context)
      when contract_name in ["objective_satisfaction_report.v1", "objective_tradeoff_report.v1"] do
    StrategyPlanningPropertyRouter.property(field, contract_name, contract, context)
  end

  def property(field, contract_name, contract, context)
      when contract_name in ["ranking_comparison_report.v1", "pareto_frontier_report.v1"] do
    StrategyPlanningPropertyRouter.property(field, contract_name, contract, context)
  end

  def property(field, "score_term_report.v1" = contract_name, contract, context) do
    StrategyPlanningPropertyRouter.property(field, contract_name, contract, context)
  end

  def property(field, "resource_filter_summary.v1" = contract_name, contract, context) do
    StrategyPlanningPropertyRouter.property(field, contract_name, contract, context)
  end

  def property(field, "constraint_report.v1" = contract_name, contract, context) do
    StrategyPlanningPropertyRouter.property(field, contract_name, contract, context)
  end

  def property(field, contract_name, contract, context)
      when contract_name in [
             "operational_import_eligibility_summary.v1",
             "operational_readiness_gate_summary.v1",
             "operational_execution_boundary_summary.v1"
           ] do
    OrbitalDynamics.Schema.OperationalPropertyRouter.property(
      field,
      contract_name,
      contract,
      context
    )
  end

  def property(field, contract_name, contract, context)
      when contract_name in ["operational_quality_gate_summary.v1", "quality_gate_report.v1"] do
    OrbitalDynamics.Schema.OperationalPropertyRouter.property(
      field,
      contract_name,
      contract,
      context
    )
  end

  def property(field, contract_name, contract, context)
      when contract_name in [
             "operational_quality_gate_unavailable_resource_summary.v1",
             "operational_quality_gate_operator_training_summary.v1",
             "operational_quality_gate_schema_validation_summary.v1",
             "operational_quality_gate_import_readiness_summary.v1"
           ] do
    OrbitalDynamics.Schema.OperationalPropertyRouter.property(
      field,
      contract_name,
      contract,
      context
    )
  end

  def property(field, "operational_readiness_report.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.OperationalPropertyRouter.property(
      field,
      contract_name,
      contract,
      context
    )
  end

  def property(field, "operator_review_package.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.OperationalPropertyRouter.property(
      field,
      contract_name,
      contract,
      context
    )
  end

  def property(field, "cadence_import_manifest.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.OperationalPropertyRouter.property(
      field,
      contract_name,
      contract,
      context
    )
  end

  def property(field, "maneuver_review_report.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.ManeuverArtifactPropertyDispatch.review(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {fn -> provider(context, :maneuver_review_row_json_schema, []) end,
       context_value(context, :stable_id_pattern),
       fn -> provider(context, :maneuver_review_report_model_limits, []) end}
    )
  end

  def property(field, "branch_comparison_report.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.StrategyArtifactPropertyDispatch.branch_comparison(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {fn -> provider(context, :branch_comparison_row_json_schema, []) end,
       &OrbitalDynamics.CampaignPlanner.branch_comparison_model_limits/0}
    )
  end

  def property(field, "campaign_strategy.v3" = contract_name, contract, context) do
    OrbitalDynamics.Schema.StrategyArtifactPropertyDispatch.campaign_strategy(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {fn -> provider(context, :strategy_branch_json_schema, []) end,
       fn -> provider(context, :strategy_recommendation_json_schema, []) end,
       fn -> provider(context, :operational_feedback_json_schema, []) end,
       fn -> provider(context, :policy_action_rule_json_schema, []) end}
    )
  end

  def property(field, "planned_activity.v1", contract, context) do
    OrbitalDynamics.Schema.PlannedActivityJsonSchema.dispatch_property(field, contract,
      focused_property:
        OrbitalDynamics.Schema.PlannedActivityJsonSchema.property_fun_from_context(
          cadence_import_schema:
            provider(context, :cadence_import_json_schema, ["planned_activity.v1"]),
          source_window_schema:
            provider(context, :candidate_activity_source_window_json_schema, []),
          stable_id_pattern: context_value(context, :stable_id_pattern),
          timeline_identity_schema: provider(context, :timeline_identity_json_schema, [])
        ),
      execution_uncertainty_schema: fn ->
        provider(context, :execution_uncertainty_json_schema, [])
      end,
      number_or_string_schema: &OrbitalDynamics.Schema.CommonJsonSchema.number_or_string/0,
      default_property: fn field, contract ->
        fallback(field, "planned_activity.v1", contract, context)
      end
    )
  end

  def property(field, "plan_delta.v1", contract, context) do
    OrbitalDynamics.Schema.PlanDeltaJsonSchema.dispatch_property(field, contract,
      focused_property:
        OrbitalDynamics.Schema.PlanDeltaJsonSchema.property_fun_from_context(
          activity_context_schema: provider(context, :activity_context_json_schema, []),
          planned_activity_schema: provider(context, :planned_activity_json_schema, []),
          realized_activity_schema: provider(context, :realized_activity_json_schema, [])
        ),
      execution_uncertainty_schema: fn ->
        provider(context, :execution_uncertainty_json_schema, [])
      end,
      number_or_string_schema: &OrbitalDynamics.Schema.CommonJsonSchema.number_or_string/0,
      default_property: fn field, contract ->
        fallback(field, "plan_delta.v1", contract, context)
      end
    )
  end

  def property("lighting_confidence", _name, _contract, _context) do
    OrbitalDynamics.Schema.CommonJsonSchema.number_or_string()
  end

  def property(field, "proposed_contact.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.ContactPlanningPropertyDispatch.proposed_contact(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {fn -> provider(context, :cadence_import_json_schema, ["proposed_contact.v1"]) end,
       &OrbitalDynamics.Schema.ProposedContactContracts.model_limits/0,
       fn -> provider(context, :candidate_activity_source_window_json_schema, []) end,
       fn -> provider(context, :timeline_identity_json_schema, []) end}
    )
  end

  def property(field, "candidate_refresh.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.CandidateRefreshPropertyDispatch.candidate_refresh(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {fn -> provider(context, :source_window_lineage_json_schema, []) end,
       fn -> provider(context, :invalidated_candidate_json_schema, []) end,
       fn -> provider(context, :candidate_activity_json_schema, []) end,
       fn -> provider(context, :contact_intent_row_json_schema, []) end,
       fn -> provider(context, :resource_summary_row_json_schema, []) end,
       fn -> provider(context, :validation_record_json_schema, []) end,
       fn -> OrbitalDynamics.CandidateRefresh.model_limits() end,
       context_value(context, :stable_id_pattern),
       fn -> provider(context, :operational_feedback_json_schema, []) end,
       fn -> provider(context, :station_calendar_provider_counteroffer_actions, []) end,
       &OrbitalDynamics.Schema.ValidationAcceptanceReportContracts.safety_case_count_fields/0,
       fn arg1 -> embedded(arg1, context) end}
    )
  end

  def property(field, name, contract, context) do
    fallback(field, name, contract, context)
  end

  defp embedded(contract_name, context) do
    OrbitalDynamics.Schema.EmbeddedContractJsonSchema.build(contract_name,
      contract: fn arg1 -> provider(context, :registry_contract!, [arg1]) end,
      property: fn arg1, arg2, arg3 -> property(arg1, arg2, arg3, context) end
    )
  end
end
