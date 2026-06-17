Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyProviderCounterofferSourceReportTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.CandidateRefresh
  alias OrbitalDynamics.Schema

  test "strategy carries mission-state provider-counteroffer reports into branch refresh requests" do
    counteroffer_report = fn prefix, status, required_action, cost_delta, reviewable? ->
      %{
        "schema_contract" => "provider_counteroffer_report.v1",
        "source" => "campaign_planner_test.#{prefix}.provider_counteroffer_report",
        "source_artifact_type" => "station_calendar_report.v1",
        "counteroffer_count" => 1,
        "reviewable_count" => if(reviewable?, do: 1, else: 0),
        "counteroffer_status_counts" => %{"stale_status" => 99},
        "required_operator_action_counts" => %{"stale_action" => 99},
        "rows" => [
          %{
            "id" => "provider_counteroffer:#{prefix}_counteroffer",
            "provider_counteroffer_id" => "#{prefix}_counteroffer",
            "provider_counteroffer_status" => status,
            "provider_counteroffer_cost_delta" => cost_delta,
            "provider_counteroffer_lock_deadline_s" =>
              if(prefix == "result_wrapped", do: 120.0, else: 180.0),
            "provider_counteroffer_start_delta_s" =>
              if(prefix == "result_wrapped", do: -5.0, else: 10.0),
            "provider_counteroffer_end_delta_s" =>
              if(prefix == "result_wrapped", do: -10.0, else: 20.0),
            "provider_counteroffer_duration_delta_s" =>
              if(prefix == "result_wrapped", do: -5.0, else: 10.0),
            "ground_station_id" => "equator_prime",
            "station_calendar_entry_id" => "#{prefix}_contact_original",
            "station_calendar_provider_entry_id" => "#{prefix}_provider_offer",
            "reviewable" => reviewable?,
            "required_operator_action" => required_action,
            "trust_boundary" => "#{prefix}_provider_counteroffer_row_boundary"
          }
        ],
        "provenance" => %{
          "trust_boundary" => "#{prefix}_provider_counteroffer_report_boundary"
        }
      }
    end

    direct_report =
      counteroffer_report.(
        "direct",
        "proposed",
        "review_provider_counteroffer",
        40.0,
        true
      )

    canonical_report =
      counteroffer_report.(
        "canonical",
        "proposed",
        "review_provider_counteroffer",
        80.0,
        true
      )

    source_wrapped_report =
      counteroffer_report.(
        "source_wrapped",
        "proposed",
        "review_provider_counteroffer",
        60.0,
        true
      )

    result_wrapped_report =
      counteroffer_report.("result_wrapped", "accepted", "none", 20.0, false)

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_provider_counteroffer_report", direct_report)
      |> Map.put("provider_counteroffer_report", canonical_report)
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "provider_counteroffer_report" => Map.delete(source_wrapped_report, "provenance"),
        "provenance" => %{"trust_boundary" => "source_wrapped_provider_counteroffer_boundary"}
      })
      |> Map.put(:result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "source_provider_counteroffer_report" => Map.delete(result_wrapped_report, "provenance"),
        "provenance" => %{"trust_boundary" => "result_wrapped_provider_counteroffer_boundary"}
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
          "mission_state.source_provider_counteroffer_report",
          "mission_state.provider_counteroffer_report",
          "mission_state.source_result_artifact.provider_counteroffer_report",
          "mission_state.result_artifact.source_provider_counteroffer_report"
        ] do
      assert source_path in candidate_source["source_report_input_paths"]

      assert source_path in candidate_source[
               "candidate_refresh_request_source_report_input_paths"
             ]
    end

    assert %{
             "source_report_count" => 4,
             "source_report_row_count" => 4,
             "source_report_provider_counteroffer_reviewable_count" => 3,
             "source_report_provider_counteroffer_cost_delta_count" => 4,
             "source_report_provider_counteroffer_cost_delta_total" => 200.0,
             "source_report_provider_counteroffer_timing_shift_count" => 4,
             "source_report_provider_counteroffer_start_delta_count" => 4,
             "source_report_provider_counteroffer_end_delta_count" => 4,
             "source_report_provider_counteroffer_duration_delta_count" => 4,
             "source_report_provider_counteroffer_lock_deadline_count" => 4,
             "source_report_provider_counteroffer_earliest_lock_deadline_s" => 120.0,
             "source_report_provider_counteroffer_status_counts" => %{
               "accepted" => 1,
               "proposed" => 3
             },
             "source_report_provider_counteroffer_required_operator_action_counts" => %{
               "none" => 1,
               "review_provider_counteroffer" => 3
             }
           } = candidate_source["candidate_refresh_request_source_report_summary"]

    assert %{
             "source" =>
               "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_activity_state",
             "source_report_count" => 4,
             "source_report_row_count" => 4,
             "source_report_paths" => replay_source_paths,
             "reviewable_count" => 3,
             "counteroffer_cost_delta_count" => 4,
             "counteroffer_cost_delta_total" => 200.0,
             "counteroffer_timing_shift_count" => 4,
             "counteroffer_start_delta_count" => 4,
             "counteroffer_end_delta_count" => 4,
             "counteroffer_duration_delta_count" => 4,
             "counteroffer_lock_deadline_count" => 4,
             "earliest_counteroffer_lock_deadline_s" => 120.0,
             "counteroffer_status_counts" => %{"accepted" => 1, "proposed" => 3},
             "required_operator_action_counts" => %{
               "none" => 1,
               "review_provider_counteroffer" => 3
             },
             "trust_boundary_status" => "declared",
             "trust_boundaries" => replay_trust_boundaries,
             "branch_local_counteroffer_pressure" => true,
             "branch_local_counteroffer_review_pressure" => true,
             "branch_local_counteroffer_cost_pressure" => true,
             "branch_local_counteroffer_timing_pressure" => true,
             "branch_local_counteroffer_lock_pressure" => true,
             "branch_local_counteroffer_import_readiness_pressure" => false,
             "branch_local_plan_impact_pressure" => false,
             "assumptions" => %{
               "provider_write" => "not_performed_by_summary",
               "schedule_mutation" => "not_performed_by_summary",
               "candidate_generation" => "not_performed_by_summary"
             }
           } = CandidateRefresh.provider_counteroffer_replay_summary(candidate_source)

    assert Enum.sort(replay_source_paths) == [
             "mission_state.provider_counteroffer_report",
             "mission_state.result_artifact.source_provider_counteroffer_report",
             "mission_state.source_provider_counteroffer_report",
             "mission_state.source_result_artifact.provider_counteroffer_report"
           ]

    assert Enum.sort(replay_trust_boundaries) == [
             "canonical_provider_counteroffer_report_boundary",
             "canonical_provider_counteroffer_row_boundary",
             "direct_provider_counteroffer_report_boundary",
             "direct_provider_counteroffer_row_boundary",
             "result_wrapped_provider_counteroffer_row_boundary",
             "source_wrapped_provider_counteroffer_row_boundary"
           ]

    provider_counteroffer_pressure_count =
      Enum.count(
        urgent["risk_indicators"],
        &(&1["type"] == "provider_counteroffer_review" and
            &1["feedback_source"] ==
              "candidate_source.provider_counteroffer_replay_summary")
      )

    assert provider_counteroffer_pressure_count == 1

    assert Enum.any?(
             urgent["risk_indicators"],
             &(&1["type"] == "provider_counteroffer_review" and
                 &1["feedback_scope"] == "provider_counteroffer" and
                 &1["reviewable_count"] == 3 and
                 &1["counteroffer_cost_delta_count"] == 4 and
                 &1["counteroffer_cost_delta_total"] == 200.0 and
                 &1["counteroffer_timing_shift_count"] == 4 and
                 &1["counteroffer_start_delta_count"] == 4 and
                 &1["counteroffer_end_delta_count"] == 4 and
                 &1["counteroffer_duration_delta_count"] == 4 and
                 &1["counteroffer_lock_deadline_count"] == 4 and
                 &1["earliest_counteroffer_lock_deadline_s"] == 120.0 and
                 &1["counteroffer_status_counts"] == %{"accepted" => 1, "proposed" => 3} and
                 &1["required_operator_action_counts"] == %{
                   "none" => 1,
                   "review_provider_counteroffer" => 3
                 })
           )

    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    assert urgent["score_terms"]["provider_counteroffer_pressure_penalty"] ==
             -provider_counteroffer_pressure_count * risk_weight

    assert "provider_counteroffer_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == urgent["branch_id"] and
                 &1["term_key"] == "provider_counteroffer_pressure_penalty" and &1["value"] < 0.0)
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
