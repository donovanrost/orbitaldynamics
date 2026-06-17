defmodule OrbitalDynamics.Schema.ResourceContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{ResourceFilter, ResourceSummary, Schema}

  test "exports nested resource projection report row schema" do
    assert {:ok, schema} = Schema.json_schema("resource_projection_report.v1")
    assert {:ok, flow_summary_schema} = Schema.json_schema("resource_projection_flow_summary.v1")

    row_schema = get_in(schema, ["properties", "projected_resources", "items"])

    assert row_schema["type"] == "object"
    assert "spacecraft_id" in row_schema["required"]

    assert get_in(schema, ["properties", "model", "enum"]) == [
             "thin_battery_handoff_resource_projection_fixture",
             "thin_campaign_selected_activity_resource_projection",
             "thin_repaired_activity_resource_projection",
             "thin_selected_activity_resource_projection",
             "thin_stale_derived_margin_resource_projection_fixture",
             "thin_strategy_branch_activity_resource_projection"
           ]

    assert get_in(schema, ["properties", "source", "type"]) == "string"

    assert get_in(schema, ["properties", "input_resource_summary_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(schema, ["properties", "invalid_activity_input_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(schema, ["properties", "resource_pressure_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(schema, ["properties", "resource_pressure_spacecraft_ids", "items", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(schema, [
             "properties",
             "resource_pressure_activity_ids_by_type",
             "additionalProperties",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, ["properties", "spacecraft_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    Enum.each(
      ["activity_count", "effective_activity_count", "observation_count", "downlink_count"],
      fn field ->
        assert get_in(row_schema, ["properties", field]) == %{
                 "type" => "integer",
                 "minimum" => 0
               }
      end
    )

    assert get_in(row_schema, ["properties", "ignored_activity_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(row_schema, ["properties", "ignored_activity_ids", "items", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, ["properties", "projected_storage_margin", "type"]) == "number"

    Enum.each(
      [
        "projected_storage_overflow_mb",
        "projected_downlink_shortfall_mb",
        "storage_limited_downlinked_mb",
        "unused_downlink_capacity_mb"
      ],
      fn field ->
        assert get_in(row_schema, ["properties", field]) == %{
                 "type" => "number",
                 "minimum" => 0.0
               }
      end
    )

    assert get_in(row_schema, ["properties", "resource_source_quality", "type"]) == "string"

    assert get_in(row_schema, ["properties", "resource_trust_boundary_status", "type"]) ==
             "string"

    assert get_in(row_schema, ["properties", "resource_pressure_status", "type"]) == "string"

    assert get_in(row_schema, ["properties", "resource_pressure_types", "items", "type"]) ==
             "string"

    assert get_in(row_schema, ["properties", "resource_provenance", "type"]) == "object"
    assert get_in(row_schema, ["properties", "payload_available", "type"]) == "boolean"
    assert get_in(row_schema, ["properties", "antenna_available", "type"]) == "boolean"

    Enum.each(
      [
        "battery_capacity_wh",
        "battery_energy_used_wh",
        "starting_battery_energy_used_wh",
        "projected_battery_energy_used_wh",
        "projected_battery_overuse_wh"
      ],
      fn field ->
        assert get_in(row_schema, ["properties", field]) == %{
                 "type" => "number",
                 "minimum" => 0.0
               }
      end
    )

    Enum.each(
      ["battery_state_of_charge", "projected_battery_state_of_charge", "projected_power_margin"],
      fn field ->
        assert get_in(row_schema, ["properties", field]) == %{
                 "type" => "number",
                 "minimum" => 0.0,
                 "maximum" => 1.0
               }
      end
    )

    assert get_in(row_schema, ["properties", "warnings", "items", "type"]) == "string"

    assert get_in(row_schema, [
             "properties",
             "approval_requirements",
             "items",
             "properties",
             "schema_contract",
             "const"
           ]) == "approval_requirement.v1"

    assert get_in(row_schema, [
             "properties",
             "approval_rule_matches",
             "items",
             "properties",
             "rule_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    flow_row_schema = get_in(row_schema, ["properties", "activity_resource_flow", "items"])

    assert get_in(flow_row_schema, ["properties", "planned_latency_s"]) == %{
             "type" => "number",
             "minimum" => 0.0
           }

    assert get_in(flow_row_schema, ["properties", "completed_fraction"]) == %{
             "type" => "number",
             "minimum" => 0.0,
             "maximum" => 1.0
           }

    assert get_in(flow_row_schema, ["properties", "battery_state_of_charge_after"]) == %{
             "type" => "number",
             "minimum" => 0.0,
             "maximum" => 1.0
           }

    assert get_in(flow_row_schema, ["properties", "latency_status", "enum"]) == [
             "within_limit",
             "late"
           ]

    assert get_in(flow_row_schema, ["properties", "resource_effect_status", "enum"]) ==
             ResourceSummary.capabilities().roll_forward_resource_effect_statuses

    assert get_in(flow_summary_schema, ["properties", "source"]) == %{"type" => "string"}

    Enum.each(["resource_flow_status", "resource_pressure_status", "latency_status"], fn field ->
      assert get_in(flow_summary_schema, ["properties", field]) == %{
               "type" => "string",
               "enum" => ["clear", "review_required"]
             }
    end)

    assert get_in(flow_summary_schema, [
             "properties",
             "actual_data_volume_evidence_count"
           ]) == %{"type" => "integer", "minimum" => 0}

    Enum.each(["total_actual_data_volume_mb", "total_data_volume_delta_mb"], fn field ->
      assert get_in(flow_summary_schema, ["properties", field]) == %{"type" => "number"}
    end)

    Enum.each(
      [
        "actual_data_volume_under_delivered_activity_ids",
        "actual_data_volume_over_delivered_activity_ids",
        "actual_data_volume_exact_activity_ids"
      ],
      fn field ->
        assert get_in(flow_summary_schema, ["properties", field, "items", "pattern"]) ==
                 Schema.identity_policy()["stable_id_pattern"]
      end
    )

    assert get_in(schema, [
             "properties",
             "resource_source_quality_counts",
             "additionalProperties"
           ]) == %{"type" => "integer", "minimum" => 0}

    assert get_in(schema, [
             "properties",
             "resource_trust_boundary_status_counts",
             "additionalProperties"
           ]) == %{"type" => "integer", "minimum" => 0}

    assert get_in(schema, ["properties", "invalid_activity_input_ids", "items", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(schema, ["properties", "model_limits", "const"]) ==
             OrbitalDynamics.ResourceProjection.capabilities().known_limits
             |> Enum.map(&Atom.to_string/1)

    resource_projection_report = read_json!("study_results/resource_projection_report_v1.json")

    invalid_payload_available =
      put_in(
        resource_projection_report,
        ["projected_resources", Access.at(0), "payload_available"],
        "yes"
      )

    assert {:error, payload_available_report} =
             Schema.validate_artifact(invalid_payload_available,
               schema_contract: "resource_projection_report.v1"
             )

    assert Enum.any?(
             payload_available_report["errors"],
             &(&1["path"] == "$.projected_resources[0].payload_available")
           )

    invalid_resource_pressure_types =
      put_in(
        resource_projection_report,
        ["projected_resources", Access.at(0), "resource_pressure_types"],
        ["storage_overflow", 42]
      )

    assert {:error, resource_pressure_types_report} =
             Schema.validate_artifact(invalid_resource_pressure_types,
               schema_contract: "resource_projection_report.v1"
             )

    assert Enum.any?(
             resource_pressure_types_report["errors"],
             &(&1["path"] == "$.projected_resources[0].resource_pressure_types[1]")
           )

    invalid_resource_provenance =
      put_in(
        resource_projection_report,
        ["projected_resources", Access.at(0), "resource_provenance"],
        ["operator"]
      )

    assert {:error, resource_provenance_report} =
             Schema.validate_artifact(invalid_resource_provenance,
               schema_contract: "resource_projection_report.v1"
             )

    assert Enum.any?(
             resource_provenance_report["errors"],
             &(&1["path"] == "$.projected_resources[0].resource_provenance")
           )

    invalid_ignored_activity_count =
      put_in(
        resource_projection_report,
        ["projected_resources", Access.at(0), "ignored_activity_count"],
        -1
      )

    assert {:error, ignored_activity_count_report} =
             Schema.validate_artifact(invalid_ignored_activity_count,
               schema_contract: "resource_projection_report.v1"
             )

    assert Enum.any?(
             ignored_activity_count_report["errors"],
             &(&1["path"] == "$.projected_resources[0].ignored_activity_count")
           )

    invalid_ignored_activity_ids =
      put_in(
        resource_projection_report,
        ["projected_resources", Access.at(0), "ignored_activity_ids"],
        ["bad id"]
      )

    assert {:error, ignored_activity_ids_report} =
             Schema.validate_artifact(invalid_ignored_activity_ids,
               schema_contract: "resource_projection_report.v1"
             )

    assert Enum.any?(
             ignored_activity_ids_report["errors"],
             &(&1["path"] == "$.projected_resources[0].ignored_activity_ids[0]")
           )

    invalid_projected_storage_overflow =
      put_in(
        resource_projection_report,
        ["projected_resources", Access.at(0), "projected_storage_overflow_mb"],
        -0.1
      )

    assert {:error, projected_storage_overflow_report} =
             Schema.validate_artifact(invalid_projected_storage_overflow,
               schema_contract: "resource_projection_report.v1"
             )

    assert Enum.any?(
             projected_storage_overflow_report["errors"],
             &(&1["path"] == "$.projected_resources[0].projected_storage_overflow_mb")
           )

    invalid_unused_downlink_capacity =
      put_in(
        resource_projection_report,
        ["projected_resources", Access.at(0), "unused_downlink_capacity_mb"],
        "5.0"
      )

    assert {:error, unused_downlink_capacity_report} =
             Schema.validate_artifact(invalid_unused_downlink_capacity,
               schema_contract: "resource_projection_report.v1"
             )

    assert Enum.any?(
             unused_downlink_capacity_report["errors"],
             &(&1["path"] == "$.projected_resources[0].unused_downlink_capacity_mb")
           )

    invalid_battery_capacity =
      put_in(
        resource_projection_report,
        ["projected_resources", Access.at(0), "battery_capacity_wh"],
        -1.0
      )

    assert {:error, battery_capacity_report} =
             Schema.validate_artifact(invalid_battery_capacity,
               schema_contract: "resource_projection_report.v1"
             )

    assert Enum.any?(
             battery_capacity_report["errors"],
             &(&1["path"] == "$.projected_resources[0].battery_capacity_wh")
           )

    invalid_projected_battery_state_of_charge =
      put_in(
        resource_projection_report,
        ["projected_resources", Access.at(0), "projected_battery_state_of_charge"],
        1.2
      )

    assert {:error, projected_battery_state_of_charge_report} =
             Schema.validate_artifact(invalid_projected_battery_state_of_charge,
               schema_contract: "resource_projection_report.v1"
             )

    assert Enum.any?(
             projected_battery_state_of_charge_report["errors"],
             &(&1["path"] == "$.projected_resources[0].projected_battery_state_of_charge")
           )

    invalid_projected_power_margin =
      put_in(
        resource_projection_report,
        ["projected_resources", Access.at(0), "projected_power_margin"],
        "0.64"
      )

    assert {:error, projected_power_margin_report} =
             Schema.validate_artifact(invalid_projected_power_margin,
               schema_contract: "resource_projection_report.v1"
             )

    assert Enum.any?(
             projected_power_margin_report["errors"],
             &(&1["path"] == "$.projected_resources[0].projected_power_margin")
           )

    battery_handoff_report =
      read_json!("study_results/resource_projection_battery_handoff_v1.json")

    invalid_approval_requirement =
      put_in(
        battery_handoff_report,
        [
          "projected_resources",
          Access.at(0),
          "approval_requirements",
          Access.at(0),
          "activity_id"
        ],
        "bad id"
      )

    assert {:error, approval_requirement_report} =
             Schema.validate_artifact(invalid_approval_requirement,
               schema_contract: "resource_projection_report.v1"
             )

    assert Enum.any?(
             approval_requirement_report["errors"],
             &(&1["path"] ==
                 "$.projected_resources[0].approval_requirements[0].activity_id")
           )

    invalid_approval_rule_match =
      put_in(
        battery_handoff_report,
        ["projected_resources", Access.at(0), "approval_rule_matches", Access.at(0), "rule_id"],
        "bad id"
      )

    assert {:error, approval_rule_match_report} =
             Schema.validate_artifact(invalid_approval_rule_match,
               schema_contract: "resource_projection_report.v1"
             )

    assert Enum.any?(
             approval_rule_match_report["errors"],
             &(&1["path"] == "$.projected_resources[0].approval_rule_matches[0].rule_id")
           )
  end

  test "exports nested resource filter report suppressed candidate schema" do
    assert {:ok, schema} = Schema.json_schema("resource_filter_report.v1")

    row_schema = get_in(schema, ["properties", "suppressed_candidates", "items"])

    assert row_schema["type"] == "object"
    assert "suppressed_reason" in row_schema["required"]

    assert get_in(schema, ["properties", "model", "const"]) ==
             "resource_summary_availability_and_margin_filter"

    assert get_in(schema, ["properties", "input_candidate_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(schema, ["properties", "duplicate_suppressed_candidate_row_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(schema, ["properties", "resource_source_quality_counts", "type"]) == "object"

    assert get_in(schema, ["properties", "resource_trust_boundary_status_counts", "type"]) ==
             "object"

    assert get_in(schema, [
             "properties",
             "suppressed_resource_trust_boundary_status_counts",
             "type"
           ]) == "object"

    assert get_in(schema, ["properties", "invalid_candidate_input_ids", "items", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, ["properties", "scenario_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, ["properties", "ground_station_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, ["properties", "station_availability", "type"]) == "string"
  end

  test "validates checked-in resource summary fixture" do
    summary = read_json!("study_results/resource_summary_v1.json")

    generated_summary =
      summary
      |> OrbitalDynamics.resource_summary_from_map!()
      |> OrbitalDynamics.resource_summary_to_map()

    assert generated_summary == summary

    assert {:ok, %{"schema_contract" => "resource_summary.v1"}} =
             Schema.validate_artifact(summary)

    assert %{
             "schema_contract" => "resource_summary.v1",
             "spacecraft_id" => "leo_1",
             "mode" => "degraded",
             "fuel_margin" => 0.82,
             "power_margin" => 0.74,
             "battery_capacity_wh" => 1200.0,
             "battery_energy_used_wh" => 312.0,
             "battery_state_of_charge" => 0.74,
             "thermal_margin_c" => -2.5,
             "storage_capacity_mb" => 1000.0,
             "storage_used_mb" => 250.0,
             "storage_margin" => 0.75,
             "downlink_capacity_mb" => 600.0,
             "downlink_margin" => 0.65,
             "spacecraft_available" => false,
             "source_quality" => "operator_supplied",
             "trust_boundary" => "operator_declared_resource_summary",
             "suppressed_activity_types" => ["observe", "command"],
             "incompatible_activity_types" => ["command", "health_check"],
             "payload_available" => false,
             "antenna_available" => true,
             "degraded" => true,
             "assumptions" => %{
               "model" => "operator_summary",
               "source" => "campaign_manifest_demo"
             },
             "provenance" => %{
               "source" => "ops",
               "trust_boundary" => "operator_declared_resource_summary"
             }
           } = summary
  end

  test "validates checked-in resource filter summary fixture" do
    report = read_json!("study_results/resource_filter_report_v1.json")
    summary = read_json!("study_results/resource_filter_summary_v1.json")

    generated_summary = OrbitalDynamics.resource_filter_summary(report)

    assert generated_summary == summary

    assert {:ok, %{"schema_contract" => "resource_filter_summary.v1"}} =
             Schema.validate_artifact(summary)

    assert %{
             "source_artifact_type" => "resource_filter_report.v1",
             "input_candidate_count" => 3,
             "kept_candidate_count" => 1,
             "suppressed_candidate_count" => 2,
             "suppression_review_status" => "review_required",
             "suppressed_candidate_ids" => [
               "leo_1_downlink_equator_prime_1",
               "leo_1_observe_target_a_1"
             ],
             "suppressed_reason_counts" => %{
               "downlink_margin_below_policy" => 1,
               "storage_margin_below_observe_policy" => 1
             },
             "suppressed_candidate_ids_by_reason" => %{
               "downlink_margin_below_policy" => ["leo_1_downlink_equator_prime_1"],
               "storage_margin_below_observe_policy" => ["leo_1_observe_target_a_1"]
             },
             "resource_blocking_dimension_counts" => %{"downlink" => 1, "storage" => 1},
             "suppressed_candidate_ids_by_resource_blocking_dimension" => %{
               "downlink" => ["leo_1_downlink_equator_prime_1"],
               "storage" => ["leo_1_observe_target_a_1"]
             },
             "suppressed_candidate_ids_by_scenario_id" => %{
               "leo_1" => ["leo_1_downlink_equator_prime_1", "leo_1_observe_target_a_1"]
             },
             "suppressed_resource_source_quality_counts" => %{"operator_supplied" => 2},
             "suppressed_candidate_ids_by_resource_source_quality" => %{
               "operator_supplied" => [
                 "leo_1_downlink_equator_prime_1",
                 "leo_1_observe_target_a_1"
               ]
             },
             "suppressed_resource_trust_boundary_status_counts" => %{"missing" => 2},
             "suppressed_candidate_ids_by_resource_trust_boundary_status" => %{
               "missing" => ["leo_1_downlink_equator_prime_1", "leo_1_observe_target_a_1"]
             },
             "invalid_candidate_input_count" => 0,
             "invalid_candidate_input_ids" => [],
             "invalid_resource_summary_input_count" => 0,
             "invalid_resource_summary_input_ids" => [],
             "duplicate_suppressed_candidate_id_count" => 0,
             "duplicate_suppressed_candidate_row_count" => 0,
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_schedule_mutation",
               "operator_authority" => "not_granted_by_resource_filter_summary",
               "resource_state_propagation" => "not_performed",
               "source" => "resource_filter_report.v1"
             }
           } = summary

    assert Enum.map(summary["review_rows"], & &1["id"]) == [
             "leo_1_observe_target_a_1",
             "leo_1_downlink_equator_prime_1"
           ]

    assert summary["model_limits"] == report["model_limits"]
  end

  test "validates checked-in resource filter report fixture regenerates through public facade" do
    report = read_json!("study_results/resource_filter_report_v1.json")

    candidates = [
      %{
        id: :leo_1_observe_target_a_1,
        type: :observe,
        scenario_id: :leo_1,
        source_window_id: :"window:leo_1:target_visibility:target_a:1",
        starts_at_s: 60.0,
        ends_at_s: 180.0
      },
      %{
        id: :leo_1_downlink_equator_prime_1,
        type: :downlink,
        scenario_id: :leo_1,
        source_window_id: :"window:leo_1:ground_station_access:equator_prime:1",
        ground_station_id: :equator_prime,
        station_availability: :available,
        starts_at_s: 200.0,
        ends_at_s: 320.0
      },
      %{
        id: :leo_1_command_equator_prime_1,
        type: :command,
        scenario_id: :leo_1,
        source_window_id: :"window:leo_1:ground_station_access:equator_prime:command:1",
        ground_station_id: :equator_prime,
        starts_at_s: 400.0,
        ends_at_s: 430.0
      }
    ]

    resource_summaries = [
      %{
        source_quality: :operator_supplied,
        downlink_margin: 0.1,
        storage_margin: 0.1,
        power_margin: 0.8,
        fuel_margin: 0.8
      }
    ]

    generated_report =
      OrbitalDynamics.resource_filter_report(candidates, resource_summaries,
        policy: %{
          min_activity_fuel_margin: 0.1,
          min_observe_storage_margin: 0.2,
          min_downlink_margin: 0.2
        }
      )

    assert generated_report == report

    assert {:ok, %{"schema_contract" => "resource_filter_report.v1"}} =
             Schema.validate_artifact(report)

    expected_assumptions = resource_filter_report_capability_assumptions()

    assert Map.take(report["assumptions"], Map.keys(expected_assumptions)) == expected_assumptions

    assert report["model"] == "resource_summary_availability_and_margin_filter"

    assert report["model_limits"] == [
             "artifact_level_only",
             "externally_supplied_resource_summary",
             "no_subsystem_simulation",
             "no_resource_time_propagation",
             "no_schedule_mutation"
           ]

    assert report["policy"] == %{
             "min_activity_fuel_margin" => 0.1,
             "min_downlink_margin" => 0.2,
             "min_observe_storage_margin" => 0.2
           }

    assert %{
             "input_candidate_count" => 3,
             "kept_candidate_count" => 1,
             "suppressed_candidate_count" => 2,
             "input_resource_summary_count" => 1,
             "valid_resource_summary_count" => 1,
             "invalid_resource_summary_input_count" => 0,
             "invalid_resource_summary_input_ids" => [],
             "invalid_resource_summary_inputs" => [],
             "invalid_candidate_input_count" => 0,
             "invalid_candidate_input_ids" => [],
             "duplicate_suppressed_candidate_id_count" => 0,
             "duplicate_suppressed_candidate_row_count" => 0,
             "resource_source_quality_counts" => %{"operator_supplied" => 1},
             "resource_trust_boundary_status_counts" => %{"missing" => 1},
             "suppressed_resource_source_quality_counts" => %{"operator_supplied" => 2},
             "suppressed_resource_trust_boundary_status_counts" => %{"missing" => 2}
           } = report

    assert report["suppressed_candidate_ids_by_resource_source_quality"] == %{
             "operator_supplied" => [
               "leo_1_downlink_equator_prime_1",
               "leo_1_observe_target_a_1"
             ]
           }

    assert report["suppressed_candidate_ids_by_resource_trust_boundary_status"] == %{
             "missing" => ["leo_1_downlink_equator_prime_1", "leo_1_observe_target_a_1"]
           }

    rows_by_id = Map.new(report["suppressed_candidates"], &{&1["id"], &1})

    assert %{
             "type" => "observe",
             "scenario_id" => "leo_1",
             "suppressed_reason" => "storage_margin_below_observe_policy",
             "resource_blocking_dimension" => "storage",
             "resource_source_quality" => "operator_supplied",
             "resource_trust_boundary_status" => "missing",
             "storage_margin" => 0.1,
             "downlink_margin" => 0.1,
             "power_margin" => 0.8,
             "fuel_margin" => 0.8,
             "source_resource_summary" => %{"source_quality" => "operator_supplied"}
           } = rows_by_id["leo_1_observe_target_a_1"]

    assert %{
             "type" => "downlink",
             "direction" => "downlink",
             "scenario_id" => "leo_1",
             "ground_station_id" => "equator_prime",
             "station_availability" => "available",
             "suppressed_reason" => "downlink_margin_below_policy",
             "resource_blocking_dimension" => "downlink",
             "resource_source_quality" => "operator_supplied",
             "resource_trust_boundary_status" => "missing",
             "storage_margin" => 0.1,
             "downlink_margin" => 0.1,
             "power_margin" => 0.8,
             "fuel_margin" => 0.8,
             "source_resource_summary" => %{"source_quality" => "operator_supplied"}
           } = rows_by_id["leo_1_downlink_equator_prime_1"]
  end

  test "validates checked-in resource projection flow summary fixture" do
    report = read_json!("study_results/resource_projection_report_v1.json")
    summary = read_json!("study_results/resource_projection_flow_summary_v1.json")

    generated_summary = OrbitalDynamics.resource_projection_flow_summary(report)

    assert generated_summary == summary

    assert {:ok, %{"schema_contract" => "resource_projection_flow_summary.v1"}} =
             Schema.validate_artifact(summary)

    assert %{
             "schema_contract" => "resource_projection_flow_summary.v1",
             "schema_version" => 1,
             "model" => "artifact_only_selected_activity_resource_flow_summary",
             "source" => "campaign.resource_summaries",
             "input_resource_summary_count" => 1,
             "activity_count" => 1,
             "valid_activity_count" => 1,
             "flow_row_count" => 1,
             "projected_resource_count" => 1,
             "valid_resource_summary_count" => 1,
             "resource_flow_status" => "clear",
             "resource_pressure_status" => "clear",
             "resource_pressure_count" => 0,
             "ignored_activity_count" => 0,
             "ignored_activity_reason_counts" => %{},
             "ignored_activity_ids" => [],
             "ignored_activity_ids_by_reason" => %{},
             "invalid_activity_input_count" => 0,
             "invalid_activity_input_ids" => [],
             "invalid_activity_inputs" => [],
             "invalid_resource_summary_input_count" => 0,
             "invalid_resource_summary_input_ids" => [],
             "invalid_resource_summary_inputs" => [],
             "total_battery_energy_consumed_wh" => 120.0,
             "total_battery_energy_generated_wh" => +0.0,
             "net_battery_energy_delta_wh" => 120.0,
             "peak_battery_overuse_wh" => +0.0,
             "total_storage_produced_mb" => +0.0,
             "total_storage_overflow_mb" => +0.0,
             "total_storage_limited_downlinked_mb" => +0.0,
             "total_downlink_shortfall_mb" => +0.0,
             "total_unused_downlink_capacity_mb" => +0.0,
             "total_planned_downlink_mb" => +0.0,
             "actual_data_volume_evidence_count" => 0,
             "total_actual_data_volume_mb" => +0.0,
             "total_data_volume_delta_mb" => +0.0,
             "actual_data_volume_under_delivered_activity_ids" => [],
             "actual_data_volume_over_delivered_activity_ids" => [],
             "actual_data_volume_exact_activity_ids" => [],
             "total_projected_storage_remaining_mb" => 750,
             "total_projected_downlink_remaining_mb" => 600,
             "minimum_projected_storage_remaining_mb" => 750,
             "minimum_projected_downlink_remaining_mb" => 600,
             "resource_pressure_types" => [],
             "resource_pressure_activity_ids_by_type" => %{},
             "resource_pressure_spacecraft_ids_by_type" => %{},
             "resource_pressure_source_window_ids_by_type" => %{},
             "resource_pressure_ground_station_ids_by_type" => %{},
             "resource_pressure_capacity_fractions_by_type" => %{},
             "resource_pressure_station_calendar_directions_by_type" => %{},
             "resource_pressure_station_calendar_entry_ids_by_type" => %{},
             "resource_pressure_station_calendar_provider_entry_ids_by_type" => %{},
             "resource_pressure_station_calendar_provider_ids_by_type" => %{},
             "resource_pressure_spacecraft_ids" => [],
             "assumptions" => %{
               "activity_status_model" =>
                 "terminal_or_approval_rejected_activities_are_audited_with_zero_projected_resource_effect",
               "execution_boundary" => "artifact_only_no_schedule_mutation",
               "latency_model" => "declared_activity_timestamps_only",
               "projection_model" => "thin_time_ordered_resource_roll_forward",
               "realized_state_reconciliation" => "not_performed",
               "scope" => "selected_activity_resource_flow_and_pressure_evidence",
               "source" => "campaign.resource_summaries",
               "subsystem_model_capability_contract" => "subsystem_model_capability.v1",
               "subsystem_model_capability_ids" => [
                 "subsystem.power.battery.energy_storage.planning_grade",
                 "subsystem.data_recorder.storage_buffer.planning_grade"
               ],
               "subsystem_model_capability_ids_by_resource" => %{
                 "battery" => "subsystem.power.battery.energy_storage.planning_grade",
                 "storage" => "subsystem.data_recorder.storage_buffer.planning_grade"
               },
               "subsystem_simulation" => "not_performed"
             }
           } = summary

    assert [%{"spacecraft_id" => "leo_1", "resource_pressure_status" => "nominal"}] =
             summary["projected_resources"]

    assert [
             %{
               "activity_id" => "leo_1_observe_target_a_1",
               "activity_status" => "planned",
               "resource_effect_status" => "projected",
               "resource_effect_reason" => "active_planning_activity",
               "battery_energy_consumed_wh" => 120,
               "battery_energy_generated_wh" => 0,
               "battery_energy_delta_wh" => 120,
               "storage_used_after_mb" => 250,
               "downlink_used_after_mb" => 0
             }
           ] = summary["activity_resource_flow"]

    assert summary["model_limits"] == report["model_limits"]
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end

  defp resource_filter_report_capability_assumptions do
    capabilities = ResourceFilter.capabilities()

    %{
      "resource_filter_policy_fields" => capabilities.resource_filter_policy_fields,
      "resource_availability_aliases" => capabilities.resource_availability_aliases,
      "resource_degraded_aliases" => capabilities.resource_degraded_aliases,
      "resource_margin_aliases" => capabilities.resource_margin_aliases,
      "resource_power_margin_source_aliases" => capabilities.resource_power_margin_source_aliases,
      "resource_availability_true_tokens" => capabilities.resource_availability_true_tokens,
      "resource_availability_false_tokens" => capabilities.resource_availability_false_tokens,
      "provider_direction_aliases" => capabilities.provider_direction_aliases,
      "station_calendar_direction_aliases" => capabilities.station_calendar_direction_aliases,
      "provider_result_map_value_keys" => capabilities.provider_result_map_value_keys,
      "candidate_stable_identity_fields" => capabilities.candidate_stable_identity_fields,
      "station_calendar_id_list_fields" => capabilities.station_calendar_id_list_fields,
      "suppression_reasons" => capabilities.suppression_reasons,
      "row_review_statuses" => capabilities.row_review_statuses
    }
  end
end
