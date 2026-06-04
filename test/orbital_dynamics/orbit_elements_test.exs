defmodule OrbitalDynamics.OrbitElementsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CentralBody, Epoch, Frame, OrbitElements, StateVector}

  test "declares conversion capabilities and fidelity limits" do
    assert %{
             model: :two_body_osculating_classical_elements,
             validation_level: :educational,
             frame_policy: :input_frame_no_transformation,
             singularity_policy: :undefined_angles_return_nil,
             output_state: :cartesian_state_vector,
             coordinate_units: %{
               position: :kilometer,
               velocity: :kilometer_per_second,
               angles: :degree
             },
             known_limits: known_limits
           } = OrbitElements.capabilities()

    assert :two_body_assumption_only in known_limits
    assert :no_frame_transformation in known_limits
    assert :singular_classical_angles_return_nil in known_limits
  end

  test "converts a circular equatorial Cartesian state to singular classical elements" do
    earth = CentralBody.earth()
    radius_km = 7_000.0
    velocity_km_s = :math.sqrt(earth.mu_km3_s2 / radius_km)

    state =
      StateVector.new!(
        {radius_km, 0.0, 0.0},
        {0.0, velocity_km_s, 0.0},
        Epoch.new!(0.0, :tdb),
        Frame.earth_inertial_j2000()
      )

    assert {:ok, elements} = OrbitElements.from_state(state, earth)

    assert elements.orbit_class == :elliptic
    assert_in_delta elements.semi_major_axis_km, radius_km, 1.0e-9
    assert_in_delta elements.eccentricity, 0.0, 1.0e-12
    assert_in_delta elements.inclination_deg, 0.0, 1.0e-12
    assert elements.raan_deg == nil
    assert elements.argument_of_periapsis_deg == nil
    assert elements.true_anomaly_deg == nil
    assert_in_delta elements.true_longitude_deg, 0.0, 1.0e-12
    assert_in_delta elements.perigee_radius_km, radius_km, 1.0e-9
    assert_in_delta elements.apogee_radius_km, radius_km, 1.0e-9
  end

  test "converts an eccentric equatorial perigee state" do
    earth = CentralBody.earth()
    perigee_radius_km = 7_000.0
    eccentricity = 0.1
    semi_major_axis_km = perigee_radius_km / (1.0 - eccentricity)

    velocity_km_s =
      :math.sqrt(earth.mu_km3_s2 * (2.0 / perigee_radius_km - 1.0 / semi_major_axis_km))

    state =
      StateVector.new!(
        {perigee_radius_km, 0.0, 0.0},
        {0.0, velocity_km_s, 0.0},
        Epoch.new!(0.0, :tdb),
        Frame.earth_inertial_j2000()
      )

    elements = OrbitElements.from_state!(state, earth.mu_km3_s2)

    assert_in_delta elements.semi_major_axis_km, semi_major_axis_km, 1.0e-9
    assert_in_delta elements.eccentricity, eccentricity, 1.0e-12
    assert_in_delta elements.perigee_radius_km, perigee_radius_km, 1.0e-9
    assert_in_delta elements.apogee_radius_km, semi_major_axis_km * (1.0 + eccentricity), 1.0e-9
    assert_in_delta elements.longitude_of_periapsis_deg, 0.0, 1.0e-12
    assert_in_delta elements.true_anomaly_deg, 0.0, 1.0e-12
    assert elements.raan_deg == nil
    assert elements.argument_of_periapsis_deg == nil
  end

  test "converts inclined eccentric classical elements back to a Cartesian state" do
    earth = CentralBody.earth()
    epoch = Epoch.new!(123.0, :tdb)
    frame = Frame.earth_inertial_j2000()

    elements = %{
      semi_major_axis_km: 10_000.0,
      eccentricity: 0.2,
      inclination_deg: 45.0,
      raan_deg: 30.0,
      argument_of_periapsis_deg: 40.0,
      true_anomaly_deg: 50.0
    }

    assert {:ok, %StateVector{} = state} =
             OrbitElements.to_state(elements, earth, epoch: epoch, frame: frame)

    assert state.epoch == epoch
    assert state.frame == frame

    assert {:ok, round_trip} = OrbitElements.from_state(state, earth)

    assert_in_delta round_trip.semi_major_axis_km, elements.semi_major_axis_km, 1.0e-8
    assert_in_delta round_trip.eccentricity, elements.eccentricity, 1.0e-12
    assert_in_delta round_trip.inclination_deg, elements.inclination_deg, 1.0e-10
    assert_in_delta round_trip.raan_deg, elements.raan_deg, 1.0e-10

    assert_in_delta round_trip.argument_of_periapsis_deg,
                    elements.argument_of_periapsis_deg,
                    1.0e-9

    assert_in_delta round_trip.true_anomaly_deg, elements.true_anomaly_deg, 1.0e-9
  end

  test "converts circular equatorial elements using true longitude" do
    earth = CentralBody.earth()
    radius_km = 7_000.0

    assert {:ok, state} =
             OrbitalDynamics.state_from_orbital_elements(
               %{
                 "semi_major_axis_km" => radius_km,
                 "eccentricity" => 0.0,
                 "inclination_deg" => 0.0,
                 "true_longitude_deg" => 90.0
               },
               earth,
               epoch: Epoch.new!(0.0, :tdb),
               frame: Frame.earth_inertial_j2000()
             )

    assert_in_delta elem(state.position_km, 0), 0.0, 1.0e-9
    assert_in_delta elem(state.position_km, 1), radius_km, 1.0e-9

    assert_in_delta elem(state.velocity_km_s, 0),
                    -:math.sqrt(earth.mu_km3_s2 / radius_km),
                    1.0e-12

    assert_in_delta elem(state.velocity_km_s, 1), 0.0, 1.0e-12
  end

  test "rejects element-to-state conversions without explicit context or singular angles" do
    earth = CentralBody.earth()
    frame = Frame.earth_inertial_j2000()
    epoch = Epoch.new!(0.0, :tdb)
    elements = %{semi_major_axis_km: 7_000.0, eccentricity: 0.0, inclination_deg: 0.0}

    assert {:error, {:missing_option, :epoch}} =
             OrbitElements.to_state(elements, earth, frame: frame)

    assert {:error, {:missing_option, :frame}} =
             OrbitElements.to_state(elements, earth, epoch: epoch)

    assert {:error, {:missing_element, :true_longitude_deg}} =
             OrbitElements.to_state(elements, earth, epoch: epoch, frame: frame)

    assert {:error, :incompatible_frame_center} =
             OrbitElements.to_state(
               Map.put(elements, :true_longitude_deg, 0.0),
               CentralBody.new!(:moon, 4_902.800066),
               epoch: epoch,
               frame: frame
             )
  end

  test "top-level helper delegates to the public element converter" do
    earth = CentralBody.earth()
    radius_km = 7_000.0

    state =
      StateVector.new!(
        {radius_km, 0.0, 0.0},
        {0.0, :math.sqrt(earth.mu_km3_s2 / radius_km), 0.0},
        Epoch.new!(0.0, :tdb),
        Frame.earth_inertial_j2000()
      )

    assert {:ok, %OrbitElements{semi_major_axis_km: semi_major_axis_km}} =
             OrbitalDynamics.orbital_elements(state, earth)

    assert_in_delta semi_major_axis_km, radius_km, 1.0e-9
  end

  test "rejects degenerate states and invalid gravitational parameters" do
    state =
      StateVector.new!(
        {0.0, 0.0, 0.0},
        {0.0, 0.0, 0.0},
        Epoch.new!(0.0, :tdb),
        Frame.earth_inertial_j2000()
      )

    assert {:error, :degenerate_state} = OrbitElements.from_state(state, CentralBody.earth())
    assert {:error, :invalid_mu_km3_s2} = OrbitElements.from_state(state, 0.0)
  end

  test "rejects central-body conversions when the state frame center does not match" do
    state =
      StateVector.new!(
        {7_000.0, 0.0, 0.0},
        {0.0, 7.5, 0.0},
        Epoch.new!(0.0, :tdb),
        Frame.earth_inertial_j2000()
      )

    assert {:error, :incompatible_frame_center} =
             OrbitElements.from_state(state, CentralBody.new!(:moon, 4_902.800066))
  end
end
