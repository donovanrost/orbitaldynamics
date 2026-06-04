defmodule OrbitalDynamics.EventDetectors.TargetVisibilityTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.EventDetectors.TargetVisibility
  alias OrbitalDynamics.{CentralBody, Epoch, Frame, StateVector, Target, Trajectory}

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
end
