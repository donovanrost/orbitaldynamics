Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyTimelineDiffSourceReportTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.{CandidateRefresh, Schema, Timeline}

  test "strategy carries mission-state timeline-diff reports into branch refresh requests" do
    timeline_diff_report =
      fn prefix, diff_status, required_operator_action, row_overrides ->
        row =
          %{
            "id" => "timeline_diff:timeline:#{prefix}_activity",
            "rank" => 1,
            "timeline_id" => "timeline:#{prefix}_activity",
            "diff_status" => diff_status,
            "source_activity_id" => "#{prefix}_source",
            "source_activity_type" => Map.get(row_overrides, "source_activity_type", "observe"),
            "source_target_id" => "#{prefix}_target",
            "source_status" => "planned",
            "required_operator_action" => required_operator_action,
            "trust_boundary" => "#{prefix}_timeline_diff_row_boundary"
          }
          |> Map.merge(row_overrides)

        %{
          "schema_contract" => "timeline_diff_report.v1",
          "model" => "timeline_identity_activity_diff",
          "source" => "campaign_planner_test.#{prefix}.timeline_diff_report",
          "rows" => [row],
          "provenance" => %{
            "trust_boundary" => "#{prefix}_timeline_diff_report_boundary"
          }
        }
      end

    direct_report =
      timeline_diff_report.("direct", "removed", "review_removed_activity", %{
        "source_activity_type" => "observe"
      })

    canonical_report =
      timeline_diff_report.("canonical", "added", "record_timeline_change", %{
        "replacement_activity_id" => "canonical_replacement",
        "replacement_activity_type" => "observe"
      })

    source_wrapped_report =
      timeline_diff_report.("source_wrapped", "changed", "review_timeline_change", %{
        "source_activity_type" => "command",
        "replacement_activity_id" => "source_wrapped_replacement",
        "replacement_activity_type" => "command",
        "command_success_factor" => 0.0
      })

    result_wrapped_report =
      timeline_diff_report.(
        "result_wrapped",
        "duplicate",
        "review_duplicate_timeline_identity",
        %{
          "duplicate_timeline_identity_scope" => "source"
        }
      )

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_timeline_diff_report", direct_report)
      |> Map.put("timeline_diff_report", canonical_report)
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "timeline_diff_report" => Map.delete(source_wrapped_report, "provenance"),
        "provenance" => %{"trust_boundary" => "source_wrapped_timeline_diff_boundary"}
      })
      |> Map.put(:result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "source_timeline_diff_report" => Map.delete(result_wrapped_report, "provenance"),
        "provenance" => %{"trust_boundary" => "result_wrapped_timeline_diff_boundary"}
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

    for source_path <- [
          "mission_state.source_timeline_diff_report",
          "mission_state.timeline_diff_report",
          "mission_state.source_result_artifact.timeline_diff_report",
          "mission_state.result_artifact.source_timeline_diff_report"
        ] do
      assert source_path in candidate_source["source_report_input_paths"]

      assert source_path in candidate_source[
               "candidate_refresh_request_source_report_input_paths"
             ]
    end

    assert %{
             "source_report_count" => 4,
             "source_report_row_count" => 4,
             "source_report_timeline_diff_duplicate_timeline_identity_count" => 1,
             "source_report_timeline_diff_duplicate_source_timeline_identity_count" => 1,
             "source_report_timeline_diff_removed_observation_count" => 1,
             "source_report_timeline_diff_changed_command_feedback_count" => 1,
             "source_report_timeline_diff_status_counts" => %{
               "added" => 1,
               "changed" => 1,
               "duplicate" => 1,
               "removed" => 1
             },
             "source_report_timeline_diff_required_operator_action_counts" => %{
               "record_timeline_change" => 1,
               "review_duplicate_timeline_identity" => 1,
               "review_removed_activity" => 1,
               "review_timeline_change" => 1
             },
             "source_report_timeline_diff_source_activity_id_counts" => %{
               "canonical_source" => 1,
               "direct_source" => 1,
               "result_wrapped_source" => 1,
               "source_wrapped_source" => 1
             },
             "source_report_timeline_diff_replacement_activity_id_counts" => %{
               "canonical_replacement" => 1,
               "source_wrapped_replacement" => 1
             }
           } = candidate_source["candidate_refresh_request_source_report_summary"]

    assert %{
             "source" =>
               "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_diff_report",
             "contract" => "timeline_diff_report.v1",
             "source_report_count" => 4,
             "source_report_row_count" => 4,
             "source_report_paths" => replay_source_paths,
             "duplicate_timeline_identity_count" => 1,
             "duplicate_source_timeline_identity_count" => 1,
             "removed_observation_count" => 1,
             "changed_command_feedback_count" => 1,
             "diff_status_counts" => %{
               "added" => 1,
               "changed" => 1,
               "duplicate" => 1,
               "removed" => 1
             },
             "required_operator_action_counts" => %{
               "record_timeline_change" => 1,
               "review_duplicate_timeline_identity" => 1,
               "review_removed_activity" => 1,
               "review_timeline_change" => 1
             },
             "duplicate_timeline_identity_scope_counts" => %{"source" => 1},
             "source_activity_id_counts" => %{
               "canonical_source" => 1,
               "direct_source" => 1,
               "result_wrapped_source" => 1,
               "source_wrapped_source" => 1
             },
             "replacement_activity_id_counts" => %{
               "canonical_replacement" => 1,
               "source_wrapped_replacement" => 1
             },
             "trust_boundary_status" => "declared",
             "trust_boundaries" => replay_trust_boundaries,
             "branch_local_timeline_diff_pressure" => true,
             "branch_local_duplicate_identity_pressure" => true,
             "branch_local_removed_activity_pressure" => true,
             "branch_local_changed_activity_pressure" => true,
             "branch_local_activity_routing_pressure" => true,
             "branch_local_operator_review_pressure" => true,
             "assumptions" => %{
               "replay_scope" => "timeline_diff_candidate_source_report_summary_only",
               "timeline_mutation" => "not_performed_by_summary",
               "candidate_selection" => "not_performed_by_summary",
               "cadence_write" => "not_performed_by_summary"
             }
           } = CandidateRefresh.timeline_diff_replay_summary(candidate_source)

    assert Enum.sort(replay_source_paths) == [
             "mission_state.result_artifact.source_timeline_diff_report",
             "mission_state.source_result_artifact.timeline_diff_report",
             "mission_state.source_timeline_diff_report",
             "mission_state.timeline_diff_report"
           ]

    assert Enum.sort(replay_trust_boundaries) == [
             "canonical_timeline_diff_report_boundary",
             "canonical_timeline_diff_row_boundary",
             "direct_timeline_diff_report_boundary",
             "direct_timeline_diff_row_boundary",
             "result_wrapped_timeline_diff_boundary",
             "result_wrapped_timeline_diff_row_boundary",
             "source_wrapped_timeline_diff_boundary",
             "source_wrapped_timeline_diff_row_boundary"
           ]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy carries mission-state timeline-diff summaries into branch refresh requests" do
    source = [
      %{
        id: :dl_removed,
        type: :downlink,
        status: :planned,
        starts_at_s: 10.0,
        ends_at_s: 20.0,
        metadata: %{timeline_id: :"timeline:dl_removed"}
      },
      %{
        id: :cmd_changed,
        type: :command,
        status: :planned,
        approval_status: :pending,
        starts_at_s: 30.0,
        ends_at_s: 40.0,
        metadata: %{timeline_id: :"timeline:cmd_changed"}
      }
    ]

    replacement = [
      %{
        id: :cmd_changed,
        type: :command,
        status: :executed,
        approval_status: :approved,
        starts_at_s: 35.0,
        ends_at_s: 45.0,
        metadata: %{timeline_id: :"timeline:cmd_changed"}
      },
      %{
        id: :obs_added,
        type: :observe,
        status: :planned,
        starts_at_s: 50.0,
        ends_at_s: 60.0,
        metadata: %{timeline_id: :"timeline:obs_added"}
      }
    ]

    base_diff_summary =
      source
      |> Timeline.diff_report(replacement, source: "campaign_planner_test.timeline_diff_summary")
      |> Timeline.diff_summary()

    assert {:ok, %{"schema_contract" => "timeline_diff_summary.v1"}} =
             Schema.validate_artifact(base_diff_summary)

    diff_summary = fn trust_boundary ->
      Map.put(base_diff_summary, "provenance", %{"trust_boundary" => trust_boundary})
    end

    source_summary = diff_summary.("source_timeline_diff_summary_boundary")
    canonical_summary = diff_summary.("canonical_timeline_diff_summary_boundary")
    source_wrapped_summary = diff_summary.("source_wrapped_timeline_diff_summary_boundary")
    result_wrapped_summary = diff_summary.("result_wrapped_timeline_diff_summary_boundary")

    quadruple_numeric_map = fn map ->
      Map.new(map || %{}, fn {key, value} -> {key, value * 4} end)
    end

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_timeline_diff_summary", source_summary)
      |> Map.put("timeline_diff_summary", canonical_summary)
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "timeline_diff_summary" => Map.delete(source_wrapped_summary, "provenance"),
        "provenance" => %{
          "trust_boundary" => "source_wrapped_timeline_diff_summary_boundary"
        }
      })
      |> Map.put(:result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "timeline_diff_summary" => Map.delete(result_wrapped_summary, "provenance"),
        "provenance" => %{
          "trust_boundary" => "result_wrapped_timeline_diff_summary_boundary"
        }
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

    for source_path <- [
          "mission_state.source_timeline_diff_summary",
          "mission_state.timeline_diff_summary",
          "mission_state.source_result_artifact.timeline_diff_summary",
          "mission_state.result_artifact.timeline_diff_summary"
        ] do
      assert source_path in candidate_source["source_report_input_paths"]

      assert source_path in candidate_source[
               "candidate_refresh_request_source_report_input_paths"
             ]
    end

    assert %{
             "source_report_count" => 4,
             "source_report_row_count" => source_report_row_count,
             "source_report_timeline_diff_status_counts" => source_status_counts,
             "source_report_timeline_diff_required_operator_action_counts" => source_action_counts
           } = candidate_source["candidate_refresh_request_source_report_summary"]

    assert source_report_row_count == base_diff_summary["row_count"] * 4
    assert source_status_counts == quadruple_numeric_map.(base_diff_summary["diff_status_counts"])

    assert source_action_counts ==
             quadruple_numeric_map.(base_diff_summary["required_operator_action_counts"])

    assert %{
             "source" =>
               "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_diff_report",
             "contract" => "timeline_diff_summary.v1",
             "source_report_count" => 4,
             "source_report_row_count" => ^source_report_row_count,
             "source_report_paths" => replay_source_paths,
             "diff_status_counts" => ^source_status_counts,
             "required_operator_action_counts" => ^source_action_counts,
             "trust_boundary_status" => "declared",
             "trust_boundaries" => replay_trust_boundaries,
             "branch_local_timeline_diff_pressure" => true,
             "branch_local_activity_routing_pressure" => true,
             "branch_local_operator_review_pressure" => true,
             "assumptions" => %{
               "replay_scope" => "timeline_diff_candidate_source_report_summary_only"
             }
           } = CandidateRefresh.timeline_diff_replay_summary(candidate_source)

    assert Enum.sort(replay_trust_boundaries) == [
             "canonical_timeline_diff_summary_boundary",
             "result_wrapped_timeline_diff_summary_boundary",
             "source_timeline_diff_summary_boundary",
             "source_wrapped_timeline_diff_summary_boundary"
           ]

    for source_path <- [
          "mission_state.source_timeline_diff_summary",
          "mission_state.timeline_diff_summary",
          "mission_state.source_result_artifact.timeline_diff_summary",
          "mission_state.result_artifact.timeline_diff_summary"
        ] do
      assert source_path in replay_source_paths
    end

    timeline_diff_pressure_count =
      Enum.count(urgent["risk_indicators"], &(&1["type"] == "timeline_diff_pressure"))

    assert timeline_diff_pressure_count == 1

    assert %{
             "source_report_count" => 4,
             "source_report_row_count" => ^source_report_row_count,
             "source_report_paths" => pressure_source_paths,
             "diff_status_counts" => ^source_status_counts,
             "required_operator_action_counts" => ^source_action_counts,
             "feedback_source" => "candidate_source.timeline_diff_replay_summary",
             "feedback_scope" => "timeline_diff",
             "assumptions" => %{
               "replay_scope" => "timeline_diff_candidate_source_report_summary_only",
               "timeline_mutation" => "not_performed_by_summary"
             }
           } =
             Enum.find(urgent["risk_indicators"], &(&1["type"] == "timeline_diff_pressure"))

    assert Enum.sort(pressure_source_paths) == Enum.sort(replay_source_paths)

    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    assert urgent["score_terms"]["timeline_diff_pressure_penalty"] ==
             -timeline_diff_pressure_count * risk_weight

    assert "timeline_diff_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == "urgent" and
                 &1["term_key"] == "timeline_diff_pressure_penalty" and &1["value"] < 0.0)
           )

    urgent_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "urgent"))

    assert "timeline_diff_pressure" in urgent_row["risk_types"]

    assert urgent_row["branch_timeline_diff_source_report_paths"] ==
             Enum.sort(replay_source_paths)

    assert urgent_row["branch_timeline_diff_statuses"] ==
             source_status_counts |> Map.keys() |> Enum.sort()

    assert urgent_row["branch_timeline_diff_required_operator_actions"] ==
             source_action_counts |> Map.keys() |> Enum.sort()

    assert urgent_row["branch_timeline_diff_trust_boundaries"] ==
             Enum.sort(replay_trust_boundaries)

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
