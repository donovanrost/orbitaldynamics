Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyTimelineLifecycleSourceReportTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.{CandidateRefresh, Schema, Timeline}

  test "strategy carries mission-state timeline activity lifecycle states into branch refresh requests" do
    lifecycle_state = fn prefix ->
      planned = %{
        id: "#{prefix}_cmd_pending",
        type: :command,
        status: :planned,
        approval_status: :pending,
        starts_at_s: 10.0,
        ends_at_s: 20.0,
        metadata: %{timeline_id: "timeline:#{prefix}:cmd_pending"}
      }

      realized = %{
        id: "#{prefix}_cmd_pending",
        type: :command,
        status: :executed,
        approval_status: :approved,
        starts_at_s: 10.0,
        ends_at_s: 20.0,
        metadata: %{timeline_id: "timeline:#{prefix}:cmd_pending"}
      }

      Timeline.activity_lifecycle_state(planned, realized)
    end

    direct_state =
      lifecycle_state.("direct_activity_lifecycle")
      |> Map.put("trust_boundary", "direct_activity_lifecycle_boundary")

    canonical_state = lifecycle_state.("canonical_activity_lifecycle")
    wrapped_state = lifecycle_state.("wrapped_activity_lifecycle")

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_timeline_activity_lifecycle_state", [direct_state])
      |> Map.put("timeline_activity_lifecycle_state", canonical_state)
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "timeline_activity_lifecycle_state" => wrapped_state,
        "provenance" => %{"trust_boundary" => "wrapped_activity_lifecycle_boundary"}
      })

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        branches: [
          %{id: "baseline"},
          %{
            id: "urgent",
            events: [%{type: "urgent_target", target_id: "target_a", priority: 12.0}]
          }
        ],
        current_epoch_s: 0.0
      )

    urgent = branch(artifact, "urgent")

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             candidate_source = urgent["assumptions"]["candidate_source"]

    source_report_input_paths = candidate_source["source_report_input_paths"]

    assert "mission_state.source_timeline_activity_lifecycle_state" in source_report_input_paths

    assert "mission_state.timeline_activity_lifecycle_state" in source_report_input_paths

    assert "mission_state.source_result_artifact.timeline_activity_lifecycle_state" in source_report_input_paths

    assert "mission_state.source_timeline_activity_lifecycle_state" in candidate_source[
             "candidate_refresh_request_source_report_input_paths"
           ]

    assert "mission_state.timeline_activity_lifecycle_state" in candidate_source[
             "candidate_refresh_request_source_report_input_paths"
           ]

    assert "mission_state.source_result_artifact.timeline_activity_lifecycle_state" in candidate_source[
             "candidate_refresh_request_source_report_input_paths"
           ]

    assert %{
             "source_report_count" => 3,
             "source_report_row_count" => 3,
             "source_report_timeline_activity_lifecycle_state_row_count" => 3,
             "source_report_timeline_activity_lifecycle_state_review_required_count" => 3,
             "source_report_timeline_activity_lifecycle_state_transition_decision_counts" => %{
               "review" => 3
             },
             "source_report_timeline_activity_lifecycle_state_status_transition_decision_counts" =>
               %{
                 "record" => 3
               },
             "source_report_timeline_activity_lifecycle_state_approval_transition_decision_counts" =>
               %{
                 "review" => 3
               },
             "source_report_timeline_activity_lifecycle_state_required_operator_action_counts" =>
               %{
                 "record_timeline_change" => 3,
                 "review_activity_approval" => 3
               },
             "source_report_timeline_activity_lifecycle_state_import_action_counts" => %{
               "review_timeline_diff" => 3
             }
           } = candidate_source["candidate_refresh_request_source_report_summary"]

    assert %{
             "source" =>
               "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_activity_lifecycle_state",
             "contract" => "timeline_activity_lifecycle_state.v1",
             "source_report_count" => 3,
             "source_report_row_count" => 3,
             "source_report_paths" => replay_source_paths,
             "branch_local_timeline_activity_lifecycle_state_pressure" => true,
             "branch_local_activity_lifecycle_review_pressure" => true,
             "branch_local_activity_lifecycle_action_pressure" => true,
             "branch_local_activity_lifecycle_routing_pressure" => true,
             "assumptions" => %{
               "replay_scope" =>
                 "timeline_activity_lifecycle_state_candidate_source_report_summary_only",
               "activity_lifecycle_application" => "not_performed_by_summary",
               "timeline_mutation" => "not_performed_by_summary"
             }
           } = CandidateRefresh.timeline_activity_lifecycle_state_replay_summary(candidate_source)

    for source_path <- [
          "mission_state.source_timeline_activity_lifecycle_state",
          "mission_state.timeline_activity_lifecycle_state",
          "mission_state.source_result_artifact.timeline_activity_lifecycle_state"
        ] do
      assert source_path in replay_source_paths
    end

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy carries mission-state timeline lifecycle-state summaries into branch refresh requests" do
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

    lifecycle_summary =
      planned
      |> Timeline.lifecycle_state_summary(realized)
      |> Map.put("provenance", %{"trust_boundary" => "branch_lifecycle_summary"})

    canonical_lifecycle_summary =
      planned
      |> Timeline.lifecycle_state_summary(realized)
      |> Map.delete("provenance")

    assert {:ok, %{"schema_contract" => "timeline_lifecycle_state_summary.v1"}} =
             Schema.validate_artifact(lifecycle_summary)

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_timeline_lifecycle_state_summary", lifecycle_summary)
      |> Map.put("timeline_lifecycle_state_summary", canonical_lifecycle_summary)
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "timeline_lifecycle_state_summary" => Map.delete(lifecycle_summary, "provenance"),
        "provenance" => %{"trust_boundary" => "wrapped_lifecycle_summary_boundary"}
      })

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        branches: [
          %{id: "baseline"},
          %{
            id: "urgent",
            events: [%{type: "urgent_target", target_id: "target_a", priority: 12.0}]
          }
        ],
        current_epoch_s: 0.0
      )

    urgent = branch(artifact, "urgent")

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             candidate_source = urgent["assumptions"]["candidate_source"]

    source_report_input_paths = candidate_source["source_report_input_paths"]

    assert "mission_state.source_timeline_lifecycle_state_summary" in source_report_input_paths

    assert "mission_state.timeline_lifecycle_state_summary" in source_report_input_paths

    assert "mission_state.source_result_artifact.timeline_lifecycle_state_summary" in source_report_input_paths

    assert "mission_state.source_timeline_lifecycle_state_summary" in candidate_source[
             "candidate_refresh_request_source_report_input_paths"
           ]

    assert "mission_state.timeline_lifecycle_state_summary" in candidate_source[
             "candidate_refresh_request_source_report_input_paths"
           ]

    assert "mission_state.source_result_artifact.timeline_lifecycle_state_summary" in candidate_source[
             "candidate_refresh_request_source_report_input_paths"
           ]

    assert %{
             "source_report_count" => 3,
             "source_report_row_count" => 12,
             "source_report_timeline_lifecycle_state_row_count" => 12,
             "source_report_timeline_lifecycle_state_planned_activity_count" => 15,
             "source_report_timeline_lifecycle_state_realized_activity_count" => 6,
             "source_report_timeline_lifecycle_state_preserved_count" => 3,
             "source_report_timeline_lifecycle_state_review_required_count" => 9,
             "source_report_timeline_lifecycle_state_duplicate_timeline_identity_count" => 3,
             "source_report_timeline_lifecycle_state_invalid_activity_input_count" => 3,
             "source_report_timeline_lifecycle_state_invalid_activity_input_ids" => [
               "timeline_row:5:bad_missing_type"
             ],
             "source_report_timeline_lifecycle_state_transition_decision_counts" => %{
               "none" => 3,
               "review" => 9
             },
             "source_report_timeline_lifecycle_state_required_operator_action_counts" => %{
               "none" => 3,
               "review_activity_approval" => 3,
               "review_duplicate_timeline_identity" => 3,
               "review_invalid_activity_input" => 3
             },
             "source_report_timeline_lifecycle_state_import_action_counts" => %{
               "record_preserved_activity" => 3,
               "review_timeline_diff" => 9
             }
           } = candidate_source["candidate_refresh_request_source_report_summary"]

    assert %{
             "source" =>
               "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_lifecycle_state_summary",
             "contract" => "timeline_lifecycle_state_summary.v1",
             "source_report_count" => 3,
             "source_report_row_count" => 12,
             "source_report_paths" => replay_source_paths,
             "planned_activity_count" => 15,
             "realized_activity_count" => 6,
             "recordable_count" => 0,
             "preserved_count" => 3,
             "review_required_count" => 9,
             "duplicate_timeline_identity_count" => 3,
             "invalid_activity_input_count" => 3,
             "invalid_activity_input_ids" => ["timeline_row:5:bad_missing_type"],
             "transition_decision_counts" => %{"none" => 3, "review" => 9},
             "required_operator_action_counts" => %{
               "none" => 3,
               "review_activity_approval" => 3,
               "review_duplicate_timeline_identity" => 3,
               "review_invalid_activity_input" => 3
             },
             "import_action_counts" => %{
               "record_preserved_activity" => 3,
               "review_timeline_diff" => 9
             },
             "preserved_timeline_ids" => ["timeline:obs_done"],
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
             "trust_boundary_status" => "declared",
             "trust_boundaries" => [
               "branch_lifecycle_summary",
               "wrapped_lifecycle_summary_boundary"
             ],
             "branch_local_timeline_lifecycle_state_pressure" => true,
             "branch_local_lifecycle_review_pressure" => true,
             "branch_local_lifecycle_recordable_pressure" => false,
             "branch_local_lifecycle_preservation_pressure" => true,
             "assumptions" => %{
               "replay_scope" => "timeline_lifecycle_state_candidate_source_report_summary_only",
               "timeline_lifecycle_application" => "not_performed_by_summary",
               "timeline_mutation" => "not_performed_by_summary"
             }
           } = CandidateRefresh.timeline_lifecycle_state_replay_summary(candidate_source)

    for source_path <- [
          "mission_state.source_timeline_lifecycle_state_summary",
          "mission_state.timeline_lifecycle_state_summary",
          "mission_state.source_result_artifact.timeline_lifecycle_state_summary"
        ] do
      assert source_path in replay_source_paths
    end

    assert_timeline_lifecycle_pressure_score_terms(
      urgent,
      artifact,
      "timeline_lifecycle_state_review"
    )

    urgent_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "urgent"))

    assert "timeline_lifecycle_state_review" in urgent_row["risk_types"]

    assert urgent_row["branch_timeline_lifecycle_state_review_timeline_ids"] == [
             "timeline:cmd_pending",
             "timeline:dup",
             "timeline:invalid_activity_input:bad_missing_type"
           ]

    assert urgent_row["branch_timeline_lifecycle_state_review_activity_ids"] == [
             "cmd_pending",
             "dup_a",
             "dup_b",
             "timeline_row:5:bad_missing_type"
           ]

    assert urgent_row["branch_timeline_lifecycle_state_invalid_activity_input_ids"] == [
             "timeline_row:5:bad_missing_type"
           ]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy challenge scores timeline lifecycle replay from rows when top-level fields are stale" do
    planned = [
      %{
        id: :stale_strategy_cmd_pending,
        type: :command,
        status: :planned,
        approval_status: :pending,
        starts_at_s: 10.0,
        ends_at_s: 20.0,
        metadata: %{timeline_id: :"timeline:stale_strategy:cmd_pending"}
      },
      %{
        id: :stale_strategy_dup_a,
        type: :observe,
        status: :planned,
        starts_at_s: 30.0,
        ends_at_s: 40.0,
        metadata: %{timeline_id: :"timeline:stale_strategy:dup"}
      },
      %{
        id: :stale_strategy_dup_b,
        type: :observe,
        status: :planned,
        starts_at_s: 35.0,
        ends_at_s: 45.0,
        metadata: %{timeline_id: :"timeline:stale_strategy:dup"}
      },
      %{id: :stale_strategy_bad_missing_type, status: :planned}
    ]

    realized = [
      %{
        id: :stale_strategy_cmd_pending,
        type: :command,
        status: :executed,
        approval_status: :approved,
        starts_at_s: 10.0,
        ends_at_s: 20.0,
        metadata: %{timeline_id: :"timeline:stale_strategy:cmd_pending"}
      }
    ]

    stale_summary =
      planned
      |> Timeline.lifecycle_state_summary(realized)
      |> Map.put("provenance", %{"trust_boundary" => "stale_strategy_lifecycle_summary"})
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

    artifact =
      strategy(base_plan(%{}),
        mission_state:
          mission_state_with_refresh_inputs()
          |> Map.put(:source_timeline_lifecycle_state_summary, stale_summary),
        branches: [
          %{id: "baseline"},
          %{
            id: "urgent",
            events: [%{type: "urgent_target", target_id: "target_a", priority: 12.0}]
          }
        ],
        current_epoch_s: 0.0
      )

    urgent = branch(artifact, "urgent")

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             candidate_source = urgent["assumptions"]["candidate_source"]

    assert %{
             "source_report_row_count" => 3,
             "review_required_count" => 3,
             "duplicate_timeline_identity_count" => 1,
             "invalid_activity_input_count" => 1,
             "transition_decision_counts" => %{"review" => 3},
             "required_operator_action_counts" => %{
               "review_activity_approval" => 1,
               "review_duplicate_timeline_identity" => 1,
               "review_invalid_activity_input" => 1
             },
             "import_action_counts" => %{"review_timeline_diff" => 3},
             "review_timeline_ids" => [
               "timeline:invalid_activity_input:stale_strategy_bad_missing_type",
               "timeline:stale_strategy:cmd_pending",
               "timeline:stale_strategy:dup"
             ],
             "review_activity_ids" => [
               "stale_strategy_cmd_pending",
               "stale_strategy_dup_a",
               "stale_strategy_dup_b",
               "timeline_row:4:stale_strategy_bad_missing_type"
             ],
             "branch_local_timeline_lifecycle_state_pressure" => true,
             "branch_local_lifecycle_review_pressure" => true
           } = CandidateRefresh.timeline_lifecycle_state_replay_summary(candidate_source)

    assert Enum.any?(
             urgent["risk_indicators"],
             &(&1["type"] == "timeline_lifecycle_state_review" and
                 &1["feedback_source"] ==
                   "candidate_source.timeline_lifecycle_state_replay_summary" and
                 &1["source_report_count"] == 1 and
                 &1["source_report_row_count"] == 3 and
                 &1["source_report_paths"] == [
                   "mission_state.source_timeline_lifecycle_state_summary"
                 ] and
                 &1["review_required_count"] == 3 and
                 &1["duplicate_timeline_identity_count"] == 1 and
                 &1["invalid_activity_input_count"] == 1 and
                 &1["review_timeline_ids"] == [
                   "timeline:invalid_activity_input:stale_strategy_bad_missing_type",
                   "timeline:stale_strategy:cmd_pending",
                   "timeline:stale_strategy:dup"
                 ] and
                 &1["review_activity_ids"] == [
                   "stale_strategy_cmd_pending",
                   "stale_strategy_dup_a",
                   "stale_strategy_dup_b",
                   "timeline_row:4:stale_strategy_bad_missing_type"
                 ])
           )

    assert_timeline_lifecycle_pressure_score_terms(
      urgent,
      artifact,
      "timeline_lifecycle_state_review"
    )

    urgent_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "urgent"))

    assert "timeline_lifecycle_state_review" in urgent_row["risk_types"]

    assert urgent_row["branch_timeline_lifecycle_state_review_timeline_ids"] == [
             "timeline:invalid_activity_input:stale_strategy_bad_missing_type",
             "timeline:stale_strategy:cmd_pending",
             "timeline:stale_strategy:dup"
           ]

    assert urgent_row["branch_timeline_lifecycle_state_review_activity_ids"] == [
             "stale_strategy_cmd_pending",
             "stale_strategy_dup_a",
             "stale_strategy_dup_b",
             "timeline_row:4:stale_strategy_bad_missing_type"
           ]

    assert urgent_row["branch_timeline_lifecycle_state_invalid_activity_input_ids"] == [
             "timeline_row:4:stale_strategy_bad_missing_type"
           ]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch pressure from timeline lifecycle state summaries" do
    lifecycle_summary = fn prefix, trust_boundary ->
      planned = [
        %{
          id: :"#{prefix}_cmd_pending",
          type: :command,
          status: :planned,
          approval_status: :pending,
          starts_at_s: 10.0,
          ends_at_s: 20.0,
          metadata: %{timeline_id: "timeline:#{prefix}:cmd_pending"}
        },
        %{
          id: :"#{prefix}_dup_a",
          type: :observe,
          status: :planned,
          starts_at_s: 30.0,
          ends_at_s: 40.0,
          metadata: %{timeline_id: "timeline:#{prefix}:dup"}
        },
        %{
          id: :"#{prefix}_dup_b",
          type: :observe,
          status: :planned,
          starts_at_s: 35.0,
          ends_at_s: 45.0,
          metadata: %{timeline_id: "timeline:#{prefix}:dup"}
        },
        %{
          id: :"#{prefix}_bad_missing_type",
          status: :planned,
          starts_at_s: 50.0,
          ends_at_s: 60.0,
          metadata: %{timeline_id: "timeline:#{prefix}:bad_missing_type"}
        }
      ]

      realized = [
        %{
          id: :"#{prefix}_cmd_pending",
          type: :command,
          status: :executed,
          approval_status: :approved,
          starts_at_s: 10.0,
          ends_at_s: 20.0,
          metadata: %{timeline_id: "timeline:#{prefix}:cmd_pending"}
        }
      ]

      planned
      |> Timeline.lifecycle_state_summary(realized, source: "mission.#{prefix}.lifecycle")
      |> Map.put("provenance", %{"trust_boundary" => trust_boundary})
    end

    direct_summary = lifecycle_summary.("direct_lifecycle", "direct_lifecycle_boundary")
    canonical_summary = lifecycle_summary.("canonical_lifecycle", "canonical_lifecycle_boundary")

    wrapped_summary =
      lifecycle_summary.("wrapped_lifecycle", "wrapped_lifecycle_boundary")
      |> Map.delete("provenance")

    assert {:ok, %{"schema_contract" => "timeline_lifecycle_state_summary.v1"}} =
             Schema.validate_artifact(direct_summary)

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_timeline_lifecycle_state_summary", direct_summary)
      |> Map.put("timeline_lifecycle_state_summary", canonical_summary)
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "timeline_lifecycle_state_summary" => wrapped_summary,
        "provenance" => %{"trust_boundary" => "wrapped_lifecycle_artifact_boundary"}
      })

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    direct_branch =
      branch(
        artifact,
        "derived_timeline_lifecycle_state_pressure_mission.direct_lifecycle.lifecycle"
      )

    assert %{
             "type" => "timeline_lifecycle_state_pressure",
             "timeline_lifecycle_state_status" => "review_required",
             "review_required_count" => 3,
             "duplicate_timeline_identity_count" => 1,
             "invalid_activity_input_count" => 1,
             "review_timeline_ids" => [
               "timeline:direct_lifecycle:cmd_pending",
               "timeline:direct_lifecycle:dup",
               "timeline:invalid_activity_input:direct_lifecycle_bad_missing_type"
             ],
             "review_activity_ids" => [
               "direct_lifecycle_cmd_pending",
               "direct_lifecycle_dup_a",
               "direct_lifecycle_dup_b",
               "timeline_row:4:direct_lifecycle_bad_missing_type"
             ],
             "invalid_activity_input_ids" => [
               "timeline_row:4:direct_lifecycle_bad_missing_type"
             ],
             "required_operator_action_counts" => %{
               "review_activity_approval" => 1,
               "review_duplicate_timeline_identity" => 1,
               "review_invalid_activity_input" => 1
             },
             "import_action_counts" => %{"review_timeline_diff" => 3},
             "feedback_source" => "mission_state.source_timeline_lifecycle_state_summary",
             "feedback_scope" => "timeline_lifecycle_state",
             "trust_boundary" => "direct_lifecycle_boundary",
             "requires_operator_review" => true,
             "derivation_reasons" => ["timeline_lifecycle_state_summary_pressure"]
           } = List.first(direct_branch["events"])

    assert Enum.any?(
             direct_branch["risk_indicators"],
             &(&1["type"] == "timeline_lifecycle_state_review" and
                 &1["invalid_activity_input_ids"] == [
                   "timeline_row:4:direct_lifecycle_bad_missing_type"
                 ] and
                 &1["feedback_source"] ==
                   "mission_state.source_timeline_lifecycle_state_summary")
           )

    assert_timeline_lifecycle_pressure_score_terms(
      direct_branch,
      artifact,
      "timeline_lifecycle_state_review"
    )

    direct_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(
        &(&1["branch_id"] ==
            "derived_timeline_lifecycle_state_pressure_mission.direct_lifecycle.lifecycle")
      )

    assert direct_row["branch_timeline_lifecycle_state_statuses"] == ["review_required"]

    assert direct_row["branch_timeline_lifecycle_state_review_timeline_ids"] == [
             "timeline:direct_lifecycle:cmd_pending",
             "timeline:direct_lifecycle:dup",
             "timeline:invalid_activity_input:direct_lifecycle_bad_missing_type"
           ]

    assert direct_row["branch_timeline_lifecycle_state_invalid_activity_input_ids"] == [
             "timeline_row:4:direct_lifecycle_bad_missing_type"
           ]

    assert direct_row["branch_timeline_lifecycle_state_required_operator_actions"] == [
             "review_activity_approval",
             "review_duplicate_timeline_identity",
             "review_invalid_activity_input"
           ]

    assert direct_row["branch_timeline_lifecycle_state_import_actions"] == [
             "review_timeline_diff"
           ]

    wrapped_branch =
      branch(
        artifact,
        "derived_timeline_lifecycle_state_pressure_mission.wrapped_lifecycle.lifecycle"
      )

    assert %{
             "feedback_source" =>
               "mission_state.source_result_artifact.timeline_lifecycle_state_summary",
             "trust_boundary" => "wrapped_lifecycle_artifact_boundary"
           } = List.first(wrapped_branch["events"])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives lifecycle pressure from row-local stale aggregate evidence" do
    planned = [
      %{
        id: :stale_lifecycle_cmd_pending,
        type: :command,
        status: :planned,
        approval_status: :pending,
        starts_at_s: 10.0,
        ends_at_s: 20.0,
        metadata: %{timeline_id: "timeline:stale_lifecycle:cmd_pending"}
      },
      %{
        id: :stale_lifecycle_dup_a,
        type: :observe,
        status: :planned,
        metadata: %{timeline_id: "timeline:stale_lifecycle:dup"}
      },
      %{
        id: :stale_lifecycle_dup_b,
        type: :observe,
        status: :planned,
        metadata: %{timeline_id: "timeline:stale_lifecycle:dup"}
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
        metadata: %{timeline_id: "timeline:stale_lifecycle:cmd_pending"}
      }
    ]

    stale_summary =
      planned
      |> Timeline.lifecycle_state_summary(realized, source: "mission.stale_lifecycle.lifecycle")
      |> Map.put("provenance", %{"trust_boundary" => "stale_lifecycle_boundary"})
      |> Map.merge(%{
        "recordable_count" => 0,
        "preserved_count" => 0,
        "review_required_count" => 0,
        "duplicate_timeline_identity_count" => 0,
        "invalid_activity_input_count" => 0,
        "transition_decision_counts" => %{},
        "required_operator_action_counts" => %{},
        "operator_action_reason_counts" => %{},
        "import_action_counts" => %{},
        "planned_status_category_counts" => %{},
        "realized_status_category_counts" => %{},
        "planned_approval_category_counts" => %{},
        "realized_approval_category_counts" => %{},
        "status_transition_category_counts" => %{},
        "approval_transition_category_counts" => %{},
        "review_timeline_ids" => [],
        "review_activity_ids" => [],
        "invalid_activity_input_ids" => [],
        "review_timeline_ids_by_required_operator_action" => %{},
        "review_timeline_ids_by_operator_action_reason" => %{},
        "review_timeline_ids_by_status_transition_category" => %{},
        "review_timeline_ids_by_approval_transition_category" => %{},
        "review_rows" => []
      })

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_timeline_lifecycle_state_summary", stale_summary)

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    branch =
      branch(
        artifact,
        "derived_timeline_lifecycle_state_pressure_mission.stale_lifecycle.lifecycle"
      )

    assert %{
             "timeline_lifecycle_state_status" => "review_required",
             "review_required_count" => 3,
             "duplicate_timeline_identity_count" => 1,
             "invalid_activity_input_count" => 1,
             "review_timeline_ids" => [
               "timeline:invalid_activity_input:stale_lifecycle_bad_missing_type",
               "timeline:stale_lifecycle:cmd_pending",
               "timeline:stale_lifecycle:dup"
             ],
             "invalid_activity_input_ids" => [
               "timeline_row:4:stale_lifecycle_bad_missing_type"
             ],
             "feedback_source" => "mission_state.source_timeline_lifecycle_state_summary",
             "trust_boundary" => "stale_lifecycle_boundary"
           } = List.first(branch["events"])

    assert Enum.any?(
             branch["risk_indicators"],
             &(&1["type"] == "timeline_lifecycle_state_review" and
                 &1["invalid_activity_input_ids"] == [
                   "timeline_row:4:stale_lifecycle_bad_missing_type"
                 ])
           )

    assert_timeline_lifecycle_pressure_score_terms(
      branch,
      artifact,
      "timeline_lifecycle_state_review"
    )

    row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(
        &(&1["branch_id"] ==
            "derived_timeline_lifecycle_state_pressure_mission.stale_lifecycle.lifecycle")
      )

    assert row["branch_timeline_lifecycle_state_statuses"] == ["review_required"]

    assert row["branch_timeline_lifecycle_state_invalid_activity_input_ids"] == [
             "timeline_row:4:stale_lifecycle_bad_missing_type"
           ]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch pressure from timeline activity lifecycle states" do
    lifecycle_state = fn prefix, trust_boundary ->
      Timeline.activity_lifecycle_state(
        %{
          id: :"#{prefix}_cmd_pending",
          type: :command,
          status: :planned,
          approval_status: :pending,
          starts_at_s: 10.0,
          ends_at_s: 20.0,
          metadata: %{timeline_id: "timeline:#{prefix}:cmd_pending"}
        },
        %{
          id: :"#{prefix}_cmd_pending",
          type: :command,
          status: :executed,
          approval_status: :approved,
          starts_at_s: 10.0,
          ends_at_s: 20.0,
          metadata: %{timeline_id: "timeline:#{prefix}:cmd_pending"}
        }
      )
      |> Map.put("trust_boundary", trust_boundary)
    end

    direct_state =
      lifecycle_state.("direct_activity_lifecycle_pressure", "direct_activity_lifecycle_boundary")

    canonical_state =
      lifecycle_state.(
        "canonical_activity_lifecycle_pressure",
        "canonical_activity_lifecycle_boundary"
      )

    wrapped_state =
      lifecycle_state.(
        "wrapped_activity_lifecycle_pressure",
        "wrapped_activity_lifecycle_boundary"
      )
      |> Map.delete("trust_boundary")

    assert {:ok, %{"schema_contract" => "timeline_activity_lifecycle_state.v1"}} =
             Schema.validate_artifact(direct_state)

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_timeline_activity_lifecycle_state", direct_state)
      |> Map.put("timeline_activity_lifecycle_state", canonical_state)
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "timeline_activity_lifecycle_state" => wrapped_state,
        "provenance" => %{"trust_boundary" => "wrapped_activity_lifecycle_artifact_boundary"}
      })

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    direct_branch =
      branch(
        artifact,
        "derived_timeline_activity_lifecycle_state_pressure_direct_activity_lifecycle_pressure_cmd_pending"
      )

    assert %{
             "type" => "timeline_activity_lifecycle_state_pressure",
             "activity_id" => "direct_activity_lifecycle_pressure_cmd_pending",
             "timeline_id" => "timeline:direct_activity_lifecycle_pressure:cmd_pending",
             "transition_decision" => "review",
             "status_transition_decision" => "record",
             "approval_transition_decision" => "review",
             "required_operator_action" => "review_activity_approval",
             "required_operator_actions" => [
               "record_timeline_change",
               "review_activity_approval"
             ],
             "operator_action_reasons" => [
               "activity_execution_recorded",
               "approval_grant_requires_operator_authority"
             ],
             "import_action" => "review_timeline_diff",
             "feedback_source" => "mission_state.source_timeline_activity_lifecycle_state",
             "feedback_scope" => "timeline_activity_lifecycle_state",
             "trust_boundary" => "direct_activity_lifecycle_boundary",
             "requires_operator_review" => true,
             "derivation_reasons" => ["timeline_activity_lifecycle_state_pressure"]
           } = List.first(direct_branch["events"])

    assert Enum.any?(
             direct_branch["risk_indicators"],
             &(&1["type"] == "timeline_activity_lifecycle_state_review" and
                 &1["activity_id"] ==
                   "direct_activity_lifecycle_pressure_cmd_pending" and
                 &1["feedback_source"] ==
                   "mission_state.source_timeline_activity_lifecycle_state")
           )

    assert_timeline_lifecycle_pressure_score_terms(
      direct_branch,
      artifact,
      "timeline_activity_lifecycle_state_review"
    )

    direct_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(
        &(&1["branch_id"] ==
            "derived_timeline_activity_lifecycle_state_pressure_direct_activity_lifecycle_pressure_cmd_pending")
      )

    assert direct_row["branch_timeline_activity_lifecycle_state_activity_ids"] == [
             "direct_activity_lifecycle_pressure_cmd_pending"
           ]

    assert direct_row["branch_timeline_activity_lifecycle_state_timeline_ids"] == [
             "timeline:direct_activity_lifecycle_pressure:cmd_pending"
           ]

    assert direct_row["branch_timeline_activity_lifecycle_state_transition_decisions"] == [
             "review"
           ]

    assert direct_row["branch_timeline_activity_lifecycle_state_required_operator_actions"] == [
             "record_timeline_change",
             "review_activity_approval"
           ]

    assert direct_row["branch_timeline_activity_lifecycle_state_import_actions"] == [
             "review_timeline_diff"
           ]

    wrapped_branch =
      branch(
        artifact,
        "derived_timeline_activity_lifecycle_state_pressure_wrapped_activity_lifecycle_pressure_cmd_pending"
      )

    assert %{
             "feedback_source" =>
               "mission_state.source_result_artifact.timeline_activity_lifecycle_state",
             "trust_boundary" => "wrapped_activity_lifecycle_artifact_boundary"
           } = List.first(wrapped_branch["events"])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  defp assert_timeline_lifecycle_pressure_score_terms(branch, artifact, risk_type) do
    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])
    pressure_term = timeline_lifecycle_pressure_term(risk_type)

    timeline_lifecycle_pressure_count =
      Enum.count(
        branch["risk_indicators"],
        &(&1["type"] == risk_type)
      )

    assert timeline_lifecycle_pressure_count == 1

    assert branch["score_terms"][pressure_term] ==
             -timeline_lifecycle_pressure_count * risk_weight

    if pressure_term == "timeline_activity_state_pressure_penalty" do
      assert branch["score_terms"]["timeline_lifecycle_pressure_penalty"] == 0.0
    end

    assert branch["score_terms"]["timeline_pressure_penalty"] == 0.0

    assert branch["score_terms"]["risk_penalty"] ==
             -(length(branch["risk_indicators"]) - timeline_lifecycle_pressure_count) *
               risk_weight

    assert pressure_term in artifact["score_term_report"]["score_term_keys"]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == branch["branch_id"] and
                 &1["term_key"] == pressure_term and
                 &1["value"] < 0.0)
           )
  end

  defp timeline_lifecycle_pressure_term("timeline_activity_lifecycle_state_review"),
    do: "timeline_activity_state_pressure_penalty"

  defp timeline_lifecycle_pressure_term(_risk_type),
    do: "timeline_lifecycle_pressure_penalty"
end
