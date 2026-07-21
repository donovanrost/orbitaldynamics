Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyContactFilterReplayRecommendationTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy recommendation skips unavailable-station contact-filter replay by default" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [],
        "candidate_activities" => []
      })

    urgent_target_event = %{
      type: "urgent_target",
      target_id: "target_a",
      starts_at_s: 500.0,
      ends_at_s: 560.0,
      priority: 20.0,
      candidate_windows: [
        %{
          id: "candidate_obs_hot",
          type: "observe",
          target_id: "target_a",
          scenario_id: "leo_1",
          starts_at_s: 500.0,
          ends_at_s: 560.0,
          duration_s: 60.0,
          score: 10.0
        }
      ]
    }

    unavailable_report = contact_filter_report(:unavailable, :unavailable_contact_filter)
    reserved_report = contact_filter_report(:reserved, :reserved_contact_filter)

    assert {:ok, %{"schema_contract" => "contact_filter_report.v1"}} =
             Schema.validate_artifact(unavailable_report)

    assert {:ok, %{"schema_contract" => "contact_filter_report.v1"}} =
             Schema.validate_artifact(reserved_report)

    blocked_artifact =
      strategy(prior_plan,
        mission_state:
          mission_state_with_refresh_inputs()
          |> Map.put(:objectives, [%{"type" => "priority_commitment", "target_id" => "target_a"}])
          |> Map.put("source_contact_filter_report", unavailable_report),
        strategy_policy: %{
          "mission_value_weight" => 10.0,
          "risk_weight" => 0.0,
          "approval_load_weight" => 0.0
        },
        approval_policy: %{"operator_review_risk_limit" => 10},
        branches: [
          %{id: "baseline"},
          %{id: "unavailable_contact_filter", events: [urgent_target_event]}
        ],
        current_epoch_s: 0.0
      )

    blocked_branch = branch(blocked_artifact, "unavailable_contact_filter")

    assert blocked_branch["score_terms"]["mission_value_score"] >
             branch(blocked_artifact, "baseline")["score_terms"]["mission_value_score"]

    assert blocked_artifact["recommendation"]["recommended_branch_id"] == "baseline"
    assert blocked_branch["approval_status"] == "blocked_by_policy"

    assert %{
             "schema_contract" => "policy_decision.v1",
             "classification" => "blocked_by_policy",
             "fallback_policy" => %{"blocked_risk_types" => blocked_risk_types}
           } = blocked_branch["policy_decision"]

    assert "contact_filter_blocked" in blocked_risk_types

    assert Enum.any?(
             blocked_branch["risk_indicators"],
             &(&1["type"] == "downlink_completion_gap" and
                 &1["feedback_scope"] == "contact_filter" and
                 &1["station_suppression_availability_counts"] == %{"unavailable" => 1})
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(blocked_artifact)

    review_artifact =
      strategy(prior_plan,
        mission_state:
          mission_state_with_refresh_inputs()
          |> Map.put(:objectives, [%{"type" => "priority_commitment", "target_id" => "target_a"}])
          |> Map.put("source_contact_filter_report", reserved_report),
        strategy_policy: %{
          "mission_value_weight" => 10.0,
          "risk_weight" => 0.0,
          "approval_load_weight" => 0.0
        },
        approval_policy: %{"operator_review_risk_limit" => 10},
        branches: [
          %{id: "baseline"},
          %{id: "reserved_contact_filter", events: [urgent_target_event]}
        ],
        current_epoch_s: 0.0
      )

    review_branch = branch(review_artifact, "reserved_contact_filter")

    assert review_artifact["recommendation"]["recommended_branch_id"] ==
             "reserved_contact_filter"

    assert review_branch["approval_status"] == "operator_review_required"
    assert review_artifact["recommendation"]["approval_status"] == "operator_review_required"

    assert Enum.any?(
             review_branch["risk_indicators"],
             &(&1["type"] == "downlink_completion_gap" and
                 &1["feedback_scope"] == "contact_filter" and
                 &1["station_suppression_availability_counts"] == %{"reserved" => 1})
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(review_artifact)
  end

  defp contact_filter_report(station_status, boundary) do
    OrbitalDynamics.contact_filter_report(
      [
        %{
          id: :dl_contact_filter,
          type: :downlink,
          scenario_id: :leo_1,
          ground_station_id: :equator_prime,
          starts_at_s: 100.0,
          ends_at_s: 160.0
        }
      ],
      [
        %{
          ground_station_id: :equator_prime,
          status: station_status,
          starts_at_s: 90.0,
          ends_at_s: 170.0,
          trust_boundary: boundary
        }
      ]
    )
    |> Map.put("provenance", %{"trust_boundary" => Atom.to_string(boundary)})
  end
end
