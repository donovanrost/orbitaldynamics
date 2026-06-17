Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyManeuverReviewSourceTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy derives maneuver success feedback from prior maneuver review reports" do
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
        "source_maneuver_review_report" => %{
          "schema_contract" => "maneuver_review_report.v1",
          "model" => "artifact_only_maneuver_review_report",
          "source" => "maneuver_recommendation.v1",
          "maneuver_count" => 1,
          "review_required_count" => 1,
          "rows" => [
            %{
              "id" => "maneuver_review:leo_1:burn_impulsive",
              "maneuver_id" => "burn_impulsive",
              "scenario_id" => "leo_1",
              "maneuver_type" => "impulsive_burn",
              "epoch_s" => 100.0,
              "approval_status" => "operator_review_required",
              "required_operator_action" => "review_maneuver_recommendation",
              "maneuver_success_factor" => 0.4,
              "maneuver_success_factor_source" => "preburn_confidence_model",
              "execution_uncertainty" => %{
                "timing_3sigma_s" => "75.0",
                "delta_v_3sigma_km_s" => ["0.0", "0.002", "0.0"],
                "source" => "provider_execution_covariance"
              },
              "confidence_weight" => "3.0",
              "confidence_weight_source" => "operator_sample_size"
            },
            %{
              "id" => "maneuver_review:leo_1:burn_impulsive_light",
              "maneuver_id" => "burn_impulsive",
              "scenario_id" => "leo_1",
              "maneuver_type" => "impulsive_burn",
              "epoch_s" => 100.0,
              "approval_status" => "operator_review_required",
              "required_operator_action" => "review_maneuver_recommendation",
              "maneuver_success_factor" => 1.0,
              "feedback_sample_weight" => "1.0"
            }
          ]
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        branch_generation_policy: %{
          maneuver_execution_timing_3sigma_threshold_s: 60.0,
          maneuver_execution_delta_v_3sigma_threshold_km_s: 0.001
        },
        derive_branches?: true,
        branches: [%{id: "baseline"}, %{id: "manual_review", events: [%{type: "operator_note"}]}],
        current_epoch_s: 0.0
      )

    assert get_in(artifact, ["operational_feedback", "maneuver_success_rate"]) == %{
             "burn_impulsive" => 0.55
           }

    assert get_in(artifact, ["operational_feedback", "maneuver_execution_uncertainty"]) == %{
             "burn_impulsive" => %{
               "execution_uncertainty_status" => "declared",
               "execution_uncertainty" => %{
                 "timing_3sigma_s" => "75.0",
                 "delta_v_3sigma_km_s" => ["0.0", "0.002", "0.0"],
                 "source" => "provider_execution_covariance"
               },
               "timing_3sigma_s" => 75.0,
               "delta_v_3sigma_km_s" => [0.0, 0.002, 0.0],
               "delta_v_3sigma_magnitude_km_s" => 0.002,
               "execution_uncertainty_source" => "provider_execution_covariance"
             }
           }

    assert Enum.any?(
             get_in(artifact, ["operational_feedback_provenance", "sources"]),
             &(&1["source"] == "prior_plan.maneuver_review_report.rows" and
                 &1["source_report_contract"] == "maneuver_review_report.v1" and
                 &1["source_report_row_count"] == 2 and
                 &1["weighted_feedback_row_count"] == 2 and
                 &1["feedback_weight_sources"] == ["operator_sample_size"] and
                 &1["source_execution_uncertainty_declared_count"] == 1)
           )

    maneuver_branch = branch(artifact, "derived_maneuver_success_feedback")

    assert %{
             "type" => "maneuver_success_feedback",
             "activity_id" => "burn_impulsive",
             "maneuver_success_factor" => 0.55,
             "feedback_source" => "operational_feedback.maneuver_success_rate",
             "feedback_scope" => "activity"
           } = List.first(maneuver_branch["events"])

    uncertainty_branch = branch(artifact, "derived_maneuver_execution_uncertainty_feedback")

    assert %{
             "type" => "maneuver_execution_uncertainty_feedback",
             "activity_id" => "burn_impulsive",
             "timing_3sigma_s" => 75.0,
             "delta_v_3sigma_magnitude_km_s" => 0.002,
             "execution_uncertainty_source" => "provider_execution_covariance",
             "feedback_source" => "operational_feedback.maneuver_execution_uncertainty",
             "feedback_scope" => "activity"
           } = List.first(uncertainty_branch["events"])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives maneuver success feedback from mission-state maneuver review reports" do
    maneuver_review_report = %{
      "schema_contract" => "maneuver_review_report.v1",
      "model" => "artifact_only_maneuver_review_report",
      "source" => "cadence.live_maneuver_review",
      "maneuver_count" => 1,
      "review_required_count" => 1,
      "rows" => [
        %{
          "id" => "maneuver_review:leo_1:burn_live",
          "maneuver_id" => "burn_live",
          "scenario_id" => "leo_1",
          "maneuver_type" => "impulsive_burn",
          "epoch_s" => 100.0,
          "approval_status" => "operator_review_required",
          "required_operator_action" => "review_maneuver_recommendation",
          "maneuver_success_factor" => 0.35,
          "confidence_weight" => "2.0",
          "confidence_weight_source" => "live_maneuver_sample",
          "execution_uncertainty" => %{
            "timing_3sigma_s" => "90.0",
            "delta_v_3sigma_km_s" => ["0.0", "0.003", "0.0"],
            "source" => "live_navigation_covariance"
          }
        }
      ]
    }

    artifact =
      strategy(
        base_plan(%{
          "planning_horizon" => %{"duration_s" => 2_000.0},
          "activities" => [
            %{
              "id" => "burn_live",
              "type" => "impulsive_burn",
              "scenario_id" => "leo_1",
              "starts_at_s" => 100.0,
              "ends_at_s" => 100.0,
              "duration_s" => 0.0,
              "score" => 0.0
            }
          ]
        }),
        mission_state:
          mission_state_with_refresh_inputs()
          |> Map.put(:source_maneuver_review_report, maneuver_review_report),
        branch_generation_policy: %{
          maneuver_execution_timing_3sigma_threshold_s: 60.0,
          maneuver_execution_delta_v_3sigma_threshold_km_s: 0.001
        },
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    assert get_in(artifact, ["operational_feedback", "maneuver_success_rate"]) == %{
             "burn_live" => 0.35
           }

    assert get_in(artifact, [
             "operational_feedback",
             "maneuver_execution_uncertainty",
             "burn_live",
             "timing_3sigma_s"
           ]) == 90.0

    assert Enum.any?(
             artifact["operational_feedback_provenance"]["sources"],
             &(&1["source"] == "mission_state.maneuver_review_report.rows" and
                 &1["source_report_paths"] == ["mission_state.source_maneuver_review_report"] and
                 &1["source_report_contract"] == "maneuver_review_report.v1" and
                 &1["weighted_feedback_row_count"] == 1 and
                 &1["source_execution_uncertainty_declared_count"] == 1)
           )

    maneuver_branch = branch(artifact, "derived_maneuver_success_feedback")

    assert %{
             "type" => "maneuver_success_feedback",
             "activity_id" => "burn_live",
             "maneuver_success_factor" => 0.35,
             "feedback_source" => "operational_feedback.maneuver_success_rate"
           } = List.first(maneuver_branch["events"])

    assert get_in(maneuver_branch, [
             "assumptions",
             "candidate_source",
             "source_operational_feedback_provenance",
             "derived_from_source_maneuver_review_report"
           ])

    assert get_in(maneuver_branch, [
             "assumptions",
             "candidate_source",
             "source_operational_feedback_provenance",
             "source_maneuver_review_report_paths"
           ]) == ["mission_state.source_maneuver_review_report"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives maneuver feedback from result artifact maneuver review without duplicate recommendations" do
    recommendation = %{
      "schema_contract" => "maneuver_recommendation.v1",
      "id" => "burn_from_result",
      "scenario_id" => "leo_1",
      "type" => "impulsive_burn",
      "epoch_s" => 120.0,
      "epoch_scale" => "tdb",
      "frame" => "eci_j2000",
      "delta_v_km_s" => [0.0, 0.01, 0.0],
      "delta_v_magnitude_km_s" => 0.01,
      "maneuver_model" => "impulsive_burns",
      "assumptions" => %{
        "execution_boundary" => "recommendation_only_no_command_execution"
      }
    }

    maneuver_review_report = %{
      "schema_contract" => "maneuver_review_report.v1",
      "model" => "artifact_only_maneuver_review_report",
      "source" => "result_set_artifact.maneuver_recommendations",
      "maneuver_count" => 1,
      "review_required_count" => 1,
      "rows" => [
        %{
          "id" => "maneuver_review:leo_1:burn_from_result",
          "maneuver_id" => "burn_from_result",
          "scenario_id" => "leo_1",
          "maneuver_type" => "impulsive_burn",
          "epoch_s" => 120.0,
          "epoch_scale" => "tdb",
          "frame" => "eci_j2000",
          "delta_v_km_s" => [0.0, 0.01, 0.0],
          "delta_v_magnitude_km_s" => 0.01,
          "approval_status" => "operator_review_required",
          "required_operator_action" => "review_maneuver_recommendation",
          "maneuver_success_factor" => 0.35,
          "maneuver_success_factor_source" => "result_artifact_review",
          "feedback_sample_weight" => "1.0",
          "source_recommendation" => recommendation
        }
      ]
    }

    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          %{
            "id" => "burn_from_result",
            "type" => "impulsive_burn",
            "scenario_id" => "leo_1",
            "starts_at_s" => 120.0,
            "ends_at_s" => 120.0,
            "duration_s" => 0.0,
            "score" => 0.0
          }
        ],
        "source_result_artifact" => %{
          "schema_contract" => "result_artifact.v1",
          "study_id" => "maneuver_result_artifact",
          "maneuver_review_report" => maneuver_review_report,
          "maneuver_recommendations" => [recommendation]
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    assert get_in(artifact, ["operational_feedback", "maneuver_success_rate"]) == %{
             "burn_from_result" => 0.35
           }

    assert Enum.any?(
             get_in(artifact, ["operational_feedback_provenance", "sources"]),
             &(&1["source"] == "prior_plan.maneuver_review_report.rows" and
                 &1["source_report_contract"] == "maneuver_review_report.v1" and
                 &1["source_report_count"] == 1 and
                 &1["source_report_paths"] == [
                   "prior_plan.source_result_artifact.maneuver_review_report"
                 ] and
                 &1["source_report_row_count"] == 1 and
                 &1["source_result_artifact_count"] == 1 and
                 &1["source_result_artifact_maneuver_review_row_count"] == 1 and
                 &1["weighted_feedback_row_count"] == 1)
           )

    maneuver_branch = branch(artifact, "derived_maneuver_success_feedback")

    assert %{
             "type" => "maneuver_success_feedback",
             "activity_id" => "burn_from_result",
             "maneuver_success_factor" => 0.35,
             "feedback_source" => "operational_feedback.maneuver_success_rate",
             "feedback_scope" => "activity"
           } = List.first(maneuver_branch["events"])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
