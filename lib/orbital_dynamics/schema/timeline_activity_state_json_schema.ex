defmodule OrbitalDynamics.Schema.TimelineActivityStateJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @enum_count_fields [
    "status_counts",
    "feedback_kind_counts",
    "match_strategy_counts",
    "cadence_import_status_counts",
    "planned_protection_decision_counts"
  ]

  @count_map_fields [
    "realized_provider_counts",
    "realized_source_quality_counts"
  ]

  @stable_id_fields [
    "activity_id",
    "timeline_id",
    "planned_timeline_id",
    "realized_timeline_id"
  ]

  @stable_id_array_fields [
    "activity_ids",
    "review_activity_ids"
  ]

  @string_fields [
    "feedback_status",
    "planned_approval_category",
    "planned_approval_status",
    "planned_protection_category",
    "planned_protection_reason",
    "planned_status",
    "planned_status_category",
    "realized_approval_category",
    "realized_approval_status",
    "realized_status",
    "realized_status_category",
    "realized_trust_boundary_status"
  ]

  @boolean_fields [
    "review_required",
    "planned_locked",
    "realized_locked",
    "planned_executed",
    "realized_executed"
  ]

  @activity_context_fields [
    "source_activity_context",
    "realized_activity_context"
  ]

  @lifecycle_transition_fields [
    "status_transition",
    "approval_transition"
  ]

  @protection_decision_fields [
    "source_protection_decision",
    "realized_protection_decision"
  ]

  @source_string_fields [
    "state_status",
    "planned_status",
    "realized_status",
    "planned_status_category",
    "realized_status_category",
    "planned_approval_status",
    "realized_approval_status",
    "planned_approval_category",
    "realized_approval_category",
    "realized_trust_boundary_status"
  ]

  @source_boolean_fields [
    "review_required",
    "planned_locked",
    "realized_locked",
    "planned_executed",
    "realized_executed"
  ]

  @property_fields [
    "rows",
    "schema_contract",
    "model",
    "validation_level",
    "row_count",
    "realized_trust_boundaries",
    "state_status",
    "feedback_kind",
    "match_strategy",
    "planned_protection_decision",
    "timeline_identity",
    "assumptions",
    "model_limits"
    | @enum_count_fields ++
        @count_map_fields ++
        @stable_id_fields ++
        @stable_id_array_fields ++
        @string_fields ++
        @boolean_fields ++
        @activity_context_fields ++
        @lifecycle_transition_fields ++
        @protection_decision_fields
  ]

  def property_field?(field) when field in @property_fields, do: true
  def property_field?(_field), do: false

  def property_from_context(
        field,
        row_schema,
        schema_contract,
        capability,
        stable_id_pattern,
        stable_id_array_schema,
        string_array_schema,
        timeline_identity_schema,
        activity_context_schema,
        lifecycle_transition_schema,
        protection_decision_schema,
        assumptions_schema,
        model_limits
      ) do
    deps =
      property_deps_from_context(
        row_schema,
        schema_contract,
        capability,
        stable_id_pattern,
        stable_id_array_schema,
        string_array_schema,
        timeline_identity_schema,
        activity_context_schema,
        lifecycle_transition_schema,
        protection_decision_schema,
        assumptions_schema,
        model_limits
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
        row_schema,
        schema_contract,
        capability,
        stable_id_pattern,
        stable_id_array_schema,
        string_array_schema,
        timeline_identity_schema,
        activity_context_schema,
        lifecycle_transition_schema,
        protection_decision_schema,
        assumptions_schema,
        model_limits
      ) do
    deps =
      property_deps_from_context(
        row_schema,
        schema_contract,
        capability,
        stable_id_pattern,
        stable_id_array_schema,
        string_array_schema,
        timeline_identity_schema,
        activity_context_schema,
        lifecycle_transition_schema,
        protection_decision_schema,
        assumptions_schema,
        model_limits
      )

    fn field ->
      property_from_context(field, deps)
    end
  end

  def property_deps_from_context(
        row_schema,
        schema_contract,
        capability,
        stable_id_pattern,
        stable_id_array_schema,
        string_array_schema,
        timeline_identity_schema,
        activity_context_schema,
        lifecycle_transition_schema,
        protection_decision_schema,
        assumptions_schema,
        model_limits
      ) do
    [
      row_schema: row_schema,
      schema_contract: schema_contract,
      capability: capability,
      stable_id_pattern: stable_id_pattern,
      stable_id_array_schema: stable_id_array_schema,
      string_array_schema: string_array_schema,
      timeline_identity_schema: timeline_identity_schema,
      activity_context_schema: activity_context_schema,
      lifecycle_transition_schema: lifecycle_transition_schema,
      protection_decision_schema: protection_decision_schema,
      assumptions_schema: assumptions_schema,
      model_limits: model_limits
    ]
  end

  def property_opts("rows", deps) do
    [row_schema: fetch_dep!(deps, :row_schema)]
  end

  def property_opts("schema_contract", deps) do
    [schema_contract: fetch_dep!(deps, :schema_contract)]
  end

  def property_opts(field, deps) when field in @enum_count_fields do
    [capability: fetch_dep!(deps, :capability)]
  end

  def property_opts(field, deps) when field in @stable_id_fields do
    [stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)]
  end

  def property_opts(field, deps) when field in @stable_id_array_fields do
    [stable_id_array_schema: fetch_dep!(deps, :stable_id_array_schema)]
  end

  def property_opts("realized_trust_boundaries", deps) do
    [string_array_schema: fetch_dep!(deps, :string_array_schema)]
  end

  def property_opts("state_status", deps) do
    [report_statuses: fetch_dep!(deps, :capability).report_statuses]
  end

  def property_opts("feedback_kind", deps) do
    [feedback_kinds: fetch_dep!(deps, :capability).feedback_kinds]
  end

  def property_opts("match_strategy", deps) do
    [match_strategies: fetch_dep!(deps, :capability).match_strategies]
  end

  def property_opts("planned_protection_decision", deps) do
    [planned_protection_decisions: fetch_dep!(deps, :capability).planned_protection_decisions]
  end

  def property_opts("timeline_identity", deps) do
    [timeline_identity_schema: fetch_dep!(deps, :timeline_identity_schema)]
  end

  def property_opts(field, deps) when field in @activity_context_fields do
    [activity_context_schema: fetch_dep!(deps, :activity_context_schema)]
  end

  def property_opts(field, deps) when field in @lifecycle_transition_fields do
    [lifecycle_transition_schema: fetch_dep!(deps, :lifecycle_transition_schema)]
  end

  def property_opts(field, deps) when field in @protection_decision_fields do
    [protection_decision_schema: fetch_dep!(deps, :protection_decision_schema)]
  end

  def property_opts("assumptions", deps) do
    [assumptions_schema: fetch_dep!(deps, :assumptions_schema)]
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

  def property("schema_contract", opts) do
    %{"type" => "string", "const" => Keyword.fetch!(opts, :schema_contract)}
  end

  def property("model", _opts) do
    %{"type" => "string", "const" => "artifact_only_timeline_activity_state"}
  end

  def property("validation_level", _opts) do
    %{"type" => "string", "const" => "artifact_contract"}
  end

  def property("row_count", _opts) do
    %{"type" => "integer", "minimum" => 0}
  end

  def property(field, opts) when field in @enum_count_fields do
    capability = Keyword.fetch!(opts, :capability)

    field
    |> enum_count_values(capability)
    |> CommonJsonSchema.enum_count_map()
  end

  def property(field, _opts) when field in @count_map_fields do
    CommonJsonSchema.non_negative_integer_count_map()
  end

  def property(field, opts) when field in @stable_id_fields do
    %{"type" => "string", "pattern" => Keyword.fetch!(opts, :stable_id_pattern)}
  end

  def property(field, opts) when field in @stable_id_array_fields do
    Keyword.fetch!(opts, :stable_id_array_schema)
  end

  def property("realized_trust_boundaries", opts) do
    Keyword.fetch!(opts, :string_array_schema)
  end

  def property(field, _opts) when field in @boolean_fields do
    %{"type" => "boolean"}
  end

  def property("state_status", opts) do
    %{
      "type" => "string",
      "enum" => ["empty", "review_required" | Keyword.fetch!(opts, :report_statuses)]
    }
  end

  def property("feedback_kind", opts) do
    %{"type" => "string", "enum" => Keyword.fetch!(opts, :feedback_kinds)}
  end

  def property("match_strategy", opts) do
    %{"type" => "string", "enum" => Keyword.fetch!(opts, :match_strategies)}
  end

  def property(field, _opts) when field in @string_fields do
    %{"type" => "string"}
  end

  def property("planned_protection_decision", opts) do
    %{"type" => "string", "enum" => Keyword.fetch!(opts, :planned_protection_decisions)}
  end

  def property("timeline_identity", opts) do
    Keyword.fetch!(opts, :timeline_identity_schema)
  end

  def property(field, opts) when field in @activity_context_fields do
    Keyword.fetch!(opts, :activity_context_schema)
  end

  def property(field, opts) when field in @lifecycle_transition_fields do
    Keyword.fetch!(opts, :lifecycle_transition_schema)
  end

  def property(field, opts) when field in @protection_decision_fields do
    Keyword.fetch!(opts, :protection_decision_schema)
  end

  def property("assumptions", opts) do
    Keyword.fetch!(opts, :assumptions_schema)
  end

  def property("model_limits", opts) do
    model_limits = Keyword.fetch!(opts, :model_limits)

    %{
      "type" => "array",
      "const" => model_limits,
      "items" => %{"type" => "string", "enum" => model_limits}
    }
  end

  def source_from_context(
        stable_id_pattern,
        stable_id_array_schema,
        string_array_schema,
        lifecycle_transition_schema,
        protection_decision_schema
      ) do
    source(
      stable_id_pattern: stable_id_pattern,
      stable_id_array_schema: stable_id_array_schema,
      string_array_schema: string_array_schema,
      lifecycle_transition_schema: lifecycle_transition_schema,
      protection_decision_schema: protection_decision_schema
    )
  end

  def source_from_context(deps) when is_list(deps) do
    source_from_context(
      fetch_dep!(deps, :stable_id_pattern),
      fetch_dep!(deps, :stable_id_array_schema),
      fetch_dep!(deps, :string_array_schema),
      fetch_dep!(deps, :lifecycle_transition_schema),
      fetch_dep!(deps, :protection_decision_schema)
    )
  end

  def source(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)

    %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" =>
        %{
          "schema_contract" => %{"type" => "string", "const" => "timeline_activity_state.v1"},
          "model" => %{"type" => "string", "const" => "artifact_only_timeline_activity_state"},
          "validation_level" => %{"type" => "string", "const" => "artifact_contract"},
          "row_count" => %{"type" => "integer", "minimum" => 0},
          "timeline_id" => stable_id_schema(stable_id_pattern),
          "activity_id" => stable_id_schema(stable_id_pattern),
          "activity_ids" => Keyword.fetch!(opts, :stable_id_array_schema),
          "review_activity_ids" => Keyword.fetch!(opts, :stable_id_array_schema),
          "realized_provider_counts" => CommonJsonSchema.non_negative_integer_count_map(),
          "realized_source_quality_counts" => CommonJsonSchema.non_negative_integer_count_map(),
          "realized_trust_boundaries" => Keyword.fetch!(opts, :string_array_schema),
          "status_transition" => Keyword.fetch!(opts, :lifecycle_transition_schema),
          "approval_transition" => Keyword.fetch!(opts, :lifecycle_transition_schema),
          "source_protection_decision" => Keyword.fetch!(opts, :protection_decision_schema),
          "realized_protection_decision" => Keyword.fetch!(opts, :protection_decision_schema)
        }
        |> Map.merge(CommonJsonSchema.string_properties(@source_string_fields))
        |> Map.merge(CommonJsonSchema.boolean_properties(@source_boolean_fields))
    }
  end

  defp enum_count_values("status_counts", capability), do: capability.report_statuses
  defp enum_count_values("feedback_kind_counts", capability), do: capability.feedback_kinds
  defp enum_count_values("match_strategy_counts", capability), do: capability.match_strategies

  defp enum_count_values("cadence_import_status_counts", capability),
    do: capability.cadence_import_statuses

  defp enum_count_values("planned_protection_decision_counts", capability),
    do: capability.planned_protection_decisions

  defp stable_id_schema(stable_id_pattern) do
    %{"type" => "string", "pattern" => stable_id_pattern}
  end

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      fun when is_function(fun, 0) -> fun.()
      value -> value
    end
  end
end
