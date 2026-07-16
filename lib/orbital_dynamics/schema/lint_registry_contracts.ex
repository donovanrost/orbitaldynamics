defmodule OrbitalDynamics.Schema.LintRegistryContracts do
  @moduledoc false

  def contracts do
    %{
      "campaign_request_lint.v1" => %{
        "schema_contract" => "campaign_request_lint.v1",
        "artifact_family" => "campaign_request_lint",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "validation_mode",
          "semantic_validator",
          "lint_task",
          "type",
          "status",
          "error_count",
          "errors",
          "request"
        ],
        "optional_fields" => ["source_plan"],
        "nested_contracts" => []
      },
      "study_manifest_lint.v1" => %{
        "schema_contract" => "study_manifest_lint.v1",
        "artifact_family" => "study_manifest_lint",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "schema_version",
          "schema_id",
          "manifest_schema_contract",
          "manifest_schema_id",
          "validation_mode",
          "semantic_validator",
          "lint_task",
          "schema_export_command",
          "supported",
          "manifest",
          "status",
          "error_count",
          "warning_count",
          "errors",
          "warnings"
        ],
        "optional_fields" => ["study_id", "scenario_count", "outputs"],
        "nested_contracts" => []
      }
    }
  end
end
