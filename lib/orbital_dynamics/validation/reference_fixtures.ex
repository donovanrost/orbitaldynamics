defmodule OrbitalDynamics.Validation.ReferenceFixtures do
  @moduledoc false

  alias OrbitalDynamics.Validation.ReferenceFixtures.AcceptedPlanningState
  alias OrbitalDynamics.Validation.ReferenceFixtures.ActivityArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.BenchmarkArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.CandidateRefreshBase
  alias OrbitalDynamics.Validation.ReferenceFixtures.CandidateRefreshCapacityFilter
  alias OrbitalDynamics.Validation.ReferenceFixtures.CandidateRefreshContact
  alias OrbitalDynamics.Validation.ReferenceFixtures.CandidateRefreshFilterRejection
  alias OrbitalDynamics.Validation.ReferenceFixtures.CandidateRefreshFreshnessBudget
  alias OrbitalDynamics.Validation.ReferenceFixtures.CandidateRefreshPlanningFeedback
  alias OrbitalDynamics.Validation.ReferenceFixtures.CandidateRefreshReadiness
  alias OrbitalDynamics.Validation.ReferenceFixtures.CandidateRefreshStationAllocation
  alias OrbitalDynamics.Validation.ReferenceFixtures.CandidateRefreshTimeline
  alias OrbitalDynamics.Validation.ReferenceFixtures.CandidateStateArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.CandidateStrategyArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.CampaignArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.CampaignPlanning
  alias OrbitalDynamics.Validation.ReferenceFixtures.ContactAllocationArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.ContactContentionArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.ContactIntentArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.ContactWindowArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.CoreRunReports
  alias OrbitalDynamics.Validation.ReferenceFixtures.DecisionSupportArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.EnvironmentCapabilities
  alias OrbitalDynamics.Validation.ReferenceFixtures.LinkCapacityArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.ManifestArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.ObjectiveScoringArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.OperationalPlanningArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.Orbital
  alias OrbitalDynamics.Validation.ReferenceFixtures.PolicyBundleArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.PolicyDecisions
  alias OrbitalDynamics.Validation.ReferenceFixtures.PolicyEvidenceArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.ProviderCapacityPackArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.ResourcePressureHandoffArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.ResourceProjectionArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.ResourceSafetyArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.ResourceSummaryArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.SchemaCompatibilityArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.StateManeuverArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.SubsystemModelCapabilities
  alias OrbitalDynamics.Validation.ReferenceFixtures.TimelineActivityStateArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.TimelineHandoffArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.TimelinePreservationArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.TimelineTransitionArtifacts

  @candidate_refresh_source_report_input_order Enum.join(
                                                 [
                                                   "station_calendar_report",
                                                   "station_calendar_precedence_summary",
                                                   "contact_intent_summary",
                                                   "resource_projection_report",
                                                   "resource_projection_flow_summary",
                                                   "resource_filter_report",
                                                   "resource_filter_summary",
                                                   "contact_filter_report",
                                                   "link_capacity_summary",
                                                   "relay_data_path_summary",
                                                   "timeline_feedback_report",
                                                   "operational_timeline_report",
                                                   "timeline_integrity_report",
                                                   "timeline_activity_precondition_summary",
                                                   "timeline_preservation_report",
                                                   "timeline_diff_report",
                                                   "timeline_diff_summary",
                                                   "timeline_lifecycle_state_summary",
                                                   "timeline_dependency_impact_summary",
                                                   "timeline_publication_summary",
                                                   "timeline_transition_application_report",
                                                   "timeline_transition_application_summary",
                                                   "objective_satisfaction_report",
                                                   "objective_tradeoff_report",
                                                   "score_term_report",
                                                   "constraint_report",
                                                   "candidate_diff_report",
                                                   "candidate_rejection_report",
                                                   "freshness_report",
                                                   "refresh_budget_report",
                                                   "schema_validation_report",
                                                   "schema_validation_batch_report",
                                                   "operational_readiness_report",
                                                   "operational_import_eligibility_summary",
                                                   "operational_readiness_gate_summary",
                                                   "operational_execution_boundary_summary",
                                                   "command_window_report",
                                                   "maneuver_review_report",
                                                   "provider_counteroffer_report",
                                                   "provider_counteroffer_review_summary",
                                                   "provider_counteroffer_import_readiness_summary",
                                                   "provider_counteroffer_plan_impact_summary",
                                                   "contact_allocation_report",
                                                   "contact_allocation_summary",
                                                   "contact_allocation_station_pressure_summary",
                                                   "contact_allocation_reservation_conflict_summary",
                                                   "contact_allocation_capacity_pack_summary",
                                                   "contact_allocation_provider_reservation_request_summary",
                                                   "station_reservation_report",
                                                   "station_reservation_review_summary",
                                                   "station_reservation_hold_summary",
                                                   "station_reservation_hold_import_readiness_summary",
                                                   "contact_contention_report",
                                                   "contact_contention_resolution_report",
                                                   "contact_contention_resolution_summary",
                                                   "link_capacity_report",
                                                   "quality_gate_report",
                                                   "operational_quality_gate_summary",
                                                   "operational_quality_gate_unavailable_resource_summary",
                                                   "operational_quality_gate_operator_training_summary",
                                                   "operational_quality_gate_schema_validation_summary",
                                                   "operational_quality_gate_import_readiness_summary",
                                                   "model_acceptance_report",
                                                   "validation_safety_case_summary"
                                                 ],
                                                 "|"
                                               )

  @fixtures %{
    "fixture.artifact.capability_catalog.v1" => %{
      "id" => "fixture.artifact.capability_catalog.v1",
      "model_id" => "artifact.capability_catalog.v1",
      "reference_case" => "checked-in public capability catalog artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/capability_catalog_v1.json",
        "contract" => "capability_catalog.v1"
      },
      "expected" => %{
        "schema_contract" => "capability_catalog.v1",
        "schema_version" => 1,
        "model" => "public_capability_catalog",
        "top_level_family_count" => 7,
        "planning_capability_count" => 6,
        "operations_capability_count" => 17,
        "validation_family_count" => 2,
        "artifact_contract_count" => 121,
        "artifact_contract_list_count" => 121,
        "compatibility_policy_version" => 1,
        "identity_policy_version" => 1,
        "public_validation_facade_count" => 13,
        "optimizer_model" => "per_spacecraft_greedy_non_overlapping",
        "optimizer_contract" => "optimizer_contract.v1",
        "cadence_import_contract" => "cadence_import_manifest.v1",
        "operational_readiness_contract" => "operational_readiness_report.v1",
        "station_calendar_reservation_contract" => "station_reservation_report.v1",
        "candidate_refresh_input_count" => 81,
        "candidate_refresh_source_report_input_count" => 64,
        "candidate_refresh_source_report_input_order" =>
          @candidate_refresh_source_report_input_order,
        "candidate_refresh_source_report_helper_count" => 40
      },
      "tolerances" => %{
        "schema_version" => 0,
        "top_level_family_count" => 0,
        "planning_capability_count" => 0,
        "operations_capability_count" => 0,
        "validation_family_count" => 0,
        "artifact_contract_count" => 0,
        "artifact_contract_list_count" => 0,
        "compatibility_policy_version" => 0,
        "identity_policy_version" => 0,
        "public_validation_facade_count" => 0,
        "candidate_refresh_input_count" => 0,
        "candidate_refresh_source_report_input_count" => 0,
        "candidate_refresh_source_report_helper_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not full capability certification",
        "checks public catalog counts and key contract routing only"
      ]
    },
    "fixture.artifact.station_calendar_precedence_summary.v1" => %{
      "id" => "fixture.artifact.station_calendar_precedence_summary.v1",
      "model_id" => "artifact.station_calendar_precedence_summary.v1",
      "reference_case" => "checked-in station calendar precedence summary artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/station_calendar_precedence_summary_v1.json",
        "contract" => "station_calendar_precedence_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "station_calendar_precedence_summary.v1",
        "model" => "artifact_only_station_calendar_precedence_summary",
        "source_artifact_type" => "station_calendar_report.v1",
        "source" => "ops_calendar",
        "affected_contact_count" => 1,
        "precedence_review_status" => "review_required",
        "applied_availability_counts" => %{"unavailable" => 1},
        "applied_status_counts" => %{"unavailable" => 1},
        "overlap_availability_counts" => %{
          "reduced_capacity" => 1,
          "reserved" => 1,
          "unavailable" => 1
        },
        "affected_contact_ids_by_applied_availability" => %{"unavailable" => ["dl_1"]},
        "affected_contact_ids_by_applied_status" => %{"unavailable" => ["dl_1"]},
        "affected_contact_ids_by_overlap_availability" => %{
          "reduced_capacity" => ["dl_1"],
          "reserved" => ["dl_1"],
          "unavailable" => ["dl_1"]
        },
        "reserved_under_higher_precedence_contact_count" => 1,
        "reserved_under_higher_precedence_contact_ids" => "dl_1",
        "reserved_under_higher_precedence_contact_ids_by_applied_availability" => %{
          "unavailable" => ["dl_1"]
        },
        "reserved_under_higher_precedence_contact_ids_by_applied_status" => %{
          "unavailable" => ["dl_1"]
        },
        "unavailable_contact_ids" => "dl_1",
        "reserved_overlap_contact_ids" => "dl_1",
        "reduced_capacity_contact_ids" => "dl_1",
        "model_limit_count" => 5,
        "execution_boundary" => "artifact_only_no_provider_reservation",
        "scope" => "station_calendar_availability_precedence_review",
        "operator_authority" => "not_granted_by_summary",
        "no_network_calls" => true,
        "no_provider_reservation" => true,
        "no_schedule_mutation" => true,
        "no_conflict_resolution" => true
      },
      "tolerances" => %{
        "affected_contact_count" => 0,
        "reserved_under_higher_precedence_contact_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by station_calendar_precedence_summary.v1 validation tests"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external provider validation",
        "checks compact precedence routing, higher-precedence reservation visibility, and no-provider/no-mutation boundaries only"
      ]
    },
    "fixture.artifact.station_calendar_provider.v1" => %{
      "id" => "fixture.artifact.station_calendar_provider.v1",
      "model_id" => "artifact.station_calendar_provider.v1",
      "reference_case" => "checked-in declared station calendar provider artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/station_calendar_provider_v1.json",
        "contract" => "station_calendar_provider.v1"
      },
      "expected" => %{
        "schema_contract" => "station_calendar_provider.v1",
        "id" => "declared_ground_network_demo",
        "provider_id" => "declared_ground_network_demo",
        "entry_count" => 2,
        "entry_id_order" => "equator_prime_maintenance_1|equator_prime_reservation_1",
        "ground_station_id_order" => "equator_prime|equator_prime",
        "maintenance_entry_count" => 1,
        "reserved_entry_count" => 1,
        "zero_capacity_entry_count" => 1,
        "reservation_entry_count" => 1,
        "reservation_id_order" => "reservation_equator_prime_1",
        "reserved_by_order" => "ops_team_b",
        "provenance_source" => "declared_provider_fixture",
        "trust_boundary" => "operator_declared_station_calendar",
        "assumption_boundary" => "artifact_only_no_provider_reservation",
        "network_access" => "none"
      },
      "tolerances" => %{
        "entry_count" => 0,
        "maintenance_entry_count" => 0,
        "reserved_entry_count" => 0,
        "zero_capacity_entry_count" => 0,
        "reservation_entry_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external provider validation",
        "checks declared station-calendar entries, reservation metadata, and no-provider-write boundary only"
      ]
    },
    "fixture.artifact.operator_review_package.v1" => %{
      "id" => "fixture.artifact.operator_review_package.v1",
      "model_id" => "artifact.operator_review_package.v1",
      "reference_case" => "checked-in standalone operator review package artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/operator_review_package_v1.json",
        "contract" => "operator_review_package.v1"
      },
      "expected" => %{
        "schema_contract" => "operator_review_package.v1",
        "model" => "artifact_only_operator_review_package",
        "review_count" => 8,
        "row_derived_review_count" => 8,
        "approval_requirement_count" => 1,
        "policy_escalation_count" => 1,
        "realized_feedback_count" => 1,
        "resource_projection_review_count" => 1,
        "resource_suppression_count" => 1,
        "contact_suppression_count" => 1,
        "link_capacity_review_count" => 1,
        "timeline_diff_count" => 1,
        "row_derived_review_type_counts" => %{
          "approval_requirement" => 1,
          "contact_suppression" => 1,
          "link_capacity_review" => 1,
          "policy_escalation" => 1,
          "realized_feedback" => 1,
          "resource_projection_review" => 1,
          "resource_suppression" => 1,
          "timeline_diff_review" => 1
        },
        "row_derived_required_operator_action_counts" => %{
          "approve_manual_contact" => 1,
          "review_contact_variance" => 1,
          "review_link_capacity_summary" => 1,
          "review_policy_escalation" => 1,
          "review_resource_projection" => 1,
          "review_suppressed_contact" => 1,
          "review_suppressed_observation" => 1,
          "review_timeline_change" => 1
        },
        "row_derived_review_queue_counts" => %{
          "approval_requirement|approve_manual_contact|operator_review_required" => 1,
          "contact_suppression|review_suppressed_contact|operator_review_required" => 1,
          "link_capacity_review|review_link_capacity_summary|operator_review_required" => 1,
          "policy_escalation|review_policy_escalation|operator_review_required" => 1,
          "realized_feedback|review_contact_variance|operator_review_required" => 1,
          "resource_projection_review|review_resource_projection|operator_review_required" => 1,
          "resource_suppression|review_suppressed_observation|operator_review_required" => 1,
          "timeline_diff_review|review_timeline_change|operator_review_required" => 1
        },
        "row_derived_review_row_ids_by_type" => %{
          "approval_requirement" => ["approval:operator_review_package:manual_contact:1"],
          "contact_suppression" => ["contact_suppression:leo_1_downlink_equator_prime_1:1"],
          "link_capacity_review" => ["link_capacity:equator_prime:1"],
          "policy_escalation" => ["policy_escalation:contact_execution_coordination:1"],
          "realized_feedback" => ["realized_feedback:downlink_equator:1"],
          "resource_projection_review" => ["resource_projection:leo_1:1"],
          "resource_suppression" => ["resource_suppression:leo_1_observe_target_a_1:1"],
          "timeline_diff_review" => ["timeline_diff:timeline:downlink_equator:1"]
        }
      },
      "tolerances" => %{
        "review_count" => 0,
        "row_derived_review_count" => 0,
        "approval_requirement_count" => 0,
        "policy_escalation_count" => 0,
        "realized_feedback_count" => 0,
        "resource_projection_review_count" => 0,
        "resource_suppression_count" => 0,
        "contact_suppression_count" => 0,
        "link_capacity_review_count" => 0,
        "timeline_diff_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external operations validation",
        "checks operator-review import surface counts only"
      ]
    },
    "fixture.artifact.operational_execution_boundary_summary.v1" => %{
      "id" => "fixture.artifact.operational_execution_boundary_summary.v1",
      "model_id" => "artifact.operational_execution_boundary_summary.v1",
      "reference_case" =>
        "checked-in operational execution boundary summary from ready readiness evidence",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/operational_execution_boundary_summary_v1.json",
        "source_contract" => "operational_readiness_report.v1",
        "contract" => "operational_execution_boundary_summary.v1",
        "source_artifact_type" => "planned_activity.v1"
      },
      "expected" => %{
        "schema_contract" => "operational_execution_boundary_summary.v1",
        "model" => "artifact_only_operational_execution_boundary_summary",
        "source" => "operational_readiness_report.v1",
        "source_artifact_type" => "planned_activity.v1",
        "source_artifact_id" => "activity_1",
        "readiness_level" => "import_eligible",
        "import_classification" => "importable",
        "status" => "passed",
        "import_eligible" => true,
        "handoff_only" => true,
        "execution_allowed" => false,
        "cadence_write_allowed" => false,
        "operator_authority_granted" => false,
        "execution_boundary" => "adapter_handoff_only",
        "operational_mode_gate_id" => "operational_mode",
        "operational_mode_gate_status" => "passed",
        "operational_mode_gate_classification" => "importable",
        "gate_count" => 5,
        "passed_gate_count" => 5,
        "review_gate_count" => 0,
        "analysis_gate_count" => 0,
        "blocked_gate_count" => 0,
        "non_passed_gate_count" => 0,
        "non_passed_gate_keys" => "",
        "model_limit_count" => 2,
        "assumption_execution_boundary" => "artifact_only_no_cadence_write_no_command_execution",
        "operator_authority" => "not_granted_by_execution_boundary_summary",
        "cadence_write" => "not_performed_by_summary",
        "command_execution" => "not_performed_by_summary",
        "assumption_source" => "operational_readiness_report.v1"
      },
      "tolerances" => %{
        "gate_count" => 0,
        "passed_gate_count" => 0,
        "review_gate_count" => 0,
        "analysis_gate_count" => 0,
        "blocked_gate_count" => 0,
        "non_passed_gate_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by operational_execution_boundary_summary.v1 validation tests"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external operations validation",
        "checks execution/write/authority denial, gate counts, and handoff boundary only"
      ]
    },
    "fixture.artifact.operational_import_eligibility_summary.v1" => %{
      "id" => "fixture.artifact.operational_import_eligibility_summary.v1",
      "model_id" => "artifact.operational_import_eligibility_summary.v1",
      "reference_case" =>
        "checked-in operational import eligibility summary from ready readiness evidence",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/operational_import_eligibility_summary_v1.json",
        "source_contract" => "operational_readiness_report.v1",
        "contract" => "operational_import_eligibility_summary.v1",
        "source_artifact_type" => "planned_activity.v1"
      },
      "expected" => %{
        "schema_contract" => "operational_import_eligibility_summary.v1",
        "model" => "artifact_only_import_eligibility_summary",
        "source" => "operational_readiness_report.v1",
        "source_artifact_type" => "planned_activity.v1",
        "source_artifact_id" => "activity_1",
        "readiness_level" => "import_eligible",
        "import_classification" => "importable",
        "status" => "passed",
        "import_eligible" => true,
        "gate_count" => 5,
        "passed_gate_count" => 5,
        "review_gate_count" => 0,
        "analysis_gate_count" => 0,
        "blocked_gate_count" => 0,
        "non_passed_gate_count" => 0,
        "row_derived_non_passed_gate_count" => 0,
        "non_passed_gate_keys" => "",
        "model_limit_count" => 2,
        "execution_boundary" => "artifact_only_no_cadence_write",
        "operator_authority" => "not_granted_by_summary",
        "assumption_source" => "operational_readiness_report.v1"
      },
      "tolerances" => %{
        "gate_count" => 0,
        "passed_gate_count" => 0,
        "review_gate_count" => 0,
        "analysis_gate_count" => 0,
        "blocked_gate_count" => 0,
        "non_passed_gate_count" => 0,
        "row_derived_non_passed_gate_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by operational_import_eligibility_summary.v1 validation tests"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external operations validation",
        "checks import eligibility, gate counts, and no-authority boundary only"
      ]
    },
    "fixture.artifact.operational_readiness_report.v1" => %{
      "id" => "fixture.artifact.operational_readiness_report.v1",
      "model_id" => "artifact.operational_readiness_report.v1",
      "reference_case" =>
        "curated operational readiness report from ready Cadence import evidence",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/operational_readiness_report_v1.json",
        "source_contract" => "cadence_import_manifest.v1",
        "contract" => "operational_readiness_report.v1",
        "source_artifact_type" => "planned_activity.v1"
      },
      "expected" => %{
        "schema_contract" => "operational_readiness_report.v1",
        "model" => "artifact_only_operational_readiness_classifier",
        "report_id" => "operational_readiness:planned_activity.v1:activity_1",
        "source_artifact_type" => "planned_activity.v1",
        "source_artifact_id" => "activity_1",
        "readiness_level" => "import_eligible",
        "import_classification" => "importable",
        "status" => "passed",
        "gate_count" => 5,
        "row_derived_gate_count" => 5,
        "passed_gate_count" => 5,
        "row_derived_passed_gate_count" => 5,
        "review_gate_count" => 0,
        "row_derived_review_gate_count" => 0,
        "analysis_gate_count" => 0,
        "row_derived_analysis_gate_count" => 0,
        "blocked_gate_count" => 0,
        "row_derived_blocked_gate_count" => 0,
        "row_derived_gate_status_counts" => %{"passed" => 5},
        "row_derived_gate_classification_counts" => %{"importable" => 5},
        "row_derived_gate_ids_by_status" => %{
          "passed" => [
            "adapter_boundary",
            "cadence_import",
            "operational_mode",
            "operator_review",
            "source_contract"
          ]
        },
        "row_derived_gate_ids_by_classification" => %{
          "importable" => [
            "adapter_boundary",
            "cadence_import",
            "operational_mode",
            "operator_review",
            "source_contract"
          ]
        },
        "review_row_count" => 0,
        "import_row_count" => 1,
        "ready_for_import_count" => 1,
        "row_derived_ready_for_import_count" => 1,
        "manifest_review_required_count" => 0,
        "row_derived_manifest_review_required_count" => 0,
        "blocked_import_count" => 0,
        "row_derived_blocked_import_count" => 0,
        "missing_import_count" => 0,
        "row_derived_missing_import_count" => 0,
        "invalid_cadence_import_count" => 0,
        "row_derived_invalid_cadence_import_count" => 0,
        "current_freshness_count" => 0,
        "row_derived_current_freshness_count" => 0,
        "stale_freshness_count" => 0,
        "row_derived_stale_freshness_count" => 0,
        "unknown_freshness_count" => 0,
        "row_derived_unknown_freshness_count" => 0,
        "freshness_status_counts" => %{},
        "row_derived_freshness_status_counts" => %{},
        "schema_validation_pass_count" => 0,
        "row_derived_schema_validation_pass_count" => 0,
        "schema_validation_fail_count" => 0,
        "row_derived_schema_validation_fail_count" => 0,
        "schema_validation_error_count" => 0,
        "row_derived_schema_validation_error_count" => 0,
        "schema_validation_warning_count" => 0,
        "row_derived_schema_validation_warning_count" => 0,
        "schema_validation_remediation_count" => 0,
        "row_derived_schema_validation_remediation_count" => 0,
        "schema_validation_status_counts" => %{},
        "row_derived_schema_validation_status_counts" => %{},
        "import_status_counts" => %{"ready_for_import" => 1},
        "row_derived_import_status_counts" => %{"ready_for_import" => 1},
        "cadence_import_status_counts" => %{"present" => 1},
        "row_derived_cadence_import_status_counts" => %{"present" => 1},
        "source_model_count" => 1,
        "source_model_limit_count" => 1,
        "adapter_context_count" => 0,
        "adapter_trust_boundary_missing_count" => 0
      },
      "tolerances" => %{
        "gate_count" => 0,
        "row_derived_gate_count" => 0,
        "passed_gate_count" => 0,
        "row_derived_passed_gate_count" => 0,
        "review_gate_count" => 0,
        "row_derived_review_gate_count" => 0,
        "analysis_gate_count" => 0,
        "row_derived_analysis_gate_count" => 0,
        "blocked_gate_count" => 0,
        "row_derived_blocked_gate_count" => 0,
        "review_row_count" => 0,
        "import_row_count" => 0,
        "ready_for_import_count" => 0,
        "row_derived_ready_for_import_count" => 0,
        "manifest_review_required_count" => 0,
        "row_derived_manifest_review_required_count" => 0,
        "blocked_import_count" => 0,
        "row_derived_blocked_import_count" => 0,
        "missing_import_count" => 0,
        "row_derived_missing_import_count" => 0,
        "invalid_cadence_import_count" => 0,
        "row_derived_invalid_cadence_import_count" => 0,
        "current_freshness_count" => 0,
        "row_derived_current_freshness_count" => 0,
        "stale_freshness_count" => 0,
        "row_derived_stale_freshness_count" => 0,
        "unknown_freshness_count" => 0,
        "row_derived_unknown_freshness_count" => 0,
        "schema_validation_pass_count" => 0,
        "row_derived_schema_validation_pass_count" => 0,
        "schema_validation_fail_count" => 0,
        "row_derived_schema_validation_fail_count" => 0,
        "schema_validation_error_count" => 0,
        "row_derived_schema_validation_error_count" => 0,
        "schema_validation_warning_count" => 0,
        "row_derived_schema_validation_warning_count" => 0,
        "schema_validation_remediation_count" => 0,
        "row_derived_schema_validation_remediation_count" => 0,
        "source_model_count" => 0,
        "source_model_limit_count" => 0,
        "adapter_context_count" => 0,
        "adapter_trust_boundary_missing_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by operational_readiness_report.v1 validation tests"
      ],
      "known_limits" => [
        "internal artifact regression, not external operations validation",
        "checks readiness classification and evidence counts only"
      ]
    },
    "fixture.artifact.operational_readiness_gate_summary.v1" => %{
      "id" => "fixture.artifact.operational_readiness_gate_summary.v1",
      "model_id" => "artifact.operational_readiness_gate_summary.v1",
      "reference_case" =>
        "checked-in operational readiness gate summary from ready readiness evidence",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/operational_readiness_gate_summary_v1.json",
        "source_contract" => "operational_readiness_report.v1",
        "contract" => "operational_readiness_gate_summary.v1",
        "source_artifact_type" => "planned_activity.v1"
      },
      "expected" => %{
        "schema_contract" => "operational_readiness_gate_summary.v1",
        "model" => "artifact_only_operational_readiness_gate_summary",
        "source" => "operational_readiness_report.v1",
        "source_artifact_type" => "planned_activity.v1",
        "source_artifact_id" => "activity_1",
        "readiness_level" => "import_eligible",
        "import_classification" => "importable",
        "status" => "passed",
        "gate_count" => 5,
        "row_derived_gate_count" => 5,
        "passed_gate_count" => 5,
        "row_derived_passed_gate_count" => 5,
        "review_gate_count" => 0,
        "row_derived_review_gate_count" => 0,
        "analysis_gate_count" => 0,
        "row_derived_analysis_gate_count" => 0,
        "blocked_gate_count" => 0,
        "row_derived_blocked_gate_count" => 0,
        "non_passed_gate_count" => 0,
        "row_derived_non_passed_gate_count" => 0,
        "gate_status_counts" => %{"passed" => 5},
        "row_derived_gate_status_counts" => %{"passed" => 5},
        "gate_classification_counts" => %{"importable" => 5},
        "row_derived_gate_classification_counts" => %{"importable" => 5},
        "gate_ids_by_status" => %{
          "passed" => [
            "adapter_boundary",
            "cadence_import",
            "operational_mode",
            "operator_review",
            "source_contract"
          ]
        },
        "row_derived_gate_ids_by_status" => %{
          "passed" => [
            "adapter_boundary",
            "cadence_import",
            "operational_mode",
            "operator_review",
            "source_contract"
          ]
        },
        "gate_ids_by_classification" => %{
          "importable" => [
            "adapter_boundary",
            "cadence_import",
            "operational_mode",
            "operator_review",
            "source_contract"
          ]
        },
        "row_derived_gate_ids_by_classification" => %{
          "importable" => [
            "adapter_boundary",
            "cadence_import",
            "operational_mode",
            "operator_review",
            "source_contract"
          ]
        },
        "passed_gate_keys" =>
          "source_contract|operational_mode|adapter_boundary|operator_review|cadence_import",
        "non_passed_gate_keys" => "",
        "model_limit_count" => 2,
        "execution_boundary" => "artifact_only_no_cadence_write",
        "operator_authority" => "not_granted_by_summary",
        "assumption_source" => "operational_readiness_report.v1"
      },
      "tolerances" => %{
        "gate_count" => 0,
        "row_derived_gate_count" => 0,
        "passed_gate_count" => 0,
        "row_derived_passed_gate_count" => 0,
        "review_gate_count" => 0,
        "row_derived_review_gate_count" => 0,
        "analysis_gate_count" => 0,
        "row_derived_analysis_gate_count" => 0,
        "blocked_gate_count" => 0,
        "row_derived_blocked_gate_count" => 0,
        "non_passed_gate_count" => 0,
        "row_derived_non_passed_gate_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by operational_readiness_gate_summary.v1 validation tests"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external operations validation",
        "checks gate routing maps, gate counts, and no-authority boundary only"
      ]
    },
    "fixture.artifact.quality_gate_report.v1" => %{
      "id" => "fixture.artifact.quality_gate_report.v1",
      "model_id" => "artifact.quality_gate_report.v1",
      "reference_case" => "curated quality gate report from ready operational readiness evidence",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "source_contract" => "operational_readiness_report.v1",
        "contract" => "quality_gate_report.v1",
        "source_artifact_type" => "planned_activity.v1"
      },
      "expected" => %{
        "schema_contract" => "quality_gate_report.v1",
        "model" => "artifact_only_operational_quality_gate_report",
        "report_id" => "quality_gate:planned_activity.v1:activity_1",
        "source_artifact_type" => "planned_activity.v1",
        "source_artifact_id" => "activity_1",
        "source_readiness_report_id" => "operational_readiness:planned_activity.v1:activity_1",
        "readiness_level" => "import_eligible",
        "import_classification" => "importable",
        "status" => "passed",
        "gate_count" => 5,
        "row_derived_gate_count" => 5,
        "passed_gate_count" => 5,
        "row_derived_passed_gate_count" => 5,
        "review_gate_count" => 0,
        "row_derived_review_gate_count" => 0,
        "analysis_gate_count" => 0,
        "row_derived_analysis_gate_count" => 0,
        "blocked_gate_count" => 0,
        "row_derived_blocked_gate_count" => 0,
        "row_count" => 5,
        "gate_status_counts" => %{"passed" => 5},
        "row_derived_gate_status_counts" => %{"passed" => 5},
        "gate_classification_counts" => %{"importable" => 5},
        "row_derived_gate_classification_counts" => %{"importable" => 5},
        "gate_ids_by_status" => %{
          "passed" => [
            "adapter_boundary",
            "cadence_import",
            "operational_mode",
            "operator_review",
            "source_contract"
          ]
        },
        "row_derived_gate_ids_by_status" => %{
          "passed" => [
            "adapter_boundary",
            "cadence_import",
            "operational_mode",
            "operator_review",
            "source_contract"
          ]
        },
        "gate_ids_by_classification" => %{
          "importable" => [
            "adapter_boundary",
            "cadence_import",
            "operational_mode",
            "operator_review",
            "source_contract"
          ]
        },
        "row_derived_gate_ids_by_classification" => %{
          "importable" => [
            "adapter_boundary",
            "cadence_import",
            "operational_mode",
            "operator_review",
            "source_contract"
          ]
        },
        "row_derived_ready_for_import_count" => 1,
        "row_derived_manifest_review_required_count" => 0,
        "row_derived_blocked_import_count" => 0,
        "row_derived_missing_import_count" => 0,
        "row_derived_invalid_cadence_import_count" => 0,
        "row_derived_current_freshness_count" => 0,
        "row_derived_stale_freshness_count" => 0,
        "row_derived_unknown_freshness_count" => 0,
        "row_derived_freshness_status_counts" => %{},
        "row_derived_schema_validation_pass_count" => 0,
        "row_derived_schema_validation_fail_count" => 0,
        "row_derived_schema_validation_error_count" => 0,
        "row_derived_schema_validation_warning_count" => 0,
        "row_derived_schema_validation_remediation_count" => 0,
        "row_derived_schema_validation_status_counts" => %{},
        "row_derived_import_status_counts" => %{"ready_for_import" => 1},
        "row_derived_cadence_import_status_counts" => %{"present" => 1},
        "model_limit_count" => 2,
        "execution_boundary" => "artifact_only_no_cadence_write",
        "operator_authority" => "not_granted_by_quality_gate_report"
      },
      "tolerances" => %{
        "gate_count" => 0,
        "row_derived_gate_count" => 0,
        "passed_gate_count" => 0,
        "row_derived_passed_gate_count" => 0,
        "review_gate_count" => 0,
        "row_derived_review_gate_count" => 0,
        "analysis_gate_count" => 0,
        "row_derived_analysis_gate_count" => 0,
        "blocked_gate_count" => 0,
        "row_derived_blocked_gate_count" => 0,
        "row_count" => 0,
        "row_derived_ready_for_import_count" => 0,
        "row_derived_manifest_review_required_count" => 0,
        "row_derived_blocked_import_count" => 0,
        "row_derived_missing_import_count" => 0,
        "row_derived_invalid_cadence_import_count" => 0,
        "row_derived_current_freshness_count" => 0,
        "row_derived_stale_freshness_count" => 0,
        "row_derived_unknown_freshness_count" => 0,
        "row_derived_schema_validation_pass_count" => 0,
        "row_derived_schema_validation_fail_count" => 0,
        "row_derived_schema_validation_error_count" => 0,
        "row_derived_schema_validation_warning_count" => 0,
        "row_derived_schema_validation_remediation_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by quality_gate_report.v1 validation tests"
      ],
      "known_limits" => [
        "internal artifact regression, not external operations validation",
        "checks gate projection counts and authority boundary only"
      ]
    },
    "fixture.artifact.operational_quality_gate_summary.v1" => %{
      "id" => "fixture.artifact.operational_quality_gate_summary.v1",
      "model_id" => "artifact.operational_quality_gate_summary.v1",
      "reference_case" =>
        "checked-in quality gate summary from resource-pressure review evidence",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/operational_quality_gate_summary_v1.json",
        "source_contract" => "quality_gate_report.v1",
        "contract" => "operational_quality_gate_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "operational_quality_gate_summary.v1",
        "model" => "artifact_only_quality_gate_summary",
        "source" => "quality_gate_report.v1",
        "source_artifact_type" => "resource_projection_report.v1",
        "source_artifact_id" => "resource_summaries",
        "source_quality_gate_report_id" =>
          "quality_gate:resource_projection_report.v1:resource_summaries",
        "source_readiness_report_id" =>
          "operational_readiness:resource_projection_report.v1:resource_summaries",
        "readiness_level" => "operator_review",
        "import_classification" => "review_only",
        "status" => "review_required",
        "execution_allowed" => false,
        "cadence_write_allowed" => false,
        "operator_authority_granted" => false,
        "gate_count" => 6,
        "row_derived_gate_count" => 6,
        "passed_gate_count" => 3,
        "row_derived_passed_gate_count" => 3,
        "review_gate_count" => 3,
        "row_derived_review_gate_count" => 3,
        "analysis_gate_count" => 0,
        "row_derived_analysis_gate_count" => 0,
        "blocked_gate_count" => 0,
        "row_derived_blocked_gate_count" => 0,
        "non_passed_gate_count" => 3,
        "row_derived_non_passed_gate_count" => 3,
        "gate_status_counts" => %{"passed" => 3, "review_required" => 3},
        "row_derived_gate_status_counts" => %{"passed" => 3, "review_required" => 3},
        "gate_classification_counts" => %{"importable" => 3, "review_only" => 3},
        "row_derived_gate_classification_counts" => %{
          "importable" => 3,
          "review_only" => 3
        },
        "gate_ids_by_status" => %{
          "passed" => ["adapter_boundary", "operational_mode", "source_contract"],
          "review_required" => ["cadence_import", "operator_review", "resource_availability"]
        },
        "row_derived_gate_ids_by_status" => %{
          "passed" => ["adapter_boundary", "operational_mode", "source_contract"],
          "review_required" => ["cadence_import", "operator_review", "resource_availability"]
        },
        "gate_ids_by_classification" => %{
          "importable" => ["adapter_boundary", "operational_mode", "source_contract"],
          "review_only" => ["cadence_import", "operator_review", "resource_availability"]
        },
        "row_derived_gate_ids_by_classification" => %{
          "importable" => ["adapter_boundary", "operational_mode", "source_contract"],
          "review_only" => ["cadence_import", "operator_review", "resource_availability"]
        },
        "non_passed_gate_keys" => "cadence_import|operator_review|resource_availability",
        "row_derived_non_passed_gate_keys" =>
          "cadence_import|operator_review|resource_availability",
        "non_passed_quality_gate_row_keys" =>
          "quality_gate:resource_projection_report.v1:resource_summaries:cadence_import:6|quality_gate:resource_projection_report.v1:resource_summaries:operator_review:5|quality_gate:resource_projection_report.v1:resource_summaries:resource_availability:4",
        "row_derived_non_passed_quality_gate_row_keys" =>
          "quality_gate:resource_projection_report.v1:resource_summaries:cadence_import:6|quality_gate:resource_projection_report.v1:resource_summaries:operator_review:5|quality_gate:resource_projection_report.v1:resource_summaries:resource_availability:4",
        "row_derived_non_passed_quality_gate_row_count" => 3,
        "model_limit_count" => 2,
        "execution_boundary" => "artifact_only_no_cadence_write",
        "operator_authority" => "not_granted_by_quality_gate_summary",
        "cadence_write" => "not_performed_by_summary",
        "command_execution" => "not_performed_by_summary"
      },
      "tolerances" => %{
        "gate_count" => 0,
        "row_derived_gate_count" => 0,
        "passed_gate_count" => 0,
        "row_derived_passed_gate_count" => 0,
        "review_gate_count" => 0,
        "row_derived_review_gate_count" => 0,
        "analysis_gate_count" => 0,
        "row_derived_analysis_gate_count" => 0,
        "blocked_gate_count" => 0,
        "row_derived_blocked_gate_count" => 0,
        "non_passed_gate_count" => 0,
        "row_derived_non_passed_gate_count" => 0,
        "row_derived_non_passed_quality_gate_row_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by operational_quality_gate_summary.v1 validation tests"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external operations validation",
        "checks base quality-gate summary routing, review pressure, and no-authority boundary only"
      ]
    },
    "fixture.artifact.operational_quality_gate_import_readiness_summary.v1" => %{
      "id" => "fixture.artifact.operational_quality_gate_import_readiness_summary.v1",
      "model_id" => "artifact.operational_quality_gate_import_readiness_summary.v1",
      "reference_case" =>
        "checked-in quality gate import-readiness summary from stale freshness evidence",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" =>
          "study_results/operational_quality_gate_import_readiness_summary_v1.json",
        "source_contract" => "quality_gate_report.v1",
        "contract" => "operational_quality_gate_import_readiness_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "operational_quality_gate_import_readiness_summary.v1",
        "model" => "artifact_only_quality_gate_import_readiness_summary",
        "source" => "quality_gate_report.v1",
        "source_artifact_type" => "planned_activity.v1",
        "source_artifact_id" => "activity_1",
        "source_quality_gate_report_id" => "quality_gate:planned_activity.v1:activity_1",
        "source_readiness_report_id" => "operational_readiness:planned_activity.v1:activity_1",
        "import_readiness_row_count" => 1,
        "ready_for_import_count" => 1,
        "row_derived_ready_for_import_count" => 1,
        "manifest_review_required_count" => 0,
        "blocked_import_count" => 0,
        "missing_import_count" => 0,
        "invalid_cadence_import_count" => 0,
        "current_freshness_count" => 0,
        "stale_freshness_count" => 1,
        "row_derived_stale_freshness_count" => 1,
        "unknown_freshness_count" => 0,
        "freshness_status_counts" => %{"stale" => 1},
        "freshness_status_keys" => "stale",
        "import_status_counts" => %{"ready_for_import" => 1},
        "import_status_keys" => "ready_for_import",
        "cadence_import_status_counts" => %{"present" => 1},
        "cadence_import_status_keys" => "present",
        "row_derived_cadence_import_present_count" => 1,
        "freshness_review_required" => true,
        "import_preparation_required" => false,
        "import_blocked" => false,
        "quality_gate_row_ids_by_status" => %{
          "review_required" => ["quality_gate:planned_activity.v1:activity_1:cadence_import:5"]
        },
        "quality_gate_ids_by_status" => %{"review_required" => ["cadence_import"]},
        "review_required_quality_gate_row_keys" =>
          "quality_gate:planned_activity.v1:activity_1:cadence_import:5",
        "blocked_quality_gate_row_keys" => "",
        "ready_quality_gate_row_keys" => "",
        "analysis_only_quality_gate_row_keys" => "",
        "stale_or_unknown_freshness_quality_gate_row_keys" =>
          "quality_gate:planned_activity.v1:activity_1:cadence_import:5",
        "import_preparation_quality_gate_row_keys" => "",
        "blocked_import_quality_gate_row_keys" => "",
        "import_readiness_gate_keys" => "cadence_import",
        "row_derived_review_required_quality_gate_row_count" => 1,
        "row_derived_stale_or_unknown_freshness_quality_gate_row_count" => 1,
        "execution_boundary" => "artifact_only_no_cadence_write",
        "operator_authority" => "not_granted_by_import_readiness_summary",
        "cadence_write" => "not_performed_by_summary",
        "command_execution" => "not_performed_by_summary",
        "model_limit_count" => 2
      },
      "tolerances" => %{
        "import_readiness_row_count" => 0,
        "ready_for_import_count" => 0,
        "row_derived_ready_for_import_count" => 0,
        "manifest_review_required_count" => 0,
        "blocked_import_count" => 0,
        "missing_import_count" => 0,
        "invalid_cadence_import_count" => 0,
        "current_freshness_count" => 0,
        "stale_freshness_count" => 0,
        "row_derived_stale_freshness_count" => 0,
        "unknown_freshness_count" => 0,
        "row_derived_cadence_import_present_count" => 0,
        "row_derived_review_required_quality_gate_row_count" => 0,
        "row_derived_stale_or_unknown_freshness_quality_gate_row_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by operational_quality_gate_import_readiness_summary.v1 validation tests"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external operations validation",
        "checks import-readiness status maps, freshness review routing, and no-authority boundary only"
      ]
    },
    "fixture.artifact.operational_quality_gate_unavailable_resource_summary.v1" => %{
      "id" => "fixture.artifact.operational_quality_gate_unavailable_resource_summary.v1",
      "model_id" => "artifact.operational_quality_gate_unavailable_resource_summary.v1",
      "reference_case" =>
        "generated quality gate unavailable-resource summary from contact allocation resource pressure",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "source_contract" => "quality_gate_report.v1",
        "contract" => "operational_quality_gate_unavailable_resource_summary.v1",
        "source_artifact_type" => "contact_allocation_report.v1"
      },
      "expected" => %{
        "schema_contract" => "operational_quality_gate_unavailable_resource_summary.v1",
        "model" => "artifact_only_quality_gate_unavailable_resource_summary",
        "source" => "quality_gate_report.v1",
        "source_artifact_type" => "contact_allocation_report.v1",
        "source_artifact_id" => "validation_unavailable_resource_fixture",
        "source_quality_gate_report_id" =>
          "quality_gate:contact_allocation_report.v1:validation_unavailable_resource_fixture",
        "source_readiness_report_id" =>
          "operational_readiness:contact_allocation_report.v1:validation_unavailable_resource_fixture",
        "resource_availability_row_count" => 1,
        "row_derived_resource_availability_row_count" => 1,
        "unavailable_resource_row_count" => 1,
        "unavailable_resource_pressure_count" => 1,
        "row_derived_unavailable_resource_pressure_count" => 1,
        "unavailable_resource_reason_counts" => %{"antenna_unavailable" => 1},
        "unavailable_resource_reason_keys" => "antenna_unavailable",
        "station_availability_reason_counts" => %{},
        "station_availability_reason_keys" => "",
        "resource_blocking_dimension_counts" => %{"antenna" => 1},
        "blocked_contact_ids_by_blocking_dimension" => %{"antenna" => ["dl_resource_blocked"]},
        "blocked_contact_ids_by_spacecraft_id" => %{"leo_1" => ["dl_resource_blocked"]},
        "blocked_contact_ids_by_status" => %{"review_required" => ["dl_resource_blocked"]},
        "quality_gate_row_ids_by_status" => %{
          "review_required" => [
            "quality_gate:contact_allocation_report.v1:validation_unavailable_resource_fixture:resource_availability:4"
          ]
        },
        "quality_gate_ids_by_status" => %{"review_required" => ["resource_availability"]},
        "review_required_quality_gate_row_keys" =>
          "quality_gate:contact_allocation_report.v1:validation_unavailable_resource_fixture:resource_availability:4",
        "blocked_quality_gate_row_keys" => "",
        "resource_availability_gate_keys" => "resource_availability",
        "row_derived_review_required_quality_gate_row_count" => 1,
        "row_derived_blocked_quality_gate_row_count" => 0,
        "execution_boundary" => "artifact_only_no_cadence_write",
        "operator_authority" => "not_granted_by_unavailable_resource_summary",
        "cadence_write" => "not_performed_by_summary",
        "command_execution" => "not_performed_by_summary",
        "model_limit_count" => 2
      },
      "tolerances" => %{
        "resource_availability_row_count" => 0,
        "row_derived_resource_availability_row_count" => 0,
        "unavailable_resource_row_count" => 0,
        "unavailable_resource_pressure_count" => 0,
        "row_derived_unavailable_resource_pressure_count" => 0,
        "row_derived_review_required_quality_gate_row_count" => 0,
        "row_derived_blocked_quality_gate_row_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by operational_quality_gate_unavailable_resource_summary.v1 validation tests"
      ],
      "known_limits" => [
        "internal generated artifact regression, not external operations validation",
        "checks unavailable-resource reason maps, row-status routing, contact ID maps, and no-authority boundary only"
      ]
    },
    "fixture.artifact.operational_quality_gate_unavailable_resource_summary.resource_projection_v1" =>
      %{
        "id" =>
          "fixture.artifact.operational_quality_gate_unavailable_resource_summary.resource_projection_v1",
        "model_id" => "artifact.operational_quality_gate_unavailable_resource_summary.v1",
        "reference_case" =>
          "checked-in quality gate unavailable-resource summary from resource projection pressure",
        "validation_level" => "artifact_contract",
        "fixture_type" => "curated_internal_artifact_regression",
        "inputs" => %{
          "artifact_path" =>
            "study_results/operational_quality_gate_unavailable_resource_summary_v1.json",
          "contract" => "operational_quality_gate_unavailable_resource_summary.v1",
          "source_artifact_type" => "resource_projection_report.v1"
        },
        "expected" => %{
          "schema_contract" => "operational_quality_gate_unavailable_resource_summary.v1",
          "model" => "artifact_only_quality_gate_unavailable_resource_summary",
          "source" => "quality_gate_report.v1",
          "source_artifact_type" => "resource_projection_report.v1",
          "source_artifact_id" => "resource_summaries",
          "source_quality_gate_report_id" =>
            "quality_gate:resource_projection_report.v1:resource_summaries",
          "source_readiness_report_id" =>
            "operational_readiness:resource_projection_report.v1:resource_summaries",
          "resource_availability_row_count" => 1,
          "row_derived_resource_availability_row_count" => 1,
          "unavailable_resource_row_count" => 1,
          "unavailable_resource_pressure_count" => 2,
          "row_derived_unavailable_resource_pressure_count" => 2,
          "unavailable_resource_reason_counts" => %{
            "antenna_unavailable" => 1,
            "payload_unavailable" => 1
          },
          "unavailable_resource_reason_keys" => "antenna_unavailable|payload_unavailable",
          "station_availability_reason_counts" => %{},
          "station_availability_reason_keys" => "",
          "resource_blocking_dimension_counts" => %{},
          "blocked_contact_ids_by_blocking_dimension" => %{},
          "blocked_contact_ids_by_spacecraft_id" => %{},
          "blocked_contact_ids_by_status" => %{},
          "quality_gate_row_ids_by_status" => %{
            "review_required" => [
              "quality_gate:resource_projection_report.v1:resource_summaries:resource_availability:4"
            ]
          },
          "quality_gate_ids_by_status" => %{"review_required" => ["resource_availability"]},
          "review_required_quality_gate_row_keys" =>
            "quality_gate:resource_projection_report.v1:resource_summaries:resource_availability:4",
          "blocked_quality_gate_row_keys" => "",
          "resource_availability_gate_keys" => "resource_availability",
          "row_derived_review_required_quality_gate_row_count" => 1,
          "row_derived_blocked_quality_gate_row_count" => 0,
          "execution_boundary" => "artifact_only_no_cadence_write",
          "operator_authority" => "not_granted_by_unavailable_resource_summary",
          "cadence_write" => "not_performed_by_summary",
          "command_execution" => "not_performed_by_summary",
          "model_limit_count" => 2
        },
        "tolerances" => %{
          "resource_availability_row_count" => 0,
          "row_derived_resource_availability_row_count" => 0,
          "unavailable_resource_row_count" => 0,
          "unavailable_resource_pressure_count" => 0,
          "row_derived_unavailable_resource_pressure_count" => 0,
          "row_derived_review_required_quality_gate_row_count" => 0,
          "row_derived_blocked_quality_gate_row_count" => 0,
          "model_limit_count" => 0
        },
        "evidence" => [
          "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
          "schema-linted by mix orbital_dynamics.schema.lint"
        ],
        "known_limits" => [
          "internal checked-in artifact regression, not external operations validation",
          "checks resource-projection unavailable-resource reason maps, review routing, and no-authority boundary only"
        ]
      },
    "fixture.artifact.operational_quality_gate_operator_training_summary.v1" => %{
      "id" => "fixture.artifact.operational_quality_gate_operator_training_summary.v1",
      "model_id" => "artifact.operational_quality_gate_operator_training_summary.v1",
      "reference_case" =>
        "checked-in quality gate operator-training summary from review-required training evidence",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" =>
          "study_results/operational_quality_gate_operator_training_summary_v1.json",
        "source_contract" => "quality_gate_report.v1",
        "contract" => "operational_quality_gate_operator_training_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "operational_quality_gate_operator_training_summary.v1",
        "model" => "artifact_only_quality_gate_operator_training_summary",
        "source" => "quality_gate_report.v1",
        "source_artifact_type" => "planned_activity.v1",
        "source_artifact_id" => "activity_1",
        "source_quality_gate_report_id" => "quality_gate:planned_activity.v1:activity_1",
        "source_readiness_report_id" => "operational_readiness:planned_activity.v1:activity_1",
        "operator_training_row_count" => 1,
        "operator_training_requirement_count" => 5,
        "row_derived_operator_training_requirement_count" => 5,
        "operator_training_requirement_counts" => %{
          "certification" => 1,
          "operator_role" => 2,
          "qualification" => 1,
          "training" => 1
        },
        "operator_training_requirement_keys" =>
          "certification|operator_role|qualification|training",
        "required_operator_role_keys" => "contact_operator|mission_director",
        "required_training_keys" => "contact_replan_drill",
        "required_certification_keys" => "cadence_import_cert",
        "required_qualification_keys" => "sat_ops_current",
        "quality_gate_row_ids_by_status" => %{
          "review_required" => [
            "quality_gate:planned_activity.v1:activity_1:operator_training:4"
          ]
        },
        "quality_gate_row_ids_by_classification" => %{
          "review_only" => [
            "quality_gate:planned_activity.v1:activity_1:operator_training:4"
          ]
        },
        "quality_gate_ids_by_status" => %{"review_required" => ["operator_training"]},
        "quality_gate_ids_by_classification" => %{"review_only" => ["operator_training"]},
        "review_required_quality_gate_row_keys" =>
          "quality_gate:planned_activity.v1:activity_1:operator_training:4",
        "blocked_quality_gate_row_keys" => "",
        "review_only_quality_gate_row_keys" =>
          "quality_gate:planned_activity.v1:activity_1:operator_training:4",
        "operator_training_gate_keys" => "operator_training",
        "operator_training_review_required" => true,
        "row_derived_review_required_quality_gate_row_count" => 1,
        "row_derived_review_only_quality_gate_row_count" => 1,
        "execution_boundary" => "artifact_only_no_cadence_write",
        "operator_authority" => "not_granted_by_operator_training_summary",
        "cadence_write" => "not_performed_by_summary",
        "command_execution" => "not_performed_by_summary",
        "model_limit_count" => 2
      },
      "tolerances" => %{
        "operator_training_row_count" => 0,
        "operator_training_requirement_count" => 0,
        "row_derived_operator_training_requirement_count" => 0,
        "row_derived_review_required_quality_gate_row_count" => 0,
        "row_derived_review_only_quality_gate_row_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by operational_quality_gate_operator_training_summary.v1 validation tests"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external operations validation",
        "checks operator-training requirement routing and no-authority boundary only"
      ]
    },
    "fixture.artifact.operational_quality_gate_schema_validation_summary.v1" => %{
      "id" => "fixture.artifact.operational_quality_gate_schema_validation_summary.v1",
      "model_id" => "artifact.operational_quality_gate_schema_validation_summary.v1",
      "reference_case" =>
        "checked-in quality gate schema-validation summary from failed schema evidence",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" =>
          "study_results/operational_quality_gate_schema_validation_summary_v1.json",
        "source_contract" => "quality_gate_report.v1",
        "contract" => "operational_quality_gate_schema_validation_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "operational_quality_gate_schema_validation_summary.v1",
        "model" => "artifact_only_quality_gate_schema_validation_summary",
        "source" => "quality_gate_report.v1",
        "source_artifact_type" => "planned_activity.v1",
        "source_artifact_id" => "activity_1",
        "source_quality_gate_report_id" => "quality_gate:planned_activity.v1:activity_1",
        "source_readiness_report_id" => "operational_readiness:planned_activity.v1:activity_1",
        "schema_validation_row_count" => 1,
        "schema_validation_pass_count" => 0,
        "row_derived_schema_validation_pass_count" => 0,
        "schema_validation_fail_count" => 1,
        "row_derived_schema_validation_fail_count" => 1,
        "schema_validation_error_count" => 1,
        "schema_validation_warning_count" => 0,
        "schema_validation_remediation_count" => 1,
        "schema_validation_status_counts" => %{"fail" => 1},
        "schema_validation_status_keys" => "fail",
        "schema_validation_import_blocked" => true,
        "quality_gate_row_ids_by_status" => %{
          "blocked" => ["quality_gate:planned_activity.v1:activity_1:cadence_import:5"]
        },
        "quality_gate_ids_by_status" => %{"blocked" => ["cadence_import"]},
        "blocked_quality_gate_row_keys" =>
          "quality_gate:planned_activity.v1:activity_1:cadence_import:5",
        "review_required_quality_gate_row_keys" => "",
        "failed_schema_validation_quality_gate_row_keys" =>
          "quality_gate:planned_activity.v1:activity_1:cadence_import:5",
        "schema_validation_gate_keys" => "cadence_import",
        "row_derived_blocked_quality_gate_row_count" => 1,
        "row_derived_failed_schema_validation_quality_gate_row_count" => 1,
        "execution_boundary" => "artifact_only_no_cadence_write",
        "operator_authority" => "not_granted_by_schema_validation_summary",
        "cadence_write" => "not_performed_by_summary",
        "command_execution" => "not_performed_by_summary",
        "model_limit_count" => 2
      },
      "tolerances" => %{
        "schema_validation_row_count" => 0,
        "schema_validation_pass_count" => 0,
        "row_derived_schema_validation_pass_count" => 0,
        "schema_validation_fail_count" => 0,
        "row_derived_schema_validation_fail_count" => 0,
        "schema_validation_error_count" => 0,
        "schema_validation_warning_count" => 0,
        "schema_validation_remediation_count" => 0,
        "row_derived_blocked_quality_gate_row_count" => 0,
        "row_derived_failed_schema_validation_quality_gate_row_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by operational_quality_gate_schema_validation_summary.v1 validation tests"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external operations validation",
        "checks schema-validation status maps, blocked row routing, and no-authority boundary only"
      ]
    },
    "fixture.artifact.station_calendar_report.stale_provider_reservation_hold" => %{
      "id" => "fixture.artifact.station_calendar_report.stale_provider_reservation_hold",
      "model_id" => "artifact.station_calendar_report.v1",
      "reference_case" =>
        "curated station calendar report from stale but plausible provider reservation hold",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "provider_contract" => "station_calendar_provider.v1",
        "contract" => "station_calendar_report.v1",
        "provider_entry_status" => "reservation_hold"
      },
      "expected" => %{
        "schema_contract" => "station_calendar_report.v1",
        "model" => "campaign_ground_network_interval_overlay",
        "input_contact_count" => 1,
        "calendar_entry_count" => 1,
        "affected_contact_count" => 1,
        "affected_duration_s" => 40.0,
        "provider_calendar_contention_group_count" => 0,
        "duplicate_affected_contact_id_count" => 0,
        "duplicate_affected_contact_row_count" => 0,
        "affected_contact_ground_station_counts" => %{"equator_prime" => 1},
        "row_derived_affected_contact_ground_station_counts" => %{"equator_prime" => 1},
        "affected_contact_availability_counts" => %{"reserved" => 1},
        "row_derived_affected_contact_availability_counts" => %{"reserved" => 1},
        "direction_counts" => %{"downlink" => 1},
        "row_derived_direction_counts" => %{"downlink" => 1},
        "station_calendar_status_counts" => %{"reserved" => 1},
        "row_derived_station_calendar_status_counts" => %{"reserved" => 1},
        "station_reservation_match_status_counts" => %{"overlap" => 1},
        "row_derived_station_reservation_match_status_counts" => %{"overlap" => 1},
        "stale_reservation_hold_count" => 1,
        "row_derived_stale_reservation_hold_count" => 1,
        "reservation_hold_status_count" => 1,
        "row_derived_reservation_hold_status_count" => 1,
        "row_derived_affected_contact_count" => 1,
        "row_derived_affected_duration_s" => 40.0,
        "row_derived_contact_ids_by_station_reservation_match_status" => %{
          "overlap" => ["dl_hold"]
        },
        "provider_reservation_execution_boundary" => "artifact_only_no_provider_reservation"
      },
      "tolerances" => %{
        "input_contact_count" => 0,
        "calendar_entry_count" => 0,
        "affected_contact_count" => 0,
        "affected_duration_s" => 0,
        "provider_calendar_contention_group_count" => 0,
        "duplicate_affected_contact_id_count" => 0,
        "duplicate_affected_contact_row_count" => 0,
        "stale_reservation_hold_count" => 0,
        "reservation_hold_status_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by station_calendar_report.v1 validation tests"
      ],
      "known_limits" => [
        "internal artifact regression, not external provider validation",
        "checks declared provider-calendar evidence only",
        "does not call provider APIs, reserve station time, or mutate schedules"
      ]
    },
    "fixture.artifact.station_reservation_report.stale_provider_reservation_hold" => %{
      "id" => "fixture.artifact.station_reservation_report.stale_provider_reservation_hold",
      "model_id" => "artifact.station_reservation_report.v1",
      "reference_case" =>
        "curated station reservation summary from stale but plausible provider reservation hold",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "source_contract" => "station_calendar_report.v1",
        "contract" => "station_reservation_report.v1",
        "provider_entry_status" => "reservation_hold"
      },
      "expected" => %{
        "schema_contract" => "station_reservation_report.v1",
        "model" => "artifact_only_station_reservation_summary",
        "affected_contact_reservation_count" => 1,
        "provider_calendar_contention_group_count" => 0,
        "reservation_review_count" => 1,
        "reservation_review_status" => "review_required",
        "station_reservation_match_status_counts" => %{"overlap" => 1},
        "row_derived_station_reservation_match_status_counts" => %{"overlap" => 1},
        "reservation_status_counts" => %{"tentative_hold" => 2},
        "row_derived_reservation_status_counts" => %{"tentative_hold" => 2},
        "reservation_id_order" => "provider_hold_1",
        "row_derived_reservation_id_order" => "provider_hold_1",
        "row_derived_reservation_ids_by_match_status" => %{"overlap" => ["provider_hold_1"]},
        "provider_reservation_execution_boundary" => "artifact_only_no_provider_reservation"
      },
      "tolerances" => %{
        "affected_contact_reservation_count" => 0,
        "provider_calendar_contention_group_count" => 0,
        "reservation_review_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by station_reservation_report.v1 validation tests"
      ],
      "known_limits" => [
        "internal artifact regression, not external provider validation",
        "checks reservation summary routing and no-provider-write boundary only",
        "does not call provider APIs, reserve station time, or mutate schedules"
      ]
    },
    "fixture.artifact.station_reservation_review_summary.v1" => %{
      "id" => "fixture.artifact.station_reservation_review_summary.v1",
      "model_id" => "artifact.station_reservation_review_summary.v1",
      "reference_case" => "checked-in station reservation review summary",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/station_reservation_review_summary_v1.json",
        "source_contract" => "station_reservation_report.v1",
        "contract" => "station_reservation_review_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "station_reservation_review_summary.v1",
        "model" => "artifact_only_station_reservation_review_summary",
        "source_artifact_type" => "station_reservation_report.v1",
        "source" => "station_calendar_report.reservation_evidence",
        "reservation_count" => 3,
        "affected_contact_reservation_count" => 1,
        "provider_calendar_contention_group_count" => 2,
        "reservation_review_status" => "review_required",
        "reservation_expiration_count" => 2,
        "earliest_reservation_expires_at_s" => 240.0,
        "expired_reservation_count" => 1,
        "active_reservation_count" => 1,
        "missing_reservation_expiration_count" => 1,
        "reservation_expiration_status_counts" => %{"active" => 1, "expired" => 1, "missing" => 1},
        "row_derived_reservation_expiration_status_counts" => %{
          "active" => 1,
          "expired" => 1,
          "missing" => 1
        },
        "review_reservation_id_keys" =>
          "reservation_active|reservation_expired|reservation_missing",
        "row_derived_review_reservation_id_keys" =>
          "reservation_active|reservation_expired|reservation_missing",
        "reservation_ids_by_expiration_status" => %{
          "active" => ["reservation_active"],
          "expired" => ["reservation_expired"],
          "missing" => ["reservation_missing"]
        },
        "row_derived_reservation_ids_by_expiration_status" => %{
          "active" => ["reservation_active"],
          "expired" => ["reservation_expired"],
          "missing" => ["reservation_missing"]
        },
        "row_derived_reservation_ids_by_row_type" => %{
          "affected_contact" => ["reservation_expired"],
          "provider_calendar_contention_group" => ["reservation_active", "reservation_missing"]
        },
        "row_derived_required_operator_action_counts" => %{
          "review_station_provider_contention" => 2,
          "review_station_reservation_overlap" => 1
        },
        "row_derived_review_contact_ids_by_expiration_status" => %{
          "expired" => ["dl_source_reserved"]
        },
        "execution_boundary" => "artifact_only_no_provider_reservation",
        "operator_authority" => "not_granted_by_summary",
        "model_limit_count" => 5
      },
      "tolerances" => %{
        "reservation_count" => 0,
        "affected_contact_reservation_count" => 0,
        "provider_calendar_contention_group_count" => 0,
        "reservation_expiration_count" => 0,
        "earliest_reservation_expires_at_s" => 0,
        "expired_reservation_count" => 0,
        "active_reservation_count" => 0,
        "missing_reservation_expiration_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by station_reservation_review_summary.v1 validation tests"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external provider validation",
        "checks review summary routing and no-provider-write boundary only",
        "does not call provider APIs, accept reservations, or mutate schedules"
      ]
    },
    "fixture.artifact.station_reservation_hold_summary.v1" => %{
      "id" => "fixture.artifact.station_reservation_hold_summary.v1",
      "model_id" => "artifact.station_reservation_hold_summary.v1",
      "reference_case" => "checked-in station reservation hold summary",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/station_reservation_hold_summary_v1.json",
        "source_contract" => "station_reservation_report.v1",
        "contract" => "station_reservation_hold_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "station_reservation_hold_summary.v1",
        "model" => "artifact_only_station_reservation_hold_summary",
        "source_artifact_type" => "station_reservation_report.v1",
        "source" => "station_calendar_report.reservation_evidence",
        "reservation_hold_count" => 2,
        "affected_contact_reservation_hold_count" => 1,
        "provider_calendar_contention_hold_count" => 1,
        "reservation_hold_review_status" => "review_required",
        "reservation_hold_status_counts" => %{"held" => 2},
        "row_derived_reservation_hold_status_counts" => %{"held" => 2},
        "reservation_hold_expiration_status_counts" => %{"expired" => 1, "missing" => 1},
        "row_derived_reservation_hold_expiration_status_counts" => %{
          "expired" => 1,
          "missing" => 1
        },
        "reservation_hold_id_keys" => "reservation_expired|reservation_missing",
        "row_derived_reservation_hold_id_keys" => "reservation_expired|reservation_missing",
        "reservation_hold_ids_by_reserved_by" => %{
          "ops_calendar" => ["reservation_expired"],
          "partner_calendar" => ["reservation_missing"]
        },
        "row_derived_reservation_hold_ids_by_reserved_by" => %{
          "ops_calendar" => ["reservation_expired"],
          "partner_calendar" => ["reservation_missing"]
        },
        "reservation_hold_ids_by_row_type" => %{
          "affected_contact" => ["reservation_expired"],
          "provider_calendar_contention_group" => ["reservation_missing"]
        },
        "row_derived_reservation_hold_ids_by_row_type" => %{
          "affected_contact" => ["reservation_expired"],
          "provider_calendar_contention_group" => ["reservation_missing"]
        },
        "reservation_hold_contact_ids_by_expiration_status" => %{
          "expired" => ["dl_source_reserved"]
        },
        "row_derived_reservation_hold_contact_ids_by_expiration_status" => %{
          "expired" => ["dl_source_reserved"]
        },
        "earliest_reservation_hold_expires_at_s" => 240.0,
        "execution_boundary" => "artifact_only_no_provider_reservation",
        "operator_authority" => "not_granted_by_summary",
        "model_limit_count" => 5
      },
      "tolerances" => %{
        "reservation_hold_count" => 0,
        "affected_contact_reservation_hold_count" => 0,
        "provider_calendar_contention_hold_count" => 0,
        "earliest_reservation_hold_expires_at_s" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by station_reservation_hold_summary.v1 validation tests"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external provider validation",
        "checks hold summary routing and no-provider-write boundary only",
        "does not call provider APIs, accept reservations, or mutate schedules"
      ]
    },
    "fixture.artifact.station_reservation_hold_import_readiness_summary.v1" => %{
      "id" => "fixture.artifact.station_reservation_hold_import_readiness_summary.v1",
      "model_id" => "artifact.station_reservation_hold_import_readiness_summary.v1",
      "reference_case" => "checked-in station reservation hold import-readiness summary",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" =>
          "study_results/station_reservation_hold_import_readiness_summary_v1.json",
        "source_contract" => "station_reservation_report.v1",
        "contract" => "station_reservation_hold_import_readiness_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "station_reservation_hold_import_readiness_summary.v1",
        "model" => "artifact_only_station_reservation_hold_import_readiness_summary",
        "source_artifact_type" => "station_reservation_report.v1",
        "source" => "station_calendar_report.reservation_evidence",
        "reservation_hold_count" => 2,
        "import_readiness_status" => "review_required",
        "import_classification" => "review_only",
        "ready_for_import_count" => 0,
        "review_required_before_import_count" => 2,
        "no_import_required_count" => 0,
        "reservation_hold_import_status_counts" => %{"review_required_before_import" => 2},
        "row_derived_reservation_hold_import_status_counts" => %{
          "review_required_before_import" => 2
        },
        "required_import_action_counts" => %{
          "review_station_provider_contention" => 1,
          "review_station_reservation_overlap" => 1
        },
        "row_derived_required_import_action_counts" => %{
          "review_station_provider_contention" => 1,
          "review_station_reservation_overlap" => 1
        },
        "reservation_hold_ids_by_import_status" => %{
          "review_required_before_import" => ["reservation_expired", "reservation_missing"]
        },
        "row_derived_reservation_hold_ids_by_import_status" => %{
          "review_required_before_import" => ["reservation_expired", "reservation_missing"]
        },
        "reservation_hold_ids_by_required_import_action" => %{
          "review_station_provider_contention" => ["reservation_missing"],
          "review_station_reservation_overlap" => ["reservation_expired"]
        },
        "row_derived_reservation_hold_ids_by_required_import_action" => %{
          "review_station_provider_contention" => ["reservation_missing"],
          "review_station_reservation_overlap" => ["reservation_expired"]
        },
        "reservation_hold_contact_ids_by_import_status" => %{
          "review_required_before_import" => ["dl_source_reserved"]
        },
        "row_derived_reservation_hold_contact_ids_by_import_status" => %{
          "review_required_before_import" => ["dl_source_reserved"]
        },
        "execution_boundary" => "artifact_only_no_provider_or_cadence_writes",
        "provider_write" => "not_performed_by_summary",
        "cadence_write" => "not_performed_by_summary",
        "reservation_acceptance" => "not_performed_by_summary",
        "operator_authority" => "not_granted_by_import_readiness_summary",
        "model_limit_count" => 5
      },
      "tolerances" => %{
        "reservation_hold_count" => 0,
        "ready_for_import_count" => 0,
        "review_required_before_import_count" => 0,
        "no_import_required_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by station_reservation_hold_import_readiness_summary.v1 validation tests"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external provider validation",
        "checks hold import-readiness routing and no-provider/no-Cadence-write boundary only",
        "does not call provider APIs, accept reservations, or write Cadence imports"
      ]
    },
    "fixture.artifact.station_calendar_report.v1" => %{
      "id" => "fixture.artifact.station_calendar_report.v1",
      "model_id" => "artifact.station_calendar_report.v1",
      "reference_case" => "checked-in station calendar report artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/station_calendar_report_v1.json",
        "contract" => "station_calendar_report.v1"
      },
      "expected" => %{
        "schema_contract" => "station_calendar_report.v1",
        "model" => "campaign_ground_network_interval_overlay",
        "input_contact_count" => 2,
        "calendar_entry_count" => 2,
        "affected_contact_count" => 2,
        "affected_duration_s" => 80.0,
        "provider_calendar_contention_group_count" => 1,
        "duplicate_affected_contact_id_count" => 0,
        "duplicate_affected_contact_row_count" => 0,
        "affected_contact_ground_station_counts" => %{"equator_prime" => 2},
        "row_derived_affected_contact_ground_station_counts" => %{"equator_prime" => 2},
        "affected_contact_availability_counts" => %{
          "reduced_capacity" => 1,
          "reserved" => 1
        },
        "row_derived_affected_contact_availability_counts" => %{
          "reduced_capacity" => 1,
          "reserved" => 1
        },
        "direction_counts" => %{"command" => 1, "downlink" => 1},
        "row_derived_direction_counts" => %{"command" => 1, "downlink" => 1},
        "station_calendar_status_counts" => %{"available" => 1, "reserved" => 1},
        "row_derived_station_calendar_status_counts" => %{
          "available" => 1,
          "reserved" => 1
        },
        "station_reservation_match_status_counts" => %{"overlap" => 1},
        "row_derived_station_reservation_match_status_counts" => %{"overlap" => 1},
        "stale_reservation_hold_count" => 0,
        "row_derived_stale_reservation_hold_count" => 0,
        "reservation_hold_status_count" => 0,
        "row_derived_reservation_hold_status_count" => 0,
        "row_derived_affected_contact_count" => 2,
        "row_derived_affected_duration_s" => 80.0,
        "row_derived_contact_ids_by_station_reservation_match_status" => %{
          "overlap" => ["cmd_1"]
        },
        "provider_reservation_execution_boundary" => "artifact_only_no_provider_reservation"
      },
      "tolerances" => %{
        "input_contact_count" => 0,
        "calendar_entry_count" => 0,
        "affected_contact_count" => 0,
        "affected_duration_s" => 0,
        "provider_calendar_contention_group_count" => 0,
        "duplicate_affected_contact_id_count" => 0,
        "duplicate_affected_contact_row_count" => 0,
        "stale_reservation_hold_count" => 0,
        "reservation_hold_status_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external provider validation",
        "checks station-calendar overlay counts and artifact-only execution boundary only"
      ]
    },
    "fixture.artifact.provider_counteroffer_report.v1" => %{
      "id" => "fixture.artifact.provider_counteroffer_report.v1",
      "model_id" => "artifact.provider_counteroffer_report.v1",
      "reference_case" =>
        "curated provider counteroffer report preserving timing and cost impact evidence",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "provider_contract" => "station_calendar_provider.v1",
        "contract" => "provider_counteroffer_report.v1",
        "provider_counteroffer_status" => "proposed"
      },
      "expected" => %{
        "schema_contract" => "provider_counteroffer_report.v1",
        "model" => "artifact_only_provider_counteroffer_review",
        "source_artifact_type" => "station_calendar_report.v1",
        "counteroffer_count" => 1,
        "row_derived_counteroffer_count" => 1,
        "reviewable_count" => 1,
        "row_derived_reviewable_count" => 1,
        "counteroffer_cost_delta_count" => 1,
        "row_derived_counteroffer_cost_delta_count" => 1,
        "counteroffer_cost_delta_total" => 125.5,
        "row_derived_counteroffer_cost_delta_total" => 125.5,
        "counteroffer_lock_deadline_count" => 1,
        "row_derived_counteroffer_lock_deadline_count" => 1,
        "earliest_counteroffer_lock_deadline_s" => 150.0,
        "row_derived_earliest_counteroffer_lock_deadline_s" => 150.0,
        "timing_shift_counteroffer_count" => 1,
        "row_derived_timing_shift_counteroffer_count" => 1,
        "provider_counteroffer_start_delta_s" => 30.0,
        "provider_counteroffer_end_delta_s" => 30.0,
        "required_operator_action_count" => 1,
        "row_derived_required_operator_action_count" => 1,
        "provider_write_boundary" => "artifact_only_no_provider_writes"
      },
      "tolerances" => %{
        "counteroffer_count" => 0,
        "row_derived_counteroffer_count" => 0,
        "reviewable_count" => 0,
        "row_derived_reviewable_count" => 0,
        "counteroffer_cost_delta_count" => 0,
        "row_derived_counteroffer_cost_delta_count" => 0,
        "counteroffer_cost_delta_total" => 0,
        "row_derived_counteroffer_cost_delta_total" => 0,
        "counteroffer_lock_deadline_count" => 0,
        "row_derived_counteroffer_lock_deadline_count" => 0,
        "earliest_counteroffer_lock_deadline_s" => 0,
        "row_derived_earliest_counteroffer_lock_deadline_s" => 0,
        "timing_shift_counteroffer_count" => 0,
        "row_derived_timing_shift_counteroffer_count" => 0,
        "provider_counteroffer_start_delta_s" => 0,
        "provider_counteroffer_end_delta_s" => 0,
        "required_operator_action_count" => 0,
        "row_derived_required_operator_action_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by provider_counteroffer_report.v1 validation tests"
      ],
      "known_limits" => [
        "internal artifact regression, not external provider validation",
        "checks declared provider counteroffer timing and cost evidence only",
        "does not call provider APIs, accept counteroffers, reserve station time, or mutate schedules"
      ]
    },
    "fixture.artifact.provider_counteroffer_import_readiness_summary.v1" => %{
      "id" => "fixture.artifact.provider_counteroffer_import_readiness_summary.v1",
      "model_id" => "artifact.provider_counteroffer_import_readiness_summary.v1",
      "reference_case" => "checked-in provider counteroffer import-readiness summary artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/provider_counteroffer_import_readiness_summary_v1.json",
        "contract" => "provider_counteroffer_import_readiness_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "provider_counteroffer_import_readiness_summary.v1",
        "model" => "artifact_only_provider_counteroffer_import_readiness_summary",
        "source" => "station_calendar_report.affected_contacts",
        "source_artifact_id" => "station_calendar_report",
        "source_artifact_type" => "provider_counteroffer_report.v1",
        "source_counteroffer_artifact_type" => "station_calendar_report.v1",
        "counteroffer_count" => 1,
        "reviewable_count" => 1,
        "row_derived_reviewable_count" => 1,
        "import_readiness_status" => "review_required",
        "import_classification" => "review_only",
        "ready_for_import_count" => 0,
        "review_required_before_import_count" => 1,
        "no_import_required_count" => 0,
        "provider_counteroffer_import_status_counts" => %{
          "review_required_before_import" => 1
        },
        "row_derived_provider_counteroffer_import_status_counts" => %{
          "review_required_before_import" => 1
        },
        "required_import_action_counts" => %{"review_provider_counteroffer" => 1},
        "row_derived_required_import_action_counts" => %{
          "review_provider_counteroffer" => 1
        },
        "counteroffer_lock_deadline_status_counts" => %{"expired" => 1},
        "row_derived_counteroffer_lock_deadline_status_counts" => %{"expired" => 1},
        "counteroffer_status_counts" => %{"proposed" => 1},
        "counteroffer_negotiation_state_counts" => %{"proposed" => 1},
        "counteroffer_ids_by_import_status" => %{
          "review_required_before_import" => ["provider_offer_1"]
        },
        "counteroffer_ids_by_required_import_action" => %{
          "review_provider_counteroffer" => ["provider_offer_1"]
        },
        "counteroffer_ids_by_lock_deadline_status" => %{
          "expired" => ["provider_offer_1"]
        },
        "row_derived_counteroffer_ids_by_import_status" => %{
          "review_required_before_import" => ["provider_offer_1"]
        },
        "row_derived_counteroffer_ids_by_required_import_action" => %{
          "review_provider_counteroffer" => ["provider_offer_1"]
        },
        "row_derived_counteroffer_ids_by_lock_deadline_status" => %{
          "expired" => ["provider_offer_1"]
        },
        "review_counteroffer_ids" => "provider_offer_1",
        "no_import_required_counteroffer_ids" => "",
        "import_readiness_row_count" => 1,
        "execution_boundary" => "artifact_only_no_provider_or_cadence_writes",
        "operator_authority" => "not_granted_by_import_readiness_summary",
        "provider_write" => "not_performed_by_summary",
        "cadence_write" => "not_performed_by_summary",
        "offer_acceptance" => "not_performed_by_summary",
        "deadline_evaluation" => "relative_to_now_s",
        "now_s" => 160.0,
        "assumption_source" => "provider_counteroffer_report.v1"
      },
      "tolerances" => %{
        "counteroffer_count" => 0,
        "reviewable_count" => 0,
        "row_derived_reviewable_count" => 0,
        "ready_for_import_count" => 0,
        "review_required_before_import_count" => 0,
        "no_import_required_count" => 0,
        "import_readiness_row_count" => 0,
        "now_s" => 0
      },
      "evidence" => [
        "generated by OrbitalDynamics.Communications.StationCalendar.provider_counteroffer_import_readiness_summary/2",
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external provider validation",
        "checks import-readiness routing and no provider/Cadence write assumptions only"
      ]
    },
    "fixture.artifact.provider_counteroffer_plan_impact_summary.v1" => %{
      "id" => "fixture.artifact.provider_counteroffer_plan_impact_summary.v1",
      "model_id" => "artifact.provider_counteroffer_plan_impact_summary.v1",
      "reference_case" => "checked-in provider counteroffer plan-impact summary artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/provider_counteroffer_plan_impact_summary_v1.json",
        "contract" => "provider_counteroffer_plan_impact_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "provider_counteroffer_plan_impact_summary.v1",
        "model" => "artifact_only_provider_counteroffer_plan_impact_summary",
        "source" => "station_calendar_report.affected_contacts",
        "source_artifact_id" => "station_calendar_report",
        "source_artifact_type" => "provider_counteroffer_report.v1",
        "source_counteroffer_artifact_type" => "station_calendar_report.v1",
        "counteroffer_count" => 1,
        "reviewable_count" => 1,
        "row_derived_reviewable_count" => 1,
        "plan_impact_status" => "review_required",
        "timing_shift_counteroffer_count" => 1,
        "row_derived_timing_shift_counteroffer_count" => 1,
        "counteroffer_cost_delta_count" => 1,
        "row_derived_counteroffer_cost_delta_count" => 1,
        "counteroffer_cost_delta_total" => 125.5,
        "row_derived_counteroffer_cost_delta_total" => 125.5,
        "counteroffer_lock_deadline_status_counts" => %{"active" => 1},
        "row_derived_counteroffer_lock_deadline_status_counts" => %{"active" => 1},
        "affected_station_calendar_entry_ids" => "provider_counteroffer_window",
        "affected_provider_entry_ids" => "provider_counteroffer_window",
        "impact_counteroffer_ids" => "provider_offer_1",
        "timing_shift_counteroffer_ids" => "provider_offer_1",
        "cost_delta_counteroffer_ids" => "provider_offer_1",
        "counteroffer_ids_by_lock_deadline_status" => %{"active" => ["provider_offer_1"]},
        "row_derived_counteroffer_ids_by_lock_deadline_status" => %{
          "active" => ["provider_offer_1"]
        },
        "impact_row_count" => 1,
        "provider_counteroffer_start_delta_s" => 30.0,
        "provider_counteroffer_end_delta_s" => 30.0,
        "provider_counteroffer_duration_delta_s" => 0.0,
        "execution_boundary" => "artifact_only_no_provider_writes",
        "operator_authority" => "not_granted_by_summary",
        "deadline_evaluation" => "relative_to_now_s",
        "now_s" => 120.0,
        "assumption_source" => "provider_counteroffer_report.v1"
      },
      "tolerances" => %{
        "counteroffer_count" => 0,
        "reviewable_count" => 0,
        "row_derived_reviewable_count" => 0,
        "timing_shift_counteroffer_count" => 0,
        "row_derived_timing_shift_counteroffer_count" => 0,
        "counteroffer_cost_delta_count" => 0,
        "row_derived_counteroffer_cost_delta_count" => 0,
        "counteroffer_cost_delta_total" => 0,
        "row_derived_counteroffer_cost_delta_total" => 0,
        "impact_row_count" => 0,
        "provider_counteroffer_start_delta_s" => 0,
        "provider_counteroffer_end_delta_s" => 0,
        "provider_counteroffer_duration_delta_s" => 0,
        "now_s" => 0
      },
      "evidence" => [
        "generated by OrbitalDynamics.Communications.StationCalendar.provider_counteroffer_plan_impact_summary/2",
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external provider validation",
        "checks timing/cost impact identity and no provider-write assumptions only"
      ]
    },
    "fixture.artifact.provider_counteroffer_review_summary.v1" => %{
      "id" => "fixture.artifact.provider_counteroffer_review_summary.v1",
      "model_id" => "artifact.provider_counteroffer_review_summary.v1",
      "reference_case" => "checked-in provider counteroffer review summary artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/provider_counteroffer_review_summary_v1.json",
        "contract" => "provider_counteroffer_review_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "provider_counteroffer_review_summary.v1",
        "model" => "artifact_only_provider_counteroffer_review_summary",
        "source" => "station_calendar_report.affected_contacts",
        "source_artifact_id" => "station_calendar_report",
        "source_artifact_type" => "provider_counteroffer_report.v1",
        "source_counteroffer_artifact_type" => "station_calendar_report.v1",
        "counteroffer_count" => 1,
        "reviewable_count" => 1,
        "row_derived_reviewable_count" => 1,
        "counteroffer_review_status" => "review_required",
        "counteroffer_status_counts" => %{"proposed" => 1},
        "counteroffer_negotiation_state_counts" => %{"proposed" => 1},
        "counteroffer_lock_deadline_count" => 1,
        "earliest_counteroffer_lock_deadline_s" => 150.0,
        "counteroffer_lock_deadline_status_counts" => %{"expired" => 1},
        "row_derived_counteroffer_lock_deadline_status_counts" => %{"expired" => 1},
        "counteroffer_ids_by_lock_deadline_status" => %{
          "expired" => ["provider_offer_1"]
        },
        "row_derived_counteroffer_ids_by_lock_deadline_status" => %{
          "expired" => ["provider_offer_1"]
        },
        "expired_counteroffer_lock_deadline_count" => 1,
        "active_counteroffer_lock_deadline_count" => 0,
        "missing_counteroffer_lock_deadline_count" => 0,
        "review_counteroffer_ids" => "provider_offer_1",
        "row_derived_review_counteroffer_ids" => "provider_offer_1",
        "row_count" => 1,
        "review_row_count" => 1,
        "execution_boundary" => "artifact_only_no_provider_writes",
        "operator_authority" => "not_granted_by_summary",
        "deadline_evaluation" => "relative_to_now_s",
        "now_s" => 160.0,
        "assumption_source" => "provider_counteroffer_report.v1"
      },
      "tolerances" => %{
        "counteroffer_count" => 0,
        "reviewable_count" => 0,
        "row_derived_reviewable_count" => 0,
        "counteroffer_lock_deadline_count" => 0,
        "earliest_counteroffer_lock_deadline_s" => 0,
        "expired_counteroffer_lock_deadline_count" => 0,
        "active_counteroffer_lock_deadline_count" => 0,
        "missing_counteroffer_lock_deadline_count" => 0,
        "row_count" => 0,
        "review_row_count" => 0,
        "now_s" => 0
      },
      "evidence" => [
        "generated by OrbitalDynamics.Communications.StationCalendar.provider_counteroffer_review_summary/2",
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external provider validation",
        "checks review status, deadline routing, and no provider-write assumptions only"
      ]
    },
    "fixture.artifact.model_acceptance_report.operational_import" => %{
      "id" => "fixture.artifact.model_acceptance_report.operational_import",
      "model_id" => "artifact.model_acceptance_report.v1",
      "reference_case" =>
        "curated model acceptance report for operational import evidence boundaries",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "contract" => "model_acceptance_report.v1",
        "intended_use" => "operational_import",
        "model_ids" => [
          "orbit_data.simple_json",
          "event.access_windows",
          "propagator.two_body",
          "missing.model"
        ]
      },
      "expected" => %{
        "schema_contract" => "model_acceptance_report.v1",
        "model" => "registry_model_acceptance_classifier",
        "intended_use" => "operational_import",
        "status" => "blocked",
        "model_count" => 4,
        "record_count" => 3,
        "row_count" => 4,
        "accepted_count" => 1,
        "review_required_count" => 1,
        "blocked_count" => 2,
        "unknown_model_count" => 1,
        "status_counts" => %{
          "accepted" => 1,
          "blocked" => 2,
          "review_required" => 1
        },
        "validation_level_counts" => %{
          "analysis" => 1,
          "artifact_contract" => 1,
          "educational" => 1,
          "unknown" => 1
        },
        "model_ids_by_status" => %{
          "accepted" => ["orbit_data.simple_json"],
          "blocked" => ["propagator.two_body", "missing.model"],
          "review_required" => ["event.access_windows"]
        },
        "model_ids_by_validation_level" => %{
          "analysis" => ["event.access_windows"],
          "artifact_contract" => ["orbit_data.simple_json"],
          "educational" => ["propagator.two_body"],
          "unknown" => ["missing.model"]
        },
        "model_ids_by_intended_use" => %{
          "operational_import" => [
            "orbit_data.simple_json",
            "event.access_windows",
            "propagator.two_body",
            "missing.model"
          ]
        }
      },
      "tolerances" => %{
        "model_count" => 0,
        "record_count" => 0,
        "row_count" => 0,
        "accepted_count" => 0,
        "review_required_count" => 0,
        "blocked_count" => 0,
        "unknown_model_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by model_acceptance_report.v1 validation tests"
      ],
      "known_limits" => [
        "internal artifact regression, not external model certification",
        "checks intended-use acceptance counts and unknown-model blocking only"
      ]
    },
    "fixture.artifact.validation_safety_case_summary.v1" => %{
      "id" => "fixture.artifact.validation_safety_case_summary.v1",
      "model_id" => "artifact.validation_safety_case_summary.v1",
      "reference_case" =>
        "curated validation safety-case summary for artifact-only handoff boundaries",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "contract" => "validation_safety_case_summary.v1",
        "artifact_path" => "study_results/validation_safety_case_summary_v1.json",
        "case_id" => "case:compatibility-example"
      },
      "expected" => %{
        "schema_contract" => "validation_safety_case_summary.v1",
        "model" => "artifact_only_validation_safety_case_summary",
        "source" => "validation.safety_case_evidence",
        "summary_id" => "validation_safety_case:case:compatibility-example",
        "case_id" => "case:compatibility-example",
        "status" => "blocked",
        "evidence_count" => 4,
        "accepted_evidence_count" => 1,
        "review_required_evidence_count" => 1,
        "blocked_evidence_count" => 2,
        "model_accepted_count" => 1,
        "model_review_required_count" => 1,
        "model_blocked_count" => 0,
        "unknown_model_count" => 0,
        "readiness_review_required_count" => 0,
        "readiness_blocked_count" => 0,
        "ready_for_import_count" => 0,
        "quality_gate_review_count" => 0,
        "quality_gate_blocked_count" => 0,
        "schema_error_count" => 2,
        "schema_warning_count" => 0,
        "schema_validation_report_count" => 0,
        "schema_validation_failed_report_count" => 0,
        "fixture_passed_count" => 0,
        "fixture_failed_count" => 0,
        "input_contract_count" => 2,
        "evidence_status_counts" => %{
          "accepted_for_use" => 1,
          "blocked" => 2,
          "review_required" => 1
        },
        "model_acceptance_evidence_status_counts" => %{
          "accepted" => 1,
          "review_required" => 1
        },
        "model_acceptance_evidence_model_ids_by_status" => %{
          "accepted" => ["orbit_data.simple_json"],
          "review_required" => ["event.access_windows"]
        },
        "model_acceptance_evidence_model_ids_by_validation_level" => %{
          "analysis" => ["event.access_windows"],
          "artifact_contract" => ["orbit_data.simple_json"]
        },
        "model_acceptance_evidence_model_ids_by_intended_use" => %{
          "operational_import" => ["orbit_data.simple_json", "event.access_windows"]
        },
        "evidence_refs_by_status" => %{
          "accepted_for_use" => ["schema_validation_report.v1:candidate_refresh.v1"],
          "blocked" => [
            "schema_validation_report.v1:candidate_refresh.v1",
            "schema_validation_report.v1:candidate_refresh.v1"
          ],
          "review_required" => [
            "model_acceptance_report.v1:model_acceptance:operational_import:orbit_data.simple_json__event.access_windows"
          ]
        },
        "evidence_refs_by_contract" => %{
          "model_acceptance_report.v1" => [
            "model_acceptance_report.v1:model_acceptance:operational_import:orbit_data.simple_json__event.access_windows"
          ],
          "schema_validation_report.v1" => [
            "schema_validation_report.v1:candidate_refresh.v1",
            "schema_validation_report.v1:candidate_refresh.v1",
            "schema_validation_report.v1:candidate_refresh.v1"
          ]
        },
        "model_limit_count" => 3,
        "execution_boundary" => "artifact_only_no_cadence_write",
        "certification_authority" => "not_granted_by_summary",
        "operator_authority" => "not_granted_by_summary"
      },
      "tolerances" => %{
        "evidence_count" => 0,
        "accepted_evidence_count" => 0,
        "review_required_evidence_count" => 0,
        "blocked_evidence_count" => 0,
        "model_accepted_count" => 0,
        "model_review_required_count" => 0,
        "model_blocked_count" => 0,
        "unknown_model_count" => 0,
        "readiness_review_required_count" => 0,
        "readiness_blocked_count" => 0,
        "ready_for_import_count" => 0,
        "quality_gate_review_count" => 0,
        "quality_gate_blocked_count" => 0,
        "schema_error_count" => 0,
        "schema_warning_count" => 0,
        "schema_validation_report_count" => 0,
        "schema_validation_failed_report_count" => 0,
        "fixture_passed_count" => 0,
        "fixture_failed_count" => 0,
        "input_contract_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by validation_safety_case_summary.v1 validation tests"
      ],
      "known_limits" => [
        "internal artifact regression, not external safety-case certification",
        "checks evidence counts, routing maps, and authority boundaries only",
        "does not approve imports, certify models, or write to Cadence"
      ]
    }
  }

  @all_fixtures Orbital.all()
                |> Map.merge(AcceptedPlanningState.all())
                |> Map.merge(ActivityArtifacts.all())
                |> Map.merge(BenchmarkArtifacts.all())
                |> Map.merge(CandidateRefreshBase.all())
                |> Map.merge(CandidateRefreshCapacityFilter.all())
                |> Map.merge(CandidateRefreshContact.all())
                |> Map.merge(CandidateRefreshFilterRejection.all())
                |> Map.merge(CandidateRefreshFreshnessBudget.all())
                |> Map.merge(CandidateRefreshPlanningFeedback.all())
                |> Map.merge(CandidateRefreshReadiness.all())
                |> Map.merge(CandidateRefreshStationAllocation.all())
                |> Map.merge(CandidateRefreshTimeline.all())
                |> Map.merge(CandidateStateArtifacts.all())
                |> Map.merge(CandidateStrategyArtifacts.all())
                |> Map.merge(CampaignArtifacts.all())
                |> Map.merge(CampaignPlanning.all())
                |> Map.merge(ContactAllocationArtifacts.all())
                |> Map.merge(ContactContentionArtifacts.all())
                |> Map.merge(ContactIntentArtifacts.all())
                |> Map.merge(ContactWindowArtifacts.all())
                |> Map.merge(CoreRunReports.all())
                |> Map.merge(DecisionSupportArtifacts.all())
                |> Map.merge(EnvironmentCapabilities.all())
                |> Map.merge(LinkCapacityArtifacts.all())
                |> Map.merge(ManifestArtifacts.all())
                |> Map.merge(ObjectiveScoringArtifacts.all())
                |> Map.merge(OperationalPlanningArtifacts.all())
                |> Map.merge(PolicyBundleArtifacts.all())
                |> Map.merge(PolicyDecisions.all())
                |> Map.merge(PolicyEvidenceArtifacts.all())
                |> Map.merge(ProviderCapacityPackArtifacts.all())
                |> Map.merge(ResourcePressureHandoffArtifacts.all())
                |> Map.merge(ResourceProjectionArtifacts.all())
                |> Map.merge(ResourceSafetyArtifacts.all())
                |> Map.merge(ResourceSummaryArtifacts.all())
                |> Map.merge(SchemaCompatibilityArtifacts.all())
                |> Map.merge(StateManeuverArtifacts.all())
                |> Map.merge(SubsystemModelCapabilities.all())
                |> Map.merge(TimelineActivityStateArtifacts.all())
                |> Map.merge(TimelineHandoffArtifacts.all())
                |> Map.merge(TimelinePreservationArtifacts.all())
                |> Map.merge(TimelineTransitionArtifacts.all())
                |> Map.merge(@fixtures)

  def all, do: @all_fixtures

  def fetch(id) when is_binary(id), do: Map.fetch(@all_fixtures, id)
end
