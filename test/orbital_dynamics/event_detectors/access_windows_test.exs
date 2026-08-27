defmodule OrbitalDynamics.EventDetectors.AccessWindowsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.EventDetectors.AccessWindows
  alias OrbitalDynamics.{CentralBody, Epoch, Frame, GroundStation, StateVector, Trajectory}

  @earth_rotation_rate_rad_s 7.2921150e-5
  @safe_number_bound 1_000_000_000_000_000

  defmodule StructProbe do
    defstruct [:value]
  end

  test "declares detector capabilities" do
    assert %{
             detector: :access_windows,
             validation_level: :analysis,
             timing_policy: :sampled_state_linear_boundary,
             interpolation: :linear_sample_crossing,
             boundary_refinement: :aos_los_linear_margin_interpolation,
             supported_boundary_refinements: [
               :linear_sample_crossing,
               :bracketed_bisection
             ],
             root_refinement_defaults: %{
               root_tolerance_s: 1.0e-3,
               root_max_iterations: 64
             },
             coordinate_model: :spherical_earth_access_geometry,
             known_limits: known_limits
           } = AccessWindows.capabilities()

    assert :sample_cadence_limited in known_limits
    assert :refinement_not_root_solved in known_limits
    assert :root_refinement_interpolated_state_only in known_limits
    assert :root_refinement_not_externally_validated in known_limits
    assert :multiple_crossings_within_sample_not_resolved in known_limits
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

    assert AccessWindows.detect(trajectory,
             ground_station: station,
             central_body: earth,
             boundary_refinement: :linear_sample_crossing
           ) == AccessWindows.detect(trajectory, ground_station: station, central_body: earth)
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

  test "root-refines AOS and LOS on the cubic-Hermite state path with deterministic bounds" do
    earth = CentralBody.earth()
    station = GroundStation.new!(:equator, 0.0, 0.0, minimum_elevation_deg: 0.0)
    radius_km = earth.equatorial_radius_km + 500.0
    initial_angle_rad = :math.pi() / 6.0
    spacecraft_rate_rad_s = -:math.pi() / 3600.0

    before_state =
      circular_pass_state(radius_km, 0.0, initial_angle_rad, spacecraft_rate_rad_s)

    after_state =
      circular_pass_state(radius_km, 600.0, initial_angle_rad, spacecraft_rate_rad_s)

    assert {:ok, linear} =
             AccessWindows.refine_aos_los_boundary(before_state, after_state, station,
               central_body: earth
             )

    root_opts = [
      central_body: earth,
      boundary_refinement: :bracketed_bisection,
      root_tolerance_s: 1.0e-3
    ]

    assert {:ok, root} =
             OrbitalDynamics.refine_access_boundary(
               before_state,
               after_state,
               station,
               root_opts
             )

    assert AccessWindows.refine_aos_los_boundary(
             before_state,
             after_state,
             station,
             root_opts
           ) == {:ok, root}

    horizon_angle_rad = :math.acos(earth.equatorial_radius_km / radius_km)

    analytical_spherical_crossing_s =
      (horizon_angle_rad - initial_angle_rad) /
        (spacecraft_rate_rad_s - @earth_rotation_rate_rad_s)

    assert root.boundary == :aos
    assert root.interpolation == :cubic_hermite_state

    aos_model_error_s =
      abs(root.epoch.seconds_since_j2000 - analytical_spherical_crossing_s)

    assert aos_model_error_s <
             abs(linear.epoch.seconds_since_j2000 - analytical_spherical_crossing_s)

    assert aos_model_error_s < 0.5

    assert %{
             event_timing_policy: :sampled_state_bracketed_root_refinement,
             interpolation: :cubic_hermite_state,
             refinement_model: :aos_los_bracketed_bisection,
             root_solver: :bisection,
             root_function: :elevation_margin_deg,
             root_scope: :cubic_hermite_interpolated_state_geometry,
             root_solved: true,
             validation_level: :analysis,
             confidence: :bounded_root_in_interpolated_state,
             requested_root_tolerance_s: 1.0e-3,
             input_event_time_bracket_s: 600.0,
             before_epoch_s: before_epoch_s,
             after_epoch_s: 600.0,
             root_max_iterations: 64
           } = root.assumptions

    assert before_epoch_s == 0.0
    assert root.assumptions.event_time_tolerance_s <= 1.0e-3
    assert root.assumptions.event_time_bracket_s <= 2.0e-3
    assert root.assumptions.root_iterations > 0
    assert root.assumptions.root_function_evaluations > root.assumptions.root_iterations
    assert :not_dense_propagator_output in root.assumptions.model_limits
    assert :not_externally_validated in root.assumptions.model_limits
    assert :not_flight_fidelity in root.assumptions.model_limits

    trajectory = trajectory([before_state, after_state])

    assert {:ok, [event]} =
             AccessWindows.detect(trajectory,
               ground_station: station,
               central_body: earth,
               boundary_refinement: :bracketed_bisection,
               root_tolerance_s: 1.0e-3
             )

    assert event.starts_at == root.epoch
    assert event.metadata.interpolation == :cubic_hermite_state
    assert event.metadata.boundary_refinement == :aos_los_bracketed_bisection
    assert event.metadata.start_boundary == :root_refined
    assert event.metadata.start_boundary_detail.root_solved == true
    assert event.metadata.start_boundary_detail.edge == :start

    assert event.metadata.event_timing_policy ==
             :sampled_state_bracketed_root_refinement

    assert event.metadata.root_refined_boundary_count == 1
    assert event.metadata.clipped_boundary_count == 1
    assert event.metadata.confidence == :mixed_root_refined_and_sample_clipped

    # The clipped end keeps the event-wide bound at sample cadence even though
    # the AOS boundary has the tighter local root bracket above.
    assert event.metadata.event_time_tolerance_s == 600.0

    complete_trajectory =
      trajectory([
        before_state,
        circular_pass_state(radius_km, 300.0, initial_angle_rad, spacecraft_rate_rad_s),
        circular_pass_state(radius_km, 1200.0, initial_angle_rad, spacecraft_rate_rad_s)
      ])

    assert {:ok, [complete_event]} =
             AccessWindows.detect(complete_trajectory,
               ground_station: station,
               central_body: earth,
               boundary_refinement: :bracketed_bisection,
               root_tolerance_s: 1.0e-3
             )

    assert complete_event.metadata.start_boundary == :root_refined
    assert complete_event.metadata.end_boundary == :root_refined
    assert complete_event.metadata.root_refined_boundary_count == 2
    assert complete_event.metadata.clipped_boundary_count == 0
    assert complete_event.metadata.confidence == :bounded_root_in_interpolated_state
    assert complete_event.metadata.event_time_tolerance_s <= 1.0e-3

    los_rate_rad_s = :math.pi() / 3600.0
    before_los = circular_pass_state(radius_km, 0.0, 0.0, los_rate_rad_s)
    after_los = circular_pass_state(radius_km, 600.0, 0.0, los_rate_rad_s)

    assert {:ok, linear_los} =
             AccessWindows.refine_aos_los_boundary(before_los, after_los, station,
               central_body: earth
             )

    assert {:ok, los} =
             AccessWindows.refine_aos_los_boundary(before_los, after_los, station, root_opts)

    analytical_los_s = horizon_angle_rad / (los_rate_rad_s - @earth_rotation_rate_rad_s)

    assert los.boundary == :los

    los_model_error_s = abs(los.epoch.seconds_since_j2000 - analytical_los_s)

    assert los_model_error_s <
             abs(linear_los.epoch.seconds_since_j2000 - analytical_los_s)

    assert los_model_error_s < 0.5

    assert los.assumptions.event_time_tolerance_s <= 1.0e-3
  end

  test "root refinement rejects incompatible states and reports bounded non-convergence" do
    earth = CentralBody.earth()
    station = GroundStation.new!(:equator, 0.0, 0.0, minimum_elevation_deg: 0.0)
    radius_km = earth.equatorial_radius_km + 500.0
    initial_angle_rad = :math.pi() / 6.0
    spacecraft_rate_rad_s = -:math.pi() / 3600.0

    before_state =
      circular_pass_state(radius_km, 0.0, initial_angle_rad, spacecraft_rate_rad_s)

    after_state =
      circular_pass_state(radius_km, 600.0, initial_angle_rad, spacecraft_rate_rad_s)

    assert {:error,
            {:root_refinement_not_converged,
             %{
               root_iterations: 1,
               root_max_iterations: 1,
               requested_root_tolerance_s: 1.0e-12,
               remaining_event_time_bracket_s: 300.0
             }}} =
             AccessWindows.refine_aos_los_boundary(before_state, after_state, station,
               central_body: earth,
               boundary_refinement: :bracketed_bisection,
               root_tolerance_s: 1.0e-12,
               root_max_iterations: 1
             )

    assert {:error,
            {:boundary_refinement_failed, :start,
             {:root_refinement_not_converged, %{root_iterations: 1}}}} =
             AccessWindows.detect(trajectory([before_state, after_state]),
               ground_station: station,
               central_body: earth,
               boundary_refinement: :bracketed_bisection,
               root_tolerance_s: 1.0e-12,
               root_max_iterations: 1
             )

    incompatible_frame = Frame.new!(:other_eci, :earth, :j2000)

    assert {:error, :incompatible_state_frames} =
             AccessWindows.refine_aos_los_boundary(
               before_state,
               %{after_state | frame: incompatible_frame},
               station,
               central_body: earth,
               boundary_refinement: :bracketed_bisection
             )

    assert {:error, :incompatible_epoch_scales} =
             AccessWindows.refine_aos_los_boundary(
               before_state,
               %{after_state | epoch: Epoch.new!(600.0, :utc)},
               station,
               central_body: earth,
               boundary_refinement: :bracketed_bisection
             )

    assert {:error, {:invalid_option, :root_tolerance_s}} =
             AccessWindows.refine_aos_los_boundary(before_state, after_state, station,
               central_body: earth,
               boundary_refinement: :bracketed_bisection,
               root_tolerance_s: 0.0
             )

    assert {:error, {:invalid_option, :root_max_iterations}} =
             AccessWindows.refine_aos_los_boundary(before_state, after_state, station,
               central_body: earth,
               boundary_refinement: :bracketed_bisection,
               root_max_iterations: 101
             )

    assert {:error, :non_increasing_state_epochs} =
             AccessWindows.refine_aos_los_boundary(
               before_state,
               %{after_state | epoch: Epoch.new!(0.0, :tdb)},
               station,
               central_body: earth,
               boundary_refinement: :bracketed_bisection
             )
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

  test "public access boundaries reject hostile inputs with typed errors" do
    earth = CentralBody.earth()
    station = GroundStation.new!(:equator, 0.0, 0.0)
    before_state = opposite_earth(earth, 0.0)
    after_state = above_station(earth, 60.0)
    trajectory = trajectory([before_state, after_state])

    assert {:error, {:missing_option, :ground_station}} =
             AccessWindows.detect(trajectory, central_body: earth)

    assert {:error, {:invalid_container, :opts}} =
             AccessWindows.detect(trajectory, [{:ground_station, station} | :tail])

    assert {:error, {:container_depth_exceeded, :opts}} =
             AccessWindows.detect(trajectory,
               ground_station: station,
               central_body: earth,
               audit_payload: deep_value(10)
             )

    assert {:error, {:invalid_container, :opts}} =
             AccessWindows.detect(trajectory,
               ground_station: station,
               central_body: earth,
               audit_payload: %{42 => "bad key"}
             )

    assert {:error, {:invalid_container, :opts}} =
             AccessWindows.detect(trajectory,
               ground_station: station,
               central_body: earth,
               ignored: @safe_number_bound + 1
             )

    assert {:error, {:invalid_container, :opts}} =
             AccessWindows.detect(trajectory,
               ground_station: station,
               central_body: earth,
               ignored: huge_integer()
             )

    assert {:error, {:unsupported_option, :ignored}} =
             AccessWindows.detect(trajectory,
               ground_station: station,
               central_body: earth,
               ignored: "safe"
             )

    assert {:error, {:invalid_option, :trajectory}} =
             AccessWindows.detect(:not_a_trajectory, ground_station: station, central_body: earth)

    assert {:error, {:invalid_container, :states}} =
             AccessWindows.detect(
               %Trajectory{trajectory | states: [before_state | :tail]},
               ground_station: station,
               central_body: earth
             )

    assert {:error, {:invalid_state, :state}} =
             AccessWindows.detect(
               %Trajectory{
                 trajectory
                 | states: [%{before_state | position_km: {1.0e16, 0.0, 0.0}}]
               },
               ground_station: station,
               central_body: earth
             )

    assert {:error, {:invalid_trajectory, :non_increasing_epochs}} =
             AccessWindows.detect(
               trajectory([after_state, before_state]),
               ground_station: station,
               central_body: earth
             )

    assert {:error, {:invalid_option, :ground_station}} =
             AccessWindows.detect(trajectory,
               ground_station: %{station | latitude_deg: 1.0e16},
               central_body: earth
             )

    assert {:error, {:invalid_option, :ground_station}} =
             AccessWindows.detect(trajectory,
               ground_station: %{station | latitude_deg: @safe_number_bound + 1},
               central_body: earth
             )

    assert {:error, {:invalid_option, :ground_station}} =
             AccessWindows.detect(trajectory,
               ground_station: %{station | latitude_deg: huge_integer()},
               central_body: earth
             )

    assert {:error, {:invalid_central_body, :equatorial_radius_km}} =
             AccessWindows.detect(trajectory,
               ground_station: station,
               central_body: %{earth | equatorial_radius_km: 1.0e16}
             )

    assert {:error, {:invalid_central_body, :equatorial_radius_km}} =
             AccessWindows.detect(trajectory,
               ground_station: station,
               central_body: %{earth | equatorial_radius_km: @safe_number_bound + 1}
             )

    assert {:error, {:invalid_central_body, :equatorial_radius_km}} =
             AccessWindows.detect(trajectory,
               ground_station: station,
               central_body: %{earth | equatorial_radius_km: huge_integer()}
             )

    for {label, nonfinite} <- nonfinite_float_values() do
      assert {:error, {:invalid_option, :ground_station}} =
               AccessWindows.detect(trajectory,
                 ground_station: %{station | latitude_deg: nonfinite},
                 central_body: earth
               ),
             "#{label} ground station numeric field was admitted"

      assert {:error, {:invalid_central_body, :equatorial_radius_km}} =
               AccessWindows.detect(trajectory,
                 ground_station: station,
                 central_body: %{earth | equatorial_radius_km: nonfinite}
               ),
             "#{label} central body numeric field was admitted"
    end

    assert {:ok, [_event]} =
             AccessWindows.detect(trajectory,
               ground_station: station,
               central_body: earth,
               root_tolerance_s: @safe_number_bound
             )

    assert {:error, {:invalid_option, :root_tolerance_s}} =
             AccessWindows.detect(trajectory,
               ground_station: station,
               central_body: earth,
               root_tolerance_s: @safe_number_bound + 1
             )

    assert {:error, {:invalid_option, :root_tolerance_s}} =
             AccessWindows.detect(trajectory,
               ground_station: station,
               central_body: earth,
               root_tolerance_s: huge_integer()
             )

    callback_probe = fn -> send(self(), :access_callback_invoked) end

    for {label, bad_value} <- hostile_option_values(callback_probe) do
      assert {:error, {:invalid_container, :opts}} =
               AccessWindows.detect(trajectory,
                 ground_station: station,
                 central_body: earth,
                 ignored: bad_value
               ),
             "#{label} ignored access option was admitted"

      assert {:error, {:invalid_container, :opts}} =
               AccessWindows.detect(trajectory,
                 ground_station: %{station | id: bad_value},
                 central_body: earth
               ),
             "#{label} ground station field was admitted"

      assert {:error, {:invalid_container, :opts}} =
               AccessWindows.detect(trajectory,
                 ground_station: station,
                 central_body: %{earth | name: bad_value}
               ),
             "#{label} central body field was admitted"

      assert {:error, {:invalid_container, :opts}} =
               AccessWindows.refine_aos_los_boundary(
                 before_state,
                 after_state,
                 station,
                 central_body: earth,
                 ignored: bad_value
               ),
             "#{label} refine ignored access option was admitted"

      refute_receive :access_callback_invoked
    end

    assert {:error, {:unsupported_boundary_refinement, :unsupported}} =
             AccessWindows.model_limits(:unsupported)

    assert {:error, {:invalid_option, :access_boundary}} =
             AccessWindows.refine_aos_los_boundary(
               :before,
               after_state,
               station,
               central_body: earth
             )

    assert {:error, {:invalid_state, :before_state}} =
             AccessWindows.refine_aos_los_boundary(
               %{before_state | velocity_km_s: {0.0, 1.0e16, 0.0}},
               after_state,
               station,
               central_body: earth
             )

    assert {:error, {:container_limit_exceeded, :opts}} =
             AccessWindows.refine_aos_los_boundary(
               before_state,
               after_state,
               station,
               central_body: earth,
               audit_payload: wide_map(129)
             )
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

  defp circular_pass_state(radius_km, seconds_since_j2000, initial_angle_rad, rate_rad_s) do
    angle_rad = initial_angle_rad + rate_rad_s * seconds_since_j2000

    state(
      {radius_km * :math.cos(angle_rad), radius_km * :math.sin(angle_rad), 0.0},
      {
        -radius_km * rate_rad_s * :math.sin(angle_rad),
        radius_km * rate_rad_s * :math.cos(angle_rad),
        0.0
      },
      seconds_since_j2000
    )
  end

  defp state(position_km, seconds_since_j2000) do
    state(position_km, {0.0, 0.0, 0.0}, seconds_since_j2000)
  end

  defp state(position_km, velocity_km_s, seconds_since_j2000) do
    StateVector.new!(
      position_km,
      velocity_km_s,
      Epoch.new!(seconds_since_j2000, :tdb),
      Frame.earth_inertial_j2000()
    )
  end

  defp deep_value(depth) do
    Enum.reduce(1..depth, "leaf", fn index, acc -> %{"level_#{index}" => acc} end)
  end

  defp wide_map(count) do
    Map.new(1..count, fn index -> {"k#{index}", index} end)
  end

  defp hostile_option_values(callback_probe) do
    [
      {"struct", %StructProbe{value: :nested}},
      {"pid", self()},
      {"reference", make_ref()},
      {"function", callback_probe},
      {"tuple", {:tuple, :not_json}}
    ] ++ port_probe_values()
  end

  defp port_probe_values do
    case Port.list() do
      [port | _rest] -> [{"port", port}]
      [] -> []
    end
  end

  defp huge_integer, do: :erlang.bsl(1, 1_000_000)

  defp nonfinite_float_values do
    [
      {"nan", :erlang.binary_to_term(<<131, 70, 127, 248, 0, 0, 0, 0, 0, 1>>, [:safe])},
      {"positive infinity",
       :erlang.binary_to_term(<<131, 70, 127, 240, 0, 0, 0, 0, 0, 0>>, [:safe])},
      {"negative infinity",
       :erlang.binary_to_term(<<131, 70, 255, 240, 0, 0, 0, 0, 0, 0>>, [:safe])}
    ]
  end
end
