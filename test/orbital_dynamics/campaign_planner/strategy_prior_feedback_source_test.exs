Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyPriorFeedbackSourceTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy derives prior result-artifact operational feedback from source report keys" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          downlink("dl_source_feedback_wrapper", 100.0, 160.0),
          observe(
            "obs_source_feedback_wrapper",
            "leo_1",
            "target_source_feedback",
            200.0,
            260.0,
            12.0
          ),
          health_check("cmd_source_feedback_wrapper", "leo_1", 300.0, 330.0),
          %{
            "id" => "burn_source_feedback_wrapper",
            "type" => "impulsive_burn",
            "scenario_id" => "leo_1",
            "starts_at_s" => 400.0,
            "ends_at_s" => 400.0,
            "duration_s" => 0.0,
            "score" => 0.0
          }
        ],
        "source_candidate_activities" => [
          refreshed_downlink("candidate_source_feedback_wrapper", 500.0, 560.0)
        ],
        "source_result_artifact" => %{
          "schema_contract" => "result_artifact.v1",
          "study_id" => "source_operational_feedback_result_artifact",
          "metadata" => %{"trust_boundary" => "ops_source_operational_feedback_artifact"},
          "source_timeline_feedback_report" => %{
            "schema_contract" => "timeline_feedback_report.v1",
            "operational_feedback" => %{
              "station_throughput_factor" => %{"equator_prime" => 0.45}
            },
            "rows" => []
          },
          "source_operational_timeline_report" => %{
            "schema_contract" => "operational_timeline_report.v1",
            "source" => "adapter.source_operational_timeline",
            "rows" => [
              %{
                "id" => "timeline_row:obs_source_feedback_wrapper",
                "activity_id" => "obs_source_feedback_wrapper",
                "activity_type" => "observe",
                "scenario_id" => "leo_1",
                "target_id" => "target_source_feedback",
                "starts_at_s" => 200.0,
                "ends_at_s" => 260.0,
                "observation_success_factor" => 0.35,
                "image_quality_score" => 0.35,
                "image_quality_status" => "marginal"
              }
            ]
          },
          "source_command_window_report" => %{
            "schema_contract" => "command_window_report.v1",
            "model" => "artifact_only_command_window_report",
            "health_check_count" => 1,
            "review_required_count" => 1,
            "rows" => [
              %{
                "id" => "command_window:cmd_source_feedback_wrapper",
                "activity_id" => "cmd_source_feedback_wrapper",
                "activity_type" => "health_check",
                "window_type" => "health_check_window",
                "scenario_id" => "leo_1",
                "starts_at_s" => 300.0,
                "ends_at_s" => 330.0,
                "command_success_factor" => 0.25
              }
            ]
          },
          "source_maneuver_review_report" => %{
            "schema_contract" => "maneuver_review_report.v1",
            "model" => "artifact_only_maneuver_review_report",
            "maneuver_count" => 1,
            "review_required_count" => 1,
            "rows" => [
              %{
                "id" => "maneuver_review:leo_1:burn_source_feedback_wrapper",
                "maneuver_id" => "burn_source_feedback_wrapper",
                "scenario_id" => "leo_1",
                "maneuver_type" => "impulsive_burn",
                "epoch_s" => 400.0,
                "approval_status" => "operator_review_required",
                "required_operator_action" => "review_maneuver_recommendation",
                "maneuver_success_factor" => 0.3,
                "execution_uncertainty" => %{
                  "timing_3sigma_s" => "80.0",
                  "delta_v_3sigma_km_s" => ["0.0", "0.002", "0.0"],
                  "source" => "source_wrapper_covariance"
                }
              }
            ]
          }
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
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    assert get_in(artifact, ["operational_feedback", "station_throughput_factor"]) == %{
             "equator_prime" => 0.45
           }

    assert get_in(artifact, ["operational_feedback", "observation_success_rate"]) == %{
             "target_source_feedback" => 0.35
           }

    assert get_in(artifact, ["operational_feedback", "command_success_rate"]) == %{
             "cmd_source_feedback_wrapper" => 0.25
           }

    assert get_in(artifact, ["operational_feedback", "maneuver_success_rate"]) == %{
             "burn_source_feedback_wrapper" => 0.3
           }

    assert get_in(artifact, [
             "operational_feedback",
             "maneuver_execution_uncertainty",
             "burn_source_feedback_wrapper",
             "timing_3sigma_s"
           ]) == 80.0

    sources = artifact["operational_feedback_provenance"]["sources"]

    assert %{
             "source_report_paths" => [
               "prior_plan.source_result_artifact.source_timeline_feedback_report"
             ],
             "trust_boundaries" => ["ops_source_operational_feedback_artifact"]
           } =
             Enum.find(
               sources,
               &(&1["source"] ==
                   "prior_plan.source_timeline_feedback_report.operational_feedback")
             )

    assert %{
             "source_report_paths" => [
               "prior_plan.source_result_artifact.source_operational_timeline_report"
             ],
             "source_report_row_count" => 1,
             "trust_boundaries" => ["ops_source_operational_feedback_artifact"]
           } =
             Enum.find(sources, &(&1["source"] == "prior_plan.operational_timeline_report.rows"))

    assert %{
             "source_report_paths" => [
               "prior_plan.source_result_artifact.source_command_window_report"
             ],
             "source_report_row_count" => 1,
             "trust_boundaries" => ["ops_source_operational_feedback_artifact"]
           } =
             Enum.find(sources, &(&1["source"] == "prior_plan.command_window_report.rows"))

    assert %{
             "source_report_paths" => [
               "prior_plan.source_result_artifact.source_maneuver_review_report"
             ],
             "source_report_row_count" => 1,
             "source_execution_uncertainty_declared_count" => 1
           } =
             Enum.find(sources, &(&1["source"] == "prior_plan.maneuver_review_report.rows"))

    assert %{
             "type" => "station_throughput_feedback",
             "trust_boundary" => "ops_source_operational_feedback_artifact"
           } = List.first(branch(artifact, "derived_station_throughput_feedback")["events"])

    assert %{
             "type" => "observation_success_feedback",
             "trust_boundary" => "ops_source_operational_feedback_artifact"
           } =
             List.first(
               branch(
                 artifact,
                 "derived_operational_timeline_feedback_obs_source_feedback_wrapper"
               )["events"]
             )

    assert %{
             "type" => "command_success_feedback",
             "trust_boundary" => "ops_source_operational_feedback_artifact"
           } = List.first(branch(artifact, "derived_command_success_feedback")["events"])

    assert %{
             "type" => "maneuver_success_feedback",
             "trust_boundary" => "ops_source_operational_feedback_artifact"
           } = List.first(branch(artifact, "derived_maneuver_success_feedback")["events"])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives command and maneuver feedback from prior operator review package rows" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          health_check("cmd_health_1", "leo_1", 100.0, 130.0),
          %{
            "id" => "burn_impulsive",
            "type" => "impulsive_burn",
            "scenario_id" => "leo_1",
            "starts_at_s" => 200.0,
            "ends_at_s" => 200.0,
            "duration_s" => 0.0,
            "score" => 0.0
          }
        ],
        "operator_review_package" => %{
          "schema_contract" => "operator_review_package.v1",
          "source_artifact_type" => "campaign_strategy.v3",
          "review_count" => 2,
          "rows" => [
            %{
              "id" => "operator_review:command_window:cmd_health_1",
              "review_type" => "command_window_review",
              "activity_id" => "cmd_health_1",
              "activity_type" => "health_check",
              "scenario_id" => "leo_1",
              "required_operator_action" => "review_command_contact",
              "action" => "review_command_contact",
              "approval_status" => "operator_review_required",
              "command_success_factor" => 0.25,
              "source_command_window" => %{
                "activity_id" => "cmd_health_1",
                "activity_type" => "health_check",
                "scenario_id" => "leo_1",
                "command_success_factor" => 0.25,
                "command_success_factor_source" => "operator_review_queue"
              }
            },
            %{
              "id" => "operator_review:maneuver_review:burn_impulsive",
              "review_type" => "maneuver_review",
              "maneuver_id" => "burn_impulsive",
              "maneuver_type" => "impulsive_burn",
              "scenario_id" => "leo_1",
              "required_operator_action" => "review_maneuver_recommendation",
              "action" => "review_maneuver_recommendation",
              "approval_status" => "operator_review_required",
              "maneuver_success_factor" => 0.4,
              "source_maneuver_review" => %{
                "maneuver_id" => "burn_impulsive",
                "maneuver_type" => "impulsive_burn",
                "scenario_id" => "leo_1",
                "maneuver_success_factor" => 0.4,
                "maneuver_success_factor_source" => "operator_review_queue",
                "execution_uncertainty" => %{
                  "timing_3sigma_s" => 90.0,
                  "delta_v_3sigma_km_s" => [0.0, 0.003, 0.0],
                  "source" => "review_queue_covariance"
                }
              }
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

    assert get_in(artifact, ["operational_feedback", "command_success_rate"]) == %{
             "cmd_health_1" => 0.25
           }

    assert get_in(artifact, ["operational_feedback", "maneuver_success_rate"]) == %{
             "burn_impulsive" => 0.4
           }

    assert get_in(artifact, ["operational_feedback", "maneuver_execution_uncertainty"]) == %{
             "burn_impulsive" => %{
               "execution_uncertainty_status" => "declared",
               "execution_uncertainty" => %{
                 "timing_3sigma_s" => 90.0,
                 "delta_v_3sigma_km_s" => [0.0, 0.003, 0.0],
                 "source" => "review_queue_covariance"
               },
               "timing_3sigma_s" => 90.0,
               "delta_v_3sigma_km_s" => [0.0, 0.003, 0.0],
               "delta_v_3sigma_magnitude_km_s" => 0.003,
               "execution_uncertainty_source" => "review_queue_covariance"
             }
           }

    assert Enum.any?(
             get_in(artifact, ["operational_feedback_provenance", "sources"]),
             &(&1["source"] == "prior_plan.operator_review_package.rows" and
                 &1["source_report_contract"] == "operator_review_package.v1" and
                 &1["source_report_row_count"] == 2 and
                 &1["source_review_type_counts"] == %{
                   "command_window_review" => 1,
                   "maneuver_review" => 1
                 } and
                 &1["source_review_action_counts"] == %{
                   "review_command_contact" => 1,
                   "review_maneuver_recommendation" => 1
                 })
           )

    command_branch = branch(artifact, "derived_command_success_feedback")

    assert %{
             "type" => "command_success_feedback",
             "activity_id" => "cmd_health_1",
             "command_success_factor" => 0.25
           } = List.first(command_branch["events"])

    maneuver_branch = branch(artifact, "derived_maneuver_success_feedback")

    assert %{
             "type" => "maneuver_success_feedback",
             "activity_id" => "burn_impulsive",
             "maneuver_success_factor" => 0.4
           } = List.first(maneuver_branch["events"])

    uncertainty_branch = branch(artifact, "derived_maneuver_execution_uncertainty_feedback")

    assert %{
             "type" => "maneuver_execution_uncertainty_feedback",
             "activity_id" => "burn_impulsive",
             "timing_3sigma_s" => 90.0,
             "execution_uncertainty_source" => "review_queue_covariance"
           } = List.first(uncertainty_branch["events"])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy replays operator review packages embedded in prior result artifacts" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          health_check("cmd_result_review", "leo_1", 100.0, 130.0)
        ],
        "source_result_artifact" => %{
          "schema_contract" => "result_artifact.v1",
          "metadata" => %{"trust_boundary" => "ops_operator_review_result_artifact"},
          "operator_review_package" => %{
            "schema_contract" => "operator_review_package.v1",
            "source_artifact_type" => "campaign_strategy.v3",
            "review_count" => 1,
            "rows" => [
              %{
                "id" => "operator_review:command_window:cmd_result_review",
                "review_type" => "command_window_review",
                "activity_id" => "cmd_result_review",
                "activity_type" => "health_check",
                "scenario_id" => "leo_1",
                "starts_at_s" => 100.0,
                "ends_at_s" => 130.0,
                "required_operator_action" => "review_command_contact",
                "action" => "review_command_contact",
                "approval_status" => "operator_review_required",
                "source_command_window" => %{
                  "activity_id" => "cmd_result_review",
                  "activity_type" => "health_check",
                  "scenario_id" => "leo_1",
                  "starts_at_s" => 100.0,
                  "ends_at_s" => 130.0,
                  "command_success_factor" => 0.25,
                  "command_success_factor_source" => "operator_review_queue"
                }
              }
            ]
          }
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    assert get_in(artifact, ["operational_feedback", "command_success_rate"]) == %{
             "cmd_result_review" => 0.25
           }

    assert Enum.any?(
             get_in(artifact, ["operational_feedback_provenance", "sources"]),
             &(&1["source"] == "prior_plan.operator_review_package.rows" and
                 &1["source_report_contract"] == "operator_review_package.v1" and
                 &1["source_report_count"] == 1 and
                 &1["source_report_row_count"] == 1 and
                 &1["source_review_type_counts"] == %{"command_window_review" => 1} and
                 &1["source_review_action_counts"] == %{"review_command_contact" => 1} and
                 &1["trust_boundaries"] == ["ops_operator_review_result_artifact"])
           )

    review_branch = branch(artifact, "derived_command_window_feedback_cmd_result_review")

    assert %{
             "type" => "command_success_feedback",
             "activity_id" => "cmd_result_review",
             "command_success_factor" => 0.25,
             "feedback_source" =>
               "prior_plan.source_result_artifact.operator_review_package.rows.source_command_window",
             "feedback_scope" => "command_window",
             "trust_boundary" => "ops_operator_review_result_artifact"
           } = List.first(review_branch["events"])

    feedback_branch = branch(artifact, "derived_command_success_feedback")

    assert %{
             "type" => "command_success_feedback",
             "activity_id" => "cmd_result_review",
             "command_success_factor" => 0.25,
             "feedback_source" => "operational_feedback.command_success_rate",
             "trust_boundary" => "ops_operator_review_result_artifact"
           } = List.first(feedback_branch["events"])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy replays Cadence import manifests embedded in prior result artifacts" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          health_check("cmd_result_import", "leo_1", 100.0, 130.0)
        ],
        "source_result_artifact" => %{
          "schema_contract" => "result_artifact.v1",
          "metadata" => %{"trust_boundary" => "ops_cadence_import_result_artifact"},
          "cadence_import_manifest" => %{
            "schema_contract" => "cadence_import_manifest.v1",
            "source_artifact_type" => "operator_review_package.v1",
            "row_count" => 1,
            "review_required_count" => 1,
            "rows" => [
              %{
                "id" => "cadence_import:command_window:cmd_result_import",
                "import_action" => "review_command_window",
                "source_review_type" => "command_window_review",
                "activity_id" => "cmd_result_import",
                "activity_type" => "health_check",
                "scenario_id" => "leo_1",
                "starts_at_s" => 100.0,
                "ends_at_s" => 130.0,
                "required_operator_action" => "review_command_contact",
                "action" => "review_command_contact",
                "approval_status" => "operator_review_required",
                "source_command_window" => %{
                  "activity_id" => "cmd_result_import",
                  "activity_type" => "health_check",
                  "scenario_id" => "leo_1",
                  "starts_at_s" => 100.0,
                  "ends_at_s" => 130.0,
                  "command_success_factor" => 0.25,
                  "command_success_factor_source" => "cadence_import_queue"
                }
              }
            ]
          }
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    assert get_in(artifact, ["operational_feedback", "command_success_rate"]) == %{
             "cmd_result_import" => 0.25
           }

    assert Enum.any?(
             get_in(artifact, ["operational_feedback_provenance", "sources"]),
             &(&1["source"] == "prior_plan.cadence_import_manifest.rows.source_review_row" and
                 &1["source_report_contract"] == "cadence_import_manifest.v1" and
                 &1["source_report_count"] == 1 and
                 &1["source_report_row_count"] == 1 and
                 &1["source_review_type_counts"] == %{"command_window_review" => 1} and
                 &1["source_review_action_counts"] == %{"review_command_contact" => 1} and
                 &1["trust_boundaries"] == ["ops_cadence_import_result_artifact"])
           )

    review_branch = branch(artifact, "derived_command_window_feedback_cmd_result_import")

    assert %{
             "type" => "command_success_feedback",
             "activity_id" => "cmd_result_import",
             "command_success_factor" => 0.25,
             "feedback_source" =>
               "prior_plan.source_result_artifact.cadence_import_manifest.rows.source_command_window",
             "feedback_scope" => "command_window",
             "trust_boundary" => "ops_cadence_import_result_artifact"
           } = List.first(review_branch["events"])

    feedback_branch = branch(artifact, "derived_command_success_feedback")

    assert %{
             "type" => "command_success_feedback",
             "activity_id" => "cmd_result_import",
             "command_success_factor" => 0.25,
             "feedback_source" => "operational_feedback.command_success_rate",
             "trust_boundary" => "ops_cadence_import_result_artifact"
           } = List.first(feedback_branch["events"])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
