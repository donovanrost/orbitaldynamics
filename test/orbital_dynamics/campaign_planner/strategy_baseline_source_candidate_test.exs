Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyBaselineSourceCandidateTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.{CampaignPlanner, Schema}
  alias OrbitalDynamics.CampaignPlanner.ReplanRequest

  test "strategy requires at least two branches" do
    assert_raise ArgumentError,
                 ~r/requires a baseline branch and at least one what-if branch/,
                 fn ->
                   strategy(base_plan(%{}), branches: [%{id: "baseline"}], current_epoch_s: 0.0)
                 end
  end

  test "strategy requires an explicit baseline branch" do
    assert_raise ArgumentError,
                 ~r/requires a baseline branch and at least one what-if branch/,
                 fn ->
                   strategy(base_plan(%{}),
                     branches: [%{id: "outage"}, %{id: "fuel"}],
                     current_epoch_s: 0.0
                   )
                 end
  end

  test "strategy rejects V2 repair artifacts without source candidate windows" do
    v2_artifact_without_candidates = %{
      "schema_version" => 2,
      "planner" => "OrbitalDynamics.CampaignPlanner.V2",
      "source_plan_id" => "campaign_plan:test",
      "activities" => [downlink("dl_1", 100.0, 160.0)]
    }

    assert_raise ArgumentError,
                 ~r/V3 strategy with a V2 repair artifact requires source_candidate_activities/,
                 fn ->
                   strategy(v2_artifact_without_candidates,
                     branches: [%{id: "baseline"}, %{id: "outage"}],
                     current_epoch_s: 0.0
                   )
                 end
  end

  test "strategy reuses source candidates carried by V2 repair artifacts" do
    source_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 1_500.0},
        "activities" => [downlink("dl_1", 100.0, 160.0)],
        "candidate_activities" => [downlink("dl_2", 700.0, 760.0)]
      })

    v2_artifact =
      CampaignPlanner.repair(%ReplanRequest{
        prior_plan: source_plan,
        realized_state: %{activities: []},
        current_epoch_s: 0.0,
        generated_at: ~U[2026-05-14 00:00:00Z]
      })

    artifact =
      strategy(v2_artifact,
        branches: [
          %{id: "baseline"},
          %{
            id: "outage",
            events: [
              %{
                type: "ground_station_outage",
                ground_station_id: "equator_prime",
                starts_at_s: 90.0,
                ends_at_s: 200.0
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
               "replacement_activity_id" => "dl_2"
             }
           ] =
             branch(artifact, "outage")["repair_result"]["deltas"]
             |> Enum.filter(&(&1["activity_id"] == "dl_1"))
  end

  test "strategy reuses V2 source candidates carried by result artifact wrappers" do
    v2_artifact = %{
      "schema_version" => 2,
      "planner" => "OrbitalDynamics.CampaignPlanner.V2",
      "plan_id" => "campaign_plan_test",
      "source_plan_id" => "campaign_plan_test",
      "activities" => [downlink("dl_1", 100.0, 160.0)],
      "source_result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "metadata" => %{"trust_boundary" => "ops_candidate_result_artifact"},
        "source_candidate_activities" => [refreshed_downlink("dl_2", 700.0, 760.0)]
      }
    }

    artifact =
      strategy(v2_artifact,
        branches: [
          %{id: "baseline"},
          %{
            id: "outage",
            events: [
              %{
                type: "ground_station_outage",
                ground_station_id: "equator_prime",
                starts_at_s: 90.0,
                ends_at_s: 200.0
              }
            ]
          }
        ],
        current_epoch_s: 0.0
      )

    outage = branch(artifact, "outage")

    assert [
             %{
               "activity_id" => "dl_1",
               "repair_action" => "moved",
               "replacement_activity_id" => "dl_2"
             }
           ] =
             outage["repair_result"]["deltas"]
             |> Enum.filter(&(&1["activity_id"] == "dl_1"))

    assert [
             %{
               "id" => "dl_2",
               "trust_boundary" => "ops_candidate_result_artifact"
             }
           ] = outage["repair_result"]["source_candidate_activities"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
