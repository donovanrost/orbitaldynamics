defmodule OrbitalDynamics.Schema.StrategySchemaProviders do
  @moduledoc false

  def build(stable_id_pattern, opts) when is_binary(stable_id_pattern) and is_list(opts) do
    dependencies = Map.new(opts)

    %{
      {:strategy_branch_event_json_schema, 0} => fn ->
        OrbitalDynamics.Schema.StrategyContextJsonSchema.event(
          context_inputs(stable_id_pattern, dependencies)
        )
      end,
      {:strategy_branch_json_schema, 0} => fn ->
        OrbitalDynamics.Schema.StrategyContextJsonSchema.branch(
          context_inputs(stable_id_pattern, dependencies)
        )
      end,
      {:strategy_branch_risk_json_schema, 0} => fn ->
        OrbitalDynamics.Schema.StrategyContextJsonSchema.risk(
          stable_id_pattern,
          call(dependencies, :scoped_downlink_context_properties)
        )
      end,
      {:strategy_branch_tradeoff_json_schema, 0} => fn ->
        OrbitalDynamics.Schema.StrategyContextJsonSchema.tradeoff()
      end,
      {:strategy_explanation_json_schema, 0} => fn ->
        OrbitalDynamics.Schema.StrategyContextJsonSchema.explanation(
          stable_id_pattern,
          OrbitalDynamics.Schema.PlanningAnalysisSchemaProviders.branch_scoped_downlink_context_properties(
            stable_id_pattern
          )
        )
      end,
      {:strategy_recommendation_json_schema, 0} => fn ->
        call(dependencies, :strategy_recommendation_schema)
      end
    }
  end

  defp context_inputs(stable_id_pattern, dependencies) do
    [
      stable_id_pattern: stable_id_pattern,
      stable_id_array_schema:
        OrbitalDynamics.Schema.CommonJsonSchema.stable_id_array(stable_id_pattern),
      numeric_map_schema: OrbitalDynamics.Schema.CommonJsonSchema.numeric_map(),
      string_array_schema: OrbitalDynamics.Schema.CommonJsonSchema.string_array(),
      semantic_change_details_schema:
        OrbitalDynamics.Schema.CandidateDiffJsonSchema.semantic_change_details(),
      string_list_map_schema: OrbitalDynamics.Schema.CommonJsonSchema.string_list_map(),
      non_negative_integer_count_map_schema:
        OrbitalDynamics.Schema.CommonJsonSchema.non_negative_integer_count_map(),
      provider_counteroffer_negotiation_states:
        call(dependencies, :provider_counteroffer_negotiation_states),
      scoped_downlink_context_properties: call(dependencies, :scoped_downlink_context_properties),
      approval_requirement_schema: call(dependencies, :approval_requirement_schema),
      policy_decision_rule_match_schema: call(dependencies, :policy_decision_rule_match_schema),
      policy_decision_schema: call(dependencies, :policy_decision_schema)
    ]
  end

  defp call(dependencies, name), do: dependencies |> Map.fetch!(name) |> apply([])
end
