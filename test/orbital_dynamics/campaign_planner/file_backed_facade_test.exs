Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.FileBackedFacadeTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.{CampaignPlanner, Epoch, ResultSet, Schema}
  alias OrbitalDynamics.CampaignPlanner.ReplanRequest

  test "strategy accepts ISO generated_at strings from JSON requests" do
    artifact =
      strategy(base_plan(%{}),
        branches: [%{id: "baseline"}, %{id: "outage"}],
        current_epoch_s: 0.0,
        generated_at: "2026-05-14T20:23:00Z"
      )

    assert artifact["generated_at"] == "2026-05-14T20:23:00Z"
  end

  test "repair accepts checked-in JSON request with source plan reference" do
    artifact =
      OrbitalDynamics.campaign_repair_from_file!(
        "studies/leo_constellation_campaign_repair_v2.json"
      )

    assert artifact["schema_version"] == 2

    assert artifact["source_plan_id"] ==
             "campaign_plan:leo_constellation_campaign:2026-05-14T00:00:00Z"

    assert {:ok, %{"schema_contract" => "campaign_repair.v2", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy accepts checked-in JSON request with embedded branch candidate refresh" do
    artifact =
      OrbitalDynamics.campaign_strategy_from_file!(
        "studies/leo_constellation_campaign_strategy_v3.json"
      )

    assert %{
             "branch_id" => "operator_station_outage",
             "assumptions" => %{
               "candidate_source" => %{
                 "type" => "candidate_refresh.v1",
                 "refresh_id" => "candidate_refresh:operator_station_outage:2026-05-14T00:00:00Z"
               }
             },
             "repair_result" => %{
               "source_candidate_activities" => [
                 %{
                   "id" => "branch_refresh_observe_target_a_late_1",
                   "target_id" => "target_a",
                   "source_window_id" => "window:leo_1:target_visibility:target_a_late:1"
                 }
               ]
             }
           } = branch(artifact, "operator_station_outage")

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "file-backed strategy requests require a resolvable source plan reference" do
    path =
      Path.join(
        System.tmp_dir!(),
        "orbital_dynamics_bad_strategy_request_#{System.unique_integer([:positive])}.json"
      )

    File.write!(
      path,
      :json.encode(%{
        "source_plan_ref" => %{"path" => "missing/source_plan.json"},
        "branches" => [%{"id" => "baseline"}],
        "current_epoch_s" => 0.0,
        "remaining_horizon" => %{"starts_at_s" => 0.0, "ends_at_s" => 600.0}
      })
    )

    assert_raise ArgumentError, ~r/source_plan_ref.path does not exist/, fn ->
      CampaignPlanner.strategy_from_file!(path)
    end

    File.rm(path)
  end

  test "strategy rejects invalid branch candidate refresh artifacts" do
    prior_plan =
      base_plan(%{
        "activities" => [downlink("dl_1", 100.0, 160.0)],
        "candidate_activities" => [downlink("dl_stale", 700.0, 760.0)]
      })

    assert_raise ArgumentError, ~r/invalid candidate_refresh.v1 artifact/, fn ->
      strategy(prior_plan,
        branches: [
          %{id: "baseline"},
          %{id: "outage", candidate_refresh: %{"artifact_type" => "candidate_refresh"}}
        ],
        current_epoch_s: 0.0
      )
    end
  end

  test "strategy rejects invalid branch candidate refresh requests" do
    prior_plan =
      base_plan(%{
        "activities" => [downlink("dl_1", 100.0, 160.0)],
        "candidate_activities" => [downlink("dl_stale", 700.0, 760.0)]
      })

    assert_raise ArgumentError, ~r/invalid branch candidate_refresh_request/, fn ->
      strategy(prior_plan,
        branches: [
          %{id: "baseline"},
          %{id: "outage", candidate_refresh_request: %{"remaining_horizon" => %{}}}
        ],
        current_epoch_s: 0.0
      )
    end
  end

  test "public facades expose V1 V2 and V3 campaign planner entry points" do
    campaign = %{
      "targets" => [%{"id" => "target_a", "priority" => 2.0}],
      "constraints" => %{},
      "scoring_policy" => %{"target_value_weight" => 1.0, "contact_value_weight" => 0.1}
    }

    result_set =
      campaign_result_set([
        target_visibility_result(:leo_1, :target_a, 50.0, 110.0, 2.0),
        access_result(:leo_1, :equator_prime, 100.0, 170.0)
      ])

    plan_opts = [generated_at: ~U[2026-05-14 00:00:00Z], campaign: campaign]

    assert OrbitalDynamics.campaign_plan(result_set, plan_opts) ==
             CampaignPlanner.build(result_set, plan_opts)

    repair_request = %ReplanRequest{
      prior_plan:
        base_plan(%{
          "activities" => [downlink("dl_1", 100.0, 160.0)],
          "candidate_activities" => [downlink("dl_2", 700.0, 760.0)]
        }),
      realized_state: %{activities: [%{id: "dl_1", status: "missed"}]},
      current_epoch_s: 165.0,
      generated_at: ~U[2026-05-14 00:00:00Z]
    }

    assert OrbitalDynamics.campaign_repair(repair_request) ==
             CampaignPlanner.repair(repair_request)

    strategy_request = %{
      prior_plan: base_plan(%{"candidate_activities" => [downlink("dl_1", 100.0, 160.0)]}),
      mission_state: mission_state([]),
      branches: [%{id: "baseline"}, %{id: "manual_review", events: [%{type: "operator_note"}]}],
      current_epoch_s: 0.0,
      remaining_horizon: %{"starts_at_s" => 0.0, "ends_at_s" => 1_000.0},
      generated_at: ~U[2026-05-14 00:00:00Z]
    }

    assert OrbitalDynamics.campaign_strategy(strategy_request) ==
             CampaignPlanner.strategy(strategy_request)
  end

  defp campaign_result_set(event_results) do
    ResultSet.new!(%{
      study_id: :campaign,
      trajectory_results: [],
      event_results: event_results,
      errors: [],
      assumptions: %{},
      metadata: %{}
    })
  end

  defp target_visibility_result(scenario_id, target_id, starts_at_s, ends_at_s, priority) do
    %{
      scenario_id: scenario_id,
      event_type: :target_visibility,
      events: [
        %{
          type: :target_visibility,
          starts_at: Epoch.new!(starts_at_s, :tdb),
          ends_at: Epoch.new!(ends_at_s, :tdb),
          metadata: %{
            target_id: target_id,
            target_priority: priority,
            max_elevation_deg: 60.0,
            minimum_elevation_deg: 10.0
          }
        }
      ],
      source: %{target_id: target_id}
    }
  end

  defp access_result(scenario_id, ground_station_id, starts_at_s, ends_at_s) do
    %{
      scenario_id: scenario_id,
      event_type: :ground_station_access,
      events: [
        %{
          type: :ground_station_access,
          starts_at: Epoch.new!(starts_at_s, :tdb),
          ends_at: Epoch.new!(ends_at_s, :tdb),
          metadata: %{
            max_elevation_deg: 45.0,
            minimum_elevation_deg: 5.0
          }
        }
      ],
      source: %{ground_station_id: ground_station_id}
    }
  end
end
