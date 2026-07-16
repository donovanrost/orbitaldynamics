defmodule OrbitalDynamics.Validation.ArtifactObservations.TimelineActivityStatusState do
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
      "planned_status" => Map.get(artifact, "planned_status"),
      "realized_status" => Map.get(artifact, "realized_status"),
      "planned_status_category" => Map.get(artifact, "planned_status_category"),
      "realized_status_category" => Map.get(artifact, "realized_status_category"),
      "transition_decision" => Map.get(artifact, "transition_decision"),
      "review_required" => Map.get(artifact, "review_required"),
      "required_operator_action" => Map.get(artifact, "required_operator_action"),
      "operator_action_reason" => Map.get(artifact, "operator_action_reason"),
      "import_action" => Map.get(artifact, "import_action"),
      "status_transition_field" => get_in(artifact, ["status_transition", "field"]),
      "status_transition_type" => get_in(artifact, ["status_transition", "transition_type"]),
      "status_transition_from" => get_in(artifact, ["status_transition", "from"]),
      "status_transition_to" => get_in(artifact, ["status_transition", "to"]),
      "status_transition_from_category" =>
        get_in(artifact, ["status_transition", "from_category"]),
      "status_transition_to_category" => get_in(artifact, ["status_transition", "to_category"]),
      "status_transition_category" =>
        get_in(artifact, ["status_transition", "transition_category"]),
      "status_transition_requires_operator_review" =>
        get_in(artifact, ["status_transition", "requires_operator_review"]),
      "status_transition_operator_action_reason" =>
        get_in(artifact, ["status_transition", "operator_action_reason"]),
      "planned_context_status" => get_in(artifact, ["planned_activity_context", "status"]),
      "planned_context_source_window_id" =>
        get_in(artifact, ["planned_activity_context", "source_window_id"]),
      "realized_context_status" => get_in(artifact, ["realized_activity_context", "status"]),
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
