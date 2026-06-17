defmodule OrbitalDynamics.Schema.LintReportJsonSchema do
  @moduledoc false

  @campaign_request_count_fields ["error_count"]
  @study_manifest_count_fields ["error_count", "warning_count"]

  def campaign_request_property("schema_contract", _opts) do
    %{"type" => "string", "const" => "campaign_request_lint.v1"}
  end

  def campaign_request_property(field, _opts) when field in ["lint_task", "semantic_validator"] do
    %{"type" => "string"}
  end

  def campaign_request_property(field, _opts) when field in @campaign_request_count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def campaign_request_property("validation_mode", _opts) do
    %{"type" => "string", "const" => "campaign_request_lint"}
  end

  def campaign_request_property("type", _opts) do
    %{"type" => "string", "enum" => ["repair", "strategy"]}
  end

  def campaign_request_property("status", _opts) do
    %{"type" => "string", "enum" => ["pass", "fail"]}
  end

  def campaign_request_property("errors", opts) do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :validation_issue_schema)}
  end

  def campaign_request_property("request", opts) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => ["path", "sha256"],
      "properties" => %{
        "path" => %{"type" => "string"},
        "sha256" => Keyword.fetch!(opts, :sha256_schema)
      }
    }
  end

  def campaign_request_property("source_plan", opts) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => ["schema_contract", "status", "path", "sha256"],
      "properties" => %{
        "artifact_key" => %{"type" => "string"},
        "path" => %{"type" => "string"},
        "plan_id" => %{"type" => "string", "pattern" => Keyword.fetch!(opts, :stable_id_pattern)},
        "requested_path" => %{"type" => "string"},
        "schema_contract" => %{"type" => "string"},
        "sha256" => Keyword.fetch!(opts, :sha256_schema),
        "source" => %{"type" => "string"},
        "status" => %{"type" => "string", "enum" => ["pass", "fail"]}
      }
    }
  end

  def study_manifest_property("schema_contract", _opts) do
    %{"type" => "string", "const" => "study_manifest_lint.v1"}
  end

  def study_manifest_property("schema_version", opts) do
    %{
      "type" => "integer",
      "const" => Keyword.fetch!(opts, :schema_version),
      "description" => "Artifact schema version"
    }
  end

  def study_manifest_property(field, opts) when field in ["schema_id", "manifest_schema_id"] do
    %{"type" => "string", "pattern" => Keyword.fetch!(opts, :stable_id_pattern)}
  end

  def study_manifest_property("validation_mode", _opts) do
    %{"type" => "string", "const" => "study_manifest_lint"}
  end

  def study_manifest_property("manifest_schema_contract", _opts) do
    %{"type" => "string", "const" => "study_manifest.v1"}
  end

  def study_manifest_property(field, _opts) when field in @study_manifest_count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def study_manifest_property(field, _opts)
      when field in ["lint_task", "schema_export_command", "semantic_validator"] do
    %{"type" => "string"}
  end

  def study_manifest_property("status", _opts) do
    %{"type" => "string", "enum" => ["pass", "fail"]}
  end

  def study_manifest_property("study_id", _opts) do
    %{"type" => ["string", "null"]}
  end

  def study_manifest_property("scenario_count", _opts) do
    %{"type" => ["integer", "null"], "minimum" => 0}
  end

  def study_manifest_property(field, _opts) when field in ["manifest", "outputs", "supported"] do
    %{"type" => "object"}
  end

  def study_manifest_property("errors", opts) do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :manifest_lint_issue_schema)}
  end

  def study_manifest_property("warnings", opts) do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :manifest_lint_issue_schema)}
  end
end
