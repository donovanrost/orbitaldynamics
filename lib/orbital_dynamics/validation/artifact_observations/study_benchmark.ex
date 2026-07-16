defmodule OrbitalDynamics.Validation.ArtifactObservations.StudyBenchmark do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    results = map_rows(artifact, "results")

    %{
      "schema_version" => Map.get(artifact, "schema_version"),
      "benchmark_mode_count" => count(get_in(artifact, ["benchmark_options"]) || %{}, "modes"),
      "repetition_count" => get_in(artifact, ["benchmark_options", "repetitions"]),
      "result_count" => length(results),
      "local_result_count" => Enum.count(results, &(Map.get(&1, "mode") == "local")),
      "distributed_result_count" => Enum.count(results, &(Map.get(&1, "mode") == "distributed")),
      "matches_baseline_count" => Enum.count(results, &(Map.get(&1, "matches_baseline") == true)),
      "failure_count_total" => sum_numeric(results, "failure_count"),
      "scenario_count_total" => sum_numeric(results, "scenario_count"),
      "trajectory_count_total" => sum_numeric(results, "trajectory_count"),
      "manifest_path" => get_in(artifact, ["manifest", "path"]),
      "manifest_sha256_length" =>
        case get_in(artifact, ["manifest", "sha256"]) do
          value when is_binary(value) -> String.length(value)
          _value -> 0
        end,
      "max_duration_ms" =>
        results
        |> Enum.map(&Map.get(&1, "duration_ms"))
        |> Enum.filter(&is_number/1)
        |> Enum.max(fn -> 0 end),
      "backend_count" =>
        results
        |> Enum.map(&Map.get(&1, "backend"))
        |> Enum.reject(&is_nil/1)
        |> Enum.uniq()
        |> length(),
      "propagator_option_count" =>
        count(get_in(artifact, ["benchmark_options"]) || %{}, "propagators"),
      "monte_carlo_count_option_count" =>
        count(get_in(artifact, ["benchmark_options"]) || %{}, "monte_carlo_counts"),
      "max_concurrency_option_count" =>
        count(get_in(artifact, ["benchmark_options"]) || %{}, "max_concurrencies"),
      "task_chunk_size_option_count" =>
        count(get_in(artifact, ["benchmark_options"]) || %{}, "task_chunk_sizes")
    }
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

  defp sum_numeric(rows, key) do
    rows
    |> Enum.map(&Map.get(&1, key))
    |> Enum.filter(&is_number/1)
    |> Enum.sum()
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
