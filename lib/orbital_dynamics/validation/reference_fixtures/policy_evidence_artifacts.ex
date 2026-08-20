defmodule OrbitalDynamics.Validation.ReferenceFixtures.PolicyEvidenceArtifacts do
  @moduledoc false

  @fixtures %{
    "fixture.artifact.backend_acceptance_policy.v1" => %{
      "id" => "fixture.artifact.backend_acceptance_policy.v1",
      "model_id" => "artifact.backend_acceptance_policy.v1",
      "reference_case" => "checked-in backend acceptance policy artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/backend_acceptance_policy_v1.json",
        "contract" => "backend_acceptance_policy.v1"
      },
      "expected" => %{
        "schema_contract" => "backend_acceptance_policy.v1",
        "tier_count" => 3,
        "implementation_count" => 6,
        "benchmark_case_count" => 2,
        "reference_backend_count" => 2,
        "known_limit_count" => 4,
        "numeric_tolerance_policy" => "validation_tolerance_policy.v1",
        "reference_backend_tier" => "reference_default",
        "two_body_tier" => "reference_default",
        "two_body_nx_tier" => "experimental_accelerator",
        "external_service_requires_provider_policy" => true
      },
      "tolerances" => %{
        "tier_count" => 0,
        "implementation_count" => 0,
        "benchmark_case_count" => 0,
        "reference_backend_count" => 0,
        "known_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external backend validation",
        "checks backend tier counts, implementation routing, reference backend mapping, and tolerance-policy link only"
      ]
    },
    "fixture.artifact.validation_tolerance_policy.v1" => %{
      "id" => "fixture.artifact.validation_tolerance_policy.v1",
      "model_id" => "artifact.validation_tolerance_policy.v1",
      "reference_case" => "checked-in validation tolerance policy artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/validation_tolerance_policy_v1.json",
        "contract" => "validation_tolerance_policy.v1"
      },
      "expected" => %{
        "schema_contract" => "validation_tolerance_policy.v1",
        "validation_level_count" => 5,
        "comparison_model_count" => 3,
        "event_timing_key_count" => 4,
        "artifact_regression_limit" => "not an external physics or operations truth model",
        "artifact_regression_scope" =>
          "schema and public-surface stability checks for checked-in artifacts",
        "current_event_timing_policy" => "sampled_state_linear_boundary",
        "validated_level_description" =>
          "external reference-tool or operational evidence within the record's exact covered regime and declared tolerances"
      },
      "tolerances" => %{
        "validation_level_count" => 0,
        "comparison_model_count" => 0,
        "event_timing_key_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external validation policy certification",
        "checks tolerance policy level counts, comparison model vocabulary, event-timing policy, and artifact-regression boundary only"
      ]
    },
    "fixture.artifact.validation_record.v1" => %{
      "id" => "fixture.artifact.validation_record.v1",
      "model_id" => "artifact.validation_record.v1",
      "reference_case" => "checked-in validation record artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/validation_record_v1.json",
        "contract" => "validation_record.v1"
      },
      "expected" => %{
        "schema_contract" => "validation_record.v1",
        "id" => "propagator.two_body",
        "model" => "point_mass_two_body",
        "implementation" => "OrbitalDynamics.Propagators.TwoBody",
        "validation_level" => "educational",
        "evidence_count" => 3,
        "known_limit_count" => 3,
        "tolerance_count" => 3,
        "position_tolerance_km" => 1.0e-6,
        "velocity_tolerance_km_s" => 1.0e-9,
        "energy_relative_tolerance" => 1.0e-9
      },
      "tolerances" => %{
        "evidence_count" => 0,
        "known_limit_count" => 0,
        "tolerance_count" => 0,
        "position_tolerance_km" => 0.0,
        "velocity_tolerance_km_s" => 0.0,
        "energy_relative_tolerance" => 0.0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external model validation",
        "checks validation record identity, implementation, validation level, evidence/limit counts, and tolerance values only"
      ]
    },
    "fixture.artifact.validation_check.v1" => %{
      "id" => "fixture.artifact.validation_check.v1",
      "model_id" => "artifact.validation_check.v1",
      "reference_case" => "checked-in validation check artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/validation_check_v1.json",
        "contract" => "validation_check.v1"
      },
      "expected" => %{
        "schema_contract" => "validation_check.v1",
        "field" => "activity_count",
        "status" => "pass",
        "expected" => 1,
        "observed" => 1,
        "tolerance" => 0,
        "error" => 0
      },
      "tolerances" => %{
        "expected" => 0,
        "observed" => 0,
        "tolerance" => 0,
        "error" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external validation evidence",
        "checks validation check scalar equality fields only"
      ]
    }
  }

  def all, do: @fixtures
end
