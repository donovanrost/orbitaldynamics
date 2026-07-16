defmodule OrbitalDynamics.OperatorReview.StrategyArtifactTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{OperatorReview, Schema}

  test "builds strategy review package from recommendation risks approvals and branch warnings" do
    package =
      OperatorReview.from_strategy_artifact(%{
        "strategy_metadata" => %{"strategy_id" => "strategy:1"},
        "operational_feedback_provenance" => %{
          "model" => "deterministic_merge_explicit_overrides_mission_state_overrides_prior_plan",
          "input_keys" => ["contact_success_rate", "station_throughput_factor"],
          "source_count" => 1,
          "sources" => [
            %{
              "source" => "request.operational_feedback",
              "input_keys" => ["contact_success_rate", "station_throughput_factor"],
              "trust_boundary_status" => "declared",
              "trust_boundary" => "cadence_feedback_adapter"
            }
          ]
        },
        "recommendation" => %{
          "recommended_branch_id" => "urgent",
          "approval_status" => "operator_review_required",
          "reason" => "best_expected_score_requiring_operator_review",
          "ranked_branch_ids" => ["urgent", "baseline"],
          "requires_approval" => [
            %{
              "schema_contract" => "approval_requirement.v1",
              "activity_id" => "obs_urgent",
              "activity_type" => "observe",
              "action" => "approve_strategic_addition",
              "requirement_type" => "strategic_addition",
              "reason" => "urgent_high_priority_target_inserted",
              "activity_context" => %{
                "target_id" => "target_hot",
                "source_window_id" => "window:target_hot",
                "target_priority" => 4.0,
                "observation_success_factor" => 0.5,
                "contact_success_factor" => 0.4,
                "contact_success_factor_source" =>
                  "operational_feedback.contact_success_rate.station"
              },
              "candidate_diff" => %{
                "invalidated_candidate_id" => "obs_old",
                "invalidated_candidate_ids" => ["obs_old", "obs_old_copy"],
                "replacement_candidate_id" => "obs_urgent",
                "invalidated_reason" => "ambiguous_candidate_diff_match",
                "candidate_diff_match_status" => "ambiguous_replacement_candidate_diff",
                "candidate_diff_match_count" => 2,
                "candidate_budget_match_status" => "budget_dropped_replacement_candidate",
                "candidate_budget_match_count" => 1,
                "budget_dropped_candidate_ids" => ["obs_urgent"],
                "semantic_change_reasons" => ["source_window_id_changed"]
              }
            }
          ],
          "risks_remaining" => [
            %{
              "type" => "urgent_target",
              "severity" => "medium",
              "reason" => "urgent target",
              "activity_id" => "obs_urgent",
              "scenario_id" => "leo_1",
              "target_id" => "target_hot",
              "collection_id" => "collection_hot",
              "product_id" => "product_hot",
              "payload_id" => "payload_hot",
              "instrument_id" => "instrument_hot",
              "objective_id" => "objective:latency_hot",
              "objective_type" => "collection_latency",
              "latency_objective" => true,
              "max_latency_s" => 180.0,
              "planned_latency_s" => 420.0,
              "required_downlink_mb" => 30.0,
              "planned_downlink_mb" => 0.0,
              "source_activity_ids" => ["obs_hot"],
              "maneuver_id" => "burn_uncertain",
              "execution_uncertainty_status" => "declared",
              "execution_uncertainty_source" => "provider_execution_covariance",
              "timing_3sigma_s" => 75.0,
              "delta_v_3sigma_magnitude_km_s" => 0.002,
              "feedback_source" => "prior_plan.source_objective_satisfaction_report",
              "feedback_scope" => "objective_satisfaction",
              "direction" => "downlink",
              "source_window_id" => "window:leo_1:ground_station_access:equator_prime:risk",
              "source_window_type" => "ground_station_access",
              "ground_station_id" => "equator_prime",
              "station_calendar_entry_id" => "station_calendar_entry_1",
              "station_calendar_directions" => ["command"]
            }
          ],
          "tradeoffs" => [
            %{
              "dimension" => "expected_score",
              "baseline" => 50.0,
              "recommended" => 75.0,
              "delta" => 25.0
            },
            %{"dimension" => "risk_count", "baseline" => 0, "recommended" => 1, "delta" => 1}
          ],
          "explanation" => [
            %{
              "type" => "branch_event_summary",
              "branch_event_count" => 2,
              "branch_event_types" => ["downlink_completion_gap"],
              "branch_event_trust_boundary_status_counts" => %{"declared" => 1, "missing" => 1},
              "capacity_pack_group_ids" => ["station:equator_prime:pack:review"],
              "capacity_pack_statuses" => ["deferred_by_reduced_station_capacity_pack"],
              "capacity_pack_min_capacity_fraction" => 0.5,
              "capacity_pack_max_used_fraction" => 0.5,
              "capacity_pack_max_required_capacity_fraction" => 0.25,
              "capacity_pack_total_required_capacity_fraction" => 0.35,
              "capacity_pack_required_capacity_sources" => [
                "contact_required_capacity_fraction",
                "default_reduced_capacity_policy"
              ]
            }
          ]
        },
        "ranking_comparison_report" => %{
          "schema_contract" => "ranking_comparison_report.v1",
          "model" => "scenario_ranking_pairwise_delta",
          "source" => "campaign_strategy.branch_comparison_report",
          "objective" => "strategy_branch_score",
          "objective_direction" => "maximize",
          "left_label" => "normalized_branch_order",
          "right_label" => "score_ranked_branches",
          "left_count" => 2,
          "right_count" => 2,
          "matched_count" => 2,
          "left_only_count" => 0,
          "right_only_count" => 0,
          "row_count" => 2,
          "winner" => %{
            "left_scenario_id" => "urgent",
            "right_scenario_id" => "baseline",
            "changed" => true
          },
          "rows" => [
            %{
              "scenario_id" => "baseline",
              "status" => "matched",
              "left_rank" => 2,
              "right_rank" => 1,
              "rank_delta" => 1,
              "left_value" => 50.0,
              "right_value" => 75.0,
              "value_delta" => 25.0
            },
            %{
              "scenario_id" => "urgent",
              "status" => "matched",
              "left_rank" => 1,
              "right_rank" => 2,
              "rank_delta" => -1,
              "left_value" => 75.0,
              "right_value" => 50.0,
              "value_delta" => -25.0
            }
          ],
          "assumptions" => %{"rank_source" => "input_order"}
        },
        "branches" => [
          %{
            "branch_id" => "urgent",
            "warnings" => ["resource margin low"],
            "resource_projection_report" => %{
              "schema_contract" => "resource_projection_report.v1",
              "model" => "thin_strategy_branch_activity_resource_projection",
              "projected_resources" => [
                %{
                  "spacecraft_id" => "leo_1",
                  "activity_count" => 1,
                  "downlink_count" => 1,
                  "estimated_downlink_mb" => 60.0,
                  "downlink_capacity_mb" => 10.0,
                  "projected_downlink_margin" => 0.0,
                  "projected_downlink_shortfall_mb" => 50.0,
                  "approval_status" => "blocked_by_policy",
                  "activity_resource_flow" => [
                    %{
                      "activity_id" => "urgent_downlink_allocated",
                      "activity_type" => "downlink",
                      "starts_at_s" => 620.0,
                      "downlink_shortfall_mb" => 50.0
                    }
                  ]
                }
              ]
            },
            "repair_result" => %{
              "source_resource_filter_report" => %{
                "schema_contract" => "resource_filter_report.v1",
                "model" => "resource_summary_availability_and_margin_filter",
                "input_candidate_count" => 2,
                "kept_candidate_count" => 1,
                "suppressed_candidate_count" => 1,
                "suppressed_candidates" => [
                  %{
                    "id" => "urgent_downlink_suppressed",
                    "type" => "downlink",
                    "scenario_id" => "leo_1",
                    "starts_at_s" => 500.0,
                    "ends_at_s" => 620.0,
                    "ground_station_id" => "equator_prime",
                    "station_availability" => "available",
                    "suppressed_reason" => "downlink_margin_below_policy",
                    "source_window_id" => "window:leo_1:ground_station_access:equator_prime:3"
                  }
                ]
              },
              "source_contact_filter_report" => %{
                "schema_contract" => "contact_filter_report.v1",
                "model" => "ground_station_availability_filter",
                "input_contact_count" => 2,
                "kept_candidate_count" => 1,
                "suppressed_candidate_count" => 1,
                "suppressed_candidates" => [
                  %{
                    "id" => "urgent_downlink_contact_suppressed",
                    "type" => "downlink",
                    "scenario_id" => "leo_1",
                    "starts_at_s" => 450.0,
                    "ends_at_s" => 510.0,
                    "ground_station_id" => "equator_prime",
                    "station_availability" => "unavailable",
                    "suppressed_reason" => "ground_station_unavailable",
                    "source_window_id" => "window:leo_1:ground_station_access:equator_prime:2"
                  }
                ]
              },
              "source_contact_allocation_report" => %{
                "schema_contract" => "contact_allocation_report.v1",
                "model" => "deterministic_station_contact_allocation",
                "source" => "candidate_refresh.candidate_activities",
                "input_contact_count" => 2,
                "allocated_contact_count" => 1,
                "deferred_contact_count" => 1,
                "blocked_contact_count" => 0,
                "rows" => [
                  %{
                    "id" => "contact_allocation:urgent_downlink_allocated",
                    "contact_id" => "urgent_downlink_allocated",
                    "type" => "downlink",
                    "scenario_id" => "leo_1",
                    "ground_station_id" => "equator_prime",
                    "direction" => "downlink",
                    "starts_at_s" => 620.0,
                    "ends_at_s" => 700.0,
                    "source_window_id" => "window:leo_1:ground_station_access:equator_prime:4",
                    "allocation_status" => "allocated",
                    "allocation_reason" => "selected_by_contention_resolution",
                    "selected" => true,
                    "contention_group_id" => "station:equator_prime:contention:4",
                    "deferred_contact_ids" => ["urgent_downlink_deferred"],
                    "review_status" => "operator_review_required"
                  },
                  %{
                    "id" => "contact_allocation:urgent_downlink_deferred",
                    "contact_id" => "urgent_downlink_deferred",
                    "type" => "downlink",
                    "scenario_id" => "leo_2",
                    "ground_station_id" => "equator_prime",
                    "direction" => "downlink",
                    "starts_at_s" => 630.0,
                    "ends_at_s" => 710.0,
                    "source_window_id" => "window:leo_2:ground_station_access:equator_prime:4",
                    "allocation_status" => "deferred",
                    "allocation_reason" => "same_station_contention",
                    "selected" => false,
                    "contention_group_id" => "station:equator_prime:contention:4",
                    "selected_contact_id" => "urgent_downlink_allocated",
                    "review_status" => "operator_review_required"
                  }
                ]
              },
              "source_contact_intents" => [
                %{
                  "schema_contract" => "contact_intent.v1",
                  "id" => "urgent_downlink_allocated",
                  "activity_id" => "urgent_downlink_allocated",
                  "activity_type" => "downlink",
                  "scenario_id" => "leo_1",
                  "ground_station_id" => "equator_prime",
                  "direction" => "downlink",
                  "starts_at_s" => 620.0,
                  "ends_at_s" => 700.0,
                  "approval_status" => "operator_review_required",
                  "approval_requirements" => [
                    %{
                      "schema_contract" => "approval_requirement.v1",
                      "id" => "approval:urgent_downlink_allocated",
                      "activity_id" => "urgent_downlink_allocated",
                      "activity_type" => "downlink",
                      "action" => "review_contact_intent",
                      "requirement_type" => "contact_schedule_change",
                      "reason" => "contact intent requires schedule authority"
                    }
                  ],
                  "approval_rule_matches" => [
                    %{
                      "rule_id" => "downlink_schedule_authority_review",
                      "required_authority" => "contact_schedule_authority"
                    }
                  ],
                  "policy_decision" => %{
                    "schema_contract" => "policy_decision.v1",
                    "policy_bundle_id" => "command_contact_authority_v1",
                    "classification" => "operator_review_required"
                  }
                }
              ]
            }
          }
        ],
        "provenance" => %{"source_plan_id" => "campaign_plan:test"}
      })

    assert package["review_count"] == 14
    assert package["approval_requirement_count"] == 1
    assert package["contact_allocation_review_count"] == 2
    assert package["contact_intent_review_count"] == 1
    assert package["contact_suppression_count"] == 1
    assert package["contention_recommendation_count"] == 0
    assert package["realized_feedback_count"] == 0
    assert package["resource_projection_review_count"] == 1
    assert package["resource_suppression_count"] == 1
    assert package["risk_count"] == 1
    assert package["recommendation_count"] == 1
    assert package["ranking_comparison_count"] == 2
    assert package["tradeoff_count"] == 2
    assert package["warning_count"] == 1

    assert %{
             "review_type" => "strategy_recommendation",
             "branch_id" => "urgent",
             "recommended_branch_id" => "urgent",
             "ranked_branch_ids" => ["urgent", "baseline"],
             "tradeoff_count" => 2,
             "risk_count" => 1,
             "risk_types" => ["urgent_target"],
             "activity_ids" => ["obs_urgent"],
             "scenario_ids" => ["leo_1"],
             "ground_station_ids" => ["equator_prime"],
             "target_ids" => ["target_hot"],
             "collection_ids" => ["collection_hot"],
             "product_ids" => ["product_hot"],
             "payload_ids" => ["payload_hot"],
             "instrument_ids" => ["instrument_hot"],
             "objective_ids" => ["objective:latency_hot"],
             "objective_types" => ["collection_latency"],
             "feedback_sources" => ["prior_plan.source_objective_satisfaction_report"],
             "feedback_scopes" => ["objective_satisfaction"],
             "source_activity_ids" => ["obs_hot"],
             "source_window_ids" => ["window:leo_1:ground_station_access:equator_prime:risk"],
             "source_window_types" => ["ground_station_access"],
             "maneuver_ids" => ["burn_uncertain"],
             "maneuver_execution_uncertainty_statuses" => ["declared"],
             "maneuver_execution_uncertainty_sources" => ["provider_execution_covariance"],
             "maneuver_execution_uncertainty_timing_3sigma_s" => [75.0],
             "maneuver_execution_uncertainty_delta_v_3sigma_magnitude_km_s" => [0.002],
             "directions" => ["downlink"],
             "station_calendar_entry_ids" => ["station_calendar_entry_1"],
             "station_calendar_directions" => ["command"],
             "branch_event_count" => 2,
             "branch_event_types" => ["downlink_completion_gap"],
             "branch_event_trust_boundary_status_counts" => %{
               "declared" => 1,
               "missing" => 1
             },
             "capacity_pack_group_ids" => ["station:equator_prime:pack:review"],
             "capacity_pack_statuses" => ["deferred_by_reduced_station_capacity_pack"],
             "capacity_pack_min_capacity_fraction" => 0.5,
             "capacity_pack_max_used_fraction" => 0.5,
             "capacity_pack_max_required_capacity_fraction" => 0.25,
             "capacity_pack_total_required_capacity_fraction" => 0.35,
             "capacity_pack_required_capacity_sources" => [
               "contact_required_capacity_fraction",
               "default_reduced_capacity_policy"
             ],
             "approval_requirement_count" => 1,
             "required_operator_action" => "review_strategy_recommendation",
             "operational_feedback_trust_boundary_status" => "declared",
             "operational_feedback_trust_boundary" => "cadence_feedback_adapter",
             "operational_feedback_input_keys" => [
               "contact_success_rate",
               "station_throughput_factor"
             ],
             "source_operational_feedback_provenance" => %{
               "source_count" => 1
             }
           } = Enum.find(package["rows"], &(&1["review_type"] == "strategy_recommendation"))

    assert %{
             "risk_type" => "urgent_target",
             "activity_id" => "obs_urgent",
             "scenario_id" => "leo_1",
             "ground_station_id" => "equator_prime",
             "target_id" => "target_hot",
             "collection_id" => "collection_hot",
             "product_id" => "product_hot",
             "payload_id" => "payload_hot",
             "instrument_id" => "instrument_hot",
             "objective_id" => "objective:latency_hot",
             "objective_type" => "collection_latency",
             "latency_objective" => true,
             "max_latency_s" => 180.0,
             "planned_latency_s" => 420.0,
             "required_downlink_mb" => 30.0,
             "feedback_source" => "prior_plan.source_objective_satisfaction_report",
             "feedback_scope" => "objective_satisfaction",
             "source_window_id" => "window:leo_1:ground_station_access:equator_prime:risk",
             "source_window_type" => "ground_station_access",
             "direction" => "downlink",
             "station_calendar_entry_id" => "station_calendar_entry_1",
             "station_calendar_directions" => ["command"]
           } =
             Enum.find(package["rows"], &(&1["review_type"] == "risk_explanation"))

    assert %{
             "review_type" => "strategy_tradeoff",
             "subject_id" => "expected_score",
             "branch_id" => "urgent",
             "required_operator_action" => "review_strategy_tradeoff",
             "baseline" => 50.0,
             "recommended" => 75.0,
             "delta" => 25.0,
             "source_tradeoff" => %{"dimension" => "expected_score"}
           } = Enum.find(package["rows"], &(&1["review_type"] == "strategy_tradeoff"))

    assert %{
             "review_type" => "ranking_comparison_review",
             "source" => "campaign_strategy.ranking_comparison_report.rows",
             "subject_id" => "baseline",
             "scenario_id" => "baseline",
             "required_operator_action" => "review_ranking_comparison",
             "left_rank" => 2,
             "right_rank" => 1,
             "rank_delta" => 1,
             "source_ranking_comparison" => %{"scenario_id" => "baseline"}
           } = Enum.find(package["rows"], &(&1["review_type"] == "ranking_comparison_review"))

    assert %{
             "review_type" => "approval_requirement",
             "activity_id" => "obs_urgent",
             "candidate_diff" => %{
               "invalidated_candidate_id" => "obs_old",
               "invalidated_candidate_ids" => ["obs_old", "obs_old_copy"],
               "replacement_candidate_id" => "obs_urgent",
               "invalidated_reason" => "ambiguous_candidate_diff_match",
               "candidate_diff_match_status" => "ambiguous_replacement_candidate_diff",
               "candidate_diff_match_count" => 2,
               "candidate_budget_match_status" => "budget_dropped_replacement_candidate",
               "candidate_budget_match_count" => 1,
               "budget_dropped_candidate_ids" => ["obs_urgent"],
               "semantic_change_reasons" => ["source_window_id_changed"]
             },
             "invalidated_candidate_id" => "obs_old",
             "invalidated_candidate_ids" => ["obs_old", "obs_old_copy"],
             "replacement_candidate_id" => "obs_urgent",
             "invalidated_reason" => "ambiguous_candidate_diff_match",
             "candidate_diff_match_status" => "ambiguous_replacement_candidate_diff",
             "candidate_diff_match_count" => 2,
             "candidate_budget_match_status" => "budget_dropped_replacement_candidate",
             "candidate_budget_match_count" => 1,
             "budget_dropped_candidate_ids" => ["obs_urgent"],
             "activity_context" => %{
               "target_id" => "target_hot",
               "source_window_id" => "window:target_hot",
               "target_priority" => 4.0,
               "observation_success_factor" => 0.5,
               "contact_success_factor" => 0.4,
               "contact_success_factor_source" =>
                 "operational_feedback.contact_success_rate.station"
             },
             "source_requirement" => %{
               "activity_context" => %{
                 "target_id" => "target_hot",
                 "source_window_id" => "window:target_hot"
               },
               "candidate_diff" => %{
                 "invalidated_reason" => "ambiguous_candidate_diff_match"
               }
             }
           } = Enum.find(package["rows"], &(&1["review_type"] == "approval_requirement"))

    assert %{
             "review_type" => "contact_suppression",
             "branch_id" => "urgent",
             "activity_id" => "urgent_downlink_contact_suppressed",
             "activity_type" => "downlink",
             "required_operator_action" => "review_suppressed_contact",
             "ground_station_id" => "equator_prime",
             "station_availability" => "unavailable",
             "source" =>
               "campaign_strategy.branches.repair_result.source_contact_filter_report.suppressed_candidates",
             "source_contact_suppression" => %{
               "suppressed_reason" => "ground_station_unavailable"
             }
           } = Enum.find(package["rows"], &(&1["review_type"] == "contact_suppression"))

    assert %{
             "review_type" => "contact_allocation_review",
             "branch_id" => "urgent",
             "contact_id" => "urgent_downlink_deferred",
             "allocation_status" => "deferred",
             "required_operator_action" => "review_contact_allocation",
             "source" =>
               "campaign_strategy.branches.repair_result.source_contact_allocation_report.rows",
             "source_contact_allocation" => %{
               "allocation_reason" => "same_station_contention"
             }
           } = Enum.find(package["rows"], &(&1["contact_id"] == "urgent_downlink_deferred"))

    assert %{
             "review_type" => "contact_intent_review",
             "branch_id" => "urgent",
             "activity_id" => "urgent_downlink_allocated",
             "contact_id" => "urgent_downlink_allocated",
             "required_operator_action" => "review_contact_intent",
             "approval_status" => "operator_review_required",
             "source" => "campaign_strategy.branches.repair_result.source_contact_intents",
             "source_policy_decision" => %{
               "policy_bundle_id" => "command_contact_authority_v1",
               "classification" => "operator_review_required"
             },
             "source_contact_intent" => %{
               "schema_contract" => "contact_intent.v1",
               "activity_id" => "urgent_downlink_allocated"
             }
           } = Enum.find(package["rows"], &(&1["review_type"] == "contact_intent_review"))

    assert %{
             "review_type" => "resource_suppression",
             "branch_id" => "urgent",
             "activity_id" => "urgent_downlink_suppressed",
             "activity_type" => "downlink",
             "required_operator_action" => "review_suppressed_contact",
             "ground_station_id" => "equator_prime",
             "station_availability" => "available",
             "source" =>
               "campaign_strategy.branches.repair_result.source_resource_filter_report.suppressed_candidates",
             "source_resource_suppression" => %{
               "suppressed_reason" => "downlink_margin_below_policy"
             }
           } = Enum.find(package["rows"], &(&1["review_type"] == "resource_suppression"))

    assert %{
             "review_type" => "resource_projection_review",
             "branch_id" => "urgent",
             "spacecraft_id" => "leo_1",
             "approval_status" => "blocked_by_policy",
             "projected_downlink_shortfall_mb" => 50.0,
             "first_resource_pressure_activity_id" => "urgent_downlink_allocated",
             "first_resource_pressure_kind" => "downlink_shortfall",
             "source" =>
               "campaign_strategy.branches.resource_projection_report.projected_resources",
             "source_resource_projection" => %{
               "projected_downlink_shortfall_mb" => 50.0
             }
           } = Enum.find(package["rows"], &(&1["review_type"] == "resource_projection_review"))

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    stale_source_risk =
      update_in(package, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"review_type" => "risk_explanation", "source_risk" => %{}} = row ->
            row
            |> put_in(["source_risk", "type"], "stale_risk_type")
            |> put_in(["source_risk", "severity"], "critical")

          row ->
            row
        end)
      end)

    assert {:error, stale_source_risk_report} = Schema.validate_artifact(stale_source_risk)

    assert Enum.any?(
             stale_source_risk_report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.risk_type$/ and
                 &1["message"] == "must match source_risk.type")
           )

    assert Enum.any?(
             stale_source_risk_report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.severity$/ and
                 &1["message"] == "must match source_risk.severity")
           )

    stale_source_recommendation =
      update_in(package, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"review_type" => "strategy_recommendation", "source_recommendation" => %{}} = row ->
            row
            |> put_in(["source_recommendation", "recommended_branch_id"], "baseline")
            |> put_in(["source_recommendation", "risks_remaining"], [])

          row ->
            row
        end)
      end)

    assert {:error, stale_source_recommendation_report} =
             Schema.validate_artifact(stale_source_recommendation)

    assert Enum.any?(
             stale_source_recommendation_report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.branch_id$/ and
                 &1["message"] == "must match source_recommendation.recommended_branch_id")
           )

    assert Enum.any?(
             stale_source_recommendation_report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.risk_count$/ and
                 &1["message"] == "must match source_recommendation.risks_remaining count")
           )

    stale_source_tradeoff =
      update_in(package, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"review_type" => "strategy_tradeoff", "source_tradeoff" => %{}} = row ->
            put_in(row, ["source_tradeoff", "delta"], 12.0)

          row ->
            row
        end)
      end)

    assert {:error, stale_source_tradeoff_report} =
             Schema.validate_artifact(stale_source_tradeoff)

    assert Enum.any?(
             stale_source_tradeoff_report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.delta$/ and
                 &1["message"] == "must match source_tradeoff.delta")
           )
  end
end
