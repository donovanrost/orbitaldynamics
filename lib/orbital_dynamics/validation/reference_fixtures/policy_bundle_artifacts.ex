defmodule OrbitalDynamics.Validation.ReferenceFixtures.PolicyBundleArtifacts do
  @moduledoc false

  @fixtures %{
    "fixture.artifact.policy_bundle.v1" => %{
      "id" => "fixture.artifact.policy_bundle.v1",
      "model_id" => "artifact.policy_bundle.v1",
      "reference_case" => "checked-in mission operations policy bundle artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/policy_bundle_v1.json",
        "contract" => "policy_bundle.v1"
      },
      "expected" => %{
        "schema_contract" => "policy_bundle.v1",
        "id" => "mission_ops_escalation_v1",
        "action_rule_count" => 6,
        "blocked_risk_type_count" => 2,
        "auto_approvable_approval_count_limit" => 0,
        "auto_approvable_risk_limit" => 0,
        "operator_review_risk_limit" => 2,
        "classification_counts" => %{
          "blocked_by_policy" => 1,
          "operator_review_required" => 5
        },
        "required_authority_counts" => %{
          "command_authority" => 1,
          "contact_schedule_authority" => 3,
          "flight_director" => 1,
          "mission_planning_authority" => 1
        },
        "boundary" => "artifact_only_no_authority_lookup",
        "workflow_execution" => "none",
        "provenance_source" => "OrbitalDynamics.Policy.bundle!",
        "no_command_execution" => true,
        "no_schedule_mutation" => true,
        "model_limit_count" => 5
      },
      "tolerances" => %{
        "action_rule_count" => 0,
        "blocked_risk_type_count" => 0,
        "auto_approvable_approval_count_limit" => 0,
        "auto_approvable_risk_limit" => 0,
        "operator_review_risk_limit" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external policy validation",
        "checks representative policy bundle rule counts, authority routing maps, artifact-only boundary, and model-limit evidence only"
      ]
    },
    "fixture.artifact.policy_bundle.ground_network_allocation" => %{
      "id" => "fixture.artifact.policy_bundle.ground_network_allocation",
      "model_id" => "artifact.policy_bundle.v1",
      "reference_case" => "checked-in ground-network allocation policy bundle artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/policy_bundle_ground_network_allocation_v1.json",
        "contract" => "policy_bundle.v1"
      },
      "expected" => %{
        "schema_contract" => "policy_bundle.v1",
        "id" => "ground_network_allocation_v1",
        "action_rule_count" => 14,
        "blocked_risk_type_count" => 2,
        "auto_approvable_approval_count_limit" => 0,
        "auto_approvable_risk_limit" => 0,
        "operator_review_risk_limit" => 2,
        "classification_counts" => %{
          "blocked_by_policy" => 3,
          "operator_review_required" => 11
        },
        "required_authority_counts" => %{"contact_schedule_authority" => 14},
        "escalation_queue_counts" => %{
          "ground_network" => 13,
          "ground_network_priority" => 1
        },
        "station_availability_rule_count" => 3,
        "reduced_capacity_rule_count" => 2,
        "unavailable_or_maintenance_rule_count" => 1,
        "contention_rule_count" => 5,
        "contact_allocation_rule_count" => 1,
        "required_operator_action_rule_count" => 2,
        "command_direction_rule_count" => 1,
        "missing_trust_rule_count" => 1,
        "rule_ids_by_classification" => %{
          "blocked_by_policy" => [
            "duplicate_contact_identity_block",
            "reduced_station_capacity_insufficient_block",
            "unavailable_station_contact_block"
          ],
          "operator_review_required" => [
            "command_station_calendar_direction_review",
            "declared_provider_calendar_contention_review",
            "high_overlap_contact_contention_review",
            "invalid_contact_contention_input_review",
            "invalid_link_capacity_input_review",
            "low_actual_downlink_completion_review",
            "missing_priority_field_evidence_review",
            "missing_station_calendar_trust_review",
            "reserved_station_contact_review",
            "same_station_contact_contention_review",
            "severe_capacity_reduction_review"
          ]
        },
        "boundary" => "artifact_only_no_authority_lookup",
        "workflow_execution" => "none",
        "provenance_source" => "OrbitalDynamics.Policy.bundle!",
        "no_command_execution" => true,
        "no_schedule_mutation" => true,
        "model_limit_count" => 5
      },
      "tolerances" => %{
        "action_rule_count" => 0,
        "blocked_risk_type_count" => 0,
        "auto_approvable_approval_count_limit" => 0,
        "auto_approvable_risk_limit" => 0,
        "operator_review_risk_limit" => 0,
        "station_availability_rule_count" => 0,
        "reduced_capacity_rule_count" => 0,
        "unavailable_or_maintenance_rule_count" => 0,
        "contention_rule_count" => 0,
        "contact_allocation_rule_count" => 0,
        "required_operator_action_rule_count" => 0,
        "command_direction_rule_count" => 0,
        "missing_trust_rule_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external policy validation",
        "checks ground-network allocation policy rule counts, authority routing, calendar-review triggers, and artifact-only boundary only"
      ]
    },
    "fixture.artifact.policy_bundle.operator_review_queue_authority" => %{
      "id" => "fixture.artifact.policy_bundle.operator_review_queue_authority",
      "model_id" => "artifact.policy_bundle.v1",
      "reference_case" => "checked-in operator-review queue authority policy bundle artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/policy_bundle_operator_review_queue_authority_v1.json",
        "contract" => "policy_bundle.v1"
      },
      "expected" => %{
        "schema_contract" => "policy_bundle.v1",
        "id" => "operator_review_queue_authority_v1",
        "action_rule_count" => 5,
        "blocked_risk_type_count" => 2,
        "auto_approvable_approval_count_limit" => 0,
        "auto_approvable_risk_limit" => 0,
        "operator_review_risk_limit" => 2,
        "classification_counts" => %{"operator_review_required" => 5},
        "required_authority_counts" => %{
          "contact_schedule_authority" => 1,
          "maneuver_authority" => 1,
          "mission_operations_authority" => 1,
          "resource_model_authority" => 1,
          "timeline_protection_authority" => 1
        },
        "escalation_queue_counts" => %{
          "flight_dynamics" => 1,
          "ground_network" => 1,
          "mission_operations" => 1,
          "mission_planning" => 2
        },
        "rule_ids_by_classification" => %{
          "operator_review_required" => [
            "ground_network_review_queue_authority",
            "maneuver_review_queue_authority",
            "policy_escalation_review_queue_authority",
            "resource_review_queue_authority",
            "timeline_review_queue_authority"
          ]
        },
        "required_operator_action_rule_count" => 0,
        "boundary" => "artifact_only_no_authority_lookup",
        "workflow_execution" => "none",
        "provenance_source" => "OrbitalDynamics.Policy.bundle!",
        "no_command_execution" => true,
        "no_schedule_mutation" => true,
        "model_limit_count" => 5
      },
      "tolerances" => %{
        "action_rule_count" => 0,
        "blocked_risk_type_count" => 0,
        "auto_approvable_approval_count_limit" => 0,
        "auto_approvable_risk_limit" => 0,
        "operator_review_risk_limit" => 0,
        "required_operator_action_rule_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external policy validation",
        "checks operator-review queue authority routing, queue counts, rule IDs, and artifact-only boundary only"
      ]
    },
    "fixture.artifact.policy_bundle.command_contact_authority" => %{
      "id" => "fixture.artifact.policy_bundle.command_contact_authority",
      "model_id" => "artifact.policy_bundle.v1",
      "reference_case" => "checked-in command/contact authority policy bundle artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/policy_bundle_command_contact_authority_v1.json",
        "contract" => "policy_bundle.v1"
      },
      "expected" => %{
        "schema_contract" => "policy_bundle.v1",
        "id" => "command_contact_authority_v1",
        "action_rule_count" => 14,
        "blocked_risk_type_count" => 2,
        "auto_approvable_approval_count_limit" => 0,
        "auto_approvable_risk_limit" => 0,
        "operator_review_risk_limit" => 2,
        "classification_counts" => %{
          "blocked_by_policy" => 1,
          "operator_review_required" => 13
        },
        "required_authority_counts" => %{
          "cadence_import_boundary_authority" => 1,
          "command_authority" => 5,
          "contact_schedule_authority" => 6,
          "mission_planning_authority" => 1,
          "tracking_coordination_authority" => 1
        },
        "escalation_queue_counts" => %{
          "ground_network" => 6,
          "mission_operations" => 5,
          "mission_planning" => 2,
          "tracking_operations" => 1
        },
        "station_availability_rule_count" => 2,
        "required_operator_action_rule_count" => 2,
        "rule_ids_by_classification" => %{
          "blocked_by_policy" => ["command_window_station_calendar_block"],
          "operator_review_required" => [
            "command_result_failure_review",
            "command_uplink_authority_review",
            "command_window_station_calendar_review",
            "contact_result_failure_review",
            "downlink_schedule_authority_review",
            "failed_command_success_review",
            "failed_contact_success_review",
            "health_command_authority_review",
            "invalid_command_window_input_review",
            "low_command_success_confidence_review",
            "low_contact_success_confidence_review",
            "missing_cadence_import_review",
            "tracking_coordination_review"
          ]
        },
        "boundary" => "artifact_only_no_authority_lookup",
        "workflow_execution" => "none",
        "provenance_source" => "OrbitalDynamics.Policy.bundle!",
        "no_command_execution" => true,
        "no_schedule_mutation" => true,
        "model_limit_count" => 5
      },
      "tolerances" => %{
        "action_rule_count" => 0,
        "blocked_risk_type_count" => 0,
        "auto_approvable_approval_count_limit" => 0,
        "auto_approvable_risk_limit" => 0,
        "operator_review_risk_limit" => 0,
        "station_availability_rule_count" => 0,
        "required_operator_action_rule_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external policy validation",
        "checks command/contact authority routing, queue counts, rule IDs, and artifact-only boundary only"
      ]
    },
    "fixture.artifact.policy_bundle.conservative_ops" => %{
      "id" => "fixture.artifact.policy_bundle.conservative_ops",
      "model_id" => "artifact.policy_bundle.v1",
      "reference_case" => "checked-in conservative operations policy bundle artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/policy_bundle_conservative_ops_v1.json",
        "contract" => "policy_bundle.v1"
      },
      "expected" => %{
        "schema_contract" => "policy_bundle.v1",
        "id" => "conservative_ops_v1",
        "action_rule_count" => 2,
        "blocked_risk_type_count" => 8,
        "auto_approvable_approval_count_limit" => 0,
        "auto_approvable_risk_limit" => 0,
        "operator_review_risk_limit" => 0,
        "classification_counts" => %{"blocked_by_policy" => 1, "operator_review_required" => 1},
        "required_authority_counts" => %{"unknown" => 2},
        "escalation_queue_counts" => %{"unknown" => 2},
        "rule_ids_by_classification" => %{
          "blocked_by_policy" => ["resource_pressure_block"],
          "operator_review_required" => ["all_requirements_review"]
        },
        "boundary" => "artifact_only_no_authority_lookup",
        "workflow_execution" => "none",
        "provenance_source" => "OrbitalDynamics.Policy.bundle!",
        "no_command_execution" => true,
        "no_schedule_mutation" => true,
        "model_limit_count" => 5
      },
      "tolerances" => %{
        "action_rule_count" => 0,
        "blocked_risk_type_count" => 0,
        "auto_approvable_approval_count_limit" => 0,
        "auto_approvable_risk_limit" => 0,
        "operator_review_risk_limit" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external policy validation",
        "checks conservative policy blocking/review rules, risk limits, and artifact-only boundary only"
      ]
    },
    "fixture.artifact.policy_bundle.contact_command_review" => %{
      "id" => "fixture.artifact.policy_bundle.contact_command_review",
      "model_id" => "artifact.policy_bundle.v1",
      "reference_case" => "checked-in contact/command review policy bundle artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/policy_bundle_contact_command_review_v1.json",
        "contract" => "policy_bundle.v1"
      },
      "expected" => %{
        "schema_contract" => "policy_bundle.v1",
        "id" => "contact_command_review_v1",
        "action_rule_count" => 3,
        "blocked_risk_type_count" => 2,
        "auto_approvable_approval_count_limit" => 0,
        "auto_approvable_risk_limit" => 0,
        "operator_review_risk_limit" => 2,
        "classification_counts" => %{"operator_review_required" => 3},
        "required_authority_counts" => %{"unknown" => 3},
        "escalation_queue_counts" => %{"unknown" => 3},
        "rule_ids_by_classification" => %{
          "operator_review_required" => [
            "command_health_review",
            "contact_schedule_review",
            "invalid_contact_intent_input_review"
          ]
        },
        "boundary" => "artifact_only_no_authority_lookup",
        "workflow_execution" => "none",
        "provenance_source" => "OrbitalDynamics.Policy.bundle!",
        "no_command_execution" => true,
        "no_schedule_mutation" => true,
        "model_limit_count" => 5
      },
      "tolerances" => %{
        "action_rule_count" => 0,
        "blocked_risk_type_count" => 0,
        "auto_approvable_approval_count_limit" => 0,
        "auto_approvable_risk_limit" => 0,
        "operator_review_risk_limit" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external policy validation",
        "checks contact/command review rule IDs, review-only classification, and artifact-only boundary only"
      ]
    },
    "fixture.artifact.policy_bundle.degraded_payload_guard" => %{
      "id" => "fixture.artifact.policy_bundle.degraded_payload_guard",
      "model_id" => "artifact.policy_bundle.v1",
      "reference_case" => "checked-in degraded payload guard policy bundle artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/policy_bundle_degraded_payload_guard_v1.json",
        "contract" => "policy_bundle.v1"
      },
      "expected" => %{
        "schema_contract" => "policy_bundle.v1",
        "id" => "degraded_payload_guard_v1",
        "action_rule_count" => 6,
        "blocked_risk_type_count" => 2,
        "auto_approvable_approval_count_limit" => 2,
        "auto_approvable_risk_limit" => 1,
        "operator_review_risk_limit" => 3,
        "classification_counts" => %{
          "auto_approvable" => 1,
          "blocked_by_policy" => 3,
          "operator_review_required" => 2
        },
        "required_authority_counts" => %{"resource_model_authority" => 2, "unknown" => 4},
        "escalation_queue_counts" => %{"resource_planning" => 2, "unknown" => 4},
        "rule_ids_by_classification" => %{
          "auto_approvable" => ["degraded_command_health_exemption"],
          "blocked_by_policy" => [
            "antenna_unavailable_contact_block",
            "degraded_payload_observation_block",
            "payload_unavailable_observation_block"
          ],
          "operator_review_required" => [
            "invalid_resource_filter_candidate_input_review",
            "invalid_resource_filter_summary_input_review"
          ]
        },
        "boundary" => "artifact_only_no_authority_lookup",
        "workflow_execution" => "none",
        "provenance_source" => "OrbitalDynamics.Policy.bundle!",
        "no_command_execution" => true,
        "no_schedule_mutation" => true,
        "model_limit_count" => 5
      },
      "tolerances" => %{
        "action_rule_count" => 0,
        "blocked_risk_type_count" => 0,
        "auto_approvable_approval_count_limit" => 0,
        "auto_approvable_risk_limit" => 0,
        "operator_review_risk_limit" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external policy validation",
        "checks degraded payload guard block/review/exemption routing and artifact-only boundary only"
      ]
    },
    "fixture.artifact.policy_bundle.default" => %{
      "id" => "fixture.artifact.policy_bundle.default",
      "model_id" => "artifact.policy_bundle.v1",
      "reference_case" => "checked-in default fallback policy bundle artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/policy_bundle_default_v1.json",
        "contract" => "policy_bundle.v1"
      },
      "expected" => %{
        "schema_contract" => "policy_bundle.v1",
        "id" => "default_v1",
        "action_rule_count" => 0,
        "blocked_risk_type_count" => 2,
        "auto_approvable_approval_count_limit" => 0,
        "auto_approvable_risk_limit" => 0,
        "operator_review_risk_limit" => 3,
        "classification_counts" => %{},
        "required_authority_counts" => %{},
        "escalation_queue_counts" => %{},
        "rule_ids_by_classification" => %{},
        "boundary" => "artifact_only_no_authority_lookup",
        "workflow_execution" => "none",
        "provenance_source" => "OrbitalDynamics.Policy.bundle!",
        "no_command_execution" => true,
        "no_schedule_mutation" => true,
        "model_limit_count" => 5
      },
      "tolerances" => %{
        "action_rule_count" => 0,
        "blocked_risk_type_count" => 0,
        "auto_approvable_approval_count_limit" => 0,
        "auto_approvable_risk_limit" => 0,
        "operator_review_risk_limit" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external policy validation",
        "checks default fallback limits and artifact-only boundary only"
      ]
    },
    "fixture.artifact.policy_bundle.maneuver_authority" => %{
      "id" => "fixture.artifact.policy_bundle.maneuver_authority",
      "model_id" => "artifact.policy_bundle.v1",
      "reference_case" => "checked-in maneuver authority policy bundle artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/policy_bundle_maneuver_authority_v1.json",
        "contract" => "policy_bundle.v1"
      },
      "expected" => %{
        "schema_contract" => "policy_bundle.v1",
        "id" => "maneuver_authority_v1",
        "action_rule_count" => 4,
        "blocked_risk_type_count" => 2,
        "auto_approvable_approval_count_limit" => 0,
        "auto_approvable_risk_limit" => 0,
        "operator_review_risk_limit" => 2,
        "classification_counts" => %{"operator_review_required" => 4},
        "required_authority_counts" => %{"maneuver_authority" => 4},
        "escalation_queue_counts" => %{"flight_dynamics" => 4},
        "required_operator_action_rule_count" => 0,
        "rule_ids_by_classification" => %{
          "operator_review_required" => [
            "impulsive_burn_authority_review",
            "invalid_maneuver_recommendation_review",
            "maneuver_result_failure_review",
            "maneuver_timing_authority_review"
          ]
        },
        "boundary" => "artifact_only_no_authority_lookup",
        "workflow_execution" => "none",
        "provenance_source" => "OrbitalDynamics.Policy.bundle!",
        "no_command_execution" => true,
        "no_schedule_mutation" => true,
        "model_limit_count" => 5
      },
      "tolerances" => %{
        "action_rule_count" => 0,
        "blocked_risk_type_count" => 0,
        "auto_approvable_approval_count_limit" => 0,
        "auto_approvable_risk_limit" => 0,
        "operator_review_risk_limit" => 0,
        "required_operator_action_rule_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external policy validation",
        "checks maneuver authority routing, queue counts, rule IDs, and artifact-only boundary only"
      ]
    },
    "fixture.artifact.policy_bundle.resource_projection_authority" => %{
      "id" => "fixture.artifact.policy_bundle.resource_projection_authority",
      "model_id" => "artifact.policy_bundle.v1",
      "reference_case" => "checked-in resource projection authority policy bundle artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/policy_bundle_resource_projection_authority_v1.json",
        "contract" => "policy_bundle.v1"
      },
      "expected" => %{
        "schema_contract" => "policy_bundle.v1",
        "id" => "resource_projection_authority_v1",
        "action_rule_count" => 7,
        "blocked_risk_type_count" => 2,
        "auto_approvable_approval_count_limit" => 0,
        "auto_approvable_risk_limit" => 0,
        "operator_review_risk_limit" => 2,
        "classification_counts" => %{
          "blocked_by_policy" => 1,
          "operator_review_required" => 6
        },
        "required_authority_counts" => %{
          "flight_director" => 1,
          "resource_model_authority" => 6
        },
        "escalation_queue_counts" => %{
          "mission_operations" => 1,
          "mission_planning" => 4,
          "resource_planning" => 2
        },
        "required_operator_action_rule_count" => 0,
        "rule_ids_by_classification" => %{
          "blocked_by_policy" => ["combined_resource_pressure_director_block"],
          "operator_review_required" => [
            "first_storage_pressure_review",
            "invalid_resource_projection_activity_input_review",
            "invalid_resource_projection_summary_input_review",
            "missing_resource_trust_boundary_review",
            "resource_pressure_review",
            "unknown_resource_source_quality_review"
          ]
        },
        "boundary" => "artifact_only_no_authority_lookup",
        "workflow_execution" => "none",
        "provenance_source" => "OrbitalDynamics.Policy.bundle!",
        "no_command_execution" => true,
        "no_schedule_mutation" => true,
        "model_limit_count" => 5
      },
      "tolerances" => %{
        "action_rule_count" => 0,
        "blocked_risk_type_count" => 0,
        "auto_approvable_approval_count_limit" => 0,
        "auto_approvable_risk_limit" => 0,
        "operator_review_risk_limit" => 0,
        "required_operator_action_rule_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external policy validation",
        "checks resource-projection authority routing, queue counts, rule IDs, and artifact-only boundary only"
      ]
    },
    "fixture.artifact.policy_bundle.timeline_protection" => %{
      "id" => "fixture.artifact.policy_bundle.timeline_protection",
      "model_id" => "artifact.policy_bundle.v1",
      "reference_case" => "checked-in timeline protection policy bundle artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/policy_bundle_timeline_protection_v1.json",
        "contract" => "policy_bundle.v1"
      },
      "expected" => %{
        "schema_contract" => "policy_bundle.v1",
        "id" => "timeline_protection_v1",
        "action_rule_count" => 9,
        "blocked_risk_type_count" => 2,
        "auto_approvable_approval_count_limit" => 0,
        "auto_approvable_risk_limit" => 0,
        "operator_review_risk_limit" => 2,
        "classification_counts" => %{
          "blocked_by_policy" => 1,
          "operator_review_required" => 8
        },
        "required_authority_counts" => %{
          "flight_director" => 1,
          "timeline_protection_authority" => 8
        },
        "escalation_queue_counts" => %{
          "mission_operations" => 1,
          "mission_planning" => 8
        },
        "required_operator_action_rule_count" => 0,
        "rule_ids_by_classification" => %{
          "blocked_by_policy" => ["executed_timeline_item_block"],
          "operator_review_required" => [
            "approved_timeline_item_review",
            "locked_timeline_item_review",
            "planned_protection_decision_review",
            "replacement_timeline_integrity_issue_review",
            "source_preserved_transition_review",
            "source_protection_decision_review",
            "source_timeline_integrity_issue_review",
            "timeline_integrity_issue_review"
          ]
        },
        "boundary" => "artifact_only_no_authority_lookup",
        "workflow_execution" => "none",
        "provenance_source" => "OrbitalDynamics.Policy.bundle!",
        "no_command_execution" => true,
        "no_schedule_mutation" => true,
        "model_limit_count" => 5
      },
      "tolerances" => %{
        "action_rule_count" => 0,
        "blocked_risk_type_count" => 0,
        "auto_approvable_approval_count_limit" => 0,
        "auto_approvable_risk_limit" => 0,
        "operator_review_risk_limit" => 0,
        "required_operator_action_rule_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external policy validation",
        "checks timeline-protection authority routing, queue counts, rule IDs, and artifact-only boundary only"
      ]
    }
  }

  def all, do: @fixtures
end
