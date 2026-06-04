defmodule OrbitalDynamics.Benchmark do
  @moduledoc """
  Baseline benchmark harness for propagation workloads.

  The harness establishes the scalar and BEAM-concurrent baselines that future
  Nx/EXLA, native, or distributed backends must compare against.
  """

  alias OrbitalDynamics.Benchmark.{Result, ScenarioFixture}

  alias OrbitalDynamics.Propagators.{
    J2,
    J2ExlaCpu,
    TwoBody,
    TwoBodyExlaCpu,
    TwoBodyNx,
    TwoBodyNxCompiled
  }

  alias OrbitalDynamics.ScenarioRunner

  @default_counts [1, 10, 100]

  @doc """
  Runs baseline propagation benchmarks for deterministic circular LEO batches.
  """
  def run(opts \\ []) do
    counts = Keyword.get(opts, :counts, @default_counts)
    duration_s = Keyword.get(opts, :duration_s, 3_600.0)
    output_step_s = Keyword.get(opts, :output_step_s, 60.0)
    max_step_s = Keyword.get(opts, :max_step_s, 10.0)
    max_concurrency = Keyword.get(opts, :max_concurrency, System.schedulers_online())
    include_nx = Keyword.get(opts, :include_nx, false)
    include_nx_compiled = Keyword.get(opts, :include_nx_compiled, false)
    include_exla_cpu = Keyword.get(opts, :include_exla_cpu, false)
    force_model = Keyword.get(opts, :force_model, :two_body)
    repetitions = Keyword.get(opts, :repetitions, 1)
    warmup_runs = Keyword.get(opts, :warmup_runs, 0)

    validate_run_options!(repetitions, warmup_runs)

    Enum.flat_map(counts, fn count ->
      scenarios =
        ScenarioFixture.circular_leo(
          count: count,
          duration_s: duration_s,
          output_step_s: output_step_s,
          id_prefix: "bench_#{count}"
        )

      mode_funs = [
        fn -> benchmark_scalar_direct(scenarios, max_step_s, force_model) end,
        fn -> benchmark_scenario_runner(scenarios, max_step_s, max_concurrency, force_model) end
      ]

      mode_funs
      |> maybe_append(include_nx, fn -> benchmark_nx_batched(scenarios, max_step_s) end)
      |> maybe_append(include_nx_compiled, fn -> benchmark_nx_compiled(scenarios, max_step_s) end)
      |> maybe_append(include_exla_cpu, fn ->
        benchmark_exla_cpu(scenarios, max_step_s, force_model)
      end)
      |> Enum.flat_map(&run_repeated(&1, repetitions, warmup_runs))
    end)
  end

  defp benchmark_scalar_direct(scenarios, max_step_s, force_model) do
    propagator = scalar_propagator(force_model)

    {elapsed_us, memory_delta_bytes, results} =
      measure(fn ->
        Enum.map(scenarios, &propagator.propagate(&1, max_step_s: max_step_s))
      end)

    success_trajectories =
      results
      |> Enum.filter(&match?({:ok, _trajectory}, &1))
      |> Enum.map(fn {:ok, trajectory} -> trajectory end)

    Result.new!(%{
      id: "#{force_model}_scalar_direct_#{length(scenarios)}",
      mode: :scalar_direct,
      backend: propagator,
      scenario_count: length(scenarios),
      sample_count: sample_count(success_trajectories),
      failure_count: Enum.count(results, &match?({:error, _reason}, &1)),
      elapsed_us: elapsed_us,
      memory_delta_bytes: memory_delta_bytes,
      options: [max_step_s: max_step_s],
      metadata: %{
        force_model: force_model,
        validation_level: propagator.capabilities().validation_level
      }
    })
  end

  defp benchmark_scenario_runner(scenarios, max_step_s, max_concurrency, force_model) do
    propagator = scalar_propagator(force_model)

    {elapsed_us, memory_delta_bytes, results} =
      measure(fn ->
        ScenarioRunner.run(scenarios,
          propagator: propagator,
          propagator_opts: [max_step_s: max_step_s],
          max_concurrency: max_concurrency
        )
      end)

    success_trajectories =
      results
      |> Enum.filter(&(&1.status == :ok))
      |> Enum.map(& &1.value)

    Result.new!(%{
      id: "#{force_model}_scenario_runner_#{length(scenarios)}",
      mode: :scenario_runner,
      backend: propagator,
      scenario_count: length(scenarios),
      sample_count: sample_count(success_trajectories),
      failure_count: Enum.count(results, &(&1.status == :error)),
      elapsed_us: elapsed_us,
      memory_delta_bytes: memory_delta_bytes,
      options: [
        max_step_s: max_step_s,
        max_concurrency: max_concurrency
      ],
      metadata: %{
        force_model: force_model,
        validation_level: propagator.capabilities().validation_level
      }
    })
  end

  defp benchmark_nx_batched(scenarios, max_step_s) do
    {elapsed_us, memory_delta_bytes, result} =
      measure(fn ->
        TwoBodyNx.propagate_many(scenarios, max_step_s: max_step_s)
      end)

    success_trajectories =
      case result do
        {:ok, trajectories} -> trajectories
        {:error, _reason} -> []
      end

    Result.new!(%{
      id: "nx_batched_#{length(scenarios)}",
      mode: :nx_batched,
      backend: TwoBodyNx,
      scenario_count: length(scenarios),
      sample_count: sample_count(success_trajectories),
      failure_count: if(match?({:ok, _trajectories}, result), do: 0, else: length(scenarios)),
      elapsed_us: elapsed_us,
      memory_delta_bytes: memory_delta_bytes,
      options: [max_step_s: max_step_s],
      metadata: %{
        validation_level: TwoBodyNx.capabilities().validation_level
      }
    })
  end

  defp benchmark_nx_compiled(scenarios, max_step_s) do
    {elapsed_us, memory_delta_bytes, result} =
      measure(fn ->
        TwoBodyNxCompiled.propagate_many(scenarios, max_step_s: max_step_s)
      end)

    success_trajectories =
      case result do
        {:ok, trajectories} -> trajectories
        {:error, _reason} -> []
      end

    Result.new!(%{
      id: "nx_compiled_#{length(scenarios)}",
      mode: :nx_compiled,
      backend: TwoBodyNxCompiled,
      scenario_count: length(scenarios),
      sample_count: sample_count(success_trajectories),
      failure_count: if(match?({:ok, _trajectories}, result), do: 0, else: length(scenarios)),
      elapsed_us: elapsed_us,
      memory_delta_bytes: memory_delta_bytes,
      options: [max_step_s: max_step_s],
      metadata: %{
        validation_level: TwoBodyNxCompiled.capabilities().validation_level
      }
    })
  end

  defp benchmark_exla_cpu(scenarios, max_step_s, force_model) do
    propagator = exla_propagator(force_model)

    {elapsed_us, memory_delta_bytes, result} =
      measure(fn ->
        propagator.propagate_many(scenarios, max_step_s: max_step_s)
      end)

    success_trajectories =
      case result do
        {:ok, trajectories} -> trajectories
        {:error, _reason} -> []
      end

    Result.new!(%{
      id: "#{force_model}_exla_cpu_#{length(scenarios)}",
      mode: :exla_cpu,
      backend: propagator,
      scenario_count: length(scenarios),
      sample_count: sample_count(success_trajectories),
      failure_count: if(match?({:ok, _trajectories}, result), do: 0, else: length(scenarios)),
      elapsed_us: elapsed_us,
      memory_delta_bytes: memory_delta_bytes,
      options: [max_step_s: max_step_s],
      metadata: %{
        force_model: force_model,
        validation_level: propagator.capabilities().validation_level
      }
    })
  end

  defp measure(fun) do
    memory_before = :erlang.memory(:total)
    start = System.monotonic_time(:microsecond)
    value = fun.()
    elapsed_us = System.monotonic_time(:microsecond) - start
    memory_after = :erlang.memory(:total)

    {elapsed_us, memory_after - memory_before, value}
  end

  defp sample_count(trajectories) do
    Enum.reduce(trajectories, 0, fn trajectory, total -> total + length(trajectory.states) end)
  end

  defp run_repeated(fun, repetitions, warmup_runs) do
    if warmup_runs > 0 do
      Enum.each(1..warmup_runs, fn _run -> fun.() end)
    end

    Enum.map(1..repetitions, fn repetition ->
      result = fun.()
      tag_repetition(result, repetition, repetitions, warmup_runs)
    end)
  end

  defp tag_repetition(result, repetition, repetitions, warmup_runs) do
    id =
      if repetitions == 1 do
        result.id
      else
        "#{result.id}_r#{repetition}"
      end

    metadata =
      Map.merge(result.metadata, %{
        repetition: repetition,
        repetitions: repetitions,
        warmup_runs: warmup_runs
      })

    %{result | id: id, metadata: metadata}
  end

  defp validate_run_options!(repetitions, warmup_runs) do
    cond do
      not is_integer(repetitions) or repetitions <= 0 ->
        raise ArgumentError, "repetitions must be a positive integer"

      not is_integer(warmup_runs) or warmup_runs < 0 ->
        raise ArgumentError, "warmup_runs must be a non-negative integer"

      true ->
        :ok
    end
  end

  defp maybe_append(results, true, fun), do: results ++ [fun]
  defp maybe_append(results, false, _fun), do: results

  defp scalar_propagator(:two_body), do: TwoBody
  defp scalar_propagator(:j2), do: J2

  defp exla_propagator(:two_body), do: TwoBodyExlaCpu
  defp exla_propagator(:j2), do: J2ExlaCpu
end
