defmodule OrbitalDynamics.Validation.OrbitalReferenceFixtures do
  @moduledoc false

  import ExUnit.Assertions

  alias OrbitalDynamics.EventDetectors.{
    AccessWindows,
    Eclipses,
    GroundTrackCrossings,
    TargetVisibility
  }

  alias OrbitalDynamics.Propagators.{J2, TwoBody}

  alias OrbitalDynamics.{
    CentralBody,
    Epoch,
    Frame,
    GroundStation,
    Scenario,
    Spacecraft,
    StateVector,
    Target,
    Trajectory
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
end
