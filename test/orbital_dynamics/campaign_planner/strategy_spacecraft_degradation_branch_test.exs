Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategySpacecraftDegradationBranchTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy derives degraded branch from explicit mission-state resource summaries" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:resource_summaries, [
        %{
          "schema_contract" => "resource_summary.v1",
          "spacecraft_id" => "leo_1",
          "mode" => "degraded",
          "degraded" => "1",
          "payload_available" => "0",
          "antenna_available" => "0",
          "provenance" => %{"source" => "operator_summary"}
        }
      ])

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}, %{id: "manual_review", events: [%{type: "operator_note"}]}],
        current_epoch_s: 0.0
      )

    degraded = branch(artifact, "derived_degraded_leo_1")

    assert degraded["derived_source"] == "mission_state.resource_summaries.degraded"

    assert %{
             "type" => "degraded_spacecraft",
             "scenario_id" => "leo_1",
             "incompatible_activity_types" => ["downlink", "observe", "planned_contact"]
           } = List.first(degraded["events"])

    repair = degraded["repair_result"]

    assert [
             %{
               "schema_contract" => "resource_summary.v1",
               "spacecraft_id" => "leo_1",
               "degraded" => true,
               "payload_available" => false,
               "antenna_available" => false,
               "provenance" => %{
                 "source" => "strategy_branch_event",
                 "event_type" => "degraded_spacecraft"
               }
             }
           ] = repair["source_resource_summaries"]

    assert %{
             "schema_contract" => "resource_filter_report.v1",
             "suppressed_candidate_count" => suppressed_count
           } = repair["source_resource_filter_report"]

    assert suppressed_count > 0

    degraded_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "derived_degraded_leo_1"))

    assert degraded_row["spacecraft_availability"] == 0.0
    assert degraded_row["payload_availability"] == 0.0
    assert degraded_row["antenna_availability"] == 0.0
    assert "spacecraft_availability_low" in degraded_row["resource_risk_types"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy branch comparison uses direct spacecraft availability resource summaries" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:resources, %{
        "fuel_margin" => 1.0,
        "spacecraft_status" => "offline"
      })

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    baseline_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "baseline"))

    assert baseline_row["spacecraft_availability"] == 0.0
    assert "spacecraft_availability_low" in baseline_row["resource_risk_types"]

    degraded = branch(artifact, "derived_degraded_leo_1")

    assert %{
             "type" => "degraded_spacecraft",
             "scenario_id" => "leo_1",
             "incompatible_activity_types" => ["downlink", "observe", "planned_contact"]
           } = List.first(degraded["events"])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy branch comparison ignores resource summaries without spacecraft availability evidence" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:spacecraft_states, [
        %{
          "scenario_id" => :leo_1,
          "status" => "unavailable",
          "source" => "operator_spacecraft_state"
        }
      ])
      |> Map.put(:resource_summaries, [
        %{
          "schema_contract" => "resource_summary.v1",
          "spacecraft_id" => "leo_1",
          "fuel_margin" => 0.8,
          "provenance" => %{"source" => "operator_summary"}
        }
      ])

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    baseline_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "baseline"))

    assert baseline_row["spacecraft_availability"] == 0.0
    assert "spacecraft_availability_low" in baseline_row["resource_risk_types"]

    degraded = branch(artifact, "derived_degraded_leo_1")

    assert %{
             "type" => "degraded_spacecraft",
             "scenario_id" => "leo_1",
             "incompatible_activity_types" => ["downlink", "observe", "planned_contact"]
           } = List.first(degraded["events"])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives degraded branch from resource summary and spacecraft state aliases" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:spacecraft_states, [
        %{
          "scenario_id" => :leo_2,
          "status" => "unavailable",
          "payload_status" => "unavailable",
          "antenna_status" => "offline",
          "source" => "operator_spacecraft_state"
        }
      ])
      |> Map.put(:resource_summaries, [
        %{
          "schema_contract" => "resource_summary.v1",
          "spacecraft_id" => "leo_1",
          "degraded?" => "1",
          "spacecraft_availability" => "0",
          "payload_status" => "unavailable",
          "antenna_status" => "disabled",
          "provenance" => %{"source" => "operator_summary"}
        }
      ])

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    resource_degraded = branch(artifact, "derived_degraded_leo_1")
    state_degraded = branch(artifact, "derived_degraded_leo_2")

    assert resource_degraded["derived_source"] == "mission_state.resource_summaries.degraded"
    assert state_degraded["derived_source"] == "operator_spacecraft_state"

    assert %{
             "type" => "degraded_spacecraft",
             "scenario_id" => "leo_1",
             "incompatible_activity_types" => ["downlink", "observe", "planned_contact"]
           } = List.first(resource_degraded["events"])

    assert %{
             "type" => "degraded_spacecraft",
             "scenario_id" => "leo_2",
             "incompatible_activity_types" => ["downlink", "observe", "planned_contact"]
           } = List.first(state_degraded["events"])

    baseline_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "baseline"))

    assert baseline_row["spacecraft_availability"] == 0.0
    assert baseline_row["payload_availability"] == 0.0
    assert baseline_row["antenna_availability"] == 0.0
    assert "spacecraft_availability_low" in baseline_row["resource_risk_types"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy branch comparison uses spacecraft-state antenna status aliases" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:spacecraft_states, [
        %{
          "scenario_id" => :leo_1,
          "status" => "operational",
          "payload_status" => "enabled",
          "antenna_status" => "offline",
          "source" => "operator_spacecraft_state"
        }
      ])

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    baseline_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "baseline"))

    assert baseline_row["spacecraft_availability"] == 1.0
    assert baseline_row["payload_availability"] == 1.0
    assert baseline_row["antenna_availability"] == 0.0
    assert "antenna_availability_low" in baseline_row["resource_risk_types"]

    degraded = branch(artifact, "derived_degraded_leo_1")

    assert %{
             "type" => "degraded_spacecraft",
             "scenario_id" => "leo_1",
             "incompatible_activity_types" => ["downlink", "planned_contact"]
           } = List.first(degraded["events"])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy normalizes degradation activity lists from mission-state degradations" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:degradations, [
        %{
          spacecraft_id: "leo_1",
          mode: "safe",
          incompatible_activity_types: [:observe, "downlink", :observe]
        }
      ])

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    degraded = branch(artifact, "derived_degraded_leo_1")

    assert degraded["derived_source"] == "mission_state.degradations"

    assert %{
             "type" => "degraded_spacecraft",
             "scenario_id" => "leo_1",
             "incompatible_activity_types" => ["downlink", "observe"]
           } = List.first(degraded["events"])

    assert Enum.any?(
             degraded["repair_result"]["source_resource_summaries"],
             &(&1["spacecraft_id"] == "leo_1" and &1["payload_available"] == false and
                 &1["antenna_available"] == false and
                 get_in(&1, ["assumptions", "incompatible_activity_types"]) == [
                   "downlink",
                   "observe"
                 ])
           )

    degraded_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "derived_degraded_leo_1"))

    assert degraded_row["payload_availability"] == 0.0
    assert degraded_row["antenna_availability"] == 0.0

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy keeps independent degraded branches for the same spacecraft" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:spacecraft_states, [
        %{
          scenario_id: :leo_1,
          mode: :degraded,
          incompatible_activity_types: [:observe],
          source: "operator_spacecraft_state"
        }
      ])
      |> Map.put(:degradations, [
        %{
          spacecraft_id: "leo_1",
          mode: "safe",
          suppressed_activity_types: ["downlink"]
        }
      ])

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    base_id = "derived_degraded_leo_1"
    refute branch(artifact, base_id)

    degraded_branches =
      Enum.filter(artifact["branches"], &String.starts_with?(&1["branch_id"], "#{base_id}_"))

    assert length(degraded_branches) == 2

    assert MapSet.new(Enum.map(degraded_branches, & &1["derived_source"])) ==
             MapSet.new(["operator_spacecraft_state", "mission_state.degradations"])

    assert degraded_branches
           |> Enum.flat_map(& &1["events"])
           |> Enum.map(&Map.take(&1, ["mode", "incompatible_activity_types"]))
           |> MapSet.new() ==
             MapSet.new([
               %{"mode" => "degraded", "incompatible_activity_types" => ["observe"]},
               %{"mode" => "safe", "incompatible_activity_types" => ["downlink"]}
             ])

    degraded_branch_ids = Enum.map(degraded_branches, & &1["branch_id"])

    assert Enum.any?(degraded_branch_ids, &String.contains?(&1, "operator_spacecraft_state"))
    assert Enum.any?(degraded_branch_ids, &String.contains?(&1, "mission_state.degradations"))

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
