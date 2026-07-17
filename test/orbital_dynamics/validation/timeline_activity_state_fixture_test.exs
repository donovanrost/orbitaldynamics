defmodule OrbitalDynamics.Validation.TimelineActivityStateFixtureTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.Validation.TimelineActivityStateFixtures,
    only: [
      timeline_activity_precondition_summary_fixture_observations: 0,
      timeline_activity_precondition_summary_fixture: 0,
      generated_timeline_activity_precondition_summary_fixture: 0,
      timeline_activity_state_fixture_observations: 0,
      timeline_activity_state_fixture: 0,
      generated_timeline_activity_state_fixture: 0,
      timeline_activity_approval_state_fixture_observations: 0,
      timeline_activity_approval_state_fixture: 0,
      generated_timeline_activity_approval_state_fixture: 0,
      timeline_activity_status_state_fixture_observations: 0,
      timeline_activity_status_state_fixture: 0,
      generated_timeline_activity_status_state_fixture: 0,
      timeline_activity_lifecycle_state_fixture_observations: 0,
      timeline_activity_lifecycle_state_fixture: 0,
      generated_timeline_activity_lifecycle_state_fixture: 0,
      timeline_lifecycle_state_summary_fixture_observations: 0,
      timeline_lifecycle_state_summary_fixture: 0,
      generated_timeline_lifecycle_state_summary_fixture: 0
    ]

  alias OrbitalDynamics.{Schema, Validation}

  test "verifies curated timeline activity precondition summary reference fixtures" do
    fixture_id = "fixture.artifact.timeline_activity_precondition_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.timeline_activity_precondition_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = timeline_activity_precondition_summary_fixture()

    assert generated_timeline_activity_precondition_summary_fixture() == report

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               timeline_activity_precondition_summary_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      timeline_activity_precondition_summary_fixture_observations()
      |> Map.put("blocked_precondition_count", 1)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "blocked_precondition_count" and &1["status"] == "fail")
           )

    stale_row_derived_observations =
      timeline_activity_precondition_summary_fixture_observations()
      |> put_in(["row_derived_precondition_type_counts", "payload_unavailable"], 0)

    assert {:ok, stale_row_derived_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_row_derived_observations)

    assert stale_row_derived_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_verification["checks"],
             &(&1["field"] == "row_derived_precondition_type_counts" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report,
               schema_contract: "timeline_activity_precondition_summary.v1"
             )

    assert OrbitalDynamics.validation_artifact_observations(
             "timeline_activity_precondition_summary.v1",
             report
           ) ==
             Validation.artifact_observations(
               "timeline_activity_precondition_summary.v1",
               report
             )
  end

  test "verifies curated timeline activity state reference fixtures" do
    fixture_id = "fixture.artifact.timeline_activity_state.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.timeline_activity_state.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = timeline_activity_state_fixture()

    assert generated_timeline_activity_state_fixture() == report

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               timeline_activity_state_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      timeline_activity_state_fixture_observations()
      |> Map.put("row_count", 1)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "row_count" and &1["status"] == "fail")
           )

    stale_row_derived_observations =
      timeline_activity_state_fixture_observations()
      |> put_in(["row_derived_match_strategy_counts", "unmatched_realized"], 0)

    assert {:ok, stale_row_derived_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_row_derived_observations)

    assert stale_row_derived_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_verification["checks"],
             &(&1["field"] == "row_derived_match_strategy_counts" and
                 &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "timeline_activity_state.v1")

    assert OrbitalDynamics.validation_artifact_observations(
             "timeline_activity_state.v1",
             report
           ) == Validation.artifact_observations("timeline_activity_state.v1", report)
  end

  test "verifies curated timeline activity approval state reference fixtures" do
    fixture_id = "fixture.artifact.timeline_activity_approval_state.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.timeline_activity_approval_state.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = timeline_activity_approval_state_fixture()
    observations = timeline_activity_approval_state_fixture_observations()

    assert generated_timeline_activity_approval_state_fixture() == report

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert observations["transition_decision"] == "review"
    assert observations["review_required"] == true
    assert observations["required_operator_action"] == "review_activity_approval"
    assert observations["operator_action_reason"] == "approval_grant_requires_operator_authority"
    assert observations["import_action"] == "review_timeline_diff"
    assert observations["approval_transition_category"] == "approval_granted"
    assert observations["approval_transition_requires_operator_review"] == true
    assert observations["no_operator_authority_grant"] == true
    assert observations["no_command_execution"] == true

    stale_action_observations =
      observations
      |> Map.put("required_operator_action", "none")

    assert {:ok, stale_action_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_action_observations)

    assert stale_action_verification["status"] == "fail"

    assert Enum.any?(
             stale_action_verification["checks"],
             &(&1["field"] == "required_operator_action" and &1["status"] == "fail")
           )

    stale_authority_observations =
      observations
      |> Map.put("no_operator_authority_grant", false)

    assert {:ok, stale_authority_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_authority_observations)

    assert stale_authority_verification["status"] == "fail"

    assert Enum.any?(
             stale_authority_verification["checks"],
             &(&1["field"] == "no_operator_authority_grant" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report,
               schema_contract: "timeline_activity_approval_state.v1"
             )

    assert OrbitalDynamics.validation_artifact_observations(
             "timeline_activity_approval_state.v1",
             report
           ) ==
             Validation.artifact_observations("timeline_activity_approval_state.v1", report)
  end

  test "verifies curated timeline activity status state reference fixtures" do
    fixture_id = "fixture.artifact.timeline_activity_status_state.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.timeline_activity_status_state.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = timeline_activity_status_state_fixture()
    observations = timeline_activity_status_state_fixture_observations()

    assert generated_timeline_activity_status_state_fixture() == report

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert observations["transition_decision"] == "record"
    assert observations["review_required"] == false
    assert observations["required_operator_action"] == "record_timeline_change"
    assert observations["operator_action_reason"] == "activity_execution_recorded"
    assert observations["import_action"] == "import_replacement_activity"
    assert observations["status_transition_category"] == "execution_recorded"
    assert observations["status_transition_requires_operator_review"] == false
    assert observations["no_operator_authority_grant"] == true
    assert observations["no_command_execution"] == true

    stale_transition_observations =
      observations
      |> Map.put("transition_decision", "none")

    assert {:ok, stale_transition_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_transition_observations)

    assert stale_transition_verification["status"] == "fail"

    assert Enum.any?(
             stale_transition_verification["checks"],
             &(&1["field"] == "transition_decision" and &1["status"] == "fail")
           )

    stale_execution_boundary_observations =
      observations
      |> Map.put("no_command_execution", false)

    assert {:ok, stale_execution_boundary_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_execution_boundary_observations
             )

    assert stale_execution_boundary_verification["status"] == "fail"

    assert Enum.any?(
             stale_execution_boundary_verification["checks"],
             &(&1["field"] == "no_command_execution" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report,
               schema_contract: "timeline_activity_status_state.v1"
             )

    assert OrbitalDynamics.validation_artifact_observations(
             "timeline_activity_status_state.v1",
             report
           ) ==
             Validation.artifact_observations("timeline_activity_status_state.v1", report)
  end

  test "verifies curated timeline activity lifecycle state reference fixtures" do
    fixture_id = "fixture.artifact.timeline_activity_lifecycle_state.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.timeline_activity_lifecycle_state.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = timeline_activity_lifecycle_state_fixture()
    observations = timeline_activity_lifecycle_state_fixture_observations()

    assert generated_timeline_activity_lifecycle_state_fixture() == report

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert observations["transition_decision"] == "review"
    assert observations["status_transition_decision"] == "record"
    assert observations["approval_transition_decision"] == "review"
    assert observations["required_operator_action_count"] == 2
    assert observations["operator_action_reason_count"] == 2
    assert observations["no_operator_authority_grant"] == true
    assert observations["no_cadence_import"] == true
    assert observations["no_command_execution"] == true

    stale_action_observations =
      observations
      |> Map.put("required_operator_action_keys", "record_timeline_change")

    assert {:ok, stale_action_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_action_observations)

    assert stale_action_verification["status"] == "fail"

    assert Enum.any?(
             stale_action_verification["checks"],
             &(&1["field"] == "required_operator_action_keys" and &1["status"] == "fail")
           )

    stale_authority_observations =
      observations
      |> Map.put("no_operator_authority_grant", false)

    assert {:ok, stale_authority_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_authority_observations)

    assert stale_authority_verification["status"] == "fail"

    assert Enum.any?(
             stale_authority_verification["checks"],
             &(&1["field"] == "no_operator_authority_grant" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report,
               schema_contract: "timeline_activity_lifecycle_state.v1"
             )

    assert OrbitalDynamics.validation_artifact_observations(
             "timeline_activity_lifecycle_state.v1",
             report
           ) ==
             Validation.artifact_observations("timeline_activity_lifecycle_state.v1", report)
  end

  test "verifies curated timeline lifecycle state summary reference fixtures" do
    fixture_id = "fixture.artifact.timeline_lifecycle_state_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.timeline_lifecycle_state_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = timeline_lifecycle_state_summary_fixture()
    observations = timeline_lifecycle_state_summary_fixture_observations()

    assert generated_timeline_lifecycle_state_summary_fixture() == report

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert observations["row_count"] == 4
    assert observations["row_derived_row_count"] == 4
    assert observations["review_required_count"] == 2
    assert observations["row_derived_review_required_count"] == 2
    assert observations["duplicate_timeline_identity_count"] == 1
    assert observations["row_derived_duplicate_timeline_identity_count"] == 1
    assert observations["review_timeline_keys"] == "timeline:cmd_provider|timeline:dup"

    assert observations["row_derived_review_timeline_keys"] ==
             "timeline:cmd_provider|timeline:dup"

    assert observations["operator_action_reason_counts"] == %{
             "activity_execution_recorded" => 2,
             "approval_grant_requires_operator_authority" => 1,
             "duplicate_timeline_identity" => 1
           }

    assert observations["row_derived_operator_action_reason_counts"] ==
             observations["operator_action_reason_counts"]

    assert observations["review_timeline_ids_by_operator_action_reason"] == %{
             "activity_execution_recorded" => ["timeline:cmd_provider"],
             "approval_grant_requires_operator_authority" => ["timeline:cmd_provider"],
             "duplicate_timeline_identity" => ["timeline:dup"]
           }

    assert observations["row_derived_review_timeline_ids_by_operator_action_reason"] ==
             observations["review_timeline_ids_by_operator_action_reason"]

    assert observations["operator_authority"] == "not_granted_by_summary"
    assert observations["cadence_import"] == "not_performed_by_summary"

    stale_review_count_observations =
      observations
      |> Map.put("row_derived_review_required_count", 1)

    assert {:ok, stale_review_count_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_review_count_observations)

    assert stale_review_count_verification["status"] == "fail"

    assert Enum.any?(
             stale_review_count_verification["checks"],
             &(&1["field"] == "row_derived_review_required_count" and &1["status"] == "fail")
           )

    stale_review_routing_observations =
      observations
      |> Map.put("row_derived_review_timeline_ids_by_required_operator_action", %{})

    assert {:ok, stale_review_routing_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_review_routing_observations)

    assert stale_review_routing_verification["status"] == "fail"

    assert Enum.any?(
             stale_review_routing_verification["checks"],
             &(&1["field"] == "row_derived_review_timeline_ids_by_required_operator_action" and
                 &1["status"] == "fail")
           )

    stale_operator_reason_observations =
      observations
      |> put_in(["row_derived_operator_action_reason_counts", "activity_execution_recorded"], 1)

    assert {:ok, stale_operator_reason_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_operator_reason_observations)

    assert stale_operator_reason_verification["status"] == "fail"

    assert Enum.any?(
             stale_operator_reason_verification["checks"],
             &(&1["field"] == "row_derived_operator_action_reason_counts" and
                 &1["status"] == "fail")
           )

    stale_operator_routing_observations =
      observations
      |> put_in(["row_derived_review_timeline_ids_by_operator_action_reason"], %{})

    assert {:ok, stale_operator_routing_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_operator_routing_observations)

    assert stale_operator_routing_verification["status"] == "fail"

    assert Enum.any?(
             stale_operator_routing_verification["checks"],
             &(&1["field"] == "row_derived_review_timeline_ids_by_operator_action_reason" and
                 &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report,
               schema_contract: "timeline_lifecycle_state_summary.v1"
             )

    assert OrbitalDynamics.validation_artifact_observations(
             "timeline_lifecycle_state_summary.v1",
             report
           ) ==
             Validation.artifact_observations("timeline_lifecycle_state_summary.v1", report)
  end
end
