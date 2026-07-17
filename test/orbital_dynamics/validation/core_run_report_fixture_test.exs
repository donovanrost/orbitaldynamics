defmodule OrbitalDynamics.Validation.CoreRunReportFixtureTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{Schema, Validation}

  import OrbitalDynamics.Validation.CoreRunReportFixtures,
    only: [
      candidate_diff_report_fixture: 0,
      candidate_diff_report_fixture_observations: 0,
      execution_report_fixture: 0,
      execution_report_fixture_observations: 0,
      freshness_report_fixture: 0,
      freshness_report_fixture_observations: 0,
      refresh_budget_report_fixture: 0,
      refresh_budget_report_fixture_observations: 0,
      validation_reference_report_fixture: 0,
      validation_reference_report_fixture_observations: 0
    ]

  test "verifies curated validation reference report fixtures" do
    fixture_id = "fixture.artifact.validation_reference_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.validation_reference_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = validation_reference_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               validation_reference_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert verification["status_counts"] == %{"pass" => 10}
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      validation_reference_report_fixture_observations()
      |> Map.put("check_count", 2)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"
    assert stale_verification["status_counts"] == %{"fail" => 1, "pass" => 9}

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "check_count" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "validation_reference_report.v1",
             report
           ) == Validation.artifact_observations("validation_reference_report.v1", report)

    assert {:ok, _schema_report} =
             Schema.validate_artifact(report,
               schema_contract: "validation_reference_report.v1"
             )

    assert report["status_counts"] == %{"pass" => 3}

    stale_check_status =
      report
      |> put_in(["checks", Access.at(0), "status"], "fail")
      |> Map.put("status", "pass")

    assert {:error, stale_check_status_report} =
             Schema.validate_artifact(stale_check_status,
               schema_contract: "validation_reference_report.v1"
             )

    assert Enum.any?(
             stale_check_status_report["errors"],
             &(&1["path"] == "$.status")
           )

    stale_status_counts = put_in(report, ["status_counts", "pass"], 2)

    assert {:error, stale_status_counts_report} =
             Schema.validate_artifact(stale_status_counts,
               schema_contract: "validation_reference_report.v1"
             )

    assert Enum.any?(
             stale_status_counts_report["errors"],
             &(&1["path"] == "$.status_counts" and
                 &1["message"] == "must equal nested check status counts")
           )
  end

  test "verifies curated candidate diff report reference fixtures" do
    fixture_id = "fixture.artifact.candidate_diff_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.candidate_diff_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = candidate_diff_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               candidate_diff_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      candidate_diff_report_fixture_observations()
      |> Map.put("invalidated_candidate_count", 0)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "invalidated_candidate_count" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "candidate_diff_report.v1")

    stale_new_candidate_count = Map.put(report, "new_candidate_count", 0)

    assert {:error, stale_new_candidate_count_report} =
             Schema.validate_artifact(stale_new_candidate_count,
               schema_contract: "candidate_diff_report.v1"
             )

    assert Enum.any?(
             stale_new_candidate_count_report["errors"],
             &(&1["path"] == "$.new_candidate_count")
           )

    stale_changed_field_alias =
      put_in(report, ["invalidated_candidates", Access.at(0), "candidate_diff_changed_fields"], [
        "starts_at_s"
      ])

    assert {:error, stale_changed_field_alias_report} =
             Schema.validate_artifact(stale_changed_field_alias,
               schema_contract: "candidate_diff_report.v1"
             )

    assert Enum.any?(
             stale_changed_field_alias_report["errors"],
             &(&1["path"] ==
                 "$.invalidated_candidates[0].candidate_diff_changed_fields")
           )

    stale_semantic_reasons =
      put_in(report, ["invalidated_candidates", Access.at(0), "semantic_change_reasons"], [
        "starts_at_s_changed"
      ])

    assert {:error, stale_semantic_reasons_report} =
             Schema.validate_artifact(stale_semantic_reasons,
               schema_contract: "candidate_diff_report.v1"
             )

    assert Enum.any?(
             stale_semantic_reasons_report["errors"],
             &(&1["path"] == "$.invalidated_candidates[0].semantic_change_reasons")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "candidate_diff_report.v1",
             report
           ) == Validation.artifact_observations("candidate_diff_report.v1", report)
  end

  test "verifies curated refresh budget report reference fixtures" do
    fixture_id = "fixture.artifact.refresh_budget_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.refresh_budget_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = refresh_budget_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               refresh_budget_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      refresh_budget_report_fixture_observations()
      |> Map.put("dropped_candidate_count", 0)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "dropped_candidate_count" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "refresh_budget_report.v1",
             report
           ) == Validation.artifact_observations("refresh_budget_report.v1", report)

    assert {:ok, %{"schema_contract" => "refresh_budget_report.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "refresh_budget_report.v1"
             )

    stale_model = Map.put(report, "model", "stale_refresh_budget_model")

    assert {:error, stale_model_report} =
             Schema.validate_artifact(stale_model,
               schema_contract: "refresh_budget_report.v1"
             )

    assert Enum.any?(
             stale_model_report["errors"],
             &(&1["path"] == "$.model" and
                 &1["message"] ==
                   "must equal \"deterministic_candidate_limit_after_filters\"")
           )

    stale_kept_candidate_count = Map.put(report, "kept_candidate_count", 2)

    assert {:error, stale_kept_candidate_count_report} =
             Schema.validate_artifact(stale_kept_candidate_count,
               schema_contract: "refresh_budget_report.v1"
             )

    assert Enum.any?(
             stale_kept_candidate_count_report["errors"],
             &(&1["path"] == "$.kept_candidate_count")
           )

    stale_input_candidate_count = Map.put(report, "input_candidate_count", 3)

    assert {:error, stale_input_candidate_count_report} =
             Schema.validate_artifact(stale_input_candidate_count,
               schema_contract: "refresh_budget_report.v1"
             )

    assert Enum.any?(
             stale_input_candidate_count_report["errors"],
             &(&1["path"] == "$.input_candidate_count")
           )

    stale_duplicate_kept_candidate_ids =
      Map.put(report, "kept_candidate_ids", [
        "leo_1_observe_target_a_1",
        "leo_1_observe_target_a_1"
      ])
      |> Map.put("kept_candidate_count", 2)
      |> Map.put("input_candidate_count", 3)

    assert {:error, stale_duplicate_kept_candidate_ids_report} =
             Schema.validate_artifact(stale_duplicate_kept_candidate_ids,
               schema_contract: "refresh_budget_report.v1"
             )

    assert Enum.any?(
             stale_duplicate_kept_candidate_ids_report["errors"],
             &(&1["path"] == "$.kept_candidate_ids")
           )

    stale_overlapping_candidate_ids =
      Map.put(report, "dropped_candidate_ids", ["leo_1_observe_target_a_1"])

    assert {:error, stale_overlapping_candidate_ids_report} =
             Schema.validate_artifact(stale_overlapping_candidate_ids,
               schema_contract: "refresh_budget_report.v1"
             )

    assert Enum.any?(
             stale_overlapping_candidate_ids_report["errors"],
             &(&1["path"] == "$.dropped_candidate_ids")
           )
  end

  test "verifies curated execution report reference fixtures" do
    fixture_id = "fixture.artifact.execution_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.execution_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = execution_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               execution_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      execution_report_fixture_observations()
      |> Map.put("failed_scenario_count", 0)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "failed_scenario_count" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "execution_report.v1",
             report
           ) == Validation.artifact_observations("execution_report.v1", report)

    assert {:ok, %{"schema_contract" => "execution_report.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "execution_report.v1"
             )

    stale_scenario_count = Map.put(report, "scenario_count", 1999)

    assert {:error, stale_scenario_count_report} =
             Schema.validate_artifact(stale_scenario_count,
               schema_contract: "execution_report.v1"
             )

    assert Enum.any?(
             stale_scenario_count_report["errors"],
             &(&1["path"] == "$.scenario_count")
           )

    stale_failed_scenario_count = Map.put(report, "failed_scenario_count", 0)

    assert {:error, stale_failed_scenario_count_report} =
             Schema.validate_artifact(stale_failed_scenario_count,
               schema_contract: "execution_report.v1"
             )

    assert Enum.any?(
             stale_failed_scenario_count_report["errors"],
             &(&1["path"] == "$.failed_scenario_count")
           )

    stale_status = Map.put(report, "status", "completed")

    assert {:error, stale_status_report} =
             Schema.validate_artifact(stale_status,
               schema_contract: "execution_report.v1"
             )

    assert Enum.any?(
             stale_status_report["errors"],
             &(&1["path"] == "$.status")
           )

    stale_execution_plan_count = put_in(report, ["execution_plan", "scenario_count"], 1999)

    assert {:error, stale_execution_plan_count_report} =
             Schema.validate_artifact(stale_execution_plan_count,
               schema_contract: "execution_report.v1"
             )

    assert Enum.any?(
             stale_execution_plan_count_report["errors"],
             &(&1["path"] == "$.execution_plan.scenario_count")
           )

    stale_node_distribution = put_in(report, ["node_distribution", "mission_ops@node_b"], 999)

    assert {:error, stale_node_distribution_report} =
             Schema.validate_artifact(stale_node_distribution,
               schema_contract: "execution_report.v1"
             )

    assert Enum.any?(
             stale_node_distribution_report["errors"],
             &(&1["path"] == "$.node_distribution")
           )
  end

  test "verifies curated freshness report reference fixtures" do
    fixture_id = "fixture.artifact.freshness_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.freshness_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = freshness_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               freshness_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      freshness_report_fixture_observations()
      |> Map.put("status", "stale")

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "status" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "freshness_report.v1",
             report
           ) == Validation.artifact_observations("freshness_report.v1", report)

    assert {:ok, %{"schema_contract" => "freshness_report.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "freshness_report.v1"
             )

    stale_status = Map.put(report, "status", "stale")

    assert {:error, stale_status_report} =
             Schema.validate_artifact(stale_status,
               schema_contract: "freshness_report.v1"
             )

    assert Enum.any?(
             stale_status_report["errors"],
             &(&1["path"] == "$.status")
           )

    stale_horizon_offset = Map.put(report, "horizon_start_offset_s", 2)

    assert {:error, stale_horizon_offset_report} =
             Schema.validate_artifact(stale_horizon_offset,
               schema_contract: "freshness_report.v1"
             )

    assert Enum.any?(
             stale_horizon_offset_report["errors"],
             &(&1["path"] == "$.stale_reasons")
           )

    stale_unknown_reasons = Map.put(report, "unknown_reasons", ["horizon_alignment_unknown"])

    assert {:error, stale_unknown_reasons_report} =
             Schema.validate_artifact(stale_unknown_reasons,
               schema_contract: "freshness_report.v1"
             )

    assert Enum.any?(
             stale_unknown_reasons_report["errors"],
             &(&1["path"] == "$.unknown_reasons")
           )

    stale_state_quality_status = Map.put(report, "state_quality_status", "not_accepted")

    assert {:error, stale_state_quality_status_report} =
             Schema.validate_artifact(stale_state_quality_status,
               schema_contract: "freshness_report.v1"
             )

    assert Enum.any?(
             stale_state_quality_status_report["errors"],
             &(&1["path"] == "$.state_quality_status" and
                 &1["message"] == "must equal accepted")
           )

    stale_model = Map.put(report, "model", "stale_freshness_model")

    assert {:error, stale_model_report} =
             Schema.validate_artifact(stale_model,
               schema_contract: "freshness_report.v1"
             )

    assert Enum.any?(
             stale_model_report["errors"],
             &(&1["path"] == "$.model" and
                 &1["message"] ==
                   "must equal \"accepted_snapshot_horizon_and_quality_freshness\"")
           )

    stale_state_quality_policy_input =
      Map.put(report, "accepted_state_quality_level", "telemetry_unreviewed")

    assert {:error, stale_state_quality_policy_input_report} =
             Schema.validate_artifact(stale_state_quality_policy_input,
               schema_contract: "freshness_report.v1"
             )

    assert Enum.any?(
             stale_state_quality_policy_input_report["errors"],
             &(&1["path"] == "$.stale_reasons" and
                 &1["message"] == "must equal freshness-policy-derived stale_reasons")
           )

    assert Enum.any?(
             stale_state_quality_policy_input_report["errors"],
             &(&1["path"] == "$.status" and &1["message"] == "must equal stale")
           )

    stale_model_limits =
      Map.put(report, "model_limits", Enum.drop(Map.fetch!(report, "model_limits"), 1))

    assert {:error, stale_model_limits_report} =
             Schema.validate_artifact(stale_model_limits,
               schema_contract: "freshness_report.v1"
             )

    assert Enum.any?(
             stale_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits")
           )
  end
end
