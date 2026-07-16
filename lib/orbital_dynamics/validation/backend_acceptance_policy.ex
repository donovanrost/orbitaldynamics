defmodule OrbitalDynamics.Validation.BackendAcceptancePolicy do
  @moduledoc false

  def build do
    %{
      "schema_contract" => "backend_acceptance_policy.v1",
      "reference_backend" => %{
        "tier" => "reference_default",
        "implementations" => [
          "OrbitalDynamics.Propagators.TwoBody",
          "OrbitalDynamics.Propagators.J2"
        ],
        "validation_basis" => [
          "validation registry records",
          "curated internal reference fixtures",
          "fixed-step scalar Elixir execution"
        ]
      },
      "acceptance_tiers" => %{
        "reference_default" => %{
          "description" => "default planning backend for current artifacts",
          "requires_benchmark_artifact" => false,
          "requires_reference_match" => true
        },
        "experimental_accelerator" => %{
          "description" =>
            "usable for experiments and batch acceleration when reference outputs match",
          "requires_benchmark_artifact" => true,
          "requires_reference_match" => true,
          "speedup_claim" => "requires matching benchmark artifact for workload shape"
        },
        "external_service_adapter" => %{
          "description" => "future external or service backend boundary",
          "requires_benchmark_artifact" => true,
          "requires_reference_match" => true,
          "requires_provider_policy" => true
        }
      },
      "implementation_tiers" => %{
        "OrbitalDynamics.Propagators.TwoBody" => "reference_default",
        "OrbitalDynamics.Propagators.J2" => "reference_default",
        "OrbitalDynamics.Propagators.TwoBodyNx" => "experimental_accelerator",
        "OrbitalDynamics.Propagators.TwoBodyNxCompiled" => "experimental_accelerator",
        "OrbitalDynamics.Propagators.TwoBodyExlaCpu" => "experimental_accelerator",
        "OrbitalDynamics.Propagators.J2ExlaCpu" => "experimental_accelerator"
      },
      "comparison_requirements" => %{
        "same_manifest_or_scenario_set" => true,
        "same_outputs" => true,
        "numeric_tolerance_policy" => "validation_tolerance_policy.v1",
        "artifact_public_surface_match" => "required for product artifacts",
        "failure_isolation" => "failed scenarios must preserve scenario_id"
      },
      "benchmark_reference_cases" => [
        %{
          "id" => "benchmark.propagator.scalar_vs_batch_leo",
          "artifact_family" => "orbital_dynamics.benchmark",
          "minimum_modes" => ["scalar_direct", "scenario_runner"],
          "claim_scope" => "kernel/sample throughput by scenario count"
        },
        %{
          "id" => "benchmark.study.monte_carlo_scaling",
          "artifact_family" => "orbital_dynamics.study.benchmark",
          "minimum_modes" => ["local"],
          "claim_scope" => "study-level elapsed time and artifact overhead"
        }
      ],
      "known_limits" => [
        "no external reference-tool acceptance yet",
        "speedup claims are workload-specific",
        "Nx and EXLA backends remain experimental accelerators",
        "policy does not certify flight dynamics fidelity"
      ]
    }
  end
end
