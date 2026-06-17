Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyCommandWindowSourceReportTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.CandidateRefresh
  alias OrbitalDynamics.Schema

  test "strategy carries mission-state command-window reports into branch refresh requests" do
    command_window_report = fn prefix, direction, required_operator_action ->
      %{
        "schema_contract" => "command_window_report.v1",
        "source" => "campaign_planner_test.#{prefix}.command_window_report",
        "rows" => [
          %{
            "id" => "#{prefix}_window",
            "activity_id" => "#{prefix}_activity",
            "direction" => direction,
            "window_type" => "command_window",
            "command_success" => false,
            "required_operator_action" => required_operator_action,
            "provenance" => %{
              "trust_boundary" => "#{prefix}_command_window_row_boundary"
            }
          }
        ],
        "provenance" => %{
          "trust_boundary" => "#{prefix}_command_window_report_boundary"
        }
      }
    end

    direct_report =
      command_window_report.("direct", "s-band command", "review_command_window")

    canonical_report =
      command_window_report.("canonical", "s-band command", "review_command_window")

    source_wrapped_report =
      command_window_report.("source_wrapped", "Up Link", "review_command_result")

    result_wrapped_report =
      command_window_report.("result_wrapped", "tracking_pass", "none")

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_command_window_report", direct_report)
      |> Map.put("command_window_report", canonical_report)
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "command_window_report" => Map.delete(source_wrapped_report, "provenance"),
        "provenance" => %{"trust_boundary" => "source_wrapped_command_window_boundary"}
      })
      |> Map.put(:result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "source_command_window_report" => Map.delete(result_wrapped_report, "provenance"),
        "provenance" => %{"trust_boundary" => "result_wrapped_command_window_boundary"}
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
          "mission_state.source_command_window_report",
          "mission_state.command_window_report",
          "mission_state.source_result_artifact.command_window_report",
          "mission_state.result_artifact.source_command_window_report"
        ] do
      assert source_path in candidate_source["source_report_input_paths"]

      assert source_path in candidate_source[
               "candidate_refresh_request_source_report_input_paths"
             ]
    end

    assert %{
             "source_report_count" => 4,
             "source_report_row_count" => 4,
             "source_report_command_window_command_feedback_count" => 4,
             "source_report_command_window_input_keys" => ["command_success_rate"],
             "source_report_command_window_direction_counts" => %{
               "command" => 2,
               "tracking" => 1,
               "uplink" => 1
             },
             "source_report_command_window_required_operator_action_counts" => %{
               "none" => 1,
               "review_command_result" => 1,
               "review_command_window" => 2
             }
           } = candidate_source["candidate_refresh_request_source_report_summary"]

    assert %{
             "contract" => "command_window_report.v1",
             "source_report_count" => 4,
             "source_report_row_count" => 4,
             "source_report_paths" => replay_source_paths,
             "command_feedback_count" => 4,
             "input_keys" => ["command_success_rate"],
             "direction_counts" => %{
               "command" => 2,
               "tracking" => 1,
               "uplink" => 1
             },
             "activity_ids_by_direction" => %{
               "command" => ["direct_activity", "canonical_activity"],
               "tracking" => ["result_wrapped_activity"],
               "uplink" => ["source_wrapped_activity"]
             },
             "window_ids_by_direction" => %{
               "command" => ["direct_window", "canonical_window"],
               "tracking" => ["result_wrapped_window"],
               "uplink" => ["source_wrapped_window"]
             },
             "required_operator_action_counts" => %{
               "none" => 1,
               "review_command_result" => 1,
               "review_command_window" => 2
             },
             "trust_boundary_status" => "declared",
             "trust_boundaries" => replay_trust_boundaries,
             "branch_local_command_window_pressure" => true,
             "branch_local_command_feedback_pressure" => true,
             "branch_local_command_window_action_pressure" => true,
             "assumptions" => %{
               "command_execution" => "not_performed_by_summary",
               "candidate_selection" => "not_performed_by_summary",
               "cadence_write" => "not_performed_by_summary"
             }
           } = CandidateRefresh.command_window_replay_summary(candidate_source)

    assert Enum.sort(replay_source_paths) == [
             "mission_state.command_window_report",
             "mission_state.result_artifact.source_command_window_report",
             "mission_state.source_command_window_report",
             "mission_state.source_result_artifact.command_window_report"
           ]

    assert Enum.sort(replay_trust_boundaries) == [
             "canonical_command_window_report_boundary",
             "canonical_command_window_row_boundary",
             "direct_command_window_report_boundary",
             "direct_command_window_row_boundary",
             "result_wrapped_command_window_boundary",
             "result_wrapped_command_window_row_boundary",
             "source_wrapped_command_window_boundary",
             "source_wrapped_command_window_row_boundary"
           ]

    command_window_pressure_count =
      Enum.count(
        urgent["risk_indicators"],
        &(&1["type"] == "command_window_pressure" and
            &1["feedback_source"] == "candidate_source.command_window_replay_summary")
      )

    assert command_window_pressure_count == 1

    assert Enum.any?(
             urgent["risk_indicators"],
             &(&1["type"] == "command_window_pressure" and
                 &1["source_report_count"] == 4 and
                 &1["source_report_row_count"] == 4 and
                 &1["command_feedback_count"] == 4 and
                 &1["direction_counts"] == %{
                   "command" => 2,
                   "tracking" => 1,
                   "uplink" => 1
                 } and
                 &1["required_operator_action_counts"] == %{
                   "none" => 1,
                   "review_command_result" => 1,
                   "review_command_window" => 2
                 } and
                 &1["trust_boundaries"] == replay_trust_boundaries and
                 &1["assumptions"]["command_execution"] == "not_performed_by_summary")
           )

    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    assert urgent["score_terms"]["command_window_pressure_penalty"] ==
             -command_window_pressure_count * risk_weight

    assert "command_window_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == "urgent" and
                 &1["term_key"] == "command_window_pressure_penalty" and &1["value"] < 0.0)
           )

    urgent_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "urgent"))

    assert "command_window_pressure" in urgent_row["risk_types"]

    assert urgent_row["branch_command_window_source_report_paths"] == [
             "mission_state.command_window_report",
             "mission_state.result_artifact.source_command_window_report",
             "mission_state.source_command_window_report",
             "mission_state.source_result_artifact.command_window_report"
           ]

    assert urgent_row["branch_command_window_directions"] == ["command", "tracking", "uplink"]

    assert urgent_row["branch_command_window_required_operator_actions"] == [
             "none",
             "review_command_result",
             "review_command_window"
           ]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
