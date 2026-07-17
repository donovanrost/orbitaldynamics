defmodule OrbitalDynamics.Validation.CandidateRefreshReadinessReplayFixtureTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{Schema, Validation}

  import OrbitalDynamics.Validation.CandidateRefreshReadinessReplayFixtures,
    only: [
      candidate_refresh_operational_readiness_fixture: 0,
      candidate_refresh_operational_readiness_fixture_observations: 0,
      candidate_refresh_quality_gate_fixture: 0,
      candidate_refresh_quality_gate_fixture_observations: 0,
      candidate_refresh_resource_projection_fixture: 0,
      candidate_refresh_resource_projection_fixture_observations: 0
    ]

  test "verifies candidate refresh resource projection replay fixtures" do
    fixture_id = "fixture.artifact.candidate_refresh.resource_projection_replay"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.candidate_refresh.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    artifact = candidate_refresh_resource_projection_fixture()
    observations = candidate_refresh_resource_projection_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "source_report_family_count" => 1,
             "source_report_row_count" => 4,
             "source_resource_projection_report_count" => 1,
             "source_resource_projection_row_count" => 4,
             "source_resource_projection_projected_resource_count" => 2,
             "source_resource_projection_invalid_activity_input_count" => 1,
             "source_resource_projection_invalid_resource_summary_input_count" => 1,
             "source_resource_projection_resource_pressure_status_counts" => %{
               "downlink_shortfall" => 1,
               "storage_shortfall" => 1
             },
             "source_resource_projection_resource_pressure_type_counts" => %{
               "downlink_shortfall" => 1,
               "storage_pressure" => 1,
               "storage_shortfall" => 1
             },
             "source_resource_projection_resource_pressure_direction_counts" => %{
               "downlink" => 1,
               "tracking" => 1
             },
             "source_resource_projection_resource_pressure_activity_ids_by_status" => %{
               "downlink_shortfall" => ["dl_pressure_1"],
               "storage_shortfall" => ["imaging_1", "imaging_2"]
             },
             "source_resource_projection_resource_pressure_activity_ids_by_type" => %{
               "downlink_shortfall" => ["dl_pressure_1"],
               "storage_pressure" => ["dl_pressure_1"],
               "storage_shortfall" => ["imaging_1", "imaging_2"]
             },
             "source_resource_projection_resource_pressure_activity_ids_by_direction" => %{
               "downlink" => ["dl_pressure_1"],
               "tracking" => ["imaging_1", "imaging_2"]
             },
             "source_resource_projection_trust_boundary_status" => "declared"
           } = observations

    stale_status_observations =
      observations
      |> Map.put("source_resource_projection_resource_pressure_status_counts", %{
        "stale_status" => 2
      })

    assert {:ok, stale_status_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_status_observations)

    assert stale_status_verification["status"] == "fail"

    assert Enum.any?(
             stale_status_verification["checks"],
             &(&1["field"] == "source_resource_projection_resource_pressure_status_counts" and
                 &1["status"] == "fail")
           )

    assert {:ok, _validated_artifact} =
             Schema.validate_artifact(artifact, schema_contract: "candidate_refresh.v1")
  end

  test "verifies candidate refresh quality gate replay fixtures" do
    fixture_id = "fixture.artifact.candidate_refresh.quality_gate_replay"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.candidate_refresh.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    artifact = candidate_refresh_quality_gate_fixture()
    observations = candidate_refresh_quality_gate_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "source_report_family_count" => 1,
             "source_report_row_count" => 6,
             "source_quality_gate_report_count" => 1,
             "source_quality_gate_row_count" => 6,
             "source_quality_gate_gate_count" => 6,
             "source_quality_gate_passed_gate_count" => 3,
             "source_quality_gate_review_gate_count" => 3,
             "source_quality_gate_analysis_gate_count" => 0,
             "source_quality_gate_blocked_gate_count" => 0,
             "source_quality_gate_readiness_level_counts" => %{"operator_review" => 1},
             "source_quality_gate_import_classification_counts" => %{"review_only" => 1},
             "source_quality_gate_status_counts" => %{"review_required" => 1},
             "source_quality_gate_gate_status_counts" => %{
               "passed" => 3,
               "review_required" => 3
             },
             "source_quality_gate_gate_classification_counts" => %{
               "importable" => 3,
               "review_only" => 3
             },
             "source_quality_gate_ready_for_import_count" => 0,
             "source_quality_gate_trust_boundary_status" => "declared",
             "source_quality_gate_resource_availability_pressure_count" => 2,
             "source_quality_gate_resource_availability_reason_counts" => %{
               "antenna_unavailable" => 1,
               "payload_unavailable" => 1
             },
             "source_quality_gate_resource_availability_reason_ids" =>
               "antenna_unavailable|payload_unavailable",
             "source_quality_gate_branch_local_review_pressure" => true,
             "source_quality_gate_branch_local_import_pressure" => false,
             "source_quality_gate_branch_local_resource_pressure" => true
           } = observations

    stale_resource_pressure_observations =
      observations
      |> Map.put("source_quality_gate_branch_local_resource_pressure", false)

    assert {:ok, stale_resource_pressure_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_resource_pressure_observations)

    assert stale_resource_pressure_verification["status"] == "fail"

    assert Enum.any?(
             stale_resource_pressure_verification["checks"],
             &(&1["field"] == "source_quality_gate_branch_local_resource_pressure" and
                 &1["status"] == "fail")
           )

    assert {:ok, _validated_artifact} =
             Schema.validate_artifact(artifact, schema_contract: "candidate_refresh.v1")
  end

  test "verifies candidate refresh operational readiness replay fixtures" do
    fixture_id = "fixture.artifact.candidate_refresh.operational_readiness_replay"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.candidate_refresh.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    artifact = candidate_refresh_operational_readiness_fixture()
    observations = candidate_refresh_operational_readiness_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "source_report_family_count" => 1,
             "source_report_row_count" => 1,
             "source_operational_readiness_report_count" => 1,
             "source_operational_readiness_row_count" => 1,
             "source_operational_readiness_gate_count" => 6,
             "source_operational_readiness_passed_gate_count" => 3,
             "source_operational_readiness_review_gate_count" => 3,
             "source_operational_readiness_analysis_gate_count" => 0,
             "source_operational_readiness_blocked_gate_count" => 0,
             "source_operational_readiness_readiness_level_counts" => %{
               "operator_review" => 1
             },
             "source_operational_readiness_import_classification_counts" => %{
               "review_only" => 1
             },
             "source_operational_readiness_status_counts" => %{"review_required" => 1},
             "source_operational_readiness_trust_boundary_status" => "declared",
             "source_operational_readiness_resource_availability_pressure_count" => 2,
             "source_operational_readiness_resource_availability_reason_counts" => %{
               "antenna_unavailable" => 1,
               "payload_unavailable" => 1
             },
             "source_operational_readiness_resource_availability_reason_ids" =>
               "antenna_unavailable|payload_unavailable",
             "source_operational_readiness_branch_local_review_pressure" => true,
             "source_operational_readiness_branch_local_import_pressure" => true,
             "source_operational_readiness_branch_local_resource_pressure" => true
           } = observations

    stale_status_observations =
      observations
      |> Map.put("source_operational_readiness_status_counts", %{"stale_status" => 1})

    assert {:ok, stale_status_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_status_observations)

    assert stale_status_verification["status"] == "fail"

    assert Enum.any?(
             stale_status_verification["checks"],
             &(&1["field"] == "source_operational_readiness_status_counts" and
                 &1["status"] == "fail")
           )

    stale_resource_pressure_observations =
      observations
      |> Map.put("source_operational_readiness_branch_local_resource_pressure", false)

    assert {:ok, stale_resource_pressure_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_resource_pressure_observations)

    assert stale_resource_pressure_verification["status"] == "fail"

    assert Enum.any?(
             stale_resource_pressure_verification["checks"],
             &(&1["field"] == "source_operational_readiness_branch_local_resource_pressure" and
                 &1["status"] == "fail")
           )

    assert {:ok, _validated_artifact} =
             Schema.validate_artifact(artifact, schema_contract: "candidate_refresh.v1")
  end
end
