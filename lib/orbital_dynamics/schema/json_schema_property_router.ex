defmodule OrbitalDynamics.Schema.JsonSchemaPropertyRouter do
  @moduledoc false
  alias OrbitalDynamics.Schema.{
    CampaignArtifactPropertyRouter,
    CandidateRefreshReportJsonSchema,
    CandidateRefreshPropertyRouter,
    ContactPlanningPropertyRouter,
    ExecutionArtifactPropertyRouter,
    FilterResourcePropertyRouter,
    ReferencePolicyPropertyRouter,
    ResultArtifactPropertyRouter,
    StrategyPlanningPropertyRouter,
    TimelineReportPropertyRouter,
    ValidationPropertyRouter
  }

  import OrbitalDynamics.Schema.JsonSchemaPropertySupport,
    only: [context_value: 2, fallback: 4, provider: 3]

  def property(field, "timeline_revision.v1", _contract, _context) do
    OrbitalDynamics.Schema.TimelineRevisionContracts.json_schema()
    |> Map.fetch!("properties")
    |> Map.fetch!(field)
  end

  def property(field, "authority_context.v1", _contract, _context) do
    OrbitalDynamics.Schema.AuthorityContextContracts.property(field)
  end

  def property("authority_context", _contract_name, _contract, _context) do
    OrbitalDynamics.Schema.AuthorityContextContracts.json_schema()
  end

  def property("authority_context_evaluation", _contract_name, _contract, _context) do
    OrbitalDynamics.Schema.AuthorityContextContracts.evaluation_json_schema()
  end

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

  def property(field, "campaign_plan_search_trace.v1", _contract, context) do
    OrbitalDynamics.Schema.CampaignPlanSearchTraceJsonSchema.property_from_context(field, context)
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
    ExecutionArtifactPropertyRouter.property(field, contract_name, contract, context)
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

  def property(field, "resource_state_trace.v1", _contract, context) do
    OrbitalDynamics.Schema.ResourceStateTraceJsonSchema.property(field,
      stable_id_pattern: context_value(context, :stable_id_pattern)
    )
  end

  def property(field, "downlink_link_budget.v1", _contract, context) do
    OrbitalDynamics.Schema.DownlinkLinkBudgetJsonSchema.property(field,
      stable_id_pattern: context_value(context, :stable_id_pattern)
    )
  end

  def property(field, "contact_intent.v1" = contract_name, contract, context) do
    ContactPlanningPropertyRouter.property(field, contract_name, contract, context)
  end

  def property(field, "contact_intent_summary.v1" = contract_name, contract, context) do
    ContactPlanningPropertyRouter.property(field, contract_name, contract, context)
  end

  def property(field, "approval_requirement.v1" = contract_name, contract, context) do
    ReferencePolicyPropertyRouter.property(field, contract_name, contract, context)
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
    ExecutionArtifactPropertyRouter.property(field, "realized_activity.v1", contract, context)
  end

  def property(field, "maneuver_recommendation.v1" = contract_name, contract, context) do
    ExecutionArtifactPropertyRouter.property(field, contract_name, contract, context)
  end

  def property(field, contract_name, contract, context)
      when contract_name in [
             "provider_counteroffer_report.v1",
             "provider_counteroffer_review_summary.v1",
             "provider_counteroffer_import_readiness_summary.v1",
             "provider_counteroffer_plan_impact_summary.v1"
           ] do
    OrbitalDynamics.Schema.GroundNetworkPropertyRouter.property(
      field,
      contract_name,
      contract,
      context
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

  def property(field, "local_search_optimization_certificate.v1", _contract, context) do
    OrbitalDynamics.Schema.LocalSearchOptimizationCertificateJsonSchema.property(
      field,
      context_value(context, :stable_id_pattern)
    )
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
    StrategyPlanningPropertyRouter.property(field, contract_name, contract, context)
  end

  def property(field, "branch_comparison_report.v1" = contract_name, contract, context) do
    StrategyPlanningPropertyRouter.property(field, contract_name, contract, context)
  end

  def property(field, "campaign_strategy.v3" = contract_name, contract, context) do
    StrategyPlanningPropertyRouter.property(
      field,
      contract_name,
      contract,
      context,
      fn embedded_contract_name -> embedded(embedded_contract_name, context) end
    )
  end

  def property(field, "planned_activity.v1", contract, context) do
    StrategyPlanningPropertyRouter.property(field, "planned_activity.v1", contract, context)
  end

  def property(field, "plan_delta.v1", contract, context) do
    StrategyPlanningPropertyRouter.property(field, "plan_delta.v1", contract, context)
  end

  def property("lighting_confidence", _name, _contract, _context) do
    OrbitalDynamics.Schema.CommonJsonSchema.number_or_string()
  end

  def property(field, "proposed_contact.v1" = contract_name, contract, context) do
    ContactPlanningPropertyRouter.property(field, contract_name, contract, context)
  end

  def property(field, "candidate_refresh.v1" = contract_name, contract, context) do
    CandidateRefreshPropertyRouter.property(
      field,
      contract_name,
      contract,
      context,
      fn embedded_contract_name -> embedded(embedded_contract_name, context) end
    )
  end

  def property(field, "candidate_refresh_execution.v1", _contract, context) do
    context
    |> context_value(:stable_id_pattern)
    |> CandidateRefreshReportJsonSchema.candidate_refresh_execution_schema()
    |> Map.fetch!("properties")
    |> Map.fetch!(field)
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
