defmodule OrbitalDynamics.ScenarioRunnerTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  alias OrbitalDynamics.ScenarioRunner

  test "evaluates scenarios concurrently while preserving input order" do
    parent = self()
    scenarios = for id <- [:a, :b, :c, :d], do: %{id: id}

    propagator = fn scenario ->
      send(parent, {:started, scenario.id, self()})

      receive do
        :continue -> {:ok, %{scenario_id: scenario.id}}
      after
        1_000 -> {:error, :not_released}
      end
    end

    runner =
      Task.async(fn ->
        ScenarioRunner.run(scenarios,
          propagator: propagator,
          max_concurrency: 4,
          timeout: 2_000
        )
      end)

    started =
      for _ <- scenarios do
        receive do
          {:started, id, pid} -> {id, pid}
        after
          1_000 -> flunk("expected all scenarios to start before releasing workers")
        end
      end

    assert started |> Enum.map(&elem(&1, 0)) |> Enum.sort() == [:a, :b, :c, :d]

    Enum.each(started, fn {_id, pid} -> send(pid, :continue) end)

    results = Task.await(runner, 2_000)

    assert Enum.map(results, & &1.scenario_id) == [:a, :b, :c, :d]
    assert Enum.map(results, & &1.scenario_index) == [0, 1, 2, 3]
    assert Enum.all?(results, &(&1.status == :ok))
    assert Enum.all?(results, &(&1.node == node()))
  end

  test "converts propagator errors into result structs" do
    scenarios = [%{id: :bad}]
    propagator = fn _scenario -> {:error, :failed_propagation} end

    assert [
             %ScenarioRunner.Result{
               scenario_id: :bad,
               status: :error,
               error: :failed_propagation
             }
           ] = ScenarioRunner.run(scenarios, propagator: propagator)
  end

  test "preserves selected source-manifest indexes" do
    scenarios = [%{id: :a}, %{id: :c}]
    propagator = fn scenario -> {:ok, %{scenario_id: scenario.id}} end

    results =
      ScenarioRunner.run(scenarios,
        propagator: propagator,
        scenario_indexes: [0, 2]
      )

    assert Enum.map(results, & &1.scenario_id) == [:a, :c]
    assert Enum.map(results, & &1.scenario_index) == [0, 2]

    assert_raise ArgumentError, ~r/unique ascending/, fn ->
      ScenarioRunner.run(scenarios,
        propagator: propagator,
        scenario_indexes: [2, 0]
      )
    end
  end

  test "preserves scenario id when a default task exits" do
    scenarios = [%{id: :exiting}]
    propagator = fn _scenario -> exit(:propagator_exit) end

    log =
      capture_log(fn ->
        assert [
                 %ScenarioRunner.Result{
                   scenario_id: :exiting,
                   scenario_index: 0,
                   status: :error,
                   error: {:task_exit, :propagator_exit}
                 }
               ] = ScenarioRunner.run(scenarios, propagator: propagator)
      end)

    assert log =~ ":propagator_exit"
  end

  test "preserves scenario id when a default task times out" do
    scenarios = [%{id: :timeout}]

    propagator = fn _scenario ->
      Process.sleep(:infinity)
    end

    assert [
             %ScenarioRunner.Result{
               scenario_id: :timeout,
               scenario_index: 0,
               status: :error,
               error: {:task_exit, :timeout}
             }
           ] = ScenarioRunner.run(scenarios, propagator: propagator, timeout: 1)
  end

  test "spreads work across multiple task supervisors while preserving input order" do
    scenarios = for id <- [:a, :b, :c, :d], do: %{id: id}
    propagator = fn scenario -> {:ok, %{scenario_id: scenario.id}} end

    results =
      ScenarioRunner.run(scenarios,
        propagator: propagator,
        max_concurrency: 2,
        task_supervisors: [
          OrbitalDynamics.ScenarioSupervisor,
          OrbitalDynamics.ScenarioSupervisor
        ]
      )

    assert Enum.map(results, & &1.scenario_id) == [:a, :b, :c, :d]
    assert Enum.map(results, & &1.scenario_index) == [0, 1, 2, 3]
    assert Enum.all?(results, &(&1.status == :ok))
    assert Enum.all?(results, &(&1.node == node()))
  end

  test "uses max concurrency per task supervisor in multi-supervisor mode" do
    parent = self()
    scenarios = for id <- [:a, :b, :c, :d], do: %{id: id}

    propagator = fn scenario ->
      send(parent, {:started, scenario.id, self()})

      receive do
        :continue -> {:ok, %{scenario_id: scenario.id}}
      after
        1_000 -> {:error, :not_released}
      end
    end

    runner =
      Task.async(fn ->
        ScenarioRunner.run(scenarios,
          propagator: propagator,
          max_concurrency: 2,
          task_supervisors: [
            OrbitalDynamics.ScenarioSupervisor,
            OrbitalDynamics.ScenarioSupervisor
          ]
        )
      end)

    started =
      for _ <- scenarios do
        receive do
          {:started, id, pid} -> {id, pid}
        after
          1_000 -> flunk("expected all scenarios to start before releasing workers")
        end
      end

    assert started |> Enum.map(&elem(&1, 0)) |> Enum.sort() == [:a, :b, :c, :d]

    Enum.each(started, fn {_id, pid} -> send(pid, :continue) end)

    results = Task.await(runner, 2_000)
    assert Enum.map(results, & &1.scenario_id) == [:a, :b, :c, :d]
  end

  test "chunks distributed task supervisor work while preserving input order" do
    parent = self()
    scenarios = for id <- [:a, :b, :c, :d], do: %{id: id}

    propagator = fn scenario ->
      send(parent, {:evaluated, scenario.id, self()})
      {:ok, %{scenario_id: scenario.id}}
    end

    results =
      ScenarioRunner.run(scenarios,
        propagator: propagator,
        max_concurrency: 2,
        task_chunk_size: 2,
        task_supervisors: [
          OrbitalDynamics.ScenarioSupervisor,
          OrbitalDynamics.ScenarioSupervisor
        ]
      )

    evaluations =
      for _ <- scenarios do
        receive do
          {:evaluated, id, pid} -> {id, pid}
        after
          1_000 -> flunk("expected every scenario to be evaluated")
        end
      end

    pids_by_id = Map.new(evaluations)

    assert pids_by_id[:a] == pids_by_id[:b]
    assert pids_by_id[:c] == pids_by_id[:d]
    assert pids_by_id[:a] != pids_by_id[:c]
    assert Enum.map(results, & &1.scenario_id) == [:a, :b, :c, :d]
  end

  test "resolves auto chunk size for distributed task supervisor waves" do
    assert ScenarioRunner.resolve_task_chunk_size(5,
             max_concurrency: 1,
             task_chunk_size: :auto,
             task_supervisors: [
               OrbitalDynamics.ScenarioSupervisor,
               OrbitalDynamics.ScenarioSupervisor
             ]
           ) == 2

    assert ScenarioRunner.task_chunking_recommendation(5,
             max_concurrency: 1,
             task_chunk_size: :auto,
             task_supervisors: [
               OrbitalDynamics.ScenarioSupervisor,
               OrbitalDynamics.ScenarioSupervisor
             ]
           ) == %{
             applied_task_chunk_size: 2,
             concurrent_task_batches: 2,
             policy: :auto,
             reason: "target_two_distributed_task_waves",
             recommended_task_chunk_size: 2,
             requested_task_chunk_size: :auto,
             supervisor_count: 2,
             target_wave_count: 2
           }
  end

  test "auto chunk size falls back to single-scenario chunks without supervisors" do
    assert ScenarioRunner.resolve_task_chunk_size(50,
             max_concurrency: 4,
             task_chunk_size: :auto
           ) == 1

    assert ScenarioRunner.task_chunking_recommendation(50,
             max_concurrency: 4,
             task_chunk_size: :auto
           ) == %{
             applied_task_chunk_size: 1,
             concurrent_task_batches: 4,
             policy: :not_applicable,
             reason: "task_chunking_requires_task_supervisors",
             recommended_task_chunk_size: 1,
             requested_task_chunk_size: :auto,
             supervisor_count: 0,
             target_wave_count: nil
           }
  end
end
