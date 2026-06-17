Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.RepairContactAllocationContentionTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "repair allocation detects same-spacecraft cross-station contention in repaired activities" do
    primary_contact = refreshed_downlink("dl_equator", 100.0, 220.0)

    overlapping_contact =
      "dl_dsn"
      |> refreshed_downlink(120.0, 240.0)
      |> Map.put("ground_station_id", "deep_space_net")
      |> Map.put("source_window_id", "window:leo_1:ground_station_access:deep_space_net:1")
      |> Map.put("source_window", %{
        "id" => "window:leo_1:ground_station_access:deep_space_net:1",
        "type" => "ground_station_access"
      })

    artifact =
      repair(
        %{
          "activities" => [primary_contact, overlapping_contact],
          "candidate_activities" => []
        },
        realized_state: %{activities: []},
        current_epoch_s: 0.0,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert %{
             "schema_contract" => "contact_allocation_report.v1",
             "source" => "campaign_repair.activities",
             "input_contact_count" => 2,
             "allocated_contact_count" => 1,
             "deferred_contact_count" => 1,
             "blocked_contact_count" => 0,
             "contact_contention_report" => %{
               "conflict_group_count" => 1,
               "conflict_groups" => [
                 %{
                   "id" => "spacecraft:leo_1:contention:1",
                   "resource_scope" => "spacecraft",
                   "ground_station_id" => "multi_station",
                   "ground_station_ids" => ["deep_space_net", "equator_prime"],
                   "spacecraft_id" => "leo_1",
                   "operator_action_reason" => "same_spacecraft_overlapping_contact_windows"
                 }
               ]
             },
             "rows" => allocation_rows
           } = artifact["contact_allocation_report"]

    assert %{
             "contact_id" => "dl_equator",
             "spacecraft_id" => "leo_1",
             "allocation_status" => "allocated",
             "allocation_reason" => "selected_by_contention_resolution",
             "contention_group_id" => "spacecraft:leo_1:contention:1"
           } = Enum.find(allocation_rows, &(&1["contact_id"] == "dl_equator"))

    assert %{
             "contact_id" => "dl_dsn",
             "spacecraft_id" => "leo_1",
             "allocation_status" => "deferred",
             "allocation_reason" => "same_spacecraft_contention",
             "selected_contact_id" => "dl_equator",
             "contention_group_id" => "spacecraft:leo_1:contention:1"
           } = Enum.find(allocation_rows, &(&1["contact_id"] == "dl_dsn"))

    assert Enum.any?(
             artifact["operator_review_package"]["rows"],
             &(&1["review_type"] == "contact_allocation_review" and
                 &1["source"] == "campaign_repair.contact_allocation_report.rows" and
                 &1["contact_id"] == "dl_dsn" and
                 &1["allocation_reason"] == "same_spacecraft_contention")
           )

    assert Enum.any?(
             artifact["cadence_import_manifest"]["rows"],
             &(&1["import_action"] == "review_contact_allocation" and
                 &1["source_review_type"] == "contact_allocation_review" and
                 &1["contact_id"] == "dl_dsn" and
                 &1["allocation_reason"] == "same_spacecraft_contention")
           )

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(artifact["contact_allocation_report"])

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)
  end
end
