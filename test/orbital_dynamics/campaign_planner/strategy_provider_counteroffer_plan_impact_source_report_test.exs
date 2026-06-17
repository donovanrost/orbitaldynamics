Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyProviderCounterofferPlanImpactSourceReportTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.CandidateRefresh
  alias OrbitalDynamics.Schema

  test "strategy carries mission-state provider-counteroffer plan-impact summaries into branch refresh requests" do
    direct_summary = provider_counteroffer_plan_impact_summary_fixture("direct")
    canonical_summary = provider_counteroffer_plan_impact_summary_fixture("canonical")
    wrapped_summary = provider_counteroffer_plan_impact_summary_fixture("wrapped")

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_provider_counteroffer_plan_impact_summary", direct_summary)
      |> Map.put("provider_counteroffer_plan_impact_summary", canonical_summary)
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "source_provider_counteroffer_plan_impact_summary" =>
          Map.delete(wrapped_summary, "provenance"),
        "provenance" => %{"trust_boundary" => "wrapped_counteroffer_plan_impact_boundary"}
      })

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
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

    assert "mission_state.source_provider_counteroffer_plan_impact_summary" in source_report_input_paths

    assert "mission_state.provider_counteroffer_plan_impact_summary" in source_report_input_paths

    assert "mission_state.source_result_artifact.source_provider_counteroffer_plan_impact_summary" in source_report_input_paths

    assert "mission_state.source_provider_counteroffer_plan_impact_summary" in candidate_source[
             "candidate_refresh_request_source_report_input_paths"
           ]

    assert "mission_state.provider_counteroffer_plan_impact_summary" in candidate_source[
             "candidate_refresh_request_source_report_input_paths"
           ]

    assert "mission_state.source_result_artifact.source_provider_counteroffer_plan_impact_summary" in candidate_source[
             "candidate_refresh_request_source_report_input_paths"
           ]

    assert %{
             "source_report_count" => 3,
             "source_report_row_count" => 3,
             "source_report_provider_counteroffer_reviewable_count" => 3,
             "source_report_provider_counteroffer_cost_delta_count" => 3,
             "source_report_provider_counteroffer_cost_delta_total" => 190.0,
             "source_report_provider_counteroffer_timing_shift_count" => 3,
             "source_report_provider_counteroffer_lock_deadline_count" => 3,
             "source_report_provider_counteroffer_earliest_lock_deadline_s" => 210.0,
             "source_report_provider_counteroffer_status_counts" => %{"proposed" => 3},
             "source_report_provider_counteroffer_required_operator_action_counts" => %{
               "review_provider_counteroffer" => 3
             },
             "source_report_provider_counteroffer_plan_impact_summary_count" => 3,
             "source_report_provider_counteroffer_plan_impact_status_counts" => %{
               "review_required" => 3
             },
             "source_report_provider_counteroffer_affected_station_calendar_entry_ids" => [
               "canonical_contact_original",
               "direct_contact_original",
               "wrapped_contact_original"
             ],
             "source_report_provider_counteroffer_affected_provider_entry_ids" => [
               "canonical_provider_offer",
               "direct_provider_offer",
               "wrapped_provider_offer"
             ],
             "source_report_provider_counteroffer_impact_counteroffer_ids" => [
               "canonical_counteroffer",
               "direct_counteroffer",
               "wrapped_counteroffer"
             ]
           } = candidate_source["candidate_refresh_request_source_report_summary"]

    assert %{
             "source_report_count" => 3,
             "source_report_row_count" => 3,
             "source_report_paths" => replay_source_paths,
             "reviewable_count" => 3,
             "counteroffer_cost_delta_count" => 3,
             "counteroffer_cost_delta_total" => 190.0,
             "counteroffer_timing_shift_count" => 3,
             "counteroffer_lock_deadline_count" => 3,
             "earliest_counteroffer_lock_deadline_s" => 210.0,
             "counteroffer_status_counts" => %{"proposed" => 3},
             "required_operator_action_counts" => %{"review_provider_counteroffer" => 3},
             "plan_impact_summary_count" => 3,
             "plan_impact_status_counts" => %{"review_required" => 3},
             "affected_station_calendar_entry_ids" => [
               "canonical_contact_original",
               "direct_contact_original",
               "wrapped_contact_original"
             ],
             "affected_provider_entry_ids" => [
               "canonical_provider_offer",
               "direct_provider_offer",
               "wrapped_provider_offer"
             ],
             "impact_counteroffer_ids" => [
               "canonical_counteroffer",
               "direct_counteroffer",
               "wrapped_counteroffer"
             ],
             "timing_shift_counteroffer_ids" => [
               "canonical_counteroffer",
               "direct_counteroffer",
               "wrapped_counteroffer"
             ],
             "cost_delta_counteroffer_ids" => [
               "canonical_counteroffer",
               "direct_counteroffer",
               "wrapped_counteroffer"
             ],
             "trust_boundary_status" => "declared",
             "trust_boundaries" => replay_trust_boundaries,
             "branch_local_counteroffer_pressure" => true,
             "branch_local_counteroffer_review_pressure" => true,
             "branch_local_counteroffer_cost_pressure" => true,
             "branch_local_counteroffer_timing_pressure" => true,
             "branch_local_counteroffer_lock_pressure" => true,
             "branch_local_plan_impact_pressure" => true,
             "assumptions" => %{
               "provider_write" => "not_performed_by_summary",
               "schedule_mutation" => "not_performed_by_summary",
               "candidate_generation" => "not_performed_by_summary"
             }
           } = CandidateRefresh.provider_counteroffer_replay_summary(candidate_source)

    for source_path <- [
          "mission_state.provider_counteroffer_plan_impact_summary",
          "mission_state.source_provider_counteroffer_plan_impact_summary",
          "mission_state.source_result_artifact.source_provider_counteroffer_plan_impact_summary"
        ] do
      assert source_path in replay_source_paths
    end

    assert Enum.sort(replay_trust_boundaries) == [
             "canonical_counteroffer_plan_impact_fixture",
             "canonical_provider_calendar_feed",
             "direct_counteroffer_plan_impact_fixture",
             "direct_provider_calendar_feed",
             "wrapped_counteroffer_plan_impact_boundary",
             "wrapped_provider_calendar_feed"
           ]

    direct_branch = branch(artifact, "derived_provider_counteroffer_pressure_direct_counteroffer")

    assert %{
             "type" => "provider_counteroffer_pressure",
             "provider_counteroffer_id" => "direct_counteroffer",
             "provider_counteroffer_status" => "proposed",
             "provider_counteroffer_cost_delta" => 50.0,
             "provider_counteroffer_lock_deadline_s" => 240.0,
             "provider_counteroffer_start_delta_s" => 30.0,
             "provider_counteroffer_end_delta_s" => 20.0,
             "provider_counteroffer_duration_delta_s" => -10.0,
             "plan_impact_status" => "review_required",
             "station_calendar_entry_id" => "direct_contact_original",
             "station_calendar_provider_entry_id" => "direct_provider_offer",
             "affected_station_calendar_entry_ids" => ["direct_contact_original"],
             "affected_provider_entry_ids" => ["direct_provider_offer"],
             "feedback_source" =>
               "mission_state.source_provider_counteroffer_plan_impact_summary.impact_rows",
             "feedback_scope" => "provider_counteroffer",
             "trust_boundary" => "direct_provider_calendar_feed",
             "assumptions" => %{
               "provider_write" => "not_performed_by_strategy_branch",
               "schedule_mutation" => "not_performed_by_strategy_branch",
               "operator_authority" => "not_granted_by_strategy_branch"
             }
           } = List.first(direct_branch["events"])

    assert Enum.any?(
             direct_branch["risk_indicators"],
             &(&1["type"] == "provider_counteroffer_pressure" and
                 &1["plan_impact_status"] == "review_required")
           )

    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    provider_counteroffer_pressure_count =
      Enum.count(
        direct_branch["risk_indicators"],
        &(&1["feedback_scope"] == "provider_counteroffer")
      )

    assert provider_counteroffer_pressure_count > 0

    assert direct_branch["score_terms"]["provider_counteroffer_pressure_penalty"] ==
             -provider_counteroffer_pressure_count * risk_weight

    assert direct_branch["score_terms"]["risk_penalty"] ==
             -(length(direct_branch["risk_indicators"]) -
                 provider_counteroffer_pressure_count) *
               risk_weight

    comparison_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(
        &(&1["branch_id"] == "derived_provider_counteroffer_pressure_direct_counteroffer")
      )

    assert "provider_counteroffer_pressure" in comparison_row["risk_types"]

    assert comparison_row["branch_station_calendar_provider_entry_ids"] == [
             "direct_provider_offer"
           ]

    assert branch(artifact, "derived_provider_counteroffer_pressure_canonical_counteroffer")
    assert branch(artifact, "derived_provider_counteroffer_pressure_wrapped_counteroffer")

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  defp provider_counteroffer_plan_impact_summary_fixture(prefix) do
    cost_delta =
      case prefix do
        "direct" -> 50.0
        _prefix -> 70.0
      end

    lock_deadline_s =
      case prefix do
        "direct" -> 240.0
        _prefix -> 210.0
      end

    impact_row = %{
      "id" => "provider_counteroffer:#{prefix}_counteroffer",
      "provider_counteroffer_id" => "#{prefix}_counteroffer",
      "provider_counteroffer_status" => "proposed",
      "provider_counteroffer_cost_delta" => cost_delta,
      "provider_counteroffer_lock_deadline_s" => lock_deadline_s,
      "provider_counteroffer_start_delta_s" => 30.0,
      "provider_counteroffer_end_delta_s" => 20.0,
      "provider_counteroffer_duration_delta_s" => -10.0,
      "plan_impact_status" => "review_required",
      "station_calendar_entry_id" => "#{prefix}_contact_original",
      "station_calendar_provider_entry_id" => "#{prefix}_provider_offer",
      "affected_station_calendar_entry_ids" => ["#{prefix}_contact_original"],
      "affected_provider_entry_ids" => ["#{prefix}_provider_offer"],
      "reviewable" => true,
      "required_operator_action" => "review_provider_counteroffer",
      "trust_boundary" => "#{prefix}_provider_calendar_feed"
    }

    %{
      "schema_contract" => "provider_counteroffer_plan_impact_summary.v1",
      "model" => "artifact_only_provider_counteroffer_plan_impact_summary",
      "source_artifact_type" => "provider_counteroffer_report.v1",
      "source" => "campaign_planner_test.#{prefix}.provider_counteroffer_plan_impact_summary",
      "plan_impact_status" => "review_required",
      "counteroffer_count" => 1,
      "reviewable_count" => 1,
      "counteroffer_cost_delta_count" => 1,
      "counteroffer_cost_delta_total" => cost_delta,
      "timing_shift_counteroffer_count" => 1,
      "counteroffer_lock_deadline_count" => 1,
      "earliest_counteroffer_lock_deadline_s" => lock_deadline_s,
      "counteroffer_status_counts" => %{"stale_status" => 99},
      "required_operator_action_counts" => %{"stale_action" => 99},
      "affected_station_calendar_entry_ids" => ["#{prefix}_contact_original"],
      "affected_provider_entry_ids" => ["#{prefix}_provider_offer"],
      "impact_counteroffer_ids" => ["#{prefix}_counteroffer"],
      "timing_shift_counteroffer_ids" => ["#{prefix}_counteroffer"],
      "cost_delta_counteroffer_ids" => ["#{prefix}_counteroffer"],
      "impact_rows" => [impact_row],
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_provider_write_or_schedule_mutation"
      },
      "provenance" => %{"trust_boundary" => "#{prefix}_counteroffer_plan_impact_fixture"}
    }
  end
end
