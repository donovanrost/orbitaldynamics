Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyCombinedDerivedBranchTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy can synthesize an opt-in combined derived mission-state branch" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:ground_network, [
        %{
          ground_station_id: "equator_prime",
          status: "unavailable",
          starts_at_s: 0.0,
          ends_at_s: 120.0
        }
      ])
      |> Map.put(:resources, %{"fuel_margin" => 0.1, "downlink_margin" => 0.4})
      |> Map.put(:objectives, [
        %{
          type: "priority_commitment",
          target_id: "target_a",
          latitude_deg: 0.0,
          longitude_deg: 0.0,
          priority: 4.0
        }
      ])

    artifact =
      strategy(base_plan(%{"activities" => [downlink("dl_1", 100.0, 160.0)]}),
        mission_state: mission_state,
        derive_branches?: true,
        branch_generation_policy: %{combine_derived_branches: true},
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    combined = branch(artifact, "derived_combined_mission_state")
    event_types = Enum.map(combined["events"], & &1["type"])

    assert combined["derived_source"] == "branch_generation.combined_derived"
    assert "fuel_preservation_mode" in event_types
    assert "ground_station_outage" in event_types
    assert "reduced_downlink_capacity" in event_types
    assert "urgent_target" in event_types

    assert %{
             "source_branch_id" => "derived_fuel_preservation",
             "source_branch_ids" => ["derived_fuel_preservation"]
           } = Enum.find(combined["events"], &(&1["type"] == "fuel_preservation_mode"))

    assert %{
             "source_branch_id" => "derived_station_outage_equator_prime",
             "source_branch_ids" => ["derived_station_outage_equator_prime"]
           } = Enum.find(combined["events"], &(&1["type"] == "ground_station_outage"))

    assert Enum.all?(combined["events"], &is_binary(&1["source_branch_id"]))

    assert %{
             "branch_event_count" => event_count,
             "combined_source_branch_ids" => source_branch_ids
           } =
             Enum.find(
               artifact["branch_comparison_report"]["rows"],
               &(&1["branch_id"] == "derived_combined_mission_state")
             )

    assert event_count == length(combined["events"])

    assert source_branch_ids == [
             "derived_downlink_constrained",
             "derived_fuel_preservation",
             "derived_station_outage_equator_prime",
             "derived_urgent_target_target_a"
           ]

    assert %{
             "branch_event_count" => ^event_count,
             "combined_source_branch_ids" => ^source_branch_ids
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["review_type"] == "strategy_tradeoff" and
                   &1["branch_id"] == "derived_combined_mission_state")
             )

    assert %{
             "branch_event_count" => ^event_count,
             "combined_source_branch_ids" => ^source_branch_ids
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["import_action"] == "review_strategy_branch_alternative" and
                   &1["branch_id"] == "derived_combined_mission_state")
             )

    assert combined["provenance"]["branch_metadata"]["combined_branch_ids"] == [
             "derived_downlink_constrained",
             "derived_fuel_preservation",
             "derived_station_outage_equator_prime",
             "derived_urgent_target_target_a"
           ]

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             combined["assumptions"]["candidate_source"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy skips combined derived branch when fewer than two branches are derived" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:objectives, [
        %{
          type: "priority_commitment",
          target_id: "target_a",
          latitude_deg: 0.0,
          longitude_deg: 0.0,
          priority: 4.0
        }
      ])

    artifact =
      strategy(base_plan(%{"activities" => [downlink("dl_1", 100.0, 160.0)]}),
        mission_state: mission_state,
        derive_branches?: true,
        branch_generation_policy: %{combine_derived_branches: true},
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    refute branch(artifact, "derived_combined_mission_state")
  end
end
