defmodule OrbitalDynamics.Propagators.TwoBodyTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Propagators.TwoBody
  alias OrbitalDynamics.Maneuver.ImpulsiveBurn
  alias OrbitalDynamics.{CentralBody, Epoch, Frame, Scenario, Spacecraft, StateVector, Vector3}

  test "declares scalar two-body capabilities" do
    assert %{
             backend: :scalar_elixir,
             force_models: [:point_mass_two_body],
             numerical_methods: [:rk4_fixed_step, :rk4_adaptive_step_doubling],
             validation_level: :educational,
             supports_batching: false,
             supports_events: false,
             supports_maneuvers: true,
             supports_adaptive_step: true
           } = TwoBody.capabilities()
  end

  test "propagates a circular orbit through half a period" do
    central_body = CentralBody.earth()
    radius_km = 7_000.0
    velocity_km_s = :math.sqrt(central_body.mu_km3_s2 / radius_km)
    half_period_s = :math.pi() * :math.sqrt(:math.pow(radius_km, 3) / central_body.mu_km3_s2)

    scenario =
      circular_scenario(
        central_body: central_body,
        radius_km: radius_km,
        velocity_km_s: velocity_km_s,
        duration_s: half_period_s,
        output_step_s: half_period_s
      )

    assert {:ok, trajectory} = TwoBody.propagate(scenario, max_step_s: 5.0)
    [initial_state, final_state] = trajectory.states

    assert initial_state == scenario.initial_state
    assert_close_tuple(final_state.position_km, {-radius_km, 0.0, 0.0}, 0.02)
    assert_close_tuple(final_state.velocity_km_s, {0.0, -velocity_km_s, 0.0}, 0.00005)
    assert_in_delta final_state.epoch.seconds_since_j2000, half_period_s, 1.0e-9

    assert trajectory.assumptions.force_model == :point_mass_two_body
    assert trajectory.assumptions.numerical_method == :rk4_fixed_step
    assert trajectory.assumptions.position_unit == :kilometer
  end

  test "returns deterministic output for repeated runs" do
    central_body = CentralBody.earth()
    radius_km = 7_000.0
    velocity_km_s = :math.sqrt(central_body.mu_km3_s2 / radius_km)

    scenario =
      circular_scenario(
        central_body: central_body,
        radius_km: radius_km,
        velocity_km_s: velocity_km_s,
        duration_s: 600.0,
        output_step_s: 120.0
      )

    assert TwoBody.propagate(scenario, max_step_s: 10.0) ==
             TwoBody.propagate(scenario, max_step_s: 10.0)
  end

  test "includes a final sample when output cadence does not divide duration" do
    scenario = circular_scenario(duration_s: 100.0, output_step_s: 30.0)

    assert {:ok, trajectory} = TwoBody.propagate(scenario, max_step_s: 10.0)

    assert Enum.map(trajectory.states, & &1.epoch.seconds_since_j2000) == [
             0.0,
             30.0,
             60.0,
             90.0,
             100.0
           ]
  end

  test "keeps a zero-duration scenario at the initial state" do
    scenario = circular_scenario(duration_s: 0.0, output_step_s: 60.0)

    assert {:ok, trajectory} = TwoBody.propagate(scenario, max_step_s: 10.0)
    assert trajectory.states == [scenario.initial_state]
  end

  test "approximately conserves specific energy and angular momentum" do
    central_body = CentralBody.earth()
    radius_km = 7_000.0
    velocity_km_s = :math.sqrt(central_body.mu_km3_s2 / radius_km)
    period_s = 2.0 * :math.pi() * :math.sqrt(:math.pow(radius_km, 3) / central_body.mu_km3_s2)

    scenario =
      circular_scenario(
        central_body: central_body,
        radius_km: radius_km,
        velocity_km_s: velocity_km_s,
        duration_s: period_s,
        output_step_s: period_s / 8.0
      )

    assert {:ok, trajectory} = TwoBody.propagate(scenario, max_step_s: 5.0)

    initial_energy = specific_energy(scenario.initial_state, central_body.mu_km3_s2)
    initial_h = specific_angular_momentum(scenario.initial_state)

    for state <- trajectory.states do
      assert_in_delta specific_energy(state, central_body.mu_km3_s2), initial_energy, 1.0e-8
      assert_close_tuple(specific_angular_momentum(state), initial_h, 1.0e-5)
    end
  end

  test "supports deterministic adaptive step-doubling propagation when explicitly requested" do
    central_body = CentralBody.earth()
    radius_km = 7_000.0
    velocity_km_s = :math.sqrt(central_body.mu_km3_s2 / radius_km)
    half_period_s = :math.pi() * :math.sqrt(:math.pow(radius_km, 3) / central_body.mu_km3_s2)

    scenario =
      circular_scenario(
        central_body: central_body,
        radius_km: radius_km,
        velocity_km_s: velocity_km_s,
        duration_s: half_period_s,
        output_step_s: half_period_s
      )

    opts = [
      integration: :adaptive_step,
      max_step_s: 120.0,
      min_step_s: 1.0,
      adaptive_position_tolerance_km: 1.0e-3,
      adaptive_velocity_tolerance_km_s: 1.0e-6
    ]

    assert {:ok, trajectory} = TwoBody.propagate(scenario, opts)
    assert TwoBody.propagate(scenario, opts) == {:ok, trajectory}

    [initial_state, final_state] = trajectory.states

    assert initial_state == scenario.initial_state
    assert_close_tuple(final_state.position_km, {-radius_km, 0.0, 0.0}, 0.05)
    assert_close_tuple(final_state.velocity_km_s, {0.0, -velocity_km_s, 0.0}, 0.0001)

    assert trajectory.assumptions.numerical_method == :rk4_adaptive_step_doubling
    assert trajectory.assumptions.integration_mode == :adaptive_step
    assert trajectory.assumptions.max_step_s == 120.0
    assert trajectory.assumptions.min_step_s == 1.0
    assert trajectory.assumptions.adaptive_position_tolerance_km == 1.0e-3
    assert trajectory.assumptions.adaptive_velocity_tolerance_km_s == 1.0e-6
    assert trajectory.assumptions.adaptive_accepted_step_count > 0
    assert trajectory.assumptions.adaptive_max_accepted_step_s <= 120.0
    assert trajectory.assumptions.adaptive_min_accepted_step_s >= 1.0
    assert trajectory.assumptions.adaptive_error_estimate == :step_doubling
  end

  test "applies an aligned impulsive burn during propagation" do
    maneuver =
      ImpulsiveBurn.new!(
        :raise_apogee,
        Epoch.new!(60.0, :tdb),
        {0.0, 0.01, 0.0},
        Frame.earth_inertial_j2000()
      )

    baseline = circular_scenario(duration_s: 120.0, output_step_s: 60.0)
    scenario = circular_scenario(duration_s: 120.0, output_step_s: 60.0, maneuvers: [maneuver])

    assert {:ok, baseline_trajectory} = TwoBody.propagate(baseline, max_step_s: 10.0)
    assert {:ok, maneuvered_trajectory} = TwoBody.propagate(scenario, max_step_s: 10.0)

    baseline_at_burn = Enum.at(baseline_trajectory.states, 1)
    maneuvered_at_burn = Enum.at(maneuvered_trajectory.states, 1)

    assert_in_delta Vector3.norm(maneuvered_at_burn.velocity_km_s) -
                      Vector3.norm(baseline_at_burn.velocity_km_s),
                    0.01,
                    1.0e-4

    assert maneuvered_trajectory.assumptions.maneuver_count == 1
    assert_in_delta maneuvered_trajectory.assumptions.total_delta_v_km_s, 0.01, 1.0e-12

    assert [%{id: :raise_apogee, type: :impulsive_burn}] =
             maneuvered_trajectory.assumptions.maneuvers
  end

  test "applies an off-step impulsive burn by segmenting propagation at the burn epoch" do
    maneuver =
      ImpulsiveBurn.new!(
        :off_step,
        Epoch.new!(55.0, :tdb),
        {0.0, 0.01, 0.0},
        Frame.earth_inertial_j2000()
      )

    baseline = circular_scenario(duration_s: 120.0, output_step_s: 60.0)
    scenario = circular_scenario(duration_s: 120.0, output_step_s: 60.0, maneuvers: [maneuver])

    assert {:ok, baseline_trajectory} = TwoBody.propagate(baseline, max_step_s: 10.0)
    assert {:ok, maneuvered_trajectory} = TwoBody.propagate(scenario, max_step_s: 10.0)

    baseline_final = List.last(baseline_trajectory.states)
    maneuvered_final = List.last(maneuvered_trajectory.states)

    assert Vector3.norm(
             Vector3.subtract(maneuvered_final.velocity_km_s, baseline_final.velocity_km_s)
           ) >
             0.005

    assert maneuvered_trajectory.assumptions.maneuver_count == 1
  end

  test "composes multiple burns at the same sample epoch before returning that sample" do
    burns = [
      ImpulsiveBurn.new!(
        :burn_1,
        Epoch.new!(60.0, :tdb),
        {0.0, 0.01, 0.0},
        Frame.earth_inertial_j2000()
      ),
      ImpulsiveBurn.new!(
        :burn_2,
        Epoch.new!(60.0, :tdb),
        {0.0, 0.02, 0.0},
        Frame.earth_inertial_j2000()
      )
    ]

    baseline = circular_scenario(duration_s: 120.0, output_step_s: 60.0)
    scenario = circular_scenario(duration_s: 120.0, output_step_s: 60.0, maneuvers: burns)

    assert {:ok, baseline_trajectory} = TwoBody.propagate(baseline, max_step_s: 10.0)
    assert {:ok, maneuvered_trajectory} = TwoBody.propagate(scenario, max_step_s: 10.0)

    baseline_at_burn = Enum.at(baseline_trajectory.states, 1)
    maneuvered_at_burn = Enum.at(maneuvered_trajectory.states, 1)

    assert_in_delta Vector3.norm(maneuvered_at_burn.velocity_km_s) -
                      Vector3.norm(baseline_at_burn.velocity_km_s),
                    0.03,
                    1.0e-4

    assert maneuvered_trajectory.assumptions.maneuver_count == 2
    assert_in_delta maneuvered_trajectory.assumptions.total_delta_v_km_s, 0.03, 1.0e-12
  end

  test "rejects an invalid numerical step" do
    scenario = circular_scenario(duration_s: 60.0, output_step_s: 60.0)

    assert {:error, {:invalid_option, :max_step_s}} = TwoBody.propagate(scenario, max_step_s: 0.0)

    assert {:error, {:invalid_option, :integration}} =
             TwoBody.propagate(scenario, integration: :root_solved)

    assert {:error, {:invalid_option, :min_step_s}} =
             TwoBody.propagate(scenario,
               integration: :adaptive_step,
               max_step_s: 10.0,
               min_step_s: 20.0
             )

    assert {:error, {:invalid_option, :adaptive_position_tolerance_km}} =
             TwoBody.propagate(scenario,
               integration: :adaptive_step,
               adaptive_position_tolerance_km: 0.0
             )
  end

  test "safe propagation rejects invalid domain inputs without raising" do
    scenario = circular_scenario(duration_s: 60.0, output_step_s: 60.0)

    zero_radius_state = %StateVector{scenario.initial_state | position_km: {0.0, 0.0, 0.0}}
    invalid_radius = %Scenario{scenario | initial_state: zero_radius_state}
    invalid_mu = %Scenario{scenario | central_body: %CentralBody{name: :invalid, mu_km3_s2: 0.0}}

    assert {:error, {:invalid_scenario, :initial_state_radius_km}} =
             TwoBody.propagate(invalid_radius, max_step_s: 10.0)

    assert {:error, {:invalid_scenario, :central_body_mu_km3_s2}} =
             TwoBody.propagate(invalid_mu, max_step_s: 10.0)
  end

  defp circular_scenario(opts) do
    central_body = Keyword.get(opts, :central_body, CentralBody.earth())
    radius_km = Keyword.get(opts, :radius_km, 7_000.0)

    velocity_km_s =
      Keyword.get(opts, :velocity_km_s, :math.sqrt(central_body.mu_km3_s2 / radius_km))

    duration_s = Keyword.fetch!(opts, :duration_s)
    output_step_s = Keyword.fetch!(opts, :output_step_s)
    maneuvers = Keyword.get(opts, :maneuvers, [])

    state =
      StateVector.new!(
        {radius_km, 0.0, 0.0},
        {0.0, velocity_km_s, 0.0},
        Epoch.new!(0.0, :tdb),
        Frame.earth_inertial_j2000()
      )

    spacecraft = Spacecraft.new!(:observer, 250.0)

    Scenario.new!(:leo_circular, spacecraft, state,
      duration_s: duration_s,
      output_step_s: output_step_s,
      central_body: central_body,
      maneuvers: maneuvers
    )
  end

  defp assert_close_tuple(actual, expected, tolerance) do
    delta = actual |> Vector3.subtract(expected) |> Vector3.norm()
    assert delta <= tolerance
  end

  defp specific_energy(state, mu_km3_s2) do
    velocity_norm = Vector3.norm(state.velocity_km_s)
    radius_norm = Vector3.norm(state.position_km)

    velocity_norm * velocity_norm / 2.0 - mu_km3_s2 / radius_norm
  end

  defp specific_angular_momentum(state) do
    Vector3.cross(state.position_km, state.velocity_km_s)
  end
end
