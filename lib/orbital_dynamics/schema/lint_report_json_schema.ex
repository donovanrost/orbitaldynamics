defmodule OrbitalDynamics.Schema.LintReportJsonSchema do
  @moduledoc false

  @campaign_request_count_fields ["error_count"]
  @study_manifest_count_fields ["error_count", "warning_count"]

  @campaign_request_fields [
    "schema_contract",
    "validation_mode",
    "semantic_validator",
    "lint_task",
    "type",
    "status",
    "errors",
    "request",
    "source_plan"
    | @campaign_request_count_fields
  ]

  @study_manifest_fields [
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
    "errors",
    "warnings",
    "study_id",
    "scenario_count",
    "outputs"
    | @study_manifest_count_fields
  ]

  def campaign_request_property_field?(field) when field in @campaign_request_fields, do: true
  def campaign_request_property_field?(_field), do: false

  def study_manifest_property_field?(field) when field in @study_manifest_fields, do: true
  def study_manifest_property_field?(_field), do: false

  def campaign_request_property_from_context(
        field,
        validation_issue_schema,
        sha256_schema,
        stable_id_pattern
      ) do
    campaign_request_property(field,
      validation_issue_schema: validation_issue_schema,
      sha256_schema: sha256_schema,
      stable_id_pattern: stable_id_pattern
    )
  end

  def campaign_request_property_from_context(field, deps) when is_list(deps) do
    campaign_request_property(field,
      validation_issue_schema: fetch_dep!(deps, :validation_issue_schema),
      sha256_schema: fetch_dep!(deps, :sha256_schema),
      stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)
    )
  end

  def campaign_request_property_fun_from_context(deps) when is_list(deps) do
    fn field ->
      campaign_request_property_from_context(field, deps)
    end
  end

  def campaign_request_property_fun_from_context(
        validation_issue_schema,
        sha256_schema,
        stable_id_pattern
      ) do
    deps = [
      validation_issue_schema: validation_issue_schema,
      sha256_schema: sha256_schema,
      stable_id_pattern: stable_id_pattern
    ]

    fn field ->
      campaign_request_property_from_context(field, deps)
    end
  end

  def study_manifest_property_from_context(
        field,
        schema_version,
        stable_id_pattern,
        manifest_lint_issue_schema
      ) do
    study_manifest_property(field,
      schema_version: schema_version,
      stable_id_pattern: stable_id_pattern,
      manifest_lint_issue_schema: manifest_lint_issue_schema
    )
  end

  def study_manifest_property_from_context(field, deps) when is_list(deps) do
    study_manifest_property(field,
      schema_version: fetch_dep!(deps, :schema_version),
      stable_id_pattern: fetch_dep!(deps, :stable_id_pattern),
      manifest_lint_issue_schema: fetch_dep!(deps, :manifest_lint_issue_schema)
    )
  end

  def study_manifest_property_fun_from_context(deps) when is_list(deps) do
    fn field ->
      study_manifest_property_from_context(field, deps)
    end
  end

  def study_manifest_property_fun_from_context(
        schema_version,
        stable_id_pattern,
        manifest_lint_issue_schema
      ) do
    deps = [
      schema_version: schema_version,
      stable_id_pattern: stable_id_pattern,
      manifest_lint_issue_schema: manifest_lint_issue_schema
    ]

    fn field ->
      study_manifest_property_from_context(field, deps)
    end
  end

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

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      fun when is_function(fun, 0) -> fun.()
      value -> value
    end
  end
end
