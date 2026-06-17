Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyBranchDerivationTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.CampaignPlanner

  test "strategy derives deterministic mission-state branches and merges explicit branches without duplicates" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          observe("obs_1", "leo_1", "target_a", 100.0, 160.0, 100.0),
          downlink("dl_1", 200.0, 260.0)
        ],
        "candidate_activities" => [
          observe("hot_window", "leo_2", "target_hot", 500.0, 560.0, 300.0),
          downlink("dl_2", 700.0, 760.0)
        ]
      })

    state = %{
      snapshot_id: "ops-derived",
      spacecraft_states: [
        %{scenario_id: :leo_1, mode: :degraded, incompatible_activity_types: :observe}
      ],
      ground_network: [
        %{
          ground_station_id: "equator_prime",
          status: "unavailable",
          starts_at_s: 190.0,
          ends_at_s: 300.0
        }
      ],
      resources: %{fuel_margin: 0.1, downlink_margin: 0.5},
      objectives: [
        %{type: "urgent_target", target_id: "target_hot", priority: 20.0},
        %{type: "downlink_completion", required_contacts: 2}
      ]
    }

    request = [
      mission_state: state,
      derive_branches?: true,
      branches: [
        %{id: "baseline", label: "Caller baseline"},
        %{id: "derived_fuel_preservation", label: "Caller fuel branch wins"}
      ],
      current_epoch_s: 0.0,
      generated_at: ~U[2026-05-14 12:00:00Z]
    ]

    left = strategy(prior_plan, request)
    right = strategy(prior_plan, request)
    branch_ids = Enum.map(left["branches"], & &1["branch_id"])

    assert left == right
    assert Enum.frequencies(branch_ids)["baseline"] == 1
    assert Enum.frequencies(branch_ids)["derived_fuel_preservation"] == 1
    assert "derived_degraded_leo_1" in branch_ids
    assert "derived_station_outage_equator_prime" in branch_ids
    assert "derived_urgent_target_target_hot" in branch_ids
    assert "derived_downlink_constrained" in branch_ids

    degraded = branch(left, "derived_degraded_leo_1")
    assert degraded["derived_source"] == "mission_state.spacecraft_states"

    assert [
             %{
               "scenario_id" => "leo_1",
               "incompatible_activity_types" => ["observe"]
             }
           ] = degraded["events"]

    assert Enum.any?(degraded["repair_result"]["deltas"], &(&1["repair_action"] == "suppressed"))
  end

  test "strategy preserves explicit false branch derivation flags over alias booleans" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          downlink("dl_1", 200.0, 260.0)
        ],
        "candidate_activities" => [
          downlink("dl_2", 700.0, 760.0)
        ]
      })

    request = %{
      :prior_plan => prior_plan,
      :mission_state =>
        mission_state([
          %{"type" => "downlink_completion", "required_contacts" => 2}
        ]),
      :derive_branches? => false,
      "derive_branches?" => true,
      :branches => [%{id: "baseline"}, %{id: "same_plan", events: []}],
      :current_epoch_s => 0.0,
      :remaining_horizon => %{"starts_at_s" => 0.0, "ends_at_s" => 2_000.0},
      :generated_at => ~U[2026-05-14 00:00:00Z]
    }

    artifact = CampaignPlanner.strategy(request)

    assert Enum.map(artifact["branches"], & &1["branch_id"]) == ["baseline", "same_plan"]
  end
end
