defmodule OrbitalDynamics.BenchmarkTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Benchmark

  test "runs scalar direct and scenario runner benchmark modes" do
    results =
      Benchmark.run(
        counts: [2],
        duration_s: 120.0,
        output_step_s: 60.0,
        max_step_s: 10.0,
        max_concurrency: 2
      )

    assert Enum.map(results, & &1.mode) == [:scalar_direct, :scenario_runner]
    assert Enum.map(results, & &1.scenario_count) == [2, 2]
    assert Enum.map(results, & &1.sample_count) == [6, 6]
    assert Enum.all?(results, &(&1.failure_count == 0))
    assert Enum.all?(results, &is_integer(&1.elapsed_us))
    assert Enum.all?(results, &(&1.metadata.scenarios_per_second >= 0.0))
  end

  test "optionally includes Nx batched benchmark mode" do
    results =
      Benchmark.run(
        counts: [2],
        duration_s: 120.0,
        output_step_s: 60.0,
        max_step_s: 10.0,
        max_concurrency: 2,
        include_nx: true
      )

    assert Enum.map(results, & &1.mode) == [:scalar_direct, :scenario_runner, :nx_batched]
    assert Enum.map(results, & &1.scenario_count) == [2, 2, 2]
    assert Enum.map(results, & &1.sample_count) == [6, 6, 6]
    assert Enum.all?(results, &(&1.failure_count == 0))
  end

  test "optionally includes compiled Nx benchmark mode" do
    results =
      Benchmark.run(
        counts: [2],
        duration_s: 120.0,
        output_step_s: 60.0,
        max_step_s: 10.0,
        max_concurrency: 2,
        include_nx_compiled: true
      )

    assert Enum.map(results, & &1.mode) == [:scalar_direct, :scenario_runner, :nx_compiled]
    assert Enum.map(results, & &1.scenario_count) == [2, 2, 2]
    assert Enum.map(results, & &1.sample_count) == [6, 6, 6]
    assert Enum.all?(results, &(&1.failure_count == 0))
  end

  test "optionally includes EXLA CPU benchmark mode" do
    results =
      Benchmark.run(
        counts: [2],
        duration_s: 120.0,
        output_step_s: 60.0,
        max_step_s: 10.0,
        max_concurrency: 2,
        include_exla_cpu: true
      )

    assert Enum.map(results, & &1.mode) == [:scalar_direct, :scenario_runner, :exla_cpu]
    assert Enum.map(results, & &1.scenario_count) == [2, 2, 2]
    assert Enum.map(results, & &1.sample_count) == [6, 6, 6]
    assert Enum.all?(results, &(&1.failure_count == 0))
  end

  test "can benchmark J2 scalar and EXLA CPU modes" do
    results =
      Benchmark.run(
        counts: [2],
        duration_s: 120.0,
        output_step_s: 60.0,
        max_step_s: 10.0,
        max_concurrency: 2,
        force_model: :j2,
        include_exla_cpu: true
      )

    assert Enum.map(results, & &1.mode) == [:scalar_direct, :scenario_runner, :exla_cpu]
    assert Enum.map(results, & &1.metadata.force_model) == [:j2, :j2, :j2]
    assert Enum.all?(results, &(&1.failure_count == 0))
  end

  test "supports warmup runs and measured repetitions" do
    results =
      Benchmark.run(
        counts: [2],
        duration_s: 120.0,
        output_step_s: 60.0,
        max_step_s: 10.0,
        max_concurrency: 2,
        repetitions: 2,
        warmup_runs: 1
      )

    assert Enum.map(results, & &1.mode) == [
             :scalar_direct,
             :scalar_direct,
             :scenario_runner,
             :scenario_runner
           ]

    assert Enum.map(results, & &1.id) == [
             "two_body_scalar_direct_2_r1",
             "two_body_scalar_direct_2_r2",
             "two_body_scenario_runner_2_r1",
             "two_body_scenario_runner_2_r2"
           ]

    assert Enum.map(results, & &1.metadata.repetition) == [1, 2, 1, 2]
    assert Enum.all?(results, &(&1.metadata.repetitions == 2))
    assert Enum.all?(results, &(&1.metadata.warmup_runs == 1))
  end

  test "rejects invalid benchmark run options" do
    assert_raise ArgumentError, "repetitions must be a positive integer", fn ->
      Benchmark.run(repetitions: 0)
    end

    assert_raise ArgumentError, "warmup_runs must be a non-negative integer", fn ->
      Benchmark.run(warmup_runs: -1)
    end
  end
end
