defmodule OrbitalDynamics.Propagators.TwoBodyNxCompiledTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Benchmark.ScenarioFixture
  alias OrbitalDynamics.Propagators.{TwoBody, TwoBodyNxCompiled}
  alias OrbitalDynamics.Vector3

  test "declares compiled Nx batch capabilities" do
    assert %{
             backend: :nx_compiled,
             force_models: [:point_mass_two_body],
             numerical_methods: [:rk4_fixed_step],
             validation_level: :educational,
             supports_batching: true,
             supports_events: false,
             supports_maneuvers: false
           } = TwoBodyNxCompiled.capabilities()
  end

  test "matches scalar two-body propagation for supported homogeneous batches" do
    scenarios =
      ScenarioFixture.circular_leo(
        count: 4,
        duration_s: 600.0,
        output_step_s: 120.0
      )

    assert {:ok, nx_trajectories} = TwoBodyNxCompiled.propagate_many(scenarios, max_step_s: 10.0)

    scalar_trajectories =
      Enum.map(scenarios, fn scenario ->
        assert {:ok, trajectory} = TwoBody.propagate(scenario, max_step_s: 10.0)
        trajectory
      end)

    assert Enum.map(nx_trajectories, & &1.scenario_id) ==
             Enum.map(scalar_trajectories, & &1.scenario_id)

    for {nx_trajectory, scalar_trajectory} <- Enum.zip(nx_trajectories, scalar_trajectories) do
      assert length(nx_trajectory.states) == length(scalar_trajectory.states)
      assert nx_trajectory.assumptions.backend == :nx_compiled

      for {nx_state, scalar_state} <- Enum.zip(nx_trajectory.states, scalar_trajectory.states) do
        assert_close_tuple(nx_state.position_km, scalar_state.position_km, 1.0e-3)
        assert_close_tuple(nx_state.velocity_km_s, scalar_state.velocity_km_s, 1.0e-6)
        assert nx_state.epoch == scalar_state.epoch
        assert nx_state.frame == scalar_state.frame
      end
    end
  end

  test "rejects batches that are not shape-stable for the compiled kernel" do
    [scenario] =
      ScenarioFixture.circular_leo(
        count: 1,
        duration_s: 100.0,
        output_step_s: 30.0
      )

    assert {:error, {:unsupported_batch, :duration_not_multiple_of_output_step_s}} =
             TwoBodyNxCompiled.propagate_many([scenario], max_step_s: 10.0)

    [scenario] =
      ScenarioFixture.circular_leo(
        count: 1,
        duration_s: 120.0,
        output_step_s: 30.0
      )

    assert {:error, {:unsupported_batch, :output_step_not_multiple_of_max_step_s}} =
             TwoBodyNxCompiled.propagate_many([scenario], max_step_s: 8.0)
  end

  test "single-scenario propagate returns a normal trajectory" do
    [scenario] = ScenarioFixture.circular_leo(count: 1, duration_s: 120.0, output_step_s: 60.0)

    assert {:ok, trajectory} = TwoBodyNxCompiled.propagate(scenario, max_step_s: 10.0)
    assert trajectory.scenario_id == scenario.id
    assert length(trajectory.states) == 3
  end

  defp assert_close_tuple(actual, expected, tolerance) do
    delta = actual |> Vector3.subtract(expected) |> Vector3.norm()
    assert delta <= tolerance
  end
end
