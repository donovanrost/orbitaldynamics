Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyValidationRefreshBudgetRecommendationTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy recommendation skips branches blocked by schema validation errors by default" do
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

    error_schema_validation_event = %{
      type: "schema_validation_pressure",
      feedback_scope: "schema_validation",
      feedback_source: "mission_state.source_schema_validation_report.errors",
      validation_status: "fail",
      validation_mode: "artifact_contract",
      validated_contract: "candidate_refresh.v1",
      validated_artifact_family: "candidate_refresh",
      artifact_path: "study_results/candidate_refresh.json",
      issue_severity: "error",
      issue_path: "$.candidate_activities[0].starts_at_s",
      issue_message: "starts_at_s must be numeric",
      error_count: 1,
      warning_count: 0,
      required_operator_action: "review_schema_validation",
      derivation_reasons: ["schema_validation_review"]
    }

    warning_schema_validation_event = %{
      type: "schema_validation_pressure",
      feedback_scope: "schema_validation",
      feedback_source: "mission_state.source_schema_validation_report.warnings",
      validation_status: "warning",
      validation_mode: "artifact_contract",
      validated_contract: "candidate_refresh.v1",
      validated_artifact_family: "candidate_refresh",
      artifact_path: "study_results/candidate_refresh.json",
      issue_severity: "warning",
      issue_path: "$.metadata.review_hint",
      issue_message: "review hint is advisory",
      error_count: 0,
      warning_count: 1,
      required_operator_action: "review_schema_validation",
      derivation_reasons: ["schema_validation_review"]
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
            id: "schema_validation_error",
            events: [urgent_target_event, error_schema_validation_event]
          }
        ],
        current_epoch_s: 0.0
      )

    blocked_branch = branch(blocked_artifact, "schema_validation_error")

    assert blocked_branch["score_terms"]["mission_value_score"] >
             branch(blocked_artifact, "baseline")["score_terms"]["mission_value_score"]

    assert blocked_artifact["recommendation"]["recommended_branch_id"] == "baseline"
    assert blocked_branch["approval_status"] == "blocked_by_policy"

    assert "schema_validation_blocked" in blocked_artifact["approval_policy"][
             "blocked_risk_types"
           ]

    assert Enum.any?(
             blocked_branch["risk_indicators"],
             &(&1["type"] == "schema_validation_pressure" and
                 &1["feedback_scope"] == "schema_validation" and
                 &1["validation_status"] == "fail" and
                 &1["issue_severity"] == "error" and
                 &1["error_count"] == 1)
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
            id: "schema_validation_warning",
            events: [urgent_target_event, warning_schema_validation_event]
          }
        ],
        current_epoch_s: 0.0
      )

    review_branch = branch(review_artifact, "schema_validation_warning")

    assert review_artifact["recommendation"]["recommended_branch_id"] ==
             "schema_validation_warning"

    assert review_branch["approval_status"] == "operator_review_required"

    assert review_artifact["recommendation"]["approval_status"] ==
             "operator_review_required"

    assert Enum.any?(
             review_branch["risk_indicators"],
             &(&1["type"] == "schema_validation_pressure" and
                 &1["feedback_scope"] == "schema_validation" and
                 &1["validation_status"] == "warning" and
                 &1["issue_severity"] == "warning")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(review_artifact)
  end

  test "strategy recommendation skips branches blocked by invalid refresh budget by default" do
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

    invalid_refresh_budget_event = %{
      type: "refresh_budget_pressure",
      feedback_scope: "refresh_budget",
      feedback_source: "mission_state.source_refresh_budget_report",
      input_candidate_count: 4,
      kept_candidate_count: 2,
      dropped_candidate_count: 2,
      current_max_candidate_activities: 2,
      relaxed_max_candidate_activities: 4,
      refresh_budget_status: "invalid",
      candidate_limit_status: "invalid",
      invalid_candidate_limit_policy: true,
      invalid_candidate_limit_policy_count: 1,
      invalid_candidate_limit_policy_reason: "max_candidate_activities_must_be_integer",
      branch_local_budget_pressure: true,
      branch_local_dropped_candidate_pressure: true,
      branch_local_invalid_limit_pressure: true,
      branch_local_candidate_limit_applied: true,
      required_operator_action: "review_refresh_budget",
      derivation_reasons: ["refresh_budget_candidate_limit_pressure"]
    }

    dropped_refresh_budget_event = %{
      type: "refresh_budget_pressure",
      feedback_scope: "refresh_budget",
      feedback_source: "mission_state.source_refresh_budget_report",
      input_candidate_count: 4,
      kept_candidate_count: 2,
      dropped_candidate_count: 2,
      current_max_candidate_activities: 2,
      relaxed_max_candidate_activities: 4,
      refresh_budget_status: "dropped",
      candidate_limit_status: "dropped",
      invalid_candidate_limit_policy: false,
      invalid_candidate_limit_policy_count: 0,
      branch_local_budget_pressure: true,
      branch_local_dropped_candidate_pressure: true,
      branch_local_candidate_limit_applied: true,
      required_operator_action: "review_refresh_budget",
      derivation_reasons: ["refresh_budget_candidate_limit_pressure"]
    }

    limited_refresh_budget_event = %{
      type: "refresh_budget_pressure",
      feedback_scope: "refresh_budget",
      feedback_source: "mission_state.source_refresh_budget_report",
      input_candidate_count: 2,
      kept_candidate_count: 2,
      dropped_candidate_count: 0,
      current_max_candidate_activities: 2,
      relaxed_max_candidate_activities: 2,
      refresh_budget_status: "limited",
      candidate_limit_status: "limited",
      invalid_candidate_limit_policy: false,
      invalid_candidate_limit_policy_count: 0,
      branch_local_budget_pressure: true,
      branch_local_candidate_limit_applied: true,
      required_operator_action: "review_refresh_budget",
      derivation_reasons: ["refresh_budget_candidate_limit_pressure"]
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
            id: "invalid_refresh_budget",
            events: [urgent_target_event, invalid_refresh_budget_event]
          }
        ],
        current_epoch_s: 0.0
      )

    blocked_branch = branch(blocked_artifact, "invalid_refresh_budget")

    assert blocked_branch["score_terms"]["mission_value_score"] >
             branch(blocked_artifact, "baseline")["score_terms"]["mission_value_score"]

    assert blocked_artifact["recommendation"]["recommended_branch_id"] == "baseline"
    assert blocked_branch["approval_status"] == "blocked_by_policy"

    assert "refresh_budget_blocked" in blocked_artifact["approval_policy"][
             "blocked_risk_types"
           ]

    assert Enum.any?(
             blocked_branch["risk_indicators"],
             &(&1["type"] == "refresh_budget_pressure" and
                 &1["feedback_scope"] == "refresh_budget" and
                 &1["refresh_budget_status"] == "invalid" and
                 &1["candidate_limit_status"] == "invalid")
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
            id: "dropped_refresh_budget",
            events: [urgent_target_event, dropped_refresh_budget_event]
          }
        ],
        current_epoch_s: 0.0
      )

    review_branch = branch(review_artifact, "dropped_refresh_budget")

    assert review_artifact["recommendation"]["recommended_branch_id"] ==
             "dropped_refresh_budget"

    assert review_branch["approval_status"] == "operator_review_required"

    assert review_artifact["recommendation"]["approval_status"] ==
             "operator_review_required"

    assert Enum.any?(
             review_branch["risk_indicators"],
             &(&1["type"] == "refresh_budget_pressure" and
                 &1["feedback_scope"] == "refresh_budget" and
                 &1["refresh_budget_status"] == "dropped" and
                 &1["candidate_limit_status"] == "dropped")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(review_artifact)

    limited_artifact =
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
            id: "limited_refresh_budget",
            events: [urgent_target_event, limited_refresh_budget_event]
          }
        ],
        current_epoch_s: 0.0
      )

    limited_branch = branch(limited_artifact, "limited_refresh_budget")

    assert limited_artifact["recommendation"]["recommended_branch_id"] ==
             "limited_refresh_budget"

    assert limited_branch["approval_status"] == "operator_review_required"

    assert Enum.any?(
             limited_branch["risk_indicators"],
             &(&1["type"] == "refresh_budget_pressure" and
                 &1["feedback_scope"] == "refresh_budget" and
                 &1["refresh_budget_status"] == "limited" and
                 &1["candidate_limit_status"] == "limited")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(limited_artifact)
  end
end
