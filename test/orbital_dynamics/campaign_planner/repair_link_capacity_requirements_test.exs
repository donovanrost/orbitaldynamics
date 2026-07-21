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
          ]),
        scoring_policy: %{"risk_weight" => "2.5"}
      )

    assert [%{"id" => "dl_2"}] = artifact["activities"]

    assert %{
             "required_downlink_mb" => 100.0,
             "selected_capacity_adjusted_throughput_mb" => 60.0,
             "selected_downlink_shortfall_mb" => 40.0,
             "downlink_requirement_status" => "shortfall"
           } = artifact["link_capacity_report"]

    assert artifact["score_terms"]["link_capacity_pressure_penalty"] == -2.5
    assert artifact["score"] == artifact["score_terms"] |> Map.values() |> Enum.sum()

    assert "link_capacity_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert [
             %{
               "term_key" => "link_capacity_pressure_penalty",
               "value" => -2.5,
               "selected" => true
             }
           ] =
             Enum.filter(
               artifact["score_term_report"]["rows"],
               &(&1["term_key"] == "link_capacity_pressure_penalty")
             )

    assert {:ok, %{"schema_contract" => "campaign_repair.v2", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "repair scoring omits link-capacity pressure when selected capacity satisfies demand" do
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
              "required_downlink_mb" => 60.0
            }
          ]),
        scoring_policy: %{"risk_weight" => "2.5"}
      )

    assert %{
             "selected_downlink_shortfall_mb" => shortfall,
             "downlink_requirement_status" => "satisfied"
           } = artifact["link_capacity_report"]

    assert shortfall == 0.0

    refute Map.has_key?(artifact["score_terms"], "link_capacity_pressure_penalty")

    refute "link_capacity_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

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
