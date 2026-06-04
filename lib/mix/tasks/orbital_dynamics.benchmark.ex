defmodule Mix.Tasks.OrbitalDynamics.Benchmark do
  @moduledoc """
  Runs baseline OrbitalDynamics propagation benchmarks.

  ## Options

    * `--counts` - comma-separated scenario counts, default `1,10,100`
    * `--duration-s` - scenario duration in seconds, default `3600`
    * `--output-step-s` - trajectory output cadence in seconds, default `60`
    * `--max-step-s` - RK4 maximum integration step in seconds, default `10`
    * `--force-model` - `two_body` or `j2`, default `two_body`
    * `--max-concurrency` - ScenarioRunner concurrency, default schedulers online
    * `--include-nx` - include the experimental Nx batched backend
    * `--include-nx-compiled` - include the compiled Nx batched backend
    * `--include-exla-cpu` - include the EXLA host CPU backend
    * `--warmup-runs` - measured modes to run and discard before recording, default `0`
    * `--repetitions` - measured repetitions per mode and count, default `1`
    * `--output` - optional path for a JSON benchmark artifact

  Example:

      mix orbital_dynamics.benchmark --counts 1,100,1000 --duration-s 600 --output benchmark_results/baseline.json
  """

  use Mix.Task

  alias OrbitalDynamics.Benchmark
  alias OrbitalDynamics.Benchmark.Artifact

  @shortdoc "Runs baseline propagation benchmarks"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    opts = parse_args!(args)
    output_path = Keyword.get(opts, :output)
    benchmark_opts = Keyword.delete(opts, :output)

    started_at = DateTime.utc_now()
    results = Benchmark.run(benchmark_opts)
    completed_at = DateTime.utc_now()

    print_results(results)
    maybe_write_artifact(results, benchmark_opts, output_path, started_at, completed_at)
  end

  defp parse_args!(args) do
    {parsed, rest, invalid} =
      OptionParser.parse(args,
        strict: [
          counts: :string,
          duration_s: :float,
          output_step_s: :float,
          max_step_s: :float,
          force_model: :string,
          max_concurrency: :integer,
          include_nx: :boolean,
          include_nx_compiled: :boolean,
          include_exla_cpu: :boolean,
          warmup_runs: :integer,
          repetitions: :integer,
          output: :string
        ],
        aliases: [
          c: :counts
        ]
      )

    unless rest == [] and invalid == [] do
      Mix.raise("invalid benchmark arguments: #{inspect(rest ++ invalid)}")
    end

    parsed
    |> normalize_counts()
    |> normalize_force_model()
    |> Keyword.put_new(:max_concurrency, System.schedulers_online())
  end

  defp normalize_counts(opts) do
    case Keyword.fetch(opts, :counts) do
      {:ok, counts} ->
        Keyword.put(opts, :counts, parse_counts!(counts))

      :error ->
        opts
    end
  end

  defp normalize_force_model(opts) do
    case Keyword.fetch(opts, :force_model) do
      {:ok, "two_body"} -> Keyword.put(opts, :force_model, :two_body)
      {:ok, "j2"} -> Keyword.put(opts, :force_model, :j2)
      {:ok, other} -> Mix.raise("--force-model must be two_body or j2, got: #{inspect(other)}")
      :error -> opts
    end
  end

  defp parse_counts!(counts) do
    counts
    |> String.split(",", trim: true)
    |> Enum.map(fn count ->
      case Integer.parse(count) do
        {value, ""} when value > 0 ->
          value

        _other ->
          Mix.raise("--counts must be a comma-separated list of positive integers")
      end
    end)
  end

  defp print_results(results) do
    Mix.shell().info("")
    Mix.shell().info("OrbitalDynamics benchmark")
    Mix.shell().info("")

    Mix.shell().info(
      pad("mode", 18) <>
        pad("rep", 8) <>
        pad("scenarios", 12) <>
        pad("samples", 12) <>
        pad("elapsed ms", 14) <>
        pad("scenarios/s", 16) <>
        pad("samples/s", 16) <>
        "failures"
    )

    Mix.shell().info(String.duplicate("-", 96))

    Enum.each(results, fn result ->
      Mix.shell().info(
        pad(to_string(result.mode), 18) <>
          pad("#{result.metadata.repetition}/#{result.metadata.repetitions}", 8) <>
          pad(to_string(result.scenario_count), 12) <>
          pad(to_string(result.sample_count), 12) <>
          pad(format_float(result.elapsed_us / 1_000.0), 14) <>
          pad(format_float(result.metadata.scenarios_per_second), 16) <>
          pad(format_float(result.metadata.samples_per_second), 16) <>
          to_string(result.failure_count)
      )
    end)
  end

  defp maybe_write_artifact(_results, _benchmark_opts, nil, _started_at, _completed_at), do: :ok

  defp maybe_write_artifact(results, benchmark_opts, output_path, started_at, completed_at) do
    artifact =
      Artifact.build(results, benchmark_opts,
        started_at: started_at,
        completed_at: completed_at
      )

    Artifact.write_json!(artifact, output_path)
    Mix.shell().info("")
    Mix.shell().info("Wrote benchmark artifact: #{output_path}")
  end

  defp pad(value, width), do: String.pad_trailing(value, width)
  defp format_float(value), do: :erlang.float_to_binary(value * 1.0, decimals: 2)
end
