defmodule OrbitalDynamics.Validation.ArtifactObservations.ResourceStateTrace do
  @moduledoc false

  alias OrbitalDynamics.ResourceStateTrace

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    rows = map_rows(artifact, "trace_rows")
    first_row = List.first(rows) || %{}
    final_state = map_value(artifact, "final_state")
    limit_evidence = map_value(first_row, "limit_evidence")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "id" => Map.get(artifact, "id"),
      "model" => Map.get(artifact, "model"),
      "spacecraft_id" => Map.get(artifact, "spacecraft_id"),
      "status" => Map.get(artifact, "status"),
      "input_activity_count" => Map.get(artifact, "input_activity_count"),
      "applied_activity_count" => Map.get(artifact, "applied_activity_count"),
      "ignored_activity_count" => Map.get(artifact, "ignored_activity_count"),
      "invalid_activity_count" => Map.get(artifact, "invalid_activity_count"),
      "violation_count" => Map.get(artifact, "violation_count"),
      "violation_type_order" => artifact |> Map.get("violation_types", []) |> Enum.join("|"),
      "trace_row_count" => length(rows),
      "first_activity_id" => Map.get(first_row, "activity_id"),
      "first_state_status" => Map.get(first_row, "state_status"),
      "final_battery_energy_remaining_wh" => Map.get(final_state, "battery_energy_remaining_wh"),
      "final_recorder_used_mb" => Map.get(final_state, "recorder_used_mb"),
      "battery_depletion_wh" => Map.get(limit_evidence, "battery_depletion_wh"),
      "recorder_overflow_mb" => Map.get(limit_evidence, "recorder_overflow_mb"),
      "source" => get_in(artifact, ["provenance", "source"]),
      "identity_matches_content" => identity_matches_content?(artifact),
      "model_limit_count" => count(artifact, "model_limits")
    }
  end

  defp identity_matches_content?(artifact) do
    core = Map.delete(artifact, "id")
    Map.get(artifact, "id") == ResourceStateTrace.artifact_id(core)
  end

  defp count(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> length(values)
      _value -> 0
    end
  end

  defp map_rows(map, key) do
    case Map.get(map, key) do
      rows when is_list(rows) -> Enum.filter(rows, &is_map/1)
      _rows -> []
    end
  end

  defp map_value(map, key) do
    case Map.get(map, key) do
      value when is_map(value) -> value
      _value -> %{}
    end
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {to_string(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: value
end
