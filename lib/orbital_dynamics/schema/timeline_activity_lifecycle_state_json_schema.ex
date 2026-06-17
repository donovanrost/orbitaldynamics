defmodule OrbitalDynamics.Schema.TimelineActivityLifecycleStateJsonSchema do
  @moduledoc false

  @status_state "timeline_activity_status_state.v1"
  @approval_state "timeline_activity_approval_state.v1"
  @lifecycle_state "timeline_activity_lifecycle_state.v1"

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

  def property("invalid_activity_input_reasons", opts) do
    Keyword.fetch!(opts, :string_array_schema)
  end

  def property("required_operator_actions", opts) do
    Keyword.fetch!(opts, :string_array_schema)
  end

  def property("operator_action_reasons", opts) do
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

  defp model_const(@status_state), do: "artifact_only_timeline_activity_status_state"
  defp model_const(@approval_state), do: "artifact_only_timeline_activity_approval_state"
  defp model_const(@lifecycle_state), do: "artifact_only_timeline_activity_lifecycle_state"

  defp require_contract!(contract_name, allowed_contracts, field) do
    if contract_name not in allowed_contracts do
      raise ArgumentError,
            "field #{inspect(field)} is not valid for lifecycle contract #{inspect(contract_name)}"
    end
  end
end
