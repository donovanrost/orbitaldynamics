Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyResourceMarginBranchTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy derives downlink relief branch from low storage margin" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:resources, %{"fuel_margin" => 1.0, "storage_margin" => "0.1"})
      |> put_in(
        [:candidate_refresh_defaults, :resource_filter_policy],
        %{min_observe_storage_margin: 0.2}
      )

    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 600.0, "output_step_s" => 60.0},
        "activities" => [downlink("existing_dl", 500.0, 560.0)]
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}, %{id: "manual_review", events: [%{type: "operator_note"}]}],
        current_epoch_s: 0.0
      )

    downlink_branch = branch(artifact, "derived_downlink_constrained")
    event = List.first(downlink_branch["events"])

    assert %{
             "type" => "downlink_completion_gap",
             "planned_contacts" => 1,
             "required_contacts" => 2,
             "storage_margin" => 0.1,
             "storage_margin_threshold" => 0.2,
             "derivation_reasons" => ["storage_margin_low"]
           } = event

    assert %{
             "type" => "resource_margin_pressure",
             "spacecraft_id" => "leo_1",
             "resource_field" => "storage_margin",
             "storage_margin" => 0.1,
             "storage_margin_threshold" => 0.2,
             "derivation_reasons" => ["storage_margin_low"]
           } =
             Enum.find(downlink_branch["events"], &(&1["type"] == "resource_margin_pressure"))

    repair = downlink_branch["repair_result"]

    assert [
             %{
               "schema_contract" => "resource_summary.v1",
               "spacecraft_id" => "leo_1",
               "storage_margin" => 0.1,
               "provenance" => %{
                 "source" => "strategy_branch_event",
                 "event_type" => "resource_margin_pressure"
               }
             }
           ] = repair["source_resource_summaries"]

    assert %{
             "schema_contract" => "resource_filter_report.v1",
             "suppressed_candidate_count" => suppressed_count,
             "suppressed_candidates" => [
               %{"suppressed_reason" => "storage_margin_below_observe_policy"} | _
             ]
           } = repair["source_resource_filter_report"]

    assert suppressed_count > 0

    assert [
             %{
               "type" => "downlink",
               "repair" => %{"reason" => "storage_relief_downlink_candidate_inserted"},
               "feasibility" => %{
                 "status" => "validated_candidate_window",
                 "derivation_reasons" => ["storage_margin_low"],
                 "required_contacts" => 2,
                 "planned_contacts" => 1
               }
             }
           ] = downlink_branch["candidate_plan"]["strategic_additions"]

    refute Enum.any?(
             repair["source_candidate_activities"],
             &(&1["type"] == "observe" and &1["scenario_id"] == "leo_1")
           )

    assert Enum.any?(
             downlink_branch["risk_indicators"],
             &(&1["type"] == "downlink_completion_gap" and
                 String.contains?(&1["reason"], "storage margin 0.1 below threshold 0.2"))
           )

    assert_storage_downlink_pressure_score_terms(downlink_branch, artifact, 2)

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy carries low downlink capacity branch through resource-filtered refresh" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:resources, %{"fuel_margin" => 1.0, "downlink_margin" => "0.4"})
      |> put_in(
        [:candidate_refresh_defaults, :resource_filter_policy],
        %{min_downlink_margin: 0.75, min_observe_power_margin: 0.2}
      )

    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 600.0, "output_step_s" => 60.0},
        "activities" => [downlink("existing_dl", 500.0, 560.0)]
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}, %{id: "manual_review", events: [%{type: "operator_note"}]}],
        current_epoch_s: 0.0
      )

    downlink_branch = branch(artifact, "derived_downlink_constrained")

    assert %{
             "type" => "reduced_downlink_capacity",
             "capacity_fraction" => 0.4
           } = Enum.find(downlink_branch["events"], &(&1["type"] == "reduced_downlink_capacity"))

    assert %{
             "type" => "resource_margin_pressure",
             "spacecraft_id" => "leo_1",
             "resource_field" => "downlink_margin",
             "downlink_margin" => 0.4,
             "downlink_margin_threshold" => 0.75,
             "derivation_reasons" => ["downlink_margin_low"]
           } =
             Enum.find(downlink_branch["events"], &(&1["resource_field"] == "downlink_margin"))

    repair = downlink_branch["repair_result"]

    assert [
             %{
               "schema_contract" => "resource_summary.v1",
               "spacecraft_id" => "leo_1",
               "downlink_margin" => 0.4,
               "provenance" => %{
                 "source" => "strategy_branch_event",
                 "event_type" => "resource_margin_pressure"
               }
             }
           ] = repair["source_resource_summaries"]

    assert %{
             "schema_contract" => "resource_filter_report.v1",
             "suppressed_candidate_count" => suppressed_count,
             "suppressed_candidates" => [
               %{"suppressed_reason" => "downlink_margin_below_policy"} | _
             ]
           } = repair["source_resource_filter_report"]

    assert suppressed_count > 0

    refute Enum.any?(
             repair["source_candidate_activities"],
             &(&1["type"] == "downlink" and &1["scenario_id"] == "leo_1")
           )

    downlink_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "derived_downlink_constrained"))

    assert downlink_row["downlink_capacity_margin"] == 0.4
    assert "downlink_capacity_low" in downlink_row["resource_risk_types"]

    assert_storage_downlink_pressure_score_terms(downlink_branch, artifact, 1, 1)

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy carries low fuel preservation branch through resource-filtered refresh" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:resources, %{"fuel_margin" => 0.1})
      |> put_in(
        [:candidate_refresh_defaults, :resource_filter_policy],
        %{min_activity_fuel_margin: 0.25}
      )

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    fuel_branch = branch(artifact, "derived_fuel_preservation")
    event_types = Enum.map(fuel_branch["events"], & &1["type"])

    assert "fuel_preservation_mode" in event_types

    assert %{
             "type" => "resource_margin_pressure",
             "spacecraft_id" => "leo_1",
             "resource_field" => "fuel_margin",
             "fuel_margin" => 0.1,
             "fuel_margin_threshold" => 0.25,
             "derivation_reasons" => ["fuel_margin_low"]
           } = Enum.find(fuel_branch["events"], &(&1["type"] == "resource_margin_pressure"))

    repair = fuel_branch["repair_result"]

    assert [
             %{
               "schema_contract" => "resource_summary.v1",
               "spacecraft_id" => "leo_1",
               "fuel_margin" => 0.1,
               "provenance" => %{
                 "source" => "strategy_branch_event",
                 "event_type" => "resource_margin_pressure"
               }
             }
           ] = repair["source_resource_summaries"]

    assert %{
             "schema_contract" => "resource_filter_report.v1",
             "suppressed_candidate_count" => suppressed_count,
             "suppressed_candidates" => [
               %{"suppressed_reason" => "fuel_margin_below_policy"} | _
             ]
           } = repair["source_resource_filter_report"]

    assert suppressed_count > 0
    assert repair["source_candidate_activities"] == []

    fuel_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "derived_fuel_preservation"))

    assert fuel_row["fuel_margin"] == 0.1
    assert "fuel_margin_low" in fuel_row["resource_risk_types"]
    assert fuel_row["fuel_preservation_mode"] == true

    assert_resource_margin_pressure_score_terms(fuel_branch, artifact)

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives low fuel branch from explicit mission-state resource summaries" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:resources, %{"fuel_margin" => 1.0})
      |> Map.put(:resource_summaries, [
        %{
          "schema_contract" => "resource_summary.v1",
          "spacecraft_id" => "leo_1",
          "fuel_margin" => 0.1,
          "source_quality" => "operator_supplied",
          "provenance" => %{"source" => "operator_summary"}
        }
      ])
      |> put_in(
        [:candidate_refresh_defaults, :resource_filter_policy],
        %{min_activity_fuel_margin: 0.25}
      )

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    fuel_branch = branch(artifact, "derived_fuel_preservation")

    assert %{
             "type" => "resource_margin_pressure",
             "spacecraft_id" => "leo_1",
             "resource_field" => "fuel_margin",
             "fuel_margin" => 0.1,
             "source_quality" => "operator_supplied"
           } = Enum.find(fuel_branch["events"], &(&1["type"] == "resource_margin_pressure"))

    assert fuel_branch["derived_source"] == "mission_state.resource_summaries.fuel_margin"

    fuel_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "derived_fuel_preservation"))

    assert fuel_row["fuel_margin"] == 0.1
    assert "fuel_margin_low" in fuel_row["resource_risk_types"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy fuel preservation keeps every low-fuel resource summary" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:resources, %{"fuel_margin" => 1.0})
      |> Map.put(:resource_summaries, [
        %{
          "schema_contract" => "resource_summary.v1",
          "spacecraft_id" => "leo_1",
          "fuel_margin" => 0.1,
          "source_quality" => "operator_supplied",
          "provenance" => %{"source" => "operator_summary_a"}
        },
        %{
          "schema_contract" => "resource_summary.v1",
          "spacecraft_id" => "leo_2",
          "fuel_margin" => 0.05,
          "source_quality" => "operator_supplied",
          "provenance" => %{"source" => "operator_summary_b"}
        }
      ])
      |> put_in(
        [:candidate_refresh_defaults, :resource_filter_policy],
        %{min_activity_fuel_margin: 0.25}
      )

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    fuel_branch = branch(artifact, "derived_fuel_preservation")

    fuel_events =
      Enum.filter(fuel_branch["events"], &(&1["type"] == "resource_margin_pressure"))

    assert fuel_events
           |> Enum.map(&Map.take(&1, ["spacecraft_id", "fuel_margin", "resource_field"]))
           |> MapSet.new() ==
             MapSet.new([
               %{
                 "spacecraft_id" => "leo_1",
                 "fuel_margin" => 0.1,
                 "resource_field" => "fuel_margin"
               },
               %{
                 "spacecraft_id" => "leo_2",
                 "fuel_margin" => 0.05,
                 "resource_field" => "fuel_margin"
               }
             ])

    assert fuel_branch["repair_result"]["source_resource_summaries"]
           |> Enum.map(&Map.take(&1, ["spacecraft_id", "fuel_margin"]))
           |> MapSet.new() ==
             MapSet.new([
               %{"spacecraft_id" => "leo_1", "fuel_margin" => 0.1},
               %{"spacecraft_id" => "leo_2", "fuel_margin" => 0.05}
             ])

    fuel_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "derived_fuel_preservation"))

    assert fuel_row["fuel_margin"] == 0.05
    assert fuel_row["fuel_preservation_mode"] == true
    assert "fuel_margin_low" in fuel_row["resource_risk_types"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives low downlink branch from explicit downlink capacity margin alias" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:resource_summaries, [
        %{
          "schema_contract" => "resource_summary.v1",
          "spacecraft_id" => "leo_1",
          "downlink_capacity_margin" => 0.4,
          "source_quality" => "operator_supplied",
          "provenance" => %{"source" => "operator_summary"}
        }
      ])
      |> put_in(
        [:candidate_refresh_defaults, :resource_filter_policy],
        %{min_downlink_margin: 0.75}
      )

    artifact =
      strategy(base_plan(%{"activities" => [downlink("existing_dl", 500.0, 560.0)]}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    downlink_branch = branch(artifact, "derived_downlink_constrained")

    assert %{
             "type" => "resource_margin_pressure",
             "resource_field" => "downlink_margin",
             "downlink_margin" => 0.4,
             "source_quality" => "operator_supplied"
           } = Enum.find(downlink_branch["events"], &(&1["resource_field"] == "downlink_margin"))

    assert downlink_branch["derived_source"] == "mission_state.resource_summaries.downlink_margin"

    assert Enum.any?(
             downlink_branch["repair_result"]["source_resource_summaries"],
             &(&1["spacecraft_id"] == "leo_1" and &1["downlink_margin"] == 0.4 and
                 not Map.has_key?(&1, "downlink_capacity_margin"))
           )

    downlink_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "derived_downlink_constrained"))

    assert downlink_row["downlink_capacity_margin"] == 0.4
    assert "downlink_capacity_low" in downlink_row["resource_risk_types"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "explicit mission-state resource summaries override raw low fuel resources for branch derivation" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:resources, %{"fuel_margin" => 0.1})
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

    refute branch(artifact, "derived_fuel_preservation")

    baseline_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "baseline"))

    assert baseline_row["fuel_margin"] == 0.8
    refute "fuel_margin_low" in baseline_row["resource_risk_types"]
  end

  test "strategy derives power constrained branch through resource-filtered refresh" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:resources, %{"fuel_margin" => 1.0, "power_margin" => 0.1})
      |> put_in(
        [:candidate_refresh_defaults, :resource_filter_policy],
        %{min_observe_power_margin: 0.2}
      )

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    power_branch = branch(artifact, "derived_power_constrained_leo_1")
    event = List.first(power_branch["events"])

    assert %{
             "type" => "resource_margin_pressure",
             "spacecraft_id" => "leo_1",
             "resource_field" => "power_margin",
             "power_margin" => 0.1,
             "power_margin_threshold" => 0.2,
             "derivation_reasons" => ["power_margin_low"]
           } = event

    repair = power_branch["repair_result"]

    assert [
             %{
               "schema_contract" => "resource_summary.v1",
               "spacecraft_id" => "leo_1",
               "power_margin" => 0.1,
               "provenance" => %{
                 "source" => "strategy_branch_event",
                 "event_type" => "resource_margin_pressure"
               }
             }
           ] = repair["source_resource_summaries"]

    assert %{
             "schema_contract" => "resource_filter_report.v1",
             "suppressed_candidate_count" => suppressed_count,
             "suppressed_candidates" => [
               %{"suppressed_reason" => "power_margin_below_observe_policy"} | _
             ]
           } = repair["source_resource_filter_report"]

    assert suppressed_count > 0

    refute Enum.any?(
             repair["source_candidate_activities"],
             &(&1["type"] == "observe" and &1["scenario_id"] == "leo_1")
           )

    assert Enum.any?(
             power_branch["risk_indicators"],
             &(&1["type"] == "power_margin_low" and &1["value"] == 0.1)
           )

    power_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "derived_power_constrained_leo_1"))

    assert power_row["power_margin"] == 0.1
    assert "power_margin_low" in power_row["resource_risk_types"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy keeps independent power constrained branches for the same spacecraft" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:resource_summaries, [
        %{
          "schema_contract" => "resource_summary.v1",
          "spacecraft_id" => "leo_1",
          "power_margin" => 0.1,
          "source_quality" => "operator_supplied",
          "provenance" => %{"source" => "operator_summary_a"}
        },
        %{
          "schema_contract" => "resource_summary.v1",
          "spacecraft_id" => "leo_1",
          "power_margin" => 0.05,
          "source_quality" => "operator_supplied",
          "provenance" => %{"source" => "operator_summary_b"}
        }
      ])
      |> put_in(
        [:candidate_refresh_defaults, :resource_filter_policy],
        %{min_observe_power_margin: 0.2}
      )

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    base_id = "derived_power_constrained_leo_1"
    refute branch(artifact, base_id)

    power_branches =
      Enum.filter(artifact["branches"], &String.starts_with?(&1["branch_id"], "#{base_id}_"))

    assert length(power_branches) == 2

    assert MapSet.new(Enum.map(power_branches, & &1["derived_source"])) ==
             MapSet.new(["mission_state.resource_summaries.power_margin"])

    assert power_branches
           |> Enum.flat_map(& &1["events"])
           |> Enum.map(& &1["power_margin"])
           |> Enum.sort() == [0.05, 0.1]

    assert Enum.all?(power_branches, fn branch ->
             Enum.any?(
               branch["risk_indicators"],
               &(&1["type"] == "power_margin_low")
             )
           end)

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives downlink constrained branch from explicit resource summary margins" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:resources, %{"fuel_margin" => 1.0, "storage_margin" => 1.0})
      |> Map.put(:resource_summaries, [
        %{
          "schema_contract" => "resource_summary.v1",
          "spacecraft_id" => "leo_1",
          "storage_margin" => 0.1,
          "downlink_margin" => 0.4,
          "source_quality" => "operator_supplied",
          "provenance" => %{"source" => "operator_summary"}
        }
      ])
      |> put_in(
        [:candidate_refresh_defaults, :resource_filter_policy],
        %{min_observe_storage_margin: 0.2, min_downlink_margin: 0.75}
      )

    artifact =
      strategy(
        base_plan(%{
          "planning_horizon" => %{"duration_s" => 600.0, "output_step_s" => 60.0},
          "activities" => [downlink("existing_dl", 500.0, 560.0)]
        }),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    downlink_branch = branch(artifact, "derived_downlink_constrained")

    assert %{"type" => "downlink_completion_gap", "storage_margin" => 0.1} =
             Enum.find(downlink_branch["events"], &(&1["type"] == "downlink_completion_gap"))

    assert %{
             "type" => "resource_margin_pressure",
             "resource_field" => "downlink_margin",
             "downlink_margin" => 0.4,
             "source_quality" => "operator_supplied"
           } = Enum.find(downlink_branch["events"], &(&1["resource_field"] == "downlink_margin"))

    assert %{
             "type" => "resource_margin_pressure",
             "resource_field" => "storage_margin",
             "storage_margin" => 0.1,
             "source_quality" => "operator_supplied"
           } = Enum.find(downlink_branch["events"], &(&1["resource_field"] == "storage_margin"))

    downlink_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "derived_downlink_constrained"))

    assert downlink_row["storage_margin"] == 0.1
    assert downlink_row["downlink_capacity_margin"] == 0.4
    assert "storage_margin_low" in downlink_row["resource_risk_types"]
    assert "downlink_capacity_low" in downlink_row["resource_risk_types"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy downlink constrained branch keeps every low downlink and storage summary" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:resources, %{"fuel_margin" => 1.0, "storage_margin" => 1.0})
      |> Map.put(:resource_summaries, [
        %{
          "schema_contract" => "resource_summary.v1",
          "spacecraft_id" => "leo_2",
          "storage_margin" => 0.1,
          "downlink_margin" => 0.4,
          "source_quality" => "operator_supplied",
          "provenance" => %{"source" => "operator_summary_b"}
        },
        %{
          "schema_contract" => "resource_summary.v1",
          "spacecraft_id" => "leo_1",
          "storage_margin" => 0.05,
          "downlink_margin" => 0.3,
          "source_quality" => "telemetry_estimate",
          "provenance" => %{"source" => "operator_summary_a"}
        }
      ])
      |> put_in(
        [:candidate_refresh_defaults, :resource_filter_policy],
        %{min_observe_storage_margin: 0.2, min_downlink_margin: 0.75}
      )

    artifact =
      strategy(
        base_plan(%{
          "planning_horizon" => %{"duration_s" => 600.0, "output_step_s" => 60.0},
          "activities" => [downlink("existing_dl", 500.0, 560.0)]
        }),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    downlink_branch = branch(artifact, "derived_downlink_constrained")

    pressure_events =
      Enum.filter(downlink_branch["events"], &(&1["type"] == "resource_margin_pressure"))

    assert pressure_events
           |> Enum.filter(&(&1["resource_field"] == "downlink_margin"))
           |> Enum.map(&{&1["spacecraft_id"], &1["downlink_margin"], &1["source_quality"]}) == [
             {"leo_1", 0.3, "telemetry_estimate"},
             {"leo_2", 0.4, "operator_supplied"}
           ]

    assert pressure_events
           |> Enum.filter(&(&1["resource_field"] == "storage_margin"))
           |> Enum.map(&{&1["spacecraft_id"], &1["storage_margin"], &1["source_quality"]}) == [
             {"leo_1", 0.05, "telemetry_estimate"},
             {"leo_2", 0.1, "operator_supplied"}
           ]

    downlink_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "derived_downlink_constrained"))

    assert downlink_row["storage_margin"] == 0.05
    assert downlink_row["downlink_capacity_margin"] == 0.3

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy does not derive power constrained branch above threshold" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:resources, %{"fuel_margin" => 1.0, "power_margin" => 0.8})

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    refute branch(artifact, "derived_power_constrained_leo_1")
  end

  test "strategy derives power constrained branch from numeric string resource summary margin" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:resource_summaries, [
        %{
          "schema_contract" => "resource_summary.v1",
          "spacecraft_id" => "leo_1",
          "power_margin" => "0.05",
          "source_quality" => "telemetry_estimate",
          "provenance" => %{"source" => "operator_summary"}
        }
      ])

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        branch_generation_policy: %{power_margin_threshold: "0.2"},
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    power_branch = branch(artifact, "derived_power_constrained_leo_1")

    assert %{
             "type" => "resource_margin_pressure",
             "spacecraft_id" => "leo_1",
             "resource_field" => "power_margin",
             "power_margin" => 0.05,
             "power_margin_threshold" => 0.2,
             "source_quality" => "telemetry_estimate"
           } = List.first(power_branch["events"])

    assert Enum.any?(
             power_branch["risk_indicators"],
             &(&1["type"] == "power_margin_low" and &1["value"] == 0.05)
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives thermal constrained branch from explicit resource summary margins" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:resource_summaries, [
        %{
          "schema_contract" => "resource_summary.v1",
          "spacecraft_id" => "leo_1",
          "thermal_margin_c" => 1.5,
          "source_quality" => "operator_supplied",
          "provenance" => %{"source" => "operator_summary"}
        }
      ])

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        branch_generation_policy: %{thermal_margin_c_threshold: "2.0"},
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    thermal_branch = branch(artifact, "derived_thermal_constrained_leo_1")

    assert %{
             "type" => "resource_margin_pressure",
             "spacecraft_id" => "leo_1",
             "resource_field" => "thermal_margin_c",
             "thermal_margin_c" => 1.5,
             "thermal_margin_c_threshold" => 2.0,
             "derivation_reasons" => ["thermal_margin_low"],
             "source_quality" => "operator_supplied"
           } = List.first(thermal_branch["events"])

    assert Enum.any?(
             thermal_branch["repair_result"]["source_resource_summaries"],
             &(&1["spacecraft_id"] == "leo_1" and &1["thermal_margin_c"] == 1.5 and
                 get_in(&1, ["provenance", "event_type"]) == "resource_margin_pressure")
           )

    assert %{"min_activity_thermal_margin_c" => 2.0} =
             thermal_branch["repair_result"]["source_resource_filter_report"]["policy"]

    assert Enum.any?(
             thermal_branch["repair_result"]["source_resource_filter_report"][
               "suppressed_candidates"
             ],
             &(&1["suppressed_reason"] == "thermal_margin_below_policy" and
                 &1["resource_blocking_dimension"] == "thermal" and
                 &1["thermal_margin_c"] == 1.5)
           )

    assert Enum.any?(
             thermal_branch["risk_indicators"],
             &(&1["type"] == "thermal_margin_c_low" and &1["value"] == 1.5)
           )

    thermal_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "derived_thermal_constrained_leo_1"))

    assert thermal_row["thermal_margin_c"] == 1.5
    assert "thermal_margin_low" in thermal_row["resource_risk_types"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  defp assert_storage_downlink_pressure_score_terms(
         branch,
         artifact,
         expected_pressure_count,
         extra_split_pressure_count \\ 0
       ) do
    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    storage_downlink_pressure_count =
      Enum.count(
        branch["risk_indicators"],
        &(&1["type"] in [
            "storage_overflow",
            "downlink_shortfall",
            "storage_margin_low",
            "downlink_margin_low"
          ])
      )

    assert storage_downlink_pressure_count == expected_pressure_count

    assert branch["score_terms"]["storage_downlink_pressure_penalty"] ==
             -storage_downlink_pressure_count * risk_weight

    assert branch["score_terms"]["risk_penalty"] ==
             -(length(branch["risk_indicators"]) -
                 storage_downlink_pressure_count - extra_split_pressure_count) * risk_weight

    assert "storage_downlink_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == branch["branch_id"] and
                 &1["term_key"] == "storage_downlink_pressure_penalty" and
                 &1["value"] < 0.0)
           )
  end

  defp assert_resource_margin_pressure_score_terms(branch, artifact) do
    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    resource_margin_pressure_count =
      Enum.count(
        branch["risk_indicators"],
        &(&1["type"] in [
            "fuel_margin_low",
            "power_margin_low",
            "thermal_margin_c_low"
          ])
      )

    assert resource_margin_pressure_count > 0

    assert branch["score_terms"]["resource_margin_pressure_penalty"] ==
             -resource_margin_pressure_count * risk_weight

    assert branch["score_terms"]["risk_penalty"] ==
             -(length(branch["risk_indicators"]) - resource_margin_pressure_count) *
               risk_weight

    assert "resource_margin_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == branch["branch_id"] and
                 &1["term_key"] == "resource_margin_pressure_penalty" and
                 &1["value"] < 0.0)
           )
  end
end
