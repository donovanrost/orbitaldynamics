defmodule OrbitalDynamics.Propagators.TwoBodyDragTest do
  use ExUnit.Case, async: true

  defmodule StageFailingAtmosphereProvider do
    @behaviour OrbitalDynamics.Environment.Provider

    @impl true
    def capabilities do
      %{
        "id" => "environment.provider.atmosphere.stage_failure",
        "schema_contract" => "environment_provider_capability.v1",
        "category" => "atmosphere_density",
        "model" => "stage_failure_test_atmosphere",
        "source" => "test_fixture",
        "validation_level" => "test_only",
        "coverage" => %{
          "starts_at_s" => nil,
          "ends_at_s" => nil,
          "time_scale" => "seconds_since_j2000",
          "coverage_policy" => "all_times"
        },
        "interpolation" => "test_only",
        "supported_bodies" => ["earth"],
        "network_access" => false,
        "outputs" => ["density_kg_m3"],
        "known_limits" => ["fails away from the initial fixture altitude"]
      }
    end

    @impl true
    def fetch(:atmosphere_density, opts) do
      altitude_km = Keyword.fetch!(opts, :altitude_km)

      if abs(altitude_km - 400.0) <= 1.0e-12 do
        {:ok,
         %{
           "provider_id" => capabilities()["id"],
           "model" => capabilities()["model"],
           "density_kg_m3" => 3.89e-12
         }}
      else
        {:error, :stage_density_unavailable}
      end
    end
  end

  alias OrbitalDynamics.Environment.ExponentialAtmosphereProvider
  alias OrbitalDynamics.Maneuver.ImpulsiveBurn
  alias OrbitalDynamics.Propagators.{TwoBody, TwoBodyDrag}
  alias OrbitalDynamics.ResultSet.Artifact

  alias OrbitalDynamics.{
    CentralBody,
    Epoch,
    Frame,
    Scenario,
    Schema,
    Spacecraft,
    StateVector,
    Study,
    Vector3
  }

  test "declares an explicit programmatic-only scalar drag propagation boundary" do
    assert %{
             backend: :scalar_elixir,
             force_models: [:point_mass_two_body, :atmospheric_drag],
             numerical_methods: [:rk4_fixed_step],
             validation_level: :educational,
             supports_batching: false,
             supports_events: false,
             supports_maneuvers: true,
             supports_adaptive_step: false,
             supported_bodies: [:earth],
             supported_frames: [:eci_j2000],
             atmosphere_provider: :configurable_programmatic_option,
             manifest_support: :programmatic_only
           } = TwoBodyDrag.capabilities()
  end

  test "propagates deterministically with provider-backed drag and records provenance" do
    scenario = drag_scenario(duration_s: 3_600.0, output_step_s: 600.0, area_m2: 20.0)

    assert {:ok, drag_trajectory} = TwoBodyDrag.propagate(scenario, max_step_s: 10.0)
    assert TwoBodyDrag.propagate(scenario, max_step_s: 10.0) == {:ok, drag_trajectory}
    assert {:ok, two_body_trajectory} = TwoBody.propagate(scenario, max_step_s: 10.0)

    drag_final = List.last(drag_trajectory.states)
    two_body_final = List.last(two_body_trajectory.states)

    assert specific_energy(drag_final, scenario.central_body.mu_km3_s2) <
             specific_energy(two_body_final, scenario.central_body.mu_km3_s2)

    assert Vector3.norm(Vector3.subtract(drag_final.position_km, two_body_final.position_km)) >
             1.0e-4

    assert drag_trajectory.assumptions.force_model ==
             :point_mass_two_body_atmospheric_drag

    assert drag_trajectory.assumptions.force_models == [
             :point_mass_two_body,
             :atmospheric_drag
           ]

    assert drag_trajectory.assumptions.atmosphere_provider_id ==
             "environment.provider.atmosphere.exponential_reference"

    assert drag_trajectory.assumptions.atmosphere_provider_model ==
             "single_scale_height_exponential_atmosphere"

    assert drag_trajectory.assumptions.earth_rotation_provider_id ==
             "environment.provider.earth_rotation.constant_rate"

    assert drag_trajectory.assumptions.spacecraft_mass_kg == 120.0
    assert drag_trajectory.assumptions.drag_area_m2 == 20.0
    assert drag_trajectory.assumptions.drag_coefficient == 2.2
    assert drag_trajectory.assumptions.model_limits == TwoBodyDrag.model_limits()

    assert Artifact.trajectory_model_limits(drag_trajectory.assumptions) ==
             Enum.uniq(
               ["trajectory_summary_only", "state_samples_not_archived", "not_flight_certified"] ++
                 TwoBodyDrag.model_limits()
             )
  end

  test "zero-density provider parameters recover the fixed-step two-body states exactly" do
    scenario = drag_scenario(duration_s: 600.0, output_step_s: 120.0)

    opts = [
      max_step_s: 10.0,
      atmosphere_provider: {ExponentialAtmosphereProvider, reference_density_kg_m3: 0.0}
    ]

    assert {:ok, drag_trajectory} = TwoBodyDrag.propagate(scenario, opts)
    assert {:ok, two_body_trajectory} = TwoBody.propagate(scenario, max_step_s: 10.0)
    assert drag_trajectory.states == two_body_trajectory.states
  end

  test "supports aligned impulsive maneuvers without dropping drag provenance" do
    maneuver =
      ImpulsiveBurn.new!(
        :raise_apogee,
        Epoch.new!(60.0, :tdb),
        {0.0, 0.01, 0.0},
        Frame.earth_inertial_j2000()
      )

    baseline = drag_scenario(duration_s: 120.0, output_step_s: 60.0)

    maneuvered =
      drag_scenario(duration_s: 120.0, output_step_s: 60.0, maneuvers: [maneuver])

    assert {:ok, baseline_trajectory} = TwoBodyDrag.propagate(baseline, max_step_s: 10.0)
    assert {:ok, maneuvered_trajectory} = TwoBodyDrag.propagate(maneuvered, max_step_s: 10.0)

    assert maneuvered_trajectory.assumptions.maneuver_count == 1

    assert maneuvered_trajectory.assumptions.atmosphere_provider_id ==
             baseline_trajectory.assumptions.atmosphere_provider_id

    assert Enum.at(maneuvered_trajectory.states, 1).velocity_km_s !=
             Enum.at(baseline_trajectory.states, 1).velocity_km_s
  end

  test "runs through the public programmatic Study path" do
    scenario = drag_scenario(duration_s: 120.0, output_step_s: 60.0)

    study =
      Study.new!(:drag_study, [scenario],
        propagator: TwoBodyDrag,
        propagator_opts: [max_step_s: 10.0]
      )

    assert [result] = OrbitalDynamics.analyze_study(study)
    assert result.status == :ok
    assert result.value.assumptions.force_model == :point_mass_two_body_atmospheric_drag

    assert {:ok, result_set} = OrbitalDynamics.run_study(study)

    artifact =
      Artifact.build(result_set, generated_at: ~U[2026-07-20 00:00:00Z])

    assert [trajectory_summary] = artifact.trajectories
    assert trajectory_summary.force_model == "point_mass_two_body_atmospheric_drag"

    assert trajectory_summary.model_limits ==
             Artifact.trajectory_model_limits(result.value.assumptions)

    json_artifact =
      artifact
      |> :json.encode()
      |> IO.iodata_to_binary()
      |> :json.decode()

    assert {:ok, %{"schema_contract" => "result_artifact.v1", "status" => "pass"}} =
             Schema.validate_artifact(json_artifact, contract: "result_artifact.v1")
  end

  test "rejects invalid integration and ballistic inputs without raising" do
    scenario = drag_scenario(duration_s: 60.0, output_step_s: 60.0)

    assert {:error, {:invalid_option, :max_step_s}} =
             TwoBodyDrag.propagate(scenario, max_step_s: 0.0)

    assert {:error, {:invalid_option, :integration}} =
             TwoBodyDrag.propagate(scenario, integration: :adaptive_step)

    assert {:error, {:invalid_option, :options}} =
             TwoBodyDrag.propagate(scenario, [:not_keyword])

    missing_area = %{scenario | spacecraft: Spacecraft.new!(:missing_area, 100.0)}

    assert {:error, {:invalid_spacecraft, :drag_area_m2}} =
             TwoBodyDrag.propagate(missing_area)

    assert {:error, {:invalid_scenario, :central_body}} =
             TwoBodyDrag.propagate(%{scenario | central_body: nil})

    assert {:error, {:invalid_scenario, :initial_state_position_km}} =
             TwoBodyDrag.propagate(%{
               scenario
               | initial_state: %{scenario.initial_state | position_km: :bad}
             })
  end

  test "returns provider failures from intermediate RK4 stages" do
    scenario = drag_scenario(duration_s: 10.0, output_step_s: 10.0)

    assert {:error, :stage_density_unavailable} =
             TwoBodyDrag.propagate(scenario,
               max_step_s: 10.0,
               atmosphere_provider: StageFailingAtmosphereProvider
             )
  end

  defp drag_scenario(opts) do
    earth = CentralBody.earth()
    altitude_km = Keyword.get(opts, :altitude_km, 400.0)
    radius_km = earth.equatorial_radius_km + altitude_km
    velocity_km_s = :math.sqrt(earth.mu_km3_s2 / radius_km)

    state =
      StateVector.new!(
        {radius_km, 0.0, 0.0},
        {0.0, velocity_km_s, 0.0},
        Epoch.new!(0.0, :tdb),
        Frame.earth_inertial_j2000()
      )

    spacecraft =
      Spacecraft.new!(:drag_sat, 100.0,
        propellant_mass_kg: 20.0,
        area_m2: Keyword.get(opts, :area_m2, 4.0),
        drag_coefficient: 2.2
      )

    Scenario.new!(:drag_leo, spacecraft, state,
      duration_s: Keyword.fetch!(opts, :duration_s),
      output_step_s: Keyword.fetch!(opts, :output_step_s),
      central_body: earth,
      maneuvers: Keyword.get(opts, :maneuvers, [])
    )
  end

  defp specific_energy(state, mu_km3_s2) do
    velocity_km_s = Vector3.norm(state.velocity_km_s)
    radius_km = Vector3.norm(state.position_km)
    velocity_km_s * velocity_km_s / 2.0 - mu_km3_s2 / radius_km
  end
end
