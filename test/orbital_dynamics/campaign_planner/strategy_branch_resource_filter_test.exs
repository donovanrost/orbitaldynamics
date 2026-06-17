Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyBranchResourceFilterTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy-derived refresh applies degraded spacecraft events through resource filters" do
    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state_with_refresh_inputs(),
        branches: [
          %{id: "baseline"},
          %{
            id: "degraded",
            events: [
              %{
                type: "degraded_spacecraft",
                scenario_id: "leo_1",
                incompatible_activity_types: ["observe"]
              }
            ]
          }
        ],
        current_epoch_s: 0.0
      )

    repair = branch(artifact, "degraded")["repair_result"]

    assert %{
             "schema_contract" => "resource_filter_report.v1",
             "suppressed_candidate_count" => suppressed_count
           } = repair["source_resource_filter_report"]

    assert suppressed_count > 0

    refute Enum.any?(
             repair["source_candidate_activities"],
             &(&1["type"] == "observe" and &1["scenario_id"] == "leo_1")
           )
  end

  test "strategy-derived degraded event preserves explicit spacecraft availability aliases" do
    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state_with_refresh_inputs(),
        branches: [
          %{id: "baseline"},
          %{
            id: "degraded",
            events: [
              %{
                "type" => "degraded_spacecraft",
                "scenario_id" => "leo_1",
                "spacecraft_available?" => "false"
              }
            ]
          }
        ],
        current_epoch_s: 0.0
      )

    degraded = branch(artifact, "degraded")
    event = List.first(degraded["events"])

    assert %{
             "type" => "degraded_spacecraft",
             "scenario_id" => "leo_1",
             "spacecraft_available" => false,
             "incompatible_activity_types" => ["downlink", "observe", "planned_contact"]
           } = event

    assert Enum.any?(
             degraded["repair_result"]["source_resource_summaries"],
             &(&1["spacecraft_id"] == "leo_1" and &1["spacecraft_available"] == false and
                 &1["payload_available"] == false and &1["antenna_available"] == false and
                 get_in(&1, ["provenance", "event_type"]) == "degraded_spacecraft")
           )

    refute Enum.any?(
             degraded["repair_result"]["source_candidate_activities"],
             &(&1["scenario_id"] == "leo_1" and &1["type"] in ["observe", "downlink"])
           )

    assert degraded["resource_impacts"]["spacecraft_availability"] == 0.0
    assert degraded["resource_impacts"]["payload_availability"] == 0.0
    assert degraded["resource_impacts"]["antenna_availability"] == 0.0

    degraded_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "degraded"))

    assert degraded_row["spacecraft_availability"] == 0.0
    assert degraded_row["payload_availability"] == 0.0
    assert degraded_row["antenna_availability"] == 0.0
    assert "spacecraft_availability_low" in degraded_row["resource_risk_types"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy-derived refresh synthesizes resource summaries from mission-state resources" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:resources, %{
        "fuel_margin" => 0.8,
        "power_margin" => 0.7,
        "payload_available" => false
      })

    artifact =
      strategy(
        base_plan(%{}),
        mission_state: mission_state,
        branches: [
          %{id: "baseline"},
          %{
            id: "urgent",
            events: [%{type: "urgent_target", target_id: "target_a", priority: 12.0}]
          }
        ],
        current_epoch_s: 0.0
      )

    repair = branch(artifact, "urgent")["repair_result"]

    assert [
             %{
               "schema_contract" => "resource_summary.v1",
               "spacecraft_id" => "leo_1",
               "payload_available" => false,
               "source_quality" => "operator_supplied",
               "provenance" => %{"source" => "mission_state.resources"}
             }
           ] = repair["source_resource_summaries"]

    assert %{
             "schema_contract" => "resource_filter_report.v1",
             "resource_source_quality_counts" => %{"operator_supplied" => 1},
             "suppressed_candidate_count" => suppressed_count
           } = repair["source_resource_filter_report"]

    assert suppressed_count > 0

    refute Enum.any?(
             repair["source_candidate_activities"],
             &(&1["type"] == "observe" and &1["target_id"] == "target_a")
           )
  end

  test "strategy-derived refresh synthesizes per-spacecraft resource summaries from mission-state resources" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:resources, %{
        "spacecraft" => [
          %{
            "spacecraft_id" => "leo_1",
            "fuel_margin" => 0.8,
            "power_margin" => 0.7,
            "payload_available" => false
          },
          %{
            "spacecraft_id" => "leo_2",
            "fuel_margin" => 0.9,
            "power_margin" => 0.8,
            "payload_available" => true
          }
        ]
      })

    artifact =
      strategy(
        base_plan(%{
          "activities" => [
            observe("obs_resource_alias", "leo_1", "target_a", 100.0, 160.0, 10.0),
            downlink("dl_resource_alias", 200.0, 260.0)
          ]
        }),
        mission_state: mission_state,
        branches: [
          %{id: "baseline"},
          %{
            id: "urgent",
            events: [%{type: "urgent_target", target_id: "target_a", priority: 12.0}]
          }
        ],
        current_epoch_s: 0.0
      )

    repair = branch(artifact, "urgent")["repair_result"]

    assert [
             %{
               "schema_contract" => "resource_summary.v1",
               "spacecraft_id" => "leo_1",
               "payload_available" => false,
               "source_quality" => "operator_supplied",
               "provenance" => %{"source" => "mission_state.resources"}
             },
             %{
               "schema_contract" => "resource_summary.v1",
               "spacecraft_id" => "leo_2",
               "payload_available" => true,
               "source_quality" => "operator_supplied",
               "provenance" => %{"source" => "mission_state.resources"}
             }
           ] = repair["source_resource_summaries"]

    assert %{
             "schema_contract" => "resource_filter_report.v1",
             "resource_source_quality_counts" => %{"operator_supplied" => 2},
             "suppressed_candidate_count" => suppressed_count
           } = repair["source_resource_filter_report"]

    assert suppressed_count > 0

    refute Enum.any?(
             repair["source_candidate_activities"],
             &(&1["type"] == "observe" and &1["scenario_id"] == "leo_1")
           )
  end

  test "explicit mission-state resource summaries override synthesized resources" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:resources, %{"payload_available" => false})
      |> Map.put(:resource_summaries, [
        %{
          "spacecraft_id" => "leo_1",
          "payload_available" => true,
          "fuel_margin" => 0.8,
          "power_margin" => 0.7,
          "provenance" => %{"source" => "operator_summary"}
        }
      ])

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        branches: [
          %{id: "baseline"},
          %{
            id: "urgent",
            events: [%{type: "urgent_target", target_id: "target_a", priority: 12.0}]
          }
        ],
        current_epoch_s: 0.0
      )

    repair = branch(artifact, "urgent")["repair_result"]

    assert [
             %{
               "spacecraft_id" => "leo_1",
               "payload_available" => true,
               "provenance" => %{"source" => "operator_summary"}
             }
           ] = repair["source_resource_summaries"]

    assert Enum.any?(
             repair["source_candidate_activities"],
             &(&1["type"] == "observe" and &1["target_id"] == "target_a")
           )
  end
end
