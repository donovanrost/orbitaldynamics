defmodule OrbitalDynamics.Validation.ArtifactObservations.PlanDelta do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    timeline_identity = get_in(artifact, ["source_activity_context", "timeline_identity"]) || %{}

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "activity_id" => Map.get(artifact, "activity_id"),
      "activity_type" => Map.get(artifact, "activity_type"),
      "status" => Map.get(artifact, "status"),
      "reason" => Map.get(artifact, "reason"),
      "repair_action" => Map.get(artifact, "repair_action"),
      "requires_approval" => Map.get(artifact, "requires_approval"),
      "planned_type" => get_in(artifact, ["planned", "type"]),
      "planned_scenario_id" => get_in(artifact, ["planned", "scenario_id"]),
      "planned_source_window_id" => get_in(artifact, ["planned", "source_window_id"]),
      "planned_starts_at_s" => get_in(artifact, ["planned", "starts_at_s"]),
      "planned_ends_at_s" => get_in(artifact, ["planned", "ends_at_s"]),
      "realized_status" => get_in(artifact, ["realized", "status"]),
      "realized_reason" => get_in(artifact, ["realized", "reason"]),
      "source_timeline_id" => Map.get(artifact, "source_timeline_id"),
      "source_context_window_id" =>
        get_in(artifact, ["source_activity_context", "source_window_id"]),
      "timeline_identity_field_count" => map_size(timeline_identity),
      "timeline_identity_activity_id" => Map.get(timeline_identity, "activity_id")
    }
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {to_string(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: value
end
