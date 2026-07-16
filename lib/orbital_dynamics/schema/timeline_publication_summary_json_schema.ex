defmodule OrbitalDynamics.Schema.TimelinePublicationSummaryJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema
  alias OrbitalDynamics.Schema.FocusedSourceJsonSchema

  @stable_id_fields [
    "publication_id",
    "publication_authority",
    "source_artifact_id"
  ]

  @count_fields [
    "dependency_impact_row_count",
    "timeline_diff_row_count",
    "timeline_diff_changed_count",
    "timeline_diff_review_required_count"
  ]

  @count_map_fields [
    "changed_field_counts",
    "downstream_invalidation_reason_counts"
  ]

  @stable_id_array_fields [
    "supersedes_artifact_ids",
    "downstream_product_ids",
    "invalidated_downstream_product_ids",
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
    "impacted_exclusive_with_timeline_ids",
    "changed_timeline_ids",
    "review_timeline_ids"
  ]

  @stable_id_array_map_fields [
    "timeline_ids_by_changed_field",
    "invalidated_downstream_product_ids_by_reason"
  ]

  @property_fields [
    "schema_contract",
    "model",
    "validation_level",
    "source",
    "source_artifact_type",
    "publication_sequence",
    "publication_status",
    "downstream_invalidation_status",
    "dependency_impact_status",
    "source_timeline_diff_summary",
    "source_timeline_dependency_impact_summary",
    "assumptions",
    "model_limits"
    | @stable_id_fields ++
        @count_fields ++
        @count_map_fields ++ @stable_id_array_fields ++ @stable_id_array_map_fields
  ]

  def property_field?(field) when field in @property_fields, do: true
  def property_field?(_field), do: false

  def property_from_context(
        field,
        schema_contract,
        stable_id_pattern,
        timeline_diff_summary_source_schema,
        timeline_dependency_impact_summary_source_schema,
        stable_id_array_schema,
        stable_id_array_map_schema,
        model_limits
      ) do
    deps =
      property_deps_from_context(
        schema_contract,
        stable_id_pattern,
        timeline_diff_summary_source_schema,
        timeline_dependency_impact_summary_source_schema,
        stable_id_array_schema,
        stable_id_array_map_schema,
        model_limits
      )

    property_from_context(field, deps)
  end

  def property_from_context(field, deps) when is_list(deps) do
    property(field, property_opts(field, deps))
  end

  def property_fun_from_context(
        schema_contract,
        stable_id_pattern,
        timeline_diff_summary_source_schema,
        timeline_dependency_impact_summary_source_schema,
        stable_id_array_schema,
        stable_id_array_map_schema,
        model_limits
      ) do
    deps =
      property_deps_from_context(
        schema_contract,
        stable_id_pattern,
        timeline_diff_summary_source_schema,
        timeline_dependency_impact_summary_source_schema,
        stable_id_array_schema,
        stable_id_array_map_schema,
        model_limits
      )

    property_fun_from_context(deps)
  end

  def property_fun_from_context(deps) when is_list(deps) do
    fn field -> property_from_context(field, deps) end
  end

  def property_deps_from_context(
        schema_contract,
        stable_id_pattern,
        timeline_diff_summary_source_schema,
        timeline_dependency_impact_summary_source_schema,
        stable_id_array_schema,
        stable_id_array_map_schema,
        model_limits
      ) do
    [
      schema_contract: schema_contract,
      stable_id_pattern: stable_id_pattern,
      timeline_diff_summary_source_schema: timeline_diff_summary_source_schema,
      timeline_dependency_impact_summary_source_schema:
        timeline_dependency_impact_summary_source_schema,
      stable_id_array_schema: stable_id_array_schema,
      stable_id_array_map_schema: stable_id_array_map_schema,
      model_limits: model_limits
    ]
  end

  def source_from_context(
        schema_contract,
        contract,
        stable_id_pattern,
        timeline_diff_summary_source_schema,
        timeline_dependency_impact_summary_source_schema,
        stable_id_array_schema,
        stable_id_array_map_schema,
        model_limits,
        default_property
      ) do
    deps =
      property_deps_from_context(
        schema_contract,
        stable_id_pattern,
        timeline_diff_summary_source_schema,
        timeline_dependency_impact_summary_source_schema,
        stable_id_array_schema,
        stable_id_array_map_schema,
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
    source_from_context(schema_contract, contract, deps, default_property)
  end

  def property_opts("schema_contract", deps) do
    [schema_contract: fetch_dep!(deps, :schema_contract)]
  end

  def property_opts(field, deps) when field in @stable_id_fields do
    [stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)]
  end

  def property_opts("source_timeline_diff_summary", deps) do
    [timeline_diff_summary_source_schema: fetch_dep!(deps, :timeline_diff_summary_source_schema)]
  end

  def property_opts("source_timeline_dependency_impact_summary", deps) do
    [
      timeline_dependency_impact_summary_source_schema:
        fetch_dep!(deps, :timeline_dependency_impact_summary_source_schema)
    ]
  end

  def property_opts(field, deps) when field in @stable_id_array_fields do
    [stable_id_array_schema: fetch_dep!(deps, :stable_id_array_schema)]
  end

  def property_opts(field, deps) when field in @stable_id_array_map_fields do
    [stable_id_array_map_schema: fetch_dep!(deps, :stable_id_array_map_schema)]
  end

  def property_opts("model_limits", deps) do
    [model_limits: fetch_dep!(deps, :model_limits)]
  end

  def property_opts(_field, _deps), do: []

  def property("schema_contract", opts) do
    %{"type" => "string", "const" => Keyword.fetch!(opts, :schema_contract)}
  end

  def property("model", _opts) do
    %{"type" => "string", "const" => "artifact_only_timeline_publication_summary"}
  end

  def property("validation_level", _opts) do
    %{"type" => "string", "const" => "artifact_contract"}
  end

  def property("source", _opts) do
    %{"type" => "string"}
  end

  def property(field, opts) when field in @stable_id_fields do
    %{"type" => "string", "pattern" => Keyword.fetch!(opts, :stable_id_pattern)}
  end

  def property("source_artifact_type", _opts) do
    %{"type" => "string", "minLength" => 1}
  end

  def property("publication_sequence", _opts) do
    %{"type" => "integer", "minimum" => 0}
  end

  def property("publication_status", _opts) do
    %{
      "type" => "string",
      "enum" => ["published", "published_with_downstream_invalidations", "review_required"]
    }
  end

  def property("downstream_invalidation_status", _opts) do
    %{"type" => "string", "enum" => ["clear", "invalidated"]}
  end

  def property("dependency_impact_status", _opts) do
    %{"type" => "string", "enum" => ["clear", "not_evaluated", "review_required"]}
  end

  def property("source_timeline_diff_summary", opts) do
    Keyword.fetch!(opts, :timeline_diff_summary_source_schema)
  end

  def property("source_timeline_dependency_impact_summary", opts) do
    Keyword.fetch!(opts, :timeline_dependency_impact_summary_source_schema)
  end

  def property(field, _opts) when field in @count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property(field, _opts) when field in @count_map_fields do
    CommonJsonSchema.non_negative_integer_count_map()
  end

  def property(field, opts) when field in @stable_id_array_fields do
    Keyword.fetch!(opts, :stable_id_array_schema)
  end

  def property(field, opts) when field in @stable_id_array_map_fields do
    Keyword.fetch!(opts, :stable_id_array_map_schema)
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

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      fun when is_function(fun, 0) -> fun.()
      value -> value
    end
  end
end
