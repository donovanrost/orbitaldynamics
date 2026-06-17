Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyManeuverReviewSourceReportTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.CandidateRefresh
  alias OrbitalDynamics.Schema

  test "strategy carries mission-state maneuver-review reports into branch refresh requests" do
    maneuver_review_report =
      fn prefix, success_factor, uncertainty_status, required_operator_action ->
        uncertainty =
          case uncertainty_status do
            "declared" -> %{"timing_3sigma_s" => 75.0}
            _status -> nil
          end

        row =
          %{
            "id" => "#{prefix}_maneuver_review",
            "maneuver_id" => "#{prefix}_burn",
            "required_operator_action" => required_operator_action,
            "provenance" => %{
              "trust_boundary" => "#{prefix}_maneuver_review_row_boundary"
            }
          }
          |> Map.put(
            "maneuver_success_factor",
            success_factor
          )
          |> then(fn row ->
            case uncertainty_status do
              "declared" ->
                Map.put(row, "execution_uncertainty", uncertainty)

              "missing" ->
                Map.put(row, "execution_uncertainty_status", "missing")

              _status ->
                row
            end
          end)

        %{
          "schema_contract" => "maneuver_review_report.v1",
          "source" => "campaign_planner_test.#{prefix}.maneuver_review_report",
          "rows" => [row],
          "provenance" => %{
            "trust_boundary" => "#{prefix}_maneuver_review_report_boundary"
          }
        }
      end

    direct_report =
      maneuver_review_report.("direct", 0.4, "declared", "review_maneuver_execution")

    canonical_report =
      maneuver_review_report.("canonical", 0.2, "missing", "review_maneuver_execution")

    source_wrapped_report =
      maneuver_review_report.(
        "source_wrapped",
        0.0,
        "missing",
        "review_maneuver_uncertainty"
      )

    result_wrapped_report =
      maneuver_review_report.("result_wrapped", 0.6, "declared", "none")

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_maneuver_review_report", direct_report)
      |> Map.put("maneuver_review_report", canonical_report)
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "maneuver_review_report" => Map.delete(source_wrapped_report, "provenance"),
        "provenance" => %{"trust_boundary" => "source_wrapped_maneuver_review_boundary"}
      })
      |> Map.put(:result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "source_maneuver_review_report" => Map.delete(result_wrapped_report, "provenance"),
        "provenance" => %{"trust_boundary" => "result_wrapped_maneuver_review_boundary"}
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
          "mission_state.source_maneuver_review_report",
          "mission_state.maneuver_review_report",
          "mission_state.source_result_artifact.maneuver_review_report",
          "mission_state.result_artifact.source_maneuver_review_report"
        ] do
      assert source_path in candidate_source["source_report_input_paths"]

      assert source_path in candidate_source[
               "candidate_refresh_request_source_report_input_paths"
             ]
    end

    assert %{
             "source_report_count" => 4,
             "source_report_row_count" => 4,
             "source_report_maneuver_review_maneuver_success_feedback_count" => 4,
             "source_report_maneuver_review_execution_uncertainty_declared_count" => 2,
             "source_report_maneuver_review_execution_uncertainty_missing_count" => 2,
             "source_report_maneuver_review_input_keys" => [
               "maneuver_execution_uncertainty",
               "maneuver_success_rate"
             ],
             "source_report_maneuver_review_maneuver_id_counts" => %{
               "canonical_burn" => 1,
               "direct_burn" => 1,
               "result_wrapped_burn" => 1,
               "source_wrapped_burn" => 1
             },
             "source_report_maneuver_review_required_operator_action_counts" => %{
               "none" => 1,
               "review_maneuver_execution" => 2,
               "review_maneuver_uncertainty" => 1
             }
           } = candidate_source["candidate_refresh_request_source_report_summary"]

    assert %{
             "contract" => "maneuver_review_report.v1",
             "source_report_count" => 4,
             "source_report_row_count" => 4,
             "source_report_paths" => replay_source_paths,
             "maneuver_success_feedback_count" => 4,
             "execution_uncertainty_declared_count" => 2,
             "execution_uncertainty_missing_count" => 2,
             "input_keys" => [
               "maneuver_execution_uncertainty",
               "maneuver_success_rate"
             ],
             "maneuver_id_counts" => %{
               "canonical_burn" => 1,
               "direct_burn" => 1,
               "result_wrapped_burn" => 1,
               "source_wrapped_burn" => 1
             },
             "required_operator_action_counts" => %{
               "none" => 1,
               "review_maneuver_execution" => 2,
               "review_maneuver_uncertainty" => 1
             },
             "trust_boundary_status" => "declared",
             "trust_boundaries" => replay_trust_boundaries,
             "branch_local_maneuver_review_pressure" => true,
             "branch_local_maneuver_feedback_pressure" => true,
             "branch_local_maneuver_routing_pressure" => true,
             "branch_local_maneuver_action_pressure" => true,
             "branch_local_execution_uncertainty_pressure" => true,
             "assumptions" => %{
               "maneuver_execution" => "not_performed_by_summary",
               "candidate_selection" => "not_performed_by_summary",
               "cadence_write" => "not_performed_by_summary"
             }
           } = CandidateRefresh.maneuver_review_replay_summary(candidate_source)

    assert Enum.sort(replay_source_paths) == [
             "mission_state.maneuver_review_report",
             "mission_state.result_artifact.source_maneuver_review_report",
             "mission_state.source_maneuver_review_report",
             "mission_state.source_result_artifact.maneuver_review_report"
           ]

    assert Enum.sort(replay_trust_boundaries) == [
             "canonical_maneuver_review_report_boundary",
             "canonical_maneuver_review_row_boundary",
             "direct_maneuver_review_report_boundary",
             "direct_maneuver_review_row_boundary",
             "result_wrapped_maneuver_review_boundary",
             "result_wrapped_maneuver_review_row_boundary",
             "source_wrapped_maneuver_review_boundary",
             "source_wrapped_maneuver_review_row_boundary"
           ]

    maneuver_review_pressure_count =
      Enum.count(
        urgent["risk_indicators"],
        &(&1["type"] == "maneuver_review_pressure" and
            &1["feedback_source"] == "candidate_source.maneuver_review_replay_summary")
      )

    assert maneuver_review_pressure_count == 1

    assert Enum.any?(
             urgent["risk_indicators"],
             &(&1["type"] == "maneuver_review_pressure" and
                 &1["source_report_count"] == 4 and
                 &1["source_report_row_count"] == 4 and
                 &1["maneuver_success_feedback_count"] == 4 and
                 &1["execution_uncertainty_declared_count"] == 2 and
                 &1["execution_uncertainty_missing_count"] == 2 and
                 &1["input_keys"] == [
                   "maneuver_execution_uncertainty",
                   "maneuver_success_rate"
                 ] and
                 &1["maneuver_id_counts"] == %{
                   "canonical_burn" => 1,
                   "direct_burn" => 1,
                   "result_wrapped_burn" => 1,
                   "source_wrapped_burn" => 1
                 } and
                 &1["required_operator_action_counts"] == %{
                   "none" => 1,
                   "review_maneuver_execution" => 2,
                   "review_maneuver_uncertainty" => 1
                 } and
                 &1["trust_boundaries"] == replay_trust_boundaries and
                 &1["assumptions"]["maneuver_execution"] == "not_performed_by_summary")
           )

    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    assert urgent["score_terms"]["maneuver_review_pressure_penalty"] ==
             -maneuver_review_pressure_count * risk_weight

    assert "maneuver_review_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == "urgent" and
                 &1["term_key"] == "maneuver_review_pressure_penalty" and &1["value"] < 0.0)
           )

    urgent_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "urgent"))

    assert "maneuver_review_pressure" in urgent_row["risk_types"]

    assert urgent_row["branch_maneuver_review_source_report_paths"] == [
             "mission_state.maneuver_review_report",
             "mission_state.result_artifact.source_maneuver_review_report",
             "mission_state.source_maneuver_review_report",
             "mission_state.source_result_artifact.maneuver_review_report"
           ]

    assert urgent_row["branch_maneuver_review_input_keys"] == [
             "maneuver_execution_uncertainty",
             "maneuver_success_rate"
           ]

    assert urgent_row["branch_maneuver_review_maneuver_ids"] == [
             "canonical_burn",
             "direct_burn",
             "result_wrapped_burn",
             "source_wrapped_burn"
           ]

    assert urgent_row["branch_maneuver_review_required_operator_actions"] == [
             "none",
             "review_maneuver_execution",
             "review_maneuver_uncertainty"
           ]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
