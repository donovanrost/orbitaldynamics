defmodule OrbitalDynamics.Schema.CampaignStrategyJsonSchema do
  @moduledoc false

  @strategy_policy_weight_fields [
    "approval_load_weight",
    "asset_balance_weight",
    "coverage_weight",
    "downlink_completion_weight",
    "fuel_preservation_weight",
    "latency_weight",
    "mission_value_weight",
    "priority_commitment_weight",
    "probability_weight",
    "revisit_weight",
    "risk_weight",
    "schedule_stability_weight"
  ]

  @property_fields [
    "strategy_policy",
    "approval_policy",
    "branches",
    "recommendation",
    "operational_feedback"
  ]

  def property_field?(field) when field in @property_fields, do: true
  def property_field?(_field), do: false

  def property_opts("approval_policy", deps) do
    [policy_action_rule_schema: fetch_dep!(deps, :policy_action_rule_schema)]
  end

  def property_opts("branches", deps) do
    [strategy_branch_schema: fetch_dep!(deps, :strategy_branch_schema)]
  end

  def property_opts("recommendation", deps) do
    [strategy_recommendation_schema: fetch_dep!(deps, :strategy_recommendation_schema)]
  end

  def property_opts("operational_feedback", deps) do
    [operational_feedback_schema: fetch_dep!(deps, :operational_feedback_schema)]
  end

  def property_opts(_field, _deps), do: []

  def property_fun_from_context(deps) when is_list(deps) do
    fn field ->
      property(field, property_opts(field, deps))
    end
  end

  def property("strategy_policy", _opts) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" => Map.new(@strategy_policy_weight_fields, &{&1, %{"type" => "number"}})
    }
  end

  def property("approval_policy", opts) do
    OrbitalDynamics.Schema.PolicyDecisionJsonSchema.approval_policy(
      policy_action_rule_schema: Keyword.fetch!(opts, :policy_action_rule_schema)
    )
  end

  def property("branches", opts) do
    %{
      "type" => "array",
      "items" => Keyword.fetch!(opts, :strategy_branch_schema)
    }
  end

  def property("recommendation", opts) do
    Keyword.fetch!(opts, :strategy_recommendation_schema)
  end

  def property("operational_feedback", opts) do
    Keyword.fetch!(opts, :operational_feedback_schema)
  end

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      fun when is_function(fun, 0) -> fun.()
      value -> value
    end
  end
end
