Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyTimelineDiffCommandManeuverPressureTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy derives changed timeline diff command feedback from failed outcome rows" do
    prior_plan =
      base_plan(%{
        "activities" => [
          health_check("cmd_source", "leo_1", 100.0, 130.0),
          downlink("dl_1", 300.0, 360.0)
        ],
        "source_timeline_diff_report" => %{
          "schema_contract" => "timeline_diff_report.v1",
          "model" => "timeline_identity_activity_diff",
          "source" => "repair.activities",
          "row_count" => 1,
          "changed_count" => 1,
          "provenance" => %{"trust_boundary" => "ops_timeline_review"},
          "rows" => [
            %{
              "id" => "timeline_diff:timeline:cmd_changed",
              "rank" => 1,
              "timeline_id" => "timeline:cmd_changed",
              "diff_status" => "changed",
              "changed_fields" => ["command_result", "command_success_factor"],
              "source_activity_id" => "cmd_source",
              "replacement_activity_id" => "cmd_changed",
              "source_activity_type" => "health_check",
              "replacement_activity_type" => "health_check",
              "source_direction" => "command",
              "replacement_direction" => "command",
              "source_ground_station_id" => "equator_prime",
              "replacement_ground_station_id" => "equator_prime",
              "source_source_window_id" => "window_equator_command",
              "replacement_source_window_id" => "window_equator_command",
              "scenario_id" => "leo_1",
              "source_status" => "planned",
              "replacement_activity_context" => %{
                "starts_at_s" => 100.0,
                "ends_at_s" => 130.0,
                "command_result" => "rejected",
                "realized_status" => "failed"
              },
              "required_operator_action" => "review_timeline_change"
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

    branch = branch(artifact, "derived_timeline_diff_changed_cmd_source")

    assert %{
             "type" => "command_success_feedback",
             "activity_id" => "cmd_source",
             "scenario_id" => "leo_1",
             "command_result" => "rejected",
             "realized_status" => "failed",
             "source_activity_id" => "cmd_source",
             "replacement_activity_id" => "cmd_changed",
             "source_activity_ids" => ["cmd_changed", "cmd_source"],
             "timeline_id" => "timeline:cmd_changed",
             "feedback_source" => "prior_plan.source_timeline_diff_report",
             "feedback_scope" => "timeline_diff",
             "trust_boundary" => "ops_timeline_review",
             "derivation_reasons" => [
               "timeline_diff_changed_activity",
               "timeline_diff_changed_command"
             ]
           } = List.first(branch["events"])

    assert List.first(branch["events"])["command_success_factor"] == 0.0
    assert branch["feedback_adjustments"]["command_success_factor"] == 0.0

    assert Enum.any?(
             branch["risk_indicators"],
             &(&1["type"] == "command_success_rate_low" and &1["value"] == 0.0 and
                 &1["command_result"] == "rejected" and &1["realized_status"] == "failed" and
                 &1["source_activity_ids"] == ["cmd_changed", "cmd_source"])
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives changed timeline diff command feedback from provider-shaped health-check contacts" do
    prior_plan =
      base_plan(%{
        "activities" => [
          health_check("health_source", "leo_1", 100.0, 130.0),
          downlink("dl_1", 300.0, 360.0)
        ],
        "source_timeline_diff_report" => %{
          "schema_contract" => "timeline_diff_report.v1",
          "model" => "timeline_identity_activity_diff",
          "source" => "repair.activities",
          "row_count" => 1,
          "changed_count" => 1,
          "provenance" => %{"trust_boundary" => "ops_health_check_review"},
          "rows" => [
            %{
              "id" => "timeline_diff:timeline:health_changed",
              "rank" => 1,
              "timeline_id" => "timeline:health_changed",
              "diff_status" => "changed",
              "changed_fields" => ["command_result", "command_success_factor"],
              "source_activity_id" => "health_source",
              "replacement_activity_id" => "health_changed",
              "source_activity_type" => "planned_contact",
              "replacement_activity_type" => "planned_contact",
              "source_direction" => "health-check",
              "replacement_direction" => "health-check",
              "scenario_id" => "leo_1",
              "source_status" => "planned",
              "replacement_activity_context" => %{
                "starts_at_s" => 100.0,
                "ends_at_s" => 130.0,
                "command_result" => "timeout",
                "realized_status" => "failed"
              },
              "required_operator_action" => "review_timeline_change"
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

    branch = branch(artifact, "derived_timeline_diff_changed_health_source")

    assert %{
             "type" => "command_success_feedback",
             "activity_id" => "health_source",
             "scenario_id" => "leo_1",
             "command_result" => "timeout",
             "realized_status" => "failed",
             "source_activity_id" => "health_source",
             "replacement_activity_id" => "health_changed",
             "feedback_source" => "prior_plan.source_timeline_diff_report",
             "feedback_scope" => "timeline_diff",
             "trust_boundary" => "ops_health_check_review",
             "derivation_reasons" => [
               "timeline_diff_changed_activity",
               "timeline_diff_changed_command"
             ]
           } = List.first(branch["events"])

    assert List.first(branch["events"])["command_success_factor"] == 0.0
    assert branch["feedback_adjustments"]["command_success_factor"] == 0.0

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives changed timeline diff command feedback from routing identity mismatch" do
    prior_plan =
      base_plan(%{
        "activities" => [
          health_check("cmd_route_source", "leo_1", 100.0, 130.0),
          downlink("dl_1", 300.0, 360.0)
        ],
        "source_timeline_diff_report" => %{
          "schema_contract" => "timeline_diff_report.v1",
          "model" => "timeline_identity_activity_diff",
          "source" => "repair.activities",
          "row_count" => 1,
          "changed_count" => 1,
          "provenance" => %{"trust_boundary" => "ops_command_identity_review"},
          "rows" => [
            %{
              "id" => "timeline_diff:timeline:cmd_route_changed",
              "rank" => 1,
              "timeline_id" => "timeline:cmd_route_changed",
              "diff_status" => "changed",
              "changed_fields" => ["ground_station_id", "direction", "source_window_id"],
              "source_activity_id" => "cmd_route_source",
              "replacement_activity_id" => "cmd_route_replacement",
              "source_activity_type" => "planned_contact",
              "replacement_activity_type" => "planned_contact",
              "source_direction" => "uplink",
              "replacement_direction" => "command",
              "source_ground_station_id" => "polar_prime",
              "replacement_ground_station_id" => "equator_prime",
              "source_source_window_id" => "window_polar_uplink",
              "replacement_source_window_id" => "window_equator_command",
              "scenario_id" => "leo_1",
              "source_status" => "planned",
              "replacement_activity_context" => %{
                "starts_at_s" => 100.0,
                "ends_at_s" => 130.0,
                "command_result" => "accepted, executed",
                "realized_status" => "completed"
              },
              "required_operator_action" => "review_timeline_change"
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

    branch = branch(artifact, "derived_timeline_diff_changed_cmd_route_source")
    event = List.first(branch["events"])

    assert %{
             "type" => "command_success_feedback",
             "activity_id" => "cmd_route_source",
             "scenario_id" => "leo_1",
             "ground_station_id" => "equator_prime",
             "planned_ground_station_id" => "polar_prime",
             "realized_ground_station_id" => "equator_prime",
             "ground_station_match_status" => "mismatch",
             "direction" => "command",
             "planned_direction" => "uplink",
             "realized_direction" => "command",
             "direction_match_status" => "mismatch",
             "source_window_id" => "window_equator_command",
             "planned_source_window_id" => "window_polar_uplink",
             "realized_source_window_id" => "window_equator_command",
             "source_window_match_status" => "mismatch",
             "command_identity_mismatch_fields" => [
               "direction",
               "ground_station",
               "source_window"
             ],
             "command_result" => "accepted, executed",
             "realized_status" => "completed",
             "source_activity_id" => "cmd_route_source",
             "replacement_activity_id" => "cmd_route_replacement",
             "source_activity_ids" => ["cmd_route_replacement", "cmd_route_source"],
             "timeline_id" => "timeline:cmd_route_changed",
             "feedback_source" => "prior_plan.source_timeline_diff_report",
             "feedback_scope" => "timeline_diff",
             "feedback_key" => "cmd_route_source",
             "trust_boundary" => "ops_command_identity_review",
             "derivation_reasons" => [
               "timeline_diff_changed_activity",
               "timeline_diff_changed_command_identity",
               "direction_mismatch",
               "ground_station_mismatch",
               "source_window_mismatch"
             ]
           } = event

    assert event["command_success_factor"] == 0.0
    assert branch["feedback_adjustments"]["command_success_factor"] == 0.0

    assert Enum.any?(
             branch["risk_indicators"],
             &(&1["type"] == "command_success_rate_low" and
                 &1["ground_station_match_status"] == "mismatch" and
                 &1["direction_match_status"] == "mismatch" and
                 &1["source_window_match_status"] == "mismatch" and
                 &1["command_identity_mismatch_fields"] == [
                   "direction",
                   "ground_station",
                   "source_window"
                 ])
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives changed timeline diff command feedback from typed terminal status transitions" do
    prior_plan =
      base_plan(%{
        "activities" => [
          health_check("cmd_transition_source", "leo_1", 100.0, 130.0),
          downlink("dl_1", 300.0, 360.0)
        ],
        "source_timeline_diff_report" => %{
          "schema_contract" => "timeline_diff_report.v1",
          "model" => "timeline_identity_activity_diff",
          "source" => "repair.activities",
          "row_count" => 1,
          "changed_count" => 1,
          "provenance" => %{"trust_boundary" => "ops_status_transition_review"},
          "rows" => [
            %{
              "id" => "timeline_diff:timeline:cmd_transition_failed",
              "rank" => 1,
              "timeline_id" => "timeline:cmd_transition_failed",
              "diff_status" => "changed",
              "changed_fields" => ["status"],
              "source_activity_id" => "cmd_transition_source",
              "replacement_activity_id" => "cmd_transition_failed",
              "source_activity_type" => "health_check",
              "replacement_activity_type" => "health_check",
              "scenario_id" => "leo_1",
              "source_status" => "planned",
              "replacement_status" => "failed",
              "status_transition" => %{
                "field" => "status",
                "from" => "planned",
                "to" => "failed",
                "transition_type" => "changed",
                "transition_category" => "terminal_exception",
                "requires_operator_review" => true
              },
              "replacement_activity_context" => %{
                "starts_at_s" => 100.0,
                "ends_at_s" => 130.0
              },
              "required_operator_action" => "review_timeline_change"
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

    branch = branch(artifact, "derived_timeline_diff_changed_cmd_transition_source")

    assert %{
             "type" => "command_success_feedback",
             "activity_id" => "cmd_transition_source",
             "realized_status" => "failed",
             "source_activity_id" => "cmd_transition_source",
             "replacement_activity_id" => "cmd_transition_failed",
             "timeline_id" => "timeline:cmd_transition_failed",
             "status_transition" => %{
               "field" => "status",
               "from" => "planned",
               "to" => "failed",
               "transition_type" => "changed",
               "transition_category" => "terminal_exception",
               "requires_operator_review" => true
             },
             "transition_type" => "changed",
             "transition_category" => "terminal_exception",
             "requires_operator_review" => true,
             "feedback_source" => "prior_plan.source_timeline_diff_report",
             "feedback_scope" => "timeline_diff",
             "trust_boundary" => "ops_status_transition_review",
             "derivation_reasons" => [
               "timeline_diff_changed_activity",
               "timeline_diff_changed_command"
             ]
           } = List.first(branch["events"])

    assert List.first(branch["events"])["command_success_factor"] == 0.0
    assert branch["feedback_adjustments"]["command_success_factor"] == 0.0

    assert Enum.any?(
             branch["risk_indicators"],
             &(&1["type"] == "command_success_rate_low" and
                 &1["transition_category"] == "terminal_exception" and
                 &1["requires_operator_review"] == true)
           )

    assert %{
             "branch_transition_types" => ["changed"],
             "branch_transition_categories" => ["terminal_exception"],
             "branch_requires_operator_review" => true,
             "branch_requires_operator_review_count" => 1,
             "branch_realized_statuses" => ["failed"]
           } =
             Enum.find(
               artifact["branch_comparison_report"]["rows"],
               &(&1["branch_id"] == "derived_timeline_diff_changed_cmd_transition_source")
             )

    assert %{
             "branch_transition_types" => ["changed"],
             "branch_transition_categories" => ["terminal_exception"],
             "branch_requires_operator_review" => true,
             "branch_requires_operator_review_count" => 1,
             "source_branch_comparison" => %{
               "branch_transition_categories" => ["terminal_exception"],
               "branch_requires_operator_review" => true
             }
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["review_type"] == "strategy_tradeoff" and
                   &1["branch_id"] == "derived_timeline_diff_changed_cmd_transition_source")
             )

    assert %{
             "source_review_type" => "strategy_branch_comparison",
             "branch_transition_types" => ["changed"],
             "branch_transition_categories" => ["terminal_exception"],
             "branch_requires_operator_review" => true,
             "branch_requires_operator_review_count" => 1,
             "source_branch_comparison" => %{
               "branch_transition_categories" => ["terminal_exception"],
               "branch_requires_operator_review" => true
             }
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["source_review_type"] == "strategy_branch_comparison" and
                   &1["branch_id"] == "derived_timeline_diff_changed_cmd_transition_source")
             )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy disambiguates duplicate timeline diff status transitions by transition metadata" do
    prior_plan =
      base_plan(%{
        "activities" => [
          health_check("cmd_transition_duplicate_source", "leo_1", 100.0, 130.0),
          downlink("dl_1", 300.0, 360.0)
        ],
        "source_timeline_diff_report" => %{
          "schema_contract" => "timeline_diff_report.v1",
          "model" => "timeline_identity_activity_diff",
          "source" => "repair.activities",
          "row_count" => 2,
          "changed_count" => 2,
          "provenance" => %{"trust_boundary" => "ops_status_transition_review"},
          "rows" => [
            %{
              "id" => "timeline_diff:timeline:cmd_transition_terminal",
              "rank" => 1,
              "timeline_id" => "timeline:cmd_transition_duplicate",
              "diff_status" => "changed",
              "changed_fields" => ["status"],
              "source_activity_id" => "cmd_transition_duplicate_source",
              "replacement_activity_id" => "cmd_transition_duplicate_replacement",
              "source_activity_type" => "health_check",
              "replacement_activity_type" => "health_check",
              "scenario_id" => "leo_1",
              "source_status" => "planned",
              "replacement_status" => "failed",
              "status_transition" => %{
                "field" => "status",
                "from" => "planned",
                "to" => "failed",
                "transition_type" => "changed",
                "transition_category" => "terminal_exception",
                "requires_operator_review" => true
              },
              "replacement_activity_context" => %{
                "starts_at_s" => 100.0,
                "ends_at_s" => 130.0
              },
              "required_operator_action" => "review_timeline_change"
            },
            %{
              "id" => "timeline_diff:timeline:cmd_transition_policy",
              "rank" => 2,
              "timeline_id" => "timeline:cmd_transition_duplicate",
              "diff_status" => "changed",
              "changed_fields" => ["status"],
              "source_activity_id" => "cmd_transition_duplicate_source",
              "replacement_activity_id" => "cmd_transition_duplicate_replacement",
              "source_activity_type" => "health_check",
              "replacement_activity_type" => "health_check",
              "scenario_id" => "leo_1",
              "source_status" => "planned",
              "replacement_status" => "rejected",
              "status_transition" => %{
                "field" => "status",
                "from" => "planned",
                "to" => "rejected",
                "transition_type" => "changed",
                "transition_category" => "policy_rejection",
                "requires_operator_review" => true
              },
              "replacement_activity_context" => %{
                "starts_at_s" => 100.0,
                "ends_at_s" => 130.0
              },
              "required_operator_action" => "review_timeline_change"
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

    base_id = "derived_timeline_diff_changed_cmd_transition_duplicate_source"
    refute branch(artifact, base_id)

    transition_branches =
      Enum.filter(artifact["branches"], &String.starts_with?(&1["branch_id"], "#{base_id}_"))

    assert length(transition_branches) == 2

    assert Enum.any?(
             transition_branches,
             &(get_in(&1, ["events", Access.at(0), "transition_category"]) ==
                 "terminal_exception" and
                 String.contains?(&1["branch_id"], "terminal_exception"))
           )

    assert Enum.any?(
             transition_branches,
             &(get_in(&1, ["events", Access.at(0), "transition_category"]) ==
                 "policy_rejection" and
                 String.contains?(&1["branch_id"], "policy_rejection"))
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy ignores successful changed timeline diff command rows" do
    prior_plan =
      base_plan(%{
        "source_timeline_diff_report" => %{
          "schema_contract" => "timeline_diff_report.v1",
          "model" => "timeline_identity_activity_diff",
          "source" => "repair.activities",
          "row_count" => 1,
          "changed_count" => 1,
          "provenance" => %{"trust_boundary" => "ops_timeline_review"},
          "rows" => [
            %{
              "id" => "timeline_diff:timeline:cmd_success",
              "rank" => 1,
              "timeline_id" => "timeline:cmd_success",
              "diff_status" => "changed",
              "changed_fields" => ["command_result"],
              "source_activity_id" => "cmd_success_source",
              "replacement_activity_id" => "cmd_success",
              "source_activity_type" => "health_check",
              "replacement_activity_type" => "health_check",
              "scenario_id" => "leo_1",
              "source_status" => "planned",
              "replacement_activity_context" => %{"command_result" => "accepted, executed"},
              "required_operator_action" => "review_timeline_change"
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

    refute branch(artifact, "derived_timeline_diff_changed_cmd_success_source")

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives changed timeline diff command feedback from operator review rows" do
    prior_plan =
      base_plan(%{
        "activities" => [
          health_check("cmd_review_source", "leo_1", 100.0, 130.0),
          downlink("dl_1", 300.0, 360.0)
        ],
        "operator_review_package" => %{
          "schema_contract" => "operator_review_package.v1",
          "source_artifact_type" => "timeline_diff_report.v1",
          "review_count" => 1,
          "provenance" => %{"trust_boundary" => "ops_timeline_review_queue"},
          "rows" => [
            %{
              "id" => "operator_review:timeline_diff:cmd_review_changed",
              "review_type" => "timeline_diff_review",
              "source" => "timeline_diff_report.rows",
              "subject_id" => "timeline:cmd_review_changed",
              "approval_status" => "operator_review_required",
              "source_timeline_diff" => %{
                "id" => "timeline_diff:timeline:cmd_review_changed",
                "rank" => 1,
                "timeline_id" => "timeline:cmd_review_changed",
                "diff_status" => "changed",
                "changed_fields" => ["command_result", "command_success_factor"],
                "source_activity_id" => "cmd_review_source",
                "replacement_activity_id" => "cmd_review_changed",
                "source_activity_type" => "health_check",
                "replacement_activity_type" => "health_check",
                "scenario_id" => "leo_1",
                "source_status" => "planned",
                "replacement_activity_context" => %{
                  "starts_at_s" => 100.0,
                  "ends_at_s" => 130.0,
                  "command_result" => "failed"
                },
                "required_operator_action" => "review_timeline_change"
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

    branch = branch(artifact, "derived_timeline_diff_changed_cmd_review_source")

    assert %{
             "type" => "command_success_feedback",
             "activity_id" => "cmd_review_source",
             "source_activity_id" => "cmd_review_source",
             "replacement_activity_id" => "cmd_review_changed",
             "source_activity_ids" => ["cmd_review_changed", "cmd_review_source"],
             "timeline_id" => "timeline:cmd_review_changed",
             "feedback_source" => "prior_plan.operator_review_package.rows.source_timeline_diff",
             "feedback_scope" => "timeline_diff",
             "trust_boundary" => "ops_timeline_review_queue",
             "derivation_reasons" => [
               "timeline_diff_changed_activity",
               "timeline_diff_changed_command"
             ]
           } = List.first(branch["events"])

    assert List.first(branch["events"])["command_success_factor"] == 0.0
    assert branch["feedback_adjustments"]["command_success_factor"] == 0.0

    assert Enum.any?(
             branch["risk_indicators"],
             &(&1["type"] == "command_success_rate_low" and &1["value"] == 0.0)
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives changed timeline diff maneuver feedback from failed outcome rows" do
    prior_plan =
      base_plan(%{
        "activities" => [maneuver("burn_source", 100.0)],
        "source_timeline_diff_report" => %{
          "schema_contract" => "timeline_diff_report.v1",
          "model" => "timeline_identity_activity_diff",
          "source" => "repair.activities",
          "row_count" => 1,
          "changed_count" => 1,
          "provenance" => %{"trust_boundary" => "ops_timeline_review"},
          "rows" => [
            %{
              "id" => "timeline_diff:timeline:burn_changed",
              "rank" => 1,
              "timeline_id" => "timeline:burn_changed",
              "diff_status" => "changed",
              "changed_fields" => [nil, "maneuver result", "maneuver_success_factor"],
              "source_activity_id" => "burn_source",
              "replacement_activity_id" => "burn_changed",
              "source_activity_type" => "maneuver",
              "replacement_activity_type" => "maneuver",
              "scenario_id" => "leo_1",
              "source_status" => "planned",
              "replacement_activity_context" => %{
                "starts_at_s" => 100.0,
                "ends_at_s" => 100.0,
                "maneuver_result" => "accepted, failed",
                "realized_status" => "failed"
              },
              "required_operator_action" => "review_timeline_change"
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

    branch = branch(artifact, "derived_timeline_diff_changed_burn_source")

    assert %{
             "type" => "maneuver_success_feedback",
             "activity_id" => "burn_source",
             "scenario_id" => "leo_1",
             "maneuver_result" => "accepted, failed",
             "realized_status" => "failed",
             "source_activity_id" => "burn_source",
             "replacement_activity_id" => "burn_changed",
             "source_activity_ids" => ["burn_changed", "burn_source"],
             "timeline_id" => "timeline:burn_changed",
             "changed_fields" => ["maneuver_result", "maneuver_success_factor"],
             "feedback_source" => "prior_plan.source_timeline_diff_report",
             "feedback_scope" => "timeline_diff",
             "trust_boundary" => "ops_timeline_review",
             "derivation_reasons" => [
               "timeline_diff_changed_activity",
               "timeline_diff_changed_maneuver"
             ]
           } = List.first(branch["events"])

    assert List.first(branch["events"])["maneuver_success_factor"] == 0.0
    assert branch["feedback_adjustments"]["maneuver_success_factor"] == 0.0

    assert Enum.any?(
             branch["risk_indicators"],
             &(&1["type"] == "maneuver_success_rate_low" and &1["value"] == 0.0 and
                 &1["maneuver_result"] == "accepted, failed" and
                 &1["realized_status"] == "failed" and
                 &1["source_activity_ids"] == ["burn_changed", "burn_source"])
           )

    assert_execution_feedback_pressure_score_terms(branch, artifact, "maneuver_success_rate_low")

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives changed timeline diff maneuver execution uncertainty feedback" do
    prior_plan =
      base_plan(%{
        "activities" => [maneuver("burn_uncertain_source", 100.0)],
        "source_timeline_diff_report" => %{
          "schema_contract" => "timeline_diff_report.v1",
          "model" => "timeline_identity_activity_diff",
          "source" => "repair.activities",
          "row_count" => 1,
          "changed_count" => 1,
          "provenance" => %{"trust_boundary" => "ops_timeline_review"},
          "rows" => [
            %{
              "id" => "timeline_diff:timeline:burn_uncertain",
              "rank" => 1,
              "timeline_id" => "timeline:burn_uncertain",
              "diff_status" => "changed",
              "changed_fields" => ["execution_uncertainty"],
              "source_activity_id" => "burn_uncertain_source",
              "replacement_activity_id" => "burn_uncertain_replacement",
              "source_activity_type" => "maneuver",
              "replacement_activity_type" => "maneuver",
              "scenario_id" => "leo_1",
              "source_status" => "planned",
              "replacement_activity_context" => %{
                "starts_at_s" => 100.0,
                "ends_at_s" => 100.0,
                "maneuver_id" => "burn_uncertain_source",
                "execution_uncertainty" => %{
                  "timing_3sigma_s" => 90.0,
                  "delta_v_3sigma_km_s" => [0.0, 0.003, 0.004],
                  "source" => "timeline_diff_covariance"
                }
              },
              "required_operator_action" => "review_timeline_change"
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

    branch = branch(artifact, "derived_timeline_diff_changed_burn_uncertain_source")

    assert %{
             "type" => "maneuver_execution_uncertainty_feedback",
             "activity_id" => "burn_uncertain_source",
             "scenario_id" => "leo_1",
             "starts_at_s" => 100.0,
             "ends_at_s" => 100.0,
             "execution_uncertainty_status" => "declared",
             "timing_3sigma_s" => 90.0,
             "delta_v_3sigma_magnitude_km_s" => 0.005,
             "execution_uncertainty_source" => "timeline_diff_covariance",
             "source_activity_id" => "burn_uncertain_source",
             "replacement_activity_id" => "burn_uncertain_replacement",
             "source_activity_ids" => ["burn_uncertain_replacement", "burn_uncertain_source"],
             "timeline_id" => "timeline:burn_uncertain",
             "maneuver_id" => "burn_uncertain_source",
             "feedback_source" => "prior_plan.source_timeline_diff_report",
             "feedback_scope" => "timeline_diff",
             "feedback_key" => "burn_uncertain_source",
             "trust_boundary" => "ops_timeline_review",
             "derivation_reasons" => [
               "timeline_diff_changed_activity",
               "timeline_diff_changed_maneuver_uncertainty"
             ]
           } = uncertainty_event = List.first(branch["events"])

    assert uncertainty_event["delta_v_3sigma_km_s"] == [0.0, 0.003, 0.004]

    assert %{"source" => "timeline_diff_covariance"} =
             uncertainty_event["execution_uncertainty"]

    assert Enum.any?(
             branch["risk_indicators"],
             &(&1["type"] == "maneuver_execution_uncertainty_high" and
                 &1["activity_id"] == "burn_uncertain_source" and
                 &1["execution_uncertainty_source"] == "timeline_diff_covariance" and
                 &1["timing_3sigma_s"] == 90.0 and
                 &1["delta_v_3sigma_magnitude_km_s"] == 0.005 and
                 &1["feedback_source"] == "prior_plan.source_timeline_diff_report" and
                 &1["trust_boundary"] == "ops_timeline_review")
           )

    assert_execution_feedback_pressure_score_terms(
      branch,
      artifact,
      "maneuver_execution_uncertainty_high"
    )

    assert %{
             "branch_maneuver_execution_uncertainty_activity_ids" => ["burn_uncertain_source"],
             "branch_maneuver_execution_uncertainty_timeline_ids" => ["timeline:burn_uncertain"],
             "branch_maneuver_execution_uncertainty_maneuver_ids" => ["burn_uncertain_source"],
             "branch_maneuver_execution_uncertainty_statuses" => ["declared"],
             "branch_maneuver_execution_uncertainty_sources" => ["timeline_diff_covariance"],
             "branch_maneuver_execution_uncertainty_max_timing_3sigma_s" => 90.0,
             "branch_maneuver_execution_uncertainty_max_delta_v_3sigma_magnitude_km_s" => 0.005
           } =
             Enum.find(
               artifact["branch_comparison_report"]["rows"],
               &(&1["branch_id"] == "derived_timeline_diff_changed_burn_uncertain_source")
             )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives changed timeline diff maneuver missing uncertainty feedback" do
    prior_plan =
      base_plan(%{
        "activities" => [maneuver("burn_missing_source", 100.0)],
        "source_timeline_diff_report" => %{
          "schema_contract" => "timeline_diff_report.v1",
          "model" => "timeline_identity_activity_diff",
          "source" => "repair.activities",
          "row_count" => 1,
          "changed_count" => 1,
          "provenance" => %{"trust_boundary" => "ops_timeline_review"},
          "rows" => [
            %{
              "id" => "timeline_diff:timeline:burn_missing_uncertainty",
              "rank" => 1,
              "timeline_id" => "timeline:burn_missing_uncertainty",
              "diff_status" => "changed",
              "changed_fields" => ["execution_uncertainty_status"],
              "source_activity_id" => "burn_missing_source",
              "replacement_activity_id" => "burn_missing_replacement",
              "source_activity_type" => "maneuver",
              "replacement_activity_type" => "maneuver",
              "scenario_id" => "leo_1",
              "replacement_activity_context" => %{
                "starts_at_s" => 100.0,
                "ends_at_s" => 100.0,
                "maneuver_id" => "burn_missing_source",
                "execution_uncertainty_status" => "missing"
              },
              "required_operator_action" => "review_maneuver_uncertainty"
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

    branch = branch(artifact, "derived_timeline_diff_changed_burn_missing_source")

    assert %{
             "type" => "maneuver_execution_uncertainty_feedback",
             "activity_id" => "burn_missing_source",
             "scenario_id" => "leo_1",
             "execution_uncertainty_status" => "missing",
             "source_activity_id" => "burn_missing_source",
             "replacement_activity_id" => "burn_missing_replacement",
             "source_activity_ids" => ["burn_missing_replacement", "burn_missing_source"],
             "timeline_id" => "timeline:burn_missing_uncertainty",
             "maneuver_id" => "burn_missing_source",
             "required_operator_action" => "review_maneuver_uncertainty",
             "feedback_source" => "prior_plan.source_timeline_diff_report",
             "feedback_scope" => "timeline_diff",
             "feedback_key" => "burn_missing_source",
             "trust_boundary" => "ops_timeline_review"
           } = uncertainty_event = List.first(branch["events"])

    refute Map.has_key?(uncertainty_event, "execution_uncertainty")

    assert Enum.any?(
             branch["risk_indicators"],
             &(&1["type"] == "maneuver_execution_uncertainty_missing" and
                 &1["activity_id"] == "burn_missing_source" and
                 &1["timeline_id"] == "timeline:burn_missing_uncertainty" and
                 &1["feedback_source"] == "prior_plan.source_timeline_diff_report")
           )

    assert_execution_feedback_pressure_score_terms(
      branch,
      artifact,
      "maneuver_execution_uncertainty_missing"
    )

    assert %{
             "branch_maneuver_execution_uncertainty_activity_ids" => ["burn_missing_source"],
             "branch_maneuver_execution_uncertainty_timeline_ids" => [
               "timeline:burn_missing_uncertainty"
             ],
             "branch_maneuver_execution_uncertainty_maneuver_ids" => ["burn_missing_source"],
             "branch_maneuver_execution_uncertainty_statuses" => ["missing"]
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["branch_id"] == "derived_timeline_diff_changed_burn_missing_source")
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
end
