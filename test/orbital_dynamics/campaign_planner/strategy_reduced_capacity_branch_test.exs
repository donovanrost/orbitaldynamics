Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyReducedCapacityBranchTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy represents reduced capacity, missed maneuver, and fuel preservation choices" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          maneuver("burn_1", 120.0),
          maneuver("burn_2", 180.0),
          downlink("dl_1", 300.0, 360.0)
        ],
        "candidate_activities" => [downlink("dl_2", 700.0, 760.0)]
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([%{"type" => "downlink_completion", "required_contacts" => 1}],
            resources: %{"fuel_margin" => 0.8}
          ),
        branches: [
          %{id: "baseline"},
          %{
            id: "fuel_capacity",
            events: [
              %{type: "missed_maneuver", activity_id: "burn_1"},
              %{
                type: "delayed_maneuver",
                activity_id: "burn_2",
                actual_starts_at_s: 240.0
              },
              %{
                type: "reduced_downlink_capacity",
                ground_station_id: "equator_prime",
                capacity_fraction: "0.5",
                starts_at_s: "650.0",
                ends_at_s: "800.0"
              },
              %{type: "fuel_preservation_mode"}
            ]
          }
        ],
        current_epoch_s: 0.0
      )

    fuel_capacity = branch(artifact, "fuel_capacity")

    assert fuel_capacity["candidate_plan"]["capacity_adjustments"] == [
             %{
               "capacity_fraction" => 0.5,
               "ends_at_s" => 800.0,
               "ground_station_id" => "equator_prime",
               "starts_at_s" => 650.0,
               "type" => "reduced_downlink_capacity"
             }
           ]

    assert Enum.any?(fuel_capacity["risk_indicators"], &(&1["type"] == "missed_maneuver"))
    assert Enum.any?(fuel_capacity["risk_indicators"], &(&1["type"] == "delayed_maneuver"))
    assert fuel_capacity["score_terms"]["fuel_preservation_score"] > 0.0
  end

  test "strategy only applies reduced downlink capacity inside the event window" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => "2000.0"},
        "activities" => [downlink("dl_1", 100.0, 160.0)],
        "candidate_activities" => [
          downlink("dl_2", 700.0, 760.0),
          downlink("dl_3", 900.0, 960.0)
        ]
      })

    artifact =
      strategy(prior_plan,
        scoring_policy: %{"schedule_move_cost_weight" => 0.0},
        branches: [
          %{id: "baseline"},
          %{
            id: "capacity_window",
            events: [
              %{
                type: "ground_station_outage",
                ground_station_id: "equator_prime",
                starts_at_s: 90.0,
                ends_at_s: 200.0
              },
              %{
                type: "reduced_downlink_capacity",
                ground_station_id: "equator_prime",
                capacity_fraction: "0.5",
                starts_at_s: "650.0",
                ends_at_s: "800.0"
              }
            ]
          }
        ],
        current_epoch_s: 0.0
      )

    assert [
             %{
               "activity_id" => "dl_1",
               "repair_action" => "moved",
               "replacement_activity_id" => "dl_3"
             }
           ] =
             branch(artifact, "capacity_window")["repair_result"]["deltas"]
             |> Enum.filter(&(&1["activity_id"] == "dl_1"))
  end

  test "strategy applies reduced downlink capacity to planned-contact downlink candidates" do
    reduced_candidate =
      "planned_dl_2"
      |> refreshed_downlink(700.0, 760.0)
      |> Map.put("type", "planned_contact")
      |> Map.put("score", "10.0")
      |> put_in(["score_terms", "contact_value"], "10.0")

    full_capacity_candidate =
      "planned_dl_3"
      |> refreshed_downlink(900.0, 960.0)
      |> Map.put("type", "planned_contact")

    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [downlink("dl_1", 100.0, 160.0)],
        "candidate_activities" => [reduced_candidate, full_capacity_candidate]
      })

    artifact =
      strategy(prior_plan,
        scoring_policy: %{"schedule_move_cost_weight" => 0.0},
        branches: [
          %{id: "baseline"},
          %{
            id: "capacity_window",
            events: [
              %{
                type: "ground_station_outage",
                ground_station_id: "equator_prime",
                starts_at_s: 90.0,
                ends_at_s: 200.0
              },
              %{
                type: "reduced_downlink_capacity",
                ground_station_id: "equator_prime",
                capacity_fraction: 0.5,
                starts_at_s: 650.0,
                ends_at_s: 800.0
              }
            ]
          }
        ],
        current_epoch_s: 0.0
      )

    capacity_window = branch(artifact, "capacity_window")

    assert [
             %{
               "activity_id" => "dl_1",
               "repair_action" => "moved",
               "replacement_activity_id" => "planned_dl_3"
             }
           ] =
             capacity_window["repair_result"]["deltas"]
             |> Enum.filter(&(&1["activity_id"] == "dl_1"))

    assert %{"capacity_fraction" => 0.5, "score_terms" => %{"capacity_factor" => 0.5}} =
             Enum.find(
               capacity_window["repair_result"]["source_candidate_activities"],
               &(&1["id"] == "planned_dl_2")
             )

    assert %{"score" => 5.0, "score_terms" => %{"contact_value" => "10.0"}} =
             Enum.find(
               capacity_window["repair_result"]["source_candidate_activities"],
               &(&1["id"] == "planned_dl_2")
             )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy reduced capacity changes selected planned-contact throughput artifacts" do
    reduced_candidate =
      "planned_dl_2"
      |> refreshed_downlink(700.0, 760.0)
      |> Map.put("type", "planned_contact")
      |> Map.put("completed_fraction", 0.5)
      |> Map.put("actual_throughput_mb", 15.0)
      |> Map.put("required_downlink_mb", 60.0)

    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 1_500.0},
        "activities" => [downlink("dl_1", 100.0, 160.0)],
        "candidate_activities" => [reduced_candidate]
      })

    artifact =
      strategy(prior_plan,
        approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"},
        branches: [
          %{id: "baseline"},
          %{
            id: "capacity_window",
            events: [
              %{
                type: "ground_station_outage",
                ground_station_id: "equator_prime",
                starts_at_s: 90.0,
                ends_at_s: 200.0
              },
              %{
                type: "reduced_downlink_capacity",
                ground_station_id: "equator_prime",
                capacity_fraction: 0.5,
                starts_at_s: 650.0,
                ends_at_s: 800.0
              }
            ]
          }
        ],
        current_epoch_s: 0.0
      )

    repair = branch(artifact, "capacity_window")["repair_result"]

    assert [
             %{
               "id" => "planned_dl_2",
               "station_capacity_fraction" => 0.5,
               "throughput_model" => %{"station_capacity_fraction" => 0.5}
             }
           ] = repair["activities"]

    assert %{
             "selected_estimated_throughput_mb" => 60.0,
             "selected_capacity_adjusted_throughput_mb" => 30.0,
             "actual_throughput_mb" => 15.0,
             "actual_downlink_completion_ratio" => 0.25,
             "actual_downlink_shortfall_mb" => 45.0,
             "actual_downlink_requirement_status" => "shortfall",
             "actual_completion_fraction" => 0.5,
             "actual_completion_contact_count" => 1,
             "actual_completion_contact_ids" => ["planned_dl_2"],
             "rows" => [
               %{
                 "capacity_fraction_min" => 0.5,
                 "capacity_fraction_max" => 0.5,
                 "selected_capacity_adjusted_throughput_mb" => 30.0,
                 "actual_throughput_mb" => 15.0,
                 "actual_downlink_completion_ratio" => 0.25,
                 "actual_downlink_shortfall_mb" => 45.0,
                 "actual_downlink_requirement_status" => "shortfall",
                 "actual_completion_fraction" => 0.5,
                 "actual_completion_contact_count" => 1,
                 "actual_completion_contact_ids" => ["planned_dl_2"],
                 "approval_status" => "operator_review_required",
                 "approval_rule_matches" => rule_matches
               }
             ]
           } = repair["link_capacity_report"]

    assert Enum.any?(
             rule_matches,
             &(&1["rule_id"] == "low_actual_downlink_completion_review" and
                 &1["actual_completion_fraction"] == 0.5)
           )

    capacity_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "capacity_window"))

    assert capacity_row["repair_link_actual_throughput_mb"] == 15.0
    assert capacity_row["repair_link_actual_downlink_completion_ratio"] == 0.25
    assert capacity_row["repair_link_actual_downlink_shortfall_mb"] == 45.0
    assert capacity_row["repair_link_actual_downlink_requirement_status"] == "shortfall"

    capacity_row_index =
      Enum.find_index(
        artifact["branch_comparison_report"]["rows"],
        &(&1["branch_id"] == "capacity_window")
      )

    actual_completion_invalid =
      put_in(
        artifact,
        [
          "branch_comparison_report",
          "rows",
          Access.at(capacity_row_index),
          "repair_link_actual_downlink_completion_ratio"
        ],
        0.75
      )

    assert {:error, actual_completion_report} =
             Schema.validate_artifact(actual_completion_invalid)

    assert Enum.any?(
             actual_completion_report["errors"],
             &(&1["path"] ==
                 "$.branch_comparison_report.rows[#{capacity_row_index}].repair_link_actual_downlink_completion_ratio" and
                 &1["message"] ==
                   "must match the enclosing branch repair link_capacity_report.actual_downlink_completion_ratio")
           )

    assert %{
             "review_type" => "link_capacity_review",
             "source" => "campaign_strategy.branches.repair_result.link_capacity_report.rows",
             "branch_id" => "capacity_window",
             "ground_station_id" => "equator_prime",
             "selected_capacity_adjusted_throughput_mb" => 30.0,
             "selected_contact_ids" => ["planned_dl_2"],
             "actual_completion_fraction" => 0.5,
             "actual_completion_contact_count" => 1,
             "actual_completion_contact_ids" => ["planned_dl_2"],
             "approval_status" => "operator_review_required",
             "source_policy_decision" => %{
               "classification" => "operator_review_required"
             },
             "required_operator_action" => "review_link_capacity_summary"
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["review_type"] == "link_capacity_review" and
                   &1["branch_id"] == "capacity_window")
             )

    assert %{
             "import_action" => "review_link_capacity",
             "source_review_type" => "link_capacity_review",
             "branch_id" => "capacity_window",
             "ground_station_id" => "equator_prime",
             "selected_capacity_adjusted_throughput_mb" => 30.0,
             "actual_completion_fraction" => 0.5,
             "actual_completion_contact_count" => 1,
             "actual_completion_contact_ids" => ["planned_dl_2"],
             "source_policy_decision" => %{
               "classification" => "operator_review_required"
             }
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["import_action"] == "review_link_capacity" and
                   &1["branch_id"] == "capacity_window")
             )

    assert [%{"term_key" => repair_term_key, "value" => repair_term_value} | _] =
             repair["score_term_report"]["rows"]

    assert %{
             "review_type" => "score_term_review",
             "source" => "campaign_strategy.branches.repair_result.score_term_report.rows",
             "branch_id" => "capacity_window",
             "term_key" => ^repair_term_key,
             "value" => ^repair_term_value,
             "required_operator_action" => "review_score_term"
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["review_type"] == "score_term_review" and
                   &1["source"] ==
                     "campaign_strategy.branches.repair_result.score_term_report.rows" and
                   &1["branch_id"] == "capacity_window" and
                   &1["term_key"] == repair_term_key)
             )

    assert %{
             "import_action" => "review_score_term",
             "source_review_type" => "score_term_review",
             "branch_id" => "capacity_window",
             "term_key" => ^repair_term_key,
             "value" => ^repair_term_value
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["import_action"] == "review_score_term" and
                   &1["source"] ==
                     "campaign_strategy.branches.repair_result.score_term_report.rows" and
                   &1["branch_id"] == "capacity_window" and
                   &1["term_key"] == repair_term_key)
             )

    assert [%{"score" => repair_tradeoff_score} | _] =
             repair["objective_tradeoff_report"]["tradeoffs"]

    assert %{
             "review_type" => "objective_tradeoff_review",
             "source" =>
               "campaign_strategy.branches.repair_result.objective_tradeoff_report.tradeoffs",
             "branch_id" => "capacity_window",
             "score" => ^repair_tradeoff_score,
             "required_operator_action" => "review_objective_tradeoff"
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["review_type"] == "objective_tradeoff_review" and
                   &1["source"] ==
                     "campaign_strategy.branches.repair_result.objective_tradeoff_report.tradeoffs" and
                   &1["branch_id"] == "capacity_window")
             )

    assert %{
             "import_action" => "review_objective_tradeoff",
             "source_review_type" => "objective_tradeoff_review",
             "branch_id" => "capacity_window",
             "score" => ^repair_tradeoff_score
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["import_action"] == "review_objective_tradeoff" and
                   &1["source"] ==
                     "campaign_strategy.branches.repair_result.objective_tradeoff_report.tradeoffs" and
                   &1["branch_id"] == "capacity_window")
             )

    assert %{
             "activity_id" => "planned_dl_2",
             "required_operator_action" => "review_activity_approval"
           } =
             Enum.find(
               repair["operational_timeline_report"]["rows"],
               &(&1["activity_id"] == "planned_dl_2")
             )

    assert %{
             "review_type" => "operational_timeline_review",
             "source" =>
               "campaign_strategy.branches.repair_result.operational_timeline_report.rows",
             "branch_id" => "capacity_window",
             "activity_id" => "planned_dl_2",
             "required_operator_action" => "review_activity_approval"
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["review_type"] == "operational_timeline_review" and
                   &1["branch_id"] == "capacity_window" and
                   &1["activity_id"] == "planned_dl_2")
             )

    assert %{
             "import_action" => "review_operational_timeline",
             "source_review_type" => "operational_timeline_review",
             "source" =>
               "campaign_strategy.branches.repair_result.operational_timeline_report.rows",
             "branch_id" => "capacity_window",
             "activity_id" => "planned_dl_2",
             "required_operator_action" => "review_activity_approval"
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["source_review_type"] == "operational_timeline_review" and
                   &1["branch_id"] == "capacity_window" and
                   &1["activity_id"] == "planned_dl_2")
             )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives reduced station capacity from numeric-string mission-state entries" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:ground_network, [
        %{
          station_id: "equator_prime",
          capacity_fraction: "0.5",
          starts_at_s: "0.0",
          ends_at_s: "600.0"
        }
      ])

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}, %{id: "manual_review", events: [%{type: "operator_note"}]}],
        current_epoch_s: 0.0
      )

    capacity = branch(artifact, "derived_station_capacity_equator_prime")

    assert [
             %{
               "type" => "reduced_downlink_capacity",
               "ground_station_id" => "equator_prime",
               "capacity_fraction" => 0.5,
               "starts_at_s" => starts_at_s,
               "ends_at_s" => ends_at_s
             }
           ] = capacity["events"]

    assert starts_at_s == 0.0
    assert ends_at_s == 600.0

    repair = capacity["repair_result"]

    assert Enum.any?(
             repair["source_candidate_activities"],
             &(&1["ground_station_id"] == "equator_prime" and
                 get_in(&1, ["throughput_model", "station_capacity_fraction"]) == 0.5)
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
