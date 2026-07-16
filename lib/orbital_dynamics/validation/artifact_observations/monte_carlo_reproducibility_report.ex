defmodule OrbitalDynamics.Validation.ArtifactObservations.MonteCarloReproducibilityReport do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    generated_scenario_ids = list_values(artifact, "generated_scenario_ids")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "source" => Map.get(artifact, "source"),
      "generator" => Map.get(artifact, "generator"),
      "requested_count" => Map.get(artifact, "requested_count"),
      "generated_scenario_count" => Map.get(artifact, "generated_scenario_count"),
      "generated_scenario_id_count" => length(generated_scenario_ids),
      "first_generated_scenario_id" => List.first(generated_scenario_ids),
      "last_generated_scenario_id" => List.last(generated_scenario_ids),
      "deterministic_seed" => Map.get(artifact, "deterministic_seed"),
      "seed" => Map.get(artifact, "seed"),
      "rng" => Map.get(artifact, "rng"),
      "sampling_method" => Map.get(artifact, "sampling_method"),
      "id_prefix" => Map.get(artifact, "id_prefix"),
      "position_sigma_km" => Map.get(artifact, "position_sigma_km"),
      "velocity_sigma_km_s" => Map.get(artifact, "velocity_sigma_km_s"),
      "distribution" => get_in(artifact, ["assumptions", "distribution"]),
      "covariance_model" => get_in(artifact, ["assumptions", "covariance_model"]),
      "model_limit_count" => count(artifact, "model_limits"),
      "known_limit_count" => count(artifact, "known_limits")
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
