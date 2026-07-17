defmodule OrbitalDynamics.Validation.ReferenceFixtures do
  @moduledoc false

  alias OrbitalDynamics.Validation.ReferenceFixtures.AcceptedPlanningState
  alias OrbitalDynamics.Validation.ReferenceFixtures.ActivityArtifacts
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
  alias OrbitalDynamics.Validation.ReferenceFixtures.ContactIntentArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.ContactWindowArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.CoreRunReports
  alias OrbitalDynamics.Validation.ReferenceFixtures.EnvironmentCapabilities
  alias OrbitalDynamics.Validation.ReferenceFixtures.LinkCapacityArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.ManifestArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.OperationalPlanningArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.Orbital
  alias OrbitalDynamics.Validation.ReferenceFixtures.PolicyBundleArtifacts
  alias OrbitalDynamics.Validation.ReferenceFixtures.PolicyDecisions
  alias OrbitalDynamics.Validation.ReferenceFixtures.PolicyEvidenceArtifacts
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
    "fixture.artifact.cadence_import_manifest.resource_projection_battery_handoff_v1" => %{
      "id" => "fixture.artifact.cadence_import_manifest.resource_projection_battery_handoff_v1",
      "model_id" => "artifact.cadence_import_manifest.v1",
      "reference_case" =>
        "checked-in Cadence import resource-projection battery handoff artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" =>
          "study_results/cadence_import_resource_projection_battery_handoff_v1.json",
        "contract" => "cadence_import_manifest.v1",
        "source_contract" => "resource_projection_report.v1"
      },
      "expected" => %{
        "schema_contract" => "cadence_import_manifest.v1",
        "model" => "artifact_only_cadence_import_manifest",
        "source_artifact_type" => "resource_projection_report.v1",
        "row_count" => 1,
        "review_required_count" => 1,
        "source_review_type_counts" => %{"resource_projection_review" => 1},
        "import_action_counts" => %{"review_resource_projection" => 1},
        "resource_projection_battery_handoff_count" => 1,
        "source_review_battery_handoff_count" => 1,
        "total_resource_projection_battery_energy_consumed_wh" => 23.0,
        "total_resource_projection_battery_energy_generated_wh" => 8.0,
        "net_resource_projection_battery_energy_delta_wh" => 15.0,
        "peak_resource_projection_battery_overuse_wh" => 4.0,
        "model_limit_count" => 4
      },
      "tolerances" => %{
        "row_count" => 0,
        "review_required_count" => 0,
        "resource_projection_battery_handoff_count" => 0,
        "source_review_battery_handoff_count" => 0,
        "total_resource_projection_battery_energy_consumed_wh" => 0.0,
        "total_resource_projection_battery_energy_generated_wh" => 0.0,
        "net_resource_projection_battery_energy_delta_wh" => 0.0,
        "peak_resource_projection_battery_overuse_wh" => 0.0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external Cadence API validation",
        "checks resource-projection battery handoff routing and no-write boundary only"
      ]
    },
    "fixture.artifact.contact_allocation_provider_reservation_request_summary.v1" => %{
      "id" => "fixture.artifact.contact_allocation_provider_reservation_request_summary.v1",
      "model_id" => "artifact.contact_allocation_provider_reservation_request_summary.v1",
      "reference_case" => "checked-in provider reservation request summary fixture",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "source" =>
          "study_results/contact_allocation_provider_reservation_request_summary_v1.json",
        "contract" => "contact_allocation_provider_reservation_request_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "contact_allocation_provider_reservation_request_summary.v1",
        "model" => "artifact_only_contact_allocation_provider_reservation_request_summary",
        "source_artifact_type" => "contact_allocation_report.v1",
        "source" => "validation.provider_reservation_request_summary",
        "input_contact_count" => 4,
        "row_derived_input_contact_count" => 4,
        "provider_reservation_candidate_contact_count" => 2,
        "row_derived_provider_reservation_candidate_contact_count" => 2,
        "provider_reservation_request_contact_count" => 1,
        "row_derived_provider_reservation_request_contact_count" => 1,
        "provider_reservation_review_contact_count" => 1,
        "row_derived_provider_reservation_review_contact_count" => 1,
        "provider_reservation_no_request_contact_count" => 2,
        "row_derived_provider_reservation_no_request_contact_count" => 2,
        "provider_reservation_request_status" => "review_required",
        "provider_reservation_request_contact_keys" => "dl_reserved_owner",
        "provider_reservation_review_contact_keys" => "dl_review_overlap",
        "provider_reservation_no_request_contact_keys" => "dl_reserved_intruder|dl_unreserved",
        "provider_reservation_no_request_contact_ids_by_direction" => %{
          "tracking" => ["dl_reserved_intruder"],
          "uplink" => ["dl_unreserved"]
        },
        "row_derived_provider_reservation_no_request_contact_ids_by_direction" => %{
          "tracking" => ["dl_reserved_intruder"],
          "uplink" => ["dl_unreserved"]
        },
        "row_derived_provider_reservation_no_request_contact_ids_by_direction_and_ground_station_id" =>
          %{
            "tracking" => %{"equator_prime" => ["dl_reserved_intruder"]},
            "uplink" => %{"equator_prime" => ["dl_unreserved"]}
          },
        "provider_reservation_request_contact_ids_by_direction" => %{
          "downlink" => ["dl_reserved_owner"]
        },
        "row_derived_provider_reservation_request_contact_ids_by_direction" => %{
          "downlink" => ["dl_reserved_owner"]
        },
        "row_derived_provider_reservation_request_contact_ids_by_direction_and_ground_station_id" =>
          %{
            "downlink" => %{"equator_prime" => ["dl_reserved_owner"]}
          },
        "provider_reservation_review_contact_ids_by_direction" => %{
          "command" => ["dl_review_overlap"]
        },
        "row_derived_provider_reservation_review_contact_ids_by_direction" => %{
          "command" => ["dl_review_overlap"]
        },
        "row_derived_provider_reservation_review_contact_ids_by_direction_and_ground_station_id" =>
          %{
            "command" => %{"equator_prime" => ["dl_review_overlap"]}
          },
        "provider_reservation_request_contact_ids_by_ground_station_id" => %{
          "equator_prime" => ["dl_reserved_owner"]
        },
        "provider_reservation_review_contact_ids_by_ground_station_id" => %{
          "equator_prime" => ["dl_review_overlap"]
        },
        "provider_reservation_request_contact_ids_by_match_status" => %{
          "matched" => ["dl_reserved_owner"]
        },
        "provider_reservation_review_contact_ids_by_match_status" => %{
          "overlap" => ["dl_review_overlap"]
        },
        "provider_reservation_request_ids_by_match_status" => %{
          "matched" => ["reservation_1"]
        },
        "provider_reservation_review_ids_by_match_status" => %{
          "overlap" => ["reservation_review"]
        },
        "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation",
        "provider_reservation_execution" => "not_performed_by_summary",
        "operator_authority" => "not_granted_by_provider_reservation_request_summary"
      },
      "tolerances" => %{
        "input_contact_count" => 0,
        "row_derived_input_contact_count" => 0,
        "provider_reservation_candidate_contact_count" => 0,
        "row_derived_provider_reservation_candidate_contact_count" => 0,
        "provider_reservation_request_contact_count" => 0,
        "row_derived_provider_reservation_request_contact_count" => 0,
        "provider_reservation_review_contact_count" => 0,
        "row_derived_provider_reservation_review_contact_count" => 0,
        "provider_reservation_no_request_contact_count" => 0,
        "row_derived_provider_reservation_no_request_contact_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal generated artifact regression, not external provider reservation validation",
        "checks provider-reservation request, review, no-request routing maps and no-provider-write boundary only"
      ]
    },
    "fixture.artifact.contact_allocation_report.reduced_capacity_pack" => %{
      "id" => "fixture.artifact.contact_allocation_report.reduced_capacity_pack",
      "model_id" => "artifact.contact_allocation_report.v1",
      "reference_case" => "checked-in reduced-capacity contact allocation pack artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/contact_allocation_capacity_pack_report_v1.json",
        "contract" => "contact_allocation_report.v1"
      },
      "expected" => %{
        "schema_contract" => "contact_allocation_report.v1",
        "model" => "deterministic_station_contact_allocation",
        "input_contact_count" => 3,
        "row_count" => 3,
        "allocated_contact_count" => 2,
        "returned_allocated_contact_count" => 2,
        "deferred_contact_count" => 1,
        "blocked_contact_count" => 0,
        "reduced_capacity_pack_group_count" => 1,
        "reduced_capacity_pack_capacity_fraction_total" => 0.5,
        "reduced_capacity_pack_used_fraction_total" => 0.5,
        "reduced_capacity_pack_unused_fraction_total" => 0.0,
        "reduced_capacity_pack_selected_contact_count" => 1,
        "reduced_capacity_pack_capacity_packed_contact_count" => 1,
        "reduced_capacity_pack_deferred_contact_count" => 1,
        "required_capacity_fraction_total" => 0.75,
        "selected_contact_count" => 2,
        "allocation_reason_counts" => %{
          "same_station_contention" => 1,
          "selected_by_contention_resolution" => 1,
          "selected_by_reduced_station_capacity_pack" => 1
        },
        "capacity_pack_status_counts" => %{
          "deferred_by_reduced_station_capacity_pack" => 1,
          "selected_by_contention_resolution" => 1,
          "selected_by_reduced_station_capacity_pack" => 1
        },
        "reported_reduced_capacity_pack_status_counts" => %{
          "capacity_limited" => 1
        },
        "reported_capacity_pack_status_counts" => %{
          "deferred_by_reduced_station_capacity_pack" => 1,
          "selected_by_contention_resolution" => 1,
          "selected_by_reduced_station_capacity_pack" => 1
        },
        "contact_ids_by_capacity_pack_status" => %{
          "deferred_by_reduced_station_capacity_pack" => ["dl_capacity_overflow"],
          "selected_by_contention_resolution" => ["dl_capacity_primary"],
          "selected_by_reduced_station_capacity_pack" => ["dl_capacity_secondary"]
        },
        "reported_capacity_pack_contact_ids_by_status" => %{
          "deferred_by_reduced_station_capacity_pack" => ["dl_capacity_overflow"],
          "selected_by_contention_resolution" => ["dl_capacity_primary"],
          "selected_by_reduced_station_capacity_pack" => ["dl_capacity_secondary"]
        },
        "reported_station_pressure_contact_ids_by_ground_station_id" => %{
          "equator_prime" => [
            "dl_capacity_overflow",
            "dl_capacity_primary",
            "dl_capacity_secondary"
          ]
        },
        "reported_station_pressure_contact_ids_by_availability" => %{
          "available" => [
            "dl_capacity_overflow",
            "dl_capacity_primary",
            "dl_capacity_secondary"
          ],
          "reduced_capacity" => [
            "dl_capacity_overflow",
            "dl_capacity_primary",
            "dl_capacity_secondary"
          ]
        },
        "reported_station_pressure_contact_ids_by_precedence_availability" => %{
          "reduced_capacity" => [
            "dl_capacity_overflow",
            "dl_capacity_primary",
            "dl_capacity_secondary"
          ]
        },
        "reported_station_pressure_contact_ids_by_precedence_rank" => %{
          "2" => [
            "dl_capacity_overflow",
            "dl_capacity_primary",
            "dl_capacity_secondary"
          ]
        },
        "contact_ids_by_effective_allocation_status" => %{
          "allocated" => ["dl_capacity_primary", "dl_capacity_secondary"],
          "deferred" => ["dl_capacity_overflow"]
        },
        "station_calendar_trust_boundary_status_counts" => %{"declared" => 3},
        "calendar_entry_trust_boundary_status_counts" => %{"declared" => 1},
        "model_limit_count" => 8
      },
      "tolerances" => %{
        "input_contact_count" => 0,
        "row_count" => 0,
        "allocated_contact_count" => 0,
        "returned_allocated_contact_count" => 0,
        "deferred_contact_count" => 0,
        "blocked_contact_count" => 0,
        "reduced_capacity_pack_group_count" => 0,
        "reduced_capacity_pack_capacity_fraction_total" => 0.0,
        "reduced_capacity_pack_used_fraction_total" => 0.0,
        "reduced_capacity_pack_unused_fraction_total" => 0.0,
        "reduced_capacity_pack_selected_contact_count" => 0,
        "reduced_capacity_pack_capacity_packed_contact_count" => 0,
        "reduced_capacity_pack_deferred_contact_count" => 0,
        "required_capacity_fraction_total" => 0.0,
        "selected_contact_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external allocation validation",
        "checks reduced-capacity station pack counts, contact routing, capacity fractions, and model-limit boundary only"
      ]
    },
    "fixture.artifact.contact_filter_report.v1" => %{
      "id" => "fixture.artifact.contact_filter_report.v1",
      "model_id" => "artifact.contact_filter_report.v1",
      "reference_case" => "checked-in contact filter artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/contact_filter_report_v1.json",
        "contract" => "contact_filter_report.v1"
      },
      "expected" => %{
        "schema_contract" => "contact_filter_report.v1",
        "model" => "thin_ground_network_availability_filter",
        "input_candidate_count" => 3,
        "kept_candidate_count" => 0,
        "suppressed_candidate_count" => 3,
        "row_derived_suppressed_candidate_count" => 3,
        "suppressed_candidate_row_count" => 3,
        "duplicate_suppressed_candidate_id_count" => 0,
        "duplicate_suppressed_candidate_row_count" => 0,
        "station_reservation_match_status_counts" => %{"overlap" => 1},
        "suppressed_reason_counts" => %{
          "ground_station_reserved" => 1,
          "ground_station_unavailable" => 2
        },
        "suppressed_station_availability_counts" => %{
          "reserved" => 1,
          "unavailable" => 2
        },
        "suppressed_candidate_ids_by_reason" => %{
          "ground_station_reserved" => ["leo_2_downlink_polar_north_1"],
          "ground_station_unavailable" => [
            "leo_1_downlink_equator_prime_1",
            "leo_1_tracking_equator_prime_1"
          ]
        },
        "model_limit_count" => 5
      },
      "tolerances" => %{
        "input_candidate_count" => 0,
        "kept_candidate_count" => 0,
        "suppressed_candidate_count" => 0,
        "row_derived_suppressed_candidate_count" => 0,
        "suppressed_candidate_row_count" => 0,
        "duplicate_suppressed_candidate_id_count" => 0,
        "duplicate_suppressed_candidate_row_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not provider availability validation",
        "checks contact filter counts, suppression routing maps, and model-limit boundary only"
      ]
    },
    "fixture.artifact.contact_contention_report.v1" => %{
      "id" => "fixture.artifact.contact_contention_report.v1",
      "model_id" => "artifact.contact_contention_report.v1",
      "reference_case" => "checked-in contact contention artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/contact_contention_report_v1.json",
        "contract" => "contact_contention_report.v1"
      },
      "expected" => %{
        "schema_contract" => "contact_contention_report.v1",
        "model" => "single_station_interval_overlap",
        "input_contact_count" => 4,
        "conflict_group_count" => 2,
        "row_derived_conflict_group_count" => 2,
        "conflict_group_row_count" => 2,
        "conflicted_contact_count" => 4,
        "row_derived_conflicted_contact_count" => 4,
        "group_contact_count_total" => 4,
        "row_derived_group_contact_count_total" => 4,
        "duplicate_contact_candidate_count" => 0,
        "duplicate_contact_id_count" => 0,
        "review_required_group_count" => 2,
        "row_derived_review_required_group_count" => 2,
        "resource_scope_counts" => %{"ground_station" => 1, "spacecraft" => 1},
        "required_operator_action_counts" => %{"review_contact_contention" => 2},
        "conflict_group_ids_by_resource_scope" => %{
          "ground_station" => ["station:equator_prime:contention:1"],
          "spacecraft" => ["spacecraft:sat_1:contention:1"]
        },
        "model_limit_count" => 5
      },
      "tolerances" => %{
        "input_contact_count" => 0,
        "conflict_group_count" => 0,
        "row_derived_conflict_group_count" => 0,
        "conflict_group_row_count" => 0,
        "conflicted_contact_count" => 0,
        "row_derived_conflicted_contact_count" => 0,
        "group_contact_count_total" => 0,
        "row_derived_group_contact_count_total" => 0,
        "duplicate_contact_candidate_count" => 0,
        "duplicate_contact_id_count" => 0,
        "review_required_group_count" => 0,
        "row_derived_review_required_group_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not provider schedule validation",
        "checks contact contention counts, operator-action routing, resource-scope maps, and model-limit boundary only"
      ]
    },
    "fixture.artifact.contact_contention_report.cross_station_spacecraft" => %{
      "id" => "fixture.artifact.contact_contention_report.cross_station_spacecraft",
      "model_id" => "artifact.contact_contention_report.v1",
      "reference_case" => "generated cross-station same-spacecraft contact contention challenge",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "source" => "generated_cross_station_spacecraft_contention_fixture",
        "contract" => "contact_contention_report.v1"
      },
      "expected" => %{
        "schema_contract" => "contact_contention_report.v1",
        "model" => "single_station_interval_overlap",
        "input_contact_count" => 3,
        "conflict_group_count" => 1,
        "row_derived_conflict_group_count" => 1,
        "conflict_group_row_count" => 1,
        "conflicted_contact_count" => 2,
        "row_derived_conflicted_contact_count" => 2,
        "group_contact_count_total" => 2,
        "row_derived_group_contact_count_total" => 2,
        "duplicate_contact_candidate_count" => 0,
        "duplicate_contact_id_count" => 0,
        "review_required_group_count" => 1,
        "row_derived_review_required_group_count" => 1,
        "resource_scope_counts" => %{"spacecraft" => 1},
        "required_operator_action_counts" => %{"review_contact_contention" => 1},
        "conflict_group_ids_by_resource_scope" => %{
          "spacecraft" => ["spacecraft:sat_1:contention:1"]
        },
        "model_limit_count" => 5
      },
      "tolerances" => %{
        "input_contact_count" => 0,
        "conflict_group_count" => 0,
        "row_derived_conflict_group_count" => 0,
        "conflict_group_row_count" => 0,
        "conflicted_contact_count" => 0,
        "row_derived_conflicted_contact_count" => 0,
        "group_contact_count_total" => 0,
        "row_derived_group_contact_count_total" => 0,
        "duplicate_contact_candidate_count" => 0,
        "duplicate_contact_id_count" => 0,
        "review_required_group_count" => 0,
        "row_derived_review_required_group_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal generated artifact regression, not provider schedule validation",
        "checks same-spacecraft cross-station contention routing without provider reservation or schedule mutation"
      ]
    },
    "fixture.artifact.contact_contention_resolution_report.v1" => %{
      "id" => "fixture.artifact.contact_contention_resolution_report.v1",
      "model_id" => "artifact.contact_contention_resolution_report.v1",
      "reference_case" => "checked-in contact contention resolution artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/contact_contention_resolution_report_v1.json",
        "contract" => "contact_contention_resolution_report.v1"
      },
      "expected" => %{
        "schema_contract" => "contact_contention_resolution_report.v1",
        "model" => "deterministic_contact_contention_recommendation",
        "conflict_group_count" => 2,
        "row_derived_conflict_group_count" => 2,
        "recommendation_count" => 2,
        "row_derived_recommendation_count" => 2,
        "recommendation_row_count" => 2,
        "candidate_count_total" => 4,
        "selected_contact_count" => 2,
        "row_derived_selected_contact_count" => 2,
        "deferred_contact_count" => 2,
        "row_derived_deferred_contact_count" => 2,
        "review_required_recommendation_count" => 2,
        "row_derived_review_required_recommendation_count" => 2,
        "resource_scope_counts" => %{"ground_station" => 1, "spacecraft" => 1},
        "action_counts" => %{"recommend_preferred_contact_for_operator_review" => 2},
        "selection_reason_counts" => %{"highest_score_earliest_start" => 2},
        "selected_contact_ids_by_resource_scope" => %{
          "ground_station" => ["dl_1"],
          "spacecraft" => ["dl_3"]
        },
        "resolution_boundary" => "recommendation_only_no_station_reservation",
        "model_limit_count" => 5
      },
      "tolerances" => %{
        "conflict_group_count" => 0,
        "row_derived_conflict_group_count" => 0,
        "recommendation_count" => 0,
        "row_derived_recommendation_count" => 0,
        "recommendation_row_count" => 0,
        "candidate_count_total" => 0,
        "selected_contact_count" => 0,
        "row_derived_selected_contact_count" => 0,
        "deferred_contact_count" => 0,
        "row_derived_deferred_contact_count" => 0,
        "review_required_recommendation_count" => 0,
        "row_derived_review_required_recommendation_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not provider reservation or schedule validation",
        "checks contention-resolution recommendation counts, routing maps, no-reservation boundary, and model-limit boundary only"
      ]
    },
    "fixture.artifact.contact_contention_resolution_summary.v1" => %{
      "id" => "fixture.artifact.contact_contention_resolution_summary.v1",
      "model_id" => "artifact.contact_contention_resolution_summary.v1",
      "reference_case" => "checked-in contact contention resolution summary artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/contact_contention_resolution_summary_v1.json",
        "contract" => "contact_contention_resolution_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "contact_contention_resolution_summary.v1",
        "model" => "artifact_only_contact_contention_resolution_summary",
        "source_artifact_type" => "contact_contention_resolution_report.v1",
        "conflict_group_count" => 2,
        "recommendation_count" => 2,
        "recommendation_group_ids" =>
          "spacecraft:sat_1:contention:1|station:equator_prime:contention:1",
        "review_group_ids" => "spacecraft:sat_1:contention:1|station:equator_prime:contention:1",
        "selected_contact_ids" => "dl_1|dl_3",
        "selected_contact_ids_by_group_id" => %{
          "spacecraft:sat_1:contention:1" => ["dl_3"],
          "station:equator_prime:contention:1" => ["dl_1"]
        },
        "deferred_contact_ids" => "dl_2|dl_4",
        "deferred_contact_ids_by_group_id" => %{
          "spacecraft:sat_1:contention:1" => ["dl_4"],
          "station:equator_prime:contention:1" => ["dl_2"]
        },
        "review_contact_ids" => "dl_1|dl_2|dl_3|dl_4",
        "review_contact_ids_by_group_id" => %{
          "spacecraft:sat_1:contention:1" => ["dl_3", "dl_4"],
          "station:equator_prime:contention:1" => ["dl_1", "dl_2"]
        },
        "review_recommendation_count" => 2,
        "resource_scope_counts" => %{"ground_station" => 1, "spacecraft" => 1},
        "selected_contact_ids_by_resource_scope" => %{
          "ground_station" => ["dl_1"],
          "spacecraft" => ["dl_3"]
        },
        "deferred_contact_ids_by_resource_scope" => %{
          "ground_station" => ["dl_2"],
          "spacecraft" => ["dl_4"]
        },
        "review_contact_ids_by_resource_scope" => %{
          "ground_station" => ["dl_1", "dl_2"],
          "spacecraft" => ["dl_3", "dl_4"]
        },
        "selection_reason_counts" => %{"highest_score_earliest_start" => 2},
        "selected_contact_ids_by_selection_reason" => %{
          "highest_score_earliest_start" => ["dl_1", "dl_3"]
        },
        "action_counts" => %{"recommend_preferred_contact_for_operator_review" => 2},
        "review_contact_ids_by_action" => %{
          "recommend_preferred_contact_for_operator_review" => [
            "dl_1",
            "dl_2",
            "dl_3",
            "dl_4"
          ]
        },
        "ambiguous_group_ids" => "",
        "ambiguous_duplicate_contact_ids" => "",
        "ambiguous_duplicate_contact_ids_by_group_id" => %{},
        "model_limit_count" => 5,
        "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation",
        "assumption_source" => "contact_contention_resolution_report.v1",
        "candidate_mutation" => "none",
        "operator_authority" => "not_granted_by_summary",
        "no_provider_reservation" => true,
        "no_candidate_suppression" => true,
        "no_schedule_mutation" => true,
        "no_link_budget_model" => true
      },
      "tolerances" => %{
        "conflict_group_count" => 0,
        "recommendation_count" => 0,
        "review_recommendation_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by contact_contention_resolution_summary.v1 validation tests"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not provider reservation or schedule validation",
        "checks compact contention-resolution routing, review handoff IDs, model limits, and no-mutation boundaries only"
      ]
    },
    "fixture.artifact.relay_data_path_summary.v1" => %{
      "id" => "fixture.artifact.relay_data_path_summary.v1",
      "model_id" => "artifact.relay_data_path_summary.v1",
      "reference_case" => "checked-in relay data-path summary artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/relay_data_path_summary_v1.json",
        "contract" => "relay_data_path_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "relay_data_path_summary.v1",
        "model" => "artifact_only_relay_data_path_summary",
        "source" => "relay_ops",
        "route_count" => 2,
        "row_derived_route_count" => 2,
        "relay_route_count" => 1,
        "row_derived_relay_route_count" => 1,
        "direct_downlink_route_count" => 1,
        "row_derived_direct_downlink_route_count" => 1,
        "custody_status_counts" => %{"confirmed" => 1, "missing_ack" => 1},
        "row_derived_custody_status_counts" => %{"confirmed" => 1, "missing_ack" => 1},
        "latency_status_counts" => %{"exceeds_limit" => 1, "within_limit" => 1},
        "row_derived_latency_status_counts" => %{"exceeds_limit" => 1, "within_limit" => 1},
        "risk_status_counts" => %{"high" => 1, "nominal" => 1},
        "row_derived_risk_status_counts" => %{"high" => 1, "nominal" => 1},
        "route_ids" => "relay_data_path:sat_a:downlink_1:54b7e7ff594c|route_direct",
        "row_derived_route_ids" => "relay_data_path:sat_a:downlink_1:54b7e7ff594c|route_direct",
        "source_spacecraft_ids" => "sat_a|sat_b",
        "row_derived_source_spacecraft_ids" => "sat_a|sat_b",
        "relay_spacecraft_ids" => "relay_1|relay_2",
        "row_derived_relay_spacecraft_ids" => "relay_1|relay_2",
        "ground_station_ids" => "dss_14|dss_35",
        "row_derived_ground_station_ids" => "dss_14|dss_35",
        "ground_downlink_contact_ids" => "downlink_1|downlink_2",
        "row_derived_ground_downlink_contact_ids" => "downlink_1|downlink_2",
        "route_ids_by_custody_status" => %{
          "confirmed" => ["relay_data_path:sat_a:downlink_1:54b7e7ff594c"],
          "missing_ack" => ["route_direct"]
        },
        "row_derived_route_ids_by_custody_status" => %{
          "confirmed" => ["relay_data_path:sat_a:downlink_1:54b7e7ff594c"],
          "missing_ack" => ["route_direct"]
        },
        "route_ids_by_latency_status" => %{
          "exceeds_limit" => ["route_direct"],
          "within_limit" => ["relay_data_path:sat_a:downlink_1:54b7e7ff594c"]
        },
        "row_derived_route_ids_by_latency_status" => %{
          "exceeds_limit" => ["route_direct"],
          "within_limit" => ["relay_data_path:sat_a:downlink_1:54b7e7ff594c"]
        },
        "route_ids_by_risk_status" => %{
          "high" => ["route_direct"],
          "nominal" => ["relay_data_path:sat_a:downlink_1:54b7e7ff594c"]
        },
        "row_derived_route_ids_by_risk_status" => %{
          "high" => ["route_direct"],
          "nominal" => ["relay_data_path:sat_a:downlink_1:54b7e7ff594c"]
        },
        "route_ids_by_ground_station_id" => %{
          "dss_14" => ["relay_data_path:sat_a:downlink_1:54b7e7ff594c"],
          "dss_35" => ["route_direct"]
        },
        "row_derived_route_ids_by_ground_station_id" => %{
          "dss_14" => ["relay_data_path:sat_a:downlink_1:54b7e7ff594c"],
          "dss_35" => ["route_direct"]
        },
        "maximum_latency_s" => 500.0,
        "row_derived_maximum_latency_s" => 500.0,
        "maximum_latency_limit_s" => 300.0,
        "row_derived_maximum_latency_limit_s" => 300.0,
        "execution_boundary" => "artifact_only_no_relay_scheduling_or_schedule_mutation",
        "custody_acknowledgement_delivery" => "not_performed",
        "model_limit_count" => 6
      },
      "tolerances" => %{
        "route_count" => 0,
        "row_derived_route_count" => 0,
        "relay_route_count" => 0,
        "row_derived_relay_route_count" => 0,
        "direct_downlink_route_count" => 0,
        "row_derived_direct_downlink_route_count" => 0,
        "maximum_latency_s" => 0,
        "row_derived_maximum_latency_s" => 0,
        "maximum_latency_limit_s" => 0,
        "row_derived_maximum_latency_limit_s" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not relay scheduling validation",
        "checks relay/direct route counts, custody/latency/risk routing maps, route IDs, and model-limit boundary only"
      ]
    },
    "fixture.artifact.maneuver_review_report.v1" => %{
      "id" => "fixture.artifact.maneuver_review_report.v1",
      "model_id" => "artifact.maneuver_review_report.v1",
      "reference_case" => "checked-in maneuver review artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/maneuver_review_report_v1.json",
        "contract" => "maneuver_review_report.v1"
      },
      "expected" => %{
        "schema_contract" => "maneuver_review_report.v1",
        "model" => "artifact_only_maneuver_review_report",
        "source" => "study_results/mission_plan_checkout.json.maneuver_recommendations",
        "source_artifact_id" => "mission_plan_checkout",
        "maneuver_count" => 1,
        "row_count" => 1,
        "review_required_count" => 1,
        "invalid_maneuver_recommendation_count" => 0,
        "invalid_maneuver_recommendation_id_count" => 0,
        "execution_uncertainty_declared_count" => 0,
        "execution_uncertainty_missing_count" => 1,
        "total_delta_v_km_s" => 0.01,
        "approval_status_counts" => %{"operator_review_required" => 1},
        "required_operator_action_counts" => %{"review_maneuver_recommendation" => 1},
        "execution_uncertainty_status_counts" => %{"missing" => 1},
        "maneuver_review_ids_by_required_operator_action" => %{
          "review_maneuver_recommendation" => ["maneuver_review:ops_checkout:trim_burn"]
        },
        "execution_boundary" => "recommendation_only_no_command_execution",
        "review_boundary" => "review_only_no_command_execution",
        "model_limit_count" => 5
      },
      "tolerances" => %{
        "maneuver_count" => 0,
        "row_count" => 0,
        "review_required_count" => 0,
        "invalid_maneuver_recommendation_count" => 0,
        "invalid_maneuver_recommendation_id_count" => 0,
        "execution_uncertainty_declared_count" => 0,
        "execution_uncertainty_missing_count" => 0,
        "total_delta_v_km_s" => 0.0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not maneuver execution validation",
        "checks maneuver review counts, operator-action routing, and no-command boundary only"
      ]
    },
    "fixture.artifact.monte_carlo_reproducibility_report.v1" => %{
      "id" => "fixture.artifact.monte_carlo_reproducibility_report.v1",
      "model_id" => "artifact.monte_carlo_reproducibility_report.v1",
      "reference_case" => "checked-in Monte Carlo reproducibility artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/monte_carlo_reproducibility_report_v1.json",
        "contract" => "monte_carlo_reproducibility_report.v1"
      },
      "expected" => %{
        "schema_contract" => "monte_carlo_reproducibility_report.v1",
        "model" => "seeded_independent_normal_cartesian_dispersion",
        "source" => "study_metadata.monte_carlo",
        "generator" => "state_vector_dispersion",
        "requested_count" => 20,
        "generated_scenario_count" => 20,
        "generated_scenario_id_count" => 20,
        "first_generated_scenario_id" => "dispersion_1",
        "last_generated_scenario_id" => "dispersion_20",
        "deterministic_seed" => true,
        "seed" => 12345,
        "rng" => "rand_exsss",
        "sampling_method" => "box_muller_transform",
        "id_prefix" => "dispersion",
        "position_sigma_km" => [0.1, 0.1, 0.05],
        "velocity_sigma_km_s" => [0.0001, 0.0001, 0.00005],
        "distribution" => "independent normal per Cartesian component",
        "covariance_model" => "none",
        "model_limit_count" => 4,
        "known_limit_count" => 4
      },
      "tolerances" => %{
        "requested_count" => 0,
        "generated_scenario_count" => 0,
        "generated_scenario_id_count" => 0,
        "seed" => 0,
        "position_sigma_km" => 0.0,
        "velocity_sigma_km_s" => 0.0,
        "model_limit_count" => 0,
        "known_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not statistical validation",
        "checks seeded reproducibility counts, RNG metadata, dispersion sigmas, and model-limit boundary only"
      ]
    },
    "fixture.artifact.pareto_frontier_report.v1" => %{
      "id" => "fixture.artifact.pareto_frontier_report.v1",
      "model_id" => "artifact.pareto_frontier_report.v1",
      "reference_case" => "checked-in Pareto frontier artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/pareto_frontier_report_v1.json",
        "contract" => "pareto_frontier_report.v1"
      },
      "expected" => %{
        "schema_contract" => "pareto_frontier_report.v1",
        "model" => "objective_vector_pareto_frontier",
        "source" => "strategy.branch_objectives",
        "alternative_count" => 4,
        "row_count" => 4,
        "frontier_count" => 3,
        "dominated_count" => 1,
        "objective_count" => 2,
        "objective_directions" => %{"coverage" => "maximize", "risk" => "minimize"},
        "frontier_status_counts" => %{"false" => 1, "true" => 3},
        "objective_key_count_counts" => %{"0" => 1, "2" => 3},
        "alternative_ids_by_frontier_status" => %{
          "false" => ["dominated"],
          "true" => ["balanced", "coverage_leader", "ignored_no_numeric"]
        },
        "missing_objective_policy" => "alternative_with_missing_objective_cannot_dominate",
        "search_performed" => false,
        "model_limit_count" => 4
      },
      "tolerances" => %{
        "alternative_count" => 0,
        "row_count" => 0,
        "frontier_count" => 0,
        "dominated_count" => 0,
        "objective_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external optimizer validation",
        "checks deterministic frontier counts, dominance routing, and no-solver boundary only"
      ]
    },
    "fixture.artifact.resource_projection_report.v1" => %{
      "id" => "fixture.artifact.resource_projection_report.v1",
      "model_id" => "artifact.resource_projection_report.v1",
      "reference_case" => "checked-in selected-activity resource projection artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/resource_projection_report_v1.json",
        "contract" => "resource_projection_report.v1"
      },
      "expected" => %{
        "schema_contract" => "resource_projection_report.v1",
        "model" => "thin_campaign_selected_activity_resource_projection",
        "activity_count" => 1,
        "input_resource_summary_count" => 1,
        "valid_activity_count" => 1,
        "invalid_activity_input_count" => 0,
        "projected_resource_count" => 1,
        "activity_resource_flow_count" => 1,
        "resource_pressure_row_count" => 0,
        "storage_overflow_row_count" => 0,
        "downlink_shortfall_row_count" => 0,
        "projected_storage_overflow_mb_total" => 0.0,
        "projected_downlink_shortfall_mb_total" => 0.0,
        "warning_count" => 0,
        "model_limit_count" => 9,
        "resource_source_quality_counts" => %{"operator_supplied" => 1},
        "resource_trust_boundary_status_counts" => %{"missing" => 1}
      },
      "tolerances" => %{
        "activity_count" => 0,
        "input_resource_summary_count" => 0,
        "valid_activity_count" => 0,
        "invalid_activity_input_count" => 0,
        "projected_resource_count" => 0,
        "activity_resource_flow_count" => 0,
        "resource_pressure_row_count" => 0,
        "storage_overflow_row_count" => 0,
        "downlink_shortfall_row_count" => 0,
        "projected_storage_overflow_mb_total" => 0.0,
        "projected_downlink_shortfall_mb_total" => 0.0,
        "warning_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external resource-model validation",
        "checks resource projection counts, pressure routing counts, and summary maps only"
      ]
    },
    "fixture.artifact.resource_projection_flow_summary.v1" => %{
      "id" => "fixture.artifact.resource_projection_flow_summary.v1",
      "model_id" => "artifact.resource_projection_flow_summary.v1",
      "reference_case" => "checked-in compact selected-activity resource-flow summary artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/resource_projection_flow_summary_v1.json",
        "contract" => "resource_projection_flow_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "resource_projection_flow_summary.v1",
        "model" => "artifact_only_selected_activity_resource_flow_summary",
        "source" => "campaign.resource_summaries",
        "activity_count" => 1,
        "valid_activity_count" => 1,
        "invalid_activity_input_count" => 0,
        "input_resource_summary_count" => 1,
        "valid_resource_summary_count" => 1,
        "invalid_resource_summary_input_count" => 0,
        "projected_resource_count" => 1,
        "flow_row_count" => 1,
        "resource_flow_status" => "clear",
        "resource_pressure_status" => "clear",
        "resource_pressure_count" => 0,
        "total_storage_produced_mb" => 0.0,
        "total_storage_limited_downlinked_mb" => 0.0,
        "total_downlink_shortfall_mb" => 0.0,
        "total_unused_downlink_capacity_mb" => 0.0,
        "total_battery_energy_consumed_wh" => 120.0,
        "total_battery_energy_generated_wh" => 0.0,
        "net_battery_energy_delta_wh" => 120.0,
        "peak_battery_overuse_wh" => 0.0,
        "total_projected_storage_remaining_mb" => 750.0,
        "minimum_projected_storage_remaining_mb" => 750.0,
        "total_projected_downlink_remaining_mb" => 600.0,
        "minimum_projected_downlink_remaining_mb" => 600.0,
        "ignored_activity_count" => 0,
        "ignored_activity_reason_counts" => %{},
        "resource_pressure_types" => [],
        "model_limit_count" => 9,
        "execution_boundary" => "artifact_only_no_schedule_mutation"
      },
      "tolerances" => %{
        "activity_count" => 0,
        "valid_activity_count" => 0,
        "invalid_activity_input_count" => 0,
        "input_resource_summary_count" => 0,
        "valid_resource_summary_count" => 0,
        "invalid_resource_summary_input_count" => 0,
        "projected_resource_count" => 0,
        "flow_row_count" => 0,
        "resource_pressure_count" => 0,
        "total_storage_produced_mb" => 0.0,
        "total_storage_limited_downlinked_mb" => 0.0,
        "total_downlink_shortfall_mb" => 0.0,
        "total_unused_downlink_capacity_mb" => 0.0,
        "total_battery_energy_consumed_wh" => 0.0,
        "total_battery_energy_generated_wh" => 0.0,
        "net_battery_energy_delta_wh" => 0.0,
        "peak_battery_overuse_wh" => 0.0,
        "total_projected_storage_remaining_mb" => 0.0,
        "minimum_projected_storage_remaining_mb" => 0.0,
        "total_projected_downlink_remaining_mb" => 0.0,
        "minimum_projected_downlink_remaining_mb" => 0.0,
        "ignored_activity_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external resource-model validation",
        "checks compact resource-flow row-derived storage, downlink, battery, and pressure evidence only"
      ]
    },
    "fixture.artifact.resource_projection_report.battery_handoff_v1" => %{
      "id" => "fixture.artifact.resource_projection_report.battery_handoff_v1",
      "model_id" => "artifact.resource_projection_report.v1",
      "reference_case" => "checked-in resource projection battery handoff source artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/resource_projection_battery_handoff_v1.json",
        "contract" => "resource_projection_report.v1"
      },
      "expected" => %{
        "schema_contract" => "resource_projection_report.v1",
        "model" => "thin_battery_handoff_resource_projection_fixture",
        "activity_count" => 2,
        "projected_resource_count" => 1,
        "activity_resource_flow_count" => 2,
        "storage_overflow_row_count" => 1,
        "downlink_shortfall_row_count" => 1,
        "total_battery_energy_consumed_wh" => 23.0,
        "total_battery_energy_generated_wh" => 8.0,
        "net_battery_energy_delta_wh" => 15.0,
        "peak_battery_overuse_wh" => 4.0,
        "model_limit_count" => 9
      },
      "tolerances" => %{
        "activity_count" => 0,
        "projected_resource_count" => 0,
        "activity_resource_flow_count" => 0,
        "storage_overflow_row_count" => 0,
        "downlink_shortfall_row_count" => 0,
        "total_battery_energy_consumed_wh" => 0.0,
        "total_battery_energy_generated_wh" => 0.0,
        "net_battery_energy_delta_wh" => 0.0,
        "peak_battery_overuse_wh" => 0.0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external resource-model validation",
        "checks battery flow aggregation source values for review/import handoff fixtures only"
      ]
    },
    "fixture.artifact.resource_projection_report.stale_resource_summary_margins" => %{
      "id" => "fixture.artifact.resource_projection_report.stale_resource_summary_margins",
      "model_id" => "artifact.resource_projection_report.v1",
      "reference_case" => "generated stale derived-margin resource projection challenge",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "source" => "generated_resource_projection_stale_derived_margin_fixture",
        "contract" => "resource_projection_report.v1"
      },
      "expected" => %{
        "schema_contract" => "resource_projection_report.v1",
        "model" => "thin_stale_derived_margin_resource_projection_fixture",
        "activity_count" => 1,
        "input_resource_summary_count" => 3,
        "valid_resource_summary_count" => 1,
        "invalid_activity_input_count" => 0,
        "invalid_resource_summary_input_count" => 2,
        "invalid_resource_summary_input_ids" => "leo_2|leo_3",
        "invalid_resource_summary_input_reasons" =>
          "stale_battery_state_of_charge|stale_storage_margin",
        "stale_battery_state_of_charge_count" => 1,
        "stale_storage_margin_count" => 1,
        "projected_resource_count" => 1,
        "activity_resource_flow_count" => 1,
        "model_limit_count" => 9
      },
      "tolerances" => %{
        "activity_count" => 0,
        "input_resource_summary_count" => 0,
        "valid_resource_summary_count" => 0,
        "invalid_activity_input_count" => 0,
        "invalid_resource_summary_input_count" => 0,
        "stale_battery_state_of_charge_count" => 0,
        "stale_storage_margin_count" => 0,
        "projected_resource_count" => 0,
        "activity_resource_flow_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal generated artifact regression, not external resource-model validation",
        "checks stale explicit battery and storage derived-margin evidence is preserved for review"
      ]
    },
    "fixture.artifact.resource_summary.v1" => %{
      "id" => "fixture.artifact.resource_summary.v1",
      "model_id" => "artifact.resource_summary.v1",
      "reference_case" => "checked-in planning resource summary artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/resource_summary_v1.json",
        "contract" => "resource_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "resource_summary.v1",
        "spacecraft_id" => "leo_1",
        "mode" => "degraded",
        "fuel_margin" => 0.82,
        "power_margin" => 0.74,
        "battery_capacity_wh" => 1200.0,
        "battery_energy_used_wh" => 312.0,
        "battery_state_of_charge" => 0.74,
        "thermal_margin_c" => -2.5,
        "storage_capacity_mb" => 1000.0,
        "storage_used_mb" => 250.0,
        "storage_margin" => 0.75,
        "downlink_capacity_mb" => 600.0,
        "downlink_margin" => 0.65,
        "spacecraft_available" => false,
        "payload_available" => false,
        "antenna_available" => true,
        "degraded" => true,
        "source_quality" => "operator_supplied",
        "trust_boundary" => "operator_declared_resource_summary",
        "suppressed_activity_type_count" => 2,
        "suppressed_activity_type_order" => "observe|command",
        "incompatible_activity_type_count" => 2,
        "incompatible_activity_type_order" => "command|health_check",
        "assumption_source" => "campaign_manifest_demo",
        "provenance_source" => "ops"
      },
      "tolerances" => %{
        "fuel_margin" => 0.0,
        "power_margin" => 0.0,
        "battery_capacity_wh" => 0.0,
        "battery_energy_used_wh" => 0.0,
        "battery_state_of_charge" => 0.0,
        "thermal_margin_c" => 0.0,
        "storage_capacity_mb" => 0.0,
        "storage_used_mb" => 0.0,
        "storage_margin" => 0.0,
        "downlink_capacity_mb" => 0.0,
        "downlink_margin" => 0.0,
        "suppressed_activity_type_count" => 0,
        "incompatible_activity_type_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external resource-model validation",
        "checks resource-summary normalization, derived margins, availability flags, and provenance boundaries only"
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
    "fixture.artifact.resource_filter_report.v1" => %{
      "id" => "fixture.artifact.resource_filter_report.v1",
      "model_id" => "artifact.resource_filter_report.v1",
      "reference_case" => "checked-in resource filter artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/resource_filter_report_v1.json",
        "contract" => "resource_filter_report.v1"
      },
      "expected" => %{
        "schema_contract" => "resource_filter_report.v1",
        "model" => "resource_summary_availability_and_margin_filter",
        "input_candidate_count" => 3,
        "kept_candidate_count" => 1,
        "suppressed_candidate_count" => 2,
        "suppressed_candidate_row_count" => 2,
        "invalid_candidate_input_count" => 0,
        "duplicate_suppressed_candidate_id_count" => 0,
        "duplicate_suppressed_candidate_row_count" => 0,
        "resource_source_quality_counts" => %{"operator_supplied" => 1},
        "resource_trust_boundary_status_counts" => %{"missing" => 1},
        "suppressed_resource_source_quality_counts" => %{"operator_supplied" => 2},
        "suppressed_resource_trust_boundary_status_counts" => %{"missing" => 2},
        "suppressed_reason_counts" => %{
          "downlink_margin_below_policy" => 1,
          "storage_margin_below_observe_policy" => 1
        },
        "suppressed_blocking_dimension_counts" => %{"downlink" => 1, "storage" => 1},
        "suppressed_candidate_ids_by_blocking_dimension" => %{
          "downlink" => ["leo_1_downlink_equator_prime_1"],
          "storage" => ["leo_1_observe_target_a_1"]
        },
        "model_limit_count" => 5
      },
      "tolerances" => %{
        "input_candidate_count" => 0,
        "kept_candidate_count" => 0,
        "suppressed_candidate_count" => 0,
        "suppressed_candidate_row_count" => 0,
        "invalid_candidate_input_count" => 0,
        "duplicate_suppressed_candidate_id_count" => 0,
        "duplicate_suppressed_candidate_row_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not subsystem simulation validation",
        "checks resource filter counts, suppression routing maps, trust-boundary maps, and model-limit boundary only"
      ]
    },
    "fixture.artifact.resource_filter_summary.v1" => %{
      "id" => "fixture.artifact.resource_filter_summary.v1",
      "model_id" => "artifact.resource_filter_summary.v1",
      "reference_case" => "checked-in resource filter summary artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/resource_filter_summary_v1.json",
        "contract" => "resource_filter_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "resource_filter_summary.v1",
        "model" => "artifact_only_resource_filter_summary",
        "source_artifact_type" => "resource_filter_report.v1",
        "input_candidate_count" => 3,
        "kept_candidate_count" => 1,
        "suppressed_candidate_count" => 2,
        "suppression_review_status" => "review_required",
        "suppressed_candidate_ids" => "leo_1_downlink_equator_prime_1|leo_1_observe_target_a_1",
        "suppressed_reason_counts" => %{
          "downlink_margin_below_policy" => 1,
          "storage_margin_below_observe_policy" => 1
        },
        "suppressed_candidate_ids_by_reason" => %{
          "downlink_margin_below_policy" => ["leo_1_downlink_equator_prime_1"],
          "storage_margin_below_observe_policy" => ["leo_1_observe_target_a_1"]
        },
        "resource_blocking_dimension_counts" => %{"downlink" => 1, "storage" => 1},
        "suppressed_candidate_ids_by_resource_blocking_dimension" => %{
          "downlink" => ["leo_1_downlink_equator_prime_1"],
          "storage" => ["leo_1_observe_target_a_1"]
        },
        "suppressed_candidate_ids_by_scenario_id" => %{
          "leo_1" => ["leo_1_downlink_equator_prime_1", "leo_1_observe_target_a_1"]
        },
        "suppressed_resource_source_quality_counts" => %{"operator_supplied" => 2},
        "suppressed_candidate_ids_by_resource_source_quality" => %{
          "operator_supplied" => [
            "leo_1_downlink_equator_prime_1",
            "leo_1_observe_target_a_1"
          ]
        },
        "suppressed_resource_trust_boundary_status_counts" => %{"missing" => 2},
        "suppressed_candidate_ids_by_resource_trust_boundary_status" => %{
          "missing" => ["leo_1_downlink_equator_prime_1", "leo_1_observe_target_a_1"]
        },
        "invalid_candidate_input_count" => 0,
        "invalid_candidate_input_ids" => "",
        "invalid_resource_summary_input_count" => 0,
        "invalid_resource_summary_input_ids" => "",
        "duplicate_suppressed_candidate_id_count" => 0,
        "duplicate_suppressed_candidate_row_count" => 0,
        "review_row_count" => 2,
        "review_row_ids" => "leo_1_observe_target_a_1|leo_1_downlink_equator_prime_1",
        "model_limit_count" => 5,
        "execution_boundary" => "artifact_only_no_schedule_mutation",
        "assumption_source" => "resource_filter_report.v1",
        "operator_authority" => "not_granted_by_resource_filter_summary",
        "resource_state_propagation" => "not_performed",
        "no_schedule_mutation" => true,
        "no_resource_time_propagation" => true,
        "no_subsystem_simulation" => true
      },
      "tolerances" => %{
        "input_candidate_count" => 0,
        "kept_candidate_count" => 0,
        "suppressed_candidate_count" => 0,
        "invalid_candidate_input_count" => 0,
        "invalid_resource_summary_input_count" => 0,
        "duplicate_suppressed_candidate_id_count" => 0,
        "duplicate_suppressed_candidate_row_count" => 0,
        "review_row_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by resource_filter_summary.v1 validation tests"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not subsystem simulation validation",
        "checks compact suppression counts, routing maps, review rows, and no-mutation/no-propagation boundaries only"
      ]
    },
    "fixture.artifact.resource_filter_report.stale_resource_summary_margins" => %{
      "id" => "fixture.artifact.resource_filter_report.stale_resource_summary_margins",
      "model_id" => "artifact.resource_filter_report.v1",
      "reference_case" => "generated stale derived-margin resource filter challenge",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "source" => "generated_resource_filter_stale_derived_margin_fixture",
        "contract" => "resource_filter_report.v1"
      },
      "expected" => %{
        "schema_contract" => "resource_filter_report.v1",
        "model" => "resource_summary_availability_and_margin_filter",
        "input_candidate_count" => 1,
        "kept_candidate_count" => 1,
        "suppressed_candidate_count" => 0,
        "suppressed_candidate_row_count" => 0,
        "input_resource_summary_count" => 2,
        "valid_resource_summary_count" => 0,
        "invalid_resource_summary_input_count" => 2,
        "invalid_resource_summary_input_ids" => "sat_1|sat_2",
        "invalid_resource_summary_input_reasons" =>
          "stale_battery_state_of_charge|stale_storage_margin",
        "stale_battery_state_of_charge_count" => 1,
        "stale_storage_margin_count" => 1,
        "model_limit_count" => 5
      },
      "tolerances" => %{
        "input_candidate_count" => 0,
        "kept_candidate_count" => 0,
        "suppressed_candidate_count" => 0,
        "suppressed_candidate_row_count" => 0,
        "input_resource_summary_count" => 0,
        "valid_resource_summary_count" => 0,
        "invalid_resource_summary_input_count" => 0,
        "stale_battery_state_of_charge_count" => 0,
        "stale_storage_margin_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal generated artifact regression, not subsystem simulation validation",
        "checks stale explicit battery and storage derived-margin evidence does not suppress candidates"
      ]
    },
    "fixture.artifact.objective_satisfaction_report.v1" => %{
      "id" => "fixture.artifact.objective_satisfaction_report.v1",
      "model_id" => "artifact.objective_satisfaction_report.v1",
      "reference_case" => "checked-in objective satisfaction artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/objective_satisfaction_report_v1.json",
        "contract" => "objective_satisfaction_report.v1"
      },
      "expected" => %{
        "schema_contract" => "objective_satisfaction_report.v1",
        "model" => "campaign_v1_selected_activity_objective_summary",
        "source" => "campaign_plan.activities",
        "objective_count" => 4,
        "row_count" => 4,
        "selected_count_total" => 2,
        "satisfied_count_total" => 2,
        "required_count_total" => 4,
        "status_counts" => %{
          "no_candidate_window" => 1,
          "partial" => 1,
          "selected" => 1,
          "unmet" => 1
        },
        "objective_type_counts" => %{
          "downlink_completion" => 1,
          "target_commitment" => 2,
          "target_coverage" => 1
        },
        "objective_ids_by_status" => %{
          "no_candidate_window" => ["objective:target_commitment:target_b"],
          "partial" => ["objective:target_coverage"],
          "selected" => ["objective:target_commitment:target_a"],
          "unmet" => ["objective:downlink_completion"]
        },
        "execution_status" => "planned_not_executed",
        "model_limit_count" => 4
      },
      "tolerances" => %{
        "objective_count" => 0,
        "row_count" => 0,
        "selected_count_total" => 0,
        "satisfied_count_total" => 0,
        "required_count_total" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not objective-achievement validation",
        "checks objective satisfaction counts, status routing maps, planned-not-executed boundary, and model-limit boundary only"
      ]
    },
    "fixture.artifact.objective_tradeoff_report.v1" => %{
      "id" => "fixture.artifact.objective_tradeoff_report.v1",
      "model_id" => "artifact.objective_tradeoff_report.v1",
      "reference_case" => "checked-in objective tradeoff artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/objective_tradeoff_report_v1.json",
        "contract" => "objective_tradeoff_report.v1"
      },
      "expected" => %{
        "schema_contract" => "objective_tradeoff_report.v1",
        "model" => "ranked_timeline_score_term_tradeoffs",
        "objective" => "maximize weighted observation value and contact value",
        "ranking_count" => 1,
        "tradeoff_row_count" => 1,
        "score_term_key_count" => 7,
        "activity_count_total" => 1,
        "selected_observation_count_total" => 1,
        "selected_contact_count_total" => 0,
        "score_total" => 1417.2731832107565,
        "score_delta_from_selected_total" => 0.0,
        "scenario_ids_by_rank" => %{"1" => ["leo_1"]},
        "score_term_key_counts" => %{
          "activity_count_penalty" => 1,
          "activity_score" => 1,
          "contact_value" => 1,
          "eclipse_penalty" => 1,
          "selected_contact_count" => 1,
          "selected_observation_count" => 1,
          "target_value" => 1
        },
        "selection_assumption" => "best_ranked_timeline_is_selected",
        "model_limit_count" => 4
      },
      "tolerances" => %{
        "ranking_count" => 0,
        "tradeoff_row_count" => 0,
        "score_term_key_count" => 0,
        "activity_count_total" => 0,
        "selected_observation_count_total" => 0,
        "selected_contact_count_total" => 0,
        "score_total" => 0.0,
        "score_delta_from_selected_total" => 0.0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not optimizer validation",
        "checks objective tradeoff counts, score-term shape, selected-ranking assumptions, and model-limit boundary only"
      ]
    },
    "fixture.artifact.score_term_report.v1" => %{
      "id" => "fixture.artifact.score_term_report.v1",
      "model_id" => "artifact.score_term_report.v1",
      "reference_case" => "checked-in score term artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/score_term_report_v1.json",
        "contract" => "score_term_report.v1"
      },
      "expected" => %{
        "schema_contract" => "score_term_report.v1",
        "model" => "ranked_timeline_score_terms",
        "source" => "campaign_plan.ranked_timelines",
        "row_count" => 7,
        "derived_row_count" => 7,
        "selected_row_count" => 7,
        "score_term_key_count" => 7,
        "score_term_key_counts" => %{
          "activity_count_penalty" => 1,
          "activity_score" => 1,
          "contact_value" => 1,
          "eclipse_penalty" => 1,
          "selected_contact_count" => 1,
          "selected_observation_count" => 1,
          "target_value" => 1
        },
        "row_derived_score_term_key_counts" => %{
          "activity_count_penalty" => 1,
          "activity_score" => 1,
          "contact_value" => 1,
          "eclipse_penalty" => 1,
          "selected_contact_count" => 1,
          "selected_observation_count" => 1,
          "target_value" => 1
        },
        "term_value_total" => 2835.546366421513,
        "timeline_score_total" => 9920.912282475295,
        "score_term_source" => "ranked_timeline.score_terms",
        "model_limit_count" => 4
      },
      "tolerances" => %{
        "row_count" => 0,
        "derived_row_count" => 0,
        "selected_row_count" => 0,
        "score_term_key_count" => 0,
        "term_value_total" => 0.0,
        "timeline_score_total" => 0.0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not score-policy validation",
        "checks score-term row counts, key shape, selected-row counts, score totals, and model-limit boundary only"
      ]
    },
    "fixture.artifact.ranking_comparison_report.v1" => %{
      "id" => "fixture.artifact.ranking_comparison_report.v1",
      "model_id" => "artifact.ranking_comparison_report.v1",
      "reference_case" => "checked-in ranking comparison artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/ranking_comparison_report_v1.json",
        "contract" => "ranking_comparison_report.v1"
      },
      "expected" => %{
        "schema_contract" => "ranking_comparison_report.v1",
        "model" => "scenario_ranking_pairwise_delta",
        "source" => "study_benchmark.rankings",
        "objective" => "final_radius_km",
        "objective_direction" => "maximize",
        "left_count" => 2,
        "right_count" => 2,
        "matched_count" => 1,
        "left_only_count" => 1,
        "right_only_count" => 1,
        "row_count" => 3,
        "derived_row_count" => 3,
        "status_counts" => %{"left_only" => 1, "matched" => 1, "right_only" => 1},
        "scenario_ids_by_status" => %{
          "left_only" => ["burn_a"],
          "matched" => ["burn_b"],
          "right_only" => ["burn_c"]
        },
        "rank_delta_total" => 1,
        "value_delta_total" => 15,
        "winner_changed" => true,
        "external_solver" => false,
        "model_limit_count" => 4
      },
      "tolerances" => %{
        "left_count" => 0,
        "right_count" => 0,
        "matched_count" => 0,
        "left_only_count" => 0,
        "right_only_count" => 0,
        "row_count" => 0,
        "derived_row_count" => 0,
        "rank_delta_total" => 0,
        "value_delta_total" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not optimizer validation",
        "checks ranking comparison counts, status routing, winner-change evidence, and model-limit boundary only"
      ]
    },
    "fixture.artifact.strategy_branch.v1" => %{
      "id" => "fixture.artifact.strategy_branch.v1",
      "model_id" => "artifact.strategy_branch.v1",
      "reference_case" => "checked-in standalone V3 strategy branch artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/strategy_branch_v1.json",
        "contract" => "strategy_branch.v1"
      },
      "expected" => %{
        "schema_contract" => "strategy_branch.v1",
        "branch_id" => "derived_urgent_target_target_hot",
        "label" => "Derived urgent target target_hot",
        "probability" => 1.0,
        "event_count" => 2,
        "event_type_counts" => %{"downlink_completion_gap" => 1, "urgent_target" => 1},
        "candidate_activity_count" => 0,
        "strategic_addition_count" => 0,
        "capacity_adjustment_count" => 0,
        "repair_delta_count" => 0,
        "approval_requirement_count" => 0,
        "policy_classification" => "operator_review_required",
        "policy_risk_count" => 1,
        "score" => 2835.3981832107565,
        "score_term_count" => 4,
        "warning_count" => 1,
        "risk_count" => 1,
        "approval_status" => "operator_review_required",
        "derived_source" => "mission_state.objectives",
        "tradeoff_count" => 1,
        "downlink_capacity_margin" => 0.62
      },
      "tolerances" => %{
        "probability" => 0.0,
        "event_count" => 0,
        "candidate_activity_count" => 0,
        "strategic_addition_count" => 0,
        "capacity_adjustment_count" => 0,
        "repair_delta_count" => 0,
        "approval_requirement_count" => 0,
        "policy_risk_count" => 0,
        "score" => 0.0,
        "score_term_count" => 0,
        "warning_count" => 0,
        "risk_count" => 0,
        "tradeoff_count" => 0,
        "downlink_capacity_margin" => 0.0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external strategy validation",
        "checks standalone branch event/risk/score routing only"
      ]
    },
    "fixture.artifact.strategy_recommendation.v1" => %{
      "id" => "fixture.artifact.strategy_recommendation.v1",
      "model_id" => "artifact.strategy_recommendation.v1",
      "reference_case" => "checked-in standalone V3 strategy recommendation artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/strategy_recommendation_v1.json",
        "contract" => "strategy_recommendation.v1"
      },
      "expected" => %{
        "schema_contract" => "strategy_recommendation.v1",
        "status" => "pass",
        "recommended_branch_id" => "derived_urgent_target_target_hot",
        "approval_status" => "operator_review_required",
        "reason" => "best_expected_score_requiring_operator_review",
        "ranked_branch_count" => 4,
        "ranked_branch_id_order" =>
          "derived_urgent_target_target_hot|derived_target_revisit_target_hot|derived_combined_mission_state|operator_placeholder_urgent",
        "tradeoff_count" => 3,
        "explanation_count" => 4,
        "risk_count" => 2,
        "approval_requirement_count" => 1,
        "requires_operator_review_count" => 1,
        "branch_event_summary_count" => 1,
        "branch_event_type_counts" => %{"urgent_target" => 1},
        "branch_requires_operator_review" => true
      },
      "tolerances" => %{
        "ranked_branch_count" => 0,
        "tradeoff_count" => 0,
        "explanation_count" => 0,
        "risk_count" => 0,
        "approval_requirement_count" => 0,
        "requires_operator_review_count" => 0,
        "branch_event_summary_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external strategy validation",
        "checks standalone recommendation ranking/review routing only"
      ]
    },
    "fixture.artifact.study_benchmark.v1" => %{
      "id" => "fixture.artifact.study_benchmark.v1",
      "model_id" => "artifact.study_benchmark.v1",
      "reference_case" => "checked-in persisted study benchmark artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/study_benchmark.json",
        "contract" => "study_benchmark.v1"
      },
      "expected" => %{
        "schema_version" => 1,
        "benchmark_mode_count" => 1,
        "repetition_count" => 2,
        "result_count" => 2,
        "local_result_count" => 2,
        "matches_baseline_count" => 2,
        "failure_count_total" => 0,
        "scenario_count_total" => 8,
        "trajectory_count_total" => 8,
        "manifest_path" => "studies/raise_apogee_search.json",
        "manifest_sha256_length" => 64,
        "max_duration_ms" => 3
      },
      "tolerances" => %{
        "schema_version" => 0,
        "benchmark_mode_count" => 0,
        "repetition_count" => 0,
        "result_count" => 0,
        "local_result_count" => 0,
        "matches_baseline_count" => 0,
        "failure_count_total" => 0,
        "scenario_count_total" => 0,
        "trajectory_count_total" => 0,
        "manifest_sha256_length" => 0,
        "max_duration_ms" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not performance certification",
        "checks persisted benchmark shape, counts, and baseline-match metadata only"
      ]
    },
    "fixture.artifact.study_benchmark.distributed_concurrency_sweep" => %{
      "id" => "fixture.artifact.study_benchmark.distributed_concurrency_sweep",
      "model_id" => "artifact.study_benchmark.v1",
      "reference_case" => "checked-in distributed concurrency sweep benchmark artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/distributed_concurrency_sweep.json",
        "contract" => "study_benchmark.v1"
      },
      "expected" => %{
        "schema_version" => 1,
        "benchmark_mode_count" => 2,
        "repetition_count" => 3,
        "result_count" => 108,
        "local_result_count" => 54,
        "distributed_result_count" => 54,
        "matches_baseline_count" => 108,
        "failure_count_total" => 0,
        "scenario_count_total" => 1_188_000,
        "trajectory_count_total" => 1_188_000,
        "manifest_path" => "studies/leo_dispersion_monte_carlo.json",
        "manifest_sha256_length" => 64,
        "max_duration_ms" => 3_352,
        "backend_count" => 0,
        "propagator_option_count" => 0,
        "monte_carlo_count_option_count" => 2,
        "max_concurrency_option_count" => 3,
        "task_chunk_size_option_count" => 3
      },
      "tolerances" => %{
        "schema_version" => 0,
        "benchmark_mode_count" => 0,
        "repetition_count" => 0,
        "result_count" => 0,
        "local_result_count" => 0,
        "distributed_result_count" => 0,
        "matches_baseline_count" => 0,
        "failure_count_total" => 0,
        "scenario_count_total" => 0,
        "trajectory_count_total" => 0,
        "manifest_sha256_length" => 0,
        "max_duration_ms" => 0,
        "backend_count" => 0,
        "propagator_option_count" => 0,
        "monte_carlo_count_option_count" => 0,
        "max_concurrency_option_count" => 0,
        "task_chunk_size_option_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not performance certification",
        "checks distributed/local benchmark rows, option sweep shape, and baseline-match metadata only"
      ]
    },
    "fixture.artifact.study_benchmark.distributed_chunk_sweep" => %{
      "id" => "fixture.artifact.study_benchmark.distributed_chunk_sweep",
      "model_id" => "artifact.study_benchmark.v1",
      "reference_case" => "checked-in distributed chunk sweep benchmark artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/distributed_chunk_sweep.json",
        "contract" => "study_benchmark.v1"
      },
      "expected" => %{
        "schema_version" => 1,
        "benchmark_mode_count" => 2,
        "repetition_count" => 3,
        "result_count" => 72,
        "local_result_count" => 36,
        "distributed_result_count" => 36,
        "matches_baseline_count" => 72,
        "failure_count_total" => 0,
        "scenario_count_total" => 792_000,
        "manifest_path" => "studies/leo_dispersion_monte_carlo.json",
        "manifest_sha256_length" => 64,
        "max_duration_ms" => 4_000,
        "monte_carlo_count_option_count" => 2,
        "task_chunk_size_option_count" => 6
      },
      "tolerances" => %{
        "schema_version" => 0,
        "benchmark_mode_count" => 0,
        "repetition_count" => 0,
        "result_count" => 0,
        "local_result_count" => 0,
        "distributed_result_count" => 0,
        "matches_baseline_count" => 0,
        "failure_count_total" => 0,
        "scenario_count_total" => 0,
        "manifest_sha256_length" => 0,
        "max_duration_ms" => 0,
        "monte_carlo_count_option_count" => 0,
        "task_chunk_size_option_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not performance certification",
        "checks distributed chunk sweep rows, option shape, and baseline-match metadata only"
      ]
    },
    "fixture.artifact.study_benchmark.distributed_monte_carlo_scaling" => %{
      "id" => "fixture.artifact.study_benchmark.distributed_monte_carlo_scaling",
      "model_id" => "artifact.study_benchmark.v1",
      "reference_case" => "checked-in distributed Monte Carlo scaling benchmark artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/distributed_monte_carlo_scaling.json",
        "contract" => "study_benchmark.v1"
      },
      "expected" => %{
        "schema_version" => 1,
        "benchmark_mode_count" => 2,
        "repetition_count" => 3,
        "result_count" => 18,
        "local_result_count" => 9,
        "distributed_result_count" => 9,
        "matches_baseline_count" => 18,
        "failure_count_total" => 0,
        "scenario_count_total" => 133_200,
        "trajectory_count_total" => 133_200,
        "manifest_path" => "studies/leo_dispersion_monte_carlo.json",
        "manifest_sha256_length" => 64,
        "max_duration_ms" => 3_289,
        "backend_count" => 0,
        "propagator_option_count" => 0,
        "monte_carlo_count_option_count" => 3,
        "max_concurrency_option_count" => 0,
        "task_chunk_size_option_count" => 0
      },
      "tolerances" => %{
        "schema_version" => 0,
        "benchmark_mode_count" => 0,
        "repetition_count" => 0,
        "result_count" => 0,
        "local_result_count" => 0,
        "distributed_result_count" => 0,
        "matches_baseline_count" => 0,
        "failure_count_total" => 0,
        "scenario_count_total" => 0,
        "trajectory_count_total" => 0,
        "manifest_sha256_length" => 0,
        "max_duration_ms" => 0,
        "backend_count" => 0,
        "propagator_option_count" => 0,
        "monte_carlo_count_option_count" => 0,
        "max_concurrency_option_count" => 0,
        "task_chunk_size_option_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not performance certification",
        "checks distributed/local Monte Carlo benchmark rows, option sweep shape, and baseline-match metadata only"
      ]
    },
    "fixture.artifact.study_benchmark.distributed_diagnostic_sweep" => %{
      "id" => "fixture.artifact.study_benchmark.distributed_diagnostic_sweep",
      "model_id" => "artifact.study_benchmark.v1",
      "reference_case" => "checked-in distributed diagnostic sweep benchmark artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/distributed_diagnostic_sweep.json",
        "contract" => "study_benchmark.v1"
      },
      "expected" => %{
        "schema_version" => 1,
        "benchmark_mode_count" => 2,
        "repetition_count" => 3,
        "result_count" => 36,
        "local_result_count" => 12,
        "distributed_result_count" => 24,
        "matches_baseline_count" => 36,
        "failure_count_total" => 0,
        "scenario_count_total" => 396_000,
        "manifest_path" => "studies/leo_dispersion_monte_carlo.json",
        "manifest_sha256_length" => 64,
        "max_duration_ms" => 2_074,
        "monte_carlo_count_option_count" => 2,
        "max_concurrency_option_count" => 2,
        "task_chunk_size_option_count" => 2
      },
      "tolerances" => %{
        "schema_version" => 0,
        "benchmark_mode_count" => 0,
        "repetition_count" => 0,
        "result_count" => 0,
        "local_result_count" => 0,
        "distributed_result_count" => 0,
        "matches_baseline_count" => 0,
        "failure_count_total" => 0,
        "scenario_count_total" => 0,
        "manifest_sha256_length" => 0,
        "max_duration_ms" => 0,
        "monte_carlo_count_option_count" => 0,
        "max_concurrency_option_count" => 0,
        "task_chunk_size_option_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not performance certification",
        "checks distributed diagnostic sweep rows, option shape, and baseline-match metadata only"
      ]
    },
    "fixture.artifact.study_benchmark.distributed_monte_carlo_chunked" => %{
      "id" => "fixture.artifact.study_benchmark.distributed_monte_carlo_chunked",
      "model_id" => "artifact.study_benchmark.v1",
      "reference_case" => "checked-in distributed Monte Carlo chunked benchmark artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/distributed_monte_carlo_chunked.json",
        "contract" => "study_benchmark.v1"
      },
      "expected" => %{
        "schema_version" => 1,
        "benchmark_mode_count" => 2,
        "repetition_count" => 3,
        "result_count" => 18,
        "local_result_count" => 9,
        "distributed_result_count" => 9,
        "matches_baseline_count" => 18,
        "failure_count_total" => 0,
        "scenario_count_total" => 133_200,
        "manifest_path" => "studies/leo_dispersion_monte_carlo.json",
        "manifest_sha256_length" => 64,
        "max_duration_ms" => 2_241,
        "monte_carlo_count_option_count" => 3
      },
      "tolerances" => %{
        "schema_version" => 0,
        "benchmark_mode_count" => 0,
        "repetition_count" => 0,
        "result_count" => 0,
        "local_result_count" => 0,
        "distributed_result_count" => 0,
        "matches_baseline_count" => 0,
        "failure_count_total" => 0,
        "scenario_count_total" => 0,
        "manifest_sha256_length" => 0,
        "max_duration_ms" => 0,
        "monte_carlo_count_option_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not performance certification",
        "checks distributed Monte Carlo chunked rows, option shape, and baseline-match metadata only"
      ]
    },
    "fixture.artifact.study_benchmark.monte_carlo_scaling" => %{
      "id" => "fixture.artifact.study_benchmark.monte_carlo_scaling",
      "model_id" => "artifact.study_benchmark.v1",
      "reference_case" => "checked-in local Monte Carlo scaling benchmark artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/monte_carlo_scaling.json",
        "contract" => "study_benchmark.v1"
      },
      "expected" => %{
        "schema_version" => 1,
        "benchmark_mode_count" => 1,
        "repetition_count" => 1,
        "result_count" => 2,
        "local_result_count" => 2,
        "distributed_result_count" => 0,
        "matches_baseline_count" => 2,
        "failure_count_total" => 0,
        "scenario_count_total" => 220,
        "manifest_path" => "studies/leo_dispersion_monte_carlo.json",
        "manifest_sha256_length" => 64,
        "max_duration_ms" => 16,
        "monte_carlo_count_option_count" => 2
      },
      "tolerances" => %{
        "schema_version" => 0,
        "benchmark_mode_count" => 0,
        "repetition_count" => 0,
        "result_count" => 0,
        "local_result_count" => 0,
        "distributed_result_count" => 0,
        "matches_baseline_count" => 0,
        "failure_count_total" => 0,
        "scenario_count_total" => 0,
        "manifest_sha256_length" => 0,
        "max_duration_ms" => 0,
        "monte_carlo_count_option_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not performance certification",
        "checks local Monte Carlo scaling rows, option shape, and baseline-match metadata only"
      ]
    },
    "fixture.artifact.study_benchmark.nx_study_benchmark" => %{
      "id" => "fixture.artifact.study_benchmark.nx_study_benchmark",
      "model_id" => "artifact.study_benchmark.v1",
      "reference_case" => "checked-in Nx study benchmark artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/nx_study_benchmark.json",
        "contract" => "study_benchmark.v1"
      },
      "expected" => %{
        "schema_version" => 1,
        "benchmark_mode_count" => 1,
        "repetition_count" => 2,
        "result_count" => 12,
        "local_result_count" => 12,
        "distributed_result_count" => 0,
        "matches_baseline_count" => 12,
        "failure_count_total" => 0,
        "scenario_count_total" => 13_200,
        "trajectory_count_total" => 13_200,
        "manifest_path" => "studies/leo_dispersion_monte_carlo.json",
        "manifest_sha256_length" => 64,
        "max_duration_ms" => 67_760,
        "backend_count" => 3,
        "propagator_option_count" => 3,
        "monte_carlo_count_option_count" => 2,
        "max_concurrency_option_count" => 0,
        "task_chunk_size_option_count" => 0
      },
      "tolerances" => %{
        "schema_version" => 0,
        "benchmark_mode_count" => 0,
        "repetition_count" => 0,
        "result_count" => 0,
        "local_result_count" => 0,
        "distributed_result_count" => 0,
        "matches_baseline_count" => 0,
        "failure_count_total" => 0,
        "scenario_count_total" => 0,
        "trajectory_count_total" => 0,
        "manifest_sha256_length" => 0,
        "max_duration_ms" => 0,
        "backend_count" => 0,
        "propagator_option_count" => 0,
        "monte_carlo_count_option_count" => 0,
        "max_concurrency_option_count" => 0,
        "task_chunk_size_option_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not performance certification",
        "checks Nx benchmark backend coverage, option shape, and baseline-match metadata only"
      ]
    },
    "fixture.artifact.schema_validation_report.v1" => %{
      "id" => "fixture.artifact.schema_validation_report.v1",
      "model_id" => "artifact.schema_validation_report.v1",
      "reference_case" => "checked-in schema validation report artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/schema_validation_report_v1.json",
        "contract" => "schema_validation_report.v1",
        "validated_contract" => "campaign_plan.v1"
      },
      "expected" => %{
        "schema_contract" => "schema_validation_report.v1",
        "model" => "executable_artifact_contract_validation",
        "validation_mode" => "artifact_file",
        "artifact_path" => "study_results/leo_constellation_campaign.json",
        "validated_contract" => "campaign_plan.v1",
        "validated_artifact_family" => "campaign_plan",
        "validated_schema_version" => 1,
        "status" => "pass",
        "error_count" => 0,
        "warning_count" => 0,
        "remediation_count" => 0,
        "error_row_count" => 0,
        "warning_row_count" => 0,
        "remediation_row_count" => 0,
        "model_limit_count" => 3
      },
      "tolerances" => %{
        "validated_schema_version" => 0,
        "error_count" => 0,
        "warning_count" => 0,
        "remediation_count" => 0,
        "error_row_count" => 0,
        "warning_row_count" => 0,
        "remediation_row_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external schema validator certification",
        "checks executable schema-validation report counts and model-limit boundary only"
      ]
    },
    "fixture.artifact.schema_validation_batch_report.v1" => %{
      "id" => "fixture.artifact.schema_validation_batch_report.v1",
      "model_id" => "artifact.schema_validation_batch_report.v1",
      "reference_case" => "checked-in schema validation batch report artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/schema_validation_batch_report_v1.json",
        "contract" => "schema_validation_batch_report.v1",
        "input_dir" => "study_results"
      },
      "expected" => %{
        "schema_contract" => "schema_validation_batch_report.v1",
        "model" => "executable_artifact_contract_batch_validation",
        "validation_mode" => "artifact_directory",
        "input_dir" => "study_results",
        "status" => "pass",
        "status_counts" => %{"pass" => 155},
        "file_count" => 155,
        "artifact_count" => 155,
        "skipped_count" => 0,
        "error_count" => 0,
        "warning_count" => 0,
        "remediation_count" => 0,
        "report_count" => 155,
        "pass_report_count" => 155,
        "fail_report_count" => 0,
        "skipped_artifact_count" => 0,
        "model_limit_count" => 3
      },
      "tolerances" => %{
        "file_count" => 0,
        "artifact_count" => 0,
        "skipped_count" => 0,
        "error_count" => 0,
        "warning_count" => 0,
        "remediation_count" => 0,
        "report_count" => 0,
        "pass_report_count" => 0,
        "fail_report_count" => 0,
        "skipped_artifact_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not an external compatibility suite",
        "checks batch validation counts, status count maps, and model-limit boundary only"
      ]
    },
    "fixture.artifact.schema_migration_report.deprecated_campaign_plan" => %{
      "id" => "fixture.artifact.schema_migration_report.deprecated_campaign_plan",
      "model_id" => "artifact.schema_migration_report.v1",
      "reference_case" =>
        "checked-in schema migration report with campaign-plan deprecation hint",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/schema_migration_report_v1.json",
        "contract" => "schema_migration_report.v1"
      },
      "expected" => %{
        "schema_contract" => "schema_migration_report.v1",
        "schema_version" => 1,
        "model" => "executable_schema_migration_and_deprecation_report",
        "source" => "orbital_dynamics.schema_registry",
        "status" => "review_required",
        "compatibility_policy_version" => 1,
        "compatible_change_rule_count" => 3,
        "breaking_change_rule_count" => 5,
        "contract_count" => 121,
        "current_contract_count" => 120,
        "deprecated_contract_count" => 1,
        "future_contract_count" => 0,
        "migration_row_count" => 121,
        "deprecation_warning_count" => 1,
        "row_derived_contract_count" => 121,
        "status_counts" => %{"current" => 120, "deprecated" => 1},
        "row_derived_status_counts" => %{"current" => 120, "deprecated" => 1},
        "migration_action_counts" => %{
          "continue_current_contract" => 120,
          "plan_replacement" => 1
        },
        "row_derived_migration_action_counts" => %{
          "continue_current_contract" => 120,
          "plan_replacement" => 1
        },
        "deprecated_contracts" => "campaign_plan.v1",
        "replacement_contracts" => "campaign_strategy.v3",
        "execution_boundary" => "artifact_only_no_schema_rewrite",
        "migration_authority" => "not_granted_by_report",
        "model_limit_count" => 4
      },
      "tolerances" => %{
        "schema_version" => 0,
        "compatibility_policy_version" => 0,
        "compatible_change_rule_count" => 0,
        "breaking_change_rule_count" => 0,
        "contract_count" => 0,
        "current_contract_count" => 0,
        "deprecated_contract_count" => 0,
        "future_contract_count" => 0,
        "migration_row_count" => 0,
        "deprecation_warning_count" => 0,
        "row_derived_contract_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not automatic schema migration",
        "checks schema registry/deprecation rollups and report-only migration boundary"
      ]
    },
    "fixture.artifact.schema_migration_report.future_campaign_plan" => %{
      "id" => "fixture.artifact.schema_migration_report.future_campaign_plan",
      "model_id" => "artifact.schema_migration_report.v1",
      "reference_case" => "generated schema migration report with campaign-plan future hint",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "source" => "generated_schema_migration_future_contract_fixture",
        "contract" => "schema_migration_report.v1"
      },
      "expected" => %{
        "schema_contract" => "schema_migration_report.v1",
        "schema_version" => 1,
        "model" => "executable_schema_migration_and_deprecation_report",
        "source" => "orbital_dynamics.schema_registry",
        "status" => "review_required",
        "compatibility_policy_version" => 1,
        "compatible_change_rule_count" => 3,
        "breaking_change_rule_count" => 5,
        "contract_count" => 122,
        "current_contract_count" => 121,
        "deprecated_contract_count" => 0,
        "future_contract_count" => 1,
        "migration_row_count" => 122,
        "deprecation_warning_count" => 0,
        "row_derived_contract_count" => 122,
        "status_counts" => %{"current" => 121, "future" => 1},
        "row_derived_status_counts" => %{"current" => 121, "future" => 1},
        "migration_action_counts" => %{
          "continue_current_contract" => 121,
          "prepare_future_contract" => 1
        },
        "row_derived_migration_action_counts" => %{
          "continue_current_contract" => 121,
          "prepare_future_contract" => 1
        },
        "deprecated_contracts" => "",
        "replacement_contracts" => "",
        "execution_boundary" => "artifact_only_no_schema_rewrite",
        "migration_authority" => "not_granted_by_report",
        "model_limit_count" => 4
      },
      "tolerances" => %{
        "schema_version" => 0,
        "compatibility_policy_version" => 0,
        "compatible_change_rule_count" => 0,
        "breaking_change_rule_count" => 0,
        "contract_count" => 0,
        "current_contract_count" => 0,
        "deprecated_contract_count" => 0,
        "future_contract_count" => 0,
        "migration_row_count" => 0,
        "deprecation_warning_count" => 0,
        "row_derived_contract_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal generated artifact regression, not automatic schema migration",
        "checks future-contract rollups and report-only migration boundary"
      ]
    },
    "fixture.artifact.cadence_import_manifest.resource_pressure_v1" => %{
      "id" => "fixture.artifact.cadence_import_manifest.resource_pressure_v1",
      "model_id" => "artifact.cadence_import_manifest.v1",
      "reference_case" => "checked-in resource-pressure Cadence import manifest artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/cadence_import_resource_pressure_v1.json",
        "contract" => "cadence_import_manifest.v1"
      },
      "expected" => %{
        "schema_contract" => "cadence_import_manifest.v1",
        "model" => "artifact_only_cadence_import_manifest",
        "manifest_id" =>
          "cadence_import_manifest:operational_readiness:resource_projection_report.v1:resource_summaries",
        "source_artifact_type" => "operational_readiness_report.v1",
        "source_artifact_id" =>
          "operational_readiness:resource_projection_report.v1:resource_summaries",
        "row_count" => 4,
        "ready_count" => 0,
        "row_derived_ready_count" => 0,
        "blocked_count" => 0,
        "row_derived_blocked_count" => 0,
        "review_required_count" => 4,
        "missing_import_count" => 0,
        "row_derived_missing_import_count" => 0,
        "source_review_count" => 4,
        "import_status_counts" => %{"review_required_before_import" => 4},
        "row_derived_import_status_counts" => %{"review_required_before_import" => 4},
        "import_action_counts" => %{"review_operational_readiness" => 4},
        "row_derived_import_action_counts" => %{"review_operational_readiness" => 4},
        "cadence_import_status_counts" => %{"present" => 4},
        "row_derived_cadence_import_status_counts" => %{"present" => 4},
        "required_operator_action_counts" => %{"review_operational_readiness" => 4},
        "row_derived_required_operator_action_counts" => %{
          "review_operational_readiness" => 4
        },
        "source_review_type_counts" => %{"operational_readiness_review" => 4},
        "row_derived_source_review_type_counts" => %{
          "operational_readiness_review" => 4
        },
        "import_side_counts" => %{"source" => 4},
        "row_derived_import_side_counts" => %{"source" => 4},
        "source_review_queue_counts" => %{
          "operational_readiness_review|review_operational_readiness|operator_review_required" =>
            4
        },
        "row_derived_source_review_queue_counts" => %{
          "operational_readiness_review|review_operational_readiness|operator_review_required" =>
            4
        },
        "resource_availability_import_row_count" => 2,
        "row_derived_resource_availability_pressure_count" => 4,
        "row_derived_resource_availability_reason_counts" => %{
          "antenna_unavailable" => 2,
          "payload_unavailable" => 2
        },
        "row_derived_resource_availability_reason_keys" =>
          "antenna_unavailable|payload_unavailable",
        "row_derived_unavailable_resource_reason_keys" =>
          "antenna_unavailable|payload_unavailable",
        "execution_boundary" => "artifact_only_no_cadence_api_writes",
        "authorization_boundary" => "operator_review_or_cadence_adapter_must_authorize_import",
        "model_limit_count" => 4
      },
      "tolerances" => %{
        "row_count" => 0,
        "ready_count" => 0,
        "row_derived_ready_count" => 0,
        "blocked_count" => 0,
        "row_derived_blocked_count" => 0,
        "review_required_count" => 0,
        "missing_import_count" => 0,
        "row_derived_missing_import_count" => 0,
        "source_review_count" => 0,
        "resource_availability_import_row_count" => 0,
        "row_derived_resource_availability_pressure_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external Cadence API validation",
        "checks resource-pressure import routing and no-write authorization boundary only"
      ]
    },
    "fixture.artifact.operational_readiness_report.resource_pressure_v1" => %{
      "id" => "fixture.artifact.operational_readiness_report.resource_pressure_v1",
      "model_id" => "artifact.operational_readiness_report.v1",
      "reference_case" => "checked-in resource-pressure operational readiness artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/operational_readiness_resource_pressure_v1.json",
        "contract" => "operational_readiness_report.v1"
      },
      "expected" => %{
        "schema_contract" => "operational_readiness_report.v1",
        "model" => "artifact_only_operational_readiness_classifier",
        "report_id" => "operational_readiness:resource_projection_report.v1:resource_summaries",
        "source_artifact_type" => "resource_projection_report.v1",
        "source_artifact_id" => "resource_summaries",
        "readiness_level" => "operator_review",
        "import_classification" => "review_only",
        "status" => "review_required",
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
        "row_derived_gate_status_counts" => %{
          "passed" => 3,
          "review_required" => 3
        },
        "row_derived_gate_classification_counts" => %{
          "importable" => 3,
          "review_only" => 3
        },
        "review_row_count" => 1,
        "import_row_count" => 1,
        "ready_for_import_count" => 0,
        "row_derived_ready_for_import_count" => 0,
        "manifest_review_required_count" => 1,
        "row_derived_manifest_review_required_count" => 0,
        "blocked_import_count" => 0,
        "row_derived_blocked_import_count" => 0,
        "missing_import_count" => 0,
        "row_derived_missing_import_count" => 0,
        "invalid_cadence_import_count" => 0,
        "row_derived_invalid_cadence_import_count" => 0,
        "import_status_counts" => %{"review_required_before_import" => 1},
        "row_derived_import_status_counts" => %{},
        "cadence_import_status_counts" => %{"present" => 1},
        "row_derived_cadence_import_status_counts" => %{},
        "resource_availability_pressure_count" => 2,
        "row_derived_resource_availability_pressure_count" => 2,
        "resource_availability_reason_counts" => %{
          "antenna_unavailable" => 1,
          "payload_unavailable" => 1
        },
        "row_derived_resource_availability_reason_counts" => %{
          "antenna_unavailable" => 1,
          "payload_unavailable" => 1
        },
        "resource_availability_reason_keys" => "antenna_unavailable|payload_unavailable",
        "row_derived_resource_availability_reason_keys" =>
          "antenna_unavailable|payload_unavailable",
        "unavailable_resource_reason_keys" => "antenna_unavailable|payload_unavailable",
        "row_derived_unavailable_resource_reason_keys" =>
          "antenna_unavailable|payload_unavailable",
        "source_model_count" => 1,
        "source_model_limit_count" => 9,
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
        "resource_availability_pressure_count" => 0,
        "row_derived_resource_availability_pressure_count" => 0,
        "source_model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external operations validation",
        "checks resource-pressure readiness classification and no-execution boundary only"
      ]
    },
    "fixture.artifact.operator_review_package.resource_pressure_v1" => %{
      "id" => "fixture.artifact.operator_review_package.resource_pressure_v1",
      "model_id" => "artifact.operator_review_package.v1",
      "reference_case" => "checked-in resource-pressure operator review artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/operator_review_resource_pressure_v1.json",
        "contract" => "operator_review_package.v1"
      },
      "expected" => %{
        "schema_contract" => "operator_review_package.v1",
        "model" => "artifact_only_operator_review_package",
        "review_count" => 4,
        "row_derived_review_count" => 4,
        "approval_requirement_count" => 0,
        "policy_escalation_count" => 0,
        "realized_feedback_count" => 0,
        "resource_projection_review_count" => 0,
        "resource_suppression_count" => 0,
        "contact_suppression_count" => 0,
        "link_capacity_review_count" => 0,
        "timeline_diff_count" => 0,
        "row_derived_review_type_counts" => %{"operational_readiness_review" => 4},
        "row_derived_required_operator_action_counts" => %{
          "review_operational_readiness" => 4
        },
        "row_derived_review_queue_counts" => %{
          "operational_readiness_review|review_operational_readiness|operator_review_required" =>
            4
        },
        "resource_availability_review_row_count" => 2,
        "row_derived_resource_availability_pressure_count" => 4,
        "row_derived_resource_availability_reason_counts" => %{
          "antenna_unavailable" => 2,
          "payload_unavailable" => 2
        },
        "row_derived_resource_availability_reason_keys" =>
          "antenna_unavailable|payload_unavailable",
        "row_derived_unavailable_resource_reason_keys" =>
          "antenna_unavailable|payload_unavailable"
      },
      "tolerances" => %{
        "review_count" => 0,
        "row_derived_review_count" => 0,
        "resource_availability_review_row_count" => 0,
        "row_derived_resource_availability_pressure_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external operator workflow validation",
        "checks resource-pressure review routing and artifact-only review boundary only"
      ]
    },
    "fixture.artifact.quality_gate_report.resource_pressure_v1" => %{
      "id" => "fixture.artifact.quality_gate_report.resource_pressure_v1",
      "model_id" => "artifact.quality_gate_report.v1",
      "reference_case" => "checked-in resource-pressure quality gate artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/quality_gate_resource_pressure_v1.json",
        "contract" => "quality_gate_report.v1"
      },
      "expected" => %{
        "schema_contract" => "quality_gate_report.v1",
        "model" => "artifact_only_operational_quality_gate_report",
        "report_id" => "quality_gate:resource_projection_report.v1:resource_summaries",
        "source_artifact_type" => "resource_projection_report.v1",
        "source_artifact_id" => "resource_summaries",
        "source_readiness_report_id" =>
          "operational_readiness:resource_projection_report.v1:resource_summaries",
        "readiness_level" => "operator_review",
        "import_classification" => "review_only",
        "status" => "review_required",
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
        "row_count" => 6,
        "gate_status_counts" => %{"passed" => 3, "review_required" => 3},
        "row_derived_gate_status_counts" => %{"passed" => 3, "review_required" => 3},
        "gate_classification_counts" => %{"importable" => 3, "review_only" => 3},
        "row_derived_gate_classification_counts" => %{
          "importable" => 3,
          "review_only" => 3
        },
        "resource_availability_gate_count" => 1,
        "row_derived_resource_availability_pressure_count" => 2,
        "row_derived_resource_availability_reason_counts" => %{
          "antenna_unavailable" => 1,
          "payload_unavailable" => 1
        },
        "row_derived_resource_availability_reason_keys" =>
          "antenna_unavailable|payload_unavailable",
        "row_derived_unavailable_resource_reason_keys" =>
          "antenna_unavailable|payload_unavailable",
        "row_derived_ready_for_import_count" => 0,
        "row_derived_manifest_review_required_count" => 0,
        "row_derived_blocked_import_count" => 0,
        "row_derived_missing_import_count" => 0,
        "row_derived_invalid_cadence_import_count" => 0,
        "row_derived_import_status_counts" => %{},
        "row_derived_cadence_import_status_counts" => %{},
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
        "resource_availability_gate_count" => 0,
        "row_derived_resource_availability_pressure_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external operations validation",
        "checks resource-pressure gate routing and no-authority boundary only"
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
    "fixture.artifact.operator_review_package.resource_projection_battery_handoff_v1" => %{
      "id" => "fixture.artifact.operator_review_package.resource_projection_battery_handoff_v1",
      "model_id" => "artifact.operator_review_package.v1",
      "reference_case" =>
        "checked-in operator-review resource-projection battery handoff artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" =>
          "study_results/operator_review_resource_projection_battery_handoff_v1.json",
        "contract" => "operator_review_package.v1",
        "source_contract" => "resource_projection_report.v1"
      },
      "expected" => %{
        "schema_contract" => "operator_review_package.v1",
        "model" => "artifact_only_operator_review_package",
        "review_count" => 1,
        "resource_projection_review_count" => 1,
        "resource_projection_battery_handoff_count" => 1,
        "total_resource_projection_battery_energy_consumed_wh" => 23.0,
        "total_resource_projection_battery_energy_generated_wh" => 8.0,
        "net_resource_projection_battery_energy_delta_wh" => 15.0,
        "peak_resource_projection_battery_overuse_wh" => 4.0
      },
      "tolerances" => %{
        "review_count" => 0,
        "resource_projection_review_count" => 0,
        "resource_projection_battery_handoff_count" => 0,
        "total_resource_projection_battery_energy_consumed_wh" => 0.0,
        "total_resource_projection_battery_energy_generated_wh" => 0.0,
        "net_resource_projection_battery_energy_delta_wh" => 0.0,
        "peak_resource_projection_battery_overuse_wh" => 0.0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external operations validation",
        "checks resource-projection battery handoff row aggregation only"
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
                |> Map.merge(ContactIntentArtifacts.all())
                |> Map.merge(ContactWindowArtifacts.all())
                |> Map.merge(CoreRunReports.all())
                |> Map.merge(EnvironmentCapabilities.all())
                |> Map.merge(LinkCapacityArtifacts.all())
                |> Map.merge(ManifestArtifacts.all())
                |> Map.merge(OperationalPlanningArtifacts.all())
                |> Map.merge(PolicyBundleArtifacts.all())
                |> Map.merge(PolicyDecisions.all())
                |> Map.merge(PolicyEvidenceArtifacts.all())
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
