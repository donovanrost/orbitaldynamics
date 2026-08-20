defmodule OrbitalDynamics.ForceModels.AtmosphericDragTest do
  use ExUnit.Case, async: true

  defmodule MismatchedDensityProvider do
    @behaviour OrbitalDynamics.Environment.Provider

    @impl true
    def capabilities do
      %{
        "id" => "environment.provider.atmosphere.test",
        "schema_contract" => "environment_provider_capability.v1",
        "category" => "atmosphere_density",
        "model" => "constant_test_atmosphere",
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
        "known_limits" => ["test fixture only"]
      }
    end

    @impl true
    def fetch(:atmosphere_density, _opts) do
      {:ok,
       %{
         "provider_id" => "environment.provider.atmosphere.wrong",
         "model" => "constant_test_atmosphere",
         "density_kg_m3" => 1.0e-12
       }}
    end
  end

  alias OrbitalDynamics.Environment.{ExponentialAtmosphereProvider, FixedSunProvider}
  alias OrbitalDynamics.ForceModels.AtmosphericDrag
  alias OrbitalDynamics.{CentralBody, Epoch, Frame, Spacecraft, StateVector, Vector3}

  test "public facade evaluates provider-backed co-rotating atmospheric drag" do
    earth = CentralBody.earth()
    state = state_at_altitude(earth, 400.0, {0.0, 7.67, 0.0})

    spacecraft =
      Spacecraft.new!(:drag_sat, 100.0,
        propellant_mass_kg: 20.0,
        area_m2: 4.0,
        drag_coefficient: 2.2
      )

    assert {:ok, result} =
             OrbitalDynamics.atmospheric_drag_acceleration(state, spacecraft, earth)

    assert result.model == :co_rotating_reference_atmosphere_drag
    assert result.validation_level == :educational

    assert result.atmosphere_provider_id ==
             "environment.provider.atmosphere.exponential_reference"

    assert result.earth_rotation_provider_id ==
             "environment.provider.earth_rotation.constant_rate"

    assert result.atmosphere_provider_model == "single_scale_height_exponential_atmosphere"
    assert result.atmosphere_density_product["reference_altitude_km"] == 400.0
    assert result.atmosphere_density_product["scale_height_km"] == 60.0
    assert result.earth_rotation_model == "constant_earth_rotation"
    assert result.spacecraft_mass_kg == 120.0
    assert result.drag_area_m2 == 4.0
    assert result.drag_coefficient == 2.2
    assert_in_delta result.altitude_km, 400.0, 1.0e-12
    assert_in_delta result.density_kg_m3, 3.89e-12, 1.0e-18

    assert {atmosphere_velocity_x, atmosphere_velocity_y, atmosphere_velocity_z} =
             result.atmosphere_velocity_km_s

    assert atmosphere_velocity_x == 0.0
    assert atmosphere_velocity_z == 0.0
    assert atmosphere_velocity_y > 0.0

    assert {relative_velocity_x, relative_velocity_y, relative_velocity_z} =
             result.relative_velocity_km_s

    assert relative_velocity_x == 0.0
    assert relative_velocity_z == 0.0
    assert relative_velocity_y < 7.67

    assert {acceleration_x, acceleration_y, acceleration_z} = result.acceleration_km_s2
    assert acceleration_x == 0.0
    assert acceleration_z == 0.0
    assert acceleration_y < 0.0

    expected_magnitude =
      0.5 * result.density_kg_m3 * result.drag_coefficient * result.drag_area_m2 /
        result.spacecraft_mass_kg * result.relative_speed_km_s * result.relative_speed_km_s *
        1_000.0

    assert_in_delta result.acceleration_magnitude_km_s2, expected_magnitude, 1.0e-18
    assert Vector3.dot(result.acceleration_km_s2, result.relative_velocity_km_s) < 0.0
    assert result.assumptions.atmosphere_rotation == :constant_rate_co_rotation
    assert result.assumptions.acceleration_unit == :kilometer_per_second_squared

    assert "standalone_evaluator_two_body_drag_and_j2_drag_propagators_only" in result.model_limits
  end

  test "uses configured atmosphere provider parameters without hiding zero density" do
    earth = CentralBody.earth()
    state = state_at_altitude(earth, 400.0, {0.0, 7.67, 0.0})
    spacecraft = Spacecraft.new!(:drag_sat, 100.0, area_m2: 4.0, drag_coefficient: 2.2)

    assert {:ok, zero_density_result} =
             AtmosphericDrag.evaluate(state, spacecraft, earth,
               atmosphere_provider: {ExponentialAtmosphereProvider, reference_density_kg_m3: 0.0}
             )

    assert zero_density_result.density_kg_m3 == 0.0
    assert zero_density_result.atmosphere_density_product["reference_density_kg_m3"] == 0.0
    assert zero_density_result.acceleration_km_s2 == {0.0, 0.0, 0.0}
    assert zero_density_result.acceleration_magnitude_km_s2 == 0.0

    zero_coefficient_spacecraft =
      Spacecraft.new!(:no_drag_sat, 100.0, area_m2: 4.0, drag_coefficient: 0.0)

    assert {:ok, zero_coefficient_result} =
             AtmosphericDrag.evaluate(state, zero_coefficient_spacecraft, earth)

    assert zero_coefficient_result.density_kg_m3 > 0.0
    assert zero_coefficient_result.acceleration_km_s2 == {0.0, 0.0, 0.0}
  end

  test "rejects missing ballistic inputs, incompatible frames, and wrong providers" do
    earth = CentralBody.earth()
    state = state_at_altitude(earth, 400.0, {0.0, 7.67, 0.0})

    assert {:error, {:invalid_spacecraft, :drag_area_m2}} =
             AtmosphericDrag.evaluate(state, Spacecraft.new!(:missing_area, 100.0), earth)

    assert {:error, {:invalid_spacecraft, :drag_coefficient}} =
             AtmosphericDrag.evaluate(
               state,
               Spacecraft.new!(:missing_coefficient, 100.0, area_m2: 4.0),
               earth
             )

    assert {:error, {:invalid_spacecraft, :spacecraft_mass_kg}} =
             AtmosphericDrag.evaluate(
               state,
               Spacecraft.new!(:missing_mass, 0.0, area_m2: 4.0, drag_coefficient: 2.2),
               earth
             )

    malformed_mass_spacecraft = %{
      Spacecraft.new!(:malformed_mass, 100.0, area_m2: 4.0, drag_coefficient: 2.2)
      | dry_mass_kg: :unknown
    }

    assert {:error, {:invalid_spacecraft, :spacecraft_mass_kg}} =
             AtmosphericDrag.evaluate(state, malformed_mass_spacecraft, earth)

    wrong_frame_state = %{
      state
      | frame: Frame.new!(:earth_body_fixed, :earth, :body_fixed)
    }

    assert {:error, {:invalid_state, :frame}} =
             AtmosphericDrag.evaluate(
               wrong_frame_state,
               Spacecraft.new!(:drag_sat, 100.0, area_m2: 4.0, drag_coefficient: 2.2),
               earth
             )

    malformed_state = %{state | position_km: :unknown}

    assert {:error, {:invalid_state, :state_vector}} =
             AtmosphericDrag.evaluate(
               malformed_state,
               Spacecraft.new!(:drag_sat, 100.0, area_m2: 4.0, drag_coefficient: 2.2),
               earth
             )

    below_surface_state = state_at_altitude(earth, -1.0, {0.0, 7.67, 0.0})

    assert {:error, {:invalid_state, :altitude_km}} =
             AtmosphericDrag.evaluate(
               below_surface_state,
               Spacecraft.new!(:drag_sat, 100.0, area_m2: 4.0, drag_coefficient: 2.2),
               earth
             )

    assert {:error, {:unsupported_environment_request, :atmosphere_density}} =
             AtmosphericDrag.evaluate(
               state,
               Spacecraft.new!(:drag_sat, 100.0, area_m2: 4.0, drag_coefficient: 2.2),
               earth,
               atmosphere_provider: FixedSunProvider
             )

    assert {:error, {:invalid_environment_product, :provider_id}} =
             AtmosphericDrag.evaluate(
               state,
               Spacecraft.new!(:drag_sat, 100.0, area_m2: 4.0, drag_coefficient: 2.2),
               earth,
               atmosphere_provider: MismatchedDensityProvider
             )

    assert {:error, {:invalid_option, :options}} =
             AtmosphericDrag.evaluate(state, malformed_mass_spacecraft, earth, [:not_keyword])
  end

  test "declares the explicit evaluator and scalar drag integration boundary" do
    assert %{
             force_model: :atmospheric_drag,
             validation_level: :educational,
             supported_bodies: [:earth],
             supported_frames: [:eci_j2000],
             public_facades: [:atmospheric_drag_acceleration],
             known_limits: known_limits
           } = AtmosphericDrag.capabilities()

    assert :standalone_evaluator_two_body_drag_and_j2_drag_propagators_only in known_limits
    assert :not_integrated_by_accelerated_propagators in known_limits

    assert OrbitalDynamics.capability_catalog().analysis.force_models.atmospheric_drag ==
             AtmosphericDrag.capabilities()

    assert {:ok, %{"schema_contract" => "capability_catalog.v1", "status" => "pass"}} =
             OrbitalDynamics.capability_catalog_artifact()
             |> OrbitalDynamics.Schema.validate_artifact()
  end

  defp state_at_altitude(earth, altitude_km, velocity_km_s) do
    StateVector.new!(
      {earth.equatorial_radius_km + altitude_km, 0.0, 0.0},
      velocity_km_s,
      Epoch.new!(0.0, :tdb),
      Frame.earth_inertial_j2000()
    )
  end
end
