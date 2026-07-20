defmodule OrbitalDynamics.Schema.ExecutionStateSchemaProviders do
  @moduledoc false

  def build(stable_id_pattern) when is_binary(stable_id_pattern) do
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
