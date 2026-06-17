defmodule OrbitalDynamics.Schema.SchemaMigrationReportJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema
  alias OrbitalDynamics.Schema.ValidationJsonSchema

  @count_fields [
    "compatibility_policy_version",
    "compatible_change_rule_count",
    "breaking_change_rule_count",
    "contract_count",
    "current_contract_count",
    "deprecated_contract_count",
    "future_contract_count",
    "migration_row_count",
    "deprecation_warning_count"
  ]

  def property("schema_contract", opts) do
    schema_contract = Keyword.fetch!(opts, :schema_contract)

    %{
      "type" => "string",
      "const" => schema_contract,
      "description" => "Stable executable contract identifier"
    }
  end

  def property("schema_version", opts) do
    %{
      "type" => "integer",
      "const" => Keyword.fetch!(opts, :schema_version),
      "description" => "Artifact schema version"
    }
  end

  def property("assumptions", _opts) do
    %{"type" => "object"}
  end

  def property("source", _opts) do
    %{"type" => "string", "const" => "orbital_dynamics.schema_registry"}
  end

  def property("model", _opts) do
    %{
      "type" => "string",
      "const" => "executable_schema_migration_and_deprecation_report"
    }
  end

  def property("status", opts) do
    %{"type" => "string", "enum" => Keyword.fetch!(opts, :schema_migration_statuses)}
  end

  def property("status_counts", opts) do
    opts
    |> Keyword.fetch!(:schema_migration_row_statuses)
    |> CommonJsonSchema.enum_count_map()
  end

  def property("migration_action_counts", _opts) do
    CommonJsonSchema.non_negative_integer_count_map()
  end

  def property("rows", opts) do
    %{
      "type" => "array",
      "items" => Keyword.fetch!(opts, :row_schema)
    }
  end

  def property("model_limits", opts) do
    model_limits = Keyword.fetch!(opts, :model_limits)

    %{
      "type" => "array",
      "const" => model_limits,
      "items" => %{"type" => "string", "enum" => model_limits}
    }
  end

  def property(field, _opts) when field in @count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def row do
    ValidationJsonSchema.migration_row()
  end
end
