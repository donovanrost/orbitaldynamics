defmodule OrbitalDynamics.Schema.StrategyContextJsonSchema do
  @moduledoc false

  def tradeoff, do: OrbitalDynamics.Schema.StrategyBranchJsonSchema.tradeoff()

  def risk(stable_id_pattern, scoped_downlink_context_properties) do
    OrbitalDynamics.Schema.StrategyBranchJsonSchema.risk(
      stable_id_pattern,
      scoped_downlink_context_properties
    )
  end

  def branch(context) do
    OrbitalDynamics.Schema.StrategyBranchJsonSchema.branch(
      stable_id_pattern: fetch!(context, :stable_id_pattern),
      numeric_map_schema: fetch!(context, :numeric_map_schema),
      string_array_schema: fetch!(context, :string_array_schema),
      event_schema: event(context),
      risk_schema:
        risk(
          fetch!(context, :stable_id_pattern),
          fetch!(context, :scoped_downlink_context_properties)
        ),
      approval_requirement_schema: fetch!(context, :approval_requirement_schema),
      policy_decision_rule_match_schema: fetch!(context, :policy_decision_rule_match_schema),
      tradeoff_schema: tradeoff(),
      policy_decision_schema: fetch!(context, :policy_decision_schema),
      assumptions_schema: assumptions(context),
      provenance_schema: provenance(context)
    )
  end

  def assumptions(context) do
    OrbitalDynamics.Schema.StrategyBranchJsonSchema.assumptions(
      stable_id_pattern: fetch!(context, :stable_id_pattern),
      string_array_schema: fetch!(context, :string_array_schema),
      event_schema: event(context)
    )
  end

  def provenance(context) do
    OrbitalDynamics.Schema.StrategyBranchJsonSchema.provenance(
      stable_id_pattern: fetch!(context, :stable_id_pattern),
      string_array_schema: fetch!(context, :string_array_schema)
    )
  end

  def event(context) do
    OrbitalDynamics.Schema.StrategyBranchJsonSchema.event(
      stable_id_pattern: fetch!(context, :stable_id_pattern),
      stable_id_array_schema: fetch!(context, :stable_id_array_schema),
      semantic_change_details_schema: fetch!(context, :semantic_change_details_schema),
      numeric_map_schema: fetch!(context, :numeric_map_schema),
      string_list_map_schema: fetch!(context, :string_list_map_schema),
      non_negative_integer_count_map_schema:
        fetch!(context, :non_negative_integer_count_map_schema),
      provider_counteroffer_negotiation_states:
        fetch!(context, :provider_counteroffer_negotiation_states)
    )
  end

  def explanation(stable_id_pattern, scoped_downlink_context_properties) do
    OrbitalDynamics.Schema.StrategyRecommendationJsonSchema.explanation(
      stable_id_pattern,
      branch_event_summary_properties(stable_id_pattern, scoped_downlink_context_properties)
    )
  end

  def branch_event_summary_properties(stable_id_pattern, scoped_downlink_context_properties) do
    OrbitalDynamics.Schema.StrategyRecommendationJsonSchema.branch_event_summary_properties(
      stable_id_pattern,
      scoped_downlink_context_properties
    )
  end

  defp fetch!(context, key), do: Keyword.fetch!(context, key)
end
