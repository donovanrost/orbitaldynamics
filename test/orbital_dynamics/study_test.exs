defmodule OrbitalDynamics.StudyTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Propagators.TwoBody
  alias OrbitalDynamics.Maneuver.ImpulsiveBurn
  alias OrbitalDynamics.{CentralBody, Epoch, Frame, Scenario, Spacecraft, StateVector, Study}

  test "creates a reproducible study manifest" do
    scenarios = [scenario(:a), scenario(:b)]

    assert %Study{
             id: :leo_access,
             scenarios: ^scenarios,
             propagator: TwoBody,
             propagator_opts: [max_step_s: 10.0],
             outputs: [:trajectories, :contacts],
             seed_manifest: %{monte_carlo: 42},
             metadata: %{description: "LEO access study"}
           } =
             Study.new!(:leo_access, scenarios,
               propagator_opts: [max_step_s: 10.0],
               outputs: [:trajectories, :contacts],
               seed_manifest: %{monte_carlo: 42},
               metadata: %{description: "LEO access study"}
             )
  end

  test "analyzes a study with the configured propagator" do
    study =
      Study.new!(:leo_access, [scenario(:a), scenario(:b)], propagator_opts: [max_step_s: 10.0])

    results = OrbitalDynamics.analyze_study(study)

    assert Enum.map(results, & &1.scenario_id) == [:a, :b]
    assert Enum.all?(results, &(&1.status == :ok))
    assert Enum.all?(results, &(&1.value.assumptions.max_step_s == 10.0))
  end

  test "rejects duplicate scenario ids" do
    scenarios = [scenario(:same), scenario(:same)]

    assert_raise ArgumentError, "scenario ids must be unique within a study", fn ->
      Study.new!(:duplicate_ids, scenarios)
    end
  end

  test "rejects invalid manifest fields" do
    assert_raise ArgumentError, "study id is required", fn ->
      Study.new!("", [scenario(:a)])
    end

    assert_raise ArgumentError,
                 "scenarios must be a non-empty list of OrbitalDynamics.Scenario structs",
                 fn ->
                   Study.new!(:empty, [])
                 end

    assert_raise ArgumentError, "outputs must be a non-empty list of atoms", fn ->
      Study.new!(:bad_outputs, [scenario(:a)], outputs: [])
    end
  end

  test "scenarios can carry impulsive maneuvers" do
    maneuver =
      ImpulsiveBurn.new!(
        :burn_1,
        Epoch.new!(60.0, :tdb),
        {0.0, 0.01, 0.0},
        Frame.earth_inertial_j2000()
      )

    scenario = scenario(:with_burn, maneuvers: [maneuver])

    assert scenario.maneuvers == [maneuver]
  end

  test "rejects invalid scenario maneuvers" do
    assert_raise ArgumentError,
                 "maneuvers must be a list of OrbitalDynamics.Maneuver.ImpulsiveBurn structs",
                 fn ->
                   scenario(:bad_maneuver, maneuvers: [:not_a_burn])
                 end
  end

  defp scenario(id, opts \\ []) do
    central_body = CentralBody.earth()
    radius_km = 7_000.0
    velocity_km_s = :math.sqrt(central_body.mu_km3_s2 / radius_km)

    state =
      StateVector.new!(
        {radius_km, 0.0, 0.0},
        {0.0, velocity_km_s, 0.0},
        Epoch.new!(0.0, :tdb),
        Frame.earth_inertial_j2000()
      )

    spacecraft = Spacecraft.new!(:"sat_#{id}", 250.0)

    scenario_opts =
      [
        duration_s: 600.0,
        output_step_s: 60.0,
        central_body: central_body
      ]
      |> Keyword.merge(opts)

    Scenario.new!(id, spacecraft, state, scenario_opts)
  end
end
