defmodule OrbitalDynamics.EventDetectors.AccessWindowsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.EventDetectors.AccessWindows
  alias OrbitalDynamics.{CentralBody, Epoch, Frame, GroundStation, StateVector, Trajectory}

  test "declares detector capabilities" do
    assert %{
             detector: :access_windows,
             validation_level: :analysis,
             timing_policy: :sampled_state_linear_boundary,
             interpolation: :linear_sample_crossing,
             boundary_refinement: :aos_los_linear_margin_interpolation,
             coordinate_model: :spherical_earth_access_geometry,
             known_limits: known_limits
           } = AccessWindows.capabilities()

    assert :sample_cadence_limited in known_limits
    assert :refinement_not_root_solved in known_limits
    assert :no_refraction_model in known_limits
  end

  test "detects one access window from contiguous visible samples" do
    earth = CentralBody.earth()
    station = GroundStation.new!(:equator, 0.0, 0.0, minimum_elevation_deg: 0.0)

    trajectory =
      trajectory([
        above_station(earth, 0.0),
        above_station(earth, 60.0),
        opposite_earth(earth, 120.0)
      ])

    assert {:ok, [event]} =
             AccessWindows.detect(trajectory, ground_station: station, central_body: earth)

    assert event.type == :ground_station_access
    assert event.starts_at.seconds_since_j2000 == 0.0
    assert event.ends_at.seconds_since_j2000 > 60.0
    assert event.ends_at.seconds_since_j2000 < 120.0
    assert event.metadata.ground_station_id == :equator
    assert event.metadata.sample_count == 2
    assert event.metadata.geometry_model == :simplified_spherical_earth_rotation
    assert event.metadata.interpolation == :linear_sample_crossing
    assert event.metadata.boundary_refinement == :aos_los_linear_margin_interpolation
    assert event.metadata.start_boundary == :clipped_start
    assert event.metadata.end_boundary == :interpolated
    assert event.metadata.start_boundary_detail.boundary == :clipped_start
    assert event.metadata.start_boundary_detail.interpolation == :clipped_to_sample
    assert event.metadata.start_boundary_detail.root_solved == false
    assert event.metadata.end_boundary_detail.boundary == :los
    assert event.metadata.end_boundary_detail.edge == :end
    assert event.metadata.end_boundary_detail.interpolation == :linear_sample_crossing
    assert event.metadata.end_boundary_detail.interpolation_fraction > 0.0
    assert event.metadata.end_boundary_detail.interpolation_fraction < 1.0

    assert event.metadata.end_boundary_detail.event_timing_policy ==
             :sampled_state_linear_boundary

    assert event.metadata.end_boundary_detail.event_time_bracket_s == 60.0
    assert event.metadata.end_boundary_detail.before_epoch_s == 60.0
    assert event.metadata.end_boundary_detail.after_epoch_s == 120.0
    assert event.metadata.end_boundary_detail.root_solved == false
    assert event.metadata.max_elevation_deg > 80.0
    assert event.metadata.event_timing_policy == :sampled_state_linear_boundary
    assert event.metadata.event_detector == :access_windows
    assert event.metadata.event_time_tolerance_s == 60.0
    assert event.metadata.max_sample_step_s == 60.0
    assert event.metadata.confidence == :bounded_by_sample_cadence
  end

  test "public API detects access windows" do
    earth = CentralBody.earth()
    station = GroundStation.new!(:equator, 0.0, 0.0)
    trajectory = trajectory([above_station(earth, 0.0)])

    assert {:ok, [%{type: :ground_station_access}]} =
             OrbitalDynamics.access_windows(trajectory, station, central_body: earth)
  end

  test "refines bracketed AOS and LOS boundaries" do
    earth = CentralBody.earth()
    station = GroundStation.new!(:equator, 0.0, 0.0, minimum_elevation_deg: 0.0)

    before_aos = opposite_earth(earth, 0.0)
    after_aos = above_station(earth, 60.0)

    assert {:ok, aos} =
             AccessWindows.refine_aos_los_boundary(before_aos, after_aos, station,
               central_body: earth
             )

    assert aos.boundary == :aos
    assert aos.interpolation == :linear_sample_crossing
    assert aos.interpolation_fraction > 0.0
    assert aos.interpolation_fraction < 1.0
    assert aos.epoch.seconds_since_j2000 > 0.0
    assert aos.epoch.seconds_since_j2000 < 60.0
    assert aos.assumptions.root_solved == false
    assert aos.assumptions.event_time_bracket_s == 60.0
    assert aos.assumptions.before_epoch_s == 0.0
    assert aos.assumptions.after_epoch_s == 60.0

    assert {:ok, los} =
             OrbitalDynamics.refine_access_boundary(
               after_aos,
               opposite_earth(earth, 120.0),
               station,
               central_body: earth
             )

    assert los.boundary == :los
    assert los.epoch.seconds_since_j2000 > 60.0
    assert los.epoch.seconds_since_j2000 < 120.0
  end

  test "rejects unbracketed access boundary refinement" do
    earth = CentralBody.earth()
    station = GroundStation.new!(:equator, 0.0, 0.0, minimum_elevation_deg: 0.0)

    assert {:error, :not_bracketed} =
             AccessWindows.refine_aos_los_boundary(
               above_station(earth, 0.0),
               above_station(earth, 60.0),
               station,
               central_body: earth
             )
  end

  test "returns no windows when every sample is below elevation threshold" do
    earth = CentralBody.earth()
    station = GroundStation.new!(:equator, 0.0, 0.0)
    trajectory = trajectory([opposite_earth(earth, 0.0), opposite_earth(earth, 60.0)])

    assert {:ok, []} =
             AccessWindows.detect(trajectory, ground_station: station, central_body: earth)
  end

  test "splits separated visible samples into separate windows" do
    earth = CentralBody.earth()
    station = GroundStation.new!(:equator, 0.0, 0.0)

    trajectory =
      trajectory([
        above_station(earth, 0.0),
        opposite_earth(earth, 60.0),
        above_station(earth, 120.0)
      ])

    assert {:ok, [first, second]} =
             AccessWindows.detect(trajectory, ground_station: station, central_body: earth)

    assert first.starts_at.seconds_since_j2000 == 0.0
    assert first.ends_at.seconds_since_j2000 > 0.0
    assert first.ends_at.seconds_since_j2000 < 60.0
    assert second.starts_at.seconds_since_j2000 > 60.0
    assert second.starts_at.seconds_since_j2000 < 120.0
    assert second.ends_at.seconds_since_j2000 == 120.0
  end

  test "rejects invalid detector options" do
    earth = CentralBody.earth()
    trajectory = trajectory([above_station(earth, 0.0)])

    assert {:error, {:invalid_option, :ground_station}} =
             AccessWindows.detect(trajectory, ground_station: :not_a_station, central_body: earth)
  end

  defp trajectory(states) do
    %Trajectory{
      scenario_id: :access_test,
      states: states,
      assumptions: %{force_model: :manual}
    }
  end

  defp above_station(earth, seconds_since_j2000) do
    state({earth.equatorial_radius_km + 500.0, 0.0, 0.0}, seconds_since_j2000)
  end

  defp opposite_earth(earth, seconds_since_j2000) do
    state({-(earth.equatorial_radius_km + 500.0), 0.0, 0.0}, seconds_since_j2000)
  end

  defp state(position_km, seconds_since_j2000) do
    StateVector.new!(
      position_km,
      {0.0, 0.0, 0.0},
      Epoch.new!(seconds_since_j2000, :tdb),
      Frame.earth_inertial_j2000()
    )
  end
end
