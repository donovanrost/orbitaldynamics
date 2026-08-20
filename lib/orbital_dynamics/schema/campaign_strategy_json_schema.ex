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
    "recommendation_eligibility",
    "operational_feedback",
    "source_repair_id",
    "score_term_report",
    "objective_tradeoff_report",
    "pareto_frontier_report",
    "operational_feedback_provenance",
    "cadence_import_manifest"
  ]

  @embedded_report_contracts %{
    "score_term_report" => "score_term_report.v1",
    "objective_tradeoff_report" => "objective_tradeoff_report.v1",
    "pareto_frontier_report" => "pareto_frontier_report.v1",
    "cadence_import_manifest" => "cadence_import_manifest.v1"
  }

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

  def property_opts("source_repair_id", deps) do
    [stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)]
  end

  def property_opts("recommendation_eligibility", deps) do
    [stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)]
  end

  def property_opts(field, deps) when is_map_key(@embedded_report_contracts, field) do
    [
      embedded_contract: fetch_dep!(deps, :embedded_contract),
      embedded_contract_name: Map.fetch!(@embedded_report_contracts, field)
    ]
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

  def property("source_repair_id", opts) do
    %{
      "type" => ["string", "null"],
      "pattern" => Keyword.fetch!(opts, :stable_id_pattern)
    }
  end

  def property("recommendation_eligibility", opts) do
    OrbitalDynamics.Schema.StrategyRecommendationEligibilityContracts.json_schema(
      Keyword.fetch!(opts, :stable_id_pattern)
    )
  end

  def property(field, opts) when is_map_key(@embedded_report_contracts, field) do
    opts
    |> Keyword.fetch!(:embedded_contract)
    |> apply([Keyword.fetch!(opts, :embedded_contract_name)])
  end

  def property("operational_feedback_provenance", _opts) do
    OrbitalDynamics.Schema.OperationalFeedbackJsonSchema.strategy_provenance()
  end

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      fun when is_function(fun, 0) -> fun.()
      value -> value
    end
  end
end
