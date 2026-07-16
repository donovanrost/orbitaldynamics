defmodule OrbitalDynamics.Schema.TimelineActivityLifecycleStateJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @status_state "timeline_activity_status_state.v1"
  @approval_state "timeline_activity_approval_state.v1"
  @lifecycle_state "timeline_activity_lifecycle_state.v1"

  @default_assumption_fields [
    "artifact_only",
    "no_schedule_mutation",
    "no_operator_authority_grant",
    "no_command_execution"
  ]

  @lifecycle_assumption_fields [
    "artifact_only",
    "no_schedule_mutation",
    "no_operator_authority_grant",
    "no_cadence_import",
    "no_command_execution"
  ]

  @status_string_fields [
    "planned_status",
    "realized_status",
    "planned_status_category",
    "realized_status_category"
  ]

  @approval_string_fields [
    "planned_approval_status",
    "realized_approval_status",
    "planned_approval_category",
    "realized_approval_category"
  ]

  @stable_id_fields [
    "activity_id",
    "planned_activity_id",
    "realized_activity_id",
    "timeline_id",
    "planned_timeline_id",
    "realized_timeline_id"
  ]

  @transition_decision_fields [
    "transition_decision",
    "status_transition_decision",
    "approval_transition_decision"
  ]

  @string_array_fields [
    "invalid_activity_input_reasons",
    "required_operator_actions",
    "operator_action_reasons"
  ]

  @boolean_fields [
    "review_required",
    "planned_locked",
    "realized_locked",
    "planned_executed",
    "realized_executed",
    "invalid_activity_input"
  ]

  @lifecycle_transition_fields [
    "status_transition",
    "approval_transition"
  ]

  @activity_context_fields [
    "planned_activity_context",
    "realized_activity_context"
  ]

  @protection_decision_fields [
    "planned_protection_decision",
    "realized_protection_decision"
  ]

  def property_field?(field)
      when field in [
             "schema_contract",
             "model",
             "model_limits",
             "validation_level",
             "operator_action_reason",
             "invalid_activity_input_count",
             "import_action",
             "assumptions"
           ],
      do: true

  def property_field?(field)
      when field in @status_string_fields or field in @approval_string_fields or
             field in @stable_id_fields or field in @transition_decision_fields or
             field in @string_array_fields or field in @boolean_fields or
             field in @lifecycle_transition_fields or field in @activity_context_fields or
             field in @protection_decision_fields,
      do: true

  def property_field?(_field), do: false

  def property_opts(field, contract_name, _deps)
      when field in ["schema_contract", "model"] or
             field in @status_string_fields or
             field in @approval_string_fields do
    [contract_name: contract_name]
  end

  def property_opts("model_limits", _contract_name, deps) do
    [model_limits: fetch_dep!(deps, :model_limits)]
  end

  def property_opts(field, _contract_name, deps) when field in @stable_id_fields do
    [stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)]
  end

  def property_opts(field, _contract_name, deps) when field in @transition_decision_fields do
    [transition_decisions: fetch_dep!(deps, :transition_decisions)]
  end

  def property_opts(field, _contract_name, deps) when field in @string_array_fields do
    [string_array_schema: fetch_dep!(deps, :string_array_schema)]
  end

  def property_opts(field, _contract_name, deps) when field in @lifecycle_transition_fields do
    [lifecycle_transition_schema: fetch_dep!(deps, :lifecycle_transition_schema)]
  end

  def property_opts(field, _contract_name, deps) when field in @protection_decision_fields do
    [protection_decision_schema: fetch_dep!(deps, :protection_decision_schema)]
  end

  def property_opts(field, _contract_name, deps) when field in @activity_context_fields do
    [activity_context_schema: fetch_dep!(deps, :activity_context_schema)]
  end

  def property_opts("assumptions", @lifecycle_state, deps) do
    [assumptions_schema: fetch_dep!(deps, :lifecycle_assumptions_schema)]
  end

  def property_opts("assumptions", _contract_name, deps) do
    [assumptions_schema: fetch_dep!(deps, :default_assumptions_schema)]
  end

  def property_opts(_field, _contract_name, _deps), do: []

  def property_from_context(field, deps) when is_list(deps) do
    contract_name = fetch_dep!(deps, :contract_name)
    property(field, property_opts(field, contract_name, deps))
  end

  def property_from_context(
        field,
        contract_name,
        model_limits,
        stable_id_pattern,
        transition_decisions,
        string_array_schema,
        lifecycle_transition_schema,
        protection_decision_schema,
        activity_context_schema,
        lifecycle_assumptions_schema,
        default_assumptions_schema
      ) do
    deps = [
      model_limits: model_limits,
      stable_id_pattern: stable_id_pattern,
      transition_decisions: transition_decisions,
      string_array_schema: string_array_schema,
      lifecycle_transition_schema: lifecycle_transition_schema,
      protection_decision_schema: protection_decision_schema,
      activity_context_schema: activity_context_schema,
      lifecycle_assumptions_schema: lifecycle_assumptions_schema,
      default_assumptions_schema: default_assumptions_schema
    ]

    property_from_context(field, Keyword.put(deps, :contract_name, contract_name))
  end

  def property_fun_from_context(deps) when is_list(deps) do
    fn field -> property_from_context(field, deps) end
  end

  def property_fun_from_context(
        contract_name,
        model_limits,
        stable_id_pattern,
        transition_decisions,
        string_array_schema,
        lifecycle_transition_schema,
        protection_decision_schema,
        activity_context_schema,
        lifecycle_assumptions_schema,
        default_assumptions_schema
      ) do
    fn field ->
      property_from_context(
        field,
        contract_name: contract_name,
        model_limits: model_limits,
        stable_id_pattern: stable_id_pattern,
        transition_decisions: transition_decisions,
        string_array_schema: string_array_schema,
        lifecycle_transition_schema: lifecycle_transition_schema,
        protection_decision_schema: protection_decision_schema,
        activity_context_schema: activity_context_schema,
        lifecycle_assumptions_schema: lifecycle_assumptions_schema,
        default_assumptions_schema: default_assumptions_schema
      )
    end
  end

  def property("schema_contract", opts) do
    %{"type" => "string", "const" => Keyword.fetch!(opts, :contract_name)}
  end

  def property("model", opts) do
    %{"type" => "string", "const" => model_const(Keyword.fetch!(opts, :contract_name))}
  end

  def property("model_limits", opts) do
    model_limits = Keyword.fetch!(opts, :model_limits)

    %{
      "type" => "array",
      "const" => model_limits,
      "items" => %{"type" => "string", "enum" => model_limits}
    }
  end

  def property("validation_level", _opts) do
    %{"type" => "string", "const" => "artifact_contract"}
  end

  def property("operator_action_reason", _opts) do
    %{"type" => "string"}
  end

  def property(field, opts) when field in @status_string_fields do
    opts
    |> Keyword.fetch!(:contract_name)
    |> require_contract!([@status_state, @lifecycle_state], field)

    %{"type" => "string"}
  end

  def property(field, opts) when field in @approval_string_fields do
    opts
    |> Keyword.fetch!(:contract_name)
    |> require_contract!([@approval_state, @lifecycle_state], field)

    %{"type" => "string"}
  end

  def property(field, opts) when field in @stable_id_fields do
    %{"type" => "string", "pattern" => Keyword.fetch!(opts, :stable_id_pattern)}
  end

  def property(field, opts) when field in @transition_decision_fields do
    %{"type" => "string", "enum" => Keyword.fetch!(opts, :transition_decisions)}
  end

  def property(field, _opts) when field in @boolean_fields do
    %{"type" => "boolean"}
  end

  def property("invalid_activity_input_count", _opts) do
    %{"type" => "integer", "minimum" => 0}
  end

  def property(field, opts) when field in @string_array_fields do
    Keyword.fetch!(opts, :string_array_schema)
  end

  def property("import_action", _opts) do
    %{"type" => "string"}
  end

  def property(field, opts) when field in @lifecycle_transition_fields do
    Keyword.fetch!(opts, :lifecycle_transition_schema)
  end

  def property(field, opts) when field in @protection_decision_fields do
    Keyword.fetch!(opts, :protection_decision_schema)
  end

  def property(field, opts) when field in @activity_context_fields do
    Keyword.fetch!(opts, :activity_context_schema)
  end

  def property("assumptions", opts) do
    Keyword.fetch!(opts, :assumptions_schema)
  end

  def default_assumptions do
    CommonJsonSchema.boolean_const_assumptions(@default_assumption_fields)
  end

  def lifecycle_assumptions do
    CommonJsonSchema.boolean_const_assumptions(@lifecycle_assumption_fields)
  end

  def row_from_context(
        model_limits,
        stable_id_pattern,
        stable_id_array_schema,
        transition_decisions,
        string_array_schema,
        lifecycle_transition_schema,
        activity_context_schema,
        protection_decision_schema
      ) do
    row(
      model_limits: model_limits,
      stable_id_pattern: stable_id_pattern,
      stable_id_array_schema: stable_id_array_schema,
      transition_decisions: transition_decisions,
      string_array_schema: string_array_schema,
      lifecycle_transition_schema: lifecycle_transition_schema,
      activity_context_schema: activity_context_schema,
      protection_decision_schema: protection_decision_schema
    )
  end

  def row_from_context(deps) when is_list(deps) do
    row(
      model_limits: fetch_dep!(deps, :model_limits),
      stable_id_pattern: fetch_dep!(deps, :stable_id_pattern),
      stable_id_array_schema: fetch_dep!(deps, :stable_id_array_schema),
      transition_decisions: fetch_dep!(deps, :transition_decisions),
      string_array_schema: fetch_dep!(deps, :string_array_schema),
      lifecycle_transition_schema: fetch_dep!(deps, :lifecycle_transition_schema),
      activity_context_schema: fetch_dep!(deps, :activity_context_schema),
      protection_decision_schema: fetch_dep!(deps, :protection_decision_schema)
    )
  end

  def row(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)

    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => [
        "rank",
        "timeline_id",
        "transition_decision",
        "review_required",
        "required_operator_action",
        "import_action"
      ],
      "properties" => %{
        "schema_contract" => %{
          "type" => "string",
          "const" => @lifecycle_state
        },
        "model" => %{
          "type" => "string",
          "const" => "artifact_only_timeline_activity_lifecycle_state"
        },
        "model_limits" => %{
          "type" => "array",
          "const" => Keyword.fetch!(opts, :model_limits),
          "items" => %{
            "type" => "string",
            "enum" => Keyword.fetch!(opts, :model_limits)
          }
        },
        "validation_level" => %{"type" => "string", "const" => "artifact_contract"},
        "rank" => %{"type" => "integer", "minimum" => 1},
        "timeline_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "activity_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "planned_activity_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "realized_activity_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "planned_timeline_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "realized_timeline_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "planned_activity_ids" => Keyword.fetch!(opts, :stable_id_array_schema),
        "realized_activity_ids" => Keyword.fetch!(opts, :stable_id_array_schema),
        "transition_decision" => %{
          "type" => "string",
          "enum" => Keyword.fetch!(opts, :transition_decisions)
        },
        "status_transition_decision" => %{
          "type" => "string",
          "enum" => Keyword.fetch!(opts, :transition_decisions)
        },
        "approval_transition_decision" => %{
          "type" => "string",
          "enum" => Keyword.fetch!(opts, :transition_decisions)
        },
        "review_required" => %{"type" => "boolean"},
        "required_operator_action" => %{"type" => "string"},
        "required_operator_actions" => Keyword.fetch!(opts, :string_array_schema),
        "operator_action_reasons" => Keyword.fetch!(opts, :string_array_schema),
        "import_action" => %{"type" => "string"},
        "status_transition" => Keyword.fetch!(opts, :lifecycle_transition_schema),
        "approval_transition" => Keyword.fetch!(opts, :lifecycle_transition_schema),
        "planned_status" => %{"type" => "string"},
        "realized_status" => %{"type" => "string"},
        "planned_status_category" => %{"type" => "string"},
        "realized_status_category" => %{"type" => "string"},
        "planned_approval_status" => %{"type" => "string"},
        "realized_approval_status" => %{"type" => "string"},
        "planned_approval_category" => %{"type" => "string"},
        "realized_approval_category" => %{"type" => "string"},
        "planned_locked" => %{"type" => "boolean"},
        "realized_locked" => %{"type" => "boolean"},
        "planned_executed" => %{"type" => "boolean"},
        "realized_executed" => %{"type" => "boolean"},
        "timeline_identity_collision" => %{"type" => "boolean"},
        "planned_duplicate_activity_count" => %{"type" => "integer", "minimum" => 0},
        "realized_duplicate_activity_count" => %{"type" => "integer", "minimum" => 0},
        "invalid_activity_input" => %{"type" => "boolean"},
        "invalid_activity_input_count" => %{"type" => "integer", "minimum" => 0},
        "invalid_activity_input_reasons" => Keyword.fetch!(opts, :string_array_schema),
        "planned_activity_context" => Keyword.fetch!(opts, :activity_context_schema),
        "realized_activity_context" => Keyword.fetch!(opts, :activity_context_schema),
        "planned_protection_decision" => Keyword.fetch!(opts, :protection_decision_schema),
        "realized_protection_decision" => Keyword.fetch!(opts, :protection_decision_schema),
        "assumptions" => %{"type" => "object", "additionalProperties" => true}
      }
    }
  end

  def source_from_context(
        stable_id_pattern,
        stable_id_array_schema,
        transition_decisions,
        string_array_schema,
        lifecycle_transition_schema,
        activity_context_schema,
        protection_decision_schema
      ) do
    source(
      stable_id_pattern: stable_id_pattern,
      stable_id_array_schema: stable_id_array_schema,
      transition_decisions: transition_decisions,
      string_array_schema: string_array_schema,
      lifecycle_transition_schema: lifecycle_transition_schema,
      activity_context_schema: activity_context_schema,
      protection_decision_schema: protection_decision_schema
    )
  end

  def source_from_context(deps) when is_list(deps) do
    source_from_context(
      fetch_dep!(deps, :stable_id_pattern),
      fetch_dep!(deps, :stable_id_array_schema),
      fetch_dep!(deps, :transition_decisions),
      fetch_dep!(deps, :string_array_schema),
      fetch_dep!(deps, :lifecycle_transition_schema),
      fetch_dep!(deps, :activity_context_schema),
      fetch_dep!(deps, :protection_decision_schema)
    )
  end

  def source(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)

    %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" => %{
        "schema_contract" => %{"type" => "string"},
        "timeline_id" => stable_id_schema(stable_id_pattern),
        "activity_id" => stable_id_schema(stable_id_pattern),
        "planned_activity_id" => stable_id_schema(stable_id_pattern),
        "realized_activity_id" => stable_id_schema(stable_id_pattern),
        "planned_activity_ids" => Keyword.fetch!(opts, :stable_id_array_schema),
        "realized_activity_ids" => Keyword.fetch!(opts, :stable_id_array_schema),
        "transition_decision" => transition_decision_schema(opts),
        "status_transition_decision" => transition_decision_schema(opts),
        "approval_transition_decision" => transition_decision_schema(opts),
        "state_status" => %{"type" => "string"},
        "review_required" => %{"type" => "boolean"},
        "required_operator_action" => %{"type" => "string"},
        "required_operator_actions" => Keyword.fetch!(opts, :string_array_schema),
        "operator_action_reasons" => Keyword.fetch!(opts, :string_array_schema),
        "import_action" => %{"type" => "string"},
        "status_transition" => Keyword.fetch!(opts, :lifecycle_transition_schema),
        "approval_transition" => Keyword.fetch!(opts, :lifecycle_transition_schema),
        "planned_activity_context" => Keyword.fetch!(opts, :activity_context_schema),
        "realized_activity_context" => Keyword.fetch!(opts, :activity_context_schema),
        "planned_protection_decision" => Keyword.fetch!(opts, :protection_decision_schema),
        "realized_protection_decision" => Keyword.fetch!(opts, :protection_decision_schema),
        "planned_locked" => %{"type" => "boolean"},
        "realized_locked" => %{"type" => "boolean"},
        "planned_executed" => %{"type" => "boolean"},
        "realized_executed" => %{"type" => "boolean"},
        "timeline_identity_collision" => %{"type" => "boolean"},
        "invalid_activity_input" => %{"type" => "boolean"},
        "invalid_activity_input_count" => %{"type" => "integer", "minimum" => 0},
        "invalid_activity_input_reasons" => Keyword.fetch!(opts, :string_array_schema)
      }
    }
  end

  defp model_const(@status_state), do: "artifact_only_timeline_activity_status_state"
  defp model_const(@approval_state), do: "artifact_only_timeline_activity_approval_state"
  defp model_const(@lifecycle_state), do: "artifact_only_timeline_activity_lifecycle_state"

  defp transition_decision_schema(opts) do
    %{"type" => "string", "enum" => Keyword.fetch!(opts, :transition_decisions)}
  end

  defp stable_id_schema(stable_id_pattern) do
    %{"type" => "string", "pattern" => stable_id_pattern}
  end

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      fun when is_function(fun, 0) -> fun.()
      value -> value
    end
  end

  defp require_contract!(contract_name, allowed_contracts, field) do
    if contract_name not in allowed_contracts do
      raise ArgumentError,
            "field #{inspect(field)} is not valid for lifecycle contract #{inspect(contract_name)}"
    end
  end
end
