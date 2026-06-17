Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyOperatorReviewFeedbackSourceTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy derives contact observation command and maneuver feedback from prior operator review timeline rows" do
    prior_plan =
      base_plan(%{
        "activities" => [
          downlink("dl_reviewed", 100.0, 160.0)
          |> Map.put("estimated_throughput_mb", 100.0),
          downlink("dl_reviewed_light", 170.0, 230.0)
          |> Map.put("estimated_throughput_mb", 100.0),
          observe("obs_reviewed", "leo_1", "target_a", 200.0, 260.0, 10.0),
          command("cmd_reviewed", "leo_1", 300.0, 330.0),
          %{
            "id" => "burn_timeline_reviewed",
            "type" => "impulsive_burn",
            "scenario_id" => "leo_1",
            "starts_at_s" => 400.0,
            "ends_at_s" => 400.0,
            "duration_s" => 0.0,
            "score" => 0.0
          }
        ],
        "operator_review_package" => %{
          "schema_contract" => "operator_review_package.v1",
          "source_artifact_type" => "campaign_strategy.v3",
          "review_count" => 5,
          "rows" => [
            %{
              "id" => "operator_review:operational_timeline:dl_reviewed",
              "review_type" => "operational_timeline_review",
              "activity_id" => "dl_reviewed",
              "activity_type" => "downlink",
              "ground_station_id" => "equator_prime",
              "required_operator_action" => "review_operational_timeline",
              "action" => "review_contact_feedback",
              "review_queue_key" =>
                "operational_timeline_review|review_contact_feedback|operator_review_required",
              "approval_status" => "operator_review_required",
              "source_operational_timeline" => %{
                "activity_id" => "dl_reviewed",
                "type" => "downlink",
                "scenario_id" => "leo_1",
                "ground_station_id" => "equator_prime",
                "contact_success_factor" => 0.25,
                "actual_throughput_mb" => 40.0,
                "estimated_throughput_mb" => 100.0,
                "confidence_weight" => "3.0",
                "confidence_weight_source" => "operator_sample_size"
              }
            },
            %{
              "id" => "operator_review:operational_timeline:dl_reviewed_light",
              "review_type" => "operational_timeline_review",
              "activity_id" => "dl_reviewed_light",
              "activity_type" => "downlink",
              "ground_station_id" => "equator_prime",
              "required_operator_action" => "review_operational_timeline",
              "action" => "review_contact_feedback",
              "review_queue_key" =>
                "operational_timeline_review|review_contact_feedback|operator_review_required",
              "approval_status" => "operator_review_required",
              "source_operational_timeline" => %{
                "activity_id" => "dl_reviewed_light",
                "type" => "downlink",
                "scenario_id" => "leo_1",
                "ground_station_id" => "equator_prime",
                "contact_success_factor" => 1.0,
                "actual_throughput_mb" => 100.0,
                "estimated_throughput_mb" => 100.0,
                "feedback_sample_weight" => "1.0"
              }
            },
            %{
              "id" => "operator_review:operational_timeline:obs_reviewed",
              "review_type" => "operational_timeline_review",
              "activity_id" => "obs_reviewed",
              "activity_type" => "observe",
              "target_id" => "target_a",
              "required_operator_action" => "review_operational_timeline",
              "action" => "review_observation_feedback",
              "review_queue_key" =>
                "operational_timeline_review|review_observation_feedback|operator_review_required",
              "approval_status" => "operator_review_required",
              "source_operational_timeline" => %{
                "activity_id" => "obs_reviewed",
                "type" => "observe",
                "scenario_id" => "leo_1",
                "target_id" => "target_a",
                "observation_success_factor" => 0.5
              }
            },
            %{
              "id" => "operator_review:operational_timeline:cmd_reviewed",
              "review_type" => "operational_timeline_review",
              "activity_id" => "cmd_reviewed",
              "activity_type" => "command",
              "ground_station_id" => "equator_prime",
              "required_operator_action" => "review_operational_timeline",
              "action" => "review_command_contact",
              "review_queue_key" =>
                "operational_timeline_review|review_command_contact|operator_review_required",
              "approval_status" => "operator_review_required",
              "source_operational_timeline" => %{
                "activity_id" => "cmd_reviewed",
                "type" => "command",
                "direction" => "command",
                "scenario_id" => "leo_1",
                "ground_station_id" => "equator_prime",
                "command_success_factor" => 0.25,
                "command_result" => ["accepted", "rejected"]
              }
            },
            %{
              "id" => "operator_review:operational_timeline:burn_timeline_reviewed",
              "review_type" => "operational_timeline_review",
              "activity_id" => "burn_timeline_reviewed",
              "activity_type" => "impulsive_burn",
              "required_operator_action" => "review_maneuver_recommendation",
              "review_queue_key" =>
                "operational_timeline_review|review_maneuver_recommendation|operator_review_required",
              "approval_status" => "operator_review_required",
              "source_operational_timeline" => %{
                "activity_id" => "burn_timeline_reviewed",
                "type" => "impulsive_burn",
                "scenario_id" => "leo_1",
                "maneuver_success_factor" => 0.35,
                "maneuver_result" => "accepted, partial",
                "execution_uncertainty" => %{
                  "timing_3sigma_s" => "85.0",
                  "delta_v_3sigma_km_s" => ["0.0", "0.0025", "0.0"],
                  "source" => "timeline_covariance"
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

    assert get_in(artifact, ["operational_feedback", "contact_success_rate"]) == %{
             "equator_prime" => 0.4375
           }

    assert get_in(artifact, ["operational_feedback", "station_throughput_factor"]) == %{
             "equator_prime" => 0.55
           }

    assert get_in(artifact, ["operational_feedback", "observation_success_rate"]) == %{
             "target_a" => 0.5
           }

    assert get_in(artifact, ["operational_feedback", "command_success_rate"]) == %{
             "cmd_reviewed" => 0.25
           }

    assert get_in(artifact, ["operational_feedback", "maneuver_success_rate"]) == %{
             "burn_timeline_reviewed" => 0.35
           }

    assert get_in(artifact, ["operational_feedback", "maneuver_execution_uncertainty"]) == %{
             "burn_timeline_reviewed" => %{
               "execution_uncertainty_status" => "declared",
               "execution_uncertainty" => %{
                 "timing_3sigma_s" => "85.0",
                 "delta_v_3sigma_km_s" => ["0.0", "0.0025", "0.0"],
                 "source" => "timeline_covariance"
               },
               "timing_3sigma_s" => 85.0,
               "delta_v_3sigma_km_s" => [0.0, 0.0025, 0.0],
               "delta_v_3sigma_magnitude_km_s" => 0.0025,
               "execution_uncertainty_source" => "timeline_covariance"
             }
           }

    assert Enum.any?(
             get_in(artifact, ["operational_feedback_provenance", "sources"]),
             &(&1["source"] == "prior_plan.operator_review_package.rows" and
                 &1["source_report_contract"] == "operator_review_package.v1" and
                 &1["source_report_row_count"] == 5 and
                 &1["source_review_type_counts"] == %{"operational_timeline_review" => 5} and
                 &1["source_review_action_counts"] == %{
                   "review_command_contact" => 1,
                   "review_contact_feedback" => 2,
                   "review_maneuver_recommendation" => 1,
                   "review_observation_feedback" => 1
                 } and
                 &1["source_review_queue_counts"] == %{
                   "operational_timeline_review|review_command_contact|operator_review_required" =>
                     1,
                   "operational_timeline_review|review_contact_feedback|operator_review_required" =>
                     2,
                   "operational_timeline_review|review_maneuver_recommendation|operator_review_required" =>
                     1,
                   "operational_timeline_review|review_observation_feedback|operator_review_required" =>
                     1
                 } and
                 &1["weighted_feedback_row_count"] == 2 and
                 &1["feedback_weight_sources"] == ["operator_sample_size"])
           )

    contact_branch = branch(artifact, "derived_contact_success_feedback")

    assert %{
             "type" => "contact_success_feedback",
             "ground_station_id" => "equator_prime",
             "contact_success_factor" => 0.4375,
             "feedback_source" => "operational_feedback.contact_success_rate"
           } = List.first(contact_branch["events"])

    observation_branch = branch(artifact, "derived_observation_success_feedback")

    assert %{
             "type" => "observation_success_feedback",
             "target_id" => "target_a",
             "observation_success_factor" => 0.5,
             "feedback_source" => "operational_feedback.observation_success_rate"
           } = List.first(observation_branch["events"])

    command_branch = branch(artifact, "derived_command_success_feedback")

    assert %{
             "type" => "command_success_feedback",
             "activity_id" => "cmd_reviewed",
             "command_success_factor" => 0.25,
             "feedback_source" => "operational_feedback.command_success_rate"
           } = List.first(command_branch["events"])

    assert_execution_feedback_pressure_score_terms(
      command_branch,
      artifact,
      "command_success_rate_low"
    )

    maneuver_branch = branch(artifact, "derived_maneuver_success_feedback")

    assert %{
             "type" => "maneuver_success_feedback",
             "activity_id" => "burn_timeline_reviewed",
             "maneuver_success_factor" => 0.35,
             "feedback_source" => "operational_feedback.maneuver_success_rate"
           } = List.first(maneuver_branch["events"])

    assert_execution_feedback_pressure_score_terms(
      maneuver_branch,
      artifact,
      "maneuver_success_rate_low"
    )

    uncertainty_branch = branch(artifact, "derived_maneuver_execution_uncertainty_feedback")

    assert %{
             "type" => "maneuver_execution_uncertainty_feedback",
             "activity_id" => "burn_timeline_reviewed",
             "timing_3sigma_s" => 85.0,
             "execution_uncertainty_source" => "timeline_covariance",
             "feedback_source" => "operational_feedback.maneuver_execution_uncertainty"
           } = List.first(uncertainty_branch["events"])

    assert_execution_feedback_pressure_score_terms(
      uncertainty_branch,
      artifact,
      "maneuver_execution_uncertainty_high"
    )

    row_contact_branch = branch(artifact, "derived_operational_timeline_feedback_dl_reviewed")

    assert [
             %{
               "type" => "contact_success_feedback",
               "activity_id" => "dl_reviewed",
               "ground_station_id" => "equator_prime",
               "contact_success_factor" => 0.25,
               "feedback_source" =>
                 "prior_plan.operator_review_package.rows.source_operational_timeline",
               "feedback_scope" => "operational_timeline",
               "derivation_reasons" => ["operational_timeline_contact_feedback"]
             },
             %{
               "type" => "station_throughput_feedback",
               "activity_id" => "dl_reviewed",
               "station_throughput_factor" => 0.4,
               "feedback_scope" => "operational_timeline",
               "derivation_reasons" => ["operational_timeline_contact_throughput"]
             }
           ] = row_contact_branch["events"]

    row_command_branch =
      branch(artifact, "derived_operational_timeline_feedback_cmd_reviewed")

    assert %{
             "type" => "command_success_feedback",
             "activity_id" => "cmd_reviewed",
             "command_success_factor" => 0.25,
             "feedback_scope" => "operational_timeline",
             "derivation_reasons" => ["operational_timeline_command_feedback"]
           } = List.first(row_command_branch["events"])

    row_maneuver_branch =
      branch(artifact, "derived_operational_timeline_feedback_burn_timeline_reviewed")

    assert Enum.any?(
             row_maneuver_branch["events"],
             &(&1["type"] == "maneuver_success_feedback" and
                 &1["activity_id"] == "burn_timeline_reviewed" and
                 &1["feedback_source"] ==
                   "prior_plan.operator_review_package.rows.source_operational_timeline" and
                 &1["derivation_reasons"] == ["operational_timeline_maneuver_feedback"])
           )

    assert Enum.any?(
             row_maneuver_branch["events"],
             &(&1["type"] == "maneuver_execution_uncertainty_feedback" and
                 &1["activity_id"] == "burn_timeline_reviewed" and
                 &1["timing_3sigma_s"] == 85.0 and
                 &1["execution_uncertainty_source"] == "timeline_covariance" and
                 &1["feedback_source"] ==
                   "prior_plan.operator_review_package.rows.source_operational_timeline" and
                 &1["derivation_reasons"] == ["operational_timeline_maneuver_uncertainty"])
           )

    refute branch(artifact, "derived_operational_timeline_feedback_dl_reviewed_light")

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives operational feedback from prior operator review realized feedback rows" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          downlink("dl_realized_review", 100.0, 160.0)
          |> Map.put("estimated_throughput_mb", 100.0),
          downlink("dl_realized_review_light", 170.0, 230.0)
          |> Map.put("estimated_throughput_mb", 100.0),
          observe("obs_realized_review", "leo_1", "target_a", 200.0, 260.0, 10.0),
          health_check("cmd_realized_review", "leo_1", 300.0, 330.0),
          %{
            "id" => "burn_realized_review",
            "type" => "impulsive_burn",
            "scenario_id" => "leo_1",
            "starts_at_s" => 400.0,
            "ends_at_s" => 400.0,
            "duration_s" => 0.0,
            "score" => 0.0
          }
        ],
        "operator_review_package" => %{
          "schema_contract" => "operator_review_package.v1",
          "source_artifact_type" => "timeline_feedback_report.v1",
          "review_count" => 5,
          "rows" => [
            %{
              "id" => "operator_review:realized_feedback:dl_realized_review",
              "review_type" => "realized_feedback",
              "activity_id" => "dl_realized_review",
              "activity_type" => "downlink",
              "feedback_status" => "matched",
              "realized_status" => "completed",
              "ground_station_id" => "equator_prime",
              "confidence_weight" => "3.0",
              "confidence_weight_source" => "operator_sample_size",
              "source_feedback" => %{
                "activity_id" => "dl_realized_review",
                "status" => "matched",
                "realized_status" => "completed",
                "planned_type" => "downlink",
                "ground_station_id" => "equator_prime",
                "contact_success_factor" => 0.2,
                "actual_throughput_mb" => 30.0,
                "estimated_throughput_mb" => 100.0,
                "required_downlink_mb" => 100.0
              }
            },
            %{
              "id" => "operator_review:realized_feedback:dl_realized_review_light",
              "review_type" => "realized_feedback",
              "activity_id" => "dl_realized_review_light",
              "activity_type" => "downlink",
              "feedback_status" => "matched",
              "realized_status" => "completed",
              "ground_station_id" => "equator_prime",
              "feedback_sample_weight" => "1.0",
              "source_feedback" => %{
                "activity_id" => "dl_realized_review_light",
                "status" => "matched",
                "realized_status" => "completed",
                "planned_type" => "downlink",
                "ground_station_id" => "equator_prime",
                "contact_success_factor" => 1.0,
                "actual_throughput_mb" => 100.0,
                "estimated_throughput_mb" => 100.0,
                "required_downlink_mb" => 100.0
              }
            },
            %{
              "id" => "operator_review:realized_feedback:obs_realized_review",
              "review_type" => "realized_feedback",
              "activity_id" => "obs_realized_review",
              "activity_type" => "observe",
              "feedback_status" => "matched",
              "realized_status" => "completed",
              "target_id" => "target_a",
              "source_feedback" => %{
                "activity_id" => "obs_realized_review",
                "status" => "matched",
                "realized_status" => "completed",
                "planned_type" => "observe",
                "target_id" => "target_a",
                "observation_success_factor" => 0.4
              }
            },
            %{
              "id" => "operator_review:realized_feedback:cmd_realized_review",
              "review_type" => "realized_feedback",
              "activity_id" => "cmd_realized_review",
              "activity_type" => "health_check",
              "feedback_status" => "matched",
              "realized_status" => "completed",
              "source_feedback" => %{
                "activity_id" => "cmd_realized_review",
                "status" => "matched",
                "realized_status" => "completed",
                "planned_type" => "health_check",
                "command_success_factor" => 0.3
              }
            },
            %{
              "id" => "operator_review:realized_feedback:burn_realized_review",
              "review_type" => "realized_feedback",
              "activity_id" => "burn_realized_review",
              "activity_type" => "impulsive_burn",
              "feedback_status" => "matched",
              "realized_status" => "completed",
              "source_feedback" => %{
                "activity_id" => "burn_realized_review",
                "status" => "matched",
                "realized_status" => "completed",
                "planned_type" => "impulsive_burn",
                "maneuver_success_factor" => 0.6,
                "execution_uncertainty" => %{
                  "timing_3sigma_s" => "70.0",
                  "delta_v_3sigma_km_s" => ["0.0", "0.0015", "0.0"],
                  "source" => "realized_feedback_covariance"
                }
              }
            }
          ]
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}, %{id: "manual_review", events: [%{type: "operator_note"}]}],
        current_epoch_s: 0.0
      )

    assert get_in(artifact, ["operational_feedback", "contact_success_rate"]) == %{
             "equator_prime" => 0.4
           }

    assert get_in(artifact, ["operational_feedback", "station_throughput_factor"]) == %{
             "equator_prime" => 0.475
           }

    assert get_in(artifact, ["operational_feedback", "observation_success_rate"]) == %{
             "target_a" => 0.4
           }

    assert get_in(artifact, ["operational_feedback", "command_success_rate"]) == %{
             "cmd_realized_review" => 0.3
           }

    assert get_in(artifact, ["operational_feedback", "maneuver_success_rate"]) == %{
             "burn_realized_review" => 0.6
           }

    assert get_in(artifact, ["operational_feedback", "maneuver_execution_uncertainty"]) == %{
             "burn_realized_review" => %{
               "execution_uncertainty_status" => "declared",
               "execution_uncertainty" => %{
                 "timing_3sigma_s" => "70.0",
                 "delta_v_3sigma_km_s" => ["0.0", "0.0015", "0.0"],
                 "source" => "realized_feedback_covariance"
               },
               "timing_3sigma_s" => 70.0,
               "delta_v_3sigma_km_s" => [0.0, 0.0015, 0.0],
               "delta_v_3sigma_magnitude_km_s" => 0.0015,
               "execution_uncertainty_source" => "realized_feedback_covariance"
             }
           }

    assert get_in(artifact, ["operational_feedback", "downlink_demand_mb"]) == %{
             "equator_prime" => 210.0
           }

    assert Enum.any?(
             get_in(artifact, ["operational_feedback_provenance", "sources"]),
             &(&1["source"] == "prior_plan.operator_review_package.rows" and
                 &1["source_report_contract"] == "operator_review_package.v1" and
                 &1["source_report_row_count"] == 5 and
                 &1["source_review_type_counts"] == %{"realized_feedback" => 5} and
                 &1["weighted_feedback_row_count"] == 2 and
                 &1["feedback_weight_sources"] == ["operator_sample_size"])
           )

    assert %{"contact_success_factor" => 0.4} =
             List.first(branch(artifact, "derived_contact_success_feedback")["events"])

    assert %{
             "type" => "downlink_demand_feedback",
             "ground_station_id" => "equator_prime",
             "required_downlink_mb" => 210.0
           } = List.first(branch(artifact, "derived_downlink_demand_feedback")["events"])

    assert %{"observation_success_factor" => 0.4} =
             List.first(branch(artifact, "derived_observation_success_feedback")["events"])

    assert %{"command_success_factor" => 0.3} =
             List.first(branch(artifact, "derived_command_success_feedback")["events"])

    assert %{"maneuver_success_factor" => 0.6} =
             List.first(branch(artifact, "derived_maneuver_success_feedback")["events"])

    realized_maneuver_branch = branch(artifact, "derived_realized_feedback_burn_realized_review")

    assert Enum.any?(
             realized_maneuver_branch["events"],
             &(&1["type"] == "maneuver_success_feedback" and
                 &1["activity_id"] == "burn_realized_review" and
                 &1["derivation_reasons"] == ["realized_maneuver_feedback"])
           )

    assert Enum.any?(
             realized_maneuver_branch["events"],
             &(&1["type"] == "maneuver_execution_uncertainty_feedback" and
                 &1["activity_id"] == "burn_realized_review" and
                 &1["timing_3sigma_s"] == 70.0 and
                 &1["execution_uncertainty_source"] == "realized_feedback_covariance" and
                 &1["feedback_source"] ==
                   "prior_plan.operator_review_package.rows.source_feedback" and
                 &1["derivation_reasons"] == ["realized_maneuver_uncertainty"])
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  defp assert_execution_feedback_pressure_score_terms(branch, artifact, risk_types) do
    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])
    expected_risk_types = List.wrap(risk_types)

    execution_feedback_risk_types =
      ~w(contact_success_rate_low observation_success_rate_low station_throughput_factor_low command_success_rate_low maneuver_success_rate_low maneuver_execution_uncertainty_high maneuver_execution_uncertainty_missing)

    Enum.each(expected_risk_types, fn risk_type ->
      assert Enum.any?(branch["risk_indicators"], &(&1["type"] == risk_type))
    end)

    execution_feedback_pressure_count =
      Enum.count(
        branch["risk_indicators"],
        &(&1["type"] in execution_feedback_risk_types)
      )

    assert execution_feedback_pressure_count > 0

    assert branch["score_terms"]["execution_feedback_pressure_penalty"] ==
             -execution_feedback_pressure_count * risk_weight

    assert branch["score_terms"]["risk_penalty"] ==
             -(length(branch["risk_indicators"]) - execution_feedback_pressure_count) *
               risk_weight

    assert "execution_feedback_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == branch["branch_id"] and
                 &1["term_key"] == "execution_feedback_pressure_penalty" and
                 &1["value"] < 0.0)
           )
  end

  defp command(id, scenario_id, starts_at_s, ends_at_s) do
    %{
      "id" => id,
      "type" => "command",
      "scenario_id" => scenario_id,
      "direction" => "uplink",
      "ground_station_id" => "equator_prime",
      "starts_at_s" => starts_at_s,
      "ends_at_s" => ends_at_s,
      "duration_s" => ends_at_s - starts_at_s,
      "score" => 1.0
    }
  end
end
