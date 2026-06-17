Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyTargetRevisitFeedbackRefreshTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy skips target revisit branches when planned observations satisfy the objective" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:objectives, [
        %{
          type: "target_revisit",
          target_id: "target_a",
          required_observations: 1,
          priority: 4.0
        }
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

  test "strategy derives branch refresh when realized feedback misses a planned observation" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:realized_activities, [
        %{id: "target_a_late", status: "missed", priority: "4.0"}
      ])

    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 600.0, "output_step_s" => 60.0},
        "activities" => [observe("target_a_late", "leo_1", "target_a", 500.0, 560.0, 10.0)]
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    revisit = branch(artifact, "derived_target_revisit_target_a")

    assert %{
             "type" => "urgent_target",
             "objective_type" => "target_revisit",
             "priority" => 4.0,
             "planned_observations" => 0,
             "required_observations" => 1,
             "source_activity_id" => "target_a_late",
             "realized_status" => "missed",
             "derivation_reason" => "realized_observation_missed"
           } = List.first(revisit["events"])

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             revisit["assumptions"]["candidate_source"]

    assert Enum.any?(
             revisit["candidate_plan"]["strategic_additions"],
             &(&1["type"] == "observe" and &1["target_id"] == "target_a")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy target revisit keeps repeated realized observation source IDs stable" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:realized_activities, [
        %{id: "target_a_late_b", status: "failed"},
        %{id: "target_a_late_a", status: "missed"}
      ])

    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 600.0, "output_step_s" => 60.0},
        "activities" => [
          observe("target_a_late_a", "leo_1", "target_a", 420.0, 480.0, 10.0),
          observe("target_a_late_b", "leo_1", "target_a", 500.0, 560.0, 10.0)
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    revisit = branch(artifact, "derived_target_revisit_target_a")

    assert %{
             "type" => "urgent_target",
             "objective_type" => "target_revisit",
             "source_activity_id" => "target_a_late_a",
             "source_activity_ids" => ["target_a_late_a", "target_a_late_b"]
           } = List.first(revisit["events"])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch refresh when provider rejects a planned observation" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:realized_activities, [
        %{id: "target_a_late", status: "rejected"}
      ])

    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 600.0, "output_step_s" => 60.0},
        "activities" => [observe("target_a_late", "leo_1", "target_a", 500.0, 560.0, 10.0)]
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    revisit = branch(artifact, "derived_target_revisit_target_a")

    assert %{
             "type" => "urgent_target",
             "source_activity_id" => "target_a_late",
             "realized_status" => "rejected",
             "derivation_reason" => "realized_observation_rejected"
           } = List.first(revisit["events"])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch refresh when direct realized status records observation failure" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:realized_activities, [
        %{id: "target_a_late", status: "matched", realized_status: "failed"}
      ])

    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 600.0, "output_step_s" => 60.0},
        "activities" => [observe("target_a_late", "leo_1", "target_a", 500.0, 560.0, 10.0)]
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    revisit = branch(artifact, "derived_target_revisit_target_a")

    assert [
             %{
               "id" => "target_a_late",
               "status" => "failed",
               "feedback_status" => "matched",
               "realized_status" => "failed"
             }
           ] = get_in(artifact, ["mission_state_snapshot", "realized_activities"])

    assert %{
             "type" => "urgent_target",
             "source_activity_id" => "target_a_late",
             "realized_status" => "failed",
             "derivation_reason" => "realized_observation_failed"
           } = List.first(revisit["events"])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
