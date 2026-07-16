defmodule OrbitalDynamics.Schema.TimelinePreservationJsonSchema do
  @moduledoc false

  @report "timeline_preservation_report.v1"
  @status "timeline_preservation_status.v1"

  @report_integer_fields [
    "activity_count",
    "mutable_activity_count",
    "preserve_activity_count",
    "review_change_activity_count",
    "preservation_sensitive_activity_count"
  ]

  @report_count_map_fields [
    "protection_decision_counts",
    "protection_category_counts",
    "protection_reason_counts"
  ]

  @report_stable_id_array_fields [
    "preserve_activity_ids",
    "preserve_timeline_ids",
    "review_change_activity_ids",
    "review_change_timeline_ids",
    "mutable_activity_ids",
    "preservation_sensitive_activity_ids",
    "preservation_sensitive_timeline_ids"
  ]

  @report_stable_id_array_map_fields [
    "activity_id_sets_by_protection_decision",
    "timeline_id_sets_by_protection_decision",
    "activity_id_sets_by_protection_category",
    "timeline_id_sets_by_protection_category",
    "activity_id_sets_by_protection_reason",
    "timeline_id_sets_by_protection_reason"
  ]

  @status_boolean_fields [
    "requires_preservation",
    "requires_operator_review",
    "locked",
    "approved",
    "invalid_activity_input"
  ]

  @status_string_fields [
    "status",
    "approval_status"
  ]

  @status_object_fields [
    "protection_decision",
    "protection_category",
    "protection_reason",
    "invalid_activity_input_reason"
  ]

  @status_stable_id_fields ["activity_id", "timeline_id"]

  @source_integer_fields [
    "activity_count",
    "mutable_activity_count",
    "preserve_activity_count",
    "review_change_activity_count",
    "preservation_sensitive_activity_count"
  ]

  @source_stable_id_array_fields [
    "preserve_activity_ids",
    "preserve_timeline_ids",
    "review_change_activity_ids",
    "review_change_timeline_ids",
    "mutable_activity_ids",
    "preservation_sensitive_activity_ids",
    "preservation_sensitive_timeline_ids"
  ]

  def property_field?(field, @report) do
    field in [
      "schema_contract",
      "model",
      "source",
      "model_limits",
      "rows",
      "timeline_preservation_status",
      "assumptions"
    ] or
      field in @report_integer_fields or
      field in @report_count_map_fields or
      field in @report_stable_id_array_fields or
      field in @report_stable_id_array_map_fields
  end

  def property_field?(field, @status) do
    field in [
      "schema_contract",
      "model",
      "model_limits",
      "timeline_preservation_status",
      "timeline_identity",
      "assumptions"
    ] or
      field in @status_boolean_fields or
      field in @status_string_fields or
      field in @status_object_fields or
      field in @status_stable_id_fields
  end

  def property_from_context(field, deps) when is_list(deps) do
    contract_name = fetch_dep!(deps, :contract_name)
    property(field, property_opts(field, contract_name, deps))
  end

  def property_from_context(
        field,
        contract_name,
        model_limits,
        count_map_schema,
        stable_id_array_schema,
        stable_id_array_map_schema,
        protection_decision_schema,
        stable_id_pattern,
        timeline_identity_schema,
        assumptions_schema
      ) do
    deps = [
      model_limits: model_limits,
      count_map_schema: count_map_schema,
      stable_id_array_schema: stable_id_array_schema,
      stable_id_array_map_schema: stable_id_array_map_schema,
      protection_decision_schema: protection_decision_schema,
      stable_id_pattern: stable_id_pattern,
      timeline_identity_schema: timeline_identity_schema,
      assumptions_schema: assumptions_schema
    ]

    property_from_context(field, Keyword.put(deps, :contract_name, contract_name))
  end

  def property_fun_from_context(deps) when is_list(deps) do
    fn field -> property_from_context(field, deps) end
  end

  def property_fun_from_context(
        contract_name,
        model_limits,
        count_map_schema,
        stable_id_array_schema,
        stable_id_array_map_schema,
        protection_decision_schema,
        stable_id_pattern,
        timeline_identity_schema,
        assumptions_schema
      ) do
    fn field ->
      property_from_context(
        field,
        contract_name: contract_name,
        model_limits: model_limits,
        count_map_schema: count_map_schema,
        stable_id_array_schema: stable_id_array_schema,
        stable_id_array_map_schema: stable_id_array_map_schema,
        protection_decision_schema: protection_decision_schema,
        stable_id_pattern: stable_id_pattern,
        timeline_identity_schema: timeline_identity_schema,
        assumptions_schema: assumptions_schema
      )
    end
  end

  def property_opts(field, contract_name, _deps)
      when field in ["schema_contract", "model", "source"] do
    [contract_name: contract_name]
  end

  def property_opts("model_limits", contract_name, deps) do
    [contract_name: contract_name, model_limits: fetch_dep!(deps, :model_limits)]
  end

  def property_opts(field, contract_name, deps) when field in @report_count_map_fields do
    [contract_name: contract_name, count_map_schema: fetch_dep!(deps, :count_map_schema)]
  end

  def property_opts(field, contract_name, deps) when field in @report_stable_id_array_fields do
    [
      contract_name: contract_name,
      stable_id_array_schema: fetch_dep!(deps, :stable_id_array_schema)
    ]
  end

  def property_opts(field, contract_name, deps)
      when field in @report_stable_id_array_map_fields do
    [
      contract_name: contract_name,
      stable_id_array_map_schema: fetch_dep!(deps, :stable_id_array_map_schema)
    ]
  end

  def property_opts("rows", contract_name, deps) do
    [
      contract_name: contract_name,
      protection_decision_schema: fetch_dep!(deps, :protection_decision_schema)
    ]
  end

  def property_opts(field, contract_name, _deps)
      when field in @report_integer_fields or field in @status_boolean_fields or
             field in @status_string_fields or field in @status_object_fields do
    [contract_name: contract_name]
  end

  def property_opts(field, contract_name, deps) when field in @status_stable_id_fields do
    [contract_name: contract_name, stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)]
  end

  def property_opts("timeline_identity", contract_name, deps) do
    [
      contract_name: contract_name,
      timeline_identity_schema: fetch_dep!(deps, :timeline_identity_schema)
    ]
  end

  def property_opts("assumptions", contract_name, deps) do
    [contract_name: contract_name, assumptions_schema: fetch_dep!(deps, :assumptions_schema)]
  end

  def property_opts(_field, _contract_name, _deps), do: []

  def property("schema_contract", opts) do
    %{"type" => "string", "const" => Keyword.fetch!(opts, :contract_name)}
  end

  def property("model", opts) do
    %{"type" => "string", "const" => model_const(Keyword.fetch!(opts, :contract_name))}
  end

  def property("source", opts) do
    require_contract!(opts, [@report], "source")
    %{"type" => "string"}
  end

  def property("model_limits", opts) do
    model_limits = Keyword.fetch!(opts, :model_limits)

    %{
      "type" => "array",
      "const" => model_limits,
      "items" => %{"type" => "string", "enum" => model_limits}
    }
  end

  def property(field, opts) when field in @report_integer_fields do
    require_contract!(opts, [@report], field)
    %{"type" => "integer", "minimum" => 0}
  end

  def property(field, opts) when field in @report_count_map_fields do
    require_contract!(opts, [@report], field)
    schema_value(opts, :count_map_schema)
  end

  def property(field, opts) when field in @report_stable_id_array_fields do
    require_contract!(opts, [@report], field)
    schema_value(opts, :stable_id_array_schema)
  end

  def property(field, opts) when field in @report_stable_id_array_map_fields do
    require_contract!(opts, [@report], field)
    schema_value(opts, :stable_id_array_map_schema)
  end

  def property("rows", opts) do
    require_contract!(opts, [@report], "rows")
    %{"type" => "array", "items" => schema_value(opts, :protection_decision_schema)}
  end

  def property("timeline_preservation_status", _opts) do
    %{"type" => "string", "enum" => ["clear", "preservation_required", "review_required"]}
  end

  def property(field, opts) when field in @status_boolean_fields do
    require_contract!(opts, [@status], field)
    %{"type" => "boolean"}
  end

  def property(field, opts) when field in @status_string_fields do
    require_contract!(opts, [@status], field)
    %{"type" => "string"}
  end

  def property(field, opts) when field in @status_object_fields do
    require_contract!(opts, [@status], field)
    %{"type" => "object"}
  end

  def property(field, opts) when field in @status_stable_id_fields do
    require_contract!(opts, [@status], field)
    %{"type" => "string", "pattern" => Keyword.fetch!(opts, :stable_id_pattern)}
  end

  def property("timeline_identity", opts) do
    require_contract!(opts, [@status], "timeline_identity")
    schema_value(opts, :timeline_identity_schema)
  end

  def property("assumptions", opts) do
    Keyword.fetch!(opts, :assumptions_schema).(Keyword.fetch!(opts, :contract_name))
  end

  def source_from_context(stable_id_pattern, stable_id_array_schema, timeline_identity_schema) do
    source(
      stable_id_pattern: stable_id_pattern,
      stable_id_array_schema: stable_id_array_schema,
      timeline_identity_schema: timeline_identity_schema
    )
  end

  def source_from_context(deps) when is_list(deps) do
    source_from_context(
      fetch_dep!(deps, :stable_id_pattern),
      fetch_dep!(deps, :stable_id_array_schema),
      fetch_dep!(deps, :timeline_identity_schema)
    )
  end

  def source(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)

    %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" =>
        %{
          "schema_contract" => %{"type" => "string"},
          "model" => %{"type" => "string"},
          "validation_level" => %{"type" => "string"},
          "source" => %{"type" => "string"},
          "activity_id" => stable_id_schema(stable_id_pattern),
          "timeline_id" => stable_id_schema(stable_id_pattern),
          "timeline_identity" => Keyword.fetch!(opts, :timeline_identity_schema),
          "activity_type" => %{"type" => "string"},
          "status" => %{"type" => "string"},
          "approval_status" => %{"type" => "string"},
          "timeline_preservation_status" => property("timeline_preservation_status", []),
          "requires_preservation" => %{"type" => "boolean"},
          "requires_operator_review" => %{"type" => "boolean"},
          "protection_decision" => %{"type" => "string"},
          "protection_category" => %{"type" => "string"},
          "protection_reason" => %{"type" => "string"},
          "reason" => %{"type" => "string"},
          "locked" => %{"type" => "boolean"},
          "approved" => %{"type" => "boolean"},
          "executed" => %{"type" => "boolean"},
          "invalid_activity_input" => %{"type" => "boolean"},
          "invalid_activity_input_reason" => %{"type" => "string"},
          "assumptions" => %{"type" => "object", "additionalProperties" => true}
        }
        |> Map.merge(integer_properties())
        |> Map.merge(stable_id_array_properties(Keyword.fetch!(opts, :stable_id_array_schema)))
    }
  end

  defp model_const(@report), do: "artifact_only_lifecycle_preservation_summary"
  defp model_const(@status), do: "artifact_only_lifecycle_preservation_status"

  defp integer_properties do
    Map.new(@source_integer_fields, &{&1, %{"type" => "integer", "minimum" => 0}})
  end

  defp stable_id_array_properties(stable_id_array_schema) do
    Map.new(@source_stable_id_array_fields, &{&1, stable_id_array_schema})
  end

  defp stable_id_schema(stable_id_pattern) do
    %{"type" => "string", "pattern" => stable_id_pattern}
  end

  defp schema_value(opts, key) do
    case Keyword.fetch!(opts, key) do
      fun when is_function(fun, 0) -> fun.()
      value -> value
    end
  end

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      fun when is_function(fun, 0) -> fun.()
      value -> value
    end
  end

  defp require_contract!(opts, allowed_contracts, field) do
    contract_name = Keyword.fetch!(opts, :contract_name)

    if contract_name not in allowed_contracts do
      raise ArgumentError,
            "field #{inspect(field)} is not valid for timeline preservation contract #{inspect(contract_name)}"
    end
  end
end
