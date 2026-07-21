defmodule OrbitalDynamics.Validation.CandidateRefreshPlanningFeedbackReplayFixtureTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{Schema, Validation}

  import OrbitalDynamics.Validation.CandidateRefreshPlanningFeedbackReplayFixtures,
    only: [
      candidate_refresh_constraint_fixture: 0,
      candidate_refresh_constraint_fixture_observations: 0,
      candidate_refresh_objective_gap_fixture: 0,
      candidate_refresh_objective_gap_fixture_observations: 0
    ]

  test "verifies candidate refresh objective gap replay fixtures" do
    fixture_id = "fixture.artifact.candidate_refresh.objective_gap_replay"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.candidate_refresh.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    artifact = candidate_refresh_objective_gap_fixture()
    observations = candidate_refresh_objective_gap_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "source_report_family_count" => 3,
             "source_report_row_count" => 9,
             "source_objective_satisfaction_gap_row_count" => 3,
             "source_objective_satisfaction_status_counts" => %{
               "partial" => 2,
               "unmet" => 1
             },
             "source_objective_satisfaction_objective_type_counts" => %{
               "delivery_latency" => 1,
               "downlink_completion" => 1,
               "target_coverage" => 1
             },
             "source_objective_tradeoff_collection_latency_gap_row_count" => 2,
             "source_score_term_term_key_counts" => %{
               "collection_latency_gap_s" => 1,
               "downlink_shortfall_mb" => 1,
               "target_gap_count" => 1
             },
             "source_score_term_source_activity_id_counts" => %{
               "score_collection_activity" => 1,
               "score_downlink_activity" => 1,
               "score_target_activity" => 1
             },
             "source_objective_gap_branch_local_objective_gap_pressure" => true,
             "source_objective_gap_branch_local_downlink_gap_pressure" => true,
             "source_objective_gap_branch_local_target_gap_pressure" => true,
             "source_objective_gap_branch_local_collection_latency_gap_pressure" => true,
             "source_objective_gap_branch_local_objective_status_pressure" => true,
             "source_objective_gap_branch_local_score_term_pressure" => true,
             "source_objective_gap_branch_local_routing_pressure" => true,
             "source_objective_satisfaction_trust_boundary_status" => "declared",
             "source_objective_tradeoff_trust_boundary_status" => "declared",
             "source_score_term_trust_boundary_status" => "declared",
             "source_score_term_branch_local_score_term_pressure" => true,
             "source_score_term_branch_local_downlink_gap_pressure" => true,
             "source_score_term_branch_local_target_gap_pressure" => true,
             "source_score_term_branch_local_collection_latency_gap_pressure" => true,
             "source_score_term_branch_local_routing_pressure" => true
           } = observations

    stale_score_term_pressure_observations =
      observations
      |> Map.put("source_score_term_branch_local_score_term_pressure", false)

    assert {:ok, stale_score_term_pressure_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_score_term_pressure_observations
             )

    assert stale_score_term_pressure_verification["status"] == "fail"

    assert Enum.any?(
             stale_score_term_pressure_verification["checks"],
             &(&1["field"] == "source_score_term_branch_local_score_term_pressure" and
                 &1["status"] == "fail")
           )

    stale_objective_gap_pressure_observations =
      observations
      |> Map.put("source_objective_gap_branch_local_objective_gap_pressure", false)

    assert {:ok, stale_objective_gap_pressure_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_objective_gap_pressure_observations
             )

    assert stale_objective_gap_pressure_verification["status"] == "fail"

    assert Enum.any?(
             stale_objective_gap_pressure_verification["checks"],
             &(&1["field"] == "source_objective_gap_branch_local_objective_gap_pressure" and
                 &1["status"] == "fail")
           )

    assert {:ok, _validated_artifact} =
             Schema.validate_artifact(artifact, schema_contract: "candidate_refresh.v1")
  end

  test "verifies candidate refresh constraint replay fixtures" do
    fixture_id = "fixture.artifact.candidate_refresh.constraint_replay"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.candidate_refresh.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    artifact = candidate_refresh_constraint_fixture()
    observations = candidate_refresh_constraint_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "source_report_family_count" => 1,
             "source_report_row_count" => 3,
             "source_constraint_report_count" => 1,
             "source_constraint_row_count" => 3,
             "source_constraint_downlink_gap_row_count" => 1,
             "source_constraint_resource_margin_row_count" => 2,
             "source_constraint_status_counts" => %{"fail" => 1, "warning" => 2},
             "source_constraint_ground_station_counts" => %{"equator_prime" => 1},
             "source_constraint_metric_counts" => %{
               "battery_margin" => 1,
               "selected_downlink_shortfall_mb" => 1,
               "storage_margin" => 1
             },
             "source_constraint_id_counts" => %{
               "battery_margin" => 1,
               "downlink_shortfall" => 1,
               "storage_margin" => 1
             },
             "source_constraint_source_activity_id_counts" => %{
               "constraint_battery_activity" => 1,
               "constraint_downlink_activity" => 1,
               "constraint_storage_activity" => 1
             },
             "source_constraint_resource_counts" => %{"battery_1" => 1, "storage_1" => 1},
             "source_constraint_spacecraft_counts" => %{"sat_1" => 2},
             "source_constraint_trust_boundary_status" => "declared",
             "source_constraint_branch_local_constraint_pressure" => true,
             "source_constraint_branch_local_downlink_gap_pressure" => true,
             "source_constraint_branch_local_resource_margin_pressure" => true,
             "source_constraint_branch_local_constraint_routing_pressure" => true
           } = observations

    stale_constraint_pressure_observations =
      observations
      |> Map.put("source_constraint_branch_local_constraint_pressure", false)

    assert {:ok, stale_constraint_pressure_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_constraint_pressure_observations
             )

    assert stale_constraint_pressure_verification["status"] == "fail"

    assert Enum.any?(
             stale_constraint_pressure_verification["checks"],
             &(&1["field"] == "source_constraint_branch_local_constraint_pressure" and
                 &1["status"] == "fail")
           )

    assert {:ok, _validated_artifact} =
             Schema.validate_artifact(artifact, schema_contract: "candidate_refresh.v1")
  end
end
