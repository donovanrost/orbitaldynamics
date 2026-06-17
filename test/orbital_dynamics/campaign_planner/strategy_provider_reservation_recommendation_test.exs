Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyProviderReservationRecommendationTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy recommendation skips branches blocked by provider reservation review by default" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [],
        "candidate_activities" => []
      })

    urgent_target_event = %{
      type: "urgent_target",
      target_id: "target_hot",
      starts_at_s: 500.0,
      ends_at_s: 560.0,
      priority: 20.0,
      candidate_windows: [
        %{
          id: "candidate_obs_hot",
          type: "observe",
          target_id: "target_hot",
          scenario_id: "leo_1",
          starts_at_s: 500.0,
          ends_at_s: 560.0,
          duration_s: 60.0,
          score: 10.0
        }
      ]
    }

    review_required_event = %{
      type: "provider_reservation_request_pressure",
      contact_id: "dl_provider_review",
      source_activity_id: "dl_provider_review",
      source_activity_ids: ["dl_provider_review"],
      ground_station_id: "equator_prime",
      direction: "downlink",
      station_reservation_id: "reservation_provider_review",
      station_reserved_by: "partner_calendar",
      station_reservation_status: "confirmed",
      station_reservation_match_status: "overlap",
      provider_reservation_request_status: "review_required",
      provider_reservation_row_scope: "review",
      required_operator_action: "review_provider_reservation_request",
      feedback_source:
        "mission_state.source_contact_allocation_provider_reservation_request_summary",
      feedback_scope: "contact_allocation_provider_reservation_request",
      trust_boundary: "provider_reservation_request_summary",
      assumptions: %{
        "provider_reservation_execution" => "not_performed_by_strategy_branch",
        "schedule_mutation" => "not_performed_by_strategy_branch",
        "operator_authority" => "not_granted_by_strategy_branch"
      }
    }

    request_ready_event = %{
      type: "provider_reservation_request_pressure",
      contact_id: "dl_provider_request_ready",
      source_activity_id: "dl_provider_request_ready",
      source_activity_ids: ["dl_provider_request_ready"],
      ground_station_id: "equator_prime",
      direction: "downlink",
      station_reservation_id: "reservation_provider_request_ready",
      station_reserved_by: "ops_calendar",
      station_reservation_status: "confirmed",
      station_reservation_match_status: "matched",
      provider_reservation_request_status: "request_ready",
      provider_reservation_row_scope: "request",
      required_operator_action: "review_provider_reservation_request",
      feedback_source:
        "mission_state.source_contact_allocation_provider_reservation_request_summary",
      feedback_scope: "contact_allocation_provider_reservation_request",
      trust_boundary: "provider_reservation_request_summary",
      assumptions: %{
        "provider_reservation_execution" => "not_performed_by_strategy_branch",
        "schedule_mutation" => "not_performed_by_strategy_branch",
        "operator_authority" => "not_granted_by_strategy_branch"
      }
    }

    blocked_artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([%{"type" => "priority_commitment", "target_id" => "target_hot"}]),
        strategy_policy: %{
          "mission_value_weight" => 10.0,
          "risk_weight" => 0.0,
          "approval_load_weight" => 0.0
        },
        branches: [
          %{id: "baseline"},
          %{
            id: "review_required_provider_reservation",
            events: [urgent_target_event, review_required_event]
          }
        ],
        current_epoch_s: 0.0
      )

    blocked_branch = branch(blocked_artifact, "review_required_provider_reservation")

    assert blocked_branch["score_terms"]["mission_value_score"] >
             branch(blocked_artifact, "baseline")["score_terms"]["mission_value_score"]

    assert blocked_artifact["recommendation"]["recommended_branch_id"] == "baseline"
    assert blocked_branch["approval_status"] == "blocked_by_policy"

    assert "provider_reservation_request_blocked" in blocked_artifact["approval_policy"][
             "blocked_risk_types"
           ]

    assert Enum.any?(
             blocked_branch["risk_indicators"],
             &(&1["type"] == "provider_reservation_request_review" and
                 &1["feedback_scope"] == "contact_allocation_provider_reservation_request" and
                 &1["provider_reservation_request_status"] == "review_required" and
                 &1["provider_reservation_row_scope"] == "review" and
                 &1["station_reservation_match_status"] == "overlap")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(blocked_artifact)

    review_artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([%{"type" => "priority_commitment", "target_id" => "target_hot"}]),
        strategy_policy: %{
          "mission_value_weight" => 10.0,
          "risk_weight" => 0.0,
          "approval_load_weight" => 0.0
        },
        branches: [
          %{id: "baseline"},
          %{
            id: "request_ready_provider_reservation",
            events: [urgent_target_event, request_ready_event]
          }
        ],
        current_epoch_s: 0.0
      )

    review_branch = branch(review_artifact, "request_ready_provider_reservation")

    assert review_artifact["recommendation"]["recommended_branch_id"] ==
             "request_ready_provider_reservation"

    assert review_branch["approval_status"] == "operator_review_required"

    assert review_artifact["recommendation"]["approval_status"] ==
             "operator_review_required"

    assert Enum.any?(
             review_branch["risk_indicators"],
             &(&1["type"] == "provider_reservation_request_review" and
                 &1["feedback_scope"] == "contact_allocation_provider_reservation_request" and
                 &1["provider_reservation_request_status"] == "request_ready" and
                 &1["provider_reservation_row_scope"] == "request" and
                 &1["station_reservation_match_status"] == "matched")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(review_artifact)
  end
end
