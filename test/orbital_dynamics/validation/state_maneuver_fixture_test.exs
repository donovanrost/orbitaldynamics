defmodule OrbitalDynamics.Validation.StateManeuverFixtureTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.Validation.StateManeuverFixtures,
    only: [
      spacecraft_state_estimate_fixture_observations: 0,
      spacecraft_state_estimate_fixture: 0,
      realized_state_snapshot_fixture_observations: 0,
      realized_state_snapshot_fixture: 0,
      remaining_horizon_fixture_observations: 0,
      remaining_horizon_fixture: 0,
      maneuver_execution_delta_fixture_observations: 0,
      maneuver_execution_delta_fixture: 0,
      maneuver_recommendation_fixture_observations: 0,
      maneuver_recommendation_fixture: 0
    ]

  alias OrbitalDynamics.{Schema, Validation}

  test "verifies curated spacecraft state estimate reference fixtures" do
    fixture_id = "fixture.artifact.spacecraft_state_estimate.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.spacecraft_state_estimate.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = spacecraft_state_estimate_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               spacecraft_state_estimate_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      spacecraft_state_estimate_fixture_observations()
      |> Map.put("quality_level", "planning_accepted")

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "quality_level" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "spacecraft_state_estimate.v1")

    stale_quality_sigma =
      put_in(report, ["quality", "position_sigma_km"], [0.1, 0.1])

    assert {:error, stale_quality_sigma_report} =
             Schema.validate_artifact(stale_quality_sigma,
               schema_contract: "spacecraft_state_estimate.v1"
             )

    assert Enum.any?(
             stale_quality_sigma_report["errors"],
             &(&1["path"] == "$.quality.position_sigma_km")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "spacecraft_state_estimate.v1",
             report
           ) == Validation.artifact_observations("spacecraft_state_estimate.v1", report)
  end

  test "verifies curated realized state snapshot reference fixtures" do
    fixture_id = "fixture.artifact.realized_state_snapshot.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.realized_state_snapshot.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = realized_state_snapshot_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               realized_state_snapshot_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      realized_state_snapshot_fixture_observations()
      |> Map.put("degraded_count", 0)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "degraded_count" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "realized_state_snapshot.v1")

    stale_degraded_count = Map.put(report, "degraded_count", 0)

    assert {:error, stale_degraded_count_report} =
             Schema.validate_artifact(stale_degraded_count,
               schema_contract: "realized_state_snapshot.v1"
             )

    assert Enum.any?(
             stale_degraded_count_report["errors"],
             &(&1["path"] == "$.degraded_count")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "realized_state_snapshot.v1",
             report
           ) == Validation.artifact_observations("realized_state_snapshot.v1", report)
  end

  test "verifies curated remaining horizon reference fixtures" do
    fixture_id = "fixture.artifact.remaining_horizon.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.remaining_horizon.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = remaining_horizon_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               remaining_horizon_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      remaining_horizon_fixture_observations()
      |> Map.put("duration_s", 540)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "duration_s" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "remaining_horizon.v1")

    stale_duration = Map.put(report, "duration_s", 540)

    assert {:error, stale_duration_report} =
             Schema.validate_artifact(stale_duration, schema_contract: "remaining_horizon.v1")

    assert Enum.any?(
             stale_duration_report["errors"],
             &(&1["path"] == "$.duration_s")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "remaining_horizon.v1",
             report
           ) == Validation.artifact_observations("remaining_horizon.v1", report)
  end

  test "verifies curated maneuver execution delta reference fixtures" do
    fixture_id = "fixture.artifact.maneuver_execution_delta.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.maneuver_execution_delta.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = maneuver_execution_delta_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               maneuver_execution_delta_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      maneuver_execution_delta_fixture_observations()
      |> Map.put("status", "partial")

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "status" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "maneuver_execution_delta.v1")

    stale_delta_v = Map.put(report, "delta_v_km_s", [0.0, 0.01])

    assert {:error, stale_delta_v_report} =
             Schema.validate_artifact(stale_delta_v,
               schema_contract: "maneuver_execution_delta.v1"
             )

    assert Enum.any?(
             stale_delta_v_report["errors"],
             &(&1["path"] == "$.delta_v_km_s")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "maneuver_execution_delta.v1",
             report
           ) == Validation.artifact_observations("maneuver_execution_delta.v1", report)
  end

  test "verifies curated maneuver recommendation reference fixtures" do
    fixture_id = "fixture.artifact.maneuver_recommendation.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.maneuver_recommendation.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = maneuver_recommendation_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               maneuver_recommendation_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      maneuver_recommendation_fixture_observations()
      |> Map.put("recommendation_only_no_command_execution", false)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "recommendation_only_no_command_execution" and
                 &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "maneuver_recommendation.v1")

    stale_delta_v_magnitude = Map.put(report, "delta_v_magnitude_km_s", 0.02)

    assert {:error, stale_delta_v_magnitude_report} =
             Schema.validate_artifact(stale_delta_v_magnitude,
               schema_contract: "maneuver_recommendation.v1"
             )

    assert Enum.any?(
             stale_delta_v_magnitude_report["errors"],
             &(&1["path"] == "$.delta_v_magnitude_km_s")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "maneuver_recommendation.v1",
             report
           ) == Validation.artifact_observations("maneuver_recommendation.v1", report)
  end
end
