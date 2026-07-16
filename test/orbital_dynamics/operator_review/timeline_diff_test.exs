defmodule OrbitalDynamics.OperatorReview.TimelineDiffTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, OperatorReview, Schema, Timeline}

  test "builds review package from operator-relevant timeline diff rows" do
    report = %{
      "schema_contract" => "timeline_diff_report.v1",
      "model" => "timeline_identity_activity_diff",
      "source" => "repair.activities",
      "source_activity_count" => 2,
      "replacement_activity_count" => 2,
      "row_count" => 2,
      "added_count" => 1,
      "removed_count" => 0,
      "changed_count" => 1,
      "unchanged_count" => 0,
      "review_required_count" => 2,
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
          "source_ends_at_s" => 20.0,
          "replacement_starts_at_s" => 12.0,
          "replacement_ends_at_s" => 22.0,
          "start_delta_s" => 2.0,
          "end_delta_s" => 2.0,
          "source_status" => "approved",
          "replacement_status" => "planned",
          "source_approval_status" => "approved",
          "replacement_approval_status" => "pending",
          "source_protection_decision" => %{
            "activity_id" => "obs_1",
            "timeline_id" => "timeline:obs_1",
            "protection_decision" => "preserve",
            "protection_category" => "locked_or_approved",
            "reason" => "activity_locked_or_approved"
          },
          "source_protection_category" => "locked_or_approved",
          "source_protection_reason" => "activity_locked_or_approved",
          "replacement_protection_decision" => %{
            "activity_id" => "obs_1b",
            "timeline_id" => "timeline:obs_1",
            "protection_decision" => "mutable",
            "protection_category" => "none",
            "reason" => "no_timeline_protection"
          },
          "replacement_protection_category" => "none",
          "replacement_protection_reason" => "no_timeline_protection",
          "status_transition" => %{
            "field" => "status",
            "transition_type" => "changed",
            "from" => "approved",
            "to" => "planned"
          },
          "approval_transition" => %{
            "field" => "approval_status",
            "transition_type" => "changed",
            "from" => "approved",
            "to" => "pending"
          },
          "changed_fields" => ["starts_at_s", "ends_at_s", "approval_status"],
          "requires_operator_review" => true,
          "required_operator_action" => "review_timeline_change",
          "reason" => "replacement timeline changes activity obs_1",
          "source_timeline_identity" => %{"timeline_id" => "timeline:obs_1"},
          "replacement_timeline_identity" => %{"timeline_id" => "timeline:obs_1"}
        },
        %{
          "id" => "timeline_diff:timeline:health_1",
          "rank" => 2,
          "timeline_id" => "timeline:health_1",
          "diff_status" => "unchanged",
          "changed_fields" => [],
          "requires_operator_review" => false,
          "required_operator_action" => "none",
          "reason" => "timeline activity unchanged"
        }
      ],
      "assumptions" => %{"execution_boundary" => "artifact_only_no_schedule_mutation"}
    }

    atom_key_report =
      report
      |> Enum.map(fn {key, value} -> {String.to_atom(key), value} end)
      |> Map.new()

    package = OperatorReview.from_timeline_diff_report(report)

    assert OrbitalDynamics.operator_review_package(report) == package
    assert OrbitalDynamics.operator_review_package(atom_key_report) == package

    assert %{
             "source_artifact_type" => "timeline_diff_report.v1",
             "source_artifact_id" => "repair.activities",
             "review_count" => 1,
             "timeline_diff_count" => 1
           } = package

    assert %{
             "review_type" => "timeline_diff_review",
             "subject_id" => "timeline:obs_1",
             "timeline_id" => "timeline:obs_1",
             "diff_status" => "changed",
             "activity_id" => "obs_1b",
             "source_activity_id" => "obs_1",
             "replacement_activity_id" => "obs_1b",
             "required_operator_action" => "review_timeline_change",
             "operator_action_reason" => "replacement timeline changes activity obs_1",
             "approval_status" => "operator_review_required",
             "changed_fields" => ["starts_at_s", "ends_at_s", "approval_status"],
             "status_transition" => %{
               "field" => "status",
               "transition_type" => "changed",
               "from" => "approved",
               "to" => "planned"
             },
             "approval_transition" => %{
               "field" => "approval_status",
               "transition_type" => "changed",
               "from" => "approved",
               "to" => "pending"
             },
             "source_protection_decision" => %{
               "protection_decision" => "preserve",
               "protection_category" => "locked_or_approved"
             },
             "source_protection_category" => "locked_or_approved",
             "source_protection_reason" => "activity_locked_or_approved",
             "replacement_protection_decision" => %{
               "protection_decision" => "mutable",
               "protection_category" => "none"
             },
             "replacement_protection_category" => "none",
             "replacement_protection_reason" => "no_timeline_protection",
             "source_timeline_diff" => %{
               "requires_operator_review" => true
             }
           } = List.first(package["rows"])

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    stale_source_timeline_diff =
      update_in(package, ["rows", Access.at(0), "source_timeline_diff"], fn row ->
        row
        |> Map.put("changed_fields", ["stale_changed_field"])
        |> Map.put("requires_operator_review", false)
      end)

    assert {:error, stale_source_timeline_diff_report} =
             Schema.validate_artifact(stale_source_timeline_diff)

    assert Enum.any?(
             stale_source_timeline_diff_report["errors"],
             &(&1["path"] == "$.rows[0].changed_fields" and
                 &1["message"] == "must match source_timeline_diff.changed_fields")
           )

    assert Enum.any?(
             stale_source_timeline_diff_report["errors"],
             &(&1["path"] == "$.rows[0].requires_operator_review" and
                 &1["message"] == "must match source_timeline_diff.requires_operator_review")
           )
  end

  test "timeline diff summaries become operator review rows" do
    summary = timeline_diff_summary()
    package = OperatorReview.from_timeline_diff_summary(summary)

    atom_key_summary =
      summary
      |> Enum.map(fn {key, value} -> {String.to_atom(key), value} end)
      |> Map.new()

    assert %{
             "source_artifact_type" => "timeline_diff_summary.v1",
             "source_artifact_id" => "diff_summary_source",
             "review_count" => 3,
             "timeline_diff_count" => 3,
             "required_operator_action_counts" => %{
               "review_added_activity" => 1,
               "review_changed_protected_activity" => 1,
               "review_removed_activity" => 1
             }
           } = package

    assert %{
             "review_type" => "timeline_diff_review",
             "source" => "timeline_diff_summary.review_rows",
             "timeline_id" => "timeline:cmd_lock",
             "diff_status" => "changed",
             "transition_decision" => "preserve_source",
             "source_timeline_diff_summary_row_count" => 3,
             "source_timeline_diff_summary_review_required_count" => 3,
             "source_timeline_diff_summary_changed_count" => 1,
             "source_timeline_diff_summary_changed_field_counts" => %{
               "ends_at_s" => 1,
               "starts_at_s" => 1
             },
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
             "source_timeline_diff" => %{
               "requires_operator_review" => true
             }
           } = Enum.find(package["rows"], &(&1["timeline_id"] == "timeline:cmd_lock"))

    assert %{
             "timeline_id" => "timeline:cmd_added",
             "diff_status" => "added",
             "required_operator_action" => "review_added_activity"
           } = Enum.find(package["rows"], &(&1["timeline_id"] == "timeline:cmd_added"))

    assert OrbitalDynamics.operator_review_package(summary) == package

    assert OrbitalDynamics.operator_review_package(Map.delete(summary, "schema_contract")) ==
             package

    assert OrbitalDynamics.operator_review_package(atom_key_summary) == package

    assert OrbitalDynamics.operator_review_package(Map.delete(atom_key_summary, :schema_contract)) ==
             package

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    invalid_source_summary_ids =
      put_in(
        package,
        [
          "rows",
          Access.at(0),
          "source_timeline_diff_summary",
          "review_timeline_ids"
        ],
        ["bad timeline id"]
      )

    assert {:error, validation_report} = Schema.validate_artifact(invalid_source_summary_ids)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_timeline_diff_summary.review_timeline_ids[0]" and
                 &1["message"] =~ "stable ID")
           )
  end

  test "timeline diff report and summary source ids use id before source and defaults" do
    assert %{"source_artifact_id" => "timeline_diff:report"} =
             OperatorReview.from_timeline_diff_report(%{
               id: :"timeline_diff:report",
               source: :timeline_diff_source,
               rows: []
             })

    assert %{"source_artifact_id" => "timeline_diff_report"} =
             OperatorReview.from_timeline_diff_report(%{rows: []})

    assert %{"source_artifact_id" => "timeline_diff:summary"} =
             OperatorReview.from_timeline_diff_summary(%{
               id: :"timeline_diff:summary",
               source: :timeline_diff_summary_source,
               review_rows: []
             })

    assert %{"source_artifact_id" => "timeline_diff_summary"} =
             OperatorReview.from_timeline_diff_summary(%{review_rows: []})
  end

  test "CandidateRefresh lifts timeline diff summaries from direct and result artifacts" do
    direct_summary =
      timeline_diff_summary()
      |> Map.put("source", "diff_summary_direct")

    source_result_summary =
      timeline_diff_summary()
      |> Map.put("source", "diff_summary_source_result")

    nested_summary =
      timeline_diff_summary()
      |> Map.put("source", "diff_summary_nested_result")

    artifact = %{
      "refresh_id" => "refresh:diff_summary_result_handoff",
      "timeline_diff_summary" => direct_summary,
      "source_result_artifact" => [source_result_summary],
      "result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "timeline_diff_summary" => nested_summary
      }
    }

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)

    diff_rows =
      Enum.filter(
        review["rows"],
        &(&1["source_timeline_diff_summary"]["schema_contract"] == "timeline_diff_summary.v1")
      )

    assert length(diff_rows) == 9

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "refresh:diff_summary_result_handoff",
             "review_count" => 9,
             "timeline_diff_count" => 9,
             "required_operator_action_counts" => %{
               "review_added_activity" => 3,
               "review_changed_protected_activity" => 3,
               "review_removed_activity" => 3
             }
           } = review

    assert Enum.sort(Enum.map(diff_rows, & &1["source"])) == [
             "candidate_refresh.result_artifact.timeline_diff_summary.review_rows",
             "candidate_refresh.result_artifact.timeline_diff_summary.review_rows",
             "candidate_refresh.result_artifact.timeline_diff_summary.review_rows",
             "candidate_refresh.source_result_artifact[0].review_rows",
             "candidate_refresh.source_result_artifact[0].review_rows",
             "candidate_refresh.source_result_artifact[0].review_rows",
             "candidate_refresh.timeline_diff_summary.review_rows",
             "candidate_refresh.timeline_diff_summary.review_rows",
             "candidate_refresh.timeline_diff_summary.review_rows"
           ]

    assert Enum.all?(
             diff_rows,
             &(&1["source_timeline_diff_summary_review_required_count"] == 3 and
                 &1["source_timeline_diff_summary"]["model"] ==
                   "artifact_only_timeline_diff_summary")
           )

    import_rows =
      Enum.filter(
        import["rows"],
        &(get_in(&1, [
            "source_review_row",
            "source_timeline_diff_summary",
            "schema_contract"
          ]) == "timeline_diff_summary.v1")
      )

    assert length(import_rows) == 9

    assert Enum.all?(
             import_rows,
             &(get_in(&1, [
                 "source_review_row",
                 "source_timeline_diff_summary",
                 "review_required_count"
               ]) == 3)
           )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "CandidateRefresh lifts accepted planning state timeline diff summaries" do
    summary =
      timeline_diff_summary()
      |> Map.put("source", "diff_summary_accepted_state")

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "refresh:accepted_timeline_diff_summary_handoff",
      "accepted_planning_state" => %{
        "source_timeline_diff_summary" => summary
      }
    }

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)

    diff_rows =
      Enum.filter(
        review["rows"],
        &(&1["source_timeline_diff_summary"]["schema_contract"] == "timeline_diff_summary.v1")
      )

    assert length(diff_rows) == 3

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "refresh:accepted_timeline_diff_summary_handoff",
             "review_count" => 3,
             "timeline_diff_count" => 3,
             "required_operator_action_counts" => %{
               "review_added_activity" => 1,
               "review_changed_protected_activity" => 1,
               "review_removed_activity" => 1
             }
           } = review

    assert Enum.map(diff_rows, & &1["source"]) == [
             "candidate_refresh.accepted_planning_state.source_timeline_diff_summary.review_rows",
             "candidate_refresh.accepted_planning_state.source_timeline_diff_summary.review_rows",
             "candidate_refresh.accepted_planning_state.source_timeline_diff_summary.review_rows"
           ]

    assert %{
             "review_type" => "timeline_diff_review",
             "source" =>
               "candidate_refresh.accepted_planning_state.source_timeline_diff_summary.review_rows",
             "timeline_id" => "timeline:cmd_lock",
             "diff_status" => "changed",
             "transition_decision" => "preserve_source",
             "source_timeline_diff_summary_review_required_count" => 3,
             "source_timeline_diff_summary_changed_count" => 1,
             "source_timeline_diff_summary" => %{
               "schema_contract" => "timeline_diff_summary.v1",
               "model" => "artifact_only_timeline_diff_summary",
               "source" => "diff_summary_accepted_state",
               "review_required_count" => 3
             },
             "source_timeline_diff" => %{
               "requires_operator_review" => true
             }
           } = Enum.find(diff_rows, &(&1["timeline_id"] == "timeline:cmd_lock"))

    import_rows =
      Enum.filter(import["rows"], &(&1["source_review_type"] == "timeline_diff_review"))

    assert length(import_rows) == 3

    assert %{
             "row_count" => 3,
             "import_action_counts" => %{"review_timeline_diff" => 3},
             "source_review_type_counts" => %{"timeline_diff_review" => 3}
           } = import

    assert %{
             "import_action" => "review_timeline_diff",
             "source_review_type" => "timeline_diff_review",
             "timeline_id" => "timeline:cmd_lock",
             "source_review_row" => %{
               "source" =>
                 "candidate_refresh.accepted_planning_state.source_timeline_diff_summary.review_rows",
               "source_timeline_diff_summary" => %{
                 "schema_contract" => "timeline_diff_summary.v1",
                 "source" => "diff_summary_accepted_state"
               }
             }
           } = Enum.find(import_rows, &(&1["timeline_id"] == "timeline:cmd_lock"))

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "CandidateRefresh lifts mission state timeline diff summaries" do
    summary =
      timeline_diff_summary()
      |> Map.put("source", "diff_summary_mission_state")

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "refresh:mission_timeline_diff_summary_handoff",
      "mission_state" => %{
        "timeline_diff_summary" => summary
      }
    }

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)

    diff_rows =
      Enum.filter(
        review["rows"],
        &(&1["source_timeline_diff_summary"]["schema_contract"] == "timeline_diff_summary.v1")
      )

    assert length(diff_rows) == 3

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "refresh:mission_timeline_diff_summary_handoff",
             "review_count" => 3,
             "timeline_diff_count" => 3
           } = review

    assert Enum.map(diff_rows, & &1["source"]) == [
             "candidate_refresh.mission_state.timeline_diff_summary.review_rows",
             "candidate_refresh.mission_state.timeline_diff_summary.review_rows",
             "candidate_refresh.mission_state.timeline_diff_summary.review_rows"
           ]

    assert %{
             "review_type" => "timeline_diff_review",
             "source" => "candidate_refresh.mission_state.timeline_diff_summary.review_rows",
             "timeline_id" => "timeline:dl_removed",
             "diff_status" => "removed",
             "required_operator_action" => "review_removed_activity",
             "source_timeline_diff_summary_row_count" => 3,
             "source_timeline_diff_summary" => %{
               "schema_contract" => "timeline_diff_summary.v1",
               "source" => "diff_summary_mission_state",
               "removed_count" => 1
             }
           } = Enum.find(diff_rows, &(&1["timeline_id"] == "timeline:dl_removed"))

    assert %{
             "row_count" => 3,
             "import_action_counts" => %{"review_timeline_diff" => 3},
             "source_review_type_counts" => %{"timeline_diff_review" => 3}
           } = import

    assert %{
             "import_action" => "review_timeline_diff",
             "source_review_type" => "timeline_diff_review",
             "timeline_id" => "timeline:dl_removed",
             "source_review_row" => %{
               "source" => "candidate_refresh.mission_state.timeline_diff_summary.review_rows",
               "source_timeline_diff_summary" => %{
                 "schema_contract" => "timeline_diff_summary.v1",
                 "source" => "diff_summary_mission_state"
               }
             }
           } = Enum.find(import["rows"], &(&1["timeline_id"] == "timeline:dl_removed"))

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
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
end
