Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyReadinessRecommendationTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy recommendation skips branches blocked by readiness and quality gates by default" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [],
        "candidate_activities" => []
      })

    blocked_readiness_event = %{
      type: "operational_readiness_pressure",
      report_id: "operational_readiness:planned_activity.v1:blocking_gate",
      source_artifact_type: "planned_activity.v1",
      source_artifact_id: "blocking_gate",
      readiness_level: "blocked",
      import_classification: "blocked",
      operational_readiness_status: "blocked",
      gate_count: 1,
      passed_gate_count: 0,
      review_gate_count: 0,
      analysis_gate_count: 0,
      blocked_gate_count: 1,
      readiness_gate_id: "execution_boundary",
      readiness_gate_status: "blocked",
      readiness_gate_classification: "blocked",
      readiness_gate_reason: "execution boundary blocks import",
      required_operator_action: "review_blocked_operational_readiness",
      feedback_source: "mission_state.source_operational_readiness_report.gates",
      feedback_scope: "operational_readiness",
      feedback_key: "execution_boundary",
      trust_boundary: "mission_state_operational_readiness_report"
    }

    blocked_quality_gate_event = %{
      type: "quality_gate_pressure",
      report_id: "quality_gate:planned_activity.v1:blocking_gate",
      source_artifact_type: "planned_activity.v1",
      source_artifact_id: "blocking_gate",
      source_readiness_report_id: "operational_readiness:planned_activity.v1:blocking_gate",
      readiness_level: "blocked",
      import_classification: "blocked",
      quality_gate_status: "blocked",
      gate_count: 1,
      passed_gate_count: 0,
      review_gate_count: 0,
      analysis_gate_count: 0,
      blocked_gate_count: 1,
      gate_id: "cadence_import",
      gate_status: "blocked",
      gate_classification: "blocked",
      gate_reason: "quality gate blocks import",
      required_operator_action: "review_blocked_operational_readiness",
      feedback_source: "mission_state.source_quality_gate_report.rows",
      feedback_scope: "quality_gate",
      feedback_key: "cadence_import",
      trust_boundary: "mission_state_quality_gate_report"
    }

    for {branch_id, event, risk_type, blocked_risk_type} <- [
          {"readiness_blocked", blocked_readiness_event, "operational_readiness_pressure",
           "operational_readiness_blocked"},
          {"quality_gate_blocked", blocked_quality_gate_event, "quality_gate_pressure",
           "quality_gate_blocked"}
        ] do
      artifact =
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
              id: branch_id,
              events: [
                %{
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
                },
                event
              ]
            }
          ],
          current_epoch_s: 0.0
        )

      blocked_branch = branch(artifact, branch_id)

      comparison_row =
        Enum.find(artifact["branch_comparison_report"]["rows"], &(&1["branch_id"] == branch_id))

      assert blocked_branch["score_terms"]["mission_value_score"] >
               branch(artifact, "baseline")["score_terms"]["mission_value_score"]

      assert artifact["recommendation"]["recommended_branch_id"] == "baseline"
      assert blocked_branch["approval_status"] == "blocked_by_policy"
      assert blocked_risk_type in artifact["approval_policy"]["blocked_risk_types"]
      assert risk_type in comparison_row["risk_types"]
      assert comparison_row["selected"] == false

      assert Enum.any?(
               blocked_branch["risk_indicators"],
               &(&1["type"] == risk_type and &1["severity"] == "high")
             )

      assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
               Schema.validate_artifact(artifact)
    end
  end

  test "strategy recommendation skips branches blocked by import readiness by default" do
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

    blocked_readiness_import_event = %{
      type: "operational_readiness_pressure",
      report_id: "operational_readiness:planned_activity.v1:import_blocked",
      source_artifact_type: "planned_activity.v1",
      source_artifact_id: "import_blocked",
      readiness_level: "operator_review",
      import_classification: "review_only",
      operational_readiness_status: "review_required",
      gate_count: 1,
      passed_gate_count: 0,
      review_gate_count: 1,
      analysis_gate_count: 0,
      blocked_gate_count: 0,
      readiness_gate_id: "cadence_import",
      readiness_gate_status: "review_required",
      readiness_gate_classification: "review_only",
      readiness_gate_reason: "Cadence import row is blocked by missing import evidence",
      import_blocked: true,
      blocked_import_count: 1,
      invalid_cadence_import_count: 0,
      import_status_counts: %{"blocked_missing_cadence_import" => 1},
      cadence_import_status_counts: %{"missing" => 1},
      blocked_import_quality_gate_row_ids: ["quality_gate:cadence_import:missing"],
      required_operator_action: "review_operational_readiness",
      feedback_source: "mission_state.source_operational_readiness_report.gates",
      feedback_scope: "operational_readiness",
      feedback_key: "cadence_import",
      trust_boundary: "mission_state_operational_readiness_report"
    }

    blocked_quality_import_event = %{
      type: "quality_gate_pressure",
      report_id: "quality_gate:planned_activity.v1:import_invalid",
      source_artifact_type: "planned_activity.v1",
      source_artifact_id: "import_invalid",
      source_readiness_report_id: "operational_readiness:planned_activity.v1:import_invalid",
      readiness_level: "operator_review",
      import_classification: "review_only",
      quality_gate_status: "review_required",
      gate_count: 1,
      passed_gate_count: 0,
      review_gate_count: 1,
      analysis_gate_count: 0,
      blocked_gate_count: 0,
      gate_id: "cadence_import",
      gate_status: "review_required",
      gate_classification: "review_only",
      gate_reason: "Cadence import row is invalid",
      import_blocked: true,
      blocked_import_count: 0,
      invalid_cadence_import_count: 1,
      import_status_counts: %{"review_required_before_import" => 1},
      cadence_import_status_counts: %{"invalid" => 1},
      blocked_import_quality_gate_row_ids: ["quality_gate:cadence_import:invalid"],
      required_operator_action: "review_operational_readiness",
      feedback_source: "mission_state.source_quality_gate_report.rows",
      feedback_scope: "quality_gate",
      feedback_key: "cadence_import",
      trust_boundary: "mission_state_quality_gate_report"
    }

    for {branch_id, event, risk_type} <- [
          {"readiness_import_blocked", blocked_readiness_import_event,
           "operational_readiness_pressure"},
          {"quality_gate_import_blocked", blocked_quality_import_event, "quality_gate_pressure"}
        ] do
      artifact =
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
            %{id: branch_id, events: [urgent_target_event, event]}
          ],
          current_epoch_s: 0.0
        )

      blocked_branch = branch(artifact, branch_id)

      comparison_row =
        Enum.find(artifact["branch_comparison_report"]["rows"], &(&1["branch_id"] == branch_id))

      assert blocked_branch["score_terms"]["mission_value_score"] >
               branch(artifact, "baseline")["score_terms"]["mission_value_score"]

      assert artifact["recommendation"]["recommended_branch_id"] == "baseline"
      assert blocked_branch["approval_status"] == "blocked_by_policy"
      assert "import_readiness_blocked" in artifact["approval_policy"]["blocked_risk_types"]
      assert risk_type in comparison_row["risk_types"]
      assert comparison_row["selected"] == false

      assert Enum.any?(
               blocked_branch["risk_indicators"],
               &(&1["type"] == risk_type and &1["import_blocked"] == true)
             )

      assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
               Schema.validate_artifact(artifact)
    end

    review_only_invalid_readiness_event = %{
      blocked_readiness_import_event
      | import_blocked: false,
        blocked_import_count: 0,
        invalid_cadence_import_count: 1,
        import_status_counts: %{"review_required_before_import" => 1},
        cadence_import_status_counts: %{"invalid" => 1},
        blocked_import_quality_gate_row_ids: []
    }

    review_only_invalid_quality_event = %{
      blocked_quality_import_event
      | import_blocked: false,
        blocked_import_count: 0,
        invalid_cadence_import_count: 1,
        import_status_counts: %{"review_required_before_import" => 1},
        cadence_import_status_counts: %{"invalid" => 1},
        blocked_import_quality_gate_row_ids: []
    }

    for {branch_id, event, risk_type} <- [
          {"review_only_readiness_import_invalid", review_only_invalid_readiness_event,
           "operational_readiness_pressure"},
          {"review_only_quality_gate_import_invalid", review_only_invalid_quality_event,
           "quality_gate_pressure"}
        ] do
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
            %{id: branch_id, events: [urgent_target_event, event]}
          ],
          current_epoch_s: 0.0
        )

      review_branch = branch(review_artifact, branch_id)

      assert review_artifact["recommendation"]["recommended_branch_id"] == branch_id
      assert review_branch["approval_status"] == "operator_review_required"

      assert review_artifact["recommendation"]["approval_status"] ==
               "operator_review_required"

      assert Enum.any?(
               review_branch["risk_indicators"],
               &(&1["type"] == risk_type and
                   &1["import_blocked"] == false and
                   &1["invalid_cadence_import_count"] == 1 and
                   &1["import_status_counts"] == %{"review_required_before_import" => 1})
             )

      assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
               Schema.validate_artifact(review_artifact)
    end
  end
end
