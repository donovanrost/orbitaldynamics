Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyCommandFeedbackSourceTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy derives command success feedback branch from operational feedback" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          health_check("cmd_health_1", "leo_1", 100.0, 130.0),
          downlink("dl_1", 300.0, 360.0)
        ],
        "candidate_activities" => []
      })

    artifact =
      strategy(prior_plan,
        operational_feedback: %{
          command_success_rate: %{"cmd_health_1" => 0.25}
        },
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    command_branch = branch(artifact, "derived_command_success_feedback")

    assert %{
             "type" => "command_success_feedback",
             "activity_id" => "cmd_health_1",
             "scenario_id" => "leo_1",
             "command_success_factor" => 0.25,
             "feedback_source" => "operational_feedback.command_success_rate",
             "feedback_scope" => "activity"
           } = List.first(command_branch["events"])

    assert command_branch["feedback_adjustments"]["command_success_factor"] == 0.25
    assert command_branch["score_terms"]["feedback_adjustment_score"] < 0.0

    command_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "derived_command_success_feedback"))

    assert command_row["command_success_factor"] == 0.25
    assert command_row["feedback_score_adjustment"] < 0.0
    assert "command_success_rate_low" in command_row["feedback_risk_types"]

    assert Enum.any?(
             command_branch["risk_indicators"],
             &(&1["type"] == "command_success_rate_low" and &1["value"] == 0.25 and
                 &1["activity_id"] == "cmd_health_1")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives command feedback from result-artifact planned activities" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "source_result_artifact" => %{
          "schema_contract" => "result_artifact.v1",
          "metadata" => %{"trust_boundary" => "ops_activity_result_artifact"},
          "activities" => [command("cmd_from_result", "leo_1", 100.0, 130.0)]
        }
      })

    artifact =
      strategy(prior_plan,
        operational_feedback: %{
          command_success_rate: %{"cmd_from_result" => 0.25}
        },
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    command_branch = branch(artifact, "derived_command_success_feedback")

    assert %{
             "type" => "command_success_feedback",
             "activity_id" => "cmd_from_result",
             "scenario_id" => "leo_1",
             "command_success_factor" => 0.25,
             "feedback_scope" => "activity"
           } = List.first(command_branch["events"])

    assert Enum.any?(
             command_branch["risk_indicators"],
             &(&1["type"] == "command_success_rate_low" and &1["activity_id"] == "cmd_from_result")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives command success feedback from prior command window reports" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          health_check("cmd_health_1", "leo_1", 100.0, 130.0),
          downlink("dl_1", 300.0, 360.0)
        ],
        "source_command_window_report" => %{
          "schema_contract" => "command_window_report.v1",
          "model" => "artifact_only_command_window_report",
          "source" => "campaign_repair.activities",
          "window_count" => 1,
          "command_count" => 0,
          "tracking_count" => 0,
          "uplink_count" => 0,
          "health_check_count" => 1,
          "review_required_count" => 1,
          "rows" => [
            %{
              "id" => "command_window:cmd_health_1",
              "activity_id" => "cmd_health_1",
              "activity_type" => "health_check",
              "window_type" => "health_check_window",
              "scenario_id" => "leo_1",
              "starts_at_s" => 100.0,
              "ends_at_s" => 130.0,
              "command_success_factor" => 0.25,
              "command_success_factor_source" => "provider_window_feedback",
              "confidence_weight" => "3.0",
              "confidence_weight_source" => "operator_sample_size"
            },
            %{
              "id" => "command_window:cmd_health_1_light",
              "activity_id" => "cmd_health_1",
              "activity_type" => "health_check",
              "window_type" => "health_check_window",
              "scenario_id" => "leo_1",
              "starts_at_s" => 100.0,
              "ends_at_s" => 130.0,
              "command_success_factor" => 1.0,
              "feedback_sample_weight" => "1.0"
            }
          ]
        }
      })

    artifact =
      strategy(prior_plan,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    assert get_in(artifact, ["operational_feedback", "command_success_rate"]) == %{
             "cmd_health_1" => 0.4375
           }

    assert Enum.any?(
             get_in(artifact, ["operational_feedback_provenance", "sources"]),
             &(&1["source"] == "prior_plan.command_window_report.rows" and
                 &1["source_report_contract"] == "command_window_report.v1" and
                 &1["source_report_row_count"] == 2 and
                 &1["weighted_feedback_row_count"] == 2 and
                 &1["feedback_weight_sources"] == ["operator_sample_size"])
           )

    command_branch = branch(artifact, "derived_command_success_feedback")

    assert %{
             "type" => "command_success_feedback",
             "activity_id" => "cmd_health_1",
             "command_success_factor" => 0.4375,
             "feedback_source" => "operational_feedback.command_success_rate",
             "feedback_scope" => "activity"
           } = List.first(command_branch["events"])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives command success feedback from mission-state command window reports" do
    command_window_report = %{
      "schema_contract" => "command_window_report.v1",
      "model" => "artifact_only_command_window_report",
      "source" => "cadence.live_command_window",
      "window_count" => 1,
      "health_check_count" => 1,
      "review_required_count" => 1,
      "provenance" => %{"trust_boundary" => "cadence_live_command_window"},
      "rows" => [
        %{
          "id" => "command_window:cmd_live_health",
          "activity_id" => "cmd_live_health",
          "activity_type" => "health_check",
          "window_type" => "health_check_window",
          "scenario_id" => "leo_1",
          "starts_at_s" => 100.0,
          "ends_at_s" => 130.0,
          "command_success_factor" => 0.2,
          "confidence_weight" => "2.0",
          "confidence_weight_source" => "live_command_sample"
        }
      ]
    }

    artifact =
      strategy(
        base_plan(%{
          "planning_horizon" => %{"duration_s" => 2_000.0},
          "activities" => [health_check("cmd_live_health", "leo_1", 100.0, 130.0)]
        }),
        mission_state:
          mission_state_with_refresh_inputs()
          |> Map.put(:source_command_window_report, command_window_report),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    assert get_in(artifact, ["operational_feedback", "command_success_rate"]) == %{
             "cmd_live_health" => 0.2
           }

    assert Enum.any?(
             artifact["operational_feedback_provenance"]["sources"],
             &(&1["source"] == "mission_state.command_window_report.rows" and
                 &1["source_report_paths"] == ["mission_state.source_command_window_report"] and
                 &1["source_report_contract"] == "command_window_report.v1" and
                 &1["weighted_feedback_row_count"] == 1 and
                 &1["trust_boundaries"] == ["cadence_live_command_window"])
           )

    command_branch = branch(artifact, "derived_command_success_feedback")

    assert %{
             "type" => "command_success_feedback",
             "activity_id" => "cmd_live_health",
             "command_success_factor" => 0.2,
             "feedback_source" => "operational_feedback.command_success_rate"
           } = List.first(command_branch["events"])

    assert get_in(command_branch, [
             "assumptions",
             "candidate_source",
             "source_operational_feedback_provenance",
             "derived_from_source_command_window_report"
           ])

    assert get_in(command_branch, [
             "assumptions",
             "candidate_source",
             "source_operational_feedback_provenance",
             "source_command_window_report_paths"
           ]) == ["mission_state.source_command_window_report"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives command success feedback from result artifact command window reports" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          health_check("cmd_health_1", "leo_1", 100.0, 130.0),
          downlink("dl_1", 300.0, 360.0)
        ],
        "source_result_artifact" => %{
          "schema_contract" => "result_artifact.v1",
          "metadata" => %{"trust_boundary" => "ops_command_result_artifact"},
          "command_window_report" => %{
            "schema_contract" => "command_window_report.v1",
            "model" => "artifact_only_command_window_report",
            "source" => "campaign_repair.activities",
            "window_count" => 1,
            "command_count" => 0,
            "tracking_count" => 0,
            "uplink_count" => 0,
            "health_check_count" => 1,
            "review_required_count" => 1,
            "rows" => [
              %{
                "id" => "command_window:cmd_health_1",
                "activity_id" => "cmd_health_1",
                "activity_type" => "health_check",
                "window_type" => "health_check_window",
                "scenario_id" => "leo_1",
                "starts_at_s" => 100.0,
                "ends_at_s" => 130.0,
                "command_success_factor" => 0.25,
                "command_success_factor_source" => "provider_window_feedback"
              }
            ]
          }
        }
      })

    artifact =
      strategy(prior_plan,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    assert get_in(artifact, ["operational_feedback", "command_success_rate"]) == %{
             "cmd_health_1" => 0.25
           }

    assert Enum.any?(
             get_in(artifact, ["operational_feedback_provenance", "sources"]),
             &(&1["source"] == "prior_plan.command_window_report.rows" and
                 &1["source_report_contract"] == "command_window_report.v1" and
                 &1["source_report_count"] == 1 and
                 &1["source_report_row_count"] == 1 and
                 &1["trust_boundaries"] == ["ops_command_result_artifact"] and
                 get_in(&1, [
                   "feedback_trust_boundaries",
                   "command_success_rate",
                   "cmd_health_1"
                 ]) == ["ops_command_result_artifact"])
           )

    command_branch = branch(artifact, "derived_command_success_feedback")

    assert %{
             "type" => "command_success_feedback",
             "activity_id" => "cmd_health_1",
             "command_success_factor" => 0.25,
             "feedback_source" => "operational_feedback.command_success_rate",
             "feedback_scope" => "activity",
             "trust_boundary" => "ops_command_result_artifact"
           } = List.first(command_branch["events"])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy matches command success operational feedback by timeline identity" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          health_check("cmd_health_1", "leo_1", 100.0, 130.0)
          |> Map.put("timeline_id", "timeline:cmd_health_1"),
          downlink("dl_1", 300.0, 360.0)
        ],
        "candidate_activities" => []
      })

    artifact =
      strategy(prior_plan,
        operational_feedback: %{
          command_success_rate: %{"timeline:cmd_health_1" => 0.25}
        },
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    command_branch = branch(artifact, "derived_command_success_feedback")

    assert %{
             "type" => "command_success_feedback",
             "activity_id" => "cmd_health_1",
             "command_success_factor" => 0.25,
             "feedback_scope" => "timeline",
             "feedback_key" => "timeline:cmd_health_1"
           } = List.first(command_branch["events"])

    assert command_branch["feedback_adjustments"]["command_success_factor"] == 0.25

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives command success feedback from realized command telemetry" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          health_check("cmd_health_1", "leo_1", 100.0, 130.0),
          downlink("dl_1", 300.0, 360.0)
        ],
        "candidate_activities" => []
      })

    mission_state =
      mission_state([])
      |> Map.put(:realized_activities, [
        %{id: "cmd_health_1", status: "executed", command_success: " FALSE "}
      ])

    artifact =
      strategy(prior_plan,
        mission_state: mission_state,
        branches: [%{id: "baseline"}, %{id: "command_confidence"}],
        current_epoch_s: 0.0
      )

    command_branch = branch(artifact, "command_confidence")

    assert get_in(artifact, ["operational_feedback", "command_success_rate"]) == %{
             "cmd_health_1" => 0.0
           }

    assert command_branch["feedback_adjustments"]["command_success_factor"] == 0.0

    assert Enum.any?(
             command_branch["risk_indicators"],
             &(&1["type"] == "command_success_rate_low" and &1["value"] == 0.0)
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives failed command feedback from rejected provider command result" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          health_check("cmd_upload", "leo_1", 100.0, 130.0),
          downlink("dl_1", 300.0, 360.0)
        ],
        "candidate_activities" => []
      })

    mission_state =
      mission_state([])
      |> Map.put(:realized_activities, [
        %{
          id: "cmd_upload",
          status: "completed",
          command_result: "rejected"
        }
      ])

    artifact =
      strategy(prior_plan,
        mission_state: mission_state,
        branches: [%{id: "baseline"}, %{id: "command_result_confidence"}],
        current_epoch_s: 0.0
      )

    command_branch = branch(artifact, "command_result_confidence")

    assert get_in(artifact, ["operational_feedback", "command_success_rate"]) == %{
             "cmd_upload" => 0.0
           }

    assert command_branch["feedback_adjustments"]["command_success_factor"] == 0.0

    assert Enum.any?(
             command_branch["risk_indicators"],
             &(&1["type"] == "command_success_rate_low" and &1["value"] == 0.0)
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives command feedback from provider planned activity identity" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          health_check("cmd_upload", "leo_1", 100.0, 130.0),
          downlink("dl_1", 300.0, 360.0)
        ],
        "candidate_activities" => []
      })

    mission_state =
      mission_state([])
      |> Map.put(:realized_activities, [
        %{
          id: "cadence-feedback-command-42",
          planned_activity_id: "cmd_upload",
          status: "completed",
          command_result: "rejected"
        }
      ])

    artifact =
      strategy(prior_plan,
        mission_state: mission_state,
        branches: [%{id: "baseline"}, %{id: "provider_identity_command_confidence"}],
        current_epoch_s: 0.0
      )

    command_branch = branch(artifact, "provider_identity_command_confidence")

    assert get_in(artifact, ["operational_feedback", "command_success_rate"]) == %{
             "cmd_upload" => 0.0
           }

    assert command_branch["feedback_adjustments"]["command_success_factor"] == 0.0

    assert Enum.any?(
             command_branch["risk_indicators"],
             &(&1["type"] == "command_success_rate_low" and &1["value"] == 0.0)
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives command feedback from provider-shaped health-check planned contacts" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          %{
            "id" => "health_contact",
            "type" => "planned_contact",
            "direction" => "health-check",
            "scenario_id" => "leo_1",
            "ground_station_id" => "equator_prime",
            "starts_at_s" => 100.0,
            "ends_at_s" => 130.0
          },
          downlink("dl_1", 300.0, 360.0)
        ],
        "candidate_activities" => []
      })

    mission_state =
      mission_state([])
      |> Map.put(:realized_activities, [
        %{
          id: "cadence-feedback-health-42",
          planned_activity_id: "health_contact",
          status: "completed",
          command_result: "timeout"
        }
      ])

    artifact =
      strategy(prior_plan,
        mission_state: mission_state,
        branches: [%{id: "baseline"}, %{id: "health_contact_confidence"}],
        current_epoch_s: 0.0
      )

    command_branch = branch(artifact, "health_contact_confidence")

    assert get_in(artifact, ["operational_feedback", "command_success_rate"]) == %{
             "health_contact" => 0.0
           }

    assert command_branch["feedback_adjustments"]["command_success_factor"] == 0.0

    assert Enum.any?(
             command_branch["risk_indicators"],
             &(&1["type"] == "command_success_rate_low" and &1["value"] == 0.0)
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy keys timeline-matched provider command feedback to planned activity" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          health_check("cmd_upload", "leo_1", 100.0, 130.0)
          |> Map.put("timeline_id", "timeline:cmd_upload"),
          downlink("dl_1", 300.0, 360.0)
        ],
        "candidate_activities" => []
      })

    mission_state =
      mission_state([])
      |> Map.put(:realized_activities, [
        %{
          id: "cadence-feedback-command-43",
          timeline_id: "timeline:cmd_upload",
          status: "completed",
          command_result: "rejected"
        }
      ])

    artifact =
      strategy(prior_plan,
        mission_state: mission_state,
        branches: [%{id: "baseline"}, %{id: "timeline_identity_command_confidence"}],
        current_epoch_s: 0.0
      )

    command_branch = branch(artifact, "timeline_identity_command_confidence")

    assert get_in(artifact, ["operational_feedback", "command_success_rate"]) == %{
             "cmd_upload" => 0.0
           }

    assert command_branch["feedback_adjustments"]["command_success_factor"] == 0.0

    assert Enum.any?(
             command_branch["risk_indicators"],
             &(&1["type"] == "command_success_rate_low" and &1["value"] == 0.0)
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy does not derive command success feedback branch without command activities" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [downlink("dl_1", 300.0, 360.0)],
        "candidate_activities" => []
      })

    artifact =
      strategy(prior_plan,
        operational_feedback: %{
          command_success_rate: %{"cmd_health_1" => 0.25, "default" => 0.25}
        },
        derive_branches?: true,
        branches: [%{id: "baseline"}, %{id: "operator_review"}],
        current_epoch_s: 0.0
      )

    refute branch(artifact, "derived_command_success_feedback")

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy lifts branch command-window review rows into import packages" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          command("cmd_1", "leo_1", 100.0, 130.0),
          downlink("dl_1", 300.0, 360.0)
        ],
        "candidate_activities" => []
      })

    artifact =
      strategy(prior_plan,
        branches: [%{id: "baseline"}, %{id: "command_review"}],
        current_epoch_s: 0.0
      )

    assert %{
             "command_window_count" => count,
             "rows" => review_rows
           } = artifact["operator_review_package"]

    assert count >= 1

    assert %{
             "review_type" => "command_window_review",
             "branch_id" => "command_review",
             "activity_id" => "cmd_1",
             "source_command_window" => %{"activity_id" => "cmd_1"}
           } =
             Enum.find(
               review_rows,
               &(&1["review_type"] == "command_window_review" and
                   &1["branch_id"] == "command_review")
             )

    assert %{
             "rows" => import_rows
           } = artifact["cadence_import_manifest"]

    assert %{
             "source_review_type" => "command_window_review",
             "import_action" => "review_command_window",
             "branch_id" => "command_review",
             "activity_id" => "cmd_1"
           } =
             Enum.find(
               import_rows,
               &(&1["source_review_type"] == "command_window_review" and
                   &1["branch_id"] == "command_review")
             )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  defp command(id, scenario_id, starts_at_s, ends_at_s) do
    %{
      "id" => id,
      "type" => "command",
      "scenario_id" => scenario_id,
      "starts_at_s" => starts_at_s,
      "ends_at_s" => ends_at_s,
      "duration_s" => ends_at_s - starts_at_s,
      "score" => 1.0
    }
  end
end
