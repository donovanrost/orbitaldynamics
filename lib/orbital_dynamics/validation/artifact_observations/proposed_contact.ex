defmodule OrbitalDynamics.Validation.ArtifactObservations.ProposedContact do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)

    %{
      "id" => Map.get(artifact, "id"),
      "scenario_id" => Map.get(artifact, "scenario_id"),
      "type" => Map.get(artifact, "type"),
      "direction" => Map.get(artifact, "direction"),
      "ground_station_id" => Map.get(artifact, "ground_station_id"),
      "source_window_id" => Map.get(artifact, "source_window_id"),
      "source_window_type" => get_in(artifact, ["source_window", "type"]),
      "event_detector" => get_in(artifact, ["source_window", "event_detector"]),
      "event_timing_policy" => get_in(artifact, ["source_window", "event_timing_policy"]),
      "event_time_tolerance_s" => get_in(artifact, ["source_window", "event_time_tolerance_s"]),
      "station_availability" => Map.get(artifact, "station_availability"),
      "schedule_conflict_status" => Map.get(artifact, "schedule_conflict_status"),
      "timeline_identity_activity_type" =>
        get_in(artifact, ["timeline_identity", "activity_type"]),
      "cadence_import_contract" => get_in(artifact, ["cadence_import", "schema_contract"]),
      "model_limit_count" => count(artifact, "model_limits"),
      "duration_s" =>
        numeric_delta(Map.get(artifact, "ends_at_s"), Map.get(artifact, "starts_at_s")),
      "estimated_throughput_mb" => Map.get(artifact, "estimated_throughput_mb")
    }
  end

  defp count(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> length(values)
      _value -> 0
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
