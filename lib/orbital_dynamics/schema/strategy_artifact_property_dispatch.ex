defmodule OrbitalDynamics.Schema.StrategyArtifactPropertyDispatch do
  @moduledoc false

  alias OrbitalDynamics.Schema.{
    BranchComparisonReportJsonSchema,
    CampaignStrategyJsonSchema,
    StrategyBranchJsonSchema,
    StrategyRecommendationJsonSchema
  }

  def branch(
        field,
        contract_name,
        contract,
        default_property,
        {
          stable_id_pattern,
          event_schema,
          risk_schema,
          approval_requirement_schema,
          numeric_map_schema,
          policy_decision_schema
        }
      ) do
    dispatch(
      field,
      contract_name,
      contract,
      &StrategyBranchJsonSchema.property_field?/1,
      StrategyBranchJsonSchema.property_fun_from_context(
        stable_id_pattern: stable_id_pattern,
        event_schema: event_schema,
        risk_schema: risk_schema,
        approval_requirement_schema: approval_requirement_schema,
        numeric_map_schema: numeric_map_schema,
        policy_decision_schema: policy_decision_schema
      ),
      default_property
    )
  end

  def recommendation(
        field,
        contract_name,
        contract,
        default_property,
        {
          schema_contract,
          stable_id_pattern,
          tradeoff_schema,
          explanation_schema,
          risk_schema,
          approval_requirement_schema
        }
      ) do
    dispatch(
      field,
      contract_name,
      contract,
      &StrategyRecommendationJsonSchema.property_field?/1,
      StrategyRecommendationJsonSchema.property_fun_from_context(
        schema_contract: schema_contract,
        stable_id_pattern: stable_id_pattern,
        tradeoff_schema: tradeoff_schema,
        explanation_schema: explanation_schema,
        risk_schema: risk_schema,
        approval_requirement_schema: approval_requirement_schema
      ),
      default_property
    )
  end

  def branch_comparison(
        field,
        contract_name,
        contract,
        default_property,
        {row_schema, model_limits, stable_id_pattern}
      ) do
    dispatch(
      field,
      contract_name,
      contract,
      &BranchComparisonReportJsonSchema.property_field?/1,
      BranchComparisonReportJsonSchema.property_fun_from_context(
        row_schema: row_schema,
        model_limits: model_limits,
        stable_id_pattern: stable_id_pattern
      ),
      default_property
    )
  end

  def campaign_strategy(
        field,
        contract_name,
        contract,
        default_property,
        {
          strategy_branch_schema,
          strategy_recommendation_schema,
          operational_feedback_schema,
          policy_action_rule_schema,
          embedded_contract,
          stable_id_pattern
        }
      ) do
    dispatch(
      field,
      contract_name,
      contract,
      &CampaignStrategyJsonSchema.property_field?/1,
      CampaignStrategyJsonSchema.property_fun_from_context(
        strategy_branch_schema: strategy_branch_schema,
        strategy_recommendation_schema: strategy_recommendation_schema,
        operational_feedback_schema: operational_feedback_schema,
        policy_action_rule_schema: policy_action_rule_schema,
        embedded_contract: embedded_contract,
        stable_id_pattern: stable_id_pattern
      ),
      default_property
    )
  end

  defp dispatch(
         field,
         contract_name,
         contract,
         property_field?,
         property,
         default_property
       ) do
    if property_field?.(field) do
      property.(field)
    else
      default_property.(field, contract_name, contract)
    end
  end
end
