defmodule OrbitalDynamics.TimelineTransitionApplicationTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, OperatorReview, Schema, Timeline}

  test "classifies reusable transition decisions for proposed activity changes" do
    source = %{
      id: :cmd_lock,
      type: :command,
      status: :planned,
      approval_status: :approved,
      locked: true,
      starts_at_s: 10.0,
      ends_at_s: 20.0,
      metadata: %{timeline_id: :"timeline:cmd_lock"}
    }

    replacement = %{
      id: :cmd_lock,
      type: :command,
      status: :planned,
      approval_status: :approved,
      locked: true,
      starts_at_s: 15.0,
      ends_at_s: 25.0,
      metadata: %{timeline_id: :"timeline:cmd_lock"}
    }

    assert %{
             "timeline_id" => "timeline:cmd_lock",
             "diff_status" => "changed",
             "transition_decision" => "preserve_source",
             "transition_decision_reason" => "activity_locked_or_approved",
             "requires_operator_review" => true,
             "required_operator_action" => "review_changed_protected_activity",
             "changed_fields" => ["starts_at_s", "ends_at_s"],
             "source_protection_decision" => %{
               "protection_decision" => "preserve",
               "protection_category" => "locked_or_approved",
               "reason" => "activity_locked_or_approved"
             },
             "replacement_protection_decision" => %{
               "protection_decision" => "preserve",
               "protection_category" => "locked_or_approved"
             }
           } = Timeline.transition_decision(source, replacement)

    assert %{
             "transition_decision" => "none",
             "transition_decision_reason" => "no_source_or_replacement_activity",
             "diff_status" => "unchanged",
             "requires_operator_review" => false,
             "changed_fields" => []
           } = Timeline.transition_decision(nil, nil)

    identity_change =
      Timeline.transition_decision(
        %{id: :obs_1, type: :observe, metadata: %{timeline_id: :"timeline:obs_old"}},
        %{id: :obs_1, type: :observe, metadata: %{timeline_id: :"timeline:obs_new"}}
      )

    assert %{
             "transition_decision" => "review",
             "transition_decision_reason" => "activity_transition_changes_timeline_identity",
             "requires_operator_review" => true,
             "required_operator_action" => "review_activity_transition",
             "changed_fields" => ["timeline_identity"],
             "transition_row_count" => 2,
             "transition_rows" => transition_rows
           } = identity_change

    assert Enum.map(transition_rows, & &1["diff_status"]) |> Enum.sort() == ["added", "removed"]

    missing_dependency_source = %{
      id: :obs_waiting_on_gate,
      type: :observe,
      target_id: :target_alpha,
      starts_at_s: 30.0,
      ends_at_s: 40.0,
      depends_on: [:missing_gate],
      metadata: %{timeline_id: :"timeline:obs_waiting_on_gate"}
    }

    assert %{
             "transition_decision" => "review",
             "transition_decision_reason" =>
               "selected_timeline_integrity_issue_requires_review:missing_dependency_activity",
             "diff_status" => "unchanged",
             "requires_operator_review" => true,
             "required_operator_action" => "review_timeline_integrity",
             "selected_timeline_integrity_status" => "review_required",
             "selected_timeline_integrity_issue_count" => 1,
             "selected_timeline_integrity_issue_types" => ["missing_dependency_activity"],
             "selected_missing_dependency_activity_ids" => ["missing_gate"]
           } = Timeline.transition_decision(missing_dependency_source, missing_dependency_source)

    self_dependency_source = %{
      id: :obs_waiting_on_self,
      type: :observe,
      target_id: :target_alpha,
      starts_at_s: 45.0,
      ends_at_s: 55.0,
      depends_on: [:obs_waiting_on_self],
      metadata: %{timeline_id: :"timeline:obs_waiting_on_self"}
    }

    assert %{
             "transition_decision" => "review",
             "transition_decision_reason" =>
               "source and replacement timeline activities require integrity review",
             "required_operator_action" => "review_timeline_integrity"
           } = Timeline.transition_decision(self_dependency_source, self_dependency_source)

    assert [
             %{
               "source_timeline_integrity_issue_types" => ["self_dependency_activity"],
               "source_self_dependency_activity_ids" => ["obs_waiting_on_self"],
               "replacement_self_dependency_activity_ids" => ["obs_waiting_on_self"]
             }
           ] = Timeline.diff_report([self_dependency_source], [self_dependency_source])["rows"]

    assert %{
             "transition_decision" => "none",
             "requires_operator_review" => false
           } =
             Timeline.transition_decision(
               missing_dependency_source,
               missing_dependency_source,
               validate_selected_dependencies?: false
             )

    assert OrbitalDynamics.timeline_transition_decision(source, replacement) ==
             Timeline.transition_decision(source, replacement)
  end

  test "resolves reusable transition applications without mutating schedules" do
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

    assert %{
             "transition_decision" => "preserve_source",
             "application_status" => "source_preserved_pending_review",
             "selected_activity_source" => "source",
             "requires_operator_review" => true,
             "selected_activity" => %{
               "activity_id" => "cmd_lock",
               "starts_at_s" => 10.0,
               "ends_at_s" => 20.0,
               "protection_decision" => "preserve"
             }
           } = Timeline.transition_application(protected_source, protected_replacement)

    review_source = %{
      id: :obs_1,
      type: :observe,
      target_id: :target_a,
      starts_at_s: 10.0,
      ends_at_s: 20.0,
      metadata: %{timeline_id: :"timeline:obs_1"}
    }

    review_replacement = %{
      id: :obs_1,
      type: :observe,
      target_id: :target_a,
      starts_at_s: 12.0,
      ends_at_s: 22.0,
      metadata: %{timeline_id: :"timeline:obs_1"}
    }

    assert %{
             "transition_decision" => "review",
             "application_status" => "operator_review_required",
             "requires_operator_review" => true,
             "required_operator_action" => "review_timeline_change"
           } = mutable_review = Timeline.transition_application(review_source, review_replacement)

    refute Map.has_key?(mutable_review, "selected_activity")

    assert %{
             "transition_decision" => "none",
             "application_status" => "source_unchanged",
             "selected_activity_source" => "source",
             "selected_activity" => %{"activity_id" => "obs_1"}
           } = Timeline.transition_application(review_source, review_source)

    missing_dependency_source = %{
      id: :obs_waiting_on_gate,
      type: :observe,
      target_id: :target_alpha,
      starts_at_s: 30.0,
      ends_at_s: 40.0,
      depends_on: [:missing_gate],
      metadata: %{timeline_id: :"timeline:obs_waiting_on_gate"}
    }

    assert %{
             "transition_decision" => "none",
             "application_status" => "selected_timeline_integrity_review_required",
             "requires_operator_review" => true,
             "required_operator_action" => "review_timeline_integrity",
             "selected_timeline_integrity_issue_types" => ["missing_dependency_activity"],
             "selected_missing_dependency_activity_ids" => ["missing_gate"],
             "selected_activity" => %{
               "activity_id" => "obs_waiting_on_gate",
               "timeline_integrity_status" => "review_required",
               "timeline_integrity_issue_types" => ["missing_dependency_activity"],
               "missing_dependency_activity_ids" => ["missing_gate"]
             }
           } =
             Timeline.transition_application(missing_dependency_source, missing_dependency_source)

    self_dependency_source = %{
      id: :obs_waiting_on_self,
      type: :observe,
      target_id: :target_alpha,
      starts_at_s: 45.0,
      ends_at_s: 55.0,
      depends_on: [:obs_waiting_on_self],
      metadata: %{timeline_id: :"timeline:obs_waiting_on_self"}
    }

    assert %{
             "transition_decision" => "review",
             "application_status" => "operator_review_required",
             "requires_operator_review" => true,
             "required_operator_action" => "review_timeline_integrity",
             "transition_decision_reason" =>
               "source and replacement timeline activities require integrity review"
           } = Timeline.transition_application(self_dependency_source, self_dependency_source)

    dependency_check_disabled =
      Timeline.transition_application(
        missing_dependency_source,
        missing_dependency_source,
        validate_selected_dependencies?: false
      )

    assert %{
             "transition_decision" => "none",
             "application_status" => "source_unchanged",
             "requires_operator_review" => false,
             "selected_activity" => %{
               "activity_id" => "obs_waiting_on_gate"
             }
           } = dependency_check_disabled

    refute Map.has_key?(dependency_check_disabled, "selected_timeline_integrity_issue_types")

    refute Map.has_key?(
             dependency_check_disabled["selected_activity"],
             "timeline_integrity_status"
           )

    assert %{
             "transition_decision" => "review",
             "application_status" => "operator_review_required"
           } =
             identity_review =
             Timeline.transition_application(
               %{id: :obs_1, type: :observe, metadata: %{timeline_id: :"timeline:old"}},
               %{id: :obs_1, type: :observe, metadata: %{timeline_id: :"timeline:new"}}
             )

    refute Map.has_key?(identity_review, "selected_activity")

    assert %{
             "transition_decision" => "none",
             "application_status" => "no_activity"
           } = Timeline.transition_application(nil, nil)

    assert OrbitalDynamics.timeline_transition_application(
             protected_source,
             protected_replacement
           ) ==
             Timeline.transition_application(protected_source, protected_replacement)
  end

  test "preserves helper transition provenance through transition application reports" do
    activity = %{
      id: :cmd_transition,
      type: :command,
      scenario_id: :leo_1,
      status: "In Progress",
      approval_status: :pending,
      metadata: %{
        timeline_id: :"timeline:cmd_transition",
        source_window_id: :"window:cmd_transition"
      }
    }

    assert {:ok, completed} = Timeline.transition_activity_status(activity, "succeeded")

    assert %{
             "helper" => "transition_activity_status",
             "field" => "status",
             "transition_type" => "changed",
             "from" => "executing",
             "to" => "completed",
             "requires_operator_review" => false
           } = provenance = completed["transition_application_provenance"]

    assert %{
             "transition_decision" => "record",
             "application_status" => "replacement_recorded",
             "selected_activity_source" => "replacement",
             "transition_application_provenance" => ^provenance,
             "selected_activity" => %{
               "activity_id" => "cmd_transition",
               "status" => "completed",
               "transition_application_provenance" => ^provenance,
               "activity_context" => %{
                 "transition_application_provenance" => ^provenance
               }
             }
           } = Timeline.transition_application(activity, completed)

    protected_activity = Map.put(activity, :locked, true)

    assert {:ok, protected_completed} =
             Timeline.transition_activity_status(protected_activity, "succeeded")

    assert %{
             "transition_decision" => "preserve_source",
             "application_status" => "source_preserved_pending_review",
             "selected_activity_source" => "source",
             "selected_activity" => %{
               "activity_id" => "cmd_transition",
               "status" => "executing"
             }
           } =
             protected_application =
             Timeline.transition_application(protected_activity, protected_completed)

    refute Map.has_key?(protected_application, "transition_application_provenance")

    assert %{
             "applications" => [application],
             "selected_activities" => [selected]
           } = report = Timeline.transition_application_report([activity], [completed])

    assert application["transition_application_provenance"] == provenance

    assert get_in(application, ["selected_activity", "transition_application_provenance"]) ==
             provenance

    assert selected["transition_application_provenance"] == provenance

    assert get_in(selected, ["activity_context", "transition_application_provenance"]) ==
             provenance

    assert {:ok, %{"schema_contract" => "timeline_transition_application_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "builds batch transition application plans without selecting review gated changes" do
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

    source = [protected_source, unchanged, removed]
    replacement = [protected_replacement, unchanged, added]

    assert %{
             "source_activity_count" => 3,
             "replacement_activity_count" => 3,
             "application_count" => 4,
             "selected_activity_count" => 2,
             "review_required_count" => 3,
             "preserved_source_count" => 1,
             "withheld_review_count" => 2,
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
               "approval_review_required" => 1,
               "approval_removed" => 1
             },
             "selected_activities" => selected,
             "applications" => applications
           } = Timeline.transition_application_report(source, replacement)

    assert Enum.map(selected, & &1["activity_id"]) |> Enum.sort() == ["cmd_lock", "obs_keep"]

    assert %{
             "timeline_id" => "timeline:cmd_lock",
             "transition_decision" => "preserve_source",
             "application_status" => "source_preserved_pending_review",
             "selected_activity_source" => "source",
             "selected_activity" => %{"activity_id" => "cmd_lock", "starts_at_s" => 10.0},
             "source_timeline_diff" => %{"requires_operator_review" => true}
           } = Enum.find(applications, &(&1["timeline_id"] == "timeline:cmd_lock"))

    assert %{
             "timeline_id" => "timeline:new_cmd",
             "transition_decision" => "review",
             "application_status" => "operator_review_required",
             "replacement_activity_type" => "command",
             "status_transition" => %{
               "field" => "status",
               "transition_type" => "added",
               "transition_category" => "status_added"
             },
             "approval_transition" => %{
               "field" => "approval_status",
               "transition_type" => "added",
               "transition_category" => "approval_review_required"
             },
             "source_timeline_diff" => %{
               "status_transition" => %{"transition_type" => "added"},
               "approval_transition" => %{"transition_type" => "added"}
             }
           } =
             added_application =
             Enum.find(applications, &(&1["timeline_id"] == "timeline:new_cmd"))

    refute Map.has_key?(added_application, "selected_activity")

    assert {:ok, %{"schema_contract" => "timeline_transition_application_report.v1"}} =
             Schema.validate_artifact(Timeline.transition_application_report(source, replacement))

    transition_report = Timeline.transition_application_report(source, replacement)
    review = OrbitalDynamics.operator_review_package(transition_report)
    manifest = OrbitalDynamics.cadence_import_manifest(transition_report)

    assert %{
             "source_artifact_type" => "timeline_transition_application_report.v1",
             "review_count" => 3,
             "timeline_diff_count" => 3
           } = review

    assert Enum.any?(
             review["rows"],
             &(&1["source"] == "timeline_transition_application_report.applications" and
                 &1["application_status"] == "source_preserved_pending_review" and
                 get_in(&1, ["selected_activity", "activity_id"]) == "cmd_lock")
           )

    assert %{
             "status_transition" => %{"transition_type" => "added"},
             "approval_transition" => %{"transition_type" => "added"},
             "source_timeline_application" => %{
               "status_transition" => %{"transition_category" => "status_added"},
               "approval_transition" => %{"transition_category" => "approval_review_required"}
             }
           } = Enum.find(review["rows"], &(&1["timeline_id"] == "timeline:new_cmd"))

    assert %{
             "source_artifact_type" => "timeline_transition_application_report.v1",
             "row_count" => 3,
             "review_required_count" => 3
           } = manifest

    assert Enum.any?(
             manifest["rows"],
             &(&1["source_review_type"] == "timeline_diff_review" and
                 &1["import_action"] == "review_timeline_diff" and
                 &1["application_status"] == "source_preserved_pending_review")
           )

    assert %{
             "status_transition" => %{"transition_type" => "added"},
             "approval_transition" => %{"transition_type" => "added"},
             "source_timeline_application" => %{
               "status_transition" => %{"transition_category" => "status_added"},
               "approval_transition" => %{"transition_category" => "approval_review_required"}
             }
           } = Enum.find(manifest["rows"], &(&1["timeline_id"] == "timeline:new_cmd"))

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    assert OrbitalDynamics.timeline_transition_application_report(source, replacement) ==
             Timeline.transition_application_report(source, replacement)
  end

  test "builds compact transition application summaries" do
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

    source = [protected_source, unchanged]
    replacement = [protected_replacement, unchanged, added]
    report = Timeline.transition_application_report(source, replacement)
    summary = Timeline.transition_application_summary(report)

    assert Timeline.transition_application_report(report) == report
    assert OrbitalDynamics.timeline_transition_application_report(report) == report

    atom_keyed_report =
      Map.new(report, fn {key, value} -> {String.to_atom(key), value} end)

    assert Timeline.transition_application_report(atom_keyed_report) == report
    assert OrbitalDynamics.timeline_transition_application_report(atom_keyed_report) == report

    assert %{
             "schema_contract" => "timeline_transition_application_summary.v1",
             "model" => "artifact_only_timeline_transition_application_summary",
             "validation_level" => "artifact_contract",
             "source_artifact_type" => "timeline_transition_application_report.v1",
             "source_activity_count" => 2,
             "replacement_activity_count" => 3,
             "application_count" => 3,
             "selected_activity_count" => 2,
             "review_required_count" => 2,
             "preserved_source_count" => 1,
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
             "review_applications" => review_applications,
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_schedule_mutation",
               "operator_authority" => "not_granted_by_summary"
             },
             "model_limits" => model_limits
           } = summary

    assert "artifact_level_only" in model_limits

    assert Enum.map(review_applications, & &1["timeline_id"]) |> Enum.sort() == [
             "timeline:cmd_lock",
             "timeline:new_cmd"
           ]

    assert {:ok, %{"schema_contract" => "timeline_transition_application_summary.v1"}} =
             Schema.validate_artifact(summary)

    atom_keyed_summary =
      summary
      |> Map.delete("schema_contract")
      |> Map.put(:schema_contract, "timeline_transition_application_summary.v1")

    assert Timeline.transition_application_summary(summary) == summary
    assert Timeline.transition_application_summary(atom_keyed_summary) == summary
    assert OrbitalDynamics.timeline_transition_application_summary(summary) == summary

    stale_review_count = Map.put(summary, "review_required_count", 1)

    assert {:error, stale_review_count_report} = Schema.validate_artifact(stale_review_count)

    assert Enum.any?(
             stale_review_count_report["errors"],
             &(&1["path"] == "$.review_required_count" and
                 &1["message"] ==
                   "must equal review-application-derived review_required_count")
           )

    stale_review_ids = Map.put(summary, "review_timeline_ids", ["timeline:cmd_lock"])

    assert {:error, stale_review_ids_report} = Schema.validate_artifact(stale_review_ids)

    assert Enum.any?(
             stale_review_ids_report["errors"],
             &(&1["path"] == "$.review_timeline_ids" and
                 &1["message"] == "must equal review-application-derived review_timeline_ids")
           )

    stale_review_activity_ids = Map.put(summary, "review_activity_ids", ["cmd_lock"])

    assert {:error, stale_review_activity_ids_report} =
             Schema.validate_artifact(stale_review_activity_ids)

    assert Enum.any?(
             stale_review_activity_ids_report["errors"],
             &(&1["path"] == "$.review_activity_ids" and
                 &1["message"] == "must equal review-application-derived review_activity_ids")
           )

    stale_withheld_ids = Map.put(summary, "withheld_review_timeline_ids", [])

    assert {:error, stale_withheld_ids_report} = Schema.validate_artifact(stale_withheld_ids)

    assert Enum.any?(
             stale_withheld_ids_report["errors"],
             &(&1["path"] == "$.withheld_review_timeline_ids" and
                 &1["message"] ==
                   "must equal review-application-derived withheld_review_timeline_ids")
           )

    assert Timeline.transition_application_summary(source, replacement) == summary
    assert OrbitalDynamics.timeline_transition_application_summary(report) == summary
    assert OrbitalDynamics.timeline_transition_application_summary(source, replacement) == summary
    assert read_json!("study_results/timeline_transition_application_summary_v1.json") == summary

    stale_summary_count_report =
      Map.merge(report, %{
        "application_count" => 99,
        "selected_activity_count" => 99,
        "review_required_count" => 99,
        "preserved_source_count" => 99,
        "recorded_replacement_count" => 99,
        "withheld_review_count" => 99,
        "selected_timeline_integrity_review_count" => 99,
        "selected_timeline_integrity_issue_count" => 99,
        "selected_timeline_integrity_issue_types" => ["stale_issue"],
        "application_status_counts" => %{"stale_status" => 99},
        "transition_decision_counts" => %{"stale_decision" => 99},
        "required_operator_action_counts" => %{"stale_action" => 99},
        "status_transition_category_counts" => %{"stale_status_category" => 99},
        "approval_transition_category_counts" => %{"stale_approval_category" => 99}
      })

    assert %{
             "application_count" => 3,
             "selected_activity_count" => 2,
             "review_required_count" => 2,
             "preserved_source_count" => 1,
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
             "required_operator_action_counts" => %{
               "none" => 1,
               "review_added_activity" => 1,
               "review_changed_protected_activity" => 1
             },
             "status_transition_category_counts" => %{
               "status_added" => 1
             },
             "approval_transition_category_counts" => %{
               "approval_review_required" => 1
             }
           } = stale_summary = Timeline.transition_application_summary(stale_summary_count_report)

    assert stale_summary["recorded_replacement_count"] == 0
    assert stale_summary["selected_timeline_integrity_review_count"] == 0
    assert stale_summary["selected_timeline_integrity_issue_count"] == 0
    assert stale_summary["selected_timeline_integrity_issue_types"] == []
  end

  test "extracts transition selected activities from reports and source timelines" do
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
      id: :coast_keep,
      type: :coast,
      starts_at_s: 30.0,
      ends_at_s: 40.0,
      metadata: %{timeline_id: :"timeline:coast_keep"}
    }

    review_only_added = %{
      id: :cmd_new,
      type: :command,
      starts_at_s: 50.0,
      ends_at_s: 60.0,
      metadata: %{timeline_id: :"timeline:cmd_new"}
    }

    source = [protected_source, unchanged]
    replacement = [protected_replacement, unchanged, review_only_added]
    report = Timeline.transition_application_report(source, replacement)

    assert [
             %{
               "activity_id" => "cmd_lock",
               "starts_at_s" => 10.0,
               "protection_decision" => "preserve"
             },
             %{
               "activity_id" => "coast_keep",
               "starts_at_s" => 30.0,
               "ends_at_s" => 40.0
             }
           ] = Timeline.transition_selected_activities(report)

    refute Enum.any?(
             Timeline.transition_selected_activities(report),
             &(&1["activity_id"] == "cmd_new")
           )

    assert Timeline.transition_selected_activities(source, replacement) ==
             Timeline.transition_selected_activities(report)

    assert OrbitalDynamics.timeline_transition_selected_activities(source, replacement) ==
             Timeline.transition_selected_activities(report)

    assert OrbitalDynamics.timeline_transition_selected_activities(%{
             selected_activities: report["selected_activities"]
           }) == Timeline.transition_selected_activities(report)

    assert {:ok, %{"schema_contract" => "timeline_transition_application_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "rechecks selected transition application subset for withheld dependencies" do
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

    report =
      Timeline.transition_application_report([dependency, protected_source], [
        protected_replacement
      ])

    assert %{
             "selected_activity_count" => 1,
             "selected_timeline_integrity_review_count" => 1,
             "selected_timeline_integrity_issue_count" => 1,
             "selected_timeline_integrity_issue_types" => ["missing_dependency_activity"]
           } = report

    assert %{
             "activity_id" => "cmd_lock",
             "timeline_integrity_status" => "review_required",
             "timeline_integrity_issue_types" => ["missing_dependency_activity"],
             "missing_dependency_activity_ids" => ["cmd_prereq"]
           } = List.first(report["selected_activities"])

    assert %{
             "application_status" => "source_preserved_pending_review",
             "selected_activity" => %{
               "activity_id" => "cmd_lock",
               "timeline_integrity_status" => "review_required",
               "missing_dependency_activity_ids" => ["cmd_prereq"]
             }
           } = Enum.find(report["applications"], &(&1["timeline_id"] == "timeline:cmd_lock"))

    assert report["assumptions"]["selected_missing_dependency_validation"] == "enabled"

    assert {:ok, %{"schema_contract" => "timeline_transition_application_report.v1"}} =
             Schema.validate_artifact(report)

    report_without_selected_dependency_check =
      Timeline.transition_application_report(
        [dependency, protected_source],
        [protected_replacement],
        validate_selected_dependencies?: false
      )

    assert report_without_selected_dependency_check["selected_timeline_integrity_issue_count"] ==
             0

    assert report_without_selected_dependency_check["selected_timeline_integrity_issue_types"] ==
             []

    assert report_without_selected_dependency_check["assumptions"][
             "selected_missing_dependency_validation"
           ] == "disabled"

    unchanged_with_missing_dependency = %{
      id: :obs_waiting_on_gate,
      type: :observe,
      target_id: :target_alpha,
      starts_at_s: 30.0,
      ends_at_s: 40.0,
      depends_on: [:missing_gate],
      metadata: %{timeline_id: :"timeline:obs_waiting_on_gate"}
    }

    gated_report =
      Timeline.transition_application_report(
        [unchanged_with_missing_dependency],
        [unchanged_with_missing_dependency]
      )

    assert %{
             "review_required_count" => 1,
             "withheld_review_count" => 0,
             "application_status_counts" => %{
               "selected_timeline_integrity_review_required" => 1
             }
           } = gated_report

    assert %{
             "timeline_id" => "timeline:obs_waiting_on_gate",
             "diff_status" => "unchanged",
             "transition_decision" => "none",
             "application_status" => "selected_timeline_integrity_review_required",
             "requires_operator_review" => true,
             "required_operator_action" => "review_timeline_integrity",
             "selected_timeline_integrity_issue_types" => ["missing_dependency_activity"],
             "selected_missing_dependency_activity_ids" => ["missing_gate"]
           } = List.first(gated_report["applications"])

    review = OrbitalDynamics.operator_review_package(gated_report)

    assert %{
             "review_count" => 1,
             "rows" => [
               %{
                 "timeline_id" => "timeline:obs_waiting_on_gate",
                 "required_operator_action" => "review_timeline_integrity",
                 "application_status" => "selected_timeline_integrity_review_required",
                 "selected_timeline_integrity_issue_types" => ["missing_dependency_activity"],
                 "selected_missing_dependency_activity_ids" => ["missing_gate"],
                 "source_timeline_application" => %{
                   "selected_timeline_integrity_issue_types" => ["missing_dependency_activity"]
                 }
               }
             ]
           } = review

    assert {:ok, %{"schema_contract" => "timeline_transition_application_report.v1"}} =
             Schema.validate_artifact(gated_report)

    assert_rejects_stale_transition_selected_activity_evidence(
      gated_report,
      "timeline:obs_waiting_on_gate",
      "selected_missing_dependency_activity_ids",
      ["other_gate"],
      "missing_dependency_activity_ids"
    )

    unchanged_with_self_dependency = %{
      id: :obs_waiting_on_self,
      type: :observe,
      target_id: :target_alpha,
      starts_at_s: 45.0,
      ends_at_s: 55.0,
      depends_on: [:obs_waiting_on_self],
      metadata: %{timeline_id: :"timeline:obs_waiting_on_self"}
    }

    self_dependency_report =
      Timeline.transition_application_report(
        [unchanged_with_self_dependency],
        [unchanged_with_self_dependency]
      )

    assert %{
             "application_status" => "operator_review_required",
             "transition_decision" => "review",
             "required_operator_action" => "review_timeline_integrity",
             "source_timeline_diff" => %{
               "source_timeline_integrity_issue_types" => ["self_dependency_activity"],
               "source_self_dependency_activity_ids" => ["obs_waiting_on_self"],
               "replacement_self_dependency_activity_ids" => ["obs_waiting_on_self"]
             }
           } = List.first(self_dependency_report["applications"])

    assert {:ok, %{"schema_contract" => "timeline_transition_application_report.v1"}} =
             Schema.validate_artifact(self_dependency_report)

    duplicate_exclusivity_source = %{
      id: :obs_duplicate_exclusivity,
      type: :observe,
      target_id: :target_alpha,
      status: :planned,
      approval_status: :approved,
      locked: true,
      starts_at_s: 60.0,
      ends_at_s: 70.0,
      exclusive_with_activity_ids: [:dl_clear, :dl_clear],
      metadata: %{timeline_id: :"timeline:obs_duplicate_exclusivity"}
    }

    duplicate_exclusivity_report =
      Timeline.transition_application_report(
        [duplicate_exclusivity_source],
        [],
        validate_selected_dependencies?: false
      )

    assert %{
             "application_status" => "source_preserved_pending_review",
             "selected_activity_source" => "source",
             "selected_timeline_integrity_issue_types" => ["duplicate_exclusivity_activity"],
             "selected_duplicate_exclusivity_activity_ids" => ["dl_clear"],
             "selected_activity" => %{
               "duplicate_exclusivity_activity_ids" => ["dl_clear"]
             }
           } = List.first(duplicate_exclusivity_report["applications"])

    duplicate_exclusivity_review =
      OrbitalDynamics.operator_review_package(duplicate_exclusivity_report)

    assert [duplicate_exclusivity_review_row] = duplicate_exclusivity_review["rows"]

    assert duplicate_exclusivity_review_row["selected_duplicate_exclusivity_activity_ids"] == [
             "dl_clear"
           ]

    assert get_in(duplicate_exclusivity_review_row, [
             "source_timeline_application",
             "selected_duplicate_exclusivity_activity_ids"
           ]) == ["dl_clear"]

    duplicate_exclusivity_manifest =
      CadenceImport.from_timeline_transition_application_report(duplicate_exclusivity_report)

    assert [duplicate_exclusivity_manifest_row] = duplicate_exclusivity_manifest["rows"]

    assert duplicate_exclusivity_manifest_row["selected_duplicate_exclusivity_activity_ids"] == [
             "dl_clear"
           ]

    assert get_in(duplicate_exclusivity_manifest_row, [
             "source_review_row",
             "selected_duplicate_exclusivity_activity_ids"
           ]) == ["dl_clear"]

    assert {:ok, %{"schema_contract" => "timeline_transition_application_report.v1"}} =
             Schema.validate_artifact(duplicate_exclusivity_report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(duplicate_exclusivity_review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(duplicate_exclusivity_manifest)

    manifest = CadenceImport.from_timeline_transition_application_report(gated_report)

    assert %{
             "row_count" => 1,
             "rows" => [
               %{
                 "timeline_id" => "timeline:obs_waiting_on_gate",
                 "required_operator_action" => "review_timeline_integrity",
                 "application_status" => "selected_timeline_integrity_review_required",
                 "selected_timeline_integrity_issue_types" => ["missing_dependency_activity"],
                 "selected_missing_dependency_activity_ids" => ["missing_gate"],
                 "source_review_row" => %{
                   "selected_timeline_integrity_issue_types" => ["missing_dependency_activity"],
                   "selected_missing_dependency_activity_ids" => ["missing_gate"]
                 },
                 "source_timeline_application" => %{
                   "selected_timeline_integrity_issue_types" => ["missing_dependency_activity"]
                 }
               }
             ]
           } = manifest

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "transition application handoffs preserve selected exclusivity overlap evidence" do
    obs_overlap = %{
      id: :obs_overlap,
      type: :observe,
      target_id: :target_a,
      status: :planned,
      approval_status: :approved,
      locked: true,
      starts_at_s: 10.0,
      ends_at_s: 20.0,
      exclusive_with_activity_ids: [:dl_overlap],
      metadata: %{timeline_id: :"timeline:obs_overlap"}
    }

    dl_overlap = %{
      id: :dl_overlap,
      type: :downlink,
      ground_station_id: :dss_14,
      status: :planned,
      approval_status: :approved,
      locked: true,
      starts_at_s: 15.0,
      ends_at_s: 25.0,
      metadata: %{timeline_id: :"timeline:dl_overlap"}
    }

    report =
      Timeline.transition_application_report([obs_overlap, dl_overlap], [],
        validate_selected_dependencies?: false
      )

    assert %{
             "selected_activity_count" => 2,
             "selected_timeline_integrity_review_count" => 1,
             "selected_timeline_integrity_issue_count" => 1,
             "selected_timeline_integrity_issue_types" => ["exclusivity_overlap"]
           } = report

    assert %{
             "timeline_id" => "timeline:obs_overlap",
             "selected_timeline_integrity_issue_types" => ["exclusivity_overlap"],
             "selected_exclusivity_violation_activity_ids" => ["dl_overlap"],
             "selected_exclusivity_violation_timeline_ids" => ["timeline:dl_overlap"],
             "selected_activity" => %{
               "exclusive_with_activity_ids" => ["dl_overlap"],
               "exclusivity_violation_activity_ids" => ["dl_overlap"],
               "exclusivity_violation_timeline_ids" => ["timeline:dl_overlap"]
             }
           } = Enum.find(report["applications"], &(&1["timeline_id"] == "timeline:obs_overlap"))

    review = OperatorReview.from_timeline_transition_application_report(report)
    review_row = Enum.find(review["rows"], &(&1["timeline_id"] == "timeline:obs_overlap"))

    assert %{
             "selected_timeline_integrity_issue_types" => ["exclusivity_overlap"],
             "selected_exclusivity_violation_activity_ids" => ["dl_overlap"],
             "selected_exclusivity_violation_timeline_ids" => ["timeline:dl_overlap"],
             "source_timeline_application" => %{
               "selected_exclusivity_violation_activity_ids" => ["dl_overlap"],
               "selected_exclusivity_violation_timeline_ids" => ["timeline:dl_overlap"]
             }
           } = review_row

    manifest = CadenceImport.from_timeline_transition_application_report(report)
    manifest_row = Enum.find(manifest["rows"], &(&1["timeline_id"] == "timeline:obs_overlap"))

    assert %{
             "selected_timeline_integrity_issue_types" => ["exclusivity_overlap"],
             "selected_exclusivity_violation_activity_ids" => ["dl_overlap"],
             "selected_exclusivity_violation_timeline_ids" => ["timeline:dl_overlap"],
             "source_review_row" => %{
               "selected_exclusivity_violation_activity_ids" => ["dl_overlap"],
               "selected_exclusivity_violation_timeline_ids" => ["timeline:dl_overlap"]
             }
           } = manifest_row

    assert {:ok, %{"schema_contract" => "timeline_transition_application_report.v1"}} =
             Schema.validate_artifact(report)

    assert_rejects_stale_transition_selected_activity_evidence(
      report,
      "timeline:obs_overlap",
      "selected_exclusivity_violation_timeline_ids",
      ["timeline:other_overlap"],
      "exclusivity_violation_timeline_ids"
    )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    group_obs_overlap = %{
      id: :group_obs_overlap,
      type: :observe,
      target_id: :target_a,
      status: :planned,
      approval_status: :approved,
      locked: true,
      starts_at_s: 30.0,
      ends_at_s: 40.0,
      exclusivity_group: :station_dss_14,
      metadata: %{timeline_id: :"timeline:group_obs_overlap"}
    }

    group_dl_overlap = %{
      id: :group_dl_overlap,
      type: :downlink,
      ground_station_id: :dss_14,
      status: :planned,
      approval_status: :approved,
      locked: true,
      starts_at_s: 35.0,
      ends_at_s: 45.0,
      exclusivity_group: :station_dss_14,
      metadata: %{timeline_id: :"timeline:group_dl_overlap"}
    }

    group_report =
      Timeline.transition_application_report([group_obs_overlap, group_dl_overlap], [],
        validate_selected_dependencies?: false
      )

    assert %{
             "selected_timeline_integrity_issue_types" => ["exclusivity_group_overlap"],
             "selected_exclusivity_violation_activity_ids" => ["group_dl_overlap"],
             "selected_exclusivity_violation_timeline_ids" => ["timeline:group_dl_overlap"],
             "selected_exclusivity_violation_group" => "station_dss_14",
             "selected_activity" => %{
               "exclusivity_violation_activity_ids" => ["group_dl_overlap"],
               "exclusivity_violation_timeline_ids" => ["timeline:group_dl_overlap"],
               "exclusivity_violation_group" => "station_dss_14"
             }
           } =
             Enum.find(
               group_report["applications"],
               &(&1["timeline_id"] == "timeline:group_obs_overlap")
             )

    group_review = OperatorReview.from_timeline_transition_application_report(group_report)

    group_review_row =
      Enum.find(group_review["rows"], &(&1["timeline_id"] == "timeline:group_obs_overlap"))

    assert %{
             "selected_exclusivity_violation_group" => "station_dss_14",
             "source_timeline_application" => %{
               "selected_exclusivity_violation_group" => "station_dss_14"
             }
           } = group_review_row

    group_manifest = CadenceImport.from_timeline_transition_application_report(group_report)

    group_manifest_row =
      Enum.find(group_manifest["rows"], &(&1["timeline_id"] == "timeline:group_obs_overlap"))

    assert %{
             "selected_exclusivity_violation_group" => "station_dss_14",
             "source_review_row" => %{
               "selected_exclusivity_violation_group" => "station_dss_14"
             }
           } = group_manifest_row

    assert {:ok, %{"schema_contract" => "timeline_transition_application_report.v1"}} =
             Schema.validate_artifact(group_report)

    assert_rejects_stale_transition_selected_activity_evidence(
      group_report,
      "timeline:group_obs_overlap",
      "selected_exclusivity_violation_group",
      "station_other",
      "exclusivity_violation_group"
    )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(group_review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(group_manifest)
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end

  defp assert_rejects_stale_transition_selected_activity_evidence(
         report,
         timeline_id,
         field,
         stale_value,
         selected_activity_field
       ) do
    application_index =
      Enum.find_index(report["applications"], &(&1["timeline_id"] == timeline_id))

    invalid_report =
      update_in(report, ["applications", Access.at(application_index)], fn application ->
        Map.put(application, field, stale_value)
      end)

    assert {:error, validation_report} = Schema.validate_artifact(invalid_report)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.applications[#{application_index}].#{field}" and
                 &1["message"] == "must match selected_activity #{selected_activity_field} values")
           )
  end
end
