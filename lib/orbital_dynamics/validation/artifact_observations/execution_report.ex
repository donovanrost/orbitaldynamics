defmodule OrbitalDynamics.Validation.ArtifactObservations.ExecutionReport do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    failed_scenarios = map_rows(artifact, "failed_scenarios")
    supervisor_nodes = list_values(artifact, "task_supervisor_nodes")
    node_distribution = Map.get(artifact, "node_distribution", %{})

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "status" => Map.get(artifact, "status"),
      "study_id" => Map.get(artifact, "study_id"),
      "run_id" => Map.get(artifact, "run_id"),
      "backend" => Map.get(artifact, "backend"),
      "execution_mode" => Map.get(artifact, "execution_mode"),
      "scenario_count" => Map.get(artifact, "scenario_count"),
      "completed_scenario_count" => Map.get(artifact, "completed_scenario_count"),
      "failed_scenario_count" => Map.get(artifact, "failed_scenario_count"),
      "event_result_count" => Map.get(artifact, "event_result_count"),
      "task_chunk_size" => Map.get(artifact, "task_chunk_size"),
      "effective_task_concurrency" => Map.get(artifact, "effective_task_concurrency"),
      "timeout" => Map.get(artifact, "timeout"),
      "failed_scenario_row_count" => length(failed_scenarios),
      "first_failed_scenario_id" => first_map_value(failed_scenarios, "scenario_id"),
      "first_failed_scenario_stage" => first_map_value(failed_scenarios, "stage"),
      "first_failed_scenario_resumability" => first_map_value(failed_scenarios, "resumability"),
      "first_failed_scenario_retry_recommendation" =>
        first_map_value(failed_scenarios, "retry_recommendation"),
      "node_distribution_counts" => node_distribution,
      "node_distribution_total" =>
        node_distribution
        |> Map.values()
        |> Enum.filter(&is_number/1)
        |> Enum.sum(),
      "task_supervisor_node_count" => length(supervisor_nodes),
      "execution_plan_distribution_mode" =>
        get_in(artifact, ["execution_plan", "distribution_mode"]),
      "execution_plan_task_batch_count" =>
        get_in(artifact, ["execution_plan", "task_batch_count"]),
      "execution_plan_wave_count" => get_in(artifact, ["execution_plan", "wave_count"]),
      "execution_plan_supervisor_count" =>
        get_in(artifact, ["execution_plan", "supervisor_count"]),
      "execution_plan_batch_propagation" =>
        get_in(artifact, ["execution_plan", "batch_propagation"]),
      "adaptive_chunking_policy" =>
        get_in(artifact, ["execution_plan", "adaptive_chunking", "policy"]),
      "adaptive_chunking_reason" =>
        get_in(artifact, ["execution_plan", "adaptive_chunking", "reason"]),
      "backend_acceptance_tier" =>
        get_in(artifact, [
          "assumptions",
          "backend_selection_policy",
          "backend_acceptance_evidence",
          "tier"
        ]),
      "reference_backend" =>
        get_in(artifact, ["assumptions", "backend_selection_policy", "reference_backend"]),
      "requires_benchmark_artifact" =>
        get_in(artifact, [
          "assumptions",
          "backend_selection_policy",
          "requires_benchmark_artifact"
        ]),
      "requires_reference_match" =>
        get_in(artifact, ["assumptions", "backend_selection_policy", "requires_reference_match"]),
      "failure_isolation" => get_in(artifact, ["assumptions", "failure_isolation"]),
      "model_limit_count" => count(artifact, "model_limits")
    }
  end

  defp count(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> length(values)
      _value -> 0
    end
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
