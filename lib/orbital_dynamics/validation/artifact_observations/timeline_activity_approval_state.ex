defmodule OrbitalDynamics.Validation.ArtifactObservations.TimelineActivityApprovalState do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)

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
      "planned_approval_status" => Map.get(artifact, "planned_approval_status"),
      "realized_approval_status" => Map.get(artifact, "realized_approval_status"),
      "planned_approval_category" => Map.get(artifact, "planned_approval_category"),
      "realized_approval_category" => Map.get(artifact, "realized_approval_category"),
      "transition_decision" => Map.get(artifact, "transition_decision"),
      "review_required" => Map.get(artifact, "review_required"),
      "required_operator_action" => Map.get(artifact, "required_operator_action"),
      "operator_action_reason" => Map.get(artifact, "operator_action_reason"),
      "import_action" => Map.get(artifact, "import_action"),
      "approval_transition_field" => get_in(artifact, ["approval_transition", "field"]),
      "approval_transition_type" => get_in(artifact, ["approval_transition", "transition_type"]),
      "approval_transition_from" => get_in(artifact, ["approval_transition", "from"]),
      "approval_transition_to" => get_in(artifact, ["approval_transition", "to"]),
      "approval_transition_from_category" =>
        get_in(artifact, ["approval_transition", "from_category"]),
      "approval_transition_to_category" =>
        get_in(artifact, ["approval_transition", "to_category"]),
      "approval_transition_category" =>
        get_in(artifact, ["approval_transition", "transition_category"]),
      "approval_transition_requires_operator_review" =>
        get_in(artifact, ["approval_transition", "requires_operator_review"]),
      "approval_transition_operator_action_reason" =>
        get_in(artifact, ["approval_transition", "operator_action_reason"]),
      "planned_context_approval_status" =>
        get_in(artifact, ["planned_activity_context", "approval_status"]),
      "planned_context_source_window_id" =>
        get_in(artifact, ["planned_activity_context", "source_window_id"]),
      "realized_context_approval_status" =>
        get_in(artifact, ["realized_activity_context", "approval_status"]),
      "artifact_only" => get_in(artifact, ["assumptions", "artifact_only"]),
      "no_schedule_mutation" => get_in(artifact, ["assumptions", "no_schedule_mutation"]),
      "no_operator_authority_grant" =>
        get_in(artifact, ["assumptions", "no_operator_authority_grant"]),
      "no_command_execution" => get_in(artifact, ["assumptions", "no_command_execution"])
    }
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
