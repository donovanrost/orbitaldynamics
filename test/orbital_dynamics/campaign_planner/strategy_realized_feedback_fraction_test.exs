Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyRealizedFeedbackFractionTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy uses partial completed fraction for command and maneuver feedback" do
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
          health_check("cmd_health_1", "leo_1", 140.0, 170.0),
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
          status: "partial",
          completed_fraction: 0.2
        },
        %{id: "cmd_health_1", status: "partial", completed_fraction: 0.4}
      ])

    artifact =
      strategy(prior_plan,
        mission_state: mission_state,
        branches: [%{id: "baseline"}, %{id: "ops_confidence"}],
        current_epoch_s: 0.0
      )

    ops_confidence = branch(artifact, "ops_confidence")

    assert get_in(artifact, ["operational_feedback", "maneuver_success_rate"]) == %{
             "burn_impulsive" => 0.2
           }

    assert get_in(artifact, ["operational_feedback", "command_success_rate"]) == %{
             "cmd_health_1" => 0.4
           }

    assert ops_confidence["feedback_adjustments"]["maneuver_success_factor"] == 0.2
    assert ops_confidence["feedback_adjustments"]["command_success_factor"] == 0.4
    assert ops_confidence["score_terms"]["feedback_adjustment_score"] < 0.0

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy uses completed fraction on completed realized feedback before assuming full success" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          observe("obs_fraction", "leo_1", "target_a", 100.0, 160.0, 100.0),
          downlink("dl_fraction", 300.0, 360.0),
          %{
            "id" => "burn_fraction",
            "type" => "impulsive_burn",
            "scenario_id" => "leo_1",
            "starts_at_s" => 500.0,
            "ends_at_s" => 500.0,
            "duration_s" => 0.0,
            "score" => 0.0
          },
          health_check("cmd_fraction", "leo_1", 600.0, 630.0)
        ],
        "candidate_activities" => []
      })

    mission_state =
      mission_state([])
      |> Map.put(:realized_activities, [
        %{id: "obs_fraction", status: "completed", completed_fraction: 0.25},
        %{id: "dl_fraction", status: "completed", completed_fraction: 0.3},
        %{id: "burn_fraction", status: "completed", completed_fraction: 0.2},
        %{id: "cmd_fraction", status: "completed", completed_fraction: 0.4}
      ])

    artifact =
      strategy(prior_plan,
        mission_state: mission_state,
        branches: [%{id: "baseline"}, %{id: "ops_fraction"}],
        current_epoch_s: 0.0
      )

    ops_fraction = branch(artifact, "ops_fraction")

    assert get_in(artifact, ["operational_feedback", "observation_success_rate"]) == %{
             "target_a" => 0.25
           }

    assert get_in(artifact, ["operational_feedback", "contact_success_rate"]) == %{
             "equator_prime" => 0.3
           }

    assert get_in(artifact, ["operational_feedback", "maneuver_success_rate"]) == %{
             "burn_fraction" => 0.2
           }

    assert get_in(artifact, ["operational_feedback", "command_success_rate"]) == %{
             "cmd_fraction" => 0.4
           }

    assert ops_fraction["feedback_adjustments"]["observation_success_factor"] == 0.25
    assert ops_fraction["feedback_adjustments"]["contact_success_factor"] == 0.3
    assert ops_fraction["feedback_adjustments"]["maneuver_success_factor"] == 0.2
    assert ops_fraction["feedback_adjustments"]["command_success_factor"] == 0.4
    assert ops_fraction["score_terms"]["feedback_adjustment_score"] < 0.0

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
