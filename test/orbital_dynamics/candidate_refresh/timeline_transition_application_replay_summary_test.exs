defmodule OrbitalDynamics.CandidateRefresh.TimelineTransitionApplicationReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CandidateRefresh, Schema, Timeline}

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
end
