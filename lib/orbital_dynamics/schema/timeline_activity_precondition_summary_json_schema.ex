defmodule OrbitalDynamics.Schema.TimelineActivityPreconditionSummaryJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.FocusedSourceJsonSchema

  @count_fields [
    "blocked_precondition_count",
    "review_precondition_count"
  ]

  @string_array_fields [
    "blocked_precondition_types",
    "review_precondition_types"
  ]

  @stable_id_fields [
    "activity_id",
    "timeline_id"
  ]

  @stable_id_array_fields [
    "dependency_activity_ids",
    "dependency_timeline_ids",
    "exclusive_with_activity_ids",
    "exclusive_with_timeline_ids"
  ]

  @boolean_fields [
    "allow_overlap",
    "invalid_activity_input"
  ]

  @string_fields [
    "activity_type",
    "invalid_activity_input_reason"
  ]

  @property_fields [
    "schema_contract",
    "model",
    "validation_level",
    "model_limits",
    "precondition_status",
    "preconditions",
    "timeline_identity",
    "source_activity",
    "assumptions"
    | @count_fields ++
        @string_array_fields ++
        @stable_id_fields ++ @stable_id_array_fields ++ @boolean_fields ++ @string_fields
  ]

  def property_field?(field) when field in @property_fields, do: true
  def property_field?(_field), do: false

  def property_from_context(
        field,
        schema_contract,
        model_limits,
        precondition_statuses,
        string_array_schema,
        precondition_schema,
        stable_id_pattern,
        stable_id_array_schema,
        timeline_identity_schema
      ) do
    deps =
      property_deps_from_context(
        schema_contract,
        model_limits,
        precondition_statuses,
        string_array_schema,
        precondition_schema,
        stable_id_pattern,
        stable_id_array_schema,
        timeline_identity_schema
      )

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
        model_limits,
        precondition_statuses,
        string_array_schema,
        precondition_schema,
        stable_id_pattern,
        stable_id_array_schema,
        timeline_identity_schema
      ) do
    deps =
      property_deps_from_context(
        schema_contract,
        model_limits,
        precondition_statuses,
        string_array_schema,
        precondition_schema,
        stable_id_pattern,
        stable_id_array_schema,
        timeline_identity_schema
      )

    fn field ->
      property_from_context(field, deps)
    end
  end

  def property_deps_from_context(
        schema_contract,
        model_limits,
        precondition_statuses,
        string_array_schema,
        precondition_schema,
        stable_id_pattern,
        stable_id_array_schema,
        timeline_identity_schema
      ) do
    [
      schema_contract: schema_contract,
      model_limits: model_limits,
      precondition_statuses: precondition_statuses,
      string_array_schema: string_array_schema,
      precondition_schema: precondition_schema,
      stable_id_pattern: stable_id_pattern,
      stable_id_array_schema: stable_id_array_schema,
      timeline_identity_schema: timeline_identity_schema
    ]
  end

  def source_from_context(
        schema_contract,
        contract,
        model_limits,
        precondition_statuses,
        string_array_schema,
        precondition_schema,
        stable_id_pattern,
        stable_id_array_schema,
        timeline_identity_schema,
        default_property
      ) do
    deps =
      property_deps_from_context(
        schema_contract,
        model_limits,
        precondition_statuses,
        string_array_schema,
        precondition_schema,
        stable_id_pattern,
        stable_id_array_schema,
        timeline_identity_schema
      )

    source_from_context(schema_contract, contract, deps, default_property)
  end

  def source_from_context(schema_contract, contract, deps, default_property) when is_list(deps) do
    FocusedSourceJsonSchema.build(
      schema_contract,
      contract,
      &property_field?/1,
      &property_opts/2,
      &property/2,
      Keyword.put(deps, :schema_contract, schema_contract),
      default_property
    )
  end

  def summary_source_from_context(schema_contract, contract, deps, default_property) do
    source_from_context(schema_contract, contract, deps, default_property)
  end

  def property_opts("schema_contract", deps) do
    [schema_contract: fetch_dep!(deps, :schema_contract)]
  end

  def property_opts("model_limits", deps) do
    [model_limits: fetch_dep!(deps, :model_limits)]
  end

  def property_opts("precondition_status", deps) do
    [precondition_statuses: fetch_dep!(deps, :precondition_statuses)]
  end

  def property_opts(field, deps) when field in @string_array_fields do
    [string_array_schema: fetch_dep!(deps, :string_array_schema)]
  end

  def property_opts("preconditions", deps) do
    [precondition_schema: fetch_dep!(deps, :precondition_schema)]
  end

  def property_opts(field, deps) when field in @stable_id_fields do
    [stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)]
  end

  def property_opts(field, deps) when field in @stable_id_array_fields do
    [stable_id_array_schema: fetch_dep!(deps, :stable_id_array_schema)]
  end

  def property_opts("timeline_identity", deps) do
    [timeline_identity_schema: fetch_dep!(deps, :timeline_identity_schema)]
  end

  def property_opts(_field, _deps), do: []

  def property("schema_contract", opts) do
    %{"type" => "string", "const" => Keyword.fetch!(opts, :schema_contract)}
  end

  def property("model", _opts) do
    %{
      "type" => "string",
      "const" => "artifact_only_timeline_activity_precondition_summary"
    }
  end

  def property("validation_level", _opts) do
    %{"type" => "string", "const" => "artifact_contract"}
  end

  def property("model_limits", opts) do
    model_limits = Keyword.fetch!(opts, :model_limits)

    %{
      "type" => "array",
      "const" => model_limits,
      "items" => %{"type" => "string", "enum" => model_limits}
    }
  end

  def property("precondition_status", opts) do
    %{"type" => "string", "enum" => Keyword.fetch!(opts, :precondition_statuses)}
  end

  def property(field, _opts) when field in @count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property(field, opts) when field in @string_array_fields do
    Keyword.fetch!(opts, :string_array_schema)
  end

  def property("preconditions", opts) do
    %{
      "type" => "array",
      "items" => Keyword.fetch!(opts, :precondition_schema)
    }
  end

  def property(field, opts) when field in @stable_id_fields do
    %{"type" => "string", "pattern" => Keyword.fetch!(opts, :stable_id_pattern)}
  end

  def property(field, opts) when field in @stable_id_array_fields do
    Keyword.fetch!(opts, :stable_id_array_schema)
  end

  def property(field, _opts) when field in @boolean_fields do
    %{"type" => "boolean"}
  end

  def property(field, _opts) when field in @string_fields do
    %{"type" => "string"}
  end

  def property("timeline_identity", opts) do
    Keyword.fetch!(opts, :timeline_identity_schema)
  end

  def property("source_activity", _opts) do
    %{"type" => "object", "additionalProperties" => true}
  end

  def property("assumptions", _opts) do
    %{"type" => "object", "additionalProperties" => true}
  end

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      fun when is_function(fun, 0) -> fun.()
      value -> value
    end
  end
end
