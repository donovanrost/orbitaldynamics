defmodule OrbitalDynamics.Validation.ReferenceFixtures.CandidateRefreshTimeline do
  @moduledoc false

  @fixtures %{
    "fixture.artifact.candidate_refresh.timeline_activity_precondition_replay" => %{
      "id" => "fixture.artifact.candidate_refresh.timeline_activity_precondition_replay",
      "model_id" => "artifact.candidate_refresh.v1",
      "reference_case" =>
        "generated candidate refresh replay of timeline-activity precondition evidence",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "source" => "generated_candidate_refresh_timeline_activity_precondition_fixture",
        "contract" => "candidate_refresh.v1"
      },
      "expected" => %{
        "schema_contract" => "candidate_refresh.v1",
        "schema_version" => 1,
        "planner" => "OrbitalDynamics.CandidateRefresh.V1",
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
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
        "source_timeline_activity_precondition_duplicate_exclusivity_activity_id_counts" => %{
          "dl_conflict" => 1
        },
        "source_timeline_activity_precondition_duplicate_exclusivity_timeline_id_counts" => %{
          "timeline:dl_conflict" => 1
        },
        "source_timeline_activity_precondition_allow_overlap_counts" => %{"true" => 1},
        "source_timeline_activity_precondition_trust_boundary_status" => "declared"
      },
      "tolerances" => %{
        "schema_version" => 0,
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "source_report_family_count" => 0,
        "source_report_row_count" => 0,
        "source_timeline_activity_precondition_report_count" => 0,
        "source_timeline_activity_precondition_row_count" => 0,
        "source_timeline_activity_precondition_blocked_precondition_count" => 0,
        "source_timeline_activity_precondition_review_precondition_count" => 0,
        "source_timeline_activity_precondition_invalid_activity_input_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal generated artifact regression, not external timeline validation",
        "checks candidate-refresh replay of timeline-activity precondition provenance without mutating schedules, granting operator authority, selecting candidates, approving imports, or writing to Cadence"
      ]
    },
    "fixture.artifact.candidate_refresh.timeline_lifecycle_state_replay" => %{
      "id" => "fixture.artifact.candidate_refresh.timeline_lifecycle_state_replay",
      "model_id" => "artifact.candidate_refresh.v1",
      "reference_case" =>
        "generated candidate refresh replay of timeline lifecycle state evidence",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "source" => "generated_candidate_refresh_timeline_lifecycle_state_fixture",
        "contract" => "candidate_refresh.v1"
      },
      "expected" => %{
        "schema_contract" => "candidate_refresh.v1",
        "schema_version" => 1,
        "planner" => "OrbitalDynamics.CandidateRefresh.V1",
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
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
        "source_timeline_lifecycle_state_review_timeline_ids_by_required_operator_action" => %{
          "review_activity_approval" => ["timeline:cmd_provider"],
          "review_duplicate_timeline_identity" => ["timeline:dup"]
        },
        "source_timeline_lifecycle_state_trust_boundary_status" => "declared"
      },
      "tolerances" => %{
        "schema_version" => 0,
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "source_report_family_count" => 0,
        "source_report_row_count" => 0,
        "source_timeline_lifecycle_state_report_count" => 0,
        "source_timeline_lifecycle_state_row_count" => 0,
        "source_timeline_lifecycle_state_planned_activity_count" => 0,
        "source_timeline_lifecycle_state_realized_activity_count" => 0,
        "source_timeline_lifecycle_state_recordable_count" => 0,
        "source_timeline_lifecycle_state_preserved_count" => 0,
        "source_timeline_lifecycle_state_review_required_count" => 0,
        "source_timeline_lifecycle_state_duplicate_timeline_identity_count" => 0,
        "source_timeline_lifecycle_state_invalid_activity_input_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal generated artifact regression, not external timeline validation",
        "checks candidate-refresh replay of timeline lifecycle-state provenance without mutating schedules, granting operator authority, selecting candidates, approving imports, or writing to Cadence"
      ]
    },
    "fixture.artifact.candidate_refresh.timeline_activity_lifecycle_replay" => %{
      "id" => "fixture.artifact.candidate_refresh.timeline_activity_lifecycle_replay",
      "model_id" => "artifact.candidate_refresh.v1",
      "reference_case" =>
        "generated candidate refresh replay of timeline activity lifecycle evidence",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "source" => "generated_candidate_refresh_timeline_activity_lifecycle_fixture",
        "contract" => "candidate_refresh.v1"
      },
      "expected" => %{
        "schema_contract" => "candidate_refresh.v1",
        "schema_version" => 1,
        "planner" => "OrbitalDynamics.CandidateRefresh.V1",
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "source_report_family_count" => 1,
        "source_report_row_count" => 1,
        "source_timeline_activity_lifecycle_report_count" => 1,
        "source_timeline_activity_lifecycle_row_count" => 1,
        "source_timeline_activity_lifecycle_review_required_count" => 1,
        "source_timeline_activity_lifecycle_invalid_activity_input_count" => 0,
        "source_timeline_activity_lifecycle_transition_decision_counts" => %{"review" => 1},
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
        "source_timeline_activity_lifecycle_action_routing" => %{
          "record_timeline_change" => %{
            "activity_ids" => ["cmd_provider"],
            "approval_transition_categories" => ["approval_granted"],
            "protection_categories" => ["executed", "none"],
            "review_count" => 1,
            "status_transition_categories" => ["execution_recorded"],
            "timeline_ids" => ["timeline:cmd_provider"]
          },
          "review_activity_approval" => %{
            "activity_ids" => ["cmd_provider"],
            "approval_transition_categories" => ["approval_granted"],
            "protection_categories" => ["executed", "none"],
            "review_count" => 1,
            "status_transition_categories" => ["execution_recorded"],
            "timeline_ids" => ["timeline:cmd_provider"]
          }
        },
        "source_timeline_activity_lifecycle_trust_boundary_status" => "declared"
      },
      "tolerances" => %{
        "schema_version" => 0,
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "source_report_family_count" => 0,
        "source_report_row_count" => 0,
        "source_timeline_activity_lifecycle_report_count" => 0,
        "source_timeline_activity_lifecycle_row_count" => 0,
        "source_timeline_activity_lifecycle_review_required_count" => 0,
        "source_timeline_activity_lifecycle_invalid_activity_input_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal generated artifact regression, not external timeline validation",
        "checks candidate-refresh replay of timeline activity lifecycle provenance without mutating schedules, granting operator authority, selecting candidates, approving imports, or writing to Cadence"
      ]
    },
    "fixture.artifact.candidate_refresh.timeline_transition_application_replay" => %{
      "id" => "fixture.artifact.candidate_refresh.timeline_transition_application_replay",
      "model_id" => "artifact.candidate_refresh.v1",
      "reference_case" =>
        "generated candidate refresh replay of timeline-transition selected-integrity evidence",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "source" => "generated_candidate_refresh_timeline_transition_application_fixture",
        "contract" => "candidate_refresh.v1"
      },
      "expected" => %{
        "schema_contract" => "candidate_refresh.v1",
        "schema_version" => 1,
        "planner" => "OrbitalDynamics.CandidateRefresh.V1",
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
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
      },
      "tolerances" => %{
        "schema_version" => 0,
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "source_report_family_count" => 0,
        "source_report_row_count" => 0,
        "source_timeline_transition_application_report_count" => 0,
        "source_timeline_transition_application_row_count" => 0,
        "source_timeline_transition_application_application_count" => 0,
        "source_timeline_transition_application_selected_activity_count" => 0,
        "source_timeline_transition_application_selected_integrity_review_count" => 0,
        "source_timeline_transition_application_selected_integrity_issue_count" => 0,
        "source_timeline_transition_application_review_required_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal generated artifact regression, not transition execution validation",
        "checks candidate-refresh replay of timeline-transition selected-integrity provenance without schedule mutation, candidate selection, import approval, or Cadence writes"
      ]
    }
  }

  def all, do: @fixtures
end
