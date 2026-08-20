defmodule OrbitalDynamics.Validation.OrbitalReferenceFixtures do
  @moduledoc false

  import ExUnit.Assertions

  alias OrbitalDynamics.EventDetectors.{
    AccessWindows,
    Eclipses,
    GroundTrackCrossings,
    TargetVisibility
  }

  alias OrbitalDynamics.Propagators.{J2, J2Drag, TwoBody, TwoBodyDrag}

  alias OrbitalDynamics.{
    CentralBody,
    Epoch,
    Frame,
    GroundStation,
    Scenario,
    Spacecraft,
    StateVector,
    Target,
    Trajectory,
    Vector3
  }

  def two_body_fixture_observations do
    central_body = CentralBody.earth()
    radius_km = 7_000.0
    velocity_km_s = :math.sqrt(central_body.mu_km3_s2 / radius_km)

    scenario =
      Scenario.new!(
        :fixture_two_body_leo_600s,
        Spacecraft.new!(:sat_1, 250.0),
        StateVector.new!(
          {radius_km, 0.0, 0.0},
          {0.0, velocity_km_s, 0.0},
          Epoch.new!(0.0, :tdb),
          Frame.earth_inertial_j2000()
        ),
        duration_s: 600.0,
        output_step_s: 120.0,
        central_body: central_body
      )

    assert {:ok, trajectory} = TwoBody.propagate(scenario, max_step_s: 10.0)
    final_state = List.last(trajectory.states)

    %{
      "sample_count" => length(trajectory.states),
      "final_epoch_s" => final_state.epoch.seconds_since_j2000,
      "final_position_km" => Tuple.to_list(final_state.position_km),
      "final_velocity_km_s" => Tuple.to_list(final_state.velocity_km_s)
    }
  end

  def j2_fixture_observations do
    central_body = CentralBody.earth()
    radius_km = 7_000.0
    velocity_km_s = :math.sqrt(central_body.mu_km3_s2 / radius_km)

    scenario =
      Scenario.new!(
        :fixture_j2_leo_600s,
        Spacecraft.new!(:sat_1, 250.0),
        StateVector.new!(
          {radius_km, 0.0, 0.0},
          {0.0, velocity_km_s, 0.0},
          Epoch.new!(0.0, :tdb),
          Frame.earth_inertial_j2000()
        ),
        duration_s: 600.0,
        output_step_s: 120.0,
        central_body: central_body
      )

    assert {:ok, trajectory} = J2.propagate(scenario, max_step_s: 10.0)
    final_state = List.last(trajectory.states)

    %{
      "sample_count" => length(trajectory.states),
      "final_epoch_s" => final_state.epoch.seconds_since_j2000,
      "final_position_km" => Tuple.to_list(final_state.position_km),
      "final_velocity_km_s" => Tuple.to_list(final_state.velocity_km_s)
    }
  end

  def atmospheric_drag_fixture_observations do
    central_body = CentralBody.earth()

    state =
      StateVector.new!(
        {central_body.equatorial_radius_km + 400.0, 0.0, 0.0},
        {0.0, 7.67, 0.0},
        Epoch.new!(0.0, :tdb),
        Frame.earth_inertial_j2000()
      )

    spacecraft =
      Spacecraft.new!(:drag_fixture, 100.0,
        propellant_mass_kg: 20.0,
        area_m2: 4.0,
        drag_coefficient: 2.2
      )

    assert {:ok, result} =
             OrbitalDynamics.atmospheric_drag_acceleration(state, spacecraft, central_body)

    %{
      "altitude_km" => result.altitude_km,
      "density_kg_m3" => result.density_kg_m3,
      "spacecraft_mass_kg" => result.spacecraft_mass_kg,
      "atmosphere_velocity_km_s" => Tuple.to_list(result.atmosphere_velocity_km_s),
      "relative_velocity_km_s" => Tuple.to_list(result.relative_velocity_km_s),
      "relative_speed_km_s" => result.relative_speed_km_s,
      "acceleration_km_s2" => Tuple.to_list(result.acceleration_km_s2),
      "acceleration_magnitude_km_s2" => result.acceleration_magnitude_km_s2,
      "atmosphere_provider_id" => result.atmosphere_provider_id,
      "earth_rotation_provider_id" => result.earth_rotation_provider_id,
      "model_limit_count" => length(result.model_limits)
    }
  end

  def two_body_drag_fixture_observations do
    central_body = CentralBody.earth()
    radius_km = central_body.equatorial_radius_km + 400.0
    velocity_km_s = :math.sqrt(central_body.mu_km3_s2 / radius_km)

    initial_state =
      StateVector.new!(
        {radius_km, 0.0, 0.0},
        {0.0, velocity_km_s, 0.0},
        Epoch.new!(0.0, :tdb),
        Frame.earth_inertial_j2000()
      )

    spacecraft =
      Spacecraft.new!(:drag_fixture, 100.0,
        propellant_mass_kg: 20.0,
        area_m2: 4.0,
        drag_coefficient: 2.2
      )

    scenario =
      Scenario.new!(:drag_fixture, spacecraft, initial_state,
        duration_s: 600.0,
        output_step_s: 600.0,
        central_body: central_body
      )

    study =
      OrbitalDynamics.Study.new!(:drag_fixture, [scenario],
        propagator: TwoBodyDrag,
        propagator_opts: [max_step_s: 10.0]
      )

    assert [%{status: :ok, value: trajectory}] = OrbitalDynamics.analyze_study(study)
    final_state = List.last(trajectory.states)

    initial_specific_energy = specific_energy(initial_state, central_body.mu_km3_s2)
    final_specific_energy = specific_energy(final_state, central_body.mu_km3_s2)

    %{
      "initial_position_km" => Tuple.to_list(initial_state.position_km),
      "initial_velocity_km_s" => Tuple.to_list(initial_state.velocity_km_s),
      "final_position_km" => Tuple.to_list(final_state.position_km),
      "final_velocity_km_s" => Tuple.to_list(final_state.velocity_km_s),
      "initial_specific_energy_km2_s2" => initial_specific_energy,
      "final_specific_energy_km2_s2" => final_specific_energy,
      "specific_energy_change_km2_s2" => final_specific_energy - initial_specific_energy,
      "atmosphere_provider_id" => trajectory.assumptions.atmosphere_provider_id,
      "earth_rotation_provider_id" => trajectory.assumptions.earth_rotation_provider_id,
      "model_limit_count" => length(trajectory.assumptions.model_limits)
    }
  end

  def j2_drag_convergence_fixture_observations do
    central_body = CentralBody.earth()
    radius_km = central_body.equatorial_radius_km + 400.0
    velocity_km_s = :math.sqrt(central_body.mu_km3_s2 / radius_km)

    initial_state =
      StateVector.new!(
        {radius_km, 0.0, 0.0},
        {0.0, velocity_km_s, 0.0},
        Epoch.new!(0.0, :tdb),
        Frame.earth_inertial_j2000()
      )

    spacecraft =
      Spacecraft.new!(:j2_drag_convergence_fixture, 100.0,
        propellant_mass_kg: 20.0,
        area_m2: 4.0,
        drag_coefficient: 2.2
      )

    scenario =
      Scenario.new!(:j2_drag_convergence_fixture, spacecraft, initial_state,
        duration_s: 86_400.0,
        output_step_s: 3_600.0,
        central_body: central_body
      )

    assert {:ok, coarse_trajectory} = J2Drag.propagate(scenario, max_step_s: 10.0)
    assert {:ok, fine_trajectory} = J2Drag.propagate(scenario, max_step_s: 5.0)

    coarse_final = List.last(coarse_trajectory.states)
    fine_final = List.last(fine_trajectory.states)

    position_delta_km =
      coarse_final.position_km
      |> Vector3.subtract(fine_final.position_km)
      |> Vector3.norm()

    velocity_delta_km_s =
      coarse_final.velocity_km_s
      |> Vector3.subtract(fine_final.velocity_km_s)
      |> Vector3.norm()

    convergence = J2Drag.capabilities().planning_horizon_step_convergence

    classification =
      if position_delta_km <= convergence.position_tolerance_km and
           velocity_delta_km_s <= convergence.velocity_tolerance_km_s,
         do: "pass_internal_only",
         else: "fail_internal_only"

    %{
      "sample_count" => length(coarse_trajectory.states),
      "coarse_final_position_km" => Tuple.to_list(coarse_final.position_km),
      "coarse_final_velocity_km_s" => Tuple.to_list(coarse_final.velocity_km_s),
      "fine_final_position_km" => Tuple.to_list(fine_final.position_km),
      "fine_final_velocity_km_s" => Tuple.to_list(fine_final.velocity_km_s),
      "coarse_fine_position_delta_km" => position_delta_km,
      "coarse_fine_velocity_delta_km_s" => velocity_delta_km_s,
      "declared_position_tolerance_km" => convergence.position_tolerance_km,
      "declared_velocity_tolerance_km_s" => convergence.velocity_tolerance_km_s,
      "convergence_classification" => classification,
      "atmosphere_provider_id" => coarse_trajectory.assumptions.atmosphere_provider_id,
      "atmosphere_source_revision" =>
        coarse_trajectory.assumptions.atmosphere_provider_source_revision,
      "model_limit_count" => length(coarse_trajectory.assumptions.model_limits)
    }
  end

  def access_fixture_observations do
    earth = CentralBody.earth()
    station = GroundStation.new!(:equator, 0.0, 0.0, minimum_elevation_deg: 0.0)

    trajectory = %Trajectory{
      scenario_id: :fixture_access_equator,
      states: [
        access_state({earth.equatorial_radius_km + 500.0, 0.0, 0.0}, 0.0),
        access_state({earth.equatorial_radius_km + 500.0, 0.0, 0.0}, 60.0),
        access_state({-(earth.equatorial_radius_km + 500.0), 0.0, 0.0}, 120.0)
      ],
      assumptions: %{force_model: :manual}
    }

    assert {:ok, [event]} =
             AccessWindows.detect(trajectory, ground_station: station, central_body: earth)

    starts_at_s = event.starts_at.seconds_since_j2000
    ends_at_s = event.ends_at.seconds_since_j2000

    %{
      "window_count" => 1,
      "first_window_starts_at_s" => starts_at_s,
      "first_window_ends_at_s" => ends_at_s,
      "first_window_duration_s" => ends_at_s - starts_at_s,
      "first_window_sample_count" => event.metadata.sample_count,
      "first_window_max_elevation_deg" => event.metadata.max_elevation_deg
    }
  end

  def eclipse_fixture_observations do
    earth = CentralBody.earth()
    radius_km = earth.equatorial_radius_km + 500.0

    trajectory = %Trajectory{
      scenario_id: :fixture_eclipse_cylindrical_shadow,
      states: [
        access_state({-radius_km, 0.0, 0.0}, 0.0),
        access_state({-radius_km, 0.0, 0.0}, 60.0),
        access_state({radius_km, 0.0, 0.0}, 120.0)
      ],
      assumptions: %{force_model: :manual}
    }

    assert {:ok, [event]} =
             Eclipses.detect(trajectory, central_body: earth, sun_direction: {1.0, 0.0, 0.0})

    starts_at_s = event.starts_at.seconds_since_j2000
    ends_at_s = event.ends_at.seconds_since_j2000

    %{
      "interval_count" => 1,
      "first_interval_starts_at_s" => starts_at_s,
      "first_interval_ends_at_s" => ends_at_s,
      "first_interval_duration_s" => ends_at_s - starts_at_s,
      "first_interval_sample_count" => event.metadata.sample_count,
      "first_interval_minimum_shadow_axis_distance_km" =>
        event.metadata.minimum_shadow_axis_distance_km,
      "first_interval_maximum_shadow_margin_km" => event.metadata.maximum_shadow_margin_km
    }
  end

  def target_visibility_fixture_observations do
    earth = CentralBody.earth()
    radius_km = earth.equatorial_radius_km + 500.0
    target = Target.new!(:target_a, 0.0, 0.0, minimum_elevation_deg: 0.0, priority: 4.0)

    trajectory = %Trajectory{
      scenario_id: :fixture_target_visibility_equator,
      states: [
        access_state({radius_km, 0.0, 0.0}, 0.0),
        access_state({radius_km, 0.0, 0.0}, 60.0),
        access_state({-radius_km, 0.0, 0.0}, 120.0)
      ],
      assumptions: %{force_model: :manual}
    }

    assert {:ok, [event]} =
             TargetVisibility.detect(trajectory, target: target, central_body: earth)

    starts_at_s = event.starts_at.seconds_since_j2000
    ends_at_s = event.ends_at.seconds_since_j2000

    %{
      "window_count" => 1,
      "first_window_starts_at_s" => starts_at_s,
      "first_window_ends_at_s" => ends_at_s,
      "first_window_duration_s" => ends_at_s - starts_at_s,
      "first_window_sample_count" => event.metadata.sample_count,
      "first_window_max_elevation_deg" => event.metadata.max_elevation_deg,
      "target_priority" => event.metadata.target_priority
    }
  end

  def ground_track_crossing_fixture_observations do
    trajectory = %Trajectory{
      scenario_id: :fixture_ground_track_equator,
      states: [
        access_state({1.0, 0.0, -1.0}, 0.0),
        access_state({1.0, 0.0, 1.0}, 60.0)
      ],
      assumptions: %{force_model: :manual}
    }

    assert {:ok, [event]} =
             GroundTrackCrossings.detect(trajectory, crossing: :latitude, latitude_deg: 0.0)

    %{
      "crossing_count" => 1,
      "first_crossing_epoch_s" => event.starts_at.seconds_since_j2000,
      "first_crossing_target_deg" => event.metadata.target_deg,
      "first_crossing_direction" => Atom.to_string(event.metadata.crossing_direction)
    }
  end

  defp access_state(position_km, seconds_since_j2000) do
    StateVector.new!(
      position_km,
      {0.0, 0.0, 0.0},
      Epoch.new!(seconds_since_j2000, :tdb),
      Frame.earth_inertial_j2000()
    )
  end

  defp specific_energy(state, mu_km3_s2) do
    velocity_km_s = Vector3.norm(state.velocity_km_s)
    radius_km = Vector3.norm(state.position_km)
    velocity_km_s * velocity_km_s / 2.0 - mu_km3_s2 / radius_km
  end
end
