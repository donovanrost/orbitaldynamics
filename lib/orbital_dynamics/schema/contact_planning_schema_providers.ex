defmodule OrbitalDynamics.Schema.ContactPlanningSchemaProviders do
  @moduledoc false

  def build(stable_id_pattern, opts) when is_binary(stable_id_pattern) and is_list(opts) do
    dependencies = Map.new(opts)

    %{
      {:contact_intent_row_json_schema, 0} => fn ->
        contact_intent_row(stable_id_pattern, dependencies)
      end,
      {:proposed_contact_row_json_schema, 0} => fn ->
        proposed_contact_row(stable_id_pattern, dependencies)
      end
    }
  end

  defp contact_intent_row(stable_id_pattern, dependencies) do
    OrbitalDynamics.Schema.ContactIntentJsonSchema.row_from_context(
      stable_id_pattern: stable_id_pattern,
      timeline_identity_schema: Map.fetch!(dependencies, :timeline_identity_schema),
      approval_requirement_schema: Map.fetch!(dependencies, :approval_requirement_schema),
      policy_decision_rule_match_schema:
        Map.fetch!(dependencies, :policy_decision_rule_match_schema),
      model_limits: Map.fetch!(dependencies, :contact_intent_model_limits),
      policy_decision_schema: Map.fetch!(dependencies, :policy_decision_schema)
    )
  end

  defp proposed_contact_row(stable_id_pattern, dependencies) do
    OrbitalDynamics.Schema.ProposedContactJsonSchema.row_from_context(
      stable_id_pattern: stable_id_pattern,
      string_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
      source_window_schema: Map.fetch!(dependencies, :source_window_schema),
      cadence_import_schema: fn ->
        dependencies
        |> Map.fetch!(:cadence_import_schema)
        |> apply(["proposed_contact.v1"])
      end
    )
  end
end
