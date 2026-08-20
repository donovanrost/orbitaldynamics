defmodule OrbitalDynamics.Validation.OrbitalReferenceFixtureTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.Validation.OrbitalReferenceFixtures,
    only: [
      access_fixture_observations: 0,
      atmospheric_drag_fixture_observations: 0,
      eclipse_fixture_observations: 0,
      ground_track_crossing_fixture_observations: 0,
      j2_fixture_observations: 0,
      j2_drag_convergence_fixture_observations: 0,
      target_visibility_fixture_observations: 0,
      two_body_drag_fixture_observations: 0,
      two_body_fixture_observations: 0
    ]

  alias OrbitalDynamics.Validation

  test "verifies curated atmospheric-drag reference fixture observations" do
    fixture_id = "fixture.force_model.atmospheric_drag.earth_400km"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)
    assert fixture["model_id"] == "force_model.atmospheric_drag"
    assert fixture["fixture_type"] == "curated_internal_regression"

    observations = atmospheric_drag_fixture_observations()
    assert {:ok, report} = Validation.verify_reference_fixture(fixture_id, observations)
    assert report["schema_contract"] == "validation_reference_report.v1"
    assert report["status"] == "pass"
    assert Enum.all?(report["checks"], &(&1["status"] == "pass"))

    stale_observations = Map.put(observations, "acceleration_magnitude_km_s2", 0.0)

    assert {:ok, stale_report} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_report["status"] == "fail"

    assert Enum.any?(
             stale_report["checks"],
             &(&1["field"] == "acceleration_magnitude_km_s2" and &1["status"] == "fail")
           )
  end

  test "verifies the curated two-body-drag trajectory fixture through the Study path" do
    fixture_id = "fixture.propagator.two_body_drag.earth_400km_600s"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)
    assert fixture["model_id"] == "propagator.two_body_drag"
    assert fixture["fixture_type"] == "curated_internal_regression"

    observations = two_body_drag_fixture_observations()
    assert observations["specific_energy_change_km2_s2"] < 0.0

    assert {:ok, report} = Validation.verify_reference_fixture(fixture_id, observations)
    assert report["status"] == "pass"
    assert Enum.all?(report["checks"], &(&1["status"] == "pass"))

    stale_observations = Map.put(observations, "specific_energy_change_km2_s2", 0.0)

    assert {:ok, stale_report} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_report["status"] == "fail"

    assert Enum.any?(
             stale_report["checks"],
             &(&1["field"] == "specific_energy_change_km2_s2" and &1["status"] == "fail")
           )
  end

  test "verifies the declared 24-hour J2-drag internal step-convergence fixture" do
    fixture_id = "fixture.propagator.j2_drag.earth_400km_24h_step_convergence"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)
    assert fixture["model_id"] == "propagator.j2_drag"
    assert fixture["fixture_type"] == "curated_internal_convergence"

    observations = j2_drag_convergence_fixture_observations()
    assert observations["convergence_classification"] == "pass_internal_only"

    assert observations["coarse_fine_position_delta_km"] <=
             observations["declared_position_tolerance_km"]

    assert observations["coarse_fine_velocity_delta_km_s"] <=
             observations["declared_velocity_tolerance_km_s"]

    assert {:ok, report} = Validation.verify_reference_fixture(fixture_id, observations)
    assert report["status"] == "pass"
    assert Enum.all?(report["checks"], &(&1["status"] == "pass"))

    assert "internal numerical step-convergence regression, not external truth or acceptance evidence" in fixture[
             "known_limits"
           ]
  end

  test "verifies curated two-body reference fixture observations" do
    assert {:ok, fixture} = Validation.reference_fixture("fixture.two_body.circular_leo_600s")

    assert fixture["model_id"] == "propagator.two_body"
    assert fixture["fixture_type"] == "curated_internal_regression"

    assert {:ok, report} =
             Validation.verify_reference_fixture(
               "fixture.two_body.circular_leo_600s",
               two_body_fixture_observations()
             )

    assert report["schema_contract"] == "validation_reference_report.v1"
    assert report["status"] == "pass"
    assert Enum.all?(report["checks"], &(&1["status"] == "pass"))
  end

  test "verifies curated J2 reference fixture observations" do
    assert {:ok, fixture} = Validation.reference_fixture("fixture.j2.circular_leo_600s")

    assert fixture["model_id"] == "propagator.j2"
    assert fixture["fixture_type"] == "curated_internal_regression"

    assert {:ok, report} =
             Validation.verify_reference_fixture(
               "fixture.j2.circular_leo_600s",
               j2_fixture_observations()
             )

    assert report["schema_contract"] == "validation_reference_report.v1"
    assert report["status"] == "pass"
    assert Enum.all?(report["checks"], &(&1["status"] == "pass"))
  end

  test "verifies curated access-window reference fixture observations" do
    assert {:ok, fixture} =
             Validation.reference_fixture("fixture.event.access.equator_overhead_120s")

    assert fixture["model_id"] == "event.access_windows"
    assert fixture["fixture_type"] == "curated_internal_regression"

    assert {:ok, report} =
             Validation.verify_reference_fixture(
               "fixture.event.access.equator_overhead_120s",
               access_fixture_observations()
             )

    assert report["schema_contract"] == "validation_reference_report.v1"
    assert report["status"] == "pass"
    assert Enum.all?(report["checks"], &(&1["status"] == "pass"))
  end

  test "verifies curated eclipse reference fixture observations" do
    assert {:ok, fixture} =
             Validation.reference_fixture("fixture.event.eclipse.cylindrical_shadow_120s")

    assert fixture["model_id"] == "event.eclipses"
    assert fixture["fixture_type"] == "curated_internal_regression"

    assert {:ok, report} =
             Validation.verify_reference_fixture(
               "fixture.event.eclipse.cylindrical_shadow_120s",
               eclipse_fixture_observations()
             )

    assert report["schema_contract"] == "validation_reference_report.v1"
    assert report["status"] == "pass"
    assert Enum.all?(report["checks"], &(&1["status"] == "pass"))
  end

  test "verifies curated target-visibility reference fixture observations" do
    assert {:ok, fixture} =
             Validation.reference_fixture("fixture.event.target_visibility.equator_overhead_120s")

    assert fixture["model_id"] == "event.target_visibility"
    assert fixture["fixture_type"] == "curated_internal_regression"

    assert {:ok, report} =
             Validation.verify_reference_fixture(
               "fixture.event.target_visibility.equator_overhead_120s",
               target_visibility_fixture_observations()
             )

    assert report["schema_contract"] == "validation_reference_report.v1"
    assert report["status"] == "pass"
    assert Enum.all?(report["checks"], &(&1["status"] == "pass"))
  end

  test "verifies curated ground-track crossing reference fixture observations" do
    assert {:ok, fixture} =
             Validation.reference_fixture("fixture.event.ground_track.latitude_equator_60s")

    assert fixture["model_id"] == "event.ground_track_crossings"
    assert fixture["fixture_type"] == "curated_internal_regression"

    assert {:ok, report} =
             Validation.verify_reference_fixture(
               "fixture.event.ground_track.latitude_equator_60s",
               ground_track_crossing_fixture_observations()
             )

    assert report["schema_contract"] == "validation_reference_report.v1"
    assert report["status"] == "pass"
    assert Enum.all?(report["checks"], &(&1["status"] == "pass"))
  end
end
