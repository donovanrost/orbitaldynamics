Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyDownlinkCompletionBranchTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy downlink completion objective stages matching station and window candidate" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          downlink("dl_other_station", 100.0, 160.0)
          |> Map.put("ground_station_id", "dss_14")
        ],
        "candidate_activities" => [
          downlink("dl_wrong_station", 520.0, 580.0)
          |> Map.put("ground_station_id", "dss_14")
          |> Map.put("score", 100.0),
          downlink("dl_equator_prime", 700.0, 760.0),
          downlink("dl_too_late", 1_000.0, 1_060.0)
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([
            %{
              "type" => "downlink_completion",
              "required_contacts" => 1,
              "ground_station_id" => "equator_prime",
              "starts_at_s" => 0.0,
              "ends_at_s" => 900.0
            }
          ]),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    downlink_branch = branch(artifact, "derived_downlink_constrained")

    assert [
             %{
               "id" => "dl_equator_prime",
               "ground_station_id" => "equator_prime",
               "starts_at_s" => 700.0,
               "feasibility" => %{
                 "status" => "validated_candidate_window",
                 "ground_station_id" => "equator_prime",
                 "required_contacts" => 1,
                 "planned_contacts" => 0
               }
             }
           ] = downlink_branch["candidate_plan"]["strategic_additions"]

    assert %{
             "type" => "downlink_completion_gap",
             "objective_type" => "downlink_completion",
             "ground_station_id" => "equator_prime",
             "ends_at_s" => 900.0
           } = List.first(downlink_branch["events"])

    assert List.first(downlink_branch["events"])["starts_at_s"] == 0.0

    baseline = branch(artifact, "baseline")

    assert baseline["score_terms"]["downlink_completion_score"] == 0.0
    assert downlink_branch["score_terms"]["downlink_completion_score"] > 0.0
  end

  test "strategy downlink completion objective accepts station-id selector" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "candidate_activities" => [
          downlink("dl_wrong_station", 700.0, 760.0)
          |> Map.put("ground_station_id", "dss_14")
          |> Map.put("score", 100.0),
          downlink("dl_equator_prime", 760.0, 820.0)
          |> Map.put("score", 10.0)
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([
            %{
              "type" => "downlink_completion",
              "required_contacts" => 1,
              "station_id" => "equator_prime",
              "starts_at_s" => 0.0,
              "ends_at_s" => 900.0
            }
          ]),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    downlink_branch = branch(artifact, "derived_downlink_constrained")

    assert [
             %{
               "id" => "dl_equator_prime",
               "ground_station_id" => "equator_prime",
               "feasibility" => %{"ground_station_id" => "equator_prime"}
             }
           ] = downlink_branch["candidate_plan"]["strategic_additions"]

    assert %{
             "type" => "downlink_completion_gap",
             "ground_station_id" => "equator_prime"
           } = List.first(downlink_branch["events"])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy downlink completion objective scopes planned downlinks by data identity" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          downlink("dl_collection_b_planned", 600.0, 660.0)
          |> Map.put("collection_id", "collection_b")
          |> Map.put("product_id", "product_b")
        ],
        "candidate_activities" => [
          downlink("dl_collection_b_candidate", 700.0, 760.0)
          |> Map.put("collection_id", "collection_b")
          |> Map.put("product_id", "product_b")
          |> Map.put("score", 100.0),
          downlink("dl_collection_a_candidate", 760.0, 820.0)
          |> Map.put("collection_id", "collection_a")
          |> Map.put("product_id", "product_a")
          |> Map.put("score", 10.0)
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([
            %{
              "id" => "collection_a_downlink",
              "type" => "downlink_completion",
              "required_contacts" => 1,
              "collection_id" => "collection_a",
              "product_id" => "product_a",
              "starts_at_s" => 0.0,
              "ends_at_s" => 900.0
            }
          ]),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    downlink_branch = branch(artifact, "derived_downlink_constrained")

    assert %{
             "objective_id" => "collection_a_downlink",
             "collection_id" => "collection_a",
             "product_id" => "product_a",
             "planned_contacts" => 0
           } = List.first(downlink_branch["events"])

    assert [
             %{
               "id" => "dl_collection_a_candidate",
               "collection_id" => "collection_a",
               "product_id" => "product_a",
               "repair" => %{"reason" => "downlink_completion_candidate_inserted"}
             }
           ] = downlink_branch["candidate_plan"]["strategic_additions"]

    refute Enum.any?(
             downlink_branch["candidate_plan"]["strategic_additions"],
             &(&1["id"] == "dl_collection_b_candidate")
           )

    baseline = branch(artifact, "baseline")

    assert get_in(baseline, [
             "objective_satisfaction",
             "downlink_completion",
             "planned_contacts"
           ]) == 0

    assert get_in(baseline, ["objective_satisfaction", "downlink_completion", "ratio"]) == 0.0

    assert get_in(downlink_branch, [
             "objective_satisfaction",
             "downlink_completion",
             "planned_contacts"
           ]) == 1

    assert get_in(downlink_branch, ["objective_satisfaction", "downlink_completion", "ratio"]) ==
             1.0

    comparison_rows = artifact["branch_comparison_report"]["rows"]
    baseline_row = Enum.find(comparison_rows, &(&1["branch_id"] == "baseline"))

    downlink_row =
      Enum.find(comparison_rows, &(&1["branch_id"] == "derived_downlink_constrained"))

    assert baseline_row["downlink_completion_planned_contacts"] == 0
    assert baseline_row["downlink_completion_ratio"] == 0.0
    assert downlink_row["downlink_completion_planned_contacts"] == 1
    assert downlink_row["downlink_completion_ratio"] == 1.0

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy downlink completion preserves broad provider product selectors as plural evidence" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "candidate_activities" => [
          downlink("dl_product_beta", 700.0, 760.0)
          |> Map.put("data_product", %{"data_product_id" => "product_beta"})
          |> Map.put("score", 100.0),
          downlink("dl_product_gamma", 720.0, 780.0)
          |> Map.put("product_id", "product_gamma")
          |> Map.put("score", 120.0)
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([
            %{
              "id" => "provider_product_set_downlink",
              "type" => "downlink_completion",
              "required_contacts" => 1,
              "products" => [%{"id" => "product_alpha"}, %{"data_product_id" => "product_beta"}],
              "starts_at_s" => 0.0,
              "ends_at_s" => 900.0
            }
          ]),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    downlink_branch = branch(artifact, "derived_downlink_constrained")
    event = List.first(downlink_branch["events"])

    assert %{
             "objective_id" => "provider_product_set_downlink",
             "product_ids" => ["product_alpha", "product_beta"],
             "planned_contacts" => 0
           } = event

    refute Map.has_key?(event, "product_id")

    assert [
             %{
               "id" => "dl_product_beta",
               "product_id" => "product_beta",
               "repair" => %{"reason" => "downlink_completion_candidate_inserted"}
             }
           ] = downlink_branch["candidate_plan"]["strategic_additions"]

    refute Enum.any?(
             downlink_branch["candidate_plan"]["strategic_additions"],
             &(&1["id"] == "dl_product_gamma")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy downlink completion preserves broad collection resource selectors as plural evidence" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "candidate_activities" => [
          downlink("dl_collection_payload_match", 700.0, 760.0)
          |> Map.merge(%{
            "collection" => %{"id" => "collection_alpha"},
            "payload" => %{"id" => "payload_a"},
            "instrument" => %{"id" => "instrument_a"},
            "score" => 100.0
          }),
          downlink("dl_wrong_collection", 710.0, 770.0)
          |> Map.merge(%{
            "collection_id" => "collection_gamma",
            "payload_id" => "payload_a",
            "instrument_id" => "instrument_a",
            "score" => 150.0
          }),
          downlink("dl_wrong_payload", 720.0, 780.0)
          |> Map.merge(%{
            "collection_id" => "collection_alpha",
            "payload_id" => "payload_c",
            "instrument_id" => "instrument_a",
            "score" => 140.0
          })
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([
            %{
              "id" => "provider_collection_payload_set_downlink",
              "type" => "downlink_completion",
              "required_contacts" => 1,
              "collections" => [
                %{"id" => "collection_alpha"},
                %{"collection_id" => "collection_beta"}
              ],
              "payloads" => [%{"id" => "payload_a"}, %{"payload_id" => "payload_b"}],
              "instruments" => [%{"id" => "instrument_a"}, %{"instrument_id" => "instrument_b"}],
              "starts_at_s" => 0.0,
              "ends_at_s" => 900.0
            }
          ]),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    downlink_branch = branch(artifact, "derived_downlink_constrained")
    event = List.first(downlink_branch["events"])

    assert %{
             "objective_id" => "provider_collection_payload_set_downlink",
             "collection_ids" => ["collection_alpha", "collection_beta"],
             "payload_ids" => ["payload_a", "payload_b"],
             "instrument_ids" => ["instrument_a", "instrument_b"],
             "planned_contacts" => 0
           } = event

    refute Map.has_key?(event, "collection_id")
    refute Map.has_key?(event, "payload_id")
    refute Map.has_key?(event, "instrument_id")

    assert [
             %{
               "id" => "dl_collection_payload_match",
               "collection_id" => "collection_alpha",
               "payload_id" => "payload_a",
               "instrument_id" => "instrument_a",
               "feasibility" => %{
                 "objective_id" => "provider_collection_payload_set_downlink",
                 "objective_type" => "downlink_completion",
                 "collection_ids" => ["collection_alpha", "collection_beta"],
                 "payload_ids" => ["payload_a", "payload_b"],
                 "instrument_ids" => ["instrument_a", "instrument_b"]
               },
               "repair" => %{"reason" => "downlink_completion_candidate_inserted"}
             }
           ] = downlink_branch["candidate_plan"]["strategic_additions"]

    assert Enum.any?(
             downlink_branch["approval_requirements"],
             &(get_in(&1, ["activity_context", "objective_id"]) ==
                 "provider_collection_payload_set_downlink" and
                 get_in(&1, ["activity_context", "objective_type"]) ==
                   "downlink_completion" and
                 get_in(&1, ["activity_context", "collection_ids"]) == [
                   "collection_alpha",
                   "collection_beta"
                 ] and
                 get_in(&1, ["activity_context", "payload_ids"]) == [
                   "payload_a",
                   "payload_b"
                 ] and
                 get_in(&1, ["activity_context", "instrument_ids"]) == [
                   "instrument_a",
                   "instrument_b"
                 ])
           )

    assert Enum.any?(
             artifact["recommendation"]["explanation"],
             &(&1["type"] == "strategic_addition" and
                 &1["activity_id"] == "dl_collection_payload_match" and
                 &1["objective_id"] == "provider_collection_payload_set_downlink" and
                 &1["collection_ids"] == ["collection_alpha", "collection_beta"] and
                 &1["payload_ids"] == ["payload_a", "payload_b"] and
                 &1["instrument_ids"] == ["instrument_a", "instrument_b"])
           )

    refute Enum.any?(
             downlink_branch["candidate_plan"]["strategic_additions"],
             &(&1["id"] in ["dl_wrong_collection", "dl_wrong_payload"])
           )

    comparison_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "derived_downlink_constrained"))

    assert comparison_row["branch_collection_ids"] == ["collection_alpha", "collection_beta"]
    assert comparison_row["branch_payload_ids"] == ["payload_a", "payload_b"]
    assert comparison_row["branch_instrument_ids"] == ["instrument_a", "instrument_b"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy downlink completion ratio requires both contact count and data volume when declared" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          downlink("dl_high_volume", 120.0, 180.0)
          |> Map.put("estimated_throughput_mb", 100.0)
        ],
        "candidate_activities" => []
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([
            %{
              "type" => "downlink_completion",
              "required_contacts" => 2,
              "required_downlink_mb" => 50.0,
              "starts_at_s" => 0.0,
              "ends_at_s" => 300.0
            }
          ]),
        derive_branches?: false,
        branches: [%{id: "baseline"}, %{id: "same_plan", events: []}],
        current_epoch_s: 0.0
      )

    baseline = branch(artifact, "baseline")

    assert get_in(baseline, [
             "objective_satisfaction",
             "downlink_completion",
             "planned_contacts"
           ]) == 1

    assert get_in(baseline, [
             "objective_satisfaction",
             "downlink_completion",
             "planned_downlink_mb"
           ]) == 100.0

    assert get_in(baseline, ["objective_satisfaction", "downlink_completion", "ratio"]) == 0.5
    assert baseline["score_terms"]["downlink_completion_score"] == 25.0

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy downlink completion risk explains both contact and data-volume gaps" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          downlink("dl_low_volume", 120.0, 180.0)
          |> Map.put("estimated_throughput_mb", 40.0)
        ],
        "candidate_activities" => []
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([
            %{
              "type" => "downlink_completion",
              "required_contacts" => 2,
              "required_downlink_mb" => 120.0,
              "starts_at_s" => 0.0,
              "ends_at_s" => 300.0
            }
          ]),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    downlink_branch = branch(artifact, "derived_downlink_constrained")

    assert %{
             "type" => "downlink_completion_gap",
             "required_contacts" => 2,
             "planned_contacts" => 1,
             "required_downlink_mb" => 120.0,
             "planned_downlink_mb" => 40.0
           } = List.first(downlink_branch["events"])

    assert Enum.any?(
             downlink_branch["risk_indicators"],
             &(&1["type"] == "downlink_completion_gap" and
                 &1["reason"] ==
                   "planned downlinks 1 below required 2; planned downlink volume 40.0 MB below required 120.0 MB")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy normalizes numeric-string downlink completion objective fields" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => "2000.0"},
        "activities" => [
          downlink("dl_low_volume", 120.0, 180.0)
          |> Map.merge(%{
            "starts_at_s" => "120.0",
            "ends_at_s" => "180.0",
            "estimated_throughput_mb" => "40.0"
          })
        ],
        "candidate_activities" => [
          downlink("dl_volume_fill", 220.0, 280.0)
          |> Map.merge(%{
            "starts_at_s" => "220.0",
            "ends_at_s" => "280.0",
            "estimated_throughput_mb" => "100.0",
            "score" => "100.0"
          }),
          downlink("dl_lower_score", 200.0, 260.0)
          |> Map.put("score", 10.0)
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([
            %{
              "type" => "downlink_completion",
              "required_contacts" => "2",
              "required_downlink_mb" => "120.0",
              "starts_at_s" => "0.0"
            }
          ]),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    downlink_branch = branch(artifact, "derived_downlink_constrained")

    event = List.first(downlink_branch["events"])

    assert %{
             "type" => "downlink_completion_gap",
             "required_contacts" => 2,
             "planned_contacts" => 1,
             "required_downlink_mb" => 120.0,
             "planned_downlink_mb" => 40.0,
             "ends_at_s" => 2000.0
           } = event

    assert event["starts_at_s"] == 0.0

    assert [
             %{
               "id" => "dl_volume_fill",
               "feasibility" => %{
                 "required_contacts" => 2,
                 "required_downlink_mb" => 120.0,
                 "planned_downlink_mb" => 40.0
               }
             }
           ] = downlink_branch["candidate_plan"]["strategic_additions"]

    assert get_in(branch(artifact, "baseline"), [
             "objective_satisfaction",
             "downlink_completion",
             "required_downlink_mb"
           ]) == 120.0

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy normalizes provider-style downlink contact-count objective aliases" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "candidate_activities" => [
          downlink("dl_provider_alias_1", 220.0, 280.0)
          |> Map.put("score", 100.0),
          downlink("dl_provider_alias_2", 320.0, 380.0)
          |> Map.put("score", 90.0)
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([
            %{
              "objective" => "Downlink Completion",
              "id" => "provider_downlink_contact_count",
              "required_contact_count" => "2",
              "starts_at_s" => "0.0",
              "ends_at_s" => "500.0"
            }
          ]),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    downlink_branch = branch(artifact, "derived_downlink_constrained")

    assert %{
             "type" => "downlink_completion_gap",
             "objective_id" => "provider_downlink_contact_count",
             "objective_type" => "downlink_completion",
             "required_contacts" => 2,
             "planned_contacts" => 0
           } = List.first(downlink_branch["events"])

    assert [
             %{"id" => "dl_provider_alias_1"},
             %{"id" => "dl_provider_alias_2"}
           ] = downlink_branch["candidate_plan"]["strategic_additions"]

    assert Enum.all?(
             downlink_branch["candidate_plan"]["strategic_additions"],
             &(get_in(&1, ["repair", "reason"]) == "downlink_completion_candidate_inserted" and
                 get_in(&1, ["feasibility", "required_contacts"]) == 2)
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives independent branches for multiple scoped downlink objectives" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          downlink("dl_equator_satisfied", 120.0, 180.0)
        ],
        "candidate_activities" => [
          downlink("dl_dss14_candidate", 640.0, 700.0)
          |> Map.put("ground_station_id", "dss_14")
          |> Map.put("score", 100.0)
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([
            %{
              "id" => "equator_done",
              "type" => "downlink_completion",
              "required_contacts" => 1,
              "ground_station_id" => "equator_prime",
              "starts_at_s" => 0.0,
              "ends_at_s" => 300.0
            },
            %{
              "id" => "dss14_bulk",
              "type" => "downlink_completion",
              "required_contacts" => 1,
              "ground_station_id" => "dss_14",
              "starts_at_s" => 500.0,
              "ends_at_s" => 900.0
            }
          ]),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    refute branch(artifact, "derived_downlink_constrained_equator_done")

    dss14_branch = branch(artifact, "derived_downlink_constrained_dss14_bulk")

    assert [
             %{
               "id" => "dl_dss14_candidate",
               "ground_station_id" => "dss_14",
               "feasibility" => %{"ground_station_id" => "dss_14"}
             }
           ] = dss14_branch["candidate_plan"]["strategic_additions"]

    assert %{
             "type" => "downlink_completion_gap",
             "objective_id" => "dss14_bulk",
             "ground_station_id" => "dss_14",
             "planned_contacts" => 0
           } = List.first(dss14_branch["events"])

    baseline = branch(artifact, "baseline")

    assert get_in(baseline, [
             "objective_satisfaction",
             "downlink_completion",
             "required_contacts"
           ]) == 2

    assert get_in(baseline, [
             "objective_satisfaction",
             "downlink_completion",
             "planned_contacts"
           ]) == 1

    assert get_in(baseline, ["objective_satisfaction", "downlink_completion", "ratio"]) == 0.5

    assert get_in(dss14_branch, [
             "objective_satisfaction",
             "downlink_completion",
             "required_contacts"
           ]) == 2

    assert get_in(dss14_branch, [
             "objective_satisfaction",
             "downlink_completion",
             "planned_contacts"
           ]) == 2

    assert get_in(dss14_branch, ["objective_satisfaction", "downlink_completion", "ratio"]) ==
             1.0

    comparison_rows = artifact["branch_comparison_report"]["rows"]
    baseline_row = Enum.find(comparison_rows, &(&1["branch_id"] == "baseline"))

    dss14_row =
      Enum.find(comparison_rows, &(&1["branch_id"] == "derived_downlink_constrained_dss14_bulk"))

    assert baseline_row["downlink_completion_required_contacts"] == 2
    assert baseline_row["downlink_completion_planned_contacts"] == 1
    assert baseline_row["downlink_completion_ratio"] == 0.5
    assert dss14_row["downlink_completion_required_contacts"] == 2
    assert dss14_row["downlink_completion_planned_contacts"] == 2
    assert dss14_row["downlink_completion_ratio"] == 1.0

    assert baseline["score_terms"]["downlink_completion_score"] == 25.0
    assert dss14_branch["score_terms"]["downlink_completion_score"] == 50.0

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy keeps scoped downlink branches when objective ids repeat" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "candidate_activities" => [
          downlink("dl_equator_candidate", 240.0, 300.0)
          |> Map.put("ground_station_id", "equator_prime")
          |> Map.put("score", 80.0),
          downlink("dl_dss14_candidate", 640.0, 700.0)
          |> Map.put("ground_station_id", "dss_14")
          |> Map.put("score", 100.0)
        ]
      })

    mission_state =
      mission_state([
        %{
          "id" => "provider_bulk",
          "type" => "downlink_completion",
          "required_contacts" => 1,
          "ground_station_id" => "equator_prime",
          "starts_at_s" => 0.0,
          "ends_at_s" => 400.0
        },
        %{
          "id" => "provider_bulk",
          "type" => "downlink_completion",
          "required_contacts" => 1,
          "ground_station_id" => "dss_14",
          "starts_at_s" => 500.0,
          "ends_at_s" => 900.0
        }
      ])

    artifact =
      strategy(prior_plan,
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    base_id = "derived_downlink_constrained_provider_bulk"
    refute branch(artifact, base_id)

    downlink_branches =
      Enum.filter(artifact["branches"], &String.starts_with?(&1["branch_id"], "#{base_id}_"))

    assert length(downlink_branches) == 2

    assert downlink_branches
           |> Enum.map(&List.first(&1["events"])["ground_station_id"])
           |> MapSet.new() == MapSet.new(["equator_prime", "dss_14"])

    assert Enum.any?(
             downlink_branches,
             &(Enum.any?(&1["candidate_plan"]["strategic_additions"], fn addition ->
                 addition["id"] == "dl_equator_candidate"
               end) and
                 String.contains?(&1["branch_id"], "equator_prime"))
           )

    assert Enum.any?(
             downlink_branches,
             &(Enum.any?(&1["candidate_plan"]["strategic_additions"], fn addition ->
                 addition["id"] == "dl_dss14_candidate"
               end) and String.contains?(&1["branch_id"], "dss_14"))
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy downlink completion stages planned-contact downlink candidates" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [],
        "candidate_activities" => [
          downlink("planned_command", 640.0, 700.0)
          |> Map.put("type", "planned_contact")
          |> Map.put("direction", "command")
          |> Map.put("score", 100.0),
          downlink("planned_downlink", 700.0, 760.0)
          |> Map.put("type", "planned_contact")
          |> Map.put("direction", "downlink")
          |> Map.put("score", 10.0)
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([
            %{
              "type" => "downlink_completion",
              "required_contacts" => 1,
              "ground_station_id" => "equator_prime",
              "starts_at_s" => 500.0,
              "ends_at_s" => 900.0
            }
          ]),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    downlink_branch = branch(artifact, "derived_downlink_constrained")

    assert [
             %{
               "id" => "planned_downlink",
               "type" => "planned_contact",
               "direction" => "downlink",
               "feasibility" => %{
                 "status" => "validated_candidate_window",
                 "ground_station_id" => "equator_prime",
                 "planned_contacts" => 0
               }
             }
           ] = downlink_branch["candidate_plan"]["strategic_additions"]

    refute Enum.any?(
             downlink_branch["candidate_plan"]["strategic_additions"],
             &(&1["id"] == "planned_command")
           )

    assert get_in(downlink_branch, [
             "objective_satisfaction",
             "downlink_completion",
             "ratio"
           ]) == 1.0
  end

  test "strategy downlink completion stages provider-shaped station contacts without type" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [],
        "candidate_activities" => [
          %{
            "id" => "provider_downlink",
            "scenario_id" => "leo_1",
            "station_id" => "equator_prime",
            "start_s" => 700.0,
            "end_s" => 760.0,
            "estimated_throughput_mb" => 60.0,
            "score" => 10.0
          },
          downlink("explicit_downlink_too_late", 1_200.0, 1_260.0)
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([
            %{
              "type" => "downlink_completion",
              "required_contacts" => 1,
              "station_id" => "equator_prime",
              "starts_at_s" => 500.0,
              "ends_at_s" => 900.0
            }
          ]),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    downlink_branch = branch(artifact, "derived_downlink_constrained")

    assert [
             %{
               "id" => "provider_downlink",
               "type" => "downlink",
               "direction" => "downlink",
               "ground_station_id" => "equator_prime",
               "starts_at_s" => 700.0,
               "ends_at_s" => 760.0,
               "feasibility" => %{
                 "status" => "validated_candidate_window",
                 "ground_station_id" => "equator_prime",
                 "planned_contacts" => 0
               }
             }
           ] = downlink_branch["candidate_plan"]["strategic_additions"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy downlink completion stages provider-shaped nested station contacts" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [],
        "candidate_activities" => [
          %{
            "id" => "provider_nested_downlink",
            "scenario_id" => "leo_1",
            "ground_station" => %{"ground_station_id" => "equator_prime"},
            "start_s" => 700.0,
            "end_s" => 760.0,
            "estimated_throughput_mb" => 60.0,
            "score" => 10.0
          },
          %{
            "id" => "provider_nested_other_station",
            "scenario_id" => "leo_1",
            "station" => %{"id" => "polar_prime"},
            "start_s" => 710.0,
            "end_s" => 770.0,
            "estimated_throughput_mb" => 80.0,
            "score" => 100.0
          }
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([
            %{
              "type" => "downlink_completion",
              "required_contacts" => 1,
              "station" => %{"id" => "equator_prime"},
              "starts_at_s" => 500.0,
              "ends_at_s" => 900.0
            }
          ]),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    downlink_branch = branch(artifact, "derived_downlink_constrained")

    assert [
             %{
               "id" => "provider_nested_downlink",
               "type" => "downlink",
               "direction" => "downlink",
               "ground_station_id" => "equator_prime",
               "starts_at_s" => 700.0,
               "ends_at_s" => 760.0,
               "feasibility" => %{
                 "status" => "validated_candidate_window",
                 "ground_station_id" => "equator_prime"
               }
             }
           ] = downlink_branch["candidate_plan"]["strategic_additions"]

    refute Enum.any?(
             downlink_branch["candidate_plan"]["strategic_additions"],
             &(&1["id"] == "provider_nested_other_station")
           )

    assert get_in(downlink_branch, [
             "objective_satisfaction",
             "downlink_completion",
             "ratio"
           ]) == 1.0

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy downlink completion stages activity-type-only provider contacts" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [],
        "candidate_activities" => [
          %{
            "id" => "alias_downlink",
            "activity_type" => "downlink",
            "scenario_id" => "leo_1",
            "station_id" => "equator_prime",
            "start_s" => 700.0,
            "end_s" => 760.0,
            "estimated_throughput_mb" => 60.0,
            "score" => 10.0
          },
          %{
            "id" => "alias_command",
            "activity_type" => "command",
            "scenario_id" => "leo_1",
            "station_id" => "equator_prime",
            "start_s" => 710.0,
            "end_s" => 740.0,
            "score" => 100.0
          }
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([
            %{
              "type" => "downlink_completion",
              "required_contacts" => 1,
              "station_id" => "equator_prime",
              "starts_at_s" => 500.0,
              "ends_at_s" => 900.0
            }
          ]),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    downlink_branch = branch(artifact, "derived_downlink_constrained")

    assert [
             %{
               "id" => "alias_downlink",
               "type" => "downlink",
               "activity_type" => "downlink",
               "ground_station_id" => "equator_prime",
               "starts_at_s" => 700.0,
               "ends_at_s" => 760.0
             }
           ] = downlink_branch["candidate_plan"]["strategic_additions"]

    refute Enum.any?(
             downlink_branch["candidate_plan"]["strategic_additions"],
             &(&1["id"] == "alias_command")
           )

    assert get_in(downlink_branch, [
             "objective_satisfaction",
             "downlink_completion",
             "ratio"
           ]) == 1.0

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy downlink objectives count provider-shaped selected station contacts without type" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          %{
            "id" => "provider_selected_downlink",
            "scenario_id" => "leo_1",
            "station_id" => "equator_prime",
            "start_s" => 700.0,
            "end_s" => 760.0,
            "estimated_throughput_mb" => 60.0
          }
        ],
        "candidate_activities" => [downlink("unused_candidate", 800.0, 860.0)]
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([
            %{
              "type" => "downlink_completion",
              "required_contacts" => 1,
              "required_downlink_mb" => 50.0,
              "station_id" => "equator_prime",
              "starts_at_s" => 500.0,
              "ends_at_s" => 900.0
            }
          ]),
        derive_branches?: true,
        branches: [%{id: "baseline"}, %{id: "manual_review", events: [%{type: "operator_note"}]}],
        current_epoch_s: 0.0
      )

    baseline = branch(artifact, "baseline")

    assert [
             %{
               "id" => "provider_selected_downlink",
               "type" => "downlink",
               "direction" => "downlink",
               "ground_station_id" => "equator_prime",
               "starts_at_s" => 700.0,
               "ends_at_s" => 760.0
             }
           ] = baseline["candidate_plan"]["activities"]

    assert get_in(baseline, ["objective_satisfaction", "downlink_completion"]) == %{
             "required_contacts" => 1,
             "planned_contacts" => 1,
             "required_downlink_mb" => 50.0,
             "planned_downlink_mb" => 60.0,
             "ratio" => 1.0
           }

    refute Enum.any?(baseline["risk_indicators"], &(&1["type"] == "no_viable_downlink"))

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy downlink completion discounts sparse missed planned-contact downlinks" do
    planned_contact =
      downlink("planned_downlink", 700.0, 760.0)
      |> Map.put("type", "planned_contact")
      |> Map.put("direction", "downlink")
      |> Map.put("score", 10.0)

    replacement_contact =
      downlink("planned_downlink_recovery", 800.0, 860.0)
      |> Map.put("type", "planned_contact")
      |> Map.put("direction", "downlink")
      |> Map.put("score", 100.0)

    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [planned_contact],
        "candidate_activities" => [replacement_contact]
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([
            %{
              "type" => "downlink_completion",
              "required_contacts" => 1,
              "ground_station_id" => "equator_prime",
              "starts_at_s" => 500.0,
              "ends_at_s" => 900.0
            }
          ])
          |> Map.put(:realized_activities, [%{id: "planned_downlink", status: "missed"}]),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    downlink_branch = branch(artifact, "derived_downlink_constrained")

    assert %{
             "type" => "downlink_completion_gap",
             "planned_contacts" => 0,
             "source_activity_id" => "planned_downlink",
             "realized_status" => "missed",
             "derivation_reasons" => [
               "downlink_completion_gap",
               "realized_downlink_missed"
             ]
           } = Enum.find(downlink_branch["events"], &(&1["type"] == "downlink_completion_gap"))

    assert Enum.any?(
             downlink_branch["repair_result"]["deltas"],
             &(&1["activity_id"] == "planned_downlink" and
                 &1["replacement_activity_id"] == "planned_downlink_recovery" and
                 &1["repair_action"] == "moved")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy downlink completion discounts provider contact feedback joined to planned downlinks" do
    planned_contact =
      downlink("planned_downlink", 700.0, 760.0)
      |> Map.put("type", "planned_contact")
      |> Map.put("direction", "downlink")
      |> Map.put("score", 10.0)

    replacement_contact =
      downlink("planned_downlink_recovery", 800.0, 860.0)
      |> Map.put("type", "planned_contact")
      |> Map.put("direction", "downlink")
      |> Map.put("score", 100.0)

    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [planned_contact],
        "candidate_activities" => [replacement_contact]
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([
            %{
              "type" => "downlink_completion",
              "required_contacts" => 1,
              "ground_station_id" => "equator_prime",
              "starts_at_s" => 500.0,
              "ends_at_s" => 900.0
            }
          ])
          |> Map.put(:realized_activities, [
            %{id: "planned_downlink", type: "contact", direction: "downlink", status: "missed"}
          ]),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    downlink_branch = branch(artifact, "derived_downlink_constrained")

    assert %{
             "type" => "downlink_completion_gap",
             "planned_contacts" => 0,
             "source_activity_id" => "planned_downlink",
             "realized_status" => "missed",
             "derivation_reasons" => [
               "downlink_completion_gap",
               "realized_downlink_missed"
             ]
           } = Enum.find(downlink_branch["events"], &(&1["type"] == "downlink_completion_gap"))

    assert Enum.any?(
             downlink_branch["repair_result"]["deltas"],
             &(&1["activity_id"] == "planned_downlink" and
                 &1["replacement_activity_id"] == "planned_downlink_recovery" and
                 &1["repair_action"] == "moved")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy downlink completion keeps multiple realized source IDs as stable arrays" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          downlink("planned_downlink_a", 700.0, 760.0),
          downlink("planned_downlink_b", 800.0, 860.0)
        ],
        "candidate_activities" => [
          refreshed_downlink("planned_downlink_recovery", 900.0, 960.0)
          |> Map.put("score", 100.0)
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([
            %{
              "type" => "downlink_completion",
              "required_contacts" => 2,
              "ground_station_id" => "equator_prime"
            }
          ])
          |> Map.put(:realized_activities, [
            %{id: "planned_downlink_b", status: "failed"},
            %{id: "planned_downlink_a", status: "missed"}
          ]),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    downlink_branch = branch(artifact, "derived_downlink_constrained")

    assert %{
             "type" => "downlink_completion_gap",
             "planned_contacts" => 0,
             "source_activity_id" => "planned_downlink_a",
             "source_activity_ids" => ["planned_downlink_a", "planned_downlink_b"],
             "realized_status" => "failed,missed"
           } = Enum.find(downlink_branch["events"], &(&1["type"] == "downlink_completion_gap"))

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy downlink completion objective can require downlink data volume" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          downlink("dl_planned", 100.0, 160.0)
          |> Map.put("estimated_throughput_mb", 40.0)
        ],
        "candidate_activities" => [
          refreshed_downlink("dl_small", 700.0, 730.0)
          |> Map.put("estimated_throughput_mb", 30.0)
          |> Map.put("score", 100.0),
          refreshed_downlink("dl_large", 900.0, 960.0)
          |> Map.put("estimated_throughput_mb", 60.0)
          |> Map.put("score", 90.0),
          refreshed_downlink("dl_unneeded", 1_200.0, 1_260.0)
          |> Map.put("estimated_throughput_mb", 60.0)
          |> Map.put("score", 10.0)
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([
            %{
              "type" => "downlink_completion",
              "required_downlink_mb" => 120.0,
              "ground_station_id" => "equator_prime",
              "starts_at_s" => 0.0,
              "ends_at_s" => 1_000.0
            }
          ]),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    downlink_branch = branch(artifact, "derived_downlink_constrained")

    assert %{
             "type" => "downlink_completion_gap",
             "required_downlink_mb" => 120.0,
             "planned_downlink_mb" => 40.0,
             "required_contacts" => 1,
             "planned_contacts" => 1
           } = List.first(downlink_branch["events"])

    additions = downlink_branch["candidate_plan"]["strategic_additions"]

    assert %{
             "feasibility" => %{
               "required_downlink_mb" => 120.0,
               "planned_downlink_mb" => 40.0,
               "staged_downlink_mb" => 90.0,
               "candidate_downlink_mb" => 30.0
             }
           } = Enum.find(additions, &(&1["id"] == "dl_small"))

    assert %{
             "feasibility" => %{
               "required_downlink_mb" => 120.0,
               "planned_downlink_mb" => 40.0,
               "staged_downlink_mb" => 90.0,
               "candidate_downlink_mb" => 60.0
             }
           } = Enum.find(additions, &(&1["id"] == "dl_large"))

    refute Enum.any?(additions, &(&1["id"] == "dl_unneeded"))

    assert get_in(downlink_branch, [
             "objective_satisfaction",
             "downlink_completion",
             "required_downlink_mb"
           ]) == 120.0

    assert get_in(downlink_branch, [
             "objective_satisfaction",
             "downlink_completion",
             "planned_downlink_mb"
           ]) == 130.0

    assert get_in(downlink_branch, [
             "objective_satisfaction",
             "downlink_completion",
             "ratio"
           ]) == 1.0

    downlink_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "derived_downlink_constrained"))

    assert %{
             "downlink_completion_required_contacts" => 1,
             "downlink_completion_planned_contacts" => 3,
             "downlink_completion_required_downlink_mb" => 120.0,
             "downlink_completion_planned_downlink_mb" => 130.0,
             "downlink_completion_ratio" => 1.0,
             "repair_link_required_downlink_mb" => 120.0,
             "repair_link_selected_capacity_adjusted_throughput_mb" => 40.0,
             "repair_link_selected_downlink_shortfall_mb" => 80.0,
             "repair_link_downlink_requirement_status" => "shortfall",
             "coverage_observed_target_count" => 0,
             "revisit_count" => 0
           } = downlink_row

    downlink_row_index =
      Enum.find_index(
        artifact["branch_comparison_report"]["rows"],
        &(&1["branch_id"] == "derived_downlink_constrained")
      )

    objective_required_downlink_invalid =
      put_in(
        artifact,
        [
          "branch_comparison_report",
          "rows",
          Access.at(downlink_row_index),
          "downlink_completion_required_downlink_mb"
        ],
        121.0
      )

    assert {:error, objective_required_downlink_report} =
             Schema.validate_artifact(objective_required_downlink_invalid)

    assert Enum.any?(
             objective_required_downlink_report["errors"],
             &(&1["path"] ==
                 "$.branch_comparison_report.rows[#{downlink_row_index}].downlink_completion_required_downlink_mb" and
                 &1["message"] ==
                   "must match the enclosing branch objective downlink_completion.required_downlink_mb")
           )

    required_downlink_invalid =
      put_in(
        artifact,
        [
          "branch_comparison_report",
          "rows",
          Access.at(downlink_row_index),
          "repair_link_required_downlink_mb"
        ],
        121.0
      )

    assert {:error, required_downlink_report} =
             Schema.validate_artifact(required_downlink_invalid)

    assert Enum.any?(
             required_downlink_report["errors"],
             &(&1["path"] ==
                 "$.branch_comparison_report.rows[#{downlink_row_index}].repair_link_required_downlink_mb" and
                 &1["message"] ==
                   "must match the enclosing branch repair link_capacity_report.required_downlink_mb")
           )

    assert Enum.any?(
             downlink_branch["risk_indicators"],
             &(&1["type"] == "downlink_completion_gap" and
                 &1["reason"] ==
                   "planned downlink volume 40.0 MB below required 120.0 MB")
           )

    assert Enum.any?(
             get_in(artifact, ["recommendation", "explanation"]),
             &(&1["type"] == "risk_driver" and
                 &1["risk_type"] == "downlink_completion_gap" and
                 &1["reason"] ==
                   "planned downlink volume 40.0 MB below required 120.0 MB")
           )

    assert Enum.any?(
             get_in(artifact, ["recommendation", "explanation"]),
             &(&1["type"] == "repair_link_capacity" and
                 &1["recommended_branch_id"] == "derived_downlink_constrained" and
                 &1["required_downlink_mb"] == 120.0 and
                 &1["selected_capacity_adjusted_throughput_mb"] == 40.0 and
                 &1["selected_downlink_shortfall_mb"] == 80.0 and
                 &1["downlink_requirement_status"] == "shortfall")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy explicit downlink gap events inherit aggregate mission-state downlink volume demand" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [],
        "candidate_activities" => [
          refreshed_downlink("dl_large", 700.0, 760.0)
          |> Map.put("estimated_throughput_mb", 100.0)
          |> Map.put("score", 100.0),
          refreshed_downlink("dl_small", 900.0, 960.0)
          |> Map.put("estimated_throughput_mb", 50.0)
          |> Map.put("score", 10.0)
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([
            %{"type" => "downlink_completion", "required_downlink_mb" => 100.0},
            %{"type" => "downlink_completion", "required_downlink_mb" => 50.0}
          ]),
        derive_branches?: false,
        branches: [
          %{id: "baseline"},
          %{
            id: "manual_gap",
            events: [
              %{
                type: "downlink_completion_gap",
                required_contacts: 1,
                starts_at_s: 500.0,
                ends_at_s: 1_000.0
              }
            ]
          }
        ],
        current_epoch_s: 0.0
      )

    manual_gap = branch(artifact, "manual_gap")
    additions = manual_gap["candidate_plan"]["strategic_additions"]

    assert Enum.map(additions, & &1["id"]) == ["dl_large", "dl_small"]

    assert Enum.all?(
             additions,
             &(get_in(&1, ["feasibility", "required_downlink_mb"]) == 150.0)
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy branch-generated refresh scores downlinks against required data volume gap" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:objectives, [
        %{
          type: "downlink_completion",
          required_downlink_mb: 1_000.0,
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

    downlink_branch = branch(artifact, "derived_downlink_constrained")

    assert %{
             "type" => "downlink_completion_gap",
             "required_downlink_mb" => 1_000.0
           } = List.first(downlink_branch["events"])

    assert List.first(downlink_branch["events"])["planned_downlink_mb"] == 0

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             downlink_branch["assumptions"]["candidate_source"]

    generated_downlink =
      downlink_branch["repair_result"]["source_candidate_activities"]
      |> Enum.find(&(&1["type"] == "downlink" and &1["ground_station_id"] == "equator_prime"))

    assert %{
             "required_downlink_mb" => 1_000.0,
             "downlink_completion_source" => "operational_feedback.downlink_demand_mb.station",
             "downlink_requirement_status" => "shortfall"
           } = generated_downlink

    assert generated_downlink["candidate_downlink_mb"] > 0.0
    assert generated_downlink["selected_downlink_shortfall_mb"] > 0.0
    assert generated_downlink["score_terms"]["downlink_completion_value"] > 0.0

    assert get_in(generated_downlink, ["throughput_model", "required_downlink_mb"]) == 1_000.0
    assert get_in(generated_downlink, ["activity_context", "required_downlink_mb"]) == 1_000.0

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy downlink completion data volume subtracts missed realized downlinks" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          downlink("dl_missed", 100.0, 160.0)
          |> Map.put("estimated_throughput_mb", 60.0),
          downlink("dl_remaining", 300.0, 360.0)
          |> Map.put("estimated_throughput_mb", 60.0)
        ],
        "candidate_activities" => [
          refreshed_downlink("dl_replacement", 700.0, 760.0)
          |> Map.put("estimated_throughput_mb", 60.0)
          |> Map.put("score", 100.0)
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([
            %{
              "type" => "downlink_completion",
              "required_downlink_mb" => 120.0,
              "ground_station_id" => "equator_prime",
              "starts_at_s" => 0.0,
              "ends_at_s" => 1_000.0
            }
          ])
          |> Map.put(:realized_activities, [%{id: "dl_missed", status: "missed"}]),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    downlink_branch = branch(artifact, "derived_downlink_constrained")

    assert %{
             "type" => "downlink_completion_gap",
             "required_downlink_mb" => 120.0,
             "planned_downlink_mb" => 60.0,
             "source_activity_id" => "dl_missed",
             "realized_status" => "missed",
             "derivation_reasons" => [
               "downlink_completion_gap",
               "realized_downlink_missed"
             ]
           } = List.first(downlink_branch["events"])

    assert Enum.any?(
             downlink_branch["repair_result"]["deltas"],
             &(&1["activity_id"] == "dl_missed" and
                 &1["replacement_activity_id"] == "dl_replacement" and
                 &1["repair_action"] == "moved")
           )

    assert %{
             "id" => "dl_replacement",
             "repair" => %{"action" => "moved"}
           } =
             Enum.find(
               downlink_branch["candidate_plan"]["activities"],
               &(&1["id"] == "dl_replacement")
             )

    assert get_in(downlink_branch, [
             "objective_satisfaction",
             "downlink_completion",
             "planned_downlink_mb"
           ]) == 120.0

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy downlink completion treats cancelled provider spelling as failed realized downlink" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          downlink("dl_cancelled", 100.0, 160.0)
          |> Map.put("estimated_throughput_mb", 60.0)
        ],
        "candidate_activities" => [
          refreshed_downlink("dl_replacement", 700.0, 760.0)
          |> Map.put("estimated_throughput_mb", 60.0)
          |> Map.put("score", 100.0)
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([
            %{
              "type" => "downlink_completion",
              "required_downlink_mb" => 60.0,
              "ground_station_id" => "equator_prime",
              "starts_at_s" => 0.0,
              "ends_at_s" => 1_000.0
            }
          ])
          |> Map.put(:realized_activities, [%{id: "dl_cancelled", status: " CANCELLED "}]),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    downlink_branch = branch(artifact, "derived_downlink_constrained")

    assert %{
             "type" => "downlink_completion_gap",
             "source_activity_id" => "dl_cancelled",
             "realized_status" => "cancelled",
             "derivation_reasons" => [
               "downlink_completion_gap",
               "realized_downlink_cancelled"
             ]
           } = List.first(downlink_branch["events"])

    assert Enum.any?(
             downlink_branch["repair_result"]["deltas"],
             &(&1["activity_id"] == "dl_cancelled" and
                 &1["repair_action"] == "canceled" and
                 &1["status"] == "cancelled")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy does not infer realized downlinks from duplicate planned activity ids" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          observe("duplicate_activity", "leo_1", "target_a", 100.0, 160.0, 10.0),
          downlink("duplicate_activity", 300.0, 360.0)
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([
            %{
              "type" => "downlink_completion",
              "required_contacts" => 1,
              "ground_station_id" => "equator_prime",
              "starts_at_s" => 0.0,
              "ends_at_s" => 1_000.0
            }
          ])
          |> Map.put(:realized_activities, [%{id: "duplicate_activity", status: "missed"}]),
        derive_branches?: true,
        branches: [%{id: "baseline"}, %{id: "manual_review", events: [%{type: "operator_note"}]}],
        current_epoch_s: 0.0
      )

    refute branch(artifact, "derived_downlink_constrained")

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
