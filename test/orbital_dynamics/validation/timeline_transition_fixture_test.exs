defmodule OrbitalDynamics.Validation.TimelineTransitionFixtureTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.Validation.TimelineTransitionFixtures,
    only: [
      timeline_transition_application_summary_fixture_observations: 0,
      timeline_transition_application_summary_fixture: 0,
      timeline_transition_application_selected_integrity_summary_fixture_observations: 0,
      timeline_transition_application_selected_integrity_summary_fixture: 0,
      timeline_transition_application_report_fixture_observations: 0,
      timeline_transition_application_report_fixture: 0,
      timeline_transition_application_selected_integrity_fixture_observations: 0,
      timeline_transition_application_selected_integrity_fixture: 0
    ]

  alias OrbitalDynamics.{Schema, Validation}

  test "verifies curated timeline transition application summary reference fixtures" do
    fixture_id = "fixture.artifact.timeline_transition_application_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.timeline_transition_application_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = timeline_transition_application_summary_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               timeline_transition_application_summary_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      timeline_transition_application_summary_fixture_observations()
      |> Map.put("review_required_count", 1)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "review_required_count" and &1["status"] == "fail")
           )

    stale_row_derived_observations =
      timeline_transition_application_summary_fixture_observations()
      |> put_in(["row_derived_required_operator_action_counts", "review_added_activity"], 0)

    assert {:ok, stale_row_derived_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_row_derived_observations)

    assert stale_row_derived_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_verification["checks"],
             &(&1["field"] == "row_derived_required_operator_action_counts" and
                 &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report,
               schema_contract: "timeline_transition_application_summary.v1"
             )

    assert OrbitalDynamics.validation_artifact_observations(
             "timeline_transition_application_summary.v1",
             report
           ) ==
             Validation.artifact_observations(
               "timeline_transition_application_summary.v1",
               report
             )
  end

  test "verifies curated timeline transition application selected integrity summary reference fixtures" do
    fixture_id = "fixture.artifact.timeline_transition_application_selected_integrity_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.timeline_transition_application_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    summary = timeline_transition_application_selected_integrity_summary_fixture()

    observations =
      timeline_transition_application_selected_integrity_summary_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "selected_timeline_integrity_issue_count" => 1,
             "selected_timeline_integrity_review_count" => 1,
             "selected_timeline_integrity_issue_type_counts" => %{
               "missing_dependency_activity" => 1
             },
             "row_derived_selected_timeline_integrity_issue_type_counts" => %{
               "missing_dependency_activity" => 1
             },
             "row_derived_selected_required_operator_action_counts" => %{
               "review_changed_protected_activity" => 1
             },
             "row_derived_selected_review_timeline_ids_by_required_operator_action" => %{
               "review_changed_protected_activity" => ["timeline:cmd_lock"]
             },
             "row_derived_selected_missing_dependency_activity_keys" => "cmd_prereq"
           } = observations

    stale_selected_issue_count_observations =
      observations
      |> Map.put("selected_timeline_integrity_issue_count", 0)

    assert {:ok, stale_selected_issue_count_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_selected_issue_count_observations
             )

    assert stale_selected_issue_count_verification["status"] == "fail"

    assert Enum.any?(
             stale_selected_issue_count_verification["checks"],
             &(&1["field"] == "selected_timeline_integrity_issue_count" and
                 &1["status"] == "fail")
           )

    stale_selected_routing_observations =
      observations
      |> put_in(
        [
          "row_derived_selected_review_timeline_ids_by_required_operator_action",
          "review_changed_protected_activity"
        ],
        []
      )

    assert {:ok, stale_selected_routing_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_selected_routing_observations)

    assert stale_selected_routing_verification["status"] == "fail"

    assert Enum.any?(
             stale_selected_routing_verification["checks"],
             &(&1["field"] ==
                 "row_derived_selected_review_timeline_ids_by_required_operator_action" and
                 &1["status"] == "fail")
           )

    stale_selected_dependency_observations =
      observations
      |> Map.put("row_derived_selected_missing_dependency_activity_keys", "")

    assert {:ok, stale_selected_dependency_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_selected_dependency_observations
             )

    assert stale_selected_dependency_verification["status"] == "fail"

    assert Enum.any?(
             stale_selected_dependency_verification["checks"],
             &(&1["field"] == "row_derived_selected_missing_dependency_activity_keys" and
                 &1["status"] == "fail")
           )

    assert {:ok, _valid_summary} =
             Schema.validate_artifact(summary,
               schema_contract: "timeline_transition_application_summary.v1"
             )

    assert OrbitalDynamics.validation_artifact_observations(
             "timeline_transition_application_summary.v1",
             summary
           ) ==
             Validation.artifact_observations(
               "timeline_transition_application_summary.v1",
               summary
             )
  end

  test "verifies curated timeline transition application report reference fixtures" do
    fixture_id = "fixture.artifact.timeline_transition_application_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.timeline_transition_application_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = timeline_transition_application_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               timeline_transition_application_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      timeline_transition_application_report_fixture_observations()
      |> Map.put("application_count", 3)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "application_count" and &1["status"] == "fail")
           )

    stale_row_derived_observations =
      timeline_transition_application_report_fixture_observations()
      |> put_in(["row_derived_application_status_counts", "operator_review_required"], 1)

    assert {:ok, stale_row_derived_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_row_derived_observations)

    assert stale_row_derived_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_verification["checks"],
             &(&1["field"] == "row_derived_application_status_counts" and
                 &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report,
               schema_contract: "timeline_transition_application_report.v1"
             )

    stale_application_count = Map.put(report, "application_count", 0)

    assert {:error, stale_application_count_report} =
             Schema.validate_artifact(stale_application_count,
               schema_contract: "timeline_transition_application_report.v1"
             )

    assert Enum.any?(
             stale_application_count_report["errors"],
             &(&1["path"] == "$.application_count")
           )

    stale_transition_decision_counts =
      Map.put(report, "transition_decision_counts", %{"none" => 4})

    assert {:error, stale_transition_decision_counts_report} =
             Schema.validate_artifact(stale_transition_decision_counts,
               schema_contract: "timeline_transition_application_report.v1"
             )

    assert Enum.any?(
             stale_transition_decision_counts_report["errors"],
             &(&1["path"] == "$.transition_decision_counts")
           )

    stale_model_limits = Map.put(report, "model_limits", ["artifact_level_only"])

    assert {:error, stale_model_limits_report} =
             Schema.validate_artifact(stale_model_limits,
               schema_contract: "timeline_transition_application_report.v1"
             )

    assert Enum.any?(
             stale_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "timeline_transition_application_report.v1",
             report
           ) ==
             Validation.artifact_observations("timeline_transition_application_report.v1", report)
  end

  test "verifies curated timeline transition application selected integrity reference fixtures" do
    fixture_id = "fixture.artifact.timeline_transition_application_selected_integrity.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.timeline_transition_application_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = timeline_transition_application_selected_integrity_fixture()
    observations = timeline_transition_application_selected_integrity_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "selected_timeline_integrity_issue_count" => 1,
             "selected_timeline_integrity_review_count" => 1,
             "selected_timeline_integrity_issue_type_counts" => %{
               "missing_dependency_activity" => 1
             },
             "row_derived_selected_timeline_integrity_issue_type_counts" => %{
               "missing_dependency_activity" => 1
             },
             "row_derived_selected_required_operator_action_counts" => %{
               "review_changed_protected_activity" => 1
             },
             "row_derived_selected_application_ids_by_required_operator_action" => %{
               "review_changed_protected_activity" => ["timeline_diff:timeline:cmd_lock"]
             },
             "row_derived_selected_missing_dependency_activity_keys" => "cmd_prereq"
           } = observations

    stale_selected_issue_count_observations =
      observations
      |> Map.put("selected_timeline_integrity_issue_count", 0)

    assert {:ok, stale_selected_issue_count_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_selected_issue_count_observations
             )

    assert stale_selected_issue_count_verification["status"] == "fail"

    assert Enum.any?(
             stale_selected_issue_count_verification["checks"],
             &(&1["field"] == "selected_timeline_integrity_issue_count" and
                 &1["status"] == "fail")
           )

    stale_selected_issue_type_observations =
      observations
      |> put_in(
        [
          "row_derived_selected_timeline_integrity_issue_type_counts",
          "missing_dependency_activity"
        ],
        0
      )

    assert {:ok, stale_selected_issue_type_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_selected_issue_type_observations
             )

    assert stale_selected_issue_type_verification["status"] == "fail"

    assert Enum.any?(
             stale_selected_issue_type_verification["checks"],
             &(&1["field"] == "row_derived_selected_timeline_integrity_issue_type_counts" and
                 &1["status"] == "fail")
           )

    stale_selected_dependency_observations =
      observations
      |> Map.put("row_derived_selected_missing_dependency_activity_keys", "")

    assert {:ok, stale_selected_dependency_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_selected_dependency_observations
             )

    assert stale_selected_dependency_verification["status"] == "fail"

    assert Enum.any?(
             stale_selected_dependency_verification["checks"],
             &(&1["field"] == "row_derived_selected_missing_dependency_activity_keys" and
                 &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report,
               schema_contract: "timeline_transition_application_report.v1"
             )

    assert OrbitalDynamics.validation_artifact_observations(
             "timeline_transition_application_report.v1",
             report
           ) ==
             Validation.artifact_observations("timeline_transition_application_report.v1", report)
  end
end
