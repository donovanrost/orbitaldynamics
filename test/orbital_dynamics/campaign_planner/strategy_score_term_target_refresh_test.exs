Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyScoreTermTargetRefreshTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy derives target refresh from operator-review score-term source rows" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 600.0, "output_step_s" => 60.0},
        "operator_review_package" => %{
          "schema_contract" => "operator_review_package.v1",
          "source_artifact_type" => "score_term_report.v1",
          "review_count" => 2,
          "rows" => [
            %{
              "id" => "operator_review:score_term:target_gap",
              "review_type" => "score_term_review",
              "required_operator_action" => "review_score_term",
              "action" => "review_score_term",
              "approval_status" => "operator_review_required",
              "source_score_term" => %{
                "id" => "score_gap:target",
                "rank" => 1,
                "scenario_id" => "leo_1",
                "term_key" => "Missing Observation Count",
                "value" => 2.0,
                "timeline_score" => 9.0,
                "selected" => false,
                "target_id" => "target_a",
                "planned_observations" => 0,
                "score_terms" => %{"Target Value" => 7.0}
              }
            },
            %{
              "id" => "operator_review:score_term:target_flat",
              "review_type" => "score_term_review",
              "required_operator_action" => "review_score_term",
              "action" => "review_score_term",
              "approval_status" => "operator_review_required",
              "scenario_id" => "leo_1",
              "term_key" => "target-gap-count",
              "value" => 1.0,
              "timeline_score" => 4.0,
              "selected" => false,
              "target_id" => "target_d",
              "planned_observations" => 0,
              "score_terms" => %{"Target Value" => 8.0}
            }
          ]
        },
        "cadence_import_manifest" => %{
          "schema_contract" => "cadence_import_manifest.v1",
          "source_artifact_type" => "operator_review_package.v1",
          "manifest_id" => "cadence_import_manifest:score_term_review",
          "row_count" => 3,
          "ready_count" => 0,
          "review_required_count" => 3,
          "blocked_count" => 0,
          "missing_import_count" => 0,
          "provenance" => %{"trust_boundary" => "cadence_score_import_queue"},
          "rows" => [
            %{
              "id" => "cadence_import:score_term:target_import",
              "rank" => 1,
              "import_action" => "review_score_term",
              "import_status" => "review_required_before_import",
              "cadence_import_status" => "present",
              "source_review_type" => "score_term_review",
              "source_review_row" => %{
                "id" => "operator_review:score_term:target_import",
                "review_type" => "score_term_review",
                "required_operator_action" => "review_score_term",
                "action" => "review_score_term",
                "approval_status" => "operator_review_required",
                "source_score_term" => %{
                  "id" => "score_gap:target_import",
                  "rank" => 1,
                  "scenario_id" => "leo_1",
                  "term_key" => "missing-observation-count",
                  "value" => 1.0,
                  "timeline_score" => 6.0,
                  "selected" => false,
                  "target_id" => "target_b",
                  "planned_observations" => 0
                }
              }
            },
            %{
              "id" => "cadence_import:score_term:target_top_import",
              "rank" => 2,
              "import_action" => "review_score_term",
              "import_status" => "review_required_before_import",
              "cadence_import_status" => "present",
              "source_review_type" => "score_term_review",
              "source_review_row" => %{
                "id" => "operator_review:score_term:target_top_import",
                "approval_status" => "operator_review_required"
              },
              "source_score_term" => %{
                "id" => "score_gap:target_top_import",
                "rank" => 2,
                "scenario_id" => "leo_1",
                "term_key" => "target-gap-count",
                "value" => 1.0,
                "timeline_score" => 5.0,
                "selected" => false,
                "target_id" => "target_c",
                "planned_observations" => 0
              }
            },
            %{
              "id" => "cadence_import:score_term:target_flat_import",
              "rank" => 3,
              "import_action" => "review_score_term",
              "import_status" => "review_required_before_import",
              "cadence_import_status" => "present",
              "source_review_type" => "score_term_review",
              "scenario_id" => "leo_1",
              "term_key" => "missing observation count",
              "value" => 1.0,
              "timeline_score" => 3.0,
              "selected" => false,
              "target_id" => "target_e",
              "planned_observations" => 0
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

    score_branch = branch(artifact, "derived_score_term_pressure_score_gap:target")

    assert %{
             "type" => "urgent_target",
             "target_id" => "target_a",
             "required_observations" => 2,
             "planned_observations" => 0,
             "priority" => 7.0,
             "score_term_key" => "missing_observation_count",
             "score_term_value" => 2.0,
             "feedback_source" => "prior_plan.operator_review_package.rows.source_score_term",
             "feedback_scope" => "score_term",
             "derivation_reasons" => [
               "score_term_target_gap",
               "score_term_missing_observation_count"
             ]
           } = List.first(score_branch["events"])

    assert Enum.any?(
             score_branch["candidate_plan"]["strategic_additions"],
             &(&1["type"] == "observe" and &1["target_id"] == "target_a")
           )

    flat_score_branch =
      branch(artifact, "derived_score_term_pressure_operator_review:score_term:target_flat")

    assert %{
             "type" => "urgent_target",
             "target_id" => "target_d",
             "required_observations" => 1,
             "planned_observations" => 0,
             "score_term_key" => "target_gap_count",
             "feedback_source" => "prior_plan.operator_review_package.rows.score_term_review",
             "feedback_scope" => "score_term"
           } = List.first(flat_score_branch["events"])

    import_score_branch = branch(artifact, "derived_score_term_pressure_score_gap:target_import")

    assert %{
             "type" => "urgent_target",
             "target_id" => "target_b",
             "required_observations" => 1,
             "planned_observations" => 0,
             "score_term_key" => "missing_observation_count",
             "feedback_source" =>
               "prior_plan.cadence_import_manifest.rows.source_review_row.source_score_term",
             "feedback_scope" => "score_term",
             "trust_boundary" => "cadence_score_import_queue"
           } = List.first(import_score_branch["events"])

    top_import_score_branch =
      branch(artifact, "derived_score_term_pressure_score_gap:target_top_import")

    assert %{
             "type" => "urgent_target",
             "target_id" => "target_c",
             "required_observations" => 1,
             "planned_observations" => 0,
             "score_term_key" => "target_gap_count",
             "feedback_source" => "prior_plan.cadence_import_manifest.rows.source_score_term",
             "feedback_scope" => "score_term",
             "trust_boundary" => "cadence_score_import_queue"
           } = List.first(top_import_score_branch["events"])

    flat_import_score_branch =
      branch(artifact, "derived_score_term_pressure_cadence_import:score_term:target_flat_import")

    assert %{
             "type" => "urgent_target",
             "target_id" => "target_e",
             "required_observations" => 1,
             "planned_observations" => 0,
             "score_term_key" => "missing_observation_count",
             "feedback_source" => "prior_plan.cadence_import_manifest.rows.score_term_review",
             "feedback_scope" => "score_term",
             "trust_boundary" => "cadence_score_import_queue"
           } = List.first(flat_import_score_branch["events"])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives score-term target refresh from inline target specs" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 600.0, "output_step_s" => 60.0},
        "source_score_term_report" => %{
          "schema_contract" => "score_term_report.v1",
          "model" => "score_term_pressure_fixture",
          "source" => "fixture.score_terms",
          "row_count" => 2,
          "score_term_keys" => ["missing_observation_count", "target_gap_count"],
          "assumptions" => %{"score_term_source" => "fixture"},
          "rows" => [
            %{
              "id" => "score_gap:inline_target",
              "rank" => 1,
              "scenario_id" => "leo_1",
              "term_key" => "target gap count",
              "value" => 1.0,
              "timeline_score" => 6.0,
              "selected" => false,
              "target_gap_targets" => [
                %{
                  "target_id" => "target_inline",
                  "priority" => 8.0,
                  "latitude_deg" => 12.0,
                  "longitude_deg" => -33.0,
                  "minimum_elevation_deg" => 15.0
                }
              ]
            },
            %{
              "id" => "score_gap:missed_observation_target",
              "rank" => 2,
              "scenario_id" => "leo_1",
              "term_key" => "missing observation count",
              "value" => 2.0,
              "timeline_score" => 9.0,
              "selected" => false,
              "planned_observations" => 0,
              "missed_observation_target_ids" => ["target_score_missed_obs"],
              "missed_observation_targets" => [
                %{
                  "id" => "target_score_missed_obs",
                  "priority" => "9.0",
                  "latitude_deg" => 15.0,
                  "longitude_deg" => -25.0,
                  "minimum_elevation_deg" => 11.0
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

    score_branch = branch(artifact, "derived_score_term_pressure_score_gap:inline_target")

    missed_observation_branch =
      branch(artifact, "derived_score_term_pressure_score_gap:missed_observation_target")

    assert %{
             "type" => "urgent_target",
             "target_id" => "target_inline",
             "priority" => 8.0,
             "latitude_deg" => 12.0,
             "longitude_deg" => -33.0,
             "minimum_elevation_deg" => 15.0,
             "required_observations" => 1,
             "feedback_source" => "prior_plan.source_score_term_report"
           } = List.first(score_branch["events"])

    assert %{
             "type" => "urgent_target",
             "target_id" => "target_score_missed_obs",
             "priority" => 9.0,
             "latitude_deg" => 15.0,
             "longitude_deg" => -25.0,
             "minimum_elevation_deg" => 11.0,
             "required_observations" => 2,
             "planned_observations" => 0,
             "score_term_key" => "missing_observation_count",
             "score_term_value" => 2.0,
             "feedback_source" => "prior_plan.source_score_term_report",
             "feedback_scope" => "score_term",
             "derivation_reasons" => [
               "score_term_target_gap",
               "score_term_missing_observation_count"
             ]
           } = List.first(missed_observation_branch["events"])

    assert Enum.any?(
             score_branch["candidate_plan"]["strategic_additions"],
             &(&1["type"] == "observe" and &1["target_id"] == "target_inline")
           )

    assert Enum.count(
             missed_observation_branch["candidate_plan"]["strategic_additions"],
             &(&1["type"] == "observe" and &1["target_id"] == "target_score_missed_obs")
           ) == 1

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy scopes score-term target refresh from nested source observation metadata" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 600.0, "output_step_s" => 60.0},
        "candidate_activities" => [
          observe("obs_score_nested_target", "leo_1", "target_score_nested", 360.0, 420.0, 12.0),
          observe(
            "obs_score_nested_target_wrong_spacecraft",
            "leo_2",
            "target_score_nested",
            300.0,
            360.0,
            20.0
          )
        ],
        "source_score_term_report" => %{
          "schema_contract" => "score_term_report.v1",
          "model" => "score_term_pressure_fixture",
          "source" => "fixture.score_terms",
          "row_count" => 1,
          "score_term_keys" => ["target_gap_count"],
          "rows" => [
            %{
              "id" => "score_gap:nested_target",
              "rank" => 1,
              "term_key" => "target gap count",
              "value" => 1.0,
              "source_observation" => %{
                "activity_id" => "obs_score_nested_source",
                "scenario_id" => "leo_1",
                "target_id" => "target_score_nested",
                "priority" => 9.0,
                "latitude_deg" => 22.0,
                "longitude_deg" => 44.0,
                "minimum_elevation_deg" => 18.0
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

    score_branch = branch(artifact, "derived_score_term_pressure_score_gap:nested_target")

    assert %{
             "type" => "urgent_target",
             "target_id" => "target_score_nested",
             "scenario_id" => "leo_1",
             "priority" => 9.0,
             "latitude_deg" => 22.0,
             "longitude_deg" => 44.0,
             "minimum_elevation_deg" => 18.0,
             "required_observations" => 1,
             "source_activity_ids" => ["obs_score_nested_source"],
             "score_term_key" => "target_gap_count",
             "feedback_source" => "prior_plan.source_score_term_report"
           } = List.first(score_branch["events"])

    assert [
             %{
               "id" =>
                 "derived_score_term_pressure_score_gap:nested_target_urgent_observe_target_score_nested",
               "target_id" => "target_score_nested",
               "scenario_id" => "leo_1"
             }
           ] = score_branch["candidate_plan"]["strategic_additions"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives score-term target refresh from commitment and priority aliases" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 600.0, "output_step_s" => 60.0},
        "source_score_term_report" => %{
          "schema_contract" => "score_term_report.v1",
          "model" => "score_term_pressure_fixture",
          "source" => "fixture.score_terms",
          "row_count" => 3,
          "score_term_keys" => ["target_gap_count"],
          "rows" => [
            %{
              "id" => "score_gap:committed_target",
              "rank" => 1,
              "scenario_id" => "leo_1",
              "term_key" => "target_gap_count",
              "value" => 1.0,
              "committed_targets" => [
                %{
                  "target_id" => "target_committed",
                  "priority" => 7.0,
                  "latitude_deg" => 10.0,
                  "longitude_deg" => -40.0,
                  "minimum_elevation_deg" => 14.0
                }
              ]
            },
            %{
              "id" => "score_gap:priority_target",
              "rank" => 2,
              "scenario_id" => "leo_1",
              "term_key" => "target-gap-count",
              "value" => 1.0,
              "priority_targets" => [
                %{
                  "id" => "target_priority_alias",
                  "target_priority" => 11.0,
                  "latitude_deg" => -2.0,
                  "longitude_deg" => 61.0,
                  "minimum_elevation_deg" => 21.0
                }
              ]
            },
            %{
              "id" => "score_gap:missed_target",
              "rank" => 3,
              "scenario_id" => "leo_1",
              "term_key" => "missed_target_count",
              "value" => 1.0,
              "missed_targets" => [
                %{
                  "id" => "target_missed_alias",
                  "target_priority" => 12.0,
                  "latitude_deg" => 4.0,
                  "longitude_deg" => 72.0,
                  "minimum_elevation_deg" => 19.0
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

    committed_branch = branch(artifact, "derived_score_term_pressure_score_gap:committed_target")
    priority_branch = branch(artifact, "derived_score_term_pressure_score_gap:priority_target")
    missed_branch = branch(artifact, "derived_score_term_pressure_score_gap:missed_target")

    assert %{
             "type" => "urgent_target",
             "target_id" => "target_committed",
             "priority" => 7.0,
             "latitude_deg" => 10.0,
             "longitude_deg" => -40.0,
             "minimum_elevation_deg" => 14.0,
             "score_term_key" => "target_gap_count",
             "feedback_source" => "prior_plan.source_score_term_report"
           } = List.first(committed_branch["events"])

    assert %{
             "type" => "urgent_target",
             "target_id" => "target_priority_alias",
             "priority" => 11.0,
             "latitude_deg" => -2.0,
             "longitude_deg" => 61.0,
             "minimum_elevation_deg" => 21.0,
             "score_term_key" => "target_gap_count",
             "feedback_source" => "prior_plan.source_score_term_report"
           } = List.first(priority_branch["events"])

    assert %{
             "type" => "urgent_target",
             "target_id" => "target_missed_alias",
             "priority" => 12.0,
             "latitude_deg" => 4.0,
             "longitude_deg" => 72.0,
             "minimum_elevation_deg" => 19.0,
             "score_term_key" => "missed_target_count",
             "feedback_source" => "prior_plan.source_score_term_report"
           } = List.first(missed_branch["events"])

    assert Enum.any?(
             committed_branch["candidate_plan"]["strategic_additions"],
             &(&1["type"] == "observe" and &1["target_id"] == "target_committed")
           )

    assert Enum.any?(
             priority_branch["candidate_plan"]["strategic_additions"],
             &(&1["type"] == "observe" and &1["target_id"] == "target_priority_alias")
           )

    assert Enum.any?(
             missed_branch["candidate_plan"]["strategic_additions"],
             &(&1["type"] == "observe" and &1["target_id"] == "target_missed_alias")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives score-term target refresh from revisit count aliases" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 600.0, "output_step_s" => 60.0},
        "source_score_term_report" => %{
          "schema_contract" => "score_term_report.v1",
          "model" => "score_term_pressure_fixture",
          "source" => "fixture.score_terms",
          "row_count" => 1,
          "score_term_keys" => ["missing_revisit_count"],
          "provenance" => %{"trust_boundary" => "score_term_revisit_review"},
          "rows" => [
            %{
              "id" => "score_gap:target_revisit",
              "rank" => 1,
              "scenario_id" => "leo_1",
              "term_key" => "missing revisit count",
              "value" => "2",
              "planned_revisits" => "1",
              "missing_revisit_targets" => [
                %{
                  "id" => "target_revisit_alias",
                  "priority" => "6.0",
                  "latitude_deg" => 3.0,
                  "longitude_deg" => 45.0,
                  "minimum_elevation_deg" => 12.0
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

    revisit_branch = branch(artifact, "derived_score_term_pressure_score_gap:target_revisit")

    assert %{
             "type" => "urgent_target",
             "target_id" => "target_revisit_alias",
             "priority" => 6.0,
             "planned_observations" => 1.0,
             "required_observations" => 3,
             "score_term_key" => "missing_revisit_count",
             "score_term_value" => 2.0,
             "feedback_source" => "prior_plan.source_score_term_report",
             "feedback_scope" => "score_term",
             "trust_boundary" => "score_term_revisit_review",
             "derivation_reasons" => [
               "score_term_target_gap",
               "score_term_missing_revisit_count"
             ]
           } = List.first(revisit_branch["events"])

    revisit_additions =
      Enum.filter(
        revisit_branch["candidate_plan"]["strategic_additions"],
        &(&1["target_id"] == "target_revisit_alias")
      )

    assert length(revisit_additions) == 2

    assert Enum.all?(revisit_additions, &(&1["target_id"] == "target_revisit_alias"))

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives score-term target refresh from singular target object aliases" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 600.0, "output_step_s" => 60.0},
        "source_score_term_report" => %{
          "schema_contract" => "score_term_report.v1",
          "model" => "score_term_pressure_fixture",
          "source" => "fixture.score_terms",
          "row_count" => 1,
          "score_term_keys" => ["target_gap_count"],
          "rows" => [
            %{
              "id" => "score_gap:target_object",
              "rank" => 1,
              "scenario_id" => "leo_1",
              "term_key" => "coverage-gap-count",
              "value" => 1.0,
              "target" => %{
                "id" => "target_alias",
                "priority" => 9.0,
                "latitude_deg" => 22.0,
                "longitude_deg" => 44.0,
                "minimum_elevation_deg" => 18.0
              }
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

    score_branch = branch(artifact, "derived_score_term_pressure_score_gap:target_object")

    assert %{
             "type" => "urgent_target",
             "target_id" => "target_alias",
             "priority" => 9.0,
             "latitude_deg" => 22.0,
             "longitude_deg" => 44.0,
             "minimum_elevation_deg" => 18.0,
             "required_observations" => 1,
             "score_term_key" => "coverage_gap_count",
             "feedback_source" => "prior_plan.source_score_term_report"
           } = List.first(score_branch["events"])

    assert Enum.any?(
             score_branch["candidate_plan"]["strategic_additions"],
             &(&1["type"] == "observe" and &1["target_id"] == "target_alias")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy does not derive score-term refresh without explicit routing evidence" do
    prior_plan =
      base_plan(%{
        "source_score_term_report" => %{
          "schema_contract" => "score_term_report.v1",
          "model" => "score_term_pressure_fixture",
          "source" => "fixture.score_terms",
          "row_count" => 2,
          "score_term_keys" => ["downlink_shortfall_mb", "missing_observation_count"],
          "assumptions" => %{"score_term_source" => "fixture"},
          "rows" => [
            %{
              "id" => "score_gap:unrouted_downlink",
              "rank" => 1,
              "scenario_id" => "leo_1",
              "term_key" => "downlink_shortfall_mb",
              "value" => 42.0,
              "timeline_score" => 12.0,
              "selected" => true
            },
            %{
              "id" => "score_gap:unrouted_target",
              "rank" => 1,
              "scenario_id" => "leo_1",
              "term_key" => "missing_observation_count",
              "value" => 2.0,
              "timeline_score" => 9.0,
              "selected" => false
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

    refute branch(artifact, "derived_score_term_pressure_score_gap:unrouted_downlink")
    refute branch(artifact, "derived_score_term_pressure_score_gap:unrouted_target")

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
