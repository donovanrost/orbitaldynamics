defmodule OrbitalDynamics.Propagators.TwoBodyExlaCpuTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Benchmark.ScenarioFixture
  alias OrbitalDynamics.Maneuver.ImpulsiveBurn
  alias OrbitalDynamics.Propagators.{TwoBody, TwoBodyExlaCpu}
  alias OrbitalDynamics.{Epoch, Frame, Vector3}

  test "declares EXLA CPU batch capabilities" do
    assert %{
             backend: :exla_cpu,
             force_models: [:point_mass_two_body],
             numerical_methods: [:rk4_fixed_step],
             validation_level: :educational,
             supports_batching: true,
             supports_events: false,
             supports_maneuvers: false
           } = TwoBodyExlaCpu.capabilities()
  end

  test "matches scalar two-body propagation for supported homogeneous batches" do
    scenarios =
      ScenarioFixture.circular_leo(
        count: 4,
        duration_s: 120.0,
        output_step_s: 60.0
      )

    assert {:ok, exla_trajectories} = TwoBodyExlaCpu.propagate_many(scenarios, max_step_s: 10.0)

    scalar_trajectories =
      Enum.map(scenarios, fn scenario ->
        assert {:ok, trajectory} = TwoBody.propagate(scenario, max_step_s: 10.0)
        trajectory
      end)

    assert Enum.map(exla_trajectories, & &1.scenario_id) ==
             Enum.map(scalar_trajectories, & &1.scenario_id)

    for {exla_trajectory, scalar_trajectory} <- Enum.zip(exla_trajectories, scalar_trajectories) do
      assert length(exla_trajectory.states) == length(scalar_trajectory.states)
      assert exla_trajectory.assumptions.backend == :exla_cpu

      for {exla_state, scalar_state} <- Enum.zip(exla_trajectory.states, scalar_trajectory.states) do
        assert_close_tuple(exla_state.position_km, scalar_state.position_km, 1.0e-3)
        assert_close_tuple(exla_state.velocity_km_s, scalar_state.velocity_km_s, 1.0e-6)
        assert exla_state.epoch == scalar_state.epoch
        assert exla_state.frame == scalar_state.frame
      end
    end
  end

  test "rejects maneuver scenarios because this backend does not support maneuvers yet" do
    [scenario] = ScenarioFixture.circular_leo(count: 1, duration_s: 120.0, output_step_s: 60.0)
    scenario = %{scenario | maneuvers: [maneuver()]}

    assert {:error, {:unsupported_scenario, :maneuvers}} =
             TwoBodyExlaCpu.propagate(scenario, max_step_s: 10.0)
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
