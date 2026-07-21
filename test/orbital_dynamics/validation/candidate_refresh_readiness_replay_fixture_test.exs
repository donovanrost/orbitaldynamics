defmodule OrbitalDynamics.Validation.CandidateRefreshReadinessReplayFixtureTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, OperatorReview, Schema, Validation}

  import OrbitalDynamics.Validation.CandidateRefreshReadinessReplayFixtures,
    only: [
      candidate_refresh_candidate_scoped_readiness_nonmatching_challenge_fixture: 0,
      candidate_refresh_candidate_scoped_readiness_selection_challenge_fixture: 0,
      candidate_refresh_candidate_scoped_readiness_selection_challenge_fixture_observations: 0,
      candidate_refresh_candidate_scoped_readiness_selection_challenge_request: 0,
      candidate_refresh_operational_readiness_fixture: 0,
      candidate_refresh_operational_readiness_fixture_observations: 0,
      candidate_refresh_operational_readiness_selection_challenge_fixture: 0,
      candidate_refresh_operational_readiness_selection_challenge_fixture_observations: 0,
      candidate_refresh_operational_readiness_selection_challenge_request: 0,
      candidate_refresh_quality_gate_fixture: 0,
      candidate_refresh_quality_gate_fixture_observations: 0,
      candidate_refresh_quality_gate_unavailable_resource_selection_challenge_fixture: 0,
      candidate_refresh_quality_gate_unavailable_resource_selection_challenge_fixture_observations:
        0,
      candidate_refresh_quality_gate_unavailable_resource_selection_challenge_request: 0,
      candidate_refresh_resource_projection_fixture: 0,
      candidate_refresh_resource_projection_fixture_observations: 0
    ]

  test "verifies candidate refresh resource projection replay fixtures" do
    fixture_id = "fixture.artifact.candidate_refresh.resource_projection_replay"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.candidate_refresh.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    artifact = candidate_refresh_resource_projection_fixture()
    observations = candidate_refresh_resource_projection_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "source_report_family_count" => 1,
             "source_report_row_count" => 4,
             "source_resource_projection_report_count" => 1,
             "source_resource_projection_row_count" => 4,
             "source_resource_projection_projected_resource_count" => 2,
             "source_resource_projection_invalid_activity_input_count" => 1,
             "source_resource_projection_invalid_resource_summary_input_count" => 1,
             "source_resource_projection_resource_pressure_status_counts" => %{
               "downlink_shortfall" => 1,
               "storage_shortfall" => 1
             },
             "source_resource_projection_resource_pressure_type_counts" => %{
               "downlink_shortfall" => 1,
               "storage_pressure" => 1,
               "storage_shortfall" => 1
             },
             "source_resource_projection_resource_pressure_direction_counts" => %{
               "downlink" => 1,
               "tracking" => 1
             },
             "source_resource_projection_resource_pressure_activity_ids_by_status" => %{
               "downlink_shortfall" => ["dl_pressure_1"],
               "storage_shortfall" => ["imaging_1", "imaging_2"]
             },
             "source_resource_projection_resource_pressure_activity_ids_by_type" => %{
               "downlink_shortfall" => ["dl_pressure_1"],
               "storage_pressure" => ["dl_pressure_1"],
               "storage_shortfall" => ["imaging_1", "imaging_2"]
             },
             "source_resource_projection_resource_pressure_activity_ids_by_direction" => %{
               "downlink" => ["dl_pressure_1"],
               "tracking" => ["imaging_1", "imaging_2"]
             },
             "source_resource_projection_trust_boundary_status" => "declared"
           } = observations

    stale_status_observations =
      observations
      |> Map.put("source_resource_projection_resource_pressure_status_counts", %{
        "stale_status" => 2
      })

    assert {:ok, stale_status_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_status_observations)

    assert stale_status_verification["status"] == "fail"

    assert Enum.any?(
             stale_status_verification["checks"],
             &(&1["field"] == "source_resource_projection_resource_pressure_status_counts" and
                 &1["status"] == "fail")
           )

    assert {:ok, _validated_artifact} =
             Schema.validate_artifact(artifact, schema_contract: "candidate_refresh.v1")
  end

  test "verifies candidate refresh quality gate replay fixtures" do
    fixture_id = "fixture.artifact.candidate_refresh.quality_gate_replay"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.candidate_refresh.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    artifact = candidate_refresh_quality_gate_fixture()
    observations = candidate_refresh_quality_gate_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "source_report_family_count" => 1,
             "source_report_row_count" => 6,
             "source_quality_gate_report_count" => 1,
             "source_quality_gate_row_count" => 6,
             "source_quality_gate_gate_count" => 6,
             "source_quality_gate_passed_gate_count" => 3,
             "source_quality_gate_review_gate_count" => 3,
             "source_quality_gate_analysis_gate_count" => 0,
             "source_quality_gate_blocked_gate_count" => 0,
             "source_quality_gate_readiness_level_counts" => %{"operator_review" => 1},
             "source_quality_gate_import_classification_counts" => %{"review_only" => 1},
             "source_quality_gate_status_counts" => %{"review_required" => 1},
             "source_quality_gate_gate_status_counts" => %{
               "passed" => 3,
               "review_required" => 3
             },
             "source_quality_gate_gate_classification_counts" => %{
               "importable" => 3,
               "review_only" => 3
             },
             "source_quality_gate_ready_for_import_count" => 0,
             "source_quality_gate_trust_boundary_status" => "declared",
             "source_quality_gate_resource_availability_pressure_count" => 2,
             "source_quality_gate_resource_availability_reason_counts" => %{
               "antenna_unavailable" => 1,
               "payload_unavailable" => 1
             },
             "source_quality_gate_resource_availability_reason_ids" =>
               "antenna_unavailable|payload_unavailable",
             "source_quality_gate_branch_local_review_pressure" => true,
             "source_quality_gate_branch_local_import_pressure" => false,
             "source_quality_gate_branch_local_resource_pressure" => true
           } = observations

    stale_resource_pressure_observations =
      observations
      |> Map.put("source_quality_gate_branch_local_resource_pressure", false)

    assert {:ok, stale_resource_pressure_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_resource_pressure_observations)

    assert stale_resource_pressure_verification["status"] == "fail"

    assert Enum.any?(
             stale_resource_pressure_verification["checks"],
             &(&1["field"] == "source_quality_gate_branch_local_resource_pressure" and
                 &1["status"] == "fail")
           )

    assert {:ok, _validated_artifact} =
             Schema.validate_artifact(artifact, schema_contract: "candidate_refresh.v1")
  end

  test "verifies exact unavailable-resource quality-gate selection without scope leakage" do
    fixture_id =
      "fixture.artifact.candidate_refresh.quality_gate_unavailable_resource_selection_challenge"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)
    assert fixture["fixture_type"] == "curated_internal_artifact_challenge"

    artifact = candidate_refresh_quality_gate_unavailable_resource_selection_challenge_fixture()

    observations =
      candidate_refresh_quality_gate_unavailable_resource_selection_challenge_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "candidate_count" => 1,
             "candidate_activity_id_keys" => "leo_2_downlink_dss_43_1",
             "contact_intent_activity_id_keys" => "leo_2_downlink_dss_43_1",
             "candidate_rejection_candidate_count" => 2,
             "candidate_rejection_rejected_count" => 1,
             "candidate_rejection_rejected_candidate_id_keys" => "leo_1_downlink_equator_prime_1",
             "invalidated_candidate_id_keys" => "leo_1_downlink_equator_prime_1",
             "invalidated_candidate_reason_counts" => %{
               "dropped_by_quality_gate_unavailable_resource" => 1
             },
             "source_quality_gate_resource_availability_reason_counts" => %{
               "antenna_unavailable" => 1
             }
           } = observations

    request = candidate_refresh_quality_gate_unavailable_resource_selection_challenge_request()

    summary =
      get_in(request, [
        "accepted_planning_state",
        "operational_quality_gate_unavailable_resource_summary"
      ])

    assert summary["blocked_contact_ids_by_spacecraft_id"] == %{
             "sat_1" => [
               "leo_1_downlink_equator_prime_1",
               "leo_2_downlink_dss_43_1"
             ]
           }

    assert [
             %{
               "candidate_id" => "leo_1_downlink_equator_prime_1",
               "activity_context" => %{
                 "provenance" => %{
                   "quality_gate_candidate_filter" => %{
                     "source_summary_schema_contract" =>
                       "operational_quality_gate_unavailable_resource_summary.v1",
                     "blocked_spacecraft_ids" => ["sat_1"],
                     "source_artifact_ids" => ["quality-gate-selection-challenge"],
                     "source_quality_gate_report_ids" => [
                       "quality_gate:unavailable_resource_selection_challenge"
                     ],
                     "trust_boundaries" => [
                       "generated_quality_gate_selection_challenge"
                     ]
                   }
                 }
               }
             },
             %{"candidate_id" => "leo_2_downlink_dss_43_1"}
           ] = artifact["candidate_rejection_report"]["rows"]

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert Enum.any?(
             review["rows"],
             &(&1["review_type"] == "candidate_rejection_review" and
                 &1["candidate_id"] == "leo_1_downlink_equator_prime_1")
           )

    assert Enum.any?(
             import["rows"],
             &(&1["source_review_type"] == "candidate_rejection_review" and
                 &1["subject_id"] == "leo_1_downlink_equator_prime_1")
           )

    stale_scope_observations =
      Map.put(
        observations,
        "candidate_activity_id_keys",
        "leo_1_downlink_equator_prime_1"
      )

    assert {:ok, stale_scope_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_scope_observations)

    assert stale_scope_verification["status"] == "fail"

    assert Enum.any?(
             stale_scope_verification["checks"],
             &(&1["field"] == "candidate_activity_id_keys" and &1["status"] == "fail")
           )

    assert {:ok,
            %{"schema_contract" => "operational_quality_gate_unavailable_resource_summary.v1"}} =
             Schema.validate_artifact(summary)

    assert {:ok, %{"schema_contract" => "candidate_rejection_report.v1"}} =
             Schema.validate_artifact(artifact["candidate_rejection_report"])

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1"}} =
             Schema.validate_artifact(artifact)
  end

  test "verifies candidate refresh operational readiness replay fixtures" do
    fixture_id = "fixture.artifact.candidate_refresh.operational_readiness_replay"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.candidate_refresh.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    artifact = candidate_refresh_operational_readiness_fixture()
    observations = candidate_refresh_operational_readiness_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "source_report_family_count" => 1,
             "source_report_row_count" => 1,
             "source_operational_readiness_report_count" => 1,
             "source_operational_readiness_row_count" => 1,
             "source_operational_readiness_gate_count" => 6,
             "source_operational_readiness_passed_gate_count" => 3,
             "source_operational_readiness_review_gate_count" => 3,
             "source_operational_readiness_analysis_gate_count" => 0,
             "source_operational_readiness_blocked_gate_count" => 0,
             "source_operational_readiness_readiness_level_counts" => %{
               "operator_review" => 1
             },
             "source_operational_readiness_import_classification_counts" => %{
               "review_only" => 1
             },
             "source_operational_readiness_status_counts" => %{"review_required" => 1},
             "source_operational_readiness_trust_boundary_status" => "declared",
             "source_operational_readiness_resource_availability_pressure_count" => 2,
             "source_operational_readiness_resource_availability_reason_counts" => %{
               "antenna_unavailable" => 1,
               "payload_unavailable" => 1
             },
             "source_operational_readiness_resource_availability_reason_ids" =>
               "antenna_unavailable|payload_unavailable",
             "source_operational_readiness_branch_local_review_pressure" => true,
             "source_operational_readiness_branch_local_import_pressure" => true,
             "source_operational_readiness_branch_local_resource_pressure" => true
           } = observations

    stale_status_observations =
      observations
      |> Map.put("source_operational_readiness_status_counts", %{"stale_status" => 1})

    assert {:ok, stale_status_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_status_observations)

    assert stale_status_verification["status"] == "fail"

    assert Enum.any?(
             stale_status_verification["checks"],
             &(&1["field"] == "source_operational_readiness_status_counts" and
                 &1["status"] == "fail")
           )

    stale_resource_pressure_observations =
      observations
      |> Map.put("source_operational_readiness_branch_local_resource_pressure", false)

    assert {:ok, stale_resource_pressure_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_resource_pressure_observations)

    assert stale_resource_pressure_verification["status"] == "fail"

    assert Enum.any?(
             stale_resource_pressure_verification["checks"],
             &(&1["field"] == "source_operational_readiness_branch_local_resource_pressure" and
                 &1["status"] == "fail")
           )

    assert {:ok, _validated_artifact} =
             Schema.validate_artifact(artifact, schema_contract: "candidate_refresh.v1")
  end

  test "verifies exact readiness selection without cross-spacecraft leakage" do
    fixture_id =
      "fixture.artifact.candidate_refresh.operational_readiness_selection_challenge"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)
    assert fixture["fixture_type"] == "curated_internal_artifact_challenge"

    artifact = candidate_refresh_operational_readiness_selection_challenge_fixture()

    observations =
      candidate_refresh_operational_readiness_selection_challenge_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "candidate_count" => 1,
             "candidate_activity_id_keys" => "leo_2_downlink_dss_43_1",
             "contact_intent_activity_id_keys" => "leo_2_downlink_dss_43_1",
             "candidate_rejection_candidate_count" => 2,
             "candidate_rejection_rejected_count" => 1,
             "candidate_rejection_rejected_candidate_id_keys" => "leo_1_downlink_equator_prime_1",
             "invalidated_candidate_id_keys" => "leo_1_downlink_equator_prime_1",
             "invalidated_candidate_reason_counts" => %{
               "dropped_by_operational_readiness_unavailable_resource" => 1
             }
           } = observations

    request = candidate_refresh_operational_readiness_selection_challenge_request()

    assert get_in(request, [
             "accepted_planning_state",
             "source_operational_readiness_report",
             "evidence",
             "resource_blocked_contact_ids_by_spacecraft_id",
             "sat_1"
           ]) == ["leo_1_downlink_equator_prime_1", "leo_2_downlink_dss_43_1"]

    assert [
             %{
               "candidate_id" => "leo_1_downlink_equator_prime_1",
               "activity_context" => %{
                 "provenance" => %{
                   "operational_readiness_candidate_filter" => %{
                     "blocked_spacecraft_ids" => ["sat_1"],
                     "source_artifact_ids" => ["readiness-selection-challenge"],
                     "trust_boundaries" => [
                       "generated_operational_readiness_selection_challenge"
                     ]
                   }
                 }
               }
             },
             %{"candidate_id" => "leo_2_downlink_dss_43_1"}
           ] = artifact["candidate_rejection_report"]["rows"]

    stale_scope_observations =
      Map.put(
        observations,
        "candidate_activity_id_keys",
        "leo_1_downlink_equator_prime_1"
      )

    assert {:ok, stale_scope_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_scope_observations)

    assert stale_scope_verification["status"] == "fail"

    assert Enum.any?(
             stale_scope_verification["checks"],
             &(&1["field"] == "candidate_activity_id_keys" and &1["status"] == "fail")
           )

    readiness_report =
      get_in(request, [
        "accepted_planning_state",
        "source_operational_readiness_report"
      ])

    assert {:ok, %{"schema_contract" => "operational_readiness_report.v1"}} =
             Schema.validate_artifact(readiness_report)

    assert {:ok, %{"schema_contract" => "candidate_rejection_report.v1"}} =
             Schema.validate_artifact(artifact["candidate_rejection_report"])

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1"}} =
             Schema.validate_artifact(artifact)
  end

  test "verifies exact candidate-scoped readiness selection challenge evidence" do
    fixture_id =
      "fixture.artifact.candidate_refresh.candidate_scoped_operational_readiness_selection_challenge"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)
    assert fixture["fixture_type"] == "curated_internal_artifact_challenge"

    artifact = candidate_refresh_candidate_scoped_readiness_selection_challenge_fixture()

    observations =
      candidate_refresh_candidate_scoped_readiness_selection_challenge_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "candidate_count" => 1,
             "candidate_activity_id_keys" => "leo_1_downlink_equator_prime_1",
             "candidate_rejection_source" =>
               "candidate_refresh.candidate_scoped_operational_readiness",
             "candidate_rejection_rejected_candidate_id_keys" => "leo_1_observe_target_a_1",
             "candidate_rejection_operational_readiness_filter_source_artifact_type_keys" =>
               "planned_activity.v1",
             "candidate_rejection_operational_readiness_filter_source_artifact_id_keys" =>
               "leo_1_observe_target_a_1",
             "candidate_rejection_operational_readiness_filter_status_keys" => "blocked",
             "candidate_rejection_operational_readiness_filter_selection_scope_keys" =>
               "candidate_artifact",
             "invalidated_candidate_reason_counts" => %{
               "dropped_by_candidate_scoped_operational_readiness" => 1
             }
           } = observations

    assert [
             %{
               "candidate_id" => "leo_1_observe_target_a_1",
               "activity_context" => %{
                 "provenance" => %{
                   "operational_readiness_candidate_filter" => %{
                     "source_schema_contract" => "operational_readiness_report.v1",
                     "source_artifact_types" => ["planned_activity.v1"],
                     "source_artifact_ids" => ["leo_1_observe_target_a_1"],
                     "operational_readiness_statuses" => ["blocked"],
                     "selection_scopes" => ["candidate_artifact"],
                     "trust_boundaries" => [
                       "generated_candidate_scoped_readiness_selection_challenge"
                     ]
                   }
                 }
               }
             },
             %{"candidate_id" => "leo_1_downlink_equator_prime_1"}
           ] = artifact["candidate_rejection_report"]["rows"]

    request = candidate_refresh_candidate_scoped_readiness_selection_challenge_request()

    readiness_report =
      get_in(request, ["accepted_planning_state", "operational_readiness_report"])

    assert {:ok, %{"schema_contract" => "operational_readiness_report.v1"}} =
             Schema.validate_artifact(readiness_report)

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)

    stale_identity_observations =
      Map.put(
        observations,
        "candidate_rejection_rejected_candidate_id_keys",
        "stale_observe_target_a_1"
      )

    assert {:ok, %{"status" => "fail", "checks" => stale_identity_checks}} =
             Validation.verify_reference_fixture(fixture_id, stale_identity_observations)

    assert Enum.any?(
             stale_identity_checks,
             &(&1["field"] == "candidate_rejection_rejected_candidate_id_keys" and
                 &1["status"] == "fail")
           )

    stale_reason_observations =
      Map.put(
        observations,
        "invalidated_candidate_reason_counts",
        %{"dropped_by_operational_readiness_unavailable_resource" => 1}
      )

    assert {:ok, %{"status" => "fail", "checks" => stale_reason_checks}} =
             Validation.verify_reference_fixture(fixture_id, stale_reason_observations)

    assert Enum.any?(
             stale_reason_checks,
             &(&1["field"] == "invalidated_candidate_reason_counts" and
                 &1["status"] == "fail")
           )

    nonmatching_artifact =
      candidate_refresh_candidate_scoped_readiness_nonmatching_challenge_fixture()

    assert Enum.map(nonmatching_artifact["candidate_activities"], & &1["id"]) == [
             "leo_1_observe_target_a_1",
             "leo_1_downlink_equator_prime_1"
           ]

    assert nonmatching_artifact["candidate_rejection_report"]["rejected_count"] == 0

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1"}} =
             Schema.validate_artifact(artifact)

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1"}} =
             Schema.validate_artifact(nonmatching_artifact)
  end
end
