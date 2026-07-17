defmodule OrbitalDynamics.Validation.CandidateRefreshFreshnessBudgetReplayFixtureTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{Schema, Validation}

  import OrbitalDynamics.Validation.CandidateRefreshFreshnessBudgetReplayFixtures,
    only: [
      candidate_refresh_freshness_fixture: 0,
      candidate_refresh_freshness_fixture_observations: 0,
      candidate_refresh_refresh_budget_fixture: 0,
      candidate_refresh_refresh_budget_fixture_observations: 0
    ]

  test "verifies candidate refresh freshness replay fixtures" do
    fixture_id = "fixture.artifact.candidate_refresh.freshness_replay"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.candidate_refresh.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    artifact = candidate_refresh_freshness_fixture()
    observations = candidate_refresh_freshness_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "source_report_family_count" => 1,
             "source_report_row_count" => 2,
             "source_freshness_report_count" => 2,
             "source_freshness_row_count" => 2,
             "source_freshness_path_keys" =>
               "source_freshness_report[0]|source_freshness_report[1]",
             "source_freshness_status_counts" => %{
               "stale" => 1,
               "unknown" => 1
             },
             "source_freshness_stale_reason_count" => 2,
             "source_freshness_stale_reason_keys" =>
               "accepted_snapshot_older_than_policy|horizon_start_before_now",
             "source_freshness_stale_reason_counts" => %{
               "accepted_snapshot_older_than_policy" => 1,
               "horizon_start_before_now" => 1
             },
             "source_freshness_unknown_reason_count" => 1,
             "source_freshness_unknown_reason_keys" => "missing_generated_at",
             "source_freshness_unknown_reason_counts" => %{"missing_generated_at" => 1},
             "source_freshness_trust_boundary_status" => "declared",
             "source_freshness_branch_local_stale_pressure" => true,
             "source_freshness_branch_local_unknown_pressure" => true,
             "source_freshness_branch_local_freshness_pressure" => true
           } = observations

    stale_freshness_pressure_observations =
      observations
      |> Map.put("source_freshness_branch_local_freshness_pressure", false)

    assert {:ok, stale_freshness_pressure_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_freshness_pressure_observations
             )

    assert stale_freshness_pressure_verification["status"] == "fail"

    assert Enum.any?(
             stale_freshness_pressure_verification["checks"],
             &(&1["field"] == "source_freshness_branch_local_freshness_pressure" and
                 &1["status"] == "fail")
           )

    assert {:ok, _validated_artifact} =
             Schema.validate_artifact(artifact, schema_contract: "candidate_refresh.v1")
  end

  test "verifies candidate refresh refresh-budget replay fixtures" do
    fixture_id = "fixture.artifact.candidate_refresh.refresh_budget_replay"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.candidate_refresh.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    artifact = candidate_refresh_refresh_budget_fixture()
    observations = candidate_refresh_refresh_budget_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "source_report_family_count" => 1,
             "source_report_row_count" => 2,
             "source_refresh_budget_report_count" => 2,
             "source_refresh_budget_row_count" => 2,
             "source_refresh_budget_path_keys" =>
               "source_refresh_budget_report[0]|source_refresh_budget_report[1]",
             "source_refresh_budget_input_candidate_count" => 5,
             "source_refresh_budget_kept_candidate_count" => 3,
             "source_refresh_budget_dropped_candidate_count" => 2,
             "source_refresh_budget_invalid_candidate_limit_policy_count" => 1,
             "source_refresh_budget_invalid_candidate_limit_policy_reason_counts" => %{
               "max_candidate_activities_must_be_integer" => 1
             },
             "source_refresh_budget_kept_candidate_id_keys" =>
               "candidate_a|candidate_b|candidate_e",
             "source_refresh_budget_dropped_candidate_id_keys" => "candidate_c|candidate_d",
             "source_refresh_budget_trust_boundary_status" => "declared",
             "source_refresh_budget_branch_local_budget_pressure" => true,
             "source_refresh_budget_branch_local_dropped_candidate_pressure" => true,
             "source_refresh_budget_branch_local_invalid_limit_pressure" => true,
             "source_refresh_budget_branch_local_candidate_limit_applied" => true
           } = observations

    stale_budget_pressure_observations =
      observations
      |> Map.put("source_refresh_budget_branch_local_budget_pressure", false)

    assert {:ok, stale_budget_pressure_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_budget_pressure_observations
             )

    assert stale_budget_pressure_verification["status"] == "fail"

    assert Enum.any?(
             stale_budget_pressure_verification["checks"],
             &(&1["field"] == "source_refresh_budget_branch_local_budget_pressure" and
                 &1["status"] == "fail")
           )

    assert {:ok, _validated_artifact} =
             Schema.validate_artifact(artifact, schema_contract: "candidate_refresh.v1")
  end
end
