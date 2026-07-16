defmodule OrbitalDynamics.Validation.ArtifactObservations.TimelineActivityLifecycleState do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    required_operator_actions = list_values(artifact, "required_operator_actions")
    operator_action_reasons = list_values(artifact, "operator_action_reasons")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "validation_level" => Map.get(artifact, "validation_level"),
      "activity_id" => Map.get(artifact, "activity_id"),
      "planned_activity_id" => Map.get(artifact, "planned_activity_id"),
      "realized_activity_id" => Map.get(artifact, "realized_activity_id"),
      "timeline_id" => Map.get(artifact, "timeline_id"),
      "planned_timeline_id" => Map.get(artifact, "planned_timeline_id"),
      "realized_timeline_id" => Map.get(artifact, "realized_timeline_id"),
      "planned_status" => Map.get(artifact, "planned_status"),
      "realized_status" => Map.get(artifact, "realized_status"),
      "planned_status_category" => Map.get(artifact, "planned_status_category"),
      "realized_status_category" => Map.get(artifact, "realized_status_category"),
      "planned_approval_status" => Map.get(artifact, "planned_approval_status"),
      "realized_approval_status" => Map.get(artifact, "realized_approval_status"),
      "planned_approval_category" => Map.get(artifact, "planned_approval_category"),
      "realized_approval_category" => Map.get(artifact, "realized_approval_category"),
      "planned_locked" => Map.get(artifact, "planned_locked"),
      "realized_locked" => Map.get(artifact, "realized_locked"),
      "planned_executed" => Map.get(artifact, "planned_executed"),
      "realized_executed" => Map.get(artifact, "realized_executed"),
      "status_transition_decision" => Map.get(artifact, "status_transition_decision"),
      "approval_transition_decision" => Map.get(artifact, "approval_transition_decision"),
      "transition_decision" => Map.get(artifact, "transition_decision"),
      "review_required" => Map.get(artifact, "review_required"),
      "required_operator_action" => Map.get(artifact, "required_operator_action"),
      "required_operator_action_count" => length(required_operator_actions),
      "required_operator_action_keys" => Enum.join(required_operator_actions, "|"),
      "operator_action_reason_count" => length(operator_action_reasons),
      "operator_action_reason_keys" => Enum.join(operator_action_reasons, "|"),
      "import_action" => Map.get(artifact, "import_action"),
      "status_transition_category" =>
        get_in(artifact, ["status_transition", "transition_category"]),
      "status_transition_operator_action_reason" =>
        get_in(artifact, ["status_transition", "operator_action_reason"]),
      "approval_transition_category" =>
        get_in(artifact, ["approval_transition", "transition_category"]),
      "approval_transition_operator_action_reason" =>
        get_in(artifact, ["approval_transition", "operator_action_reason"]),
      "planned_protection_decision" =>
        get_in(artifact, ["planned_protection_decision", "protection_decision"]),
      "planned_protection_category" =>
        get_in(artifact, ["planned_protection_decision", "protection_category"]),
      "planned_protection_reason" => get_in(artifact, ["planned_protection_decision", "reason"]),
      "realized_protection_decision" =>
        get_in(artifact, ["realized_protection_decision", "protection_decision"]),
      "realized_protection_category" =>
        get_in(artifact, ["realized_protection_decision", "protection_category"]),
      "realized_protection_reason" =>
        get_in(artifact, ["realized_protection_decision", "reason"]),
      "artifact_only" => get_in(artifact, ["assumptions", "artifact_only"]),
      "no_schedule_mutation" => get_in(artifact, ["assumptions", "no_schedule_mutation"]),
      "no_operator_authority_grant" =>
        get_in(artifact, ["assumptions", "no_operator_authority_grant"]),
      "no_cadence_import" => get_in(artifact, ["assumptions", "no_cadence_import"]),
      "no_command_execution" => get_in(artifact, ["assumptions", "no_command_execution"])
    }
  end

  defp list_values(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> values
      _values -> []
    end
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), stringify_keys(value)}
      {key, value} when is_binary(key) -> {key, stringify_keys(value)}
      {key, value} -> {key, stringify_keys(value)}
    end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: value
end
