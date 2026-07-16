defmodule OrbitalDynamics.Schema.TimelineDiffSummaryJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema
  alias OrbitalDynamics.Schema.FocusedSourceJsonSchema

  @count_fields [
    "source_activity_count",
    "replacement_activity_count",
    "row_count",
    "added_count",
    "removed_count",
    "changed_count",
    "unchanged_count",
    "review_required_count",
    "duplicate_timeline_identity_count",
    "invalid_source_activity_input_count",
    "invalid_replacement_activity_input_count"
  ]

  @stable_id_array_fields [
    "added_timeline_ids",
    "removed_timeline_ids",
    "changed_timeline_ids",
    "unchanged_timeline_ids",
    "duplicate_timeline_identity_ids",
    "invalid_source_activity_input_ids",
    "invalid_replacement_activity_input_ids",
    "review_timeline_ids"
  ]

  @stable_id_array_map_fields [
    "review_timeline_ids_by_required_operator_action",
    "review_timeline_ids_by_status_transition_category",
    "review_timeline_ids_by_approval_transition_category",
    "timeline_ids_by_changed_field"
  ]

  @enum_count_map_fields [
    "diff_status_counts",
    "transition_decision_counts",
    "required_operator_action_counts",
    "status_transition_category_counts",
    "approval_transition_category_counts"
  ]

  def property_field?(field)
      when field in [
             "schema_contract",
             "model",
             "validation_level",
             "source_artifact_type",
             "source",
             "review_rows",
             "changed_field_counts",
             "assumptions",
             "model_limits"
           ],
      do: true

  def property_field?(field)
      when field in @count_fields or field in @stable_id_array_fields or
             field in @stable_id_array_map_fields or field in @enum_count_map_fields,
      do: true

  def property_field?(_field), do: false

  def property_opts("model_limits", deps) do
    [model_limits: fetch_dep!(deps, :model_limits)]
  end

  def property_opts("review_rows", deps) do
    [row_schema: fetch_dep!(deps, :row_schema)]
  end

  def property_opts(field, deps) when field in @enum_count_map_fields do
    [capability: fetch_dep!(deps, :capability)]
  end

  def property_opts(field, deps)
      when field in @stable_id_array_fields or field in @stable_id_array_map_fields do
    [stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)]
  end

  def property_opts(_field, _deps), do: []

  def property_from_context(field, deps) when is_list(deps) do
    property(field, property_opts(field, deps))
  end

  def property_fun_from_context(deps) when is_list(deps) do
    fn field -> property_from_context(field, deps) end
  end

  def property_deps_from_context(model_limits, row_schema, capability, stable_id_pattern) do
    [
      model_limits: model_limits,
      row_schema: row_schema,
      capability: capability,
      stable_id_pattern: stable_id_pattern
    ]
  end

  def source_from_context(
        schema_contract,
        contract,
        model_limits,
        row_schema,
        capability,
        stable_id_pattern,
        default_property
      ) do
    deps = property_deps_from_context(model_limits, row_schema, capability, stable_id_pattern)
    source_from_context(schema_contract, contract, deps, default_property)
  end

  def source_from_context(schema_contract, contract, deps, default_property) when is_list(deps) do
    FocusedSourceJsonSchema.build(
      schema_contract,
      contract,
      &property_field?/1,
      &property_opts/2,
      &property/2,
      deps,
      default_property
    )
  end

  def summary_source_from_context(schema_contract, contract, deps, default_property) do
    source_from_context(schema_contract, contract, deps, default_property)
  end

  def property("schema_contract", _opts) do
    %{"type" => "string", "const" => "timeline_diff_summary.v1"}
  end

  def property("model", _opts) do
    %{"type" => "string", "const" => "artifact_only_timeline_diff_summary"}
  end

  def property("validation_level", _opts) do
    %{"type" => "string", "const" => "artifact_contract"}
  end

  def property("source_artifact_type", _opts) do
    %{"type" => "string", "const" => "timeline_diff_report.v1"}
  end

  def property("source", _opts), do: %{"type" => "string"}

  def property("review_rows", opts) do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :row_schema)}
  end

  def property(field, _opts) when field in @count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property(field, opts)
      when field in @enum_count_map_fields do
    opts
    |> Keyword.fetch!(:capability)
    |> capability_values(field)
    |> CommonJsonSchema.enum_count_map()
  end

  def property("changed_field_counts", _opts),
    do: CommonJsonSchema.non_negative_integer_count_map()

  def property(field, opts) when field in @stable_id_array_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array()
  end

  def property(field, opts) when field in @stable_id_array_map_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array_map()
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

  defp capability_values(capability, "diff_status_counts"), do: capability.timeline_diff_statuses

  defp capability_values(capability, "transition_decision_counts"),
    do: capability.transition_decisions

  defp capability_values(capability, "required_operator_action_counts"),
    do: capability.timeline_diff_required_operator_actions

  defp capability_values(capability, "status_transition_category_counts"),
    do: capability.status_transition_categories

  defp capability_values(capability, "approval_transition_category_counts"),
    do: capability.approval_transition_categories

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      fun when is_function(fun, 0) -> fun.()
      value -> value
    end
  end
end
