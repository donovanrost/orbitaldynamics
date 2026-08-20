defmodule OrbitalDynamics.Propagators.J2DragTest do
  use ExUnit.Case, async: true

  defmodule CountingAtmosphereProvider do
    @behaviour OrbitalDynamics.Environment.Provider

    @impl true
    def capabilities do
      send(self(), :counting_provider_capability_read)

      capability(
        "environment.provider.atmosphere.counting_fixture",
        "counting_zero_density_fixture",
        nil,
        nil
      )
    end

    @impl true
    def fetch(:atmosphere_density, _opts) do
      send(self(), :counting_provider_density_fetch)

      {:ok,
       %{
         "provider_id" => "environment.provider.atmosphere.counting_fixture",
         "model" => "counting_zero_density_fixture",
         "density_kg_m3" => 0.0
       }}
    end

    defp capability(id, model, starts_at_s, ends_at_s) do
      %{
        "id" => id,
        "schema_contract" => "environment_provider_capability.v1",
        "category" => "atmosphere_density",
        "model" => model,
        "source" => "test_fixture",
        "validation_level" => "test_only",
        "coverage" => %{
          "starts_at_s" => starts_at_s,
          "ends_at_s" => ends_at_s,
          "time_scale" => "seconds_since_j2000",
          "coverage_policy" => "declared_test_span"
        },
        "interpolation" => "constant",
        "supported_bodies" => ["earth"],
        "network_access" => false,
        "outputs" => ["density_kg_m3"],
        "known_limits" => ["test fixture only"]
      }
    end
  end

  defmodule FiniteCoverageAtmosphereProvider do
    @behaviour OrbitalDynamics.Environment.Provider

    @impl true
    def capabilities do
      %{
        "id" => "environment.provider.atmosphere.finite_fixture",
        "schema_contract" => "environment_provider_capability.v1",
        "category" => "atmosphere_density",
        "model" => "finite_zero_density_fixture",
        "source" => "test_fixture",
        "validation_level" => "test_only",
        "coverage" => %{
          "starts_at_s" => 0.0,
          "ends_at_s" => 60.0,
          "time_scale" => "seconds_since_j2000",
          "coverage_policy" => "declared_test_span"
        },
        "interpolation" => "constant",
        "supported_bodies" => ["earth"],
        "network_access" => false,
        "outputs" => ["density_kg_m3"],
        "known_limits" => ["test fixture only"]
      }
    end

    @impl true
    def fetch(:atmosphere_density, _opts) do
      {:ok,
       %{
         "provider_id" => "environment.provider.atmosphere.finite_fixture",
         "model" => "finite_zero_density_fixture",
         "density_kg_m3" => 0.0
       }}
    end
  end

  defmodule MalformedDensityProvider do
    @behaviour OrbitalDynamics.Environment.Provider

    @impl true
    def capabilities do
      %{
        "id" => "environment.provider.atmosphere.malformed_fixture",
        "schema_contract" => "environment_provider_capability.v1",
        "category" => "atmosphere_density",
        "model" => "malformed_density_fixture",
        "source" => "test_fixture",
        "validation_level" => "test_only",
        "coverage" => %{
          "starts_at_s" => nil,
          "ends_at_s" => nil,
          "time_scale" => "seconds_since_j2000",
          "coverage_policy" => "all_times"
        },
        "interpolation" => "constant",
        "supported_bodies" => ["earth"],
        "network_access" => false,
        "outputs" => ["density_kg_m3"],
        "known_limits" => ["returns a malformed test density"]
      }
    end

    @impl true
    def fetch(:atmosphere_density, _opts) do
      {:ok,
       %{
         "provider_id" => "environment.provider.atmosphere.malformed_fixture",
         "model" => "malformed_density_fixture",
         "density_kg_m3" => -1.0
       }}
    end
  end

  defmodule ExtremeDensityProvider do
    @behaviour OrbitalDynamics.Environment.Provider

    @impl true
    def capabilities do
      %{
        "id" => "environment.provider.atmosphere.extreme_fixture",
        "schema_contract" => "environment_provider_capability.v1",
        "category" => "atmosphere_density",
        "model" => "extreme_density_fixture",
        "source" => "test_fixture",
        "validation_level" => "test_only",
        "coverage" => %{
          "starts_at_s" => nil,
          "ends_at_s" => nil,
          "time_scale" => "seconds_since_j2000",
          "coverage_policy" => "all_times"
        },
        "interpolation" => "constant",
        "supported_bodies" => ["earth"],
        "network_access" => false,
        "outputs" => ["density_kg_m3"],
        "known_limits" => ["returns an extreme test density or raises arithmetic"]
      }
    end

    @impl true
    def fetch(:atmosphere_density, _opts) do
      if Process.get(:j2_drag_extreme_density_case) == :raise_arithmetic do
        raise ArithmeticError, "test provider arithmetic failure"
      end

      {:ok,
       %{
         "provider_id" => "environment.provider.atmosphere.extreme_fixture",
         "model" => "extreme_density_fixture",
         "density_kg_m3" => 1.0e300
       }}
    end
  end

  defmodule RejectedPolicyAtmosphereProvider do
    @behaviour OrbitalDynamics.Environment.Provider

    @impl true
    def capabilities do
      policy_case = Process.get(:j2_drag_rejected_policy_case)

      %{
        "id" => "environment.provider.atmosphere.rejected_policy_fixture",
        "schema_contract" => "environment_provider_capability.v1",
        "category" => "atmosphere_density",
        "model" => "rejected_policy_density_fixture",
        "source" => "test_fixture",
        "validation_level" => "test_only",
        "coverage" => %{
          "starts_at_s" => nil,
          "ends_at_s" => nil,
          "time_scale" =>
            if(policy_case == :unsupported_time_scale,
              do: "tai_seconds_since_j2000",
              else: "seconds_since_j2000"
            ),
          "coverage_policy" => "all_times"
        },
        "interpolation" => "constant",
        "supported_bodies" => ["earth"],
        "network_access" => policy_case == :network_access,
        "trust_boundary" => "test_only_network_boundary",
        "outputs" => ["density_kg_m3"],
        "known_limits" => ["test fixture only"]
      }
    end

    @impl true
    def fetch(:atmosphere_density, _opts) do
      {:ok,
       %{
         "provider_id" => "environment.provider.atmosphere.rejected_policy_fixture",
         "model" => "rejected_policy_density_fixture",
         "density_kg_m3" => 0.0
       }}
    end
  end

  alias OrbitalDynamics.Environment.ExponentialAtmosphereProvider
  alias OrbitalDynamics.Maneuver.ImpulsiveBurn
  alias OrbitalDynamics.Propagators.{J2, J2Drag, TwoBody, TwoBodyDrag}

  alias OrbitalDynamics.{
    CentralBody,
    Epoch,
    Frame,
    Scenario,
    Spacecraft,
    StateVector,
    Vector3
  }

  test "declares the bounded opt-in scalar combined-force capability" do
    zero = 0.0

    assert %{
             backend: :scalar_elixir,
             force_models: [:point_mass_two_body, :j2, :atmospheric_drag],
             force_composition: :single_acceleration_sum_per_rk4_stage,
             numerical_methods: [:rk4_fixed_step],
             validation_level: :educational,
             supports_maneuvers: false,
             supported_bodies: [:earth],
             supported_frames: [:eci_j2000],
             supported_time_scales: [:tdb],
             duration_envelope_s: %{maximum: 86_400.0},
             output_step_envelope_s: %{maximum: 86_400.0},
             max_step_envelope_s: %{default: 10.0, maximum: 30.0},
             supported_numeric_envelope: %{
               central_body: %{
                 mu_km3_s2: %{minimum: 350_000.0, maximum: 450_000.0},
                 equatorial_radius_km: %{minimum: 6_000.0, maximum: 7_000.0},
                 j2: %{minimum: ^zero, maximum: 2.0e-3}
               },
               spacecraft: %{
                 total_mass_kg: %{minimum: 0.1, maximum: 10_000_000.0},
                 drag_area_m2: %{minimum: ^zero, maximum: 1_000_000.0},
                 drag_coefficient: %{minimum: ^zero, maximum: 5.0}
               },
               environment: %{
                 density_kg_m3: %{minimum: ^zero, maximum: 1.0e-3}
               }
             },
             manifest_support: false,
             planning_horizon_step_convergence: %{
               evidence_type: :internal_numerical_step_convergence,
               external_acceptance: false,
               horizon_s: 86_400.0
             }
           } = J2Drag.capabilities()

    assert OrbitalDynamics.capability_catalog().analysis.propagators.j2_drag ==
             J2Drag.capabilities()

    scenario = scenario(duration_s: 60.0, output_step_s: 60.0)
    assert OrbitalDynamics.propagate(scenario) == TwoBody.propagate(scenario)
  end

  test "instantaneous total acceleration is the declared component vector sum" do
    scenario = scenario(duration_s: 60.0, output_step_s: 60.0)

    assert {:ok, result} =
             OrbitalDynamics.j2_drag_acceleration(
               scenario.initial_state,
               scenario.spacecraft,
               scenario.central_body
             )

    expected_total =
      result.point_mass_acceleration_km_s2
      |> Vector3.add(result.j2_acceleration_km_s2)
      |> Vector3.add(result.atmospheric_drag_acceleration_km_s2)

    assert result.total_acceleration_km_s2 == expected_total
    assert result.force_composition == :direct_component_vector_sum
    assert result.force_models == [:point_mass_two_body, :j2, :atmospheric_drag]
    assert result.atmosphere_provider.source == "internal_reference_model"
    assert result.atmosphere_provider.source_revision == "exponential-reference.v1"
    assert result.atmosphere_provider.coverage["coverage_policy"] == "all_times"
    assert result.atmosphere_provider.network_access == false
    assert result.earth_rotation_provider.source_revision == "constant-earth-rotation.v1"
  end

  test "propagates deterministically with exact initial-state and output-cadence semantics" do
    scenario = scenario(duration_s: 65.0, output_step_s: 30.0)

    assert {:ok, trajectory} = OrbitalDynamics.propagate_j2_drag(scenario, max_step_s: 10.0)
    assert OrbitalDynamics.propagate_j2_drag(scenario, max_step_s: 10.0) == {:ok, trajectory}

    assert hd(trajectory.states) == scenario.initial_state

    assert Enum.map(trajectory.states, & &1.epoch.seconds_since_j2000) == [
             0.0,
             30.0,
             60.0,
             65.0
           ]

    assert trajectory.assumptions.force_model == :earth_j2_atmospheric_drag

    assert trajectory.assumptions.environment_policy ==
             :offline_immutable_captured_once_before_integration

    assert trajectory.assumptions.spacecraft_ballistic_parameters == %{
             mass_kg: 120.0,
             drag_area_m2: 4.0,
             drag_coefficient: 2.2
           }

    assert trajectory.assumptions.atmosphere_provider.source_revision ==
             "exponential-reference.v1"

    assert trajectory.assumptions.atmosphere_provider.coverage["coverage_policy"] ==
             "all_times"

    assert trajectory.assumptions.validation_evidence ==
             :internal_step_convergence_not_external_acceptance
  end

  test "zero drag matches J2 and disabled J2 matches two-body drag" do
    scenario = scenario(duration_s: 600.0, output_step_s: 120.0)

    zero_drag_opts = [
      max_step_s: 10.0,
      atmosphere_provider: {ExponentialAtmosphereProvider, reference_density_kg_m3: 0.0}
    ]

    assert {:ok, combined_zero_drag} = J2Drag.propagate(scenario, zero_drag_opts)
    assert {:ok, j2_reference} = J2.propagate(scenario, max_step_s: 10.0)
    assert combined_zero_drag.states == j2_reference.states

    assert combined_zero_drag.assumptions.atmosphere_provider.parameters[
             "reference_density_kg_m3"
           ] == 0.0

    earth_without_j2 = %{scenario.central_body | j2: 0.0}
    no_j2_scenario = %{scenario | central_body: earth_without_j2}

    assert {:ok, combined_no_j2} = J2Drag.propagate(no_j2_scenario, max_step_s: 10.0)
    assert {:ok, drag_reference} = TwoBodyDrag.propagate(no_j2_scenario, max_step_s: 10.0)
    assert combined_no_j2.states == drag_reference.states
  end

  test "inclined controlled limits exercise J2 out-of-plane acceleration and combined drag" do
    scenario = inclined_scenario(duration_s: 600.0, output_step_s: 120.0)

    assert {:ok, components} =
             OrbitalDynamics.j2_drag_acceleration(
               scenario.initial_state,
               scenario.spacecraft,
               scenario.central_body
             )

    assert abs(elem(components.j2_acceleration_km_s2, 2)) > 0.0
    assert Vector3.norm(components.atmospheric_drag_acceleration_km_s2) > 0.0

    zero_drag_opts = [
      max_step_s: 10.0,
      atmosphere_provider: {ExponentialAtmosphereProvider, reference_density_kg_m3: 0.0}
    ]

    assert {:ok, combined_zero_drag} = J2Drag.propagate(scenario, zero_drag_opts)
    assert {:ok, j2_reference} = J2.propagate(scenario, max_step_s: 10.0)
    assert combined_zero_drag.states == j2_reference.states

    no_j2_scenario = %{scenario | central_body: %{scenario.central_body | j2: 0.0}}

    assert {:ok, combined_no_j2} = J2Drag.propagate(no_j2_scenario, max_step_s: 10.0)
    assert {:ok, drag_reference} = TwoBodyDrag.propagate(no_j2_scenario, max_step_s: 10.0)
    assert combined_no_j2.states == drag_reference.states
  end

  test "acceleration rejects unsupported finite numeric extremes deterministically" do
    scenario = scenario(duration_s: 60.0, output_step_s: 60.0)
    extreme = 1.0e300

    cases = [
      {
        %{scenario | spacecraft: %{scenario.spacecraft | dry_mass_kg: extreme}},
        [],
        {:error, {:unsupported_spacecraft, :spacecraft_mass_kg}}
      },
      {
        %{scenario | spacecraft: %{scenario.spacecraft | area_m2: extreme}},
        [],
        {:error, {:unsupported_spacecraft, :drag_area_m2}}
      },
      {
        %{scenario | spacecraft: %{scenario.spacecraft | drag_coefficient: extreme}},
        [],
        {:error, {:unsupported_spacecraft, :drag_coefficient}}
      },
      {
        %{scenario | central_body: %{scenario.central_body | mu_km3_s2: extreme}},
        [],
        {:error, {:unsupported_scenario, :central_body_mu_km3_s2}}
      },
      {
        %{scenario | central_body: %{scenario.central_body | equatorial_radius_km: extreme}},
        [],
        {:error, {:unsupported_scenario, :equatorial_radius_km}}
      },
      {
        %{scenario | central_body: %{scenario.central_body | j2: extreme}},
        [],
        {:error, {:unsupported_scenario, :j2}}
      },
      {
        %{
          scenario
          | initial_state: %{scenario.initial_state | velocity_km_s: {0.0, extreme, 0.0}}
        },
        [],
        {:error, {:unsupported_state, :velocity_km_s}}
      },
      {
        scenario,
        [
          atmosphere_provider: ExtremeDensityProvider,
          atmosphere_source_revision: "extreme-density.v1"
        ],
        {:error, {:unsupported_environment_product, :density_kg_m3}}
      },
      {
        scenario,
        [
          atmosphere_provider:
            {ExponentialAtmosphereProvider, reference_altitude_km: 2_000.0, scale_height_km: 1.0}
        ],
        {:error, {:unsupported_environment_provider_parameter, :exponential_argument}}
      }
    ]

    Enum.each(cases, fn {case_scenario, opts, expected} ->
      assert_acceleration_error(case_scenario, opts, expected)
    end)

    huge_integer = Integer.pow(10, 400)

    assert_acceleration_error(
      scenario,
      [
        atmosphere_provider:
          {ExponentialAtmosphereProvider, reference_density_kg_m3: huge_integer}
      ],
      {:error, {:environment_provider_error, :capability_arithmetic}}
    )

    Process.put(:j2_drag_extreme_density_case, :raise_arithmetic)

    assert_acceleration_error(
      scenario,
      [
        atmosphere_provider: ExtremeDensityProvider,
        atmosphere_source_revision: "arithmetic-density.v1"
      ],
      {:error, {:environment_provider_error, :atmosphere_density_arithmetic}}
    )
  end

  test "propagation preflight rejects unsupported finite numeric extremes deterministically" do
    scenario = scenario(duration_s: 60.0, output_step_s: 60.0)
    extreme = 1.0e300

    cases = [
      {
        %{scenario | spacecraft: %{scenario.spacecraft | dry_mass_kg: extreme}},
        [],
        {:error, {:unsupported_spacecraft, :spacecraft_mass_kg}}
      },
      {
        %{scenario | spacecraft: %{scenario.spacecraft | area_m2: extreme}},
        [],
        {:error, {:unsupported_spacecraft, :drag_area_m2}}
      },
      {
        %{scenario | spacecraft: %{scenario.spacecraft | drag_coefficient: extreme}},
        [],
        {:error, {:unsupported_spacecraft, :drag_coefficient}}
      },
      {
        %{scenario | central_body: %{scenario.central_body | mu_km3_s2: extreme}},
        [],
        {:error, {:unsupported_scenario, :central_body_mu_km3_s2}}
      },
      {
        %{scenario | initial_state: %{scenario.initial_state | position_km: {extreme, 0.0, 0.0}}},
        [],
        {:error, {:unsupported_state, :position_km}}
      },
      {
        scenario,
        [
          atmosphere_provider: ExtremeDensityProvider,
          atmosphere_source_revision: "extreme-density.v1"
        ],
        {:error, {:unsupported_environment_product, :density_kg_m3}}
      },
      {
        scenario,
        [
          atmosphere_provider:
            {ExponentialAtmosphereProvider, reference_altitude_km: 2_000.0, scale_height_km: 1.0}
        ],
        {:error, {:unsupported_environment_provider_parameter, :exponential_argument}}
      },
      {
        %{scenario | output_step_s: extreme},
        [],
        {:error, {:unsupported_scenario, :output_step_s}}
      }
    ]

    Enum.each(cases, fn {case_scenario, opts, expected} ->
      assert_propagation_error(case_scenario, opts, expected)
    end)

    Process.put(:j2_drag_extreme_density_case, :raise_arithmetic)

    assert_propagation_error(
      scenario,
      [
        atmosphere_provider: ExtremeDensityProvider,
        atmosphere_source_revision: "arithmetic-density.v1"
      ],
      {:error, {:environment_provider_error, :atmosphere_density_arithmetic}}
    )
  end

  test "captures provider policy once and requires custom source revision" do
    scenario = scenario(duration_s: 60.0, output_step_s: 60.0)

    assert {:error, {:missing_option, :atmosphere_source_revision}} =
             J2Drag.propagate(scenario, atmosphere_provider: CountingAtmosphereProvider)

    assert {:ok, trajectory} =
             J2Drag.propagate(scenario,
               atmosphere_provider: CountingAtmosphereProvider,
               atmosphere_source_revision: "counting-fixture.v1"
             )

    assert_received :counting_provider_capability_read
    refute_received :counting_provider_capability_read
    assert_received :counting_provider_density_fetch

    assert trajectory.assumptions.atmosphere_provider.source_revision ==
             "counting-fixture.v1"
  end

  test "rejects provider coverage and malformed provider products explicitly" do
    scenario = scenario(duration_s: 61.0, output_step_s: 61.0)

    assert {:error, {:unsupported_provider_coverage, {coverage_start_s, coverage_end_s}}} =
             J2Drag.propagate(scenario,
               atmosphere_provider: FiniteCoverageAtmosphereProvider,
               atmosphere_source_revision: "finite-fixture.v1"
             )

    assert coverage_start_s == 0.0
    assert coverage_end_s == 61.0

    assert {:error, {:invalid_environment_product, :density_kg_m3}} =
             J2Drag.propagate(scenario,
               atmosphere_provider: MalformedDensityProvider,
               atmosphere_source_revision: "malformed-fixture.v1"
             )
  end

  test "rejects network-backed and unsupported-time provider policies" do
    scenario = scenario(duration_s: 60.0, output_step_s: 60.0)

    Process.put(:j2_drag_rejected_policy_case, :network_access)

    assert {:error, :network_access} =
             J2Drag.propagate(scenario,
               atmosphere_provider: RejectedPolicyAtmosphereProvider,
               atmosphere_source_revision: "network-fixture.v1"
             )

    Process.put(:j2_drag_rejected_policy_case, :unsupported_time_scale)

    assert {:error, {:unsupported_provider_time_scale, "tai_seconds_since_j2000"}} =
             J2Drag.propagate(scenario,
               atmosphere_provider: RejectedPolicyAtmosphereProvider,
               atmosphere_source_revision: "wrong-time-fixture.v1"
             )
  end

  test "rejects malformed physical parameters and unsupported integration envelope" do
    scenario = scenario(duration_s: 60.0, output_step_s: 60.0)

    assert {:error, {:invalid_spacecraft, :drag_area_m2}} =
             J2Drag.propagate(%{
               scenario
               | spacecraft: Spacecraft.new!(:missing_area, 100.0, drag_coefficient: 2.2)
             })

    assert {:error, {:invalid_spacecraft, :spacecraft_mass_kg}} =
             J2Drag.propagate(%{
               scenario
               | spacecraft: Spacecraft.new!(:zero_mass, 0.0, area_m2: 4.0, drag_coefficient: 2.2)
             })

    assert {:error, {:invalid_scenario, :j2}} =
             J2Drag.propagate(%{scenario | central_body: %{scenario.central_body | j2: nil}})

    assert {:error, {:unsupported_option, :max_step_s}} =
             J2Drag.propagate(scenario, max_step_s: 30.1)

    assert {:error, {:unsupported_scenario, :duration_s}} =
             scenario(duration_s: 86_400.1, output_step_s: 60.0)
             |> J2Drag.propagate()

    maneuver =
      ImpulsiveBurn.new!(
        :unsupported_burn,
        Epoch.new!(60.0, :tdb),
        {0.0, 0.001, 0.0},
        Frame.earth_inertial_j2000()
      )

    assert {:error, {:unsupported_scenario, :maneuvers}} =
             J2Drag.propagate(%{scenario | maneuvers: [maneuver]})
  end

  test "rejects unsupported body, frame, time scale, and non-LEO altitude" do
    scenario = scenario(duration_s: 60.0, output_step_s: 60.0)

    moon =
      CentralBody.new!(:moon, 4_902.800066,
        equatorial_radius_km: 1_737.4,
        j2: 2.032e-4
      )

    assert {:error, {:unsupported_scenario, :central_body}} =
             J2Drag.propagate(%{scenario | central_body: moon})

    fixed_state = %{scenario.initial_state | frame: Frame.earth_fixed()}

    assert {:error, {:unsupported_frame, :earth_body_fixed}} =
             J2Drag.propagate(%{scenario | initial_state: fixed_state})

    utc_state = %{scenario.initial_state | epoch: Epoch.new!(0.0, :utc)}

    assert {:error, {:unsupported_time_scale, :utc}} =
             J2Drag.propagate(%{scenario | initial_state: utc_state})

    high_state = %{
      scenario.initial_state
      | position_km: {scenario.central_body.equatorial_radius_km + 2_001.0, 0.0, 0.0}
    }

    assert {:error, {:unsupported_scenario, :initial_altitude_km}} =
             J2Drag.propagate(%{scenario | initial_state: high_state})
  end

  defp assert_acceleration_error(scenario, opts, expected) do
    evaluate = fn ->
      OrbitalDynamics.j2_drag_acceleration(
        scenario.initial_state,
        scenario.spacecraft,
        scenario.central_body,
        opts
      )
    end

    assert evaluate.() == expected
    assert evaluate.() == expected
  end

  defp assert_propagation_error(scenario, opts, expected) do
    propagate = fn -> OrbitalDynamics.propagate_j2_drag(scenario, opts) end

    assert propagate.() == expected
    assert propagate.() == expected
  end

  defp inclined_scenario(opts) do
    earth = CentralBody.earth()
    radius_km = earth.equatorial_radius_km + 400.0
    speed_km_s = :math.sqrt(earth.mu_km3_s2 / radius_km)
    inclination_rad = 50.0 * :math.pi() / 180.0
    argument_of_latitude_rad = 45.0 * :math.pi() / 180.0
    cos_u = :math.cos(argument_of_latitude_rad)
    sin_u = :math.sin(argument_of_latitude_rad)
    cos_i = :math.cos(inclination_rad)
    sin_i = :math.sin(inclination_rad)

    state =
      StateVector.new!(
        {
          radius_km * cos_u,
          radius_km * sin_u * cos_i,
          radius_km * sin_u * sin_i
        },
        {
          -speed_km_s * sin_u,
          speed_km_s * cos_u * cos_i,
          speed_km_s * cos_u * sin_i
        },
        Epoch.new!(0.0, :tdb),
        Frame.earth_inertial_j2000()
      )

    spacecraft =
      Spacecraft.new!(:inclined_j2_drag_sat, 100.0,
        propellant_mass_kg: 20.0,
        area_m2: 4.0,
        drag_coefficient: 2.2
      )

    Scenario.new!(:inclined_j2_drag_leo, spacecraft, state,
      duration_s: Keyword.fetch!(opts, :duration_s),
      output_step_s: Keyword.fetch!(opts, :output_step_s),
      central_body: earth
    )
  end

  defp scenario(opts) do
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
      Spacecraft.new!(:j2_drag_sat, 100.0,
        propellant_mass_kg: 20.0,
        area_m2: 4.0,
        drag_coefficient: 2.2
      )

    Scenario.new!(:j2_drag_leo, spacecraft, state,
      duration_s: Keyword.fetch!(opts, :duration_s),
      output_step_s: Keyword.fetch!(opts, :output_step_s),
      central_body: earth
    )
  end
end
