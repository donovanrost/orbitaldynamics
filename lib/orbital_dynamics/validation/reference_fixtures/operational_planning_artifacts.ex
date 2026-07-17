defmodule OrbitalDynamics.Validation.ReferenceFixtures.OperationalPlanningArtifacts do
  @moduledoc false

  @fixtures %{
    "fixture.artifact.command_window_report.v1" => %{
      "id" => "fixture.artifact.command_window_report.v1",
      "model_id" => "artifact.command_window_report.v1",
      "reference_case" => "checked-in command window artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/command_window_report_v1.json",
        "contract" => "command_window_report.v1"
      },
      "expected" => %{
        "schema_contract" => "command_window_report.v1",
        "model" => "artifact_only_command_window_report",
        "source" => "fixture.command_window.activities",
        "window_count" => 4,
        "row_count" => 4,
        "command_count" => 1,
        "health_check_count" => 1,
        "tracking_count" => 1,
        "uplink_count" => 1,
        "review_required_count" => 2,
        "source_window_lineage_count" => 1,
        "locked_window_count" => 1,
        "window_type_counts" => %{
          "command_window" => 1,
          "health_check_window" => 1,
          "tracking_window" => 1,
          "uplink_window" => 1
        },
        "row_derived_window_type_counts" => %{
          "command_window" => 1,
          "health_check_window" => 1,
          "tracking_window" => 1,
          "uplink_window" => 1
        },
        "required_operator_action_counts" => %{
          "monitor_activity" => 2,
          "prepare_cadence_import" => 1,
          "review_command_contact" => 1
        },
        "row_derived_required_operator_action_counts" => %{
          "monitor_activity" => 2,
          "prepare_cadence_import" => 1,
          "review_command_contact" => 1
        },
        "approval_status_counts" => %{
          "approved" => 1,
          "not_required" => 1,
          "operator_review_required" => 2
        },
        "row_derived_approval_status_counts" => %{
          "approved" => 1,
          "not_required" => 1,
          "operator_review_required" => 2
        },
        "cadence_import_status_counts" => %{
          "missing" => 2,
          "not_applicable" => 1,
          "present" => 1
        },
        "row_derived_cadence_import_status_counts" => %{
          "missing" => 2,
          "not_applicable" => 1,
          "present" => 1
        },
        "window_ids_by_required_operator_action" => %{
          "monitor_activity" => [
            "command_window:health_poll",
            "command_window:tracking_pass"
          ],
          "prepare_cadence_import" => ["command_window:uplink_contact"],
          "review_command_contact" => ["command_window:cmd_window"]
        },
        "row_derived_window_ids_by_required_operator_action" => %{
          "monitor_activity" => [
            "command_window:health_poll",
            "command_window:tracking_pass"
          ],
          "prepare_cadence_import" => ["command_window:uplink_contact"],
          "review_command_contact" => ["command_window:cmd_window"]
        },
        "execution_boundary" => "artifact_only_no_schedule_mutation_or_command_execution",
        "model_limit_count" => 4
      },
      "tolerances" => %{
        "window_count" => 0,
        "row_count" => 0,
        "command_count" => 0,
        "health_check_count" => 0,
        "tracking_count" => 0,
        "uplink_count" => 0,
        "review_required_count" => 0,
        "source_window_lineage_count" => 0,
        "locked_window_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external command execution validation",
        "checks command-window counts, operator action routing, and artifact-only boundary only"
      ]
    },
    "fixture.artifact.constraint_report.v1" => %{
      "id" => "fixture.artifact.constraint_report.v1",
      "model_id" => "artifact.constraint_report.v1",
      "reference_case" => "checked-in constraint report artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/constraint_report_v1.json",
        "contract" => "constraint_report.v1"
      },
      "expected" => %{
        "schema_contract" => "constraint_report.v1",
        "model" => "artifact_metric_threshold",
        "status" => "fail",
        "constraint_count" => 2,
        "row_count" => 3,
        "constraint_row_count" => 3,
        "status_counts" => %{"fail" => 1, "pass" => 1, "warning" => 1},
        "row_derived_status_counts" => %{"fail" => 1, "pass" => 1, "warning" => 1},
        "metric_counts" => %{"estimated_throughput_mb" => 1, "min_altitude_km" => 2},
        "row_derived_metric_counts" => %{
          "estimated_throughput_mb" => 1,
          "min_altitude_km" => 2
        },
        "operator_counts" => %{">=" => 3},
        "row_derived_operator_counts" => %{">=" => 3},
        "constraint_ids_by_status" => %{
          "fail" => ["minimum_operational_altitude"],
          "pass" => ["minimum_operational_altitude"],
          "warning" => ["downlink_margin"]
        },
        "row_derived_constraint_ids_by_status" => %{
          "fail" => ["minimum_operational_altitude"],
          "pass" => ["minimum_operational_altitude"],
          "warning" => ["downlink_margin"]
        },
        "constraint_model" => "artifact_level_metric_thresholds",
        "model_limit_count" => 5
      },
      "tolerances" => %{
        "constraint_count" => 0,
        "row_count" => 0,
        "constraint_row_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external constraint validation",
        "checks threshold status distribution, metric rows, and artifact-level boundary only"
      ]
    },
    "fixture.artifact.operational_timeline_report.v1" => %{
      "id" => "fixture.artifact.operational_timeline_report.v1",
      "model_id" => "artifact.operational_timeline_report.v1",
      "reference_case" => "checked-in operational timeline artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/operational_timeline_report_v1.json",
        "contract" => "operational_timeline_report.v1"
      },
      "expected" => %{
        "schema_contract" => "operational_timeline_report.v1",
        "model" => "selected_activity_operational_context_summary",
        "source" => "mission_plan.activities",
        "activity_count" => 3,
        "row_count" => 3,
        "contact_count" => 2,
        "command_count" => 2,
        "approved_count" => 2,
        "executed_count" => 0,
        "locked_count" => 0,
        "terminal_exception_count" => 0,
        "dependency_count" => 1,
        "dependency_issue_count" => 2,
        "exclusivity_count" => 1,
        "exclusivity_issue_count" => 3,
        "timeline_integrity_issue_count" => 5,
        "timeline_integrity_review_count" => 2,
        "duplicate_timeline_identity_count" => 0,
        "duplicate_timeline_identity_activity_count" => 0,
        "source_window_lineage_count" => 2,
        "operational_kind_counts" => %{"command" => 1, "contact" => 1, "health_check" => 1},
        "row_derived_operational_kind_counts" => %{
          "command" => 1,
          "contact" => 1,
          "health_check" => 1
        },
        "activity_status_counts" => %{"planned" => 3},
        "row_derived_activity_status_counts" => %{"planned" => 3},
        "approval_status_counts" => %{"approved" => 2, "pending" => 1},
        "row_derived_approval_status_counts" => %{"approved" => 2, "pending" => 1},
        "cadence_import_status_counts" => %{
          "missing" => 1,
          "not_applicable" => 1,
          "present" => 1
        },
        "row_derived_cadence_import_status_counts" => %{
          "missing" => 1,
          "not_applicable" => 1,
          "present" => 1
        },
        "required_operator_action_counts" => %{
          "monitor_activity" => 1,
          "review_timeline_integrity" => 2
        },
        "row_derived_required_operator_action_counts" => %{
          "monitor_activity" => 1,
          "review_timeline_integrity" => 2
        },
        "timeline_integrity_issue_type_counts" => %{
          "dependency_order_violation" => 1,
          "exclusivity_group_overlap" => 2,
          "exclusivity_overlap" => 1,
          "missing_dependency_activity" => 1
        },
        "row_derived_timeline_integrity_issue_type_counts" => %{
          "dependency_order_violation" => 1,
          "exclusivity_group_overlap" => 2,
          "exclusivity_overlap" => 1,
          "missing_dependency_activity" => 1
        },
        "timeline_row_ids_by_required_operator_action" => %{
          "monitor_activity" => ["timeline_row:1:health_1"],
          "review_timeline_integrity" => ["timeline_row:2:cmd_1", "timeline_row:3:dl_1"]
        },
        "row_derived_timeline_row_ids_by_required_operator_action" => %{
          "monitor_activity" => ["timeline_row:1:health_1"],
          "review_timeline_integrity" => ["timeline_row:2:cmd_1", "timeline_row:3:dl_1"]
        },
        "timeline_row_ids_by_integrity_status" => %{
          "none" => ["timeline_row:1:health_1"],
          "review_required" => ["timeline_row:2:cmd_1", "timeline_row:3:dl_1"]
        },
        "row_derived_timeline_row_ids_by_integrity_status" => %{
          "none" => ["timeline_row:1:health_1"],
          "review_required" => ["timeline_row:2:cmd_1", "timeline_row:3:dl_1"]
        },
        "execution_boundary" => "planned_not_commanded",
        "missing_dependency_validation" => "enabled",
        "model_limit_count" => 4
      },
      "tolerances" => %{
        "activity_count" => 0,
        "row_count" => 0,
        "contact_count" => 0,
        "command_count" => 0,
        "approved_count" => 0,
        "executed_count" => 0,
        "locked_count" => 0,
        "terminal_exception_count" => 0,
        "dependency_count" => 0,
        "dependency_issue_count" => 0,
        "exclusivity_count" => 0,
        "exclusivity_issue_count" => 0,
        "timeline_integrity_issue_count" => 0,
        "timeline_integrity_review_count" => 0,
        "duplicate_timeline_identity_count" => 0,
        "duplicate_timeline_identity_activity_count" => 0,
        "source_window_lineage_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external operations validation",
        "checks operational timeline counts, integrity review routing, and no-command boundary only"
      ]
    }
  }

  def all, do: @fixtures
end
