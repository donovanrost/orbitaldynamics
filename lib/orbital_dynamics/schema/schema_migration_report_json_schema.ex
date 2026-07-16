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

  @property_fields [
    "schema_contract",
    "schema_version",
    "model",
    "source",
    "status",
    "status_counts",
    "migration_action_counts",
    "rows",
    "assumptions",
    "model_limits"
    | @count_fields
  ]

  def property_field?(field) when field in @property_fields, do: true
  def property_field?(_field), do: false

  def property_from_context(
        field,
        schema_contract,
        schema_version,
        capability,
        row_schema,
        model_limits
      ) do
    deps = [
      schema_contract: schema_contract,
      schema_version: schema_version,
      schema_migration_statuses: capability.schema_migration_statuses,
      schema_migration_row_statuses: capability.schema_migration_row_statuses,
      row_schema: row_schema,
      model_limits: model_limits
    ]

    property(field, property_opts(field, deps))
  end

  def property_from_context(field, deps) when is_list(deps) do
    property(field, property_opts(field, deps))
  end

  def property_fun_from_context(deps) when is_list(deps) do
    fn field ->
      property_from_context(field, deps)
    end
  end

  def property_fun_from_context(
        schema_contract,
        schema_version,
        capability,
        row_schema,
        model_limits
      ) do
    deps = [
      schema_contract: schema_contract,
      schema_version: schema_version,
      schema_migration_statuses: capability.schema_migration_statuses,
      schema_migration_row_statuses: capability.schema_migration_row_statuses,
      row_schema: row_schema,
      model_limits: model_limits
    ]

    fn field ->
      property_from_context(field, deps)
    end
  end

  def property_opts("schema_contract", deps) do
    [schema_contract: fetch_dep!(deps, :schema_contract)]
  end

  def property_opts("schema_version", deps) do
    [schema_version: fetch_dep!(deps, :schema_version)]
  end

  def property_opts("status", deps) do
    [schema_migration_statuses: fetch_dep!(deps, :schema_migration_statuses)]
  end

  def property_opts("status_counts", deps) do
    [
      schema_migration_row_statuses: fetch_dep!(deps, :schema_migration_row_statuses)
    ]
  end

  def property_opts("rows", deps) do
    [row_schema: fetch_dep!(deps, :row_schema)]
  end

  def property_opts("model_limits", deps) do
    [model_limits: fetch_dep!(deps, :model_limits)]
  end

  def property_opts(_field, _deps), do: []

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

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      fun when is_function(fun, 0) -> fun.()
      value -> value
    end
  end
end
