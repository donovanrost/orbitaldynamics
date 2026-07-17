defmodule OrbitalDynamics.Validation.CandidateStrategyFixtureTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{Schema, Validation}

  import OrbitalDynamics.Validation.CandidateStrategyFixtures,
    only: [
      branch_comparison_report_fixture: 0,
      branch_comparison_report_fixture_observations: 0,
      invalidated_candidate_fixture: 0,
      invalidated_candidate_fixture_observations: 0,
      optimizer_contract_fixture: 0,
      optimizer_contract_fixture_observations: 0,
      proposed_contact_fixture: 0,
      proposed_contact_fixture_observations: 0,
      strategy_branch_fixture: 0,
      strategy_branch_fixture_observations: 0,
      strategy_recommendation_fixture: 0,
      strategy_recommendation_fixture_observations: 0
    ]

  test "verifies curated proposed contact reference fixtures" do
    fixture_id = "fixture.artifact.proposed_contact.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.proposed_contact.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = proposed_contact_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               proposed_contact_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      proposed_contact_fixture_observations()
      |> Map.put("station_availability", "reserved")

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "station_availability" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "proposed_contact.v1")

    stale_source_window_id =
      Map.put(report, "source_window_id", "window:leo_1:ground_station_access:equator_prime:2")

    assert {:error, stale_source_window_id_report} =
             Schema.validate_artifact(stale_source_window_id,
               schema_contract: "proposed_contact.v1"
             )

    assert Enum.any?(
             stale_source_window_id_report["errors"],
             &(&1["path"] == "$.source_window_id")
           )

    assert OrbitalDynamics.validation_artifact_observations("proposed_contact.v1", report) ==
             Validation.artifact_observations("proposed_contact.v1", report)
  end

  test "verifies curated branch comparison report reference fixtures" do
    fixture_id = "fixture.artifact.branch_comparison_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.branch_comparison_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = branch_comparison_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               branch_comparison_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      branch_comparison_report_fixture_observations()
      |> Map.put("selected_count", 2)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "selected_count" and &1["status"] == "fail")
           )

    stale_row_derived_observations =
      branch_comparison_report_fixture_observations()
      |> Map.put("row_derived_approval_status_counts", %{
        "blocked_by_policy" => 8,
        "operator_review_required" => 5
      })

    assert {:ok, stale_row_derived_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_row_derived_observations)

    assert stale_row_derived_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_verification["checks"],
             &(&1["field"] == "row_derived_approval_status_counts" and
                 &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "branch_comparison_report.v1")

    stale_branch_count = Map.put(report, "branch_count", 0)

    assert {:error, stale_branch_count_report} =
             Schema.validate_artifact(stale_branch_count,
               schema_contract: "branch_comparison_report.v1"
             )

    assert Enum.any?(
             stale_branch_count_report["errors"],
             &(&1["path"] == "$.branch_count")
           )

    stale_score_delta =
      put_in(report, ["rows", Access.at(1), "score_delta_from_recommended"], 0)

    assert {:error, stale_score_delta_report} =
             Schema.validate_artifact(stale_score_delta,
               schema_contract: "branch_comparison_report.v1"
             )

    assert Enum.any?(
             stale_score_delta_report["errors"],
             &(&1["path"] == "$.rows[1].score_delta_from_recommended")
           )

    stale_repair_score_term_count =
      put_in(report, ["rows", Access.at(0), "repair_score_term_count"], 0)

    assert {:error, stale_repair_score_term_count_report} =
             Schema.validate_artifact(stale_repair_score_term_count,
               schema_contract: "branch_comparison_report.v1"
             )

    assert Enum.any?(
             stale_repair_score_term_count_report["errors"],
             &(&1["path"] == "$.rows[0].repair_score_term_count")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "branch_comparison_report.v1",
             report
           ) == Validation.artifact_observations("branch_comparison_report.v1", report)
  end

  test "verifies curated optimizer contract reference fixtures" do
    fixture_id = "fixture.artifact.optimizer_contract.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.optimizer_contract.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = optimizer_contract_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               optimizer_contract_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      optimizer_contract_fixture_observations()
      |> Map.put("external_solver", true)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "external_solver" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations("optimizer_contract.v1", report) ==
             Validation.artifact_observations("optimizer_contract.v1", report)

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "optimizer_contract.v1")

    stale_candidate_count = Map.put(report, "candidate_count", 1)

    assert {:error, stale_candidate_count_report} =
             Schema.validate_artifact(stale_candidate_count,
               schema_contract: "optimizer_contract.v1"
             )

    assert Enum.any?(
             stale_candidate_count_report["errors"],
             &(&1["path"] == "$.candidate_count")
           )
  end

  test "verifies curated invalidated candidate reference fixtures" do
    fixture_id = "fixture.artifact.invalidated_candidate.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.invalidated_candidate.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = invalidated_candidate_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               invalidated_candidate_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      invalidated_candidate_fixture_observations()
      |> Map.put("replacement_candidate_id", "other_candidate")

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "replacement_candidate_id" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "invalidated_candidate.v1")

    stale_source_target_id = Map.put(report, "source_target_id", "target_b")

    assert {:error, stale_source_target_id_report} =
             Schema.validate_artifact(stale_source_target_id,
               schema_contract: "invalidated_candidate.v1"
             )

    assert Enum.any?(
             stale_source_target_id_report["errors"],
             &(&1["path"] == "$.source_target_id")
           )

    assert OrbitalDynamics.validation_artifact_observations("invalidated_candidate.v1", report) ==
             Validation.artifact_observations("invalidated_candidate.v1", report)
  end

  test "verifies curated strategy branch reference fixtures" do
    fixture_id = "fixture.artifact.strategy_branch.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.strategy_branch.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = strategy_branch_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               strategy_branch_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      strategy_branch_fixture_observations()
      |> Map.put("approval_status", "blocked_by_policy")

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "approval_status" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations("strategy_branch.v1", report) ==
             Validation.artifact_observations("strategy_branch.v1", report)

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "strategy_branch.v1")

    stale_score = Map.put(report, "score", report["score"] + 1.0)

    assert {:error, stale_score_report} =
             Schema.validate_artifact(stale_score,
               schema_contract: "strategy_branch.v1"
             )

    assert Enum.any?(stale_score_report["errors"], &(&1["path"] == "$.score"))
  end

  test "verifies curated strategy recommendation reference fixtures" do
    fixture_id = "fixture.artifact.strategy_recommendation.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.strategy_recommendation.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = strategy_recommendation_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               strategy_recommendation_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      strategy_recommendation_fixture_observations()
      |> Map.put("ranked_branch_count", 3)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "ranked_branch_count" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations("strategy_recommendation.v1", report) ==
             Validation.artifact_observations("strategy_recommendation.v1", report)

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "strategy_recommendation.v1")

    stale_ranked_branch_ids =
      Map.put(
        report,
        "ranked_branch_ids",
        tl(report["ranked_branch_ids"]) ++ [report["recommended_branch_id"]]
      )

    assert {:error, stale_rank_report} =
             Schema.validate_artifact(stale_ranked_branch_ids,
               schema_contract: "strategy_recommendation.v1"
             )

    assert Enum.any?(stale_rank_report["errors"], &(&1["path"] == "$.recommended_branch_id"))
  end
end
