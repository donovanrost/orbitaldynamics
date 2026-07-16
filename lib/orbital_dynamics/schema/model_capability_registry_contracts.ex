defmodule OrbitalDynamics.Schema.ModelCapabilityRegistryContracts do
  @moduledoc false

  def contracts do
    %{
      "environment_model_capability.v1" => %{
        "schema_contract" => "environment_model_capability.v1",
        "artifact_family" => "environment_model_capability",
        "schema_version" => 1,
        "required_fields" => [
          "id",
          "schema_contract",
          "category",
          "model",
          "source",
          "validation_level",
          "time_span",
          "supported_bodies",
          "network_access",
          "parameters",
          "known_limits"
        ],
        "optional_fields" => [
          "coordinate_frame",
          "interpolation"
        ],
        "nested_contracts" => []
      },
      "environment_provider_capability.v1" => %{
        "schema_contract" => "environment_provider_capability.v1",
        "artifact_family" => "environment_provider_capability",
        "schema_version" => 1,
        "required_fields" => [
          "id",
          "schema_contract",
          "category",
          "model",
          "source",
          "validation_level",
          "coverage",
          "interpolation",
          "supported_bodies",
          "network_access",
          "known_limits"
        ],
        "optional_fields" => [
          "outputs",
          "parameters",
          "trust_boundary",
          "provenance"
        ],
        "nested_contracts" => []
      },
      "subsystem_model_capability.v1" => %{
        "schema_contract" => "subsystem_model_capability.v1",
        "artifact_family" => "subsystem_model_capability",
        "schema_version" => 1,
        "required_fields" => [
          "id",
          "schema_contract",
          "subsystem",
          "model",
          "source",
          "fidelity_tier",
          "validation_level",
          "applicability",
          "state_variables",
          "activity_effects",
          "parameters",
          "known_limits"
        ],
        "optional_fields" => [
          "provenance"
        ],
        "nested_contracts" => []
      }
    }
  end
end
