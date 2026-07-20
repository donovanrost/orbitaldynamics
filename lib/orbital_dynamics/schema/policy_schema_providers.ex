defmodule OrbitalDynamics.Schema.PolicySchemaProviders do
  @moduledoc false

  def build(stable_id_pattern, opts) when is_binary(stable_id_pattern) and is_list(opts) do
    dependencies = Map.new(opts)

    %{
      {:policy_action_rule_json_schema, 0} => fn -> action_rule(stable_id_pattern) end,
      {:policy_decision_json_schema, 0} => Map.fetch!(dependencies, :policy_decision_schema),
      {:policy_decision_evidence_json_schema, 0} => fn ->
        OrbitalDynamics.Schema.PolicyDecisionJsonSchema.evidence(
          stable_id_pattern: stable_id_pattern,
          policy_escalation_schema: escalation(stable_id_pattern)
        )
      end,
      {:policy_decision_rule_match_json_schema, 0} => fn -> rule_match(stable_id_pattern) end,
      {:policy_escalation_json_schema, 0} => fn -> escalation(stable_id_pattern) end,
      {:scoped_downlink_context_json_schema_properties, 0} => fn ->
        scoped_downlink_context_properties(stable_id_pattern)
      end
    }
  end

  def rule_match(stable_id_pattern) when is_binary(stable_id_pattern) do
    OrbitalDynamics.Schema.PolicyDecisionRuleMatchJsonSchema.rule_match_from_context(
      stable_id_pattern: stable_id_pattern,
      policy_context_fields: OrbitalDynamics.Schema.PolicyFieldGroups.json_schema()
    )
  end

  def escalation(stable_id_pattern) when is_binary(stable_id_pattern) do
    OrbitalDynamics.Schema.PolicyDecisionRuleMatchJsonSchema.escalation_from_context(
      stable_id_pattern: stable_id_pattern
    )
  end

  defp action_rule(stable_id_pattern) do
    action_rule_fields = OrbitalDynamics.Schema.PolicyFieldGroups.action_rule()

    OrbitalDynamics.Schema.PolicyActionRuleJsonSchema.action_rule(
      stable_id_pattern: stable_id_pattern,
      policy_context_fields: OrbitalDynamics.Schema.PolicyFieldGroups.json_schema(),
      number_fields: Keyword.fetch!(action_rule_fields, :number_fields),
      integer_fields: Keyword.fetch!(action_rule_fields, :integer_fields)
    )
  end

  defp scoped_downlink_context_properties(stable_id_pattern) do
    OrbitalDynamics.Schema.ScopedDownlinkContextJsonSchema.scoped_from_context(
      stable_id_pattern: stable_id_pattern
    )
  end
end
