Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyScoreTermPressureTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "readiness and quality-gate pressure penalize otherwise equal strategy branches" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [],
        "candidate_activities" => []
      })

    urgent_event = %{
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

    readiness_event = %{
      type: "operational_readiness_pressure",
      report_id: "operational_readiness:resource_projection_report.v1:live_ops",
      source_artifact_type: "resource_projection_report.v1",
      source_artifact_id: "live_ops",
      readiness_level: "operator_review",
      import_classification: "review_only",
      operational_readiness_status: "review_required",
      readiness_gate_id: "operator_training",
      readiness_gate_status: "review_required",
      readiness_gate_classification: "review_only",
      readiness_gate_reason: "operator training requires role-qualified review",
      required_operator_action: "review_operational_readiness",
      feedback_source: "mission_state.source_operational_readiness_report.gates",
      feedback_scope: "operational_readiness",
      feedback_key: "operator_training",
      trust_boundary: "mission_state_operational_readiness_report"
    }

    quality_gate_event = %{
      type: "quality_gate_pressure",
      report_id: "quality_gate:resource_projection_report.v1:live_ops",
      source_artifact_type: "resource_projection_report.v1",
      source_artifact_id: "live_ops",
      source_readiness_report_id: "operational_readiness:resource_projection_report.v1:live_ops",
      readiness_level: "operator_review",
      import_classification: "review_only",
      quality_gate_status: "review_required",
      gate_id: "resource_availability",
      gate_status: "review_required",
      gate_classification: "review_only",
      gate_reason: "resource availability evidence requires operator review before import",
      required_operator_action: "review_operational_readiness",
      feedback_source: "mission_state.source_quality_gate_report.rows",
      feedback_scope: "quality_gate",
      feedback_key: "resource_availability",
      trust_boundary: "mission_state_quality_gate_report",
      resource_availability_reason_ids: ["antenna_unavailable", "payload_unavailable"]
    }

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([%{"type" => "priority_commitment", "target_id" => "target_hot"}]),
        strategy_policy: %{
          "mission_value_weight" => 10.0,
          "risk_weight" => 5.0,
          "approval_load_weight" => 0.0
        },
        approval_policy: %{
          "blocked_risk_types" => [],
          "operator_review_risk_limit" => 10
        },
        branches: [
          %{id: "baseline"},
          %{id: "urgent_clean", events: [urgent_event]},
          %{id: "urgent_pressure", events: [urgent_event, readiness_event, quality_gate_event]}
        ],
        current_epoch_s: 0.0
      )

    assert artifact["recommendation"]["recommended_branch_id"] == "urgent_clean"

    clean_branch = branch(artifact, "urgent_clean")
    pressure_branch = branch(artifact, "urgent_pressure")

    assert clean_branch["score_terms"]["contact_allocation_pressure_penalty"] == 0.0
    assert clean_branch["score_terms"]["approval_boundary_pressure_penalty"] == 0.0
    assert clean_branch["score_terms"]["risk_penalty"] == -5.0
    assert pressure_branch["score_terms"]["contact_allocation_pressure_penalty"] == 0.0

    quality_gate_pressure_count =
      Enum.count(
        pressure_branch["risk_indicators"],
        &(&1["type"] == "quality_gate_pressure")
      )

    assert quality_gate_pressure_count == 1

    assert_operator_training_pressure_score_terms(pressure_branch, artifact, 1)
    assert_resource_availability_pressure_score_terms(pressure_branch, artifact, 1)

    assert pressure_branch["score"] < clean_branch["score"]

    assert %{
             "type" => "operational_readiness_pressure",
             "severity" => "medium",
             "report_id" => "operational_readiness:resource_projection_report.v1:live_ops",
             "readiness_gate_id" => "operator_training",
             "required_operator_action" => "review_operational_readiness",
             "trust_boundary" => "mission_state_operational_readiness_report"
           } =
             Enum.find(
               pressure_branch["risk_indicators"],
               &(&1["type"] == "operational_readiness_pressure")
             )

    assert %{
             "type" => "quality_gate_pressure",
             "severity" => "medium",
             "report_id" => "quality_gate:resource_projection_report.v1:live_ops",
             "gate_id" => "resource_availability",
             "resource_availability_reason_ids" => [
               "antenna_unavailable",
               "payload_unavailable"
             ],
             "trust_boundary" => "mission_state_quality_gate_report"
           } =
             Enum.find(
               pressure_branch["risk_indicators"],
               &(&1["type"] == "quality_gate_pressure")
             )

    pressure_comparison =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "urgent_pressure"))

    assert pressure_comparison["risk_count"] == 3
    assert "operational_readiness_pressure" in pressure_comparison["risk_types"]
    assert "quality_gate_pressure" in pressure_comparison["risk_types"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)

    assert {:ok, %{"schema_contract" => "branch_comparison_report.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact["branch_comparison_report"])
  end

  test "approval-boundary pressure uses dedicated strategy score terms" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [],
        "candidate_activities" => []
      })

    urgent_event = %{
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

    approval_boundary_event = %{
      type: "approval_boundary_pressure",
      approval_boundary: "recommendations_only_no_command_execution",
      approval_boundary_status: "operator_review_required",
      approval_boundary_reason: "command execution requires flight director approval",
      automation_boundary: "no_command_execution",
      execution_boundary: "artifact_only_no_execution",
      import_classification: "review_only",
      required_operator_action: "review_command_execution_boundary",
      required_authority: "flight_director",
      policy_bundle_id: "mission_ops_approval_v1",
      rule_id: "command_execution_boundary",
      feedback_source: "mission_state.approval_boundary",
      feedback_scope: "approval_boundary",
      feedback_key: "command_execution",
      trust_boundary: "mission_state_approval_boundary"
    }

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([%{"type" => "priority_commitment", "target_id" => "target_hot"}]),
        strategy_policy: %{
          "mission_value_weight" => 10.0,
          "risk_weight" => 5.0,
          "approval_load_weight" => 0.0
        },
        approval_policy: %{
          "blocked_risk_types" => [],
          "operator_review_risk_limit" => 10
        },
        branches: [
          %{id: "baseline"},
          %{id: "urgent_clean", events: [urgent_event]},
          %{id: "urgent_approval_boundary", events: [urgent_event, approval_boundary_event]}
        ],
        current_epoch_s: 0.0
      )

    clean_branch = branch(artifact, "urgent_clean")
    pressure_branch = branch(artifact, "urgent_approval_boundary")

    approval_boundary_pressure_count =
      Enum.count(
        pressure_branch["risk_indicators"],
        &(&1["type"] == "approval_boundary_pressure")
      )

    assert approval_boundary_pressure_count == 1

    assert pressure_branch["score_terms"]["approval_boundary_pressure_penalty"] ==
             -approval_boundary_pressure_count * 5.0

    assert pressure_branch["score_terms"]["risk_penalty"] ==
             -(length(pressure_branch["risk_indicators"]) - approval_boundary_pressure_count) *
               5.0

    assert clean_branch["score_terms"]["approval_boundary_pressure_penalty"] == 0.0
    assert pressure_branch["score"] < clean_branch["score"]

    assert %{
             "type" => "approval_boundary_pressure",
             "severity" => "medium",
             "approval_boundary" => "recommendations_only_no_command_execution",
             "approval_boundary_status" => "operator_review_required",
             "automation_boundary" => "no_command_execution",
             "execution_boundary" => "artifact_only_no_execution",
             "required_operator_action" => "review_command_execution_boundary",
             "required_authority" => "flight_director",
             "trust_boundary" => "mission_state_approval_boundary",
             "reason" => "command execution requires flight director approval"
           } =
             Enum.find(
               pressure_branch["risk_indicators"],
               &(&1["type"] == "approval_boundary_pressure")
             )

    assert "approval_boundary_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == "urgent_approval_boundary" and
                 &1["term_key"] == "approval_boundary_pressure_penalty" and &1["value"] < 0.0)
           )

    pressure_comparison =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "urgent_approval_boundary"))

    assert "approval_boundary_pressure" in pressure_comparison["risk_types"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  defp assert_operator_training_pressure_score_terms(
         branch,
         artifact,
         extra_split_pressure_count
       ) do
    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    operator_training_pressure_count =
      Enum.count(
        branch["risk_indicators"],
        &operator_training_source_report_pressure?(&1)
      )

    assert operator_training_pressure_count > 0

    assert branch["score_terms"]["operator_training_pressure_penalty"] ==
             -operator_training_pressure_count * risk_weight

    assert branch["score_terms"]["quality_gate_pressure_penalty"] == 0.0

    assert branch["score_terms"]["risk_penalty"] ==
             -(length(branch["risk_indicators"]) -
                 operator_training_pressure_count - extra_split_pressure_count) *
               risk_weight

    assert "operator_training_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == branch["branch_id"] and
                 &1["term_key"] == "operator_training_pressure_penalty" and &1["value"] < 0.0)
           )
  end

  defp assert_resource_availability_pressure_score_terms(
         branch,
         artifact,
         extra_split_pressure_count
       ) do
    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    resource_availability_pressure_count =
      Enum.count(
        branch["risk_indicators"],
        &(&1["type"] in [
            "resource_unavailable",
            "spacecraft_unavailable",
            "payload_unavailable",
            "spacecraft_degraded_payload_unavailable",
            "activity_type_suppressed_by_resource_summary",
            "activity_type_incompatible_with_resource_summary",
            "antenna_unavailable"
          ] or resource_availability_source_report_pressure?(&1))
      )

    assert resource_availability_pressure_count > 0

    assert branch["score_terms"]["resource_availability_pressure_penalty"] ==
             -resource_availability_pressure_count * risk_weight

    assert branch["score_terms"]["quality_gate_pressure_penalty"] == 0.0

    assert branch["score_terms"]["risk_penalty"] ==
             -(length(branch["risk_indicators"]) -
                 resource_availability_pressure_count - extra_split_pressure_count) *
               risk_weight

    assert "resource_availability_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == branch["branch_id"] and
                 &1["term_key"] == "resource_availability_pressure_penalty" and
                 &1["value"] < 0.0)
           )
  end

  defp resource_availability_source_report_pressure?(%{"type" => "quality_gate_pressure"} = risk) do
    risk["gate_id"] == "resource_availability" or
      is_map(risk["resource_availability_reason_counts"]) or
      is_map(risk["unavailable_resource_reason_counts"]) or
      is_map(risk["blocked_contact_ids_by_blocking_dimension"])
  end

  defp resource_availability_source_report_pressure?(
         %{"type" => "operational_readiness_pressure"} = risk
       ) do
    risk["readiness_gate_id"] == "resource_availability" or
      is_map(risk["resource_availability_reason_counts"]) or
      is_map(risk["unavailable_resource_reason_counts"]) or
      is_map(risk["blocked_contact_ids_by_blocking_dimension"])
  end

  defp resource_availability_source_report_pressure?(_risk), do: false

  defp operator_training_source_report_pressure?(%{"type" => "quality_gate_pressure"} = risk) do
    risk["gate_id"] == "operator_training" or
      risk["operator_training_requirement_count"] not in [nil, 0] or
      is_map(risk["operator_training_requirement_counts"])
  end

  defp operator_training_source_report_pressure?(
         %{"type" => "operational_readiness_pressure"} = risk
       ) do
    risk["readiness_gate_id"] == "operator_training" or
      risk["operator_training_requirement_count"] not in [nil, 0] or
      is_map(risk["operator_training_requirement_counts"]) or
      risk["required_operator_roles"] not in [nil, []] or
      risk["required_training_ids"] not in [nil, []] or
      risk["required_certification_ids"] not in [nil, []] or
      risk["required_qualification_ids"] not in [nil, []]
  end

  defp operator_training_source_report_pressure?(_risk), do: false
end
