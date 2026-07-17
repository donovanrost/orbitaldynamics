defmodule OrbitalDynamics.Validation.ReferenceFixtures.TimelineHandoffArtifacts do
  @moduledoc false

  @fixtures %{
    "fixture.artifact.timeline_diff_report.v1" => %{
      "id" => "fixture.artifact.timeline_diff_report.v1",
      "model_id" => "artifact.timeline_diff_report.v1",
      "reference_case" => "checked-in timeline diff artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/timeline_diff_report_v1.json",
        "contract" => "timeline_diff_report.v1"
      },
      "expected" => %{
        "schema_contract" => "timeline_diff_report.v1",
        "model" => "timeline_identity_activity_diff",
        "source" => "repair.activities",
        "source_activity_count" => 3,
        "replacement_activity_count" => 3,
        "row_count" => 4,
        "added_count" => 1,
        "changed_count" => 2,
        "removed_count" => 1,
        "unchanged_count" => 0,
        "review_required_count" => 4,
        "duplicate_timeline_identity_count" => 0,
        "duplicate_source_timeline_identity_count" => 0,
        "duplicate_replacement_timeline_identity_count" => 0,
        "diff_status_counts" => %{"added" => 1, "changed" => 2, "removed" => 1},
        "row_derived_diff_status_counts" => %{
          "added" => 1,
          "changed" => 2,
          "removed" => 1
        },
        "approval_transition_counts" => %{"added" => 1, "changed" => 1, "removed" => 1},
        "row_derived_approval_transition_counts" => %{
          "added" => 1,
          "changed" => 1,
          "removed" => 1
        },
        "status_transition_counts" => %{"added" => 1, "changed" => 1, "removed" => 1},
        "row_derived_status_transition_counts" => %{
          "added" => 1,
          "changed" => 1,
          "removed" => 1
        },
        "required_operator_action_counts" => %{
          "review_added_activity" => 1,
          "review_changed_protected_activity" => 1,
          "review_removed_activity" => 1,
          "review_timeline_change" => 1
        },
        "row_derived_required_operator_action_counts" => %{
          "review_added_activity" => 1,
          "review_changed_protected_activity" => 1,
          "review_removed_activity" => 1,
          "review_timeline_change" => 1
        },
        "changed_field_counts" => %{
          "activity_id" => 1,
          "approval_status" => 1,
          "ends_at_s" => 1,
          "execution_uncertainty" => 1,
          "starts_at_s" => 1,
          "status" => 1,
          "timeline_presence" => 2
        },
        "row_derived_changed_field_counts" => %{
          "activity_id" => 1,
          "approval_status" => 1,
          "ends_at_s" => 1,
          "execution_uncertainty" => 1,
          "starts_at_s" => 1,
          "status" => 1,
          "timeline_presence" => 2
        },
        "row_ids_by_diff_status" => %{
          "added" => ["timeline_diff:timeline:cmd_added"],
          "changed" => [
            "timeline_diff:timeline:obs_1",
            "timeline_diff:timeline:raise_apogee"
          ],
          "removed" => ["timeline_diff:timeline:dl_removed"]
        },
        "row_ids_by_required_operator_action" => %{
          "review_added_activity" => ["timeline_diff:timeline:cmd_added"],
          "review_changed_protected_activity" => ["timeline_diff:timeline:obs_1"],
          "review_removed_activity" => ["timeline_diff:timeline:dl_removed"],
          "review_timeline_change" => ["timeline_diff:timeline:raise_apogee"]
        },
        "row_derived_row_ids_by_diff_status" => %{
          "added" => ["timeline_diff:timeline:cmd_added"],
          "changed" => [
            "timeline_diff:timeline:obs_1",
            "timeline_diff:timeline:raise_apogee"
          ],
          "removed" => ["timeline_diff:timeline:dl_removed"]
        },
        "row_derived_row_ids_by_required_operator_action" => %{
          "review_added_activity" => ["timeline_diff:timeline:cmd_added"],
          "review_changed_protected_activity" => ["timeline_diff:timeline:obs_1"],
          "review_removed_activity" => ["timeline_diff:timeline:dl_removed"],
          "review_timeline_change" => ["timeline_diff:timeline:raise_apogee"]
        },
        "execution_boundary" => "artifact_only_no_schedule_mutation",
        "model_limit_count" => 4
      },
      "tolerances" => %{
        "source_activity_count" => 0,
        "replacement_activity_count" => 0,
        "row_count" => 0,
        "added_count" => 0,
        "changed_count" => 0,
        "removed_count" => 0,
        "unchanged_count" => 0,
        "review_required_count" => 0,
        "duplicate_timeline_identity_count" => 0,
        "duplicate_source_timeline_identity_count" => 0,
        "duplicate_replacement_timeline_identity_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external timeline validation",
        "checks timeline diff counts, transition maps, operator-action routing, and no-schedule-mutation boundary only"
      ]
    },
    "fixture.artifact.cadence_import_manifest.v1" => %{
      "id" => "fixture.artifact.cadence_import_manifest.v1",
      "model_id" => "artifact.cadence_import_manifest.v1",
      "reference_case" => "checked-in Cadence import manifest artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/cadence_import_manifest_v1.json",
        "contract" => "cadence_import_manifest.v1"
      },
      "expected" => %{
        "schema_contract" => "cadence_import_manifest.v1",
        "schema_version" => 1,
        "model" => "artifact_only_cadence_import_manifest",
        "manifest_id" => "cadence_import_manifest:repair:fixture",
        "source_artifact_type" => "campaign_repair.v2",
        "source_artifact_id" => "repair:fixture",
        "row_count" => 2,
        "ready_count" => 1,
        "row_derived_ready_count" => 1,
        "blocked_count" => 1,
        "row_derived_blocked_count" => 1,
        "review_required_count" => 0,
        "missing_import_count" => 1,
        "row_derived_missing_import_count" => 1,
        "source_review_count" => 2,
        "import_status_counts" => %{
          "blocked_missing_cadence_import" => 1,
          "ready_for_import" => 1
        },
        "row_derived_import_status_counts" => %{
          "blocked_missing_cadence_import" => 1,
          "ready_for_import" => 1
        },
        "import_action_counts" => %{"import_replacement_activity" => 2},
        "row_derived_import_action_counts" => %{"import_replacement_activity" => 2},
        "cadence_import_status_counts" => %{"missing" => 1, "present" => 1},
        "row_derived_cadence_import_status_counts" => %{"missing" => 1, "present" => 1},
        "required_operator_action_counts" => %{"review_moved_timeline_item" => 2},
        "row_derived_required_operator_action_counts" => %{
          "review_moved_timeline_item" => 2
        },
        "source_review_type_counts" => %{"plan_delta_review" => 2},
        "row_derived_source_review_type_counts" => %{"plan_delta_review" => 2},
        "import_side_counts" => %{"replacement" => 2},
        "row_derived_import_side_counts" => %{"replacement" => 2},
        "source_review_queue_counts" => %{
          "plan_delta_review|review_moved_timeline_item|not_required" => 2
        },
        "row_derived_source_review_queue_counts" => %{
          "plan_delta_review|review_moved_timeline_item|not_required" => 2
        },
        "manifest_row_ids_by_import_status" => %{
          "blocked_missing_cadence_import" => ["cadence_import:plan_delta:dl_3:moved:2"],
          "ready_for_import" => ["cadence_import:plan_delta:dl_1:moved:1"]
        },
        "row_derived_manifest_row_ids_by_import_status" => %{
          "blocked_missing_cadence_import" => ["cadence_import:plan_delta:dl_3:moved:2"],
          "ready_for_import" => ["cadence_import:plan_delta:dl_1:moved:1"]
        },
        "execution_boundary" => "artifact_only_no_cadence_api_writes",
        "authorization_boundary" => "operator_review_or_cadence_adapter_must_authorize_import",
        "model_limit_count" => 4
      },
      "tolerances" => %{
        "schema_version" => 0,
        "row_count" => 0,
        "ready_count" => 0,
        "row_derived_ready_count" => 0,
        "blocked_count" => 0,
        "row_derived_blocked_count" => 0,
        "review_required_count" => 0,
        "missing_import_count" => 0,
        "row_derived_missing_import_count" => 0,
        "source_review_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external Cadence API validation",
        "checks import manifest counts, handoff routing, and no-write authorization boundary only"
      ]
    },
    "fixture.artifact.timeline_feedback_report.v1" => %{
      "id" => "fixture.artifact.timeline_feedback_report.v1",
      "model_id" => "artifact.timeline_feedback_report.v1",
      "reference_case" => "checked-in timeline feedback artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/timeline_feedback_report_v1.json",
        "contract" => "timeline_feedback_report.v1"
      },
      "expected" => %{
        "schema_contract" => "timeline_feedback_report.v1",
        "model" => "planned_vs_realized_activity_reconciliation",
        "planned_count" => 4,
        "realized_count" => 4,
        "row_count" => 4,
        "operational_feedback_count" => 16,
        "operational_feedback_excluded_count" => 1,
        "duplicate_realized_feedback_count" => 0,
        "ambiguous_timeline_feedback_count" => 0,
        "ambiguous_timeline_match_count" => 0,
        "duplicate_realized_match_count" => 0,
        "execution_uncertainty_declared_count" => 0,
        "execution_uncertainty_missing_count" => 1,
        "operator_review_count" => 4,
        "cadence_import_manifest_row_count" => 4,
        "status_counts" => %{"matched" => 4},
        "row_derived_status_counts" => %{"matched" => 4},
        "feedback_kind_counts" => %{
          "command" => 1,
          "contact" => 1,
          "maneuver" => 1,
          "observation" => 1
        },
        "row_derived_feedback_kind_counts" => %{
          "command" => 1,
          "contact" => 1,
          "maneuver" => 1,
          "observation" => 1
        },
        "match_strategy_counts" => %{"planned_activity_id" => 4},
        "row_derived_match_strategy_counts" => %{"planned_activity_id" => 4},
        "planned_protection_decision_counts" => %{"preserve" => 4},
        "row_derived_planned_protection_decision_counts" => %{"preserve" => 4},
        "cadence_import_status_counts" => %{
          "missing" => 1,
          "not_applicable" => 2,
          "present" => 1
        },
        "row_derived_cadence_import_status_counts" => %{
          "missing" => 1,
          "not_applicable" => 2,
          "present" => 1
        },
        "realized_status_counts" => %{"completed" => 3, "partial" => 1},
        "row_derived_realized_status_counts" => %{"completed" => 3, "partial" => 1},
        "status_transition_category_counts" => %{"execution_recorded" => 4},
        "row_derived_status_transition_category_counts" => %{"execution_recorded" => 4},
        "activity_ids_by_feedback_kind" => %{
          "command" => ["cmd_repoint"],
          "contact" => ["downlink_equator"],
          "maneuver" => ["burn_cleanup"],
          "observation" => ["obs_feedback"]
        },
        "activity_ids_by_status" => %{
          "matched" => ["burn_cleanup", "cmd_repoint", "downlink_equator", "obs_feedback"]
        },
        "row_derived_activity_ids_by_feedback_kind" => %{
          "command" => ["cmd_repoint"],
          "contact" => ["downlink_equator"],
          "maneuver" => ["burn_cleanup"],
          "observation" => ["obs_feedback"]
        },
        "row_derived_activity_ids_by_status" => %{
          "matched" => ["burn_cleanup", "cmd_repoint", "downlink_equator", "obs_feedback"]
        },
        "boundary" => "report_only_no_schedule_mutation",
        "model_limit_count" => 5
      },
      "tolerances" => %{
        "planned_count" => 0,
        "realized_count" => 0,
        "row_count" => 0,
        "operational_feedback_count" => 0,
        "operational_feedback_excluded_count" => 0,
        "duplicate_realized_feedback_count" => 0,
        "ambiguous_timeline_feedback_count" => 0,
        "ambiguous_timeline_match_count" => 0,
        "duplicate_realized_match_count" => 0,
        "execution_uncertainty_declared_count" => 0,
        "execution_uncertainty_missing_count" => 0,
        "operator_review_count" => 0,
        "cadence_import_manifest_row_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external operations validation",
        "checks timeline feedback reconciliation counts, nested handoff counts, feedback routing, and no-schedule-mutation boundary only"
      ]
    }
  }

  def all, do: @fixtures
end
