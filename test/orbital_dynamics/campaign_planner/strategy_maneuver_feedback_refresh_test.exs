Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyManeuverFeedbackRefreshTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy derives maneuver success refresh branch from operational feedback" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          %{
            "id" => "burn_impulsive",
            "type" => "impulsive_burn",
            "scenario_id" => "leo_1",
            "starts_at_s" => 100.0,
            "ends_at_s" => 100.0,
            "duration_s" => 0.0,
            "score" => 0.0
          }
        ],
        "candidate_activities" => []
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        operational_feedback: %{
          maneuver_success_rate: %{"burn_impulsive" => 0.5}
        },
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    maneuver_branch = branch(artifact, "derived_maneuver_success_feedback")

    assert %{
             "type" => "maneuver_success_feedback",
             "activity_id" => "burn_impulsive",
             "scenario_id" => "leo_1",
             "maneuver_success_factor" => 0.5,
             "feedback_source" => "operational_feedback.maneuver_success_rate",
             "feedback_scope" => "activity",
             "feedback_key" => "burn_impulsive"
           } = List.first(maneuver_branch["events"])

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             maneuver_branch["assumptions"]["candidate_source"]

    assert maneuver_branch["feedback_adjustments"]["maneuver_success_factor"] == 0.5
    assert maneuver_branch["score_terms"]["feedback_adjustment_score"] < 0.0

    assert Enum.any?(
             maneuver_branch["risk_indicators"],
             &(&1["type"] == "maneuver_success_rate_low" and &1["value"] == 0.5 and
                 &1["activity_id"] == "burn_impulsive")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives maneuver execution uncertainty refresh branch from operational feedback" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          %{
            "id" => "burn_impulsive",
            "type" => "impulsive_burn",
            "scenario_id" => "leo_1",
            "starts_at_s" => 100.0,
            "ends_at_s" => 100.0,
            "duration_s" => 0.0,
            "score" => 0.0
          }
        ],
        "candidate_activities" => []
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        operational_feedback: %{
          trust_boundary: "cadence_operational_feedback",
          maneuver_execution_uncertainty: %{
            "burn_impulsive" => %{
              "execution_uncertainty_status" => "declared",
              "execution_uncertainty" => %{
                "timing_3sigma_s" => 75.0,
                "delta_v_3sigma_km_s" => [0.0, 0.002, 0.0],
                "source" => "provider_execution_covariance"
              },
              "timing_3sigma_s" => 75.0,
              "delta_v_3sigma_km_s" => [0.0, 0.002, 0.0],
              "delta_v_3sigma_magnitude_km_s" => 0.002,
              "execution_uncertainty_source" => "provider_execution_covariance"
            }
          }
        },
        branch_generation_policy: %{
          maneuver_execution_timing_3sigma_threshold_s: 60.0,
          maneuver_execution_delta_v_3sigma_threshold_km_s: 0.001
        },
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    uncertainty_branch = branch(artifact, "derived_maneuver_execution_uncertainty_feedback")

    assert %{
             "type" => "maneuver_execution_uncertainty_feedback",
             "activity_id" => "burn_impulsive",
             "scenario_id" => "leo_1",
             "execution_uncertainty_status" => "declared",
             "timing_3sigma_s" => 75.0,
             "timing_3sigma_threshold_s" => 60.0,
             "delta_v_3sigma_magnitude_km_s" => 0.002,
             "delta_v_3sigma_magnitude_threshold_km_s" => 0.001,
             "execution_uncertainty_source" => "provider_execution_covariance",
             "feedback_source" => "operational_feedback.maneuver_execution_uncertainty",
             "feedback_scope" => "activity",
             "feedback_key" => "burn_impulsive",
             "trust_boundary" => "cadence_operational_feedback"
           } = uncertainty_event = List.first(uncertainty_branch["events"])

    assert uncertainty_event["delta_v_3sigma_km_s"] == [0.0, 0.002, 0.0]

    assert %{"source" => "provider_execution_covariance"} =
             get_in(uncertainty_event, ["execution_uncertainty"])

    assert Enum.any?(
             uncertainty_branch["risk_indicators"],
             &(&1["type"] == "maneuver_execution_uncertainty_high" and
                 &1["activity_id"] == "burn_impulsive" and
                 &1["execution_uncertainty_status"] == "declared" and
                 &1["execution_uncertainty_source"] == "provider_execution_covariance" and
                 &1["timing_3sigma_s"] == 75.0 and
                 &1["delta_v_3sigma_magnitude_km_s"] == 0.002 and
                 &1["feedback_source"] ==
                   "operational_feedback.maneuver_execution_uncertainty" and
                 &1["trust_boundary"] == "cadence_operational_feedback")
           )

    assert %{
             "branch_maneuver_execution_uncertainty_activity_ids" => ["burn_impulsive"],
             "branch_maneuver_execution_uncertainty_statuses" => ["declared"],
             "branch_maneuver_execution_uncertainty_sources" => [
               "provider_execution_covariance"
             ],
             "branch_maneuver_execution_uncertainty_max_timing_3sigma_s" => 75.0,
             "branch_maneuver_execution_uncertainty_max_delta_v_3sigma_magnitude_km_s" => 0.002
           } =
             Enum.find(
               artifact["branch_comparison_report"]["rows"],
               &(&1["branch_id"] == "derived_maneuver_execution_uncertainty_feedback")
             )

    assert %{
             "branch_maneuver_execution_uncertainty_activity_ids" => ["burn_impulsive"],
             "branch_maneuver_execution_uncertainty_max_timing_3sigma_s" => 75.0
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["review_type"] == "strategy_tradeoff" and
                   &1["branch_id"] == "derived_maneuver_execution_uncertainty_feedback")
             )

    assert %{
             "branch_maneuver_execution_uncertainty_activity_ids" => ["burn_impulsive"],
             "branch_maneuver_execution_uncertainty_max_delta_v_3sigma_magnitude_km_s" => 0.002
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["source_review_type"] == "strategy_branch_comparison" and
                   &1["branch_id"] == "derived_maneuver_execution_uncertainty_feedback")
             )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy matches maneuver success operational feedback by timeline identity" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          %{
            "id" => "burn_impulsive",
            "type" => "impulsive_burn",
            "scenario_id" => "leo_1",
            "timeline_id" => "timeline:burn_impulsive",
            "starts_at_s" => 100.0,
            "ends_at_s" => 100.0,
            "duration_s" => 0.0,
            "score" => 0.0
          }
        ],
        "candidate_activities" => []
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        operational_feedback: %{
          maneuver_success_rate: %{"timeline:burn_impulsive" => 0.5}
        },
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    maneuver_branch = branch(artifact, "derived_maneuver_success_feedback")

    assert %{
             "type" => "maneuver_success_feedback",
             "activity_id" => "burn_impulsive",
             "maneuver_success_factor" => 0.5,
             "feedback_scope" => "timeline",
             "feedback_key" => "timeline:burn_impulsive"
           } = List.first(maneuver_branch["events"])

    assert maneuver_branch["feedback_adjustments"]["maneuver_success_factor"] == 0.5

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives maneuver success refresh branch from realized maneuver telemetry" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          %{
            "id" => "burn_impulsive",
            "type" => "impulsive_burn",
            "scenario_id" => "leo_1",
            "starts_at_s" => 100.0,
            "ends_at_s" => 100.0,
            "duration_s" => 0.0,
            "score" => 0.0
          }
        ],
        "candidate_activities" => []
      })

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:realized_activities, [
        %{
          id: "burn_impulsive",
          type: "impulsive_burn",
          status: "partial",
          completed_fraction: 0.2
        }
      ])

    artifact =
      strategy(prior_plan,
        mission_state: mission_state,
        derive_branches?: true,
        branches: [
          %{id: "baseline"},
          %{id: "manual", events: [%{type: "fuel_preservation_mode"}]}
        ],
        current_epoch_s: 0.0
      )

    maneuver_branch = branch(artifact, "derived_maneuver_success_feedback")

    assert get_in(artifact, ["operational_feedback", "maneuver_success_rate"]) == %{
             "burn_impulsive" => 0.2
           }

    assert %{
             "type" => "maneuver_success_feedback",
             "activity_id" => "burn_impulsive",
             "maneuver_success_factor" => 0.2
           } = List.first(maneuver_branch["events"])

    assert maneuver_branch["feedback_adjustments"]["maneuver_success_factor"] == 0.2

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy does not derive maneuver success branch above feedback threshold" do
    prior_plan =
      base_plan(%{
        "activities" => [
          %{
            "id" => "burn_impulsive",
            "type" => "impulsive_burn",
            "scenario_id" => "leo_1",
            "starts_at_s" => 100.0,
            "ends_at_s" => 100.0,
            "duration_s" => 0.0,
            "score" => 0.0
          }
        ],
        "candidate_activities" => []
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        operational_feedback: %{
          maneuver_success_rate: %{"burn_impulsive" => 0.95}
        },
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    refute branch(artifact, "derived_maneuver_success_feedback")

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy-derived refresh carries maneuver branch events into accepted state deltas" do
    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state_with_refresh_inputs(),
        branches: [
          %{id: "baseline"},
          %{
            id: "maneuver_refresh",
            events: [
              %{type: "missed_maneuver", activity_id: "burn_1"},
              %{
                type: "delayed_maneuver",
                activity_id: "burn_2",
                actual_starts_at_s: 240.0
              }
            ]
          }
        ],
        current_epoch_s: 0.0
      )

    maneuver_branch = branch(artifact, "maneuver_refresh")

    assert %{
             "type" => "candidate_refresh.v1",
             "maneuver_execution_delta_count" => 2,
             "scope" => "branch_generated"
           } = maneuver_branch["assumptions"]["candidate_source"]

    assert maneuver_branch["repair_result"]["assumptions"]["candidate_source"][
             "maneuver_execution_delta_count"
           ] == 2
  end

  test "strategy-derived refresh carries realized maneuver telemetry into accepted state deltas" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:realized_activities, [
        %{
          id: "burn_failed",
          status: "failed",
          starts_at_s: 120.0
        },
        %{
          id: "burn_delayed",
          status: "delayed",
          actual_starts_at_s: 180.0
        }
      ])

    artifact =
      strategy(
        base_plan(%{
          "activities" => [
            maneuver("burn_failed", 120.0),
            maneuver("burn_delayed", 150.0)
          ]
        }),
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

    assert %{
             "type" => "candidate_refresh.v1",
             "maneuver_execution_delta_count" => 2,
             "scope" => "branch_generated"
           } = urgent["assumptions"]["candidate_source"]

    assert urgent["repair_result"]["assumptions"]["candidate_source"][
             "maneuver_execution_delta_count"
           ] == 2

    assert get_in(artifact, ["operational_feedback", "maneuver_success_rate"]) == %{
             "burn_delayed" => 0.5,
             "burn_failed" => 0.0
           }

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
