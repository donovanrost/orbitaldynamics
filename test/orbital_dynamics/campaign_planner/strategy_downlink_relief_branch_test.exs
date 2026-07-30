Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyDownlinkReliefBranchTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy downlink completion stages low downlink margin additions with resource-specific reason" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 1_000.0},
        "candidate_activities" => [
          refreshed_downlink("dl_margin_relief", 700.0, 760.0)
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([%{"type" => "downlink_completion", "required_contacts" => 1}],
            resources: %{"fuel_margin" => 1.0, "downlink_margin" => 0.4}
          ),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    downlink_branch = branch(artifact, "derived_downlink_constrained")

    assert %{
             "type" => "downlink_completion_gap",
             "derivation_reasons" => ["downlink_completion_gap", "downlink_margin_low"]
           } = Enum.find(downlink_branch["events"], &(&1["type"] == "downlink_completion_gap"))

    assert [
             %{
               "id" => "dl_margin_relief",
               "repair" => %{"reason" => "downlink_margin_candidate_inserted"},
               "feasibility" => %{
                 "derivation_reasons" => ["downlink_completion_gap", "downlink_margin_low"]
               }
             }
           ] = downlink_branch["candidate_plan"]["strategic_additions"]

    assert Enum.any?(
             downlink_branch["approval_requirements"],
             &(&1["reason"] == "downlink_margin_candidate_inserted")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy downlink-latency objective alias derives canonical collection latency branch" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 1_000.0},
        "activities" => [
          observe("obs_target_a", "leo_1", "target_a", 100.0, 160.0, 50.0)
        ],
        "candidate_activities" => [
          refreshed_downlink("dl_latency_relief", 220.0, 280.0)
          |> Map.put("score", 100.0),
          refreshed_downlink("dl_too_late", 400.0, 460.0)
          |> Map.put("score", 90.0)
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([
            %{
              "type" => "downlink_latency",
              "target_id" => "target_a",
              "max_latency_s" => 120.0
            }
          ]),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    latency_branch = branch(artifact, "derived_collection_latency_obs_target_a")

    assert %{
             "type" => "downlink_completion_gap",
             "objective_type" => "collection_latency",
             "latency_objective" => true,
             "target_id" => "target_a",
             "scenario_id" => "leo_1",
             "starts_at_s" => 160.0,
             "ends_at_s" => 280.0,
             "max_latency_s" => 120.0,
             "source_activity_id" => "obs_target_a",
             "derivation_reasons" => ["collection_latency_gap"]
           } = List.first(latency_branch["events"])

    assert [
             %{
               "id" => "dl_latency_relief",
               "repair" => %{"reason" => "collection_latency_downlink_candidate_inserted"},
               "feasibility" => %{
                 "status" => "validated_candidate_window",
                 "derivation_reasons" => ["collection_latency_gap"],
                 "required_contacts" => 1,
                 "planned_contacts" => 0
               }
             }
           ] = latency_branch["candidate_plan"]["strategic_additions"]

    assert Enum.any?(
             latency_branch["approval_requirements"],
             &(&1["reason"] == "collection_latency_downlink_candidate_inserted")
           )

    assert Enum.any?(
             get_in(artifact, ["recommendation", "explanation"]),
             &(&1["type"] == "strategic_addition" and
                 &1["reason"] == "collection_latency_downlink_candidate_inserted")
           )

    assert Enum.any?(
             get_in(artifact, ["operator_review_package", "rows"]),
             &(&1["review_type"] == "approval_requirement" and
                 &1["reason"] == "collection_latency_downlink_candidate_inserted")
           )

    refute Enum.any?(
             latency_branch["candidate_plan"]["strategic_additions"],
             &(&1["id"] == "dl_too_late")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy collection latency objective accepts station-id selector" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 1_000.0},
        "activities" => [
          observe("obs_target_a", "leo_1", "target_a", 100.0, 160.0, 50.0)
        ],
        "candidate_activities" => [
          refreshed_downlink("dl_wrong_station", 220.0, 280.0)
          |> Map.put("ground_station_id", "dss_14")
          |> Map.put("score", 100.0),
          refreshed_downlink("dl_latency_relief", 240.0, 300.0)
          |> Map.put("score", 10.0)
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([
            %{
              "type" => "collection_latency",
              "target_id" => "target_a",
              "station_id" => "equator_prime",
              "max_latency_s" => 180.0
            }
          ]),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    latency_branch = branch(artifact, "derived_collection_latency_obs_target_a")

    assert %{
             "type" => "downlink_completion_gap",
             "ground_station_id" => "equator_prime",
             "starts_at_s" => 160.0,
             "ends_at_s" => 340.0
           } = List.first(latency_branch["events"])

    assert [
             %{
               "id" => "dl_latency_relief",
               "ground_station_id" => "equator_prime",
               "repair" => %{"reason" => "collection_latency_downlink_candidate_inserted"}
             }
           ] = latency_branch["candidate_plan"]["strategic_additions"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy collection latency objective scopes source observations by data identity" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 1_000.0},
        "activities" => [
          observe("obs_collection_a", "leo_1", "target_a", 100.0, 160.0, 50.0)
          |> Map.put("collection_id", "collection_a")
          |> Map.put("product_id", "product_a")
          |> Map.put("payload_id", "payload_nadir"),
          observe("obs_collection_b", "leo_1", "target_a", 300.0, 360.0, 50.0)
          |> Map.put("collection_id", "collection_b")
          |> Map.put("product_id", "product_b")
          |> Map.put("payload_id", "payload_nadir"),
          downlink("dl_collection_b_on_time", 220.0, 240.0)
          |> Map.put("collection_id", "collection_b")
          |> Map.put("product_id", "product_b")
        ],
        "candidate_activities" => [
          refreshed_downlink("dl_latency_relief", 250.0, 280.0)
          |> Map.put("score", 100.0)
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([
            %{
              "id" => "latency_collection_a",
              "type" => "collection_latency",
              "target_id" => "target_a",
              "collection_id" => "collection_a",
              "product_id" => "product_a",
              "payload_id" => "payload_nadir",
              "max_latency_s" => 120.0
            }
          ]),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    latency_branch =
      branch(artifact, "derived_collection_latency_latency_collection_a_obs_collection_a")

    assert %{
             "objective_id" => "latency_collection_a",
             "source_activity_id" => "obs_collection_a",
             "collection_id" => "collection_a",
             "product_id" => "product_a",
             "payload_id" => "payload_nadir"
           } = List.first(latency_branch["events"])

    assert [
             %{
               "id" => "dl_latency_relief",
               "repair" => %{"reason" => "collection_latency_downlink_candidate_inserted"}
             }
           ] = latency_branch["candidate_plan"]["strategic_additions"]

    refute branch(artifact, "derived_collection_latency_latency_collection_a_obs_collection_b")

    assert [
             %{
               "source_activity_id" => "obs_collection_a",
               "collection_id" => "collection_a",
               "product_id" => "product_a",
               "status" => "satisfied"
             }
           ] = latency_branch["objective_satisfaction"]["collection_latency"]["rows"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy collection latency objectives preserve objective identity in derived branch ids" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 1_000.0},
        "activities" => [
          observe("obs_target_a", "leo_1", "target_a", 100.0, 160.0, 50.0)
        ],
        "candidate_activities" => [
          refreshed_downlink("dl_fast_equator", 220.0, 280.0)
          |> Map.put("score", 100.0),
          refreshed_downlink("dl_bulk_dss14", 240.0, 300.0)
          |> Map.put("ground_station_id", "dss_14")
          |> Map.put("score", 90.0)
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([
            %{
              "id" => "fast_equator",
              "type" => "collection_latency",
              "target_id" => "target_a",
              "station_id" => "equator_prime",
              "max_latency_s" => 120.0
            },
            %{
              "id" => "bulk_dss14",
              "type" => "collection_latency",
              "target_id" => "target_a",
              "station_id" => "dss_14",
              "max_latency_s" => 180.0
            }
          ]),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    branch_ids = Enum.map(artifact["branches"], & &1["branch_id"])

    assert "derived_collection_latency_fast_equator_obs_target_a" in branch_ids
    assert "derived_collection_latency_bulk_dss14_obs_target_a" in branch_ids
    assert branch_ids == Enum.uniq(branch_ids)

    fast_branch = branch(artifact, "derived_collection_latency_fast_equator_obs_target_a")
    bulk_branch = branch(artifact, "derived_collection_latency_bulk_dss14_obs_target_a")

    assert %{
             "objective_id" => "fast_equator",
             "ground_station_id" => "equator_prime"
           } = List.first(fast_branch["events"])

    assert %{
             "objective_id" => "bulk_dss14",
             "ground_station_id" => "dss_14"
           } = List.first(bulk_branch["events"])

    assert [
             %{
               "id" => "dl_fast_equator",
               "repair" => %{"reason" => "collection_latency_downlink_candidate_inserted"}
             }
           ] = fast_branch["candidate_plan"]["strategic_additions"]

    assert [
             %{
               "id" => "dl_bulk_dss14",
               "repair" => %{"reason" => "collection_latency_downlink_candidate_inserted"}
             }
           ] = bulk_branch["candidate_plan"]["strategic_additions"]

    assert [
             %{
               "objective_id" => "bulk_dss14",
               "source_activity_id" => "obs_target_a"
             },
             %{
               "objective_id" => "fast_equator",
               "source_activity_id" => "obs_target_a"
             }
           ] = fast_branch["objective_satisfaction"]["collection_latency"]["rows"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy collection latency objective can require downlink data volume" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 1_000.0},
        "activities" => [
          observe("obs_target_a", "leo_1", "target_a", 100.0, 160.0, 50.0),
          downlink("dl_on_time_small", 220.0, 280.0)
          |> Map.put("estimated_throughput_mb", 40.0)
        ],
        "candidate_activities" => [
          refreshed_downlink("dl_latency_small", 300.0, 330.0)
          |> Map.put("estimated_throughput_mb", 30.0)
          |> Map.put("score", 100.0),
          refreshed_downlink("dl_latency_large", 360.0, 420.0)
          |> Map.put("estimated_throughput_mb", 60.0)
          |> Map.put("score", 90.0),
          refreshed_downlink("dl_too_late", 500.0, 560.0)
          |> Map.put("estimated_throughput_mb", 100.0)
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([
            %{
              "type" => "collection_latency",
              "target_id" => "target_a",
              "max_latency_s" => 300.0,
              "required_downlink_mb" => 120.0
            }
          ]),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    latency_branch = branch(artifact, "derived_collection_latency_obs_target_a")

    assert %{
             "type" => "downlink_completion_gap",
             "objective_type" => "collection_latency",
             "latency_objective" => true,
             "required_downlink_mb" => 120.0,
             "planned_downlink_mb" => 40.0,
             "planned_contacts" => 1,
             "planned_latency_s" => 60.0
           } = List.first(latency_branch["events"])

    additions = latency_branch["candidate_plan"]["strategic_additions"]

    assert Enum.map(additions, & &1["id"]) == ["dl_latency_large", "dl_latency_small"]

    assert %{
             "feasibility" => %{
               "required_downlink_mb" => 120.0,
               "planned_downlink_mb" => 40.0,
               "staged_downlink_mb" => 90.0,
               "candidate_downlink_mb" => 30.0
             },
             "repair" => %{"reason" => "collection_latency_downlink_candidate_inserted"}
           } = Enum.find(additions, &(&1["id"] == "dl_latency_small"))

    assert %{
             "feasibility" => %{
               "required_downlink_mb" => 120.0,
               "planned_downlink_mb" => 40.0,
               "staged_downlink_mb" => 90.0,
               "candidate_downlink_mb" => 60.0
             }
           } = Enum.find(additions, &(&1["id"] == "dl_latency_large"))

    refute Enum.any?(additions, &(&1["id"] == "dl_too_late"))

    assert %{
             "objective_count" => 1,
             "observation_count" => 1,
             "satisfied_observation_count" => 1,
             "unsatisfied_observation_count" => 0,
             "ratio" => 1.0,
             "rows" => [
               %{
                 "source_activity_id" => "obs_target_a",
                 "target_id" => "target_a",
                 "scenario_id" => "leo_1",
                 "status" => "satisfied",
                 "max_latency_s" => 300.0,
                 "planned_latency_s" => 60.0,
                 "required_downlink_mb" => 120.0,
                 "planned_downlink_mb" => 130.0,
                 "planned_contacts" => 3
               }
             ]
           } = latency_branch["objective_satisfaction"]["collection_latency"]

    comparison_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "derived_collection_latency_obs_target_a"))

    assert %{
             "collection_latency_ratio" => 1.0,
             "collection_latency_objective_count" => 1,
             "collection_latency_observation_count" => 1,
             "collection_latency_satisfied_observation_count" => 1,
             "collection_latency_unsatisfied_observation_count" => 0
           } = comparison_row

    comparison_index =
      Enum.find_index(
        artifact["branch_comparison_report"]["rows"],
        &(&1["branch_id"] == "derived_collection_latency_obs_target_a")
      )

    for field <- [
          "collection_latency_ratio",
          "collection_latency_objective_count",
          "collection_latency_observation_count",
          "collection_latency_satisfied_observation_count",
          "collection_latency_unsatisfied_observation_count"
        ] do
      drift = if field == "collection_latency_ratio", do: 0.75, else: comparison_row[field] + 1

      invalid =
        put_in(
          artifact,
          ["branch_comparison_report", "rows", Access.at(comparison_index), field],
          drift
        )

      assert {:error, validation_report} = Schema.validate_artifact(invalid)

      assert Enum.any?(
               validation_report["errors"],
               &(&1["path"] ==
                   "$.branch_comparison_report.rows[#{comparison_index}].#{field}")
             )
    end

    assert get_in(artifact, [
             "pareto_frontier_report",
             "objective_directions",
             "collection_latency_ratio"
           ]) == "maximize"

    assert get_in(artifact, [
             "pareto_frontier_report",
             "objective_directions",
             "collection_latency_unsatisfied_observation_count"
           ]) == "minimize"

    assert Enum.any?(
             artifact["recommendation"]["explanation"],
             &(&1["type"] == "objective_satisfaction" and
                 &1["objective"] == "collection_latency" and
                 &1["ratio"] == 1.0 and
                 &1["collection_latency_ratio"] == 1.0 and
                 &1["collection_latency_objective_count"] == 1 and
                 &1["collection_latency_satisfied_observation_count"] == 1 and
                 &1["satisfied_observation_count"] == 1 and
                 &1["unsatisfied_observation_count"] == 0)
           )

    strategy_review_row =
      artifact["operator_review_package"]["rows"]
      |> Enum.find(&(&1["review_type"] == "strategy_recommendation"))

    assert Enum.any?(
             get_in(strategy_review_row, ["source_recommendation", "explanation"]),
             &(&1["type"] == "objective_satisfaction" and
                 &1["objective"] == "collection_latency" and
                 &1["ratio"] == 1.0 and
                 &1["collection_latency_ratio"] == 1.0 and
                 &1["collection_latency_objective_count"] == 1 and
                 &1["collection_latency_satisfied_observation_count"] == 1 and
                 &1["satisfied_observation_count"] == 1 and
                 &1["unsatisfied_observation_count"] == 0)
           )

    strategy_import_row =
      artifact["cadence_import_manifest"]["rows"]
      |> Enum.find(&(&1["import_action"] == "import_strategy_recommendation"))

    assert Enum.any?(
             get_in(strategy_import_row, ["source_recommendation", "explanation"]),
             &(&1["type"] == "objective_satisfaction" and
                 &1["objective"] == "collection_latency" and
                 &1["ratio"] == 1.0 and
                 &1["collection_latency_ratio"] == 1.0 and
                 &1["collection_latency_objective_count"] == 1 and
                 &1["collection_latency_satisfied_observation_count"] == 1 and
                 &1["satisfied_observation_count"] == 1 and
                 &1["unsatisfied_observation_count"] == 0)
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy normalizes numeric-string collection latency objective and activity fields" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 1_000.0},
        "activities" => [
          observe("obs_target_a", "leo_1", "target_a", 100.0, 160.0, 50.0),
          downlink("dl_on_time_small", 220.0, 280.0)
          |> Map.merge(%{
            "starts_at_s" => "220.0",
            "ends_at_s" => "280.0",
            "estimated_throughput_mb" => "40.0"
          })
        ],
        "candidate_activities" => [
          refreshed_downlink("dl_latency_fill", 300.0, 330.0)
          |> Map.merge(%{
            "starts_at_s" => "300.0",
            "ends_at_s" => "330.0",
            "estimated_throughput_mb" => "100.0"
          })
          |> Map.put("score", 100.0)
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([
            %{
              "type" => "collection_latency",
              "target_id" => "target_a",
              "max_latency_s" => "300.0",
              "required_downlink_mb" => "120.0"
            }
          ]),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    latency_branch = branch(artifact, "derived_collection_latency_obs_target_a")

    assert %{
             "type" => "downlink_completion_gap",
             "objective_type" => "collection_latency",
             "required_downlink_mb" => 120.0,
             "planned_downlink_mb" => 40.0,
             "max_latency_s" => 300.0,
             "planned_latency_s" => 60.0
           } = List.first(latency_branch["events"])

    assert [
             %{
               "id" => "dl_latency_fill",
               "feasibility" => %{
                 "required_downlink_mb" => 120.0,
                 "planned_downlink_mb" => 40.0,
                 "candidate_downlink_mb" => 100.0
               }
             }
           ] = latency_branch["candidate_plan"]["strategic_additions"]

    assert [
             %{
               "source_activity_id" => "obs_target_a",
               "status" => "satisfied",
               "max_latency_s" => 300.0,
               "required_downlink_mb" => 120.0,
               "planned_downlink_mb" => 140.0
             }
           ] = latency_branch["objective_satisfaction"]["collection_latency"]["rows"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy normalizes provider-style collection latency objective aliases" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 1_000.0},
        "activities" => [
          observe("obs_delivery_alias", "leo_1", "target_a", 100.0, 160.0, 50.0),
          downlink("dl_delivery_small", 220.0, 280.0)
          |> Map.put("estimated_throughput_mb", 40.0)
        ],
        "candidate_activities" => [
          refreshed_downlink("dl_delivery_fill", 300.0, 330.0)
          |> Map.put("estimated_throughput_mb", 100.0)
          |> Map.put("score", 100.0)
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([
            %{
              "objective" => "Max Delivery Latency",
              "id" => "provider_delivery_latency",
              "target_id" => "target_a",
              "max_delivery_latency_s" => "300.0",
              "target_data_volume_mb" => "120.0"
            }
          ]),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    latency_branch =
      branch(artifact, "derived_collection_latency_provider_delivery_latency_obs_delivery_alias")

    assert %{
             "type" => "downlink_completion_gap",
             "objective_id" => "provider_delivery_latency",
             "objective_type" => "collection_latency",
             "target_id" => "target_a",
             "required_downlink_mb" => 120.0,
             "planned_downlink_mb" => 40.0,
             "max_latency_s" => 300.0
           } = List.first(latency_branch["events"])

    assert [
             %{
               "id" => "dl_delivery_fill",
               "repair" => %{"reason" => "collection_latency_downlink_candidate_inserted"},
               "feasibility" => %{
                 "required_downlink_mb" => 120.0,
                 "planned_downlink_mb" => 40.0,
                 "candidate_downlink_mb" => 100.0
               }
             }
           ] = latency_branch["candidate_plan"]["strategic_additions"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy normalizes provider-style collection latency data-identity selectors" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 1_000.0},
        "activities" => [
          observe("obs_delivery_nested", "leo_1", "target_a", 100.0, 160.0, 50.0)
          |> Map.merge(%{
            "collection_id" => "collection_alpha",
            "product_id" => "product_beta",
            "payload_id" => "camera_a",
            "instrument_id" => "instrument_a"
          }),
          observe("obs_delivery_wrong_product", "leo_1", "target_a", 180.0, 240.0, 50.0)
          |> Map.merge(%{
            "collection_id" => "collection_alpha",
            "product_id" => "product_gamma",
            "payload_id" => "camera_a",
            "instrument_id" => "instrument_a"
          })
        ],
        "candidate_activities" => [
          refreshed_downlink("dl_delivery_nested_fill", 260.0, 300.0)
          |> Map.merge(%{
            "collection" => %{"id" => "collection_alpha"},
            "data_product" => %{"data_product_id" => "product_beta"},
            "payload" => %{"id" => "camera_a"},
            "instrument" => %{"id" => "instrument_a"},
            "estimated_throughput_mb" => 100.0
          })
          |> Map.put("score", 100.0),
          refreshed_downlink("dl_delivery_wrong_product", 250.0, 290.0)
          |> Map.put("product_id", "product_gamma")
          |> Map.put("score", 120.0)
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([
            %{
              "objective" => "Max Delivery Latency",
              "id" => "provider_nested_delivery",
              "target_id" => "target_a",
              "collection" => %{"id" => "collection_alpha"},
              "products" => [%{"id" => "product_alpha"}, %{"data_product_id" => "product_beta"}],
              "payload" => %{"id" => "camera_a"},
              "instrument" => %{"instrument_id" => "instrument_a"},
              "max_delivery_latency_s" => "300.0",
              "target_data_volume_mb" => "90.0"
            }
          ]),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    latency_branch =
      branch(artifact, "derived_collection_latency_provider_nested_delivery_obs_delivery_nested")

    assert %{
             "objective_id" => "provider_nested_delivery",
             "objective_type" => "collection_latency",
             "source_activity_id" => "obs_delivery_nested",
             "collection_id" => "collection_alpha",
             "product_id" => "product_beta",
             "product_ids" => ["product_alpha", "product_beta"],
             "payload_id" => "camera_a",
             "instrument_id" => "instrument_a"
           } = List.first(latency_branch["events"])

    assert [
             %{
               "id" => "dl_delivery_nested_fill",
               "collection_id" => "collection_alpha",
               "product_id" => "product_beta",
               "payload_id" => "camera_a",
               "instrument_id" => "instrument_a",
               "repair" => %{"reason" => "collection_latency_downlink_candidate_inserted"}
             }
           ] = latency_branch["candidate_plan"]["strategic_additions"]

    refute branch(
             artifact,
             "derived_collection_latency_provider_nested_delivery_obs_delivery_wrong_product"
           )

    refute Enum.any?(
             latency_branch["candidate_plan"]["strategic_additions"],
             &(&1["id"] == "dl_delivery_wrong_product")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy collection latency objective skips branch when latency data volume is met" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 1_000.0},
        "activities" => [
          observe("obs_target_a", "leo_1", "target_a", 100.0, 160.0, 50.0),
          downlink("dl_on_time_large", 220.0, 280.0)
          |> Map.put("estimated_throughput_mb", 130.0)
        ],
        "candidate_activities" => [
          refreshed_downlink("dl_unneeded", 300.0, 360.0)
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([
            %{
              "type" => "collection_latency",
              "target_id" => "target_a",
              "max_latency_s" => 300.0,
              "required_downlink_mb" => 120.0
            }
          ]),
        derive_branches?: true,
        branches: [%{id: "baseline"}, %{id: "manual_review", events: [%{type: "operator_note"}]}],
        current_epoch_s: 0.0
      )

    refute Enum.any?(
             artifact["branches"],
             &(&1["branch_id"] == "derived_collection_latency_obs_target_a")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy collection latency objective can stage branch-generated downlink relief" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 1_000.0, "output_step_s" => "60.0"},
        "activities" => [
          observe("obs_target_a", "leo_1", "target_a", -120.0, -60.0, 50.0)
        ],
        "candidate_activities" => []
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state_with_refresh_inputs()
          |> Map.put(:objectives, [
            %{
              type: "collection_latency",
              target_id: "target_a",
              max_latency_s: 600.0
            }
          ]),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    latency_branch = branch(artifact, "derived_collection_latency_obs_target_a")

    assert %{
             "type" => "candidate_refresh.v1",
             "snapshot_id" => "ops-rich",
             "scope" => "branch_generated"
           } = latency_branch["assumptions"]["candidate_source"]

    assert Enum.any?(
             latency_branch["repair_result"]["source_candidate_activities"],
             &(&1["type"] == "downlink" and &1["ground_station_id"] == "equator_prime")
           )

    assert [
             %{
               "type" => "downlink",
               "repair" => %{"reason" => "collection_latency_downlink_candidate_inserted"},
               "feasibility" => %{
                 "status" => "validated_candidate_window",
                 "derivation_reasons" => ["collection_latency_gap"]
               }
             }
           ] = latency_branch["candidate_plan"]["strategic_additions"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy collection latency objective derives one branch per missing observation downlink" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 1_000.0},
        "activities" => [
          observe("obs_target_a_1", "leo_1", "target_a", 100.0, 160.0, 50.0),
          observe("obs_target_a_2", "leo_1", "target_a", 300.0, 360.0, 50.0)
        ],
        "candidate_activities" => [
          refreshed_downlink("dl_latency_1", 220.0, 280.0)
          |> Map.put("score", 100.0),
          refreshed_downlink("dl_latency_2", 420.0, 480.0)
          |> Map.put("score", 90.0)
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([
            %{
              "type" => "collection_latency",
              "target_id" => "target_a",
              "max_latency_s" => 120.0
            }
          ]),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    branch_ids = Enum.map(artifact["branches"], & &1["branch_id"])

    assert "derived_collection_latency_obs_target_a_1" in branch_ids
    assert "derived_collection_latency_obs_target_a_2" in branch_ids

    first_branch = branch(artifact, "derived_collection_latency_obs_target_a_1")
    second_branch = branch(artifact, "derived_collection_latency_obs_target_a_2")

    assert %{
             "source_activity_id" => "obs_target_a_1",
             "starts_at_s" => 160.0,
             "ends_at_s" => 280.0
           } = List.first(first_branch["events"])

    assert %{
             "source_activity_id" => "obs_target_a_2",
             "starts_at_s" => 360.0,
             "ends_at_s" => 480.0
           } = List.first(second_branch["events"])

    assert [
             %{
               "id" => "dl_latency_1",
               "repair" => %{"reason" => "collection_latency_downlink_candidate_inserted"}
             }
           ] = first_branch["candidate_plan"]["strategic_additions"]

    assert [
             %{
               "id" => "dl_latency_2",
               "repair" => %{"reason" => "collection_latency_downlink_candidate_inserted"}
             }
           ] = second_branch["candidate_plan"]["strategic_additions"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "branch-generated refresh accumulates multiple downlink data-volume gaps" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 1_000.0},
        "activities" => [],
        "candidate_activities" => []
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [
          %{id: "baseline"},
          %{
            id: "operator_multi_gap",
            events: [
              %{
                type: "downlink_completion_gap",
                required_downlink_mb: 1_000.0,
                ground_station_id: "equator_prime",
                starts_at_s: 0.0,
                ends_at_s: 1_000.0
              },
              %{
                type: "downlink_completion_gap",
                required_downlink_mb: 1_000.0,
                ground_station_id: "equator_prime",
                starts_at_s: 0.0,
                ends_at_s: 1_000.0
              }
            ]
          }
        ],
        current_epoch_s: 0.0
      )

    multi_gap = branch(artifact, "operator_multi_gap")

    assert Enum.count(multi_gap["events"], &(&1["type"] == "downlink_completion_gap")) == 2

    generated_downlink =
      multi_gap["repair_result"]["source_candidate_activities"]
      |> Enum.find(&(&1["type"] == "downlink" and &1["ground_station_id"] == "equator_prime"))

    assert %{
             "required_downlink_mb" => 2_000.0,
             "downlink_completion_source" => "operational_feedback.downlink_demand_mb.station",
             "downlink_requirement_status" => "shortfall"
           } = generated_downlink

    assert get_in(generated_downlink, ["throughput_model", "required_downlink_mb"]) == 2_000.0
    assert get_in(generated_downlink, ["activity_context", "required_downlink_mb"]) == 2_000.0

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy collection latency objective skips branch when planned downlink meets latency" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 1_000.0},
        "activities" => [
          observe("obs_target_a", "leo_1", "target_a", 100.0, 160.0, 50.0),
          downlink("dl_on_time", 220.0, 280.0)
        ],
        "candidate_activities" => [
          refreshed_downlink("dl_unneeded", 300.0, 360.0)
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([
            %{
              "type" => "collection_latency",
              "target_id" => "target_a",
              "max_latency_s" => 120.0
            }
          ]),
        derive_branches?: true,
        branches: [%{id: "baseline"}, %{id: "manual_review", events: [%{type: "operator_note"}]}],
        current_epoch_s: 0.0
      )

    refute Enum.any?(
             artifact["branches"],
             &(&1["branch_id"] == "derived_collection_latency_obs_target_a")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy collection latency objective ignores missed realized downlinks" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 1_000.0},
        "activities" => [
          observe("obs_target_a", "leo_1", "target_a", 100.0, 160.0, 50.0),
          downlink("dl_on_time", 220.0, 280.0)
        ],
        "candidate_activities" => [
          refreshed_downlink("dl_latency_recovery", 240.0, 300.0)
          |> Map.put("score", 100.0)
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([
            %{
              "type" => "collection_latency",
              "target_id" => "target_a",
              "max_latency_s" => 160.0
            }
          ])
          |> Map.put(:realized_activities, [%{id: "dl_on_time", status: "missed"}]),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    latency_branch = branch(artifact, "derived_collection_latency_obs_target_a")

    assert %{
             "type" => "downlink_completion_gap",
             "objective_type" => "collection_latency",
             "missed_downlink_activity_id" => "dl_on_time",
             "missed_downlink_activity_ids" => ["dl_on_time"],
             "realized_status" => "missed",
             "derivation_reasons" => [
               "collection_latency_gap",
               "realized_downlink_missed"
             ]
           } = List.first(latency_branch["events"])

    assert Enum.any?(
             latency_branch["repair_result"]["deltas"],
             &(&1["activity_id"] == "dl_on_time" and
                 &1["replacement_activity_id"] == "dl_latency_recovery" and
                 &1["repair_action"] == "moved")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy collection latency objective skips missed realized observations" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 1_000.0},
        "activities" => [
          observe("obs_target_a", "leo_1", "target_a", 100.0, 160.0, 50.0)
        ],
        "candidate_activities" => [
          refreshed_downlink("dl_unneeded_without_collected_data", 220.0, 280.0)
          |> Map.put("score", 100.0),
          observe("obs_retry_target_a", "leo_1", "target_a", 240.0, 300.0, 80.0)
          |> Map.put("score", 120.0)
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([
            %{
              "type" => "collection_latency",
              "target_id" => "target_a",
              "max_latency_s" => 160.0
            }
          ])
          |> Map.put(:realized_activities, [%{id: "obs_target_a", status: "missed"}]),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    refute branch(artifact, "derived_collection_latency_obs_target_a")

    revisit = branch(artifact, "derived_target_revisit_target_a")

    assert %{
             "type" => "urgent_target",
             "source_activity_id" => "obs_target_a",
             "realized_status" => "missed",
             "derivation_reason" => "realized_observation_missed"
           } = List.first(revisit["events"])

    assert Enum.any?(
             revisit["candidate_plan"]["strategic_additions"],
             &(&1["type"] == "observe" and &1["target_id"] == "target_a" and
                 &1["starts_at_s"] == 240.0 and
                 get_in(&1, ["repair", "reason"]) == "target_revisit_candidate_inserted")
           )

    refute Enum.any?(
             revisit["candidate_plan"]["strategic_additions"],
             &(&1["id"] == "dl_unneeded_without_collected_data")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy collection latency objective skips completed observations with no collected data" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 1_000.0},
        "activities" => [
          observe("obs_target_a", "leo_1", "target_a", 100.0, 160.0, 50.0)
        ],
        "candidate_activities" => [
          refreshed_downlink("dl_unneeded_without_observation_data", 220.0, 280.0)
          |> Map.put("score", 100.0),
          observe("obs_retry_target_a", "leo_1", "target_a", 240.0, 300.0, 80.0)
          |> Map.put("score", 120.0)
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([
            %{
              "type" => "collection_latency",
              "target_id" => "target_a",
              "max_latency_s" => 160.0
            }
          ])
          |> Map.put(:realized_activities, [
            %{id: "obs_target_a", status: "completed", observation_success: " FALSE "}
          ]),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    refute branch(artifact, "derived_collection_latency_obs_target_a")

    observation_feedback = branch(artifact, "derived_observation_success_feedback")

    assert %{
             "type" => "observation_success_feedback",
             "target_id" => "target_a"
           } = observation_feedback_event = List.first(observation_feedback["events"])

    assert observation_feedback_event["observation_success_factor"] == 0.0

    refute Enum.any?(
             observation_feedback["candidate_plan"]["strategic_additions"],
             &(&1["id"] == "dl_unneeded_without_observation_data")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy collection latency objective treats provider contact result failure as missed downlink" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 1_000.0},
        "activities" => [
          observe("obs_target_a", "leo_1", "target_a", 100.0, 160.0, 50.0),
          downlink("dl_on_time", 220.0, 280.0)
        ],
        "candidate_activities" => [
          refreshed_downlink("dl_latency_recovery", 240.0, 300.0)
          |> Map.put("score", 100.0)
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([
            %{
              "type" => "collection_latency",
              "target_id" => "target_a",
              "max_latency_s" => 160.0
            }
          ])
          |> Map.put(:realized_activities, [
            %{id: "dl_on_time", status: "completed", contact_result: "dropped"}
          ]),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    latency_branch = branch(artifact, "derived_collection_latency_obs_target_a")

    assert %{
             "type" => "downlink_completion_gap",
             "objective_type" => "collection_latency",
             "missed_downlink_activity_id" => "dl_on_time",
             "realized_status" => "completed",
             "contact_result" => "dropped",
             "derivation_reasons" => [
               "collection_latency_gap",
               "realized_downlink_completed",
               "realized_downlink_contact_result_dropped"
             ]
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

  test "strategy collection latency objective honors successful provider contact result over failed status" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 1_000.0},
        "activities" => [
          observe("obs_target_a", "leo_1", "target_a", 100.0, 160.0, 50.0),
          downlink("dl_on_time", 220.0, 280.0)
        ],
        "candidate_activities" => [
          refreshed_downlink("dl_unneeded", 240.0, 300.0)
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([
            %{
              "type" => "collection_latency",
              "target_id" => "target_a",
              "max_latency_s" => 160.0
            }
          ])
          |> Map.put(:realized_activities, [
            %{id: "dl_on_time", status: "failed", contact_result: "delivered"}
          ]),
        derive_branches?: true,
        branches: [%{id: "baseline"}, %{id: "manual_review", events: [%{type: "operator_note"}]}],
        current_epoch_s: 0.0
      )

    refute branch(artifact, "derived_collection_latency_obs_target_a")

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy collection latency objective normalizes successful provider result aliases" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 1_000.0},
        "activities" => [
          observe("obs_target_a", "leo_1", "target_a", 100.0, 160.0, 50.0),
          downlink("dl_on_time", 220.0, 280.0)
        ],
        "candidate_activities" => [
          refreshed_downlink("dl_unneeded", 240.0, 300.0)
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([
            %{
              "type" => "collection_latency",
              "target_id" => "target_a",
              "max_latency_s" => 160.0
            }
          ])
          |> Map.put(:realized_activities, [
            %{id: "dl_on_time", status: "failed", contact_result: " DELIVERED "}
          ]),
        derive_branches?: true,
        branches: [%{id: "baseline"}, %{id: "manual_review", events: [%{type: "operator_note"}]}],
        current_epoch_s: 0.0
      )

    refute branch(artifact, "derived_collection_latency_obs_target_a")

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy collection latency feedback only includes downlinks in the observation latency window" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 1_000.0},
        "activities" => [
          observe("obs_target_a", "leo_1", "target_a", 100.0, 160.0, 50.0),
          downlink("dl_target_a_on_time", 220.0, 280.0),
          observe("obs_target_b", "leo_1", "target_b", 500.0, 560.0, 50.0)
        ],
        "candidate_activities" => [
          refreshed_downlink("dl_target_b_recovery", 600.0, 660.0)
          |> Map.put("score", 100.0)
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([
            %{
              "type" => "collection_latency",
              "target_id" => "target_b",
              "max_latency_s" => 120.0
            }
          ])
          |> Map.put(:realized_activities, [%{id: "dl_target_a_on_time", status: "missed"}]),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    latency_branch = branch(artifact, "derived_collection_latency_obs_target_b")
    event = List.first(latency_branch["events"])

    assert %{
             "type" => "downlink_completion_gap",
             "source_activity_id" => "obs_target_b",
             "derivation_reasons" => ["collection_latency_gap"]
           } = event

    refute Map.has_key?(event, "missed_downlink_activity_id")
    refute Map.has_key?(event, "realized_status")

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy warns when downlink completion has no validated candidate" do
    artifact =
      strategy(base_plan(%{}),
        mission_state:
          mission_state([%{"type" => "downlink_completion", "required_contacts" => 1}]),
        branches: [
          %{id: "baseline"},
          %{
            id: "downlink_gap",
            events: [%{type: "downlink_completion_gap", required_contacts: 1}]
          }
        ],
        current_epoch_s: 0.0
      )

    downlink_gap = branch(artifact, "downlink_gap")

    assert downlink_gap["candidate_plan"]["strategic_additions"] == []

    assert "downlink completion gap not staged: no_validated_candidate_window" in downlink_gap[
             "warnings"
           ]

    assert Enum.any?(downlink_gap["risk_indicators"], &(&1["type"] == "no_viable_downlink"))
  end

  test "strategy does not generate branch downlink candidates from duplicate station ids" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:ground_stations, [
        %{
          id: "equator_prime",
          latitude_deg: 0.0,
          longitude_deg: 0.0,
          minimum_elevation_deg: 5.0
        },
        %{
          id: "equator_prime",
          latitude_deg: 10.0,
          longitude_deg: 10.0,
          minimum_elevation_deg: 5.0
        }
      ])
      |> Map.put(:objectives, [
        %{
          type: "downlink_completion",
          required_contacts: 1,
          ground_station_id: "equator_prime"
        }
      ])

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    downlink_gap = branch(artifact, "derived_downlink_constrained")

    assert downlink_gap["candidate_plan"]["strategic_additions"] == []

    refute Enum.any?(
             downlink_gap["repair_result"]["source_candidate_activities"],
             &(&1["type"] == "downlink" and &1["ground_station_id"] == "equator_prime")
           )

    assert "downlink completion gap not staged: no_validated_candidate_window" in downlink_gap[
             "warnings"
           ]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy branch refresh keeps station definitions ahead of calendar geometry duplicates" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:ground_network, [
        %{
          ground_station_id: "equator_prime",
          latitude_deg: 80.0,
          longitude_deg: 0.0,
          minimum_elevation_deg: 5.0,
          status: "available"
        }
      ])
      |> Map.put(:objectives, [
        %{
          type: "downlink_completion",
          required_contacts: 1,
          ground_station_id: "equator_prime"
        }
      ])

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    downlink_gap = branch(artifact, "derived_downlink_constrained")

    assert [
             %{
               "type" => "downlink",
               "ground_station_id" => "equator_prime",
               "feasibility" => %{
                 "status" => "validated_candidate_window"
               }
             }
           ] = downlink_gap["candidate_plan"]["strategic_additions"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
