defmodule OrbitalDynamics.Study.Benchmark do
  @moduledoc """
  Study-level benchmark harness for comparing execution modes.

  Unlike `OrbitalDynamics.Benchmark`, this runs a full study manifest and
  compares mission-planning artifacts rather than raw propagation kernels.
  """

  alias OrbitalDynamics.RuntimeTelemetry
  alias OrbitalDynamics.ResultSet.Artifact
  alias OrbitalDynamics.Study.Benchmark.Report
  alias OrbitalDynamics.Study.Manifest

  @schema_version 1
  @modes ["local", "remote", "distributed"]

  @doc """
  Runs a study benchmark from a manifest path.
  """
  def run(manifest_path, opts \\ []) when is_binary(manifest_path) and is_list(opts) do
    with {:ok, modes} <- modes(opts),
         {:ok, repetitions} <- repetitions(opts),
         {:ok, monte_carlo_counts} <- monte_carlo_counts(opts),
         {:ok, propagators} <- propagators(opts),
         {:ok, task_chunk_sizes} <- task_chunk_sizes(opts),
         {:ok, max_concurrencies} <- max_concurrencies(opts),
         :ok <- validate_remote_options(modes, opts),
         {:ok, manifest} <- Manifest.from_file(manifest_path),
         {:ok, variants} <- manifest_variants(manifest, monte_carlo_counts, propagators),
         {:ok, rows} <-
           benchmark_rows(variants, modes, repetitions, opts, task_chunk_sizes, max_concurrencies) do
      {:ok,
       %{
         schema_version: @schema_version,
         generated_at: DateTime.to_iso8601(DateTime.utc_now()),
         manifest: Keyword.get(manifest.run_opts, :manifest, %{path: manifest_path}),
         model_limits: Report.model_limits(),
         benchmark_options:
           %{
             modes: modes,
             repetitions: repetitions
           }
           |> maybe_put(:monte_carlo_counts, monte_carlo_counts)
           |> maybe_put(:propagators, propagators)
           |> maybe_put(:task_chunk_size, Keyword.get(opts, :task_chunk_size))
           |> maybe_put(:task_chunk_sizes, Keyword.get(opts, :task_chunk_sizes))
           |> maybe_put(:max_concurrency, Keyword.get(opts, :max_concurrency))
           |> maybe_put(:max_concurrencies, Keyword.get(opts, :max_concurrencies))
           |> maybe_put(:task_supervisor_node, Keyword.get(opts, :task_supervisor_node)),
         results: attach_baseline_matches(rows)
       }}
    end
  end

  @doc """
  Writes a benchmark artifact as JSON.
  """
  def write_json!(artifact, path) when is_map(artifact) and is_binary(path) do
    path
    |> Path.dirname()
    |> File.mkdir_p!()

    json =
      artifact
      |> encode_value()
      |> :json.encode()
      |> IO.iodata_to_binary()

    File.write!(path, json <> "\n")
    path
  end

  defp benchmark_rows(variants, modes, repetitions, opts, task_chunk_sizes, max_concurrencies) do
    variants
    |> Enum.reduce_while({:ok, []}, fn variant, {:ok, rows} ->
      case variant_rows(variant, modes, repetitions, opts, task_chunk_sizes, max_concurrencies) do
        {:ok, variant_rows} -> {:cont, {:ok, rows ++ variant_rows}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp variant_rows(variant, modes, repetitions, opts, task_chunk_sizes, max_concurrencies) do
    max_concurrencies
    |> Enum.reduce_while({:ok, []}, fn max_concurrency, {:ok, rows} ->
      concurrency_rows(variant, modes, repetitions, opts, task_chunk_sizes, max_concurrency)
      |> case do
        {:ok, concurrency_rows} -> {:cont, {:ok, rows ++ concurrency_rows}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp concurrency_rows(variant, modes, repetitions, opts, task_chunk_sizes, max_concurrency) do
    with {:ok, local_rows} <- maybe_local_rows(modes, variant, repetitions, opts, max_concurrency),
         {:ok, chunked_rows} <-
           chunked_mode_rows(variant, modes, repetitions, opts, task_chunk_sizes, max_concurrency) do
      {:ok, local_rows ++ chunked_rows}
    end
  end

  defp maybe_local_rows(modes, variant, repetitions, opts, max_concurrency) do
    if "local" in modes do
      mode_rows("local", variant, repetitions, opts, nil, max_concurrency)
    else
      {:ok, []}
    end
  end

  defp chunked_mode_rows(variant, modes, repetitions, opts, task_chunk_sizes, max_concurrency) do
    chunked_modes = Enum.reject(modes, &(&1 == "local"))

    task_chunk_sizes
    |> Enum.reduce_while({:ok, []}, fn task_chunk_size, {:ok, rows} ->
      chunk_rows(chunked_modes, variant, repetitions, opts, task_chunk_size, max_concurrency)
      |> case do
        {:ok, chunk_rows} -> {:cont, {:ok, rows ++ chunk_rows}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp chunk_rows(modes, variant, repetitions, opts, task_chunk_size, max_concurrency) do
    modes
    |> Enum.reduce_while({:ok, []}, fn mode, {:ok, rows} ->
      mode_rows(mode, variant, repetitions, opts, task_chunk_size, max_concurrency)
      |> case do
        {:ok, mode_rows} -> {:cont, {:ok, rows ++ mode_rows}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp mode_rows(mode, variant, repetitions, opts, task_chunk_size, max_concurrency) do
    1..repetitions
    |> Enum.reduce_while({:ok, []}, fn repetition, {:ok, rows} ->
      case run_once(
             mode,
             repetition,
             repetitions,
             variant,
             opts,
             task_chunk_size,
             max_concurrency
           ) do
        {:ok, row} -> {:cont, {:ok, rows ++ [row]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp run_once(mode, repetition, repetitions, variant, opts, task_chunk_size, max_concurrency) do
    manifest = variant.manifest
    run_opts = run_opts(manifest.run_opts, mode, opts, task_chunk_size, max_concurrency)
    telemetry_nodes = telemetry_nodes(run_opts)
    telemetry_before = RuntimeTelemetry.snapshot(telemetry_nodes)

    case OrbitalDynamics.run_study(manifest.study, run_opts) do
      {:ok, result_set} ->
        telemetry_after = RuntimeTelemetry.snapshot(telemetry_nodes)
        runtime_telemetry = RuntimeTelemetry.diff(telemetry_before, telemetry_after)

        {artifact, artifact_build_ms} =
          timed(fn ->
            result_set
            |> Artifact.build()
            |> json_safe()
          end)

        run = artifact["run"] || %{}
        run_options = Map.get(run, "options", %{})
        run_metadata = Map.get(run, "metadata", %{})
        execution_plan = Map.get(run_metadata, "execution_plan", %{})
        phase_timings = Map.get(run_metadata, "phase_timings_ms", %{})
        propagation_ms = Map.get(phase_timings, "propagation")
        event_detection_ms = Map.get(phase_timings, "event_detection")
        signature = output_signature(artifact)
        payload_metrics = Map.get(artifact, "payload_metrics", %{})
        artifact_body_bytes = Map.get(payload_metrics, "artifact_body_bytes")
        scenario_count = run_metadata["scenario_count"]

        {:ok,
         %{
           id:
             "#{manifest.study.id}_#{mode}_propagator_#{variant.propagator}_mc_#{variant.monte_carlo_count || "default"}_concurrency_#{run_options["max_concurrency"] || "default"}_chunk_#{task_chunk_size || "default"}_r#{repetition}",
           mode: mode,
           propagator: variant.propagator,
           repetition: repetition,
           repetitions: repetitions,
           duration_ms: run["duration_ms"],
           backend: run["backend"],
           propagation_ms: propagation_ms,
           event_detection_ms: event_detection_ms,
           artifact_build_ms: artifact_build_ms,
           overhead_ms: overhead_ms(run["duration_ms"], propagation_ms, event_detection_ms),
           overhead_percent:
             overhead_percent(run["duration_ms"], propagation_ms, event_detection_ms),
           execution_mode: run_metadata["execution_mode"],
           execution_plan: execution_plan,
           batch_propagation: run_metadata["batch_propagation"],
           max_concurrency: run_options["max_concurrency"],
           effective_task_concurrency: run_metadata["effective_task_concurrency"],
           effective_task_chunk_size: Map.get(execution_plan, "effective_task_chunk_size"),
           task_batch_count: Map.get(execution_plan, "task_batch_count"),
           batches_per_wave: Map.get(execution_plan, "batches_per_wave"),
           wave_count: Map.get(execution_plan, "wave_count"),
           supervisor_count: Map.get(execution_plan, "supervisor_count"),
           task_supervisor_node: run_metadata["task_supervisor_node"],
           scenario_count: scenario_count,
           trajectory_count: run_metadata["trajectory_count"],
           failure_count: run_metadata["failure_count"],
           scenarios_per_second: scenarios_per_second(scenario_count, run["duration_ms"]),
           artifact_body_bytes: artifact_body_bytes,
           artifact_size_mb: artifact_size_mb(artifact_body_bytes),
           artifact_bytes_per_scenario:
             artifact_bytes_per_scenario(artifact_body_bytes, scenario_count),
           payload_top_level_key_count: Map.get(payload_metrics, "top_level_key_count"),
           per_node_trajectory_counts: per_node_trajectory_counts(artifact),
           runtime_telemetry: runtime_telemetry,
           output_signature: signature
         }
         |> maybe_put(:monte_carlo_count, variant.monte_carlo_count)
         |> maybe_put(:task_chunk_size, task_chunk_size)}

      {:error, reason} ->
        {:error, {:study_run_failed, mode, reason}}
    end
  end

  defp run_opts(base_opts, "local", _opts, task_chunk_size, max_concurrency) do
    base_opts
    |> Keyword.delete(:task_supervisor)
    |> Keyword.delete(:task_supervisors)
    |> maybe_put_run_option(:task_chunk_size, task_chunk_size)
    |> maybe_put_run_option(:max_concurrency, max_concurrency)
  end

  defp run_opts(base_opts, "remote", opts, task_chunk_size, max_concurrency) do
    node_name = Keyword.fetch!(opts, :task_supervisor_node)

    base_opts
    |> Keyword.delete(:task_supervisors)
    |> maybe_put_run_option(:task_chunk_size, task_chunk_size)
    |> maybe_put_run_option(:max_concurrency, max_concurrency)
    |> Keyword.put(
      :task_supervisor,
      {OrbitalDynamics.ScenarioSupervisor, String.to_atom(node_name)}
    )
  end

  defp run_opts(base_opts, "distributed", opts, task_chunk_size, max_concurrency) do
    node_name = Keyword.fetch!(opts, :task_supervisor_node)

    base_opts
    |> Keyword.delete(:task_supervisor)
    |> maybe_put_run_option(:task_chunk_size, task_chunk_size)
    |> maybe_put_run_option(:max_concurrency, max_concurrency)
    |> Keyword.put(:task_supervisors, [
      OrbitalDynamics.ScenarioSupervisor,
      {OrbitalDynamics.ScenarioSupervisor, String.to_atom(node_name)}
    ])
  end

  defp manifest_variants(manifest, monte_carlo_counts, propagators) do
    with {:ok, count_variants} <- monte_carlo_variants(manifest, monte_carlo_counts) do
      propagator_variants(count_variants, propagators)
    end
  end

  defp monte_carlo_variants(manifest, nil),
    do:
      {:ok,
       [
         %{
           manifest: manifest,
           monte_carlo_count: nil,
           propagator: Map.get(manifest.source, "propagator", "two_body")
         }
       ]}

  defp monte_carlo_variants(manifest, counts) when is_list(counts) do
    case manifest.source do
      %{"monte_carlo" => %{} = monte_carlo} ->
        counts
        |> Enum.reduce_while({:ok, []}, fn count, {:ok, variants} ->
          source = %{manifest.source | "monte_carlo" => Map.put(monte_carlo, "count", count)}

          case Manifest.from_map(source) do
            {:ok, variant_manifest} ->
              variant_manifest = preserve_manifest_metadata(variant_manifest, manifest)

              {:cont,
               {:ok,
                variants ++
                  [
                    %{
                      manifest: variant_manifest,
                      monte_carlo_count: count,
                      propagator: Map.get(variant_manifest.source, "propagator", "two_body")
                    }
                  ]}}

            {:error, reason} ->
              {:halt, {:error, {:invalid_monte_carlo_count_variant, count, reason}}}
          end
        end)

      _source ->
        {:error, {:missing_field, "monte_carlo"}}
    end
  end

  defp propagator_variants(variants, nil), do: {:ok, variants}

  defp propagator_variants(variants, propagators) when is_list(propagators) do
    variants
    |> Enum.reduce_while({:ok, []}, fn variant, {:ok, acc} ->
      propagators
      |> Enum.reduce_while({:ok, []}, fn propagator, {:ok, propagator_variants} ->
        source = Map.put(variant.manifest.source, "propagator", propagator)

        case Manifest.from_map(source) do
          {:ok, propagator_manifest} ->
            propagator_manifest =
              preserve_manifest_metadata(propagator_manifest, variant.manifest)

            {:cont,
             {:ok,
              propagator_variants ++
                [
                  %{
                    variant
                    | manifest: propagator_manifest,
                      propagator: propagator
                  }
                ]}}

          {:error, reason} ->
            {:halt, {:error, {:invalid_propagator_variant, propagator, reason}}}
        end
      end)
      |> case do
        {:ok, propagator_variants} -> {:cont, {:ok, acc ++ propagator_variants}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp preserve_manifest_metadata(variant_manifest, original_manifest) do
    case Keyword.fetch(original_manifest.run_opts, :manifest) do
      {:ok, manifest_metadata} ->
        %{variant_manifest | run_opts: variant_manifest.run_opts ++ [manifest: manifest_metadata]}

      :error ->
        variant_manifest
    end
  end

  defp attach_baseline_matches([]), do: []

  defp attach_baseline_matches(rows) do
    baseline_by_case =
      rows
      |> Enum.group_by(&baseline_case/1)
      |> Map.new(fn {benchmark_case, case_rows} ->
        baseline = Enum.find(case_rows, &(&1.mode == "local")) || hd(case_rows)
        {benchmark_case, baseline.output_signature}
      end)

    Enum.map(rows, fn row ->
      Map.put(
        row,
        :matches_baseline,
        row.output_signature == Map.fetch!(baseline_by_case, baseline_case(row))
      )
    end)
  end

  defp baseline_case(row),
    do: {Map.get(row, :monte_carlo_count, :default), Map.get(row, :max_concurrency, :default)}

  defp scenarios_per_second(scenario_count, duration_ms)
       when is_number(scenario_count) and is_number(duration_ms) and duration_ms > 0 do
    scenario_count / (duration_ms / 1_000.0)
  end

  defp scenarios_per_second(_scenario_count, _duration_ms), do: nil

  defp overhead_ms(duration_ms, propagation_ms, event_detection_ms)
       when is_number(duration_ms) and is_number(propagation_ms) and
              is_number(event_detection_ms) do
    max(duration_ms - propagation_ms - event_detection_ms, 0)
  end

  defp overhead_ms(_duration_ms, _propagation_ms, _event_detection_ms), do: nil

  defp overhead_percent(duration_ms, propagation_ms, event_detection_ms)
       when is_number(duration_ms) and duration_ms > 0 do
    case overhead_ms(duration_ms, propagation_ms, event_detection_ms) do
      overhead_ms when is_number(overhead_ms) -> overhead_ms / duration_ms * 100.0
      _overhead_ms -> nil
    end
  end

  defp overhead_percent(_duration_ms, _propagation_ms, _event_detection_ms), do: nil

  defp artifact_size_mb(bytes) when is_integer(bytes) and bytes >= 0,
    do: bytes / 1_000_000.0

  defp artifact_size_mb(_bytes), do: nil

  defp artifact_bytes_per_scenario(bytes, scenario_count)
       when is_integer(bytes) and bytes >= 0 and is_integer(scenario_count) and scenario_count > 0,
       do: bytes / scenario_count

  defp artifact_bytes_per_scenario(_bytes, _scenario_count), do: nil

  defp output_signature(artifact) do
    %{
      scenario_ids:
        artifact
        |> Map.get("trajectories", [])
        |> Enum.map(& &1["scenario_id"])
        |> Enum.sort(),
      ranking:
        artifact
        |> get_in(["scenario_rankings", "rows"])
        |> List.wrap()
        |> Enum.map(& &1["scenario_id"]),
      constraints:
        artifact
        |> Map.get("constraint_results", [])
        |> Enum.map(fn row ->
          %{
            constraint_id: row["constraint_id"],
            scenario_id: row["scenario_id"],
            status: row["status"]
          }
        end)
        |> Enum.sort_by(&{&1.constraint_id, &1.scenario_id})
    }
  end

  defp per_node_trajectory_counts(artifact) do
    artifact
    |> Map.get("trajectories", [])
    |> Enum.group_by(&Map.get(&1, "node"))
    |> Map.new(fn {node, rows} -> {node, length(rows)} end)
  end

  defp telemetry_nodes(run_opts) do
    run_opts
    |> Keyword.get(:task_supervisors)
    |> case do
      supervisors when is_list(supervisors) and supervisors != [] ->
        Enum.map(supervisors, &task_supervisor_node/1)

      _supervisors ->
        [task_supervisor_node(Keyword.get(run_opts, :task_supervisor))]
    end
    |> Enum.uniq()
  end

  defp task_supervisor_node({_supervisor, supervisor_node}), do: supervisor_node
  defp task_supervisor_node(_supervisor), do: node()

  defp modes(opts) do
    opts
    |> Keyword.get(:modes, ["local"])
    |> List.wrap()
    |> Enum.map(&to_string/1)
    |> case do
      [] ->
        {:error, {:invalid_option, :modes}}

      modes ->
        unsupported = modes -- @modes

        if unsupported == [] do
          {:ok, modes}
        else
          {:error, {:unsupported_modes, unsupported}}
        end
    end
  end

  defp repetitions(opts) do
    repetitions = Keyword.get(opts, :repetitions, 1)

    if is_integer(repetitions) and repetitions > 0 do
      {:ok, repetitions}
    else
      {:error, {:invalid_option, :repetitions}}
    end
  end

  defp monte_carlo_counts(opts) do
    case Keyword.get(opts, :monte_carlo_counts) do
      nil ->
        {:ok, nil}

      counts when is_list(counts) and counts != [] ->
        if Enum.all?(counts, &(is_integer(&1) and &1 > 0)) do
          {:ok, counts}
        else
          {:error, {:invalid_option, :monte_carlo_counts}}
        end

      _counts ->
        {:error, {:invalid_option, :monte_carlo_counts}}
    end
  end

  defp propagators(opts) do
    case Keyword.get(opts, :propagators) do
      nil ->
        {:ok, nil}

      propagators when is_list(propagators) and propagators != [] ->
        if Enum.all?(propagators, &(is_binary(&1) and &1 != "")) do
          {:ok, propagators}
        else
          {:error, {:invalid_option, :propagators}}
        end

      _propagators ->
        {:error, {:invalid_option, :propagators}}
    end
  end

  defp task_chunk_sizes(opts) do
    case {Keyword.get(opts, :task_chunk_size), Keyword.get(opts, :task_chunk_sizes)} do
      {nil, nil} ->
        {:ok, [nil]}

      {value, nil} when is_integer(value) and value > 0 ->
        {:ok, [value]}

      {nil, values} when is_list(values) and values != [] ->
        if Enum.all?(values, &(is_integer(&1) and &1 > 0)) do
          {:ok, values}
        else
          {:error, {:invalid_option, :task_chunk_sizes}}
        end

      {nil, _values} ->
        {:error, {:invalid_option, :task_chunk_sizes}}

      {_value, nil} ->
        {:error, {:invalid_option, :task_chunk_size}}

      {_value, _values} ->
        {:error, {:conflicting_options, [:task_chunk_size, :task_chunk_sizes]}}
    end
  end

  defp max_concurrencies(opts) do
    case {Keyword.get(opts, :max_concurrency), Keyword.get(opts, :max_concurrencies)} do
      {nil, nil} ->
        {:ok, [nil]}

      {value, nil} when is_integer(value) and value > 0 ->
        {:ok, [value]}

      {nil, values} when is_list(values) and values != [] ->
        if Enum.all?(values, &(is_integer(&1) and &1 > 0)) do
          {:ok, values}
        else
          {:error, {:invalid_option, :max_concurrencies}}
        end

      {nil, _values} ->
        {:error, {:invalid_option, :max_concurrencies}}

      {_value, nil} ->
        {:error, {:invalid_option, :max_concurrency}}

      {_value, _values} ->
        {:error, {:conflicting_options, [:max_concurrency, :max_concurrencies]}}
    end
  end

  defp validate_remote_options(modes, opts) do
    if Enum.any?(modes, &(&1 in ["remote", "distributed"])) and
         Keyword.get(opts, :task_supervisor_node) in [nil, ""] do
      {:error, {:missing_option, :task_supervisor_node}}
    else
      :ok
    end
  end

  defp json_safe(value) do
    value
    |> encode_value()
    |> :json.encode()
    |> IO.iodata_to_binary()
    |> :json.decode()
  end

  defp timed(fun) when is_function(fun, 0) do
    started_monotonic = System.monotonic_time()
    value = fun.()
    {value, elapsed_ms(started_monotonic)}
  end

  defp elapsed_ms(started_monotonic) do
    (System.monotonic_time() - started_monotonic)
    |> System.convert_time_unit(:native, :millisecond)
  end

  defp encode_value(values) when is_list(values) do
    if values != [] and Keyword.keyword?(values) do
      Map.new(values, fn {key, value} -> {encode_key(key), encode_value(value)} end)
    else
      Enum.map(values, &encode_value/1)
    end
  end

  defp encode_value(value) when is_map(value) do
    Map.new(value, fn {key, value} -> {encode_key(key), encode_value(value)} end)
  end

  defp encode_value(nil), do: :null
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(value), do: value

  defp encode_key(key) when is_atom(key), do: Atom.to_string(key)
  defp encode_key(key) when is_binary(key), do: key
  defp encode_key(key), do: inspect(key)

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
  defp maybe_put_run_option(opts, _key, nil), do: opts
  defp maybe_put_run_option(opts, key, value), do: Keyword.put(opts, key, value)
end
