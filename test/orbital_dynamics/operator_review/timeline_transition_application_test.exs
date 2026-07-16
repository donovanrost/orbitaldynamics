defmodule OrbitalDynamics.OperatorReview.TimelineTransitionApplicationTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, OperatorReview, Schema, Timeline}

  test "candidate refresh source timeline transition application reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:source_timeline_transition_review:001",
      "source_timeline_transition_application_report" => [
        %{
          "schema_contract" => "timeline_transition_application_report.v1",
          "source" => "mission_state.source_timeline_transition_application_report",
          "applications" => [
            %{
              "id" => "timeline_transition_application:timeline:cmd_added",
              "rank" => 1,
              "timeline_id" => "timeline:cmd_added",
              "diff_status" => "added",
              "changed_fields" => ["activity_added"],
              "transition_decision" => "review",
              "application_status" => "operator_review_required",
              "selected_activity_source" => "replacement",
              "selected_activity" => %{
                "activity_id" => "cmd_added",
                "starts_at_s" => 40.0,
                "ends_at_s" => 50.0
              },
              "requires_operator_review" => true,
              "required_operator_action" => "review_timeline_change",
              "reason" => "replacement timeline adds command activity cmd_added",
              "source_timeline_diff" => %{
                "id" => "timeline_diff:timeline:cmd_added",
                "rank" => 1,
                "timeline_id" => "timeline:cmd_added",
                "diff_status" => "added",
                "replacement_activity_id" => "cmd_added",
                "replacement_activity_type" => "command",
                "scenario_id" => "leo_1",
                "replacement_starts_at_s" => 40.0,
                "replacement_ends_at_s" => 50.0,
                "changed_fields" => ["activity_added"],
                "requires_operator_review" => true,
                "required_operator_action" => "review_timeline_change",
                "reason" => "replacement timeline adds command activity cmd_added",
                "status_transition" => %{
                  "field" => "status",
                  "transition_type" => "added",
                  "transition_category" => "status_added"
                },
                "approval_transition" => %{
                  "field" => "approval_status",
                  "transition_type" => "added",
                  "transition_category" => "approval_review_required"
                }
              }
            }
          ]
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:source_timeline_transition_review:001",
             "review_count" => 1,
             "timeline_diff_count" => 1
           } = package

    assert [
             %{
               "review_type" => "timeline_diff_review",
               "source" =>
                 "candidate_refresh.source_timeline_transition_application_report[0].applications",
               "timeline_id" => "timeline:cmd_added",
               "diff_status" => "added",
               "activity_id" => "cmd_added",
               "replacement_activity_id" => "cmd_added",
               "required_operator_action" => "review_timeline_change",
               "application_status" => "operator_review_required",
               "selected_activity_source" => "replacement",
               "selected_activity" => %{"activity_id" => "cmd_added"},
               "source_timeline_application" => %{
                 "application_status" => "operator_review_required"
               },
               "source_timeline_diff" => %{
                 "timeline_id" => "timeline:cmd_added",
                 "application_status" => "operator_review_required"
               }
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "builds review package from transition application report review rows" do
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

    package =
      OrbitalDynamics.operator_review_package(report, approval_policy: approval_policy)

    assert %{
             "source_artifact_type" => "timeline_transition_application_report.v1",
             "source_artifact_id" => "timeline_transition_application_report",
             "review_count" => 3,
             "timeline_diff_count" => 3
           } = package

    assert %{
             "review_type" => "timeline_diff_review",
             "source" => "timeline_transition_application_report.applications",
             "timeline_id" => "timeline:cmd_lock",
             "application_status" => "source_preserved_pending_review",
             "selected_activity_source" => "source",
             "selected_activity" => %{
               "activity_id" => "cmd_lock",
               "starts_at_s" => 10.0
             },
             "policy_classification" => "operator_review_required",
             "approval_rule_matches" => [
               %{
                 "rule_id" => "transition_application_preserve_review",
                 "classification" => "operator_review_required",
                 "application_status" => "source_preserved_pending_review",
                 "escalation_queue" => "mission_planning",
                 "required_authority" => "mission_planning_authority"
               }
             ],
             "source_policy_decision" => %{
               "schema_contract" => "policy_decision.v1",
               "classification" => "operator_review_required"
             },
             "source_timeline_application" => %{
               "application_status" => "source_preserved_pending_review"
             },
             "source_timeline_diff" => %{
               "requires_operator_review" => true,
               "application_status" => "source_preserved_pending_review"
             }
           } = Enum.find(package["rows"], &(&1["timeline_id"] == "timeline:cmd_lock"))

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
             "source_timeline_diff" => %{
               "status_transition" => %{"transition_type" => "added"},
               "approval_transition" => %{"transition_type" => "added"}
             }
           } = added = Enum.find(package["rows"], &(&1["timeline_id"] == "timeline:cmd_added"))

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
             "source_timeline_diff" => %{
               "source_self_dependency_activity_ids" => ["obs_self_dependency"],
               "replacement_self_dependency_activity_ids" => ["obs_self_dependency"]
             }
           } = Enum.find(package["rows"], &(&1["timeline_id"] == "timeline:obs_self_dependency"))

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "lifecycle transition application provenance survives review and import handoff" do
    source_activity = %{
      id: :cmd_lifecycle_complete,
      type: :command,
      status: "In Progress",
      approval_status: :pending,
      dependencies: [:missing_gate],
      metadata: %{timeline_id: :"timeline:cmd_lifecycle_complete"}
    }

    {:ok, replacement_activity} =
      Timeline.apply_lifecycle_event(source_activity, "record completion")

    report =
      Timeline.transition_application_report([source_activity], [replacement_activity],
        source: "timeline_transition_application_report"
      )

    assert [
             %{
               "application_status" => "selected_timeline_integrity_review_required",
               "requires_operator_review" => true,
               "transition_application_provenance" => provenance,
               "selected_activity" => %{
                 "transition_application_provenance" => selected_provenance,
                 "activity_context" => %{
                   "transition_application_provenance" => context_provenance
                 }
               }
             }
           ] = report["applications"]

    assert selected_provenance == provenance
    assert context_provenance == provenance

    assert %{
             "helper" => "apply_lifecycle_event",
             "operator_action_reason" => "activity_execution_recorded",
             "transition_category" => "execution_recorded",
             "transition_type" => "changed",
             "requires_operator_review" => false
           } = provenance

    package = OperatorReview.from_timeline_transition_application_report(report)

    assert %{
             "review_count" => 1,
             "rows" => [
               %{
                 "application_status" => "selected_timeline_integrity_review_required",
                 "required_operator_action" => "review_timeline_integrity",
                 "transition_application_provenance" => ^provenance,
                 "selected_activity" => %{
                   "activity_context" => %{
                     "transition_application_provenance" => ^provenance
                   }
                 },
                 "source_timeline_application" => %{
                   "transition_application_provenance" => ^provenance,
                   "selected_activity" => %{
                     "transition_application_provenance" => ^provenance
                   }
                 },
                 "source_timeline_diff" => %{
                   "transition_application_provenance" => ^provenance
                 }
               }
             ]
           } = package

    manifest = CadenceImport.from_timeline_transition_application_report(report)

    assert %{
             "schema_contract" => "cadence_import_manifest.v1",
             "review_required_count" => 1,
             "rows" => [
               %{
                 "application_status" => "selected_timeline_integrity_review_required",
                 "import_status" => "review_required_before_import",
                 "transition_application_provenance" => ^provenance,
                 "source_review_row" => %{
                   "transition_application_provenance" => ^provenance
                 },
                 "source_timeline_application" => %{
                   "transition_application_provenance" => ^provenance
                 }
               }
             ]
           } = manifest

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "timeline transition application summaries become operator review rows" do
    summary = timeline_transition_application_summary()
    package = OperatorReview.from_timeline_transition_application_summary(summary)

    atom_key_summary =
      summary
      |> Enum.map(fn {key, value} -> {String.to_atom(key), value} end)
      |> Map.new()

    assert %{
             "source_artifact_type" => "timeline_transition_application_summary.v1",
             "source_artifact_id" => "transition_summary_source",
             "review_count" => 3,
             "timeline_diff_count" => 3,
             "required_operator_action_counts" => %{
               "review_added_activity" => 1,
               "review_changed_protected_activity" => 1,
               "review_timeline_integrity" => 1
             }
           } = package

    assert %{
             "review_type" => "timeline_diff_review",
             "source" => "timeline_transition_application_summary.review_applications",
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
             "source_transition_application_preserved_source_timeline_ids" => [
               "timeline:cmd_lock"
             ],
             "source_timeline_transition_application_summary" => %{
               "model" => "artifact_only_timeline_transition_application_summary",
               "review_required_count" => 3,
               "review_activity_ids" => ["cmd_added", "cmd_lock", "obs_self_dependency"],
               "selected_activity_ids" => ["cmd_lock"]
             },
             "source_timeline_application" => %{
               "application_status" => "source_preserved_pending_review"
             }
           } = Enum.find(package["rows"], &(&1["timeline_id"] == "timeline:cmd_lock"))

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
           } = Enum.find(package["rows"], &(&1["timeline_id"] == "timeline:obs_self_dependency"))

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
          "source_timeline_transition_application_summary",
          "selected_activity_ids"
        ],
        ["bad activity id"]
      )

    assert {:error, validation_report} = Schema.validate_artifact(invalid_source_summary_ids)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_timeline_transition_application_summary.selected_activity_ids[0]" and
                 &1["message"] =~ "stable ID")
           )
  end

  test "timeline transition application report and summary source ids fall back through defaults" do
    assert %{"source_artifact_id" => "transition:summary"} =
             OperatorReview.from_timeline_transition_application_summary(%{
               id: :"transition:summary",
               review_applications: []
             })

    assert %{"source_artifact_id" => "timeline_transition_application_summary"} =
             OperatorReview.from_timeline_transition_application_summary(%{
               review_applications: []
             })

    assert %{"source_artifact_id" => "transition:report"} =
             OperatorReview.from_timeline_transition_application_report(%{
               id: :"transition:report",
               applications: []
             })

    assert %{"source_artifact_id" => "timeline_transition_application_report"} =
             OperatorReview.from_timeline_transition_application_report(%{applications: []})
  end

  test "CandidateRefresh lifts transition application summaries from direct and result artifacts" do
    direct_summary =
      timeline_transition_application_summary()
      |> Map.put("source", "transition_summary_direct")

    source_result_summary =
      timeline_transition_application_summary()
      |> Map.put("source", "transition_summary_source_result")

    nested_summary =
      timeline_transition_application_summary()
      |> Map.put("source", "transition_summary_nested_result")

    artifact = %{
      "refresh_id" => "refresh:transition_summary_result_handoff",
      "timeline_transition_application_summary" => direct_summary,
      "source_result_artifact" => [source_result_summary],
      "result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "timeline_transition_application_summary" => nested_summary
      }
    }

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)

    transition_rows =
      Enum.filter(
        review["rows"],
        &(&1["source_timeline_transition_application_summary"]["schema_contract"] ==
            "timeline_transition_application_summary.v1")
      )

    assert length(transition_rows) == 9

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "refresh:transition_summary_result_handoff",
             "review_count" => 9,
             "timeline_diff_count" => 9,
             "required_operator_action_counts" => %{
               "review_added_activity" => 3,
               "review_changed_protected_activity" => 3,
               "review_timeline_integrity" => 3
             }
           } = review

    assert Enum.sort(Enum.map(transition_rows, & &1["source"])) == [
             "candidate_refresh.result_artifact.timeline_transition_application_summary.review_applications",
             "candidate_refresh.result_artifact.timeline_transition_application_summary.review_applications",
             "candidate_refresh.result_artifact.timeline_transition_application_summary.review_applications",
             "candidate_refresh.source_result_artifact[0].review_applications",
             "candidate_refresh.source_result_artifact[0].review_applications",
             "candidate_refresh.source_result_artifact[0].review_applications",
             "candidate_refresh.timeline_transition_application_summary.review_applications",
             "candidate_refresh.timeline_transition_application_summary.review_applications",
             "candidate_refresh.timeline_transition_application_summary.review_applications"
           ]

    assert Enum.all?(
             transition_rows,
             &(&1["source_transition_application_count"] == 3 and
                 &1["source_timeline_transition_application_summary"]["model"] ==
                   "artifact_only_timeline_transition_application_summary")
           )

    import_rows =
      Enum.filter(
        import["rows"],
        &(get_in(&1, [
            "source_review_row",
            "source_timeline_transition_application_summary",
            "schema_contract"
          ]) == "timeline_transition_application_summary.v1")
      )

    assert length(import_rows) == 9

    assert Enum.all?(
             import_rows,
             &(get_in(&1, [
                 "source_review_row",
                 "source_timeline_transition_application_summary",
                 "schema_contract"
               ]) == "timeline_transition_application_summary.v1" and
                 is_map(&1["source_review_row"]["source_timeline_application"]))
           )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "CandidateRefresh lifts all nested transition application source paths" do
    report = %{
      "schema_contract" => "timeline_transition_application_report.v1",
      "source" => "nested.timeline_transition_application_report",
      "applications" => [
        %{
          "id" => "timeline_transition_application:timeline:cmd_nested_transition",
          "rank" => 1,
          "timeline_id" => "timeline:cmd_nested_transition",
          "diff_status" => "added",
          "changed_fields" => ["activity_added"],
          "transition_decision" => "review",
          "application_status" => "operator_review_required",
          "selected_activity_source" => "replacement",
          "selected_activity" => %{
            "activity_id" => "cmd_nested_transition",
            "starts_at_s" => 40.0,
            "ends_at_s" => 50.0
          },
          "requires_operator_review" => true,
          "required_operator_action" => "review_timeline_change",
          "reason" => "replacement timeline adds command activity cmd_nested_transition",
          "source_timeline_diff" => %{
            "id" => "timeline_diff:timeline:cmd_nested_transition",
            "rank" => 1,
            "timeline_id" => "timeline:cmd_nested_transition",
            "diff_status" => "added",
            "replacement_activity_id" => "cmd_nested_transition",
            "replacement_activity_type" => "command",
            "changed_fields" => ["activity_added"],
            "requires_operator_review" => true,
            "required_operator_action" => "review_timeline_change",
            "reason" => "replacement timeline adds command activity cmd_nested_transition"
          }
        }
      ]
    }

    summary =
      timeline_transition_application_summary()
      |> Map.put("source", "nested.timeline_transition_application_summary")

    cases = [
      {"accepted_planning_state", "source_timeline_transition_application_report", report,
       ".applications", 1, "source_timeline_application"},
      {"accepted_planning_state", "timeline_transition_application_report", report,
       ".applications", 1, "source_timeline_application"},
      {"mission_state", "source_timeline_transition_application_report", report, ".applications",
       1, "source_timeline_application"},
      {"mission_state", "timeline_transition_application_report", report, ".applications", 1,
       "source_timeline_application"},
      {"accepted_planning_state", "source_timeline_transition_application_summary", summary,
       ".review_applications", 3, "source_timeline_transition_application_summary"},
      {"accepted_planning_state", "timeline_transition_application_summary", summary,
       ".review_applications", 3, "source_timeline_transition_application_summary"},
      {"mission_state", "source_timeline_transition_application_summary", summary,
       ".review_applications", 3, "source_timeline_transition_application_summary"},
      {"mission_state", "timeline_transition_application_summary", summary,
       ".review_applications", 3, "source_timeline_transition_application_summary"}
    ]

    Enum.each(cases, fn {state_key, field, payload, source_suffix, expected_count,
                         source_payload_key} ->
      source = "candidate_refresh.#{state_key}.#{field}#{source_suffix}"

      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "refresh_id" => "refresh:#{state_key}:#{field}",
        state_key => %{field => payload}
      }

      review = OperatorReview.from_candidate_refresh_artifact(artifact)
      import = CadenceImport.from_candidate_refresh_artifact(artifact)

      rows = Enum.filter(review["rows"], &(&1["source"] == source))

      import_rows =
        Enum.filter(import["rows"], &(get_in(&1, ["source_review_row", "source"]) == source))

      assert length(rows) == expected_count
      assert length(import_rows) == expected_count

      assert %{
               "review_count" => ^expected_count,
               "timeline_diff_count" => ^expected_count
             } = review

      assert %{"row_count" => ^expected_count} = import

      assert Enum.all?(rows, &(&1["review_type"] == "timeline_diff_review"))
      assert Enum.all?(rows, &is_map(&1[source_payload_key]))
      assert Enum.all?(import_rows, &(&1["source_review_type"] == "timeline_diff_review"))

      assert Enum.all?(
               import_rows,
               &is_map(get_in(&1, ["source_review_row", source_payload_key]))
             )
    end)

    wrapped_cases = [
      {%{"source_result_artifact" => [report]},
       "candidate_refresh.source_result_artifact[0].applications"},
      {%{
         "result_artifact" => %{
           "schema_contract" => "result_artifact.v1",
           "timeline_transition_application_report" => report
         }
       }, "candidate_refresh.result_artifact.timeline_transition_application_report.applications"}
    ]

    Enum.each(wrapped_cases, fn {artifact_fields, source} ->
      artifact =
        Map.merge(
          %{
            "schema_contract" => "candidate_refresh.v1",
            "refresh_id" => "refresh:wrapped_transition_application_report"
          },
          artifact_fields
        )

      review = OperatorReview.from_candidate_refresh_artifact(artifact)
      import = CadenceImport.from_candidate_refresh_artifact(artifact)

      assert [
               %{
                 "review_type" => "timeline_diff_review",
                 "source" => ^source,
                 "timeline_id" => "timeline:cmd_nested_transition",
                 "source_timeline_application" => %{
                   "application_status" => "operator_review_required"
                 }
               }
             ] = review["rows"]

      assert [
               %{
                 "source_review_type" => "timeline_diff_review",
                 "source_review_row" => %{
                   "source" => ^source,
                   "source_timeline_application" => %{
                     "application_status" => "operator_review_required"
                   }
                 }
               }
             ] = import["rows"]
    end)
  end

  test "timeline transition packages reject stale source application evidence" do
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

    package =
      source
      |> OrbitalDynamics.Timeline.transition_application_report(replacement,
        source: "timeline_transition_application_report"
      )
      |> OperatorReview.from_timeline_transition_application_report()
      |> update_in(["rows", Access.at(0), "source_timeline_application"], fn source_row ->
        Map.put(source_row, "application_status", "operator_review_required")
      end)

    assert {:error, stale_source_report} = Schema.validate_artifact(package)

    assert Enum.any?(
             stale_source_report["errors"],
             &(&1["path"] == "$.rows[0].application_status" and
                 &1["message"] ==
                   "must match source_timeline_application.application_status")
           )
  end

  defp timeline_transition_application_summary do
    {source, replacement} = timeline_transition_application_pair()

    source
    |> Timeline.transition_application_report(replacement, source: "transition_summary_source")
    |> Timeline.transition_application_summary()
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
