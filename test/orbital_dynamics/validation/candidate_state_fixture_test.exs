defmodule OrbitalDynamics.Validation.CandidateStateFixtureTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{Schema, Validation}

  import OrbitalDynamics.Validation.CandidateStateFixtures,
    only: [
      accepted_planning_state_fixture: 0,
      accepted_planning_state_fixture_observations: 0,
      accepted_planning_state_oem_fixture: 0,
      accepted_planning_state_oem_fixture_observations: 0,
      accepted_planning_state_opm_fixture: 0,
      accepted_planning_state_opm_fixture_observations: 0,
      candidate_diff_row_fixture: 0,
      candidate_diff_row_fixture_observations: 0,
      candidate_rejection_report_fixture: 0,
      candidate_rejection_report_fixture_observations: 0
    ]

  test "verifies curated candidate rejection report reference fixtures" do
    fixture_id = "fixture.artifact.candidate_rejection_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.candidate_rejection_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = candidate_rejection_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               candidate_rejection_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      candidate_rejection_report_fixture_observations()
      |> Map.put("required_operator_review_count", 2)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "required_operator_review_count" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "candidate_rejection_report.v1",
             report
           ) == Validation.artifact_observations("candidate_rejection_report.v1", report)

    assert {:ok, %{"schema_contract" => "candidate_rejection_report.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "candidate_rejection_report.v1"
             )

    stale_rejected_count = Map.put(report, "rejected_count", 2)

    assert {:error, stale_rejected_count_report} =
             Schema.validate_artifact(stale_rejected_count,
               schema_contract: "candidate_rejection_report.v1"
             )

    assert Enum.any?(
             stale_rejected_count_report["errors"],
             &(&1["path"] == "$.rejected_count")
           )

    stale_rejection_reason_counts =
      put_in(report, ["rejection_reason_counts", "station_reserved"], 0)

    assert {:error, stale_rejection_reason_counts_report} =
             Schema.validate_artifact(stale_rejection_reason_counts,
               schema_contract: "candidate_rejection_report.v1"
             )

    assert Enum.any?(
             stale_rejection_reason_counts_report["errors"],
             &(&1["path"] == "$.rejection_reason_counts")
           )

    stale_candidate_id_sets =
      put_in(report, ["candidate_id_sets_by_rejection_reason", "station_reserved"], [])

    assert {:error, stale_candidate_id_sets_report} =
             Schema.validate_artifact(stale_candidate_id_sets,
               schema_contract: "candidate_rejection_report.v1"
             )

    assert Enum.any?(
             stale_candidate_id_sets_report["errors"],
             &(&1["path"] == "$.candidate_id_sets_by_rejection_reason")
           )

    stale_required_operator_action_counts =
      put_in(report, ["required_operator_action_counts", "review_candidate_rejection"], 2)

    assert {:error, stale_required_operator_action_counts_report} =
             Schema.validate_artifact(stale_required_operator_action_counts,
               schema_contract: "candidate_rejection_report.v1"
             )

    assert Enum.any?(
             stale_required_operator_action_counts_report["errors"],
             &(&1["path"] == "$.required_operator_action_counts")
           )

    stale_reviewable_candidate_ids = Map.put(report, "reviewable_candidate_ids", ["obs_clouded"])

    assert {:error, stale_reviewable_candidate_ids_report} =
             Schema.validate_artifact(stale_reviewable_candidate_ids,
               schema_contract: "candidate_rejection_report.v1"
             )

    assert Enum.any?(
             stale_reviewable_candidate_ids_report["errors"],
             &(&1["path"] == "$.reviewable_candidate_ids")
           )
  end

  test "verifies curated candidate diff row reference fixtures" do
    fixture_id = "fixture.artifact.candidate_diff_row.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.candidate_diff_row.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = candidate_diff_row_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               candidate_diff_row_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      candidate_diff_row_fixture_observations()
      |> Map.put("candidate_diff_changed_field_count", 2)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "candidate_diff_changed_field_count" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "candidate_diff_row.v1")

    stale_changed_field_count = Map.put(report, "candidate_diff_changed_field_count", 2)

    assert {:error, stale_changed_field_count_report} =
             Schema.validate_artifact(stale_changed_field_count,
               schema_contract: "candidate_diff_row.v1"
             )

    assert Enum.any?(
             stale_changed_field_count_report["errors"],
             &(&1["path"] == "$.candidate_diff_changed_field_count")
           )

    stale_changed_field_alias =
      Map.put(report, "candidate_diff_changed_fields", ["starts_at_s"])

    assert {:error, stale_changed_field_alias_report} =
             Schema.validate_artifact(stale_changed_field_alias,
               schema_contract: "candidate_diff_row.v1"
             )

    assert Enum.any?(
             stale_changed_field_alias_report["errors"],
             &(&1["path"] == "$.candidate_diff_changed_fields")
           )

    stale_semantic_reasons = Map.put(report, "semantic_change_reasons", ["starts_at_s_changed"])

    assert {:error, stale_semantic_reasons_report} =
             Schema.validate_artifact(stale_semantic_reasons,
               schema_contract: "candidate_diff_row.v1"
             )

    assert Enum.any?(
             stale_semantic_reasons_report["errors"],
             &(&1["path"] == "$.semantic_change_reasons")
           )

    assert OrbitalDynamics.validation_artifact_observations("candidate_diff_row.v1", report) ==
             Validation.artifact_observations("candidate_diff_row.v1", report)
  end

  test "verifies curated accepted planning state reference fixtures" do
    fixture_id = "fixture.artifact.accepted_planning_state.simple"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.accepted_planning_state.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = accepted_planning_state_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               accepted_planning_state_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      accepted_planning_state_fixture_observations()
      |> Map.put("provenance_network_access", true)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "provenance_network_access" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "accepted_planning_state.v1")

    stale_state_estimate_count =
      put_in(report, ["provenance", "state_estimate_count"], 0)

    assert {:error, stale_state_estimate_count_report} =
             Schema.validate_artifact(stale_state_estimate_count,
               schema_contract: "accepted_planning_state.v1"
             )

    assert Enum.any?(
             stale_state_estimate_count_report["errors"],
             &(&1["path"] == "$.provenance.state_estimate_count")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "accepted_planning_state.v1",
             report
           ) == Validation.artifact_observations("accepted_planning_state.v1", report)
  end

  test "verifies curated CCSDS OPM accepted planning state reference fixtures" do
    fixture_id = "fixture.artifact.accepted_planning_state.opm"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.accepted_planning_state.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = accepted_planning_state_opm_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               accepted_planning_state_opm_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      accepted_planning_state_opm_fixture_observations()
      |> Map.put("provenance_input_format", "simple_json_state_estimate_batch")

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "provenance_input_format" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "accepted_planning_state.v1",
             report
           ) == Validation.artifact_observations("accepted_planning_state.v1", report)
  end

  test "verifies curated CCSDS OEM accepted planning state reference fixtures" do
    fixture_id = "fixture.artifact.accepted_planning_state.oem"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.accepted_planning_state.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = accepted_planning_state_oem_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               accepted_planning_state_oem_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      accepted_planning_state_oem_fixture_observations()
      |> Map.put("provenance_input_format", "ccsds_opm_kvn")

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "provenance_input_format" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "accepted_planning_state.v1",
             report
           ) == Validation.artifact_observations("accepted_planning_state.v1", report)
  end
end
