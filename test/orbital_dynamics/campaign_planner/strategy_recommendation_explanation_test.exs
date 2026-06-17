Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyRecommendationExplanationTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy recommendation explanation names concrete changes objectives risks and approvals" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [downlink("dl_1", 100.0, 160.0)],
        "candidate_activities" => [downlink("dl_2", 700.0, 760.0)]
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([%{"type" => "priority_commitment", "target_id" => "target_hot"}]),
        strategy_policy: %{
          "mission_value_weight" => 10.0,
          "risk_weight" => 1.0,
          "approval_load_weight" => 1.0
        },
        approval_policy: %{
          "blocked_risk_types" => [],
          "operator_review_risk_limit" => 10
        },
        branches: [
          %{id: "baseline"},
          %{
            id: "urgent",
            events: [
              %{
                type: "urgent_target",
                target_id: "target_hot",
                starts_at_s: 500.0,
                ends_at_s: 560.0,
                priority: 20.0,
                source_branch_id: "derived_urgent_target_target_hot",
                source_branch_ids: ["derived_urgent_target_target_hot"],
                status_transition: %{
                  field: "approval_status",
                  from: "planned",
                  to: "operator_review_required",
                  transition_type: "approval_state_changed",
                  transition_category: "urgent_retarget_review",
                  transition_reason: "operator review required for urgent retarget",
                  requires_operator_review: true
                },
                candidate_windows: [
                  %{
                    id: "candidate_obs_hot",
                    type: "observe",
                    target_id: "target_hot",
                    scenario_id: "leo_1",
                    starts_at_s: 500.0,
                    ends_at_s: 560.0,
                    duration_s: 60.0,
                    score: 10.0,
                    estimated_storage_mb: 200.0
                  }
                ]
              }
            ]
          }
        ],
        candidate_refresh:
          candidate_refresh_artifact([],
            resource_summaries: [
              %{
                "schema_contract" => "resource_summary.v1",
                "spacecraft_id" => "leo_1",
                "storage_capacity_mb" => 100.0,
                "storage_used_mb" => 0.0,
                "downlink_capacity_mb" => 1_000.0,
                "fuel_margin" => 0.8,
                "power_margin" => 0.7,
                "payload_available" => true,
                "antenna_available" => true
              }
            ]
          ),
        current_epoch_s: 0.0
      )

    explanation = artifact["recommendation"]["explanation"]
    tradeoff_dimensions = Enum.map(artifact["recommendation"]["tradeoffs"], & &1["dimension"])

    assert artifact["recommendation"]["recommended_branch_id"] == "urgent"

    assert Enum.any?(
             explanation,
             &(&1["type"] == "strategic_addition" and &1["target_id"] == "target_hot")
           )

    assert Enum.any?(
             explanation,
             &(&1["type"] == "objective_satisfaction" and
                 &1["objective"] == "priority_commitments" and
                 &1["recommended_branch_id"] == "urgent" and
                 "target_hot" in &1["satisfied_target_ids"] and
                 &1["priority_commitment_required_target_count"] == 1 and
                 &1["priority_commitment_satisfied_target_count"] == 1 and
                 &1["priority_commitment_ratio"] == 1.0)
           )

    assert Enum.any?(
             explanation,
             &(&1["type"] == "objective_satisfaction" and
                 &1["objective"] == "downlink_completion" and
                 &1["recommended_branch_id"] == "urgent" and
                 &1["downlink_completion_required_contacts"] == 1 and
                 &1["downlink_completion_planned_contacts"] == 1 and
                 &1["downlink_completion_ratio"] == 1.0)
           )

    assert Enum.any?(
             explanation,
             &(&1["type"] == "objective_satisfaction" and
                 &1["objective"] == "coverage" and
                 &1["recommended_branch_id"] == "urgent" and
                 &1["coverage_observed_target_count"] == 1)
           )

    assert Enum.any?(
             explanation,
             &(&1["type"] == "objective_satisfaction" and
                 &1["objective"] == "revisit" and
                 &1["recommended_branch_id"] == "urgent" and
                 &1["revisit_count"] == 0)
           )

    assert Enum.any?(
             explanation,
             &(&1["type"] == "risk_driver" and &1["risk_type"] == "urgent_target" and
                 &1["target_id"] == "target_hot")
           )

    assert Enum.any?(
             explanation,
             &(&1["type"] == "resource_pressure" and
                 &1["recommended_branch_id"] == "urgent" and
                 &1["activity_id"] == "urgent_urgent_observe_target_hot" and
                 &1["activity_type"] == "observe" and
                 &1["pressure_kind"] == "storage_overflow" and
                 &1["first_resource_pressure_activity_id"] == "urgent_urgent_observe_target_hot" and
                 &1["first_resource_pressure_activity_type"] == "observe" and
                 &1["first_resource_pressure_kind"] == "storage_overflow" and
                 &1["first_resource_pressure_starts_at_s"] == 500.0 and
                 &1["starts_at_s"] == 500.0 and
                 &1["peak_storage_overflow_mb"] == 100.0)
           )

    assert_storage_downlink_pressure_score_terms(branch(artifact, "urgent"), artifact, 1)

    assert Enum.any?(
             explanation,
             &(&1["type"] == "approval_driver" and &1["action"] == "approve_strategic_addition")
           )

    assert Enum.any?(explanation, &(&1["type"] == "branch_tradeoff"))

    assert Enum.any?(
             explanation,
             &(&1["type"] == "branch_event_summary" and
                 &1["recommended_branch_id"] == "urgent" and
                 &1["branch_event_count"] == 1 and
                 &1["branch_event_types"] == ["urgent_target"] and
                 &1["branch_transition_types"] == ["approval_state_changed"] and
                 &1["branch_transition_categories"] == ["urgent_retarget_review"] and
                 &1["branch_transition_reasons"] == [
                   "operator review required for urgent retarget"
                 ] and
                 &1["branch_requires_operator_review"] == true and
                 &1["branch_requires_operator_review_count"] == 1 and
                 &1["combined_source_branch_ids"] == ["derived_urgent_target_target_hot"])
           )

    assert %{
             "review_type" => "strategy_recommendation",
             "branch_event_types" => ["urgent_target"],
             "branch_transition_types" => ["approval_state_changed"],
             "branch_transition_categories" => ["urgent_retarget_review"],
             "branch_transition_reasons" => ["operator review required for urgent retarget"],
             "branch_requires_operator_review" => true,
             "branch_requires_operator_review_count" => 1
           } =
             artifact["operator_review_package"]["rows"]
             |> Enum.find(&(&1["review_type"] == "strategy_recommendation"))

    assert %{
             "import_action" => "import_strategy_recommendation",
             "branch_event_types" => ["urgent_target"],
             "branch_transition_types" => ["approval_state_changed"],
             "branch_transition_categories" => ["urgent_retarget_review"],
             "branch_transition_reasons" => ["operator review required for urgent retarget"],
             "branch_requires_operator_review" => true,
             "branch_requires_operator_review_count" => 1
           } =
             artifact["cadence_import_manifest"]["rows"]
             |> Enum.find(
               &(&1["import_action"] == "import_strategy_recommendation" and
                   &1["selected"] == true)
             )

    review_import = OrbitalDynamics.cadence_import_manifest(artifact["operator_review_package"])

    assert %{
             "import_action" => "review_strategy_recommendation",
             "source_review_type" => "strategy_recommendation",
             "branch_event_types" => ["urgent_target"],
             "branch_transition_types" => ["approval_state_changed"],
             "branch_transition_categories" => ["urgent_retarget_review"],
             "branch_transition_reasons" => ["operator review required for urgent retarget"],
             "branch_requires_operator_review" => true,
             "branch_requires_operator_review_count" => 1
           } =
             review_import["rows"]
             |> Enum.find(&(&1["source_review_type"] == "strategy_recommendation"))

    assert [
             "expected_score",
             "mission_value",
             "coverage",
             "revisit",
             "latency",
             "downlink_completion",
             "fuel_preservation",
             "asset_balance",
             "priority_commitment",
             "resource_score",
             "feedback_adjustment",
             "contact_allocation_pressure",
             "provider_reservation_request_pressure",
             "station_reservation_conflict_pressure",
             "candidate_diff_pressure",
             "timeline_diff_pressure",
             "link_capacity_pressure",
             "contact_intent_pressure",
             "contact_contention_pressure",
             "contact_filter_pressure",
             "command_window_pressure",
             "objective_gap_pressure",
             "timeline_feedback_pressure",
             "operational_timeline_pressure",
             "maneuver_review_pressure",
             "operational_readiness_pressure",
             "operator_training_pressure",
             "import_readiness_pressure",
             "quality_gate_pressure",
             "approval_boundary_pressure",
             "timeline_integrity_pressure",
             "timeline_dependency_impact_pressure",
             "timeline_publication_pressure",
             "timeline_transition_application_pressure",
             "timeline_activity_state_pressure",
             "timeline_lifecycle_pressure",
             "timeline_precondition_pressure",
             "timeline_preservation_pressure",
             "timeline_pressure",
             "storage_downlink_pressure",
             "resource_projection_pressure",
             "resource_availability_pressure",
             "resource_margin_pressure",
             "battery_depletion_pressure",
             "station_calendar_pressure",
             "station_reservation_expiration_pressure",
             "candidate_rejection_pressure",
             "provider_counteroffer_pressure",
             "model_acceptance_pressure",
             "validation_safety_case_pressure",
             "schema_validation_pressure",
             "refresh_budget_pressure",
             "refresh_freshness_pressure",
             "validation_refresh_pressure",
             "relay_data_path_pressure",
             "execution_feedback_pressure",
             "risk_count",
             "approval_count",
             "schedule_stability"
           ] = tradeoff_dimensions
  end

  test "strategy recommendation explains spacecraft-unavailable resource pressure" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "candidate_activities" => []
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([%{"type" => "priority_commitment", "target_id" => "target_hot"}]),
        strategy_policy: %{
          "mission_value_weight" => 10.0,
          "risk_weight" => 0.0,
          "approval_load_weight" => 0.0
        },
        approval_policy: %{
          "blocked_risk_types" => [],
          "operator_review_risk_limit" => 10
        },
        branches: [
          %{id: "baseline"},
          %{
            id: "urgent",
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
                    score: 10.0,
                    estimated_storage_mb: 200.0
                  }
                ]
              }
            ]
          }
        ],
        candidate_refresh:
          candidate_refresh_artifact([],
            resource_summaries: [
              %{
                "schema_contract" => "resource_summary.v1",
                "spacecraft_id" => "leo_1",
                "spacecraft_available" => false,
                "storage_capacity_mb" => 100.0,
                "storage_used_mb" => 0.0,
                "downlink_capacity_mb" => 1_000.0
              }
            ]
          ),
        current_epoch_s: 0.0
      )

    assert artifact["recommendation"]["recommended_branch_id"] == "urgent"

    assert Enum.any?(
             artifact["recommendation"]["explanation"],
             &(&1["type"] == "resource_pressure" and
                 &1["recommended_branch_id"] == "urgent" and
                 &1["spacecraft_id"] == "leo_1" and
                 &1["activity_id"] == "urgent_urgent_observe_target_hot" and
                 &1["pressure_kind"] == "spacecraft_unavailable" and
                 &1["first_resource_pressure_activity_id"] == "urgent_urgent_observe_target_hot" and
                 &1["first_resource_pressure_kind"] == "spacecraft_unavailable" and
                 &1["resource_pressure_status"] == "spacecraft_unavailable" and
                 &1["resource_pressure_types"] == ["spacecraft_unavailable"])
           )

    assert Enum.any?(
             artifact["recommendation"]["explanation"],
             &(&1["type"] == "risk_driver" and &1["risk_type"] == "spacecraft_unavailable" and
                 &1["spacecraft_id"] == "leo_1" and &1["value"] == false and
                 &1["resource_pressure_status"] == "spacecraft_unavailable" and
                 &1["resource_pressure_types"] == ["spacecraft_unavailable"])
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy recommendation explains first resource pressure contact context" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "candidate_activities" => [
          refreshed_downlink("dl_recovery", 500.0, 560.0)
          |> Map.put("estimated_energy_used_wh", 5.0)
          |> Map.put("source_station_calendar_entry", %{
            "id" => "station_calendar_entry_1",
            "provider_id" => "ops_calendar",
            "provider_entry_id" => "ops_calendar_window_1",
            "direction" => "downlink"
          })
        ]
      })

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:objectives, [
        %{
          "type" => "downlink_completion",
          "required_contacts" => 1,
          "ground_station_id" => "equator_prime",
          "starts_at_s" => 0.0,
          "ends_at_s" => 900.0
        }
      ])
      |> Map.put(:resource_summaries, [
        %{
          "schema_contract" => "resource_summary.v1",
          "spacecraft_id" => "leo_1",
          "storage_capacity_mb" => 1_000.0,
          "storage_used_mb" => 30.0,
          "downlink_capacity_mb" => 10.0,
          "battery_capacity_wh" => 100.0,
          "battery_energy_used_wh" => 10.0,
          "fuel_margin" => 0.8,
          "power_margin" => 0.7,
          "payload_available" => true,
          "antenna_available" => true
        }
      ])

    artifact =
      strategy(prior_plan,
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        strategy_policy: %{
          "risk_weight" => 0.0,
          "approval_load_weight" => 0.0
        },
        approval_policy: %{
          "blocked_risk_types" => [],
          "operator_review_risk_limit" => 10
        },
        current_epoch_s: 0.0
      )

    assert artifact["recommendation"]["recommended_branch_id"] == "derived_downlink_constrained"

    assert %{
             "type" => "resource_pressure",
             "recommended_branch_id" => "derived_downlink_constrained",
             "activity_id" => "leo_1_downlink_equator_prime_1",
             "activity_type" => "downlink",
             "pressure_kind" => "downlink_shortfall",
             "direction" => "downlink",
             "ground_station_id" => "equator_prime",
             "first_resource_pressure_activity_id" => "leo_1_downlink_equator_prime_1",
             "first_resource_pressure_activity_type" => "downlink",
             "first_resource_pressure_kind" => "downlink_shortfall",
             "first_resource_pressure_direction" => "downlink",
             "first_resource_pressure_ground_station_id" => "equator_prime"
           } =
             artifact["recommendation"]["explanation"]
             |> Enum.find(&(&1["type"] == "resource_pressure"))

    assert %{
             "review_type" => "strategy_recommendation",
             "activity_ids" => activity_ids,
             "ground_station_ids" => ["equator_prime"],
             "directions" => ["downlink"],
             "resource_pressure_statuses" => ["downlink_shortfall"],
             "resource_pressure_types" => ["downlink_shortfall"],
             "first_resource_pressure_kinds" => ["downlink_shortfall"]
           } =
             artifact["operator_review_package"]["rows"]
             |> Enum.find(&(&1["review_type"] == "strategy_recommendation"))

    assert "leo_1_downlink_equator_prime_1" in activity_ids

    assert %{
             "import_action" => "import_strategy_recommendation",
             "activity_ids" => import_activity_ids,
             "ground_station_ids" => ["equator_prime"],
             "directions" => ["downlink"],
             "resource_pressure_statuses" => ["downlink_shortfall"],
             "resource_pressure_types" => ["downlink_shortfall"],
             "first_resource_pressure_kinds" => ["downlink_shortfall"]
           } =
             artifact["cadence_import_manifest"]["rows"]
             |> Enum.find(&(&1["import_action"] == "import_strategy_recommendation"))

    assert "leo_1_downlink_equator_prime_1" in import_activity_ids

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  defp candidate_refresh_artifact(candidates, opts) do
    %{
      "schema_version" => 1,
      "schema_contract" => "candidate_refresh.v1",
      "artifact_type" => "candidate_refresh",
      "generated_at" => "2026-05-14T00:00:00Z",
      "planner" => "OrbitalDynamics.CandidateRefresh.V1",
      "refresh_id" => Keyword.get(opts, :refresh_id, "candidate_refresh:test:abc"),
      "study_id" => "candidate_refresh_test",
      "snapshot_id" => "ops-state-1",
      "current_epoch_s" => 0.0,
      "remaining_horizon" => %{
        "starts_at_s" => 0.0,
        "ends_at_s" => 1_000.0,
        "output_step_s" => 60.0
      },
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-1",
        "spacecraft_state_count" => 1
      },
      "refreshed_windows" => %{
        "access_windows" => [],
        "target_visibility_windows" => [],
        "eclipse_intervals" => []
      },
      "candidate_activities" => candidates,
      "contact_intents" => Keyword.get(opts, :contact_intents, []),
      "resource_summaries" => Keyword.get(opts, :resource_summaries, []),
      "contact_filter_report" => Keyword.get(opts, :contact_filter_report),
      "contact_allocation_report" => Keyword.get(opts, :contact_allocation_report),
      "resource_filter_report" => Keyword.get(opts, :resource_filter_report),
      "refresh_budget_report" => Keyword.get(opts, :refresh_budget_report),
      "candidate_diff_report" => Keyword.get(opts, :candidate_diff_report),
      "freshness_report" => Keyword.get(opts, :freshness_report),
      "invalidated_candidates" => [],
      "validation_records" => [],
      "warnings" => [],
      "assumptions" => %{},
      "provenance" => %{},
      "source_window_lineage" =>
        Enum.map(candidates, fn candidate ->
          %{
            "candidate_activity_id" => candidate["id"],
            "source_window_id" => candidate["source_window_id"],
            "source_window_type" => get_in(candidate, ["source_window", "type"]),
            "scenario_id" => candidate["scenario_id"]
          }
        end)
    }
  end

  defp assert_storage_downlink_pressure_score_terms(
         branch,
         artifact,
         expected_pressure_count,
         extra_split_pressure_count \\ 0
       ) do
    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    storage_downlink_pressure_count =
      Enum.count(
        branch["risk_indicators"],
        &(&1["type"] in [
            "storage_overflow",
            "downlink_shortfall",
            "storage_margin_low",
            "downlink_margin_low"
          ])
      )

    assert storage_downlink_pressure_count == expected_pressure_count

    assert branch["score_terms"]["storage_downlink_pressure_penalty"] ==
             -storage_downlink_pressure_count * risk_weight

    assert branch["score_terms"]["risk_penalty"] ==
             -(length(branch["risk_indicators"]) -
                 storage_downlink_pressure_count - extra_split_pressure_count) * risk_weight

    assert "storage_downlink_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == branch["branch_id"] and
                 &1["term_key"] == "storage_downlink_pressure_penalty" and
                 &1["value"] < 0.0)
           )
  end
end
