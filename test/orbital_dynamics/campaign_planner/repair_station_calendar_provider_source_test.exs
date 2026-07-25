Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.RepairStationCalendarProviderSourceTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  test "preserves the exact declared station-calendar provider source" do
    provider = %{
      schema_contract: "station_calendar_provider.v1",
      id: "ops_calendar",
      provider_id: "ops_calendar",
      entries: [
        %{
          id: "equator_maintenance",
          ground_station_id: "equator_prime",
          availability: "maintenance",
          starts_at_s: 490.0,
          ends_at_s: 570.0,
          capacity_fraction: 0.0
        },
        %{
          id: "equator_future_capacity",
          ground_station_id: "equator_prime",
          availability: "reduced_capacity",
          starts_at_s: 700.0,
          ends_at_s: 800.0,
          capacity_fraction: 0.5
        }
      ],
      provenance: %{
        source: "declared_provider_fixture",
        trust_boundary: "operator_declared_station_calendar"
      },
      assumptions: %{
        boundary: "artifact_only_no_provider_reservation",
        network_access: "none"
      }
    }

    expected_provider = OrbitalDynamics.CampaignPlanner.ValueEncoding.stringify_keys(provider)

    artifact =
      repair(
        %{
          "activities" => [downlink("dl_1", 100.0, 160.0)],
          "candidate_activities" => [refreshed_downlink("dl_2", 500.0, 560.0)]
        },
        realized_state: %{activities: [%{id: "dl_1", status: "missed"}]},
        current_epoch_s: 165.0,
        station_calendar: provider
      )

    assert artifact["source_station_calendar_provider"] == expected_provider

    assert %{
             "affected_contacts" => [
               %{
                 "contact_id" => "dl_2",
                 "station_calendar_entry_id" => "equator_maintenance"
               }
             ]
           } = artifact["source_station_calendar_report"]

    assert Enum.any?(
             artifact["source_station_calendar_provider"]["entries"],
             &(&1["id"] == "equator_future_capacity")
           )

    refute Enum.any?(
             artifact["operator_review_package"]["rows"],
             &(is_binary(&1["source"]) and
                 String.starts_with?(
                   &1["source"],
                   "campaign_repair.source_station_calendar_provider"
                 ))
           )

    refute Enum.any?(
             artifact["cadence_import_manifest"]["rows"],
             &(is_binary(&1["source"]) and
                 String.starts_with?(
                   &1["source"],
                   "campaign_repair.source_station_calendar_provider"
                 ))
           )
  end

  test "omits the provider source for normalized ground-network rows" do
    artifact =
      repair(
        %{
          "activities" => [downlink("dl_1", 100.0, 160.0)],
          "candidate_activities" => [refreshed_downlink("dl_2", 500.0, 560.0)]
        },
        realized_state: %{activities: [%{id: "dl_1", status: "missed"}]},
        current_epoch_s: 165.0,
        ground_network: [
          %{
            id: "equator_maintenance",
            ground_station_id: "equator_prime",
            availability: "maintenance",
            starts_at_s: 490.0,
            ends_at_s: 570.0
          }
        ]
      )

    refute Map.has_key?(artifact, "source_station_calendar_provider")
  end

  test "omits invalid claimed provider artifacts without changing legacy overlay behavior" do
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
          id: "legacy_calendar",
          entries: [
            %{
              id: "equator_maintenance",
              ground_station_id: "equator_prime",
              availability: "maintenance",
              starts_at_s: 490.0,
              ends_at_s: 570.0
            }
          ]
        }
      )

    refute Map.has_key?(artifact, "source_station_calendar_provider")

    assert get_in(artifact, [
             "source_station_calendar_report",
             "affected_contacts",
             Access.at(0),
             "contact_id"
           ]) ==
             "dl_2"
  end
end
