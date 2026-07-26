Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.RepairMissedDownlinkCandidateSelectionTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "repair skips the failed source and duplicate replacement candidate ids" do
    missed_downlink = refreshed_downlink("dl_1", 100.0, 160.0)

    duplicate_a =
      refreshed_downlink("dl_duplicate", 500.0, 560.0)
      |> Map.put("score", 500.0)

    duplicate_b =
      refreshed_downlink("dl_duplicate", 700.0, 760.0)
      |> Map.put("score", 600.0)

    unique_replacement =
      refreshed_downlink("dl_unique", 900.0, 960.0)
      |> Map.put("score", 1.0)

    artifact =
      repair(
        %{
          "activities" => [missed_downlink],
          "candidate_activities" => [
            missed_downlink,
            duplicate_a,
            duplicate_b,
            unique_replacement
          ]
        },
        realized_state: %{activities: [%{id: "dl_1", status: "missed"}]},
        current_epoch_s: 165.0
      )

    assert [
             %{
               "activity_id" => "dl_1",
               "repair_action" => "moved",
               "replacement_activity_id" => "dl_unique"
             }
           ] = artifact["deltas"]

    assert [
             %{
               "id" => "dl_unique",
               "repair" => %{
                 "replacement_ranking" => %{
                   "evaluated_candidate_count" => 1,
                   "rows" => [
                     %{"candidate_id" => "dl_unique", "rank" => 1, "selected" => true}
                   ]
                 }
               }
             }
           ] = artifact["activities"]

    assert {:ok, %{"schema_contract" => "campaign_repair.v2", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "repair moves a missed planned-contact downlink to a later planned-contact window" do
    missed_planned_contact =
      "planned_dl_1"
      |> downlink(100.0, 160.0)
      |> Map.put("type", "planned_contact")
      |> Map.put("direction", "downlink")
      |> Map.put("source_window_id", "window:leo_1:ground_station_access:equator_prime:1")

    replacement_planned_contact =
      "planned_dl_2"
      |> refreshed_downlink(700.0, 760.0)
      |> Map.put("type", "planned_contact")

    artifact =
      repair(
        %{
          "activities" => [missed_planned_contact],
          "candidate_activities" => [missed_planned_contact, replacement_planned_contact]
        },
        realized_state: %{activities: [%{id: "planned_dl_1", status: "missed"}]},
        current_epoch_s: 165.0
      )

    assert [
             %{
               "id" => "planned_dl_2",
               "type" => "planned_contact",
               "direction" => "downlink",
               "repair" => repair
             }
           ] = artifact["activities"]

    assert repair["action"] == "moved"
    assert repair["source_activity_id"] == "planned_dl_1"
    assert repair["source_activity_context"]["direction"] == "downlink"

    assert [
             %{
               "activity_id" => "planned_dl_1",
               "activity_type" => "planned_contact",
               "repair_action" => "moved",
               "replacement_activity_id" => "planned_dl_2",
               "replacement_activity_context" => %{
                 "direction" => "downlink",
                 "cadence_import" => %{"schema_contract" => "proposed_contact.v1"}
               }
             }
           ] = artifact["deltas"]

    assert [
             %{
               "activity_id" => "planned_dl_2",
               "activity_type" => "planned_contact",
               "action" => "approve_moved_contact",
               "requirement_type" => "contact_schedule_change"
             }
           ] = artifact["approval_requirements"]

    assert %{
             "schema_contract" => "link_capacity_report.v1",
             "contact_count" => 1,
             "selected_contact_count" => 1,
             "rows" => [
               %{
                 "contact_ids" => ["planned_dl_2"],
                 "selected_contact_ids" => ["planned_dl_2"]
               }
             ]
           } = artifact["link_capacity_report"]

    refute Enum.any?(
             artifact["warnings"],
             &String.contains?(&1, "missed downlink planned_dl_1 could not be repaired")
           )

    assert {:ok, %{"schema_contract" => "campaign_repair.v2", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
