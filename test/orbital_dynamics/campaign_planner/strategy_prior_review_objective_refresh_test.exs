Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyPriorReviewObjectiveRefreshTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.{CandidateRefresh, Schema}

  test "strategy derives refresh from prior operator review source rows" do
    prior_plan =
      base_plan(%{
        "operator_review_package" => %{
          "schema_contract" => "operator_review_package.v1",
          "source_artifact_type" => "campaign_repair.v2",
          "review_count" => 4,
          "provenance" => %{"trust_boundary" => "ops_review_queue"},
          "rows" => [
            %{
              "id" => "operator_review:objective_satisfaction:downlink",
              "review_type" => "objective_satisfaction_review",
              "source" => "objective_satisfaction_report.rows",
              "subject_id" => "objective:downlink_completion",
              "objective" => "downlink_completion",
              "objective_status" => "partial",
              "approval_status" => "operator_review_required",
              "source_objective_satisfaction" => %{
                "id" => "objective:downlink_completion",
                "objective" => "downlink_completion",
                "status" => "partial",
                "required_count" => 1,
                "selected_count" => 0,
                "required_downlink_mb" => 90.0,
                "selected_downlink_mb" => 0.0
              }
            },
            %{
              "id" => "operator_review:objective_satisfaction:downlink_flat",
              "review_type" => "objective_satisfaction_review",
              "source" => "objective_satisfaction_report.rows",
              "subject_id" => "objective:downlink_flat_review",
              "objective" => "downlink_completion",
              "objective_status" => "partial",
              "approval_status" => "operator_review_required",
              "required_count" => 1,
              "selected_count" => 0,
              "required_downlink_mb" => 65.0,
              "selected_downlink_mb" => 0.0
            }
          ]
        },
        "cadence_import_manifest" => %{
          "schema_contract" => "cadence_import_manifest.v1",
          "source_artifact_type" => "objective_satisfaction_report.v1",
          "provenance" => %{"trust_boundary" => "cadence_objective_import_queue"},
          "rows" => [
            %{
              "id" => "cadence_import:objective_satisfaction:downlink",
              "import_action" => "review_objective_satisfaction",
              "source_review_type" => "objective_satisfaction_review",
              "approval_status" => "operator_review_required",
              "source_objective_satisfaction" => %{
                "id" => "objective:downlink_import",
                "objective" => "downlink_completion",
                "status" => "partial",
                "required_count" => 1,
                "selected_count" => 0,
                "required_downlink_mb" => 75.0,
                "selected_downlink_mb" => 0.0
              }
            },
            %{
              "id" => "cadence_import:objective_satisfaction:downlink_flat",
              "import_action" => "review_objective_satisfaction",
              "source_review_type" => "objective_satisfaction_review",
              "approval_status" => "operator_review_required",
              "subject_id" => "objective:downlink_flat_import",
              "objective" => "downlink_completion",
              "objective_status" => "partial",
              "required_count" => 1,
              "selected_count" => 0,
              "required_downlink_mb" => 55.0,
              "selected_downlink_mb" => 0.0
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

    review_branch =
      branch(artifact, "derived_objective_satisfaction_objective:downlink_completion")

    assert %{
             "type" => "downlink_completion_gap",
             "objective_id" => "objective:downlink_completion",
             "required_contacts" => 1,
             "planned_contacts" => 0,
             "required_downlink_mb" => 90.0,
             "feedback_source" =>
               "prior_plan.operator_review_package.rows.source_objective_satisfaction",
             "feedback_scope" => "objective_satisfaction",
             "objective_status" => "partial",
             "trust_boundary" => "ops_review_queue"
           } = List.first(review_branch["events"])

    assert List.first(review_branch["events"])["planned_downlink_mb"] == 0.0

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             review_branch["assumptions"]["candidate_source"]

    flat_review_branch =
      branch(artifact, "derived_objective_satisfaction_objective:downlink_flat_review")

    assert %{
             "type" => "downlink_completion_gap",
             "objective_id" => "objective:downlink_flat_review",
             "required_contacts" => 1,
             "planned_contacts" => 0,
             "required_downlink_mb" => 65.0,
             "feedback_source" =>
               "prior_plan.operator_review_package.rows.objective_satisfaction_review",
             "feedback_scope" => "objective_satisfaction",
             "objective_status" => "partial",
             "trust_boundary" => "ops_review_queue"
           } = List.first(flat_review_branch["events"])

    cadence_branch = branch(artifact, "derived_objective_satisfaction_objective:downlink_import")

    assert %{
             "type" => "downlink_completion_gap",
             "objective_id" => "objective:downlink_import",
             "required_contacts" => 1,
             "planned_contacts" => 0,
             "required_downlink_mb" => 75.0,
             "feedback_source" =>
               "prior_plan.cadence_import_manifest.rows.source_objective_satisfaction",
             "feedback_scope" => "objective_satisfaction",
             "objective_status" => "partial",
             "trust_boundary" => "cadence_objective_import_queue"
           } = List.first(cadence_branch["events"])

    flat_cadence_branch =
      branch(artifact, "derived_objective_satisfaction_objective:downlink_flat_import")

    assert %{
             "type" => "downlink_completion_gap",
             "objective_id" => "objective:downlink_flat_import",
             "required_contacts" => 1,
             "planned_contacts" => 0,
             "required_downlink_mb" => 55.0,
             "feedback_source" =>
               "prior_plan.cadence_import_manifest.rows.objective_satisfaction_review",
             "feedback_scope" => "objective_satisfaction",
             "objective_status" => "partial",
             "trust_boundary" => "cadence_objective_import_queue"
           } = List.first(flat_cadence_branch["events"])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy canonicalizes provider data-latency objective pressure into refresh" do
    prior_plan =
      base_plan(%{
        "source_objective_satisfaction_report" => %{
          "schema_contract" => "objective_satisfaction_report.v1",
          "model" => "provider_delivery_objective_summary",
          "source" => "provider.delivery_objectives",
          "objective_count" => 1,
          "provenance" => %{"trust_boundary" => "provider_objective_review"},
          "rows" => [
            %{
              "id" => "objective:data_latency_alias",
              "objective" => "Data Latency",
              "status" => "Needs Replan",
              "scenario_id" => "leo_1",
              "target_id" => "target_a",
              "ground_station_id" => "equator_prime",
              "collection_id" => "collection_alias",
              "starts_at_s" => 0.0,
              "ends_at_s" => 600.0,
              "max_latency_s" => 300.0,
              "required_downlink_mb" => 40.0,
              "planned_downlink_mb" => 0.0,
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
      branch(artifact, "derived_objective_satisfaction_objective:data_latency_alias")

    assert %{
             "type" => "downlink_completion_gap",
             "objective_id" => "objective:data_latency_alias",
             "objective_type" => "collection_latency",
             "latency_objective" => true,
             "scenario_id" => "leo_1",
             "target_id" => "target_a",
             "ground_station_id" => "equator_prime",
             "collection_id" => "collection_alias",
             "required_contacts" => 1,
             "planned_contacts" => 0,
             "required_downlink_mb" => 40.0,
             "planned_downlink_mb" => planned_downlink_mb,
             "max_latency_s" => 300.0,
             "feedback_source" => "prior_plan.source_objective_satisfaction_report",
             "feedback_scope" => "objective_satisfaction",
             "objective_status" => "partial",
             "source_objective_status" => "needs_replan",
             "trust_boundary" => "provider_objective_review"
           } = List.first(latency_branch["events"])

    assert planned_downlink_mb == 0.0

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             candidate_source = latency_branch["assumptions"]["candidate_source"]

    assert "prior_plan.source_objective_satisfaction_report" in candidate_source[
             "source_report_input_paths"
           ]

    assert Enum.any?(
             latency_branch["repair_result"]["source_candidate_activities"],
             &(&1["type"] == "downlink" and
                 &1["ground_station_id"] == "equator_prime" and
                 &1["required_downlink_mb"] == 40.0)
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives refresh from prior objective tradeoff review rows" do
    prior_plan =
      base_plan(%{
        "candidate_activities" => [
          observe("obs_target_a_recovery", "leo_1", "target_a", 360.0, 420.0, 12.0),
          refreshed_downlink("dl_tradeoff_recovery", 360.0, 420.0)
          |> Map.put("estimated_throughput_mb", 90.0)
        ],
        "operator_review_package" => %{
          "schema_contract" => "operator_review_package.v1",
          "source_artifact_type" => "objective_tradeoff_report.v1",
          "review_count" => 3,
          "provenance" => %{"trust_boundary" => "ops_tradeoff_review"},
          "rows" => [
            %{
              "id" => "operator_review:objective_tradeoff:downlink_gap",
              "review_type" => "objective_tradeoff_review",
              "source" => "objective_tradeoff_report.tradeoffs",
              "subject_id" => "downlink_gap",
              "scenario_id" => "leo_1",
              "branch_id" => "downlink_gap",
              "approval_status" => "operator_review_required",
              "source_objective_tradeoff" => %{
                "rank" => 2,
                "scenario_id" => "leo_1",
                "branch_id" => "downlink_gap",
                "objective" => "downlink_completion",
                "selected" => false,
                "score" => 80.0,
                "score_delta_from_selected" => -20.0,
                "required_contact_count" => 1,
                "selected_contact_count" => 0,
                "required_downlink_mb" => 90.0,
                "selected_downlink_mb" => 0.0,
                "ground_station_id" => "equator_prime",
                "activity_ids" => ["dl_missed"],
                "score_terms" => %{"downlink_completion_value" => 90.0}
              }
            },
            %{
              "id" => "operator_review:objective_tradeoff:target_gap",
              "review_type" => "objective_tradeoff_review",
              "source" => "objective_tradeoff_report.tradeoffs",
              "subject_id" => "target_gap",
              "scenario_id" => "leo_1",
              "branch_id" => "target_gap",
              "approval_status" => "operator_review_required",
              "source_objective_tradeoff" => %{
                "rank" => 3,
                "scenario_id" => "leo_1",
                "branch_id" => "target_gap",
                "objective" => "target_coverage",
                "selected" => false,
                "score" => 75.0,
                "score_delta_from_selected" => -25.0,
                "target_id" => "target_a",
                "missed_target_ids" => ["target_a"],
                "required_observation_count" => 1,
                "selected_observation_count" => 0,
                "activity_ids" => ["obs_missed"],
                "score_terms" => %{"Target Value" => 12.0}
              }
            },
            %{
              "id" => "operator_review:objective_tradeoff:flat_downlink_gap",
              "review_type" => "objective_tradeoff_review",
              "source" => "objective_tradeoff_report.tradeoffs",
              "subject_id" => "flat_downlink_gap",
              "scenario_id" => "leo_1",
              "branch_id" => "flat_downlink_gap",
              "approval_status" => "operator_review_required",
              "rank" => 5,
              "objective" => "downlink_completion",
              "selected" => false,
              "score" => 68.0,
              "score_delta_from_selected" => -32.0,
              "required_contact_count" => 1,
              "selected_contact_count" => 0,
              "required_downlink_mb" => 70.0,
              "selected_downlink_mb" => 0.0,
              "ground_station_id" => "equator_prime",
              "activity_ids" => ["dl_flat_missed"],
              "score_terms" => %{"downlink_completion_value" => 70.0}
            }
          ]
        },
        "cadence_import_manifest" => %{
          "schema_contract" => "cadence_import_manifest.v1",
          "source_artifact_type" => "objective_tradeoff_report.v1",
          "provenance" => %{"trust_boundary" => "cadence_tradeoff_import_queue"},
          "rows" => [
            %{
              "id" => "cadence_import:objective_tradeoff:target_gap",
              "import_action" => "review_objective_tradeoff",
              "source_review_type" => "objective_tradeoff_review",
              "approval_status" => "operator_review_required",
              "source_objective_tradeoff" => %{
                "rank" => 4,
                "scenario_id" => "leo_1",
                "branch_id" => "cadence_target_gap",
                "objective" => "target_coverage",
                "selected" => false,
                "score" => 70.0,
                "score_delta_from_selected" => -30.0,
                "target_id" => "target_b",
                "target_gap_ids" => ["target_b"],
                "required_observation_count" => 1,
                "selected_observation_count" => 0,
                "score_terms" => %{"Target Value" => 10.0}
              }
            },
            %{
              "id" => "cadence_import:objective_tradeoff:flat_target_gap",
              "import_action" => "review_objective_tradeoff",
              "source_review_type" => "objective_tradeoff_review",
              "approval_status" => "operator_review_required",
              "rank" => 6,
              "scenario_id" => "leo_1",
              "branch_id" => "flat_cadence_target_gap",
              "objective" => "target_coverage",
              "selected" => false,
              "score" => 66.0,
              "score_delta_from_selected" => -34.0,
              "target_id" => "target_c",
              "target_gap_ids" => ["target_c"],
              "required_observation_count" => 1,
              "selected_observation_count" => 0,
              "score_terms" => %{"Target Value" => 9.0}
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

    downlink_branch = branch(artifact, "derived_objective_tradeoff_pressure_downlink_gap")

    assert %{
             "type" => "downlink_completion_gap",
             "objective_type" => "downlink_completion",
             "scenario_id" => "leo_1",
             "branch_id" => "downlink_gap",
             "ground_station_id" => "equator_prime",
             "required_contacts" => 1,
             "planned_contacts" => 0,
             "required_downlink_mb" => 90.0,
             "source_activity_ids" => ["dl_missed"],
             "feedback_source" =>
               "prior_plan.operator_review_package.rows.source_objective_tradeoff",
             "feedback_scope" => "objective_tradeoff",
             "trust_boundary" => "ops_tradeoff_review"
           } = List.first(downlink_branch["events"])

    assert List.first(downlink_branch["events"])["planned_downlink_mb"] == 0.0

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             downlink_branch["assumptions"]["candidate_source"]

    flat_downlink_branch =
      branch(artifact, "derived_objective_tradeoff_pressure_flat_downlink_gap")

    assert %{
             "type" => "downlink_completion_gap",
             "objective_type" => "downlink_completion",
             "scenario_id" => "leo_1",
             "branch_id" => "flat_downlink_gap",
             "ground_station_id" => "equator_prime",
             "required_contacts" => 1,
             "planned_contacts" => 0,
             "required_downlink_mb" => 70.0,
             "source_activity_ids" => ["dl_flat_missed"],
             "feedback_source" =>
               "prior_plan.operator_review_package.rows.objective_tradeoff_review",
             "feedback_scope" => "objective_tradeoff",
             "trust_boundary" => "ops_tradeoff_review"
           } = List.first(flat_downlink_branch["events"])

    target_branch = branch(artifact, "derived_objective_tradeoff_pressure_target_gap")

    assert %{
             "type" => "urgent_target",
             "objective_type" => "target_coverage",
             "target_id" => "target_a",
             "priority" => 12.0,
             "required_observations" => 1,
             "planned_observations" => 0,
             "source_activity_ids" => ["obs_missed"],
             "feedback_source" =>
               "prior_plan.operator_review_package.rows.source_objective_tradeoff",
             "feedback_scope" => "objective_tradeoff",
             "trust_boundary" => "ops_tradeoff_review"
           } = List.first(target_branch["events"])

    assert Enum.any?(
             target_branch["candidate_plan"]["strategic_additions"],
             &(&1["target_id"] == "target_a")
           )

    cadence_target_branch =
      branch(artifact, "derived_objective_tradeoff_pressure_cadence_target_gap")

    assert %{
             "type" => "urgent_target",
             "objective_type" => "target_coverage",
             "target_id" => "target_b",
             "priority" => 10.0,
             "required_observations" => 1,
             "planned_observations" => 0,
             "feedback_source" =>
               "prior_plan.cadence_import_manifest.rows.source_objective_tradeoff",
             "feedback_scope" => "objective_tradeoff",
             "trust_boundary" => "cadence_tradeoff_import_queue"
           } = List.first(cadence_target_branch["events"])

    flat_cadence_target_branch =
      branch(artifact, "derived_objective_tradeoff_pressure_flat_cadence_target_gap")

    assert %{
             "type" => "urgent_target",
             "objective_type" => "target_coverage",
             "target_id" => "target_c",
             "priority" => 9.0,
             "required_observations" => 1,
             "planned_observations" => 0,
             "feedback_source" =>
               "prior_plan.cadence_import_manifest.rows.objective_tradeoff_review",
             "feedback_scope" => "objective_tradeoff",
             "trust_boundary" => "cadence_tradeoff_import_queue"
           } = List.first(flat_cadence_target_branch["events"])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy keeps independent objective tradeoff pressures for the same branch identity" do
    prior_plan =
      base_plan(%{
        "candidate_activities" => [
          refreshed_downlink("dl_tradeoff_a_recovery", 360.0, 420.0)
          |> Map.put("estimated_throughput_mb", 80.0),
          refreshed_downlink("dl_tradeoff_b_recovery", 480.0, 540.0)
          |> Map.put("ground_station_id", "polar_prime")
          |> Map.put("estimated_throughput_mb", 60.0)
        ],
        "source_objective_tradeoff_report" => %{
          "schema_contract" => "objective_tradeoff_report.v1",
          "model" => "strategy_branch_score_term_tradeoffs",
          "ranking_count" => 1,
          "provenance" => %{"trust_boundary" => "source_tradeoff_review"},
          "rows" => [
            %{
              "rank" => 2,
              "scenario_id" => "leo_1",
              "branch_id" => "shared_tradeoff_downlink",
              "objective" => "downlink_completion",
              "selected" => false,
              "score" => 72.0,
              "score_delta_from_selected" => -18.0,
              "ground_station_id" => "equator_prime",
              "required_downlink_mb" => 80.0,
              "planned_downlink_mb" => 20.0,
              "required_contacts" => 1,
              "planned_contacts" => 0,
              "activity_ids" => ["dl_tradeoff_a"]
            }
          ]
        },
        "objective_tradeoff_report" => %{
          "schema_contract" => "objective_tradeoff_report.v1",
          "model" => "strategy_branch_score_term_tradeoffs",
          "ranking_count" => 1,
          "provenance" => %{"trust_boundary" => "canonical_tradeoff_review"},
          "rows" => [
            %{
              "rank" => 3,
              "scenario_id" => "leo_1",
              "branch_id" => "shared_tradeoff_downlink",
              "objective" => "downlink_completion",
              "selected" => false,
              "score" => 68.0,
              "score_delta_from_selected" => -22.0,
              "ground_station_id" => "polar_prime",
              "required_downlink_mb" => 60.0,
              "planned_downlink_mb" => 10.0,
              "required_contacts" => 1,
              "planned_contacts" => 0,
              "activity_ids" => ["dl_tradeoff_b"]
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

    base_id = "derived_objective_tradeoff_pressure_shared_tradeoff_downlink"
    refute branch(artifact, base_id)

    tradeoff_branches =
      Enum.filter(artifact["branches"], &String.starts_with?(&1["branch_id"], "#{base_id}_"))

    assert length(tradeoff_branches) == 2

    assert MapSet.new(Enum.map(tradeoff_branches, & &1["derived_source"])) ==
             MapSet.new([
               "prior_plan.source_objective_tradeoff_report",
               "prior_plan.objective_tradeoff_report"
             ])

    assert MapSet.new(
             Enum.map(
               tradeoff_branches,
               &get_in(&1, ["events", Access.at(0), "ground_station_id"])
             )
           ) == MapSet.new(["equator_prime", "polar_prime"])

    assert MapSet.new(
             Enum.map(
               tradeoff_branches,
               &get_in(&1, ["events", Access.at(0), "source_activity_ids"])
             )
           ) == MapSet.new([["dl_tradeoff_a"], ["dl_tradeoff_b"]])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives collection latency refresh from objective tradeoff rows" do
    prior_plan =
      base_plan(%{
        "source_objective_tradeoff_report" => %{
          "schema_contract" => "objective_tradeoff_report.v1",
          "model" => "strategy_branch_score_term_tradeoffs",
          "ranking_count" => 1,
          "provenance" => %{"trust_boundary" => "ops_tradeoff_review"},
          "tradeoffs" => [
            %{
              "rank" => 2,
              "scenario_id" => "leo_1",
              "branch_id" => "latency_gap",
              "objective" => "Collection Latency",
              "selected" => false,
              "score" => 80.0,
              "score_delta_from_selected" => -20.0,
              "target_id" => "target_a",
              "collection_id" => "collection_a",
              "source_observation" => %{"activity_id" => "obs_target_a"},
              "selected_contact" => %{"contact_id" => "dl_tradeoff_nested"},
              "ground_station_id" => "equator_prime",
              "collection_end_s" => 0.0,
              "delivery_deadline_s" => 400.0,
              "target_latency_s" => 400.0,
              "actual_delivery_latency_s" => 420.0,
              "target_data_volume_mb" => 40.0,
              "selected_data_volume_mb" => 40.0,
              "planned_contacts" => 0,
              "score_terms" => %{"latency_penalty" => -20.0}
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

    latency_branch = branch(artifact, "derived_objective_tradeoff_pressure_latency_gap")

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             latency_branch["assumptions"]["candidate_source"]

    event = List.first(latency_branch["events"])

    assert %{
             "type" => "downlink_completion_gap",
             "objective_type" => "collection_latency",
             "latency_objective" => true,
             "scenario_id" => "leo_1",
             "branch_id" => "latency_gap",
             "target_id" => "target_a",
             "collection_id" => "collection_a",
             "source_activity_id" => "obs_target_a",
             "source_activity_ids" => ["dl_tradeoff_nested", "obs_target_a"],
             "ends_at_s" => 400.0,
             "required_contacts" => 1,
             "planned_contacts" => 0,
             "required_downlink_mb" => 40.0,
             "planned_downlink_mb" => 40.0,
             "max_latency_s" => 400.0,
             "planned_latency_s" => 420.0,
             "derivation_reasons" => [
               "objective_tradeoff_downlink_gap",
               "collection_latency_gap",
               "objective_tradeoff_latency_gap",
               "objective_tradeoff_unselected"
             ],
             "feedback_source" => "prior_plan.source_objective_tradeoff_report",
             "feedback_scope" => "objective_tradeoff",
             "trust_boundary" => "ops_tradeoff_review"
           } = event

    assert event["starts_at_s"] == 0.0

    assert [
             %{
               "type" => "downlink",
               "ground_station_id" => "equator_prime",
               "repair" => %{"reason" => "collection_latency_downlink_candidate_inserted"}
             } = latency_addition
           ] = latency_branch["candidate_plan"]["strategic_additions"]

    assert %{
             "feedback_source" => "prior_plan.source_objective_tradeoff_report",
             "feedback_scope" => "objective_tradeoff",
             "trust_boundary" => "ops_tradeoff_review",
             "source_event_type" => "downlink_completion_gap",
             "source_branch_id" => "latency_gap",
             "source_activity_id" => "obs_target_a",
             "source_activity_ids" => ["dl_tradeoff_nested", "obs_target_a"],
             "derivation_reasons" => [
               "objective_tradeoff_downlink_gap",
               "collection_latency_gap",
               "objective_tradeoff_latency_gap",
               "objective_tradeoff_unselected"
             ]
           } = latency_addition["feasibility"]

    assert Enum.any?(
             latency_branch["approval_requirements"],
             &(get_in(&1, ["activity_context", "feedback_source"]) ==
                 "prior_plan.source_objective_tradeoff_report" and
                 get_in(&1, ["activity_context", "feedback_scope"]) == "objective_tradeoff" and
                 get_in(&1, ["activity_context", "trust_boundary"]) == "ops_tradeoff_review")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives collection latency refresh from mission-state objective tradeoff rows" do
    objective_tradeoff_report = %{
      "schema_contract" => "objective_tradeoff_report.v1",
      "model" => "mission_state_strategy_branch_score_term_tradeoffs",
      "ranking_count" => 1,
      "provenance" => %{"trust_boundary" => "mission_tradeoff_review"},
      "tradeoffs" => [
        %{
          "rank" => 2,
          "scenario_id" => "leo_1",
          "branch_id" => "latency_gap",
          "objective" => "Collection Latency",
          "selected" => false,
          "score" => 80.0,
          "score_delta_from_selected" => -20.0,
          "target_id" => "target_a",
          "collection_id" => "collection_a",
          "source_observation" => %{"activity_id" => "obs_target_a"},
          "selected_contact" => %{"contact_id" => "dl_tradeoff_nested"},
          "ground_station_id" => "equator_prime",
          "collection_end_s" => 0.0,
          "delivery_deadline_s" => 400.0,
          "target_latency_s" => 400.0,
          "actual_delivery_latency_s" => 420.0,
          "target_data_volume_mb" => 40.0,
          "selected_data_volume_mb" => 40.0,
          "planned_contacts" => 0,
          "score_terms" => %{"latency_penalty" => -20.0}
        }
      ]
    }

    artifact =
      strategy(base_plan(%{}),
        mission_state:
          mission_state_with_refresh_inputs()
          |> Map.put(:source_objective_tradeoff_report, objective_tradeoff_report),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    latency_branch = branch(artifact, "derived_objective_tradeoff_pressure_latency_gap")

    assert_candidate_source_report_path(
      latency_branch,
      "mission_state.source_objective_tradeoff_report"
    )

    assert %{
             "type" => "downlink_completion_gap",
             "objective_type" => "collection_latency",
             "latency_objective" => true,
             "scenario_id" => "leo_1",
             "branch_id" => "latency_gap",
             "target_id" => "target_a",
             "collection_id" => "collection_a",
             "source_activity_id" => "obs_target_a",
             "source_activity_ids" => ["dl_tradeoff_nested", "obs_target_a"],
             "ends_at_s" => 400.0,
             "required_contacts" => 1,
             "planned_contacts" => 0,
             "required_downlink_mb" => 40.0,
             "planned_downlink_mb" => 40.0,
             "max_latency_s" => 400.0,
             "planned_latency_s" => 420.0,
             "feedback_source" => "mission_state.source_objective_tradeoff_report",
             "feedback_scope" => "objective_tradeoff",
             "trust_boundary" => "mission_tradeoff_review"
           } = List.first(latency_branch["events"])

    assert Enum.any?(
             latency_branch["candidate_plan"]["strategic_additions"],
             &(&1["type"] == "downlink" and
                 &1["ground_station_id"] == "equator_prime" and
                 get_in(&1, ["feasibility", "feedback_source"]) ==
                   "mission_state.source_objective_tradeoff_report")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives mission-state objective and constraint pressure from result artifact wrappers" do
    source_result_artifact = %{
      "schema_contract" => "result_artifact.v1",
      "study_id" => "live_objective_result_artifact",
      "metadata" => %{"trust_boundary" => "live_objective_result_review"},
      "constraint_report" => %{
        "schema_contract" => "constraint_report.v1",
        "model" => "campaign_repair_local_constraint_summary",
        "constraint_count" => 1,
        "row_count" => 1,
        "status" => "warning",
        "rows" => [
          %{
            "constraint_id" => "campaign:live_result_storage_margin",
            "scenario_id" => "leo_1",
            "spacecraft_id" => "leo_1",
            "metric" => "Projected Storage Margin",
            "operator" => ">=",
            "threshold" => 0.85,
            "value" => 0.2,
            "status" => "Warning",
            "violation_severity" => "Warning",
            "activity_id" => "obs_live_result_storage"
          }
        ]
      },
      "objective_satisfaction_report" => %{
        "schema_contract" => "objective_satisfaction_report.v1",
        "model" => "mission_state_objective_summary",
        "source" => "mission_state.objectives",
        "objective_count" => 1,
        "rows" => [
          %{
            "id" => "objective:live_result_downlink",
            "objective" => "Downlink Completion",
            "status" => "Partial",
            "scenario_id" => "leo_1",
            "ground_station_id" => "equator_prime",
            "starts_at_s" => 0.0,
            "ends_at_s" => 650.0,
            "required_count" => 2,
            "selected_count" => 1,
            "required_downlink_mb" => 120.0,
            "selected_downlink_mb" => 70.0,
            "selected_contact_ids" => ["dl_selected_live_result"]
          }
        ]
      },
      "objective_tradeoff_report" => %{
        "schema_contract" => "objective_tradeoff_report.v1",
        "model" => "mission_state_strategy_branch_score_term_tradeoffs",
        "ranking_count" => 1,
        "tradeoffs" => [
          %{
            "rank" => 2,
            "scenario_id" => "leo_1",
            "branch_id" => "live_result_latency_gap",
            "objective" => "Collection Latency",
            "selected" => false,
            "score" => 80.0,
            "score_delta_from_selected" => -20.0,
            "target_id" => "target_a",
            "collection_id" => "collection_a",
            "source_observation" => %{"activity_id" => "obs_target_a"},
            "selected_contact" => %{"contact_id" => "dl_tradeoff_live_result"},
            "ground_station_id" => "equator_prime",
            "collection_end_s" => 0.0,
            "delivery_deadline_s" => 400.0,
            "target_latency_s" => 400.0,
            "actual_delivery_latency_s" => 420.0,
            "target_data_volume_mb" => 40.0,
            "selected_data_volume_mb" => 40.0,
            "planned_contacts" => 0
          }
        ]
      },
      "score_term_report" => %{
        "schema_contract" => "score_term_report.v1",
        "model" => "score_term_pressure_fixture",
        "source" => "fixture.score_terms",
        "row_count" => 1,
        "score_term_keys" => ["downlink_shortfall_mb"],
        "rows" => [
          %{
            "id" => "score_gap:live_result_downlink",
            "rank" => 1,
            "scenario_id" => "leo_1",
            "term_key" => "downlink shortfall mb",
            "value" => "42.0",
            "timeline_score" => 12.0,
            "selected" => true,
            "ground_station_id" => "equator_prime",
            "planned_downlink_mb" => 8.0,
            "selected_contact_ids" => ["dl_score_live_result"]
          }
        ]
      }
    }

    artifact =
      strategy(
        base_plan(%{
          "planning_horizon" => %{"duration_s" => 700.0, "output_step_s" => 60.0},
          "activities" => [
            observe("obs_live_result_storage", "leo_1", "target_a", 100.0, 160.0, 12.0),
            downlink("dl_score_live_result", 200.0, 260.0)
          ],
          "candidate_activities" => [
            refreshed_downlink("dl_live_objective_recovery", 520.0, 580.0)
            |> Map.put("estimated_throughput_mb", 120.0)
          ]
        }),
        mission_state:
          mission_state_with_refresh_inputs()
          |> Map.put(:source_result_artifact, source_result_artifact),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    constraint_branch =
      branch(artifact, "derived_constraint_pressure_campaign:live_result_storage_margin")

    assert %{
             "type" => "resource_margin_pressure",
             "resource_field" => "storage_margin",
             "storage_margin" => 0.2,
             "storage_margin_threshold" => 0.85,
             "activity_id" => "obs_live_result_storage",
             "feedback_source" => "mission_state.source_result_artifact.constraint_report",
             "feedback_scope" => "constraint_report",
             "trust_boundary" => "live_objective_result_review"
           } = List.first(constraint_branch["events"])

    assert "mission_state.source_result_artifact.constraint_report" in get_in(
             constraint_branch,
             ["assumptions", "candidate_source", "source_report_input_paths"]
           )

    objective_branch =
      branch(artifact, "derived_objective_satisfaction_objective:live_result_downlink")

    assert %{
             "type" => "downlink_completion_gap",
             "objective_id" => "objective:live_result_downlink",
             "required_downlink_mb" => 120.0,
             "planned_downlink_mb" => 70.0,
             "source_activity_ids" => ["dl_selected_live_result"],
             "feedback_source" =>
               "mission_state.source_result_artifact.objective_satisfaction_report",
             "feedback_scope" => "objective_satisfaction",
             "trust_boundary" => "live_objective_result_review"
           } = List.first(objective_branch["events"])

    assert "mission_state.source_result_artifact.objective_satisfaction_report" in get_in(
             objective_branch,
             ["assumptions", "candidate_source", "source_report_input_paths"]
           )

    assert "mission_state.source_result_artifact.objective_satisfaction_report" in get_in(
             objective_branch,
             [
               "assumptions",
               "candidate_source",
               "candidate_refresh_request_source_report_input_paths"
             ]
           )

    objective_candidate_source = get_in(objective_branch, ["assumptions", "candidate_source"])

    assert %{
             "source_report_objective_satisfaction_gap_row_count" => 2,
             "source_report_objective_satisfaction_downlink_gap_row_count" => 2,
             "source_report_objective_satisfaction_status_counts" => %{"partial" => 2},
             "source_reports" => %{
               "objective_satisfaction_report" => %{
                 "paths" => [
                   "mission_state.source_objective_satisfaction_report",
                   "mission_state.source_result_artifact.objective_satisfaction_report"
                 ],
                 "row_count" => 2,
                 "trust_boundary_status" => "declared",
                 "trust_boundaries" => ["live_objective_result_review"]
               }
             }
           } =
             objective_candidate_source["candidate_refresh_request_source_report_summary"]

    assert %{
             "objective_satisfaction_gap_row_count" => 2,
             "objective_satisfaction_status_counts" => %{"partial" => 2},
             "downlink_gap_row_count" => downlink_gap_row_count,
             "branch_local_objective_gap_pressure" => true,
             "branch_local_downlink_gap_pressure" => true,
             "branch_local_objective_status_pressure" => true,
             "assumptions" => %{
               "objective_generation" => "not_performed_by_summary",
               "score_recalculation" => "not_performed_by_summary",
               "candidate_generation" => "not_performed_by_summary"
             }
           } =
             objective_gap_summary =
             CandidateRefresh.objective_gap_replay_summary(objective_candidate_source)

    assert downlink_gap_row_count >= 2
    assert "objective_satisfaction_report.v1" in objective_gap_summary["contracts"]

    for source_path <- [
          "mission_state.source_objective_satisfaction_report",
          "mission_state.source_result_artifact.objective_satisfaction_report"
        ] do
      assert source_path in objective_gap_summary["source_report_paths"]
    end

    assert objective_gap_summary["ground_station_counts"]["equator_prime"] >= 2
    assert objective_gap_summary["source_activity_id_counts"]["dl_selected_live_result"] == 2
    assert objective_gap_summary["trust_boundary_status_counts"]["declared"] >= 2
    assert objective_gap_summary["trust_boundaries"] == ["live_objective_result_review"]

    tradeoff_branch =
      branch(artifact, "derived_objective_tradeoff_pressure_live_result_latency_gap")

    assert %{
             "type" => "downlink_completion_gap",
             "objective_type" => "collection_latency",
             "branch_id" => "live_result_latency_gap",
             "source_activity_ids" => ["dl_tradeoff_live_result", "obs_target_a"],
             "feedback_source" =>
               "mission_state.source_result_artifact.objective_tradeoff_report",
             "feedback_scope" => "objective_tradeoff",
             "trust_boundary" => "live_objective_result_review"
           } = List.first(tradeoff_branch["events"])

    assert "mission_state.source_result_artifact.objective_tradeoff_report" in get_in(
             tradeoff_branch,
             ["assumptions", "candidate_source", "source_report_input_paths"]
           )

    assert "mission_state.source_result_artifact.objective_tradeoff_report" in get_in(
             tradeoff_branch,
             [
               "assumptions",
               "candidate_source",
               "candidate_refresh_request_source_report_input_paths"
             ]
           )

    tradeoff_candidate_source = get_in(tradeoff_branch, ["assumptions", "candidate_source"])

    assert %{
             "source_report_objective_tradeoff_downlink_gap_row_count" => 2,
             "source_report_objective_tradeoff_collection_latency_gap_row_count" => 2,
             "source_report_objective_tradeoff_ground_station_counts" => %{"equator_prime" => 2},
             "source_report_objective_tradeoff_collection_counts" => %{"collection_a" => 2},
             "source_reports" => %{
               "objective_tradeoff_report" => %{
                 "paths" => [
                   "mission_state.source_objective_tradeoff_report",
                   "mission_state.source_result_artifact.objective_tradeoff_report"
                 ],
                 "row_count" => 2,
                 "trust_boundary_status" => "declared",
                 "trust_boundaries" => ["live_objective_result_review"]
               }
             }
           } =
             tradeoff_candidate_source["candidate_refresh_request_source_report_summary"]

    assert %{
             "objective_tradeoff_downlink_gap_row_count" => tradeoff_downlink_count,
             "objective_tradeoff_collection_latency_gap_row_count" => tradeoff_latency_count,
             "branch_local_collection_latency_gap_pressure" => true,
             "branch_local_routing_pressure" => true,
             "assumptions" => %{
               "score_recalculation" => "not_performed_by_summary",
               "candidate_generation" => "not_performed_by_summary"
             }
           } =
             tradeoff_gap_summary =
             CandidateRefresh.objective_gap_replay_summary(tradeoff_candidate_source)

    assert tradeoff_downlink_count >= 2
    assert tradeoff_latency_count >= 2
    assert "objective_tradeoff_report.v1" in tradeoff_gap_summary["contracts"]

    for source_path <- [
          "mission_state.source_objective_tradeoff_report",
          "mission_state.source_result_artifact.objective_tradeoff_report"
        ] do
      assert source_path in tradeoff_gap_summary["source_report_paths"]
    end

    assert tradeoff_gap_summary["collection_counts"]["collection_a"] >= 2
    assert tradeoff_gap_summary["source_activity_id_counts"]["dl_tradeoff_live_result"] == 2
    assert tradeoff_gap_summary["trust_boundaries"] == ["live_objective_result_review"]

    score_branch = branch(artifact, "derived_score_term_pressure_score_gap:live_result_downlink")

    assert %{
             "type" => "downlink_completion_gap",
             "score_term_key" => "downlink_shortfall_mb",
             "score_term_value" => 42.0,
             "source_activity_ids" => ["dl_score_live_result"],
             "feedback_source" => "mission_state.source_result_artifact.score_term_report",
             "feedback_scope" => "score_term",
             "trust_boundary" => "live_objective_result_review"
           } = List.first(score_branch["events"])

    assert "mission_state.source_result_artifact.score_term_report" in get_in(
             score_branch,
             ["assumptions", "candidate_source", "source_report_input_paths"]
           )

    assert "mission_state.source_result_artifact.score_term_report" in get_in(
             score_branch,
             [
               "assumptions",
               "candidate_source",
               "candidate_refresh_request_source_report_input_paths"
             ]
           )

    score_candidate_source = get_in(score_branch, ["assumptions", "candidate_source"])

    score_request_summary =
      score_candidate_source["candidate_refresh_request_source_report_summary"]

    assert %{
             "source_report_score_term_downlink_gap_row_count" => 2,
             "source_report_score_term_term_key_counts" => %{"downlink_shortfall_mb" => 2},
             "source_report_score_term_ground_station_counts" => %{"equator_prime" => 2}
           } = score_request_summary

    assert %{
             "row_count" => 2,
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["live_objective_result_review"]
           } =
             score_term_report_summary =
             get_in(score_request_summary, [
               "source_reports",
               "score_term_report"
             ])

    assert Enum.sort(score_term_report_summary["paths"]) == [
             "mission_state.source_result_artifact.score_term_report",
             "mission_state.source_score_term_report"
           ]

    assert %{
             "score_term_downlink_gap_row_count" => score_term_downlink_count,
             "score_term_key_counts" => %{"downlink_shortfall_mb" => 2},
             "branch_local_score_term_pressure" => true,
             "branch_local_downlink_gap_pressure" => true,
             "assumptions" => %{
               "score_recalculation" => "not_performed_by_summary",
               "candidate_generation" => "not_performed_by_summary"
             }
           } =
             score_gap_summary =
             CandidateRefresh.objective_gap_replay_summary(score_candidate_source)

    assert score_term_downlink_count >= 2
    assert "score_term_report.v1" in score_gap_summary["contracts"]

    for source_path <- [
          "mission_state.source_result_artifact.score_term_report",
          "mission_state.source_score_term_report"
        ] do
      assert source_path in score_gap_summary["source_report_paths"]
    end

    assert score_gap_summary["ground_station_counts"]["equator_prime"] >= 2
    assert score_gap_summary["source_activity_id_counts"]["dl_score_live_result"] == 2
    assert score_gap_summary["trust_boundaries"] == ["live_objective_result_review"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy replays list-valued result-artifact source reports with indexed paths" do
    source_result_artifact = %{
      "schema_contract" => "result_artifact.v1",
      "study_id" => "live_list_result_artifact",
      "metadata" => %{"trust_boundary" => "live_list_result_review"},
      "source_constraint_report" => [
        %{
          "schema_contract" => "constraint_report.v1",
          "model" => "campaign_repair_local_constraint_summary",
          "constraint_count" => 1,
          "row_count" => 1,
          "status" => "pass",
          "rows" => [
            %{
              "constraint_id" => "campaign:list_pass_storage_margin",
              "scenario_id" => "leo_1",
              "metric" => "Projected Storage Margin",
              "operator" => ">=",
              "threshold" => 0.2,
              "value" => 0.9,
              "status" => "pass",
              "violation_severity" => "warning"
            }
          ]
        },
        %{
          "schema_contract" => "constraint_report.v1",
          "model" => "campaign_repair_local_constraint_summary",
          "constraint_count" => 1,
          "row_count" => 1,
          "status" => "warning",
          "rows" => [
            %{
              "constraint_id" => "campaign:list_storage_margin",
              "scenario_id" => "leo_1",
              "spacecraft_id" => "leo_1",
              "metric" => "Projected Storage Margin",
              "operator" => ">=",
              "threshold" => 0.85,
              "value" => 0.2,
              "status" => "warning",
              "violation_severity" => "warning",
              "activity_id" => "obs_list_storage"
            }
          ]
        }
      ]
    }

    artifact =
      strategy(
        base_plan(%{
          "planning_horizon" => %{"duration_s" => 700.0, "output_step_s" => 60.0},
          "activities" => [
            observe("obs_list_storage", "leo_1", "target_a", 100.0, 160.0, 12.0)
          ],
          "candidate_activities" => [
            refreshed_downlink("dl_list_storage_recovery", 520.0, 580.0)
            |> Map.put("estimated_throughput_mb", 120.0)
          ]
        }),
        mission_state:
          mission_state_with_refresh_inputs()
          |> Map.put(:source_result_artifact, source_result_artifact),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    constraint_branch =
      branch(artifact, "derived_constraint_pressure_campaign:list_storage_margin")

    assert %{
             "type" => "resource_margin_pressure",
             "resource_field" => "storage_margin",
             "activity_id" => "obs_list_storage",
             "feedback_source" =>
               "mission_state.source_result_artifact.source_constraint_report[1]",
             "feedback_scope" => "constraint_report",
             "trust_boundary" => "live_list_result_review"
           } = List.first(constraint_branch["events"])

    assert "mission_state.source_result_artifact.source_constraint_report[1]" in get_in(
             constraint_branch,
             ["assumptions", "candidate_source", "source_report_input_paths"]
           )

    assert "mission_state.source_result_artifact.source_constraint_report[1]" in get_in(
             constraint_branch,
             [
               "assumptions",
               "candidate_source",
               "candidate_refresh_request_source_report_input_paths"
             ]
           )

    assert %{
             "source_report_count" => 4,
             "source_report_row_count" => 4,
             "source_report_constraint_status_counts" => %{"pass" => 2, "warning" => 2},
             "source_report_constraint_resource_margin_row_count" => 2,
             "source_reports" => %{
               "constraint_report" => %{
                 "paths" => [
                   "mission_state.source_constraint_report[0]",
                   "mission_state.source_constraint_report[1]",
                   "mission_state.source_result_artifact.source_constraint_report[0]",
                   "mission_state.source_result_artifact.source_constraint_report[1]"
                 ],
                 "row_count" => 4,
                 "trust_boundary_status" => "declared",
                 "trust_boundaries" => ["live_list_result_review"]
               }
             }
           } =
             get_in(constraint_branch, [
               "assumptions",
               "candidate_source",
               "candidate_refresh_request_source_report_summary"
             ])

    assert %{
             "contract" => "constraint_report.v1",
             "source_report_count" => 4,
             "source_report_row_count" => 4,
             "source_report_paths" => [
               "mission_state.source_constraint_report[0]",
               "mission_state.source_constraint_report[1]",
               "mission_state.source_result_artifact.source_constraint_report[0]",
               "mission_state.source_result_artifact.source_constraint_report[1]"
             ],
             "status_counts" => %{"pass" => 2, "warning" => 2},
             "constraint_id_counts" => %{
               "campaign:list_pass_storage_margin" => 2,
               "campaign:list_storage_margin" => 2
             },
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["live_list_result_review"],
             "branch_local_constraint_pressure" => true,
             "branch_local_resource_margin_pressure" => true,
             "assumptions" => %{
               "resource_mutation" => "not_performed_by_summary",
               "candidate_generation" => "not_performed_by_summary"
             }
           } =
             constraint_branch
             |> get_in(["assumptions", "candidate_source"])
             |> CandidateRefresh.constraint_replay_summary()

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives prior result-artifact objective pressure from source report keys" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 700.0, "output_step_s" => 60.0},
        "activities" => [
          observe("obs_prior_source_storage", "leo_1", "target_a", 100.0, 160.0, 12.0),
          downlink("dl_prior_source_score", 200.0, 260.0)
        ],
        "candidate_activities" => [
          refreshed_downlink("dl_prior_source_objective_recovery", 520.0, 580.0)
          |> Map.put("estimated_throughput_mb", 120.0),
          observe("obs_prior_source_target_recovery", "leo_1", "target_b", 300.0, 360.0, 10.0)
        ],
        "source_result_artifact" => %{
          "schema_contract" => "result_artifact.v1",
          "study_id" => "prior_source_objective_result_artifact",
          "provenance" => %{"trust_boundary" => "ops_prior_source_result_artifact"},
          "source_constraint_report" => %{
            "schema_contract" => "constraint_report.v1",
            "model" => "campaign_repair_local_constraint_summary",
            "constraint_count" => 1,
            "row_count" => 1,
            "status" => "warning",
            "rows" => [
              %{
                "constraint_id" => "campaign:prior_source_storage_margin",
                "scenario_id" => "leo_1",
                "spacecraft_id" => "leo_1",
                "metric" => "Projected Storage Margin",
                "operator" => ">=",
                "threshold" => 0.85,
                "value" => 0.2,
                "status" => "Warning",
                "violation_severity" => "Warning",
                "activity_id" => "obs_prior_source_storage"
              }
            ]
          },
          "source_objective_satisfaction_report" => %{
            "schema_contract" => "objective_satisfaction_report.v1",
            "model" => "prior_source_objective_summary",
            "source" => "adapter.objectives",
            "objective_count" => 1,
            "rows" => [
              %{
                "id" => "objective:prior_source_downlink",
                "objective" => "Downlink Completion",
                "status" => "Partial",
                "scenario_id" => "leo_1",
                "ground_station_id" => "equator_prime",
                "starts_at_s" => 0.0,
                "ends_at_s" => 650.0,
                "required_count" => 2,
                "selected_count" => 1,
                "required_downlink_mb" => 120.0,
                "selected_downlink_mb" => 70.0,
                "selected_contact_ids" => ["dl_prior_source_selected"]
              }
            ]
          },
          "source_objective_tradeoff_report" => %{
            "schema_contract" => "objective_tradeoff_report.v1",
            "model" => "prior_source_strategy_tradeoffs",
            "ranking_count" => 1,
            "tradeoffs" => [
              %{
                "rank" => 2,
                "scenario_id" => "leo_1",
                "branch_id" => "prior_source_target_gap",
                "objective" => "Target Coverage",
                "selected" => false,
                "score" => 80.0,
                "score_delta_from_selected" => -20.0,
                "target_gap_ids" => ["target_b"],
                "required_observation_count" => 1,
                "selected_observation_count" => 0
              }
            ]
          },
          "source_score_term_report" => %{
            "schema_contract" => "score_term_report.v1",
            "model" => "score_term_pressure_fixture",
            "source" => "fixture.score_terms",
            "row_count" => 1,
            "score_term_keys" => ["downlink_shortfall_mb"],
            "rows" => [
              %{
                "id" => "score_gap:prior_source_downlink",
                "rank" => 1,
                "scenario_id" => "leo_1",
                "term_key" => "downlink shortfall mb",
                "value" => "42.0",
                "timeline_score" => 12.0,
                "selected" => true,
                "ground_station_id" => "equator_prime",
                "planned_downlink_mb" => 8.0,
                "selected_contact_ids" => ["dl_prior_source_score"]
              }
            ]
          }
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state_with_refresh_inputs()
          |> Map.update!(:targets, fn targets ->
            targets ++
              [
                %{
                  id: "target_b",
                  latitude_deg: 8.0,
                  longitude_deg: 8.0,
                  minimum_elevation_deg: 10.0,
                  priority: 4.0
                }
              ]
          end),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    constraint_branch =
      branch(artifact, "derived_constraint_pressure_campaign:prior_source_storage_margin")

    assert %{
             "type" => "resource_margin_pressure",
             "resource_field" => "storage_margin",
             "activity_id" => "obs_prior_source_storage",
             "feedback_source" => "prior_plan.source_result_artifact.source_constraint_report",
             "trust_boundary" => "ops_prior_source_result_artifact"
           } = List.first(constraint_branch["events"])

    objective_branch =
      branch(artifact, "derived_objective_satisfaction_objective:prior_source_downlink")

    assert %{
             "type" => "downlink_completion_gap",
             "objective_id" => "objective:prior_source_downlink",
             "required_downlink_mb" => 120.0,
             "planned_downlink_mb" => 70.0,
             "feedback_source" =>
               "prior_plan.source_result_artifact.source_objective_satisfaction_report",
             "trust_boundary" => "ops_prior_source_result_artifact"
           } = List.first(objective_branch["events"])

    tradeoff_branch =
      branch(artifact, "derived_objective_tradeoff_pressure_prior_source_target_gap")

    assert %{
             "type" => "urgent_target",
             "objective_type" => "target_coverage",
             "target_id" => "target_b",
             "required_observations" => 1,
             "planned_observations" => 0,
             "feedback_source" =>
               "prior_plan.source_result_artifact.source_objective_tradeoff_report",
             "trust_boundary" => "ops_prior_source_result_artifact"
           } = List.first(tradeoff_branch["events"])

    score_branch = branch(artifact, "derived_score_term_pressure_score_gap:prior_source_downlink")

    assert %{
             "type" => "downlink_completion_gap",
             "score_term_key" => "downlink_shortfall_mb",
             "score_term_value" => 42.0,
             "source_activity_ids" => ["dl_prior_source_score"],
             "feedback_source" => "prior_plan.source_result_artifact.source_score_term_report",
             "trust_boundary" => "ops_prior_source_result_artifact"
           } = List.first(score_branch["events"])

    assert Enum.any?(
             tradeoff_branch["candidate_plan"]["strategic_additions"],
             &(get_in(&1, ["feasibility", "feedback_source"]) ==
                 "prior_plan.source_result_artifact.source_objective_tradeoff_report" and
                 &1["target_id"] == "target_b")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy scopes objective tradeoff latency refresh from nested source observation metadata" do
    prior_plan =
      base_plan(%{
        "source_objective_tradeoff_report" => %{
          "schema_contract" => "objective_tradeoff_report.v1",
          "model" => "provider_collection_latency_tradeoffs",
          "ranking_count" => 1,
          "provenance" => %{"trust_boundary" => "provider_tradeoff_review"},
          "rows" => [
            %{
              "rank" => 2,
              "branch_id" => "latency_nested_context",
              "objective" => "Collection Latency",
              "selected" => false,
              "score" => 70.0,
              "score_delta_from_selected" => -30.0,
              "source_observation" => %{
                "activity_id" => "obs_tradeoff_nested",
                "scenario_id" => "leo_1",
                "station" => %{"id" => "equator_prime"},
                "target_id" => "target_a",
                "collection_id" => "collection_tradeoff_nested",
                "product_id" => "product_tradeoff_nested",
                "payload_id" => "payload_tradeoff_nested",
                "instrument_id" => "instrument_tradeoff_nested",
                "collection_end_s" => "120.0",
                "target_latency_s" => "180.0",
                "actual_delivery_latency_s" => "420.0",
                "target_data_volume_mb" => "25.0",
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
      branch(artifact, "derived_objective_tradeoff_pressure_latency_nested_context")

    event = List.first(latency_branch["events"])

    assert %{
             "type" => "downlink_completion_gap",
             "objective_type" => "collection_latency",
             "latency_objective" => true,
             "scenario_id" => "leo_1",
             "branch_id" => "latency_nested_context",
             "target_id" => "target_a",
             "ground_station_id" => "equator_prime",
             "collection_id" => "collection_tradeoff_nested",
             "product_id" => "product_tradeoff_nested",
             "product_ids" => ["product_tradeoff_nested"],
             "payload_id" => "payload_tradeoff_nested",
             "instrument_id" => "instrument_tradeoff_nested",
             "source_activity_id" => "obs_tradeoff_nested",
             "source_activity_ids" => ["obs_tradeoff_nested"],
             "starts_at_s" => 120.0,
             "ends_at_s" => 300.0,
             "required_downlink_mb" => 25.0,
             "max_latency_s" => 180.0,
             "planned_latency_s" => 420.0,
             "feedback_source" => "prior_plan.source_objective_tradeoff_report",
             "feedback_scope" => "objective_tradeoff",
             "trust_boundary" => "provider_tradeoff_review"
           } = event

    assert event["planned_downlink_mb"] == 4.0

    assert Enum.any?(
             latency_branch["repair_result"]["source_candidate_activities"],
             &(&1["type"] == "downlink" and
                 &1["collection_id"] == "collection_tradeoff_nested" and
                 &1["product_id"] == "product_tradeoff_nested" and
                 &1["payload_id"] == "payload_tradeoff_nested" and
                 &1["instrument_id"] == "instrument_tradeoff_nested")
           )

    assert latency_branch["candidate_plan"]["strategic_additions"] == []

    assert "downlink completion gap not staged: no_validated_candidate_window" in latency_branch[
             "warnings"
           ]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  defp assert_candidate_source_report_path(branch, expected_path) do
    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             candidate_source = branch["assumptions"]["candidate_source"]

    assert expected_path in candidate_source["source_report_input_paths"]
    candidate_source
  end
end
