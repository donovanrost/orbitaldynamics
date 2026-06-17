Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyTargetRevisitGuardRefreshTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy does not infer realized observation targets from duplicate planned activity ids" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:realized_activities, [
        %{id: "duplicate_activity", status: "missed"}
      ])

    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 600.0, "output_step_s" => 60.0},
        "activities" => [
          downlink("duplicate_activity", 100.0, 160.0),
          observe("duplicate_activity", "leo_1", "target_a", 500.0, 560.0, 10.0)
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}, %{id: "manual_review", events: [%{type: "operator_note"}]}],
        current_epoch_s: 0.0
      )

    refute branch(artifact, "derived_target_revisit_target_a")

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy does not derive revisit refresh for completed observation feedback" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:realized_activities, [
        %{id: "target_a_late", status: "completed"}
      ])

    artifact =
      strategy(
        base_plan(%{
          "activities" => [observe("target_a_late", "leo_1", "target_a", 500.0, 560.0, 10.0)]
        }),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    refute branch(artifact, "derived_target_revisit_target_a")
  end
end
