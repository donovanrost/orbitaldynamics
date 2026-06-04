defmodule Mix.Tasks.OrbitalDynamics.Study.Benchmark do
  @moduledoc """
  Benchmarks complete study manifest execution modes.

  Usage:

      mix orbital_dynamics.study.benchmark --manifest studies/raise_apogee_search.json --mode local --repetitions 3
      mix orbital_dynamics.study.benchmark --manifest studies/raise_apogee_search.json --mode local --mode remote --task-supervisor-node worker@127.0.0.1
      mix orbital_dynamics.study.benchmark --manifest studies/leo_dispersion_monte_carlo.json --mode local --mode distributed --task-supervisor-node worker@127.0.0.1 --monte-carlo-counts 200,2000
      mix orbital_dynamics.study.benchmark --manifest studies/leo_dispersion_monte_carlo.json --mode local --mode distributed --task-supervisor-node worker@127.0.0.1 --task-chunk-size 100 --monte-carlo-counts 200,2000
      mix orbital_dynamics.study.benchmark --manifest studies/leo_dispersion_monte_carlo.json --mode local --mode distributed --task-supervisor-node worker@127.0.0.1 --task-chunk-sizes 1,10,100 --monte-carlo-counts 200,2000
      mix orbital_dynamics.study.benchmark --manifest studies/leo_dispersion_monte_carlo.json --mode local --mode distributed --task-supervisor-node worker@127.0.0.1 --task-chunk-sizes 50,100,250 --max-concurrencies 4,8,16 --monte-carlo-counts 2000,20000
      mix orbital_dynamics.study.benchmark --manifest studies/leo_dispersion_monte_carlo.json --mode local --propagators two_body,two_body_nx_compiled,two_body_exla_cpu --monte-carlo-counts 2000,20000
      mix orbital_dynamics.study.benchmark --manifest studies/leo_dispersion_monte_carlo.json --mode local --repetitions 3 --monte-carlo-counts 20,200,2000
  """

  use Mix.Task

  alias OrbitalDynamics.Study.Benchmark
  alias OrbitalDynamics.Study.Benchmark.Report

  @shortdoc "Benchmarks study execution modes"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    opts = parse_args!(args)
    manifest_path = Keyword.fetch!(opts, :manifest)
    output_path = Keyword.get(opts, :output)
    benchmark_opts = Keyword.drop(opts, [:manifest, :output])

    artifact =
      case Benchmark.run(manifest_path, benchmark_opts) do
        {:ok, artifact} -> artifact
        {:error, reason} -> Mix.raise("study benchmark failed: #{inspect(reason)}")
      end

    print_results(artifact)
    maybe_write_artifact(artifact, output_path)
  end

  defp parse_args!(args) do
    {parsed, rest, invalid} =
      OptionParser.parse(args,
        strict: [
          manifest: :string,
          mode: :keep,
          repetitions: :integer,
          max_concurrency: :integer,
          max_concurrencies: :string,
          monte_carlo_counts: :string,
          propagators: :string,
          task_chunk_size: :integer,
          task_chunk_sizes: :string,
          task_supervisor_node: :string,
          output: :string
        ]
      )

    unless rest == [] and invalid == [] do
      Mix.raise("invalid study benchmark arguments: #{inspect(rest ++ invalid)}")
    end

    unless Keyword.has_key?(parsed, :manifest) do
      Mix.raise("--manifest is required")
    end

    parsed
    |> normalize_modes()
    |> normalize_monte_carlo_counts()
    |> normalize_propagators()
    |> normalize_task_chunk_sizes()
    |> normalize_max_concurrencies()
    |> Keyword.put_new(:repetitions, 1)
  end

  defp normalize_modes(opts) do
    modes = Keyword.get_values(opts, :mode)

    opts =
      opts
      |> Keyword.delete(:mode)

    if modes == [] do
      Keyword.put(opts, :modes, ["local"])
    else
      Keyword.put(opts, :modes, modes)
    end
  end

  defp normalize_monte_carlo_counts(opts) do
    case Keyword.fetch(opts, :monte_carlo_counts) do
      {:ok, counts} ->
        opts
        |> Keyword.put(
          :monte_carlo_counts,
          parse_positive_integer_list!(counts, "--monte-carlo-counts")
        )

      :error ->
        opts
    end
  end

  defp normalize_task_chunk_sizes(opts) do
    case Keyword.fetch(opts, :task_chunk_sizes) do
      {:ok, sizes} ->
        opts
        |> Keyword.put(
          :task_chunk_sizes,
          parse_positive_integer_list!(sizes, "--task-chunk-sizes")
        )

      :error ->
        opts
    end
  end

  defp normalize_propagators(opts) do
    case Keyword.fetch(opts, :propagators) do
      {:ok, propagators} ->
        opts
        |> Keyword.put(:propagators, parse_nonempty_string_list!(propagators, "--propagators"))

      :error ->
        opts
    end
  end

  defp normalize_max_concurrencies(opts) do
    case Keyword.fetch(opts, :max_concurrencies) do
      {:ok, values} ->
        opts
        |> Keyword.put(
          :max_concurrencies,
          parse_positive_integer_list!(values, "--max-concurrencies")
        )

      :error ->
        opts
    end
  end

  defp parse_positive_integer_list!(values, option) do
    values
    |> String.split(",", trim: true)
    |> Enum.map(fn value ->
      case Integer.parse(String.trim(value)) do
        {count, ""} when count > 0 -> count
        _invalid -> Mix.raise("invalid #{option} value: #{inspect(values)}")
      end
    end)
    |> case do
      [] -> Mix.raise("invalid #{option} value: #{inspect(values)}")
      parsed -> parsed
    end
  end

  defp parse_nonempty_string_list!(values, option) do
    values
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> case do
      [] ->
        Mix.raise("invalid #{option} value: #{inspect(values)}")

      parsed ->
        if "" in parsed do
          Mix.raise("invalid #{option} value: #{inspect(values)}")
        else
          parsed
        end
    end
  end

  defp print_results(artifact) do
    summary =
      artifact
      |> json_safe()
      |> Report.summarize()

    Mix.shell().info("")
    Mix.shell().info("OrbitalDynamics study benchmark")
    Mix.shell().info("manifest: #{artifact.manifest.path}")
    Mix.shell().info("")

    Mix.shell().info(
      pad("mode", 12) <>
        pad("propagator", 24) <>
        pad("mc count", 12) <>
        pad("conc", 8) <>
        pad("eff conc", 10) <>
        pad("chunk", 10) <>
        pad("rep", 8) <>
        pad("scenarios", 12) <>
        pad("duration ms", 14) <>
        pad("scen/s", 12) <>
        pad("failures", 10) <>
        "matches"
    )

    Mix.shell().info(String.duplicate("-", 80))

    Enum.each(artifact.results, fn row ->
      Mix.shell().info(
        pad(row.mode, 12) <>
          pad(Map.get(row, :propagator, "default"), 24) <>
          pad(format_optional_integer(Map.get(row, :monte_carlo_count)), 12) <>
          pad(format_optional_integer(Map.get(row, :max_concurrency)), 8) <>
          pad(format_optional_integer(Map.get(row, :effective_task_concurrency)), 10) <>
          pad(format_optional_integer(Map.get(row, :task_chunk_size)), 10) <>
          pad("#{row.repetition}/#{row.repetitions}", 8) <>
          pad(format_optional_integer(row.scenario_count), 12) <>
          pad(format_float(row.duration_ms), 14) <>
          pad(format_optional_float(row.scenarios_per_second), 12) <>
          pad(to_string(row.failure_count), 10) <>
          to_string(row.matches_baseline)
      )
    end)

    Mix.shell().info("")
    Mix.shell().info("summary")

    Enum.each(summary.groups, fn group ->
      Mix.shell().info(
        "#{group.mode}#{format_group_count(group.monte_carlo_count)}#{format_group_chunk(group.task_chunk_size)}: " <>
          "propagator #{group.propagator || "default"}, " <>
          "max concurrency #{format_optional_integer(group.max_concurrency)}, " <>
          "effective concurrency #{format_optional_integer(group.effective_task_concurrency)}, " <>
          "median #{format_float(group.median_duration_ms)}ms, " <>
          "median #{format_optional_float(group.median_scenarios_per_second)} scenarios/s, " <>
          "scheduler utilization #{format_optional_percent(group.median_scheduler_utilization)}, " <>
          "speedup vs local #{format_optional_float(group.speedup_vs_local)}, " <>
          "outputs match #{group.output_matches_baseline}, " <>
          "nodes #{group.node_count} #{format_node_counts(group.per_node_trajectory_counts)}"
      )
    end)
  end

  defp maybe_write_artifact(_artifact, nil), do: :ok

  defp maybe_write_artifact(artifact, output_path) do
    Benchmark.write_json!(artifact, output_path)
    Mix.shell().info("")
    Mix.shell().info("Wrote study benchmark artifact: #{output_path}")
  end

  defp json_safe(value) do
    value
    |> encode_value()
    |> :json.encode()
    |> IO.iodata_to_binary()
    |> :json.decode()
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

  defp pad(value, width), do: value |> to_string() |> String.pad_trailing(width)
  defp format_float(value), do: :erlang.float_to_binary(value * 1.0, decimals: 2)
  defp format_optional_float(nil), do: "n/a"
  defp format_optional_float(value), do: format_float(value)
  defp format_optional_percent(nil), do: "n/a"
  defp format_optional_percent(value), do: "#{format_float(value * 100.0)}%"
  defp format_optional_integer(nil), do: "default"
  defp format_optional_integer(value), do: to_string(value)
  defp format_group_count(nil), do: ""
  defp format_group_count(count), do: " count #{count}"
  defp format_group_chunk(nil), do: ""
  defp format_group_chunk(chunk_size), do: " chunk #{chunk_size}"

  defp format_node_counts(counts) when counts == %{}, do: ""

  defp format_node_counts(counts) do
    counts =
      counts
      |> Enum.sort_by(fn {node, _count} -> node end)
      |> Enum.map(fn {node, count} -> "#{node}:#{count}" end)
      |> Enum.join(", ")

    "(#{counts})"
  end
end
