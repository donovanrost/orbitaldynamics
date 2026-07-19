defmodule OrbitalDynamics.CadenceImportTimelineTransitionTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, Schema, Timeline}

  test "builds timeline transition application import rows for review gated changes" do
    source = [
      %{
        id: :cmd_lock,
        type: :command,
        status: :planned,
        approval_status: :approved,
        locked: true,
        starts_at_s: 10.0,
        ends_at_s: 20.0,
        metadata: %{timeline_id: :"timeline:cmd_lock"}
      },
      %{
        id: :obs_self_dependency,
        type: :observe,
        target_id: :target_a,
        starts_at_s: 60.0,
        ends_at_s: 70.0,
        depends_on: [:obs_self_dependency],
        metadata: %{timeline_id: :"timeline:obs_self_dependency"}
      }
    ]

    replacement = [
      %{
        id: :cmd_lock,
        type: :command,
        status: :planned,
        approval_status: :approved,
        locked: true,
        starts_at_s: 15.0,
        ends_at_s: 25.0,
        metadata: %{timeline_id: :"timeline:cmd_lock"}
      },
      %{
        id: :cmd_added,
        type: :command,
        starts_at_s: 40.0,
        ends_at_s: 50.0,
        metadata: %{timeline_id: :"timeline:cmd_added"}
      },
      %{
        id: :obs_self_dependency,
        type: :observe,
        target_id: :target_a,
        starts_at_s: 60.0,
        ends_at_s: 70.0,
        depends_on: [:obs_self_dependency],
        metadata: %{timeline_id: :"timeline:obs_self_dependency"}
      }
    ]

    report =
      OrbitalDynamics.Timeline.transition_application_report(source, replacement,
        source: "timeline_transition_application_report"
      )

    approval_policy = %{
      action_rules: [
        %{
          id: "transition_application_preserve_review",
          application_status: "source_preserved_pending_review",
          classification: "operator_review_required",
          reason: "source-preserved transition application requires mission planning review",
          escalation_queue: "mission_planning",
          required_authority: "mission_planning_authority",
          sla_s: 900
        }
      ]
    }

    manifest = OrbitalDynamics.cadence_import_manifest(report, approval_policy: approval_policy)

    direct_manifest =
      CadenceImport.from_timeline_transition_application_report(report,
        approval_policy: approval_policy
      )

    atom_key_report =
      report
      |> Enum.map(fn {key, value} -> {String.to_atom(key), value} end)
      |> Map.new()

    assert manifest == direct_manifest
    assert CadenceImport.manifest(report, approval_policy: approval_policy) == direct_manifest

    assert OrbitalDynamics.cadence_import_manifest(atom_key_report,
             approval_policy: approval_policy
           ) == direct_manifest

    assert %{
             "source_artifact_type" => "timeline_transition_application_report.v1",
             "source_artifact_id" => "timeline_transition_application_report",
             "row_count" => 3,
             "review_required_count" => 3
           } = manifest

    assert %{
             "import_action" => "review_timeline_diff",
             "source_review_type" => "timeline_diff_review",
             "timeline_id" => "timeline:cmd_lock",
             "application_status" => "source_preserved_pending_review",
             "selected_activity_source" => "source",
             "selected_activity" => %{"activity_id" => "cmd_lock", "starts_at_s" => 10.0},
             "policy_classification" => "operator_review_required",
             "approval_rule_matches" => [
               %{
                 "rule_id" => "transition_application_preserve_review",
                 "classification" => "operator_review_required"
               }
             ],
             "source_policy_decision" => %{
               "schema_contract" => "policy_decision.v1",
               "classification" => "operator_review_required"
             },
             "source_timeline_application" => %{
               "application_status" => "source_preserved_pending_review"
             },
             "source_review_row" => %{
               "application_status" => "source_preserved_pending_review"
             }
           } = Enum.find(manifest["rows"], &(&1["timeline_id"] == "timeline:cmd_lock"))

    assert %{
             "timeline_id" => "timeline:cmd_added",
             "application_status" => "operator_review_required",
             "replacement_activity_type" => "command",
             "status_transition" => %{
               "transition_type" => "added",
               "transition_category" => "status_added"
             },
             "approval_transition" => %{
               "transition_type" => "added",
               "transition_category" => "approval_review_required"
             },
             "source_timeline_application" => %{
               "status_transition" => %{"transition_category" => "status_added"},
               "approval_transition" => %{"transition_category" => "approval_review_required"}
             },
             "source_review_row" => %{
               "source_timeline_application" => %{
                 "status_transition" => %{"transition_category" => "status_added"},
                 "approval_transition" => %{"transition_category" => "approval_review_required"}
               }
             }
           } = added = Enum.find(manifest["rows"], &(&1["timeline_id"] == "timeline:cmd_added"))

    refute Map.has_key?(added, "selected_activity")

    assert %{
             "timeline_id" => "timeline:obs_self_dependency",
             "application_status" => "operator_review_required",
             "required_operator_action" => "review_timeline_integrity",
             "source_timeline_integrity_issue_types" => ["self_dependency_activity"],
             "source_self_dependency_activity_ids" => ["obs_self_dependency"],
             "replacement_timeline_integrity_issue_types" => ["self_dependency_activity"],
             "replacement_self_dependency_activity_ids" => ["obs_self_dependency"],
             "source_timeline_application" => %{
               "source_timeline_diff" => %{
                 "source_self_dependency_activity_ids" => ["obs_self_dependency"],
                 "replacement_self_dependency_activity_ids" => ["obs_self_dependency"]
               }
             },
             "source_review_row" => %{
               "source_self_dependency_activity_ids" => ["obs_self_dependency"],
               "replacement_self_dependency_activity_ids" => ["obs_self_dependency"]
             }
           } = Enum.find(manifest["rows"], &(&1["timeline_id"] == "timeline:obs_self_dependency"))

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "timeline transition application summaries become import manifest rows" do
    summary = timeline_transition_application_summary()
    manifest = CadenceImport.from_timeline_transition_application_summary(summary)

    atom_key_summary =
      summary
      |> Enum.map(fn {key, value} -> {String.to_atom(key), value} end)
      |> Map.new()

    assert %{
             "source_artifact_type" => "timeline_transition_application_summary.v1",
             "source_artifact_id" => "transition_summary_source",
             "row_count" => 3,
             "review_required_count" => 3,
             "import_action_counts" => %{"review_timeline_diff" => 3},
             "source_review_type_counts" => %{"timeline_diff_review" => 3}
           } = manifest

    assert %{
             "import_action" => "review_timeline_diff",
             "source_review_type" => "timeline_diff_review",
             "timeline_id" => "timeline:cmd_lock",
             "application_status" => "source_preserved_pending_review",
             "selected_activity_source" => "source",
             "source_transition_application_count" => 3,
             "source_transition_application_review_required_count" => 3,
             "source_transition_application_selected_activity_ids" => ["cmd_lock"],
             "source_transition_application_review_activity_ids" => [
               "cmd_added",
               "cmd_lock",
               "obs_self_dependency"
             ],
             "source_transition_application_review_timeline_ids" => [
               "timeline:cmd_added",
               "timeline:cmd_lock",
               "timeline:obs_self_dependency"
             ],
             "source_timeline_transition_application_summary" => %{
               "model" => "artifact_only_timeline_transition_application_summary",
               "review_required_count" => 3
             },
             "source_timeline_application" => %{
               "application_status" => "source_preserved_pending_review"
             },
             "source_review_row" => %{
               "source_transition_application_review_activity_ids" => [
                 "cmd_added",
                 "cmd_lock",
                 "obs_self_dependency"
               ],
               "source_timeline_transition_application_summary" => %{
                 "selected_activity_ids" => ["cmd_lock"]
               }
             }
           } = Enum.find(manifest["rows"], &(&1["timeline_id"] == "timeline:cmd_lock"))

    assert %{
             "timeline_id" => "timeline:obs_self_dependency",
             "required_operator_action" => "review_timeline_integrity",
             "source_self_dependency_activity_ids" => ["obs_self_dependency"],
             "replacement_self_dependency_activity_ids" => ["obs_self_dependency"],
             "source_timeline_application" => %{
               "source_timeline_diff" => %{
                 "source_self_dependency_activity_ids" => ["obs_self_dependency"]
               }
             }
           } = Enum.find(manifest["rows"], &(&1["timeline_id"] == "timeline:obs_self_dependency"))

    assert CadenceImport.manifest(summary) == manifest
    assert CadenceImport.manifest(atom_key_summary) == manifest
    assert OrbitalDynamics.cadence_import_manifest(summary) == manifest

    assert OrbitalDynamics.cadence_import_manifest(Map.delete(summary, "schema_contract")) ==
             manifest

    assert OrbitalDynamics.cadence_import_manifest(atom_key_summary) == manifest

    assert OrbitalDynamics.cadence_import_manifest(Map.delete(atom_key_summary, :schema_contract)) ==
             manifest

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    invalid_source_summary_count =
      put_in(
        manifest,
        [
          "rows",
          Access.at(0),
          "source_timeline_transition_application_summary",
          "review_required_count"
        ],
        -1
      )

    assert {:error, validation_report} = Schema.validate_artifact(invalid_source_summary_count)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_timeline_transition_application_summary.review_required_count" and
                 &1["message"] =~ "non-negative integer")
           )

    invalid_nested_source_summary_id =
      put_in(
        manifest,
        [
          "rows",
          Access.at(0),
          "source_review_row",
          "source_timeline_transition_application_summary",
          "selected_activity_ids"
        ],
        ["bad activity id"]
      )

    assert {:error, validation_report} =
             Schema.validate_artifact(invalid_nested_source_summary_id)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_review_row.source_timeline_transition_application_summary.selected_activity_ids[0]" and
                 &1["message"] =~ "stable ID")
           )
  end

  test "timeline diff summaries become import manifest rows" do
    summary = timeline_diff_summary()
    manifest = CadenceImport.from_timeline_diff_summary(summary)

    atom_key_summary =
      summary
      |> Enum.map(fn {key, value} -> {String.to_atom(key), value} end)
      |> Map.new()

    assert %{
             "source_artifact_type" => "timeline_diff_summary.v1",
             "source_artifact_id" => "diff_summary_source",
             "row_count" => 3,
             "review_required_count" => 3,
             "import_action_counts" => %{"review_timeline_diff" => 3},
             "source_review_type_counts" => %{"timeline_diff_review" => 3}
           } = manifest

    assert %{
             "import_action" => "review_timeline_diff",
             "source_review_type" => "timeline_diff_review",
             "timeline_id" => "timeline:cmd_lock",
             "diff_status" => "changed",
             "transition_decision" => "preserve_source",
             "source_timeline_diff_summary_row_count" => 3,
             "source_timeline_diff_summary_review_required_count" => 3,
             "source_timeline_diff_summary_changed_count" => 1,
             "source_timeline_diff_summary_review_timeline_ids" => [
               "timeline:cmd_added",
               "timeline:cmd_lock",
               "timeline:dl_removed"
             ],
             "source_timeline_diff_summary_timeline_ids_by_changed_field" => %{
               "ends_at_s" => ["timeline:cmd_lock"],
               "starts_at_s" => ["timeline:cmd_lock"]
             },
             "source_timeline_diff_summary" => %{
               "model" => "artifact_only_timeline_diff_summary",
               "review_required_count" => 3
             },
             "source_review_row" => %{
               "source_timeline_diff_summary" => %{
                 "changed_timeline_ids" => ["timeline:cmd_lock"]
               }
             }
           } = Enum.find(manifest["rows"], &(&1["timeline_id"] == "timeline:cmd_lock"))

    assert %{
             "timeline_id" => "timeline:dl_removed",
             "diff_status" => "removed",
             "required_operator_action" => "review_removed_activity"
           } = Enum.find(manifest["rows"], &(&1["timeline_id"] == "timeline:dl_removed"))

    assert CadenceImport.manifest(summary) == manifest
    assert CadenceImport.manifest(atom_key_summary) == manifest
    assert OrbitalDynamics.cadence_import_manifest(summary) == manifest

    assert OrbitalDynamics.cadence_import_manifest(Map.delete(summary, "schema_contract")) ==
             manifest

    assert OrbitalDynamics.cadence_import_manifest(atom_key_summary) == manifest

    assert OrbitalDynamics.cadence_import_manifest(Map.delete(atom_key_summary, :schema_contract)) ==
             manifest

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    invalid_source_summary_count =
      put_in(
        manifest,
        [
          "rows",
          Access.at(0),
          "source_timeline_diff_summary",
          "review_required_count"
        ],
        -1
      )

    assert {:error, validation_report} = Schema.validate_artifact(invalid_source_summary_count)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.rows[0].source_timeline_diff_summary.review_required_count" and
                 &1["message"] =~ "non-negative integer")
           )

    invalid_nested_source_summary_id =
      put_in(
        manifest,
        [
          "rows",
          Access.at(0),
          "source_review_row",
          "source_timeline_diff_summary",
          "review_timeline_ids"
        ],
        ["bad timeline id"]
      )

    assert {:error, validation_report} =
             Schema.validate_artifact(invalid_nested_source_summary_id)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_review_row.source_timeline_diff_summary.review_timeline_ids[0]" and
                 &1["message"] =~ "stable ID")
           )
  end

  test "timeline transition import rows reject stale nested source application evidence" do
    source = [
      %{
        id: :cmd_lock,
        type: :command,
        status: :planned,
        approval_status: :approved,
        locked: true,
        starts_at_s: 10.0,
        ends_at_s: 20.0,
        metadata: %{timeline_id: :"timeline:cmd_lock"}
      }
    ]

    replacement = [
      %{
        id: :cmd_lock,
        type: :command,
        status: :planned,
        approval_status: :approved,
        locked: true,
        starts_at_s: 15.0,
        ends_at_s: 25.0,
        metadata: %{timeline_id: :"timeline:cmd_lock"}
      }
    ]

    manifest =
      source
      |> OrbitalDynamics.Timeline.transition_application_report(replacement,
        source: "timeline_transition_application_report"
      )
      |> CadenceImport.from_timeline_transition_application_report()
      |> put_in(["rows", Access.at(0), "application_status"], "operator_review_required")
      |> put_in(
        ["rows", Access.at(0), "source_timeline_application", "application_status"],
        "operator_review_required"
      )

    assert {:error, stale_source_review_report} = Schema.validate_artifact(manifest)

    assert Enum.any?(
             stale_source_review_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.application_status" and
                 &1["message"] == "must match application_status on Cadence import row")
           )
  end

  defp timeline_transition_application_summary do
    {source, replacement} = timeline_transition_application_pair()

    source
    |> Timeline.transition_application_report(replacement, source: "transition_summary_source")
    |> Timeline.transition_application_summary()
  end

  defp timeline_diff_summary do
    {source, replacement} = timeline_diff_pair()

    source
    |> Timeline.diff_report(replacement, source: "diff_summary_source")
    |> Timeline.diff_summary()
  end

  defp timeline_diff_pair do
    source = [
      %{
        id: :cmd_lock,
        type: :command,
        status: :planned,
        approval_status: :approved,
        locked: true,
        starts_at_s: 10.0,
        ends_at_s: 20.0,
        metadata: %{timeline_id: :"timeline:cmd_lock"}
      },
      %{
        id: :dl_removed,
        type: :downlink,
        starts_at_s: 30.0,
        ends_at_s: 40.0,
        metadata: %{timeline_id: :"timeline:dl_removed"}
      }
    ]

    replacement = [
      %{
        id: :cmd_lock,
        type: :command,
        status: :planned,
        approval_status: :approved,
        locked: true,
        starts_at_s: 15.0,
        ends_at_s: 25.0,
        metadata: %{timeline_id: :"timeline:cmd_lock"}
      },
      %{
        id: :cmd_added,
        type: :command,
        starts_at_s: 50.0,
        ends_at_s: 60.0,
        metadata: %{timeline_id: :"timeline:cmd_added"}
      }
    ]

    {source, replacement}
  end

  defp timeline_transition_application_pair do
    source = [
      %{
        id: :cmd_lock,
        type: :command,
        status: :planned,
        approval_status: :approved,
        locked: true,
        starts_at_s: 10.0,
        ends_at_s: 20.0,
        metadata: %{timeline_id: :"timeline:cmd_lock"}
      },
      %{
        id: :obs_self_dependency,
        type: :observe,
        target_id: :target_a,
        starts_at_s: 60.0,
        ends_at_s: 70.0,
        depends_on: [:obs_self_dependency],
        metadata: %{timeline_id: :"timeline:obs_self_dependency"}
      }
    ]

    replacement = [
      %{
        id: :cmd_lock,
        type: :command,
        status: :planned,
        approval_status: :approved,
        locked: true,
        starts_at_s: 15.0,
        ends_at_s: 25.0,
        metadata: %{timeline_id: :"timeline:cmd_lock"}
      },
      %{
        id: :cmd_added,
        type: :command,
        starts_at_s: 40.0,
        ends_at_s: 50.0,
        metadata: %{timeline_id: :"timeline:cmd_added"}
      },
      %{
        id: :obs_self_dependency,
        type: :observe,
        target_id: :target_a,
        starts_at_s: 60.0,
        ends_at_s: 70.0,
        depends_on: [:obs_self_dependency],
        metadata: %{timeline_id: :"timeline:obs_self_dependency"}
      }
    ]

    {source, replacement}
  end
end
