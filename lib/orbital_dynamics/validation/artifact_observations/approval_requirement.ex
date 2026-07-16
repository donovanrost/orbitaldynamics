defmodule OrbitalDynamics.Validation.ArtifactObservations.ApprovalRequirement do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    rule_matches = map_rows(artifact, "approval_rule_matches")
    escalations = map_rows(get_in(artifact, ["policy_decision"]) || %{}, "escalations")
    timeline_identity = get_in(artifact, ["activity_context", "timeline_identity"]) || %{}

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "activity_id" => Map.get(artifact, "activity_id"),
      "activity_type" => Map.get(artifact, "activity_type"),
      "action" => Map.get(artifact, "action"),
      "policy_classification" => Map.get(artifact, "policy_classification"),
      "policy_bundle_id" => Map.get(artifact, "policy_bundle_id"),
      "required_authority" => Map.get(artifact, "required_authority"),
      "requirement_type" => Map.get(artifact, "requirement_type"),
      "rule_id" => Map.get(artifact, "rule_id"),
      "approval_rule_match_count" => length(rule_matches),
      "policy_decision_classification" => get_in(artifact, ["policy_decision", "classification"]),
      "policy_decision_escalation_count" => length(escalations),
      "timeline_identity_field_count" => map_size(timeline_identity),
      "timeline_identity_activity_id" => Map.get(timeline_identity, "activity_id"),
      "ground_station_id" => get_in(artifact, ["activity_context", "ground_station_id"]),
      "direction" => get_in(artifact, ["activity_context", "direction"])
    }
  end

  defp map_rows(map, key) do
    case Map.get(map, key) do
      rows when is_list(rows) -> Enum.filter(rows, &is_map/1)
      _rows -> []
    end
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {to_string(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: value
end
