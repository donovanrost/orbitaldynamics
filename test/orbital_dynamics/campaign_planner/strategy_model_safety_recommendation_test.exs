Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyModelSafetyRecommendationTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy recommendation skips branches blocked by model acceptance by default" do
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

    blocked_model_acceptance_event = %{
      type: "model_acceptance_pressure",
      feedback_scope: "model_acceptance",
      feedback_source: "mission_state.source_model_acceptance_report.rows",
      report_id: "model_acceptance_report_v1",
      intended_use: "operational_import",
      model_id: "live_analysis_model",
      validation_level: "operational_import",
      model_status: "blocked",
      model_reason: "model evidence rejected for operational import",
      blocked_count: 1,
      required_operator_action: "review_blocked_model_acceptance",
      derivation_reasons: ["model_acceptance_review"]
    }

    review_model_acceptance_event = %{
      type: "model_acceptance_pressure",
      feedback_scope: "model_acceptance",
      feedback_source: "mission_state.source_model_acceptance_report.rows",
      report_id: "model_acceptance_report_v1",
      intended_use: "operational_import",
      model_id: "analysis_model_review",
      validation_level: "operational_import",
      model_status: "review_required",
      model_reason: "operator review required before promotion",
      review_required_count: 1,
      required_operator_action: "review_model_acceptance",
      derivation_reasons: ["model_acceptance_review"]
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
            id: "model_acceptance_blocked",
            events: [urgent_target_event, blocked_model_acceptance_event]
          }
        ],
        current_epoch_s: 0.0
      )

    blocked_branch = branch(blocked_artifact, "model_acceptance_blocked")

    assert blocked_branch["score_terms"]["mission_value_score"] >
             branch(blocked_artifact, "baseline")["score_terms"]["mission_value_score"]

    assert blocked_artifact["recommendation"]["recommended_branch_id"] == "baseline"
    assert blocked_branch["approval_status"] == "blocked_by_policy"

    assert "model_acceptance_blocked" in blocked_artifact["approval_policy"][
             "blocked_risk_types"
           ]

    assert Enum.any?(
             blocked_branch["risk_indicators"],
             &(&1["type"] == "model_acceptance_pressure" and
                 &1["feedback_scope"] == "model_acceptance" and
                 &1["model_status"] == "blocked" and
                 &1["required_operator_action"] == "review_blocked_model_acceptance")
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
            id: "model_acceptance_review",
            events: [urgent_target_event, review_model_acceptance_event]
          }
        ],
        current_epoch_s: 0.0
      )

    review_branch = branch(review_artifact, "model_acceptance_review")

    assert review_artifact["recommendation"]["recommended_branch_id"] ==
             "model_acceptance_review"

    assert review_branch["approval_status"] == "operator_review_required"

    assert review_artifact["recommendation"]["approval_status"] ==
             "operator_review_required"

    assert Enum.any?(
             review_branch["risk_indicators"],
             &(&1["type"] == "model_acceptance_pressure" and
                 &1["feedback_scope"] == "model_acceptance" and
                 &1["model_status"] == "review_required")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(review_artifact)
  end

  test "strategy recommendation skips branches blocked by validation safety case by default" do
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

    blocked_validation_safety_case_event = %{
      type: "validation_safety_case_pressure",
      feedback_scope: "validation_safety_case",
      feedback_source: "mission_state.source_validation_safety_case_summary.evidence",
      report_id: "validation_safety_case_summary_v1",
      validation_safety_case_status: "blocked",
      evidence_status: "blocked",
      input_contract: "model_acceptance_report.v1",
      evidence_ref: "model.blocked",
      blocked_evidence_count: 1,
      schema_error_count: 1,
      model_blocked_count: 1,
      required_operator_action: "review_blocked_validation_safety_case",
      derivation_reasons: ["validation_safety_case_review"]
    }

    review_validation_safety_case_event = %{
      type: "validation_safety_case_pressure",
      feedback_scope: "validation_safety_case",
      feedback_source: "mission_state.source_validation_safety_case_summary.evidence",
      report_id: "validation_safety_case_summary_v1",
      validation_safety_case_status: "review_required",
      evidence_status: "review_required",
      input_contract: "model_acceptance_report.v1",
      evidence_ref: "model.review",
      review_required_evidence_count: 1,
      required_operator_action: "review_validation_safety_case",
      derivation_reasons: ["validation_safety_case_review"]
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
            id: "validation_safety_case_blocked",
            events: [urgent_target_event, blocked_validation_safety_case_event]
          }
        ],
        current_epoch_s: 0.0
      )

    blocked_branch = branch(blocked_artifact, "validation_safety_case_blocked")

    assert blocked_branch["score_terms"]["mission_value_score"] >
             branch(blocked_artifact, "baseline")["score_terms"]["mission_value_score"]

    assert blocked_artifact["recommendation"]["recommended_branch_id"] == "baseline"
    assert blocked_branch["approval_status"] == "blocked_by_policy"

    assert "validation_safety_case_blocked" in blocked_artifact["approval_policy"][
             "blocked_risk_types"
           ]

    assert Enum.any?(
             blocked_branch["risk_indicators"],
             &(&1["type"] == "validation_safety_case_pressure" and
                 &1["feedback_scope"] == "validation_safety_case" and
                 &1["evidence_status"] == "blocked" and
                 &1["blocked_evidence_count"] == 1 and
                 &1["schema_error_count"] == 1 and
                 &1["required_operator_action"] == "review_blocked_validation_safety_case")
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
            id: "validation_safety_case_review",
            events: [urgent_target_event, review_validation_safety_case_event]
          }
        ],
        current_epoch_s: 0.0
      )

    review_branch = branch(review_artifact, "validation_safety_case_review")

    assert review_artifact["recommendation"]["recommended_branch_id"] ==
             "validation_safety_case_review"

    assert review_branch["approval_status"] == "operator_review_required"

    assert review_artifact["recommendation"]["approval_status"] ==
             "operator_review_required"

    assert Enum.any?(
             review_branch["risk_indicators"],
             &(&1["type"] == "validation_safety_case_pressure" and
                 &1["feedback_scope"] == "validation_safety_case" and
                 &1["evidence_status"] == "review_required")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(review_artifact)
  end
end
