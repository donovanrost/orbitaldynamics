defmodule OrbitalDynamics.Schema.ExecutionStateSchemaProviders do
  @moduledoc false

  def build(stable_id_pattern, opts) when is_binary(stable_id_pattern) and is_list(opts) do
    dependencies = Map.new(opts)

    %{
      {:maneuver_execution_delta_json_schema, 0} => fn ->
        maneuver_execution_delta(stable_id_pattern)
      end,
      {:realized_spacecraft_state_json_schema, 0} => fn ->
        realized_spacecraft_state(stable_id_pattern)
      end,
      {:realized_state_snapshot_metadata_json_schema, 0} => fn ->
        realized_state_snapshot_metadata(stable_id_pattern)
      end,
      {:spacecraft_state_estimate_json_schema, 0} => fn ->
        spacecraft_state_estimate(stable_id_pattern)
      end,
      {:plan_delta_json_schema, 0} => fn ->
        OrbitalDynamics.Schema.CampaignRepairJsonSchema.plan_delta_from_deps(
          stable_id_pattern: stable_id_pattern,
          planned_activity_schema: Map.fetch!(dependencies, :planned_activity_schema),
          realized_activity_schema: Map.fetch!(dependencies, :realized_activity_schema),
          timeline_link_schema: Map.fetch!(dependencies, :timeline_link_schema),
          activity_context_schema: Map.fetch!(dependencies, :activity_context_schema)
        )
      end
    }
  end

  defp spacecraft_state_estimate(stable_id_pattern) do
    OrbitalDynamics.Schema.AcceptedStateJsonSchema.spacecraft_state_estimate_from_context(
      stable_id_pattern: stable_id_pattern,
      numeric_triplet_schema: &OrbitalDynamics.Schema.CommonJsonSchema.numeric_triplet/0
    )
  end

  defp maneuver_execution_delta(stable_id_pattern) do
    OrbitalDynamics.Schema.AcceptedStateJsonSchema.maneuver_execution_delta_from_context(
      stable_id_pattern: stable_id_pattern,
      numeric_triplet_schema: &OrbitalDynamics.Schema.CommonJsonSchema.numeric_triplet/0
    )
  end

  defp realized_spacecraft_state(stable_id_pattern) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => ["scenario_id"],
      "properties" => %{
        "spacecraft_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "scenario_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "mode" => %{"type" => "string"},
        "status" => %{"type" => "string"},
        "payload_status" => %{"type" => "string"},
        "degraded" => %{"type" => "boolean"},
        "payload_available" => %{"type" => "boolean"},
        "antenna_available" => %{"type" => "boolean"},
        "incompatible_activity_types" => OrbitalDynamics.Schema.CommonJsonSchema.string_array(),
        "source" => %{"type" => "object", "additionalProperties" => true},
        "metadata" => %{"type" => "object", "additionalProperties" => true}
      }
    }
  end

  defp realized_state_snapshot_metadata(stable_id_pattern) do
    OrbitalDynamics.Schema.RealizedStateSnapshotJsonSchema.metadata(
      stable_id_pattern: stable_id_pattern
    )
  end
end
