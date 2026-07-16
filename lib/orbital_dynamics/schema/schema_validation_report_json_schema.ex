defmodule OrbitalDynamics.Schema.SchemaValidationReportJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema
  alias OrbitalDynamics.Schema.ValidationJsonSchema

  @report_count_fields [
    "error_count",
    "warning_count",
    "remediation_count"
  ]

  @batch_count_fields [
    "file_count",
    "artifact_count",
    "skipped_count",
    "error_count",
    "warning_count",
    "remediation_count"
  ]

  @report_fields [
    "schema_contract",
    "model",
    "validation_mode",
    "validated_contract",
    "status",
    "error_count",
    "warning_count",
    "errors",
    "warnings",
    "assumptions",
    "artifact_path",
    "validated_artifact_family",
    "validated_schema_version",
    "model_limits",
    "remediation_count",
    "remediation"
  ]

  @batch_fields [
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
    "reports",
    "model",
    "model_limits",
    "status_counts",
    "remediation_count"
  ]

  def property_field?(field, :report) when field in @report_fields, do: true
  def property_field?(field, :batch) when field in @batch_fields, do: true
  def property_field?(_field, _kind), do: false

  def property_from_context(field, kind, deps) when kind in [:report, :batch] and is_list(deps) do
    property(field, kind, property_opts(field, kind, deps))
  end

  def property_fun_from_context(kind, deps) when kind in [:report, :batch] and is_list(deps) do
    fn field ->
      property_from_context(field, kind, deps)
    end
  end

  def property_opts(field, kind, deps) when kind in [:report, :batch] do
    [
      schema_contract: schema_contract(kind, deps)
    ] ++ property_opts(field, deps)
  end

  def property_opts(field, deps) when field in ["errors", "warnings"] do
    [issue_schema: fetch_dep!(deps, :issue_schema)]
  end

  def property_opts("remediation", deps) do
    [remediation_schema: fetch_dep!(deps, :remediation_schema)]
  end

  def property_opts("model_limits", deps) do
    [model_limits: fetch_dep!(deps, :model_limits)]
  end

  def property_opts("reports", deps) do
    [batch_entry_schema: fetch_dep!(deps, :batch_entry_schema)]
  end

  def property_opts("skipped_artifacts", deps) do
    [skipped_artifact_schema: fetch_dep!(deps, :skipped_artifact_schema)]
  end

  def property_opts(_field, _deps), do: []

  def property("schema_contract", kind, opts) when kind in [:report, :batch] do
    schema_contract = Keyword.fetch!(opts, :schema_contract)

    %{
      "type" => "string",
      "const" => schema_contract,
      "description" => "Stable executable contract identifier"
    }
  end

  def property("model", :report, _opts) do
    %{
      "type" => "string",
      "const" => "executable_artifact_contract_validation"
    }
  end

  def property(field, :report, _opts)
      when field in [
             "artifact_path",
             "status",
             "validated_artifact_family",
             "validated_contract",
             "validation_mode"
           ] do
    %{"type" => "string"}
  end

  def property("validated_schema_version", :report, _opts) do
    %{"type" => "integer"}
  end

  def property("assumptions", :report, _opts) do
    %{"type" => "object"}
  end

  def property("errors", :report, opts) do
    issue_array(Keyword.fetch!(opts, :issue_schema))
  end

  def property("warnings", :report, opts) do
    issue_array(Keyword.fetch!(opts, :issue_schema))
  end

  def property("remediation", :report, opts) do
    %{
      "type" => "array",
      "items" => Keyword.fetch!(opts, :remediation_schema)
    }
  end

  def property(field, :report, _opts) when field in @report_count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property("model_limits", _kind, opts) do
    opts
    |> Keyword.fetch!(:model_limits)
    |> model_limits()
  end

  def property("model", :batch, _opts) do
    %{
      "type" => "string",
      "const" => "executable_artifact_contract_batch_validation"
    }
  end

  def property(field, :batch, _opts) when field in ["input_dir", "status", "validation_mode"] do
    %{"type" => "string"}
  end

  def property(field, :batch, _opts) when field in @batch_count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property("status_counts", :batch, _opts) do
    CommonJsonSchema.enum_count_map(["pass", "fail"])
  end

  def property("reports", :batch, opts) do
    %{
      "type" => "array",
      "items" => Keyword.fetch!(opts, :batch_entry_schema)
    }
  end

  def property("skipped_artifacts", :batch, opts) do
    %{
      "type" => "array",
      "items" => Keyword.fetch!(opts, :skipped_artifact_schema)
    }
  end

  def model_limits(model_limits) do
    ValidationJsonSchema.model_limits(model_limits)
  end

  def batch_entry(report_schema) do
    ValidationJsonSchema.batch_entry(report_schema)
  end

  def skipped_artifact do
    ValidationJsonSchema.skipped_artifact()
  end

  defp issue_array(issue_schema) do
    %{
      "type" => "array",
      "items" => issue_schema
    }
  end

  defp schema_contract(kind, deps) do
    deps
    |> Keyword.fetch!(:schema_contract)
    |> case do
      fun when is_function(fun, 1) -> fun.(kind)
      value -> value
    end
  end

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      fun when is_function(fun, 0) -> fun.()
      value -> value
    end
  end
end
