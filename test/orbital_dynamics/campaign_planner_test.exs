defmodule OrbitalDynamics.CampaignPlannerTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{
    CampaignPlanner,
    Epoch,
    ResultSet,
    Schema
  }

  test "campaign generated IDs and ordering are stable across event result permutations" do
    event_results = [
      access_result(:leo_2, :equator_prime, 150.0, 210.0),
      target_visibility_result(:leo_1, :target_b, 50.0, 110.0, 3.0),
      access_result(:leo_1, :equator_prime, 100.0, 170.0),
      target_visibility_result(:leo_1, :target_a, 60.0, 120.0, 5.0)
    ]

    campaign = %{
      "targets" => [
        %{"id" => "target_b", "priority" => "3.0"},
        %{"id" => "target_a", "priority" => "5.0"}
      ],
      "constraints" => %{},
      "scoring_policy" => %{"target_value_weight" => "1.0", "contact_value_weight" => "0.1"}
    }

    permutations = [
      event_results,
      Enum.reverse(event_results),
      [
        Enum.at(event_results, 1),
        Enum.at(event_results, 3),
        Enum.at(event_results, 0),
        Enum.at(event_results, 2)
      ],
      [
        Enum.at(event_results, 2),
        Enum.at(event_results, 0),
        Enum.at(event_results, 3),
        Enum.at(event_results, 1)
      ]
    ]

    artifacts =
      Enum.map(permutations, fn events ->
        events
        |> campaign_result_set()
        |> CampaignPlanner.build(generated_at: ~U[2026-05-14 00:00:00Z], campaign: campaign)
      end)

    [left | rest] = artifacts
    assert Enum.all?(rest, &(&1 == left))

    assert Enum.map(left["candidate_activities"], & &1["id"]) == [
             "leo_1_observe_target_b_1",
             "leo_1_observe_target_a_1",
             "leo_1_downlink_equator_prime_1",
             "leo_2_downlink_equator_prime_1"
           ]

    assert Enum.map(left["proposed_contacts"], & &1["id"]) == [
             "leo_1_downlink_equator_prime_1",
             "leo_2_downlink_equator_prime_1"
           ]

    assert Enum.map(left["contact_intents"], & &1["activity_id"]) == [
             "leo_1_downlink_equator_prime_1",
             "leo_2_downlink_equator_prime_1"
           ]

    assert Enum.map(left["ranked_timelines"], & &1["scenario_id"]) == ["leo_1", "leo_2"]

    assert [
             %{
               "target_id" => "target_a",
               "selected_activity_ids" => ["leo_1_observe_target_a_1"],
               "status" => "selected"
             },
             %{
               "target_id" => "target_b",
               "selected_activity_ids" => [],
               "status" => "candidate_available"
             }
           ] = left["target_commitments"]

    assert [
             %{
               "contact_ids" => [
                 "leo_1_downlink_equator_prime_1",
                 "leo_2_downlink_equator_prime_1"
               ]
             }
           ] = left["contact_contention_report"]["conflict_groups"]

    assert Enum.map(left["objective_tradeoff_report"]["tradeoffs"], & &1["activity_ids"]) == [
             ["leo_1_observe_target_a_1"],
             ["leo_2_downlink_equator_prime_1"]
           ]

    assert {:ok, %{"status" => "pass"}} = Schema.validate_artifact(left)
  end

  test "campaign generated IDs are stable when source events arrive unsorted" do
    early_target = hd(target_visibility_result(:leo_1, :target_a, 120.0, 240.0, 5.0).events)
    late_target = hd(target_visibility_result(:leo_1, :target_a, 260.0, 340.0, 5.0).events)
    early_access = hd(access_result(:leo_1, :equator_prime, 300.0, 420.0).events)
    late_access = hd(access_result(:leo_1, :equator_prime, 430.0, 500.0).events)

    target_result =
      %{
        target_visibility_result(:leo_1, :target_a, 120.0, 240.0, 5.0)
        | events: [early_target, late_target]
      }

    access_result =
      %{access_result(:leo_1, :equator_prime, 300.0, 420.0) | events: [early_access, late_access]}

    reversed_target_result = %{target_result | events: Enum.reverse(target_result.events)}
    reversed_access_result = %{access_result | events: Enum.reverse(access_result.events)}

    campaign = %{
      "targets" => [%{"id" => "target_a", "priority" => 5.0}],
      "constraints" => %{},
      "scoring_policy" => %{"target_value_weight" => 1.0, "contact_value_weight" => 0.1}
    }

    left =
      [target_result, access_result]
      |> campaign_result_set()
      |> CampaignPlanner.build(generated_at: ~U[2026-05-14 00:00:00Z], campaign: campaign)

    right =
      [reversed_access_result, reversed_target_result]
      |> campaign_result_set()
      |> CampaignPlanner.build(generated_at: ~U[2026-05-14 00:00:00Z], campaign: campaign)

    assert left == right

    assert Enum.map(left["candidate_activities"], &{&1["id"], &1["starts_at_s"]}) == [
             {"leo_1_observe_target_a_1", 120.0},
             {"leo_1_observe_target_a_2", 260.0},
             {"leo_1_downlink_equator_prime_1", 300.0},
             {"leo_1_downlink_equator_prime_2", 430.0}
           ]

    assert {:ok, %{"status" => "pass"}} = Schema.validate_artifact(left)
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
