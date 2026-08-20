defmodule OrbitalDynamics.Schema.StrategyPlanningPropertyRouter do
  @moduledoc false

  import OrbitalDynamics.Schema.JsonSchemaPropertySupport,
    only: [context_value: 2, fallback: 4, provider: 3]

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
       &OrbitalDynamics.CampaignPlanner.branch_comparison_model_limits/0,
       context_value(context, :stable_id_pattern)}
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

  def property(
        field,
        "campaign_strategy.v3" = contract_name,
        contract,
        context,
        embedded_contract
      ) do
    OrbitalDynamics.Schema.StrategyArtifactPropertyDispatch.campaign_strategy(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {fn -> provider(context, :strategy_branch_json_schema, []) end,
       fn -> provider(context, :strategy_recommendation_json_schema, []) end,
       fn -> provider(context, :operational_feedback_json_schema, []) end,
       fn -> provider(context, :policy_action_rule_json_schema, []) end, embedded_contract,
       context_value(context, :stable_id_pattern)}
    )
  end
end
