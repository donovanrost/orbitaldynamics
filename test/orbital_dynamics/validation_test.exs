defmodule OrbitalDynamics.ValidationTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{
    CadenceImport,
    Schema,
    OperatorReview,
    OperationalReadiness,
    Validation
  }

  import OrbitalDynamics.Validation.OrbitalReferenceFixtures,
    only: [
      access_fixture_observations: 0,
      eclipse_fixture_observations: 0,
      ground_track_crossing_fixture_observations: 0,
      j2_fixture_observations: 0,
      target_visibility_fixture_observations: 0,
      two_body_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.CampaignArtifactFixtures,
    only: [
      campaign_plan_fixture_observations: 0,
      campaign_repair_fixture_observations: 0,
      campaign_strategy_fixture_observations: 0,
      candidate_refresh_orbit_data_result_artifact_fixture_observations: 0,
      candidate_refresh_result_artifact_fixture_observations: 0,
      ground_track_result_artifact_fixture_observations: 0,
      leo_access_manifest_result_artifact_fixture_observations: 0,
      leo_access_result_artifact_fixture_observations: 0,
      mission_plan_checkout_result_artifact_fixture_observations: 0,
      monte_carlo_result_artifact_fixture_observations: 0,
      raise_apogee_result_artifact_fixture_observations: 0,
      result_artifact_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.PolicyBundleFixtures,
    only: [
      command_contact_policy_bundle_fixture_observations: 0,
      conservative_policy_bundle_fixture_observations: 0,
      contact_command_review_policy_bundle_fixture_observations: 0,
      default_policy_bundle_fixture_observations: 0,
      degraded_payload_guard_policy_bundle_fixture_observations: 0,
      ground_network_policy_bundle_fixture_observations: 0,
      maneuver_authority_policy_bundle_fixture_observations: 0,
      operator_review_queue_policy_bundle_fixture_observations: 0,
      organization_adapter_policy_bundle_fixture_observations: 0,
      policy_bundle_fixture_observations: 0,
      resource_projection_authority_policy_bundle_fixture_observations: 0,
      timeline_protection_policy_bundle_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.ActivityArtifactFixtures,
    only: [
      activity_template_fixture_observations: 0,
      candidate_activity_fixture_observations: 0,
      plan_delta_fixture_observations: 0,
      planned_activity_fixture_observations: 0,
      realized_activity_fixture_observations: 0,
      subsystem_model_capability_fixture_observations: 0,
      subsystem_model_capability_storage_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.ContactWindowFixtures,
    only: [
      contact_intent_fixture_observations: 0,
      contact_intent_summary_fixture_observations: 0,
      refreshed_window_fixture_observations: 0,
      source_window_lineage_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.StateManeuverFixtures,
    only: [
      maneuver_execution_delta_fixture_observations: 0,
      maneuver_recommendation_fixture_observations: 0,
      realized_state_snapshot_fixture_observations: 0,
      remaining_horizon_fixture_observations: 0,
      spacecraft_state_estimate_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.PolicyEvidenceFixtures,
    only: [
      backend_acceptance_policy_fixture_observations: 0,
      validation_check_fixture_observations: 0,
      validation_record_fixture_observations: 0,
      validation_tolerance_policy_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.TimelineActivityStateFixtures,
    only: [
      timeline_activity_approval_state_fixture_observations: 0,
      timeline_activity_lifecycle_state_fixture_observations: 0,
      timeline_activity_precondition_summary_fixture_observations: 0,
      timeline_activity_state_fixture_observations: 0,
      timeline_activity_status_state_fixture_observations: 0,
      timeline_lifecycle_state_summary_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.TimelinePreservationFixtures,
    only: [
      timeline_dependency_impact_summary_fixture_observations: 0,
      timeline_diff_summary_fixture_observations: 0,
      timeline_integrity_report_fixture_observations: 0,
      timeline_preservation_report_fixture_observations: 0,
      timeline_preservation_status_fixture_observations: 0,
      timeline_publication_summary_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.TimelineTransitionFixtures,
    only: [
      timeline_transition_application_report_fixture_observations: 0,
      timeline_transition_application_selected_integrity_fixture_observations: 0,
      timeline_transition_application_selected_integrity_summary_fixture_observations: 0,
      timeline_transition_application_summary_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.TimelineHandoffFixtures,
    only: [
      cadence_import_manifest_fixture_observations: 0,
      timeline_diff_report_fixture_observations: 0,
      timeline_feedback_report_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.OperationalPlanningFixtures,
    only: [
      command_window_report_fixture_observations: 0,
      constraint_report_fixture_observations: 0,
      operational_timeline_report_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.ProviderCapacityPackFixtures,
    only: [
      contact_allocation_capacity_pack_report_fixture_observations: 0,
      contact_allocation_provider_reservation_request_summary_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.ContactContentionFixtures,
    only: [
      contact_contention_cross_station_fixture_observations: 0,
      contact_contention_report_fixture_observations: 0,
      contact_contention_resolution_report_fixture_observations: 0,
      contact_contention_resolution_summary_fixture_observations: 0,
      contact_filter_report_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.LinkCapacityFixtures,
    only: [
      link_capacity_report_fixture_observations: 0,
      link_capacity_summary_fixture_observations: 0,
      relay_data_path_summary_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.DecisionSupportFixtures,
    only: [
      maneuver_review_report_fixture_observations: 0,
      monte_carlo_reproducibility_report_fixture_observations: 0,
      pareto_frontier_report_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.ResourceProjectionFixtures,
    only: [
      resource_projection_flow_summary_fixture_observations: 0,
      resource_projection_report_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.ResourceSafetyFixtures,
    only: [
      cadence_import_resource_projection_battery_handoff_fixture_observations: 0,
      operator_review_resource_projection_battery_handoff_fixture_observations: 0,
      resource_filter_stale_margin_fixture_observations: 0,
      resource_projection_battery_handoff_fixture_observations: 0,
      resource_projection_stale_margin_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.ResourceSummaryFixtures,
    only: [
      resource_filter_report_fixture_observations: 0,
      resource_filter_summary_fixture_observations: 0,
      resource_summary_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.ObjectiveScoringFixtures,
    only: [
      objective_satisfaction_report_fixture_observations: 0,
      objective_tradeoff_report_fixture_observations: 0,
      ranking_comparison_report_fixture_observations: 0,
      score_term_report_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.SchemaCompatibilityFixtures,
    only: [
      schema_migration_future_contract_fixture_observations: 0,
      schema_migration_report_fixture_observations: 0,
      schema_validation_batch_report_fixture_observations: 0,
      schema_validation_report_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.StationReservationFixtures,
    only: [
      checked_in_station_calendar_report_fixture_observations: 0,
      provider_counteroffer_import_readiness_summary_fixture_observations: 0,
      provider_counteroffer_plan_impact_summary_fixture_observations: 0,
      provider_counteroffer_report_fixture_observations: 0,
      provider_counteroffer_review_summary_fixture_observations: 0,
      station_calendar_precedence_summary_fixture_observations: 0,
      station_calendar_provider_fixture_observations: 0,
      station_calendar_report_fixture_observations: 0,
      station_reservation_hold_import_readiness_summary_fixture_observations: 0,
      station_reservation_hold_summary_fixture_observations: 0,
      station_reservation_report_fixture_observations: 0,
      station_reservation_review_summary_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.ModelAcceptanceFixtures,
    only: [
      model_acceptance_report_fixture_observations: 0,
      validation_safety_case_summary_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.CandidateRefreshBaseFixtures,
    only: [
      candidate_refresh_fixture_observations: 0,
      candidate_refresh_resource_provenance_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.CandidateRefreshContactReplayFixtures,
    only: [
      candidate_refresh_contact_contention_challenge_fixture_observations: 0,
      candidate_refresh_contact_intent_direction_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.CandidateRefreshReadinessReplayFixtures,
    only: [
      candidate_refresh_operational_readiness_fixture_observations: 0,
      candidate_refresh_quality_gate_fixture_observations: 0,
      candidate_refresh_resource_projection_fixture_observations: 0,
      operational_readiness_resource_pressure_fixture: 0,
      quality_gate_resource_pressure_fixture: 0
    ]

  import OrbitalDynamics.Validation.CandidateRefreshTimelineReplayFixtures,
    only: [
      candidate_refresh_timeline_activity_lifecycle_fixture_observations: 0,
      candidate_refresh_timeline_activity_precondition_fixture_observations: 0,
      candidate_refresh_timeline_lifecycle_state_fixture_observations: 0,
      candidate_refresh_timeline_transition_application_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.CandidateRefreshPlanningFeedbackReplayFixtures,
    only: [
      candidate_refresh_constraint_fixture_observations: 0,
      candidate_refresh_objective_gap_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.CandidateRefreshCapacityFilterReplayFixtures,
    only: [
      candidate_refresh_link_capacity_fixture_observations: 0,
      candidate_refresh_resource_filter_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.CandidateRefreshFilterRejectionReplayFixtures,
    only: [
      candidate_refresh_candidate_rejection_fixture_observations: 0,
      candidate_refresh_contact_filter_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.CandidateRefreshFreshnessBudgetReplayFixtures,
    only: [
      candidate_refresh_freshness_fixture_observations: 0,
      candidate_refresh_refresh_budget_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.CandidateRefreshStationAllocationReplayFixtures,
    only: [
      candidate_refresh_contact_allocation_contradiction_fixture_observations: 0,
      candidate_refresh_station_calendar_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.CandidateStateFixtures,
    only: [
      accepted_planning_state_fixture_observations: 0,
      accepted_planning_state_oem_fixture_observations: 0,
      accepted_planning_state_opm_fixture_observations: 0,
      candidate_diff_row_fixture_observations: 0,
      candidate_rejection_report_fixture_observations: 0
    ]

  import OrbitalDynamics.Validation.PlanningInputFixtures,
    only: [
      campaign_request_lint_fixture_observations: 0,
      capability_catalog_fixture_observations: 0,
      environment_model_capability_constant_earth_rotation_fixture_observations: 0,
      environment_model_capability_fixed_sun_fixture_observations: 0,
      environment_provider_capability_constant_earth_rotation_fixture_observations: 0,
      environment_provider_capability_exponential_atmosphere_fixture_observations: 0,
      environment_provider_capability_fixed_sun_fixture_observations: 0,
      environment_provider_capability_tabular_earth_orientation_fixture_observations: 0
    ]

  test "verifies curated operator review package reference fixtures" do
    assert {:ok, fixture} =
             Validation.reference_fixture("fixture.artifact.operator_review_package.v1")

    assert fixture["model_id"] == "artifact.operator_review_package.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    assert {:ok, report} =
             Validation.verify_reference_fixture(
               "fixture.artifact.operator_review_package.v1",
               operator_review_package_fixture_observations()
             )

    assert report["status"] == "pass"
    assert Enum.all?(report["checks"], &(&1["status"] == "pass"))

    stale_row_derived_observations =
      operator_review_package_fixture_observations()
      |> put_in(["row_derived_review_type_counts", "timeline_diff_review"], 0)

    assert {:ok, stale_row_derived_report} =
             Validation.verify_reference_fixture(
               "fixture.artifact.operator_review_package.v1",
               stale_row_derived_observations
             )

    assert stale_row_derived_report["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_report["checks"],
             &(&1["field"] == "row_derived_review_type_counts" and &1["status"] == "fail")
           )

    package = operator_review_package_fixture()

    assert {:ok, _schema_report} =
             Schema.validate_artifact(package,
               schema_contract: "operator_review_package.v1"
             )

    stale_review_count = Map.put(package, "review_count", 7)

    assert {:error, stale_review_count_report} =
             Schema.validate_artifact(stale_review_count,
               schema_contract: "operator_review_package.v1"
             )

    assert Enum.any?(
             stale_review_count_report["errors"],
             &(&1["path"] == "$.review_count")
           )

    stale_review_type_counts =
      put_in(package, ["review_type_counts", "timeline_diff_review"], 0)

    assert {:error, stale_review_type_counts_report} =
             Schema.validate_artifact(stale_review_type_counts,
               schema_contract: "operator_review_package.v1"
             )

    assert Enum.any?(
             stale_review_type_counts_report["errors"],
             &(&1["path"] == "$.review_type_counts")
           )

    stale_review_queue_counts = Map.put(package, "review_queue_counts", %{})

    assert {:error, stale_review_queue_counts_report} =
             Schema.validate_artifact(stale_review_queue_counts,
               schema_contract: "operator_review_package.v1"
             )

    assert Enum.any?(
             stale_review_queue_counts_report["errors"],
             &(&1["path"] == "$.review_queue_counts")
           )

    stale_required_operator_action_counts =
      Map.put(package, "required_operator_action_counts", %{})

    assert {:error, stale_required_operator_action_counts_report} =
             Schema.validate_artifact(stale_required_operator_action_counts,
               schema_contract: "operator_review_package.v1"
             )

    assert Enum.any?(
             stale_required_operator_action_counts_report["errors"],
             &(&1["path"] == "$.required_operator_action_counts")
           )

    stale_model_limits =
      Map.put(package, "model_limits", Enum.drop(Map.fetch!(package, "model_limits"), 1))

    assert {:error, stale_model_limits_report} =
             Schema.validate_artifact(stale_model_limits,
               schema_contract: "operator_review_package.v1"
             )

    assert Enum.any?(
             stale_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits")
           )

    stale_assumption_boundary =
      put_in(package, ["assumptions", "boundary"], "api_write_ready")

    assert {:error, stale_assumption_boundary_report} =
             Schema.validate_artifact(stale_assumption_boundary,
               schema_contract: "operator_review_package.v1"
             )

    assert Enum.any?(
             stale_assumption_boundary_report["errors"],
             &(&1["path"] == "$.assumptions.boundary")
           )
  end

  test "verifies curated operational readiness report reference fixtures" do
    assert {:ok, fixture} =
             Validation.reference_fixture("fixture.artifact.operational_readiness_report.v1")

    assert fixture["model_id"] == "artifact.operational_readiness_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = operational_readiness_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               "fixture.artifact.operational_readiness_report.v1",
               operational_readiness_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    observations = operational_readiness_report_fixture_observations()

    assert observations["row_derived_ready_for_import_count"] == 1
    assert observations["row_derived_import_status_counts"] == %{"ready_for_import" => 1}
    assert observations["row_derived_cadence_import_status_counts"] == %{"present" => 1}

    assert OrbitalDynamics.validation_artifact_observations(
             "operational_readiness_report.v1",
             report
           ) == Validation.artifact_observations("operational_readiness_report.v1", report)

    stale_row_derived_observations =
      operational_readiness_report_fixture_observations()
      |> put_in(["row_derived_gate_status_counts", "passed"], 4)

    assert {:ok, stale_row_derived_verification} =
             Validation.verify_reference_fixture(
               "fixture.artifact.operational_readiness_report.v1",
               stale_row_derived_observations
             )

    assert stale_row_derived_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_verification["checks"],
             &(&1["field"] == "row_derived_gate_status_counts" and
                 &1["status"] == "fail")
           )

    stale_import_status_observations =
      observations
      |> put_in(["row_derived_import_status_counts", "ready_for_import"], 0)

    assert {:ok, stale_import_status_verification} =
             Validation.verify_reference_fixture(
               "fixture.artifact.operational_readiness_report.v1",
               stale_import_status_observations
             )

    assert stale_import_status_verification["status"] == "fail"

    assert Enum.any?(
             stale_import_status_verification["checks"],
             &(&1["field"] == "row_derived_import_status_counts" and
                 &1["status"] == "fail")
           )

    assert {:ok, _schema_report} =
             Schema.validate_artifact(report,
               schema_contract: "operational_readiness_report.v1"
             )

    stale_model = Map.put(report, "model", "stale_operational_readiness_model")

    assert {:error, stale_model_report} =
             Schema.validate_artifact(stale_model,
               schema_contract: "operational_readiness_report.v1"
             )

    assert Enum.any?(
             stale_model_report["errors"],
             &(&1["path"] == "$.model" and
                 &1["message"] ==
                   "must equal \"artifact_only_operational_readiness_classifier\"")
           )

    stale_import_classification = Map.put(report, "import_classification", "review_only")

    assert {:error, stale_import_classification_report} =
             Schema.validate_artifact(stale_import_classification,
               schema_contract: "operational_readiness_report.v1"
             )

    assert Enum.any?(
             stale_import_classification_report["errors"],
             &(&1["path"] == "$.import_classification")
           )

    stale_readiness_level = Map.put(report, "readiness_level", "operator_review")

    assert {:error, stale_readiness_level_report} =
             Schema.validate_artifact(stale_readiness_level,
               schema_contract: "operational_readiness_report.v1"
             )

    assert Enum.any?(
             stale_readiness_level_report["errors"],
             &(&1["path"] == "$.readiness_level")
           )

    stale_gate_count = Map.put(report, "gate_count", 4)

    assert {:error, stale_gate_count_report} =
             Schema.validate_artifact(stale_gate_count,
               schema_contract: "operational_readiness_report.v1"
             )

    assert Enum.any?(
             stale_gate_count_report["errors"],
             &(&1["path"] == "$.gate_count")
           )

    stale_passed_gate_count = Map.put(report, "passed_gate_count", 4)

    assert {:error, stale_passed_gate_count_report} =
             Schema.validate_artifact(stale_passed_gate_count,
               schema_contract: "operational_readiness_report.v1"
             )

    assert Enum.any?(
             stale_passed_gate_count_report["errors"],
             &(&1["path"] == "$.passed_gate_count")
           )

    stale_evidence_count = put_in(report, ["evidence", "ready_for_import_count"], 0)

    assert {:error, stale_evidence_count_report} =
             Schema.validate_artifact(stale_evidence_count,
               schema_contract: "operational_readiness_report.v1"
             )

    assert Enum.any?(
             stale_evidence_count_report["errors"],
             &(&1["path"] == "$.evidence.ready_for_import_count")
           )

    stale_evidence_map = put_in(report, ["evidence", "import_status_counts"], %{})

    assert {:error, stale_evidence_map_report} =
             Schema.validate_artifact(stale_evidence_map,
               schema_contract: "operational_readiness_report.v1"
             )

    assert Enum.any?(
             stale_evidence_map_report["errors"],
             &(&1["path"] == "$.evidence.import_status_counts")
           )

    stale_model_limits =
      Map.put(report, "model_limits", Enum.drop(Map.fetch!(report, "model_limits"), 1))

    assert {:error, stale_model_limits_report} =
             Schema.validate_artifact(stale_model_limits,
               schema_contract: "operational_readiness_report.v1"
             )

    assert Enum.any?(
             stale_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits")
           )

    stale_assumptions =
      Map.put(
        report,
        "assumptions",
        List.replace_at(Map.fetch!(report, "assumptions"), 1, "external_import_write_ready")
      )

    assert {:error, stale_assumptions_report} =
             Schema.validate_artifact(stale_assumptions,
               schema_contract: "operational_readiness_report.v1"
             )

    assert Enum.any?(
             stale_assumptions_report["errors"],
             &(&1["path"] == "$.assumptions")
           )
  end

  test "verifies curated operational execution boundary summary reference fixtures" do
    fixture_id = "fixture.artifact.operational_execution_boundary_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.operational_execution_boundary_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = operational_execution_boundary_summary_fixture()
    observations = operational_execution_boundary_summary_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert observations["import_eligible"] == true
    assert observations["handoff_only"] == true
    assert observations["execution_allowed"] == false
    assert observations["cadence_write_allowed"] == false
    assert observations["operator_authority_granted"] == false
    assert observations["execution_boundary"] == "adapter_handoff_only"

    assert observations["assumption_execution_boundary"] ==
             "artifact_only_no_cadence_write_no_command_execution"

    assert observations["operator_authority"] == "not_granted_by_execution_boundary_summary"
    assert observations["cadence_write"] == "not_performed_by_summary"
    assert observations["command_execution"] == "not_performed_by_summary"
    assert observations["operational_mode_gate_id"] == "operational_mode"
    assert observations["operational_mode_gate_status"] == "passed"
    assert observations["gate_count"] == 5

    assert OrbitalDynamics.validation_artifact_observations(
             "operational_execution_boundary_summary.v1",
             report
           ) ==
             Validation.artifact_observations(
               "operational_execution_boundary_summary.v1",
               report
             )

    stale_execution_observations = Map.put(observations, "execution_allowed", true)

    assert {:ok, stale_execution_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_execution_observations)

    assert stale_execution_verification["status"] == "fail"

    assert Enum.any?(
             stale_execution_verification["checks"],
             &(&1["field"] == "execution_allowed" and &1["status"] == "fail")
           )

    stale_boundary_observations =
      Map.put(observations, "execution_boundary", "ready_for_command_execution")

    assert {:ok, stale_boundary_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_boundary_observations)

    assert stale_boundary_verification["status"] == "fail"

    assert Enum.any?(
             stale_boundary_verification["checks"],
             &(&1["field"] == "execution_boundary" and &1["status"] == "fail")
           )

    stale_assumption_observations =
      Map.put(observations, "command_execution", "performed_by_summary")

    assert {:ok, stale_assumption_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_assumption_observations)

    assert stale_assumption_verification["status"] == "fail"

    assert Enum.any?(
             stale_assumption_verification["checks"],
             &(&1["field"] == "command_execution" and &1["status"] == "fail")
           )

    assert {:ok, _schema_report} =
             Schema.validate_artifact(report,
               schema_contract: "operational_execution_boundary_summary.v1"
             )
  end

  test "verifies curated operational import eligibility summary reference fixtures" do
    fixture_id = "fixture.artifact.operational_import_eligibility_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.operational_import_eligibility_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = operational_import_eligibility_summary_fixture()
    observations = operational_import_eligibility_summary_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert observations["import_eligible"] == true
    assert observations["import_classification"] == "importable"
    assert observations["readiness_level"] == "import_eligible"
    assert observations["status"] == "passed"
    assert observations["gate_count"] == 5
    assert observations["passed_gate_count"] == 5
    assert observations["row_derived_non_passed_gate_count"] == 0
    assert observations["execution_boundary"] == "artifact_only_no_cadence_write"
    assert observations["operator_authority"] == "not_granted_by_summary"

    assert OrbitalDynamics.validation_artifact_observations(
             "operational_import_eligibility_summary.v1",
             report
           ) ==
             Validation.artifact_observations(
               "operational_import_eligibility_summary.v1",
               report
             )

    stale_eligible_observations = Map.put(observations, "import_eligible", false)

    assert {:ok, stale_eligible_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_eligible_observations)

    assert stale_eligible_verification["status"] == "fail"

    assert Enum.any?(
             stale_eligible_verification["checks"],
             &(&1["field"] == "import_eligible" and &1["status"] == "fail")
           )

    stale_count_observations = Map.put(observations, "gate_count", 4)

    assert {:ok, stale_count_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_count_observations)

    assert stale_count_verification["status"] == "fail"

    assert Enum.any?(
             stale_count_verification["checks"],
             &(&1["field"] == "gate_count" and &1["status"] == "fail")
           )

    stale_boundary_observations =
      Map.put(observations, "execution_boundary", "cadence_write_ready")

    assert {:ok, stale_boundary_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_boundary_observations)

    assert stale_boundary_verification["status"] == "fail"

    assert Enum.any?(
             stale_boundary_verification["checks"],
             &(&1["field"] == "execution_boundary" and &1["status"] == "fail")
           )

    assert {:ok, _schema_report} =
             Schema.validate_artifact(report,
               schema_contract: "operational_import_eligibility_summary.v1"
             )
  end

  test "verifies curated operational readiness gate summary reference fixtures" do
    fixture_id = "fixture.artifact.operational_readiness_gate_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.operational_readiness_gate_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = operational_readiness_gate_summary_fixture()
    observations = operational_readiness_gate_summary_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert observations["gate_count"] == 5
    assert observations["row_derived_gate_count"] == 5
    assert observations["gate_status_counts"] == %{"passed" => 5}
    assert observations["row_derived_gate_status_counts"] == %{"passed" => 5}
    assert observations["gate_classification_counts"] == %{"importable" => 5}

    assert observations["row_derived_gate_ids_by_status"] == %{
             "passed" => [
               "adapter_boundary",
               "cadence_import",
               "operational_mode",
               "operator_review",
               "source_contract"
             ]
           }

    assert observations["passed_gate_keys"] ==
             "source_contract|operational_mode|adapter_boundary|operator_review|cadence_import"

    assert observations["non_passed_gate_keys"] == ""
    assert observations["execution_boundary"] == "artifact_only_no_cadence_write"
    assert observations["operator_authority"] == "not_granted_by_summary"

    assert OrbitalDynamics.validation_artifact_observations(
             "operational_readiness_gate_summary.v1",
             report
           ) ==
             Validation.artifact_observations(
               "operational_readiness_gate_summary.v1",
               report
             )

    stale_status_observations =
      Map.put(observations, "row_derived_gate_status_counts", %{"passed" => 4})

    assert {:ok, stale_status_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_status_observations)

    assert stale_status_verification["status"] == "fail"

    assert Enum.any?(
             stale_status_verification["checks"],
             &(&1["field"] == "row_derived_gate_status_counts" and
                 &1["status"] == "fail")
           )

    stale_routing_observations =
      put_in(observations, ["row_derived_gate_ids_by_status", "passed"], ["source_contract"])

    assert {:ok, stale_routing_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_routing_observations)

    assert stale_routing_verification["status"] == "fail"

    assert Enum.any?(
             stale_routing_verification["checks"],
             &(&1["field"] == "row_derived_gate_ids_by_status" and &1["status"] == "fail")
           )

    stale_boundary_observations = Map.put(observations, "operator_authority", "granted")

    assert {:ok, stale_boundary_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_boundary_observations)

    assert stale_boundary_verification["status"] == "fail"

    assert Enum.any?(
             stale_boundary_verification["checks"],
             &(&1["field"] == "operator_authority" and &1["status"] == "fail")
           )

    assert {:ok, _schema_report} =
             Schema.validate_artifact(report,
               schema_contract: "operational_readiness_gate_summary.v1"
             )
  end

  test "verifies curated quality gate report reference fixtures" do
    fixture_id = "fixture.artifact.quality_gate_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.quality_gate_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = quality_gate_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               quality_gate_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    observations = quality_gate_report_fixture_observations()

    assert observations["row_derived_ready_for_import_count"] == 1
    assert observations["row_derived_import_status_counts"] == %{"ready_for_import" => 1}
    assert observations["row_derived_cadence_import_status_counts"] == %{"present" => 1}

    assert OrbitalDynamics.validation_artifact_observations("quality_gate_report.v1", report) ==
             Validation.artifact_observations("quality_gate_report.v1", report)

    stale_row_derived_observations =
      quality_gate_report_fixture_observations()
      |> put_in(["row_derived_gate_ids_by_status", "passed"], ["source_contract"])

    assert {:ok, stale_row_derived_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_row_derived_observations)

    assert stale_row_derived_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_verification["checks"],
             &(&1["field"] == "row_derived_gate_ids_by_status" and &1["status"] == "fail")
           )

    stale_import_status_observations =
      observations
      |> put_in(["row_derived_cadence_import_status_counts", "present"], 0)

    assert {:ok, stale_import_status_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_import_status_observations)

    assert stale_import_status_verification["status"] == "fail"

    assert Enum.any?(
             stale_import_status_verification["checks"],
             &(&1["field"] == "row_derived_cadence_import_status_counts" and
                 &1["status"] == "fail")
           )

    assert {:ok, _schema_report} =
             Schema.validate_artifact(report,
               schema_contract: "quality_gate_report.v1"
             )

    stale_import_classification = Map.put(report, "import_classification", "review_only")

    assert {:error, stale_import_classification_report} =
             Schema.validate_artifact(stale_import_classification,
               schema_contract: "quality_gate_report.v1"
             )

    assert Enum.any?(
             stale_import_classification_report["errors"],
             &(&1["path"] == "$.import_classification")
           )

    stale_gate_count = Map.put(report, "gate_count", 4)

    assert {:error, stale_gate_count_report} =
             Schema.validate_artifact(stale_gate_count,
               schema_contract: "quality_gate_report.v1"
             )

    assert Enum.any?(
             stale_gate_count_report["errors"],
             &(&1["path"] == "$.gate_count")
           )

    stale_gate_status_counts = Map.put(report, "gate_status_counts", %{"passed" => 4})

    assert {:error, stale_gate_status_counts_report} =
             Schema.validate_artifact(stale_gate_status_counts,
               schema_contract: "quality_gate_report.v1"
             )

    assert Enum.any?(
             stale_gate_status_counts_report["errors"],
             &(&1["path"] == "$.gate_status_counts")
           )

    stale_gate_ids_by_status =
      put_in(report, ["gate_ids_by_status", "passed"], ["source_contract"])

    assert {:error, stale_gate_ids_by_status_report} =
             Schema.validate_artifact(stale_gate_ids_by_status,
               schema_contract: "quality_gate_report.v1"
             )

    assert Enum.any?(
             stale_gate_ids_by_status_report["errors"],
             &(&1["path"] == "$.gate_ids_by_status")
           )

    stale_model_limits =
      Map.put(report, "model_limits", Enum.drop(Map.fetch!(report, "model_limits"), 1))

    assert {:error, stale_model_limits_report} =
             Schema.validate_artifact(stale_model_limits,
               schema_contract: "quality_gate_report.v1"
             )

    assert Enum.any?(
             stale_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits")
           )

    stale_execution_boundary =
      put_in(report, ["assumptions", "execution_boundary"], "cadence_write_ready")

    assert {:error, stale_execution_boundary_report} =
             Schema.validate_artifact(stale_execution_boundary,
               schema_contract: "quality_gate_report.v1"
             )

    assert Enum.any?(
             stale_execution_boundary_report["errors"],
             &(&1["path"] == "$.assumptions.execution_boundary")
           )
  end

  test "verifies curated operational quality gate summary reference fixtures" do
    fixture_id = "fixture.artifact.operational_quality_gate_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.operational_quality_gate_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = operational_quality_gate_summary_fixture()
    observations = operational_quality_gate_summary_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert observations["review_gate_count"] == 3
    assert observations["row_derived_review_gate_count"] == 3
    assert observations["non_passed_gate_count"] == 3

    assert observations["row_derived_non_passed_gate_keys"] ==
             "cadence_import|operator_review|resource_availability"

    assert observations["row_derived_non_passed_quality_gate_row_keys"] ==
             "quality_gate:resource_projection_report.v1:resource_summaries:cadence_import:6|quality_gate:resource_projection_report.v1:resource_summaries:operator_review:5|quality_gate:resource_projection_report.v1:resource_summaries:resource_availability:4"

    assert OrbitalDynamics.validation_artifact_observations(
             "operational_quality_gate_summary.v1",
             report
           ) ==
             Validation.artifact_observations(
               "operational_quality_gate_summary.v1",
               report
             )

    stale_review_count_observations = Map.put(observations, "row_derived_review_gate_count", 0)

    assert {:ok, stale_review_count_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_review_count_observations)

    assert stale_review_count_verification["status"] == "fail"

    assert Enum.any?(
             stale_review_count_verification["checks"],
             &(&1["field"] == "row_derived_review_gate_count" and &1["status"] == "fail")
           )

    stale_non_passed_routing_observations =
      Map.put(observations, "row_derived_non_passed_gate_keys", "cadence_import")

    assert {:ok, stale_non_passed_routing_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_non_passed_routing_observations
             )

    assert stale_non_passed_routing_verification["status"] == "fail"

    assert Enum.any?(
             stale_non_passed_routing_verification["checks"],
             &(&1["field"] == "row_derived_non_passed_gate_keys" and &1["status"] == "fail")
           )

    stale_non_passed_row_routing_observations =
      Map.put(
        observations,
        "row_derived_non_passed_quality_gate_row_keys",
        "quality_gate:resource_projection_report.v1:resource_summaries:cadence_import:6"
      )

    assert {:ok, stale_non_passed_row_routing_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_non_passed_row_routing_observations
             )

    assert stale_non_passed_row_routing_verification["status"] == "fail"

    assert Enum.any?(
             stale_non_passed_row_routing_verification["checks"],
             &(&1["field"] == "row_derived_non_passed_quality_gate_row_keys" and
                 &1["status"] == "fail")
           )

    stale_boundary_observations = Map.put(observations, "operator_authority", "granted")

    assert {:ok, stale_boundary_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_boundary_observations)

    assert stale_boundary_verification["status"] == "fail"

    assert Enum.any?(
             stale_boundary_verification["checks"],
             &(&1["field"] == "operator_authority" and &1["status"] == "fail")
           )

    assert {:ok, _schema_report} =
             Schema.validate_artifact(report,
               schema_contract: "operational_quality_gate_summary.v1"
             )
  end

  test "verifies curated operational quality gate import readiness summary reference fixtures" do
    fixture_id = "fixture.artifact.operational_quality_gate_import_readiness_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.operational_quality_gate_import_readiness_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = operational_quality_gate_import_readiness_summary_fixture()
    observations = operational_quality_gate_import_readiness_summary_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert observations["ready_for_import_count"] == 1
    assert observations["row_derived_ready_for_import_count"] == 1
    assert observations["stale_freshness_count"] == 1
    assert observations["row_derived_stale_freshness_count"] == 1
    assert observations["cadence_import_status_counts"] == %{"present" => 1}
    assert observations["freshness_review_required"] == true
    assert observations["import_blocked"] == false

    assert OrbitalDynamics.validation_artifact_observations(
             "operational_quality_gate_import_readiness_summary.v1",
             report
           ) ==
             Validation.artifact_observations(
               "operational_quality_gate_import_readiness_summary.v1",
               report
             )

    stale_ready_observations = Map.put(observations, "ready_for_import_count", 0)

    assert {:ok, stale_ready_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_ready_observations)

    assert stale_ready_verification["status"] == "fail"

    assert Enum.any?(
             stale_ready_verification["checks"],
             &(&1["field"] == "ready_for_import_count" and &1["status"] == "fail")
           )

    stale_row_derived_freshness_observations =
      Map.put(observations, "row_derived_stale_freshness_count", 0)

    assert {:ok, stale_row_derived_freshness_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_row_derived_freshness_observations
             )

    assert stale_row_derived_freshness_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_freshness_verification["checks"],
             &(&1["field"] == "row_derived_stale_freshness_count" and
                 &1["status"] == "fail")
           )

    stale_cadence_status_observations =
      Map.put(observations, "row_derived_cadence_import_present_count", 0)

    assert {:ok, stale_cadence_status_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_cadence_status_observations)

    assert stale_cadence_status_verification["status"] == "fail"

    assert Enum.any?(
             stale_cadence_status_verification["checks"],
             &(&1["field"] == "row_derived_cadence_import_present_count" and
                 &1["status"] == "fail")
           )

    assert {:ok, _schema_report} =
             Schema.validate_artifact(report,
               schema_contract: "operational_quality_gate_import_readiness_summary.v1"
             )
  end

  test "verifies curated operational quality gate unavailable-resource summary reference fixtures" do
    fixture_id = "fixture.artifact.operational_quality_gate_unavailable_resource_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] ==
             "artifact.operational_quality_gate_unavailable_resource_summary.v1"

    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = operational_quality_gate_unavailable_resource_summary_fixture()
    observations = operational_quality_gate_unavailable_resource_summary_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_reason_count_observations =
      observations
      |> put_in(["unavailable_resource_reason_counts", "antenna_unavailable"], 0)

    assert {:ok, stale_reason_count_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_reason_count_observations)

    assert stale_reason_count_verification["status"] == "fail"

    assert Enum.any?(
             stale_reason_count_verification["checks"],
             &(&1["field"] == "unavailable_resource_reason_counts" and
                 &1["status"] == "fail")
           )

    stale_contact_routing_observations =
      observations
      |> put_in(["blocked_contact_ids_by_blocking_dimension", "antenna"], [])

    assert {:ok, stale_contact_routing_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_contact_routing_observations)

    assert stale_contact_routing_verification["status"] == "fail"

    assert Enum.any?(
             stale_contact_routing_verification["checks"],
             &(&1["field"] == "blocked_contact_ids_by_blocking_dimension" and
                 &1["status"] == "fail")
           )

    stale_row_status_observations =
      observations
      |> Map.put("row_derived_review_required_quality_gate_row_count", 0)

    assert {:ok, stale_row_status_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_row_status_observations)

    assert stale_row_status_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_status_verification["checks"],
             &(&1["field"] == "row_derived_review_required_quality_gate_row_count" and
                 &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "operational_quality_gate_unavailable_resource_summary.v1",
             report
           ) ==
             Validation.artifact_observations(
               "operational_quality_gate_unavailable_resource_summary.v1",
               report
             )

    assert {:ok, _schema_report} =
             Schema.validate_artifact(report,
               schema_contract: "operational_quality_gate_unavailable_resource_summary.v1"
             )
  end

  test "verifies checked-in operational quality gate unavailable-resource summary reference fixture" do
    fixture_id =
      "fixture.artifact.operational_quality_gate_unavailable_resource_summary.resource_projection_v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] ==
             "artifact.operational_quality_gate_unavailable_resource_summary.v1"

    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    assert fixture["inputs"]["artifact_path"] ==
             "study_results/operational_quality_gate_unavailable_resource_summary_v1.json"

    report = operational_quality_gate_unavailable_resource_summary_checked_in_fixture()
    observations = operational_quality_gate_unavailable_resource_summary_checked_in_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert observations["source_artifact_type"] == "resource_projection_report.v1"
    assert observations["unavailable_resource_pressure_count"] == 2
    assert observations["row_derived_unavailable_resource_pressure_count"] == 2

    assert observations["unavailable_resource_reason_counts"] == %{
             "antenna_unavailable" => 1,
             "payload_unavailable" => 1
           }

    assert observations["unavailable_resource_reason_keys"] ==
             "antenna_unavailable|payload_unavailable"

    assert observations["blocked_contact_ids_by_blocking_dimension"] == %{}

    assert observations["quality_gate_row_ids_by_status"] == %{
             "review_required" => [
               "quality_gate:resource_projection_report.v1:resource_summaries:resource_availability:4"
             ]
           }

    assert observations["execution_boundary"] == "artifact_only_no_cadence_write"
    assert observations["operator_authority"] == "not_granted_by_unavailable_resource_summary"

    stale_pressure_observations =
      observations
      |> Map.put("row_derived_unavailable_resource_pressure_count", 1)

    assert {:ok, stale_pressure_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_pressure_observations)

    assert stale_pressure_verification["status"] == "fail"

    assert Enum.any?(
             stale_pressure_verification["checks"],
             &(&1["field"] == "row_derived_unavailable_resource_pressure_count" and
                 &1["status"] == "fail")
           )

    stale_reason_observations =
      observations
      |> put_in(["unavailable_resource_reason_counts", "payload_unavailable"], 0)

    assert {:ok, stale_reason_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_reason_observations)

    assert stale_reason_verification["status"] == "fail"

    assert Enum.any?(
             stale_reason_verification["checks"],
             &(&1["field"] == "unavailable_resource_reason_counts" and
                 &1["status"] == "fail")
           )

    stale_quality_gate_routing_observations =
      observations
      |> put_in(["quality_gate_row_ids_by_status", "review_required"], [])

    assert {:ok, stale_quality_gate_routing_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_quality_gate_routing_observations
             )

    assert stale_quality_gate_routing_verification["status"] == "fail"

    assert Enum.any?(
             stale_quality_gate_routing_verification["checks"],
             &(&1["field"] == "quality_gate_row_ids_by_status" and &1["status"] == "fail")
           )

    stale_boundary_observations =
      observations
      |> Map.put("execution_boundary", "cadence_write_ready")

    assert {:ok, stale_boundary_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_boundary_observations)

    assert stale_boundary_verification["status"] == "fail"

    assert Enum.any?(
             stale_boundary_verification["checks"],
             &(&1["field"] == "execution_boundary" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "operational_quality_gate_unavailable_resource_summary.v1",
             report
           ) ==
             Validation.artifact_observations(
               "operational_quality_gate_unavailable_resource_summary.v1",
               report
             )

    assert {:ok, _schema_report} =
             Schema.validate_artifact(report,
               schema_contract: "operational_quality_gate_unavailable_resource_summary.v1"
             )
  end

  test "verifies curated operational quality gate schema validation summary reference fixtures" do
    fixture_id = "fixture.artifact.operational_quality_gate_schema_validation_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.operational_quality_gate_schema_validation_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = operational_quality_gate_schema_validation_summary_fixture()
    observations = operational_quality_gate_schema_validation_summary_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert observations["schema_validation_fail_count"] == 1
    assert observations["row_derived_schema_validation_fail_count"] == 1
    assert observations["schema_validation_error_count"] == 1
    assert observations["schema_validation_remediation_count"] == 1
    assert observations["schema_validation_import_blocked"] == true
    assert observations["row_derived_blocked_quality_gate_row_count"] == 1
    assert observations["row_derived_failed_schema_validation_quality_gate_row_count"] == 1

    assert OrbitalDynamics.validation_artifact_observations(
             "operational_quality_gate_schema_validation_summary.v1",
             report
           ) ==
             Validation.artifact_observations(
               "operational_quality_gate_schema_validation_summary.v1",
               report
             )

    stale_fail_count_observations = Map.put(observations, "schema_validation_fail_count", 0)

    assert {:ok, stale_fail_count_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_fail_count_observations)

    assert stale_fail_count_verification["status"] == "fail"

    assert Enum.any?(
             stale_fail_count_verification["checks"],
             &(&1["field"] == "schema_validation_fail_count" and &1["status"] == "fail")
           )

    stale_row_derived_fail_observations =
      Map.put(observations, "row_derived_schema_validation_fail_count", 0)

    assert {:ok, stale_row_derived_fail_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_row_derived_fail_observations)

    assert stale_row_derived_fail_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_fail_verification["checks"],
             &(&1["field"] == "row_derived_schema_validation_fail_count" and
                 &1["status"] == "fail")
           )

    stale_blocked_row_observations =
      Map.put(observations, "row_derived_blocked_quality_gate_row_count", 0)

    assert {:ok, stale_blocked_row_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_blocked_row_observations)

    assert stale_blocked_row_verification["status"] == "fail"

    assert Enum.any?(
             stale_blocked_row_verification["checks"],
             &(&1["field"] == "row_derived_blocked_quality_gate_row_count" and
                 &1["status"] == "fail")
           )

    assert {:ok, _schema_report} =
             Schema.validate_artifact(report,
               schema_contract: "operational_quality_gate_schema_validation_summary.v1"
             )
  end

  test "verifies curated operational quality gate operator training summary reference fixtures" do
    fixture_id = "fixture.artifact.operational_quality_gate_operator_training_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.operational_quality_gate_operator_training_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = operational_quality_gate_operator_training_summary_fixture()
    observations = operational_quality_gate_operator_training_summary_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert observations["operator_training_requirement_count"] == 5
    assert observations["row_derived_operator_training_requirement_count"] == 5

    assert observations["operator_training_requirement_counts"] == %{
             "certification" => 1,
             "operator_role" => 2,
             "qualification" => 1,
             "training" => 1
           }

    assert observations["required_operator_role_keys"] == "contact_operator|mission_director"
    assert observations["required_training_keys"] == "contact_replan_drill"
    assert observations["required_certification_keys"] == "cadence_import_cert"
    assert observations["required_qualification_keys"] == "sat_ops_current"
    assert observations["operator_training_review_required"] == true
    assert observations["row_derived_review_required_quality_gate_row_count"] == 1
    assert observations["row_derived_review_only_quality_gate_row_count"] == 1

    assert OrbitalDynamics.validation_artifact_observations(
             "operational_quality_gate_operator_training_summary.v1",
             report
           ) ==
             Validation.artifact_observations(
               "operational_quality_gate_operator_training_summary.v1",
               report
             )

    stale_requirement_count_observations =
      Map.put(observations, "operator_training_requirement_count", 4)

    assert {:ok, stale_requirement_count_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_requirement_count_observations)

    assert stale_requirement_count_verification["status"] == "fail"

    assert Enum.any?(
             stale_requirement_count_verification["checks"],
             &(&1["field"] == "operator_training_requirement_count" and
                 &1["status"] == "fail")
           )

    stale_row_derived_requirement_observations =
      Map.put(observations, "row_derived_operator_training_requirement_count", 4)

    assert {:ok, stale_row_derived_requirement_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_row_derived_requirement_observations
             )

    assert stale_row_derived_requirement_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_requirement_verification["checks"],
             &(&1["field"] == "row_derived_operator_training_requirement_count" and
                 &1["status"] == "fail")
           )

    stale_role_routing_observations =
      Map.put(observations, "required_operator_role_keys", "contact_operator")

    assert {:ok, stale_role_routing_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_role_routing_observations)

    assert stale_role_routing_verification["status"] == "fail"

    assert Enum.any?(
             stale_role_routing_verification["checks"],
             &(&1["field"] == "required_operator_role_keys" and &1["status"] == "fail")
           )

    stale_training_routing_observations =
      Map.put(observations, "required_training_keys", "")

    assert {:ok, stale_training_routing_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_training_routing_observations)

    assert stale_training_routing_verification["status"] == "fail"

    assert Enum.any?(
             stale_training_routing_verification["checks"],
             &(&1["field"] == "required_training_keys" and &1["status"] == "fail")
           )

    stale_review_row_observations =
      Map.put(observations, "row_derived_review_required_quality_gate_row_count", 0)

    assert {:ok, stale_review_row_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_review_row_observations)

    assert stale_review_row_verification["status"] == "fail"

    assert Enum.any?(
             stale_review_row_verification["checks"],
             &(&1["field"] == "row_derived_review_required_quality_gate_row_count" and
                 &1["status"] == "fail")
           )

    assert {:ok, _schema_report} =
             Schema.validate_artifact(report,
               schema_contract: "operational_quality_gate_operator_training_summary.v1"
             )
  end

  test "rejects stale copied readiness and quality source reports from challenge fixtures" do
    readiness_review = read_json!("study_results/operator_review_resource_pressure_v1.json")
    readiness_import = read_json!("study_results/cadence_import_resource_pressure_v1.json")
    quality_gate = read_json!("study_results/quality_gate_resource_pressure_v1.json")
    quality_review = OperatorReview.from_quality_gate_report(quality_gate)
    quality_import = CadenceImport.from_quality_gate_report(quality_gate)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(readiness_review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(readiness_import)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(quality_review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(quality_import)

    stale_readiness_review =
      put_in(
        readiness_review,
        ["rows", Access.at(0), "source_operational_readiness_report", "status"],
        "passed"
      )

    assert {:error, stale_readiness_review_report} =
             Schema.validate_artifact(stale_readiness_review)

    assert Enum.any?(
             stale_readiness_review_report["errors"],
             &(&1["path"] == "$.rows[0].source_operational_readiness_report.status" and
                 &1["message"] == "must match operational_readiness_status on handoff row")
           )

    stale_readiness_import =
      put_in(
        readiness_import,
        ["rows", Access.at(0), "source_operational_readiness_report", "readiness_level"],
        "blocked"
      )

    assert {:error, stale_readiness_import_report} =
             Schema.validate_artifact(stale_readiness_import)

    assert Enum.any?(
             stale_readiness_import_report["errors"],
             &(&1["path"] == "$.rows[0].source_operational_readiness_report.readiness_level" and
                 &1["message"] == "must match readiness_level on handoff row")
           )

    stale_quality_review =
      put_in(
        quality_review,
        ["rows", Access.at(0), "source_quality_gate_report", "readiness_level"],
        "blocked"
      )

    assert {:error, stale_quality_review_report} =
             Schema.validate_artifact(stale_quality_review)

    assert Enum.any?(
             stale_quality_review_report["errors"],
             &(&1["path"] == "$.rows[0].source_quality_gate_report.readiness_level" and
                 &1["message"] == "must match readiness_level on handoff row")
           )

    stale_quality_import =
      put_in(
        quality_import,
        ["rows", Access.at(0), "source_quality_gate_report", "report_id"],
        "quality_gate:wrong_report"
      )

    assert {:error, stale_quality_import_report} =
             Schema.validate_artifact(stale_quality_import)

    assert Enum.any?(
             stale_quality_import_report["errors"],
             &(&1["path"] == "$.rows[0].source_quality_gate_report.report_id" and
                 &1["message"] == "must match quality_gate_report_id on handoff row")
           )
  end

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

  test "verifies curated study benchmark reference fixtures" do
    fixtures = [
      {
        "fixture.artifact.study_benchmark.v1",
        study_benchmark_fixture(),
        study_benchmark_fixture_observations(),
        "matches_baseline_count",
        1
      },
      {
        "fixture.artifact.study_benchmark.distributed_concurrency_sweep",
        distributed_concurrency_benchmark_fixture(),
        distributed_concurrency_benchmark_fixture_observations(),
        "distributed_result_count",
        53
      },
      {
        "fixture.artifact.study_benchmark.distributed_chunk_sweep",
        distributed_chunk_benchmark_fixture(),
        distributed_chunk_benchmark_fixture_observations(),
        "task_chunk_size_option_count",
        5
      },
      {
        "fixture.artifact.study_benchmark.distributed_monte_carlo_scaling",
        distributed_monte_carlo_scaling_benchmark_fixture(),
        distributed_monte_carlo_scaling_benchmark_fixture_observations(),
        "monte_carlo_count_option_count",
        2
      },
      {
        "fixture.artifact.study_benchmark.distributed_diagnostic_sweep",
        distributed_diagnostic_benchmark_fixture(),
        distributed_diagnostic_benchmark_fixture_observations(),
        "distributed_result_count",
        23
      },
      {
        "fixture.artifact.study_benchmark.distributed_monte_carlo_chunked",
        distributed_monte_carlo_chunked_benchmark_fixture(),
        distributed_monte_carlo_chunked_benchmark_fixture_observations(),
        "result_count",
        17
      },
      {
        "fixture.artifact.study_benchmark.monte_carlo_scaling",
        monte_carlo_scaling_benchmark_fixture(),
        monte_carlo_scaling_benchmark_fixture_observations(),
        "repetition_count",
        2
      },
      {
        "fixture.artifact.study_benchmark.nx_study_benchmark",
        nx_study_benchmark_fixture(),
        nx_study_benchmark_fixture_observations(),
        "backend_count",
        2
      }
    ]

    for {fixture_id, artifact, observations, stale_field, stale_value} <- fixtures do
      assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

      assert fixture["model_id"] == "artifact.study_benchmark.v1"
      assert fixture["fixture_type"] == "curated_internal_artifact_regression"

      assert {:ok, verification} =
               Validation.verify_reference_fixture(fixture_id, observations)

      assert verification["status"] == "pass"
      assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

      stale_observations = Map.put(observations, stale_field, stale_value)

      assert {:ok, stale_verification} =
               Validation.verify_reference_fixture(fixture_id, stale_observations)

      assert stale_verification["status"] == "fail"

      assert Enum.any?(
               stale_verification["checks"],
               &(&1["field"] == stale_field and &1["status"] == "fail")
             )

      assert OrbitalDynamics.validation_artifact_observations("study_benchmark.v1", artifact) ==
               Validation.artifact_observations("study_benchmark.v1", artifact)
    end

    benchmark_report = study_benchmark_fixture()

    assert {:ok, _validated_report} =
             Schema.validate_artifact(benchmark_report, schema_contract: "study_benchmark.v1")

    stale_scenario_count =
      put_in(benchmark_report, ["results", Access.at(0), "scenario_count"], 99)

    assert {:error, stale_scenario_count_report} =
             Schema.validate_artifact(stale_scenario_count,
               schema_contract: "study_benchmark.v1"
             )

    assert Enum.any?(
             stale_scenario_count_report["errors"],
             &(&1["path"] == "$.results[0].scenario_count")
           )
  end

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

  test "verifies curated manifest field reference fixtures" do
    fixture_id = "fixture.artifact.manifest_field_reference.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.manifest_field_reference.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = manifest_field_reference_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               manifest_field_reference_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      manifest_field_reference_fixture_observations()
      |> Map.put("field_row_count", 3719)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "field_row_count" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "manifest_field_reference.v1",
             report
           ) == Validation.artifact_observations("manifest_field_reference.v1", report)

    assert {:ok, %{"schema_contract" => "manifest_field_reference.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "manifest_field_reference.v1"
             )

    stale_field_count = Map.put(report, "field_count", 3719)

    assert {:error, stale_field_count_report} =
             Schema.validate_artifact(stale_field_count,
               schema_contract: "manifest_field_reference.v1"
             )

    assert Enum.any?(
             stale_field_count_report["errors"],
             &(&1["path"] == "$.field_count")
           )

    fields = Map.fetch!(report, "fields")

    duplicate_path_fields =
      fields
      |> List.replace_at(1, Map.put(Enum.at(fields, 1), "path", "$.campaign"))

    stale_duplicate_path = Map.put(report, "fields", duplicate_path_fields)

    assert {:error, stale_duplicate_path_report} =
             Schema.validate_artifact(stale_duplicate_path,
               schema_contract: "manifest_field_reference.v1"
             )

    assert Enum.any?(
             stale_duplicate_path_report["errors"],
             &(&1["path"] == "$.fields")
           )

    stale_top_level_required =
      Map.put(report, "top_level_required", ["schema_version", "study_id"])

    assert {:error, stale_top_level_required_report} =
             Schema.validate_artifact(stale_top_level_required,
               schema_contract: "manifest_field_reference.v1"
             )

    assert Enum.any?(
             stale_top_level_required_report["errors"],
             &(&1["path"] == "$.top_level_required")
           )

    stale_activation_sections =
      Map.put(
        report,
        "activation_sections",
        List.replace_at(Map.fetch!(report, "activation_sections"), 0, "invalid_section")
      )

    assert {:error, stale_activation_sections_report} =
             Schema.validate_artifact(stale_activation_sections,
               schema_contract: "manifest_field_reference.v1"
             )

    assert Enum.any?(
             stale_activation_sections_report["errors"],
             &(&1["path"] == "$.activation_sections[0]")
           )

    stale_supported_outputs = put_in(report, ["supported", "outputs"], ["events"])

    assert {:error, stale_supported_outputs_report} =
             Schema.validate_artifact(stale_supported_outputs,
               schema_contract: "manifest_field_reference.v1"
             )

    assert Enum.any?(
             stale_supported_outputs_report["errors"],
             &(&1["path"] == "$.supported.outputs")
           )
  end

  test "verifies curated study manifest lint reference fixtures" do
    fixture_id = "fixture.artifact.study_manifest_lint.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.study_manifest_lint.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = study_manifest_lint_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               study_manifest_lint_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      study_manifest_lint_fixture_observations()
      |> Map.put("error_count", 1)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "error_count" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "study_manifest_lint.v1",
             report
           ) == Validation.artifact_observations("study_manifest_lint.v1", report)

    assert {:ok, %{"schema_contract" => "study_manifest_lint.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "study_manifest_lint.v1"
             )

    stale_error_count = Map.put(report, "error_count", 1)

    assert {:error, stale_error_count_report} =
             Schema.validate_artifact(stale_error_count,
               schema_contract: "study_manifest_lint.v1"
             )

    assert Enum.any?(
             stale_error_count_report["errors"],
             &(&1["path"] == "$.error_count")
           )

    stale_warning_count = Map.put(report, "warning_count", 1)

    assert {:error, stale_warning_count_report} =
             Schema.validate_artifact(stale_warning_count,
               schema_contract: "study_manifest_lint.v1"
             )

    assert Enum.any?(
             stale_warning_count_report["errors"],
             &(&1["path"] == "$.warning_count")
           )

    stale_status = Map.put(report, "status", "fail")

    assert {:error, stale_status_report} =
             Schema.validate_artifact(stale_status,
               schema_contract: "study_manifest_lint.v1"
             )

    assert Enum.any?(
             stale_status_report["errors"],
             &(&1["path"] == "$.status")
           )

    stale_duplicate_outputs =
      Map.put(report, "outputs", ["trajectories", "trajectories"])

    assert {:error, stale_duplicate_outputs_report} =
             Schema.validate_artifact(stale_duplicate_outputs,
               schema_contract: "study_manifest_lint.v1"
             )

    assert Enum.any?(
             stale_duplicate_outputs_report["errors"],
             &(&1["path"] == "$.outputs")
           )

    stale_unsupported_output = Map.put(report, "outputs", ["unsupported_output"])

    assert {:error, stale_unsupported_output_report} =
             Schema.validate_artifact(stale_unsupported_output,
               schema_contract: "study_manifest_lint.v1"
             )

    assert Enum.any?(
             stale_unsupported_output_report["errors"],
             &(&1["path"] == "$.outputs")
           )
  end

  test "verifies curated approval requirement reference fixtures" do
    fixture_id = "fixture.artifact.approval_requirement.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.approval_requirement.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = approval_requirement_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               approval_requirement_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      approval_requirement_fixture_observations()
      |> Map.put("required_authority", "mission_planning_authority")

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "required_authority" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "approval_requirement.v1",
             report
           ) == Validation.artifact_observations("approval_requirement.v1", report)

    assert {:ok, %{"schema_contract" => "approval_requirement.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "approval_requirement.v1"
             )

    stale_decision_classification =
      put_in(report, ["policy_decision", "classification"], "auto_approvable")

    assert {:error, stale_decision_classification_report} =
             Schema.validate_artifact(stale_decision_classification,
               schema_contract: "approval_requirement.v1"
             )

    assert Enum.any?(
             stale_decision_classification_report["errors"],
             &(&1["path"] == "$.policy_decision.classification")
           )

    stale_decision_policy_bundle =
      put_in(report, ["policy_decision", "policy_bundle_id"], "other_policy_bundle")

    assert {:error, stale_decision_policy_bundle_report} =
             Schema.validate_artifact(stale_decision_policy_bundle,
               schema_contract: "approval_requirement.v1"
             )

    assert Enum.any?(
             stale_decision_policy_bundle_report["errors"],
             &(&1["path"] == "$.policy_decision.policy_bundle_id")
           )

    stale_rule_matches = Map.put(report, "approval_rule_matches", [])

    assert {:error, stale_rule_matches_report} =
             Schema.validate_artifact(stale_rule_matches,
               schema_contract: "approval_requirement.v1"
             )

    assert Enum.any?(
             stale_rule_matches_report["errors"],
             &(&1["path"] == "$.approval_rule_matches")
           )

    stale_escalations = put_in(report, ["policy_decision", "escalations"], [])

    assert {:error, stale_escalations_report} =
             Schema.validate_artifact(stale_escalations,
               schema_contract: "approval_requirement.v1"
             )

    assert Enum.any?(
             stale_escalations_report["errors"],
             &(&1["path"] == "$.policy_decision.escalations")
           )
  end

  test "verifies curated policy decision reference fixtures" do
    fixture_id = "fixture.artifact.policy_decision.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.policy_decision.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = policy_decision_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               policy_decision_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      policy_decision_fixture_observations()
      |> Map.put("classification", "approved")

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "classification" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "policy_decision.v1",
             report
           ) == Validation.artifact_observations("policy_decision.v1", report)

    assert {:ok, %{"schema_contract" => "policy_decision.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "policy_decision.v1"
             )

    stale_classification = Map.put(report, "classification", "auto_approvable")

    assert {:error, stale_classification_report} =
             Schema.validate_artifact(stale_classification,
               schema_contract: "policy_decision.v1"
             )

    assert Enum.any?(
             stale_classification_report["errors"],
             &(&1["path"] == "$.classification")
           )

    stale_approval_requirement_count = Map.put(report, "approval_requirement_count", 0)

    assert {:error, stale_approval_requirement_count_report} =
             Schema.validate_artifact(stale_approval_requirement_count,
               schema_contract: "policy_decision.v1"
             )

    assert Enum.any?(
             stale_approval_requirement_count_report["errors"],
             &(&1["path"] == "$.approval_requirement_count")
           )

    stale_risk_count = Map.put(report, "risk_count", 1)

    assert {:error, stale_risk_count_report} =
             Schema.validate_artifact(stale_risk_count,
               schema_contract: "policy_decision.v1"
             )

    assert Enum.any?(
             stale_risk_count_report["errors"],
             &(&1["path"] == "$.risk_count")
           )

    stale_escalation_rule_id =
      put_in(report, ["escalations", Access.at(0), "rule_id"], "other_rule")

    assert {:error, stale_escalation_rule_id_report} =
             Schema.validate_artifact(stale_escalation_rule_id,
               schema_contract: "policy_decision.v1"
             )

    assert Enum.any?(
             stale_escalation_rule_id_report["errors"],
             &(&1["path"] == "$.escalations")
           )

    stale_model_limits =
      Map.put(report, "model_limits", Enum.drop(Map.fetch!(report, "model_limits"), 1))

    assert {:error, stale_model_limits_report} =
             Schema.validate_artifact(stale_model_limits,
               schema_contract: "policy_decision.v1"
             )

    assert Enum.any?(
             stale_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits")
           )
  end

  test "verifies curated resource pressure handoff reference fixtures" do
    fixtures = [
      {
        "fixture.artifact.quality_gate_report.resource_pressure_v1",
        "quality_gate_report.v1",
        quality_gate_resource_pressure_fixture(),
        quality_gate_resource_pressure_fixture_observations()
      },
      {
        "fixture.artifact.operational_readiness_report.resource_pressure_v1",
        "operational_readiness_report.v1",
        operational_readiness_resource_pressure_fixture(),
        operational_readiness_resource_pressure_fixture_observations()
      },
      {
        "fixture.artifact.operator_review_package.resource_pressure_v1",
        "operator_review_package.v1",
        operator_review_resource_pressure_fixture(),
        operator_review_resource_pressure_fixture_observations()
      },
      {
        "fixture.artifact.cadence_import_manifest.resource_pressure_v1",
        "cadence_import_manifest.v1",
        cadence_import_resource_pressure_fixture(),
        cadence_import_resource_pressure_fixture_observations()
      }
    ]

    for {fixture_id, contract, artifact, observations} <- fixtures do
      assert {:ok, fixture} = Validation.reference_fixture(fixture_id)
      assert fixture["fixture_type"] == "curated_internal_artifact_regression"

      assert {:ok, verification} =
               Validation.verify_reference_fixture(fixture_id, observations)

      assert verification["status"] == "pass"
      assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

      assert {:ok, _schema_report} =
               Schema.validate_artifact(artifact, schema_contract: contract)

      assert OrbitalDynamics.validation_artifact_observations(contract, artifact) ==
               Validation.artifact_observations(contract, artifact)
    end

    quality_gate_observations = quality_gate_resource_pressure_fixture_observations()

    assert quality_gate_observations["resource_availability_gate_count"] == 1
    assert quality_gate_observations["row_derived_resource_availability_pressure_count"] == 2

    assert quality_gate_observations["row_derived_resource_availability_reason_counts"] == %{
             "antenna_unavailable" => 1,
             "payload_unavailable" => 1
           }

    readiness_observations = operational_readiness_resource_pressure_fixture_observations()

    assert readiness_observations["resource_availability_pressure_count"] == 2

    assert readiness_observations["row_derived_resource_availability_reason_keys"] ==
             "antenna_unavailable|payload_unavailable"

    review_observations = operator_review_resource_pressure_fixture_observations()

    assert review_observations["resource_availability_review_row_count"] == 2
    assert review_observations["row_derived_resource_availability_pressure_count"] == 4

    import_observations = cadence_import_resource_pressure_fixture_observations()

    assert import_observations["resource_availability_import_row_count"] == 2
    assert import_observations["row_derived_resource_availability_pressure_count"] == 4

    stale_quality_gate_observations =
      quality_gate_observations
      |> Map.put("resource_availability_gate_count", 0)

    assert {:ok, stale_quality_gate_verification} =
             Validation.verify_reference_fixture(
               "fixture.artifact.quality_gate_report.resource_pressure_v1",
               stale_quality_gate_observations
             )

    assert stale_quality_gate_verification["status"] == "fail"

    assert Enum.any?(
             stale_quality_gate_verification["checks"],
             &(&1["field"] == "resource_availability_gate_count" and &1["status"] == "fail")
           )

    stale_readiness_observations =
      readiness_observations
      |> Map.put("resource_availability_pressure_count", 0)

    assert {:ok, stale_readiness_verification} =
             Validation.verify_reference_fixture(
               "fixture.artifact.operational_readiness_report.resource_pressure_v1",
               stale_readiness_observations
             )

    assert stale_readiness_verification["status"] == "fail"

    assert Enum.any?(
             stale_readiness_verification["checks"],
             &(&1["field"] == "resource_availability_pressure_count" and
                 &1["status"] == "fail")
           )

    stale_review_observations =
      review_observations
      |> Map.put("resource_availability_review_row_count", 1)

    assert {:ok, stale_review_verification} =
             Validation.verify_reference_fixture(
               "fixture.artifact.operator_review_package.resource_pressure_v1",
               stale_review_observations
             )

    assert stale_review_verification["status"] == "fail"

    assert Enum.any?(
             stale_review_verification["checks"],
             &(&1["field"] == "resource_availability_review_row_count" and
                 &1["status"] == "fail")
           )

    stale_import_observations =
      import_observations
      |> put_in(["row_derived_resource_availability_reason_counts", "antenna_unavailable"], 1)

    assert {:ok, stale_import_verification} =
             Validation.verify_reference_fixture(
               "fixture.artifact.cadence_import_manifest.resource_pressure_v1",
               stale_import_observations
             )

    assert stale_import_verification["status"] == "fail"

    assert Enum.any?(
             stale_import_verification["checks"],
             &(&1["field"] == "row_derived_resource_availability_reason_counts" and
                 &1["status"] == "fail")
           )
  end

  test "verifies curated contact allocation report reference fixtures" do
    fixture_id = "fixture.artifact.contact_allocation_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.contact_allocation_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = contact_allocation_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               contact_allocation_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      contact_allocation_report_fixture_observations()
      |> Map.put("blocked_contact_count", 2)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "blocked_contact_count" and &1["status"] == "fail")
           )

    stale_row_derived_count_observations =
      contact_allocation_report_fixture_observations()
      |> Map.put("row_derived_blocked_contact_count", 2)

    assert {:ok, stale_row_derived_count_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_row_derived_count_observations)

    assert stale_row_derived_count_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_count_verification["checks"],
             &(&1["field"] == "row_derived_blocked_contact_count" and
                 &1["status"] == "fail")
           )

    stale_row_derived_observations =
      contact_allocation_report_fixture_observations()
      |> put_in(["row_derived_allocation_reason_counts", "ground_station_reserved"], 0)

    assert {:ok, stale_row_derived_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_row_derived_observations)

    assert stale_row_derived_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_verification["checks"],
             &(&1["field"] == "row_derived_allocation_reason_counts" and
                 &1["status"] == "fail")
           )

    stale_reservation_observations =
      contact_allocation_report_fixture_observations()
      |> Map.put("row_derived_station_reservation_id_counts", %{})

    assert {:ok, stale_reservation_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_reservation_observations)

    assert stale_reservation_verification["status"] == "fail"

    assert Enum.any?(
             stale_reservation_verification["checks"],
             &(&1["field"] == "row_derived_station_reservation_id_counts" and
                 &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "contact_allocation_report.v1",
             report
           ) ==
             Validation.artifact_observations("contact_allocation_report.v1", report)

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "contact_allocation_report.v1"
             )

    stale_allocation_status_counts =
      put_in(report, ["allocation_status_counts", "blocked"], 2)

    assert {:error, stale_allocation_status_counts_report} =
             Schema.validate_artifact(stale_allocation_status_counts,
               schema_contract: "contact_allocation_report.v1"
             )

    assert Enum.any?(
             stale_allocation_status_counts_report["errors"],
             &(&1["path"] == "$.allocation_status_counts")
           )

    stale_allocation_reason_counts =
      put_in(report, ["allocation_reason_counts", "ground_station_reserved"], 0)

    assert {:error, stale_allocation_reason_counts_report} =
             Schema.validate_artifact(stale_allocation_reason_counts,
               schema_contract: "contact_allocation_report.v1"
             )

    assert Enum.any?(
             stale_allocation_reason_counts_report["errors"],
             &(&1["path"] == "$.allocation_reason_counts")
           )

    stale_reservation_match_status_counts =
      put_in(report, ["station_reservation_match_status_counts", "overlap"], 0)

    assert {:error, stale_reservation_match_status_counts_report} =
             Schema.validate_artifact(stale_reservation_match_status_counts,
               schema_contract: "contact_allocation_report.v1"
             )

    assert Enum.any?(
             stale_reservation_match_status_counts_report["errors"],
             &(&1["path"] == "$.station_reservation_match_status_counts")
           )

    stale_reservation_ids = Map.put(report, "station_reservation_ids", [])

    assert {:error, stale_reservation_ids_report} =
             Schema.validate_artifact(stale_reservation_ids,
               schema_contract: "contact_allocation_report.v1"
             )

    assert Enum.any?(
             stale_reservation_ids_report["errors"],
             &(&1["path"] == "$.station_reservation_ids")
           )
  end

  test "verifies curated reservation conflict summary reference fixtures" do
    fixture_id = "fixture.artifact.contact_allocation_reservation_conflict_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] ==
             "artifact.contact_allocation_reservation_conflict_summary.v1"

    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    summary = read_json!("study_results/contact_allocation_reservation_conflict_summary_v1.json")

    observations =
      Validation.artifact_observations(
        "contact_allocation_reservation_conflict_summary.v1",
        summary
      )

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               observations
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_conflict_direction_station_observations =
      observations
      |> put_in(
        [
          "row_derived_reservation_conflict_contact_ids_by_direction_and_ground_station_id",
          "downlink",
          "equator_prime"
        ],
        ["stale_contact"]
      )

    assert {:ok, stale_conflict_direction_station_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_conflict_direction_station_observations
             )

    assert stale_conflict_direction_station_verification["status"] == "fail"

    assert Enum.any?(
             stale_conflict_direction_station_verification["checks"],
             &(&1["field"] ==
                 "row_derived_reservation_conflict_contact_ids_by_direction_and_ground_station_id" and
                 &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "contact_allocation_reservation_conflict_summary.v1",
             summary
           ) == observations

    assert {:ok, %{"schema_contract" => "contact_allocation_reservation_conflict_summary.v1"}} =
             Schema.validate_artifact(summary)
  end

  test "verifies curated station pressure summary reference fixtures" do
    fixture_id = "fixture.artifact.contact_allocation_station_pressure_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.contact_allocation_station_pressure_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    summary = read_json!("study_results/contact_allocation_station_pressure_summary_v1.json")

    observations =
      Validation.artifact_observations(
        "contact_allocation_station_pressure_summary.v1",
        summary
      )

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               observations
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_station_direction_observations =
      observations
      |> put_in(
        [
          "row_derived_station_pressure_contact_ids_by_direction_and_ground_station_id",
          "downlink",
          "equator_prime"
        ],
        ["stale_contact"]
      )

    assert {:ok, stale_station_direction_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_station_direction_observations
             )

    assert stale_station_direction_verification["status"] == "fail"

    assert Enum.any?(
             stale_station_direction_verification["checks"],
             &(&1["field"] ==
                 "row_derived_station_pressure_contact_ids_by_direction_and_ground_station_id" and
                 &1["status"] == "fail")
           )

    stale_station_status_observations =
      put_in(
        observations,
        ["row_derived_station_pressure_contact_ids_by_status", "reserved"],
        ["stale_contact"]
      )

    assert {:ok, stale_station_status_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_station_status_observations
             )

    assert stale_station_status_verification["status"] == "fail"

    assert Enum.any?(
             stale_station_status_verification["checks"],
             &(&1["field"] == "row_derived_station_pressure_contact_ids_by_status" and
                 &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "contact_allocation_station_pressure_summary.v1",
             summary
           ) == observations

    assert {:ok, %{"schema_contract" => "contact_allocation_station_pressure_summary.v1"}} =
             Schema.validate_artifact(summary)
  end

  test "verifies curated capacity pack summary reference fixtures" do
    fixture_id = "fixture.artifact.contact_allocation_capacity_pack_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.contact_allocation_capacity_pack_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    summary = read_json!("study_results/contact_allocation_capacity_pack_summary_v1.json")

    observations =
      Validation.artifact_observations(
        "contact_allocation_capacity_pack_summary.v1",
        summary
      )

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               observations
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_capacity_status_observations =
      observations
      |> put_in(
        [
          "row_derived_capacity_pack_contact_ids_by_status",
          "deferred_by_reduced_station_capacity_pack"
        ],
        []
      )

    assert {:ok, stale_capacity_status_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_capacity_status_observations
             )

    assert stale_capacity_status_verification["status"] == "fail"

    assert Enum.any?(
             stale_capacity_status_verification["checks"],
             &(&1["field"] == "row_derived_capacity_pack_contact_ids_by_status" and
                 &1["status"] == "fail")
           )

    stale_group_status_observations =
      observations
      |> put_in(
        [
          "row_derived_reduced_capacity_pack_group_ids_by_status",
          "capacity_limited"
        ],
        []
      )

    assert {:ok, stale_group_status_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_group_status_observations
             )

    assert stale_group_status_verification["status"] == "fail"

    assert Enum.any?(
             stale_group_status_verification["checks"],
             &(&1["field"] == "row_derived_reduced_capacity_pack_group_ids_by_status" and
                 &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "contact_allocation_capacity_pack_summary.v1",
             summary
           ) == observations

    assert {:ok, %{"schema_contract" => "contact_allocation_capacity_pack_summary.v1"}} =
             Schema.validate_artifact(summary)
  end

  test "verifies curated contact allocation summary reference fixtures" do
    fixture_id = "fixture.artifact.contact_allocation_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.contact_allocation_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    summary = read_json!("study_results/contact_allocation_summary_v1.json")

    observations =
      Validation.artifact_observations(
        "contact_allocation_summary.v1",
        summary
      )

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               observations
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_allocation_status_observations =
      observations
      |> put_in(
        [
          "row_derived_contact_ids_by_effective_allocation_status",
          "blocked"
        ],
        []
      )

    assert {:ok, stale_allocation_status_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_allocation_status_observations
             )

    assert stale_allocation_status_verification["status"] == "fail"

    assert Enum.any?(
             stale_allocation_status_verification["checks"],
             &(&1["field"] == "row_derived_contact_ids_by_effective_allocation_status" and
                 &1["status"] == "fail")
           )

    stale_station_pressure_observations =
      observations
      |> put_in(
        [
          "row_derived_station_pressure_contact_ids_by_ground_station_id",
          "equator_prime"
        ],
        []
      )

    assert {:ok, stale_station_pressure_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_station_pressure_observations
             )

    assert stale_station_pressure_verification["status"] == "fail"

    assert Enum.any?(
             stale_station_pressure_verification["checks"],
             &(&1["field"] == "row_derived_station_pressure_contact_ids_by_ground_station_id" and
                 &1["status"] == "fail")
           )

    stale_station_pressure_status_observations =
      put_in(
        observations,
        ["row_derived_station_pressure_contact_ids_by_status", "reserved"],
        []
      )

    assert {:ok, stale_station_pressure_status_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_station_pressure_status_observations
             )

    assert stale_station_pressure_status_verification["status"] == "fail"

    assert Enum.any?(
             stale_station_pressure_status_verification["checks"],
             &(&1["field"] == "row_derived_station_pressure_contact_ids_by_status" and
                 &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "contact_allocation_summary.v1",
             summary
           ) == observations

    assert {:ok, %{"schema_contract" => "contact_allocation_summary.v1"}} =
             Schema.validate_artifact(summary)
  end

  test "fails reference fixture verification outside declared tolerances" do
    observations =
      two_body_fixture_observations()
      |> Map.update!("final_position_km", fn [x, y, z] -> [x + 0.01, y, z] end)

    assert {:ok, %{"status" => "fail", "checks" => checks}} =
             Validation.verify_reference_fixture(
               "fixture.two_body.circular_leo_600s",
               observations
             )

    assert %{"status" => "fail", "max_abs_error" => error, "tolerance" => tolerance} =
             Enum.find(checks, &(&1["field"] == "final_position_km"))

    assert error > tolerance
  end

  test "builds deterministic reference fixture reports" do
    report =
      Validation.reference_fixture_report(%{
        "fixture.event.access.equator_overhead_120s" => access_fixture_observations(),
        "fixture.event.eclipse.cylindrical_shadow_120s" => eclipse_fixture_observations(),
        "fixture.event.target_visibility.equator_overhead_120s" =>
          target_visibility_fixture_observations(),
        "fixture.event.ground_track.latitude_equator_60s" =>
          ground_track_crossing_fixture_observations(),
        "fixture.artifact.accepted_planning_state.oem" =>
          accepted_planning_state_oem_fixture_observations(),
        "fixture.artifact.accepted_planning_state.opm" =>
          accepted_planning_state_opm_fixture_observations(),
        "fixture.artifact.accepted_planning_state.simple" =>
          accepted_planning_state_fixture_observations(),
        "fixture.artifact.activity_template.v1" => activity_template_fixture_observations(),
        "fixture.artifact.approval_requirement.v1" => approval_requirement_fixture_observations(),
        "fixture.artifact.backend_acceptance_policy.v1" =>
          backend_acceptance_policy_fixture_observations(),
        "fixture.artifact.branch_comparison_report.v1" =>
          branch_comparison_report_fixture_observations(),
        "fixture.artifact.cadence_import_manifest.v1" =>
          cadence_import_manifest_fixture_observations(),
        "fixture.artifact.cadence_import_manifest.resource_pressure_v1" =>
          cadence_import_resource_pressure_fixture_observations(),
        "fixture.artifact.cadence_import_manifest.resource_projection_battery_handoff_v1" =>
          cadence_import_resource_projection_battery_handoff_fixture_observations(),
        "fixture.artifact.campaign_plan.leo_constellation_v1" =>
          campaign_plan_fixture_observations(),
        "fixture.artifact.campaign_repair.leo_constellation_v2" =>
          campaign_repair_fixture_observations(),
        "fixture.artifact.campaign_request_lint.v1" =>
          campaign_request_lint_fixture_observations(),
        "fixture.artifact.campaign_strategy.leo_constellation_v3" =>
          campaign_strategy_fixture_observations(),
        "fixture.artifact.capability_catalog.v1" => capability_catalog_fixture_observations(),
        "fixture.artifact.candidate_activity.v1" => candidate_activity_fixture_observations(),
        "fixture.artifact.candidate_diff_report.v1" =>
          candidate_diff_report_fixture_observations(),
        "fixture.artifact.candidate_diff_row.v1" => candidate_diff_row_fixture_observations(),
        "fixture.artifact.candidate_refresh.v1" => candidate_refresh_fixture_observations(),
        "fixture.artifact.candidate_refresh.candidate_rejection_replay" =>
          candidate_refresh_candidate_rejection_fixture_observations(),
        "fixture.artifact.candidate_refresh.contact_contention_cross_station_replay" =>
          candidate_refresh_contact_contention_challenge_fixture_observations(),
        "fixture.artifact.candidate_refresh.contact_allocation_contradiction_replay" =>
          candidate_refresh_contact_allocation_contradiction_fixture_observations(),
        "fixture.artifact.candidate_refresh.contact_filter_replay" =>
          candidate_refresh_contact_filter_fixture_observations(),
        "fixture.artifact.candidate_refresh.contact_intent_direction_replay" =>
          candidate_refresh_contact_intent_direction_fixture_observations(),
        "fixture.artifact.candidate_refresh.constraint_replay" =>
          candidate_refresh_constraint_fixture_observations(),
        "fixture.artifact.candidate_refresh.freshness_replay" =>
          candidate_refresh_freshness_fixture_observations(),
        "fixture.artifact.candidate_refresh.link_capacity_replay" =>
          candidate_refresh_link_capacity_fixture_observations(),
        "fixture.artifact.candidate_refresh.operational_readiness_replay" =>
          candidate_refresh_operational_readiness_fixture_observations(),
        "fixture.artifact.candidate_refresh.timeline_activity_precondition_replay" =>
          candidate_refresh_timeline_activity_precondition_fixture_observations(),
        "fixture.artifact.candidate_refresh.timeline_activity_lifecycle_replay" =>
          candidate_refresh_timeline_activity_lifecycle_fixture_observations(),
        "fixture.artifact.candidate_refresh.timeline_lifecycle_state_replay" =>
          candidate_refresh_timeline_lifecycle_state_fixture_observations(),
        "fixture.artifact.candidate_refresh.resource_projection_replay" =>
          candidate_refresh_resource_projection_fixture_observations(),
        "fixture.artifact.candidate_refresh.timeline_transition_application_replay" =>
          candidate_refresh_timeline_transition_application_fixture_observations(),
        "fixture.artifact.candidate_refresh.objective_gap_replay" =>
          candidate_refresh_objective_gap_fixture_observations(),
        "fixture.artifact.candidate_refresh.quality_gate_replay" =>
          candidate_refresh_quality_gate_fixture_observations(),
        "fixture.artifact.candidate_refresh.refresh_budget_replay" =>
          candidate_refresh_refresh_budget_fixture_observations(),
        "fixture.artifact.candidate_refresh.resource_filter_replay" =>
          candidate_refresh_resource_filter_fixture_observations(),
        "fixture.artifact.candidate_refresh.station_calendar_replay" =>
          candidate_refresh_station_calendar_fixture_observations(),
        "fixture.artifact.candidate_refresh.resource_provenance_v1" =>
          candidate_refresh_resource_provenance_fixture_observations(),
        "fixture.artifact.candidate_rejection_report.v1" =>
          candidate_rejection_report_fixture_observations(),
        "fixture.artifact.command_window_report.v1" =>
          command_window_report_fixture_observations(),
        "fixture.artifact.constraint_report.v1" => constraint_report_fixture_observations(),
        "fixture.artifact.contact_allocation_report.reduced_capacity_pack" =>
          contact_allocation_capacity_pack_report_fixture_observations(),
        "fixture.artifact.contact_allocation_capacity_pack_summary.v1" =>
          contact_allocation_capacity_pack_summary_fixture_observations(),
        "fixture.artifact.contact_allocation_summary.v1" =>
          contact_allocation_summary_fixture_observations(),
        "fixture.artifact.contact_allocation_report.v1" =>
          contact_allocation_report_fixture_observations(),
        "fixture.artifact.contact_allocation_reservation_conflict_summary.v1" =>
          contact_allocation_reservation_conflict_summary_fixture_observations(),
        "fixture.artifact.contact_allocation_station_pressure_summary.v1" =>
          contact_allocation_station_pressure_summary_fixture_observations(),
        "fixture.artifact.contact_allocation_provider_reservation_request_summary.v1" =>
          contact_allocation_provider_reservation_request_summary_fixture_observations(),
        "fixture.artifact.contact_contention_report.v1" =>
          contact_contention_report_fixture_observations(),
        "fixture.artifact.contact_contention_report.cross_station_spacecraft" =>
          contact_contention_cross_station_fixture_observations(),
        "fixture.artifact.contact_contention_resolution_report.v1" =>
          contact_contention_resolution_report_fixture_observations(),
        "fixture.artifact.contact_contention_resolution_summary.v1" =>
          contact_contention_resolution_summary_fixture_observations(),
        "fixture.artifact.contact_filter_report.v1" =>
          contact_filter_report_fixture_observations(),
        "fixture.artifact.contact_intent.v1" => contact_intent_fixture_observations(),
        "fixture.artifact.contact_intent_summary.v1" =>
          contact_intent_summary_fixture_observations(),
        "fixture.artifact.environment_model_capability.constant_earth_rotation" =>
          environment_model_capability_constant_earth_rotation_fixture_observations(),
        "fixture.artifact.environment_model_capability.fixed_sun" =>
          environment_model_capability_fixed_sun_fixture_observations(),
        "fixture.artifact.environment_provider_capability.constant_earth_rotation" =>
          environment_provider_capability_constant_earth_rotation_fixture_observations(),
        "fixture.artifact.environment_provider_capability.exponential_atmosphere" =>
          environment_provider_capability_exponential_atmosphere_fixture_observations(),
        "fixture.artifact.environment_provider_capability.fixed_sun" =>
          environment_provider_capability_fixed_sun_fixture_observations(),
        "fixture.artifact.environment_provider_capability.tabular_earth_orientation" =>
          environment_provider_capability_tabular_earth_orientation_fixture_observations(),
        "fixture.artifact.execution_report.v1" => execution_report_fixture_observations(),
        "fixture.artifact.freshness_report.v1" => freshness_report_fixture_observations(),
        "fixture.artifact.invalidated_candidate.v1" =>
          invalidated_candidate_fixture_observations(),
        "fixture.artifact.link_capacity_report.v1" => link_capacity_report_fixture_observations(),
        "fixture.artifact.link_capacity_summary.v1" =>
          link_capacity_summary_fixture_observations(),
        "fixture.artifact.relay_data_path_summary.v1" =>
          relay_data_path_summary_fixture_observations(),
        "fixture.artifact.maneuver_execution_delta.v1" =>
          maneuver_execution_delta_fixture_observations(),
        "fixture.artifact.maneuver_review_report.v1" =>
          maneuver_review_report_fixture_observations(),
        "fixture.artifact.maneuver_recommendation.v1" =>
          maneuver_recommendation_fixture_observations(),
        "fixture.artifact.manifest_field_reference.v1" =>
          manifest_field_reference_fixture_observations(),
        "fixture.artifact.model_acceptance_report.operational_import" =>
          model_acceptance_report_fixture_observations(),
        "fixture.artifact.monte_carlo_reproducibility_report.v1" =>
          monte_carlo_reproducibility_report_fixture_observations(),
        "fixture.artifact.objective_satisfaction_report.v1" =>
          objective_satisfaction_report_fixture_observations(),
        "fixture.artifact.objective_tradeoff_report.v1" =>
          objective_tradeoff_report_fixture_observations(),
        "fixture.artifact.ranking_comparison_report.v1" =>
          ranking_comparison_report_fixture_observations(),
        "fixture.artifact.realized_activity.v1" => realized_activity_fixture_observations(),
        "fixture.artifact.realized_state_snapshot.v1" =>
          realized_state_snapshot_fixture_observations(),
        "fixture.artifact.refresh_budget_report.v1" =>
          refresh_budget_report_fixture_observations(),
        "fixture.artifact.refreshed_window.v1" => refreshed_window_fixture_observations(),
        "fixture.artifact.remaining_horizon.v1" => remaining_horizon_fixture_observations(),
        "fixture.artifact.pareto_frontier_report.v1" =>
          pareto_frontier_report_fixture_observations(),
        "fixture.artifact.plan_delta.v1" => plan_delta_fixture_observations(),
        "fixture.artifact.planned_activity.v1" => planned_activity_fixture_observations(),
        "fixture.artifact.policy_bundle.command_contact_authority" =>
          command_contact_policy_bundle_fixture_observations(),
        "fixture.artifact.policy_bundle.conservative_ops" =>
          conservative_policy_bundle_fixture_observations(),
        "fixture.artifact.policy_bundle.contact_command_review" =>
          contact_command_review_policy_bundle_fixture_observations(),
        "fixture.artifact.policy_bundle.default" => default_policy_bundle_fixture_observations(),
        "fixture.artifact.policy_bundle.degraded_payload_guard" =>
          degraded_payload_guard_policy_bundle_fixture_observations(),
        "fixture.artifact.policy_bundle.ground_network_allocation" =>
          ground_network_policy_bundle_fixture_observations(),
        "fixture.artifact.policy_bundle.maneuver_authority" =>
          maneuver_authority_policy_bundle_fixture_observations(),
        "fixture.artifact.policy_bundle.operator_review_queue_authority" =>
          operator_review_queue_policy_bundle_fixture_observations(),
        "fixture.artifact.policy_bundle.organization_adapter" =>
          organization_adapter_policy_bundle_fixture_observations(),
        "fixture.artifact.policy_bundle.resource_projection_authority" =>
          resource_projection_authority_policy_bundle_fixture_observations(),
        "fixture.artifact.policy_bundle.timeline_protection" =>
          timeline_protection_policy_bundle_fixture_observations(),
        "fixture.artifact.policy_bundle.v1" => policy_bundle_fixture_observations(),
        "fixture.artifact.policy_decision.v1" => policy_decision_fixture_observations(),
        "fixture.artifact.proposed_contact.v1" => proposed_contact_fixture_observations(),
        "fixture.artifact.validation_safety_case_summary.v1" =>
          validation_safety_case_summary_fixture_observations(),
        "fixture.artifact.operator_review_package.v1" =>
          operator_review_package_fixture_observations(),
        "fixture.artifact.operator_review_package.resource_pressure_v1" =>
          operator_review_resource_pressure_fixture_observations(),
        "fixture.artifact.operator_review_package.resource_projection_battery_handoff_v1" =>
          operator_review_resource_projection_battery_handoff_fixture_observations(),
        "fixture.artifact.operational_execution_boundary_summary.v1" =>
          operational_execution_boundary_summary_fixture_observations(),
        "fixture.artifact.operational_import_eligibility_summary.v1" =>
          operational_import_eligibility_summary_fixture_observations(),
        "fixture.artifact.operational_readiness_report.v1" =>
          operational_readiness_report_fixture_observations(),
        "fixture.artifact.operational_readiness_report.resource_pressure_v1" =>
          operational_readiness_resource_pressure_fixture_observations(),
        "fixture.artifact.operational_readiness_gate_summary.v1" =>
          operational_readiness_gate_summary_fixture_observations(),
        "fixture.artifact.operational_quality_gate_summary.v1" =>
          operational_quality_gate_summary_fixture_observations(),
        "fixture.artifact.operational_quality_gate_import_readiness_summary.v1" =>
          operational_quality_gate_import_readiness_summary_fixture_observations(),
        "fixture.artifact.operational_quality_gate_unavailable_resource_summary.v1" =>
          operational_quality_gate_unavailable_resource_summary_fixture_observations(),
        "fixture.artifact.operational_quality_gate_unavailable_resource_summary.resource_projection_v1" =>
          operational_quality_gate_unavailable_resource_summary_checked_in_observations(),
        "fixture.artifact.operational_quality_gate_operator_training_summary.v1" =>
          operational_quality_gate_operator_training_summary_fixture_observations(),
        "fixture.artifact.operational_quality_gate_schema_validation_summary.v1" =>
          operational_quality_gate_schema_validation_summary_fixture_observations(),
        "fixture.artifact.operational_timeline_report.v1" =>
          operational_timeline_report_fixture_observations(),
        "fixture.artifact.optimizer_contract.v1" => optimizer_contract_fixture_observations(),
        "fixture.artifact.provider_counteroffer_import_readiness_summary.v1" =>
          provider_counteroffer_import_readiness_summary_fixture_observations(),
        "fixture.artifact.provider_counteroffer_plan_impact_summary.v1" =>
          provider_counteroffer_plan_impact_summary_fixture_observations(),
        "fixture.artifact.provider_counteroffer_report.v1" =>
          provider_counteroffer_report_fixture_observations(),
        "fixture.artifact.provider_counteroffer_review_summary.v1" =>
          provider_counteroffer_review_summary_fixture_observations(),
        "fixture.artifact.quality_gate_report.v1" => quality_gate_report_fixture_observations(),
        "fixture.artifact.quality_gate_report.resource_pressure_v1" =>
          quality_gate_resource_pressure_fixture_observations(),
        "fixture.artifact.resource_filter_report.v1" =>
          resource_filter_report_fixture_observations(),
        "fixture.artifact.resource_filter_summary.v1" =>
          resource_filter_summary_fixture_observations(),
        "fixture.artifact.resource_filter_report.stale_resource_summary_margins" =>
          resource_filter_stale_margin_fixture_observations(),
        "fixture.artifact.resource_projection_report.v1" =>
          resource_projection_report_fixture_observations(),
        "fixture.artifact.resource_projection_flow_summary.v1" =>
          resource_projection_flow_summary_fixture_observations(),
        "fixture.artifact.resource_projection_report.battery_handoff_v1" =>
          resource_projection_battery_handoff_fixture_observations(),
        "fixture.artifact.resource_projection_report.stale_resource_summary_margins" =>
          resource_projection_stale_margin_fixture_observations(),
        "fixture.artifact.resource_summary.v1" => resource_summary_fixture_observations(),
        "fixture.artifact.result_artifact.candidate_refresh_v1" =>
          candidate_refresh_result_artifact_fixture_observations(),
        "fixture.artifact.result_artifact.candidate_refresh_orbit_data_v1" =>
          candidate_refresh_orbit_data_result_artifact_fixture_observations(),
        "fixture.artifact.result_artifact.ground_track_crossings" =>
          ground_track_result_artifact_fixture_observations(),
        "fixture.artifact.result_artifact.leo_access_demo" =>
          leo_access_result_artifact_fixture_observations(),
        "fixture.artifact.result_artifact.leo_access_demo_manifest" =>
          leo_access_manifest_result_artifact_fixture_observations(),
        "fixture.artifact.result_artifact.leo_constellation_campaign" =>
          result_artifact_fixture_observations(),
        "fixture.artifact.result_artifact.leo_dispersion_monte_carlo" =>
          monte_carlo_result_artifact_fixture_observations(),
        "fixture.artifact.result_artifact.mission_plan_checkout" =>
          mission_plan_checkout_result_artifact_fixture_observations(),
        "fixture.artifact.result_artifact.raise_apogee_search" =>
          raise_apogee_result_artifact_fixture_observations(),
        "fixture.artifact.score_term_report.v1" => score_term_report_fixture_observations(),
        "fixture.artifact.schema_validation_batch_report.v1" =>
          schema_validation_batch_report_fixture_observations(),
        "fixture.artifact.schema_validation_report.v1" =>
          schema_validation_report_fixture_observations(),
        "fixture.artifact.schema_migration_report.deprecated_campaign_plan" =>
          schema_migration_report_fixture_observations(),
        "fixture.artifact.schema_migration_report.future_campaign_plan" =>
          schema_migration_future_contract_fixture_observations(),
        "fixture.artifact.source_window_lineage.v1" =>
          source_window_lineage_fixture_observations(),
        "fixture.artifact.spacecraft_state_estimate.v1" =>
          spacecraft_state_estimate_fixture_observations(),
        "fixture.artifact.station_calendar_precedence_summary.v1" =>
          station_calendar_precedence_summary_fixture_observations(),
        "fixture.artifact.station_calendar_provider.v1" =>
          station_calendar_provider_fixture_observations(),
        "fixture.artifact.station_calendar_report.stale_provider_reservation_hold" =>
          station_calendar_report_fixture_observations(),
        "fixture.artifact.station_reservation_review_summary.v1" =>
          station_reservation_review_summary_fixture_observations(),
        "fixture.artifact.station_reservation_hold_summary.v1" =>
          station_reservation_hold_summary_fixture_observations(),
        "fixture.artifact.station_reservation_hold_import_readiness_summary.v1" =>
          station_reservation_hold_import_readiness_summary_fixture_observations(),
        "fixture.artifact.station_reservation_report.stale_provider_reservation_hold" =>
          station_reservation_report_fixture_observations(),
        "fixture.artifact.station_calendar_report.v1" =>
          checked_in_station_calendar_report_fixture_observations(),
        "fixture.artifact.strategy_branch.v1" => strategy_branch_fixture_observations(),
        "fixture.artifact.strategy_recommendation.v1" =>
          strategy_recommendation_fixture_observations(),
        "fixture.artifact.study_benchmark.distributed_concurrency_sweep" =>
          distributed_concurrency_benchmark_fixture_observations(),
        "fixture.artifact.study_benchmark.distributed_chunk_sweep" =>
          distributed_chunk_benchmark_fixture_observations(),
        "fixture.artifact.study_benchmark.distributed_diagnostic_sweep" =>
          distributed_diagnostic_benchmark_fixture_observations(),
        "fixture.artifact.study_benchmark.distributed_monte_carlo_chunked" =>
          distributed_monte_carlo_chunked_benchmark_fixture_observations(),
        "fixture.artifact.study_benchmark.distributed_monte_carlo_scaling" =>
          distributed_monte_carlo_scaling_benchmark_fixture_observations(),
        "fixture.artifact.study_benchmark.monte_carlo_scaling" =>
          monte_carlo_scaling_benchmark_fixture_observations(),
        "fixture.artifact.study_benchmark.nx_study_benchmark" =>
          nx_study_benchmark_fixture_observations(),
        "fixture.artifact.study_benchmark.v1" => study_benchmark_fixture_observations(),
        "fixture.artifact.study_manifest_lint.v1" => study_manifest_lint_fixture_observations(),
        "fixture.artifact.subsystem_model_capability.battery" =>
          subsystem_model_capability_fixture_observations(),
        "fixture.artifact.subsystem_model_capability.storage" =>
          subsystem_model_capability_storage_fixture_observations(),
        "fixture.artifact.timeline_activity_approval_state.v1" =>
          timeline_activity_approval_state_fixture_observations(),
        "fixture.artifact.timeline_activity_lifecycle_state.v1" =>
          timeline_activity_lifecycle_state_fixture_observations(),
        "fixture.artifact.timeline_activity_precondition_summary.v1" =>
          timeline_activity_precondition_summary_fixture_observations(),
        "fixture.artifact.timeline_activity_state.v1" =>
          timeline_activity_state_fixture_observations(),
        "fixture.artifact.timeline_activity_status_state.v1" =>
          timeline_activity_status_state_fixture_observations(),
        "fixture.artifact.timeline_dependency_impact_summary.v1" =>
          timeline_dependency_impact_summary_fixture_observations(),
        "fixture.artifact.timeline_diff_report.v1" => timeline_diff_report_fixture_observations(),
        "fixture.artifact.timeline_diff_summary.v1" =>
          timeline_diff_summary_fixture_observations(),
        "fixture.artifact.timeline_feedback_report.v1" =>
          timeline_feedback_report_fixture_observations(),
        "fixture.artifact.timeline_integrity_report.v1" =>
          timeline_integrity_report_fixture_observations(),
        "fixture.artifact.timeline_lifecycle_state_summary.v1" =>
          timeline_lifecycle_state_summary_fixture_observations(),
        "fixture.artifact.timeline_preservation_report.v1" =>
          timeline_preservation_report_fixture_observations(),
        "fixture.artifact.timeline_preservation_status.v1" =>
          timeline_preservation_status_fixture_observations(),
        "fixture.artifact.timeline_publication_summary.v1" =>
          timeline_publication_summary_fixture_observations(),
        "fixture.artifact.timeline_transition_application_report.v1" =>
          timeline_transition_application_report_fixture_observations(),
        "fixture.artifact.timeline_transition_application_selected_integrity.v1" =>
          timeline_transition_application_selected_integrity_fixture_observations(),
        "fixture.artifact.timeline_transition_application_selected_integrity_summary.v1" =>
          timeline_transition_application_selected_integrity_summary_fixture_observations(),
        "fixture.artifact.timeline_transition_application_summary.v1" =>
          timeline_transition_application_summary_fixture_observations(),
        "fixture.artifact.validation_check.v1" => validation_check_fixture_observations(),
        "fixture.artifact.validation_record.v1" => validation_record_fixture_observations(),
        "fixture.artifact.validation_reference_report.v1" =>
          validation_reference_report_fixture_observations(),
        "fixture.artifact.validation_tolerance_policy.v1" =>
          validation_tolerance_policy_fixture_observations(),
        "fixture.j2.circular_leo_600s" => j2_fixture_observations(),
        "fixture.two_body.circular_leo_600s" => two_body_fixture_observations()
      })

    assert %{
             "schema_contract" => "validation_reference_fixture_report.v1",
             "status" => "pass",
             "fixture_count" => 195,
             "status_counts" => %{"pass" => 195},
             "reports" => reports
           } = report

    checked_in_report = read_json!("study_results/validation_reference_fixtures.json")

    assert checked_in_report == report

    stale_checked_in_report =
      checked_in_report
      |> Map.update!("fixture_count", &(&1 - 1))

    refute stale_checked_in_report == report

    assert Enum.map(reports, & &1["fixture_id"]) == [
             "fixture.artifact.accepted_planning_state.oem",
             "fixture.artifact.accepted_planning_state.opm",
             "fixture.artifact.accepted_planning_state.simple",
             "fixture.artifact.activity_template.v1",
             "fixture.artifact.approval_requirement.v1",
             "fixture.artifact.backend_acceptance_policy.v1",
             "fixture.artifact.branch_comparison_report.v1",
             "fixture.artifact.cadence_import_manifest.resource_pressure_v1",
             "fixture.artifact.cadence_import_manifest.resource_projection_battery_handoff_v1",
             "fixture.artifact.cadence_import_manifest.v1",
             "fixture.artifact.campaign_plan.leo_constellation_v1",
             "fixture.artifact.campaign_repair.leo_constellation_v2",
             "fixture.artifact.campaign_request_lint.v1",
             "fixture.artifact.campaign_strategy.leo_constellation_v3",
             "fixture.artifact.candidate_activity.v1",
             "fixture.artifact.candidate_diff_report.v1",
             "fixture.artifact.candidate_diff_row.v1",
             "fixture.artifact.candidate_refresh.candidate_rejection_replay",
             "fixture.artifact.candidate_refresh.constraint_replay",
             "fixture.artifact.candidate_refresh.contact_allocation_contradiction_replay",
             "fixture.artifact.candidate_refresh.contact_contention_cross_station_replay",
             "fixture.artifact.candidate_refresh.contact_filter_replay",
             "fixture.artifact.candidate_refresh.contact_intent_direction_replay",
             "fixture.artifact.candidate_refresh.freshness_replay",
             "fixture.artifact.candidate_refresh.link_capacity_replay",
             "fixture.artifact.candidate_refresh.objective_gap_replay",
             "fixture.artifact.candidate_refresh.operational_readiness_replay",
             "fixture.artifact.candidate_refresh.quality_gate_replay",
             "fixture.artifact.candidate_refresh.refresh_budget_replay",
             "fixture.artifact.candidate_refresh.resource_filter_replay",
             "fixture.artifact.candidate_refresh.resource_projection_replay",
             "fixture.artifact.candidate_refresh.resource_provenance_v1",
             "fixture.artifact.candidate_refresh.station_calendar_replay",
             "fixture.artifact.candidate_refresh.timeline_activity_lifecycle_replay",
             "fixture.artifact.candidate_refresh.timeline_activity_precondition_replay",
             "fixture.artifact.candidate_refresh.timeline_lifecycle_state_replay",
             "fixture.artifact.candidate_refresh.timeline_transition_application_replay",
             "fixture.artifact.candidate_refresh.v1",
             "fixture.artifact.candidate_rejection_report.v1",
             "fixture.artifact.capability_catalog.v1",
             "fixture.artifact.command_window_report.v1",
             "fixture.artifact.constraint_report.v1",
             "fixture.artifact.contact_allocation_capacity_pack_summary.v1",
             "fixture.artifact.contact_allocation_provider_reservation_request_summary.v1",
             "fixture.artifact.contact_allocation_report.reduced_capacity_pack",
             "fixture.artifact.contact_allocation_report.v1",
             "fixture.artifact.contact_allocation_reservation_conflict_summary.v1",
             "fixture.artifact.contact_allocation_station_pressure_summary.v1",
             "fixture.artifact.contact_allocation_summary.v1",
             "fixture.artifact.contact_contention_report.cross_station_spacecraft",
             "fixture.artifact.contact_contention_report.v1",
             "fixture.artifact.contact_contention_resolution_report.v1",
             "fixture.artifact.contact_contention_resolution_summary.v1",
             "fixture.artifact.contact_filter_report.v1",
             "fixture.artifact.contact_intent.v1",
             "fixture.artifact.contact_intent_summary.v1",
             "fixture.artifact.environment_model_capability.constant_earth_rotation",
             "fixture.artifact.environment_model_capability.fixed_sun",
             "fixture.artifact.environment_provider_capability.constant_earth_rotation",
             "fixture.artifact.environment_provider_capability.exponential_atmosphere",
             "fixture.artifact.environment_provider_capability.fixed_sun",
             "fixture.artifact.environment_provider_capability.tabular_earth_orientation",
             "fixture.artifact.execution_report.v1",
             "fixture.artifact.freshness_report.v1",
             "fixture.artifact.invalidated_candidate.v1",
             "fixture.artifact.link_capacity_report.v1",
             "fixture.artifact.link_capacity_summary.v1",
             "fixture.artifact.maneuver_execution_delta.v1",
             "fixture.artifact.maneuver_recommendation.v1",
             "fixture.artifact.maneuver_review_report.v1",
             "fixture.artifact.manifest_field_reference.v1",
             "fixture.artifact.model_acceptance_report.operational_import",
             "fixture.artifact.monte_carlo_reproducibility_report.v1",
             "fixture.artifact.objective_satisfaction_report.v1",
             "fixture.artifact.objective_tradeoff_report.v1",
             "fixture.artifact.operational_execution_boundary_summary.v1",
             "fixture.artifact.operational_import_eligibility_summary.v1",
             "fixture.artifact.operational_quality_gate_import_readiness_summary.v1",
             "fixture.artifact.operational_quality_gate_operator_training_summary.v1",
             "fixture.artifact.operational_quality_gate_schema_validation_summary.v1",
             "fixture.artifact.operational_quality_gate_summary.v1",
             "fixture.artifact.operational_quality_gate_unavailable_resource_summary.resource_projection_v1",
             "fixture.artifact.operational_quality_gate_unavailable_resource_summary.v1",
             "fixture.artifact.operational_readiness_gate_summary.v1",
             "fixture.artifact.operational_readiness_report.resource_pressure_v1",
             "fixture.artifact.operational_readiness_report.v1",
             "fixture.artifact.operational_timeline_report.v1",
             "fixture.artifact.operator_review_package.resource_pressure_v1",
             "fixture.artifact.operator_review_package.resource_projection_battery_handoff_v1",
             "fixture.artifact.operator_review_package.v1",
             "fixture.artifact.optimizer_contract.v1",
             "fixture.artifact.pareto_frontier_report.v1",
             "fixture.artifact.plan_delta.v1",
             "fixture.artifact.planned_activity.v1",
             "fixture.artifact.policy_bundle.command_contact_authority",
             "fixture.artifact.policy_bundle.conservative_ops",
             "fixture.artifact.policy_bundle.contact_command_review",
             "fixture.artifact.policy_bundle.default",
             "fixture.artifact.policy_bundle.degraded_payload_guard",
             "fixture.artifact.policy_bundle.ground_network_allocation",
             "fixture.artifact.policy_bundle.maneuver_authority",
             "fixture.artifact.policy_bundle.operator_review_queue_authority",
             "fixture.artifact.policy_bundle.organization_adapter",
             "fixture.artifact.policy_bundle.resource_projection_authority",
             "fixture.artifact.policy_bundle.timeline_protection",
             "fixture.artifact.policy_bundle.v1",
             "fixture.artifact.policy_decision.v1",
             "fixture.artifact.proposed_contact.v1",
             "fixture.artifact.provider_counteroffer_import_readiness_summary.v1",
             "fixture.artifact.provider_counteroffer_plan_impact_summary.v1",
             "fixture.artifact.provider_counteroffer_report.v1",
             "fixture.artifact.provider_counteroffer_review_summary.v1",
             "fixture.artifact.quality_gate_report.resource_pressure_v1",
             "fixture.artifact.quality_gate_report.v1",
             "fixture.artifact.ranking_comparison_report.v1",
             "fixture.artifact.realized_activity.v1",
             "fixture.artifact.realized_state_snapshot.v1",
             "fixture.artifact.refresh_budget_report.v1",
             "fixture.artifact.refreshed_window.v1",
             "fixture.artifact.relay_data_path_summary.v1",
             "fixture.artifact.remaining_horizon.v1",
             "fixture.artifact.resource_filter_report.stale_resource_summary_margins",
             "fixture.artifact.resource_filter_report.v1",
             "fixture.artifact.resource_filter_summary.v1",
             "fixture.artifact.resource_projection_flow_summary.v1",
             "fixture.artifact.resource_projection_report.battery_handoff_v1",
             "fixture.artifact.resource_projection_report.stale_resource_summary_margins",
             "fixture.artifact.resource_projection_report.v1",
             "fixture.artifact.resource_summary.v1",
             "fixture.artifact.result_artifact.candidate_refresh_orbit_data_v1",
             "fixture.artifact.result_artifact.candidate_refresh_v1",
             "fixture.artifact.result_artifact.ground_track_crossings",
             "fixture.artifact.result_artifact.leo_access_demo",
             "fixture.artifact.result_artifact.leo_access_demo_manifest",
             "fixture.artifact.result_artifact.leo_constellation_campaign",
             "fixture.artifact.result_artifact.leo_dispersion_monte_carlo",
             "fixture.artifact.result_artifact.mission_plan_checkout",
             "fixture.artifact.result_artifact.raise_apogee_search",
             "fixture.artifact.schema_migration_report.deprecated_campaign_plan",
             "fixture.artifact.schema_migration_report.future_campaign_plan",
             "fixture.artifact.schema_validation_batch_report.v1",
             "fixture.artifact.schema_validation_report.v1",
             "fixture.artifact.score_term_report.v1",
             "fixture.artifact.source_window_lineage.v1",
             "fixture.artifact.spacecraft_state_estimate.v1",
             "fixture.artifact.station_calendar_precedence_summary.v1",
             "fixture.artifact.station_calendar_provider.v1",
             "fixture.artifact.station_calendar_report.stale_provider_reservation_hold",
             "fixture.artifact.station_calendar_report.v1",
             "fixture.artifact.station_reservation_hold_import_readiness_summary.v1",
             "fixture.artifact.station_reservation_hold_summary.v1",
             "fixture.artifact.station_reservation_report.stale_provider_reservation_hold",
             "fixture.artifact.station_reservation_review_summary.v1",
             "fixture.artifact.strategy_branch.v1",
             "fixture.artifact.strategy_recommendation.v1",
             "fixture.artifact.study_benchmark.distributed_chunk_sweep",
             "fixture.artifact.study_benchmark.distributed_concurrency_sweep",
             "fixture.artifact.study_benchmark.distributed_diagnostic_sweep",
             "fixture.artifact.study_benchmark.distributed_monte_carlo_chunked",
             "fixture.artifact.study_benchmark.distributed_monte_carlo_scaling",
             "fixture.artifact.study_benchmark.monte_carlo_scaling",
             "fixture.artifact.study_benchmark.nx_study_benchmark",
             "fixture.artifact.study_benchmark.v1",
             "fixture.artifact.study_manifest_lint.v1",
             "fixture.artifact.subsystem_model_capability.battery",
             "fixture.artifact.subsystem_model_capability.storage",
             "fixture.artifact.timeline_activity_approval_state.v1",
             "fixture.artifact.timeline_activity_lifecycle_state.v1",
             "fixture.artifact.timeline_activity_precondition_summary.v1",
             "fixture.artifact.timeline_activity_state.v1",
             "fixture.artifact.timeline_activity_status_state.v1",
             "fixture.artifact.timeline_dependency_impact_summary.v1",
             "fixture.artifact.timeline_diff_report.v1",
             "fixture.artifact.timeline_diff_summary.v1",
             "fixture.artifact.timeline_feedback_report.v1",
             "fixture.artifact.timeline_integrity_report.v1",
             "fixture.artifact.timeline_lifecycle_state_summary.v1",
             "fixture.artifact.timeline_preservation_report.v1",
             "fixture.artifact.timeline_preservation_status.v1",
             "fixture.artifact.timeline_publication_summary.v1",
             "fixture.artifact.timeline_transition_application_report.v1",
             "fixture.artifact.timeline_transition_application_selected_integrity.v1",
             "fixture.artifact.timeline_transition_application_selected_integrity_summary.v1",
             "fixture.artifact.timeline_transition_application_summary.v1",
             "fixture.artifact.validation_check.v1",
             "fixture.artifact.validation_record.v1",
             "fixture.artifact.validation_reference_report.v1",
             "fixture.artifact.validation_safety_case_summary.v1",
             "fixture.artifact.validation_tolerance_policy.v1",
             "fixture.event.access.equator_overhead_120s",
             "fixture.event.eclipse.cylindrical_shadow_120s",
             "fixture.event.ground_track.latitude_equator_60s",
             "fixture.event.target_visibility.equator_overhead_120s",
             "fixture.j2.circular_leo_600s",
             "fixture.two_body.circular_leo_600s"
           ]

    assert {:ok, %{"schema_contract" => "validation_reference_fixture_report.v1"}} =
             OrbitalDynamics.Schema.validate_artifact(report)

    invalid_observation_report =
      Validation.reference_fixture_report(%{
        "fixture.two_body.circular_leo_600s" => :not_an_observation_map
      })

    assert %{
             "status" => "fail",
             "status_counts" => %{"fail" => 195},
             "reports" => invalid_observation_reports
           } = invalid_observation_report

    assert %{
             "schema_contract" => "validation_reference_report.v1",
             "fixture_id" => "fixture.two_body.circular_leo_600s",
             "status" => "fail",
             "checks" => [
               %{
                 "field" => "observations",
                 "status" => "fail",
                 "expected" => "valid observations map"
               }
             ]
           } =
             Enum.find(
               invalid_observation_reports,
               &(&1["fixture_id"] == "fixture.two_body.circular_leo_600s")
             )

    assert {:ok, %{"schema_contract" => "validation_reference_fixture_report.v1"}} =
             OrbitalDynamics.Schema.validate_artifact(invalid_observation_report)

    invalid_fixture_count = Map.put(report, "fixture_count", 99)

    assert {:error, fixture_count_report} =
             OrbitalDynamics.Schema.validate_artifact(invalid_fixture_count)

    assert Enum.any?(
             fixture_count_report["errors"],
             &(&1["path"] == "$.fixture_count")
           )

    inconsistent_status_report =
      report
      |> put_in(["reports", Access.at(0), "status"], "fail")
      |> Map.put("status", "pass")

    assert {:error, inconsistent_status_errors} =
             OrbitalDynamics.Schema.validate_artifact(inconsistent_status_report)

    assert Enum.any?(
             inconsistent_status_errors["errors"],
             &(&1["path"] == "$.status" and
                 &1["message"] == "must equal nested report statuses")
           )

    invalid_negative_fixture_count = Map.put(report, "fixture_count", -1)

    assert {:error, negative_fixture_count_report} =
             OrbitalDynamics.Schema.validate_artifact(invalid_negative_fixture_count)

    assert Enum.any?(
             negative_fixture_count_report["errors"],
             &(&1["path"] == "$.fixture_count")
           )

    stale_status_counts = put_in(report, ["status_counts", "pass"], 123)

    assert {:error, stale_status_counts_report} =
             OrbitalDynamics.Schema.validate_artifact(stale_status_counts)

    assert Enum.any?(
             stale_status_counts_report["errors"],
             &(&1["path"] == "$.status_counts" and
                 &1["message"] == "must equal nested report status counts")
           )
  end

  defp branch_comparison_report_fixture_observations do
    "branch_comparison_report.v1"
    |> Validation.artifact_observations(branch_comparison_report_fixture())
  end

  defp branch_comparison_report_fixture do
    read_json!("study_results/branch_comparison_report_v1.json")
  end

  defp optimizer_contract_fixture_observations do
    "optimizer_contract.v1"
    |> Validation.artifact_observations(optimizer_contract_fixture())
  end

  defp optimizer_contract_fixture do
    read_json!("study_results/optimizer_contract_v1.json")
  end

  defp proposed_contact_fixture_observations do
    "proposed_contact.v1"
    |> Validation.artifact_observations(proposed_contact_fixture())
  end

  defp proposed_contact_fixture do
    read_json!("study_results/proposed_contact_v1.json")
  end

  defp invalidated_candidate_fixture_observations do
    "invalidated_candidate.v1"
    |> Validation.artifact_observations(invalidated_candidate_fixture())
  end

  defp invalidated_candidate_fixture do
    read_json!("study_results/invalidated_candidate_v1.json")
  end

  defp strategy_branch_fixture_observations do
    "strategy_branch.v1"
    |> Validation.artifact_observations(strategy_branch_fixture())
  end

  defp strategy_branch_fixture do
    read_json!("study_results/strategy_branch_v1.json")
  end

  defp strategy_recommendation_fixture_observations do
    "strategy_recommendation.v1"
    |> Validation.artifact_observations(strategy_recommendation_fixture())
  end

  defp strategy_recommendation_fixture do
    read_json!("study_results/strategy_recommendation_v1.json")
  end

  defp study_benchmark_fixture_observations do
    "study_benchmark.v1"
    |> Validation.artifact_observations(study_benchmark_fixture())
  end

  defp study_benchmark_fixture do
    read_json!("study_results/study_benchmark.json")
  end

  defp distributed_concurrency_benchmark_fixture_observations do
    "study_benchmark.v1"
    |> Validation.artifact_observations(distributed_concurrency_benchmark_fixture())
  end

  defp distributed_concurrency_benchmark_fixture do
    read_json!("study_results/distributed_concurrency_sweep.json")
  end

  defp distributed_chunk_benchmark_fixture_observations do
    "study_benchmark.v1"
    |> Validation.artifact_observations(distributed_chunk_benchmark_fixture())
  end

  defp distributed_chunk_benchmark_fixture do
    read_json!("study_results/distributed_chunk_sweep.json")
  end

  defp distributed_monte_carlo_scaling_benchmark_fixture_observations do
    "study_benchmark.v1"
    |> Validation.artifact_observations(distributed_monte_carlo_scaling_benchmark_fixture())
  end

  defp distributed_monte_carlo_scaling_benchmark_fixture do
    read_json!("study_results/distributed_monte_carlo_scaling.json")
  end

  defp distributed_diagnostic_benchmark_fixture_observations do
    "study_benchmark.v1"
    |> Validation.artifact_observations(distributed_diagnostic_benchmark_fixture())
  end

  defp distributed_diagnostic_benchmark_fixture do
    read_json!("study_results/distributed_diagnostic_sweep.json")
  end

  defp distributed_monte_carlo_chunked_benchmark_fixture_observations do
    "study_benchmark.v1"
    |> Validation.artifact_observations(distributed_monte_carlo_chunked_benchmark_fixture())
  end

  defp distributed_monte_carlo_chunked_benchmark_fixture do
    read_json!("study_results/distributed_monte_carlo_chunked.json")
  end

  defp monte_carlo_scaling_benchmark_fixture_observations do
    "study_benchmark.v1"
    |> Validation.artifact_observations(monte_carlo_scaling_benchmark_fixture())
  end

  defp monte_carlo_scaling_benchmark_fixture do
    read_json!("study_results/monte_carlo_scaling.json")
  end

  defp nx_study_benchmark_fixture_observations do
    "study_benchmark.v1"
    |> Validation.artifact_observations(nx_study_benchmark_fixture())
  end

  defp nx_study_benchmark_fixture do
    read_json!("study_results/nx_study_benchmark.json")
  end

  defp validation_reference_report_fixture_observations do
    "validation_reference_report.v1"
    |> Validation.artifact_observations(validation_reference_report_fixture())
  end

  defp validation_reference_report_fixture do
    read_json!("study_results/validation_reference_report_v1.json")
  end

  defp candidate_diff_report_fixture_observations do
    "candidate_diff_report.v1"
    |> Validation.artifact_observations(candidate_diff_report_fixture())
  end

  defp candidate_diff_report_fixture do
    read_json!("study_results/candidate_diff_report_v1.json")
  end

  defp refresh_budget_report_fixture_observations do
    "refresh_budget_report.v1"
    |> Validation.artifact_observations(refresh_budget_report_fixture())
  end

  defp refresh_budget_report_fixture do
    read_json!("study_results/refresh_budget_report_v1.json")
  end

  defp execution_report_fixture_observations do
    "execution_report.v1"
    |> Validation.artifact_observations(execution_report_fixture())
  end

  defp execution_report_fixture do
    read_json!("study_results/execution_report_v1.json")
  end

  defp freshness_report_fixture_observations do
    "freshness_report.v1"
    |> Validation.artifact_observations(freshness_report_fixture())
  end

  defp freshness_report_fixture do
    read_json!("study_results/freshness_report_v1.json")
  end

  defp manifest_field_reference_fixture_observations do
    "manifest_field_reference.v1"
    |> Validation.artifact_observations(manifest_field_reference_fixture())
  end

  defp manifest_field_reference_fixture do
    read_json!("study_results/manifest_field_reference.json")
  end

  defp study_manifest_lint_fixture_observations do
    "study_manifest_lint.v1"
    |> Validation.artifact_observations(study_manifest_lint_fixture())
  end

  defp study_manifest_lint_fixture do
    read_json!("study_results/study_manifest_lint_v1.json")
  end

  defp approval_requirement_fixture_observations do
    "approval_requirement.v1"
    |> Validation.artifact_observations(approval_requirement_fixture())
  end

  defp approval_requirement_fixture do
    read_json!("study_results/approval_requirement_v1.json")
  end

  defp policy_decision_fixture_observations do
    "policy_decision.v1"
    |> Validation.artifact_observations(policy_decision_fixture())
  end

  defp policy_decision_fixture do
    read_json!("study_results/policy_decision_v1.json")
  end

  defp cadence_import_resource_pressure_fixture_observations do
    "cadence_import_manifest.v1"
    |> Validation.artifact_observations(cadence_import_resource_pressure_fixture())
  end

  defp cadence_import_resource_pressure_fixture do
    read_json!("study_results/cadence_import_resource_pressure_v1.json")
  end

  defp contact_allocation_report_fixture_observations do
    "contact_allocation_report.v1"
    |> Validation.artifact_observations(contact_allocation_report_fixture())
  end

  defp contact_allocation_report_fixture do
    read_json!("study_results/contact_allocation_report_v1.json")
  end

  defp contact_allocation_summary_fixture_observations do
    "contact_allocation_summary.v1"
    |> Validation.artifact_observations(
      read_json!("study_results/contact_allocation_summary_v1.json")
    )
  end

  defp contact_allocation_capacity_pack_summary_fixture_observations do
    "contact_allocation_capacity_pack_summary.v1"
    |> Validation.artifact_observations(
      read_json!("study_results/contact_allocation_capacity_pack_summary_v1.json")
    )
  end

  defp contact_allocation_reservation_conflict_summary_fixture_observations do
    "contact_allocation_reservation_conflict_summary.v1"
    |> Validation.artifact_observations(
      read_json!("study_results/contact_allocation_reservation_conflict_summary_v1.json")
    )
  end

  defp contact_allocation_station_pressure_summary_fixture_observations do
    "contact_allocation_station_pressure_summary.v1"
    |> Validation.artifact_observations(
      read_json!("study_results/contact_allocation_station_pressure_summary_v1.json")
    )
  end

  defp operator_review_package_fixture_observations do
    operator_review_package_fixture()
    |> then(&Validation.artifact_observations("operator_review_package.v1", &1))
  end

  defp operator_review_package_fixture do
    read_json!("study_results/operator_review_package_v1.json")
  end

  defp operator_review_resource_pressure_fixture_observations do
    "operator_review_package.v1"
    |> Validation.artifact_observations(operator_review_resource_pressure_fixture())
  end

  defp operator_review_resource_pressure_fixture do
    read_json!("study_results/operator_review_resource_pressure_v1.json")
  end

  defp operational_readiness_report_fixture_observations do
    "operational_readiness_report.v1"
    |> Validation.artifact_observations(operational_readiness_report_fixture())
  end

  defp operational_readiness_report_fixture do
    read_json!("study_results/operational_readiness_report_v1.json")
  end

  defp operational_readiness_resource_pressure_fixture_observations do
    "operational_readiness_report.v1"
    |> Validation.artifact_observations(operational_readiness_resource_pressure_fixture())
  end

  defp operational_execution_boundary_summary_fixture_observations do
    "operational_execution_boundary_summary.v1"
    |> Validation.artifact_observations(operational_execution_boundary_summary_fixture())
  end

  defp operational_execution_boundary_summary_fixture do
    read_json!("study_results/operational_execution_boundary_summary_v1.json")
  end

  defp operational_import_eligibility_summary_fixture_observations do
    "operational_import_eligibility_summary.v1"
    |> Validation.artifact_observations(operational_import_eligibility_summary_fixture())
  end

  defp operational_import_eligibility_summary_fixture do
    read_json!("study_results/operational_import_eligibility_summary_v1.json")
  end

  defp operational_readiness_gate_summary_fixture_observations do
    "operational_readiness_gate_summary.v1"
    |> Validation.artifact_observations(operational_readiness_gate_summary_fixture())
  end

  defp operational_readiness_gate_summary_fixture do
    read_json!("study_results/operational_readiness_gate_summary_v1.json")
  end

  defp operational_quality_gate_summary_fixture_observations do
    "operational_quality_gate_summary.v1"
    |> Validation.artifact_observations(operational_quality_gate_summary_fixture())
  end

  defp operational_quality_gate_summary_fixture do
    read_json!("study_results/operational_quality_gate_summary_v1.json")
  end

  defp operational_quality_gate_import_readiness_summary_fixture_observations do
    "operational_quality_gate_import_readiness_summary.v1"
    |> Validation.artifact_observations(
      operational_quality_gate_import_readiness_summary_fixture()
    )
  end

  defp operational_quality_gate_import_readiness_summary_fixture do
    read_json!("study_results/operational_quality_gate_import_readiness_summary_v1.json")
  end

  defp operational_quality_gate_unavailable_resource_summary_fixture_observations do
    "operational_quality_gate_unavailable_resource_summary.v1"
    |> Validation.artifact_observations(
      operational_quality_gate_unavailable_resource_summary_fixture()
    )
  end

  defp operational_quality_gate_unavailable_resource_summary_fixture do
    review_source = %{
      "schema_contract" => "operator_review_package.v1",
      "source_artifact_type" => "contact_allocation_report.v1",
      "package_id" => "validation_unavailable_resource_fixture",
      "rows" => [
        %{
          "id" => "operator_review:contact_allocation:dl_resource_blocked",
          "review_type" => "contact_allocation_review",
          "approval_status" => "operator_review_required",
          "source_contact_allocation" => %{
            "contact_id" => "dl_resource_blocked",
            "type" => "downlink",
            "spacecraft_id" => "leo_1",
            "ground_station_id" => "equator_prime",
            "starts_at_s" => 620.0,
            "ends_at_s" => 680.0,
            "allocation_status" => "blocked",
            "allocation_reason" => "antenna_unavailable",
            "source_resource_suppression" => %{
              "id" => "dl_resource_blocked",
              "type" => "downlink",
              "spacecraft_id" => "leo_1",
              "suppressed_reason" => "antenna_unavailable",
              "resource_blocking_dimension" => "antenna",
              "antenna_available" => false,
              "resource_source_quality" => "operator_supplied",
              "resource_trust_boundary_status" => "declared"
            }
          }
        }
      ]
    }

    review_source
    |> OperationalReadiness.report()
    |> OperationalReadiness.quality_gate_report()
    |> OrbitalDynamics.operational_quality_gate_unavailable_resource_summary()
  end

  defp operational_quality_gate_unavailable_resource_summary_checked_in_observations do
    "operational_quality_gate_unavailable_resource_summary.v1"
    |> Validation.artifact_observations(
      operational_quality_gate_unavailable_resource_summary_checked_in_fixture()
    )
  end

  defp operational_quality_gate_unavailable_resource_summary_checked_in_fixture do
    read_json!("study_results/operational_quality_gate_unavailable_resource_summary_v1.json")
  end

  defp operational_quality_gate_operator_training_summary_fixture_observations do
    "operational_quality_gate_operator_training_summary.v1"
    |> Validation.artifact_observations(
      operational_quality_gate_operator_training_summary_fixture()
    )
  end

  defp operational_quality_gate_operator_training_summary_fixture do
    read_json!("study_results/operational_quality_gate_operator_training_summary_v1.json")
  end

  defp operational_quality_gate_schema_validation_summary_fixture_observations do
    "operational_quality_gate_schema_validation_summary.v1"
    |> Validation.artifact_observations(
      operational_quality_gate_schema_validation_summary_fixture()
    )
  end

  defp operational_quality_gate_schema_validation_summary_fixture do
    read_json!("study_results/operational_quality_gate_schema_validation_summary_v1.json")
  end

  defp quality_gate_report_fixture_observations do
    "quality_gate_report.v1"
    |> Validation.artifact_observations(quality_gate_report_fixture())
  end

  defp quality_gate_report_fixture do
    operational_readiness_report_fixture()
    |> OperationalReadiness.quality_gate_report()
  end

  defp quality_gate_resource_pressure_fixture_observations do
    "quality_gate_report.v1"
    |> Validation.artifact_observations(quality_gate_resource_pressure_fixture())
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
