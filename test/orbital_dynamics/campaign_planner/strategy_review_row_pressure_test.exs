Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyReviewRowPressureTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy derives branch refresh from prior contact allocation capacity pack reviews" do
    prior_plan =
      base_plan(%{
        "activities" => [
          downlink("dl_pack_review", 520.0, 580.0),
          downlink("dl_pack_import", 620.0, 680.0)
        ],
        "operator_review_package" => %{
          "schema_contract" => "operator_review_package.v1",
          "source_artifact_type" => "contact_allocation_report.v1",
          "review_count" => 1,
          "provenance" => %{"trust_boundary" => "ops_capacity_pack_review"},
          "rows" => [
            %{
              "id" => "operator_review:capacity_pack:review",
              "review_type" => "contact_allocation_capacity_pack_review",
              "source_contact_allocation_capacity_pack" => %{
                "contention_group_id" => "station:equator_prime:pack:review",
                "ground_station_id" => "equator_prime",
                "capacity_fraction" => 0.5,
                "used_capacity_fraction" => 0.5,
                "unused_capacity_fraction" => 0.0,
                "selected_contact_ids" => ["dl_selected_review"],
                "deferred_contact_ids" => ["dl_pack_review"],
                "capacity_requirement_rows" => [
                  %{
                    "contact_id" => "dl_selected_review",
                    "required_capacity_fraction" => 0.25,
                    "required_capacity_fraction_source" => "contact_required_capacity_fraction",
                    "capacity_pack_status" => "selected_by_contention_resolution"
                  },
                  %{
                    "contact_id" => "dl_pack_review",
                    "required_capacity_fraction" => 0.25,
                    "required_capacity_fraction_source" => "contact_required_capacity_fraction",
                    "capacity_pack_status" => "deferred_by_reduced_station_capacity_pack"
                  }
                ],
                "pack_status" => "deferred_by_reduced_station_capacity_pack",
                "source_contention_recommendation" => %{
                  "group_id" => "station:equator_prime:pack:review",
                  "selected_contact_id" => "dl_selected_review",
                  "deferred_contact_ids" => ["dl_pack_review"],
                  "source_contact_candidates" => [
                    downlink("dl_selected_review", 500.0, 560.0)
                    |> Map.put("estimated_throughput_mb", 40.0),
                    downlink("dl_pack_review", 520.0, 580.0)
                    |> Map.put("estimated_throughput_mb", 37.0)
                    |> Map.put(
                      "source_window_id",
                      "window:leo_1:ground_station_access:equator_prime:pack_review"
                    )
                  ]
                }
              }
            }
          ]
        },
        "cadence_import_manifest" => %{
          "schema_contract" => "cadence_import_manifest.v1",
          "source_artifact_type" => "operator_review_package.v1",
          "row_count" => 1,
          "review_required_count" => 1,
          "provenance" => %{"trust_boundary" => "cadence_capacity_pack_review"},
          "rows" => [
            %{
              "id" => "cadence_import:capacity_pack:import",
              "import_action" => "review_contact_allocation_capacity_pack",
              "source_review_type" => "contact_allocation_capacity_pack_review",
              "source_contact_allocation_capacity_pack" => %{
                "contention_group_id" => "station:deep_space_net:pack:import",
                "ground_station_id" => "deep_space_net",
                "capacity_fraction" => 0.4,
                "used_capacity_fraction" => 0.4,
                "unused_capacity_fraction" => 0.0,
                "selected_contact_ids" => ["dl_selected_import"],
                "deferred_contact_ids" => ["dl_pack_import"],
                "capacity_requirement_rows" => [
                  %{
                    "contact_id" => "dl_selected_import",
                    "required_capacity_fraction" => 0.2,
                    "required_capacity_fraction_source" => "default_reduced_capacity_policy",
                    "capacity_pack_status" => "selected_by_contention_resolution"
                  },
                  %{
                    "contact_id" => "dl_pack_import",
                    "required_capacity_fraction" => 0.2,
                    "required_capacity_fraction_source" => "default_reduced_capacity_policy",
                    "capacity_pack_status" => "deferred_by_reduced_station_capacity_pack"
                  }
                ],
                "pack_status" => "deferred_by_reduced_station_capacity_pack",
                "source_contention_recommendation" => %{
                  "group_id" => "station:deep_space_net:pack:import",
                  "selected_contact_id" => "dl_selected_import",
                  "deferred_contact_ids" => ["dl_pack_import"],
                  "source_contact_candidates" => [
                    downlink("dl_selected_import", 600.0, 660.0)
                    |> Map.put("ground_station_id", "deep_space_net")
                    |> Map.put("estimated_throughput_mb", 44.0),
                    downlink("dl_pack_import", 620.0, 680.0)
                    |> Map.put("ground_station_id", "deep_space_net")
                    |> Map.put("estimated_throughput_mb", 31.0)
                    |> Map.put(
                      "source_window_id",
                      "window:leo_1:ground_station_access:deep_space_net:pack_import"
                    )
                  ]
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
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    review_branch =
      branch(artifact, "derived_contact_contention_pressure_deferred_dl_pack_review")

    assert %{
             "type" => "downlink_completion_gap",
             "ground_station_id" => "equator_prime",
             "source_activity_id" => "dl_pack_review",
             "required_downlink_mb" => 37.0,
             "capacity_pack_group_id" => "station:equator_prime:pack:review",
             "capacity_pack_status" => "deferred_by_reduced_station_capacity_pack",
             "capacity_pack_capacity_fraction" => 0.5,
             "capacity_pack_used_fraction" => 0.5,
             "capacity_pack_unused_fraction" => review_unused_capacity_fraction,
             "required_capacity_fraction" => 0.25,
             "required_capacity_fraction_source" => "contact_required_capacity_fraction",
             "feedback_source" =>
               "prior_plan.operator_review_package.rows.source_contact_allocation_capacity_pack",
             "trust_boundary" => "ops_capacity_pack_review"
           } = List.first(review_branch["events"])

    assert review_unused_capacity_fraction == 0.0

    review_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(
        &(&1["branch_id"] == "derived_contact_contention_pressure_deferred_dl_pack_review")
      )

    assert review_row["capacity_pack_group_ids"] == ["station:equator_prime:pack:review"]
    assert review_row["capacity_pack_max_required_capacity_fraction"] == 0.25
    assert review_row["capacity_pack_total_required_capacity_fraction"] == 0.25

    assert review_row["capacity_pack_required_capacity_sources"] == [
             "contact_required_capacity_fraction"
           ]

    import_branch =
      branch(artifact, "derived_contact_contention_pressure_deferred_dl_pack_import")

    assert %{
             "type" => "downlink_completion_gap",
             "ground_station_id" => "deep_space_net",
             "source_activity_id" => "dl_pack_import",
             "required_downlink_mb" => 31.0,
             "capacity_pack_group_id" => "station:deep_space_net:pack:import",
             "capacity_pack_status" => "deferred_by_reduced_station_capacity_pack",
             "capacity_pack_capacity_fraction" => 0.4,
             "capacity_pack_used_fraction" => 0.4,
             "required_capacity_fraction" => 0.2,
             "required_capacity_fraction_source" => "default_reduced_capacity_policy",
             "feedback_source" =>
               "prior_plan.cadence_import_manifest.rows.source_contact_allocation_capacity_pack",
             "trust_boundary" => "cadence_capacity_pack_review"
           } = List.first(import_branch["events"])

    import_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(
        &(&1["branch_id"] == "derived_contact_contention_pressure_deferred_dl_pack_import")
      )

    assert import_row["capacity_pack_max_required_capacity_fraction"] == 0.2
    assert import_row["capacity_pack_total_required_capacity_fraction"] == 0.2

    assert import_row["capacity_pack_required_capacity_sources"] == [
             "default_reduced_capacity_policy"
           ]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch refresh from candidate diff replacement review rows" do
    prior_plan =
      base_plan(%{
        "activities" => [downlink("dl_existing", 100.0, 160.0)],
        "candidate_activities" => [
          downlink("dl_diff_replacement", 500.0, 560.0),
          observe("obs_diff_replacement", "leo_1", "target_a", 700.0, 760.0, 10.0)
        ],
        "operator_review_package" => %{
          "schema_contract" => "operator_review_package.v1",
          "source_artifact_type" => "candidate_diff_report.v1",
          "review_count" => 1,
          "provenance" => %{"trust_boundary" => "operator_refresh_queue"},
          "rows" => [
            %{
              "id" => "operator_review:candidate_diff:dl_old",
              "review_type" => "candidate_diff_review",
              "activity_id" => "dl_old",
              "activity_type" => "downlink",
              "scenario_id" => "leo_1",
              "ground_station_id" => "equator_prime",
              "required_operator_action" => "review_candidate_diff",
              "approval_status" => "operator_review_required",
              "source_candidate_diff" => %{
                "id" => "dl_old",
                "type" => "downlink",
                "scenario_id" => "leo_1",
                "ground_station_id" => "equator_prime",
                "collection_id" => "collection_alpha",
                "product_ids" => ["image_l0", "image_l1"],
                "payload_id" => "camera_a",
                "instrument_id" => "imager",
                "target_id" => "target_a",
                "source_activity_ids" => ["obs_semantic"],
                "objective_id" => "latency:collection_alpha",
                "objective_ids" => ["latency:collection_alpha", "objective:collection_delivery"],
                "objective_type" => "collection_latency",
                "latency_objective" => true,
                "max_latency_s" => 900.0,
                "planned_latency_s" => 540.0,
                "required_downlink_mb" => 300.0,
                "candidate_downlink_mb" => 360.0,
                "downlink_completion_ratio" => 1.0,
                "downlink_requirement_status" => "satisfied",
                "downlink_completion_source" =>
                  "candidate_refresh.downlink_demand.objectives_and_operational_feedback",
                "downlink_completion_sources" => [
                  "candidate_refresh.objectives.collection_latency",
                  "operational_feedback.downlink_demand_mb.station"
                ],
                "invalidated_reason" => "replaced_by_semantically_similar_candidate",
                "replacement_candidate_id" => "dl_diff_replacement",
                "source_window_id" => "window:leo_1:ground_station_access:equator_prime:old",
                "replacement_source_window_id" =>
                  "window:leo_1:ground_station_access:equator_prime:new"
              }
            }
          ]
        },
        "cadence_import_manifest" => %{
          "schema_contract" => "cadence_import_manifest.v1",
          "source_artifact_type" => "operator_review_package.v1",
          "row_count" => 1,
          "review_required_count" => 1,
          "provenance" => %{"trust_boundary" => "cadence_refresh_queue"},
          "rows" => [
            %{
              "id" => "cadence_import:candidate_diff:obs_old",
              "source_review_type" => "candidate_diff_review",
              "source_review_action" => "review_candidate_diff",
              "import_action" => "review_candidate_diff",
              "approval_status" => "operator_review_required",
              "required_operator_action" => "review_candidate_diff",
              "source_target_id" => "target_a",
              "source_target" => %{
                "id" => "target_a",
                "latitude_deg" => 12.5,
                "longitude_deg" => -45.25,
                "minimum_elevation_deg" => 17.5,
                "geometry_model" => "operator_inline_target_geometry"
              },
              "target_latitude_deg" => 12.5,
              "target_longitude_deg" => -45.25,
              "target_minimum_elevation_deg" => 17.5,
              "target_priority" => 6.5,
              "target_priority_source" => "candidate_refresh.objectives.observation_priority",
              "target_priority_objective_ids" => ["urgent:target_a"],
              "target_priority_objective_type" => "urgent_target",
              "semantic_change_details" => [
                %{
                  "field" => "target_priority",
                  "reason" => "target_priority_changed",
                  "prior_path" => "target_priority",
                  "refreshed_path" => "target_priority",
                  "prior_value" => 2.0,
                  "refreshed_value" => 6.5
                }
              ],
              "source_candidate_diff" => %{
                "id" => "obs_old",
                "type" => "observe",
                "scenario_id" => "leo_1",
                "target_id" => "target_a",
                "invalidated_reason" => "replaced_by_semantically_similar_candidate",
                "replacement_candidate_id" => "obs_diff_replacement",
                "source_window_id" => "window:leo_1:target_visibility:target_a:old",
                "replacement_source_window_id" => "window:leo_1:target_visibility:target_a:new"
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

    downlink_branch = branch(artifact, "derived_candidate_diff_replacement_dl_diff_replacement")

    assert %{
             "type" => "candidate_diff_replacement",
             "replacement_candidate_id" => "dl_diff_replacement",
             "invalidated_candidate_id" => "dl_old",
             "collection_id" => "collection_alpha",
             "product_ids" => ["image_l0", "image_l1"],
             "payload_id" => "camera_a",
             "instrument_id" => "imager",
             "target_id" => "target_a",
             "source_activity_ids" => ["obs_semantic"],
             "objective_id" => "latency:collection_alpha",
             "objective_ids" => ["latency:collection_alpha", "objective:collection_delivery"],
             "objective_type" => "collection_latency",
             "latency_objective" => true,
             "max_latency_s" => 900.0,
             "planned_latency_s" => 540.0,
             "required_downlink_mb" => 300.0,
             "candidate_downlink_mb" => 360.0,
             "downlink_completion_ratio" => 1.0,
             "downlink_requirement_status" => "satisfied",
             "downlink_completion_source" =>
               "candidate_refresh.downlink_demand.objectives_and_operational_feedback",
             "downlink_completion_sources" => [
               "candidate_refresh.objectives.collection_latency",
               "operational_feedback.downlink_demand_mb.station"
             ],
             "feedback_source" => "prior_plan.operator_review_package.rows.source_candidate_diff",
             "feedback_scope" => "candidate_diff",
             "trust_boundary" => "operator_refresh_queue"
           } = List.first(downlink_branch["events"])

    assert %{
             "id" => "dl_diff_replacement",
             "repair" => %{
               "action" => "strategic_addition",
               "reason" => "candidate_diff_replacement_inserted",
               "candidate_diff" => %{
                 "replacement_candidate_id" => "dl_diff_replacement",
                 "invalidated_reason" => "replaced_by_semantically_similar_candidate",
                 "collection_id" => "collection_alpha",
                 "product_ids" => ["image_l0", "image_l1"],
                 "source_activity_ids" => ["obs_semantic"],
                 "objective_id" => "latency:collection_alpha",
                 "objective_ids" => ["latency:collection_alpha", "objective:collection_delivery"],
                 "required_downlink_mb" => 300.0,
                 "candidate_downlink_mb" => 360.0,
                 "downlink_completion_ratio" => 1.0
               }
             },
             "feasibility" => %{
               "status" => "validated_candidate_diff_replacement",
               "replacement_candidate_id" => "dl_diff_replacement",
               "feedback_scope" => "candidate_diff",
               "objective_ids" => ["latency:collection_alpha", "objective:collection_delivery"]
             }
           } =
             Enum.find(
               downlink_branch["candidate_plan"]["strategic_additions"],
               &(&1["id"] == "dl_diff_replacement")
             )

    assert Enum.any?(
             downlink_branch["approval_requirements"],
             &(get_in(&1, ["activity_context", "objective_ids"]) == [
                 "latency:collection_alpha",
                 "objective:collection_delivery"
               ] and
                 get_in(&1, ["activity_context", "collection_id"]) == "collection_alpha" and
                 get_in(&1, ["activity_context", "product_ids"]) == ["image_l0", "image_l1"])
           )

    downlink_comparison_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "derived_candidate_diff_replacement_dl_diff_replacement"))

    assert downlink_comparison_row["branch_objective_ids"] == [
             "latency:collection_alpha",
             "objective:collection_delivery"
           ]

    observation_branch =
      branch(artifact, "derived_candidate_diff_replacement_obs_diff_replacement")

    assert %{
             "type" => "candidate_diff_replacement",
             "replacement_candidate_id" => "obs_diff_replacement",
             "invalidated_candidate_id" => "obs_old",
             "source_target_id" => "target_a",
             "source_target" => %{
               "id" => "target_a",
               "latitude_deg" => 12.5,
               "longitude_deg" => -45.25,
               "minimum_elevation_deg" => 17.5,
               "geometry_model" => "operator_inline_target_geometry"
             },
             "target_latitude_deg" => 12.5,
             "target_longitude_deg" => -45.25,
             "target_minimum_elevation_deg" => 17.5,
             "target_priority" => 6.5,
             "target_priority_source" => "candidate_refresh.objectives.observation_priority",
             "target_priority_objective_ids" => ["urgent:target_a"],
             "target_priority_objective_type" => "urgent_target",
             "changed_fields" => ["target_priority"],
             "candidate_diff_changed_fields" => ["target_priority"],
             "candidate_diff_changed_field_count" => 1,
             "semantic_change_details" => [
               %{
                 "field" => "target_priority",
                 "reason" => "target_priority_changed",
                 "prior_value" => 2.0,
                 "refreshed_value" => 6.5
               }
             ],
             "feedback_source" => "prior_plan.cadence_import_manifest.rows.source_candidate_diff",
             "feedback_scope" => "candidate_diff",
             "trust_boundary" => "cadence_refresh_queue"
           } = List.first(observation_branch["events"])

    assert %{
             "repair" => %{
               "candidate_diff" => %{
                 "source_target_id" => "target_a",
                 "target_latitude_deg" => 12.5,
                 "target_priority" => 6.5,
                 "target_priority_source" => "candidate_refresh.objectives.observation_priority",
                 "changed_fields" => ["target_priority"],
                 "candidate_diff_changed_fields" => ["target_priority"],
                 "candidate_diff_changed_field_count" => 1,
                 "semantic_change_details" => [
                   %{
                     "field" => "target_priority",
                     "reason" => "target_priority_changed",
                     "prior_value" => 2.0,
                     "refreshed_value" => 6.5
                   }
                 ]
               }
             },
             "feasibility" => %{
               "status" => "validated_candidate_diff_replacement",
               "source_target_id" => "target_a",
               "target_latitude_deg" => 12.5,
               "target_priority" => 6.5,
               "target_priority_source" => "candidate_refresh.objectives.observation_priority"
             }
           } =
             Enum.find(
               observation_branch["candidate_plan"]["strategic_additions"],
               &(&1["id"] == "obs_diff_replacement")
             )

    assert Enum.any?(
             observation_branch["approval_requirements"],
             &(get_in(&1, ["activity_context", "feedback_scope"]) == "candidate_diff" and
                 get_in(&1, ["activity_context", "source_target_id"]) == "target_a" and
                 get_in(&1, ["activity_context", "target_latitude_deg"]) == 12.5 and
                 get_in(&1, ["activity_context", "target_priority"]) == 6.5 and
                 get_in(&1, ["activity_context", "candidate_diff_changed_fields"]) == [
                   "target_priority"
                 ])
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch refresh from refresh budget review rows" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> put_in([:candidate_refresh_defaults, :candidate_limit_policy], %{
        max_candidate_activities: 1
      })

    prior_plan =
      base_plan(%{
        "operator_review_package" => %{
          "schema_contract" => "operator_review_package.v1",
          "source_artifact_type" => "refresh_budget_report.v1",
          "review_count" => 1,
          "provenance" => %{"trust_boundary" => "operator_refresh_budget_queue"},
          "rows" => [
            %{
              "id" => "operator_review:refresh_budget:limit",
              "review_type" => "refresh_budget_review",
              "required_operator_action" => "review_refresh_budget",
              "approval_status" => "operator_review_required",
              "source_refresh_budget_report" => %{
                "schema_contract" => "refresh_budget_report.v1",
                "model" => "deterministic_candidate_limit_after_filters",
                "input_candidate_count" => 2,
                "kept_candidate_count" => 1,
                "dropped_candidate_count" => 1,
                "max_candidate_activities" => 1,
                "selection_order" => "score_descending_then_start_then_id",
                "kept_candidate_ids" => ["dl_kept"],
                "dropped_candidate_ids" => ["obs_dropped"]
              }
            }
          ]
        },
        "cadence_import_manifest" => %{
          "schema_contract" => "cadence_import_manifest.v1",
          "source_artifact_type" => "operator_review_package.v1",
          "row_count" => 1,
          "review_required_count" => 1,
          "provenance" => %{"trust_boundary" => "cadence_refresh_budget_queue"},
          "rows" => [
            %{
              "id" => "cadence_import:refresh_budget:limit",
              "source_review_type" => "refresh_budget_review",
              "source_review_action" => "review_refresh_budget",
              "import_action" => "review_refresh_budget",
              "approval_status" => "operator_review_required",
              "required_operator_action" => "review_refresh_budget",
              "input_candidate_count" => 2,
              "kept_candidate_count" => 1,
              "dropped_candidate_count" => 1,
              "max_candidate_activities" => 1,
              "selection_order" => "score_descending_then_start_then_id",
              "kept_candidate_ids" => ["dl_kept"],
              "dropped_candidate_ids" => ["obs_dropped"]
            }
          ]
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    review_branch =
      branch(artifact, "derived_refresh_budget_pressure_operator_review:refresh_budget:limit")

    assert %{
             "type" => "refresh_budget_pressure",
             "input_candidate_count" => 2,
             "dropped_candidate_count" => 1,
             "current_max_candidate_activities" => 1,
             "relaxed_max_candidate_activities" => 2,
             "feedback_source" =>
               "prior_plan.operator_review_package.rows.source_refresh_budget_report",
             "feedback_scope" => "refresh_budget",
             "trust_boundary" => "operator_refresh_budget_queue"
           } = List.first(review_branch["events"])

    assert %{
             "type" => "candidate_refresh.v1",
             "scope" => "branch_generated"
           } = review_branch["assumptions"]["candidate_source"]

    assert %{
             "schema_contract" => "refresh_budget_report.v1",
             "max_candidate_activities" => 2,
             "dropped_candidate_count" => 0,
             "kept_candidate_count" => 2
           } = review_branch["repair_result"]["source_refresh_budget_report"]

    import_branch =
      branch(artifact, "derived_refresh_budget_pressure_cadence_import:refresh_budget:limit")

    assert %{
             "type" => "refresh_budget_pressure",
             "relaxed_max_candidate_activities" => 2,
             "feedback_source" => "prior_plan.cadence_import_manifest.rows.refresh_budget_review",
             "trust_boundary" => "cadence_refresh_budget_queue"
           } = List.first(import_branch["events"])

    assert %{
             "max_candidate_activities" => 2,
             "dropped_candidate_count" => 0,
             "kept_candidate_count" => 2
           } = import_branch["repair_result"]["source_refresh_budget_report"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch refresh from stale freshness review rows" do
    prior_plan =
      base_plan(%{
        "operator_review_package" => %{
          "schema_contract" => "operator_review_package.v1",
          "source_artifact_type" => "freshness_report.v1",
          "review_count" => 1,
          "provenance" => %{"trust_boundary" => "operator_freshness_queue"},
          "rows" => [
            %{
              "id" => "operator_review:freshness:stale",
              "review_type" => "freshness_review",
              "required_operator_action" => "review_refresh_freshness",
              "approval_status" => "operator_review_required",
              "source_freshness_report" => %{
                "schema_contract" => "freshness_report.v1",
                "model" => "accepted_state_freshness_policy",
                "status" => "stale",
                "accepted_snapshot_age_s" => 3600.0,
                "max_snapshot_age_s" => 60.0,
                "stale_reasons" => ["accepted_snapshot_older_than_policy"],
                "unknown_reasons" => []
              }
            }
          ]
        },
        "cadence_import_manifest" => %{
          "schema_contract" => "cadence_import_manifest.v1",
          "source_artifact_type" => "operator_review_package.v1",
          "row_count" => 1,
          "review_required_count" => 1,
          "provenance" => %{"trust_boundary" => "cadence_freshness_queue"},
          "rows" => [
            %{
              "id" => "cadence_import:freshness:unknown",
              "source_review_type" => "freshness_review",
              "source_review_action" => "review_refresh_freshness",
              "import_action" => "review_refresh_freshness",
              "approval_status" => "operator_review_required",
              "required_operator_action" => "review_refresh_freshness",
              "freshness_status" => "unknown",
              "unknown_reasons" => ["accepted_state_missing_quality"]
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

    stale_branch =
      branch(artifact, "derived_refresh_freshness_pressure_operator_review:freshness:stale")

    assert %{
             "type" => "refresh_freshness_pressure",
             "freshness_status" => "stale",
             "accepted_snapshot_age_s" => 3600.0,
             "feedback_source" =>
               "prior_plan.operator_review_package.rows.source_freshness_report",
             "feedback_scope" => "refresh_freshness",
             "trust_boundary" => "operator_freshness_queue"
           } = List.first(stale_branch["events"])

    assert %{
             "type" => "candidate_refresh.v1",
             "scope" => "branch_generated"
           } = stale_branch["assumptions"]["candidate_source"]

    assert stale_branch["repair_result"]["repair_metadata"]["candidate_window_count"] > 0

    unknown_branch =
      branch(artifact, "derived_refresh_freshness_pressure_cadence_import:freshness:unknown")

    assert %{
             "type" => "refresh_freshness_pressure",
             "freshness_status" => "unknown",
             "unknown_reasons" => ["accepted_state_missing_quality"],
             "feedback_source" => "prior_plan.cadence_import_manifest.rows.freshness_review",
             "trust_boundary" => "cadence_freshness_queue"
           } = List.first(unknown_branch["events"])

    assert %{
             "type" => "candidate_refresh.v1",
             "scope" => "branch_generated"
           } = unknown_branch["assumptions"]["candidate_source"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
