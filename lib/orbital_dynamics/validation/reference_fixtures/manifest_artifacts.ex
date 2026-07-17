defmodule OrbitalDynamics.Validation.ReferenceFixtures.ManifestArtifacts do
  @moduledoc false

  @fixtures %{
    "fixture.artifact.manifest_field_reference.v1" => %{
      "id" => "fixture.artifact.manifest_field_reference.v1",
      "model_id" => "artifact.manifest_field_reference.v1",
      "reference_case" => "checked-in study manifest field reference artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/manifest_field_reference.json",
        "contract" => "manifest_field_reference.v1"
      },
      "expected" => %{
        "schema_contract" => "study_manifest.v1",
        "schema_version" => 1,
        "reference_mode" => "study_manifest_schema_field_reference",
        "compatibility_policy_version" => 1,
        "identity_policy_version" => 1,
        "field_count" => 3720,
        "field_row_count" => 3720,
        "required_field_count" => 162,
        "array_item_count" => 302,
        "section_count" => 19,
        "top_level_required_count" => 3,
        "activation_section_count" => 6,
        "supported_output_count" => 5,
        "supported_propagator_count" => 6,
        "supported_lint_error_code_count" => 15,
        "supported_search_objective_count" => 15,
        "generated_id_scope_count" => 2,
        "semantic_invariant_count" => 3,
        "first_field_path" => "$.campaign",
        "last_field_path" => "$.sun_direction.[]",
        "stable_id_pattern" => "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"
      },
      "tolerances" => %{
        "schema_version" => 0,
        "compatibility_policy_version" => 0,
        "identity_policy_version" => 0,
        "field_count" => 0,
        "field_row_count" => 0,
        "required_field_count" => 0,
        "array_item_count" => 0,
        "section_count" => 0,
        "top_level_required_count" => 0,
        "activation_section_count" => 0,
        "supported_output_count" => 0,
        "supported_propagator_count" => 0,
        "supported_lint_error_code_count" => 0,
        "supported_search_objective_count" => 0,
        "generated_id_scope_count" => 0,
        "semantic_invariant_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external manifest validation",
        "checks manifest field catalog counts, supported vocabularies, policy versions, and identity-policy bounds only"
      ]
    },
    "fixture.artifact.study_manifest_lint.v1" => %{
      "id" => "fixture.artifact.study_manifest_lint.v1",
      "model_id" => "artifact.study_manifest_lint.v1",
      "reference_case" => "checked-in study manifest lint artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/study_manifest_lint_v1.json",
        "contract" => "study_manifest_lint.v1"
      },
      "expected" => %{
        "schema_contract" => "study_manifest_lint.v1",
        "schema_version" => 1,
        "manifest_schema_contract" => "study_manifest.v1",
        "status" => "pass",
        "study_id" => "leo_constellation_campaign",
        "validation_mode" => "study_manifest_lint",
        "error_count" => 0,
        "warning_count" => 0,
        "scenario_count" => 2,
        "output_count" => 4,
        "first_output" => "trajectories",
        "last_output" => "target_visibility",
        "supported_output_count" => 5,
        "supported_propagator_count" => 6,
        "supported_lint_error_code_count" => 15,
        "supported_search_objective_count" => 15,
        "manifest_path" => "studies/leo_constellation_campaign.json",
        "lint_task" => "mix orbital_dynamics.manifest.lint --manifest PATH",
        "semantic_validator" =>
          "OrbitalDynamics.Study.Manifest.from_map/1 + OrbitalDynamics.StudyRunner.validate_run_inputs/2"
      },
      "tolerances" => %{
        "schema_version" => 0,
        "error_count" => 0,
        "warning_count" => 0,
        "scenario_count" => 0,
        "output_count" => 0,
        "supported_output_count" => 0,
        "supported_propagator_count" => 0,
        "supported_lint_error_code_count" => 0,
        "supported_search_objective_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external study-manifest certification",
        "checks manifest lint counts, supported vocabularies, output bounds, and semantic-validator identity only"
      ]
    }
  }

  def all, do: @fixtures
end
