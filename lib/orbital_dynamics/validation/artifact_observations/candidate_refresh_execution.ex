defmodule OrbitalDynamics.Validation.ArtifactObservations.CandidateRefreshExecution do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    counts = map_value(artifact, "counts")
    evidence = map_value(artifact, "evidence")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "bundle_id" => Map.get(artifact, "bundle_id"),
      "execution_mode" => Map.get(artifact, "execution_mode"),
      "policy_fingerprint" => Map.get(artifact, "policy_fingerprint"),
      "refresh_id" => Map.get(artifact, "refresh_id"),
      "study_id" => Map.get(artifact, "study_id"),
      "snapshot_id" => Map.get(artifact, "snapshot_id"),
      "spacecraft_id" => Map.get(artifact, "spacecraft_id"),
      "scenario_id" => Map.get(artifact, "scenario_id"),
      "ground_station_id" => Map.get(artifact, "ground_station_id"),
      "trajectory_sample_count" => Map.get(counts, "trajectory_sample_count"),
      "access_window_count" => Map.get(counts, "access_window_count"),
      "eclipse_interval_count" => Map.get(counts, "eclipse_interval_count"),
      "candidate_activity_count" => Map.get(counts, "candidate_activity_count"),
      "downlink_candidate_count" => Map.get(counts, "downlink_candidate_count"),
      "access_windows_sha256" => Map.get(evidence, "access_windows_sha256"),
      "eclipse_intervals_sha256" => Map.get(evidence, "eclipse_intervals_sha256"),
      "candidate_source_windows_sha256" => Map.get(evidence, "candidate_source_windows_sha256"),
      "propagation_max_step_s" => get_in(artifact, ["policies", "propagation", "max_step_s"]),
      "access_boundary_refinement" =>
        get_in(artifact, ["policies", "access", "boundary_refinement"]),
      "external_validation_case_id" => get_in(artifact, ["external_validation", "case_id"]),
      "external_validation_status" => get_in(artifact, ["external_validation", "status"]),
      "model_limit_count" => count(artifact, "model_limits")
    }
  end

  defp count(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> length(values)
      _value -> 0
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
