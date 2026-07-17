defmodule OrbitalDynamics.Validation.ReferenceFixtures.TimelinePreservationArtifacts do
  @moduledoc false

  @fixtures %{
    "fixture.artifact.timeline_preservation_report.v1" => %{
      "id" => "fixture.artifact.timeline_preservation_report.v1",
      "model_id" => "artifact.timeline_preservation_report.v1",
      "reference_case" => "checked-in aggregate timeline preservation report artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/timeline_preservation_report_v1.json",
        "contract" => "timeline_preservation_report.v1"
      },
      "expected" => %{
        "schema_contract" => "timeline_preservation_report.v1",
        "model" => "artifact_only_lifecycle_preservation_summary",
        "source" => "validation.timeline_preservation_report",
        "activity_count" => 4,
        "row_count" => 3,
        "row_derived_row_count" => 3,
        "mutable_activity_count" => 1,
        "preserve_activity_count" => 2,
        "row_derived_preserve_activity_count" => 2,
        "review_change_activity_count" => 1,
        "row_derived_review_change_activity_count" => 1,
        "preservation_sensitive_activity_count" => 3,
        "row_derived_preservation_sensitive_activity_count" => 3,
        "row_derived_invalid_activity_input_count" => 1,
        "timeline_preservation_status" => "review_required",
        "protection_decision_counts" => %{
          "mutable" => 1,
          "preserve" => 2,
          "review_change" => 1
        },
        "row_derived_protection_decision_counts" => %{
          "preserve" => 2,
          "review_change" => 1
        },
        "protection_category_counts" => %{
          "executed" => 1,
          "invalid_activity_input" => 1,
          "locked_or_approved" => 1,
          "none" => 1
        },
        "row_derived_protection_category_counts" => %{
          "executed" => 1,
          "invalid_activity_input" => 1,
          "locked_or_approved" => 1
        },
        "protection_reason_counts" => %{
          "activity_already_completed" => 1,
          "activity_locked_or_approved" => 1,
          "missing_activity_type" => 1,
          "no_timeline_protection" => 1
        },
        "row_derived_protection_reason_counts" => %{
          "activity_already_completed" => 1,
          "activity_locked_or_approved" => 1,
          "missing_activity_type" => 1
        },
        "preserve_activity_keys" => "contact_locked|obs_done",
        "row_derived_preserve_activity_keys" => "contact_locked|obs_done",
        "review_change_activity_keys" => "bad_missing_type",
        "row_derived_review_change_activity_keys" => "bad_missing_type",
        "mutable_activity_keys" => "cmd_mutable",
        "preservation_sensitive_activity_keys" => "bad_missing_type|contact_locked|obs_done",
        "row_derived_preservation_sensitive_activity_keys" =>
          "bad_missing_type|contact_locked|obs_done",
        "preservation_sensitive_timeline_keys" =>
          "timeline:invalid_activity_input:bad_missing_type|timeline:observe|timeline:planned_contact",
        "row_derived_preservation_sensitive_timeline_keys" =>
          "timeline:invalid_activity_input:bad_missing_type|timeline:observe|timeline:planned_contact",
        "invalid_activity_input_keys" => "bad_missing_type",
        "activity_id_sets_by_protection_decision" => %{
          "mutable" => ["cmd_mutable"],
          "preserve" => ["contact_locked", "obs_done"],
          "review_change" => ["bad_missing_type"]
        },
        "row_derived_activity_id_sets_by_protection_decision" => %{
          "preserve" => ["contact_locked", "obs_done"],
          "review_change" => ["bad_missing_type"]
        },
        "timeline_id_sets_by_protection_decision" => %{
          "mutable" => ["timeline:command"],
          "preserve" => ["timeline:observe", "timeline:planned_contact"],
          "review_change" => ["timeline:invalid_activity_input:bad_missing_type"]
        },
        "row_derived_timeline_id_sets_by_protection_decision" => %{
          "preserve" => ["timeline:observe", "timeline:planned_contact"],
          "review_change" => ["timeline:invalid_activity_input:bad_missing_type"]
        },
        "activity_id_sets_by_protection_category" => %{
          "executed" => ["obs_done"],
          "invalid_activity_input" => ["bad_missing_type"],
          "locked_or_approved" => ["contact_locked"],
          "none" => ["cmd_mutable"]
        },
        "row_derived_activity_id_sets_by_protection_category" => %{
          "executed" => ["obs_done"],
          "invalid_activity_input" => ["bad_missing_type"],
          "locked_or_approved" => ["contact_locked"]
        },
        "timeline_id_sets_by_protection_reason" => %{
          "activity_already_completed" => ["timeline:observe"],
          "activity_locked_or_approved" => ["timeline:planned_contact"],
          "missing_activity_type" => ["timeline:invalid_activity_input:bad_missing_type"],
          "no_timeline_protection" => ["timeline:command"]
        },
        "row_derived_timeline_id_sets_by_protection_reason" => %{
          "activity_already_completed" => ["timeline:observe"],
          "activity_locked_or_approved" => ["timeline:planned_contact"],
          "missing_activity_type" => ["timeline:invalid_activity_input:bad_missing_type"]
        },
        "execution_boundary" => "artifact_only_no_schedule_mutation",
        "scope" => "lifecycle_lock_approval_and_executed_preservation_review",
        "assumption_source" => "validation.timeline_preservation_report",
        "model_limit_count" => 4
      },
      "tolerances" => %{
        "row_count" => 0,
        "row_derived_row_count" => 0,
        "preservation_sensitive_activity_count" => 0,
        "row_derived_preservation_sensitive_activity_count" => 0,
        "review_change_activity_count" => 0,
        "row_derived_review_change_activity_count" => 0
      },
      "evidence" => [
        "generated by OrbitalDynamics.Timeline.preservation_report/2",
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external operations validation",
        "checks preservation/report row routing, invalid input review evidence, and no-mutation boundary only"
      ]
    },
    "fixture.artifact.timeline_preservation_status.v1" => %{
      "id" => "fixture.artifact.timeline_preservation_status.v1",
      "model_id" => "artifact.timeline_preservation_status.v1",
      "reference_case" => "checked-in single-activity timeline preservation status artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/timeline_preservation_status_v1.json",
        "contract" => "timeline_preservation_status.v1"
      },
      "expected" => %{
        "schema_contract" => "timeline_preservation_status.v1",
        "model" => "artifact_only_lifecycle_preservation_status",
        "activity_id" => "dl_locked",
        "activity_type" => "downlink",
        "timeline_id" => "timeline:dl_locked",
        "timeline_identity_activity_id" => "dl_locked",
        "timeline_identity_activity_type" => "downlink",
        "timeline_identity_timeline_id" => "timeline:dl_locked",
        "status" => "planned",
        "approval_status" => "pending",
        "locked" => true,
        "approved" => false,
        "protection_decision" => "preserve",
        "protection_category" => "locked_or_approved",
        "protection_reason" => "activity_locked_or_approved",
        "timeline_preservation_status" => "preservation_required",
        "requires_preservation" => true,
        "requires_operator_review" => false,
        "execution_boundary" => "artifact_only_no_schedule_mutation",
        "scope" => "single_activity_lifecycle_preservation_preflight",
        "model_limit_count" => 4,
        "no_schedule_mutation" => true,
        "no_command_execution" => true,
        "derived_identity_when_no_persistent_timeline_id" => true
      },
      "tolerances" => %{"model_limit_count" => 0},
      "evidence" => [
        "generated by OrbitalDynamics.timeline_preservation_status/1",
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external operations validation",
        "checks single-activity lock preservation and artifact-only no-mutation boundary only"
      ]
    },
    "fixture.artifact.timeline_integrity_report.v1" => %{
      "id" => "fixture.artifact.timeline_integrity_report.v1",
      "model_id" => "artifact.timeline_integrity_report.v1",
      "reference_case" => "checked-in timeline integrity report artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/timeline_integrity_report_v1.json",
        "contract" => "timeline_integrity_report.v1"
      },
      "expected" => %{
        "schema_contract" => "timeline_integrity_report.v1",
        "model" => "artifact_only_timeline_integrity_summary",
        "validation_level" => "artifact_contract",
        "source" => "timeline.activities",
        "activity_count" => 3,
        "valid_activity_count" => 3,
        "invalid_activity_input_count" => 0,
        "timeline_integrity_status" => "review_required",
        "timeline_integrity_review_count" => 1,
        "row_derived_timeline_integrity_review_count" => 1,
        "timeline_integrity_issue_count" => 3,
        "row_derived_timeline_integrity_issue_count" => 3,
        "timeline_integrity_issue_type_keys" =>
          "dependency_order_violation|exclusivity_overlap|missing_dependency_activity",
        "timeline_integrity_issue_type_counts" => %{
          "dependency_order_violation" => 1,
          "exclusivity_overlap" => 1,
          "missing_dependency_activity" => 1
        },
        "row_derived_timeline_integrity_issue_type_counts" => %{
          "dependency_order_violation" => 1,
          "exclusivity_overlap" => 1,
          "missing_dependency_activity" => 1
        },
        "required_operator_action_counts" => %{"review_timeline_integrity" => 1},
        "row_derived_required_operator_action_counts" => %{"review_timeline_integrity" => 1},
        "operator_action_reason_counts" => %{"timeline_integrity_issue" => 1},
        "row_derived_operator_action_reason_counts" => %{"timeline_integrity_issue" => 1},
        "dependency_issue_count" => 2,
        "exclusivity_issue_count" => 1,
        "review_activity_keys" => "cmd_main",
        "review_timeline_keys" => "timeline:command:dss_14:10.0",
        "dependency_review_activity_keys" => "cmd_main",
        "exclusivity_review_activity_keys" => "cmd_main",
        "missing_dependency_activity_keys" => "missing_gate",
        "dependency_order_violation_activity_keys" => "health_gate",
        "exclusivity_violation_activity_keys" => "dl_conflict",
        "exclusivity_violation_timeline_keys" => "timeline:downlink:dss_14:12.0",
        "review_activity_ids_by_issue_type" => %{
          "dependency_order_violation" => ["cmd_main"],
          "exclusivity_overlap" => ["cmd_main"],
          "missing_dependency_activity" => ["cmd_main"]
        },
        "row_derived_activity_ids_by_issue_type" => %{
          "dependency_order_violation" => ["cmd_main"],
          "exclusivity_overlap" => ["cmd_main"],
          "missing_dependency_activity" => ["cmd_main"]
        },
        "review_timeline_ids_by_required_operator_action" => %{
          "review_timeline_integrity" => ["timeline:command:dss_14:10.0"]
        },
        "row_derived_timeline_ids_by_required_operator_action" => %{
          "review_timeline_integrity" => ["timeline:command:dss_14:10.0"]
        },
        "execution_boundary" => "artifact_only_no_schedule_mutation",
        "missing_dependency_validation" => "enabled",
        "scope" => "dependency_and_exclusivity_integrity_validation",
        "model_limit_count" => 4
      },
      "tolerances" => %{
        "activity_count" => 0,
        "valid_activity_count" => 0,
        "invalid_activity_input_count" => 0,
        "timeline_integrity_review_count" => 0,
        "row_derived_timeline_integrity_review_count" => 0,
        "timeline_integrity_issue_count" => 0,
        "row_derived_timeline_integrity_issue_count" => 0,
        "dependency_issue_count" => 0,
        "exclusivity_issue_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "generated by OrbitalDynamics.Timeline.integrity_report/2",
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external dependency validation evidence",
        "checks integrity review rows, dependency/exclusivity evidence, row-derived issue maps, and no-schedule-mutation boundary only"
      ]
    },
    "fixture.artifact.timeline_dependency_impact_summary.v1" => %{
      "id" => "fixture.artifact.timeline_dependency_impact_summary.v1",
      "model_id" => "artifact.timeline_dependency_impact_summary.v1",
      "reference_case" => "checked-in timeline dependency impact summary artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/timeline_dependency_impact_summary_v1.json",
        "contract" => "timeline_dependency_impact_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "timeline_dependency_impact_summary.v1",
        "model" => "artifact_only_timeline_dependency_impact_summary",
        "validation_level" => "artifact_contract",
        "source" => "timeline_diff_report.v1",
        "source_activity_count" => 4,
        "replacement_activity_count" => 3,
        "changed_source_activity_count" => 2,
        "changed_source_timeline_count" => 2,
        "dependency_impact_status" => "review_required",
        "dependent_activity_count" => 4,
        "source_dependent_activity_count" => 2,
        "replacement_dependent_activity_count" => 2,
        "impacted_source_activity_keys" => "dl_followup|health_gate",
        "dependent_activity_keys" => "cmd_main|obs_parallel",
        "impacted_dependency_activity_keys" => "health_gate",
        "impacted_exclusive_with_activity_keys" => "dl_followup",
        "dependency_impact_row_count" => 4,
        "row_derived_scope_counts" => %{"replacement" => 2, "source" => 2},
        "row_derived_dependency_impact_status_counts" => %{"review_required" => 4},
        "row_derived_required_operator_action_counts" => %{
          "review_timeline_integrity" => 4
        },
        "row_derived_operator_action_reason_counts" => %{
          "dependency_changed_or_removed_source_activity" => 2,
          "exclusivity_changed_or_removed_source_activity" => 2
        },
        "row_derived_activity_type_counts" => %{"command" => 2, "observe" => 2},
        "row_ids_by_required_operator_action" => %{
          "review_timeline_integrity" => [
            "dependency_impact:replacement:timeline:command:20.0",
            "dependency_impact:replacement:timeline:observe:60.0",
            "dependency_impact:source:timeline:command:20.0",
            "dependency_impact:source:timeline:observe:60.0"
          ]
        },
        "execution_boundary" => "artifact_only_no_schedule_mutation",
        "operator_authority" => "not_granted_by_summary",
        "model_limit_count" => 4
      },
      "tolerances" => %{
        "source_activity_count" => 0,
        "replacement_activity_count" => 0,
        "changed_source_activity_count" => 0,
        "changed_source_timeline_count" => 0,
        "dependent_activity_count" => 0,
        "source_dependent_activity_count" => 0,
        "replacement_dependent_activity_count" => 0,
        "dependency_impact_row_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "generated by OrbitalDynamics.Timeline.dependency_impact_summary/2",
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external dependency validation evidence",
        "checks dependency-impact counts, row routing, and no-authority assumptions"
      ]
    },
    "fixture.artifact.timeline_diff_summary.v1" => %{
      "id" => "fixture.artifact.timeline_diff_summary.v1",
      "model_id" => "artifact.timeline_diff_summary.v1",
      "reference_case" => "checked-in timeline diff summary artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/timeline_diff_summary_v1.json",
        "contract" => "timeline_diff_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "timeline_diff_summary.v1",
        "model" => "artifact_only_timeline_diff_summary",
        "validation_level" => "artifact_contract",
        "source_artifact_type" => "timeline_diff_report.v1",
        "source" => "repair.activities",
        "source_activity_count" => 2,
        "replacement_activity_count" => 2,
        "row_count" => 3,
        "added_count" => 1,
        "removed_count" => 1,
        "changed_count" => 1,
        "unchanged_count" => 0,
        "review_required_count" => 3,
        "review_row_count" => 3,
        "diff_status_counts" => %{"added" => 1, "changed" => 1, "removed" => 1},
        "row_derived_diff_status_counts" => %{"added" => 1, "changed" => 1, "removed" => 1},
        "transition_decision_counts" => %{"preserve_source" => 1, "review" => 2},
        "row_derived_transition_decision_counts" => %{
          "preserve_source" => 1,
          "review" => 2
        },
        "required_operator_action_counts" => %{
          "review_added_activity" => 1,
          "review_changed_protected_activity" => 1,
          "review_removed_activity" => 1
        },
        "row_derived_required_operator_action_counts" => %{
          "review_added_activity" => 1,
          "review_changed_protected_activity" => 1,
          "review_removed_activity" => 1
        },
        "changed_field_counts" => %{
          "activity_id" => 1,
          "approval_status" => 1,
          "ends_at_s" => 1,
          "starts_at_s" => 1,
          "status" => 1,
          "timeline_presence" => 2
        },
        "row_derived_changed_field_counts" => %{
          "activity_id" => 1,
          "approval_status" => 1,
          "ends_at_s" => 1,
          "starts_at_s" => 1,
          "status" => 1,
          "timeline_presence" => 2
        },
        "status_transition_category_counts" => %{
          "status_added" => 1,
          "status_changed" => 1,
          "status_removed" => 1
        },
        "row_derived_status_transition_category_counts" => %{
          "status_added" => 1,
          "status_changed" => 1,
          "status_removed" => 1
        },
        "approval_transition_category_counts" => %{
          "approval_regressed" => 1,
          "approval_removed" => 1,
          "approval_review_required" => 1
        },
        "row_derived_approval_transition_category_counts" => %{
          "approval_regressed" => 1,
          "approval_removed" => 1,
          "approval_review_required" => 1
        },
        "review_timeline_ids_by_required_operator_action" => %{
          "review_added_activity" => ["timeline:cmd_added"],
          "review_changed_protected_activity" => ["timeline:obs_1"],
          "review_removed_activity" => ["timeline:dl_removed"]
        },
        "row_derived_review_timeline_ids_by_required_operator_action" => %{
          "review_added_activity" => ["timeline:cmd_added"],
          "review_changed_protected_activity" => ["timeline:obs_1"],
          "review_removed_activity" => ["timeline:dl_removed"]
        },
        "review_timeline_keys" => "timeline:cmd_added|timeline:dl_removed|timeline:obs_1",
        "execution_boundary" => "artifact_only_no_schedule_mutation",
        "operator_authority" => "not_granted_by_summary",
        "model_limit_count" => 4
      },
      "tolerances" => %{
        "source_activity_count" => 0,
        "replacement_activity_count" => 0,
        "row_count" => 0,
        "added_count" => 0,
        "removed_count" => 0,
        "changed_count" => 0,
        "unchanged_count" => 0,
        "review_required_count" => 0,
        "review_row_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "generated by OrbitalDynamics.Timeline.diff_summary/3",
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external timeline validation evidence",
        "checks diff-summary counts, review-row routing, and no-authority assumptions"
      ]
    },
    "fixture.artifact.timeline_publication_summary.v1" => %{
      "id" => "fixture.artifact.timeline_publication_summary.v1",
      "model_id" => "artifact.timeline_publication_summary.v1",
      "reference_case" => "checked-in timeline publication summary artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/timeline_publication_summary_v1.json",
        "contract" => "timeline_publication_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "timeline_publication_summary.v1",
        "model" => "artifact_only_timeline_publication_summary",
        "validation_level" => "artifact_contract",
        "source" => "operational_timeline_report.v1",
        "source_artifact_type" => "operational_timeline_report.v1",
        "source_artifact_id" => "timeline:published_plan:v2",
        "publication_id" =>
          "timeline_publication:7:timeline:published_plan:v2:timeline:published_plan:v1",
        "publication_sequence" => 7,
        "publication_status" => "published_with_downstream_invalidations",
        "downstream_invalidation_status" => "invalidated",
        "publication_authority" => "mission_operations",
        "supersedes_artifact_ids" => "timeline:published_plan:v1",
        "downstream_product_ids" => "cadence_import:plan:v1|operator_review:plan:v1",
        "invalidated_downstream_product_ids" => "cadence_import:plan:v1|operator_review:plan:v1",
        "downstream_invalidation_reason_counts" => %{
          "dependency_impact_review_required" => 2
        },
        "invalidated_downstream_product_ids_by_reason" => %{
          "dependency_impact_review_required" => [
            "cadence_import:plan:v1",
            "operator_review:plan:v1"
          ]
        },
        "dependency_impact_status" => "review_required",
        "dependency_impact_row_count" => 2,
        "impacted_source_activity_ids" => "health_gate",
        "impacted_source_timeline_ids" => "timeline:health_check:0.0",
        "dependent_activity_ids" => "cmd_main",
        "dependent_timeline_ids" => "timeline:command:20.0",
        "source_dependent_activity_ids" => "cmd_main",
        "source_dependent_timeline_ids" => "timeline:command:20.0",
        "replacement_dependent_activity_ids" => "cmd_main",
        "replacement_dependent_timeline_ids" => "timeline:command:20.0",
        "impacted_dependency_activity_ids" => "health_gate",
        "impacted_dependency_timeline_ids" => "",
        "impacted_exclusive_with_activity_ids" => "",
        "impacted_exclusive_with_timeline_ids" => "",
        "timeline_diff_row_count" => 3,
        "timeline_diff_changed_count" => 0,
        "timeline_diff_review_required_count" => 2,
        "changed_field_counts" => %{"timeline_presence" => 2},
        "changed_timeline_ids" => "",
        "review_timeline_ids" => "timeline:health_check:0.0|timeline:health_check:5.0",
        "timeline_ids_by_changed_field" => %{
          "timeline_presence" => ["timeline:health_check:0.0", "timeline:health_check:5.0"]
        },
        "source_timeline_diff_row_count" => 3,
        "source_timeline_diff_review_required_count" => 2,
        "source_timeline_diff_changed_count" => 0,
        "source_timeline_diff_changed_field_counts" => %{"timeline_presence" => 2},
        "source_timeline_diff_review_timeline_ids" =>
          "timeline:health_check:0.0|timeline:health_check:5.0",
        "source_timeline_diff_review_timeline_ids_by_required_operator_action" => %{
          "review_added_activity" => ["timeline:health_check:5.0"],
          "review_removed_activity" => ["timeline:health_check:0.0"]
        },
        "model_limit_count" => 4,
        "execution_boundary" => "artifact_only_no_schedule_mutation",
        "notification_delivery" => "host_system_owned",
        "assumption_publication_authority" => "mission_operations",
        "operator_authority" => "not_granted_by_summary",
        "no_schedule_mutation" => true,
        "no_command_execution" => true,
        "derived_identity_when_no_persistent_timeline_id" => true
      },
      "tolerances" => %{
        "publication_sequence" => 0,
        "dependency_impact_row_count" => 0,
        "timeline_diff_row_count" => 0,
        "timeline_diff_changed_count" => 0,
        "timeline_diff_review_required_count" => 0,
        "source_timeline_diff_row_count" => 0,
        "source_timeline_diff_review_required_count" => 0,
        "source_timeline_diff_changed_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "generated by OrbitalDynamics.Timeline.publication_summary/2",
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external timeline publication evidence",
        "checks publication status, downstream invalidations, diff review routing, and no-authority assumptions"
      ]
    }
  }

  def all, do: @fixtures
end
