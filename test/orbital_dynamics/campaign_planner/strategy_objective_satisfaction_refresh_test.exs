Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyObjectiveSatisfactionRefreshTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy derives target refresh from prior objective satisfaction target gaps" do
    prior_plan =
      base_plan(%{
        "activities" => [
          observe("obs_target_b_selected", "leo_1", "target_b", 520.0, 580.0, 12.0)
        ],
        "candidate_activities" => [
          observe("obs_target_b_too_early", "leo_1", "target_b", 360.0, 420.0, 12.0),
          observe("obs_target_b_recovery", "leo_1", "target_b", 590.0, 650.0, 12.0)
        ],
        "objective_satisfaction_report" => %{
          "schema_contract" => "objective_satisfaction_report.v1",
          "model" => "campaign_v1_selected_activity_objective_summary",
          "source" => "campaign_plan.activities",
          "objective_count" => 1,
          "provenance" => %{"trust_boundary" => "ops_objective_review"},
          "rows" => [
            %{
              "id" => "objective:target_coverage",
              "objective" => "target-coverage",
              "status" => "Not Satisfied",
              "scenario_id" => "leo_1",
              "starts_at_s" => 500.0,
              "ends_at_s" => 660.0,
              "required_observation_count" => 2,
              "selected_observation_count" => 1,
              "candidate_target_ids" => ["target_a", "target_b"],
              "selected_target_ids" => ["target_a"]
            }
          ]
        }
      })

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.update!(:targets, fn targets ->
        targets ++
          [
            %{
              id: "target_b",
              latitude_deg: 5.0,
              longitude_deg: 5.0,
              minimum_elevation_deg: 10.0,
              priority: 3.0
            }
          ]
      end)

    artifact =
      strategy(prior_plan,
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    pressure_branch =
      branch(artifact, "derived_objective_satisfaction_objective:target_coverage:target_b")

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             pressure_branch["assumptions"]["candidate_source"]

    assert %{
             "type" => "urgent_target",
             "objective_id" => "objective:target_coverage",
             "objective_type" => "target_coverage",
             "target_id" => "target_b",
             "scenario_id" => "leo_1",
             "starts_at_s" => 500.0,
             "ends_at_s" => 660.0,
             "planned_observations" => 1,
             "required_observations" => 2,
             "coverage_objective_id" => "objective:target_coverage",
             "feedback_source" => "prior_plan.objective_satisfaction_report",
             "feedback_scope" => "objective_satisfaction",
             "objective_status" => "unmet",
             "trust_boundary" => "ops_objective_review"
           } = List.first(pressure_branch["events"])

    assert [
             %{
               "id" =>
                 "derived_objective_satisfaction_objective:target_coverage:target_b_urgent_observe_target_b",
               "target_id" => "target_b",
               "starts_at_s" => 590.0,
               "repair" => %{"reason" => "target_coverage_candidate_inserted"}
             }
           ] = pressure_branch["candidate_plan"]["strategic_additions"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives observation-quality refresh from objective satisfaction rows" do
    prior_plan =
      base_plan(%{
        "source_objective_satisfaction_report" => %{
          "schema_contract" => "objective_satisfaction_report.v1",
          "model" => "provider_observation_quality_summary",
          "source" => "provider.objective_summary",
          "objective_count" => 1,
          "provenance" => %{"trust_boundary" => "provider_quality_review"},
          "rows" => [
            %{
              "id" => "objective:observation_quality",
              "objective" => "observation quality",
              "status" => "degraded",
              "target_id" => "target_a",
              "scenario_id" => "leo_1",
              "source_observation" => %{"activity_id" => "obs_quality_source"},
              "image_quality_score" => "0.35",
              "image_quality_status" => "marginal",
              "image_quality_source" => "provider_imagery_quality",
              "cloud_cover_fraction" => "0.65",
              "blur_score" => "0.25"
            }
          ]
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    quality_branch =
      branch(artifact, "derived_objective_satisfaction_objective:observation_quality:target_a")

    assert %{
             "type" => "observation_success_feedback",
             "objective_id" => "objective:observation_quality",
             "objective_type" => "observation_quality",
             "target_id" => "target_a",
             "scenario_id" => "leo_1",
             "observation_success_factor" => 0.35,
             "image_quality_score" => 0.35,
             "image_quality_status" => "marginal",
             "image_quality_source" => "provider_imagery_quality",
             "cloud_cover_fraction" => 0.65,
             "blur_score" => 0.25,
             "source_activity_id" => "obs_quality_source",
             "source_activity_ids" => ["obs_quality_source"],
             "feedback_source" => "prior_plan.source_objective_satisfaction_report",
             "feedback_scope" => "objective_satisfaction",
             "quality_feedback_source" => "objective_satisfaction.image_quality_score",
             "objective_status" => "partial",
             "source_objective_status" => "degraded",
             "trust_boundary" => "provider_quality_review"
           } = List.first(quality_branch["events"])

    assert Enum.sort(
             quality_branch["assumptions"]["candidate_source"][
               "operational_feedback_input_keys"
             ]
           ) == [
             "blur_score",
             "cloud_cover_fraction",
             "image_quality_score",
             "image_quality_source",
             "image_quality_status",
             "observation_success_rate"
           ]

    quality_observation =
      quality_branch["candidate_plan"]["strategic_additions"]
      |> Enum.find(&(&1["type"] == "observe" and &1["target_id"] == "target_a"))

    assert quality_observation["repair"]["reason"] ==
             "observation_success_feedback_candidate_inserted"

    assert quality_observation["image_quality_score"] == 0.35
    assert quality_observation["image_quality_status"] == "marginal"
    assert quality_observation["image_quality_source"] == "provider_imagery_quality"
    assert quality_observation["cloud_cover_fraction"] == 0.65
    assert quality_observation["blur_score"] == 0.25

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives target refresh from objective satisfaction target-gap aliases" do
    prior_plan =
      base_plan(%{
        "candidate_activities" => [
          observe("obs_target_c", "leo_1", "target_c", 360.0, 420.0, 12.0)
        ],
        "objective_satisfaction_report" => %{
          "schema_contract" => "objective_satisfaction_report.v1",
          "model" => "provider_target_coverage_summary",
          "source" => "provider.objective_summary",
          "objective_count" => 1,
          "provenance" => %{"trust_boundary" => "provider_objective_review"},
          "rows" => [
            %{
              "id" => "objective:coverage_aliases",
              "objective" => "coverage",
              "status" => "unmet",
              "required_count" => 1,
              "selected_count" => 0,
              "missing_coverage_targets" => [
                %{
                  "id" => "target_c",
                  "priority" => "5.0",
                  "latitude_deg" => 8.0,
                  "longitude_deg" => 8.0,
                  "minimum_elevation_deg" => 10.0
                }
              ],
              "selected_coverage_target_ids" => ["target_a"]
            }
          ]
        }
      })

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.update!(:targets, fn targets ->
        targets ++
          [
            %{
              id: "target_c",
              latitude_deg: 8.0,
              longitude_deg: 8.0,
              minimum_elevation_deg: 10.0,
              priority: 4.0
            }
          ]
      end)

    artifact =
      strategy(prior_plan,
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    pressure_branch =
      branch(artifact, "derived_objective_satisfaction_objective:coverage_aliases:target_c")

    assert %{
             "type" => "urgent_target",
             "objective_id" => "objective:coverage_aliases",
             "objective_type" => "target_coverage",
             "target_id" => "target_c",
             "priority" => 5.0,
             "latitude_deg" => 8.0,
             "longitude_deg" => 8.0,
             "minimum_elevation_deg" => 10.0,
             "planned_observations" => 0,
             "required_observations" => 1,
             "feedback_source" => "prior_plan.objective_satisfaction_report",
             "feedback_scope" => "objective_satisfaction",
             "objective_status" => "unmet",
             "trust_boundary" => "provider_objective_review"
           } = List.first(pressure_branch["events"])

    assert Enum.any?(
             pressure_branch["candidate_plan"]["strategic_additions"],
             &(&1["target_id"] == "target_c" and
                 get_in(&1, ["feasibility", "feedback_scope"]) == "objective_satisfaction")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy scopes objective satisfaction target refresh from nested source observation metadata" do
    prior_plan =
      base_plan(%{
        "candidate_activities" => [
          observe("obs_nested_target", "leo_1", "target_nested_context", 360.0, 420.0, 12.0),
          observe(
            "obs_nested_target_wrong_spacecraft",
            "leo_2",
            "target_nested_context",
            300.0,
            360.0,
            20.0
          )
        ],
        "source_objective_satisfaction_report" => %{
          "schema_contract" => "objective_satisfaction_report.v1",
          "model" => "provider_target_coverage_summary",
          "source" => "provider.objective_summary",
          "objective_count" => 1,
          "provenance" => %{"trust_boundary" => "provider_objective_review"},
          "rows" => [
            %{
              "id" => "objective:nested_target_context",
              "objective" => "coverage",
              "status" => "unmet",
              "required_count" => 1,
              "selected_count" => 0,
              "source_observation" => %{
                "activity_id" => "obs_nested_source",
                "scenario_id" => "leo_1",
                "target_id" => "target_nested_context",
                "priority" => 7.0,
                "latitude_deg" => 4.0,
                "longitude_deg" => 5.0,
                "minimum_elevation_deg" => 12.0
              }
            }
          ]
        }
      })

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:targets, [])

    artifact =
      strategy(prior_plan,
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    branch =
      branch(
        artifact,
        "derived_objective_satisfaction_objective:nested_target_context:target_nested_context"
      )

    assert %{
             "type" => "urgent_target",
             "objective_id" => "objective:nested_target_context",
             "objective_type" => "target_coverage",
             "target_id" => "target_nested_context",
             "scenario_id" => "leo_1",
             "spacecraft_id" => "leo_1",
             "priority" => 7.0,
             "latitude_deg" => 4.0,
             "longitude_deg" => 5.0,
             "minimum_elevation_deg" => 12.0,
             "planned_observations" => 0,
             "required_observations" => 1,
             "source_activity_ids" => ["obs_nested_source"],
             "feedback_source" => "prior_plan.source_objective_satisfaction_report",
             "feedback_scope" => "objective_satisfaction",
             "objective_status" => "unmet",
             "trust_boundary" => "provider_objective_review"
           } = List.first(branch["events"])

    assert [
             %{
               "id" =>
                 "derived_objective_satisfaction_objective:nested_target_context:target_nested_context_urgent_observe_target_nested_context",
               "target_id" => "target_nested_context",
               "scenario_id" => "leo_1"
             }
           ] = branch["candidate_plan"]["strategic_additions"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives objective satisfaction refresh from result artifact reports" do
    prior_plan =
      base_plan(%{
        "candidate_activities" => [
          observe(
            "obs_result_artifact_target",
            "leo_1",
            "target_result_artifact",
            360.0,
            420.0,
            12.0
          )
        ],
        "source_result_artifact" => %{
          "schema_contract" => "result_artifact.v1",
          "study_id" => "objective_satisfaction_result_artifact",
          "provenance" => %{"trust_boundary" => "ops_result_artifact"},
          "objective_satisfaction_report" => %{
            "schema_contract" => "objective_satisfaction_report.v1",
            "model" => "provider_target_coverage_summary",
            "source" => "provider.objective_summary",
            "objective_count" => 1,
            "rows" => [
              %{
                "id" => "objective:result_artifact_coverage",
                "objective" => "coverage",
                "status" => "unmet",
                "required_count" => 1,
                "selected_count" => 0,
                "uncovered_target_ids" => ["target_result_artifact"]
              }
            ]
          }
        }
      })

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.update!(:targets, fn targets ->
        targets ++
          [
            %{
              id: "target_result_artifact",
              latitude_deg: 8.0,
              longitude_deg: 8.0,
              minimum_elevation_deg: 10.0,
              priority: 4.0
            }
          ]
      end)

    artifact =
      strategy(prior_plan,
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    pressure_branch =
      branch(
        artifact,
        "derived_objective_satisfaction_objective:result_artifact_coverage:target_result_artifact"
      )

    assert %{
             "type" => "urgent_target",
             "objective_id" => "objective:result_artifact_coverage",
             "objective_type" => "target_coverage",
             "target_id" => "target_result_artifact",
             "planned_observations" => 0,
             "required_observations" => 1,
             "feedback_source" =>
               "prior_plan.source_result_artifact.objective_satisfaction_report",
             "feedback_scope" => "objective_satisfaction",
             "objective_status" => "unmet",
             "trust_boundary" => "ops_result_artifact"
           } = List.first(pressure_branch["events"])

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             pressure_branch["assumptions"]["candidate_source"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives target refresh observation counts from objective satisfaction target lists" do
    prior_plan =
      base_plan(%{
        "candidate_activities" => [
          observe("obs_target_list_recovery", "leo_1", "target_list_b", 360.0, 420.0, 12.0)
        ],
        "source_objective_satisfaction_report" => %{
          "schema_contract" => "objective_satisfaction_report.v1",
          "model" => "provider_target_coverage_summary",
          "source" => "provider.objective_summary",
          "objective_count" => 1,
          "provenance" => %{"trust_boundary" => "provider_objective_review"},
          "rows" => [
            %{
              "id" => "objective:target_list_counts",
              "objective" => "coverage",
              "status" => "below target",
              "candidate_targets" => [
                %{"id" => "target_list_a", "priority" => 3.0},
                %{"id" => "target_list_b", "priority" => 8.0}
              ],
              "selected_targets" => [%{"id" => "target_list_a"}],
              "source_activity" => %{"id" => "obs_target_list_source"},
              "candidate_activity" => %{"activity_id" => "obs_target_list_candidate"},
              "selected_observations" => [
                %{"activity_id" => "obs_target_list_selected", "target_id" => "target_list_a"}
              ]
            }
          ]
        }
      })

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:targets, [])

    artifact =
      strategy(prior_plan,
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    branch =
      branch(
        artifact,
        "derived_objective_satisfaction_objective:target_list_counts:target_list_b"
      )

    assert %{
             "type" => "urgent_target",
             "target_id" => "target_list_b",
             "priority" => 8.0,
             "required_observations" => 2,
             "planned_observations" => 1,
             "source_activity_ids" => [
               "obs_target_list_candidate",
               "obs_target_list_selected",
               "obs_target_list_source"
             ],
             "objective_status" => "partial",
             "source_objective_status" => "below_target",
             "feedback_source" => "prior_plan.source_objective_satisfaction_report",
             "trust_boundary" => "provider_objective_review"
           } = List.first(branch["events"])

    assert Enum.any?(
             branch["candidate_plan"]["strategic_additions"],
             &(&1["target_id"] == "target_list_b" and
                 get_in(&1, ["feasibility", "required_observations"]) == 2)
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives objective satisfaction target counts from direct observation shortfall aliases" do
    prior_plan =
      base_plan(%{
        "candidate_activities" => [
          observe("obs_shortfall_recovery_a", "leo_1", "target_shortfall", 360.0, 420.0, 12.0),
          observe("obs_shortfall_recovery_b", "leo_1", "target_shortfall", 480.0, 540.0, 12.0)
        ],
        "source_objective_satisfaction_report" => %{
          "schema_contract" => "objective_satisfaction_report.v1",
          "model" => "provider_target_shortfall_summary",
          "source" => "provider.objective_summary",
          "objective_count" => 1,
          "provenance" => %{"trust_boundary" => "provider_shortfall_review"},
          "rows" => [
            %{
              "id" => "objective:direct_observation_shortfall",
              "objective" => "target coverage",
              "status" => "partial",
              "target" => %{
                "id" => "target_shortfall",
                "priority" => "6.0",
                "latitude_deg" => 14.0,
                "longitude_deg" => -23.0,
                "minimum_elevation_deg" => 13.0
              },
              "selected_observation_count" => "1",
              "observation_shortfall_count" => "2"
            }
          ]
        }
      })

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:targets, [])

    artifact =
      strategy(prior_plan,
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    branch =
      branch(
        artifact,
        "derived_objective_satisfaction_objective:direct_observation_shortfall:target_shortfall"
      )

    assert %{
             "type" => "urgent_target",
             "objective_type" => "target_coverage",
             "target_id" => "target_shortfall",
             "priority" => 6.0,
             "planned_observations" => 1.0,
             "required_observations" => 3,
             "feedback_source" => "prior_plan.source_objective_satisfaction_report",
             "feedback_scope" => "objective_satisfaction",
             "objective_status" => "partial",
             "trust_boundary" => "provider_shortfall_review",
             "derivation_reasons" => [
               "objective_satisfaction_target_gap",
               "objective_status_partial"
             ]
           } = List.first(branch["events"])

    additions =
      Enum.filter(
        branch["candidate_plan"]["strategic_additions"],
        &(&1["target_id"] == "target_shortfall")
      )

    assert length(additions) >= 2

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives target refresh from objective satisfaction missed-observation target aliases" do
    prior_plan =
      base_plan(%{
        "candidate_activities" => [
          observe(
            "obs_missed_observation_recovery",
            "leo_1",
            "target_missed_obs",
            360.0,
            420.0,
            12.0
          )
        ],
        "source_objective_satisfaction_report" => %{
          "schema_contract" => "objective_satisfaction_report.v1",
          "model" => "provider_missed_observation_summary",
          "source" => "provider.objective_summary",
          "objective_count" => 1,
          "provenance" => %{"trust_boundary" => "provider_missed_observation_review"},
          "rows" => [
            %{
              "id" => "objective:missed_observation_aliases",
              "objective" => "target_coverage",
              "status" => "partial",
              "selected_observation_count" => 0,
              "missed_observation_target_ids" => ["target_missed_obs"],
              "missed_observation_targets" => [
                %{
                  "id" => "target_missed_obs",
                  "priority" => "7.0",
                  "latitude_deg" => 19.5,
                  "longitude_deg" => -41.25,
                  "minimum_elevation_deg" => 12.0
                }
              ]
            }
          ]
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs() |> Map.put(:targets, []),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    branch =
      branch(
        artifact,
        "derived_objective_satisfaction_objective:missed_observation_aliases:target_missed_obs"
      )

    assert %{
             "type" => "urgent_target",
             "objective_id" => "objective:missed_observation_aliases",
             "objective_type" => "target_coverage",
             "target_id" => "target_missed_obs",
             "priority" => 7.0,
             "latitude_deg" => 19.5,
             "longitude_deg" => -41.25,
             "minimum_elevation_deg" => 12.0,
             "planned_observations" => 0,
             "required_observations" => 1,
             "feedback_source" => "prior_plan.source_objective_satisfaction_report",
             "feedback_scope" => "objective_satisfaction",
             "objective_status" => "partial",
             "trust_boundary" => "provider_missed_observation_review"
           } = List.first(branch["events"])

    candidate_source = get_in(branch, ["assumptions", "candidate_source"])

    assert "prior_plan.source_objective_satisfaction_report" in candidate_source[
             "source_report_input_paths"
           ]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives downlink refresh from objective satisfaction station object aliases" do
    prior_plan =
      base_plan(%{
        "candidate_activities" => [
          refreshed_downlink("dl_objective_station_alias", 360.0, 420.0)
          |> Map.put("estimated_throughput_mb", 55.0)
        ],
        "objective_satisfaction_report" => %{
          "schema_contract" => "objective_satisfaction_report.v1",
          "model" => "provider_downlink_objective_summary",
          "source" => "provider.objective_summary",
          "objective_count" => 1,
          "provenance" => %{"trust_boundary" => "provider_objective_review"},
          "rows" => [
            %{
              "id" => "objective:downlink_station_object",
              "objective" => "downlink-completion",
              "status" => "partial",
              "scenario_id" => "leo_1",
              "station" => %{"id" => "equator_prime", "provider" => "fixture_network"},
              "required_downlink_mb" => 55.0,
              "planned_downlink_mb" => 10.0,
              "required_contact_count" => 1,
              "selected_contact_count" => 0,
              "selected_contact_ids" => ["dl_short"]
            }
          ]
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    pressure_branch =
      branch(artifact, "derived_objective_satisfaction_objective:downlink_station_object")

    assert %{
             "type" => "downlink_completion_gap",
             "objective_id" => "objective:downlink_station_object",
             "objective_type" => "downlink_completion",
             "ground_station_id" => "equator_prime",
             "required_contacts" => 1,
             "planned_contacts" => 0,
             "required_downlink_mb" => 55.0,
             "planned_downlink_mb" => 10.0,
             "source_activity_ids" => ["dl_short"],
             "feedback_source" => "prior_plan.objective_satisfaction_report",
             "feedback_scope" => "objective_satisfaction",
             "objective_status" => "partial",
             "trust_boundary" => "provider_objective_review"
           } = List.first(pressure_branch["events"])

    assert Enum.any?(
             pressure_branch["candidate_plan"]["strategic_additions"],
             &(&1["type"] == "downlink" and &1["ground_station_id"] == "equator_prime")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives downlink refresh from objective satisfaction contact object aliases" do
    prior_plan =
      base_plan(%{
        "candidate_activities" => [
          refreshed_downlink("dl_objective_contact_object", 360.0, 420.0)
        ],
        "objective_satisfaction_report" => %{
          "schema_contract" => "objective_satisfaction_report.v1",
          "model" => "provider_downlink_objective_summary",
          "source" => "provider.objective_summary",
          "objective_count" => 1,
          "provenance" => %{"trust_boundary" => "provider_objective_review"},
          "rows" => [
            %{
              "id" => "objective:downlink_contact_objects",
              "objective" => "downlink_completion",
              "status" => "partial",
              "ground_station_id" => "equator_prime",
              "required_downlink_contacts" => [
                %{"id" => "dl_selected_object"},
                %{"downlink_activity_id" => "dl_missing_object"}
              ],
              "selected_contacts" => [
                %{"activity_id" => "dl_selected_object", "ground_station_id" => "equator_prime"}
              ],
              "source_contact" => %{"source_activity_id" => "dl_source_contact"}
            }
          ]
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    pressure_branch =
      branch(artifact, "derived_objective_satisfaction_objective:downlink_contact_objects")

    assert %{
             "type" => "downlink_completion_gap",
             "objective_id" => "objective:downlink_contact_objects",
             "required_contacts" => 2,
             "planned_contacts" => 1,
             "source_activity_ids" => [
               "dl_missing_object",
               "dl_selected_object",
               "dl_source_contact"
             ],
             "derivation_reasons" => [
               "objective_satisfaction_contact_gap",
               "objective_status_partial"
             ],
             "feedback_source" => "prior_plan.objective_satisfaction_report",
             "trust_boundary" => "provider_objective_review"
           } = List.first(pressure_branch["events"])

    assert Enum.any?(
             pressure_branch["candidate_plan"]["strategic_additions"],
             &(&1["type"] == "downlink" and &1["ground_station_id"] == "equator_prime" and
                 get_in(&1, ["feasibility", "required_contacts"]) == 2)
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives objective satisfaction refresh from provider status aliases" do
    prior_plan =
      base_plan(%{
        "activities" => [
          observe("obs_status_late", "leo_1", "target_a", 120.0, 180.0, 12.0)
          |> Map.put("collection_id", "collection_status_late")
        ],
        "candidate_activities" => [
          refreshed_downlink("dl_status_downlink_recovery", 360.0, 420.0)
          |> Map.put("estimated_throughput_mb", 80.0),
          observe(
            "obs_status_target_recovery",
            "leo_1",
            "target_status_alias",
            480.0,
            540.0,
            12.0
          ),
          refreshed_downlink("dl_status_latency_recovery", 600.0, 660.0)
          |> Map.put("collection_id", "collection_status_late")
          |> Map.put("estimated_throughput_mb", 40.0)
        ],
        "source_objective_satisfaction_report" => %{
          "schema_contract" => "objective_satisfaction_report.v1",
          "model" => "provider_objective_status_aliases",
          "source" => "provider.objective_summary",
          "objective_count" => 3,
          "provenance" => %{"trust_boundary" => "provider_objective_review"},
          "rows" => [
            %{
              "id" => "objective:provider_status_downlink",
              "objective" => "downlink_completion",
              "status" => "Below Target",
              "ground_station_id" => "equator_prime",
              "required_downlink_mb" => 80.0,
              "planned_downlink_mb" => 20.0,
              "required_contact_count" => 1,
              "selected_contact_count" => 0,
              "selected_contact_ids" => ["dl_below_target"]
            },
            %{
              "id" => "objective:provider_status_target",
              "objective" => "target coverage",
              "status" => "At Risk",
              "target" => %{
                "id" => "target_status_alias",
                "priority" => "7.0",
                "latitude_deg" => 9.0,
                "longitude_deg" => 11.0,
                "minimum_elevation_deg" => 12.0
              },
              "required_observation_count" => 1,
              "selected_observation_count" => 0,
              "selected_targets" => [%{"id" => "target_a"}]
            },
            %{
              "id" => "objective:provider_status_latency",
              "objective" => "collection latency",
              "status" => "Late",
              "source_activity_id" => "obs_status_late",
              "target_id" => "target_a",
              "scenario_id" => "leo_1",
              "ground_station_id" => "equator_prime",
              "collection_id" => "collection_status_late",
              "max_latency_s" => 120.0,
              "planned_latency_s" => 240.0,
              "required_downlink_mb" => 40.0,
              "planned_downlink_mb" => 0.0
            }
          ]
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    downlink_branch =
      branch(artifact, "derived_objective_satisfaction_objective:provider_status_downlink")

    assert %{
             "type" => "downlink_completion_gap",
             "objective_status" => "partial",
             "source_objective_status" => "below_target",
             "required_downlink_mb" => 80.0,
             "planned_downlink_mb" => 20.0,
             "derivation_reasons" => downlink_reasons
           } = List.first(downlink_branch["events"])

    assert "objective_status_partial" in downlink_reasons

    target_branch =
      branch(
        artifact,
        "derived_objective_satisfaction_objective:provider_status_target:target_status_alias"
      )

    assert %{
             "type" => "urgent_target",
             "target_id" => "target_status_alias",
             "objective_status" => "partial",
             "source_objective_status" => "at_risk",
             "priority" => 7.0,
             "required_observations" => 1,
             "planned_observations" => 0,
             "derivation_reasons" => target_reasons
           } = List.first(target_branch["events"])

    assert "objective_status_partial" in target_reasons

    latency_branch =
      branch(
        artifact,
        "derived_objective_satisfaction_objective:provider_status_latency:obs_status_late"
      )

    assert %{
             "type" => "downlink_completion_gap",
             "objective_type" => "collection_latency",
             "latency_objective" => true,
             "source_activity_id" => "obs_status_late",
             "objective_status" => "unmet",
             "source_objective_status" => "late",
             "max_latency_s" => 120.0,
             "planned_latency_s" => 240.0,
             "derivation_reasons" => latency_reasons
           } = List.first(latency_branch["events"])

    assert "objective_status_unmet" in latency_reasons

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives objective satisfaction refresh from status field aliases and booleans" do
    prior_plan =
      base_plan(%{
        "candidate_activities" => [
          refreshed_downlink("dl_status_field_alias_recovery", 360.0, 420.0)
          |> Map.put("estimated_throughput_mb", 50.0),
          observe(
            "obs_status_boolean_recovery",
            "leo_1",
            "target_boolean_status",
            480.0,
            540.0,
            12.0
          )
        ],
        "source_objective_satisfaction_report" => %{
          "schema_contract" => "objective_satisfaction_report.v1",
          "model" => "provider_objective_status_field_aliases",
          "source" => "provider.objective_summary",
          "objective_count" => 2,
          "provenance" => %{"trust_boundary" => "provider_objective_review"},
          "rows" => [
            %{
              "id" => "objective:status_field_alias",
              "objective" => "downlink_completion",
              "downlink_requirement_status" => "Needs Replan",
              "ground_station_id" => "equator_prime",
              "required_downlink_mb" => 50.0,
              "planned_downlink_mb" => 10.0,
              "required_contact_count" => 1,
              "selected_contact_count" => 0
            },
            %{
              "id" => "objective:boolean_satisfaction",
              "objective" => "target_coverage",
              "objective_satisfied?" => "false",
              "target_id" => "target_boolean_status",
              "required_observation_count" => 1,
              "selected_observation_count" => 0
            }
          ]
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    downlink_branch =
      branch(artifact, "derived_objective_satisfaction_objective:status_field_alias")

    assert %{
             "type" => "downlink_completion_gap",
             "objective_status" => "partial",
             "source_objective_status" => "needs_replan",
             "required_downlink_mb" => 50.0,
             "planned_downlink_mb" => 10.0
           } = List.first(downlink_branch["events"])

    target_branch =
      branch(
        artifact,
        "derived_objective_satisfaction_objective:boolean_satisfaction:target_boolean_status"
      )

    assert %{
             "type" => "urgent_target",
             "target_id" => "target_boolean_status",
             "objective_status" => "unmet",
             "required_observations" => 1,
             "planned_observations" => 0
           } = List.first(target_branch["events"])

    refute Map.has_key?(List.first(target_branch["events"]), "source_objective_status")

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy keeps independent objective satisfaction pressures for the same objective identity" do
    prior_plan =
      base_plan(%{
        "candidate_activities" => [
          refreshed_downlink("dl_objective_shared_a_recovery", 360.0, 420.0)
          |> Map.put("estimated_throughput_mb", 80.0),
          refreshed_downlink("dl_objective_shared_b_recovery", 480.0, 540.0)
          |> Map.put("ground_station_id", "polar_prime")
          |> Map.put("estimated_throughput_mb", 60.0)
        ],
        "source_objective_satisfaction_report" => %{
          "schema_contract" => "objective_satisfaction_report.v1",
          "model" => "provider_downlink_objective_summary",
          "source" => "provider.source_objective_summary",
          "objective_count" => 1,
          "provenance" => %{"trust_boundary" => "source_objective_review"},
          "rows" => [
            %{
              "id" => "objective:shared_downlink",
              "objective" => "downlink_completion",
              "status" => "partial",
              "scenario_id" => "leo_1",
              "ground_station_id" => "equator_prime",
              "required_downlink_mb" => 80.0,
              "planned_downlink_mb" => 20.0,
              "required_contact_count" => 1,
              "selected_contact_count" => 0,
              "selected_contact_ids" => ["dl_objective_shared_a"]
            }
          ]
        },
        "objective_satisfaction_report" => %{
          "schema_contract" => "objective_satisfaction_report.v1",
          "model" => "provider_downlink_objective_summary",
          "source" => "provider.canonical_objective_summary",
          "objective_count" => 1,
          "provenance" => %{"trust_boundary" => "canonical_objective_review"},
          "rows" => [
            %{
              "id" => "objective:shared_downlink",
              "objective" => "downlink_completion",
              "status" => "partial",
              "scenario_id" => "leo_1",
              "ground_station_id" => "polar_prime",
              "required_downlink_mb" => 60.0,
              "planned_downlink_mb" => 10.0,
              "required_contact_count" => 1,
              "selected_contact_count" => 0,
              "selected_contact_ids" => ["dl_objective_shared_b"]
            }
          ]
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    base_id = "derived_objective_satisfaction_objective:shared_downlink"
    refute branch(artifact, base_id)

    objective_branches =
      Enum.filter(artifact["branches"], &String.starts_with?(&1["branch_id"], "#{base_id}_"))

    assert length(objective_branches) == 2

    assert MapSet.new(Enum.map(objective_branches, & &1["derived_source"])) ==
             MapSet.new([
               "prior_plan.source_objective_satisfaction_report",
               "prior_plan.objective_satisfaction_report"
             ])

    assert MapSet.new(
             Enum.map(
               objective_branches,
               &get_in(&1, ["events", Access.at(0), "ground_station_id"])
             )
           ) == MapSet.new(["equator_prime", "polar_prime"])

    assert MapSet.new(
             Enum.map(
               objective_branches,
               &get_in(&1, ["events", Access.at(0), "source_activity_ids"])
             )
           ) == MapSet.new([["dl_objective_shared_a"], ["dl_objective_shared_b"]])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives target refresh from objective satisfaction inline target specs" do
    prior_plan =
      base_plan(%{
        "candidate_activities" => [
          observe("obs_target_inline_provider", "leo_1", "target_provider", 360.0, 420.0, 12.0),
          observe(
            "obs_target_priority_provider",
            "leo_1",
            "target_priority_provider",
            480.0,
            540.0,
            12.0
          )
        ],
        "source_objective_satisfaction_report" => %{
          "schema_contract" => "objective_satisfaction_report.v1",
          "model" => "provider_inline_target_objective_summary",
          "source" => "provider.objective_summary",
          "objective_count" => 1,
          "provenance" => %{"trust_boundary" => "provider_objective_review"},
          "rows" => [
            %{
              "id" => "objective:inline_target_specs",
              "objective" => "coverage",
              "status" => "unmet",
              "required_observation_count" => 1,
              "selected_observation_count" => 0,
              "target_specs" => [
                %{
                  "id" => "target_provider",
                  "latitude_deg" => 9.0,
                  "longitude_deg" => 11.0,
                  "minimum_elevation_deg" => 12.0,
                  "priority" => 6.0
                }
              ],
              "priority_targets" => [
                %{
                  "id" => "target_priority_provider",
                  "latitude_deg" => -6.0,
                  "longitude_deg" => 22.0,
                  "minimum_elevation_deg" => 14.0,
                  "priority" => 8.0
                }
              ],
              "selected_targets" => [%{"id" => "target_a"}]
            }
          ]
        }
      })

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:targets, [])

    artifact =
      strategy(prior_plan,
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    pressure_branch =
      branch(
        artifact,
        "derived_objective_satisfaction_objective:inline_target_specs:target_provider"
      )

    assert %{
             "type" => "urgent_target",
             "objective_id" => "objective:inline_target_specs",
             "objective_type" => "target_coverage",
             "target_id" => "target_provider",
             "priority" => 6.0,
             "latitude_deg" => 9.0,
             "longitude_deg" => 11.0,
             "minimum_elevation_deg" => 12.0,
             "planned_observations" => 0,
             "required_observations" => 1,
             "feedback_source" => "prior_plan.source_objective_satisfaction_report",
             "trust_boundary" => "provider_objective_review"
           } = List.first(pressure_branch["events"])

    assert Enum.any?(
             pressure_branch["repair_result"]["source_candidate_activities"],
             &(&1["type"] == "observe" and &1["target_id"] == "target_provider")
           )

    assert [
             %{
               "id" =>
                 "derived_objective_satisfaction_objective:inline_target_specs:target_provider_urgent_observe_target_provider",
               "target_id" => "target_provider",
               "repair" => %{"reason" => "target_coverage_candidate_inserted"}
             }
           ] = pressure_branch["candidate_plan"]["strategic_additions"]

    priority_branch =
      branch(
        artifact,
        "derived_objective_satisfaction_objective:inline_target_specs:target_priority_provider"
      )

    assert %{
             "type" => "urgent_target",
             "target_id" => "target_priority_provider",
             "priority" => 8.0,
             "latitude_deg" => -6.0,
             "longitude_deg" => 22.0,
             "minimum_elevation_deg" => 14.0,
             "required_observations" => 1
           } = List.first(priority_branch["events"])

    assert Enum.any?(
             priority_branch["candidate_plan"]["strategic_additions"],
             &(&1["target_id"] == "target_priority_provider")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives target refresh from objective satisfaction singular target object aliases" do
    prior_plan =
      base_plan(%{
        "candidate_activities" => [
          observe(
            "obs_target_object_provider",
            "leo_1",
            "target_object_provider",
            360.0,
            420.0,
            12.0
          )
        ],
        "source_objective_satisfaction_report" => %{
          "schema_contract" => "objective_satisfaction_report.v1",
          "model" => "provider_singular_target_objective_summary",
          "source" => "provider.objective_summary",
          "objective_count" => 1,
          "provenance" => %{"trust_boundary" => "provider_objective_review"},
          "rows" => [
            %{
              "id" => "objective:singular_target_object",
              "objective" => "coverage",
              "status" => "unmet",
              "required_observation_count" => 1,
              "selected_observation_count" => 0,
              "target" => %{
                "id" => "target_object_provider",
                "latitude_deg" => 13.0,
                "longitude_deg" => -14.0,
                "minimum_elevation_deg" => 12.0,
                "priority" => 7.0
              },
              "selected_targets" => [%{"id" => "target_a"}]
            }
          ]
        }
      })

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:targets, [])

    artifact =
      strategy(prior_plan,
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    pressure_branch =
      branch(
        artifact,
        "derived_objective_satisfaction_objective:singular_target_object:target_object_provider"
      )

    assert %{
             "type" => "urgent_target",
             "objective_id" => "objective:singular_target_object",
             "objective_type" => "target_coverage",
             "target_id" => "target_object_provider",
             "priority" => 7.0,
             "latitude_deg" => 13.0,
             "longitude_deg" => -14.0,
             "minimum_elevation_deg" => 12.0,
             "planned_observations" => 0,
             "required_observations" => 1,
             "feedback_source" => "prior_plan.source_objective_satisfaction_report",
             "trust_boundary" => "provider_objective_review"
           } = List.first(pressure_branch["events"])

    assert Enum.any?(
             pressure_branch["candidate_plan"]["strategic_additions"],
             &(&1["target_id"] == "target_object_provider" and
                 get_in(&1, ["feasibility", "feedback_scope"]) == "objective_satisfaction")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives refresh from objective satisfaction score-term gap evidence" do
    prior_plan =
      base_plan(%{
        "candidate_activities" => [
          refreshed_downlink("dl_objective_score_term_recovery", 360.0, 420.0)
          |> Map.put("estimated_throughput_mb", 70.0),
          observe("obs_target_c", "leo_1", "target_c", 480.0, 540.0, 12.0)
        ],
        "source_objective_satisfaction_report" => %{
          "schema_contract" => "objective_satisfaction_report.v1",
          "model" => "provider_objective_score_terms",
          "source" => "provider.objective_summary",
          "objective_count" => 2,
          "provenance" => %{"trust_boundary" => "provider_objective_review"},
          "rows" => [
            %{
              "id" => "objective:downlink_score_terms",
              "objective" => "downlink_completion",
              "status" => "partial",
              "planned_downlink_mb" => 20.0,
              "planned_contacts" => 0,
              "selected_contact_ids" => ["dl_short"],
              "score_terms" => %{
                "downlink shortfall mb" => 50.0,
                "contact-count-gap" => 1
              }
            },
            %{
              "id" => "objective:target_score_terms",
              "objective" => "target_coverage",
              "status" => "unmet",
              "target_gap_ids" => ["target_c"],
              "selected_observation_count" => 0,
              "score_terms" => %{"target gap count" => 2}
            }
          ]
        }
      })

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.update!(:targets, fn targets ->
        targets ++
          [
            %{
              id: "target_c",
              latitude_deg: 8.0,
              longitude_deg: 8.0,
              minimum_elevation_deg: 10.0,
              priority: 4.0
            }
          ]
      end)

    artifact =
      strategy(prior_plan,
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    downlink_branch =
      branch(artifact, "derived_objective_satisfaction_objective:downlink_score_terms")

    assert %{
             "type" => "downlink_completion_gap",
             "objective_type" => "downlink_completion",
             "required_contacts" => 1,
             "planned_contacts" => 0,
             "required_downlink_mb" => 70.0,
             "planned_downlink_mb" => 20.0,
             "source_activity_ids" => ["dl_short"],
             "derivation_reasons" => [
               "objective_satisfaction_contact_gap",
               "objective_satisfaction_downlink_volume_gap",
               "objective_satisfaction_score_term_downlink_gap",
               "objective_satisfaction_score_term_contact_gap",
               "objective_status_partial"
             ],
             "feedback_source" => "prior_plan.source_objective_satisfaction_report",
             "trust_boundary" => "provider_objective_review"
           } = List.first(downlink_branch["events"])

    target_branch =
      branch(artifact, "derived_objective_satisfaction_objective:target_score_terms:target_c")

    assert %{
             "type" => "urgent_target",
             "objective_type" => "target_coverage",
             "target_id" => "target_c",
             "required_observations" => 2,
             "planned_observations" => 0,
             "derivation_reasons" => [
               "objective_satisfaction_target_gap",
               "objective_satisfaction_score_term_target_gap",
               "objective_status_unmet"
             ]
           } = List.first(target_branch["events"])

    assert Enum.any?(
             target_branch["candidate_plan"]["strategic_additions"],
             &(&1["target_id"] == "target_c" and
                 get_in(&1, ["feasibility", "feedback_source"]) ==
                   "prior_plan.source_objective_satisfaction_report")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives target refresh from direct target commitment satisfaction rows" do
    prior_plan =
      base_plan(%{
        "candidate_activities" => [
          observe("obs_target_a", "leo_1", "target_a", 360.0, 420.0, 12.0)
        ],
        "objective_satisfaction_report" => %{
          "schema_contract" => "objective_satisfaction_report.v1",
          "model" => "campaign_v1_selected_activity_objective_summary",
          "source" => "campaign_plan.activities",
          "objective_count" => 1,
          "provenance" => %{"trust_boundary" => "ops_objective_review"},
          "rows" => [
            %{
              "id" => "objective:target_commitment:target_a",
              "objective" => "target_commitment",
              "status" => "candidate_available",
              "target_id" => "target_a",
              "priority" => 4.0,
              "candidate_count" => 1,
              "selected_count" => 0
            }
          ]
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    commitment_branch =
      branch(artifact, "derived_objective_satisfaction_objective:target_commitment:target_a")

    assert %{
             "type" => "urgent_target",
             "objective_id" => "objective:target_commitment:target_a",
             "objective_type" => "target_observation",
             "target_id" => "target_a",
             "priority" => 4.0,
             "planned_observations" => 0,
             "required_observations" => 1,
             "objective_status" => "candidate_available",
             "trust_boundary" => "ops_objective_review"
           } = List.first(commitment_branch["events"])

    assert [
             %{
               "id" =>
                 "derived_objective_satisfaction_objective:target_commitment:target_a_urgent_observe_target_a",
               "target_id" => "target_a",
               "repair" => %{"reason" => "target_observation_candidate_inserted"}
             }
           ] = commitment_branch["candidate_plan"]["strategic_additions"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives target refresh from objective satisfaction revisit count aliases" do
    prior_plan =
      base_plan(%{
        "activities" => [
          observe("obs_target_a_completed", "leo_1", "target_a", 120.0, 180.0, 12.0)
        ],
        "objective_satisfaction_report" => %{
          "schema_contract" => "objective_satisfaction_report.v1",
          "model" => "strategy_branch_objective_satisfaction_summary",
          "source" => "campaign_plan.objectives",
          "provenance" => %{"trust_boundary" => "ops_revisit_review"},
          "rows" => [
            %{
              "id" => "objective:target_revisit:target_a",
              "objective" => "target revisit",
              "status" => "partial",
              "target" => %{
                "id" => "target_a",
                "priority" => "5.0"
              },
              "planned_revisits" => "1",
              "score_terms" => %{"Missing Revisit Count" => "2"}
            }
          ]
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    revisit_branch =
      branch(artifact, "derived_objective_satisfaction_objective:target_revisit:target_a")

    assert %{
             "type" => "urgent_target",
             "objective_id" => "objective:target_revisit:target_a",
             "objective_type" => "target_revisit",
             "target_id" => "target_a",
             "priority" => 5.0,
             "planned_observations" => 1.0,
             "required_observations" => 3,
             "objective_status" => "partial",
             "trust_boundary" => "ops_revisit_review",
             "derivation_reasons" => reasons
           } = List.first(revisit_branch["events"])

    assert "objective_satisfaction_score_term_target_gap" in reasons

    assert [
             %{
               "target_id" => "target_a",
               "feasibility" => %{
                 "planned_observations" => 1,
                 "required_observations" => 3,
                 "trust_boundary" => "ops_revisit_review"
               }
             }
           ] = revisit_branch["candidate_plan"]["strategic_additions"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives collection latency refresh from objective satisfaction rows" do
    prior_plan =
      base_plan(%{
        "activities" => [
          observe("obs_target_a", "leo_1", "target_a", 100.0, 160.0, 12.0)
          |> Map.put("collection_id", "collection_a"),
          observe("obs_delivery_alias", "leo_1", "target_b", 120.0, 180.0, 12.0)
          |> Map.put("collection_id", "collection_delivery_alias")
        ],
        "candidate_activities" => [
          refreshed_downlink("dl_latency_recovery", 220.0, 280.0)
          |> Map.put("collection_id", "collection_a")
          |> Map.put("score", 100.0)
        ],
        "source_objective_satisfaction_report" => %{
          "schema_contract" => "objective_satisfaction_report.v1",
          "model" => "strategy_branch_objective_satisfaction_summary",
          "source" => "campaign_strategy.branches.objective_satisfaction.collection_latency.rows",
          "objective_count" => 1,
          "provenance" => %{"trust_boundary" => "ops_objective_review"},
          "rows" => [
            %{
              "id" => "objective:collection_latency",
              "objective" => "collection latency",
              "objective_id" => "latency:collection_a",
              "status" => "unsatisfied",
              "source_observation" => %{"activity_id" => "obs_target_a"},
              "selected_activity" => %{"activity_id" => "obs_selected_nested"},
              "missed_downlink" => %{"contact_id" => "dl_missed_nested"},
              "target_id" => "target_a",
              "scenario_id" => "leo_1",
              "ground_station_id" => "equator_prime",
              "collection_id" => "collection_a",
              "max_latency_s" => 160.0,
              "planned_latency_s" => 420.0,
              "required_downlink_mb" => 40.0,
              "planned_downlink_mb" => 0.0,
              "planned_contacts" => 0
            },
            %{
              "id" => "objective:delivery_latency_alias",
              "objective" => "collection latency",
              "status" => "not met",
              "source_activity_id" => "obs_delivery_alias",
              "target_id" => "target_b",
              "scenario_id" => "leo_1",
              "collection_id" => "collection_delivery_alias",
              "collection_end_s" => "180.0",
              "delivery_deadline_s" => "360.0",
              "target_latency_s" => "180.0",
              "actual_delivery_latency_s" => "240.0",
              "target_data_volume_mb" => "35.0",
              "selected_data_volume_mb" => "5.0",
              "planned_contact_count" => "0"
            }
          ]
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    latency_branch =
      branch(artifact, "derived_objective_satisfaction_objective:collection_latency:obs_target_a")

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             latency_branch["assumptions"]["candidate_source"]

    assert %{
             "type" => "downlink_completion_gap",
             "objective_id" => "objective:collection_latency",
             "objective_type" => "collection_latency",
             "latency_objective" => true,
             "source_activity_id" => "obs_target_a",
             "source_activity_ids" => ["obs_selected_nested", "obs_target_a"],
             "missed_downlink_activity_id" => "dl_missed_nested",
             "missed_downlink_activity_ids" => ["dl_missed_nested"],
             "target_id" => "target_a",
             "scenario_id" => "leo_1",
             "ground_station_id" => "equator_prime",
             "collection_id" => "collection_a",
             "required_contacts" => 1,
             "planned_contacts" => 0,
             "required_downlink_mb" => 40.0,
             "max_latency_s" => 160.0,
             "planned_latency_s" => 420.0,
             "feedback_source" => "prior_plan.source_objective_satisfaction_report",
             "feedback_scope" => "objective_satisfaction",
             "objective_status" => "unmet",
             "trust_boundary" => "ops_objective_review"
           } = List.first(latency_branch["events"])

    assert List.first(latency_branch["events"])["planned_downlink_mb"] == 0.0

    assert Enum.any?(
             latency_branch["repair_result"]["source_candidate_activities"],
             &(&1["type"] == "downlink" and
                 get_in(&1, ["throughput_model", "required_downlink_mb"]) == 40.0)
           )

    assert "downlink completion gap not staged: no_validated_candidate_window" in latency_branch[
             "warnings"
           ]

    alias_branch =
      branch(
        artifact,
        "derived_objective_satisfaction_objective:delivery_latency_alias:obs_delivery_alias"
      )

    alias_event = List.first(alias_branch["events"])

    assert %{
             "type" => "downlink_completion_gap",
             "objective_id" => "objective:delivery_latency_alias",
             "objective_type" => "collection_latency",
             "latency_objective" => true,
             "source_activity_id" => "obs_delivery_alias",
             "target_id" => "target_b",
             "scenario_id" => "leo_1",
             "collection_id" => "collection_delivery_alias",
             "starts_at_s" => 180.0,
             "ends_at_s" => 360.0,
             "required_contacts" => 1,
             "required_downlink_mb" => 35.0,
             "planned_downlink_mb" => 5.0,
             "max_latency_s" => 180.0,
             "planned_latency_s" => 240.0,
             "derivation_reasons" => [
               "collection_latency_gap",
               "objective_status_unmet",
               "objective_satisfaction_latency_gap",
               "objective_satisfaction_downlink_volume_gap"
             ],
             "feedback_source" => "prior_plan.source_objective_satisfaction_report",
             "feedback_scope" => "objective_satisfaction",
             "objective_status" => "unmet",
             "trust_boundary" => "ops_objective_review"
           } = alias_event

    assert alias_event["planned_contacts"] == 0.0

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy ignores failed provider downlinks from array lineage when staging objective satisfaction replacement" do
    prior_plan =
      base_plan(%{
        "activities" => [
          observe("obs_target_a", "leo_1", "target_a", 100.0, 160.0, 12.0)
          |> Map.put("collection_id", "collection_a"),
          downlink("dl_failed_provider", 220.0, 280.0)
          |> Map.put("collection_id", "collection_a")
        ],
        "candidate_activities" => [
          refreshed_downlink("dl_latency_recovery", 240.0, 300.0)
          |> Map.put("collection_id", "collection_a")
          |> Map.put("score", 100.0)
        ],
        "source_objective_satisfaction_report" => %{
          "schema_contract" => "objective_satisfaction_report.v1",
          "model" => "provider_collection_latency_summary",
          "source" => "provider.objective_summary",
          "objective_count" => 1,
          "provenance" => %{"trust_boundary" => "provider_objective_review"},
          "rows" => [
            %{
              "id" => "objective:array_latency",
              "objective" => "collection latency",
              "status" => "unsatisfied",
              "source_activity_id" => "obs_target_a",
              "target_id" => "target_a",
              "scenario_id" => "leo_1",
              "ground_station_id" => "equator_prime",
              "collection_id" => "collection_a",
              "max_latency_s" => 160.0,
              "planned_latency_s" => 420.0,
              "required_downlink_mb" => 40.0,
              "planned_downlink_mb" => 0.0,
              "planned_contacts" => 0,
              "contact_result" => "dropped",
              "missed_downlink_activity_ids" => ["dl_failed_provider"]
            }
          ]
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    latency_branch =
      branch(artifact, "derived_objective_satisfaction_objective:array_latency:obs_target_a")

    assert %{
             "contact_result" => "dropped",
             "missed_downlink_activity_ids" => ["dl_failed_provider"]
           } = List.first(latency_branch["events"])

    assert Enum.any?(
             latency_branch["candidate_plan"]["strategic_additions"],
             &(get_in(&1, ["repair", "reason"]) ==
                 "collection_latency_downlink_candidate_inserted")
           )

    refute "downlink completion gap not staged: no_validated_candidate_window" in latency_branch[
             "warnings"
           ]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy scopes objective satisfaction latency refresh from nested source observation metadata" do
    prior_plan =
      base_plan(%{
        "activities" => [
          observe("obs_nested", "leo_1", "target_nested", 100.0, 160.0, 12.0)
          |> Map.put("collection_id", "collection_nested")
        ],
        "source_objective_satisfaction_report" => %{
          "schema_contract" => "objective_satisfaction_report.v1",
          "model" => "provider_collection_latency_summary",
          "source" => "provider.objective_summary",
          "objective_count" => 1,
          "provenance" => %{"trust_boundary" => "provider_objective_review"},
          "rows" => [
            %{
              "id" => "objective:nested_latency",
              "objective" => "collection latency",
              "status" => "unsatisfied",
              "source_observation" => %{
                "activity_id" => "obs_nested",
                "scenario_id" => "leo_1",
                "ground_station" => %{"id" => "equator_prime"},
                "target_id" => "target_nested",
                "collection_id" => "collection_nested",
                "collections" => [
                  %{"id" => "collection_nested"},
                  %{"collection_id" => "collection_nested_secondary"}
                ],
                "product_id" => "product_nested",
                "products" => [
                  %{"id" => "product_nested"},
                  %{"product_id" => "product_nested_secondary"}
                ],
                "payload_id" => "payload_nested",
                "payloads" => [
                  %{"id" => "payload_nested"},
                  %{"payload_id" => "payload_nested_secondary"}
                ],
                "instrument_id" => "instrument_nested",
                "instruments" => [
                  %{"id" => "instrument_nested"},
                  %{"instrument_id" => "instrument_nested_secondary"}
                ],
                "collection_end_s" => "160.0",
                "target_latency_s" => "180.0",
                "actual_delivery_latency_s" => "420.0",
                "target_data_volume_mb" => "30.0",
                "selected_data_volume_mb" => "4.0"
              },
              "planned_contacts" => 0
            }
          ]
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    latency_branch =
      branch(artifact, "derived_objective_satisfaction_objective:nested_latency:obs_nested")

    event = List.first(latency_branch["events"])

    risk =
      Enum.find(
        latency_branch["risk_indicators"],
        &(&1["type"] == "downlink_completion_gap")
      )

    assert %{
             "type" => "downlink_completion_gap",
             "scenario_id" => "leo_1",
             "ground_station_id" => "equator_prime",
             "target_id" => "target_nested",
             "collection_id" => "collection_nested",
             "collection_ids" => ["collection_nested", "collection_nested_secondary"],
             "product_id" => "product_nested",
             "product_ids" => ["product_nested", "product_nested_secondary"],
             "payload_id" => "payload_nested",
             "payload_ids" => ["payload_nested", "payload_nested_secondary"],
             "instrument_id" => "instrument_nested",
             "instrument_ids" => ["instrument_nested", "instrument_nested_secondary"],
             "starts_at_s" => 160.0,
             "ends_at_s" => 340.0,
             "required_downlink_mb" => 30.0,
             "planned_downlink_mb" => 4.0,
             "source_activity_id" => "obs_nested",
             "source_activity_ids" => ["obs_nested"]
           } = event

    assert %{
             "type" => "downlink_completion_gap",
             "scenario_id" => "leo_1",
             "ground_station_id" => "equator_prime",
             "target_id" => "target_nested",
             "collection_id" => "collection_nested",
             "collection_ids" => ["collection_nested", "collection_nested_secondary"],
             "product_id" => "product_nested",
             "product_ids" => ["product_nested", "product_nested_secondary"],
             "payload_id" => "payload_nested",
             "payload_ids" => ["payload_nested", "payload_nested_secondary"],
             "instrument_id" => "instrument_nested",
             "instrument_ids" => ["instrument_nested", "instrument_nested_secondary"],
             "objective_id" => "objective:nested_latency",
             "objective_type" => "collection_latency",
             "latency_objective" => true,
             "max_latency_s" => 180.0,
             "planned_latency_s" => 420.0,
             "required_downlink_mb" => 30.0,
             "source_activity_ids" => ["obs_nested"],
             "feedback_source" => "prior_plan.source_objective_satisfaction_report",
             "feedback_scope" => "objective_satisfaction",
             "trust_boundary" => "provider_objective_review"
           } = risk

    assert risk["planned_downlink_mb"] == 4.0

    comparison_row =
      Enum.find(
        get_in(artifact, ["branch_comparison_report", "rows"]),
        &(&1["branch_id"] == latency_branch["branch_id"])
      )

    assert %{
             "branch_target_ids" => ["target_nested"],
             "branch_ground_station_ids" => ["equator_prime"],
             "branch_scenario_ids" => ["leo_1"],
             "branch_collection_ids" => ["collection_nested", "collection_nested_secondary"],
             "branch_product_ids" => ["product_nested", "product_nested_secondary"],
             "branch_payload_ids" => ["payload_nested", "payload_nested_secondary"],
             "branch_instrument_ids" => ["instrument_nested", "instrument_nested_secondary"],
             "branch_objective_ids" => ["objective:nested_latency"],
             "branch_objective_types" => ["collection_latency"],
             "branch_feedback_sources" => ["prior_plan.source_objective_satisfaction_report"],
             "branch_feedback_scopes" => ["objective_satisfaction"],
             "branch_source_activity_ids" => ["obs_nested"],
             "branch_max_latency_s" => 180.0,
             "branch_planned_latency_s" => 420.0,
             "branch_required_downlink_mb" => 30.0,
             "branch_planned_downlink_mb" => 4.0
           } = comparison_row

    assert %{
             "type" => "downlink",
             "collection_id" => "collection_nested",
             "product_id" => "product_nested",
             "payload_id" => "payload_nested",
             "instrument_id" => "instrument_nested",
             "objective_type" => "collection_latency"
           } =
             Enum.find(
               latency_branch["repair_result"]["source_candidate_activities"],
               &(&1["type"] == "downlink")
             )

    assert latency_branch["candidate_plan"]["strategic_additions"] == []

    assert "downlink completion gap not staged: no_validated_candidate_window" in latency_branch[
             "warnings"
           ]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
