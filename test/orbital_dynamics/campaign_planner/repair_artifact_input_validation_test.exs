Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.RepairArtifactInputValidationTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  test "repair accepts declared station calendar provider artifacts" do
    artifact =
      repair(
        %{
          "activities" => [downlink("dl_1", 100.0, 160.0)],
          "candidate_activities" => [refreshed_downlink("dl_2", 500.0, 560.0)]
        },
        realized_state: %{activities: [%{id: "dl_1", status: "missed"}]},
        current_epoch_s: 165.0,
        station_calendar: %{
          schema_contract: "station_calendar_provider.v1",
          id: "ops_calendar",
          entries: [
            %{
              id: "equator_maintenance",
              station_id: "equator_prime",
              availability: "maintenance",
              start_s: 490.0,
              end_s: 570.0
            }
          ]
        }
      )

    assert [
             %{
               "id" => "dl_2",
               "station_calendar_status" => "maintenance",
               "station_availability" => "unavailable"
             }
           ] =
             artifact["source_candidate_activities"]

    assert %{
             "affected_contacts" => [
               %{
                 "contact_id" => "dl_2",
                 "station_calendar_entry_id" => "equator_maintenance",
                 "status" => "maintenance",
                 "station_availability" => "unavailable"
               }
             ]
           } = artifact["source_station_calendar_report"]
  end

  test "repair rejects invalid station calendar provider updates" do
    assert_raise ArgumentError, ~r/entries must be a list/, fn ->
      repair(
        %{
          "activities" => [downlink("dl_1", 100.0, 160.0)],
          "candidate_activities" => [downlink("dl_2", 500.0, 560.0)]
        },
        realized_state: %{activities: [%{id: "dl_1", status: "missed"}]},
        current_epoch_s: 165.0,
        ground_network: %{ground_station_id: "equator_prime"}
      )
    end
  end

  test "repair rejects invalid candidate refresh artifacts" do
    assert_raise ArgumentError, ~r/invalid candidate_refresh.v1 artifact/, fn ->
      repair(
        %{"activities" => [downlink("dl_1", 100.0, 160.0)]},
        realized_state: %{activities: [%{id: "dl_1", status: "missed"}]},
        current_epoch_s: 165.0,
        candidate_refresh: %{"artifact_type" => "candidate_refresh"}
      )
    end
  end

  test "repair rejects invalid candidate refresh requests" do
    assert_raise ArgumentError, ~r/invalid repair candidate_refresh_request/, fn ->
      repair(
        %{
          "activities" => [downlink("dl_1", 100.0, 160.0)],
          "candidate_activities" => [downlink("dl_stale", 700.0, 760.0)]
        },
        realized_state: %{activities: [%{id: "dl_1", status: "missed"}]},
        current_epoch_s: 0.0,
        candidate_refresh_request: %{"remaining_horizon" => %{}}
      )
    end
  end
end
