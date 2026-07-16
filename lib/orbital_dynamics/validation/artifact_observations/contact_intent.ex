defmodule OrbitalDynamics.Validation.ArtifactObservations.ContactIntent do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    model_limits = list_values(artifact, "model_limits")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "id" => Map.get(artifact, "id"),
      "activity_type" => Map.get(artifact, "activity_type"),
      "scenario_id" => Map.get(artifact, "scenario_id"),
      "ground_station_id" => Map.get(artifact, "ground_station_id"),
      "direction" => Map.get(artifact, "direction"),
      "source_window_id" => Map.get(artifact, "source_window_id"),
      "starts_at_s" => Map.get(artifact, "starts_at_s"),
      "ends_at_s" => Map.get(artifact, "ends_at_s"),
      "duration_s" =>
        numeric_delta(Map.get(artifact, "ends_at_s"), Map.get(artifact, "starts_at_s")),
      "estimated_throughput_mb" => Map.get(artifact, "estimated_throughput_mb"),
      "station_availability" => Map.get(artifact, "station_availability"),
      "schedule_conflict_status" => Map.get(artifact, "schedule_conflict_status"),
      "approval_status" => Map.get(artifact, "approval_status"),
      "approval_requirement_count" => count(artifact, "approval_requirements"),
      "approval_rule_match_count" => count(artifact, "approval_rule_matches"),
      "policy_decision_classification" => get_in(artifact, ["policy_decision", "classification"]),
      "policy_bundle_id" => get_in(artifact, ["policy_decision", "policy_bundle_id"]),
      "cadence_import_external_id" => get_in(artifact, ["cadence_import", "external_id"]),
      "cadence_import_activity_type" => get_in(artifact, ["cadence_import", "activity_type"]),
      "no_provider_reservation" => "no_provider_reservation" in model_limits,
      "no_schedule_mutation" => "no_schedule_mutation" in model_limits,
      "no_command_execution" => "no_command_execution" in model_limits,
      "model_limit_count" => length(model_limits)
    }
  end

  defp count(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> length(values)
      _value -> 0
    end
  end

  defp list_values(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> values
      _values -> []
    end
  end

  defp numeric_delta(left, right) when is_number(left) and is_number(right), do: left - right
  defp numeric_delta(_left, _right), do: nil

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {to_string(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: value
end
