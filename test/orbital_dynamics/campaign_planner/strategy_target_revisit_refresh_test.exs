Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyTargetRevisitRefreshTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy derives branch refresh for unmet target revisit objectives" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:objectives, [
        %{
          type: "target_revisit",
          target_id: "target_a",
          required_observations: 2,
          priority: 4.0
        }
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
             "planned_observations" => 1,
             "required_observations" => 2
           } = List.first(revisit["events"])

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             revisit["assumptions"]["candidate_source"]

    assert Enum.any?(
             revisit["candidate_plan"]["strategic_additions"],
             &(&1["type"] == "observe" and
                 &1["target_id"] == "target_a" and
                 get_in(&1, ["repair", "reason"]) == "target_revisit_candidate_inserted")
           )
  end

  test "strategy normalizes provider-style mission-state objective type aliases" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:objectives, [
        %{
          objective: "Target Revisit",
          id: "provider_revisit_alias",
          target_id: "target_a",
          required_revisits: "2",
          priority: "4.0",
          candidate_windows: [
            %{
              id: "provider_revisit_window",
              scenario_id: "leo_1",
              starts_at_s: 300.0,
              ends_at_s: 360.0
            }
          ]
        }
      ])

    prior_plan =
      base_plan(%{
        "activities" => [observe("target_a_existing", "leo_1", "target_a", 100.0, 160.0, 10.0)]
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
             "objective_id" => "provider_revisit_alias",
             "objective_type" => "target_revisit",
             "target_id" => "target_a",
             "priority" => 4.0,
             "planned_observations" => 1,
             "required_observations" => 2
           } = List.first(revisit["events"])

    assert Enum.any?(
             revisit["candidate_plan"]["strategic_additions"],
             &(&1["type"] == "observe" and
                 &1["target_id"] == "target_a" and
                 get_in(&1, ["repair", "reason"]) == "target_revisit_candidate_inserted")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy preserves target observation objective semantics in branch refresh" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:objectives, [
        %{
          type: "target_observation",
          id: "observe_target_a",
          target_id: "target_a",
          required_observations: 1,
          priority: 4.0
        }
      ])

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    refute branch(artifact, "derived_target_revisit_target_a")

    observation = branch(artifact, "derived_target_observation_target_a")

    assert %{
             "type" => "urgent_target",
             "objective_id" => "observe_target_a",
             "objective_type" => "target_observation",
             "target_id" => "target_a",
             "required_observations" => 1
           } = List.first(observation["events"])

    assert observation["label"] == "Derived target observation target_a"

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             observation["assumptions"]["candidate_source"]

    assert Enum.any?(
             observation["candidate_plan"]["strategic_additions"],
             &(&1["type"] == "observe" and
                 &1["target_id"] == "target_a" and
                 get_in(&1, ["repair", "reason"]) == "target_observation_candidate_inserted")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy target revisit objectives honor inline target selector lists" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:targets, [])
      |> Map.put(:objectives, [
        %{
          type: "target_revisit",
          id: "revisit_inline",
          target_ids: [],
          targets: [
            %{
              id: "target_inline",
              latitude_deg: 12.0,
              longitude_deg: 34.0,
              minimum_elevation_deg: 15.0,
              priority: 6.0
            }
          ],
          required_observations: 1
        }
      ])

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    refute branch(artifact, "derived_target_revisit_revisit_inline")

    revisit = branch(artifact, "derived_target_revisit_target_inline")

    assert %{
             "objective_type" => "target_revisit",
             "target_id" => "target_inline",
             "latitude_deg" => 12.0,
             "longitude_deg" => 34.0,
             "minimum_elevation_deg" => 15.0,
             "priority" => 6.0
           } = List.first(revisit["events"])

    assert Enum.any?(
             revisit["candidate_plan"]["strategic_additions"],
             &(&1["type"] == "observe" and
                 &1["target_id"] == "target_inline" and
                 get_in(&1, ["repair", "reason"]) == "target_revisit_candidate_inserted")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy disambiguates multiple target objectives for the same target" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:objectives, [
        %{
          type: "target_revisit",
          id: "revisit_morning",
          target_id: "target_a",
          starts_at_s: 300.0,
          ends_at_s: 420.0,
          required_observations: 1
        },
        %{
          type: "target_revisit",
          id: "revisit_evening",
          target_id: "target_a",
          starts_at_s: 500.0,
          ends_at_s: 620.0,
          required_observations: 1
        }
      ])

    prior_plan =
      base_plan(%{
        "candidate_activities" => [
          observe("obs_morning", "leo_1", "target_a", 320.0, 380.0, 10.0),
          observe("obs_evening", "leo_1", "target_a", 520.0, 580.0, 10.0)
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    refute branch(artifact, "derived_target_revisit_target_a")

    morning = branch(artifact, "derived_target_revisit_target_a_revisit_morning")
    evening = branch(artifact, "derived_target_revisit_target_a_revisit_evening")

    assert %{
             "target_branch_base_id" => "derived_target_revisit_target_a",
             "target_branch_identity" => "revisit_morning"
           } = morning["provenance"]["branch_metadata"]

    assert %{"objective_id" => "revisit_morning", "starts_at_s" => 300.0} =
             List.first(morning["events"])

    assert [
             %{
               "id" => "derived_target_revisit_target_a_revisit_morning_urgent_observe_target_a",
               "starts_at_s" => 320.0,
               "repair" => %{"reason" => "target_revisit_candidate_inserted"}
             }
           ] = morning["candidate_plan"]["strategic_additions"]

    assert %{
             "target_branch_base_id" => "derived_target_revisit_target_a",
             "target_branch_identity" => "revisit_evening"
           } = evening["provenance"]["branch_metadata"]

    assert [
             %{
               "id" => "derived_target_revisit_target_a_revisit_evening_urgent_observe_target_a",
               "starts_at_s" => 520.0,
               "repair" => %{"reason" => "target_revisit_candidate_inserted"}
             }
           ] = evening["candidate_plan"]["strategic_additions"]

    morning_comparison =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "derived_target_revisit_target_a_revisit_morning"))

    assert %{
             "target_branch_base_id" => "derived_target_revisit_target_a",
             "target_branch_identity" => "revisit_morning"
           } = morning_comparison

    assert %{
             "target_branch_base_id" => "derived_target_revisit_target_a",
             "target_branch_identity" => "revisit_morning"
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["review_type"] == "strategy_tradeoff" and
                   &1["branch_id"] == "derived_target_revisit_target_a_revisit_morning")
             )

    assert %{
             "target_branch_base_id" => "derived_target_revisit_target_a",
             "target_branch_identity" => "revisit_morning"
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["branch_id"] == "derived_target_revisit_target_a_revisit_morning" and
                   &1["import_action"] in [
                     "review_strategy_branch_alternative",
                     "review_strategy_tradeoff",
                     "import_strategy_recommendation"
                   ])
             )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
