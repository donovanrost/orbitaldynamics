Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyBranchBasicsTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy applies degraded spacecraft branch state through V2 repair" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 1_000.0},
        "activities" => [observe("obs_1", "leo_1", "target_a", 100.0, 160.0, 100.0)],
        "candidate_activities" => []
      })

    artifact =
      strategy(prior_plan,
        branches: [
          %{id: "baseline"},
          %{
            id: "degraded",
            events: [
              %{
                type: "degraded_spacecraft",
                scenario_id: "leo_1",
                incompatible_activity_types: ["observe"]
              }
            ]
          }
        ],
        current_epoch_s: 0.0
      )

    degraded = branch(artifact, "degraded")

    assert [%{"activity_id" => "obs_1", "repair_action" => "suppressed"}] =
             degraded["repair_result"]["deltas"]

    assert Enum.any?(degraded["risk_indicators"], &(&1["type"] == "spacecraft_degraded"))
    assert degraded["resource_impacts"]["spacecraft_availability"] == 0.0

    degraded_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "degraded"))

    assert degraded_row["spacecraft_availability"] == 0.0
    assert "spacecraft_availability_low" in degraded_row["resource_risk_types"]
  end

  test "strategy marks branches blocked when approval policy risk is violated" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 1_000.0},
        "activities" => [downlink("dl_1", 100.0, 160.0)],
        "candidate_activities" => []
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([%{"type" => "downlink_completion", "required_contacts" => 1}]),
        branches: [
          %{id: "baseline"},
          %{
            id: "blocked_outage",
            events: [
              %{
                type: "ground_station_outage",
                ground_station_id: "equator_prime",
                starts_at_s: 90.0,
                ends_at_s: 200.0
              }
            ]
          }
        ],
        current_epoch_s: 0.0
      )

    blocked = branch(artifact, "blocked_outage")

    assert blocked["approval_status"] == "blocked_by_policy"
    assert Enum.any?(blocked["risk_indicators"], &(&1["type"] == "no_viable_downlink"))
  end

  test "strategy artifact is deterministic with fixed inputs and generated_at" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 1_000.0},
        "activities" => [downlink("dl_1", 100.0, 160.0)],
        "candidate_activities" => [downlink("dl_2", 700.0, 760.0)]
      })

    request = [
      mission_state: mission_state([]),
      branches: [
        %{id: "baseline"},
        %{id: "fuel", events: [%{type: "fuel_preservation_mode"}]}
      ],
      current_epoch_s: 0.0,
      generated_at: ~U[2026-05-14 12:00:00Z]
    ]

    left = strategy(prior_plan, request)
    right = strategy(prior_plan, request)

    assert left == right
    assert left["schema_version"] == 3
    assert is_binary(left["strategy_metadata"]["strategy_id"])
  end

  test "strategy generated IDs and ordering are stable across branch and event permutations" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 1_000.0},
        "activities" => [downlink("dl_1", 100.0, 160.0)],
        "candidate_activities" => [
          downlink("dl_2", 700.0, 760.0),
          observe("obs_2", "leo_1", "target_a", 800.0, 860.0, 12.0)
        ]
      })

    events = [
      %{type: "fuel_preservation_mode"},
      %{
        type: "reduced_downlink_capacity",
        ground_station_id: "equator_prime",
        starts_at_s: 80.0,
        ends_at_s: 200.0,
        capacity_fraction: 0.5
      }
    ]

    left =
      strategy(prior_plan,
        mission_state: mission_state([]),
        branches: [
          %{id: "baseline"},
          %{id: "capacity", events: events},
          %{id: "fuel", events: [%{type: "fuel_preservation_mode"}]}
        ],
        current_epoch_s: 0.0,
        generated_at: ~U[2026-05-14 12:00:00Z]
      )

    right =
      strategy(prior_plan,
        mission_state: mission_state([]),
        branches: [
          %{id: "fuel", events: [%{type: "fuel_preservation_mode"}]},
          %{id: "capacity", events: Enum.reverse(events)},
          %{id: "baseline"}
        ],
        current_epoch_s: 0.0,
        generated_at: ~U[2026-05-14 12:00:00Z]
      )

    assert right == left
    assert is_binary(left["strategy_metadata"]["strategy_id"])

    assert Enum.map(left["branches"], & &1["branch_id"]) ==
             left["branches"]
             |> Enum.sort_by(&{-&1["score"], &1["branch_id"]})
             |> Enum.map(& &1["branch_id"])
  end

  test "strategy branch comparison exposes probability weighted score semantics" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [observe("obs_1", "leo_1", "target_a", 100.0, 160.0, 100.0)],
        "candidate_activities" => [
          observe("hot_window", "leo_1", "target_hot", 300.0, 360.0, 1_000.0)
        ]
      })

    artifact =
      strategy(prior_plan,
        branches: [
          %{id: "baseline"},
          %{
            id: "unlikely_hot_target",
            probability: 0.01,
            events: [
              %{
                type: "urgent_target",
                target_id: "target_hot",
                priority: 12.0
              }
            ]
          }
        ],
        current_epoch_s: 0.0
      )

    baseline_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "baseline"))

    unlikely_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "unlikely_hot_target"))

    assert artifact["recommendation"]["recommended_branch_id"] == "baseline"
    assert unlikely_row["raw_score"] > baseline_row["raw_score"]
    assert unlikely_row["branch_probability"] == 0.01

    assert_in_delta unlikely_row["expected_score"],
                    unlikely_row["raw_score"] * unlikely_row["branch_probability"],
                    1.0e-9

    assert unlikely_row["score"] == unlikely_row["expected_score"]

    assert artifact["branch_comparison_report"]["assumptions"]["score"] ==
             "probability_weighted_expected_score"

    assert {:ok, %{"schema_contract" => "branch_comparison_report.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact["branch_comparison_report"])
  end

  test "strategy rejects branch probabilities outside the supported range" do
    assert_raise ArgumentError,
                 ~r/branch bad_probability probability must be between 0.0 and 1.0/,
                 fn ->
                   strategy(base_plan(%{}),
                     branches: [%{id: "baseline"}, %{id: "bad_probability", probability: 1.2}],
                     current_epoch_s: 0.0
                   )
                 end
  end

  test "strategy normalizes branch event lineage ids" do
    artifact =
      strategy(base_plan(%{}),
        branches: [
          %{id: "baseline"},
          %{
            id: "lineage",
            events: [
              %{
                id: 42,
                type: "operator_note",
                source_branch_id: :branch_b,
                source_branch_ids: [:branch_z, "branch_a", :branch_z, 42, nil, ""],
                trust_boundary: 42,
                provenance: %{trust_boundary: :ops_review},
                objective_id: :objective_a,
                scenario_id: :leo_1,
                spacecraft_id: :leo_bus_1,
                activity_id: :cmd_1,
                target_id: :target_a,
                source_activity_id: 42,
                station_id: :equator_prime,
                source_window_id: :window_a,
                collection_id: :collection_a,
                product_id: :product_a,
                payload_id: :payload_a,
                instrument_id: :camera_a,
                station_calendar_entry_id: :calendar_window_a,
                station_calendar_provider_id: :partner_calendar,
                station_calendar_provider_entry_id: :partner_entry_a,
                station_reservation_id: :reservation_a,
                reservation_id: :reservation_b,
                station_calendar_status: :reserved,
                station_calendar_trust_boundary_status: :declared,
                reserved_by: :ops_team_b,
                station_reserved_by: :ops_team_b,
                reservation_status: :confirmed,
                station_reservation_status: :confirmed,
                station_reservation_match_status: :unmatched_overlap,
                source_activity_ids: [:cmd_1, "cmd_2", :cmd_1, 42, nil],
                target_ids: [:target_a, "target_b", :target_a, 42],
                allowed_scenario_ids: [:leo_1, "leo_2", :leo_1, 42],
                source_window_ids: [:window_a, "window_b", :window_a, 42],
                product_ids: [:product_a, "product_b", :product_a, 42],
                station_calendar_overlap_entry_ids: [:calendar_window_a, "calendar_window_b", 42],
                station_calendar_ambiguous_entry_ids: [
                  :calendar_window_c,
                  "calendar_window_d",
                  nil
                ],
                station_calendar_reservation_ids: [:reservation_a, "reservation_b", 42],
                station_calendar_directions: [:downlink, "uplink", :downlink, 42],
                station_calendar_overlap_availabilities: [:reserved, "maintenance", 42],
                station_calendar_reserved_by: [:ops_team_a, "ops_team_b", 42],
                station_calendar_reservation_statuses: [:confirmed, "planned", 42],
                start_s: "20.0",
                end_s: "10.0",
                actual_start_s: "30.0",
                actual_end_s: "25.0",
                capacity_fraction: "1.25",
                station_throughput_factor: "-0.4",
                priority: "12.5",
                required_downlink_mb: "-5.0",
                timing_3sigma_s: "bad"
              }
            ]
          }
        ],
        current_epoch_s: 0.0
      )

    lineage_branch = branch(artifact, "lineage")

    assert [
             %{
               "source_branch_id" => "branch_b",
               "source_branch_ids" => ["branch_a", "branch_b", "branch_z"],
               "trust_boundary" => "ops_review",
               "objective_id" => "objective_a",
               "scenario_id" => "leo_1",
               "spacecraft_id" => "leo_bus_1",
               "activity_id" => "cmd_1",
               "target_id" => "target_a",
               "ground_station_id" => "equator_prime",
               "source_window_id" => "window_a",
               "collection_id" => "collection_a",
               "product_id" => "product_a",
               "payload_id" => "payload_a",
               "instrument_id" => "camera_a",
               "station_calendar_entry_id" => "calendar_window_a",
               "station_calendar_provider_id" => "partner_calendar",
               "station_calendar_provider_entry_id" => "partner_entry_a",
               "station_reservation_id" => "reservation_a",
               "reservation_id" => "reservation_b",
               "station_calendar_status" => "reserved",
               "station_calendar_trust_boundary_status" => "declared",
               "reserved_by" => "ops_team_b",
               "station_reserved_by" => "ops_team_b",
               "reservation_status" => "confirmed",
               "station_reservation_status" => "confirmed",
               "station_reservation_match_status" => "unmatched_overlap",
               "source_activity_ids" => ["cmd_1", "cmd_2"],
               "target_ids" => ["target_a", "target_b"],
               "allowed_scenario_ids" => ["leo_1", "leo_2"],
               "source_window_ids" => ["window_a", "window_b"],
               "product_ids" => ["product_a", "product_b"],
               "station_calendar_overlap_entry_ids" => [
                 "calendar_window_a",
                 "calendar_window_b"
               ],
               "station_calendar_ambiguous_entry_ids" => [
                 "calendar_window_c",
                 "calendar_window_d"
               ],
               "station_calendar_reservation_ids" => ["reservation_a", "reservation_b"],
               "station_calendar_directions" => ["downlink", "uplink"],
               "station_calendar_overlap_availabilities" => ["reserved", "maintenance"],
               "station_calendar_reserved_by" => ["ops_team_a", "ops_team_b"],
               "station_calendar_reservation_statuses" => ["confirmed", "planned"],
               "starts_at_s" => 20.0,
               "ends_at_s" => 20.0,
               "actual_starts_at_s" => 30.0,
               "actual_ends_at_s" => 30.0,
               "invalid_branch_event_input" => true,
               "invalid_branch_event_input_reasons" => [
                 "invalid_capacity_fraction",
                 "invalid_required_downlink_mb",
                 "invalid_station_throughput_factor"
               ],
               "invalid_branch_event_fields" => [
                 "capacity_fraction",
                 "required_downlink_mb",
                 "station_throughput_factor"
               ],
               "invalid_branch_event_values" => invalid_values,
               "priority" => 12.5
             }
           ] = lineage_branch["events"]

    assert invalid_values == %{
             "capacity_fraction" => 1.25,
             "required_downlink_mb" => -5.0,
             "station_throughput_factor" => -0.4
           }

    lineage_event = List.first(lineage_branch["events"])

    refute Map.has_key?(lineage_event, "capacity_fraction")
    refute Map.has_key?(lineage_event, "required_downlink_mb")
    refute Map.has_key?(lineage_event, "station_throughput_factor")
    refute Map.has_key?(lineage_event, "source_activity_id")
    refute Map.has_key?(lineage_event, "id")
    refute Map.has_key?(lineage_event, "timing_3sigma_s")

    lineage_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "lineage"))

    assert lineage_row["combined_source_branch_ids"] == ["branch_a", "branch_b", "branch_z"]
    assert lineage_row["branch_event_trust_boundary_status_counts"] == %{"declared" => 1}

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy recommends lower raw mission value when risk and approvals dominate" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [observe("obs_1", "leo_1", "target_a", 100.0, 160.0, 100.0)],
        "candidate_activities" => []
      })

    artifact =
      strategy(prior_plan,
        strategy_policy: %{"risk_weight" => 40_000.0, "approval_load_weight" => 20_000.0},
        branches: [
          %{
            id: "aaa_urgent",
            label: "Urgent target",
            events: [
              %{
                type: "urgent_target",
                id: "urgent_target_event",
                target_id: "priority_target",
                scenario_id: "leo_1",
                starts_at_s: 300.0,
                ends_at_s: 360.0,
                priority: 500.0
              }
            ]
          },
          %{id: "baseline", label: "Nominal"}
        ],
        current_epoch_s: 0.0
      )

    baseline = branch(artifact, "baseline")
    urgent = branch(artifact, "aaa_urgent")

    assert urgent["score_terms"]["mission_value_score"] >
             baseline["score_terms"]["mission_value_score"]

    assert artifact["recommendation"]["recommended_branch_id"] == "baseline"
    assert artifact["recommendation"]["status"] == "pass"
    assert Enum.any?(artifact["recommendation"]["tradeoffs"], &(&1["dimension"] == "risk_count"))
    assert artifact["strategy_policy"]["risk_weight"] == 40_000.0
    assert artifact["strategy_policy"]["approval_load_weight"] == 20_000.0
    refute Map.has_key?(artifact["strategy_policy"], :risk_weight)
    assert is_list(artifact["approval_policy"]["blocked_risk_types"])
    refute Map.has_key?(artifact["approval_policy"], :blocked_risk_types)

    assert %{
             "schema_contract" => "branch_comparison_report.v1",
             "model" => "deterministic_strategy_branch_score_comparison",
             "branch_count" => 2,
             "recommended_branch_id" => "baseline",
             "rows" => comparison_rows
           } = artifact["branch_comparison_report"]

    assert %{"branch_id" => "baseline", "selected" => true} =
             Enum.find(comparison_rows, &(&1["branch_id"] == "baseline"))

    assert %{"branch_id" => "aaa_urgent", "selected" => false} =
             Enum.find(comparison_rows, &(&1["branch_id"] == "aaa_urgent"))

    assert Enum.any?(comparison_rows, &(&1["risk_count"] > 0))

    assert {:ok, %{"schema_contract" => "branch_comparison_report.v1"}} =
             Schema.validate_artifact(artifact["branch_comparison_report"])

    assert %{
             "schema_contract" => "ranking_comparison_report.v1",
             "source" => "campaign_strategy.branch_comparison_report",
             "objective" => "strategy_branch_score",
             "left_label" => "normalized_branch_order",
             "right_label" => "score_ranked_branches",
             "winner" => %{
               "left_scenario_id" => "aaa_urgent",
               "right_scenario_id" => "baseline",
               "changed" => true
             }
           } = artifact["ranking_comparison_report"]

    assert %{
             "scenario_id" => "baseline",
             "left_rank" => 2,
             "right_rank" => 1,
             "rank_delta" => 1
           } =
             Enum.find(
               artifact["ranking_comparison_report"]["rows"],
               &(&1["scenario_id"] == "baseline")
             )

    assert {:ok, %{"schema_contract" => "ranking_comparison_report.v1"}} =
             Schema.validate_artifact(artifact["ranking_comparison_report"])

    assert %{
             "schema_contract" => "pareto_frontier_report.v1",
             "source" => "campaign_strategy.branch_comparison_report",
             "alternative_count" => 2,
             "objective_directions" => pareto_directions,
             "rows" => pareto_rows
           } = artifact["pareto_frontier_report"]

    assert pareto_directions["score"] == "maximize"
    assert pareto_directions["risk_count"] == "minimize"
    assert pareto_directions["approval_requirement_count"] == "minimize"
    assert Enum.map(pareto_rows, & &1["scenario_id"]) |> Enum.sort() == ["aaa_urgent", "baseline"]

    assert {:ok, %{"schema_contract" => "pareto_frontier_report.v1"}} =
             Schema.validate_artifact(artifact["pareto_frontier_report"])

    assert %{
             "schema_contract" => "score_term_report.v1",
             "model" => "strategy_branch_score_terms",
             "source" => "campaign_strategy.branches.score_terms",
             "row_count" => score_term_count,
             "score_term_keys" => score_term_keys,
             "rows" => score_term_rows
           } = artifact["score_term_report"]

    assert "expected_score" in score_term_keys
    assert score_term_count == length(score_term_rows)

    assert %{
             "scenario_id" => "baseline",
             "branch_id" => "baseline",
             "term_key" => "expected_score",
             "selected" => true
           } =
             Enum.find(
               score_term_rows,
               &(&1["branch_id"] == "baseline" and &1["term_key"] == "expected_score")
             )

    assert %{
             "scenario_id" => "aaa_urgent",
             "branch_id" => "aaa_urgent",
             "selected" => false
           } = Enum.find(score_term_rows, &(&1["branch_id"] == "aaa_urgent"))

    assert {:ok, %{"schema_contract" => "score_term_report.v1"}} =
             Schema.validate_artifact(artifact["score_term_report"])

    assert %{
             "schema_contract" => "objective_tradeoff_report.v1",
             "model" => "strategy_branch_score_term_tradeoffs",
             "ranking_count" => 2,
             "tradeoffs" => strategy_tradeoffs
           } = artifact["objective_tradeoff_report"]

    assert %{
             "scenario_id" => "baseline",
             "branch_id" => "baseline",
             "selected" => true
           } = Enum.find(strategy_tradeoffs, &(&1["branch_id"] == "baseline"))

    assert 0.0 ==
             strategy_tradeoffs
             |> Enum.find(&(&1["branch_id"] == "baseline"))
             |> Map.fetch!("score_delta_from_selected")

    assert %{"branch_id" => "aaa_urgent", "selected" => false} =
             Enum.find(strategy_tradeoffs, &(&1["branch_id"] == "aaa_urgent"))

    assert {:ok, %{"schema_contract" => "objective_tradeoff_report.v1"}} =
             Schema.validate_artifact(artifact["objective_tradeoff_report"])

    assert %{
             "schema_contract" => "operator_review_package.v1",
             "source_artifact_type" => "campaign_strategy.v3",
             "realized_feedback_count" => 0,
             "recommendation_count" => 1,
             "review_count" => review_count,
             "rows" => [%{"review_type" => "strategy_recommendation"} | _]
           } = artifact["operator_review_package"]

    assert review_count >= 1

    assert Enum.any?(
             artifact["operator_review_package"]["rows"],
             &(&1["review_type"] == "score_term_review" and &1["branch_id"] == "baseline")
           )

    assert Enum.any?(
             artifact["operator_review_package"]["rows"],
             &(&1["review_type"] == "objective_tradeoff_review" and
                 &1["branch_id"] == "baseline")
           )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(artifact["operator_review_package"])

    assert %{
             "schema_contract" => "cadence_import_manifest.v1",
             "source_artifact_type" => "campaign_strategy.v3",
             "source_artifact_id" => strategy_id,
             "row_count" => row_count,
             "ready_count" => ready_count,
             "review_required_count" => review_required_count,
             "blocked_count" => 0,
             "missing_import_count" => 0,
             "rows" => strategy_import_rows
           } = artifact["cadence_import_manifest"]

    assert strategy_id == artifact["strategy_metadata"]["strategy_id"]
    assert row_count == length(strategy_import_rows)
    assert row_count == review_count + 1

    assert ready_count ==
             Enum.count(strategy_import_rows, &(&1["import_status"] == "ready_for_import"))

    assert review_required_count ==
             Enum.count(
               strategy_import_rows,
               &(&1["import_status"] == "review_required_before_import")
             )

    assert review_required_count > 0

    assert %{
             "branch_id" => "baseline",
             "recommended_branch_id" => "baseline",
             "import_action" => "import_strategy_recommendation",
             "import_status" => "ready_for_import",
             "selected" => true,
             "source_recommendation" => %{"recommended_branch_id" => "baseline"}
           } = Enum.find(strategy_import_rows, &(&1["selected"] == true))

    assert Enum.any?(
             strategy_import_rows,
             &(&1["import_action"] == "review_strategy_branch_alternative" and
                 &1["import_status"] == "not_applicable")
           )

    assert Enum.any?(
             strategy_import_rows,
             &(&1["rank"] > 2 and &1["import_action"] == "review_strategy_tradeoff" and
                 &1["source_review_type"] == "strategy_tradeoff")
           )

    assert Enum.any?(
             strategy_import_rows,
             &(&1["rank"] > 2 and &1["import_action"] == "review_ranking_comparison" and
                 &1["source_review_type"] == "ranking_comparison_review")
           )

    assert Enum.any?(
             strategy_import_rows,
             &(&1["import_action"] == "review_score_term" and &1["branch_id"] == "baseline")
           )

    assert Enum.any?(
             strategy_import_rows,
             &(&1["import_action"] == "review_objective_tradeoff" and
                 &1["branch_id"] == "baseline")
           )

    refute Enum.any?(
             strategy_import_rows,
             &(&1["source_review_type"] == "strategy_recommendation")
           )

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(artifact["cadence_import_manifest"])
  end
end
