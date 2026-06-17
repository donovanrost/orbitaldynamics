Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.RepairLinkCapacityRequirementsTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "repair link capacity uses mission-state downlink data volume requirement" do
    missed_downlink = downlink("dl_1", 100.0, 160.0)

    artifact =
      repair(
        %{
          "activities" => [missed_downlink],
          "candidate_activities" => [
            missed_downlink,
            refreshed_downlink("dl_2", 700.0, 760.0)
          ]
        },
        realized_state: %{activities: [%{id: "dl_1", status: "missed"}]},
        current_epoch_s: 165.0,
        mission_state:
          mission_state([
            %{
              "type" => "downlink_completion",
              "required_downlink_mb" => 100.0
            }
          ])
      )

    assert [%{"id" => "dl_2"}] = artifact["activities"]

    assert %{
             "required_downlink_mb" => 100.0,
             "selected_capacity_adjusted_throughput_mb" => 60.0,
             "selected_downlink_shortfall_mb" => 40.0,
             "downlink_requirement_status" => "shortfall"
           } = artifact["link_capacity_report"]

    assert {:ok, %{"schema_contract" => "campaign_repair.v2", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "repair link capacity aggregates multiple mission-state downlink data volume requirements" do
    missed_downlink = downlink("dl_1", 100.0, 160.0)

    artifact =
      repair(
        %{
          "activities" => [missed_downlink],
          "candidate_activities" => [
            missed_downlink,
            refreshed_downlink("dl_2", 700.0, 760.0)
          ]
        },
        realized_state: %{activities: [%{id: "dl_1", status: "missed"}]},
        current_epoch_s: 165.0,
        mission_state:
          mission_state([
            %{
              "type" => "downlink_completion",
              "required_downlink_mb" => 100.0
            },
            %{
              "type" => "downlink_completion",
              "required_downlink_mb" => 50.0
            }
          ])
      )

    assert %{
             "required_downlink_mb" => 150.0,
             "selected_capacity_adjusted_throughput_mb" => 60.0,
             "selected_downlink_shortfall_mb" => 90.0,
             "downlink_requirement_status" => "shortfall"
           } = artifact["link_capacity_report"]

    assert {:ok, %{"schema_contract" => "campaign_repair.v2", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "repair link capacity policy overrides mission-state downlink requirement" do
    missed_downlink = downlink("dl_1", 100.0, 160.0)

    artifact =
      repair(
        %{
          "activities" => [missed_downlink],
          "candidate_activities" => [
            missed_downlink,
            refreshed_downlink("dl_2", 700.0, 760.0)
          ]
        },
        realized_state: %{activities: [%{id: "dl_1", status: "missed"}]},
        current_epoch_s: 165.0,
        mission_state:
          mission_state([
            %{
              "type" => "downlink_completion",
              "required_downlink_mb" => 100.0
            }
          ]),
        scoring_policy: %{"required_downlink_mb" => 120.0}
      )

    assert %{
             "required_downlink_mb" => 120.0,
             "selected_capacity_adjusted_throughput_mb" => 60.0,
             "selected_downlink_shortfall_mb" => 60.0,
             "downlink_requirement_status" => "shortfall"
           } = artifact["link_capacity_report"]

    assert {:ok, %{"schema_contract" => "campaign_repair.v2", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
