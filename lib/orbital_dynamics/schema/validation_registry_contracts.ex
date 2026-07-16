defmodule OrbitalDynamics.Schema.ValidationRegistryContracts do
  @moduledoc false

  def contracts do
    %{
      "validation_reference_fixture_report.v1" => %{
        "schema_contract" => "validation_reference_fixture_report.v1",
        "artifact_family" => "validation_reference_fixture_report",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "status",
          "fixture_count",
          "reports"
        ],
        "optional_fields" => ["status_counts"],
        "nested_contracts" => ["validation_reference_report.v1", "validation_check.v1"]
      },
      "validation_reference_report.v1" => %{
        "schema_contract" => "validation_reference_report.v1",
        "artifact_family" => "validation_reference_report",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "fixture_id",
          "model_id",
          "validation_level",
          "status",
          "checks"
        ],
        "optional_fields" => ["status_counts"],
        "nested_contracts" => ["validation_check.v1"]
      },
      "validation_check.v1" => %{
        "schema_contract" => "validation_check.v1",
        "artifact_family" => "validation_check",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "field",
          "status",
          "expected",
          "observed",
          "tolerance"
        ],
        "optional_fields" => ["error", "max_abs_error"],
        "nested_contracts" => []
      },
      "schema_validation_report.v1" => %{
        "schema_contract" => "schema_validation_report.v1",
        "artifact_family" => "schema_validation_report",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "model",
          "validation_mode",
          "validated_contract",
          "status",
          "error_count",
          "warning_count",
          "errors",
          "warnings",
          "assumptions"
        ],
        "optional_fields" => [
          "artifact_path",
          "validated_artifact_family",
          "validated_schema_version",
          "model_limits",
          "remediation_count",
          "remediation"
        ],
        "nested_contracts" => []
      },
      "schema_validation_batch_report.v1" => %{
        "schema_contract" => "schema_validation_batch_report.v1",
        "artifact_family" => "schema_validation_batch_report",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "validation_mode",
          "input_dir",
          "file_count",
          "artifact_count",
          "skipped_count",
          "skipped_artifacts",
          "status",
          "error_count",
          "warning_count",
          "reports"
        ],
        "optional_fields" => ["model", "model_limits", "status_counts", "remediation_count"],
        "nested_contracts" => ["schema_validation_report.v1"]
      },
      "schema_migration_report.v1" => %{
        "schema_contract" => "schema_migration_report.v1",
        "artifact_family" => "schema_migration_report",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "schema_version",
          "model",
          "source",
          "status",
          "compatibility_policy_version",
          "compatible_change_rule_count",
          "breaking_change_rule_count",
          "contract_count",
          "current_contract_count",
          "deprecated_contract_count",
          "future_contract_count",
          "migration_row_count",
          "deprecation_warning_count",
          "status_counts",
          "migration_action_counts",
          "rows",
          "assumptions",
          "model_limits"
        ],
        "nested_contracts" => []
      }
    }
  end
end
