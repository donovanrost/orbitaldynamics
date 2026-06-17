Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyUrgentTargetTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.CampaignPlanner
  alias OrbitalDynamics.Schema

  test "strategy stages urgent target insertion with approval boundary" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [observe("obs_1", "leo_1", "target_a", 100.0, 160.0, 100.0)],
        "candidate_activities" => []
      })

    artifact =
      strategy(prior_plan,
        branches: [
          %{id: "baseline"},
          %{
            id: "urgent",
            events: [
              %{
                type: "urgent_target",
                target_id: "target_hot",
                scenario_id: "leo_1",
                starts_at_s: 300.0,
                ends_at_s: 360.0,
                priority: 20.0
              }
            ]
          }
        ],
        current_epoch_s: 0.0
      )

    urgent = branch(artifact, "urgent")

    assert [
             %{
               "target_id" => "target_hot",
               "repair" => %{"action" => "strategic_addition"}
             }
           ] = urgent["candidate_plan"]["strategic_additions"]

    assert Enum.any?(
             urgent["approval_requirements"],
             &(&1["action"] == "approve_strategic_addition" and
                 &1["requirement_type"] == "strategic_addition")
           )
  end

  test "strategy accepts atom-keyed remaining horizons before urgent target checks" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [observe("obs_1", "leo_1", "target_a", 100.0, 160.0, 100.0)],
        "candidate_activities" => []
      })

    artifact =
      strategy(prior_plan,
        remaining_horizon: %{starts_at_s: 0.0, ends_at_s: 1_000.0},
        branches: [
          %{id: "baseline"},
          %{
            id: "urgent",
            events: [
              %{
                type: "urgent_target",
                target_id: "target_hot",
                scenario_id: "leo_1",
                starts_at_s: 300.0,
                ends_at_s: 360.0,
                priority: 20.0
              }
            ]
          }
        ],
        current_epoch_s: 0.0
      )

    assert [%{"target_id" => "target_hot"}] =
             branch(artifact, "urgent")["candidate_plan"]["strategic_additions"]
  end

  test "strategy falls back to mission-state remaining horizon when request omits one" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [observe("obs_1", "leo_1", "target_a", 100.0, 160.0, 100.0)],
        "candidate_activities" => []
      })

    artifact =
      CampaignPlanner.strategy(%{
        prior_plan: prior_plan,
        mission_state:
          mission_state_with_refresh_inputs()
          |> Map.put(:remaining_horizon, %{starts_at_s: 0.0, ends_at_s: 250.0}),
        branches: [
          %{id: "baseline"},
          %{
            id: "urgent_outside_snapshot_horizon",
            events: [
              %{
                type: "urgent_target",
                target_id: "target_hot",
                scenario_id: "leo_1",
                starts_at_s: 300.0,
                ends_at_s: 360.0,
                priority: 20.0
              }
            ]
          }
        ],
        current_epoch_s: 0.0,
        generated_at: ~U[2026-05-14 00:00:00Z]
      })

    assert get_in(artifact, ["mission_state_snapshot", "remaining_horizon"]) == %{
             "starts_at_s" => 0.0,
             "ends_at_s" => 250.0
           }

    assert branch(artifact, "urgent_outside_snapshot_horizon")
           |> get_in(["repair_result", "source_candidate_activities"])
           |> Enum.all?(&(&1["ends_at_s"] <= 250.0))

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy normalizes numeric-string target objective branch fields" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [],
        "candidate_activities" => []
      })

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:targets, [])
      |> Map.put(:objectives, [
        %{
          type: "target_observation",
          target_id: "target_string",
          priority: "12.0",
          required_observations: "2"
        }
      ])

    artifact =
      strategy(prior_plan,
        mission_state: mission_state,
        branch_generation_policy: %{urgent_priority_threshold: "10.0"},
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    target_branch = branch(artifact, "derived_target_observation_target_string")

    assert %{
             "type" => "urgent_target",
             "target_id" => "target_string",
             "priority" => 12.0,
             "required_observations" => 2,
             "planned_observations" => 0
           } = List.first(target_branch["events"])

    assert "urgent target target_string missing 2 observation(s): staged as unvalidated placeholder" in target_branch[
             "warnings"
           ]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy urgent target chooses a real candidate window when available" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [observe("obs_1", "leo_1", "target_a", 100.0, 160.0, 100.0)],
        "candidate_activities" => [
          observe("hot_early", "leo_1", "target_hot", 300.0, 360.0, 200.0)
          |> Map.put("score", "80.0"),
          observe("hot_late", "leo_2", "target_hot", 600.0, 660.0, 150.0)
          |> Map.put("score", "300.0")
        ]
      })

    artifact =
      strategy(prior_plan,
        branches: [
          %{id: "baseline"},
          %{
            id: "urgent",
            events: [%{type: "urgent_target", target_id: "target_hot", priority: "12.0"}]
          }
        ],
        current_epoch_s: 0.0
      )

    assert [
             %{
               "id" => "urgent_urgent_observe_target_hot",
               "starts_at_s" => 600.0,
               "feasibility" => %{
                 "status" => "validated_candidate_window",
                 "selected_scenario_id" => "leo_2"
               }
             }
           ] = branch(artifact, "urgent")["candidate_plan"]["strategic_additions"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy target revisit objective stages multiple validated observation windows" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [],
        "candidate_activities" => [
          observe("revisit_early", "leo_1", "target_a", 300.0, 360.0, 120.0),
          observe("revisit_late", "leo_2", "target_a", 700.0, 760.0, 110.0),
          observe("other_target", "leo_1", "target_b", 800.0, 860.0, 100.0)
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([
            %{
              "type" => "target_revisit",
              "target_id" => "target_a",
              "required_observations" => 2,
              "priority" => 8.0
            }
          ]),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    revisit = branch(artifact, "derived_target_revisit_target_a")

    assert [
             %{
               "id" => "derived_target_revisit_target_a_urgent_observe_target_a_1",
               "starts_at_s" => 300.0,
               "feasibility" => %{
                 "status" => "validated_candidate_window",
                 "required_observations" => 2,
                 "planned_observations" => 0,
                 "staged_observation_index" => 1
               }
             },
             %{
               "id" => "derived_target_revisit_target_a_urgent_observe_target_a_2",
               "starts_at_s" => 700.0,
               "feasibility" => %{
                 "status" => "validated_candidate_window",
                 "required_observations" => 2,
                 "planned_observations" => 0,
                 "staged_observation_index" => 2
               }
             }
           ] = revisit["candidate_plan"]["strategic_additions"]

    assert revisit["objective_satisfaction"]["revisit"]["revisit_count"] == 1

    assert Enum.all?(
             revisit["approval_requirements"],
             &(&1["requirement_type"] == "strategic_addition")
           )
  end

  test "strategy target revisit objective uses placeholder only for unmet observation count" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [],
        "candidate_activities" => [
          observe("revisit_early", "leo_1", "target_a", 300.0, 360.0, 120.0)
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([
            %{
              "type" => "target_revisit",
              "target_id" => "target_a",
              "required_observations" => 2,
              "priority" => 8.0
            }
          ]),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    revisit = branch(artifact, "derived_target_revisit_target_a")

    assert [
             %{"feasibility" => %{"status" => "validated_candidate_window"}},
             %{
               "id" => "derived_target_revisit_target_a_urgent_observe_target_a_2",
               "feasibility" => %{
                 "status" => "unvalidated_placeholder",
                 "required_observations" => 2,
                 "planned_observations" => 0,
                 "staged_observation_index" => 2
               }
             }
           ] = revisit["candidate_plan"]["strategic_additions"]

    assert Enum.any?(
             revisit["warnings"],
             &String.contains?(&1, "missing 1 observation(s): staged as unvalidated placeholder")
           )

    assert Enum.any?(revisit["risk_indicators"], &(&1["type"] == "urgent_target_unvalidated"))
  end

  test "strategy urgent target placeholder is unvalidated and approval-required without a candidate window" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [observe("obs_1", "leo_1", "target_a", 100.0, 160.0, 100.0)],
        "candidate_activities" => []
      })

    artifact =
      strategy(prior_plan,
        branches: [
          %{id: "baseline"},
          %{
            id: "urgent",
            events: [
              %{
                type: "urgent_target",
                target_id: "target_missing",
                starts_at_s: 400.0,
                ends_at_s: 460.0,
                priority: 12.0
              }
            ]
          }
        ],
        current_epoch_s: 0.0
      )

    urgent = branch(artifact, "urgent")

    assert [
             %{
               "feasibility" => %{"status" => "unvalidated_placeholder"},
               "repair" => %{"requires_approval" => true}
             }
           ] = urgent["candidate_plan"]["strategic_additions"]

    assert Enum.any?(urgent["warnings"], &String.contains?(&1, "unvalidated placeholder"))
    assert Enum.any?(urgent["risk_indicators"], &(&1["type"] == "urgent_target_unvalidated"))
  end

  test "strategy normalizes string false for explicit urgent target placeholders" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [],
        "candidate_activities" => []
      })

    artifact =
      strategy(prior_plan,
        branches: [
          %{id: "baseline"},
          %{
            id: "urgent",
            events: [
              %{
                type: "urgent_target",
                target_id: "target_missing",
                starts_at_s: 400.0,
                ends_at_s: 460.0,
                priority: 12.0,
                allow_placeholder: " FALSE "
              }
            ]
          }
        ],
        current_epoch_s: 0.0
      )

    urgent = branch(artifact, "urgent")

    assert %{"allow_placeholder" => false} = List.first(urgent["events"])
    assert urgent["candidate_plan"]["strategic_additions"] == []

    assert "urgent target target_missing missing 1 observation(s): not staged: no_validated_candidate_window" in urgent[
             "warnings"
           ]

    refute Enum.any?(urgent["risk_indicators"], &(&1["type"] == "urgent_target_unvalidated"))

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy normalizes string false for generated urgent placeholder policy" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [],
        "candidate_activities" => []
      })

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:objectives, [
        %{
          type: "urgent_target",
          target_id: "target_missing",
          priority: 12.0
        }
      ])

    artifact =
      strategy(prior_plan,
        mission_state: mission_state,
        branch_generation_policy: %{allow_urgent_placeholder: " FALSE "},
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    urgent = branch(artifact, "derived_urgent_target_target_missing")

    assert %{"allow_placeholder" => false} = List.first(urgent["events"])
    assert urgent["candidate_plan"]["strategic_additions"] == []

    assert "urgent target target_missing missing 1 observation(s): not staged: no_validated_candidate_window" in urgent[
             "warnings"
           ]

    refute Enum.any?(urgent["risk_indicators"], &(&1["type"] == "urgent_target_unvalidated"))

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy stages urgent targets from branch-generated refresh candidates" do
    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state_with_refresh_inputs(),
        branches: [
          %{id: "baseline"},
          %{
            id: "urgent",
            events: [%{type: "urgent_target", target_id: "target_a", priority: 12.0}]
          }
        ],
        current_epoch_s: 0.0
      )

    urgent = branch(artifact, "urgent")

    assert [
             %{
               "id" => "urgent_urgent_observe_target_a",
               "target_id" => "target_a",
               "feasibility" => %{
                 "status" => "validated_candidate_window",
                 "source_window" => %{
                   "type" => "target_visibility"
                 }
               }
             }
           ] = urgent["candidate_plan"]["strategic_additions"]

    refute Enum.any?(urgent["warnings"], &String.contains?(&1, "unvalidated placeholder"))
    refute Enum.any?(urgent["risk_indicators"], &(&1["type"] == "urgent_target_unvalidated"))
  end
end
