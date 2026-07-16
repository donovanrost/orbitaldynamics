defmodule OrbitalDynamics.Schema.TimelineDependencyImpactSummaryJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema
  alias OrbitalDynamics.Schema.FocusedSourceJsonSchema

  @count_fields [
    "source_activity_count",
    "replacement_activity_count",
    "changed_source_activity_count",
    "changed_source_timeline_count",
    "dependent_activity_count",
    "source_dependent_activity_count",
    "replacement_dependent_activity_count"
  ]

  @stable_id_array_fields [
    "impacted_source_activity_ids",
    "impacted_source_timeline_ids",
    "dependent_activity_ids",
    "dependent_timeline_ids",
    "source_dependent_activity_ids",
    "source_dependent_timeline_ids",
    "replacement_dependent_activity_ids",
    "replacement_dependent_timeline_ids",
    "impacted_dependency_activity_ids",
    "impacted_dependency_timeline_ids",
    "impacted_exclusive_with_activity_ids",
    "impacted_exclusive_with_timeline_ids"
  ]

  @row_stable_id_fields [
    "id",
    "activity_id",
    "timeline_id"
  ]

  @row_stable_id_array_fields [
    "dependency_activity_ids",
    "dependency_timeline_ids",
    "exclusive_with_activity_ids",
    "exclusive_with_timeline_ids",
    "impacted_dependency_activity_ids",
    "impacted_dependency_timeline_ids",
    "impacted_exclusive_with_activity_ids",
    "impacted_exclusive_with_timeline_ids"
  ]

  @row_string_fields [
    "activity_type",
    "status",
    "approval_status"
  ]

  @property_fields [
    "schema_contract",
    "model",
    "validation_level",
    "source",
    "dependency_impact_status",
    "dependency_impact_rows",
    "assumptions",
    "model_limits"
    | @count_fields ++ @stable_id_array_fields
  ]

  def property_field?(field) when field in @property_fields, do: true
  def property_field?(_field), do: false

  def property_from_context(
        field,
        schema_contract,
        stable_id_array_schema,
        row_schema,
        model_limits
      ) do
    deps =
      property_deps_from_context(
        schema_contract,
        stable_id_array_schema,
        row_schema,
        model_limits
      )

    property_from_context(field, deps)
  end

  def property_from_context(field, deps) when is_list(deps) do
    property(field, property_opts(field, deps))
  end

  def property_fun_from_context(
        schema_contract,
        stable_id_array_schema,
        row_schema,
        model_limits
      ) do
    deps =
      property_deps_from_context(
        schema_contract,
        stable_id_array_schema,
        row_schema,
        model_limits
      )

    property_fun_from_context(deps)
  end

  def property_fun_from_context(deps) when is_list(deps) do
    fn field -> property_from_context(field, deps) end
  end

  def property_deps_from_context(
        schema_contract,
        stable_id_array_schema,
        row_schema,
        model_limits
      ) do
    deps = [
      schema_contract: schema_contract,
      stable_id_array_schema: stable_id_array_schema,
      row_schema: row_schema,
      model_limits: model_limits
    ]

    deps
  end

  def source_from_context(
        schema_contract,
        contract,
        stable_id_array_schema,
        row_schema,
        model_limits,
        default_property
      ) do
    deps =
      property_deps_from_context(
        schema_contract,
        stable_id_array_schema,
        row_schema,
        model_limits
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
    row_schema = fn -> row_from_context(deps) end

    source_deps = Keyword.put(deps, :row_schema, row_schema)
    source_from_context(schema_contract, contract, source_deps, default_property)
  end

  def property_opts("schema_contract", deps) do
    [schema_contract: fetch_dep!(deps, :schema_contract)]
  end

  def property_opts(field, deps) when field in @stable_id_array_fields do
    [stable_id_array_schema: fetch_dep!(deps, :stable_id_array_schema)]
  end

  def property_opts("dependency_impact_rows", deps) do
    [row_schema: fetch_dep!(deps, :row_schema)]
  end

  def property_opts("model_limits", deps) do
    [model_limits: fetch_dep!(deps, :model_limits)]
  end

  def property_opts(_field, _deps), do: []

  def property("schema_contract", opts) do
    %{"type" => "string", "const" => Keyword.fetch!(opts, :schema_contract)}
  end

  def property("model", _opts) do
    %{"type" => "string", "const" => "artifact_only_timeline_dependency_impact_summary"}
  end

  def property("validation_level", _opts) do
    %{"type" => "string", "const" => "artifact_contract"}
  end

  def property("source", _opts) do
    %{"type" => "string", "const" => "timeline_diff_report.v1"}
  end

  def property(field, _opts) when field in @count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property("dependency_impact_status", _opts) do
    %{"type" => "string", "enum" => ["clear", "review_required"]}
  end

  def property(field, opts) when field in @stable_id_array_fields do
    Keyword.fetch!(opts, :stable_id_array_schema)
  end

  def property("dependency_impact_rows", opts) do
    %{
      "type" => "array",
      "items" => Keyword.fetch!(opts, :row_schema)
    }
  end

  def property("assumptions", _opts) do
    %{"type" => "object", "additionalProperties" => true}
  end

  def property("model_limits", opts) do
    model_limits = Keyword.fetch!(opts, :model_limits)

    %{
      "type" => "array",
      "const" => model_limits,
      "items" => %{"type" => "string", "enum" => model_limits}
    }
  end

  def row_from_context(stable_id_pattern, stable_id_array_schema, required_operator_actions) do
    row(
      stable_id_pattern: stable_id_pattern,
      stable_id_array_schema: stable_id_array_schema,
      required_operator_actions: required_operator_actions
    )
  end

  def row_from_context(deps) when is_list(deps) do
    row(
      stable_id_pattern: fetch_dep!(deps, :stable_id_pattern),
      stable_id_array_schema: fetch_dep!(deps, :stable_id_array_schema),
      required_operator_actions: fetch_dep!(deps, :required_operator_actions)
    )
  end

  def row(opts) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => [
        "id",
        "scope",
        "dependency_impact_status",
        "required_operator_action",
        "operator_action_reason",
        "activity_id",
        "timeline_id",
        "activity_type"
      ],
      "properties" => row_properties(opts)
    }
  end

  defp row_properties(opts) do
    %{
      "scope" => %{"type" => "string", "enum" => ["source", "replacement"]},
      "dependency_impact_status" => %{"type" => "string", "enum" => ["review_required"]},
      "required_operator_action" => %{
        "type" => "string",
        "enum" => Keyword.fetch!(opts, :required_operator_actions)
      },
      "operator_action_reason" => %{
        "type" => "string",
        "enum" => [
          "dependency_changed_or_removed_source_activity",
          "exclusivity_changed_or_removed_source_activity",
          "dependency_and_exclusivity_changed_or_removed_source_activity"
        ]
      }
    }
    |> Map.merge(stable_id_properties(Keyword.fetch!(opts, :stable_id_pattern)))
    |> Map.merge(stable_id_array_properties(Keyword.fetch!(opts, :stable_id_array_schema)))
    |> Map.merge(CommonJsonSchema.string_properties(@row_string_fields))
  end

  defp stable_id_properties(stable_id_pattern) do
    Map.new(@row_stable_id_fields, &{&1, %{"type" => "string", "pattern" => stable_id_pattern}})
  end

  defp stable_id_array_properties(stable_id_array_schema) do
    Map.new(@row_stable_id_array_fields, &{&1, stable_id_array_schema})
  end

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      fun when is_function(fun, 0) -> fun.()
      value -> value
    end
  end
end
