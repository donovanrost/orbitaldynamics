defmodule OrbitalDynamics.Validation.ArtifactObservations.PolicyDecision do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    rule_matches = map_rows(artifact, "rule_matches")
    escalations = map_rows(artifact, "escalations")
    model_limits = list_values(artifact, "model_limits")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "classification" => Map.get(artifact, "classification"),
      "policy_bundle_id" => Map.get(artifact, "policy_bundle_id"),
      "approval_requirement_count" => Map.get(artifact, "approval_requirement_count"),
      "risk_count" => Map.get(artifact, "risk_count"),
      "rule_match_count" => length(rule_matches),
      "escalation_count" => length(escalations),
      "first_rule_id" => first_map_value(rule_matches, "rule_id"),
      "first_required_authority" => first_map_value(rule_matches, "required_authority"),
      "first_escalation_queue" => first_map_value(escalations, "escalation_queue"),
      "first_escalation_role" => first_map_value(escalations, "escalation_role"),
      "first_escalation_sla_s" => first_map_value(escalations, "sla_s"),
      "boundary" => get_in(artifact, ["assumptions", "boundary"]),
      "workflow_execution" => get_in(artifact, ["assumptions", "workflow_execution"]),
      "no_command_execution" => "no_command_execution" in model_limits,
      "no_schedule_mutation" => "no_schedule_mutation" in model_limits,
      "model_limit_count" => length(model_limits)
    }
  end

  defp first_map_value(rows, key) when is_list(rows) do
    rows
    |> Enum.find(&is_map/1)
    |> then(&if(is_map(&1), do: Map.get(&1, key)))
  end

  defp list_values(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> values
      _value -> []
    end
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
