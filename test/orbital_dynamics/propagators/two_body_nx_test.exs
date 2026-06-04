defmodule OrbitalDynamics.Propagators.TwoBodyNxTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Benchmark.ScenarioFixture
  alias OrbitalDynamics.Maneuver.ImpulsiveBurn
  alias OrbitalDynamics.Propagators.{TwoBody, TwoBodyNx}
  alias OrbitalDynamics.{Epoch, Frame, Vector3}

  test "declares Nx batch capabilities" do
    assert %{
             backend: :nx,
             force_models: [:point_mass_two_body],
             numerical_methods: [:rk4_fixed_step],
             validation_level: :educational,
             supports_batching: true,
             supports_events: false,
             supports_maneuvers: false
           } = TwoBodyNx.capabilities()
  end

  test "matches scalar two-body propagation for homogeneous scenario batches" do
    scenarios =
      ScenarioFixture.circular_leo(
        count: 4,
        duration_s: 600.0,
        output_step_s: 120.0
      )

    assert {:ok, nx_trajectories} = TwoBodyNx.propagate_many(scenarios, max_step_s: 10.0)

    scalar_trajectories =
      Enum.map(scenarios, fn scenario ->
        assert {:ok, trajectory} = TwoBody.propagate(scenario, max_step_s: 10.0)
        trajectory
      end)

    assert Enum.map(nx_trajectories, & &1.scenario_id) ==
             Enum.map(scalar_trajectories, & &1.scenario_id)

    for {nx_trajectory, scalar_trajectory} <- Enum.zip(nx_trajectories, scalar_trajectories) do
      assert length(nx_trajectory.states) == length(scalar_trajectory.states)
      assert nx_trajectory.assumptions.backend == :nx

      for {nx_state, scalar_state} <- Enum.zip(nx_trajectory.states, scalar_trajectory.states) do
        assert_close_tuple(nx_state.position_km, scalar_state.position_km, 1.0e-3)
        assert_close_tuple(nx_state.velocity_km_s, scalar_state.velocity_km_s, 1.0e-6)
        assert nx_state.epoch == scalar_state.epoch
        assert nx_state.frame == scalar_state.frame
      end
    end
  end

  test "rejects unsupported heterogeneous batches" do
    [first, second] =
      ScenarioFixture.circular_leo(count: 2, duration_s: 600.0, output_step_s: 60.0)

    second = %{second | duration_s: 300.0}

    assert {:error, {:unsupported_batch, :heterogeneous_duration_s}} =
             TwoBodyNx.propagate_many([first, second], max_step_s: 10.0)
  end

  test "single-scenario propagate returns a normal trajectory" do
    [scenario] = ScenarioFixture.circular_leo(count: 1, duration_s: 120.0, output_step_s: 60.0)

    assert {:ok, trajectory} = TwoBodyNx.propagate(scenario, max_step_s: 10.0)
    assert trajectory.scenario_id == scenario.id
    assert length(trajectory.states) == 3
  end

  test "rejects maneuver scenarios because this backend does not support maneuvers yet" do
    [scenario] = ScenarioFixture.circular_leo(count: 1, duration_s: 120.0, output_step_s: 60.0)
    scenario = %{scenario | maneuvers: [maneuver()]}

    assert {:error, {:unsupported_scenario, :maneuvers}} =
             TwoBodyNx.propagate(scenario, max_step_s: 10.0)
  end

  defp assert_close_tuple(actual, expected, tolerance) do
    delta = actual |> Vector3.subtract(expected) |> Vector3.norm()
    assert delta <= tolerance
  end

  defp maneuver do
    ImpulsiveBurn.new!(
      :raise_apogee,
      Epoch.new!(55.0, :tdb),
      {0.0, 0.01, 0.0},
      Frame.earth_inertial_j2000()
    )
  end
end
