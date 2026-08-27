defmodule OrbitalDynamics.EventDetectors.TargetVisibilityTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.EventDetectors.TargetVisibility
  alias OrbitalDynamics.{CentralBody, Epoch, Frame, StateVector, Target, Trajectory}

  @safe_number_bound 1_000_000_000_000_000

  defmodule StructProbe do
    defstruct [:value]
  end

  test "declares detector capabilities" do
    assert %{
             detector: :target_visibility,
             validation_level: :analysis,
             timing_policy: :sampled_state_linear_boundary,
             interpolation: :linear_sample_crossing,
             boundary_refinement: :target_visibility_linear_margin_interpolation,
             coordinate_model: :spherical_earth_access_geometry,
             known_limits: known_limits
           } = TargetVisibility.capabilities()

    assert :sample_cadence_limited in known_limits
    assert :refinement_not_root_solved in known_limits
    assert :no_lighting_category_model in known_limits
  end

  test "detects one target visibility window from contiguous visible samples" do
    earth = CentralBody.earth()
    target = Target.new!(:target_a, 0.0, 0.0, minimum_elevation_deg: 0.0, priority: 4.0)

    trajectory =
      trajectory([
        above_target(earth, 0.0),
        above_target(earth, 60.0),
        opposite_earth(earth, 120.0)
      ])

    assert {:ok, [event]} =
             TargetVisibility.detect(trajectory, target: target, central_body: earth)

    assert event.type == :target_visibility
    assert event.starts_at.seconds_since_j2000 == 0.0
    assert event.ends_at.seconds_since_j2000 > 60.0
    assert event.ends_at.seconds_since_j2000 < 120.0
    assert event.metadata.target_id == :target_a
    assert event.metadata.target_priority == 4.0
    assert event.metadata.sample_count == 2
    assert event.metadata.geometry_model == :simplified_spherical_earth_rotation
    assert event.metadata.interpolation == :linear_sample_crossing
    assert event.metadata.boundary_refinement == :target_visibility_linear_margin_interpolation
    assert event.metadata.start_boundary == :clipped_start
    assert event.metadata.end_boundary == :interpolated
    assert event.metadata.start_boundary_detail.boundary == :clipped_start
    assert event.metadata.start_boundary_detail.interpolation == :clipped_to_sample
    assert event.metadata.start_boundary_detail.root_solved == false
    assert event.metadata.end_boundary_detail.boundary == :visibility_end
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
    assert event.metadata.event_timing_policy == :sampled_state_linear_boundary
    assert event.metadata.event_detector == :target_visibility
    assert event.metadata.event_time_tolerance_s == 60.0
  end

  test "public API detects target visibility windows" do
    earth = CentralBody.earth()
    target = Target.new!(:target_a, 0.0, 0.0)
    trajectory = trajectory([above_target(earth, 0.0)])

    assert {:ok, [%{type: :target_visibility}]} =
             OrbitalDynamics.target_visibility_windows(trajectory, target, central_body: earth)
  end

  test "refines bracketed target visibility boundaries" do
    earth = CentralBody.earth()
    target = Target.new!(:target_a, 0.0, 0.0, minimum_elevation_deg: 0.0)

    before_visibility = opposite_earth(earth, 0.0)
    after_visibility = above_target(earth, 60.0)

    assert {:ok, visibility_start} =
             TargetVisibility.refine_visibility_boundary(
               before_visibility,
               after_visibility,
               target,
               central_body: earth
             )

    assert visibility_start.boundary == :visibility_start
    assert visibility_start.interpolation == :linear_sample_crossing
    assert visibility_start.interpolation_fraction > 0.0
    assert visibility_start.interpolation_fraction < 1.0
    assert visibility_start.epoch.seconds_since_j2000 > 0.0
    assert visibility_start.epoch.seconds_since_j2000 < 60.0
    assert visibility_start.assumptions.root_solved == false
    assert visibility_start.assumptions.event_time_bracket_s == 60.0
    assert visibility_start.assumptions.before_epoch_s == 0.0
    assert visibility_start.assumptions.after_epoch_s == 60.0

    assert {:ok, visibility_end} =
             OrbitalDynamics.refine_target_visibility_boundary(
               after_visibility,
               opposite_earth(earth, 120.0),
               target,
               central_body: earth
             )

    assert visibility_end.boundary == :visibility_end
    assert visibility_end.epoch.seconds_since_j2000 > 60.0
    assert visibility_end.epoch.seconds_since_j2000 < 120.0
  end

  test "rejects unbracketed target visibility boundary refinement" do
    earth = CentralBody.earth()
    target = Target.new!(:target_a, 0.0, 0.0, minimum_elevation_deg: 0.0)

    assert {:error, :not_bracketed} =
             TargetVisibility.refine_visibility_boundary(
               above_target(earth, 0.0),
               above_target(earth, 60.0),
               target,
               central_body: earth
             )
  end

  test "rejects invalid detector options" do
    earth = CentralBody.earth()
    trajectory = trajectory([above_target(earth, 0.0)])

    assert {:error, {:invalid_option, :target}} =
             TargetVisibility.detect(trajectory, target: :not_a_target, central_body: earth)
  end

  test "public target visibility boundaries reject hostile inputs with typed errors" do
    earth = CentralBody.earth()
    target = Target.new!(:target_a, 0.0, 0.0)
    before_state = opposite_earth(earth, 0.0)
    after_state = above_target(earth, 60.0)
    trajectory = trajectory([before_state, after_state])

    assert {:error, {:missing_option, :target}} =
             TargetVisibility.detect(trajectory, central_body: earth)

    assert {:error, {:invalid_container, :opts}} =
             TargetVisibility.detect(trajectory, [{:target, target} | :tail])

    assert {:error, {:container_depth_exceeded, :opts}} =
             TargetVisibility.detect(trajectory,
               target: target,
               central_body: earth,
               audit_payload: deep_value(10)
             )

    assert {:error, {:invalid_container, :opts}} =
             TargetVisibility.detect(trajectory,
               target: target,
               central_body: earth,
               audit_payload: %{42 => "bad key"}
             )

    assert {:error, {:invalid_container, :opts}} =
             TargetVisibility.detect(trajectory,
               target: target,
               central_body: earth,
               ignored: @safe_number_bound + 1
             )

    assert {:error, {:invalid_container, :opts}} =
             TargetVisibility.detect(trajectory,
               target: target,
               central_body: earth,
               ignored: huge_integer()
             )

    assert {:error, {:unsupported_option, :ignored}} =
             TargetVisibility.detect(trajectory,
               target: target,
               central_body: earth,
               ignored: "safe"
             )

    assert {:error, {:invalid_option, :trajectory}} =
             TargetVisibility.detect(:not_a_trajectory, target: target, central_body: earth)

    assert {:error, {:invalid_container, :states}} =
             TargetVisibility.detect(
               %Trajectory{trajectory | states: [before_state | :tail]},
               target: target,
               central_body: earth
             )

    assert {:error, {:invalid_state, :state}} =
             TargetVisibility.detect(
               %Trajectory{
                 trajectory
                 | states: [%{before_state | position_km: {1.0e16, 0.0, 0.0}}]
               },
               target: target,
               central_body: earth
             )

    assert {:error, {:invalid_trajectory, :non_increasing_epochs}} =
             TargetVisibility.detect(
               trajectory([after_state, before_state]),
               target: target,
               central_body: earth
             )

    assert {:error, {:invalid_option, :target}} =
             TargetVisibility.detect(trajectory,
               target: %{target | priority: 1.0e16},
               central_body: earth
             )

    assert {:ok, [_event]} =
             TargetVisibility.detect(trajectory,
               target: %{target | priority: @safe_number_bound},
               central_body: earth
             )

    assert {:error, {:invalid_option, :target}} =
             TargetVisibility.detect(trajectory,
               target: %{target | priority: @safe_number_bound + 1},
               central_body: earth
             )

    assert {:error, {:invalid_option, :target}} =
             TargetVisibility.detect(trajectory,
               target: %{target | priority: huge_integer()},
               central_body: earth
             )

    assert {:error, {:invalid_central_body, :equatorial_radius_km}} =
             TargetVisibility.detect(trajectory,
               target: target,
               central_body: %{earth | equatorial_radius_km: 1.0e16}
             )

    assert {:error, {:invalid_central_body, :equatorial_radius_km}} =
             TargetVisibility.detect(trajectory,
               target: target,
               central_body: %{earth | equatorial_radius_km: @safe_number_bound + 1}
             )

    assert {:error, {:invalid_central_body, :equatorial_radius_km}} =
             TargetVisibility.detect(trajectory,
               target: target,
               central_body: %{earth | equatorial_radius_km: huge_integer()}
             )

    for {label, nonfinite} <- nonfinite_float_values() do
      assert {:error, {:invalid_option, :target}} =
               TargetVisibility.detect(trajectory,
                 target: %{target | priority: nonfinite},
                 central_body: earth
               ),
             "#{label} target numeric field was admitted"

      assert {:error, {:invalid_central_body, :equatorial_radius_km}} =
               TargetVisibility.detect(trajectory,
                 target: target,
                 central_body: %{earth | equatorial_radius_km: nonfinite}
               ),
             "#{label} central body numeric field was admitted"
    end

    callback_probe = fn -> send(self(), :target_visibility_callback_invoked) end

    for {label, bad_value} <- hostile_option_values(callback_probe) do
      assert {:error, {:invalid_container, :opts}} =
               TargetVisibility.detect(trajectory,
                 target: target,
                 central_body: earth,
                 ignored: bad_value
               ),
             "#{label} ignored target visibility option was admitted"

      assert {:error, {:invalid_container, :opts}} =
               TargetVisibility.detect(trajectory,
                 target: %{target | id: bad_value},
                 central_body: earth
               ),
             "#{label} target field was admitted"

      assert {:error, {:invalid_container, :opts}} =
               TargetVisibility.detect(trajectory,
                 target: target,
                 central_body: %{earth | name: bad_value}
               ),
             "#{label} central body field was admitted"

      assert {:error, {:invalid_container, :opts}} =
               TargetVisibility.refine_visibility_boundary(
                 before_state,
                 after_state,
                 target,
                 central_body: earth,
                 ignored: bad_value
               ),
             "#{label} refine ignored target option was admitted"

      refute_receive :target_visibility_callback_invoked
    end

    assert {:error, {:invalid_option, :visibility_boundary}} =
             TargetVisibility.refine_visibility_boundary(
               :before,
               after_state,
               target,
               central_body: earth
             )

    assert {:error, {:invalid_state, :before_state}} =
             TargetVisibility.refine_visibility_boundary(
               %{before_state | velocity_km_s: {0.0, 1.0e16, 0.0}},
               after_state,
               target,
               central_body: earth
             )

    assert {:error, {:container_limit_exceeded, :opts}} =
             TargetVisibility.refine_visibility_boundary(
               before_state,
               after_state,
               target,
               central_body: earth,
               audit_payload: wide_map(129)
             )
  end

  defp trajectory(states) do
    %Trajectory{
      scenario_id: :target_visibility_test,
      states: states,
      assumptions: %{force_model: :manual}
    }
  end

  defp above_target(earth, seconds_since_j2000) do
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
