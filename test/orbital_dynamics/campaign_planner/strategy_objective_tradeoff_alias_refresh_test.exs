Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyObjectiveTradeoffAliasRefreshTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy derives refresh from objective tradeoff score-term gap evidence" do
    prior_plan =
      base_plan(%{
        "candidate_activities" => [
          observe("obs_target_a_recovery", "leo_1", "target_a", 360.0, 420.0, 12.0),
          refreshed_downlink("dl_score_term_recovery", 360.0, 420.0)
          |> Map.put("estimated_throughput_mb", 70.0)
        ],
        "source_objective_tradeoff_report" => %{
          "schema_contract" => "objective_tradeoff_report.v1",
          "model" => "strategy_branch_score_term_tradeoffs",
          "ranking_count" => 2,
          "provenance" => %{"trust_boundary" => "ops_tradeoff_review"},
          "rows" => [
            %{
              "rank" => 2,
              "scenario_id" => "leo_1",
              "branch_id" => "downlink_score_terms_gap",
              "objective" => "downlink-completion",
              "selected" => " FALSE ",
              "score" => 72.0,
              "score_delta_from_selected" => -18.0,
              "ground_station_id" => "equator_prime",
              "planned_downlink_mb" => 20.0,
              "planned_contacts" => 0,
              "activity_ids" => ["dl_short"],
              "score_terms" => %{
                "downlink shortfall mb" => 50.0,
                "contact-count-gap" => 1
              }
            },
            %{
              "rank" => 3,
              "scenario_id" => "leo_1",
              "branch_id" => "target_score_terms_gap",
              "objective" => "Target Coverage",
              "selected" => false,
              "score" => 68.0,
              "score_delta_from_selected" => -22.0,
              "target_id" => "target_a",
              "selected_observation_count" => 0,
              "activity_ids" => ["obs_short"],
              "score_terms" => %{"Missing Observation Count" => 1}
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
      branch(artifact, "derived_objective_tradeoff_pressure_downlink_score_terms_gap")

    assert %{
             "type" => "downlink_completion_gap",
             "objective_type" => "downlink_completion",
             "branch_id" => "downlink_score_terms_gap",
             "required_contacts" => 1,
             "planned_contacts" => 0,
             "required_downlink_mb" => 70.0,
             "planned_downlink_mb" => 20.0,
             "source_activity_ids" => ["dl_short"],
             "derivation_reasons" => [
               "objective_tradeoff_downlink_gap",
               "objective_tradeoff_contact_count_gap",
               "objective_tradeoff_downlink_volume_gap",
               "objective_tradeoff_score_term_downlink_gap",
               "objective_tradeoff_score_term_contact_gap",
               "objective_tradeoff_unselected"
             ],
             "feedback_source" => "prior_plan.source_objective_tradeoff_report",
             "trust_boundary" => "ops_tradeoff_review"
           } = List.first(downlink_branch["events"])

    assert %{
             "feedback_source" => "prior_plan.source_objective_tradeoff_report",
             "source_branch_id" => "downlink_score_terms_gap",
             "derivation_reasons" => [
               "objective_tradeoff_downlink_gap",
               "objective_tradeoff_contact_count_gap",
               "objective_tradeoff_downlink_volume_gap",
               "objective_tradeoff_score_term_downlink_gap",
               "objective_tradeoff_score_term_contact_gap",
               "objective_tradeoff_unselected"
             ]
           } =
             List.first(downlink_branch["candidate_plan"]["strategic_additions"])["feasibility"]

    target_branch = branch(artifact, "derived_objective_tradeoff_pressure_target_score_terms_gap")

    assert %{
             "type" => "urgent_target",
             "objective_type" => "target_coverage",
             "target_id" => "target_a",
             "required_observations" => 1,
             "planned_observations" => 0,
             "source_activity_ids" => ["obs_short"],
             "derivation_reasons" => [
               "objective_tradeoff_target_gap",
               "objective_tradeoff_score_term_target_gap",
               "objective_tradeoff_unselected"
             ]
           } = List.first(target_branch["events"])

    assert Enum.any?(
             target_branch["candidate_plan"]["strategic_additions"],
             &(&1["target_id"] == "target_a" and
                 get_in(&1, ["feasibility", "source_branch_id"]) == "target_score_terms_gap")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives objective tradeoff target refresh from revisit score-term aliases" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 600.0, "output_step_s" => 60.0},
        "source_objective_tradeoff_report" => %{
          "schema_contract" => "objective_tradeoff_report.v1",
          "model" => "strategy_branch_score_term_tradeoffs",
          "ranking_count" => 1,
          "provenance" => %{"trust_boundary" => "objective_tradeoff_revisit_review"},
          "rows" => [
            %{
              "rank" => 2,
              "scenario_id" => "leo_1",
              "branch_id" => "revisit_score_terms_gap",
              "objective" => "target-revisit",
              "selected" => false,
              "score" => 62.0,
              "score_delta_from_selected" => -16.0,
              "planned_revisits" => "1",
              "score_terms" => %{"missing revisit count" => 2.0},
              "missing_revisit_targets" => [
                %{
                  "id" => "target_tradeoff_revisit",
                  "priority" => "7.0",
                  "latitude_deg" => 5.0,
                  "longitude_deg" => 41.0,
                  "minimum_elevation_deg" => 13.0
                }
              ]
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
      branch(artifact, "derived_objective_tradeoff_pressure_revisit_score_terms_gap")

    assert %{
             "type" => "urgent_target",
             "objective_type" => "target_revisit",
             "target_id" => "target_tradeoff_revisit",
             "priority" => 7.0,
             "planned_observations" => 1.0,
             "required_observations" => 3.0,
             "score" => 62.0,
             "score_delta_from_selected" => -16.0,
             "feedback_source" => "prior_plan.source_objective_tradeoff_report",
             "feedback_scope" => "objective_tradeoff",
             "trust_boundary" => "objective_tradeoff_revisit_review",
             "derivation_reasons" => [
               "objective_tradeoff_target_gap",
               "objective_tradeoff_score_term_target_gap",
               "objective_tradeoff_unselected"
             ]
           } = List.first(revisit_branch["events"])

    revisit_additions =
      Enum.filter(
        revisit_branch["candidate_plan"]["strategic_additions"],
        &(&1["target_id"] == "target_tradeoff_revisit")
      )

    assert length(revisit_additions) == 2

    assert Enum.all?(
             revisit_additions,
             &(get_in(&1, ["feasibility", "source_branch_id"]) == "revisit_score_terms_gap")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives objective tradeoff downlink refresh from station object aliases" do
    prior_plan =
      base_plan(%{
        "candidate_activities" => [
          refreshed_downlink("dl_tradeoff_station_alias", 360.0, 420.0)
          |> Map.put("estimated_throughput_mb", 45.0)
        ],
        "source_objective_tradeoff_report" => %{
          "schema_contract" => "objective_tradeoff_report.v1",
          "model" => "strategy_branch_score_term_tradeoffs",
          "ranking_count" => 1,
          "provenance" => %{"trust_boundary" => "provider_tradeoff_review"},
          "tradeoffs" => [
            %{
              "rank" => 2,
              "scenario_id" => "leo_1",
              "branch_id" => "tradeoff_station_object_gap",
              "objective" => "downlink-completion",
              "selected" => false,
              "score" => 70.0,
              "score_delta_from_selected" => -15.0,
              "station" => %{"id" => "equator_prime", "provider" => "fixture_network"},
              "required_downlink_mb" => 45.0,
              "planned_downlink_mb" => 5.0,
              "required_contact_count" => 1,
              "selected_contact_count" => 0,
              "activity_ids" => ["dl_short"]
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

    branch = branch(artifact, "derived_objective_tradeoff_pressure_tradeoff_station_object_gap")

    assert %{
             "type" => "downlink_completion_gap",
             "objective_type" => "downlink_completion",
             "ground_station_id" => "equator_prime",
             "required_downlink_mb" => 45.0,
             "planned_downlink_mb" => 5.0,
             "required_contacts" => 1,
             "planned_contacts" => 0,
             "source_activity_ids" => ["dl_short"],
             "feedback_source" => "prior_plan.source_objective_tradeoff_report",
             "trust_boundary" => "provider_tradeoff_review"
           } = List.first(branch["events"])

    assert Enum.any?(
             branch["candidate_plan"]["strategic_additions"],
             &(&1["type"] == "downlink" and &1["ground_station_id"] == "equator_prime")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives objective tradeoff refresh from result artifact reports" do
    prior_plan =
      base_plan(%{
        "candidate_activities" => [
          refreshed_downlink("dl_tradeoff_result_artifact", 360.0, 420.0)
          |> Map.put("estimated_throughput_mb", 45.0)
        ],
        "source_result_artifact" => %{
          "schema_contract" => "result_artifact.v1",
          "study_id" => "objective_tradeoff_result_artifact",
          "trust_boundary" => "ops_result_artifact",
          "objective_tradeoff_report" => %{
            "schema_contract" => "objective_tradeoff_report.v1",
            "model" => "strategy_branch_score_term_tradeoffs",
            "ranking_count" => 1,
            "tradeoffs" => [
              %{
                "rank" => 2,
                "scenario_id" => "leo_1",
                "branch_id" => "result_artifact_tradeoff_gap",
                "objective" => "downlink-completion",
                "selected" => false,
                "score" => 70.0,
                "score_delta_from_selected" => -15.0,
                "station" => %{"id" => "equator_prime", "provider" => "fixture_network"},
                "required_downlink_mb" => 45.0,
                "planned_downlink_mb" => 5.0,
                "required_contact_count" => 1,
                "selected_contact_count" => 0,
                "activity_ids" => ["dl_result_tradeoff_short"]
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

    branch =
      branch(artifact, "derived_objective_tradeoff_pressure_result_artifact_tradeoff_gap")

    assert %{
             "type" => "downlink_completion_gap",
             "objective_type" => "downlink_completion",
             "ground_station_id" => "equator_prime",
             "required_downlink_mb" => 45.0,
             "planned_downlink_mb" => 5.0,
             "required_contacts" => 1,
             "planned_contacts" => 0,
             "source_activity_ids" => ["dl_result_tradeoff_short"],
             "feedback_source" => "prior_plan.source_result_artifact.objective_tradeoff_report",
             "trust_boundary" => "ops_result_artifact"
           } = List.first(branch["events"])

    assert Enum.any?(
             branch["candidate_plan"]["strategic_additions"],
             &(&1["type"] == "downlink" and &1["ground_station_id"] == "equator_prime")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives objective tradeoff downlink refresh from contact object aliases" do
    prior_plan =
      base_plan(%{
        "candidate_activities" => [
          refreshed_downlink("dl_tradeoff_contact_object", 360.0, 420.0)
        ],
        "source_objective_tradeoff_report" => %{
          "schema_contract" => "objective_tradeoff_report.v1",
          "model" => "provider_downlink_tradeoff_summary",
          "ranking_count" => 1,
          "provenance" => %{"trust_boundary" => "provider_tradeoff_review"},
          "tradeoffs" => [
            %{
              "rank" => 2,
              "scenario_id" => "leo_1",
              "branch_id" => "tradeoff_contact_object_gap",
              "objective" => "downlink-completion",
              "selected" => false,
              "score" => 68.0,
              "score_delta_from_selected" => -17.0,
              "station" => %{"id" => "equator_prime", "provider" => "fixture_network"},
              "required_downlink_contacts" => [
                %{"id" => "dl_tradeoff_selected"},
                %{"contact_id" => "dl_tradeoff_missing"}
              ],
              "selected_contacts" => [
                %{"activity_id" => "dl_tradeoff_selected", "ground_station_id" => "equator_prime"}
              ]
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

    branch = branch(artifact, "derived_objective_tradeoff_pressure_tradeoff_contact_object_gap")

    assert %{
             "type" => "downlink_completion_gap",
             "objective_type" => "downlink_completion",
             "ground_station_id" => "equator_prime",
             "required_contacts" => 2,
             "planned_contacts" => 1,
             "source_activity_ids" => ["dl_tradeoff_selected"],
             "derivation_reasons" => [
               "objective_tradeoff_downlink_gap",
               "objective_tradeoff_contact_count_gap",
               "objective_tradeoff_unselected"
             ],
             "feedback_source" => "prior_plan.source_objective_tradeoff_report",
             "trust_boundary" => "provider_tradeoff_review"
           } = List.first(branch["events"])

    assert Enum.any?(
             branch["candidate_plan"]["strategic_additions"],
             &(&1["type"] == "downlink" and &1["ground_station_id"] == "equator_prime" and
                 get_in(&1, ["feasibility", "required_contacts"]) == 2)
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives objective tradeoff target refresh from singular target object aliases" do
    prior_plan =
      base_plan(%{
        "candidate_activities" => [
          observe(
            "obs_tradeoff_target_alias",
            "leo_1",
            "target_tradeoff_alias",
            360.0,
            420.0,
            12.0
          )
        ],
        "source_objective_tradeoff_report" => %{
          "schema_contract" => "objective_tradeoff_report.v1",
          "model" => "provider_inline_target_tradeoffs",
          "ranking_count" => 1,
          "provenance" => %{"trust_boundary" => "provider_tradeoff_review"},
          "rows" => [
            %{
              "rank" => 2,
              "scenario_id" => "leo_1",
              "branch_id" => "tradeoff_target_object_gap",
              "objective" => "coverage",
              "selected" => false,
              "score" => 62.0,
              "score_delta_from_selected" => -11.0,
              "selected_observation_count" => 0,
              "target" => %{
                "id" => "target_tradeoff_alias",
                "priority" => 8.0,
                "latitude_deg" => 11.0,
                "longitude_deg" => -22.0,
                "minimum_elevation_deg" => 16.0
              },
              "score_terms" => %{"target-gap-count" => 1}
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

    branch = branch(artifact, "derived_objective_tradeoff_pressure_tradeoff_target_object_gap")

    assert %{
             "type" => "urgent_target",
             "objective_type" => "coverage",
             "target_id" => "target_tradeoff_alias",
             "priority" => 8.0,
             "latitude_deg" => 11.0,
             "longitude_deg" => -22.0,
             "minimum_elevation_deg" => 16.0,
             "required_observations" => 1,
             "planned_observations" => 0,
             "feedback_source" => "prior_plan.source_objective_tradeoff_report",
             "trust_boundary" => "provider_tradeoff_review"
           } = List.first(branch["events"])

    assert Enum.any?(
             branch["candidate_plan"]["strategic_additions"],
             &(&1["type"] == "observe" and &1["target_id"] == "target_tradeoff_alias")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy scopes objective tradeoff target refresh from nested source observation metadata" do
    prior_plan =
      base_plan(%{
        "candidate_activities" => [
          observe(
            "obs_tradeoff_nested_target",
            "leo_1",
            "target_tradeoff_nested",
            360.0,
            420.0,
            12.0
          ),
          observe(
            "obs_tradeoff_nested_target_wrong_spacecraft",
            "leo_2",
            "target_tradeoff_nested",
            300.0,
            360.0,
            20.0
          )
        ],
        "source_objective_tradeoff_report" => %{
          "schema_contract" => "objective_tradeoff_report.v1",
          "model" => "provider_nested_target_tradeoffs",
          "ranking_count" => 1,
          "provenance" => %{"trust_boundary" => "provider_tradeoff_review"},
          "rows" => [
            %{
              "rank" => 2,
              "branch_id" => "tradeoff_nested_target_gap",
              "objective" => "coverage",
              "selected" => false,
              "score" => 62.0,
              "score_delta_from_selected" => -11.0,
              "selected_observation_count" => 0,
              "source_observation" => %{
                "activity_id" => "obs_tradeoff_source_nested",
                "scenario_id" => "leo_1",
                "target_id" => "target_tradeoff_nested",
                "priority" => 8.0,
                "latitude_deg" => 11.0,
                "longitude_deg" => -22.0,
                "minimum_elevation_deg" => 16.0
              },
              "score_terms" => %{"target-gap-count" => 1}
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

    branch = branch(artifact, "derived_objective_tradeoff_pressure_tradeoff_nested_target_gap")

    assert %{
             "type" => "urgent_target",
             "objective_type" => "coverage",
             "target_id" => "target_tradeoff_nested",
             "scenario_id" => "leo_1",
             "priority" => 8.0,
             "latitude_deg" => 11.0,
             "longitude_deg" => -22.0,
             "minimum_elevation_deg" => 16.0,
             "required_observations" => 1,
             "planned_observations" => 0,
             "source_activity_ids" => ["obs_tradeoff_source_nested"],
             "feedback_source" => "prior_plan.source_objective_tradeoff_report",
             "trust_boundary" => "provider_tradeoff_review"
           } = List.first(branch["events"])

    assert [
             %{
               "id" =>
                 "derived_objective_tradeoff_pressure_tradeoff_nested_target_gap_urgent_observe_target_tradeoff_nested",
               "target_id" => "target_tradeoff_nested",
               "scenario_id" => "leo_1"
             }
           ] = branch["candidate_plan"]["strategic_additions"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives objective tradeoff target refresh counts from target lists" do
    prior_plan =
      base_plan(%{
        "candidate_activities" => [
          observe(
            "obs_tradeoff_target_list",
            "leo_1",
            "target_tradeoff_list_b",
            360.0,
            420.0,
            12.0
          )
        ],
        "source_objective_tradeoff_report" => %{
          "schema_contract" => "objective_tradeoff_report.v1",
          "model" => "provider_target_tradeoffs",
          "ranking_count" => 1,
          "provenance" => %{"trust_boundary" => "provider_tradeoff_review"},
          "rows" => [
            %{
              "rank" => 2,
              "scenario_id" => "leo_1",
              "branch_id" => "tradeoff_target_list_gap",
              "objective" => "coverage",
              "selected" => false,
              "score" => 61.0,
              "score_delta_from_selected" => -13.0,
              "required_targets" => [
                %{"id" => "target_tradeoff_list_a", "priority" => 4.0},
                %{"id" => "target_tradeoff_list_b", "priority" => 9.0}
              ],
              "selected_targets" => [%{"id" => "target_tradeoff_list_a"}],
              "source_activity" => %{"id" => "obs_tradeoff_source"},
              "candidate_activity" => %{"activity_id" => "obs_tradeoff_candidate"},
              "selected_observations" => [
                %{
                  "activity_id" => "obs_tradeoff_selected",
                  "target_id" => "target_tradeoff_list_a"
                }
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

    branch = branch(artifact, "derived_objective_tradeoff_pressure_tradeoff_target_list_gap")

    assert %{
             "type" => "urgent_target",
             "objective_type" => "coverage",
             "target_id" => "target_tradeoff_list_b",
             "priority" => 9.0,
             "required_observations" => 2,
             "planned_observations" => 1,
             "source_activity_ids" => [
               "obs_tradeoff_candidate",
               "obs_tradeoff_selected",
               "obs_tradeoff_source"
             ],
             "derivation_reasons" => [
               "objective_tradeoff_target_gap",
               "objective_tradeoff_unselected"
             ],
             "feedback_source" => "prior_plan.source_objective_tradeoff_report",
             "trust_boundary" => "provider_tradeoff_review"
           } = List.first(branch["events"])

    assert Enum.any?(
             branch["candidate_plan"]["strategic_additions"],
             &(&1["target_id"] == "target_tradeoff_list_b" and
                 get_in(&1, ["feasibility", "required_observations"]) == 2)
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives target refresh from objective tradeoff target-gap aliases" do
    prior_plan =
      base_plan(%{
        "candidate_activities" => [
          observe("obs_target_c_recovery", "leo_1", "target_c", 360.0, 420.0, 12.0),
          observe("obs_target_missed_recovery", "leo_1", "target_missed", 420.0, 480.0, 12.0),
          observe(
            "obs_target_single_missed_recovery",
            "leo_1",
            "target_single_missed",
            480.0,
            540.0,
            12.0
          )
        ],
        "source_objective_tradeoff_report" => %{
          "schema_contract" => "objective_tradeoff_report.v1",
          "model" => "provider_target_tradeoffs",
          "ranking_count" => 2,
          "provenance" => %{"trust_boundary" => "provider_tradeoff_review"},
          "tradeoffs" => [
            %{
              "rank" => 2,
              "scenario_id" => "leo_1",
              "branch_id" => "coverage_alias_gap",
              "objective" => "coverage",
              "selected" => false,
              "score" => 60.0,
              "score_delta_from_selected" => -12.0,
              "unsatisfied_target_ids" => ["target_c"],
              "selected_observation_count" => 0,
              "activity_ids" => ["obs_short"],
              "score_terms" => %{"target_gap_count" => 1}
            },
            %{
              "rank" => 3,
              "scenario_id" => "leo_1",
              "branch_id" => "missed_target_object_gap",
              "objective" => "coverage",
              "selected" => false,
              "score" => 58.0,
              "score_delta_from_selected" => -14.0,
              "missed_targets" => [
                %{
                  "id" => "target_missed",
                  "priority" => 9.0,
                  "latitude_deg" => 12.0,
                  "longitude_deg" => -24.0,
                  "minimum_elevation_deg" => 17.0
                }
              ],
              "selected_observation_count" => 0,
              "activity_ids" => ["obs_missed"],
              "score_terms" => %{"target_gap_count" => 1}
            },
            %{
              "rank" => 4,
              "scenario_id" => "leo_1",
              "branch_id" => "singular_missed_target_object_gap",
              "objective" => "coverage",
              "selected" => false,
              "score" => 57.0,
              "score_delta_from_selected" => -15.0,
              "missed_target" => %{
                "id" => "target_single_missed",
                "priority" => 8.0,
                "latitude_deg" => 14.0,
                "longitude_deg" => -26.0,
                "minimum_elevation_deg" => 18.0
              },
              "selected_observation_count" => 0,
              "activity_ids" => ["obs_single_missed"]
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

    target_branch = branch(artifact, "derived_objective_tradeoff_pressure_coverage_alias_gap")

    assert %{
             "type" => "urgent_target",
             "objective_type" => "coverage",
             "target_id" => "target_c",
             "required_observations" => 1,
             "planned_observations" => 0,
             "source_activity_ids" => ["obs_short"],
             "derivation_reasons" => [
               "objective_tradeoff_target_gap",
               "objective_tradeoff_score_term_target_gap",
               "objective_tradeoff_unselected"
             ],
             "feedback_source" => "prior_plan.source_objective_tradeoff_report",
             "trust_boundary" => "provider_tradeoff_review"
           } = List.first(target_branch["events"])

    assert Enum.any?(
             target_branch["candidate_plan"]["strategic_additions"],
             &(&1["target_id"] == "target_c" and
                 get_in(&1, ["feasibility", "source_branch_id"]) == "coverage_alias_gap")
           )

    missed_target_branch =
      branch(artifact, "derived_objective_tradeoff_pressure_missed_target_object_gap")

    assert %{
             "type" => "urgent_target",
             "objective_type" => "coverage",
             "target_id" => "target_missed",
             "priority" => 9.0,
             "latitude_deg" => 12.0,
             "longitude_deg" => -24.0,
             "minimum_elevation_deg" => 17.0,
             "required_observations" => 1,
             "planned_observations" => 0,
             "source_activity_ids" => ["obs_missed"],
             "feedback_source" => "prior_plan.source_objective_tradeoff_report",
             "trust_boundary" => "provider_tradeoff_review"
           } = List.first(missed_target_branch["events"])

    assert Enum.any?(
             missed_target_branch["candidate_plan"]["strategic_additions"],
             &(&1["target_id"] == "target_missed" and
                 get_in(&1, ["feasibility", "source_branch_id"]) == "missed_target_object_gap")
           )

    singular_missed_target_branch =
      branch(artifact, "derived_objective_tradeoff_pressure_singular_missed_target_object_gap")

    assert %{
             "type" => "urgent_target",
             "objective_type" => "coverage",
             "target_id" => "target_single_missed",
             "priority" => 8.0,
             "latitude_deg" => 14.0,
             "longitude_deg" => -26.0,
             "minimum_elevation_deg" => 18.0,
             "required_observations" => 1,
             "planned_observations" => 0,
             "source_activity_ids" => ["obs_single_missed"],
             "derivation_reasons" => [
               "objective_tradeoff_target_gap",
               "objective_tradeoff_missed_targets",
               "objective_tradeoff_unselected"
             ],
             "feedback_source" => "prior_plan.source_objective_tradeoff_report",
             "trust_boundary" => "provider_tradeoff_review"
           } = List.first(singular_missed_target_branch["events"])

    assert Enum.any?(
             singular_missed_target_branch["candidate_plan"]["strategic_additions"],
             &(&1["target_id"] == "target_single_missed" and
                 get_in(&1, ["feasibility", "source_branch_id"]) ==
                   "singular_missed_target_object_gap")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives objective tradeoff target counts from direct observation shortfall aliases" do
    prior_plan =
      base_plan(%{
        "candidate_activities" => [
          observe(
            "obs_tradeoff_shortfall_recovery_a",
            "leo_1",
            "target_tradeoff_shortfall",
            360.0,
            420.0,
            12.0
          ),
          observe(
            "obs_tradeoff_shortfall_recovery_b",
            "leo_1",
            "target_tradeoff_shortfall",
            480.0,
            540.0,
            12.0
          )
        ],
        "source_objective_tradeoff_report" => %{
          "schema_contract" => "objective_tradeoff_report.v1",
          "model" => "provider_target_shortfall_tradeoffs",
          "ranking_count" => 1,
          "provenance" => %{"trust_boundary" => "provider_tradeoff_shortfall_review"},
          "rows" => [
            %{
              "rank" => 2,
              "scenario_id" => "leo_1",
              "branch_id" => "tradeoff_direct_observation_shortfall",
              "objective" => "target coverage",
              "selected" => false,
              "score" => 64.0,
              "score_delta_from_selected" => -11.0,
              "target" => %{
                "id" => "target_tradeoff_shortfall",
                "priority" => "8.0",
                "latitude_deg" => -9.0,
                "longitude_deg" => 31.0,
                "minimum_elevation_deg" => 15.0
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
        "derived_objective_tradeoff_pressure_tradeoff_direct_observation_shortfall"
      )

    assert %{
             "type" => "urgent_target",
             "objective_type" => "target_coverage",
             "target_id" => "target_tradeoff_shortfall",
             "priority" => 8.0,
             "planned_observations" => 1.0,
             "required_observations" => 3.0,
             "score" => 64.0,
             "score_delta_from_selected" => -11.0,
             "feedback_source" => "prior_plan.source_objective_tradeoff_report",
             "feedback_scope" => "objective_tradeoff",
             "trust_boundary" => "provider_tradeoff_shortfall_review",
             "derivation_reasons" => [
               "objective_tradeoff_target_gap",
               "objective_tradeoff_unselected"
             ]
           } = List.first(branch["events"])

    additions =
      Enum.filter(
        branch["candidate_plan"]["strategic_additions"],
        &(&1["target_id"] == "target_tradeoff_shortfall")
      )

    assert length(additions) >= 2

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives objective tradeoff target refresh from inline target specs" do
    prior_plan =
      base_plan(%{
        "candidate_activities" => [
          observe(
            "obs_tradeoff_inline_provider",
            "leo_1",
            "target_tradeoff_provider",
            360.0,
            420.0,
            12.0
          )
        ],
        "source_objective_tradeoff_report" => %{
          "schema_contract" => "objective_tradeoff_report.v1",
          "model" => "provider_inline_target_tradeoffs",
          "ranking_count" => 2,
          "provenance" => %{"trust_boundary" => "provider_tradeoff_review"},
          "tradeoffs" => [
            %{
              "rank" => 2,
              "scenario_id" => "leo_1",
              "branch_id" => "inline_tradeoff_target_gap",
              "objective" => "coverage",
              "selected" => false,
              "score" => 61.0,
              "score_delta_from_selected" => -10.0,
              "selected_observation_count" => 0,
              "priority_targets" => [
                %{
                  "id" => "target_tradeoff_provider",
                  "priority" => 7.0,
                  "latitude_deg" => 0.0,
                  "longitude_deg" => 0.0,
                  "minimum_elevation_deg" => 10.0
                }
              ],
              "selected_targets" => [%{"id" => "target_a"}],
              "score_terms" => %{"target_gap_count" => 1}
            },
            %{
              "rank" => 3,
              "scenario_id" => "leo_1",
              "branch_id" => "missed_observation_tradeoff_target",
              "objective" => "target_coverage",
              "selected" => false,
              "score" => 59.0,
              "score_delta_from_selected" => -12.0,
              "selected_observation_count" => 0,
              "observation_shortfall_count" => "2",
              "missed_observation_target_ids" => ["target_tradeoff_missed_obs"],
              "missed_observation_targets" => [
                %{
                  "id" => "target_tradeoff_missed_obs",
                  "priority" => "8.0",
                  "latitude_deg" => 11.0,
                  "longitude_deg" => -22.0,
                  "minimum_elevation_deg" => 14.0
                }
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

    target_branch =
      branch(artifact, "derived_objective_tradeoff_pressure_inline_tradeoff_target_gap")

    missed_observation_branch =
      branch(
        artifact,
        "derived_objective_tradeoff_pressure_missed_observation_tradeoff_target"
      )

    event = List.first(target_branch["events"])

    assert %{
             "type" => "urgent_target",
             "objective_type" => "coverage",
             "target_id" => "target_tradeoff_provider",
             "priority" => 7.0,
             "minimum_elevation_deg" => 10.0,
             "required_observations" => 1,
             "planned_observations" => 0,
             "feedback_source" => "prior_plan.source_objective_tradeoff_report",
             "trust_boundary" => "provider_tradeoff_review"
           } = event

    assert event["latitude_deg"] == 0.0
    assert event["longitude_deg"] == 0.0

    assert %{
             "type" => "urgent_target",
             "objective_type" => "target_coverage",
             "target_id" => "target_tradeoff_missed_obs",
             "priority" => 8.0,
             "latitude_deg" => 11.0,
             "longitude_deg" => -22.0,
             "minimum_elevation_deg" => 14.0,
             "required_observations" => 2.0,
             "planned_observations" => 0,
             "score" => 59.0,
             "score_delta_from_selected" => -12.0,
             "feedback_source" => "prior_plan.source_objective_tradeoff_report",
             "feedback_scope" => "objective_tradeoff",
             "trust_boundary" => "provider_tradeoff_review",
             "derivation_reasons" => [
               "objective_tradeoff_target_gap",
               "objective_tradeoff_missed_targets",
               "objective_tradeoff_unselected"
             ]
           } = List.first(missed_observation_branch["events"])

    assert Enum.any?(
             target_branch["repair_result"]["source_candidate_activities"],
             &(&1["type"] == "observe" and &1["target_id"] == "target_tradeoff_provider")
           )

    assert Enum.any?(
             target_branch["candidate_plan"]["strategic_additions"],
             &(&1["target_id"] == "target_tradeoff_provider" and
                 get_in(&1, ["feasibility", "feedback_scope"]) == "objective_tradeoff")
           )

    assert Enum.count(
             missed_observation_branch["candidate_plan"]["strategic_additions"],
             &(&1["target_id"] == "target_tradeoff_missed_obs" and
                 get_in(&1, ["feasibility", "feedback_scope"]) == "objective_tradeoff")
           ) == 1

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
