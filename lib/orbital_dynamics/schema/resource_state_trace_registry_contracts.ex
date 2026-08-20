defmodule OrbitalDynamics.Schema.ResourceStateTraceRegistryContracts do
  @moduledoc false

  def contracts do
    %{
      "resource_state_trace.v1" => %{
        "schema_contract" => "resource_state_trace.v1",
        "artifact_family" => "resource_state_trace",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "id",
          "model",
          "spacecraft_id",
          "status",
          "initial_state",
          "final_state",
          "input_activity_count",
          "applied_activity_count",
          "ignored_activity_count",
          "invalid_activity_count",
          "invalid_activity_ids",
          "trace_rows",
          "invalid_activities",
          "violation_count",
          "violation_types",
          "activity_ids_by_violation_type",
          "assumptions",
          "provenance",
          "model_limits"
        ],
        "optional_fields" => [],
        "nested_contracts" => []
      }
    }
  end
end
