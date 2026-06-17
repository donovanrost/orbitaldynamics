defmodule OrbitalDynamics.Schema.TimelineReportContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  test "validates standalone timeline diff report contracts" do
    report = %{
      "schema_contract" => "timeline_diff_report.v1",
      "model" => "timeline_identity_activity_diff",
      "source" => "repair.activities",
      "source_activity_count" => 1,
      "replacement_activity_count" => 1,
      "row_count" => 1,
      "added_count" => 0,
      "removed_count" => 0,
      "changed_count" => 1,
      "unchanged_count" => 0,
      "review_required_count" => 1,
      "diff_status_counts" => %{"changed" => 1},
      "required_operator_action_counts" => %{"review_timeline_change" => 1},
      "transition_decision_counts" => %{"review" => 1},
      "changed_field_counts" => %{"activity_id" => 1, "starts_at_s" => 1},
      "status_transition_counts" => %{"changed" => 1},
      "approval_transition_counts" => %{"changed" => 1},
      "status_transition_category_counts" => %{"status_changed" => 1},
      "approval_transition_category_counts" => %{"approval_review_required" => 1},
      "duplicate_timeline_identity_count" => 0,
      "duplicate_source_timeline_identity_count" => 0,
      "duplicate_replacement_timeline_identity_count" => 0,
      "rows" => [
        %{
          "id" => "timeline_diff:timeline:obs_1",
          "rank" => 1,
          "timeline_id" => "timeline:obs_1",
          "diff_status" => "changed",
          "source_activity_id" => "obs_1",
          "replacement_activity_id" => "obs_1b",
          "source_activity_type" => "observe",
          "replacement_activity_type" => "observe",
          "scenario_id" => "leo_1",
          "source_starts_at_s" => 10.0,
          "replacement_starts_at_s" => 12.0,
          "start_delta_s" => 2.0,
          "changed_fields" => ["activity_id", "starts_at_s"],
          "transition_decision" => "review",
          "transition_decision_reason" => "changed row requires operator review",
          "status_transition" => %{
            "field" => "status",
            "transition_type" => "changed",
            "transition_category" => "status_changed"
          },
          "approval_transition" => %{
            "field" => "approval_status",
            "transition_type" => "changed",
            "transition_category" => "approval_review_required"
          },
          "requires_operator_review" => true,
          "required_operator_action" => "review_timeline_change",
          "reason" => "timing changed",
          "source_activity_context" => %{
            "activity_id" => "obs_1",
            "timeline_id" => "timeline:obs_1"
          },
          "replacement_activity_context" => %{
            "activity_id" => "obs_1b",
            "timeline_id" => "timeline:obs_1"
          },
          "source_protection_category" => "locked_or_approved",
          "source_protection_decision" => %{"protection_decision" => "preserve"},
          "source_protection_reason" => "activity_locked_or_approved",
          "replacement_protection_category" => "none",
          "replacement_protection_decision" => %{"protection_decision" => "mutable"},
          "replacement_protection_reason" => "no_timeline_protection",
          "source_timeline_identity" => %{"timeline_id" => "timeline:obs_1"},
          "replacement_timeline_identity" => %{"timeline_id" => "timeline:obs_1"}
        }
      ],
      "assumptions" => %{"execution_boundary" => "artifact_only_no_schedule_mutation"}
    }

    assert {:ok, %{"schema_contract" => "timeline_diff_report.v1"}} =
             Schema.validate_artifact(report)

    invalid_model = Map.put(report, "model", "timeline_diff_v0")

    assert {:error, invalid_model_report} = Schema.validate_artifact(invalid_model)

    assert Enum.any?(
             invalid_model_report["errors"],
             &(&1["path"] == "$.model" and
                 &1["message"] == "must equal \"timeline_identity_activity_diff\"")
           )

    invalid = put_in(report, ["rows", Access.at(0), "diff_status"], "mystery")

    assert {:error, validation_report} = Schema.validate_artifact(invalid)
    assert Enum.any?(validation_report["errors"], &(&1["path"] == "$.rows[0].diff_status"))

    invalid_context = put_in(report, ["rows", Access.at(0), "source_activity_context"], "opaque")

    assert {:error, context_report} = Schema.validate_artifact(invalid_context)

    assert Enum.any?(
             context_report["errors"],
             &(&1["path"] == "$.rows[0].source_activity_context")
           )

    invalid_context_id =
      put_in(
        report,
        ["rows", Access.at(0), "source_activity_context", "dependency_activity_ids"],
        ["valid_dependency", "bad dependency"]
      )

    assert {:error, context_id_report} = Schema.validate_artifact(invalid_context_id)

    assert Enum.any?(
             context_id_report["errors"],
             &(&1["path"] == "$.rows[0].source_activity_context.dependency_activity_ids[1]")
           )

    invalid_protection_decision =
      put_in(report, ["rows", Access.at(0), "source_protection_decision", "locked"], "yes")

    assert {:error, protection_decision_report} =
             Schema.validate_artifact(invalid_protection_decision)

    assert Enum.any?(
             protection_decision_report["errors"],
             &(&1["path"] == "$.rows[0].source_protection_decision.locked")
           )

    invalid_status_transition =
      put_in(report, ["rows", Access.at(0), "status_transition"], %{
        "transition_type" => "teleport"
      })

    assert {:error, status_transition_report} =
             Schema.validate_artifact(invalid_status_transition)

    assert Enum.any?(
             status_transition_report["errors"],
             &(&1["path"] == "$.rows[0].status_transition.transition_type")
           )

    invalid_timeline_identity =
      put_in(report, ["rows", Access.at(0), "source_timeline_identity", "timeline_id"], "bad id")

    assert {:error, timeline_identity_report} =
             Schema.validate_artifact(invalid_timeline_identity)

    assert Enum.any?(
             timeline_identity_report["errors"],
             &(&1["path"] == "$.rows[0].source_timeline_identity.timeline_id")
           )

    invalid_counts = Map.put(report, "diff_status_counts", ["changed"])

    assert {:error, counts_report} = Schema.validate_artifact(invalid_counts)
    assert Enum.any?(counts_report["errors"], &(&1["path"] == "$.diff_status_counts"))

    invalid_row_derived_counts =
      put_in(report, ["transition_decision_counts", "review"], 99)

    assert {:error, row_derived_counts_report} =
             Schema.validate_artifact(invalid_row_derived_counts)

    assert Enum.any?(
             row_derived_counts_report["errors"],
             &(&1["path"] == "$.transition_decision_counts")
           )

    float_source_count = Map.put(report, "source_activity_count", 1.0)

    assert {:error, float_source_count_report} = Schema.validate_artifact(float_source_count)

    assert Enum.any?(
             float_source_count_report["errors"],
             &(&1["path"] == "$.source_activity_count")
           )

    negative_added_count = Map.put(report, "added_count", -1)

    assert {:error, negative_added_count_report} =
             Schema.validate_artifact(negative_added_count)

    assert Enum.any?(
             negative_added_count_report["errors"],
             &(&1["path"] == "$.added_count")
           )

    negative_source_duplicate_count =
      put_in(report, ["rows", Access.at(0), "source_duplicate_activity_count"], -1)

    assert {:error, negative_source_duplicate_count_report} =
             Schema.validate_artifact(negative_source_duplicate_count)

    assert Enum.any?(
             negative_source_duplicate_count_report["errors"],
             &(&1["path"] == "$.rows[0].source_duplicate_activity_count")
           )

    negative_duplicate_identity_count =
      Map.put(report, "duplicate_timeline_identity_count", -1)

    assert {:error, negative_duplicate_identity_count_report} =
             Schema.validate_artifact(negative_duplicate_identity_count)

    assert Enum.any?(
             negative_duplicate_identity_count_report["errors"],
             &(&1["path"] == "$.duplicate_timeline_identity_count")
           )
  end

  test "validates checked-in timeline diff report fixture" do
    report = read_json!("study_results/timeline_diff_report_v1.json")

    source = [
      %{
        id: :obs_1,
        type: :observe,
        scenario_id: :leo_1,
        spacecraft_id: :leo_1,
        target_id: :target_a,
        source_window_id: :target_a_window_1,
        starts_at_s: 10.0,
        ends_at_s: 20.0,
        status: :approved,
        approval_status: :approved,
        metadata: %{timeline_id: :"timeline:obs_1"}
      },
      %{
        id: :dl_removed,
        type: :downlink,
        scenario_id: :leo_1,
        spacecraft_id: :leo_1,
        ground_station_id: :dss_14,
        source_window_id: :dss_14_pass_removed,
        starts_at_s: 30.0,
        ends_at_s: 40.0,
        metadata: %{timeline_id: :"timeline:dl_removed"}
      },
      %{
        id: :raise_apogee,
        type: :impulsive_burn,
        scenario_id: :leo_1,
        starts_at_s: 60.0,
        ends_at_s: 60.0,
        execution_uncertainty: %{
          timing_3sigma_s: 1,
          delta_v_3sigma_km_s: [0, 0.0001, 0],
          source: :operator_estimate
        },
        metadata: %{timeline_id: :"timeline:raise_apogee"}
      }
    ]

    replacement = [
      %{
        id: :obs_1b,
        type: :observe,
        scenario_id: :leo_1,
        spacecraft_id: :leo_1,
        target_id: :target_a,
        source_window_id: :target_a_window_1,
        starts_at_s: 12.0,
        ends_at_s: 22.0,
        status: :planned,
        approval_status: :pending,
        metadata: %{timeline_id: :"timeline:obs_1"}
      },
      %{
        id: :cmd_added,
        type: :command,
        scenario_id: :leo_1,
        spacecraft_id: :leo_1,
        ground_station_id: :dss_14,
        source_window_id: :dss_14_pass_added,
        starts_at_s: 50.0,
        ends_at_s: 55.0,
        metadata: %{timeline_id: :"timeline:cmd_added"}
      },
      %{
        id: :raise_apogee,
        type: :impulsive_burn,
        scenario_id: :leo_1,
        starts_at_s: 60.0,
        ends_at_s: 60.0,
        execution_uncertainty: %{
          timing_3sigma_s: 3,
          delta_v_3sigma_km_s: [0, 0.0003, 0],
          source: :navigation_update
        },
        metadata: %{timeline_id: :"timeline:raise_apogee"}
      }
    ]

    generated_report =
      OrbitalDynamics.timeline_diff_report(source, replacement, source: "repair.activities")

    assert generated_report == report

    assert {:ok, %{"schema_contract" => "timeline_diff_report.v1"}} =
             Schema.validate_artifact(report)

    assert %{
             "schema_contract" => "timeline_diff_report.v1",
             "model" => "timeline_identity_activity_diff",
             "source" => "repair.activities",
             "source_activity_count" => 3,
             "replacement_activity_count" => 3,
             "valid_source_activity_count" => 3,
             "valid_replacement_activity_count" => 3,
             "invalid_source_activity_input_count" => 0,
             "invalid_replacement_activity_input_count" => 0,
             "invalid_source_activity_input_ids" => [],
             "invalid_replacement_activity_input_ids" => [],
             "row_count" => 4,
             "added_count" => 1,
             "removed_count" => 1,
             "changed_count" => 2,
             "unchanged_count" => 0,
             "review_required_count" => 4,
             "duplicate_timeline_identity_count" => 0,
             "duplicate_source_timeline_identity_count" => 0,
             "duplicate_replacement_timeline_identity_count" => 0,
             "diff_status_counts" => %{"added" => 1, "changed" => 2, "removed" => 1},
             "transition_decision_counts" => %{"preserve_source" => 1, "review" => 3},
             "required_operator_action_counts" => %{
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
             "status_transition_counts" => %{"added" => 1, "changed" => 1, "removed" => 1},
             "approval_transition_counts" => %{"added" => 1, "changed" => 1, "removed" => 1},
             "status_transition_category_counts" => %{
               "status_added" => 1,
               "status_changed" => 1,
               "status_removed" => 1
             },
             "approval_transition_category_counts" => %{
               "approval_regressed" => 1,
               "approval_removed" => 1,
               "approval_review_required" => 1
             },
             "model_limits" => [
               "artifact_level_only",
               "no_schedule_mutation",
               "no_command_execution",
               "derived_identity_when_no_persistent_timeline_id"
             ],
             "assumptions" => %{
               "comparison" =>
                 "activity identity, timing, status, approval, lock, contact, execution uncertainty, lineage, and typed status transitions",
               "duplicate_timeline_identity" =>
                 "duplicate timeline identities are preserved as operator-review collision rows",
               "execution_boundary" => "artifact_only_no_schedule_mutation",
               "identity_match" =>
                 "timeline_id derived from persistent metadata or activity context",
               "invalid_activity_input" =>
                 "source and replacement inputs missing stable identity or activity type are preserved as reviewable diff rows",
               "missing_dependency_validation" => "disabled",
               "timeline_integrity" =>
                 "source and replacement dependency/exclusivity integrity issues are preserved as reviewable diff rows"
             }
           } = report

    rows_by_timeline_id = Map.new(report["rows"], &{&1["timeline_id"], &1})

    assert %{
             "diff_status" => "added",
             "changed_fields" => ["timeline_presence"],
             "required_operator_action" => "review_added_activity",
             "transition_decision" => "review",
             "status_transition" => %{"transition_category" => "status_added"},
             "approval_transition" => %{"transition_category" => "approval_review_required"}
           } = rows_by_timeline_id["timeline:cmd_added"]

    assert %{
             "diff_status" => "removed",
             "changed_fields" => ["timeline_presence"],
             "required_operator_action" => "review_removed_activity",
             "transition_decision" => "review",
             "status_transition" => %{"transition_category" => "status_removed"},
             "approval_transition" => %{"transition_category" => "approval_removed"}
           } = rows_by_timeline_id["timeline:dl_removed"]

    assert %{
             "diff_status" => "changed",
             "changed_fields" => [
               "activity_id",
               "status",
               "approval_status",
               "starts_at_s",
               "ends_at_s"
             ],
             "required_operator_action" => "review_changed_protected_activity",
             "transition_decision" => "preserve_source",
             "status_transition" => %{"transition_category" => "status_changed"},
             "approval_transition" => %{"transition_category" => "approval_regressed"}
           } = rows_by_timeline_id["timeline:obs_1"]

    assert %{
             "diff_status" => "changed",
             "changed_fields" => ["execution_uncertainty"],
             "required_operator_action" => "review_timeline_change",
             "transition_decision" => "review",
             "source_activity_context" => %{
               "execution_uncertainty_status" => "declared",
               "timing_3sigma_s" => 1,
               "execution_uncertainty_source" => "operator_estimate"
             },
             "replacement_activity_context" => %{
               "execution_uncertainty_status" => "declared",
               "timing_3sigma_s" => 3,
               "execution_uncertainty_source" => "navigation_update"
             }
           } = rows_by_timeline_id["timeline:raise_apogee"]
  end

  test "exports timeline diff top-level count-map contract fields" do
    assert {:ok, schema} = Schema.json_schema("timeline_diff_report.v1")

    assert get_in(schema, ["properties", "model", "const"]) == "timeline_identity_activity_diff"

    assert get_in(schema, [
             "properties",
             "diff_status_counts",
             "propertyNames",
             "enum"
           ]) == OrbitalDynamics.Timeline.capabilities().timeline_diff_statuses

    assert get_in(schema, [
             "properties",
             "required_operator_action_counts",
             "propertyNames",
             "enum"
           ]) == OrbitalDynamics.Timeline.capabilities().timeline_diff_required_operator_actions

    assert get_in(schema, [
             "properties",
             "transition_decision_counts",
             "propertyNames",
             "enum"
           ]) == OrbitalDynamics.Timeline.capabilities().transition_decisions

    assert get_in(schema, [
             "properties",
             "status_transition_counts",
             "propertyNames",
             "enum"
           ]) == OrbitalDynamics.Timeline.capabilities().lifecycle_transition_types

    assert get_in(schema, [
             "properties",
             "approval_transition_category_counts",
             "propertyNames",
             "enum"
           ]) == OrbitalDynamics.Timeline.capabilities().approval_transition_categories

    assert get_in(schema, [
             "properties",
             "changed_field_counts",
             "additionalProperties"
           ]) == %{"type" => "integer", "minimum" => 0}

    assert get_in(schema, ["properties", "source_activity_count"]) ==
             %{"type" => "integer", "minimum" => 0}

    assert get_in(schema, ["properties", "review_required_count"]) ==
             %{"type" => "integer", "minimum" => 0}

    assert get_in(schema, ["properties", "duplicate_timeline_identity_count"]) ==
             %{"type" => "integer", "minimum" => 0}

    assert get_in(schema, ["properties", "duplicate_source_timeline_identity_count"]) ==
             %{"type" => "integer", "minimum" => 0}

    assert get_in(schema, ["properties", "duplicate_replacement_timeline_identity_count"]) ==
             %{"type" => "integer", "minimum" => 0}

    assert get_in(schema, [
             "properties",
             "rows",
             "items",
             "properties",
             "source_duplicate_activity_count"
           ]) == %{"type" => "integer", "minimum" => 0}
  end

  test "validates standalone timeline transition application report contracts" do
    source_diff = %{
      "id" => "timeline_diff:timeline:obs_1",
      "rank" => 1,
      "timeline_id" => "timeline:obs_1",
      "diff_status" => "changed",
      "source_activity_id" => "obs_1",
      "replacement_activity_id" => "obs_1b",
      "changed_fields" => ["starts_at_s"],
      "status_transition" => %{
        "field" => "status",
        "transition_type" => "changed",
        "transition_category" => "status_changed"
      },
      "approval_transition" => %{
        "field" => "approval_status",
        "transition_type" => "changed",
        "transition_category" => "approval_review_required"
      },
      "requires_operator_review" => true,
      "required_operator_action" => "review_timeline_change",
      "reason" => "timing changed",
      "timeline_identity_collision" => true,
      "duplicate_timeline_identity_scope" => "source",
      "source_duplicate_activity_count" => 2,
      "replacement_duplicate_activity_count" => 1,
      "source_duplicate_activity_ids" => ["obs_1", "obs_1_shadow"],
      "replacement_duplicate_activity_ids" => ["obs_1b"],
      "source_duplicate_activities" => [%{"activity_id" => "obs_1"}],
      "replacement_duplicate_activities" => [%{"activity_id" => "obs_1b"}]
    }

    report = %{
      "schema_contract" => "timeline_transition_application_report.v1",
      "model" => "artifact_only_timeline_transition_application",
      "source" => "repair.activities",
      "source_activity_count" => 1,
      "replacement_activity_count" => 1,
      "application_count" => 1,
      "selected_activity_count" => 1,
      "review_required_count" => 1,
      "application_status_counts" => %{"operator_review_required" => 1},
      "transition_decision_counts" => %{"review" => 1},
      "required_operator_action_counts" => %{"review_timeline_change" => 1},
      "status_transition_counts" => %{"changed" => 1},
      "approval_transition_counts" => %{"changed" => 1},
      "status_transition_category_counts" => %{"status_changed" => 1},
      "approval_transition_category_counts" => %{"approval_review_required" => 1},
      "preserved_source_count" => 0,
      "recorded_replacement_count" => 0,
      "withheld_review_count" => 1,
      "selected_activities" => [
        %{
          "activity_id" => "obs_1",
          "timeline_id" => "timeline:obs_1",
          "activity_type" => "observation",
          "status" => "planned",
          "approval_status" => "not_evaluated",
          "locked" => false,
          "operational_kind" => "observation",
          "required_operator_action" => "review_activity_approval",
          "execution_boundary" => "planned_not_commanded",
          "cadence_import_status" => "not_applicable",
          "starts_at_s" => 100.0,
          "ends_at_s" => 120.0,
          "target_id" => "target:obs_1",
          "approved" => false,
          "has_source_window" => false,
          "has_cadence_import" => false,
          "timeline_identity" => %{
            "timeline_id" => "timeline:obs_1",
            "source" => "provided"
          },
          "activity_context" => %{"target_id" => "target:obs_1"},
          "protection_decision" => "mutable",
          "protection_category" => "none",
          "protection_reason" => "activity is mutable"
        }
      ],
      "model_limits" => OrbitalDynamics.Timeline.model_limits(),
      "applications" => [
        Map.merge(source_diff, %{
          "transition_decision" => "review",
          "application_status" => "operator_review_required",
          "source_protection_decision" => %{
            "protection_decision" => "mutable",
            "protection_category" => "none"
          },
          "replacement_protection_decision" => %{
            "protection_decision" => "mutable",
            "protection_category" => "none"
          },
          "source_timeline_diff" => source_diff
        })
      ],
      "assumptions" => %{"execution_boundary" => "artifact_only_no_schedule_mutation"}
    }

    assert {:ok, %{"schema_contract" => "timeline_transition_application_report.v1"}} =
             Schema.validate_artifact(report)

    invalid_model = Map.put(report, "model", "stale_transition_application_model")

    assert {:error, model_report} = Schema.validate_artifact(invalid_model)

    assert Enum.any?(
             model_report["errors"],
             &(&1["path"] == "$.model" and
                 &1["message"] ==
                   "must equal \"artifact_only_timeline_transition_application\"")
           )

    stale_model_limits = Map.put(report, "model_limits", ["artifact_level_only"])

    assert {:error, model_limits_report} = Schema.validate_artifact(stale_model_limits)

    assert Enum.any?(
             model_limits_report["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] == "must match timeline report model limits")
           )

    invalid =
      put_in(report, ["applications", Access.at(0), "source_timeline_diff", "diff_status"], "x")

    assert {:error, validation_report} = Schema.validate_artifact(invalid)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.applications[0].source_timeline_diff.diff_status")
           )

    invalid_protection_decision =
      put_in(report, ["applications", Access.at(0), "source_protection_decision"], "preserve")

    assert {:error, protection_report} = Schema.validate_artifact(invalid_protection_decision)

    assert Enum.any?(
             protection_report["errors"],
             &(&1["path"] == "$.applications[0].source_protection_decision")
           )

    invalid_nested_protection_decision =
      put_in(
        report,
        ["applications", Access.at(0), "source_protection_decision", "approved"],
        "false"
      )

    assert {:error, nested_protection_report} =
             Schema.validate_artifact(invalid_nested_protection_decision)

    assert Enum.any?(
             nested_protection_report["errors"],
             &(&1["path"] == "$.applications[0].source_protection_decision.approved")
           )

    invalid_transition =
      put_in(
        report,
        ["applications", Access.at(0), "status_transition", "requires_operator_review"],
        "yes"
      )

    assert {:error, transition_report} = Schema.validate_artifact(invalid_transition)

    assert Enum.any?(
             transition_report["errors"],
             &(&1["path"] == "$.applications[0].status_transition.requires_operator_review")
           )

    invalid_selected_activity =
      put_in(report, ["selected_activities", Access.at(0), "timeline_identity"], "timeline:obs_1")

    assert {:error, selected_activity_report} =
             Schema.validate_artifact(invalid_selected_activity)

    assert Enum.any?(
             selected_activity_report["errors"],
             &(&1["path"] == "$.selected_activities[0].timeline_identity")
           )

    negative_selected_activity_integrity_count =
      put_in(report, ["selected_activities", Access.at(0), "timeline_integrity_issue_count"], -1)

    assert {:error, negative_selected_activity_integrity_count_report} =
             Schema.validate_artifact(negative_selected_activity_integrity_count)

    assert Enum.any?(
             negative_selected_activity_integrity_count_report["errors"],
             &(&1["path"] == "$.selected_activities[0].timeline_integrity_issue_count")
           )

    negative_selected_application_integrity_count =
      put_in(
        report,
        ["applications", Access.at(0), "selected_timeline_integrity_issue_count"],
        -1
      )

    assert {:error, negative_selected_application_integrity_count_report} =
             Schema.validate_artifact(negative_selected_application_integrity_count)

    assert Enum.any?(
             negative_selected_application_integrity_count_report["errors"],
             &(&1["path"] == "$.applications[0].selected_timeline_integrity_issue_count")
           )

    negative_selected_report_integrity_count =
      Map.put(report, "selected_timeline_integrity_issue_count", -1)

    assert {:error, negative_selected_report_integrity_count_report} =
             Schema.validate_artifact(negative_selected_report_integrity_count)

    assert Enum.any?(
             negative_selected_report_integrity_count_report["errors"],
             &(&1["path"] == "$.selected_timeline_integrity_issue_count")
           )

    stale_selected_report_integrity_types =
      Map.put(report, "selected_timeline_integrity_issue_types", ["missing_dependency_timeline"])

    assert {:error, stale_selected_report_integrity_types_report} =
             Schema.validate_artifact(stale_selected_report_integrity_types)

    assert Enum.any?(
             stale_selected_report_integrity_types_report["errors"],
             &(&1["path"] == "$.selected_timeline_integrity_issue_types" and
                 &1["message"] ==
                   "must equal selected-activity-derived selected_timeline_integrity_issue_types")
           )

    negative_application_duplicate_count =
      put_in(report, ["applications", Access.at(0), "source_duplicate_activity_count"], -1)

    assert {:error, negative_application_duplicate_count_report} =
             Schema.validate_artifact(negative_application_duplicate_count)

    assert Enum.any?(
             negative_application_duplicate_count_report["errors"],
             &(&1["path"] == "$.applications[0].source_duplicate_activity_count")
           )

    invalid_counts =
      put_in(report, ["application_status_counts", "operator_review_required"], 99)

    assert {:error, counts_report} = Schema.validate_artifact(invalid_counts)

    assert Enum.any?(
             counts_report["errors"],
             &(&1["path"] == "$.application_status_counts")
           )

    invalid_transition_counts = put_in(report, ["status_transition_counts"], %{"changed" => 2})

    assert {:error, transition_counts_report} =
             Schema.validate_artifact(invalid_transition_counts)

    assert Enum.any?(
             transition_counts_report["errors"],
             &(&1["path"] == "$.status_transition_counts")
           )

    float_transition_counts =
      put_in(report, ["status_transition_counts"], %{"changed" => 1.0})

    assert {:error, float_transition_counts_report} =
             Schema.validate_artifact(float_transition_counts)

    assert Enum.any?(
             float_transition_counts_report["errors"],
             &(&1["path"] == "$.status_transition_counts.changed")
           )

    negative_application_status_counts =
      put_in(report, ["application_status_counts"], %{"operator_review_required" => -1})

    assert {:error, negative_application_status_counts_report} =
             Schema.validate_artifact(negative_application_status_counts)

    assert Enum.any?(
             negative_application_status_counts_report["errors"],
             &(&1["path"] == "$.application_status_counts.operator_review_required")
           )

    float_application_count = Map.put(report, "application_count", 1.0)

    assert {:error, float_application_count_report} =
             Schema.validate_artifact(float_application_count)

    assert Enum.any?(
             float_application_count_report["errors"],
             &(&1["path"] == "$.application_count")
           )

    negative_preserved_source_count = Map.put(report, "preserved_source_count", -1)

    assert {:error, negative_preserved_source_count_report} =
             Schema.validate_artifact(negative_preserved_source_count)

    assert Enum.any?(
             negative_preserved_source_count_report["errors"],
             &(&1["path"] == "$.preserved_source_count")
           )
  end

  test "validates checked-in timeline transition application report fixture" do
    report = read_json!("study_results/timeline_transition_application_report_v1.json")

    protected_source = %{
      id: :cmd_lock,
      type: :command,
      status: :planned,
      approval_status: :approved,
      locked: true,
      starts_at_s: 10.0,
      ends_at_s: 20.0,
      metadata: %{timeline_id: :"timeline:cmd_lock"}
    }

    protected_replacement = %{
      id: :cmd_lock,
      type: :command,
      status: :planned,
      approval_status: :approved,
      locked: true,
      starts_at_s: 15.0,
      ends_at_s: 25.0,
      metadata: %{timeline_id: :"timeline:cmd_lock"}
    }

    unchanged = %{
      id: :obs_keep,
      type: :observe,
      target_id: :target_a,
      starts_at_s: 30.0,
      ends_at_s: 40.0,
      metadata: %{timeline_id: :"timeline:obs_keep"}
    }

    removed = %{
      id: :old_contact,
      type: :planned_contact,
      ground_station_id: :dss_14,
      starts_at_s: 50.0,
      ends_at_s: 60.0,
      metadata: %{timeline_id: :"timeline:old_contact"}
    }

    added = %{
      id: :new_cmd,
      type: :command,
      starts_at_s: 70.0,
      ends_at_s: 80.0,
      metadata: %{timeline_id: :"timeline:new_cmd"}
    }

    generated_report =
      OrbitalDynamics.timeline_transition_application_report(
        [protected_source, unchanged, removed],
        [protected_replacement, unchanged, added],
        source: "fixture.timeline.transition_application"
      )

    assert generated_report == report

    assert {:ok, %{"schema_contract" => "timeline_transition_application_report.v1"}} =
             Schema.validate_artifact(report)

    assert %{
             "schema_contract" => "timeline_transition_application_report.v1",
             "model" => "artifact_only_timeline_transition_application",
             "source" => "fixture.timeline.transition_application",
             "source_activity_count" => 3,
             "replacement_activity_count" => 3,
             "application_count" => 4,
             "selected_activity_count" => 2,
             "review_required_count" => 3,
             "preserved_source_count" => 1,
             "recorded_replacement_count" => 0,
             "withheld_review_count" => 2,
             "selected_timeline_integrity_issue_count" => 0,
             "selected_timeline_integrity_review_count" => 0,
             "selected_timeline_integrity_issue_types" => [],
             "application_status_counts" => %{
               "operator_review_required" => 2,
               "source_preserved_pending_review" => 1,
               "source_unchanged" => 1
             },
             "transition_decision_counts" => %{
               "none" => 1,
               "preserve_source" => 1,
               "review" => 2
             },
             "required_operator_action_counts" => %{
               "none" => 1,
               "review_added_activity" => 1,
               "review_changed_protected_activity" => 1,
               "review_removed_activity" => 1
             },
             "status_transition_counts" => %{"added" => 1, "removed" => 1},
             "approval_transition_counts" => %{"added" => 1, "removed" => 1},
             "status_transition_category_counts" => %{
               "status_added" => 1,
               "status_removed" => 1
             },
             "approval_transition_category_counts" => %{
               "approval_removed" => 1,
               "approval_review_required" => 1
             },
             "model_limits" => [
               "artifact_level_only",
               "no_schedule_mutation",
               "no_command_execution",
               "derived_identity_when_no_persistent_timeline_id"
             ],
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_schedule_mutation",
               "review_gate" =>
                 "review-required transitions withhold replacement selection until an operator decision",
               "selected_missing_dependency_validation" => "enabled",
               "selected_timeline_integrity" =>
                 "selected activities are rechecked as their own artifact-only timeline subset because withheld review rows can remove dependencies",
               "selection" =>
                 "only unchanged, recordable, or preserved protected activities are selected automatically"
             }
           } = report

    assert Enum.map(report["applications"], &{&1["timeline_id"], &1["application_status"]}) == [
             {"timeline:cmd_lock", "source_preserved_pending_review"},
             {"timeline:new_cmd", "operator_review_required"},
             {"timeline:obs_keep", "source_unchanged"},
             {"timeline:old_contact", "operator_review_required"}
           ]

    assert %{
             "timeline_id" => "timeline:cmd_lock",
             "transition_decision" => "preserve_source",
             "required_operator_action" => "review_changed_protected_activity",
             "selected_activity_source" => "source",
             "selected_activity" => %{
               "activity_id" => "cmd_lock",
               "precondition_status" => "clear",
               "blocked_precondition_count" => 0,
               "blocked_precondition_types" => [],
               "review_precondition_count" => 0,
               "review_precondition_types" => [],
               "protection_decision" => "preserve"
             },
             "source_timeline_diff" => %{
               "diff_status" => "changed",
               "changed_fields" => ["starts_at_s", "ends_at_s"],
               "requires_operator_review" => true
             }
           } = Enum.find(report["applications"], &(&1["timeline_id"] == "timeline:cmd_lock"))

    assert %{
             "timeline_id" => "timeline:new_cmd",
             "transition_decision" => "review",
             "required_operator_action" => "review_added_activity",
             "source_timeline_diff" => %{
               "diff_status" => "added",
               "status_transition" => %{"transition_category" => "status_added"},
               "approval_transition" => %{"transition_category" => "approval_review_required"}
             }
           } = Enum.find(report["applications"], &(&1["timeline_id"] == "timeline:new_cmd"))

    assert %{
             "timeline_id" => "timeline:old_contact",
             "transition_decision" => "review",
             "required_operator_action" => "review_removed_activity",
             "source_timeline_diff" => %{
               "diff_status" => "removed",
               "status_transition" => %{"transition_category" => "status_removed"},
               "approval_transition" => %{"transition_category" => "approval_removed"}
             }
           } = Enum.find(report["applications"], &(&1["timeline_id"] == "timeline:old_contact"))

    assert [
             %{
               "activity_id" => "cmd_lock",
               "precondition_status" => "clear",
               "blocked_precondition_count" => 0,
               "review_precondition_count" => 0
             },
             %{
               "activity_id" => "obs_keep",
               "precondition_status" => "clear",
               "blocked_precondition_count" => 0,
               "review_precondition_count" => 0
             }
           ] = report["selected_activities"]
  end

  test "validates checked-in timeline transition application selected integrity fixture" do
    report =
      read_json!("study_results/timeline_transition_application_selected_integrity_v1.json")

    dependency = %{
      id: :cmd_prereq,
      type: :command,
      status: :planned,
      approval_status: :pending,
      starts_at_s: 0.0,
      ends_at_s: 5.0,
      metadata: %{timeline_id: :"timeline:cmd_prereq"}
    }

    protected_source = %{
      id: :cmd_lock,
      type: :command,
      status: :planned,
      approval_status: :approved,
      locked: true,
      starts_at_s: 10.0,
      ends_at_s: 20.0,
      depends_on: [:cmd_prereq],
      metadata: %{timeline_id: :"timeline:cmd_lock"}
    }

    protected_replacement = %{
      id: :cmd_lock,
      type: :command,
      status: :planned,
      approval_status: :approved,
      locked: true,
      starts_at_s: 12.0,
      ends_at_s: 22.0,
      depends_on: [:cmd_prereq],
      metadata: %{timeline_id: :"timeline:cmd_lock"}
    }

    generated_report =
      OrbitalDynamics.timeline_transition_application_report(
        [dependency, protected_source],
        [protected_replacement],
        source: "fixture.timeline.transition_application.selected_integrity"
      )

    assert generated_report == report

    assert {:ok, %{"schema_contract" => "timeline_transition_application_report.v1"}} =
             Schema.validate_artifact(report)

    assert %{
             "schema_contract" => "timeline_transition_application_report.v1",
             "model" => "artifact_only_timeline_transition_application",
             "source" => "fixture.timeline.transition_application.selected_integrity",
             "source_activity_count" => 2,
             "replacement_activity_count" => 1,
             "application_count" => 2,
             "selected_activity_count" => 1,
             "review_required_count" => 2,
             "preserved_source_count" => 1,
             "withheld_review_count" => 1,
             "selected_timeline_integrity_issue_count" => 1,
             "selected_timeline_integrity_review_count" => 1,
             "selected_timeline_integrity_issue_types" => ["missing_dependency_activity"],
             "application_status_counts" => %{
               "operator_review_required" => 1,
               "source_preserved_pending_review" => 1
             },
             "required_operator_action_counts" => %{
               "review_changed_protected_activity" => 1,
               "review_removed_activity" => 1
             }
           } = report

    assert [
             %{
               "timeline_id" => "timeline:cmd_lock",
               "application_status" => "source_preserved_pending_review",
               "required_operator_action" => "review_changed_protected_activity",
               "selected_timeline_integrity_status" => "review_required",
               "selected_timeline_integrity_issue_types" => ["missing_dependency_activity"],
               "selected_missing_dependency_activity_ids" => ["cmd_prereq"],
               "selected_activity" => %{
                 "activity_id" => "cmd_lock",
                 "timeline_integrity_status" => "review_required",
                 "missing_dependency_activity_ids" => ["cmd_prereq"]
               }
             },
             %{
               "timeline_id" => "timeline:cmd_prereq",
               "application_status" => "operator_review_required",
               "required_operator_action" => "review_removed_activity"
             }
           ] = report["applications"]
  end

  test "validates nested timeline transition applications in review and import handoffs" do
    source_diff = %{
      "id" => "timeline_diff:timeline:obs_1",
      "rank" => 1,
      "timeline_id" => "timeline:obs_1",
      "diff_status" => "changed",
      "source_activity_id" => "obs_1",
      "replacement_activity_id" => "obs_1b",
      "changed_fields" => ["starts_at_s"],
      "requires_operator_review" => true,
      "required_operator_action" => "review_timeline_change",
      "reason" => "timing changed"
    }

    report = %{
      "schema_contract" => "timeline_transition_application_report.v1",
      "model" => "artifact_only_timeline_transition_application",
      "source" => "repair.activities",
      "source_activity_count" => 1,
      "replacement_activity_count" => 1,
      "application_count" => 1,
      "selected_activity_count" => 0,
      "review_required_count" => 1,
      "applications" => [
        Map.merge(source_diff, %{
          "transition_decision" => "review",
          "application_status" => "operator_review_required",
          "source_timeline_diff" => source_diff
        })
      ],
      "assumptions" => %{"execution_boundary" => "artifact_only_no_schedule_mutation"}
    }

    review = OrbitalDynamics.OperatorReview.from_timeline_transition_application_report(report)
    manifest = OrbitalDynamics.CadenceImport.from_timeline_transition_application_report(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    invalid_manifest_counts =
      put_in(manifest, ["import_status_counts", "ready_for_import"], 99)

    assert {:error, manifest_counts_report} = Schema.validate_artifact(invalid_manifest_counts)

    assert Enum.any?(
             manifest_counts_report["errors"],
             &(&1["path"] == "$.import_status_counts")
           )

    invalid_review =
      put_in(
        review,
        [
          "rows",
          Access.at(0),
          "source_timeline_application",
          "source_timeline_diff",
          "diff_status"
        ],
        "x"
      )

    assert {:error, review_report} = Schema.validate_artifact(invalid_review)

    assert Enum.any?(
             review_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_timeline_application.source_timeline_diff.diff_status")
           )

    invalid_manifest =
      put_in(
        manifest,
        [
          "rows",
          Access.at(0),
          "source_timeline_application",
          "source_timeline_diff",
          "diff_status"
        ],
        "x"
      )

    assert {:error, manifest_report} = Schema.validate_artifact(invalid_manifest)

    assert Enum.any?(
             manifest_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_timeline_application.source_timeline_diff.diff_status")
           )

    invalid_manifest_review_copy =
      put_in(
        manifest,
        [
          "rows",
          Access.at(0),
          "source_review_row",
          "source_timeline_application",
          "source_timeline_diff",
          "diff_status"
        ],
        "x"
      )

    assert {:error, manifest_review_copy_report} =
             Schema.validate_artifact(invalid_manifest_review_copy)

    assert Enum.any?(
             manifest_review_copy_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_review_row.source_timeline_application.source_timeline_diff.diff_status")
           )

    invalid_review_branch_quality =
      put_in(review, ["rows", Access.at(0), "branch_cloud_cover_max_fraction"], 1.2)

    assert {:error, invalid_review_branch_quality_report} =
             Schema.validate_artifact(invalid_review_branch_quality)

    assert Enum.any?(
             invalid_review_branch_quality_report["errors"],
             &(&1["path"] == "$.rows[0].branch_cloud_cover_max_fraction")
           )

    invalid_manifest_branch_events =
      put_in(manifest, ["rows", Access.at(0), "branch_event_types"], ["timeline_diff", 42])

    assert {:error, invalid_manifest_branch_events_report} =
             Schema.validate_artifact(invalid_manifest_branch_events)

    assert Enum.any?(
             invalid_manifest_branch_events_report["errors"],
             &(&1["path"] == "$.rows[0].branch_event_types[1]")
           )

    invalid_manifest_target_id =
      put_in(manifest, ["rows", Access.at(0), "target_id"], "target with spaces")

    assert {:error, invalid_manifest_target_id_report} =
             Schema.validate_artifact(invalid_manifest_target_id)

    assert Enum.any?(
             invalid_manifest_target_id_report["errors"],
             &(&1["path"] == "$.rows[0].target_id")
           )

    invalid_manifest_review_branch_counts =
      put_in(
        manifest,
        [
          "rows",
          Access.at(0),
          "source_review_row",
          "branch_event_trust_boundary_status_counts"
        ],
        %{"declared" => -1}
      )

    assert {:error, invalid_manifest_review_branch_counts_report} =
             Schema.validate_artifact(invalid_manifest_review_branch_counts)

    assert Enum.any?(
             invalid_manifest_review_branch_counts_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_review_row.branch_event_trust_boundary_status_counts.declared")
           )

    valid_source_branch_comparison = %{
      "downlink_completion_required_contacts" => 1,
      "downlink_completion_planned_contacts" => 0,
      "downlink_completion_ratio" => 0.0,
      "observation_success_factor" => 1.0
    }

    review_with_branch_source =
      put_in(
        review,
        ["rows", Access.at(0), "source_branch_comparison"],
        valid_source_branch_comparison
      )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review_with_branch_source)

    invalid_review_source_branch =
      put_in(
        review_with_branch_source,
        [
          "rows",
          Access.at(0),
          "source_branch_comparison",
          "downlink_completion_required_contacts"
        ],
        1.0
      )

    assert {:error, invalid_review_source_branch_report} =
             Schema.validate_artifact(invalid_review_source_branch)

    assert Enum.any?(
             invalid_review_source_branch_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_branch_comparison.downlink_completion_required_contacts")
           )

    invalid_review_source_branch_target_count =
      put_in(
        review_with_branch_source,
        [
          "rows",
          Access.at(0),
          "source_branch_comparison",
          "coverage_observed_target_count"
        ],
        -1
      )

    assert {:error, invalid_review_source_branch_target_count_report} =
             Schema.validate_artifact(invalid_review_source_branch_target_count)

    assert Enum.any?(
             invalid_review_source_branch_target_count_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_branch_comparison.coverage_observed_target_count")
           )

    invalid_review_source_branch_probability =
      put_in(
        review_with_branch_source,
        ["rows", Access.at(0), "source_branch_comparison", "downlink_completion_ratio"],
        1.2
      )

    assert {:error, invalid_review_source_branch_probability_report} =
             Schema.validate_artifact(invalid_review_source_branch_probability)

    assert Enum.any?(
             invalid_review_source_branch_probability_report["errors"],
             &(&1["path"] == "$.rows[0].source_branch_comparison.downlink_completion_ratio")
           )

    manifest_with_branch_source =
      put_in(
        manifest,
        ["rows", Access.at(0), "source_branch_comparison"],
        valid_source_branch_comparison
      )

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest_with_branch_source)

    invalid_manifest_source_branch =
      put_in(
        manifest_with_branch_source,
        [
          "rows",
          Access.at(0),
          "source_branch_comparison",
          "downlink_completion_planned_contacts"
        ],
        -1
      )

    assert {:error, invalid_manifest_source_branch_report} =
             Schema.validate_artifact(invalid_manifest_source_branch)

    assert Enum.any?(
             invalid_manifest_source_branch_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_branch_comparison.downlink_completion_planned_contacts")
           )

    manifest_with_review_branch_source =
      put_in(
        manifest,
        ["rows", Access.at(0), "source_review_row", "source_branch_comparison"],
        valid_source_branch_comparison
      )

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest_with_review_branch_source)

    invalid_manifest_review_source_branch =
      put_in(
        manifest_with_review_branch_source,
        [
          "rows",
          Access.at(0),
          "source_review_row",
          "source_branch_comparison",
          "downlink_completion_required_contacts"
        ],
        -1
      )

    assert {:error, invalid_manifest_review_source_branch_report} =
             Schema.validate_artifact(invalid_manifest_review_source_branch)

    assert Enum.any?(
             invalid_manifest_review_source_branch_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_review_row.source_branch_comparison.downlink_completion_required_contacts")
           )

    invalid_manifest_review_source_branch_revisit_count =
      put_in(
        manifest_with_review_branch_source,
        [
          "rows",
          Access.at(0),
          "source_review_row",
          "source_branch_comparison",
          "revisit_count"
        ],
        -1
      )

    assert {:error, invalid_manifest_review_source_branch_revisit_count_report} =
             Schema.validate_artifact(invalid_manifest_review_source_branch_revisit_count)

    assert Enum.any?(
             invalid_manifest_review_source_branch_revisit_count_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_review_row.source_branch_comparison.revisit_count")
           )

    invalid_manifest_review_source_branch_probability =
      put_in(
        manifest_with_review_branch_source,
        [
          "rows",
          Access.at(0),
          "source_review_row",
          "source_branch_comparison",
          "observation_success_factor"
        ],
        -0.1
      )

    assert {:error, invalid_manifest_review_source_branch_probability_report} =
             Schema.validate_artifact(invalid_manifest_review_source_branch_probability)

    assert Enum.any?(
             invalid_manifest_review_source_branch_probability_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_review_row.source_branch_comparison.observation_success_factor")
           )
  end

  test "exports timeline transition application top-level contract fields" do
    assert {:ok, schema} = Schema.json_schema("timeline_transition_application_report.v1")

    assert get_in(schema, ["properties", "schema_contract", "const"]) ==
             "timeline_transition_application_report.v1"

    assert get_in(schema, ["properties", "model", "const"]) ==
             "artifact_only_timeline_transition_application"

    assert get_in(schema, ["properties", "source", "type"]) == "string"

    assert get_in(schema, ["properties", "model_limits", "const"]) ==
             OrbitalDynamics.Timeline.model_limits()

    assert get_in(schema, [
             "properties",
             "application_status_counts",
             "propertyNames",
             "enum"
           ]) == OrbitalDynamics.Timeline.capabilities().transition_application_statuses

    assert get_in(schema, [
             "properties",
             "transition_decision_counts",
             "propertyNames",
             "enum"
           ]) == OrbitalDynamics.Timeline.capabilities().transition_decisions

    assert get_in(schema, [
             "properties",
             "required_operator_action_counts",
             "propertyNames",
             "enum"
           ]) ==
             OrbitalDynamics.Timeline.capabilities().transition_decision_required_operator_actions

    assert get_in(schema, [
             "properties",
             "status_transition_counts",
             "propertyNames",
             "enum"
           ]) == OrbitalDynamics.Timeline.capabilities().lifecycle_transition_types

    assert get_in(schema, [
             "properties",
             "approval_transition_category_counts",
             "additionalProperties"
           ]) == %{"type" => "integer", "minimum" => 0}

    assert get_in(schema, [
             "properties",
             "transition_decision_counts",
             "additionalProperties"
           ]) == %{"type" => "integer", "minimum" => 0}

    assert get_in(schema, [
             "properties",
             "selected_timeline_integrity_issue_count"
           ]) == %{"type" => "integer", "minimum" => 0}

    assert get_in(schema, [
             "properties",
             "selected_timeline_integrity_issue_types",
             "items",
             "enum"
           ]) == OrbitalDynamics.Timeline.capabilities().timeline_integrity_issue_types

    assert get_in(schema, ["properties", "source_activity_count"]) ==
             %{"type" => "integer", "minimum" => 0}

    assert get_in(schema, ["properties", "application_count"]) ==
             %{"type" => "integer", "minimum" => 0}

    assert get_in(schema, ["properties", "preserved_source_count"]) ==
             %{"type" => "integer", "minimum" => 0}

    assert get_in(schema, ["properties", "withheld_review_count"]) ==
             %{"type" => "integer", "minimum" => 0}

    assert get_in(schema, [
             "properties",
             "applications",
             "items",
             "properties",
             "source_duplicate_activity_ids",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(schema, [
             "properties",
             "applications",
             "items",
             "properties",
             "source_timeline_diff",
             "properties",
             "source_duplicate_activity_ids",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(schema, [
             "properties",
             "selected_activities",
             "items",
             "properties",
             "activity_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(schema, [
             "properties",
             "selected_activities",
             "items",
             "required"
           ]) == [
             "activity_id",
             "timeline_id",
             "activity_type",
             "status",
             "approval_status",
             "locked",
             "has_source_window",
             "has_cadence_import",
             "timeline_identity"
           ]

    assert get_in(schema, [
             "properties",
             "selected_activities",
             "items",
             "properties",
             "timeline_integrity_issue_count"
           ]) == %{"type" => "integer", "minimum" => 0}

    assert get_in(schema, [
             "properties",
             "selected_activities",
             "items",
             "properties",
             "timeline_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(schema, [
             "properties",
             "selected_activities",
             "items",
             "properties",
             "approval_status",
             "enum"
           ]) == OrbitalDynamics.Timeline.capabilities().approval_statuses

    assert get_in(schema, [
             "properties",
             "selected_activities",
             "items",
             "properties",
             "timeline_identity",
             "type"
           ]) == "object"

    assert get_in(schema, [
             "properties",
             "selected_activities",
             "items",
             "properties",
             "timeline_identity",
             "properties",
             "timeline_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(schema, [
             "properties",
             "selected_activities",
             "items",
             "properties",
             "protection_category",
             "type"
           ]) == "string"

    row_schema = get_in(schema, ["properties", "applications", "items"])

    assert get_in(row_schema, ["properties", "source_protection_decision", "type"]) ==
             "object"

    assert get_in(row_schema, [
             "properties",
             "source_protection_decision",
             "properties",
             "locked",
             "type"
           ]) == "boolean"

    assert get_in(row_schema, ["properties", "replacement_protection_decision", "type"]) ==
             "object"

    assert get_in(row_schema, ["properties", "status_transition", "type"]) == "object"

    assert get_in(row_schema, [
             "properties",
             "status_transition",
             "properties",
             "requires_operator_review",
             "type"
           ]) == "boolean"

    assert get_in(row_schema, ["properties", "approval_transition", "type"]) == "object"
    assert get_in(row_schema, ["properties", "operator_action_reason", "type"]) == "string"

    assert get_in(row_schema, ["properties", "selected_timeline_integrity_issue_count"]) ==
             %{"type" => "integer", "minimum" => 0}

    assert get_in(row_schema, [
             "properties",
             "selected_duplicate_exclusivity_activity_ids",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, [
             "properties",
             "selected_dependency_order_violation_timeline_ids",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, ["properties", "source_duplicate_activity_count"]) ==
             %{"type" => "integer", "minimum" => 0}
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
