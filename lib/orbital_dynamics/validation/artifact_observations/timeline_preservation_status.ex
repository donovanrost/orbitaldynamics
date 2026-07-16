defmodule OrbitalDynamics.Validation.ArtifactObservations.TimelinePreservationStatus do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    model_limits = list_values(artifact, "model_limits")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "activity_id" => Map.get(artifact, "activity_id"),
      "activity_type" => get_in(artifact, ["timeline_identity", "activity_type"]),
      "timeline_id" => Map.get(artifact, "timeline_id"),
      "timeline_identity_activity_id" => get_in(artifact, ["timeline_identity", "activity_id"]),
      "timeline_identity_activity_type" =>
        get_in(artifact, ["timeline_identity", "activity_type"]),
      "timeline_identity_timeline_id" => get_in(artifact, ["timeline_identity", "timeline_id"]),
      "status" => Map.get(artifact, "status"),
      "approval_status" => Map.get(artifact, "approval_status"),
      "locked" => Map.get(artifact, "locked"),
      "approved" => Map.get(artifact, "approved"),
      "protection_decision" => Map.get(artifact, "protection_decision"),
      "protection_category" => Map.get(artifact, "protection_category"),
      "protection_reason" => Map.get(artifact, "protection_reason"),
      "timeline_preservation_status" => Map.get(artifact, "timeline_preservation_status"),
      "requires_preservation" => Map.get(artifact, "requires_preservation"),
      "requires_operator_review" => Map.get(artifact, "requires_operator_review"),
      "execution_boundary" => get_in(artifact, ["assumptions", "execution_boundary"]),
      "scope" => get_in(artifact, ["assumptions", "scope"]),
      "model_limit_count" => length(model_limits),
      "no_schedule_mutation" => "no_schedule_mutation" in model_limits,
      "no_command_execution" => "no_command_execution" in model_limits,
      "derived_identity_when_no_persistent_timeline_id" =>
        "derived_identity_when_no_persistent_timeline_id" in model_limits
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
