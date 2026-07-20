defmodule OrbitalDynamics.Schema.TimelineFeedbackSchemaProviders do
  @moduledoc false

  def build(stable_id_pattern, timeline_feedback_contract, opts)
      when is_binary(stable_id_pattern) and is_binary(timeline_feedback_contract) and
             is_list(opts) do
    dependencies = Map.new(opts)

    %{
      {:operational_feedback_json_schema, 0} => fn ->
        OrbitalDynamics.Schema.OperationalFeedbackJsonSchema.operational_feedback(%{
          probability_map: OrbitalDynamics.Schema.CommonJsonSchema.probability_map(),
          string_value_map: OrbitalDynamics.Schema.CommonJsonSchema.string_value_map(),
          non_negative_number_map:
            OrbitalDynamics.Schema.CommonJsonSchema.non_negative_number_map(),
          string_list_map: OrbitalDynamics.Schema.CommonJsonSchema.string_list_map(),
          nested_object_map: OrbitalDynamics.Schema.CommonJsonSchema.nested_object_map(),
          realized_activity: call(dependencies, :realized_activity_schema)
        })
      end,
      {:timeline_feedback_operational_feedback_provenance_json_schema, 0} => fn ->
        OrbitalDynamics.Schema.OperationalFeedbackJsonSchema.timeline_feedback_provenance(
          timeline_feedback_contract,
          %{
            string_array: OrbitalDynamics.Schema.CommonJsonSchema.string_array(),
            count_map: OrbitalDynamics.Schema.CommonJsonSchema.non_negative_integer_count_map(),
            string_list_map: OrbitalDynamics.Schema.CommonJsonSchema.string_list_map()
          }
        )
      end,
      {:timeline_feedback_row_json_schema, 0} => fn ->
        OrbitalDynamics.Schema.TimelineFeedbackRowJsonSchema.row(
          stable_id_pattern: stable_id_pattern,
          capability: call(dependencies, :timeline_feedback_capability),
          stable_id_array_schema:
            OrbitalDynamics.Schema.CommonJsonSchema.stable_id_array(stable_id_pattern),
          string_array_schema: OrbitalDynamics.Schema.CommonJsonSchema.string_array(),
          number_array_schema: OrbitalDynamics.Schema.CommonJsonSchema.number_array(),
          probability_schema: OrbitalDynamics.Schema.CommonJsonSchema.probability(),
          number_or_string_schema: OrbitalDynamics.Schema.CommonJsonSchema.number_or_string(),
          protection_decision_schema: call(dependencies, :protection_decision_schema),
          lifecycle_transition_schema:
            OrbitalDynamics.Schema.TimelineContextJsonSchema.lifecycle_transition(),
          actual_data_rate_throughput_derivation_schema:
            OrbitalDynamics.Schema.TimelineContextJsonSchema.actual_data_rate_throughput_derivation(),
          numeric_triplet_schema: OrbitalDynamics.Schema.CommonJsonSchema.numeric_triplet(),
          timeline_identity_schema: call(dependencies, :timeline_identity_schema),
          activity_context_schema: call(dependencies, :activity_context_schema),
          planned_activity_schema: call(dependencies, :planned_activity_schema),
          realized_activity_schema: call(dependencies, :realized_activity_schema)
        )
      end
    }
  end

  defp call(dependencies, name), do: dependencies |> Map.fetch!(name) |> apply([])
end
