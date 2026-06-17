Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyManeuverFeedbackTelemetryTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy derives maneuver success feedback from realized maneuver telemetry" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          %{
            "id" => "burn_impulsive",
            "type" => "impulsive_burn",
            "scenario_id" => "leo_1",
            "starts_at_s" => 100.0,
            "ends_at_s" => 100.0,
            "duration_s" => 0.0,
            "score" => 0.0
          },
          downlink("dl_1", 300.0, 360.0)
        ],
        "candidate_activities" => []
      })

    mission_state =
      mission_state([])
      |> Map.put(:realized_activities, [
        %{
          id: "burn_impulsive",
          type: "impulsive_burn",
          status: "executed",
          maneuver_success: " FALSE "
        }
      ])

    artifact =
      strategy(prior_plan,
        mission_state: mission_state,
        branches: [
          %{id: "baseline"},
          %{
            id: "maneuver_confidence",
            events: [
              %{
                type: "delayed_maneuver",
                activity_id: "burn_impulsive",
                actual_starts_at_s: 140.0
              }
            ]
          }
        ],
        current_epoch_s: 0.0
      )

    maneuver_branch = branch(artifact, "maneuver_confidence")

    assert get_in(artifact, ["operational_feedback", "maneuver_success_rate"]) == %{
             "burn_impulsive" => 0.0
           }

    assert maneuver_branch["feedback_adjustments"]["maneuver_success_factor"] == 0.0

    assert Enum.any?(
             maneuver_branch["risk_indicators"],
             &(&1["type"] == "maneuver_success_rate_low" and &1["value"] == 0.0)
           )
  end

  test "strategy derives maneuver success feedback from provider maneuver result aliases" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          %{
            "id" => "burn_impulsive",
            "type" => "impulsive_burn",
            "scenario_id" => "leo_1",
            "starts_at_s" => 100.0,
            "ends_at_s" => 100.0,
            "duration_s" => 0.0,
            "score" => 0.0
          }
        ],
        "candidate_activities" => []
      })

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:realized_activities, [
        %{
          id: "burn_impulsive",
          type: "impulsive_burn",
          status: "completed",
          maneuver_result: "accepted, failed"
        }
      ])

    artifact =
      strategy(prior_plan,
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    maneuver_branch = branch(artifact, "derived_maneuver_success_feedback")

    assert get_in(artifact, ["operational_feedback", "maneuver_success_rate"]) == %{
             "burn_impulsive" => 0.0
           }

    assert %{
             "type" => "maneuver_success_feedback",
             "activity_id" => "burn_impulsive",
             "feedback_source" => "operational_feedback.maneuver_success_rate"
           } = maneuver_event = List.first(maneuver_branch["events"])

    assert maneuver_event["maneuver_success_factor"] == 0.0

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "explicit operational feedback overrides mission-state derived maneuver telemetry" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          %{
            "id" => "burn_impulsive",
            "type" => "impulsive_burn",
            "scenario_id" => "leo_1",
            "starts_at_s" => 100.0,
            "ends_at_s" => 100.0,
            "duration_s" => 0.0,
            "score" => 0.0
          },
          downlink("dl_1", 300.0, 360.0)
        ],
        "candidate_activities" => []
      })

    mission_state =
      mission_state([])
      |> Map.put(:realized_activities, [
        %{id: "burn_impulsive", type: "impulsive_burn", status: "failed"}
      ])

    artifact =
      strategy(prior_plan,
        mission_state: mission_state,
        operational_feedback: %{
          maneuver_success_rate: %{"burn_impulsive" => 0.5}
        },
        branches: [
          %{id: "baseline"},
          %{
            id: "maneuver_confidence",
            events: [
              %{
                type: "delayed_maneuver",
                activity_id: "burn_impulsive",
                actual_starts_at_s: 140.0
              }
            ]
          }
        ],
        current_epoch_s: 0.0
      )

    maneuver_branch = branch(artifact, "maneuver_confidence")

    assert get_in(artifact, ["operational_feedback", "maneuver_success_rate"]) == %{
             "burn_impulsive" => 0.5
           }

    assert maneuver_branch["feedback_adjustments"]["maneuver_success_factor"] == 0.5
  end
end
