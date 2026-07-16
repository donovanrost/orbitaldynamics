defmodule OrbitalDynamics.Schema.AcceptedStateRegistryContracts do
  @moduledoc false

  def contracts do
    %{
      "accepted_planning_state.v1" => %{
        "schema_contract" => "accepted_planning_state.v1",
        "artifact_family" => "accepted_planning_state",
        "schema_version" => 1,
        "required_fields" => [
          "schema_version",
          "artifact_type",
          "snapshot_id",
          "accepted_at",
          "spacecraft_states",
          "source",
          "quality",
          "provenance"
        ],
        "optional_fields" => ["maneuver_execution_deltas"],
        "nested_contracts" => ["spacecraft_state_estimate.v1", "maneuver_execution_delta.v1"]
      },
      "spacecraft_state_estimate.v1" => %{
        "schema_contract" => "spacecraft_state_estimate.v1",
        "artifact_family" => "spacecraft_state_estimate",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "spacecraft_id",
          "scenario_id",
          "epoch",
          "frame",
          "state_vector",
          "source",
          "quality"
        ],
        "optional_fields" => ["trust_boundary", "provenance", "metadata"],
        "nested_contracts" => []
      },
      "maneuver_execution_delta.v1" => %{
        "schema_contract" => "maneuver_execution_delta.v1",
        "artifact_family" => "maneuver_execution_delta",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "activity_id",
          "status",
          "source",
          "quality"
        ],
        "optional_fields" => [
          "epoch_s",
          "delta_v_km_s",
          "trust_boundary",
          "provenance",
          "metadata"
        ],
        "nested_contracts" => []
      }
    }
  end
end
