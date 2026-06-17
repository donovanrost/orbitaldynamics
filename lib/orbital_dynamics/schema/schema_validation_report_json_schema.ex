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
end
