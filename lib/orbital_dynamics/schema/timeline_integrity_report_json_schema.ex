defmodule OrbitalDynamics.Schema.TimelineIntegrityReportJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @count_fields [
    "activity_count",
    "valid_activity_count",
    "invalid_activity_input_count",
    "timeline_integrity_review_count",
    "timeline_integrity_issue_count",
    "dependency_issue_count",
    "exclusivity_issue_count"
  ]

  @count_map_fields [
    "timeline_integrity_issue_type_counts",
    "required_operator_action_counts",
    "operator_action_reason_counts"
  ]

  @stable_id_array_fields [
    "review_activity_ids",
    "review_timeline_ids",
    "dependency_review_activity_ids",
    "dependency_review_timeline_ids",
    "exclusivity_review_activity_ids",
    "exclusivity_review_timeline_ids",
    "invalid_activity_input_ids",
    "missing_dependency_activity_ids",
    "missing_dependency_timeline_ids",
    "self_dependency_activity_ids",
    "self_dependency_timeline_ids",
    "duplicate_dependency_activity_ids",
    "duplicate_dependency_timeline_ids",
    "duplicate_exclusivity_activity_ids",
    "duplicate_exclusivity_timeline_ids",
    "dependency_cycle_activity_ids",
    "dependency_cycle_timeline_ids",
    "dependency_order_violation_activity_ids",
    "dependency_order_violation_timeline_ids",
    "exclusivity_violation_activity_ids",
    "exclusivity_violation_timeline_ids"
  ]

  @stable_id_array_map_fields [
    "review_activity_ids_by_issue_type",
    "review_timeline_ids_by_issue_type",
    "review_activity_ids_by_required_operator_action",
    "review_timeline_ids_by_required_operator_action",
    "review_activity_ids_by_operator_action_reason",
    "review_timeline_ids_by_operator_action_reason"
  ]

  @property_fields [
    "schema_contract",
    "model",
    "validation_level",
    "source",
    "timeline_integrity_status",
    "timeline_integrity_issue_types",
    "rows",
    "assumptions",
    "model_limits",
    "id",
    "provenance"
    | @count_fields ++ @count_map_fields ++ @stable_id_array_fields ++ @stable_id_array_map_fields
  ]

  def property_field?(field) when field in @property_fields, do: true
  def property_field?(_field), do: false

  def property_from_context(
        field,
        row_schema,
        schema_contract,
        stable_id_pattern,
        timeline_integrity_issue_types,
        stable_id_array_schema,
        stable_id_array_map_schema,
        model_limits
      ) do
    deps = [
      row_schema: row_schema,
      schema_contract: schema_contract,
      stable_id_pattern: stable_id_pattern,
      timeline_integrity_issue_types: timeline_integrity_issue_types,
      stable_id_array_schema: stable_id_array_schema,
      stable_id_array_map_schema: stable_id_array_map_schema,
      model_limits: model_limits
    ]

    property(field, property_opts(field, deps))
  end

  def property_fun_from_context(
        row_schema,
        schema_contract,
        stable_id_pattern,
        timeline_integrity_issue_types,
        stable_id_array_schema,
        stable_id_array_map_schema,
        model_limits
      ) do
    fn field ->
      property_from_context(
        field,
        row_schema,
        schema_contract,
        stable_id_pattern,
        timeline_integrity_issue_types,
        stable_id_array_schema,
        stable_id_array_map_schema,
        model_limits
      )
    end
  end

  def property_fun_from_context(deps) when is_list(deps) do
    fn field ->
      property(field, property_opts(field, deps))
    end
  end

  def property_opts("rows", deps) do
    [row_schema: fetch_dep!(deps, :row_schema)]
  end

  def property_opts("id", deps) do
    [stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)]
  end

  def property_opts("schema_contract", deps) do
    [schema_contract: fetch_dep!(deps, :schema_contract)]
  end

  def property_opts("timeline_integrity_issue_types", deps) do
    [timeline_integrity_issue_types: fetch_dep!(deps, :timeline_integrity_issue_types)]
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

  def property("rows", opts) do
    %{
      "type" => "array",
      "items" => Keyword.fetch!(opts, :row_schema)
    }
  end

  def property("id", opts) do
    %{"type" => "string", "pattern" => Keyword.fetch!(opts, :stable_id_pattern)}
  end

  def property("provenance", _opts) do
    %{"type" => "object"}
  end

  def property("schema_contract", opts) do
    %{"type" => "string", "const" => Keyword.fetch!(opts, :schema_contract)}
  end

  def property("model", _opts) do
    %{"type" => "string", "const" => "artifact_only_timeline_integrity_summary"}
  end

  def property("validation_level", _opts) do
    %{"type" => "string", "const" => "artifact_contract"}
  end

  def property("source", _opts) do
    %{"type" => "string"}
  end

  def property(field, _opts) when field in @count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property(field, _opts) when field in @count_map_fields do
    CommonJsonSchema.non_negative_integer_count_map()
  end

  def property("timeline_integrity_status", _opts) do
    %{"type" => "string", "enum" => ["clear", "review_required"]}
  end

  def property("timeline_integrity_issue_types", opts) do
    %{
      "type" => "array",
      "items" => %{
        "type" => "string",
        "enum" => Keyword.fetch!(opts, :timeline_integrity_issue_types)
      }
    }
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
