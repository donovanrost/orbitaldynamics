defmodule OrbitalDynamics.Schema.TimelineSummaryContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  test "exports and validates timeline preservation model and source fields" do
    assert {:ok, report_schema} = Schema.json_schema("timeline_preservation_report.v1")
    assert {:ok, status_schema} = Schema.json_schema("timeline_preservation_status.v1")

    assert get_in(report_schema, ["properties", "schema_contract", "const"]) ==
             "timeline_preservation_report.v1"

    assert get_in(report_schema, ["properties", "model", "const"]) ==
             "artifact_only_lifecycle_preservation_summary"

    assert get_in(report_schema, ["properties", "source", "type"]) == "string"

    assert get_in(report_schema, ["properties", "model_limits", "const"]) ==
             OrbitalDynamics.Timeline.model_limits()

    assert get_in(report_schema, ["properties", "model_limits", "items", "enum"]) ==
             OrbitalDynamics.Timeline.model_limits()

    assert_timeline_string_assumptions_schema(
      report_schema,
      timeline_preservation_report_assumptions()
    )

    assert get_in(status_schema, ["properties", "schema_contract", "const"]) ==
             "timeline_preservation_status.v1"

    assert get_in(status_schema, ["properties", "model", "const"]) ==
             "artifact_only_lifecycle_preservation_status"

    assert get_in(status_schema, ["properties", "model_limits", "const"]) ==
             OrbitalDynamics.Timeline.model_limits()

    assert get_in(status_schema, ["properties", "model_limits", "items", "enum"]) ==
             OrbitalDynamics.Timeline.model_limits()

    assert_timeline_string_assumptions_schema(
      status_schema,
      timeline_preservation_status_assumptions()
    )

    preservation_report =
      OrbitalDynamics.Timeline.preservation_report(
        [
          %{id: :contact_locked, type: :planned_contact, locked: true},
          %{id: :cmd_mutable, type: :command, approval_status: :pending}
        ],
        source: "schema_test"
      )

    assert {:ok, %{"schema_contract" => "timeline_preservation_report.v1"}} =
             Schema.validate_artifact(preservation_report)

    invalid_report_scope =
      put_in(preservation_report, ["assumptions", "scope"], "single_activity_preflight")

    assert {:error, validation_report} = Schema.validate_artifact(invalid_report_scope)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.assumptions.scope" and
                 &1["message"] ==
                   "must equal \"lifecycle_lock_approval_and_executed_preservation_review\"")
           )

    invalid_report_model = Map.put(preservation_report, "model", "custom")

    assert {:error, validation_report} = Schema.validate_artifact(invalid_report_model)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.model" and
                 &1["message"] ==
                   "must equal \"artifact_only_lifecycle_preservation_summary\"")
           )

    invalid_report_source = Map.put(preservation_report, "source", %{"id" => "schema_test"})

    assert {:error, validation_report} = Schema.validate_artifact(invalid_report_source)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.source" and &1["message"] == "must be a binary")
           )

    preservation_status =
      OrbitalDynamics.Timeline.preservation_status(%{
        id: :contact_locked,
        type: :planned_contact,
        locked: true
      })

    assert {:ok, %{"schema_contract" => "timeline_preservation_status.v1"}} =
             Schema.validate_artifact(preservation_status)

    invalid_status_scope =
      put_in(preservation_status, ["assumptions", "scope"], "preservation_report")

    assert {:error, validation_report} = Schema.validate_artifact(invalid_status_scope)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.assumptions.scope" and
                 &1["message"] ==
                   "must equal \"single_activity_lifecycle_preservation_preflight\"")
           )

    invalid_status_model = Map.put(preservation_status, "model", "custom")

    assert {:error, validation_report} = Schema.validate_artifact(invalid_status_model)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.model" and
                 &1["message"] ==
                   "must equal \"artifact_only_lifecycle_preservation_status\"")
           )
  end

  test "validates checked-in timeline preservation report fixture" do
    preservation_report = read_json!("study_results/timeline_preservation_report_v1.json")

    activities = [
      %{
        id: :cmd_mutable,
        type: :command,
        status: :planned,
        approval_status: :pending
      },
      %{
        id: :contact_locked,
        type: :contact,
        status: :planned,
        locked: true,
        metadata: %{timeline_id: :"timeline:planned_contact"}
      },
      %{
        id: :obs_done,
        type: :observe,
        status: :completed,
        metadata: %{timeline_id: :"timeline:observe"}
      },
      %{
        id: :bad_missing_type,
        status: :planned
      }
    ]

    generated_preservation_report =
      OrbitalDynamics.timeline_preservation_report(
        activities,
        source: "validation.timeline_preservation_report"
      )

    assert generated_preservation_report == preservation_report

    assert {:ok, %{"schema_contract" => "timeline_preservation_report.v1"}} =
             Schema.validate_artifact(preservation_report)

    assert %{
             "schema_contract" => "timeline_preservation_report.v1",
             "model" => "artifact_only_lifecycle_preservation_summary",
             "source" => "validation.timeline_preservation_report",
             "activity_count" => 4,
             "mutable_activity_count" => 1,
             "preserve_activity_count" => 2,
             "review_change_activity_count" => 1,
             "preservation_sensitive_activity_count" => 3,
             "timeline_preservation_status" => "review_required",
             "protection_decision_counts" => %{
               "mutable" => 1,
               "preserve" => 2,
               "review_change" => 1
             },
             "protection_category_counts" => %{
               "executed" => 1,
               "invalid_activity_input" => 1,
               "locked_or_approved" => 1,
               "none" => 1
             },
             "protection_reason_counts" => %{
               "activity_already_completed" => 1,
               "activity_locked_or_approved" => 1,
               "missing_activity_type" => 1,
               "no_timeline_protection" => 1
             },
             "preserve_activity_ids" => ["contact_locked", "obs_done"],
             "preserve_timeline_ids" => [
               "timeline:observe",
               "timeline:planned_contact"
             ],
             "review_change_activity_ids" => ["bad_missing_type"],
             "review_change_timeline_ids" => [
               "timeline:invalid_activity_input:bad_missing_type"
             ],
             "mutable_activity_ids" => ["cmd_mutable"],
             "preservation_sensitive_activity_ids" => [
               "bad_missing_type",
               "contact_locked",
               "obs_done"
             ],
             "preservation_sensitive_timeline_ids" => [
               "timeline:invalid_activity_input:bad_missing_type",
               "timeline:observe",
               "timeline:planned_contact"
             ],
             "activity_id_sets_by_protection_decision" => %{
               "mutable" => ["cmd_mutable"],
               "preserve" => ["contact_locked", "obs_done"],
               "review_change" => ["bad_missing_type"]
             },
             "timeline_id_sets_by_protection_decision" => %{
               "mutable" => ["timeline:command"],
               "preserve" => [
                 "timeline:observe",
                 "timeline:planned_contact"
               ],
               "review_change" => ["timeline:invalid_activity_input:bad_missing_type"]
             },
             "activity_id_sets_by_protection_category" => %{
               "executed" => ["obs_done"],
               "invalid_activity_input" => ["bad_missing_type"],
               "locked_or_approved" => ["contact_locked"],
               "none" => ["cmd_mutable"]
             },
             "timeline_id_sets_by_protection_category" => %{
               "executed" => ["timeline:observe"],
               "invalid_activity_input" => ["timeline:invalid_activity_input:bad_missing_type"],
               "locked_or_approved" => ["timeline:planned_contact"],
               "none" => ["timeline:command"]
             },
             "activity_id_sets_by_protection_reason" => %{
               "activity_already_completed" => ["obs_done"],
               "activity_locked_or_approved" => ["contact_locked"],
               "missing_activity_type" => ["bad_missing_type"],
               "no_timeline_protection" => ["cmd_mutable"]
             },
             "timeline_id_sets_by_protection_reason" => %{
               "activity_already_completed" => ["timeline:observe"],
               "activity_locked_or_approved" => ["timeline:planned_contact"],
               "missing_activity_type" => ["timeline:invalid_activity_input:bad_missing_type"],
               "no_timeline_protection" => ["timeline:command"]
             },
             "model_limits" => [
               "artifact_level_only",
               "no_schedule_mutation",
               "no_command_execution",
               "derived_identity_when_no_persistent_timeline_id"
             ],
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_schedule_mutation",
               "scope" => "lifecycle_lock_approval_and_executed_preservation_review",
               "source" => "validation.timeline_preservation_report"
             }
           } = preservation_report

    assert [
             %{
               "activity_id" => "contact_locked",
               "approval_status" => "not_evaluated",
               "locked" => true,
               "protection_category" => "locked_or_approved",
               "protection_decision" => "preserve",
               "reason" => "activity_locked_or_approved",
               "status" => "planned",
               "timeline_id" => "timeline:planned_contact",
               "timeline_identity" => %{
                 "activity_id" => "contact_locked",
                 "activity_type" => "contact",
                 "timeline_id" => "timeline:planned_contact"
               }
             },
             %{
               "activity_id" => "obs_done",
               "protection_category" => "executed",
               "protection_decision" => "preserve",
               "reason" => "activity_already_completed",
               "status" => "completed",
               "timeline_id" => "timeline:observe"
             },
             %{
               "activity_id" => "bad_missing_type",
               "invalid_activity_input" => true,
               "invalid_activity_input_reason" => "missing_activity_type",
               "protection_category" => "invalid_activity_input",
               "protection_decision" => "review_change",
               "reason" => "missing_activity_type",
               "status" => "invalid",
               "timeline_id" => "timeline:invalid_activity_input:bad_missing_type"
             }
           ] = preservation_report["rows"]
  end

  test "validates checked-in timeline preservation status fixture" do
    preservation_status = read_json!("study_results/timeline_preservation_status_v1.json")

    generated_preservation_status =
      OrbitalDynamics.timeline_preservation_status(%{
        id: :dl_locked,
        type: :downlink,
        timeline_id: :"timeline:dl_locked",
        locked: true,
        approval_status: :pending
      })

    assert generated_preservation_status == preservation_status

    assert {:ok, %{"schema_contract" => "timeline_preservation_status.v1"}} =
             Schema.validate_artifact(preservation_status)

    assert %{
             "timeline_preservation_status" => "preservation_required",
             "requires_preservation" => true,
             "requires_operator_review" => false,
             "activity_id" => "dl_locked",
             "timeline_id" => "timeline:dl_locked",
             "status" => "planned",
             "approval_status" => "pending",
             "locked" => true,
             "approved" => false,
             "protection_decision" => "preserve",
             "protection_category" => "locked_or_approved",
             "protection_reason" => "activity_locked_or_approved",
             "timeline_identity" => %{
               "activity_id" => "dl_locked",
               "activity_type" => "downlink",
               "timeline_id" => "timeline:dl_locked"
             },
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_schedule_mutation",
               "scope" => "single_activity_lifecycle_preservation_preflight"
             }
           } = preservation_status

    assert preservation_status["model_limits"] == OrbitalDynamics.Timeline.model_limits()
  end

  test "exports and validates timeline transition-application summary fields" do
    assert {:ok, schema} = Schema.json_schema("timeline_transition_application_summary.v1")

    assert get_in(schema, ["properties", "schema_contract", "const"]) ==
             "timeline_transition_application_summary.v1"

    assert get_in(schema, ["properties", "model", "const"]) ==
             "artifact_only_timeline_transition_application_summary"

    assert get_in(schema, ["properties", "validation_level", "const"]) == "artifact_contract"

    assert get_in(schema, ["properties", "source_artifact_type", "const"]) ==
             "timeline_transition_application_report.v1"

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
             "status_transition_category_counts",
             "propertyNames",
             "enum"
           ]) == OrbitalDynamics.Timeline.capabilities().status_transition_categories

    assert get_in(schema, [
             "properties",
             "selected_timeline_integrity_issue_types",
             "items",
             "enum"
           ]) == OrbitalDynamics.Timeline.capabilities().timeline_integrity_issue_types

    assert get_in(schema, [
             "properties",
             "selected_activity_ids",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(schema, [
             "properties",
             "review_timeline_ids_by_required_operator_action",
             "additionalProperties",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(schema, [
             "properties",
             "review_timeline_ids_by_status_transition_category",
             "additionalProperties",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(schema, [
             "properties",
             "review_timeline_ids_by_approval_transition_category",
             "additionalProperties",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(schema, ["x-orbital-dynamics", "nested_contracts"]) == [
             "timeline_revision.v1",
             "timeline_transition_application_report.v1"
           ]

    assert get_in(schema, [
             "properties",
             "review_applications",
             "items",
             "required"
           ]) == [
             "id",
             "rank",
             "timeline_id",
             "diff_status",
             "transition_decision",
             "requires_operator_review",
             "required_operator_action",
             "reason",
             "changed_fields",
             "application_status",
             "source_timeline_diff"
           ]

    assert get_in(schema, [
             "properties",
             "review_applications",
             "items",
             "properties",
             "source_activity_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

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
      starts_at_s: 12.0,
      ends_at_s: 22.0,
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

    added = %{
      id: :new_cmd,
      type: :command,
      starts_at_s: 70.0,
      ends_at_s: 80.0,
      metadata: %{timeline_id: :"timeline:new_cmd"}
    }

    summary =
      OrbitalDynamics.Timeline.transition_application_summary(
        [protected_source, unchanged],
        [protected_replacement, unchanged, added]
      )

    assert {:ok, %{"schema_contract" => "timeline_transition_application_summary.v1"}} =
             Schema.validate_artifact(summary)

    invalid_source_contract = Map.put(summary, "source_artifact_type", "timeline_diff_report.v1")

    assert {:error, validation_report} = Schema.validate_artifact(invalid_source_contract)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.source_artifact_type" and
                 &1["message"] == "must equal \"timeline_transition_application_report.v1\"")
           )

    stale_model_limits = Map.put(summary, "model_limits", ["artifact_level_only"])

    assert {:error, validation_report} = Schema.validate_artifact(stale_model_limits)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] == "must match timeline report model limits")
           )

    stale_review_count = Map.put(summary, "review_required_count", 1)

    assert {:error, validation_report} = Schema.validate_artifact(stale_review_count)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.review_required_count" and
                 &1["message"] ==
                   "must equal review-application-derived review_required_count")
           )

    stale_action_map =
      put_in(
        summary,
        ["review_timeline_ids_by_required_operator_action", "review_added_activity"],
        ["timeline:cmd_lock"]
      )

    assert {:error, validation_report} = Schema.validate_artifact(stale_action_map)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.review_timeline_ids_by_required_operator_action" and
                 &1["message"] ==
                   "must equal review-application-derived review_timeline_ids_by_required_operator_action")
           )

    stale_status_map =
      put_in(
        summary,
        ["review_timeline_ids_by_status_transition_category", "status_added"],
        ["timeline:cmd_lock"]
      )

    assert {:error, validation_report} = Schema.validate_artifact(stale_status_map)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.review_timeline_ids_by_status_transition_category" and
                 &1["message"] ==
                   "must equal review-application-derived review_timeline_ids_by_status_transition_category")
           )

    stale_approval_map =
      put_in(
        summary,
        ["review_timeline_ids_by_approval_transition_category", "approval_review_required"],
        ["timeline:cmd_lock"]
      )

    assert {:error, validation_report} = Schema.validate_artifact(stale_approval_map)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.review_timeline_ids_by_approval_transition_category" and
                 &1["message"] ==
                   "must equal review-application-derived review_timeline_ids_by_approval_transition_category")
           )

    invalid_action_map_id =
      put_in(
        summary,
        ["review_timeline_ids_by_required_operator_action", "review_added_activity"],
        ["bad timeline"]
      )

    assert {:error, validation_report} = Schema.validate_artifact(invalid_action_map_id)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] ==
                 "$.review_timeline_ids_by_required_operator_action.review_added_activity[0]" and
                 &1["message"] =~ "stable ID")
           )
  end

  test "validates checked-in timeline transition application summary fixture" do
    summary = read_json!("study_results/timeline_transition_application_summary_v1.json")

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
      starts_at_s: 12.0,
      ends_at_s: 22.0,
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

    added = %{
      id: :new_cmd,
      type: :command,
      starts_at_s: 70.0,
      ends_at_s: 80.0,
      metadata: %{timeline_id: :"timeline:new_cmd"}
    }

    generated_summary =
      OrbitalDynamics.timeline_transition_application_summary(
        [protected_source, unchanged],
        [protected_replacement, unchanged, added]
      )

    assert generated_summary == summary

    assert {:ok, %{"schema_contract" => "timeline_transition_application_summary.v1"}} =
             Schema.validate_artifact(summary)

    assert %{
             "schema_contract" => "timeline_transition_application_summary.v1",
             "model" => "artifact_only_timeline_transition_application_summary",
             "validation_level" => "artifact_contract",
             "source_artifact_type" => "timeline_transition_application_report.v1",
             "source" => "timeline.activities",
             "source_activity_count" => 2,
             "replacement_activity_count" => 3,
             "application_count" => 3,
             "selected_activity_count" => 2,
             "review_required_count" => 2,
             "preserved_source_count" => 1,
             "recorded_replacement_count" => 0,
             "withheld_review_count" => 1,
             "application_status_counts" => %{
               "operator_review_required" => 1,
               "source_preserved_pending_review" => 1,
               "source_unchanged" => 1
             },
             "transition_decision_counts" => %{
               "none" => 1,
               "preserve_source" => 1,
               "review" => 1
             },
             "status_transition_category_counts" => %{"status_added" => 1},
             "approval_transition_category_counts" => %{
               "approval_review_required" => 1
             },
             "required_operator_action_counts" => %{
               "none" => 1,
               "review_added_activity" => 1,
               "review_changed_protected_activity" => 1
             },
             "selected_activity_ids" => ["cmd_lock", "obs_keep"],
             "selected_timeline_ids" => ["timeline:cmd_lock", "timeline:obs_keep"],
             "review_timeline_ids" => ["timeline:cmd_lock", "timeline:new_cmd"],
             "review_activity_ids" => ["cmd_lock", "new_cmd"],
             "review_timeline_ids_by_required_operator_action" => %{
               "review_added_activity" => ["timeline:new_cmd"],
               "review_changed_protected_activity" => ["timeline:cmd_lock"]
             },
             "review_timeline_ids_by_status_transition_category" => %{
               "status_added" => ["timeline:new_cmd"]
             },
             "review_timeline_ids_by_approval_transition_category" => %{
               "approval_review_required" => ["timeline:new_cmd"]
             },
             "preserved_source_timeline_ids" => ["timeline:cmd_lock"],
             "recorded_replacement_timeline_ids" => [],
             "withheld_review_timeline_ids" => ["timeline:new_cmd"],
             "selected_timeline_integrity_issue_count" => 0,
             "selected_timeline_integrity_review_count" => 0,
             "selected_timeline_integrity_issue_types" => [],
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_schedule_mutation",
               "operator_authority" => "not_granted_by_summary"
             }
           } = summary

    assert Enum.map(summary["review_applications"], & &1["timeline_id"]) == [
             "timeline:cmd_lock",
             "timeline:new_cmd"
           ]

    assert summary["model_limits"] == OrbitalDynamics.Timeline.model_limits()
  end

  test "validates checked-in timeline transition application selected integrity summary fixture" do
    summary =
      read_json!(
        "study_results/timeline_transition_application_selected_integrity_summary_v1.json"
      )

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

    generated_summary =
      OrbitalDynamics.timeline_transition_application_summary(
        [dependency, protected_source],
        [protected_replacement],
        source: "fixture.timeline.transition_application.selected_integrity"
      )

    assert generated_summary == summary

    assert {:ok, %{"schema_contract" => "timeline_transition_application_summary.v1"}} =
             Schema.validate_artifact(summary)

    assert %{
             "schema_contract" => "timeline_transition_application_summary.v1",
             "model" => "artifact_only_timeline_transition_application_summary",
             "validation_level" => "artifact_contract",
             "source_artifact_type" => "timeline_transition_application_report.v1",
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
             "review_timeline_ids_by_required_operator_action" => %{
               "review_changed_protected_activity" => ["timeline:cmd_lock"],
               "review_removed_activity" => ["timeline:cmd_prereq"]
             },
             "selected_activity_ids" => ["cmd_lock"],
             "selected_timeline_ids" => ["timeline:cmd_lock"],
             "review_activity_ids" => ["cmd_lock", "cmd_prereq"],
             "review_timeline_ids" => ["timeline:cmd_lock", "timeline:cmd_prereq"],
             "withheld_review_timeline_ids" => ["timeline:cmd_prereq"]
           } = summary

    assert [
             %{
               "timeline_id" => "timeline:cmd_lock",
               "application_status" => "source_preserved_pending_review",
               "selected_timeline_integrity_status" => "review_required",
               "selected_timeline_integrity_issue_types" => ["missing_dependency_activity"],
               "selected_missing_dependency_activity_ids" => ["cmd_prereq"]
             },
             %{
               "timeline_id" => "timeline:cmd_prereq",
               "application_status" => "operator_review_required",
               "required_operator_action" => "review_removed_activity"
             }
           ] = summary["review_applications"]
  end

  test "exports timeline activity precondition summary schema fields" do
    assert {:ok, schema} = Schema.json_schema("timeline_activity_precondition_summary.v1")

    assert schema["required"] == [
             "schema_contract",
             "model",
             "validation_level",
             "model_limits",
             "precondition_status",
             "blocked_precondition_count",
             "review_precondition_count",
             "blocked_precondition_types",
             "review_precondition_types",
             "preconditions",
             "assumptions"
           ]

    assert get_in(schema, ["properties", "schema_contract", "const"]) ==
             "timeline_activity_precondition_summary.v1"

    assert get_in(schema, ["properties", "model", "const"]) ==
             "artifact_only_timeline_activity_precondition_summary"

    assert get_in(schema, ["properties", "validation_level", "const"]) == "artifact_contract"

    assert get_in(schema, ["properties", "model_limits", "const"]) ==
             OrbitalDynamics.Timeline.model_limits()

    assert get_in(schema, ["properties", "model_limits", "items", "enum"]) ==
             OrbitalDynamics.Timeline.model_limits()

    capabilities = OrbitalDynamics.Timeline.capabilities()

    assert get_in(schema, ["properties", "precondition_status", "enum"]) ==
             capabilities.activity_precondition_statuses

    assert get_in(schema, ["properties", "preconditions", "items", "properties", "type", "enum"]) ==
             capabilities.activity_precondition_types

    assert get_in(schema, ["properties", "preconditions", "items", "required"]) == [
             "type",
             "status",
             "field",
             "reason"
           ]

    assert get_in(schema, [
             "properties",
             "preconditions",
             "items",
             "properties",
             "value",
             "type"
           ]) == ["string", "number", "boolean", "object"]

    assert get_in(schema, [
             "properties",
             "preconditions",
             "items",
             "properties",
             "status",
             "enum"
           ]) == capabilities.activity_precondition_statuses

    assert get_in(schema, ["properties", "dependency_activity_ids", "items", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(schema, ["properties", "dependency_timeline_ids", "items", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(schema, ["properties", "exclusive_with_activity_ids", "items", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(schema, ["properties", "exclusive_with_timeline_ids", "items", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(schema, ["properties", "allow_overlap", "type"]) == "boolean"
  end

  test "validates checked-in timeline activity precondition summary fixture" do
    summary = read_json!("study_results/timeline_activity_precondition_summary_v1.json")

    source_activity = %{
      "id" => "cmd_source",
      "type" => "command",
      "scenario_id" => "leo_1",
      "metadata" => %{"timeline_id" => "timeline:cmd_source"},
      "payload_available" => false,
      "resource_blocking_dimension" => "power",
      "degraded" => true
    }

    generated_summary = OrbitalDynamics.timeline_activity_precondition_summary(source_activity)

    assert generated_summary == summary

    assert {:ok, %{"schema_contract" => "timeline_activity_precondition_summary.v1"}} =
             Schema.validate_artifact(summary)

    assert %{
             "schema_contract" => "timeline_activity_precondition_summary.v1",
             "model" => "artifact_only_timeline_activity_precondition_summary",
             "validation_level" => "artifact_contract",
             "model_limits" => model_limits,
             "activity_id" => "cmd_source",
             "activity_type" => "command",
             "timeline_id" => "timeline:cmd_source",
             "timeline_identity" => %{
               "activity_id" => "cmd_source",
               "activity_type" => "command",
               "scenario_id" => "leo_1",
               "timeline_id" => "timeline:cmd_source"
             },
             "precondition_status" => "blocked",
             "blocked_precondition_count" => 2,
             "review_precondition_count" => 1,
             "blocked_precondition_types" => [
               "payload_unavailable",
               "resource_block_declared"
             ],
             "review_precondition_types" => ["degraded_mode"],
             "preconditions" => [
               %{
                 "type" => "payload_unavailable",
                 "status" => "blocked",
                 "field" => "payload_available",
                 "reason" => "payload availability is explicitly false"
               },
               %{
                 "type" => "resource_block_declared",
                 "status" => "blocked",
                 "field" => "resource_blocking_dimension",
                 "reason" => "resource blocking dimension is explicitly declared",
                 "value" => "power"
               },
               %{
                 "type" => "degraded_mode",
                 "status" => "review_required",
                 "field" => "degraded",
                 "reason" => "activity is explicitly marked degraded"
               }
             ],
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_schedule_mutation",
               "operator_authority" => "not_granted_by_precondition_summary",
               "resource_authority" => "not_reserved_by_precondition_summary"
             }
           } = summary

    assert model_limits == OrbitalDynamics.Timeline.model_limits()
  end

  test "validates timeline activity precondition summary artifact fields" do
    valid_summary = %{
      "schema_contract" => "timeline_activity_precondition_summary.v1",
      "model" => "artifact_only_timeline_activity_precondition_summary",
      "validation_level" => "artifact_contract",
      "model_limits" => OrbitalDynamics.Timeline.model_limits(),
      "activity_id" => "cmd_source",
      "timeline_id" => "timeline:cmd_source",
      "activity_type" => "command",
      "precondition_status" => "blocked",
      "blocked_precondition_count" => 1,
      "review_precondition_count" => 2,
      "blocked_precondition_types" => ["payload_unavailable"],
      "review_precondition_types" => ["degraded_mode", "subsystem_state_required"],
      "dependency_activity_ids" => ["health_check_1", "obs_1"],
      "dependency_timeline_ids" => ["timeline:health_check_1"],
      "exclusive_with_activity_ids" => ["dl_conflict"],
      "exclusive_with_timeline_ids" => ["timeline:dl_conflict"],
      "allow_overlap" => true,
      "preconditions" => [
        %{
          "type" => "payload_unavailable",
          "status" => "blocked",
          "field" => "payload_available",
          "reason" => "payload availability is explicitly false"
        },
        %{
          "type" => "degraded_mode",
          "status" => "review_required",
          "field" => "degraded",
          "reason" => "activity is explicitly marked degraded"
        },
        %{
          "type" => "subsystem_state_required",
          "status" => "review_required",
          "field" => "activity_template.subsystem_state_hints.required_states[0]",
          "reason" => "activity template declares required subsystem state",
          "value" => %{"subsystem" => "commanding", "state" => "armed"}
        }
      ],
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_schedule_mutation",
        "operator_authority" => "not_granted_by_precondition_summary",
        "resource_authority" => "not_reserved_by_precondition_summary"
      }
    }

    assert {:ok, %{"schema_contract" => "timeline_activity_precondition_summary.v1"}} =
             Schema.validate_artifact(valid_summary)

    stale_model_limits = Map.put(valid_summary, "model_limits", ["artifact_level_only"])

    assert {:error, validation_report} = Schema.validate_artifact(stale_model_limits)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] =~ "must match timeline report model limits")
           )

    invalid_status = Map.put(valid_summary, "precondition_status", "custom")

    assert {:error, validation_report} = Schema.validate_artifact(invalid_status)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.precondition_status" and &1["message"] =~ "must be one of")
           )

    stale_status = Map.put(valid_summary, "precondition_status", "clear")

    assert {:error, validation_report} = Schema.validate_artifact(stale_status)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.precondition_status" and
                 &1["message"] =~ "must equal row-derived precondition_status")
           )

    invalid_count = Map.put(valid_summary, "blocked_precondition_count", -1)

    assert {:error, validation_report} = Schema.validate_artifact(invalid_count)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.blocked_precondition_count" and
                 &1["message"] =~ "must be a non-negative integer")
           )

    stale_blocked_count = Map.put(valid_summary, "blocked_precondition_count", 0)

    assert {:error, validation_report} = Schema.validate_artifact(stale_blocked_count)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.blocked_precondition_count" and
                 &1["message"] =~ "must equal row-derived blocked_precondition_count")
           )

    stale_review_types = Map.put(valid_summary, "review_precondition_types", [])

    assert {:error, validation_report} = Schema.validate_artifact(stale_review_types)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.review_precondition_types" and
                 &1["message"] =~ "must equal row-derived review_precondition_types")
           )

    invalid_activity_id = Map.put(valid_summary, "activity_id", "cmd source")

    assert {:error, validation_report} = Schema.validate_artifact(invalid_activity_id)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.activity_id" and &1["message"] =~ "stable ID")
           )

    invalid_dependency_id =
      Map.put(valid_summary, "dependency_activity_ids", ["bad dependency"])

    assert {:error, validation_report} = Schema.validate_artifact(invalid_dependency_id)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.dependency_activity_ids[0]" and
                 &1["message"] =~ "stable ID")
           )

    invalid_exclusivity_timeline_id =
      Map.put(valid_summary, "exclusive_with_timeline_ids", ["bad timeline"])

    assert {:error, validation_report} = Schema.validate_artifact(invalid_exclusivity_timeline_id)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.exclusive_with_timeline_ids[0]" and
                 &1["message"] =~ "stable ID")
           )

    invalid_allow_overlap = Map.put(valid_summary, "allow_overlap", "true")

    assert {:error, validation_report} = Schema.validate_artifact(invalid_allow_overlap)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.allow_overlap" and &1["message"] =~ "must be a boolean")
           )

    invalid_row =
      put_in(valid_summary, ["preconditions", Access.at(0)], %{
        "type" => "payload_unavailable",
        "status" => "blocked",
        "reason" => "payload availability is explicitly false"
      })

    assert {:error, validation_report} = Schema.validate_artifact(invalid_row)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.preconditions[0].field" and &1["message"] =~ "must be a binary")
           )
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end

  defp timeline_preservation_report_assumptions do
    %{
      "execution_boundary" => "artifact_only_no_schedule_mutation",
      "scope" => "lifecycle_lock_approval_and_executed_preservation_review"
    }
  end

  defp timeline_preservation_status_assumptions do
    %{
      "execution_boundary" => "artifact_only_no_schedule_mutation",
      "scope" => "single_activity_lifecycle_preservation_preflight"
    }
  end

  defp assert_timeline_string_assumptions_schema(schema, values) do
    assumptions_schema = get_in(schema, ["properties", "assumptions"])

    assert assumptions_schema["type"] == "object"
    assert assumptions_schema["additionalProperties"] == true
    assert assumptions_schema["required"] == Map.keys(values)

    for {field, value} <- values do
      assert get_in(assumptions_schema, ["properties", field]) == %{
               "type" => "string",
               "const" => value
             }
    end
  end
end
