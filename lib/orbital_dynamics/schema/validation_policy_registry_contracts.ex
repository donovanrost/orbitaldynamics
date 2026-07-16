defmodule OrbitalDynamics.Schema.ValidationPolicyRegistryContracts do
  @moduledoc false

  def contracts do
    %{
      "validation_tolerance_policy.v1" => %{
        "schema_contract" => "validation_tolerance_policy.v1",
        "artifact_family" => "validation_tolerance_policy",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "comparison_model",
          "event_timing",
          "artifact_regressions",
          "validation_levels"
        ],
        "nested_contracts" => []
      },
      "backend_acceptance_policy.v1" => %{
        "schema_contract" => "backend_acceptance_policy.v1",
        "artifact_family" => "backend_acceptance_policy",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "reference_backend",
          "acceptance_tiers",
          "implementation_tiers",
          "comparison_requirements",
          "benchmark_reference_cases",
          "known_limits"
        ],
        "nested_contracts" => ["validation_tolerance_policy.v1"]
      },
      "capability_catalog.v1" => %{
        "schema_contract" => "capability_catalog.v1",
        "artifact_family" => "capability_catalog",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "schema_version",
          "model",
          "analysis",
          "planning",
          "operations",
          "environment",
          "constraints",
          "validation",
          "reporting"
        ],
        "nested_contracts" => []
      }
    }
  end
end
