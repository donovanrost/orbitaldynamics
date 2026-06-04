defmodule OrbitalDynamics.Propagators.J2ExlaCpuTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Benchmark.ScenarioFixture
  alias OrbitalDynamics.Propagators.{J2, J2ExlaCpu}
  alias OrbitalDynamics.Vector3

  test "matches scalar J2 propagation for supported homogeneous batches" do
    scenarios = ScenarioFixture.circular_leo(count: 4, duration_s: 600.0, output_step_s: 120.0)

    assert {:ok, exla_trajectories} = J2ExlaCpu.propagate_many(scenarios, max_step_s: 10.0)

    scalar_trajectories =
      Enum.map(scenarios, fn scenario ->
        assert {:ok, trajectory} = J2.propagate(scenario, max_step_s: 10.0)
        trajectory
      end)

    for {exla_trajectory, scalar_trajectory} <- Enum.zip(exla_trajectories, scalar_trajectories) do
      assert exla_trajectory.scenario_id == scalar_trajectory.scenario_id
      assert exla_trajectory.assumptions.backend == :exla_cpu
      assert exla_trajectory.assumptions.force_model == :earth_j2

      for {exla_state, scalar_state} <- Enum.zip(exla_trajectory.states, scalar_trajectory.states) do
        assert_close_tuple(exla_state.position_km, scalar_state.position_km, 1.0e-3)
        assert_close_tuple(exla_state.velocity_km_s, scalar_state.velocity_km_s, 1.0e-6)
      end
    end
  end

  test "rejects unsupported non-Earth central bodies" do
    [scenario] = ScenarioFixture.circular_leo(count: 1)
    central_body = %{scenario.central_body | name: :mars}

    assert {:error, {:unsupported_scenario, :central_body}} =
             J2ExlaCpu.propagate_many([%{scenario | central_body: central_body}],
               max_step_s: 10.0
             )
  end

  defp assert_close_tuple(actual, expected, tolerance) do
    delta = actual |> Vector3.subtract(expected) |> Vector3.norm()
    assert delta <= tolerance
  end
end
