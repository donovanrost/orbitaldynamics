defmodule OrbitalDynamics.Validation.ArtifactObservations.CandidateActivity do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    score_terms = Map.get(artifact, "score_terms", %{})

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "id" => Map.get(artifact, "id"),
      "type" => Map.get(artifact, "type"),
      "scenario_id" => Map.get(artifact, "scenario_id"),
      "spacecraft_id" => Map.get(artifact, "spacecraft_id"),
      "target_id" => Map.get(artifact, "target_id"),
      "source_window_id" => Map.get(artifact, "source_window_id"),
      "source_window_type" => get_in(artifact, ["source_window", "type"]),
      "starts_at_s" => Map.get(artifact, "starts_at_s"),
      "ends_at_s" => Map.get(artifact, "ends_at_s"),
      "duration_s" => Map.get(artifact, "duration_s"),
      "score" => Map.get(artifact, "score"),
      "score_term_count" => map_size(score_terms),
      "target_priority" => Map.get(artifact, "target_priority"),
      "required_downlink_mb" => Map.get(artifact, "required_downlink_mb"),
      "required_observations" => Map.get(artifact, "required_observations"),
      "product_count" => count(artifact, "product_ids"),
      "observation_objective_count" => Map.get(artifact, "observation_objective_count"),
      "collection_latency_objective_count" =>
        Map.get(artifact, "collection_latency_objective_count"),
      "target_priority_objective_count" => count(artifact, "target_priority_objective_ids"),
      "lighting_condition" => Map.get(artifact, "lighting_condition"),
      "lighting_condition_model" => Map.get(artifact, "lighting_condition_model"),
      "eclipse_overlap_s" => Map.get(artifact, "eclipse_overlap_s"),
      "event_timing_policy" => get_in(artifact, ["source_window", "event_timing_policy"]),
      "event_time_tolerance_s" => get_in(artifact, ["source_window", "event_time_tolerance_s"]),
      "max_sample_step_s" => get_in(artifact, ["source_window", "max_sample_step_s"])
    }
  end

  defp count(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> length(values)
      _value -> 0
    end
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {to_string(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: value
end
