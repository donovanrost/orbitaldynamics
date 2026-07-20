defmodule OrbitalDynamics.Schema.TimelineEdgeSchemaProviders do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  def build(stable_id_pattern, opts) when is_binary(stable_id_pattern) and is_list(opts) do
    dependencies = Map.new(opts)

    %{
      {:ranked_timeline_json_schema, 0} => fn ->
        OrbitalDynamics.Schema.CampaignPlanJsonSchema.ranked_timeline_from_context(
          stable_id_pattern: stable_id_pattern,
          campaign_activity_schema: Map.fetch!(dependencies, :campaign_activity_schema)
        )
      end,
      {:candidate_rejection_row_json_schema, 0} => fn ->
        OrbitalDynamics.Schema.CandidateRejectionReportJsonSchema.row_from_context(
          stable_id_pattern: stable_id_pattern,
          timeline_capability: Map.fetch!(dependencies, :timeline_capability),
          string_array_schema: &CommonJsonSchema.string_array/0,
          activity_context_schema: Map.fetch!(dependencies, :activity_context_schema)
        )
      end,
      {:timeline_lifecycle_state_row_json_schema, 0} => fn ->
        OrbitalDynamics.Schema.TimelineActivityLifecycleStateJsonSchema.row_from_context(
          model_limits: Map.fetch!(dependencies, :timeline_report_model_limits),
          stable_id_pattern: stable_id_pattern,
          stable_id_array_schema: fn -> CommonJsonSchema.stable_id_array(stable_id_pattern) end,
          transition_decisions: Map.fetch!(dependencies, :timeline_transition_decisions),
          string_array_schema: &CommonJsonSchema.string_array/0,
          lifecycle_transition_schema:
            &OrbitalDynamics.Schema.TimelineContextJsonSchema.lifecycle_transition/0,
          activity_context_schema: Map.fetch!(dependencies, :activity_context_schema),
          protection_decision_schema: Map.fetch!(dependencies, :protection_decision_schema)
        )
      end,
      {:timeline_transition_selected_activity_json_schema, 0} => fn ->
        OrbitalDynamics.Schema.TimelineTransitionApplicationJsonSchema.selected_activity_from_context(
          timeline_capability: Map.fetch!(dependencies, :timeline_capability),
          stable_id_pattern: stable_id_pattern,
          stable_id_array_schema: fn -> CommonJsonSchema.stable_id_array(stable_id_pattern) end,
          timeline_identity_schema: Map.fetch!(dependencies, :timeline_identity_schema),
          activity_context_schema: Map.fetch!(dependencies, :activity_context_schema)
        )
      end
    }
  end
end
