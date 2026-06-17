defmodule OrbitalDynamics.CandidateRefresh.TimelineTransitionApplicationReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CandidateRefresh, Schema, Timeline}

  test "source report summary derives timeline transition application routing maps from rows" do
    refresh = %{
      "source_timeline_transition_application_report" => %{
        "schema_contract" => "timeline_transition_application_report.v1",
        "application_count" => 99,
        "selected_activity_count" => 99,
        "selected_timeline_integrity_review_count" => 99,
        "selected_timeline_integrity_issue_count" => 99,
        "selected_timeline_integrity_issue_type_counts" => %{"stale_integrity_issue" => 99},
        "selected_activity_id_counts" => %{"stale_selected_activity" => 99},
        "review_required_count" => 99,
        "preserved_source_count" => 99,
        "recorded_replacement_count" => 99,
        "withheld_review_count" => 99,
        "duplicate_timeline_identity_count" => 99,
        "duplicate_source_timeline_identity_count" => 99,
        "duplicate_replacement_timeline_identity_count" => 99,
        "application_status_counts" => %{"stale_status" => 99},
        "transition_decision_counts" => %{"stale_decision" => 99},
        "required_operator_action_counts" => %{"stale_action" => 99},
        "duplicate_timeline_identity_scope_counts" => %{"stale_scope" => 99},
        "applications" => [
          %{
            "id" => "timeline_application:selected",
            "application_status" => "selected",
            "transition_decision" => "apply",
            "selected_activity" => %{"activity_id" => "selected_downlink_activity"},
            "required_operator_action" => "none"
          },
          %{
            "id" => "timeline_application:review",
            "application_status" => "operator_review_required",
            "transition_decision" => "review",
            "required_operator_action" => "review_timeline_change",
            "timeline_identity_collision" => true,
            "duplicate_timeline_identity_scope" => "source"
          },
          %{
            "id" => "timeline_application:withheld",
            "application_status" => "withheld_review",
            "transition_decision" => "withhold",
            "required_operator_action" => "review_duplicate_timeline_identity",
            "duplicate_timeline_identity_scope" => "replacement"
          }
        ],
        "selected_activities" => [
          %{
            "activity_id" => "selected_downlink_activity",
            "timeline_id" => "timeline:selected_downlink",
            "timeline_integrity_status" => "review_required",
            "timeline_integrity_issue_count" => 2,
            "timeline_integrity_issue_types" => [
              "missing_dependency_activity",
              "self_dependency_timeline"
            ]
          }
        ],
        "provenance" => %{"trust_boundary" => "ops_transition_application"}
      }
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_timeline_transition_application_contract" =>
               "timeline_transition_application_report.v1",
             "source_report_timeline_transition_application_count" => 1,
             "source_report_timeline_transition_application_row_count" => 3,
             "source_report_timeline_transition_application_paths" => [
               "source_timeline_transition_application_report"
             ],
             "source_report_timeline_transition_application_application_count" => 3,
             "source_report_timeline_transition_application_selected_activity_count" => 1,
             "source_report_timeline_transition_application_selected_activity_id_counts" => %{
               "selected_downlink_activity" => 1
             },
             "source_report_timeline_transition_application_review_required_count" => 2,
             "source_report_timeline_transition_application_preserved_source_count" => 0,
             "source_report_timeline_transition_application_recorded_replacement_count" => 0,
             "source_report_timeline_transition_application_withheld_review_count" => 2,
             "source_report_timeline_transition_application_duplicate_timeline_identity_count" =>
               2,
             "source_report_timeline_transition_application_duplicate_source_timeline_identity_count" =>
               1,
             "source_report_timeline_transition_application_duplicate_replacement_timeline_identity_count" =>
               1,
             "source_report_timeline_transition_application_status_counts" => %{
               "operator_review_required" => 1,
               "selected" => 1,
               "withheld_review" => 1
             },
             "source_report_timeline_transition_application_decision_counts" => %{
               "apply" => 1,
               "review" => 1,
               "withhold" => 1
             },
             "source_report_timeline_transition_application_required_operator_action_counts" => %{
               "none" => 1,
               "review_duplicate_timeline_identity" => 1,
               "review_timeline_change" => 1
             },
             "source_report_timeline_transition_application_duplicate_timeline_identity_scope_counts" =>
               %{
                 "replacement" => 1,
                 "source" => 1
               },
             "source_report_timeline_transition_application_branch_local_timeline_transition_application_pressure" =>
               true,
             "source_report_timeline_transition_application_branch_local_selected_activity_pressure" =>
               true,
             "source_report_timeline_transition_application_branch_local_review_required_pressure" =>
               true,
             "source_report_timeline_transition_application_branch_local_preserved_transition_pressure" =>
               false,
             "source_report_timeline_transition_application_branch_local_duplicate_identity_pressure" =>
               true,
             "source_report_timeline_transition_application_branch_local_operator_review_pressure" =>
               true,
             "source_reports" => %{
               "timeline_transition_application_report" => %{
                 "contract" => "timeline_transition_application_report.v1",
                 "count" => 1,
                 "row_count" => 3,
                 "paths" => ["source_timeline_transition_application_report"],
                 "application_count" => 3,
                 "selected_activity_count" => 1,
                 "selected_timeline_integrity_review_count" => 1,
                 "selected_timeline_integrity_issue_count" => 2,
                 "selected_timeline_integrity_issue_type_counts" => %{
                   "missing_dependency_activity" => 1,
                   "self_dependency_timeline" => 1
                 },
                 "selected_activity_id_counts" => %{"selected_downlink_activity" => 1},
                 "preserved_source_count" => 0,
                 "recorded_replacement_count" => 0,
                 "duplicate_timeline_identity_count" => 2,
                 "application_status_counts" => %{
                   "operator_review_required" => 1,
                   "selected" => 1,
                   "withheld_review" => 1
                 }
               }
             }
           } = summary = CandidateRefresh.source_report_summary(refresh)

    replay_summary = %{
      "model" => "artifact_only_candidate_refresh_timeline_transition_application_replay_summary",
      "source" =>
        "candidate_refresh.source_report_provenance.timeline_transition_application_report",
      "contract" => "timeline_transition_application_report.v1",
      "source_report_count" => 1,
      "source_report_row_count" => 3,
      "source_application_count" => 3,
      "source_report_paths" => ["source_timeline_transition_application_report"],
      "selected_activity_count" => 1,
      "selected_timeline_integrity_review_count" => 1,
      "selected_timeline_integrity_issue_count" => 2,
      "selected_timeline_integrity_issue_type_counts" => %{
        "missing_dependency_activity" => 1,
        "self_dependency_timeline" => 1
      },
      "selected_activity_id_counts" => %{"selected_downlink_activity" => 1},
      "review_required_count" => 2,
      "preserved_source_count" => 0,
      "recorded_replacement_count" => 0,
      "withheld_review_count" => 2,
      "duplicate_timeline_identity_count" => 2,
      "duplicate_source_timeline_identity_count" => 1,
      "duplicate_replacement_timeline_identity_count" => 1,
      "application_status_counts" => %{
        "operator_review_required" => 1,
        "selected" => 1,
        "withheld_review" => 1
      },
      "transition_decision_counts" => %{
        "apply" => 1,
        "review" => 1,
        "withhold" => 1
      },
      "required_operator_action_counts" => %{
        "none" => 1,
        "review_duplicate_timeline_identity" => 1,
        "review_timeline_change" => 1
      },
      "duplicate_timeline_identity_scope_counts" => %{
        "replacement" => 1,
        "source" => 1
      },
      "review_activity_id_counts" => %{},
      "trust_boundary_status" => "declared",
      "trust_boundaries" => ["ops_transition_application"],
      "branch_local_timeline_transition_application_pressure" => true,
      "branch_local_selected_activity_pressure" => true,
      "branch_local_selected_integrity_pressure" => true,
      "branch_local_review_required_pressure" => true,
      "branch_local_preserved_transition_pressure" => false,
      "branch_local_duplicate_identity_pressure" => true,
      "branch_local_operator_review_pressure" => true,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => "timeline_transition_application_source_report_provenance_only",
        "operator_authority" => "not_granted_by_timeline_transition_application_replay_summary",
        "timeline_application" => "not_performed_by_summary",
        "timeline_mutation" => "not_performed_by_summary",
        "candidate_selection" => "not_performed_by_summary",
        "import_approval" => "not_granted_by_timeline_transition_application_replay_summary",
        "cadence_write" => "not_performed_by_summary",
        "candidate_generation" => "not_performed_by_summary"
      }
    }

    assert CandidateRefresh.timeline_transition_application_replay_summary(refresh) ==
             replay_summary

    assert OrbitalDynamics.candidate_refresh_timeline_transition_application_replay_summary(
             refresh
           ) == replay_summary

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => summary["source_reports"]}
    }

    assert %{
             "source_report_timeline_transition_application_contract" =>
               "timeline_transition_application_report.v1",
             "source_report_timeline_transition_application_count" => 1,
             "source_report_timeline_transition_application_row_count" => 3,
             "source_report_timeline_transition_application_paths" => [
               "source_timeline_transition_application_report"
             ],
             "source_report_timeline_transition_application_application_count" => 3,
             "source_report_timeline_transition_application_selected_activity_id_counts" => %{
               "selected_downlink_activity" => 1
             },
             "source_report_timeline_transition_application_required_operator_action_counts" => %{
               "none" => 1,
               "review_duplicate_timeline_identity" => 1,
               "review_timeline_change" => 1
             },
             "source_report_timeline_transition_application_duplicate_timeline_identity_scope_counts" =>
               %{
                 "replacement" => 1,
                 "source" => 1
               },
             "source_report_timeline_transition_application_branch_local_timeline_transition_application_pressure" =>
               true,
             "source_report_timeline_transition_application_branch_local_selected_activity_pressure" =>
               true,
             "source_report_timeline_transition_application_branch_local_review_required_pressure" =>
               true,
             "source_report_timeline_transition_application_branch_local_preserved_transition_pressure" =>
               false,
             "source_report_timeline_transition_application_branch_local_duplicate_identity_pressure" =>
               true,
             "source_report_timeline_transition_application_branch_local_operator_review_pressure" =>
               true
           } = CandidateRefresh.source_report_summary(artifact)

    assert CandidateRefresh.timeline_transition_application_replay_summary(artifact) ==
             replay_summary

    assert OrbitalDynamics.candidate_refresh_timeline_transition_application_replay_summary(
             artifact
           ) == replay_summary
  end

  test "source report summary replays compact timeline transition application summaries" do
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
        starts_at_s: 30.0,
        ends_at_s: 40.0,
        dependencies: [:obs_self_dependency]
      }
    ]

    replacement = [
      %{
        id: :cmd_lock,
        type: :command,
        status: :planned,
        approval_status: :pending,
        starts_at_s: 10.0,
        ends_at_s: 20.0,
        metadata: %{timeline_id: :"timeline:cmd_lock"}
      },
      %{id: :cmd_added, type: :command, starts_at_s: 50.0, ends_at_s: 60.0},
      %{
        id: :obs_self_dependency,
        type: :observe,
        starts_at_s: 30.0,
        ends_at_s: 40.0,
        dependencies: [:obs_self_dependency]
      }
    ]

    summary =
      source
      |> Timeline.transition_application_report(replacement, source: "transition_summary_source")
      |> Timeline.transition_application_summary()
      |> Map.put("application_count", 99)
      |> Map.put("selected_activity_count", 99)
      |> Map.put("selected_timeline_integrity_review_count", 99)
      |> Map.put("selected_timeline_integrity_issue_count", 99)
      |> Map.put("selected_timeline_integrity_issue_types", ["stale_integrity_issue"])
      |> Map.put("review_required_count", 99)
      |> Map.put("preserved_source_count", 99)
      |> Map.put("recorded_replacement_count", 99)
      |> Map.put("withheld_review_count", 99)
      |> Map.put("application_status_counts", %{"stale_status" => 99})
      |> Map.put("transition_decision_counts", %{"stale_decision" => 99})
      |> Map.put("required_operator_action_counts", %{"stale_action" => 99})
      |> Map.put("provenance", %{"trust_boundary" => "direct_transition_summary"})

    replay_summary =
      summary
      |> Map.drop([
        "application_count",
        "selected_activity_count",
        "selected_timeline_integrity_review_count",
        "selected_timeline_integrity_issue_count",
        "selected_timeline_integrity_issue_types",
        "review_required_count",
        "preserved_source_count",
        "recorded_replacement_count",
        "withheld_review_count",
        "application_status_counts",
        "transition_decision_counts",
        "required_operator_action_counts",
        "provenance"
      ])
      |> Map.merge(%{
        "application_count" => 3,
        "selected_activity_count" => 1,
        "selected_timeline_integrity_review_count" => 0,
        "selected_timeline_integrity_issue_count" => 0,
        "selected_timeline_integrity_issue_types" => [],
        "review_required_count" => 3,
        "preserved_source_count" => 1,
        "recorded_replacement_count" => 0,
        "withheld_review_count" => 2,
        "application_status_counts" => %{
          "operator_review_required" => 2,
          "source_preserved_pending_review" => 1
        },
        "transition_decision_counts" => %{"preserve_source" => 1, "review" => 2},
        "required_operator_action_counts" => %{
          "review_added_activity" => 1,
          "review_changed_protected_activity" => 1,
          "review_timeline_integrity" => 1
        },
        "provenance" => %{"trust_boundary" => "direct_transition_summary"}
      })

    refresh = %{
      "accepted_planning_state" => %{"timeline_transition_application_summary" => replay_summary},
      "mission_state" => %{"source_timeline_transition_application_summary" => replay_summary},
      "source_timeline_transition_application_summary" => replay_summary,
      "source_result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "provenance" => %{"trust_boundary" => "wrapped_transition_summary"},
        "timeline_transition_application_summary" => Map.delete(replay_summary, "provenance")
      }
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_count" => 4,
             "source_report_row_count" => 12,
             "source_report_counts_by_contract" => %{
               "timeline_transition_application_summary.v1" => 4
             },
             "source_report_row_counts_by_contract" => %{
               "timeline_transition_application_summary.v1" => 12
             },
             "source_report_timeline_transition_application_contract" =>
               "timeline_transition_application_summary.v1",
             "source_report_timeline_transition_application_count" => 4,
             "source_report_timeline_transition_application_row_count" => 12,
             "source_report_timeline_transition_application_paths" => [
               "accepted_planning_state.timeline_transition_application_summary",
               "mission_state.source_timeline_transition_application_summary",
               "source_timeline_transition_application_summary",
               "source_result_artifact.timeline_transition_application_summary"
             ],
             "source_report_timeline_transition_application_application_count" => 12,
             "source_report_timeline_transition_application_selected_activity_count" => 4,
             "source_report_timeline_transition_application_selected_activity_id_counts" => %{
               "cmd_lock" => 4
             },
             "source_report_timeline_transition_application_review_activity_id_counts" => %{
               "cmd_added" => 4,
               "cmd_lock" => 4,
               "obs_self_dependency" => 4
             },
             "source_report_timeline_transition_application_review_required_count" => 12,
             "source_report_timeline_transition_application_preserved_source_count" => 4,
             "source_report_timeline_transition_application_recorded_replacement_count" => 0,
             "source_report_timeline_transition_application_withheld_review_count" => 8,
             "source_report_timeline_transition_application_status_counts" => %{
               "operator_review_required" => 8,
               "source_preserved_pending_review" => 4
             },
             "source_report_timeline_transition_application_decision_counts" => %{
               "preserve_source" => 4,
               "review" => 8
             },
             "source_report_timeline_transition_application_required_operator_action_counts" => %{
               "review_added_activity" => 4,
               "review_changed_protected_activity" => 4,
               "review_timeline_integrity" => 4
             },
             "source_reports" => %{
               "timeline_transition_application_report" => %{
                 "contract" => "timeline_transition_application_summary.v1",
                 "count" => 4,
                 "row_count" => 12,
                 "paths" => [
                   "accepted_planning_state.timeline_transition_application_summary",
                   "mission_state.source_timeline_transition_application_summary",
                   "source_timeline_transition_application_summary",
                   "source_result_artifact.timeline_transition_application_summary"
                 ],
                 "application_count" => 12,
                 "selected_activity_count" => 4,
                 "selected_timeline_integrity_review_count" => 0,
                 "selected_timeline_integrity_issue_count" => 0,
                 "selected_activity_id_counts" => %{"cmd_lock" => 4},
                 "review_activity_id_counts" => %{
                   "cmd_added" => 4,
                   "cmd_lock" => 4,
                   "obs_self_dependency" => 4
                 },
                 "review_required_count" => 12,
                 "preserved_source_count" => 4,
                 "recorded_replacement_count" => 0,
                 "withheld_review_count" => 8,
                 "trust_boundary_status" => "declared",
                 "trust_boundaries" => [
                   "direct_transition_summary",
                   "wrapped_transition_summary"
                 ]
               }
             }
           } = source_summary = CandidateRefresh.source_report_summary(refresh)

    replay = CandidateRefresh.timeline_transition_application_replay_summary(refresh)

    assert %{
             "contract" => "timeline_transition_application_summary.v1",
             "source_report_count" => 4,
             "source_report_row_count" => 12,
             "source_application_count" => 12,
             "source_report_paths" => [
               "accepted_planning_state.timeline_transition_application_summary",
               "mission_state.source_timeline_transition_application_summary",
               "source_timeline_transition_application_summary",
               "source_result_artifact.timeline_transition_application_summary"
             ],
             "selected_activity_count" => 4,
             "selected_timeline_integrity_review_count" => 0,
             "selected_timeline_integrity_issue_count" => 0,
             "selected_timeline_integrity_issue_type_counts" => %{},
             "selected_activity_id_counts" => %{"cmd_lock" => 4},
             "review_activity_id_counts" => %{
               "cmd_added" => 4,
               "cmd_lock" => 4,
               "obs_self_dependency" => 4
             },
             "review_required_count" => 12,
             "preserved_source_count" => 4,
             "recorded_replacement_count" => 0,
             "withheld_review_count" => 8,
             "application_status_counts" => %{
               "operator_review_required" => 8,
               "source_preserved_pending_review" => 4
             },
             "transition_decision_counts" => %{"preserve_source" => 4, "review" => 8},
             "required_operator_action_counts" => %{
               "review_added_activity" => 4,
               "review_changed_protected_activity" => 4,
               "review_timeline_integrity" => 4
             },
             "trust_boundary_status" => "declared",
             "trust_boundaries" => [
               "direct_transition_summary",
               "wrapped_transition_summary"
             ],
             "branch_local_timeline_transition_application_pressure" => true,
             "branch_local_selected_activity_pressure" => true,
             "branch_local_selected_integrity_pressure" => false,
             "branch_local_review_required_pressure" => true,
             "branch_local_preserved_transition_pressure" => true,
             "branch_local_operator_review_pressure" => true
           } = replay

    assert OrbitalDynamics.candidate_refresh_timeline_transition_application_replay_summary(
             refresh
           ) == replay

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => source_summary["source_reports"]}
    }

    assert CandidateRefresh.timeline_transition_application_replay_summary(artifact) == replay
  end

  test "source report summary replays exact timeline transition application summaries from result artifacts" do
    source = [
      %{
        id: :exact_cmd_lock,
        type: :command,
        status: :planned,
        approval_status: :approved,
        locked: true,
        starts_at_s: 10.0,
        ends_at_s: 20.0,
        metadata: %{timeline_id: :"timeline:exact_cmd_lock"}
      },
      %{
        id: :exact_obs_self_dependency,
        type: :observe,
        starts_at_s: 30.0,
        ends_at_s: 40.0,
        dependencies: [:exact_obs_self_dependency]
      }
    ]

    replacement = [
      %{
        id: :exact_cmd_lock,
        type: :command,
        status: :planned,
        approval_status: :pending,
        starts_at_s: 10.0,
        ends_at_s: 20.0,
        metadata: %{timeline_id: :"timeline:exact_cmd_lock"}
      },
      %{id: :exact_cmd_added, type: :command, starts_at_s: 50.0, ends_at_s: 60.0},
      %{
        id: :exact_obs_self_dependency,
        type: :observe,
        starts_at_s: 30.0,
        ends_at_s: 40.0,
        dependencies: [:exact_obs_self_dependency]
      }
    ]

    summary =
      source
      |> Timeline.transition_application_report(replacement, source: "exact_transition_source")
      |> Timeline.transition_application_summary()

    assert {:ok, %{"schema_contract" => "timeline_transition_application_summary.v1"}} =
             Schema.validate_artifact(summary)

    source_summary =
      Map.put(summary, "provenance", %{"trust_boundary" => "exact_source_transition"})

    result_summary =
      Map.put(summary, "provenance", %{"trust_boundary" => "exact_result_transition"})

    refresh = %{
      "source_result_artifact" => source_summary,
      "result_artifact" => result_summary
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_count" => 2,
             "source_report_row_count" => 6,
             "source_report_counts_by_contract" => %{
               "timeline_transition_application_summary.v1" => 2
             },
             "source_report_row_counts_by_contract" => %{
               "timeline_transition_application_summary.v1" => 6
             },
             "source_report_timeline_transition_application_contract" =>
               "timeline_transition_application_summary.v1",
             "source_report_timeline_transition_application_count" => 2,
             "source_report_timeline_transition_application_row_count" => 6,
             "source_report_timeline_transition_application_paths" => [
               "source_result_artifact",
               "result_artifact"
             ],
             "source_report_timeline_transition_application_application_count" => 6,
             "source_report_timeline_transition_application_selected_activity_count" => 2,
             "source_report_timeline_transition_application_selected_activity_id_counts" => %{
               "exact_cmd_lock" => 2
             },
             "source_report_timeline_transition_application_review_activity_id_counts" => %{
               "exact_cmd_added" => 2,
               "exact_cmd_lock" => 2,
               "exact_obs_self_dependency" => 2
             },
             "source_report_timeline_transition_application_review_required_count" => 6,
             "source_report_timeline_transition_application_preserved_source_count" => 2,
             "source_report_timeline_transition_application_withheld_review_count" => 4,
             "source_reports" => %{
               "timeline_transition_application_report" => %{
                 "contract" => "timeline_transition_application_summary.v1",
                 "count" => 2,
                 "row_count" => 6,
                 "paths" => ["source_result_artifact", "result_artifact"],
                 "application_count" => 6,
                 "selected_activity_count" => 2,
                 "selected_activity_id_counts" => %{"exact_cmd_lock" => 2},
                 "review_activity_id_counts" => %{
                   "exact_cmd_added" => 2,
                   "exact_cmd_lock" => 2,
                   "exact_obs_self_dependency" => 2
                 },
                 "review_required_count" => 6,
                 "preserved_source_count" => 2,
                 "withheld_review_count" => 4,
                 "trust_boundary_status" => "declared",
                 "trust_boundaries" => [
                   "exact_result_transition",
                   "exact_source_transition"
                 ]
               }
             }
           } = CandidateRefresh.source_report_summary(refresh)

    assert %{
             "contract" => "timeline_transition_application_summary.v1",
             "source_report_count" => 2,
             "source_report_row_count" => 6,
             "source_application_count" => 6,
             "source_report_paths" => ["source_result_artifact", "result_artifact"],
             "selected_activity_count" => 2,
             "selected_activity_id_counts" => %{"exact_cmd_lock" => 2},
             "review_activity_id_counts" => %{
               "exact_cmd_added" => 2,
               "exact_cmd_lock" => 2,
               "exact_obs_self_dependency" => 2
             },
             "review_required_count" => 6,
             "preserved_source_count" => 2,
             "withheld_review_count" => 4,
             "trust_boundaries" => [
               "exact_result_transition",
               "exact_source_transition"
             ],
             "branch_local_timeline_transition_application_pressure" => true,
             "branch_local_selected_activity_pressure" => true,
             "branch_local_review_required_pressure" => true,
             "branch_local_preserved_transition_pressure" => true,
             "branch_local_operator_review_pressure" => true
           } = CandidateRefresh.timeline_transition_application_replay_summary(refresh)
  end

  test "timeline transition application replay treats selected activity evidence as family pressure" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "timeline_transition_application_report" => %{
            "contract" => "timeline_transition_application_report.v1",
            "count" => 1,
            "row_count" => 0,
            "paths" => ["source_timeline_transition_application_report"],
            "application_count" => 0,
            "selected_activity_count" => 1,
            "selected_activity_id_counts" => %{"selected_downlink_activity" => 1},
            "application_status_counts" => %{},
            "transition_decision_counts" => %{},
            "trust_boundary_status" => "declared",
            "trust_boundaries" => ["ops_transition_application"]
          }
        }
      }
    }

    summary = CandidateRefresh.timeline_transition_application_replay_summary(artifact)

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 0
    assert summary["source_application_count"] == 0
    assert summary["selected_activity_count"] == 1
    assert summary["selected_activity_id_counts"] == %{"selected_downlink_activity" => 1}
    assert summary["application_status_counts"] == %{}
    assert summary["transition_decision_counts"] == %{}
    assert summary["branch_local_timeline_transition_application_pressure"]
    assert summary["branch_local_selected_activity_pressure"]
    refute summary["branch_local_review_required_pressure"]
    refute summary["branch_local_preserved_transition_pressure"]
    refute summary["branch_local_duplicate_identity_pressure"]
    refute summary["branch_local_operator_review_pressure"]
  end

  test "timeline transition application replay treats review preservation and duplicate evidence as family pressure" do
    base_summary = %{
      "contract" => "timeline_transition_application_report.v1",
      "count" => 1,
      "row_count" => 0,
      "paths" => ["source_timeline_transition_application_report"],
      "application_count" => 0,
      "selected_activity_count" => 0,
      "selected_activity_id_counts" => %{},
      "application_status_counts" => %{},
      "transition_decision_counts" => %{},
      "trust_boundary_status" => "declared",
      "trust_boundaries" => ["ops_transition_application"]
    }

    cases = [
      {"review count", %{"review_required_count" => 1}, "branch_local_review_required_pressure"},
      {"review action", %{"required_operator_action_counts" => %{"review_timeline_change" => 1}},
       "branch_local_review_required_pressure"},
      {"preserved source", %{"preserved_source_count" => 1},
       "branch_local_preserved_transition_pressure"},
      {"recorded replacement", %{"recorded_replacement_count" => 1},
       "branch_local_preserved_transition_pressure"},
      {"duplicate count", %{"duplicate_timeline_identity_count" => 1},
       "branch_local_duplicate_identity_pressure"},
      {"duplicate scope", %{"duplicate_timeline_identity_scope_counts" => %{"source" => 1}},
       "branch_local_duplicate_identity_pressure"}
    ]

    for {label, evidence, expected_pressure} <- cases do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "timeline_transition_application_report" => Map.merge(base_summary, evidence)
          }
        }
      }

      summary = CandidateRefresh.timeline_transition_application_replay_summary(artifact)

      assert summary["source_application_count"] == 0, label
      assert summary["source_report_row_count"] == 0, label
      assert summary["selected_activity_count"] == 0, label
      assert summary["selected_activity_id_counts"] == %{}, label
      assert summary["application_status_counts"] == %{}, label
      assert summary["transition_decision_counts"] == %{}, label
      refute summary["branch_local_selected_activity_pressure"], label
      assert summary[expected_pressure], label
      assert summary["branch_local_timeline_transition_application_pressure"], label
    end
  end

  test "timeline transition application replay summary omits contract when source report is absent" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => %{}}
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    summary = CandidateRefresh.timeline_transition_application_replay_summary(artifact)

    refute Map.has_key?(source_summary, "source_report_timeline_transition_application_contract")
    refute Map.has_key?(source_summary, "source_report_timeline_transition_application_count")
    refute Map.has_key?(source_summary, "source_report_timeline_transition_application_row_count")
    refute Map.has_key?(source_summary, "source_report_timeline_transition_application_paths")
    assert summary["source_report_count"] == 0
    assert summary["source_report_row_count"] == 0
    assert summary["source_application_count"] == 0
    assert summary["source_report_paths"] == []
    refute Map.has_key?(summary, "contract")
    refute summary["branch_local_timeline_transition_application_pressure"]
  end

  test "timeline transition application source summary omits missing identity counts for partial family placeholder" do
    partial_summaries = [
      %{"contract" => "timeline_transition_application_report.v1"},
      %{"count" => 1},
      %{"row_count" => 2},
      %{"paths" => ["provenance.source_reports.timeline_transition_application_report"]},
      %{"count" => nil, "row_count" => nil},
      %{
        "count" => nil,
        "row_count" => nil,
        "paths" => ["provenance.source_reports.timeline_transition_application_report"]
      }
    ]

    for partial_summary <- partial_summaries do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "timeline_transition_application_report" => partial_summary
          }
        }
      }

      source_summary = CandidateRefresh.source_report_summary(artifact)

      if Map.has_key?(partial_summary, "contract") do
        assert source_summary["source_report_timeline_transition_application_contract"] ==
                 "timeline_transition_application_report.v1"
      else
        refute Map.has_key?(
                 source_summary,
                 "source_report_timeline_transition_application_contract"
               )
      end

      refute Map.has_key?(source_summary, "source_report_timeline_transition_application_count")

      refute Map.has_key?(
               source_summary,
               "source_report_timeline_transition_application_row_count"
             )

      refute Map.has_key?(source_summary, "source_report_timeline_transition_application_paths")
    end
  end

  test "timeline transition application source summary preserves explicit empty identity counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "timeline_transition_application_report" => %{
            "contract" => "timeline_transition_application_report.v1",
            "count" => 0,
            "row_count" => 0,
            "paths" => ["provenance.source_reports.timeline_transition_application_report"]
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_timeline_transition_application_contract"] ==
             "timeline_transition_application_report.v1"

    assert source_summary["source_report_timeline_transition_application_count"] == 0
    assert source_summary["source_report_timeline_transition_application_row_count"] == 0

    assert source_summary["source_report_timeline_transition_application_paths"] == [
             "provenance.source_reports.timeline_transition_application_report"
           ]
  end

  test "timeline transition application source summary omits missing identity paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "timeline_transition_application_report" => %{
            "contract" => "timeline_transition_application_report.v1",
            "count" => 1,
            "row_count" => 2
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_timeline_transition_application_contract"] ==
             "timeline_transition_application_report.v1"

    assert source_summary["source_report_timeline_transition_application_count"] == 1
    assert source_summary["source_report_timeline_transition_application_row_count"] == 2
    refute Map.has_key?(source_summary, "source_report_timeline_transition_application_paths")
  end

  test "timeline transition application source summary preserves empty identity paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "timeline_transition_application_report" => %{
            "contract" => "timeline_transition_application_report.v1",
            "count" => 1,
            "row_count" => 2,
            "paths" => []
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_timeline_transition_application_contract"] ==
             "timeline_transition_application_report.v1"

    assert source_summary["source_report_timeline_transition_application_count"] == 1
    assert source_summary["source_report_timeline_transition_application_row_count"] == 2
    assert source_summary["source_report_timeline_transition_application_paths"] == []
  end

  test "timeline transition application replay reads strategy branch candidate-source summary metadata" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "timeline_transition_application_report" => %{
              "contract" => "timeline_transition_application_report.v1",
              "count" => 1,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_timeline_transition_application_report"
              ],
              "application_count" => 3,
              "selected_activity_count" => 1,
              "selected_activity_id_counts" => %{"selected_downlink_activity" => 1},
              "review_activity_id_counts" => %{"review_downlink_activity" => 1},
              "review_required_count" => 2,
              "preserved_source_count" => 1,
              "recorded_replacement_count" => 1,
              "withheld_review_count" => 1,
              "duplicate_timeline_identity_count" => 2,
              "duplicate_source_timeline_identity_count" => 1,
              "duplicate_replacement_timeline_identity_count" => 1,
              "application_status_counts" => %{
                "operator_review_required" => 1,
                "selected" => 1,
                "source_preserved_pending_review" => 1
              },
              "transition_decision_counts" => %{
                "apply" => 1,
                "preserve_source" => 1,
                "review" => 1
              },
              "required_operator_action_counts" => %{
                "none" => 1,
                "review_timeline_change" => 1
              },
              "duplicate_timeline_identity_scope_counts" => %{
                "replacement" => 1,
                "source" => 1
              },
              "trust_boundary_status" => "declared",
              "trust_boundaries" => ["branch_transition_application"]
            }
          }
        }
      },
      "provenance" => %{"source_reports" => %{}}
    }

    summary = CandidateRefresh.timeline_transition_application_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_transition_application_report"

    assert summary["contract"] == "timeline_transition_application_report.v1"
    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 3
    assert summary["source_application_count"] == 3

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_timeline_transition_application_report"
           ]

    assert summary["selected_activity_count"] == 1
    assert summary["selected_activity_id_counts"] == %{"selected_downlink_activity" => 1}
    assert summary["review_activity_id_counts"] == %{"review_downlink_activity" => 1}
    assert summary["review_required_count"] == 2
    assert summary["preserved_source_count"] == 1
    assert summary["recorded_replacement_count"] == 1
    assert summary["withheld_review_count"] == 1
    assert summary["duplicate_timeline_identity_count"] == 2
    assert summary["duplicate_source_timeline_identity_count"] == 1
    assert summary["duplicate_replacement_timeline_identity_count"] == 1

    assert summary["application_status_counts"] == %{
             "operator_review_required" => 1,
             "selected" => 1,
             "source_preserved_pending_review" => 1
           }

    assert summary["transition_decision_counts"] == %{
             "apply" => 1,
             "preserve_source" => 1,
             "review" => 1
           }

    assert summary["required_operator_action_counts"] == %{
             "none" => 1,
             "review_timeline_change" => 1
           }

    assert summary["duplicate_timeline_identity_scope_counts"] == %{
             "replacement" => 1,
             "source" => 1
           }

    assert summary["trust_boundary_status"] == "declared"
    assert summary["trust_boundaries"] == ["branch_transition_application"]
    assert summary["branch_local_timeline_transition_application_pressure"]
    assert summary["branch_local_selected_activity_pressure"]
    assert summary["branch_local_review_required_pressure"]
    assert summary["branch_local_preserved_transition_pressure"]
    assert summary["branch_local_duplicate_identity_pressure"]
    assert summary["branch_local_operator_review_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_transition_application_candidate_source_report_summary_only"

    assert OrbitalDynamics.candidate_refresh_timeline_transition_application_replay_summary(
             artifact
           ) == summary
  end

  test "timeline transition application replay reads compact strategy branch summary metadata" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "timeline_transition_application_report" => %{
              "contract" => "timeline_transition_application_summary.v1",
              "count" => 1,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_timeline_transition_application_summary"
              ],
              "application_count" => 2,
              "selected_activity_count" => 1,
              "selected_timeline_integrity_review_count" => 1,
              "selected_timeline_integrity_issue_count" => 2,
              "selected_timeline_integrity_issue_type_counts" => %{
                "missing_dependency_activity" => 1,
                "self_dependency_timeline" => 1
              },
              "selected_activity_id_counts" => %{"branch_cmd_lock" => 1},
              "review_activity_id_counts" => %{"branch_cmd_added" => 1},
              "review_required_count" => 1,
              "preserved_source_count" => 1,
              "recorded_replacement_count" => 0,
              "withheld_review_count" => 1,
              "application_status_counts" => %{
                "operator_review_required" => 1,
                "source_preserved_pending_review" => 1
              },
              "transition_decision_counts" => %{"preserve_source" => 1, "review" => 1},
              "required_operator_action_counts" => %{
                "review_added_activity" => 1,
                "review_timeline_integrity" => 1
              },
              "trust_boundary_status" => "declared",
              "trust_boundaries" => ["branch_compact_transition_summary"]
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "timeline_transition_application_report" => %{
            "contract" => "timeline_transition_application_report.v1",
            "count" => 9,
            "paths" => ["source_timeline_transition_application_report"],
            "application_count" => 9,
            "selected_activity_id_counts" => %{"stale_selected_activity" => 9}
          }
        }
      }
    }

    summary = CandidateRefresh.timeline_transition_application_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_transition_application_report"

    assert summary["contract"] == "timeline_transition_application_summary.v1"
    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 2
    assert summary["source_application_count"] == 2

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_timeline_transition_application_summary"
           ]

    assert summary["selected_activity_count"] == 1
    assert summary["selected_timeline_integrity_review_count"] == 1
    assert summary["selected_timeline_integrity_issue_count"] == 2

    assert summary["selected_timeline_integrity_issue_type_counts"] == %{
             "missing_dependency_activity" => 1,
             "self_dependency_timeline" => 1
           }

    assert summary["selected_activity_id_counts"] == %{"branch_cmd_lock" => 1}
    assert summary["review_activity_id_counts"] == %{"branch_cmd_added" => 1}
    assert summary["review_required_count"] == 1
    assert summary["preserved_source_count"] == 1
    assert summary["withheld_review_count"] == 1

    assert summary["application_status_counts"] == %{
             "operator_review_required" => 1,
             "source_preserved_pending_review" => 1
           }

    assert summary["transition_decision_counts"] == %{"preserve_source" => 1, "review" => 1}

    assert summary["required_operator_action_counts"] == %{
             "review_added_activity" => 1,
             "review_timeline_integrity" => 1
           }

    assert summary["trust_boundary_status"] == "declared"
    assert summary["trust_boundaries"] == ["branch_compact_transition_summary"]
    assert summary["branch_local_timeline_transition_application_pressure"]
    assert summary["branch_local_selected_activity_pressure"]
    assert summary["branch_local_selected_integrity_pressure"]
    assert summary["branch_local_review_required_pressure"]
    assert summary["branch_local_preserved_transition_pressure"]
    assert summary["branch_local_operator_review_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_transition_application_candidate_source_report_summary_only"

    assert OrbitalDynamics.candidate_refresh_timeline_transition_application_replay_summary(
             artifact
           ) == summary
  end

  test "timeline transition application replay labels direct candidate-source summary metadata" do
    candidate_source = %{
      "candidate_refresh_request_source_report_summary" => %{
        "source_reports" => %{
          "timeline_transition_application_report" => %{
            "contract" => "timeline_transition_application_report.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => [
              "candidate_source.candidate_refresh_request.source_timeline_transition_application_report"
            ],
            "application_count" => 1,
            "selected_activity_id_counts" => %{"direct_selected_activity" => 1},
            "required_operator_action_counts" => %{"none" => 1}
          }
        }
      }
    }

    summary = CandidateRefresh.timeline_transition_application_replay_summary(candidate_source)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_transition_application_report"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 1
    assert summary["source_application_count"] == 1

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_timeline_transition_application_report"
           ]

    assert summary["selected_activity_id_counts"] == %{"direct_selected_activity" => 1}
    assert summary["required_operator_action_counts"] == %{"none" => 1}
    assert summary["branch_local_timeline_transition_application_pressure"]
    assert summary["branch_local_selected_activity_pressure"]
    refute summary["branch_local_operator_review_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_transition_application_candidate_source_report_summary_only"
  end

  test "timeline transition application replay falls back to provenance when branch summary lacks usable family" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "timeline_transition_application_report" => %{},
            "timeline_diff_report" => %{
              "contract" => "timeline_diff_report.v1",
              "count" => 1,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_timeline_diff_report"
              ]
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "timeline_transition_application_report" => %{
            "contract" => "timeline_transition_application_report.v1",
            "count" => 1,
            "paths" => ["source_timeline_transition_application_report"],
            "application_count" => 2,
            "selected_activity_id_counts" => %{"provenance_selected_activity" => 1},
            "required_operator_action_counts" => %{"review_timeline_change" => 1}
          }
        }
      }
    }

    summary = CandidateRefresh.timeline_transition_application_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.source_report_provenance.timeline_transition_application_report"

    assert summary["source_report_paths"] == ["source_timeline_transition_application_report"]
    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 2
    assert summary["source_application_count"] == 2
    assert summary["selected_activity_id_counts"] == %{"provenance_selected_activity" => 1}
    assert summary["required_operator_action_counts"] == %{"review_timeline_change" => 1}
    assert summary["branch_local_timeline_transition_application_pressure"]
    assert summary["branch_local_operator_review_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_transition_application_source_report_provenance_only"
  end

  test "timeline transition application replay prefers partial branch family over provenance" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "timeline_transition_application_report" => %{
              "count" => 1,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_timeline_transition_application_report"
              ],
              "selected_activity_id_counts" => %{"branch_selected_activity" => 1}
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "timeline_transition_application_report" => %{
            "contract" => "timeline_transition_application_report.v1",
            "count" => 9,
            "paths" => ["source_timeline_transition_application_report"],
            "application_count" => 9,
            "review_required_count" => 9,
            "required_operator_action_counts" => %{"review_timeline_change" => 9}
          }
        }
      }
    }

    summary = CandidateRefresh.timeline_transition_application_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_transition_application_report"

    assert summary["source_report_count"] == 1
    assert summary["source_application_count"] == 0

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_timeline_transition_application_report"
           ]

    assert summary["selected_activity_id_counts"] == %{"branch_selected_activity" => 1}
    assert summary["review_required_count"] == 0
    assert summary["required_operator_action_counts"] == %{}
    assert summary["branch_local_timeline_transition_application_pressure"]
    assert summary["branch_local_selected_activity_pressure"]
    refute summary["branch_local_review_required_pressure"]
    refute summary["branch_local_operator_review_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_transition_application_candidate_source_report_summary_only"
  end
end
