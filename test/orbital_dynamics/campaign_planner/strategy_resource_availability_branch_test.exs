Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyResourceAvailabilityBranchTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy derives payload constrained branch through resource-filtered refresh" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:resources, %{"fuel_margin" => 1.0, "payload_available" => false})

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        approval_policy: %{
          "action_rules" => [
            %{
              "id" => "leo_1_payload_risk_block",
              "risk_types" => ["payload_unavailable"],
              "spacecraft_id" => "leo_1",
              "classification" => "blocked_by_policy",
              "reason" => "leo_1 payload risk blocks branch promotion"
            }
          ]
        },
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    payload_branch = branch(artifact, "derived_payload_constrained_leo_1")
    event = List.first(payload_branch["events"])

    assert %{
             "type" => "resource_availability_constraint",
             "spacecraft_id" => "leo_1",
             "resource_field" => "payload_available",
             "available" => false,
             "derivation_reasons" => ["payload_unavailable"]
           } = event

    repair = payload_branch["repair_result"]

    assert [
             %{
               "schema_contract" => "resource_summary.v1",
               "spacecraft_id" => "leo_1",
               "payload_available" => false,
               "provenance" => %{
                 "source" => "strategy_branch_event",
                 "event_type" => "resource_availability_constraint"
               }
             }
           ] = repair["source_resource_summaries"]

    assert %{
             "schema_contract" => "resource_filter_report.v1",
             "suppressed_candidate_count" => suppressed_count,
             "suppressed_candidates" => [
               %{"suppressed_reason" => "payload_unavailable"} | _
             ]
           } = repair["source_resource_filter_report"]

    assert suppressed_count > 0

    refute Enum.any?(
             repair["source_candidate_activities"],
             &(&1["type"] == "observe" and &1["scenario_id"] == "leo_1")
           )

    assert Enum.any?(
             payload_branch["risk_indicators"],
             &(&1["type"] == "payload_unavailable" and &1["value"] == false and
                 &1["spacecraft_id"] == "leo_1")
           )

    assert Enum.any?(
             payload_branch["approval_rule_matches"],
             &(&1["rule_id"] == "leo_1_payload_risk_block" and
                 &1["risk_type"] == "payload_unavailable" and
                 &1["spacecraft_id"] == "leo_1")
           )

    payload_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "derived_payload_constrained_leo_1"))

    assert payload_row["payload_availability"] == 0.0
    assert "payload_availability_low" in payload_row["resource_risk_types"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy does not derive payload constrained branch when payload is available" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:resources, %{"fuel_margin" => 1.0, "payload_available" => true})

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    refute branch(artifact, "derived_payload_constrained_leo_1")
  end

  test "strategy derives payload constrained branch from resource summary boolean aliases" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:resource_summaries, [
        %{
          "schema_contract" => "resource_summary.v1",
          "spacecraft_id" => "leo_1",
          "payload_available?" => "0",
          "source_quality" => "telemetry_estimate",
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

    payload_branch = branch(artifact, "derived_payload_constrained_leo_1")

    assert %{
             "type" => "resource_availability_constraint",
             "spacecraft_id" => "leo_1",
             "resource_field" => "payload_available",
             "available" => false,
             "derivation_reasons" => ["payload_unavailable"],
             "source_quality" => "telemetry_estimate"
           } = List.first(payload_branch["events"])

    assert Enum.any?(
             payload_branch["risk_indicators"],
             &(&1["type"] == "payload_unavailable" and &1["value"] == false)
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives antenna constrained branch through resource-filtered refresh" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:resources, %{"fuel_margin" => 1.0, "antenna_available" => false})

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    antenna_branch = branch(artifact, "derived_antenna_constrained_leo_1")
    event = List.first(antenna_branch["events"])

    assert %{
             "type" => "resource_availability_constraint",
             "spacecraft_id" => "leo_1",
             "resource_field" => "antenna_available",
             "available" => false,
             "derivation_reasons" => ["antenna_unavailable"]
           } = event

    repair = antenna_branch["repair_result"]

    assert [
             %{
               "schema_contract" => "resource_summary.v1",
               "spacecraft_id" => "leo_1",
               "antenna_available" => false,
               "provenance" => %{
                 "source" => "strategy_branch_event",
                 "event_type" => "resource_availability_constraint"
               }
             }
           ] = repair["source_resource_summaries"]

    assert %{
             "schema_contract" => "resource_filter_report.v1",
             "suppressed_candidate_count" => suppressed_count,
             "suppressed_candidates" => [
               %{"suppressed_reason" => "antenna_unavailable"} | _
             ]
           } = repair["source_resource_filter_report"]

    assert suppressed_count > 0

    refute Enum.any?(
             repair["source_candidate_activities"],
             &(&1["type"] == "downlink" and &1["scenario_id"] == "leo_1")
           )

    assert Enum.any?(
             antenna_branch["risk_indicators"],
             &(&1["type"] == "antenna_unavailable" and &1["value"] == false)
           )

    antenna_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "derived_antenna_constrained_leo_1"))

    assert antenna_row["antenna_availability"] == 0.0
    assert "antenna_availability_low" in antenna_row["resource_risk_types"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives antenna constrained branch from resource summary string booleans" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:resource_summaries, [
        %{
          "schema_contract" => "resource_summary.v1",
          "spacecraft_id" => "leo_1",
          "antenna_available" => "false",
          "source_quality" => "telemetry_estimate",
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

    antenna_branch = branch(artifact, "derived_antenna_constrained_leo_1")

    assert %{
             "type" => "resource_availability_constraint",
             "spacecraft_id" => "leo_1",
             "resource_field" => "antenna_available",
             "available" => false,
             "derivation_reasons" => ["antenna_unavailable"],
             "source_quality" => "telemetry_estimate"
           } = List.first(antenna_branch["events"])

    assert Enum.any?(
             antenna_branch["risk_indicators"],
             &(&1["type"] == "antenna_unavailable" and &1["value"] == false)
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy branch comparison uses explicit resource summary availability" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:resources, %{
        "fuel_margin" => 1.0,
        "payload_available" => true,
        "antenna_available" => true
      })
      |> Map.put(:resource_summaries, [
        %{
          "schema_contract" => "resource_summary.v1",
          "spacecraft_id" => "leo_1",
          "payload_available" => false,
          "antenna_available" => false,
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

    assert baseline_row["payload_availability"] == 0.0
    assert baseline_row["antenna_availability"] == 0.0
    assert "payload_availability_low" in baseline_row["resource_risk_types"]
    assert "antenna_availability_low" in baseline_row["resource_risk_types"]

    assert branch(artifact, "derived_payload_constrained_leo_1")
    assert branch(artifact, "derived_antenna_constrained_leo_1")
  end

  test "strategy branch comparison uses mission resource availability aliases" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:resources, %{
        "fuel_margin" => 1.0,
        "payload_available?" => "FALSE",
        "antenna_available?" => "0"
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

    assert baseline_row["payload_availability"] == 0.0
    assert baseline_row["antenna_availability"] == 0.0
    assert "payload_availability_low" in baseline_row["resource_risk_types"]
    assert "antenna_availability_low" in baseline_row["resource_risk_types"]

    assert branch(artifact, "derived_payload_constrained_leo_1")
    assert branch(artifact, "derived_antenna_constrained_leo_1")

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy does not derive antenna constrained branch when antenna is available" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:resources, %{"fuel_margin" => 1.0, "antenna_available" => true})

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    refute branch(artifact, "derived_antenna_constrained_leo_1")
  end
end
