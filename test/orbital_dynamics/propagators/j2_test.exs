defmodule OrbitalDynamics.Propagators.J2Test do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Benchmark.ScenarioFixture
  alias OrbitalDynamics.Propagators.{J2, TwoBody}
  alias OrbitalDynamics.Vector3

  test "declares J2 capabilities" do
    assert %{
             backend: :scalar_elixir,
             force_models: [:point_mass_two_body, :j2],
             numerical_methods: [:rk4_fixed_step],
             validation_level: :educational,
             supports_maneuvers: true
           } = J2.capabilities()
  end

  test "J2 acceleration differs from two-body acceleration at the equator" do
    earth = OrbitalDynamics.CentralBody.earth()
    position = {7_000.0, 0.0, 0.0}

    j2_acceleration =
      J2.acceleration(position, earth.mu_km3_s2, earth.equatorial_radius_km, earth.j2)

    two_body_acceleration =
      Vector3.scale(position, -earth.mu_km3_s2 / :math.pow(Vector3.norm(position), 3))

    assert elem(j2_acceleration, 0) < elem(two_body_acceleration, 0)
    assert elem(j2_acceleration, 1) == 0.0
    assert elem(j2_acceleration, 2) == 0.0
  end

  test "propagates deterministically and records J2 assumptions" do
    [scenario] = ScenarioFixture.circular_leo(count: 1, duration_s: 600.0, output_step_s: 120.0)

    assert {:ok, trajectory} = J2.propagate(scenario, max_step_s: 10.0)
    assert J2.propagate(scenario, max_step_s: 10.0) == {:ok, trajectory}
    assert trajectory.assumptions.force_model == :earth_j2
    assert trajectory.assumptions.j2 == scenario.central_body.j2
    assert length(trajectory.states) == 6
  end

  test "J2 and two-body produce distinct trajectories" do
    [scenario] = ScenarioFixture.circular_leo(count: 1, duration_s: 3_600.0, output_step_s: 600.0)

    assert {:ok, j2_trajectory} = J2.propagate(scenario, max_step_s: 10.0)
    assert {:ok, two_body_trajectory} = TwoBody.propagate(scenario, max_step_s: 10.0)

    j2_final = List.last(j2_trajectory.states)
    two_body_final = List.last(two_body_trajectory.states)

    assert Vector3.norm(Vector3.subtract(j2_final.position_km, two_body_final.position_km)) > 0.1
  end
end
