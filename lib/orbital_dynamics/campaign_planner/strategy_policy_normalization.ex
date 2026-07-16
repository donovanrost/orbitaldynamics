defmodule OrbitalDynamics.CampaignPlanner.StrategyPolicyNormalization do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ApprovalPolicy,
    ScalarValues,
    StrategicScoringPolicy,
    ValueEncoding
  }

  alias OrbitalDynamics.Policy

  def strategy(%StrategicScoringPolicy{} = policy), do: policy

  def strategy(policy) do
    policy = ValueEncoding.stringify_keys(policy || %{})

    %StrategicScoringPolicy{
      mission_value_weight: strategy_policy_number!(policy, "mission_value_weight", 1.0),
      coverage_weight: strategy_policy_number!(policy, "coverage_weight", 25.0),
      revisit_weight: strategy_policy_number!(policy, "revisit_weight", 5.0),
      latency_weight: strategy_policy_number!(policy, "latency_weight", 0.01),
      downlink_completion_weight:
        strategy_policy_number!(policy, "downlink_completion_weight", 50.0),
      fuel_preservation_weight: strategy_policy_number!(policy, "fuel_preservation_weight", 25.0),
      schedule_stability_weight:
        strategy_policy_number!(policy, "schedule_stability_weight", 1.0),
      asset_balance_weight: strategy_policy_number!(policy, "asset_balance_weight", 10.0),
      priority_commitment_weight:
        strategy_policy_number!(policy, "priority_commitment_weight", 50.0),
      risk_weight: strategy_policy_number!(policy, "risk_weight", 100.0),
      approval_load_weight: strategy_policy_number!(policy, "approval_load_weight", 20.0),
      probability_weight: strategy_policy_number!(policy, "probability_weight", 1.0)
    }
  end

  def approval(%ApprovalPolicy{} = policy), do: policy

  def approval(policy) do
    raw_policy = ValueEncoding.stringify_keys(policy || %{})
    policy = Policy.normalize_approval_policy(policy)
    default_policy = %ApprovalPolicy{}

    blocked_risk_types =
      if Map.has_key?(raw_policy, "blocked_risk_types") or Map.has_key?(raw_policy, "bundle") or
           Map.has_key?(raw_policy, "policy_bundle_id") do
        Map.get(policy, "blocked_risk_types", default_policy.blocked_risk_types)
      else
        default_policy.blocked_risk_types
      end

    %ApprovalPolicy{
      auto_approvable_risk_limit: Map.get(policy, "auto_approvable_risk_limit", 0),
      auto_approvable_approval_count_limit:
        Map.get(policy, "auto_approvable_approval_count_limit", 0),
      operator_review_risk_limit: Map.get(policy, "operator_review_risk_limit", 3),
      blocked_risk_types: blocked_risk_types,
      action_rules: Map.get(policy, "action_rules", [])
    }
  end

  def strategy_to_map(%StrategicScoringPolicy{} = policy), do: struct_to_string_key_map(policy)
  def approval_to_map(%ApprovalPolicy{} = policy), do: struct_to_string_key_map(policy)

  def numeric_value(policy, field, default) do
    case ScalarValues.numeric_or_nil(Map.get(policy, field, default)) do
      value when is_number(value) -> value
      _value -> default
    end
  end

  defp strategy_policy_number!(policy, field, default) do
    policy
    |> Map.get(field, default)
    |> ScalarValues.numeric!("strategy_policy.#{field}")
  end

  defp struct_to_string_key_map(policy) do
    policy
    |> Map.from_struct()
    |> Map.new(fn {key, value} -> {to_string(key), value} end)
  end
end
