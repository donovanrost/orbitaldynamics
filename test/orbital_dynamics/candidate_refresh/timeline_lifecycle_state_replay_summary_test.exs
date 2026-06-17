defmodule OrbitalDynamics.CandidateRefresh.TimelineLifecycleStateReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, CandidateRefresh, OperatorReview, Schema, Timeline}

  test "source report summary replays timeline lifecycle-state summaries" do
    planned = [
      %{
        id: :cmd_pending,
        type: :command,
        status: :planned,
        approval_status: :pending,
        starts_at_s: 10.0,
        ends_at_s: 20.0,
        metadata: %{timeline_id: :"timeline:cmd_pending"}
      },
      %{
        id: :obs_done,
        type: :observe,
        status: :executed,
        approval_status: :approved,
        starts_at_s: 30.0,
        ends_at_s: 40.0,
        metadata: %{timeline_id: :"timeline:obs_done"}
      },
      %{
        id: :dup_a,
        type: :observe,
        status: :planned,
        starts_at_s: 50.0,
        ends_at_s: 60.0,
        metadata: %{timeline_id: :"timeline:dup"}
      },
      %{
        id: :dup_b,
        type: :observe,
        status: :planned,
        starts_at_s: 55.0,
        ends_at_s: 65.0,
        metadata: %{timeline_id: :"timeline:dup"}
      },
      %{
        id: :bad_missing_type,
        status: :planned,
        starts_at_s: 70.0,
        ends_at_s: 80.0,
        metadata: %{timeline_id: :"timeline:bad_missing_type"}
      }
    ]

    realized = [
      %{
        id: :cmd_pending,
        type: :command,
        status: :executed,
        approval_status: :approved,
        starts_at_s: 10.0,
        ends_at_s: 20.0,
        metadata: %{timeline_id: :"timeline:cmd_pending"}
      },
      %{
        id: :obs_done,
        type: :observe,
        status: :executed,
        approval_status: :approved,
        starts_at_s: 30.0,
        ends_at_s: 40.0,
        metadata: %{timeline_id: :"timeline:obs_done"}
      }
    ]

    transition_application_provenance = %{
      "field" => "status",
      "from" => "planned",
      "helper" => "apply_lifecycle_event",
      "operator_action_reason" => "activity_execution_recorded",
      "requires_operator_review" => false,
      "to" => "completed",
      "transition_category" => "execution_recorded",
      "transition_type" => "changed"
    }

    put_transition_application_provenance = fn
      %{"timeline_id" => "timeline:cmd_pending"} = row ->
        row
        |> Map.put("transition_application_provenance", transition_application_provenance)
        |> Map.put("activity_context", %{
          "transition_application_provenance" => transition_application_provenance
        })
        |> put_in(
          ["realized_activity_context", "transition_application_provenance"],
          transition_application_provenance
        )

      row ->
        row
    end

    lifecycle_summary =
      planned
      |> Timeline.lifecycle_state_summary(realized)
      |> update_in(["rows"], &Enum.map(&1, put_transition_application_provenance))
      |> update_in(["review_rows"], &Enum.map(&1, put_transition_application_provenance))
      |> Map.put("provenance", %{"trust_boundary" => "ops_lifecycle_summary"})

    assert {:ok, %{"schema_contract" => "timeline_lifecycle_state_summary.v1"}} =
             Schema.validate_artifact(lifecycle_summary)

    refresh = %{
      "accepted_planning_state" => %{
        "timeline_lifecycle_state_summary" => lifecycle_summary
      },
      "mission_state" => %{
        "source_timeline_lifecycle_state_summary" => lifecycle_summary
      },
      "source_timeline_lifecycle_state_summary" => lifecycle_summary,
      "source_result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "provenance" => %{"trust_boundary" => "wrapped_lifecycle_summary"},
        "timeline_lifecycle_state_summary" => Map.delete(lifecycle_summary, "provenance")
      }
    }

    expected_lifecycle_review_routing = %{
      "review_activity_approval" => %{
        "review_count" => 4,
        "activity_ids" => ["cmd_pending"],
        "timeline_ids" => ["timeline:cmd_pending"],
        "status_transition_categories" => ["execution_recorded"],
        "approval_transition_categories" => ["approval_granted"]
      },
      "review_duplicate_timeline_identity" => %{
        "review_count" => 4,
        "activity_ids" => ["dup_a", "dup_b"],
        "timeline_ids" => ["timeline:dup"],
        "status_transition_categories" => [],
        "approval_transition_categories" => []
      },
      "review_invalid_activity_input" => %{
        "review_count" => 4,
        "activity_ids" => ["timeline_row:5:bad_missing_type"],
        "timeline_ids" => ["timeline:invalid_activity_input:bad_missing_type"],
        "status_transition_categories" => [],
        "approval_transition_categories" => []
      }
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_count" => 4,
             "source_report_counts_by_contract" => %{
               "timeline_lifecycle_state_summary.v1" => 4
             },
             "source_report_timeline_lifecycle_state_contract" =>
               "timeline_lifecycle_state_summary.v1",
             "source_report_timeline_lifecycle_state_count" => 4,
             "source_report_timeline_lifecycle_state_row_count" => 16,
             "source_report_timeline_lifecycle_state_paths" => [
               "accepted_planning_state.timeline_lifecycle_state_summary",
               "mission_state.source_timeline_lifecycle_state_summary",
               "source_timeline_lifecycle_state_summary",
               "source_result_artifact.timeline_lifecycle_state_summary"
             ],
             "source_report_timeline_lifecycle_state_planned_activity_count" => 20,
             "source_report_timeline_lifecycle_state_realized_activity_count" => 8,
             "source_report_timeline_lifecycle_state_preserved_count" => 4,
             "source_report_timeline_lifecycle_state_review_required_count" => 12,
             "source_report_timeline_lifecycle_state_duplicate_timeline_identity_count" => 4,
             "source_report_timeline_lifecycle_state_invalid_activity_input_count" => 4,
             "source_report_timeline_lifecycle_state_invalid_activity_input_ids" => [
               "timeline_row:5:bad_missing_type"
             ],
             "source_report_timeline_lifecycle_state_transition_decision_counts" => %{
               "none" => 4,
               "review" => 12
             },
             "source_report_timeline_lifecycle_state_required_operator_action_counts" => %{
               "none" => 4,
               "review_activity_approval" => 4,
               "review_duplicate_timeline_identity" => 4,
               "review_invalid_activity_input" => 4
             },
             "source_report_timeline_lifecycle_state_import_action_counts" => %{
               "record_preserved_activity" => 4,
               "review_timeline_diff" => 12
             },
             "source_report_timeline_lifecycle_state_planned_status_category_counts" => %{
               "executed" => 4,
               "planned" => 4
             },
             "source_report_timeline_lifecycle_state_realized_status_category_counts" => %{
               "executed" => 8
             },
             "source_report_timeline_lifecycle_state_planned_approval_category_counts" => %{
               "protected" => 4,
               "review_required" => 4
             },
             "source_report_timeline_lifecycle_state_status_transition_category_counts" => %{
               "execution_recorded" => 4
             },
             "source_report_timeline_lifecycle_state_approval_transition_category_counts" => %{
               "approval_granted" => 4
             },
             "source_report_timeline_lifecycle_state_transition_application_provenance_count" =>
               4,
             "source_report_timeline_lifecycle_state_transition_application_provenance_helper_counts" =>
               %{"apply_lifecycle_event" => 4},
             "source_report_timeline_lifecycle_state_transition_application_provenance_category_counts" =>
               %{"execution_recorded" => 4},
             "source_report_timeline_lifecycle_state_transition_application_provenance_operator_action_reason_counts" =>
               %{"activity_execution_recorded" => 4},
             "source_report_timeline_lifecycle_state_preserved_timeline_ids" => [
               "timeline:obs_done"
             ],
             "source_report_timeline_lifecycle_state_review_timeline_ids" => [
               "timeline:cmd_pending",
               "timeline:dup",
               "timeline:invalid_activity_input:bad_missing_type"
             ],
             "source_report_timeline_lifecycle_state_review_activity_ids" => [
               "cmd_pending",
               "dup_a",
               "dup_b",
               "timeline_row:5:bad_missing_type"
             ],
             "source_report_timeline_lifecycle_state_review_timeline_ids_by_required_operator_action" =>
               %{
                 "review_activity_approval" => ["timeline:cmd_pending"],
                 "review_duplicate_timeline_identity" => ["timeline:dup"],
                 "review_invalid_activity_input" => [
                   "timeline:invalid_activity_input:bad_missing_type"
                 ]
               },
             "source_report_timeline_lifecycle_state_review_routing" =>
               ^expected_lifecycle_review_routing,
             "source_report_timeline_lifecycle_state_branch_local_timeline_lifecycle_state_pressure" =>
               true,
             "source_report_timeline_lifecycle_state_branch_local_lifecycle_review_pressure" =>
               true,
             "source_report_timeline_lifecycle_state_branch_local_lifecycle_recordable_pressure" =>
               false,
             "source_report_timeline_lifecycle_state_branch_local_lifecycle_preservation_pressure" =>
               true,
             "source_reports" => %{
               "timeline_lifecycle_state_summary" => %{
                 "contract" => "timeline_lifecycle_state_summary.v1",
                 "count" => 4,
                 "row_count" => 16,
                 "planned_activity_count" => 20,
                 "realized_activity_count" => 8,
                 "review_required_count" => 12,
                 "invalid_activity_input_count" => 4,
                 "invalid_activity_input_ids" => ["timeline_row:5:bad_missing_type"],
                 "transition_application_provenance_count" => 4,
                 "transition_application_provenance_helper_counts" => %{
                   "apply_lifecycle_event" => 4
                 },
                 "transition_application_provenance_category_counts" => %{
                   "execution_recorded" => 4
                 },
                 "transition_application_provenance_operator_action_reason_counts" => %{
                   "activity_execution_recorded" => 4
                 },
                 "source_summary_model_counts" => %{
                   "artifact_only_timeline_lifecycle_state_summary" => 4
                 },
                 "source_summary_schema_contract_counts" => %{
                   "timeline_lifecycle_state_summary.v1" => 4
                 },
                 "paths" => [
                   "accepted_planning_state.timeline_lifecycle_state_summary",
                   "mission_state.source_timeline_lifecycle_state_summary",
                   "source_timeline_lifecycle_state_summary",
                   "source_result_artifact.timeline_lifecycle_state_summary"
                 ],
                 "trust_boundary_status" => "declared",
                 "trust_boundaries" => [
                   "ops_lifecycle_summary",
                   "wrapped_lifecycle_summary"
                 ],
                 "review_routing" => ^expected_lifecycle_review_routing
               }
             }
           } = source_summary = CandidateRefresh.source_report_summary(refresh)

    replay = CandidateRefresh.timeline_lifecycle_state_replay_summary(refresh)

    assert %{
             "model" => "artifact_only_candidate_refresh_timeline_lifecycle_state_replay_summary",
             "source" =>
               "candidate_refresh.source_report_provenance.timeline_lifecycle_state_summary",
             "contract" => "timeline_lifecycle_state_summary.v1",
             "source_report_count" => 4,
             "source_report_row_count" => 16,
             "source_report_paths" => [
               "accepted_planning_state.timeline_lifecycle_state_summary",
               "mission_state.source_timeline_lifecycle_state_summary",
               "source_timeline_lifecycle_state_summary",
               "source_result_artifact.timeline_lifecycle_state_summary"
             ],
             "planned_activity_count" => 20,
             "realized_activity_count" => 8,
             "preserved_count" => 4,
             "review_required_count" => 12,
             "duplicate_timeline_identity_count" => 4,
             "invalid_activity_input_count" => 4,
             "invalid_activity_input_ids" => ["timeline_row:5:bad_missing_type"],
             "transition_decision_counts" => %{"none" => 4, "review" => 12},
             "required_operator_action_counts" => %{
               "none" => 4,
               "review_activity_approval" => 4,
               "review_duplicate_timeline_identity" => 4,
               "review_invalid_activity_input" => 4
             },
             "import_action_counts" => %{
               "record_preserved_activity" => 4,
               "review_timeline_diff" => 12
             },
             "transition_application_provenance_count" => 4,
             "transition_application_provenance_helper_counts" => %{
               "apply_lifecycle_event" => 4
             },
             "transition_application_provenance_category_counts" => %{
               "execution_recorded" => 4
             },
             "transition_application_provenance_operator_action_reason_counts" => %{
               "activity_execution_recorded" => 4
             },
             "review_timeline_ids" => [
               "timeline:cmd_pending",
               "timeline:dup",
               "timeline:invalid_activity_input:bad_missing_type"
             ],
             "review_activity_ids" => [
               "cmd_pending",
               "dup_a",
               "dup_b",
               "timeline_row:5:bad_missing_type"
             ],
             "review_timeline_ids_by_required_operator_action" => %{
               "review_activity_approval" => ["timeline:cmd_pending"],
               "review_duplicate_timeline_identity" => ["timeline:dup"],
               "review_invalid_activity_input" => [
                 "timeline:invalid_activity_input:bad_missing_type"
               ]
             },
             "review_routing" => ^expected_lifecycle_review_routing,
             "trust_boundary_status" => "declared",
             "trust_boundaries" => [
               "ops_lifecycle_summary",
               "wrapped_lifecycle_summary"
             ],
             "branch_local_timeline_lifecycle_state_pressure" => true,
             "branch_local_lifecycle_review_pressure" => true,
             "branch_local_lifecycle_recordable_pressure" => false,
             "branch_local_lifecycle_preservation_pressure" => true
           } = replay

    assert OrbitalDynamics.candidate_refresh_timeline_lifecycle_state_replay_summary(refresh) ==
             replay

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => source_summary["source_reports"]}
    }

    assert %{
             "source_report_timeline_lifecycle_state_branch_local_timeline_lifecycle_state_pressure" =>
               true,
             "source_report_timeline_lifecycle_state_branch_local_lifecycle_review_pressure" =>
               true,
             "source_report_timeline_lifecycle_state_branch_local_lifecycle_recordable_pressure" =>
               false,
             "source_report_timeline_lifecycle_state_branch_local_lifecycle_preservation_pressure" =>
               true
           } = CandidateRefresh.source_report_summary(artifact)

    assert CandidateRefresh.timeline_lifecycle_state_replay_summary(artifact) == replay

    assert OrbitalDynamics.candidate_refresh_timeline_lifecycle_state_replay_summary(artifact) ==
             replay
  end

  test "timeline lifecycle state source summaries derive stale aggregate pressure from rows" do
    planned = [
      %{
        id: :stale_lifecycle_cmd_pending,
        type: :command,
        status: :planned,
        approval_status: :pending,
        starts_at_s: 10.0,
        ends_at_s: 20.0,
        metadata: %{timeline_id: :"timeline:stale_lifecycle:cmd_pending"}
      },
      %{
        id: :stale_lifecycle_dup_a,
        type: :observe,
        status: :planned,
        metadata: %{timeline_id: :"timeline:stale_lifecycle:dup"}
      },
      %{
        id: :stale_lifecycle_dup_b,
        type: :observe,
        status: :planned,
        metadata: %{timeline_id: :"timeline:stale_lifecycle:dup"}
      },
      %{id: :stale_lifecycle_bad_missing_type, status: :planned}
    ]

    realized = [
      %{
        id: :stale_lifecycle_cmd_pending,
        type: :command,
        status: :executed,
        approval_status: :approved,
        starts_at_s: 10.0,
        ends_at_s: 20.0,
        metadata: %{timeline_id: :"timeline:stale_lifecycle:cmd_pending"}
      }
    ]

    stale_summary =
      planned
      |> Timeline.lifecycle_state_summary(realized)
      |> Map.put("provenance", %{"trust_boundary" => "stale_lifecycle_source_summary"})
      |> update_in(["rows"], fn rows ->
        Enum.map(rows, &Map.put(&1, "review_required_count", 0))
      end)
      |> Map.merge(%{
        "row_count" => 0,
        "recordable_count" => 0,
        "preserved_count" => 0,
        "review_required_count" => 0,
        "duplicate_timeline_identity_count" => 0,
        "invalid_activity_input_count" => 0,
        "invalid_activity_input_ids" => [],
        "transition_decision_counts" => %{},
        "required_operator_action_counts" => %{},
        "import_action_counts" => %{},
        "planned_status_category_counts" => %{},
        "realized_status_category_counts" => %{},
        "planned_approval_category_counts" => %{},
        "realized_approval_category_counts" => %{},
        "status_transition_category_counts" => %{},
        "approval_transition_category_counts" => %{},
        "recordable_timeline_ids" => [],
        "preserved_timeline_ids" => [],
        "review_timeline_ids" => [],
        "review_activity_ids" => [],
        "review_timeline_ids_by_required_operator_action" => %{},
        "review_timeline_ids_by_status_transition_category" => %{},
        "review_timeline_ids_by_approval_transition_category" => %{},
        "review_routing" => %{}
      })

    refresh = %{"source_timeline_lifecycle_state_summary" => stale_summary}

    assert %{
             "source_report_timeline_lifecycle_state_count" => 1,
             "source_report_timeline_lifecycle_state_row_count" => 3,
             "source_report_timeline_lifecycle_state_review_required_count" => 3,
             "source_report_timeline_lifecycle_state_duplicate_timeline_identity_count" => 1,
             "source_report_timeline_lifecycle_state_invalid_activity_input_count" => 1,
             "source_report_timeline_lifecycle_state_invalid_activity_input_ids" => [
               "timeline_row:4:stale_lifecycle_bad_missing_type"
             ],
             "source_report_timeline_lifecycle_state_transition_decision_counts" => %{
               "review" => 3
             },
             "source_report_timeline_lifecycle_state_required_operator_action_counts" => %{
               "review_activity_approval" => 1,
               "review_duplicate_timeline_identity" => 1,
               "review_invalid_activity_input" => 1
             },
             "source_report_timeline_lifecycle_state_import_action_counts" => %{
               "review_timeline_diff" => 3
             },
             "source_report_timeline_lifecycle_state_review_timeline_ids" => [
               "timeline:invalid_activity_input:stale_lifecycle_bad_missing_type",
               "timeline:stale_lifecycle:cmd_pending",
               "timeline:stale_lifecycle:dup"
             ],
             "source_report_timeline_lifecycle_state_review_activity_ids" => [
               "stale_lifecycle_cmd_pending",
               "stale_lifecycle_dup_a",
               "stale_lifecycle_dup_b",
               "timeline_row:4:stale_lifecycle_bad_missing_type"
             ],
             "source_report_timeline_lifecycle_state_branch_local_timeline_lifecycle_state_pressure" =>
               true,
             "source_report_timeline_lifecycle_state_branch_local_lifecycle_review_pressure" =>
               true
           } = CandidateRefresh.source_report_summary(refresh)

    assert %{
             "source_report_row_count" => 3,
             "review_required_count" => 3,
             "duplicate_timeline_identity_count" => 1,
             "invalid_activity_input_count" => 1,
             "required_operator_action_counts" => %{
               "review_activity_approval" => 1,
               "review_duplicate_timeline_identity" => 1,
               "review_invalid_activity_input" => 1
             },
             "branch_local_timeline_lifecycle_state_pressure" => true,
             "branch_local_lifecycle_review_pressure" => true
           } = CandidateRefresh.timeline_lifecycle_state_replay_summary(refresh)
  end

  test "timeline lifecycle state replay summary omits contract when source report is absent" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => %{}}
    }

    summary = CandidateRefresh.timeline_lifecycle_state_replay_summary(artifact)
    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert summary["source_report_count"] == 0
    assert summary["source_report_row_count"] == 0
    assert summary["source_report_paths"] == []
    refute Map.has_key?(summary, "contract")
    assert summary["transition_application_provenance_count"] == 0
    assert summary["transition_application_provenance_helper_counts"] == %{}
    assert summary["transition_application_provenance_category_counts"] == %{}

    assert summary["transition_application_provenance_operator_action_reason_counts"] == %{}
    refute summary["branch_local_timeline_lifecycle_state_pressure"]
    refute Map.has_key?(source_summary, "source_report_timeline_lifecycle_state_contract")
    refute Map.has_key?(source_summary, "source_report_timeline_lifecycle_state_count")
    refute Map.has_key?(source_summary, "source_report_timeline_lifecycle_state_row_count")
    refute Map.has_key?(source_summary, "source_report_timeline_lifecycle_state_paths")
  end

  test "timeline lifecycle state source summary keeps declared contract without partial identity placeholders" do
    placeholder_fields = [
      %{"count" => 1},
      %{"row_count" => 2},
      %{"paths" => ["provenance.source_reports.timeline_lifecycle_state_summary"]},
      %{"count" => nil, "row_count" => 2},
      %{"count" => 1, "row_count" => nil}
    ]

    for placeholder <- placeholder_fields do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "timeline_lifecycle_state_summary" =>
              Map.put(
                placeholder,
                "contract",
                "timeline_lifecycle_state_summary.v1"
              )
          }
        }
      }

      source_summary = CandidateRefresh.source_report_summary(artifact)

      assert source_summary["source_report_timeline_lifecycle_state_contract"] ==
               "timeline_lifecycle_state_summary.v1"

      refute Map.has_key?(source_summary, "source_report_timeline_lifecycle_state_count")

      refute Map.has_key?(
               source_summary,
               "source_report_timeline_lifecycle_state_row_count"
             )

      refute Map.has_key?(source_summary, "source_report_timeline_lifecycle_state_paths")
    end
  end

  test "timeline lifecycle state source summary preserves explicit empty identity counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "timeline_lifecycle_state_summary" => %{
            "contract" => "timeline_lifecycle_state_summary.v1",
            "count" => 0,
            "row_count" => 0,
            "paths" => ["provenance.source_reports.timeline_lifecycle_state_summary"]
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_timeline_lifecycle_state_contract"] ==
             "timeline_lifecycle_state_summary.v1"

    assert source_summary["source_report_timeline_lifecycle_state_count"] == 0
    assert source_summary["source_report_timeline_lifecycle_state_row_count"] == 0

    assert source_summary["source_report_timeline_lifecycle_state_paths"] == [
             "provenance.source_reports.timeline_lifecycle_state_summary"
           ]
  end

  test "timeline lifecycle state source summary omits missing identity paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "timeline_lifecycle_state_summary" => %{
            "contract" => "timeline_lifecycle_state_summary.v1",
            "count" => 1,
            "row_count" => 2
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_timeline_lifecycle_state_contract"] ==
             "timeline_lifecycle_state_summary.v1"

    assert source_summary["source_report_timeline_lifecycle_state_count"] == 1
    assert source_summary["source_report_timeline_lifecycle_state_row_count"] == 2
    refute Map.has_key?(source_summary, "source_report_timeline_lifecycle_state_paths")
  end

  test "timeline lifecycle state source summary preserves empty identity paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "timeline_lifecycle_state_summary" => %{
            "contract" => "timeline_lifecycle_state_summary.v1",
            "count" => 1,
            "row_count" => 2,
            "paths" => []
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_timeline_lifecycle_state_contract"] ==
             "timeline_lifecycle_state_summary.v1"

    assert source_summary["source_report_timeline_lifecycle_state_count"] == 1
    assert source_summary["source_report_timeline_lifecycle_state_row_count"] == 2
    assert source_summary["source_report_timeline_lifecycle_state_paths"] == []
  end

  test "timeline lifecycle state replay reads strategy branch candidate-source summary metadata" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "timeline_lifecycle_state_summary" => %{
              "contract" => "timeline_lifecycle_state_summary.v1",
              "count" => 1,
              "row_count" => 3,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_timeline_lifecycle_state_summary"
              ],
              "source_summary_model_counts" => %{
                "artifact_only_timeline_lifecycle_state_summary" => 1
              },
              "source_summary_schema_contract_counts" => %{
                "timeline_lifecycle_state_summary.v1" => 1
              },
              "planned_activity_count" => 3,
              "realized_activity_count" => 2,
              "recordable_count" => 1,
              "preserved_count" => 1,
              "review_required_count" => 1,
              "duplicate_timeline_identity_count" => 1,
              "invalid_activity_input_count" => 1,
              "invalid_activity_input_ids" => ["timeline_row:5:bad_missing_type"],
              "transition_decision_counts" => %{"record" => 1, "review" => 1},
              "required_operator_action_counts" => %{"review_activity_approval" => 1},
              "import_action_counts" => %{"review_timeline_diff" => 1},
              "planned_status_category_counts" => %{"planned" => 1},
              "realized_status_category_counts" => %{"executed" => 1},
              "planned_approval_category_counts" => %{"review_required" => 1},
              "realized_approval_category_counts" => %{"protected" => 1},
              "status_transition_category_counts" => %{"execution_recorded" => 1},
              "approval_transition_category_counts" => %{"approval_granted" => 1},
              "transition_application_provenance_count" => 1,
              "transition_application_provenance_helper_counts" => %{
                "apply_lifecycle_event" => 1
              },
              "transition_application_provenance_category_counts" => %{
                "execution_recorded" => 1
              },
              "transition_application_provenance_operator_action_reason_counts" => %{
                "activity_execution_recorded" => 1
              },
              "recordable_timeline_ids" => ["timeline:cmd_recordable"],
              "preserved_timeline_ids" => ["timeline:obs_done"],
              "review_timeline_ids" => ["timeline:cmd_pending"],
              "review_activity_ids" => ["cmd_pending"],
              "review_timeline_ids_by_required_operator_action" => %{
                "review_activity_approval" => ["timeline:cmd_pending"]
              },
              "review_timeline_ids_by_status_transition_category" => %{
                "execution_recorded" => ["timeline:cmd_recordable"]
              },
              "review_timeline_ids_by_approval_transition_category" => %{
                "approval_granted" => ["timeline:cmd_pending"]
              },
              "review_routing" => %{
                "by_required_operator_action" => %{
                  "review_activity_approval" => ["timeline:cmd_pending"]
                }
              },
              "trust_boundary_status" => "declared",
              "trust_boundaries" => ["branch_lifecycle"]
            }
          }
        }
      },
      "provenance" => %{"source_reports" => %{}}
    }

    summary = CandidateRefresh.timeline_lifecycle_state_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_lifecycle_state_summary"

    assert summary["contract"] == "timeline_lifecycle_state_summary.v1"
    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 3

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_timeline_lifecycle_state_summary"
           ]

    assert summary["source_summary_model_counts"] == %{
             "artifact_only_timeline_lifecycle_state_summary" => 1
           }

    assert summary["source_summary_schema_contract_counts"] == %{
             "timeline_lifecycle_state_summary.v1" => 1
           }

    assert summary["planned_activity_count"] == 3
    assert summary["realized_activity_count"] == 2
    assert summary["recordable_count"] == 1
    assert summary["preserved_count"] == 1
    assert summary["review_required_count"] == 1
    assert summary["duplicate_timeline_identity_count"] == 1
    assert summary["invalid_activity_input_count"] == 1
    assert summary["invalid_activity_input_ids"] == ["timeline_row:5:bad_missing_type"]
    assert summary["transition_decision_counts"] == %{"record" => 1, "review" => 1}
    assert summary["required_operator_action_counts"] == %{"review_activity_approval" => 1}
    assert summary["import_action_counts"] == %{"review_timeline_diff" => 1}
    assert summary["planned_status_category_counts"] == %{"planned" => 1}
    assert summary["realized_status_category_counts"] == %{"executed" => 1}
    assert summary["planned_approval_category_counts"] == %{"review_required" => 1}
    assert summary["realized_approval_category_counts"] == %{"protected" => 1}
    assert summary["status_transition_category_counts"] == %{"execution_recorded" => 1}
    assert summary["approval_transition_category_counts"] == %{"approval_granted" => 1}
    assert summary["transition_application_provenance_count"] == 1

    assert summary["transition_application_provenance_helper_counts"] == %{
             "apply_lifecycle_event" => 1
           }

    assert summary["transition_application_provenance_category_counts"] == %{
             "execution_recorded" => 1
           }

    assert summary["transition_application_provenance_operator_action_reason_counts"] == %{
             "activity_execution_recorded" => 1
           }

    assert summary["recordable_timeline_ids"] == ["timeline:cmd_recordable"]
    assert summary["preserved_timeline_ids"] == ["timeline:obs_done"]
    assert summary["review_timeline_ids"] == ["timeline:cmd_pending"]
    assert summary["review_activity_ids"] == ["cmd_pending"]

    assert summary["review_timeline_ids_by_required_operator_action"] == %{
             "review_activity_approval" => ["timeline:cmd_pending"]
           }

    assert summary["review_timeline_ids_by_status_transition_category"] == %{
             "execution_recorded" => ["timeline:cmd_recordable"]
           }

    assert summary["review_timeline_ids_by_approval_transition_category"] == %{
             "approval_granted" => ["timeline:cmd_pending"]
           }

    assert summary["review_routing"] == %{
             "by_required_operator_action" => %{
               "review_activity_approval" => ["timeline:cmd_pending"]
             }
           }

    assert summary["trust_boundary_status"] == "declared"
    assert summary["trust_boundaries"] == ["branch_lifecycle"]
    assert summary["branch_local_timeline_lifecycle_state_pressure"]
    assert summary["branch_local_lifecycle_review_pressure"]
    assert summary["branch_local_lifecycle_recordable_pressure"]
    assert summary["branch_local_lifecycle_preservation_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_lifecycle_state_candidate_source_report_summary_only"

    assert OrbitalDynamics.candidate_refresh_timeline_lifecycle_state_replay_summary(artifact) ==
             summary
  end

  test "timeline lifecycle state replay labels direct candidate-source summary metadata" do
    candidate_source = %{
      "candidate_refresh_request_source_report_summary" => %{
        "source_reports" => %{
          "timeline_lifecycle_state_summary" => %{
            "contract" => "timeline_lifecycle_state_summary.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => [
              "candidate_source.candidate_refresh_request.source_timeline_lifecycle_state_summary"
            ],
            "recordable_timeline_ids" => ["timeline:direct_recordable"]
          }
        }
      }
    }

    summary = CandidateRefresh.timeline_lifecycle_state_replay_summary(candidate_source)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_lifecycle_state_summary"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 1

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_timeline_lifecycle_state_summary"
           ]

    assert summary["recordable_timeline_ids"] == ["timeline:direct_recordable"]
    assert summary["branch_local_timeline_lifecycle_state_pressure"]
    assert summary["branch_local_lifecycle_recordable_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_lifecycle_state_candidate_source_report_summary_only"
  end

  test "timeline lifecycle state replay falls back to provenance when branch summary lacks usable family" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "timeline_lifecycle_state_summary" => %{},
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
          "timeline_lifecycle_state_summary" => %{
            "contract" => "timeline_lifecycle_state_summary.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => ["source_timeline_lifecycle_state_summary"],
            "review_timeline_ids" => ["timeline:provenance_review"]
          }
        }
      }
    }

    summary = CandidateRefresh.timeline_lifecycle_state_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.source_report_provenance.timeline_lifecycle_state_summary"

    assert summary["source_report_paths"] == ["source_timeline_lifecycle_state_summary"]
    assert summary["review_timeline_ids"] == ["timeline:provenance_review"]
    assert summary["branch_local_timeline_lifecycle_state_pressure"]
    assert summary["branch_local_lifecycle_review_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_lifecycle_state_source_report_provenance_only"
  end

  test "timeline lifecycle state replay prefers partial branch family over provenance" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "timeline_lifecycle_state_summary" => %{
              "count" => 1,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_timeline_lifecycle_state_summary"
              ],
              "preserved_timeline_ids" => ["timeline:branch_preserved"]
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "timeline_lifecycle_state_summary" => %{
            "contract" => "timeline_lifecycle_state_summary.v1",
            "count" => 9,
            "row_count" => 9,
            "paths" => ["source_timeline_lifecycle_state_summary"],
            "review_required_count" => 9,
            "required_operator_action_counts" => %{"review_activity_approval" => 9}
          }
        }
      }
    }

    summary = CandidateRefresh.timeline_lifecycle_state_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_lifecycle_state_summary"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 0

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_timeline_lifecycle_state_summary"
           ]

    assert summary["preserved_timeline_ids"] == ["timeline:branch_preserved"]
    assert summary["review_required_count"] == 0
    assert summary["required_operator_action_counts"] == %{}
    assert summary["branch_local_timeline_lifecycle_state_pressure"]
    assert summary["branch_local_lifecycle_preservation_pressure"]
    refute summary["branch_local_lifecycle_review_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "timeline_lifecycle_state_candidate_source_report_summary_only"
  end

  test "operator review and import lift timeline lifecycle-state summaries from candidate refresh artifacts" do
    lifecycle_summary = fn prefix, trust_boundary ->
      planned = [
        %{
          id: "#{prefix}_cmd_pending",
          type: :command,
          status: :planned,
          approval_status: :pending,
          starts_at_s: 10.0,
          ends_at_s: 20.0,
          metadata: %{timeline_id: "timeline:#{prefix}:cmd_pending"}
        },
        %{
          id: "#{prefix}_obs_done",
          type: :observe,
          status: :executed,
          approval_status: :approved,
          starts_at_s: 30.0,
          ends_at_s: 40.0,
          metadata: %{timeline_id: "timeline:#{prefix}:obs_done"}
        },
        %{
          id: "#{prefix}_dup_a",
          type: :observe,
          status: :planned,
          starts_at_s: 50.0,
          ends_at_s: 60.0,
          metadata: %{timeline_id: "timeline:#{prefix}:dup"}
        },
        %{
          id: "#{prefix}_dup_b",
          type: :observe,
          status: :planned,
          starts_at_s: 55.0,
          ends_at_s: 65.0,
          metadata: %{timeline_id: "timeline:#{prefix}:dup"}
        }
      ]

      realized = [
        %{
          id: "#{prefix}_cmd_pending",
          type: :command,
          status: :executed,
          approval_status: :approved,
          starts_at_s: 10.0,
          ends_at_s: 20.0,
          metadata: %{timeline_id: "timeline:#{prefix}:cmd_pending"}
        },
        %{
          id: "#{prefix}_obs_done",
          type: :observe,
          status: :executed,
          approval_status: :approved,
          starts_at_s: 30.0,
          ends_at_s: 40.0,
          metadata: %{timeline_id: "timeline:#{prefix}:obs_done"}
        }
      ]

      planned
      |> Timeline.lifecycle_state_summary(realized)
      |> Map.put("provenance", %{"trust_boundary" => trust_boundary})
    end

    direct_summary = lifecycle_summary.("direct_lifecycle", "direct_lifecycle_boundary")
    canonical_summary = lifecycle_summary.("canonical_lifecycle", "canonical_lifecycle_boundary")
    wrapped_summary = lifecycle_summary.("wrapped_lifecycle", "wrapped_lifecycle_boundary")

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:timeline_lifecycle_handoff",
      "source_timeline_lifecycle_state_summary" => [direct_summary],
      "timeline_lifecycle_state_summary" => canonical_summary,
      "source_result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "provenance" => %{"trust_boundary" => "wrapped_result_artifact_boundary"},
        "timeline_lifecycle_state_summary" => Map.delete(wrapped_summary, "provenance")
      }
    }

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)

    lifecycle_rows =
      Enum.filter(review["rows"], &(&1["review_type"] == "timeline_lifecycle_state_review"))

    assert length(lifecycle_rows) == 6

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "timeline_lifecycle_state_review_count" => 6,
             "review_type_counts" => %{"timeline_lifecycle_state_review" => 6}
           } = review

    assert Enum.sort(Enum.map(lifecycle_rows, & &1["source"]) |> Enum.uniq()) == [
             "candidate_refresh.source_result_artifact.timeline_lifecycle_state_summary.review_rows",
             "candidate_refresh.source_timeline_lifecycle_state_summary[0].review_rows",
             "candidate_refresh.timeline_lifecycle_state_summary.review_rows"
           ]

    assert Enum.all?(
             lifecycle_rows,
             &(&1["timeline_lifecycle_state_status"] == "review_required")
           )

    assert Enum.any?(
             lifecycle_rows,
             &match?(
               %{
                 "timeline_id" => "timeline:direct_lifecycle:cmd_pending",
                 "required_operator_action" => "review_activity_approval",
                 "status_transition" => %{"transition_category" => "execution_recorded"},
                 "approval_transition" => %{"transition_category" => "approval_granted"}
               },
               &1
             )
           )

    import_rows =
      Enum.filter(
        import["rows"],
        &(&1["source_review_type"] == "timeline_lifecycle_state_review")
      )

    assert length(import_rows) == 6

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "import_action_counts" => %{"review_timeline_lifecycle_state" => 6},
             "source_review_type_counts" => %{"timeline_lifecycle_state_review" => 6}
           } = import

    assert Enum.all?(
             import_rows,
             &(&1["import_action"] == "review_timeline_lifecycle_state" and
                 &1["source_review_row"]["source_timeline_lifecycle_state"])
           )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end
end
