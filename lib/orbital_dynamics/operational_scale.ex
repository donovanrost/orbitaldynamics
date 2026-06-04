defmodule OrbitalDynamics.OperationalScale do
  @moduledoc """
  Explicit operational scale targets by planning maturity level.

  These are product and benchmarking targets, not runtime guarantees. They give
  benchmark reports, result payload metrics, and planner development a shared
  yardstick for deciding when local concurrency, distributed execution, or
  artifact-size work matters.
  """

  @targets %{
    "v1_campaign" => %{
      "schema_contract" => "operational_scale_target.v1",
      "maturity_level" => "v1_campaign",
      "description" => "reviewable fixed-horizon campaign planning artifact",
      "spacecraft_count" => 4,
      "planning_horizon_s" => 86_400.0,
      "output_cadence_s" => 60.0,
      "candidate_window_count" => 500,
      "scenario_count" => 200,
      "acceptable_local_runtime_s" => 30.0,
      "artifact_size_limit_mb" => 25.0,
      "replanning_cadence_s" => 3_600.0,
      "distributed_execution_threshold_scenarios" => 2_000,
      "known_limits" => [
        "target does not imply flight certification",
        "local runtime depends on hardware and selected outputs",
        "candidate counts depend on ground network and target catalog density"
      ]
    },
    "v2_repair" => %{
      "schema_contract" => "operational_scale_target.v1",
      "maturity_level" => "v2_repair",
      "description" => "rolling repair over accepted planning state and refreshed candidates",
      "spacecraft_count" => 8,
      "planning_horizon_s" => 172_800.0,
      "output_cadence_s" => 60.0,
      "candidate_window_count" => 1_500,
      "scenario_count" => 1_000,
      "acceptable_local_runtime_s" => 60.0,
      "artifact_size_limit_mb" => 75.0,
      "replanning_cadence_s" => 1_800.0,
      "distributed_execution_threshold_scenarios" => 5_000,
      "known_limits" => [
        "repair target assumes candidate refresh is already scoped to remaining horizon",
        "resource and station models remain planning-grade",
        "operator review latency is not included in runtime target"
      ]
    },
    "v3_strategy" => %{
      "schema_contract" => "operational_scale_target.v1",
      "maturity_level" => "v3_strategy",
      "description" => "branch comparison with refreshed candidates and policy artifacts",
      "spacecraft_count" => 12,
      "planning_horizon_s" => 604_800.0,
      "output_cadence_s" => 120.0,
      "candidate_window_count" => 5_000,
      "scenario_count" => 5_000,
      "acceptable_local_runtime_s" => 180.0,
      "artifact_size_limit_mb" => 250.0,
      "replanning_cadence_s" => 3_600.0,
      "distributed_execution_threshold_scenarios" => 10_000,
      "known_limits" => [
        "strategy target assumes branch count is deliberately bounded",
        "distributed execution should be benchmarked before speedup claims",
        "artifact review ergonomics may require smaller operator-facing extracts"
      ]
    }
  }

  @metric_keys [
    "spacecraft_count",
    "planning_horizon_s",
    "candidate_window_count",
    "scenario_count",
    "local_runtime_s",
    "artifact_size_mb"
  ]

  @doc """
  Returns all operational scale targets.
  """
  def targets, do: @targets

  @doc """
  Fetches one target by maturity level.
  """
  def target(level) when is_atom(level), do: target(Atom.to_string(level))
  def target(level) when is_binary(level), do: Map.fetch(@targets, level)

  @doc """
  Compares observed metrics with one operational scale target.

  Returns a report with `status` set to `"within_target"` or `"over_target"`.
  Missing metrics are ignored so callers can compare partial benchmark evidence.
  """
  def compare(level, observed) when is_map(observed) do
    with {:ok, target} <- target(level) do
      observed = stringify_keys(observed)

      rows =
        @metric_keys
        |> Enum.flat_map(&metric_row(&1, target, observed))

      status =
        if Enum.any?(rows, &(&1["status"] == "over_target")) do
          "over_target"
        else
          "within_target"
        end

      {:ok,
       %{
         "schema_contract" => "operational_scale_comparison.v1",
         "maturity_level" => target["maturity_level"],
         "status" => status,
         "rows" => rows
       }}
    end
  end

  def compare(_level, _observed), do: {:error, {:invalid_field, "observed"}}

  @doc """
  Compares a benchmark summary group with one operational scale target.

  Benchmark groups do not always carry every target metric, so this extracts the
  shared evidence surface: scenario count plus local runtime when the execution
  mode is a local/single-node mode. Distributed or remote rows still contribute
  scenario-count and distribution-threshold evidence without being treated as a
  local-runtime measurement.
  """
  def compare_benchmark_group(level, group) when is_map(group) do
    with {:ok, target} <- target(level),
         {:ok, comparison} <- compare(level, benchmark_observation(group)) do
      {:ok,
       comparison
       |> Map.put("source", benchmark_source(group))
       |> Map.put("distribution_guidance", distribution_guidance(target, group))}
    end
  end

  def compare_benchmark_group(_level, _group), do: {:error, {:invalid_field, "group"}}

  @doc """
  Compares a result artifact's execution and payload metrics with one scale target.

  This uses the artifact's `execution_report.v1` and `result_payload_metrics.v1`
  rows when present. The comparison is review evidence for long-running runs,
  not a resumability guarantee.
  """
  def compare_result_artifact(level, artifact) when is_map(artifact) do
    artifact = stringify_keys(artifact)

    with {:ok, target} <- target(level),
         {:ok, comparison} <- compare(level, result_artifact_observation(artifact)) do
      execution_report = Map.get(artifact, "execution_report", %{})

      {:ok,
       comparison
       |> Map.put("source", result_artifact_source(artifact))
       |> Map.put(
         "distribution_guidance",
         distribution_guidance(target, distribution_guidance_group(execution_report))
       )}
    end
  end

  def compare_result_artifact(_level, _artifact), do: {:error, {:invalid_field, "artifact"}}

  @doc """
  Compares a study benchmark trend summary with one operational scale target.

  The result separates latest scale-target status from descriptive runtime
  trends. A group can still be within the scale target while reporting a
  regression against its earlier benchmark point.
  """
  def compare_benchmark_trend(level, trend_summary) when is_map(trend_summary) do
    with {:ok, target} <- target(level) do
      trend_summary = stringify_keys(trend_summary)

      rows =
        trend_summary
        |> Map.get("groups", [])
        |> Enum.filter(&is_map/1)
        |> Enum.map(&trend_comparison_row(target, &1))

      status =
        cond do
          Enum.any?(rows, &(&1["scale_status"] == "over_target")) -> "over_target"
          Enum.any?(rows, &(&1["trend_status"] == "regressed")) -> "trend_regressed"
          true -> "within_target"
        end

      {:ok,
       %{
         "schema_contract" => "operational_scale_trend_comparison.v1",
         "maturity_level" => target["maturity_level"],
         "status" => status,
         "artifact_count" => Map.get(trend_summary, "artifact_count"),
         "group_count" => length(rows),
         "rows" => rows
       }}
    end
  end

  def compare_benchmark_trend(_level, _trend_summary),
    do: {:error, {:invalid_field, "trend_summary"}}

  @doc """
  Extracts operational-scale observations from a benchmark summary group.
  """
  def benchmark_observation(group) when is_map(group) do
    group = stringify_keys(group)
    mode = Map.get(group, "mode")

    %{}
    |> maybe_put_number("scenario_count", scenario_count(group))
    |> maybe_put_local_runtime(mode, runtime_ms(group))
  end

  defp metric_row("local_runtime_s", target, observed) do
    comparison_row(
      "local_runtime_s",
      target["acceptable_local_runtime_s"],
      Map.get(observed, "local_runtime_s")
    )
  end

  defp metric_row("artifact_size_mb", target, observed) do
    comparison_row(
      "artifact_size_mb",
      target["artifact_size_limit_mb"],
      Map.get(observed, "artifact_size_mb")
    )
  end

  defp metric_row(metric, target, observed) do
    comparison_row(metric, target[metric], Map.get(observed, metric))
  end

  defp comparison_row(_metric, _target_value, nil), do: []

  defp comparison_row(metric, target_value, observed_value)
       when is_number(target_value) and is_number(observed_value) do
    [
      %{
        "metric" => metric,
        "target" => target_value,
        "observed" => observed_value * 1.0,
        "status" => if(observed_value <= target_value, do: "within_target", else: "over_target")
      }
    ]
  end

  defp comparison_row(metric, _target_value, _observed_value) do
    [
      %{
        "metric" => metric,
        "status" => "not_evaluated",
        "reason" => "observed value is not numeric"
      }
    ]
  end

  defp benchmark_source(group) do
    group = stringify_keys(group)

    %{
      "mode" => Map.get(group, "mode"),
      "propagator" => Map.get(group, "propagator"),
      "task_chunk_size" => Map.get(group, "task_chunk_size"),
      "max_concurrency" => Map.get(group, "max_concurrency"),
      "node_count" => Map.get(group, "node_count")
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp trend_comparison_row(target, group) do
    observation = %{
      "mode" => Map.get(group, "mode"),
      "scenario_count" => Map.get(group, "monte_carlo_count"),
      "median_duration_ms" => Map.get(group, "latest_median_duration_ms")
    }

    {:ok, comparison} = compare(target["maturity_level"], benchmark_observation(observation))

    %{
      "mode" => Map.get(group, "mode"),
      "propagator" => Map.get(group, "propagator"),
      "monte_carlo_count" => Map.get(group, "monte_carlo_count"),
      "task_chunk_size" => Map.get(group, "task_chunk_size"),
      "max_concurrency" => Map.get(group, "max_concurrency"),
      "sample_count" => Map.get(group, "sample_count"),
      "trend_status" => Map.get(group, "trend_status"),
      "duration_delta_percent" => Map.get(group, "duration_delta_percent"),
      "scale_status" => comparison["status"],
      "scale_rows" => comparison["rows"],
      "distribution_guidance" => distribution_guidance(target, observation)
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp distribution_guidance(target, group) do
    group = stringify_keys(group)
    mode = Map.get(group, "mode")
    threshold = target["distributed_execution_threshold_scenarios"]
    observed = scenario_count(group)

    status =
      cond do
        not is_number(observed) ->
          "not_evaluated"

        observed < threshold ->
          "local_concurrency_target"

        distributed_mode?(mode) ->
          "distributed_evidence"

        true ->
          "distributed_candidate"
      end

    %{
      "status" => status,
      "mode" => mode,
      "observed_scenarios" => observed,
      "distributed_execution_threshold_scenarios" => threshold
    }
  end

  defp scenario_count(group) do
    first_number([
      Map.get(group, "scenario_count"),
      Map.get(group, "monte_carlo_count")
    ])
  end

  defp runtime_ms(group) do
    first_number([
      Map.get(group, "median_duration_ms"),
      Map.get(group, "median_elapsed_ms")
    ])
  end

  defp maybe_put_number(map, _key, nil), do: map
  defp maybe_put_number(map, key, value) when is_number(value), do: Map.put(map, key, value)
  defp maybe_put_number(map, _key, _value), do: map

  defp maybe_put_local_runtime(map, mode, runtime_ms) when is_number(runtime_ms) do
    if local_runtime_mode?(mode) do
      Map.put(map, "local_runtime_s", runtime_ms / 1_000.0)
    else
      map
    end
  end

  defp maybe_put_local_runtime(map, _mode, _runtime_ms), do: map

  defp first_number(values), do: Enum.find(values, &is_number/1)

  defp local_runtime_mode?(mode), do: not distributed_mode?(mode)

  defp distributed_mode?(mode)
       when mode in [
              "distributed",
              "remote",
              "distributed_task_supervisors",
              "remote_task_supervisor"
            ],
       do: true

  defp distributed_mode?(_mode), do: false

  defp result_artifact_observation(artifact) do
    execution_report = Map.get(artifact, "execution_report", %{})
    payload_metrics = Map.get(artifact, "payload_metrics", %{})

    %{}
    |> maybe_put_number("scenario_count", Map.get(execution_report, "scenario_count"))
    |> maybe_put_local_runtime(
      Map.get(execution_report, "execution_mode"),
      result_runtime_ms(artifact, execution_report)
    )
    |> maybe_put_number("artifact_size_mb", artifact_size_mb(payload_metrics))
  end

  defp result_runtime_ms(artifact, execution_report) do
    first_number([
      get_in(artifact, ["run", "duration_ms"]),
      execution_phase_runtime_ms(execution_report)
    ])
  end

  defp execution_phase_runtime_ms(execution_report) do
    execution_report
    |> Map.get("phase_timings_ms", %{})
    |> Map.values()
    |> Enum.filter(&is_number/1)
    |> case do
      [] -> nil
      values -> Enum.sum(values)
    end
  end

  defp artifact_size_mb(%{"artifact_body_bytes" => bytes}) when is_number(bytes),
    do: bytes / 1_000_000.0

  defp artifact_size_mb(_payload_metrics), do: nil

  defp result_artifact_source(artifact) do
    execution_report = Map.get(artifact, "execution_report", %{})
    payload_metrics = Map.get(artifact, "payload_metrics", %{})

    %{
      "study_id" => Map.get(execution_report, "study_id") || Map.get(artifact, "study_id"),
      "run_id" => Map.get(execution_report, "run_id"),
      "status" => Map.get(execution_report, "status"),
      "execution_mode" => Map.get(execution_report, "execution_mode"),
      "backend" => Map.get(execution_report, "backend"),
      "task_chunk_size" => Map.get(execution_report, "task_chunk_size"),
      "failed_scenario_count" => Map.get(execution_report, "failed_scenario_count"),
      "artifact_body_bytes" => Map.get(payload_metrics, "artifact_body_bytes")
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp distribution_guidance_group(execution_report) do
    execution_report
    |> Map.put("mode", Map.get(execution_report, "execution_mode"))
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_key(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: value

  defp encode_key(key) when is_atom(key), do: Atom.to_string(key)
  defp encode_key(key), do: key
end
