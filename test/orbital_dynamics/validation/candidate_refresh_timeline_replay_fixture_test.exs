defmodule OrbitalDynamics.Validation.CandidateRefreshTimelineReplayFixtureTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{Schema, Validation}

  import OrbitalDynamics.Validation.CandidateRefreshTimelineReplayFixtures,
    only: [
      candidate_refresh_timeline_activity_lifecycle_fixture: 0,
      candidate_refresh_timeline_activity_lifecycle_fixture_observations: 0,
      candidate_refresh_timeline_activity_precondition_fixture: 0,
      candidate_refresh_timeline_activity_precondition_fixture_observations: 0,
      candidate_refresh_timeline_lifecycle_state_fixture: 0,
      candidate_refresh_timeline_lifecycle_state_fixture_observations: 0,
      candidate_refresh_timeline_transition_application_fixture: 0,
      candidate_refresh_timeline_transition_application_fixture_observations: 0
    ]

  test "verifies candidate refresh timeline activity precondition replay fixtures" do
    fixture_id = "fixture.artifact.candidate_refresh.timeline_activity_precondition_replay"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.candidate_refresh.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    artifact = candidate_refresh_timeline_activity_precondition_fixture()
    observations = candidate_refresh_timeline_activity_precondition_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "source_report_family_count" => 1,
             "source_report_row_count" => 3,
             "source_timeline_activity_precondition_report_count" => 2,
             "source_timeline_activity_precondition_row_count" => 3,
             "source_timeline_activity_precondition_status_counts" => %{
               "blocked" => 1,
               "review_required" => 1
             },
             "source_timeline_activity_precondition_blocked_precondition_count" => 2,
             "source_timeline_activity_precondition_review_precondition_count" => 1,
             "source_timeline_activity_precondition_blocked_precondition_type_counts" => %{
               "payload_unavailable" => 1,
               "resource_block_declared" => 1
             },
             "source_timeline_activity_precondition_review_precondition_type_counts" => %{
               "degraded_mode" => 1
             },
             "source_timeline_activity_precondition_invalid_activity_input_count" => 1,
             "source_timeline_activity_precondition_invalid_activity_input_reason_counts" => %{
               "missing_activity_type" => 1
             },
             "source_timeline_activity_precondition_dependency_activity_id_counts" => %{
               "health_check_1" => 1,
               "obs_1" => 1
             },
             "source_timeline_activity_precondition_dependency_timeline_id_counts" => %{
               "timeline:health_check_1" => 1
             },
             "source_timeline_activity_precondition_exclusive_with_activity_id_counts" => %{
               "dl_conflict" => 1
             },
             "source_timeline_activity_precondition_exclusive_with_timeline_id_counts" => %{
               "timeline:dl_conflict" => 1
             },
             "source_timeline_activity_precondition_duplicate_dependency_activity_id_counts" => %{
               "obs_1" => 1
             },
             "source_timeline_activity_precondition_duplicate_dependency_timeline_id_counts" => %{
               "timeline:health_check_1" => 1
             },
             "source_timeline_activity_precondition_duplicate_exclusivity_activity_id_counts" =>
               %{
                 "dl_conflict" => 1
               },
             "source_timeline_activity_precondition_duplicate_exclusivity_timeline_id_counts" =>
               %{
                 "timeline:dl_conflict" => 1
               },
             "source_timeline_activity_precondition_allow_overlap_counts" => %{"true" => 1},
             "source_timeline_activity_precondition_trust_boundary_status" => "declared"
           } = observations

    stale_dependency_observations =
      observations
      |> Map.put("source_timeline_activity_precondition_dependency_activity_id_counts", %{
        "stale_dependency" => 1
      })

    assert {:ok, stale_dependency_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_dependency_observations)

    assert stale_dependency_verification["status"] == "fail"

    assert Enum.any?(
             stale_dependency_verification["checks"],
             &(&1["field"] ==
                 "source_timeline_activity_precondition_dependency_activity_id_counts" and
                 &1["status"] == "fail")
           )

    stale_duplicate_observations =
      observations
      |> Map.put(
        "source_timeline_activity_precondition_duplicate_dependency_activity_id_counts",
        %{"stale_duplicate_dependency" => 1}
      )

    assert {:ok, stale_duplicate_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_duplicate_observations)

    assert stale_duplicate_verification["status"] == "fail"

    assert Enum.any?(
             stale_duplicate_verification["checks"],
             &(&1["field"] ==
                 "source_timeline_activity_precondition_duplicate_dependency_activity_id_counts" and
                 &1["status"] == "fail")
           )

    assert {:ok, _validated_artifact} =
             Schema.validate_artifact(artifact, schema_contract: "candidate_refresh.v1")
  end

  test "verifies candidate refresh timeline lifecycle state replay fixtures" do
    fixture_id = "fixture.artifact.candidate_refresh.timeline_lifecycle_state_replay"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.candidate_refresh.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    artifact = candidate_refresh_timeline_lifecycle_state_fixture()
    observations = candidate_refresh_timeline_lifecycle_state_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "source_report_family_count" => 1,
             "source_report_row_count" => 4,
             "source_timeline_lifecycle_state_report_count" => 1,
             "source_timeline_lifecycle_state_row_count" => 4,
             "source_timeline_lifecycle_state_planned_activity_count" => 5,
             "source_timeline_lifecycle_state_realized_activity_count" => 3,
             "source_timeline_lifecycle_state_recordable_count" => 1,
             "source_timeline_lifecycle_state_preserved_count" => 1,
             "source_timeline_lifecycle_state_review_required_count" => 2,
             "source_timeline_lifecycle_state_duplicate_timeline_identity_count" => 1,
             "source_timeline_lifecycle_state_invalid_activity_input_count" => 0,
             "source_timeline_lifecycle_state_transition_decision_counts" => %{
               "none" => 1,
               "record" => 1,
               "review" => 2
             },
             "source_timeline_lifecycle_state_required_operator_action_counts" => %{
               "none" => 1,
               "record_timeline_change" => 1,
               "review_activity_approval" => 1,
               "review_duplicate_timeline_identity" => 1
             },
             "source_timeline_lifecycle_state_import_action_counts" => %{
               "import_replacement_activity" => 1,
               "record_preserved_activity" => 1,
               "review_timeline_diff" => 2
             },
             "source_timeline_lifecycle_state_preserved_timeline_keys" => "timeline:done_keep",
             "source_timeline_lifecycle_state_review_timeline_keys" =>
               "timeline:cmd_provider|timeline:dup",
             "source_timeline_lifecycle_state_review_activity_keys" => "cmd_provider|dup_a|dup_b",
             "source_timeline_lifecycle_state_review_timeline_ids_by_required_operator_action" =>
               %{
                 "review_activity_approval" => ["timeline:cmd_provider"],
                 "review_duplicate_timeline_identity" => ["timeline:dup"]
               },
             "source_timeline_lifecycle_state_trust_boundary_status" => "declared"
           } = observations

    stale_review_observations =
      observations
      |> put_in(
        [
          "source_timeline_lifecycle_state_review_timeline_ids_by_required_operator_action",
          "review_activity_approval"
        ],
        ["timeline:stale_review"]
      )

    assert {:ok, stale_review_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_review_observations)

    assert stale_review_verification["status"] == "fail"

    assert Enum.any?(
             stale_review_verification["checks"],
             &(&1["field"] ==
                 "source_timeline_lifecycle_state_review_timeline_ids_by_required_operator_action" and
                 &1["status"] == "fail")
           )

    assert {:ok, _validated_artifact} =
             Schema.validate_artifact(artifact, schema_contract: "candidate_refresh.v1")
  end

  test "verifies candidate refresh timeline activity lifecycle replay fixtures" do
    fixture_id = "fixture.artifact.candidate_refresh.timeline_activity_lifecycle_replay"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.candidate_refresh.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    artifact = candidate_refresh_timeline_activity_lifecycle_fixture()
    observations = candidate_refresh_timeline_activity_lifecycle_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "source_report_family_count" => 1,
             "source_report_row_count" => 1,
             "source_timeline_activity_lifecycle_report_count" => 1,
             "source_timeline_activity_lifecycle_row_count" => 1,
             "source_timeline_activity_lifecycle_review_required_count" => 1,
             "source_timeline_activity_lifecycle_invalid_activity_input_count" => 0,
             "source_timeline_activity_lifecycle_transition_decision_counts" => %{
               "review" => 1
             },
             "source_timeline_activity_lifecycle_status_transition_decision_counts" => %{
               "record" => 1
             },
             "source_timeline_activity_lifecycle_approval_transition_decision_counts" => %{
               "review" => 1
             },
             "source_timeline_activity_lifecycle_required_operator_action_counts" => %{
               "record_timeline_change" => 1,
               "review_activity_approval" => 1
             },
             "source_timeline_activity_lifecycle_import_action_counts" => %{
               "review_timeline_diff" => 1
             },
             "source_timeline_activity_lifecycle_planned_status_category_counts" => %{
               "planned" => 1
             },
             "source_timeline_activity_lifecycle_realized_status_category_counts" => %{
               "executed" => 1
             },
             "source_timeline_activity_lifecycle_planned_approval_category_counts" => %{
               "review_required" => 1
             },
             "source_timeline_activity_lifecycle_realized_approval_category_counts" => %{
               "protected" => 1
             },
             "source_timeline_activity_lifecycle_status_transition_category_counts" => %{
               "execution_recorded" => 1
             },
             "source_timeline_activity_lifecycle_approval_transition_category_counts" => %{
               "approval_granted" => 1
             },
             "source_timeline_activity_lifecycle_protection_decision_counts" => %{
               "mutable" => 1,
               "preserve" => 1
             },
             "source_timeline_activity_lifecycle_protection_category_counts" => %{
               "executed" => 1,
               "none" => 1
             },
             "source_timeline_activity_lifecycle_trust_boundary_status" => "declared"
           } = observations

    stale_action_observations =
      observations
      |> put_in(
        [
          "source_timeline_activity_lifecycle_required_operator_action_counts",
          "review_activity_approval"
        ],
        0
      )

    assert {:ok, stale_action_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_action_observations)

    assert stale_action_verification["status"] == "fail"

    assert Enum.any?(
             stale_action_verification["checks"],
             &(&1["field"] ==
                 "source_timeline_activity_lifecycle_required_operator_action_counts" and
                 &1["status"] == "fail")
           )

    assert {:ok, _validated_artifact} =
             Schema.validate_artifact(artifact, schema_contract: "candidate_refresh.v1")
  end

  test "verifies candidate refresh timeline transition application replay fixtures" do
    fixture_id = "fixture.artifact.candidate_refresh.timeline_transition_application_replay"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.candidate_refresh.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    artifact = candidate_refresh_timeline_transition_application_fixture()
    observations = candidate_refresh_timeline_transition_application_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "source_report_family_count" => 1,
             "source_report_row_count" => 1,
             "source_timeline_transition_application_report_count" => 1,
             "source_timeline_transition_application_row_count" => 1,
             "source_timeline_transition_application_application_count" => 1,
             "source_timeline_transition_application_selected_activity_count" => 1,
             "source_timeline_transition_application_selected_integrity_review_count" => 1,
             "source_timeline_transition_application_selected_integrity_issue_count" => 1,
             "source_timeline_transition_application_selected_integrity_issue_type_counts" => %{
               "missing_dependency_activity" => 1
             },
             "source_timeline_transition_application_review_required_count" => 1,
             "source_timeline_transition_application_status_counts" => %{
               "selected_timeline_integrity_review_required" => 1
             },
             "source_timeline_transition_application_required_operator_action_counts" => %{
               "review_timeline_integrity" => 1
             },
             "source_timeline_transition_application_trust_boundary_status" => "declared"
           } = observations

    stale_issue_type_observations =
      observations
      |> Map.put("source_timeline_transition_application_selected_integrity_issue_type_counts", %{
        "stale_issue" => 1
      })

    assert {:ok, stale_issue_type_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_issue_type_observations)

    assert stale_issue_type_verification["status"] == "fail"

    assert Enum.any?(
             stale_issue_type_verification["checks"],
             &(&1["field"] ==
                 "source_timeline_transition_application_selected_integrity_issue_type_counts" and
                 &1["status"] == "fail")
           )

    assert {:ok, _validated_artifact} =
             Schema.validate_artifact(artifact, schema_contract: "candidate_refresh.v1")
  end
end
