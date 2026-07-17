defmodule OrbitalDynamics.Validation.TimelinePreservationFixtureTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.Validation.TimelinePreservationFixtures,
    only: [
      timeline_preservation_report_fixture_observations: 0,
      timeline_preservation_report_fixture: 0,
      timeline_preservation_status_fixture_observations: 0,
      timeline_preservation_status_fixture: 0,
      timeline_integrity_report_fixture_observations: 0,
      timeline_integrity_report_fixture: 0,
      generated_timeline_integrity_report_fixture: 0,
      timeline_dependency_impact_summary_fixture_observations: 0,
      timeline_dependency_impact_summary_fixture: 0,
      timeline_diff_summary_fixture_observations: 0,
      timeline_diff_summary_fixture: 0,
      timeline_publication_summary_fixture_observations: 0,
      timeline_publication_summary_fixture: 0,
      generated_timeline_publication_summary_fixture: 0
    ]

  alias OrbitalDynamics.{Schema, Validation}

  test "verifies curated timeline preservation report reference fixtures" do
    fixture_id = "fixture.artifact.timeline_preservation_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.timeline_preservation_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = timeline_preservation_report_fixture()
    observations = timeline_preservation_report_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert observations["activity_count"] == 4
    assert observations["row_count"] == 3
    assert observations["row_derived_row_count"] == 3
    assert observations["preservation_sensitive_activity_count"] == 3
    assert observations["row_derived_preservation_sensitive_activity_count"] == 3
    assert observations["review_change_activity_count"] == 1
    assert observations["row_derived_review_change_activity_count"] == 1
    assert observations["row_derived_invalid_activity_input_count"] == 1
    assert observations["timeline_preservation_status"] == "review_required"

    assert observations["row_derived_protection_decision_counts"] == %{
             "preserve" => 2,
             "review_change" => 1
           }

    assert observations["activity_id_sets_by_protection_decision"] == %{
             "mutable" => ["cmd_mutable"],
             "preserve" => ["contact_locked", "obs_done"],
             "review_change" => ["bad_missing_type"]
           }

    assert observations["row_derived_activity_id_sets_by_protection_decision"] == %{
             "preserve" => ["contact_locked", "obs_done"],
             "review_change" => ["bad_missing_type"]
           }

    assert observations["preservation_sensitive_activity_keys"] ==
             "bad_missing_type|contact_locked|obs_done"

    assert observations["row_derived_preservation_sensitive_activity_keys"] ==
             "bad_missing_type|contact_locked|obs_done"

    assert observations["execution_boundary"] == "artifact_only_no_schedule_mutation"
    assert observations["scope"] == "lifecycle_lock_approval_and_executed_preservation_review"
    assert observations["model_limit_count"] == 4

    stale_review_observations =
      observations
      |> Map.put("row_derived_review_change_activity_count", 0)

    assert {:ok, stale_review_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_review_observations)

    assert stale_review_verification["status"] == "fail"

    assert Enum.any?(
             stale_review_verification["checks"],
             &(&1["field"] == "row_derived_review_change_activity_count" and
                 &1["status"] == "fail")
           )

    stale_routing_observations =
      observations
      |> Map.put("row_derived_activity_id_sets_by_protection_decision", %{})

    assert {:ok, stale_routing_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_routing_observations)

    assert stale_routing_verification["status"] == "fail"

    assert Enum.any?(
             stale_routing_verification["checks"],
             &(&1["field"] == "row_derived_activity_id_sets_by_protection_decision" and
                 &1["status"] == "fail")
           )

    stale_boundary_observations =
      observations
      |> Map.put("execution_boundary", "schedule_mutation_allowed")

    assert {:ok, stale_boundary_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_boundary_observations)

    assert stale_boundary_verification["status"] == "fail"

    assert Enum.any?(
             stale_boundary_verification["checks"],
             &(&1["field"] == "execution_boundary" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report,
               schema_contract: "timeline_preservation_report.v1"
             )

    assert OrbitalDynamics.validation_artifact_observations(
             "timeline_preservation_report.v1",
             report
           ) ==
             Validation.artifact_observations("timeline_preservation_report.v1", report)
  end

  test "verifies curated timeline preservation status reference fixtures" do
    fixture_id = "fixture.artifact.timeline_preservation_status.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.timeline_preservation_status.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    status = timeline_preservation_status_fixture()
    observations = timeline_preservation_status_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert observations["activity_id"] == "dl_locked"
    assert observations["activity_type"] == "downlink"
    assert observations["timeline_identity_timeline_id"] == "timeline:dl_locked"
    assert observations["protection_decision"] == "preserve"
    assert observations["timeline_preservation_status"] == "preservation_required"
    assert observations["requires_preservation"] == true
    assert observations["requires_operator_review"] == false
    assert observations["execution_boundary"] == "artifact_only_no_schedule_mutation"

    stale_status_observations =
      observations
      |> Map.put("timeline_preservation_status", "mutable")

    assert {:ok, stale_status_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_status_observations)

    assert stale_status_verification["status"] == "fail"

    assert Enum.any?(
             stale_status_verification["checks"],
             &(&1["field"] == "timeline_preservation_status" and &1["status"] == "fail")
           )

    stale_identity_observations =
      observations
      |> Map.put("timeline_identity_timeline_id", "timeline:dl_unlocked")

    assert {:ok, stale_identity_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_identity_observations)

    assert stale_identity_verification["status"] == "fail"

    assert Enum.any?(
             stale_identity_verification["checks"],
             &(&1["field"] == "timeline_identity_timeline_id" and &1["status"] == "fail")
           )

    stale_boundary_observations =
      observations
      |> Map.put("execution_boundary", "schedule_mutation_ready")

    assert {:ok, stale_boundary_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_boundary_observations)

    assert stale_boundary_verification["status"] == "fail"

    assert Enum.any?(
             stale_boundary_verification["checks"],
             &(&1["field"] == "execution_boundary" and &1["status"] == "fail")
           )

    assert {:ok, _valid_status} =
             Schema.validate_artifact(status,
               schema_contract: "timeline_preservation_status.v1"
             )

    assert OrbitalDynamics.validation_artifact_observations(
             "timeline_preservation_status.v1",
             status
           ) == Validation.artifact_observations("timeline_preservation_status.v1", status)
  end

  test "verifies curated timeline integrity report reference fixtures" do
    fixture_id = "fixture.artifact.timeline_integrity_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.timeline_integrity_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = timeline_integrity_report_fixture()

    assert generated_timeline_integrity_report_fixture() == report

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               timeline_integrity_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      timeline_integrity_report_fixture_observations()
      |> Map.put("timeline_integrity_issue_count", 2)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "timeline_integrity_issue_count" and &1["status"] == "fail")
           )

    stale_row_derived_observations =
      timeline_integrity_report_fixture_observations()
      |> put_in(["row_derived_timeline_integrity_issue_type_counts", "exclusivity_overlap"], 0)

    assert {:ok, stale_row_derived_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_row_derived_observations)

    assert stale_row_derived_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_verification["checks"],
             &(&1["field"] == "row_derived_timeline_integrity_issue_type_counts" and
                 &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "timeline_integrity_report.v1")

    assert OrbitalDynamics.validation_artifact_observations(
             "timeline_integrity_report.v1",
             report
           ) == Validation.artifact_observations("timeline_integrity_report.v1", report)
  end

  test "verifies curated timeline dependency impact summary reference fixtures" do
    fixture_id = "fixture.artifact.timeline_dependency_impact_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.timeline_dependency_impact_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = timeline_dependency_impact_summary_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               timeline_dependency_impact_summary_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      timeline_dependency_impact_summary_fixture_observations()
      |> Map.put("dependent_activity_count", 3)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "dependent_activity_count" and &1["status"] == "fail")
           )

    stale_row_derived_observations =
      timeline_dependency_impact_summary_fixture_observations()
      |> put_in(
        [
          "row_derived_operator_action_reason_counts",
          "dependency_changed_or_removed_source_activity"
        ],
        1
      )

    assert {:ok, stale_row_derived_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_row_derived_observations)

    assert stale_row_derived_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_verification["checks"],
             &(&1["field"] == "row_derived_operator_action_reason_counts" and
                 &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report,
               schema_contract: "timeline_dependency_impact_summary.v1"
             )

    assert OrbitalDynamics.validation_artifact_observations(
             "timeline_dependency_impact_summary.v1",
             report
           ) ==
             Validation.artifact_observations(
               "timeline_dependency_impact_summary.v1",
               report
             )
  end

  test "verifies curated timeline diff summary reference fixtures" do
    fixture_id = "fixture.artifact.timeline_diff_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.timeline_diff_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = timeline_diff_summary_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               timeline_diff_summary_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      timeline_diff_summary_fixture_observations()
      |> Map.put("review_required_count", 2)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "review_required_count" and &1["status"] == "fail")
           )

    stale_row_derived_observations =
      timeline_diff_summary_fixture_observations()
      |> put_in(["row_derived_status_transition_category_counts", "status_changed"], 0)

    assert {:ok, stale_row_derived_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_row_derived_observations)

    assert stale_row_derived_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_verification["checks"],
             &(&1["field"] == "row_derived_status_transition_category_counts" and
                 &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "timeline_diff_summary.v1")

    assert OrbitalDynamics.validation_artifact_observations(
             "timeline_diff_summary.v1",
             report
           ) == Validation.artifact_observations("timeline_diff_summary.v1", report)
  end

  test "verifies curated timeline publication summary reference fixtures" do
    fixture_id = "fixture.artifact.timeline_publication_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.timeline_publication_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = timeline_publication_summary_fixture()

    assert generated_timeline_publication_summary_fixture() == report

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               timeline_publication_summary_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      timeline_publication_summary_fixture_observations()
      |> Map.put("publication_status", "published")

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "publication_status" and &1["status"] == "fail")
           )

    stale_downstream_invalidation_observations =
      timeline_publication_summary_fixture_observations()
      |> Map.put("downstream_invalidation_status", "clear")

    assert {:ok, stale_downstream_invalidation_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_downstream_invalidation_observations
             )

    assert stale_downstream_invalidation_verification["status"] == "fail"

    assert Enum.any?(
             stale_downstream_invalidation_verification["checks"],
             &(&1["field"] == "downstream_invalidation_status" and &1["status"] == "fail")
           )

    stale_invalidation_reason_observations =
      timeline_publication_summary_fixture_observations()
      |> Map.put("downstream_invalidation_reason_counts", %{
        "superseded_publication" => 2
      })

    assert {:ok, stale_invalidation_reason_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_invalidation_reason_observations
             )

    assert stale_invalidation_reason_verification["status"] == "fail"

    assert Enum.any?(
             stale_invalidation_reason_verification["checks"],
             &(&1["field"] == "downstream_invalidation_reason_counts" and
                 &1["status"] == "fail")
           )

    stale_dependent_observations =
      timeline_publication_summary_fixture_observations()
      |> Map.put("dependent_activity_ids", "wrong_dependent")

    assert {:ok, stale_dependent_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_dependent_observations)

    assert stale_dependent_verification["status"] == "fail"

    assert Enum.any?(
             stale_dependent_verification["checks"],
             &(&1["field"] == "dependent_activity_ids" and &1["status"] == "fail")
           )

    stale_routing_observations =
      timeline_publication_summary_fixture_observations()
      |> put_in(
        [
          "source_timeline_diff_review_timeline_ids_by_required_operator_action",
          "review_added_activity"
        ],
        []
      )

    assert {:ok, stale_routing_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_routing_observations)

    assert stale_routing_verification["status"] == "fail"

    assert Enum.any?(
             stale_routing_verification["checks"],
             &(&1["field"] ==
                 "source_timeline_diff_review_timeline_ids_by_required_operator_action" and
                 &1["status"] == "fail")
           )

    stale_boundary_observations =
      timeline_publication_summary_fixture_observations()
      |> Map.put("execution_boundary", "schedule_mutation_ready")

    assert {:ok, stale_boundary_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_boundary_observations)

    assert stale_boundary_verification["status"] == "fail"

    assert Enum.any?(
             stale_boundary_verification["checks"],
             &(&1["field"] == "execution_boundary" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report,
               schema_contract: "timeline_publication_summary.v1"
             )

    assert OrbitalDynamics.validation_artifact_observations(
             "timeline_publication_summary.v1",
             report
           ) ==
             Validation.artifact_observations(
               "timeline_publication_summary.v1",
               report
             )
  end
end
