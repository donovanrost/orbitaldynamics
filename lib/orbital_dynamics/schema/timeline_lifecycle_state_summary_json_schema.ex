defmodule OrbitalDynamics.Schema.TimelineLifecycleStateSummaryJsonSchema do
  @moduledoc false

  @integer_fields [
    "planned_activity_count",
    "realized_activity_count",
    "row_count",
    "recordable_count",
    "preserved_count",
    "review_required_count",
    "duplicate_timeline_identity_count",
    "invalid_activity_input_count"
  ]

  @count_map_fields [
    "transition_decision_counts",
    "required_operator_action_counts",
    "operator_action_reason_counts",
    "import_action_counts",
    "planned_status_category_counts",
    "realized_status_category_counts",
    "planned_approval_category_counts",
    "realized_approval_category_counts",
    "status_transition_category_counts",
    "approval_transition_category_counts"
  ]

  @stable_id_array_fields [
    "recordable_timeline_ids",
    "preserved_timeline_ids",
    "review_timeline_ids",
    "review_activity_ids",
    "invalid_activity_input_ids"
  ]

  @stable_id_array_map_fields [
    "review_timeline_ids_by_required_operator_action",
    "review_timeline_ids_by_operator_action_reason",
    "review_timeline_ids_by_status_transition_category",
    "review_timeline_ids_by_approval_transition_category"
  ]

  def property_field?(field)
      when field in [
             "rows",
             "review_rows",
             "model",
             "validation_level",
             "model_limits",
             "source"
           ],
      do: true

  def property_field?(field)
      when field in @integer_fields or field in @count_map_fields or
             field in @stable_id_array_fields or field in @stable_id_array_map_fields,
      do: true

  def property_field?(_field), do: false

  def property_opts(field, deps) when field in ["rows", "review_rows"] do
    [row_schema: fetch_dep!(deps, :row_schema)]
  end

  def property_opts("model_limits", deps) do
    [model_limits: fetch_dep!(deps, :model_limits)]
  end

  def property_opts(field, deps) when field in @count_map_fields do
    [count_map_schema: fetch_dep!(deps, :count_map_schema)]
  end

  def property_opts(field, deps)
      when field in @stable_id_array_fields or field in @stable_id_array_map_fields do
    [stable_id_array_schema: fetch_dep!(deps, :stable_id_array_schema)]
  end

  def property_opts(_field, _deps), do: []

  def property_from_context(
        field,
        row_schema,
        model_limits,
        count_map_schema,
        stable_id_array_schema
      ) do
    property(
      field,
      property_opts(
        field,
        row_schema: row_schema,
        model_limits: model_limits,
        count_map_schema: count_map_schema,
        stable_id_array_schema: stable_id_array_schema
      )
    )
  end

  def property_fun_from_context(
        row_schema,
        model_limits,
        count_map_schema,
        stable_id_array_schema
      ) do
    fn field ->
      property_from_context(
        field,
        row_schema,
        model_limits,
        count_map_schema,
        stable_id_array_schema
      )
    end
  end

  def property(field, opts) when field in ["rows", "review_rows"] do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :row_schema)}
  end

  def property("model", _opts) do
    %{"type" => "string", "const" => "artifact_only_timeline_lifecycle_state_summary"}
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

  def property("source", _opts) do
    %{"type" => "string"}
  end

  def property(field, _opts) when field in @integer_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property(field, opts) when field in @count_map_fields do
    Keyword.fetch!(opts, :count_map_schema)
  end

  def property(field, opts) when field in @stable_id_array_fields do
    Keyword.fetch!(opts, :stable_id_array_schema)
  end

  def property(field, opts) when field in @stable_id_array_map_fields do
    %{
      "type" => "object",
      "additionalProperties" => Keyword.fetch!(opts, :stable_id_array_schema)
    }
  end

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      fun when is_function(fun, 0) -> fun.()
      value -> value
    end
  end
end
