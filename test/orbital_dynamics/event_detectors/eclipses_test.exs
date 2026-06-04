defmodule OrbitalDynamics.EventDetectors.EclipsesTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.EventDetectors.Eclipses
  alias OrbitalDynamics.{CentralBody, Epoch, Frame, StateVector, Trajectory}

  test "declares detector capabilities" do
    assert %{
             detector: :eclipses,
             model: :cylindrical_central_body_shadow,
             validation_level: :analysis,
             timing_policy: :sampled_state_linear_boundary,
             interpolation: :linear_sample_crossing,
             boundary_refinement: :eclipse_linear_shadow_margin_interpolation,
             lighting_summary_model: :sampled_eclipse_overlap_fraction,
             known_limits: known_limits
           } = Eclipses.capabilities()

    assert :sample_cadence_limited in known_limits
    assert :refinement_not_root_solved in known_limits
    assert :no_penumbra_model in known_limits
  end

  test "classifies sampled eclipse overlap lighting summary" do
    assert Eclipses.lighting_summary(100.0, 0.0) == %{
             "lighting_condition" => "sunlit",
             "lighting_condition_detail" => "sunlit",
             "lighting_condition_model" => "sampled_eclipse_overlap_tag",
             "lighting_detail_model" => "sampled_eclipse_overlap_fraction_tag",
             "eclipse_overlap_fraction" => 0.0,
             "lighting_confidence" => "bounded_by_sampled_eclipse_overlap"
           }

    assert Eclipses.lighting_summary(100.0, 80.0) == %{
             "lighting_condition" => "partial_eclipse",
             "lighting_condition_detail" => "mostly_eclipsed",
             "lighting_condition_model" => "sampled_eclipse_overlap_tag",
             "lighting_detail_model" => "sampled_eclipse_overlap_fraction_tag",
             "eclipse_overlap_fraction" => 0.8,
             "lighting_confidence" => "bounded_by_sampled_eclipse_overlap"
           }

    assert Eclipses.lighting_summary(0.0, 10.0)["lighting_condition_detail"] == "unknown"
  end

  test "detects one eclipse interval from contiguous shadow samples" do
    earth = CentralBody.earth()

    trajectory =
      trajectory([
        anti_sunward_inside_shadow(earth, 0.0),
        anti_sunward_inside_shadow(earth, 60.0),
        sunward(earth, 120.0)
      ])

    assert {:ok, [event]} =
             Eclipses.detect(trajectory, central_body: earth, sun_direction: {1.0, 0.0, 0.0})

    assert event.type == :eclipse
    assert event.starts_at.seconds_since_j2000 == 0.0
    assert event.ends_at.seconds_since_j2000 > 60.0
    assert event.ends_at.seconds_since_j2000 < 120.0
    assert event.metadata.scenario_id == :eclipse_test
    assert event.metadata.shadow_model == :cylindrical_central_body_shadow
    assert event.metadata.interpolation == :linear_sample_crossing
    assert event.metadata.boundary_refinement == :eclipse_linear_shadow_margin_interpolation
    assert event.metadata.start_boundary == :clipped_start
    assert event.metadata.end_boundary == :interpolated
    assert event.metadata.start_boundary_detail.boundary == :clipped_start
    assert event.metadata.start_boundary_detail.interpolation == :clipped_to_sample
    assert event.metadata.start_boundary_detail.root_solved == false
    assert event.metadata.end_boundary_detail.boundary == :eclipse_exit
    assert event.metadata.end_boundary_detail.edge == :end
    assert event.metadata.end_boundary_detail.interpolation == :linear_sample_crossing
    assert event.metadata.end_boundary_detail.interpolation_fraction > 0.0
    assert event.metadata.end_boundary_detail.interpolation_fraction < 1.0

    assert event.metadata.end_boundary_detail.event_timing_policy ==
             :sampled_state_linear_boundary

    assert event.metadata.end_boundary_detail.event_time_bracket_s == 60.0
    assert event.metadata.end_boundary_detail.before_epoch_s == 60.0
    assert event.metadata.end_boundary_detail.after_epoch_s == 120.0
    assert event.metadata.end_boundary_detail.before_eclipsed == true
    assert event.metadata.end_boundary_detail.after_eclipsed == false
    assert event.metadata.end_boundary_detail.root_solved == false
    assert event.metadata.sample_count == 2
    assert event.metadata.sun_direction == {1.0, 0.0, 0.0}
    assert event.metadata.maximum_shadow_margin_km > earth.equatorial_radius_km - 1.0
    assert event.metadata.event_timing_policy == :sampled_state_linear_boundary
    assert event.metadata.event_detector == :eclipses
    assert event.metadata.event_time_tolerance_s == 60.0
  end

  test "public API detects eclipse intervals" do
    earth = CentralBody.earth()
    trajectory = trajectory([anti_sunward_inside_shadow(earth, 0.0)])

    assert {:ok, [%{type: :eclipse}]} =
             OrbitalDynamics.eclipse_intervals(trajectory,
               central_body: earth,
               sun_direction: {1.0, 0.0, 0.0}
             )
  end

  test "refines bracketed eclipse entry and exit boundaries" do
    earth = CentralBody.earth()

    before_entry = sunward(earth, 0.0)
    after_entry = anti_sunward_inside_shadow(earth, 60.0)

    assert {:ok, entry} =
             Eclipses.refine_eclipse_boundary(before_entry, after_entry,
               central_body: earth,
               sun_direction: {1.0, 0.0, 0.0}
             )

    assert entry.boundary == :eclipse_entry
    assert entry.interpolation == :linear_sample_crossing
    assert entry.interpolation_fraction > 0.0
    assert entry.interpolation_fraction < 1.0
    assert entry.epoch.seconds_since_j2000 > 0.0
    assert entry.epoch.seconds_since_j2000 < 60.0
    assert entry.before_eclipsed == false
    assert entry.after_eclipsed == true
    assert entry.assumptions.root_solved == false
    assert entry.assumptions.event_time_bracket_s == 60.0
    assert entry.assumptions.before_epoch_s == 0.0
    assert entry.assumptions.after_epoch_s == 60.0

    assert {:ok, exit_boundary} =
             OrbitalDynamics.refine_eclipse_boundary(after_entry, sunward(earth, 120.0),
               central_body: earth,
               sun_direction: {1.0, 0.0, 0.0}
             )

    assert exit_boundary.boundary == :eclipse_exit
    assert exit_boundary.epoch.seconds_since_j2000 > 60.0
    assert exit_boundary.epoch.seconds_since_j2000 < 120.0
  end

  test "rejects unbracketed eclipse boundary refinement" do
    earth = CentralBody.earth()

    assert {:error, :not_bracketed} =
             Eclipses.refine_eclipse_boundary(
               anti_sunward_inside_shadow(earth, 0.0),
               anti_sunward_inside_shadow(earth, 60.0),
               central_body: earth,
               sun_direction: {1.0, 0.0, 0.0}
             )
  end

  test "returns no intervals for sunward or outside-cylinder samples" do
    earth = CentralBody.earth()

    trajectory =
      trajectory([
        sunward(earth, 0.0),
        anti_sunward_outside_shadow(earth, 60.0)
      ])

    assert {:ok, []} =
             Eclipses.detect(trajectory, central_body: earth, sun_direction: {1.0, 0.0, 0.0})
  end

  test "splits separated eclipsed samples into separate intervals" do
    earth = CentralBody.earth()

    trajectory =
      trajectory([
        anti_sunward_inside_shadow(earth, 0.0),
        sunward(earth, 60.0),
        anti_sunward_inside_shadow(earth, 120.0)
      ])

    assert {:ok, [first, second]} =
             Eclipses.detect(trajectory, central_body: earth, sun_direction: {1.0, 0.0, 0.0})

    assert first.starts_at.seconds_since_j2000 == 0.0
    assert first.ends_at.seconds_since_j2000 > 0.0
    assert first.ends_at.seconds_since_j2000 < 60.0
    assert second.starts_at.seconds_since_j2000 > 60.0
    assert second.starts_at.seconds_since_j2000 < 120.0
    assert second.ends_at.seconds_since_j2000 == 120.0
  end

  test "rejects invalid detector options" do
    earth = CentralBody.earth()
    trajectory = trajectory([anti_sunward_inside_shadow(earth, 0.0)])

    assert {:error, {:invalid_option, :sun_direction}} =
             Eclipses.detect(trajectory, central_body: earth, sun_direction: {0.0, 0.0, 0.0})
  end

  defp trajectory(states) do
    %Trajectory{
      scenario_id: :eclipse_test,
      states: states,
      assumptions: %{force_model: :manual}
    }
  end

  defp anti_sunward_inside_shadow(earth, seconds_since_j2000) do
    state({-(earth.equatorial_radius_km + 500.0), 0.0, 0.0}, seconds_since_j2000)
  end

  defp anti_sunward_outside_shadow(earth, seconds_since_j2000) do
    state(
      {-(earth.equatorial_radius_km + 500.0), earth.equatorial_radius_km + 1.0, 0.0},
      seconds_since_j2000
    )
  end

  defp sunward(earth, seconds_since_j2000) do
    state({earth.equatorial_radius_km + 500.0, 0.0, 0.0}, seconds_since_j2000)
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
