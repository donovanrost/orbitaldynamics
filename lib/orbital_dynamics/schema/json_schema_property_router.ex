defmodule OrbitalDynamics.Schema.JsonSchemaPropertyRouter do
  @moduledoc false
  alias OrbitalDynamics.Schema.{
    CampaignArtifactPropertyRouter,
    CandidateRefreshPropertyRouter,
    OperationalReadinessValidation,
    ReferencePolicyPropertyRouter,
    ResourceValidation,
    TimelineContextJsonSchema
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
    OrbitalDynamics.Schema.TimelineReportPropertyDispatch.feedback(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {fn -> provider(context, :timeline_feedback_row_json_schema, []) end,
       fn -> provider(context, :timeline_feedback_report_model_limits, []) end,
       fn -> provider(context, :timeline_feedback_capabilities, []) end,
       fn -> provider(context, :operational_feedback_json_schema, []) end,
       fn ->
         provider(context, :timeline_feedback_operational_feedback_provenance_json_schema, [])
       end}
    )
  end

  def property(field, "timeline_integrity_report.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.TimelineReportPropertyDispatch.integrity(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      "timeline_integrity_report.v1",
      context_value(context, :stable_id_pattern),
      {fn -> provider(context, :operational_timeline_row_json_schema, []) end,
       fn -> provider(context, :timeline_integrity_issue_types, []) end,
       fn -> provider(context, :stable_id_array_schema, []) end,
       fn -> provider(context, :stable_id_array_map_schema, []) end,
       fn -> provider(context, :timeline_report_model_limits, []) end}
    )
  end

  def property(
        field,
        "timeline_dependency_impact_summary.v1" = contract_name,
        contract,
        context
      ) do
    OrbitalDynamics.Schema.TimelineReportPropertyDispatch.dependency_impact(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      "timeline_dependency_impact_summary.v1",
      {fn -> provider(context, :stable_id_array_schema, []) end,
       fn -> provider(context, :timeline_dependency_impact_row_json_schema, []) end,
       fn -> provider(context, :timeline_report_model_limits, []) end}
    )
  end

  def property(field, "timeline_publication_summary.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.TimelineReportPropertyDispatch.publication(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      "timeline_publication_summary.v1",
      context_value(context, :stable_id_pattern),
      {fn -> provider(context, :timeline_diff_summary_source_json_schema, []) end,
       fn -> provider(context, :timeline_dependency_impact_summary_source_json_schema, []) end,
       fn -> provider(context, :stable_id_array_schema, []) end,
       fn -> provider(context, :stable_id_array_map_schema, []) end,
       fn -> provider(context, :timeline_report_model_limits, []) end}
    )
  end

  def property(field, "timeline_activity_state.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.TimelineActivityStatePropertyDispatch.state(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      "timeline_activity_state.v1",
      context_value(context, :stable_id_pattern),
      {fn -> provider(context, :timeline_feedback_row_json_schema, []) end,
       fn -> provider(context, :timeline_feedback_capabilities, []) end,
       fn -> provider(context, :stable_id_array_schema, []) end,
       &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
       fn -> provider(context, :timeline_identity_json_schema, []) end,
       fn -> provider(context, :activity_context_json_schema, []) end,
       &TimelineContextJsonSchema.lifecycle_transition/0,
       fn -> provider(context, :protection_decision_json_schema, []) end,
       fn ->
         OrbitalDynamics.Schema.CommonJsonSchema.boolean_const_assumptions([
           "artifact_only",
           "no_schedule_mutation",
           "no_command_execution"
         ])
       end, fn -> provider(context, :timeline_feedback_report_model_limits, []) end}
    )
  end

  def property(
        field,
        "timeline_activity_precondition_summary.v1" = contract_name,
        contract,
        context
      ) do
    OrbitalDynamics.Schema.TimelineProtectionPropertyDispatch.precondition(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      "timeline_activity_precondition_summary.v1",
      context_value(context, :stable_id_pattern),
      {fn -> provider(context, :timeline_report_model_limits, []) end,
       fn -> provider(context, :timeline_activity_precondition_statuses, []) end,
       &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
       fn -> provider(context, :timeline_precondition_json_schema, []) end,
       fn -> provider(context, :stable_id_array_schema, []) end,
       fn -> provider(context, :timeline_identity_json_schema, []) end}
    )
  end

  def property(field, "execution_report.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.ResultArtifactPropertyDispatch.execution_report(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {"execution_report.v1", context_value(context, :stable_id_pattern),
       &OrbitalDynamics.ResultSet.Artifact.execution_report_model_limits/0}
    )
  end

  def property(field, "result_artifact.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.ResultArtifactPropertyDispatch.result_artifact(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {1, context_value(context, :stable_id_pattern), "execution_report.v1",
       fn arg1 -> embedded(arg1, context) end}
    )
  end

  def property(field, "resource_summary.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.ResultArtifactPropertyDispatch.resource_summary(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {"resource_summary.v1", context_value(context, :stable_id_pattern)}
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
    OrbitalDynamics.Schema.ValidationEvidencePropertyDispatch.property(
      field,
      contract_name,
      contract,
      contracts: %{
        reference_fixture_report: "validation_reference_fixture_report.v1",
        reference_report: "validation_reference_report.v1",
        record: "validation_record.v1",
        check: "validation_check.v1"
      },
      reference_report_schema: fn ->
        provider(context, :validation_reference_report_json_schema, [])
      end,
      stable_id_pattern: context_value(context, :stable_id_pattern),
      validation_check_schema: &OrbitalDynamics.Schema.ValidationJsonSchema.check/0,
      validation_level_schema: &OrbitalDynamics.Schema.ValidationJsonSchema.validation_level/0,
      default_property: fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end
    )
  end

  def property(field, contract_name, contract, context)
      when contract_name in ["model_acceptance_report.v1", "validation_safety_case_summary.v1"] do
    OrbitalDynamics.Schema.ValidationAssessmentPropertyDispatch.property(
      field,
      contract_name,
      contract,
      contracts: %{
        model_acceptance_report: "model_acceptance_report.v1",
        validation_safety_case_summary: "validation_safety_case_summary.v1"
      },
      model_limits: fn -> provider(context, :model_acceptance_report_model_limits, []) end,
      stable_id_pattern: context_value(context, :stable_id_pattern),
      validation_record_schema: fn -> provider(context, :validation_record_json_schema, []) end,
      model_acceptance_row_schema: fn ->
        provider(context, :model_acceptance_row_json_schema, [])
      end,
      safety_case_evidence_row_schema: fn ->
        provider(context, :safety_case_evidence_row_json_schema, [])
      end,
      default_property: fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end
    )
  end

  def property(field, contract_name, contract, context)
      when contract_name in ["schema_validation_report.v1", "schema_validation_batch_report.v1"] do
    OrbitalDynamics.Schema.SchemaValidationPropertyDispatch.property(
      field,
      contract_name,
      contract,
      contracts: %{
        report: "schema_validation_report.v1",
        batch: "schema_validation_batch_report.v1"
      },
      issue_schema: &OrbitalDynamics.Schema.ValidationJsonSchema.issue/0,
      remediation_schema: &OrbitalDynamics.Schema.ValidationJsonSchema.remediation/0,
      model_limits: fn -> provider(context, :schema_validation_model_limits, []) end,
      batch_entry_schema: fn ->
        provider(context, :schema_validation_batch_entry_json_schema, [])
      end,
      skipped_artifact_schema:
        &OrbitalDynamics.Schema.SchemaValidationReportJsonSchema.skipped_artifact/0,
      default_property: fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end
    )
  end

  def property(field, "schema_migration_report.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.SchemaValidationPropertyDispatch.migration(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {"schema_migration_report.v1", 1,
       fn -> provider(context, :schema_migration_statuses, []) end,
       fn -> provider(context, :schema_migration_row_statuses, []) end,
       &OrbitalDynamics.Schema.SchemaMigrationReportJsonSchema.row/0,
       &OrbitalDynamics.Schema.SchemaMigrationContracts.model_limits/0}
    )
  end

  def property(field, contract_name, contract, context)
      when contract_name in ["campaign_request_lint.v1", "study_manifest_lint.v1"] do
    OrbitalDynamics.Schema.LintReportPropertyDispatch.property(
      field,
      contract_name,
      contract,
      contracts: %{
        campaign_request: "campaign_request_lint.v1",
        study_manifest: "study_manifest_lint.v1"
      },
      validation_issue_schema: &OrbitalDynamics.Schema.ValidationJsonSchema.issue/0,
      sha256_schema: fn -> provider(context, :sha256_json_schema, []) end,
      stable_id_pattern: context_value(context, :stable_id_pattern),
      manifest_lint_issue_schema:
        &OrbitalDynamics.Schema.ValidationJsonSchema.manifest_lint_issue/0,
      default_property: fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end
    )
  end

  def property(field, "strategy_branch.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.StrategyArtifactPropertyDispatch.branch(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {context_value(context, :stable_id_pattern),
       fn -> provider(context, :strategy_branch_event_json_schema, []) end,
       fn ->
         OrbitalDynamics.Schema.StrategyBranchJsonSchema.risk(
           context_value(context, :stable_id_pattern),
           provider(context, :scoped_downlink_context_json_schema_properties, [])
         )
       end, fn -> provider(context, :approval_requirement_json_schema, []) end,
       &OrbitalDynamics.Schema.CommonJsonSchema.numeric_map/0,
       fn -> provider(context, :policy_decision_json_schema, []) end}
    )
  end

  def property(field, "optimizer_contract.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.PlanningAnalysisPropertyDispatch.optimizer_contract(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {"optimizer_contract.v1", context_value(context, :stable_id_pattern)}
    )
  end

  def property(field, contract_name, contract, context)
      when contract_name in [
             "environment_model_capability.v1",
             "environment_provider_capability.v1",
             "subsystem_model_capability.v1"
           ] do
    OrbitalDynamics.Schema.ModelCapabilityPropertyDispatch.property(
      field,
      contract_name,
      contract,
      contracts: %{
        environment_model: "environment_model_capability.v1",
        environment_provider: "environment_provider_capability.v1",
        subsystem_model: "subsystem_model_capability.v1"
      },
      stable_id_pattern: context_value(context, :stable_id_pattern),
      validation_level_schema: &OrbitalDynamics.Schema.ValidationJsonSchema.validation_level/0,
      default_property: fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end
    )
  end

  def property(field, "monte_carlo_reproducibility_report.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.PlanningAnalysisPropertyDispatch.monte_carlo(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {"monte_carlo_reproducibility_report.v1", context_value(context, :stable_id_pattern),
       &OrbitalDynamics.Schema.MonteCarloReproducibilityContracts.model_limits/0,
       &OrbitalDynamics.Schema.CommonJsonSchema.numeric_triplet/0}
    )
  end

  def property(field, "strategy_recommendation.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.StrategyArtifactPropertyDispatch.recommendation(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {"strategy_recommendation.v1", context_value(context, :stable_id_pattern),
       fn -> provider(context, :strategy_branch_tradeoff_json_schema, []) end,
       fn -> provider(context, :strategy_explanation_json_schema, []) end,
       fn -> provider(context, :strategy_branch_risk_json_schema, []) end,
       fn -> provider(context, :approval_requirement_json_schema, []) end}
    )
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
    OrbitalDynamics.Schema.TimelineReportPropertyDispatch.candidate_rejection(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {&OrbitalDynamics.Schema.CandidateRejectionReportJsonSchema.model_limits/0,
       fn -> provider(context, :candidate_rejection_row_json_schema, []) end,
       fn -> provider(context, :timeline_candidate_rejection_reasons, []) end,
       fn -> provider(context, :timeline_candidate_rejection_actions, []) end,
       context_value(context, :stable_id_pattern)}
    )
  end

  def property(field, contract_name, contract, context)
      when contract_name in [
             "operational_timeline_report.v1",
             "timeline_diff_report.v1",
             "timeline_diff_summary.v1"
           ] do
    OrbitalDynamics.Schema.TimelineReportPropertyDispatch.property(
      field,
      contract_name,
      contract,
      contracts: %{
        operational_timeline_report: "operational_timeline_report.v1",
        timeline_diff_report: "timeline_diff_report.v1",
        timeline_diff_summary: "timeline_diff_summary.v1"
      },
      model_limits: fn -> provider(context, :timeline_report_model_limits, []) end,
      operational_timeline_row_schema: fn ->
        provider(context, :operational_timeline_row_json_schema, [])
      end,
      timeline_diff_row_schema: fn -> provider(context, :timeline_diff_row_json_schema, []) end,
      stable_id_pattern: context_value(context, :stable_id_pattern),
      capability: fn -> provider(context, :timeline_capabilities, []) end,
      default_property: fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end
    )
  end

  def property(field, contract_name, contract, context)
      when contract_name in [
             "timeline_activity_status_state.v1",
             "timeline_activity_approval_state.v1",
             "timeline_activity_lifecycle_state.v1"
           ] do
    OrbitalDynamics.Schema.TimelineActivityStatePropertyDispatch.lifecycle(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      context_value(context, :stable_id_pattern),
      {fn -> provider(context, :timeline_report_model_limits, []) end,
       fn -> provider(context, :timeline_transition_decisions, []) end,
       &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
       &TimelineContextJsonSchema.lifecycle_transition/0,
       fn -> provider(context, :protection_decision_json_schema, []) end,
       fn -> provider(context, :activity_context_json_schema, []) end,
       &OrbitalDynamics.Schema.TimelineActivityLifecycleStateJsonSchema.lifecycle_assumptions/0,
       &OrbitalDynamics.Schema.TimelineActivityLifecycleStateJsonSchema.default_assumptions/0}
    )
  end

  def property(field, contract_name, contract, context)
      when contract_name in ["timeline_preservation_report.v1", "timeline_preservation_status.v1"] do
    OrbitalDynamics.Schema.TimelineProtectionPropertyDispatch.preservation(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      context_value(context, :stable_id_pattern),
      provider(context, :timeline_report_model_limits, []),
      {&OrbitalDynamics.Schema.CommonJsonSchema.non_negative_integer_count_map/0,
       fn -> provider(context, :stable_id_array_schema, []) end,
       fn -> provider(context, :stable_id_array_map_schema, []) end,
       fn -> provider(context, :protection_decision_json_schema, []) end,
       fn -> provider(context, :timeline_identity_json_schema, []) end,
       fn arg1 -> provider(context, :timeline_preservation_assumptions_json_schema, [arg1]) end}
    )
  end

  def property(field, "timeline_lifecycle_state_summary.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.TimelineTransitionPropertyDispatch.lifecycle_summary(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {fn -> provider(context, :timeline_lifecycle_state_row_json_schema, []) end,
       fn -> provider(context, :timeline_report_model_limits, []) end,
       &OrbitalDynamics.Schema.CommonJsonSchema.non_negative_integer_count_map/0,
       fn -> provider(context, :stable_id_array_schema, []) end}
    )
  end

  def property(field, contract_name, contract, context)
      when contract_name in [
             "timeline_transition_application_report.v1",
             "timeline_transition_application_summary.v1"
           ] do
    OrbitalDynamics.Schema.TimelineTransitionPropertyDispatch.application(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {fn -> provider(context, :timeline_transition_application_row_json_schema, []) end,
       fn -> provider(context, :timeline_transition_selected_activity_json_schema, []) end,
       fn -> provider(context, :timeline_report_model_limits, []) end,
       fn -> provider(context, :timeline_capabilities, []) end,
       &OrbitalDynamics.Schema.CommonJsonSchema.enum_count_map/1,
       fn -> provider(context, :stable_id_array_schema, []) end,
       fn -> provider(context, :stable_id_array_map_schema, []) end}
    )
  end

  def property(field, "command_window_report.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.GroundNetworkReportPropertyDispatch.command_window(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {fn -> provider(context, :command_window_report_model_limits, []) end,
       fn -> provider(context, :command_window_row_json_schema, []) end}
    )
  end

  def property(field, "station_calendar_precedence_summary.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.GroundNetworkReportPropertyDispatch.calendar_precedence(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      context_value(context, :stable_id_pattern),
      fn -> provider(context, :station_calendar_report_model_limits, []) end
    )
  end

  def property(field, "station_reservation_report.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.GroundNetworkReportPropertyDispatch.reservation(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      context_value(context, :stable_id_pattern),
      {&OrbitalDynamics.Schema.StationReservationReportJsonSchema.models/0,
       fn -> provider(context, :station_reservation_contact_json_schema, []) end,
       fn -> provider(context, :station_reservation_provider_contention_group_json_schema, []) end}
    )
  end

  def property(field, "station_calendar_report.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.GroundNetworkReportPropertyDispatch.calendar(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {fn -> provider(context, :station_calendar_contact_json_schema, []) end,
       fn -> provider(context, :station_calendar_report_model, []) end,
       fn -> provider(context, :station_calendar_provider_contention_group_json_schema, []) end,
       fn -> provider(context, :station_calendar_provider_entry_json_schema, []) end,
       &OrbitalDynamics.Schema.OperationalReadinessContextJsonSchema.trust_boundary_status_count_map/0,
       fn -> provider(context, :station_calendar_report_model_limits, []) end}
    )
  end

  def property(field, contract_name, contract, context)
      when contract_name in [
             "station_reservation_review_summary.v1",
             "station_reservation_hold_summary.v1",
             "station_reservation_hold_import_readiness_summary.v1"
           ] do
    OrbitalDynamics.Schema.StationReservationSummaryPropertyDispatch.property(
      field,
      contract_name,
      contract,
      contracts: %{
        review_summary: "station_reservation_review_summary.v1",
        hold_summary: "station_reservation_hold_summary.v1",
        hold_import_readiness_summary: "station_reservation_hold_import_readiness_summary.v1"
      },
      review_row_schema: fn ->
        provider(context, :station_reservation_review_summary_row_json_schema, [])
      end,
      import_readiness_row_schema: fn ->
        provider(context, :station_reservation_hold_import_readiness_row_json_schema, [])
      end,
      model_limits: fn -> provider(context, :station_calendar_report_model_limits, []) end,
      stable_id_pattern: context_value(context, :stable_id_pattern),
      default_property: fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end
    )
  end

  def property(field, "station_calendar_provider.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.StandaloneCommunicationsPropertyDispatch.station_calendar_provider(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      provider(context, :station_calendar_provider_entry_json_schema, [])
    )
  end

  def property(field, contract_name, contract, context)
      when contract_name in ["link_capacity_report.v1", "link_capacity_summary.v1"] do
    OrbitalDynamics.Schema.LinkCapacityPropertyDispatch.property(
      field,
      contract_name,
      contract,
      contracts: %{report: "link_capacity_report.v1", summary: "link_capacity_summary.v1"},
      row_schema: fn -> provider(context, :link_capacity_row_json_schema, []) end,
      model_limits: &OrbitalDynamics.Schema.LinkCapacitySummaryContracts.model_limits/0,
      report_assumptions_schema: fn ->
        provider(context, :link_capacity_assumptions_json_schema, [[]])
      end,
      summary_assumptions_schema: fn ->
        provider(context, :link_capacity_assumptions_json_schema, [
          ["execution_boundary", "source", "operator_authority"]
        ])
      end,
      stable_id_array_schema: fn -> provider(context, :stable_id_array_schema, []) end,
      string_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
      count_map_schema: &OrbitalDynamics.Schema.CommonJsonSchema.non_negative_integer_count_map/0,
      number_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.number_array/0,
      actual_data_rate_throughput_derivations_schema:
        &TimelineContextJsonSchema.actual_data_rate_throughput_derivations/0,
      numeric_map_schema: &OrbitalDynamics.Schema.CommonJsonSchema.numeric_map/0,
      stable_id_array_map_schema: fn -> provider(context, :stable_id_array_map_schema, []) end,
      default_property: fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end
    )
  end

  def property(field, "relay_data_path_summary.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.StandaloneCommunicationsPropertyDispatch.relay_data_path(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {&OrbitalDynamics.Schema.RelayDataPathSummaryContracts.model_limits/0,
       &OrbitalDynamics.Schema.RelayDataPathSummaryJsonSchema.assumptions/0,
       fn -> provider(context, :relay_data_path_row_json_schema, []) end,
       &OrbitalDynamics.Schema.CommonJsonSchema.non_negative_integer_count_map/0,
       fn -> provider(context, :stable_id_array_schema, []) end,
       fn -> provider(context, :stable_id_array_map_schema, []) end}
    )
  end

  def property(field, "contact_allocation_report.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.StandaloneCommunicationsPropertyDispatch.contact_allocation(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {fn -> provider(context, :contact_allocation_row_json_schema, []) end,
       fn -> provider(context, :contact_allocation_capacity_pack_group_json_schema, []) end,
       fn -> provider(context, :contact_allocation_model_limits, []) end,
       fn -> provider(context, :stable_id_array_schema, []) end,
       fn -> provider(context, :nested_stable_id_array_map_json_schema, []) end,
       &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
       &OrbitalDynamics.Schema.OperationalReadinessContextJsonSchema.trust_boundary_status_count_map/0,
       fn -> provider(context, :contact_allocation_capabilities, []) end,
       &OrbitalDynamics.Schema.CommonJsonSchema.enum_count_map/1,
       &OrbitalDynamics.Schema.CommonJsonSchema.non_negative_integer_count_map/0,
       &OrbitalDynamics.Schema.CommonJsonSchema.non_negative_number_map/0}
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
    OrbitalDynamics.Schema.ContactAllocationSummaryPropertyDispatch.property(
      field,
      contract_name,
      contract,
      contracts: %{
        summary: "contact_allocation_summary.v1",
        reservation_conflict_summary: "contact_allocation_reservation_conflict_summary.v1",
        station_pressure_summary: "contact_allocation_station_pressure_summary.v1",
        capacity_pack_summary: "contact_allocation_capacity_pack_summary.v1",
        provider_reservation_request_summary:
          "contact_allocation_provider_reservation_request_summary.v1"
      },
      assumptions: %{
        summary: fn ->
          provider(context, :contact_allocation_summary_assumptions_json_schema, [])
        end,
        reservation_conflict_summary: fn ->
          provider(
            context,
            :contact_allocation_reservation_conflict_summary_assumptions_json_schema,
            []
          )
        end,
        station_pressure_summary: fn ->
          provider(
            context,
            :contact_allocation_station_pressure_summary_assumptions_json_schema,
            []
          )
        end,
        capacity_pack_summary: fn ->
          provider(context, :contact_allocation_capacity_pack_summary_assumptions_json_schema, [])
        end,
        provider_reservation_request_summary: fn ->
          provider(
            context,
            :contact_allocation_provider_reservation_request_summary_assumptions_json_schema,
            []
          )
        end
      },
      stable_id_pattern: context_value(context, :stable_id_pattern),
      model_limits: fn -> provider(context, :contact_allocation_model_limits, []) end,
      row_schema: fn -> provider(context, :contact_allocation_row_json_schema, []) end,
      capacity_pack_group_schema: fn ->
        provider(context, :contact_allocation_capacity_pack_group_json_schema, [])
      end,
      default_property: fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end
    )
  end

  def property(field, contract_name, contract, context)
      when contract_name in ["contact_filter_report.v1", "resource_filter_report.v1"] do
    OrbitalDynamics.Schema.FilterReportPropertyDispatch.property(
      field,
      contract_name,
      contract,
      contracts: %{contact: "contact_filter_report.v1", resource: "resource_filter_report.v1"},
      stable_id_pattern: context_value(context, :stable_id_pattern),
      trust_boundary_count_map_schema:
        &OrbitalDynamics.Schema.OperationalReadinessContextJsonSchema.trust_boundary_status_count_map/0,
      contact_model_limits: fn -> provider(context, :contact_filter_report_model_limits, []) end,
      contact_assumptions_schema: fn ->
        provider(context, :contact_filter_report_assumptions_json_schema, [])
      end,
      resource_model_limits: fn -> provider(context, :resource_filter_report_model_limits, []) end,
      resource_assumptions_schema: fn ->
        provider(context, :resource_filter_report_assumptions_json_schema, [])
      end,
      suppressed_candidate_schema: fn ->
        provider(context, :suppressed_candidate_json_schema, [])
      end,
      default_property: fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end
    )
  end

  def property(field, contract_name, contract, context)
      when contract_name in [
             "resource_projection_report.v1",
             "resource_projection_flow_summary.v1"
           ] do
    OrbitalDynamics.Schema.ResourceProjectionPropertyDispatch.property(
      field,
      contract_name,
      contract,
      contracts: %{
        report: "resource_projection_report.v1",
        flow_summary: "resource_projection_flow_summary.v1"
      },
      stable_id_pattern: context_value(context, :stable_id_pattern),
      models: &ResourceValidation.resource_projection_report_models/0,
      model_limits: &ResourceValidation.resource_projection_report_model_limits/0,
      assumptions_schema:
        &OrbitalDynamics.Schema.ResourceProjectionReportJsonSchema.assumptions/0,
      projection_row_schema: fn -> provider(context, :resource_projection_row_json_schema, []) end,
      flow_row_schema: fn -> provider(context, :resource_projection_flow_row_json_schema, []) end,
      default_property: fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end
    )
  end

  def property(field, contract_name, contract, context)
      when contract_name in [
             "contact_contention_report.v1",
             "contact_contention_resolution_report.v1",
             "contact_contention_resolution_summary.v1"
           ] do
    OrbitalDynamics.Schema.ContactContentionPropertyDispatch.property(
      field,
      contract_name,
      contract,
      stable_id_pattern: context_value(context, :stable_id_pattern),
      model_limits: provider(context, :contact_contention_report_model_limits, []),
      report_assumptions_schema:
        provider(context, :contact_contention_report_assumptions_json_schema, []),
      conflict_group_schema: provider(context, :contact_contention_group_json_schema, []),
      recommendation_schema:
        provider(context, :contact_contention_recommendation_json_schema, []),
      resolution_policy_schema:
        provider(context, :contact_contention_resolution_policy_json_schema, []),
      default_property: fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end
    )
  end

  def property(field, contract_name, contract, context)
      when contract_name in ["objective_satisfaction_report.v1", "objective_tradeoff_report.v1"] do
    OrbitalDynamics.Schema.ObjectiveReportPropertyDispatch.property(
      field,
      contract_name,
      contract,
      satisfaction_row_schema: provider(context, :objective_satisfaction_row_json_schema, []),
      satisfaction_model_limits:
        OrbitalDynamics.CampaignPlanner.objective_satisfaction_model_limits(),
      tradeoff_row_schema: provider(context, :objective_tradeoff_row_json_schema, []),
      tradeoff_models:
        OrbitalDynamics.Schema.OptimizerObjectiveContracts.objective_tradeoff_report_models(),
      score_report_model_limits: OrbitalDynamics.CampaignPlanner.score_report_model_limits(),
      default_property: fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end
    )
  end

  def property(field, contract_name, contract, context)
      when contract_name in ["ranking_comparison_report.v1", "pareto_frontier_report.v1"] do
    OrbitalDynamics.Schema.OptimizerReportPropertyDispatch.property(
      field,
      contract_name,
      contract,
      ranking_row_schema: fn -> provider(context, :ranking_comparison_row_json_schema, []) end,
      ranking_winner_schema: fn ->
        provider(context, :ranking_comparison_winner_json_schema, [])
      end,
      ranking_model_limits: fn -> OrbitalDynamics.Optimizer.ranking_comparison_model_limits() end,
      pareto_row_schema: fn -> provider(context, :pareto_frontier_row_json_schema, []) end,
      pareto_model_limits: fn -> OrbitalDynamics.Optimizer.pareto_frontier_model_limits() end,
      stable_id_pattern: context_value(context, :stable_id_pattern),
      default_property: fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end
    )
  end

  def property(field, "score_term_report.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.PlanningAnalysisPropertyDispatch.score_term(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {OrbitalDynamics.Schema.OptimizerObjectiveContracts.score_term_report_models(),
       OrbitalDynamics.CampaignPlanner.score_report_model_limits(),
       provider(context, :score_term_row_json_schema, [])}
    )
  end

  def property(field, "resource_filter_summary.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.PlanningAnalysisPropertyDispatch.resource_filter_summary(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {"resource_filter_summary.v1", "resource_filter_report.v1",
       context_value(context, :stable_id_pattern),
       fn -> provider(context, :resource_filter_report_model_limits, []) end,
       %{"type" => "object"}, fn -> provider(context, :suppressed_candidate_json_schema, []) end}
    )
  end

  def property(field, "constraint_report.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.PlanningAnalysisPropertyDispatch.constraint(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {OrbitalDynamics.Schema.ConstraintReportContracts.models(),
       OrbitalDynamics.Schema.ConstraintReportContracts.model_limit_values(),
       provider(context, :constraint_row_json_schema, [])}
    )
  end

  def property(field, contract_name, contract, context)
      when contract_name in [
             "operational_import_eligibility_summary.v1",
             "operational_readiness_gate_summary.v1",
             "operational_execution_boundary_summary.v1"
           ] do
    OrbitalDynamics.Schema.OperationalReadinessGateSummaryPropertyDispatch.property(
      field,
      contract_name,
      contract,
      capability: fn -> provider(context, :operational_readiness_capabilities, []) end,
      gate_schema: fn -> provider(context, :operational_readiness_gate_json_schema, []) end,
      import_eligibility_model_limits:
        &OperationalReadinessValidation.operational_import_eligibility_summary_model_limits/0,
      readiness_gate_model_limits:
        &OperationalReadinessValidation.operational_readiness_gate_summary_model_limits/0,
      execution_boundary_model_limits:
        &OperationalReadinessValidation.operational_execution_boundary_summary_model_limits/0,
      stable_id_pattern: context_value(context, :stable_id_pattern),
      string_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
      default_property: fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end
    )
  end

  def property(field, contract_name, contract, context)
      when contract_name in ["operational_quality_gate_summary.v1", "quality_gate_report.v1"] do
    OrbitalDynamics.Schema.QualityGateReportPropertyDispatch.property(
      field,
      contract_name,
      contract,
      capability: fn -> provider(context, :operational_readiness_capabilities, []) end,
      operational_summary_model_limits:
        &OperationalReadinessValidation.quality_gate_summary_model_limits/0,
      report_model_limits: &OperationalReadinessValidation.quality_gate_report_model_limits/0,
      row_schema: fn -> provider(context, :quality_gate_report_row_json_schema, []) end,
      stable_id_pattern: context_value(context, :stable_id_pattern),
      default_property: fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end
    )
  end

  def property(field, contract_name, contract, context)
      when contract_name in [
             "operational_quality_gate_unavailable_resource_summary.v1",
             "operational_quality_gate_operator_training_summary.v1",
             "operational_quality_gate_schema_validation_summary.v1",
             "operational_quality_gate_import_readiness_summary.v1"
           ] do
    OrbitalDynamics.Schema.SpecializedQualityGateSummaryPropertyDispatch.property(
      field,
      contract_name,
      contract,
      unavailable_resource_model_limits:
        &OperationalReadinessValidation.quality_gate_unavailable_resource_summary_model_limits/0,
      operator_training_model_limits:
        &OperationalReadinessValidation.quality_gate_operator_training_summary_model_limits/0,
      schema_validation_model_limits:
        &OperationalReadinessValidation.quality_gate_schema_validation_summary_model_limits/0,
      import_readiness_model_limits:
        &OperationalReadinessValidation.quality_gate_import_readiness_summary_model_limits/0,
      stable_id_pattern: context_value(context, :stable_id_pattern),
      default_property: fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end
    )
  end

  def property(field, "operational_readiness_report.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.OperationalHandoffPropertyDispatch.readiness(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {provider(context, :operational_readiness_capabilities, []),
       provider(context, :operational_readiness_gate_json_schema, []),
       provider(context, :operational_readiness_evidence_json_schema, []),
       OperationalReadinessValidation.operational_readiness_model_limits()}
    )
  end

  def property(field, "operator_review_package.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.OperationalHandoffPropertyDispatch.operator_review(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {provider(context, :operator_review_capabilities, []),
       provider(context, :operator_review_package_model_limits, []),
       provider(context, :operational_readiness_capabilities, []),
       provider(context, :operator_review_row_json_schema, []),
       OrbitalDynamics.Schema.OperatorReviewPackageContracts.scalar_count_fields(),
       context_value(context, :stable_id_pattern)}
    )
  end

  def property(field, "cadence_import_manifest.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.OperationalHandoffPropertyDispatch.cadence_import(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {provider(context, :cadence_import_capability, []),
       provider(context, :cadence_import_manifest_model_limits, []),
       provider(context, :operational_readiness_capabilities, []),
       provider(context, :cadence_import_manifest_row_json_schema, []),
       provider(context, :cadence_import_manifest_scalar_count_fields, []),
       context_value(context, :stable_id_pattern)}
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
