defmodule OrbitalDynamics.Validation.ObjectiveScoringFixtureTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.Validation.ObjectiveScoringFixtures,
    only: [
      objective_satisfaction_report_fixture_observations: 0,
      objective_satisfaction_report_fixture: 0,
      objective_tradeoff_report_fixture_observations: 0,
      objective_tradeoff_report_fixture: 0,
      score_term_report_fixture_observations: 0,
      score_term_report_fixture: 0,
      campaign_plan_score_term_report_fixture: 0,
      ranking_comparison_report_fixture_observations: 0,
      ranking_comparison_report_fixture: 0
    ]

  alias OrbitalDynamics.{Schema, Validation}

  test "verifies curated objective satisfaction report reference fixtures" do
    fixture_id = "fixture.artifact.objective_satisfaction_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.objective_satisfaction_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = objective_satisfaction_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               objective_satisfaction_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    observations = objective_satisfaction_report_fixture_observations()

    assert observations["status_counts"] == %{
             "no_candidate_window" => 1,
             "partial" => 1,
             "selected" => 1,
             "unmet" => 1
           }

    assert observations["objective_ids_by_status"] == %{
             "no_candidate_window" => ["objective:target_commitment:target_b"],
             "partial" => ["objective:target_coverage"],
             "selected" => ["objective:target_commitment:target_a"],
             "unmet" => ["objective:downlink_completion"]
           }

    stale_observations =
      observations
      |> Map.put("satisfied_count_total", 1)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "satisfied_count_total" and &1["status"] == "fail")
           )

    stale_status_count_observations =
      observations
      |> put_in(["status_counts", "partial"], 0)

    assert {:ok, stale_status_count_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_status_count_observations)

    assert stale_status_count_verification["status"] == "fail"

    assert Enum.any?(
             stale_status_count_verification["checks"],
             &(&1["field"] == "status_counts" and &1["status"] == "fail")
           )

    stale_status_routing_observations =
      observations
      |> put_in(["objective_ids_by_status", "partial"], [])

    assert {:ok, stale_status_routing_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_status_routing_observations)

    assert stale_status_routing_verification["status"] == "fail"

    assert Enum.any?(
             stale_status_routing_verification["checks"],
             &(&1["field"] == "objective_ids_by_status" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "objective_satisfaction_report.v1",
             report
           ) == Validation.artifact_observations("objective_satisfaction_report.v1", report)

    assert {:ok, %{"schema_contract" => "objective_satisfaction_report.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "objective_satisfaction_report.v1"
             )

    stale_model = Map.put(report, "model", "stale_objective_satisfaction_model")

    assert {:error, stale_model_report} =
             Schema.validate_artifact(stale_model,
               schema_contract: "objective_satisfaction_report.v1"
             )

    assert Enum.any?(
             stale_model_report["errors"],
             &(&1["path"] == "$.model" and
                 &1["message"] ==
                   "must equal \"campaign_v1_selected_activity_objective_summary\"")
           )

    stale_objective_count = Map.put(report, "objective_count", 3)

    assert {:error, stale_objective_count_report} =
             Schema.validate_artifact(stale_objective_count,
               schema_contract: "objective_satisfaction_report.v1"
             )

    assert Enum.any?(
             stale_objective_count_report["errors"],
             &(&1["path"] == "$.objective_count")
           )

    stale_candidate_count = put_in(report, ["rows", Access.at(0), "candidate_count"], 2)

    assert {:error, stale_candidate_count_report} =
             Schema.validate_artifact(stale_candidate_count,
               schema_contract: "objective_satisfaction_report.v1"
             )

    assert Enum.any?(
             stale_candidate_count_report["errors"],
             &(&1["path"] == "$.rows[0].candidate_count")
           )

    stale_selected_count = put_in(report, ["rows", Access.at(0), "selected_count"], 2)

    assert {:error, stale_selected_count_report} =
             Schema.validate_artifact(stale_selected_count,
               schema_contract: "objective_satisfaction_report.v1"
             )

    assert Enum.any?(
             stale_selected_count_report["errors"],
             &(&1["path"] == "$.rows[0].selected_count")
           )
  end

  test "verifies curated objective tradeoff report reference fixtures" do
    fixture_id = "fixture.artifact.objective_tradeoff_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.objective_tradeoff_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = objective_tradeoff_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               objective_tradeoff_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      objective_tradeoff_report_fixture_observations()
      |> Map.put("score_term_key_count", 6)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "score_term_key_count" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "objective_tradeoff_report.v1",
             report
           ) == Validation.artifact_observations("objective_tradeoff_report.v1", report)

    assert {:ok, %{"schema_contract" => "objective_tradeoff_report.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "objective_tradeoff_report.v1"
             )

    stale_model = Map.put(report, "model", "stale_objective_tradeoff_model")

    assert {:error, stale_model_report} =
             Schema.validate_artifact(stale_model,
               schema_contract: "objective_tradeoff_report.v1"
             )

    assert Enum.any?(
             stale_model_report["errors"],
             &(&1["path"] == "$.model" and String.starts_with?(&1["message"], "must be one of"))
           )

    stale_ranking_count = Map.put(report, "ranking_count", 0)

    assert {:error, stale_ranking_count_report} =
             Schema.validate_artifact(stale_ranking_count,
               schema_contract: "objective_tradeoff_report.v1"
             )

    assert Enum.any?(
             stale_ranking_count_report["errors"],
             &(&1["path"] == "$.ranking_count")
           )

    stale_score_term_keys = Map.put(report, "score_term_keys", ["activity_score"])

    assert {:error, stale_score_term_keys_report} =
             Schema.validate_artifact(stale_score_term_keys,
               schema_contract: "objective_tradeoff_report.v1"
             )

    assert Enum.any?(
             stale_score_term_keys_report["errors"],
             &(&1["path"] == "$.score_term_keys")
           )

    stale_activity_count = put_in(report, ["tradeoffs", Access.at(0), "activity_count"], 0)

    assert {:error, stale_activity_count_report} =
             Schema.validate_artifact(stale_activity_count,
               schema_contract: "objective_tradeoff_report.v1"
             )

    assert Enum.any?(
             stale_activity_count_report["errors"],
             &(&1["path"] == "$.tradeoffs[0].activity_count")
           )
  end

  test "verifies curated score term report reference fixtures" do
    fixture_id = "fixture.artifact.score_term_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.score_term_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = score_term_report_fixture()

    assert campaign_plan_score_term_report_fixture() == report

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               score_term_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    observations = score_term_report_fixture_observations()

    assert observations["row_derived_score_term_key_counts"] ==
             observations["score_term_key_counts"]

    stale_observations =
      observations
      |> Map.put("selected_row_count", 6)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "selected_row_count" and &1["status"] == "fail")
           )

    stale_row_derived_key_observations =
      observations
      |> put_in(["row_derived_score_term_key_counts", "activity_score"], 2)

    assert {:ok, stale_row_derived_key_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_row_derived_key_observations)

    assert stale_row_derived_key_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_key_verification["checks"],
             &(&1["field"] == "row_derived_score_term_key_counts" and
                 &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "score_term_report.v1",
             report
           ) == Validation.artifact_observations("score_term_report.v1", report)

    assert {:ok, %{"schema_contract" => "score_term_report.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "score_term_report.v1"
             )

    stale_row_count = Map.put(report, "row_count", 6)

    assert {:error, stale_row_count_report} =
             Schema.validate_artifact(stale_row_count,
               schema_contract: "score_term_report.v1"
             )

    assert Enum.any?(stale_row_count_report["errors"], &(&1["path"] == "$.row_count"))

    stale_score_term_keys =
      Map.put(report, "score_term_keys", ["activity_count_penalty"])

    assert {:error, stale_score_term_keys_report} =
             Schema.validate_artifact(stale_score_term_keys,
               schema_contract: "score_term_report.v1"
             )

    assert Enum.any?(
             stale_score_term_keys_report["errors"],
             &(&1["path"] == "$.score_term_keys")
           )
  end

  test "verifies curated ranking comparison report reference fixtures" do
    fixture_id = "fixture.artifact.ranking_comparison_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.ranking_comparison_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = ranking_comparison_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               ranking_comparison_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    observations = ranking_comparison_report_fixture_observations()

    assert observations["status_counts"] == %{
             "left_only" => 1,
             "matched" => 1,
             "right_only" => 1
           }

    assert observations["scenario_ids_by_status"] == %{
             "left_only" => ["burn_a"],
             "matched" => ["burn_b"],
             "right_only" => ["burn_c"]
           }

    stale_observations =
      observations
      |> Map.put("matched_count", 0)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "matched_count" and &1["status"] == "fail")
           )

    stale_status_count_observations =
      observations
      |> put_in(["status_counts", "matched"], 0)

    assert {:ok, stale_status_count_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_status_count_observations)

    assert stale_status_count_verification["status"] == "fail"

    assert Enum.any?(
             stale_status_count_verification["checks"],
             &(&1["field"] == "status_counts" and &1["status"] == "fail")
           )

    stale_status_routing_observations =
      observations
      |> put_in(["scenario_ids_by_status", "matched"], [])

    assert {:ok, stale_status_routing_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_status_routing_observations)

    assert stale_status_routing_verification["status"] == "fail"

    assert Enum.any?(
             stale_status_routing_verification["checks"],
             &(&1["field"] == "scenario_ids_by_status" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "ranking_comparison_report.v1",
             report
           ) == Validation.artifact_observations("ranking_comparison_report.v1", report)

    assert {:ok, %{"schema_contract" => "ranking_comparison_report.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "ranking_comparison_report.v1"
             )

    stale_model = Map.put(report, "model", "stale_ranking_comparison_model")

    assert {:error, stale_model_report} =
             Schema.validate_artifact(stale_model,
               schema_contract: "ranking_comparison_report.v1"
             )

    assert Enum.any?(
             stale_model_report["errors"],
             &(&1["path"] == "$.model" and
                 &1["message"] == "must equal \"scenario_ranking_pairwise_delta\"")
           )

    stale_count_fields = [
      {"row_count", 2},
      {"matched_count", 0},
      {"left_only_count", 0},
      {"right_only_count", 0},
      {"left_count", 1},
      {"right_count", 1}
    ]

    Enum.each(stale_count_fields, fn {field, stale_value} ->
      stale_report = Map.put(report, field, stale_value)

      assert {:error, stale_validation_report} =
               Schema.validate_artifact(stale_report,
                 schema_contract: "ranking_comparison_report.v1"
               )

      assert Enum.any?(stale_validation_report["errors"], &(&1["path"] == "$.#{field}"))
    end)

    stale_rank_delta = put_in(report, ["rows", Access.at(0), "rank_delta"], 0)

    assert {:error, stale_rank_delta_report} =
             Schema.validate_artifact(stale_rank_delta,
               schema_contract: "ranking_comparison_report.v1"
             )

    assert Enum.any?(
             stale_rank_delta_report["errors"],
             &(&1["path"] == "$.rows[0].rank_delta")
           )

    stale_value_delta = put_in(report, ["rows", Access.at(0), "value_delta"], 0)

    assert {:error, stale_value_delta_report} =
             Schema.validate_artifact(stale_value_delta,
               schema_contract: "ranking_comparison_report.v1"
             )

    assert Enum.any?(
             stale_value_delta_report["errors"],
             &(&1["path"] == "$.rows[0].value_delta")
           )
  end
end
