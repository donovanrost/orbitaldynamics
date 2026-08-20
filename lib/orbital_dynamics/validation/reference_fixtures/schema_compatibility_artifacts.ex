defmodule OrbitalDynamics.Validation.ReferenceFixtures.SchemaCompatibilityArtifacts do
  @moduledoc false

  @fixtures %{
    "fixture.artifact.schema_validation_report.v1" => %{
      "id" => "fixture.artifact.schema_validation_report.v1",
      "model_id" => "artifact.schema_validation_report.v1",
      "reference_case" => "checked-in schema validation report artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/schema_validation_report_v1.json",
        "contract" => "schema_validation_report.v1",
        "validated_contract" => "campaign_plan.v1"
      },
      "expected" => %{
        "schema_contract" => "schema_validation_report.v1",
        "model" => "executable_artifact_contract_validation",
        "validation_mode" => "artifact_file",
        "artifact_path" => "study_results/leo_constellation_campaign.json",
        "validated_contract" => "campaign_plan.v1",
        "validated_artifact_family" => "campaign_plan",
        "validated_schema_version" => 1,
        "status" => "pass",
        "error_count" => 0,
        "warning_count" => 0,
        "remediation_count" => 0,
        "error_row_count" => 0,
        "warning_row_count" => 0,
        "remediation_row_count" => 0,
        "model_limit_count" => 3
      },
      "tolerances" => %{
        "validated_schema_version" => 0,
        "error_count" => 0,
        "warning_count" => 0,
        "remediation_count" => 0,
        "error_row_count" => 0,
        "warning_row_count" => 0,
        "remediation_row_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external schema validator certification",
        "checks executable schema-validation report counts and model-limit boundary only"
      ]
    },
    "fixture.artifact.schema_validation_batch_report.v1" => %{
      "id" => "fixture.artifact.schema_validation_batch_report.v1",
      "model_id" => "artifact.schema_validation_batch_report.v1",
      "reference_case" => "checked-in schema validation batch report artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/schema_validation_batch_report_v1.json",
        "contract" => "schema_validation_batch_report.v1",
        "input_dir" => "study_results"
      },
      "expected" => %{
        "schema_contract" => "schema_validation_batch_report.v1",
        "model" => "executable_artifact_contract_batch_validation",
        "validation_mode" => "artifact_directory",
        "input_dir" => "study_results",
        "status" => "pass",
        "status_counts" => %{"pass" => 155},
        "file_count" => 155,
        "artifact_count" => 155,
        "skipped_count" => 0,
        "error_count" => 0,
        "warning_count" => 0,
        "remediation_count" => 0,
        "report_count" => 155,
        "pass_report_count" => 155,
        "fail_report_count" => 0,
        "skipped_artifact_count" => 0,
        "model_limit_count" => 3
      },
      "tolerances" => %{
        "file_count" => 0,
        "artifact_count" => 0,
        "skipped_count" => 0,
        "error_count" => 0,
        "warning_count" => 0,
        "remediation_count" => 0,
        "report_count" => 0,
        "pass_report_count" => 0,
        "fail_report_count" => 0,
        "skipped_artifact_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not an external compatibility suite",
        "checks batch validation counts, status count maps, and model-limit boundary only"
      ]
    },
    "fixture.artifact.schema_migration_report.deprecated_campaign_plan" => %{
      "id" => "fixture.artifact.schema_migration_report.deprecated_campaign_plan",
      "model_id" => "artifact.schema_migration_report.v1",
      "reference_case" =>
        "checked-in schema migration report with campaign-plan deprecation hint",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/schema_migration_report_v1.json",
        "contract" => "schema_migration_report.v1"
      },
      "expected" => %{
        "schema_contract" => "schema_migration_report.v1",
        "schema_version" => 1,
        "model" => "executable_schema_migration_and_deprecation_report",
        "source" => "orbital_dynamics.schema_registry",
        "status" => "review_required",
        "compatibility_policy_version" => 1,
        "compatible_change_rule_count" => 3,
        "breaking_change_rule_count" => 5,
        "contract_count" => 127,
        "current_contract_count" => 126,
        "deprecated_contract_count" => 1,
        "future_contract_count" => 0,
        "migration_row_count" => 127,
        "deprecation_warning_count" => 1,
        "row_derived_contract_count" => 127,
        "status_counts" => %{"current" => 126, "deprecated" => 1},
        "row_derived_status_counts" => %{"current" => 126, "deprecated" => 1},
        "migration_action_counts" => %{
          "continue_current_contract" => 126,
          "plan_replacement" => 1
        },
        "row_derived_migration_action_counts" => %{
          "continue_current_contract" => 126,
          "plan_replacement" => 1
        },
        "deprecated_contracts" => "campaign_plan.v1",
        "replacement_contracts" => "campaign_strategy.v3",
        "execution_boundary" => "artifact_only_no_schema_rewrite",
        "migration_authority" => "not_granted_by_report",
        "model_limit_count" => 4
      },
      "tolerances" => %{
        "schema_version" => 0,
        "compatibility_policy_version" => 0,
        "compatible_change_rule_count" => 0,
        "breaking_change_rule_count" => 0,
        "contract_count" => 0,
        "current_contract_count" => 0,
        "deprecated_contract_count" => 0,
        "future_contract_count" => 0,
        "migration_row_count" => 0,
        "deprecation_warning_count" => 0,
        "row_derived_contract_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not automatic schema migration",
        "checks schema registry/deprecation rollups and report-only migration boundary"
      ]
    },
    "fixture.artifact.schema_migration_report.future_campaign_plan" => %{
      "id" => "fixture.artifact.schema_migration_report.future_campaign_plan",
      "model_id" => "artifact.schema_migration_report.v1",
      "reference_case" => "generated schema migration report with campaign-plan future hint",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "source" => "generated_schema_migration_future_contract_fixture",
        "contract" => "schema_migration_report.v1"
      },
      "expected" => %{
        "schema_contract" => "schema_migration_report.v1",
        "schema_version" => 1,
        "model" => "executable_schema_migration_and_deprecation_report",
        "source" => "orbital_dynamics.schema_registry",
        "status" => "review_required",
        "compatibility_policy_version" => 1,
        "compatible_change_rule_count" => 3,
        "breaking_change_rule_count" => 5,
        "contract_count" => 128,
        "current_contract_count" => 127,
        "deprecated_contract_count" => 0,
        "future_contract_count" => 1,
        "migration_row_count" => 128,
        "deprecation_warning_count" => 0,
        "row_derived_contract_count" => 128,
        "status_counts" => %{"current" => 127, "future" => 1},
        "row_derived_status_counts" => %{"current" => 127, "future" => 1},
        "migration_action_counts" => %{
          "continue_current_contract" => 127,
          "prepare_future_contract" => 1
        },
        "row_derived_migration_action_counts" => %{
          "continue_current_contract" => 127,
          "prepare_future_contract" => 1
        },
        "deprecated_contracts" => "",
        "replacement_contracts" => "",
        "execution_boundary" => "artifact_only_no_schema_rewrite",
        "migration_authority" => "not_granted_by_report",
        "model_limit_count" => 4
      },
      "tolerances" => %{
        "schema_version" => 0,
        "compatibility_policy_version" => 0,
        "compatible_change_rule_count" => 0,
        "breaking_change_rule_count" => 0,
        "contract_count" => 0,
        "current_contract_count" => 0,
        "deprecated_contract_count" => 0,
        "future_contract_count" => 0,
        "migration_row_count" => 0,
        "deprecation_warning_count" => 0,
        "row_derived_contract_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal generated artifact regression, not automatic schema migration",
        "checks future-contract rollups and report-only migration boundary"
      ]
    }
  }

  def all, do: @fixtures
end
