defmodule OrbitalDynamics.ResourceProjectionTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, OperatorReview, ResourceProjection, Schema}

  test "declares resource projection capabilities" do
    assert %{
             artifact_contract: "resource_projection_report.v1",
             flow_summary_artifact_contract: "resource_projection_flow_summary.v1",
             validation_level: :artifact_contract,
             model: :thin_selected_activity_resource_projection,
             row_semantics: row_semantics,
             approval_policy_boundary: :optional_policy_decision_v1,
             resource_projection_helpers: resource_projection_helpers,
             public_facades: public_facades,
             handoff_artifacts: ["operator_review_package.v1", "cadence_import_manifest.v1"],
             handoff_review_type: "resource_projection_review",
             handoff_import_action: "review_resource_projection",
             subsystem_model_capability_contract: "subsystem_model_capability.v1",
             subsystem_model_capability_ids: subsystem_model_capability_ids,
             subsystem_model_capability_ids_by_resource:
               subsystem_model_capability_ids_by_resource,
             resource_availability_aliases: resource_availability_aliases,
             resource_degraded_aliases: resource_degraded_aliases,
             resource_margin_aliases: resource_margin_aliases,
             resource_source_quality_aliases: resource_source_quality_aliases,
             resource_trust_boundary_aliases: resource_trust_boundary_aliases,
             planned_data_volume_paths: planned_data_volume_paths,
             actual_data_volume_paths: actual_data_volume_paths,
             estimated_downlink_throughput_paths: estimated_downlink_throughput_paths,
             battery_energy_consumed_paths: battery_energy_consumed_paths,
             battery_energy_generated_paths: battery_energy_generated_paths,
             resource_availability_true_tokens: resource_availability_true_tokens,
             resource_availability_false_tokens: resource_availability_false_tokens,
             provider_direction_aliases: provider_direction_aliases,
             station_calendar_direction_aliases: station_calendar_direction_aliases,
             station_capacity_fraction_paths: station_capacity_fraction_paths,
             station_capacity_percent_paths: station_capacity_percent_paths,
             station_capacity_value_paths: station_capacity_value_paths,
             source_station_capacity_fraction_paths: source_station_capacity_fraction_paths,
             source_station_capacity_percent_paths: source_station_capacity_percent_paths,
             source_station_capacity_value_paths: source_station_capacity_value_paths,
             activity_stable_identity_fields: activity_stable_identity_fields,
             row_review_statuses: ["operator_review_required"],
             known_limits: known_limits
           } = ResourceProjection.capabilities()

    assert resource_projection_helpers == [:flow_report, :flow_summary]
    assert :resource_projection_report in public_facades
    assert :resource_projection_flow_report in public_facades
    assert :resource_projection_flow_summary in public_facades
    assert :time_ordered_activity_resource_flow in row_semantics
    assert :resource_projection_row_count_list_consistency in row_semantics
    assert :resource_projection_flow_summary in row_semantics
    assert :resource_projection_flow_pressure_routing in row_semantics
    assert :resource_projection_flow_provider_calendar_provider_routing in row_semantics
    assert :resource_projection_flow_invalid_input_routing in row_semantics
    assert :resource_projection_flow_ignored_activity_routing in row_semantics
    assert :status_aware_activity_resource_effects in row_semantics
    assert :contact_allocation_status_resource_effects in row_semantics
    assert :declared_activity_battery_energy_projection in row_semantics
    assert :subsystem_model_capability_refs in row_semantics
    assert :storage_limited_downlink_utilization in row_semantics
    assert :resource_projection_flow_quantity_totals in row_semantics
    assert :collection_latency_flow_evidence in row_semantics
    assert :planned_data_volume_storage_production_aliases in row_semantics
    assert :realized_data_volume_evidence in row_semantics
    assert :actual_data_volume_audit_only_aliases in row_semantics
    assert :actual_data_volume_input_validation in row_semantics
    assert :estimated_downlink_throughput_aliases in row_semantics
    assert :battery_energy_consumed_aliases in row_semantics
    assert :battery_energy_generated_aliases in row_semantics
    assert :station_calendar_pressure_context in row_semantics
    assert :station_calendar_pressure_direction_and_capacity_maps in row_semantics
    assert :payload_and_antenna_availability_pressure in row_semantics
    assert :provider_direction_aliases in row_semantics
    assert :station_calendar_direction_aliases in row_semantics
    assert :station_capacity_value_paths in row_semantics
    assert :source_station_capacity_value_paths in row_semantics
    assert :activity_stable_identity_fields in row_semantics
    assert :resource_availability_aliases in row_semantics
    assert :resource_availability_status_tokens in row_semantics
    assert :resource_degraded_aliases in row_semantics
    assert :resource_margin_aliases in row_semantics
    assert :externally_supplied_thermal_margin_pressure in row_semantics
    assert :resource_summary_activity_type_suppression in row_semantics
    assert :first_resource_pressure_event in row_semantics
    assert :resource_source_quality_counts in row_semantics
    assert :resource_source_quality_spacecraft_id_routing in row_semantics
    assert :resource_source_quality_aliases in row_semantics
    assert :resource_trust_boundary_status_counts in row_semantics
    assert :resource_trust_boundary_status_spacecraft_id_routing in row_semantics
    assert :resource_trust_boundary_aliases in row_semantics
    assert :resource_provenance_alias_normalization in row_semantics
    assert :completed_fraction_unit_interval_input_validation in row_semantics
    assert :capacity_fraction_unit_interval_input_validation in row_semantics
    assert :negative_activity_resource_quantity_review in row_semantics
    assert :malformed_activity_resource_quantity_review in row_semantics
    assert :invalid_activity_input_review in row_semantics
    assert :invalid_resource_summary_input_review in row_semantics
    assert :duplicate_resource_summary_scope_review in row_semantics
    assert :mixed_wildcard_resource_summary_scope_review in row_semantics
    assert :no_subsystem_simulation in known_limits
    assert :thin_time_ordered_resource_roll_forward in known_limits

    assert subsystem_model_capability_ids == [
             "subsystem.power.battery.energy_storage.planning_grade",
             "subsystem.data_recorder.storage_buffer.planning_grade"
           ]

    assert subsystem_model_capability_ids_by_resource == %{
             battery: "subsystem.power.battery.energy_storage.planning_grade",
             storage: "subsystem.data_recorder.storage_buffer.planning_grade"
           }

    assert :battery_projection_uses_declared_activity_energy_only in known_limits
    assert :realized_data_volume_is_evidence_not_state_reconciliation in known_limits
    assert :no_realized_state_resource_reconciliation in known_limits
    assert :no_link_budget_model in known_limits

    assert resource_availability_aliases == %{
             "payload_available" => ["payload_available?", "payload_status"],
             "antenna_available" => ["antenna_available?", "antenna_status"],
             "spacecraft_available" => [
               "spacecraft_available?",
               "spacecraft_availability",
               "spacecraft_status"
             ]
           }

    assert resource_degraded_aliases == ["degraded?"]

    assert resource_margin_aliases == %{
             "storage_margin" => ["storage_capacity_margin"],
             "downlink_margin" => ["downlink_capacity_margin"],
             "battery_state_of_charge" => ["battery_soc"]
           }

    assert resource_source_quality_aliases == [
             ["resource_source_quality"],
             ["provenance", "source_quality"],
             ["provenance", "resource_source_quality"],
             ["provenance", "quality"]
           ]

    assert resource_trust_boundary_aliases == [
             ["resource_trust_boundary"],
             ["provenance", "trust_boundary"],
             ["provenance", "resource_trust_boundary"]
           ]

    assert planned_data_volume_paths == [
             ["planned_data_volume_mb"],
             ["data_volume_mb"],
             ["estimated_data_volume_mb"],
             ["metadata", "planned_data_volume_mb"],
             ["metadata", "data_volume_mb"],
             ["metadata", "estimated_data_volume_mb"]
           ]

    assert actual_data_volume_paths == [
             ["actual_data_volume_mb"],
             ["actual_storage_mb"],
             ["actual_downlink_mb"],
             ["delivered_data_mb"],
             ["received_data_mb"],
             ["metadata", "actual_data_volume_mb"],
             ["metadata", "actual_storage_mb"],
             ["metadata", "actual_downlink_mb"],
             ["metadata", "delivered_data_mb"],
             ["metadata", "received_data_mb"]
           ]

    assert estimated_downlink_throughput_paths == [
             ["estimated_throughput_mb"],
             ["estimated_downlink_mb"],
             ["planned_throughput_mb"],
             ["throughput_model", "estimated_throughput_mb"],
             ["throughput_model", "estimated_downlink_mb"],
             ["throughput_model", "planned_throughput_mb"],
             ["metadata", "estimated_throughput_mb"],
             ["metadata", "estimated_downlink_mb"],
             ["metadata", "planned_throughput_mb"]
           ]

    assert battery_energy_consumed_paths == [
             ["estimated_energy_used_wh"],
             ["estimated_battery_energy_used_wh"],
             ["planned_energy_used_wh"],
             ["battery_energy_used_wh"],
             ["metadata", "estimated_energy_used_wh"],
             ["metadata", "estimated_battery_energy_used_wh"],
             ["metadata", "planned_energy_used_wh"],
             ["metadata", "battery_energy_used_wh"]
           ]

    assert battery_energy_generated_paths == [
             ["estimated_energy_generated_wh"],
             ["estimated_battery_energy_generated_wh"],
             ["planned_energy_generated_wh"],
             ["battery_energy_generated_wh"],
             ["metadata", "estimated_energy_generated_wh"],
             ["metadata", "estimated_battery_energy_generated_wh"],
             ["metadata", "planned_energy_generated_wh"],
             ["metadata", "battery_energy_generated_wh"]
           ]

    assert "enabled" in resource_availability_true_tokens
    assert "operational" in resource_availability_true_tokens
    assert "outage" in resource_availability_false_tokens
    assert "maintenance" in resource_availability_false_tokens
    assert provider_direction_aliases["down"] == "downlink"
    assert provider_direction_aliases["s_band_command"] == "command"
    assert provider_direction_aliases["tracking_pass"] == "tracking"
    assert station_calendar_direction_aliases["uplink"] == "command"
    assert station_calendar_direction_aliases["downlinking"] == "downlink"
    assert station_calendar_direction_aliases["sband_command"] == "command"

    assert ["throughput_model", "station_capacity_fraction"] in station_capacity_fraction_paths
    assert ["capacity_model", "capacity_fraction"] in station_capacity_fraction_paths
    assert ["activity_context", "capacity_fraction"] in station_capacity_fraction_paths
    assert ["capacity_pack_capacity_fraction"] in station_capacity_fraction_paths
    assert ["station_capacity_fraction"] in station_capacity_fraction_paths
    assert ["capacity_fraction"] in station_capacity_fraction_paths

    assert ["throughput_model", "station_capacity_percent"] in station_capacity_percent_paths
    assert ["capacity_model", "capacity_percent"] in station_capacity_percent_paths
    assert ["activity_context", "capacity_percent"] in station_capacity_percent_paths
    assert ["station_capacity_percent"] in station_capacity_percent_paths
    assert ["capacity_percent"] in station_capacity_percent_paths

    assert %{unit: :fraction, path: ["capacity_fraction"]} in station_capacity_value_paths

    assert %{unit: :fraction, path: ["capacity_pack_capacity_fraction"]} in station_capacity_value_paths

    assert %{unit: :percent, path: ["capacity_percent"]} in station_capacity_value_paths

    assert ["station_capacity_fraction"] in source_station_capacity_fraction_paths
    assert ["capacity_fraction"] in source_station_capacity_fraction_paths
    assert ["capacity_pack_capacity_fraction"] in source_station_capacity_fraction_paths
    assert ["capacity_model", "capacity_fraction"] in source_station_capacity_fraction_paths
    assert ["activity_context", "capacity_fraction"] in source_station_capacity_fraction_paths

    assert ["station_capacity_percent"] in source_station_capacity_percent_paths
    assert ["capacity_percent"] in source_station_capacity_percent_paths
    assert ["capacity_model", "station_capacity_percent"] in source_station_capacity_percent_paths
    assert ["activity_context", "capacity_percent"] in source_station_capacity_percent_paths

    assert %{unit: :percent, path: ["capacity_model", "station_capacity_percent"]} in source_station_capacity_value_paths

    assert %{unit: :fraction, path: ["capacity_pack_capacity_fraction"]} in source_station_capacity_value_paths

    assert %{unit: :fraction, path: ["activity_context", "capacity_fraction"]} in source_station_capacity_value_paths

    assert "scenario_id" in activity_stable_identity_fields
    assert "spacecraft_id" in activity_stable_identity_fields
    assert "ground_station_id" in activity_stable_identity_fields
    assert "target_id" in activity_stable_identity_fields
    assert "source_window_id" in activity_stable_identity_fields

    assert OrbitalDynamics.capability_catalog().operations.resource_projection.public_facades ==
             [
               :resource_projection_report,
               :resource_projection_flow_report,
               :resource_projection_flow_summary
             ]
  end

  test "preserves invalid external resource summaries for review" do
    report =
      ResourceProjection.report(
        [
          %{
            id: :obs_1,
            type: :observe,
            scenario_id: :leo_1,
            starts_at_s: 10.0,
            estimated_storage_mb: 20.0
          }
        ],
        [
          %{
            spacecraft_id: :leo_1,
            storage_capacity_mb: 100.0,
            storage_used_mb: 10.0,
            battery_capacity_wh: 100.0,
            battery_energy_used_wh: 20.0
          },
          %{
            spacecraft_id: :leo_2,
            battery_capacity_wh: 100.0,
            battery_energy_used_wh: -10.0
          },
          %{
            spacecraft_id: "bad spacecraft id",
            power_margin: 0.5
          }
        ],
        approval_policy: %{policy_bundle_id: "resource_projection_authority_v1"}
      )

    assert %{
             "input_resource_summary_count" => 3,
             "valid_resource_summary_count" => 1,
             "invalid_resource_summary_input_count" => 2,
             "invalid_resource_summary_input_ids" => ["leo_2", "resource_summary:3"],
             "invalid_resource_summary_inputs" => [
               %{
                 "resource_summary_id" => "leo_2",
                 "spacecraft_id" => "leo_2",
                 "required_operator_action" => "review_invalid_resource_projection_summary",
                 "invalid_resource_summary_input" => true,
                 "invalid_resource_summary_input_reason" => "negative_battery_energy_used_wh",
                 "approval_rule_matches" => [
                   %{"rule_id" => "invalid_resource_projection_summary_input_review"}
                 ],
                 "policy_decision" => %{
                   "policy_bundle_id" => "resource_projection_authority_v1"
                 },
                 "source_resource_summary" => %{"battery_energy_used_wh" => -10.0}
               },
               %{
                 "resource_summary_id" => "resource_summary:3",
                 "invalid_resource_summary_input_reason" => "invalid_spacecraft_id",
                 "source_resource_summary" => %{"spacecraft_id" => "bad spacecraft id"}
               }
             ],
             "projected_resources" => [
               %{
                 "spacecraft_id" => "leo_1",
                 "battery_state_of_charge" => 0.8,
                 "power_margin" => 0.8,
                 "projected_power_margin" => 0.8
               }
             ],
             "assumptions" => %{
               "invalid_resource_summary_input" =>
                 "external resource summaries with invalid identity, negative capacity/use fields, out-of-range margins, or stale derived margins are preserved for operator review and excluded from resource projection"
             }
           } = report

    assert {:ok, %{"schema_contract" => "resource_projection_report.v1"}} =
             Schema.validate_artifact(report)

    invalid_review_status =
      put_in(
        report,
        ["invalid_resource_summary_inputs", Access.at(0), "review_status"],
        "ready_without_review"
      )

    assert {:error, invalid_review_status_report} =
             Schema.validate_artifact(invalid_review_status)

    assert Enum.any?(
             invalid_review_status_report["errors"],
             &(&1["path"] == "$.invalid_resource_summary_inputs[0].review_status")
           )

    invalid_count_report = Map.put(report, "invalid_resource_summary_input_count", 1)

    assert {:error, invalid_count_validation} = Schema.validate_artifact(invalid_count_report)

    assert Enum.any?(
             invalid_count_validation["errors"],
             &(&1["path"] == "$.invalid_resource_summary_input_count" and
                 &1["message"] == "must equal 2")
           )

    invalid_ids_report = Map.put(report, "invalid_resource_summary_input_ids", ["leo_2"])

    assert {:error, invalid_ids_validation} = Schema.validate_artifact(invalid_ids_report)

    assert Enum.any?(
             invalid_ids_validation["errors"],
             &(&1["path"] == "$.invalid_resource_summary_input_ids" and
                 &1["message"] == "must equal row-derived invalid_resource_summary_input_ids")
           )

    review = OperatorReview.from_resource_projection_report(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert Enum.any?(review["rows"], fn row ->
             row["required_operator_action"] == "review_invalid_resource_projection_summary" and
               row["invalid_resource_summary_input_reason"] ==
                 "negative_battery_energy_used_wh" and
               get_in(row, ["source_policy_decision", "policy_bundle_id"]) ==
                 "resource_projection_authority_v1" and
               get_in(row, ["source_resource_summary", "battery_energy_used_wh"]) == -10.0
           end)

    manifest = CadenceImport.from_resource_projection_report(report)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    assert Enum.any?(manifest["rows"], fn row ->
             row["import_action"] == "review_resource_projection" and
               row["required_operator_action"] == "review_invalid_resource_projection_summary" and
               row["invalid_resource_summary_input"] == true and
               get_in(row, ["source_policy_decision", "policy_bundle_id"]) ==
                 "resource_projection_authority_v1" and
               get_in(row, ["source_resource_summary", "spacecraft_id"]) == "bad spacecraft id"
           end)
  end

  test "review-gates resource summaries with stale derived margin evidence" do
    report =
      ResourceProjection.report(
        [
          %{
            id: :obs_1,
            type: :observe,
            scenario_id: :leo_1,
            starts_at_s: 10.0,
            estimated_storage_mb: 20.0
          }
        ],
        [
          %{
            spacecraft_id: :leo_1,
            storage_capacity_mb: 100.0,
            storage_used_mb: 10.0,
            battery_capacity_wh: 100.0,
            battery_energy_used_wh: 20.0
          },
          %{
            spacecraft_id: :leo_2,
            battery_capacity_wh: 100.0,
            battery_energy_used_wh: 20.0,
            battery_state_of_charge: 0.7
          },
          %{
            spacecraft_id: :leo_3,
            storage_capacity_mb: 100.0,
            storage_used_mb: 10.0,
            storage_margin: 0.75
          }
        ],
        approval_policy: %{policy_bundle_id: "resource_projection_authority_v1"}
      )

    assert %{
             "input_resource_summary_count" => 3,
             "valid_resource_summary_count" => 1,
             "invalid_resource_summary_input_count" => 2,
             "invalid_resource_summary_input_ids" => ["leo_2", "leo_3"],
             "invalid_resource_summary_inputs" => [
               %{
                 "resource_summary_id" => "leo_2",
                 "invalid_resource_summary_input_reason" => "stale_battery_state_of_charge",
                 "source_resource_summary" => %{
                   "battery_capacity_wh" => 100.0,
                   "battery_energy_used_wh" => 20.0,
                   "battery_state_of_charge" => 0.7
                 }
               },
               %{
                 "resource_summary_id" => "leo_3",
                 "invalid_resource_summary_input_reason" => "stale_storage_margin",
                 "source_resource_summary" => %{
                   "storage_capacity_mb" => 100.0,
                   "storage_used_mb" => 10.0,
                   "storage_margin" => 0.75
                 }
               }
             ],
             "projected_resources" => [%{"spacecraft_id" => "leo_1"}],
             "assumptions" => %{
               "invalid_resource_summary_input" =>
                 "external resource summaries with invalid identity, negative capacity/use fields, out-of-range margins, or stale derived margins are preserved for operator review and excluded from resource projection"
             }
           } = report

    assert {:ok, %{"schema_contract" => "resource_projection_report.v1"}} =
             Schema.validate_artifact(report)

    assert %{
             "invalid_resource_summary_input_count" => 2,
             "invalid_resource_summary_input_ids" => ["leo_2", "leo_3"],
             "invalid_resource_summary_inputs" => [
               %{
                 "resource_summary_id" => "leo_2",
                 "invalid_resource_summary_input_reason" => "stale_battery_state_of_charge",
                 "source_resource_summary" => %{
                   "battery_state_of_charge" => 0.7
                 }
               },
               %{
                 "resource_summary_id" => "leo_3",
                 "invalid_resource_summary_input_reason" => "stale_storage_margin",
                 "source_resource_summary" => %{
                   "storage_margin" => 0.75
                 }
               }
             ]
           } = flow_summary = ResourceProjection.flow_summary(report)

    assert {:ok, %{"schema_contract" => "resource_projection_flow_summary.v1"}} =
             Schema.validate_artifact(flow_summary)

    review = OperatorReview.from_resource_projection_report(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert Enum.any?(review["rows"], fn row ->
             row["invalid_resource_summary_input_reason"] == "stale_battery_state_of_charge" and
               get_in(row, ["source_resource_summary", "battery_state_of_charge"]) == 0.7
           end)

    manifest = CadenceImport.from_resource_projection_report(report)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    assert Enum.any?(manifest["rows"], fn row ->
             row["invalid_resource_summary_input_reason"] == "stale_storage_margin" and
               get_in(row, ["source_resource_summary", "storage_margin"]) == 0.75
           end)
  end

  test "review-gates duplicate resource summaries for the same projection scope" do
    report =
      ResourceProjection.report(
        [
          %{
            id: :obs_1,
            type: :observe,
            scenario_id: :leo_1,
            spacecraft_id: :sat_1,
            starts_at_s: 10.0,
            estimated_storage_mb: 20.0
          },
          %{
            id: :obs_2,
            type: :observe,
            scenario_id: :leo_2,
            spacecraft_id: :sat_2,
            starts_at_s: 20.0,
            estimated_storage_mb: 30.0
          }
        ],
        [
          %{
            spacecraft_id: :sat_1,
            storage_capacity_mb: 100.0,
            storage_used_mb: 10.0,
            source_quality: :ops_console
          },
          %{
            spacecraft_id: :sat_1,
            storage_capacity_mb: 200.0,
            storage_used_mb: 20.0,
            source_quality: :partner_report
          },
          %{
            spacecraft_id: :sat_2,
            storage_capacity_mb: 100.0,
            storage_used_mb: 0.0,
            source_quality: :operator_supplied
          }
        ],
        approval_policy: %{policy_bundle_id: "resource_projection_authority_v1"}
      )

    assert %{
             "input_resource_summary_count" => 3,
             "valid_resource_summary_count" => 1,
             "invalid_resource_summary_input_count" => 2,
             "invalid_resource_summary_input_ids" => [
               "sat_1:duplicate:1",
               "sat_1:duplicate:2"
             ],
             "invalid_resource_summary_inputs" => [
               %{
                 "resource_summary_id" => "sat_1:duplicate:1",
                 "spacecraft_id" => "sat_1",
                 "invalid_resource_summary_input_reason" => "duplicate_resource_summary_scope",
                 "duplicate_resource_summary_scope" => true,
                 "resource_summary_key" => "sat_1",
                 "duplicate_resource_summary_index" => 1,
                 "duplicate_resource_summary_count" => 2,
                 "source_resource_summary" => %{
                   "storage_capacity_mb" => 100.0,
                   "source_quality" => "ops_console"
                 }
               },
               %{
                 "resource_summary_id" => "sat_1:duplicate:2",
                 "spacecraft_id" => "sat_1",
                 "duplicate_resource_summary_scope" => true,
                 "resource_summary_key" => "sat_1",
                 "duplicate_resource_summary_index" => 2,
                 "duplicate_resource_summary_count" => 2,
                 "source_resource_summary" => %{
                   "storage_capacity_mb" => 200.0,
                   "source_quality" => "partner_report"
                 }
               }
             ],
             "projected_resources" => [
               %{
                 "spacecraft_id" => "sat_2",
                 "activity_count" => 1,
                 "estimated_storage_produced_mb" => 30.0,
                 "resource_source_quality" => "operator_supplied"
               }
             ],
             "assumptions" => %{
               "duplicate_resource_summary_scope" =>
                 "duplicate valid resource summaries for the same spacecraft or wildcard scope are preserved for operator review and excluded from resource projection math"
             }
           } = report

    assert {:ok, %{"schema_contract" => "resource_projection_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_resource_projection_report(report)

    duplicate_review_rows =
      Enum.filter(
        review["rows"],
        &(&1["invalid_resource_summary_input_reason"] == "duplicate_resource_summary_scope")
      )

    assert Enum.map(duplicate_review_rows, & &1["subject_id"]) == [
             "sat_1:duplicate:1",
             "sat_1:duplicate:2"
           ]

    assert Enum.all?(duplicate_review_rows, fn row ->
             row["duplicate_resource_summary_scope"] == true and
               row["resource_summary_key"] == "sat_1" and
               row["duplicate_resource_summary_count"] == 2 and
               get_in(row, ["source_resource_projection", "duplicate_resource_summary_scope"]) ==
                 true
           end)

    manifest = CadenceImport.from_resource_projection_report(report)

    duplicate_manifest_rows =
      Enum.filter(
        manifest["rows"],
        &(&1["invalid_resource_summary_input_reason"] == "duplicate_resource_summary_scope")
      )

    assert Enum.map(duplicate_manifest_rows, & &1["subject_id"]) == [
             "sat_1:duplicate:1",
             "sat_1:duplicate:2"
           ]

    assert Enum.all?(duplicate_manifest_rows, fn row ->
             row["duplicate_resource_summary_scope"] == true and
               row["resource_summary_key"] == "sat_1" and
               row["duplicate_resource_summary_count"] == 2 and
               get_in(row, ["source_resource_projection", "duplicate_resource_summary_scope"]) ==
                 true
           end)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "review-gates wildcard summaries mixed with scoped summaries" do
    summaries = [
      %{
        storage_capacity_mb: 500.0,
        storage_used_mb: 50.0,
        source_quality: :fleet_default
      },
      %{
        spacecraft_id: :leo_1,
        storage_capacity_mb: 100.0,
        storage_used_mb: 0.0,
        source_quality: :operator_supplied
      }
    ]

    assert ["leo_1"] ==
             OrbitalDynamics.ResourceProjection.ResourceSummaryInput.projection_scope_ids(
               %{id: :obs_1, type: :observe, scenario_id: :leo_1},
               summaries
             )

    assert [] ==
             OrbitalDynamics.ResourceProjection.ResourceSummaryInput.projection_scope_ids(
               %{id: :obs_2, type: :observe, scenario_id: :leo_2},
               summaries
             )

    report =
      ResourceProjection.report(
        [
          %{
            id: :obs_1,
            type: :observe,
            scenario_id: :leo_1,
            estimated_storage_mb: 10.0
          },
          %{
            id: :obs_2,
            type: :observe,
            scenario_id: :leo_2,
            estimated_storage_mb: 25.0
          }
        ],
        summaries,
        approval_policy: %{policy_bundle_id: "resource_projection_authority_v1"}
      )

    assert %{
             "input_resource_summary_count" => 2,
             "valid_resource_summary_count" => 1,
             "invalid_resource_summary_input_count" => 1,
             "invalid_resource_summary_input_ids" => ["all_spacecraft:mixed_scope"],
             "invalid_resource_summary_inputs" => [
               %{
                 "resource_summary_id" => "all_spacecraft:mixed_scope",
                 "invalid_resource_summary_input_reason" =>
                   "mixed_wildcard_resource_summary_scope",
                 "mixed_wildcard_resource_summary_scope" => true,
                 "resource_summary_key" => "all_spacecraft",
                 "source_resource_summary" => %{
                   "storage_capacity_mb" => 500.0,
                   "source_quality" => "fleet_default"
                 }
               }
             ],
             "projected_resources" => [
               %{
                 "spacecraft_id" => "leo_1",
                 "activity_count" => 1,
                 "estimated_storage_produced_mb" => 10.0,
                 "resource_source_quality" => "operator_supplied"
               }
             ],
             "assumptions" => %{
               "mixed_wildcard_resource_summary_scope" =>
                 "id-less wildcard resource summaries only apply when they are the single summary; mixed wildcard and scoped summaries are preserved for operator review and excluded from projection math"
             }
           } = report

    assert {:ok, %{"schema_contract" => "resource_projection_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_resource_projection_report(report)

    assert [
             %{
               "subject_id" => "all_spacecraft:mixed_scope",
               "mixed_wildcard_resource_summary_scope" => true,
               "resource_summary_key" => "all_spacecraft"
             }
           ] =
             Enum.filter(
               review["rows"],
               &(&1["invalid_resource_summary_input_reason"] ==
                   "mixed_wildcard_resource_summary_scope")
             )

    manifest = CadenceImport.from_resource_projection_report(report)

    assert [
             %{
               "subject_id" => "all_spacecraft:mixed_scope",
               "mixed_wildcard_resource_summary_scope" => true,
               "resource_summary_key" => "all_spacecraft"
             }
           ] =
             Enum.filter(
               manifest["rows"],
               &(&1["invalid_resource_summary_input_reason"] ==
                   "mixed_wildcard_resource_summary_scope")
             )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "preserves invalid selected activity inputs for review" do
    report =
      ResourceProjection.report(
        [
          %{
            id: :obs_1,
            type: :observe,
            scenario_id: :leo_1,
            starts_at_s: 10.0,
            estimated_storage_mb: 20.0
          },
          %{
            type: :observe,
            scenario_id: :leo_1,
            starts_at_s: 15.0,
            estimated_storage_mb: 40.0
          },
          %{
            id: :bad_type,
            scenario_id: :leo_1,
            starts_at_s: 25.0
          }
        ],
        [
          %{
            spacecraft_id: :leo_1,
            storage_capacity_mb: 100.0,
            storage_used_mb: 10.0,
            downlink_capacity_mb: 100.0
          }
        ],
        approval_policy: %{policy_bundle_id: "resource_projection_authority_v1"}
      )

    assert %{
             "activity_count" => 3,
             "valid_activity_count" => 1,
             "invalid_activity_input_count" => 2,
             "invalid_activity_input_ids" => ["missing_activity_id:2", "bad_type"],
             "invalid_activity_inputs" => [
               %{
                 "activity_id" => "missing_activity_id:2",
                 "invalid_activity_input" => true,
                 "invalid_activity_input_reason" => "missing_activity_id",
                 "required_operator_action" => "review_invalid_resource_projection_input",
                 "approval_rule_matches" => [
                   %{"rule_id" => "invalid_resource_projection_activity_input_review"}
                 ],
                 "policy_decision" => %{
                   "policy_bundle_id" => "resource_projection_authority_v1"
                 },
                 "source_activity" => %{"type" => "observe"}
               },
               %{
                 "activity_id" => "bad_type",
                 "invalid_activity_input_reason" => "missing_activity_type"
               }
             ],
             "projected_resources" => [
               %{"activity_count" => 1, "estimated_storage_produced_mb" => 20.0}
             ],
             "assumptions" => %{
               "invalid_activity_input" =>
                 "selected activity inputs missing stable identity, activity type, valid unit-interval completion or capacity-fraction evidence, or valid non-negative resource quantities are preserved for operator review and excluded from resource projection"
             }
           } = report

    assert {:ok, %{"schema_contract" => "resource_projection_report.v1"}} =
             Schema.validate_artifact(report)

    invalid_review_status =
      put_in(
        report,
        ["invalid_activity_inputs", Access.at(0), "review_status"],
        "ready_without_review"
      )

    assert {:error, invalid_review_status_report} =
             Schema.validate_artifact(invalid_review_status)

    assert Enum.any?(
             invalid_review_status_report["errors"],
             &(&1["path"] == "$.invalid_activity_inputs[0].review_status")
           )

    invalid_count_report = Map.put(report, "invalid_activity_input_count", 1)

    assert {:error, invalid_count_validation} = Schema.validate_artifact(invalid_count_report)

    assert Enum.any?(
             invalid_count_validation["errors"],
             &(&1["path"] == "$.invalid_activity_input_count" and
                 &1["message"] == "must equal 2")
           )

    invalid_ids_report = Map.put(report, "invalid_activity_input_ids", ["bad_type"])

    assert {:error, invalid_ids_validation} = Schema.validate_artifact(invalid_ids_report)

    assert Enum.any?(
             invalid_ids_validation["errors"],
             &(&1["path"] == "$.invalid_activity_input_ids" and
                 &1["message"] == "must equal row-derived invalid_activity_input_ids")
           )

    invalid_valid_count_report = Map.put(report, "valid_activity_count", 3)

    assert {:error, valid_count_validation} =
             Schema.validate_artifact(invalid_valid_count_report)

    assert Enum.any?(
             valid_count_validation["errors"],
             &(&1["path"] == "$.valid_activity_count" and &1["message"] == "must equal 1")
           )

    review = OperatorReview.from_resource_projection_report(report)

    assert %{
             "review_type" => "resource_projection_review",
             "required_operator_action" => "review_invalid_resource_projection_input",
             "invalid_activity_input" => true,
             "invalid_activity_input_reason" => "missing_activity_id",
             "source_policy_decision" => %{
               "policy_bundle_id" => "resource_projection_authority_v1"
             },
             "source_activity" => %{"scenario_id" => "leo_1"}
           } = hd(review["rows"])

    manifest = CadenceImport.from_resource_projection_report(report)

    assert %{
             "import_action" => "review_resource_projection",
             "required_operator_action" => "review_invalid_resource_projection_input",
             "invalid_activity_input" => true,
             "invalid_activity_input_reason" => "missing_activity_id",
             "source_policy_decision" => %{
               "policy_bundle_id" => "resource_projection_authority_v1"
             },
             "source_activity" => %{"scenario_id" => "leo_1"}
           } = hd(manifest["rows"])
  end

  test "preserves negative activity resource quantities for review before roll-forward" do
    report =
      ResourceProjection.report(
        [
          %{
            id: :obs_valid,
            type: :observe,
            scenario_id: :leo_1,
            starts_at_s: 10.0,
            metadata: %{estimated_storage_mb: 20.0}
          },
          %{
            id: :obs_negative_storage,
            type: :observe,
            scenario_id: :leo_1,
            starts_at_s: 20.0,
            metadata: %{estimated_storage_mb: -5.0}
          },
          %{
            id: :downlink_negative_capacity,
            type: :downlink,
            scenario_id: :leo_1,
            ground_station_id: :equator_prime,
            starts_at_s: 30.0,
            throughput_model: %{capacity_adjusted_throughput_mb: -10.0}
          },
          %{
            id: :obs_negative_energy,
            type: :observe,
            scenario_id: :leo_1,
            starts_at_s: 40.0,
            estimated_energy_used_wh: -2.0
          }
        ],
        [
          %{
            spacecraft_id: :leo_1,
            storage_capacity_mb: 100.0,
            storage_used_mb: 0.0,
            downlink_capacity_mb: 50.0,
            battery_capacity_wh: 100.0,
            battery_energy_used_wh: 10.0
          }
        ]
      )

    assert %{
             "activity_count" => 4,
             "valid_activity_count" => 1,
             "invalid_activity_input_count" => 3,
             "invalid_activity_input_ids" => [
               "obs_negative_storage",
               "downlink_negative_capacity",
               "obs_negative_energy"
             ],
             "invalid_activity_inputs" => invalid_inputs,
             "projected_resources" => [
               %{
                 "activity_count" => 1,
                 "estimated_storage_produced_mb" => 20.0,
                 "projected_storage_used_mb" => 20.0
               }
             ]
           } = report

    assert %{
             "invalid_activity_input_reason" => "negative_estimated_storage_mb",
             "source_activity" => %{
               "metadata" => %{"estimated_storage_mb" => -5.0}
             }
           } = Enum.find(invalid_inputs, &(&1["activity_id"] == "obs_negative_storage"))

    assert %{
             "invalid_activity_input_reason" => "negative_capacity_adjusted_throughput_mb",
             "source_activity" => %{
               "throughput_model" => %{"capacity_adjusted_throughput_mb" => -10.0}
             }
           } = Enum.find(invalid_inputs, &(&1["activity_id"] == "downlink_negative_capacity"))

    assert %{
             "invalid_activity_input_reason" => "negative_estimated_energy_used_wh",
             "source_activity" => %{"estimated_energy_used_wh" => -2.0}
           } = Enum.find(invalid_inputs, &(&1["activity_id"] == "obs_negative_energy"))

    assert {:ok, %{"schema_contract" => "resource_projection_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_resource_projection_report(report)

    assert Enum.any?(
             review["rows"],
             &(&1["activity_id"] == "downlink_negative_capacity" and
                 &1["invalid_activity_input_reason"] ==
                   "negative_capacity_adjusted_throughput_mb")
           )

    manifest = CadenceImport.from_resource_projection_report(report)

    assert Enum.any?(
             manifest["rows"],
             &(&1["activity_id"] == "obs_negative_storage" and
                 &1["invalid_activity_input_reason"] == "negative_estimated_storage_mb")
           )
  end

  test "preserves malformed activity resource quantities for review before roll-forward" do
    report =
      ResourceProjection.report(
        [
          %{
            id: :obs_valid,
            type: :observe,
            scenario_id: :leo_1,
            starts_at_s: 10.0,
            estimated_storage_mb: 20.0
          },
          %{
            id: :obs_bad_storage,
            type: :observe,
            scenario_id: :leo_1,
            starts_at_s: 20.0,
            metadata: %{estimated_storage_mb: "twenty"}
          },
          %{
            id: :downlink_bad_throughput,
            type: :downlink,
            scenario_id: :leo_1,
            ground_station_id: :equator_prime,
            starts_at_s: 30.0,
            throughput_model: %{planned_throughput_mb: "many"}
          },
          %{
            id: :obs_bad_energy,
            type: :observe,
            scenario_id: :leo_1,
            starts_at_s: 40.0,
            estimated_energy_generated_wh: "a lot"
          }
        ],
        [
          %{
            spacecraft_id: :leo_1,
            storage_capacity_mb: 100.0,
            storage_used_mb: 0.0,
            downlink_capacity_mb: 50.0,
            battery_capacity_wh: 100.0,
            battery_energy_used_wh: 10.0
          }
        ]
      )

    assert %{
             "activity_count" => 4,
             "valid_activity_count" => 1,
             "invalid_activity_input_count" => 3,
             "invalid_activity_input_ids" => [
               "obs_bad_storage",
               "downlink_bad_throughput",
               "obs_bad_energy"
             ],
             "invalid_activity_inputs" => invalid_inputs,
             "projected_resources" => [
               %{
                 "activity_count" => 1,
                 "estimated_storage_produced_mb" => 20.0,
                 "projected_storage_used_mb" => 20.0
               }
             ]
           } = report

    assert %{
             "invalid_activity_input_reason" => "invalid_estimated_storage_mb",
             "source_activity" => %{"metadata" => %{"estimated_storage_mb" => "twenty"}}
           } = Enum.find(invalid_inputs, &(&1["activity_id"] == "obs_bad_storage"))

    assert %{
             "invalid_activity_input_reason" => "invalid_planned_throughput_mb",
             "source_activity" => %{
               "throughput_model" => %{"planned_throughput_mb" => "many"}
             }
           } = Enum.find(invalid_inputs, &(&1["activity_id"] == "downlink_bad_throughput"))

    assert %{
             "invalid_activity_input_reason" => "invalid_estimated_energy_generated_wh",
             "source_activity" => %{"estimated_energy_generated_wh" => "a lot"}
           } = Enum.find(invalid_inputs, &(&1["activity_id"] == "obs_bad_energy"))

    assert {:ok, %{"schema_contract" => "resource_projection_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_resource_projection_report(report)

    assert Enum.any?(
             review["rows"],
             &(&1["activity_id"] == "obs_bad_storage" and
                 &1["invalid_activity_input_reason"] == "invalid_estimated_storage_mb")
           )

    manifest = CadenceImport.from_resource_projection_report(report)

    assert Enum.any?(
             manifest["rows"],
             &(&1["activity_id"] == "downlink_bad_throughput" and
                 &1["invalid_activity_input_reason"] == "invalid_planned_throughput_mb")
           )
  end

  test "preserves malformed activity latency evidence for review before roll-forward" do
    report =
      ResourceProjection.report(
        [
          %{
            id: :obs_valid,
            type: :observe,
            scenario_id: :leo_1,
            starts_at_s: 10.0,
            collection_ends_at_s: 15.0,
            planned_delivery_at_s: 35.0,
            max_latency_s: 30.0,
            estimated_storage_mb: 20.0
          },
          %{
            id: :obs_negative_latency,
            type: :observe,
            scenario_id: :leo_1,
            starts_at_s: 20.0,
            metadata: %{max_latency_s: -5.0},
            estimated_storage_mb: 10.0
          },
          %{
            id: :obs_bad_latency,
            type: :observe,
            scenario_id: :leo_1,
            starts_at_s: 30.0,
            planned_latency_s: "late",
            estimated_storage_mb: 10.0
          }
        ],
        [
          %{
            spacecraft_id: :leo_1,
            storage_capacity_mb: 100.0,
            storage_used_mb: 0.0,
            downlink_capacity_mb: 50.0
          }
        ]
      )

    assert %{
             "activity_count" => 3,
             "valid_activity_count" => 1,
             "invalid_activity_input_count" => 2,
             "invalid_activity_input_ids" => ["obs_negative_latency", "obs_bad_latency"],
             "invalid_activity_inputs" => invalid_inputs,
             "projected_resources" => [
               %{
                 "activity_count" => 1,
                 "activity_resource_flow" => [
                   %{
                     "activity_id" => "obs_valid",
                     "planned_latency_s" => 20.0,
                     "latency_status" => "within_limit"
                   }
                 ]
               }
             ]
           } = report

    assert %{
             "invalid_activity_input_reason" => "negative_max_latency_s",
             "source_activity" => %{"metadata" => %{"max_latency_s" => -5.0}}
           } = Enum.find(invalid_inputs, &(&1["activity_id"] == "obs_negative_latency"))

    assert %{
             "invalid_activity_input_reason" => "invalid_planned_latency_s",
             "source_activity" => %{"planned_latency_s" => "late"}
           } = Enum.find(invalid_inputs, &(&1["activity_id"] == "obs_bad_latency"))

    assert {:ok, %{"schema_contract" => "resource_projection_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "preserves malformed resource projection stable identity fields for review" do
    report =
      ResourceProjection.report(
        [
          %{
            id: "bad activity id",
            type: :observe,
            scenario_id: :leo_1,
            target_id: :target_alpha,
            starts_at_s: 10.0,
            estimated_storage_mb: 20.0
          },
          %{
            id: :bad_scenario,
            type: :observe,
            scenario_id: "bad scenario id",
            target_id: :target_alpha,
            starts_at_s: 20.0,
            estimated_storage_mb: 30.0
          },
          %{
            id: :bad_source_window,
            type: :downlink,
            scenario_id: :leo_1,
            ground_station_id: :equator_prime,
            source_window_id: "bad source window",
            starts_at_s: 30.0,
            estimated_throughput_mb: 40.0
          },
          %{
            id: :bad_nested_source_window,
            type: :downlink,
            scenario_id: :leo_1,
            ground_station_id: :equator_prime,
            activity_context: %{
              source_window: %{
                id: "bad nested source window",
                type: :ground_station_access
              }
            },
            starts_at_s: 40.0,
            estimated_throughput_mb: 50.0
          }
        ],
        [
          %{
            spacecraft_id: :leo_1,
            storage_capacity_mb: 100.0,
            storage_used_mb: 10.0,
            downlink_capacity_mb: 100.0
          }
        ]
      )

    assert %{
             "activity_count" => 4,
             "valid_activity_count" => 0,
             "invalid_activity_input_count" => 4,
             "invalid_activity_input_ids" => [
               "invalid_activity_id:1",
               "bad_scenario",
               "bad_source_window",
               "bad_nested_source_window"
             ],
             "invalid_activity_inputs" => invalid_inputs
           } = report

    assert %{
             "activity_id" => "invalid_activity_id:1",
             "invalid_activity_input_reason" => "invalid_activity_id",
             "source_activity" => %{"id" => "bad activity id"}
           } = Enum.find(invalid_inputs, &(&1["activity_id"] == "invalid_activity_id:1"))

    assert %{
             "activity_id" => "bad_scenario",
             "scenario_id" => "missing_scenario_id:bad_scenario",
             "invalid_activity_input_reason" => "invalid_scenario_id",
             "source_activity" => %{"scenario_id" => "bad scenario id"}
           } = Enum.find(invalid_inputs, &(&1["activity_id"] == "bad_scenario"))

    bad_source_window =
      Enum.find(invalid_inputs, &(&1["activity_id"] == "bad_source_window"))

    assert %{
             "invalid_activity_input_reason" => "invalid_source_window_id",
             "ground_station_id" => "equator_prime",
             "source_activity" => %{"source_window_id" => "bad source window"}
           } = bad_source_window

    refute Map.has_key?(bad_source_window, "source_window_id")

    bad_nested_source_window =
      Enum.find(invalid_inputs, &(&1["activity_id"] == "bad_nested_source_window"))

    assert %{
             "invalid_activity_input_reason" => "invalid_source_window_id",
             "source_activity" => %{
               "source_window_id" => "bad nested source window",
               "source_window" => %{"id" => "bad nested source window"}
             }
           } = bad_nested_source_window

    refute Map.has_key?(bad_nested_source_window, "source_window_id")

    assert {:ok, %{"schema_contract" => "resource_projection_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_resource_projection_report(report)

    assert Enum.any?(
             review["rows"],
             &(&1["activity_id"] == "bad_source_window" and
                 &1["invalid_activity_input_reason"] == "invalid_source_window_id" and
                 get_in(&1, ["source_activity", "source_window_id"]) == "bad source window")
           )

    manifest = CadenceImport.from_resource_projection_report(report)

    assert Enum.any?(
             manifest["rows"],
             &(&1["activity_id"] == "bad_scenario" and
                 &1["invalid_activity_input_reason"] == "invalid_scenario_id" and
                 get_in(&1, ["source_activity", "scenario_id"]) == "bad scenario id")
           )
  end

  test "projects selected activity resources from atom or string keyed inputs" do
    activities = [
      %{
        id: :obs_1,
        type: :observe,
        scenario_id: :leo_1,
        starts_at_s: 10.0,
        metadata: %{estimated_storage_mb: 40.0, estimated_energy_used_wh: 120.0}
      },
      %{
        "id" => "dl_1",
        "type" => "downlink",
        "scenario_id" => "leo_1",
        "starts_at_s" => 20.0,
        "estimated_throughput_mb" => 60.0,
        "estimated_energy_used_wh" => 60.0,
        "throughput_model" => %{"station_capacity_fraction" => 0.5}
      }
    ]

    summaries = [
      %{
        spacecraft_id: :leo_1,
        storage_capacity_mb: 100.0,
        storage_used_mb: 20.0,
        downlink_capacity_mb: 100.0,
        battery_capacity_wh: 1200.0,
        battery_energy_used_wh: 300.0,
        fuel_margin: 0.9,
        payload_available: true,
        antenna_available: true,
        source_quality: :operator_supplied,
        provenance: %{
          source: :operator_summary,
          trust_boundary: :operator_declared_resource_summary
        }
      }
    ]

    report =
      ResourceProjection.report(activities, summaries, source: "unit_test.resource_summaries")

    assert %{
             "schema_contract" => "resource_projection_report.v1",
             "model" => "thin_selected_activity_resource_projection",
             "input_resource_summary_count" => 1,
             "activity_count" => 2,
             "model_limits" => model_limits,
             "resource_source_quality_counts" => %{"operator_supplied" => 1},
             "resource_spacecraft_ids_by_source_quality" => %{"operator_supplied" => ["leo_1"]},
             "resource_trust_boundary_status_counts" => %{"declared" => 1},
             "resource_spacecraft_ids_by_trust_boundary_status" => %{"declared" => ["leo_1"]},
             "projected_resources" => [
               %{
                 "spacecraft_id" => "leo_1",
                 "activity_count" => 2,
                 "observation_count" => 1,
                 "downlink_count" => 1,
                 "estimated_storage_produced_mb" => 40.0,
                 "estimated_downlink_mb" => 30.0,
                 "activity_resource_flow" => [
                   %{
                     "activity_id" => "obs_1",
                     "activity_type" => "observe",
                     "storage_used_before_mb" => 20.0,
                     "storage_produced_mb" => 40.0,
                     "downlinked_mb" => +0.0,
                     "storage_delta_mb" => 40.0,
                     "storage_used_after_mb" => 60.0,
                     "storage_margin_after" => 0.4,
                     "downlink_used_after_mb" => +0.0,
                     "downlink_margin_after" => 1.0,
                     "battery_energy_used_before_wh" => 300.0,
                     "battery_energy_consumed_wh" => 120.0,
                     "battery_energy_generated_wh" => +0.0,
                     "battery_energy_delta_wh" => 120.0,
                     "battery_energy_used_after_wh" => 420.0,
                     "battery_state_of_charge_after" => 0.65,
                     "battery_overuse_wh" => +0.0
                   },
                   %{
                     "activity_id" => "dl_1",
                     "activity_type" => "downlink",
                     "storage_used_before_mb" => 60.0,
                     "storage_produced_mb" => +0.0,
                     "downlinked_mb" => 30.0,
                     "storage_delta_mb" => -30.0,
                     "storage_used_after_mb" => 30.0,
                     "storage_margin_after" => 0.7,
                     "downlink_used_after_mb" => 30.0,
                     "downlink_margin_after" => 0.7,
                     "battery_energy_used_before_wh" => 420.0,
                     "battery_energy_consumed_wh" => 60.0,
                     "battery_energy_generated_wh" => +0.0,
                     "battery_energy_delta_wh" => 60.0,
                     "battery_energy_used_after_wh" => 480.0,
                     "battery_state_of_charge_after" => 0.6,
                     "battery_overuse_wh" => +0.0
                   }
                 ],
                 "starting_storage_used_mb" => 20.0,
                 "projected_storage_used_mb" => 30.0,
                 "storage_capacity_mb" => 100.0,
                 "projected_storage_margin" => 0.7,
                 "downlink_capacity_mb" => 100.0,
                 "projected_downlink_margin" => 0.7,
                 "resource_pressure_status" => "nominal",
                 "resource_pressure_types" => [],
                 "resource_source_quality" => "operator_supplied",
                 "resource_trust_boundary" => "operator_declared_resource_summary",
                 "resource_trust_boundary_status" => "declared",
                 "resource_provenance" => %{
                   "source" => "operator_summary",
                   "trust_boundary" => "operator_declared_resource_summary"
                 },
                 "fuel_margin" => 0.9,
                 "power_margin" => 0.75,
                 "projected_power_margin" => 0.6,
                 "battery_capacity_wh" => 1200.0,
                 "battery_energy_used_wh" => 300.0,
                 "battery_state_of_charge" => 0.75,
                 "starting_battery_energy_used_wh" => 300.0,
                 "projected_battery_energy_used_wh" => 480.0,
                 "projected_battery_state_of_charge" => 0.6,
                 "projected_battery_overuse_wh" => +0.0,
                 "payload_available" => true,
                 "antenna_available" => true,
                 "warnings" => []
               }
             ],
             "warnings" => [],
             "assumptions" => %{
               "source" => "unit_test.resource_summaries",
               "downlink_model" =>
                 "capacity_adjusted_estimated_throughput_consumes_downlink_capacity",
               "activity_flow_model" =>
                 "activities_ordered_by_starts_at_s_then_id_with_storage_downlink_roll_forward"
             }
           } = report

    assert "no_subsystem_simulation" in model_limits
    assert "no_schedule_mutation" in model_limits

    expected_model_limits =
      ResourceProjection.capabilities()
      |> Map.fetch!(:known_limits)
      |> Enum.map(&to_string/1)

    assert model_limits == expected_model_limits

    assert get_in(report, ["assumptions", "subsystem_model_capability_contract"]) ==
             "subsystem_model_capability.v1"

    assert get_in(report, ["assumptions", "subsystem_model_capability_ids"]) == [
             "subsystem.power.battery.energy_storage.planning_grade",
             "subsystem.data_recorder.storage_buffer.planning_grade"
           ]

    assert get_in(report, ["assumptions", "subsystem_model_capability_ids_by_resource"]) == %{
             "battery" => "subsystem.power.battery.energy_storage.planning_grade",
             "storage" => "subsystem.data_recorder.storage_buffer.planning_grade"
           }

    assert {:ok, %{"schema_contract" => "resource_projection_report.v1"}} =
             Schema.validate_artifact(report)

    stale_subsystem_ids =
      put_in(report, ["assumptions", "subsystem_model_capability_ids"], [
        "subsystem.unknown.planning_grade"
      ])

    assert {:error, stale_subsystem_ids_report} = Schema.validate_artifact(stale_subsystem_ids)

    assert Enum.any?(
             stale_subsystem_ids_report["errors"],
             &(&1["path"] == "$.assumptions.subsystem_model_capability_ids" and
                 &1["message"] == "must match ResourceProjection subsystem model capability IDs")
           )

    stale_subsystem_ids_by_resource =
      put_in(
        report,
        ["assumptions", "subsystem_model_capability_ids_by_resource", "storage"],
        "subsystem.storage.legacy"
      )

    assert {:error, stale_subsystem_ids_by_resource_report} =
             Schema.validate_artifact(stale_subsystem_ids_by_resource)

    assert Enum.any?(
             stale_subsystem_ids_by_resource_report["errors"],
             &(&1["path"] == "$.assumptions.subsystem_model_capability_ids_by_resource" and
                 &1["message"] ==
                   "must match ResourceProjection subsystem model capability IDs by resource")
           )

    assert %{
             "projected_resources" => [
               %{
                 "spacecraft_id" => "leo_1",
                 "resource_source_quality" => "operator_supplied",
                 "resource_trust_boundary" => "operator_declared_resource_summary",
                 "resource_trust_boundary_status" => "declared",
                 "resource_provenance" => %{
                   "source" => "operator_summary",
                   "trust_boundary" => "operator_declared_resource_summary"
                 }
               }
             ]
           } = ResourceProjection.flow_summary(report)

    invalid_summary_count = Map.put(report, "input_resource_summary_count", 2)

    assert {:error, summary_count_validation} = Schema.validate_artifact(invalid_summary_count)

    assert Enum.any?(
             summary_count_validation["errors"],
             &(&1["path"] == "$.input_resource_summary_count" and
                 &1["message"] == "must equal 1")
           )

    invalid_source_quality_count =
      put_in(report, ["resource_source_quality_counts", "operator_supplied"], -1)

    assert {:error, source_quality_count_validation} =
             Schema.validate_artifact(invalid_source_quality_count)

    assert Enum.any?(
             source_quality_count_validation["errors"],
             &(&1["path"] == "$.resource_source_quality_counts.operator_supplied")
           )

    stale_source_quality_ids =
      put_in(report, ["resource_spacecraft_ids_by_source_quality", "operator_supplied"], [
        "leo_2"
      ])

    assert {:error, source_quality_id_validation} =
             Schema.validate_artifact(stale_source_quality_ids)

    assert Enum.any?(
             source_quality_id_validation["errors"],
             &(&1["path"] == "$.resource_spacecraft_ids_by_source_quality" and
                 &1["message"] ==
                   "must equal row-derived resource_spacecraft_ids_by_source_quality")
           )
  end

  test "normalizes resource summary margin aliases before roll-forward projection" do
    activities = [
      %{
        id: :obs_alias,
        type: :observe,
        scenario_id: :leo_1,
        starts_at_s: 10.0,
        estimated_storage_mb: 10.0,
        estimated_energy_used_wh: 50.0
      },
      %{
        id: :dl_alias,
        type: :downlink,
        scenario_id: :leo_1,
        starts_at_s: 20.0,
        estimated_throughput_mb: 20.0,
        estimated_energy_used_wh: 50.0
      }
    ]

    summaries = [
      %{
        spacecraft_id: :leo_1,
        storage_capacity_mb: 100.0,
        storage_capacity_margin: "0.5",
        downlink_capacity_mb: 100.0,
        downlink_capacity_margin: "0.9",
        battery_capacity_wh: 1000.0,
        battery_soc: "0.8",
        fuel_margin: 0.9,
        source_quality: :operator_supplied,
        provenance: %{trust_boundary: :operator_declared_resource_summary}
      }
    ]

    assert %{
             "invalid_resource_summary_input_count" => 0,
             "projected_resources" => [
               %{
                 "starting_storage_used_mb" => 50.0,
                 "starting_storage_margin" => 0.5,
                 "projected_storage_used_mb" => 40.0,
                 "projected_storage_margin" => 0.6,
                 "starting_downlink_margin" => 0.9,
                 "projected_downlink_margin" => 0.8,
                 "battery_state_of_charge" => 0.8,
                 "projected_battery_state_of_charge" => 0.7,
                 "warnings" => []
               } = projection
             ]
           } = report = ResourceProjection.report(activities, summaries)

    assert_in_delta projection["starting_battery_energy_used_wh"], 200.0, 1.0e-9
    assert_in_delta projection["projected_battery_energy_used_wh"], 300.0, 1.0e-9

    assert {:ok, %{"schema_contract" => "resource_projection_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "projects downlink capacity from nested throughput model estimates" do
    report =
      ResourceProjection.report(
        [
          %{
            id: :obs_1,
            type: :observe,
            scenario_id: :leo_1,
            starts_at_s: 10.0,
            estimated_storage_mb: 60.0
          },
          %{
            id: :dl_nested,
            type: :downlink,
            scenario_id: :leo_1,
            starts_at_s: 20.0,
            throughput_model: %{
              estimated_throughput_mb: 80.0,
              station_capacity_fraction: 0.5
            }
          }
        ],
        [
          %{
            spacecraft_id: :leo_1,
            storage_capacity_mb: 100.0,
            storage_used_mb: 20.0,
            downlink_capacity_mb: 100.0
          }
        ]
      )

    assert %{
             "projected_resources" => [
               %{
                 "estimated_storage_produced_mb" => 60.0,
                 "estimated_downlink_mb" => 40.0,
                 "activity_resource_flow" => [
                   %{"activity_id" => "obs_1", "downlinked_mb" => +0.0},
                   %{
                     "activity_id" => "dl_nested",
                     "planned_downlink_mb" => 40.0,
                     "downlinked_mb" => 40.0,
                     "storage_used_after_mb" => 40.0,
                     "downlink_used_after_mb" => 40.0
                   }
                 ],
                 "projected_storage_used_mb" => 40.0,
                 "projected_downlink_margin" => 0.6
               }
             ]
           } = report

    assert {:ok, %{"schema_contract" => "resource_projection_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "flags declared activity battery depletion as resource pressure" do
    report =
      ResourceProjection.report(
        [
          %{
            id: :heater_run,
            type: :planned_contact,
            direction: :command,
            scenario_id: :leo_1,
            starts_at_s: 10.0,
            estimated_energy_used_wh: 50.0
          }
        ],
        [
          %{
            spacecraft_id: :leo_1,
            battery_capacity_wh: 100.0,
            battery_energy_used_wh: 80.0,
            source_quality: :operator_supplied,
            provenance: %{trust_boundary: :operator_declared_resource_summary}
          }
        ],
        approval_policy: %{policy_bundle_id: "conservative_ops_v1"}
      )

    assert %{
             "projected_resources" => [
               %{
                 "spacecraft_id" => "leo_1",
                 "power_margin" => 0.2,
                 "projected_power_margin" => projected_power_margin,
                 "starting_battery_energy_used_wh" => 80.0,
                 "projected_battery_energy_used_wh" => 130.0,
                 "projected_battery_state_of_charge" => projected_battery_state_of_charge,
                 "projected_battery_overuse_wh" => 30.0,
                 "resource_pressure_status" => "resource_pressure",
                 "resource_pressure_types" => ["battery_depletion"],
                 "first_resource_pressure_activity_id" => "heater_run",
                 "first_resource_pressure_kind" => "battery_depletion",
                 "approval_status" => "blocked_by_policy",
                 "approval_rule_matches" => [
                   %{
                     "rule_id" => "resource_pressure_block",
                     "risk_type" => "battery_depletion"
                   }
                 ],
                 "approval_requirements" => [
                   %{
                     "activity_context" => %{
                       "projected_battery_overuse_wh" => 30.0,
                       "projected_power_margin" => projected_power_margin_context,
                       "resource_pressure_types" => ["battery_depletion"]
                     }
                   }
                 ],
                 "activity_resource_flow" => [
                   %{
                     "activity_id" => "heater_run",
                     "battery_energy_used_before_wh" => 80.0,
                     "battery_energy_consumed_wh" => 50.0,
                     "battery_energy_delta_wh" => 50.0,
                     "battery_energy_used_after_wh" => 130.0,
                     "battery_state_of_charge_after" => battery_state_of_charge_after,
                     "battery_overuse_wh" => 30.0
                   }
                 ],
                 "warnings" => [
                   "projected battery energy use exceeds declared capacity by 30.0 Wh"
                 ]
               }
             ],
             "warnings" => [
               "projected battery energy use exceeds declared capacity by 30.0 Wh"
             ]
           } = report

    assert projected_power_margin == 0.0
    assert projected_battery_state_of_charge == 0.0
    assert projected_power_margin_context == 0.0
    assert battery_state_of_charge_after == 0.0

    assert {:ok, %{"schema_contract" => "resource_projection_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "flags externally supplied negative thermal margin as resource pressure" do
    report =
      ResourceProjection.report(
        [
          %{
            id: :nominal_observation,
            type: :observe,
            scenario_id: :leo_1,
            starts_at_s: 10.0,
            estimated_storage_mb: 5.0
          }
        ],
        [
          %{
            spacecraft_id: :leo_1,
            thermal_margin_c: -1.5,
            source_quality: :operator_supplied,
            provenance: %{trust_boundary: :operator_declared_resource_summary}
          }
        ],
        approval_policy: %{policy_bundle_id: "resource_projection_authority_v1"}
      )

    assert %{
             "projected_resources" => [
               %{
                 "spacecraft_id" => "leo_1",
                 "thermal_margin_c" => -1.5,
                 "resource_pressure_status" => "resource_pressure",
                 "resource_pressure_types" => ["thermal_margin_below_limit"],
                 "approval_status" => "operator_review_required",
                 "approval_rule_matches" => [
                   %{
                     "rule_id" => "resource_pressure_review",
                     "resource_pressure_types" => ["thermal_margin_below_limit"]
                   }
                 ],
                 "approval_requirements" => [
                   %{
                     "activity_context" => %{
                       "thermal_margin_c" => -1.5,
                       "resource_pressure_types" => ["thermal_margin_below_limit"]
                     }
                   }
                 ],
                 "warnings" => [
                   "externally supplied thermal margin is below zero; resource projection requires review"
                 ]
               }
             ],
             "warnings" => [
               "externally supplied thermal margin is below zero; resource projection requires review"
             ]
           } = report

    assert {:ok, %{"schema_contract" => "resource_projection_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_resource_projection_report(report)

    assert %{
             "review_type" => "resource_projection_review",
             "spacecraft_id" => "leo_1",
             "thermal_margin_c" => -1.5,
             "resource_pressure_types" => ["thermal_margin_below_limit"]
           } = hd(review["rows"])

    manifest = CadenceImport.from_resource_projection_report(report)

    assert %{
             "import_action" => "review_resource_projection",
             "spacecraft_id" => "leo_1",
             "thermal_margin_c" => -1.5,
             "resource_pressure_types" => ["thermal_margin_below_limit"]
           } = hd(manifest["rows"])
  end

  test "surfaces missing resource trust boundaries in projection rows" do
    report =
      ResourceProjection.report(
        [
          %{
            id: :obs_missing_trust,
            type: :observe,
            scenario_id: :leo_1,
            starts_at_s: 10.0,
            estimated_storage_mb: 30.0
          }
        ],
        [
          %{
            spacecraft_id: :leo_1,
            storage_capacity_mb: 100.0,
            storage_used_mb: 10.0,
            source_quality: :operator_supplied
          }
        ]
      )

    assert %{
             "resource_source_quality_counts" => %{"operator_supplied" => 1},
             "resource_spacecraft_ids_by_source_quality" => %{"operator_supplied" => ["leo_1"]},
             "resource_trust_boundary_status_counts" => %{"missing" => 1},
             "resource_spacecraft_ids_by_trust_boundary_status" => %{"missing" => ["leo_1"]},
             "projected_resources" => [
               %{
                 "spacecraft_id" => "leo_1",
                 "resource_source_quality" => "operator_supplied",
                 "resource_trust_boundary_status" => "missing"
               }
             ],
             "assumptions" => %{
               "resource_trust_boundary_model" =>
                 "resource_trust_boundary_status records whether each external resource summary declared a trust boundary"
             }
           } = report

    refute Map.has_key?(hd(report["projected_resources"]), "resource_trust_boundary")

    assert {:ok, %{"schema_contract" => "resource_projection_report.v1"}} =
             Schema.validate_artifact(report)

    assert %{
             "projected_resources" => [
               %{
                 "spacecraft_id" => "leo_1",
                 "resource_source_quality" => "operator_supplied",
                 "resource_trust_boundary_status" => "missing"
               }
             ]
           } = flow_summary = ResourceProjection.flow_summary(report)

    refute Map.has_key?(hd(flow_summary["projected_resources"]), "resource_trust_boundary")

    assert {:ok, %{"schema_contract" => "resource_projection_flow_summary.v1"}} =
             Schema.validate_artifact(flow_summary)

    stale_trust_boundary_ids =
      put_in(report, ["resource_spacecraft_ids_by_trust_boundary_status", "missing"], [
        "leo_2"
      ])

    assert {:error, trust_boundary_id_validation} =
             Schema.validate_artifact(stale_trust_boundary_ids)

    assert Enum.any?(
             trust_boundary_id_validation["errors"],
             &(&1["path"] == "$.resource_spacecraft_ids_by_trust_boundary_status" and
                 &1["message"] ==
                   "must equal row-derived resource_spacecraft_ids_by_trust_boundary_status")
           )
  end

  test "normalizes flattened resource provenance aliases in projection summaries" do
    report =
      ResourceProjection.report(
        [
          %{
            id: :obs_alias_provenance,
            type: :observe,
            scenario_id: :leo_1,
            starts_at_s: 10.0,
            estimated_storage_mb: 30.0
          }
        ],
        [
          %{
            spacecraft_id: :leo_1,
            storage_capacity_mb: 100.0,
            storage_used_mb: 10.0,
            provenance: %{
              resource_source_quality: :projection_model,
              resource_trust_boundary: :resource_projection
            }
          }
        ]
      )

    assert %{
             "resource_source_quality_counts" => %{"projection_model" => 1},
             "resource_spacecraft_ids_by_source_quality" => %{"projection_model" => ["leo_1"]},
             "resource_trust_boundary_status_counts" => %{"declared" => 1},
             "resource_spacecraft_ids_by_trust_boundary_status" => %{"declared" => ["leo_1"]},
             "projected_resources" => [
               %{
                 "spacecraft_id" => "leo_1",
                 "resource_source_quality" => "projection_model",
                 "resource_trust_boundary" => "resource_projection",
                 "resource_trust_boundary_status" => "declared",
                 "resource_provenance" => %{
                   "resource_source_quality" => "projection_model",
                   "resource_trust_boundary" => "resource_projection"
                 }
               }
             ]
           } = report

    assert {:ok, %{"schema_contract" => "resource_projection_report.v1"}} =
             Schema.validate_artifact(report)

    assert %{
             "projected_resources" => [
               %{
                 "spacecraft_id" => "leo_1",
                 "resource_source_quality" => "projection_model",
                 "resource_trust_boundary" => "resource_projection",
                 "resource_trust_boundary_status" => "declared",
                 "resource_provenance" => %{
                   "resource_source_quality" => "projection_model",
                   "resource_trust_boundary" => "resource_projection"
                 }
               }
             ]
           } = flow_summary = ResourceProjection.flow_summary(report)

    assert {:ok, %{"schema_contract" => "resource_projection_flow_summary.v1"}} =
             Schema.validate_artifact(flow_summary)
  end

  test "audits terminal or rejected activities without projecting resource effects" do
    report =
      ResourceProjection.report(
        [
          %{
            id: :obs_active,
            type: :observe,
            scenario_id: :leo_1,
            starts_at_s: 10.0,
            estimated_storage_mb: 30.0,
            status: :planned
          },
          %{
            id: :obs_canceled,
            type: :observe,
            scenario_id: :leo_1,
            starts_at_s: 20.0,
            estimated_storage_mb: 100.0,
            status: :canceled
          },
          %{
            id: :dl_completed,
            type: :downlink,
            scenario_id: :leo_1,
            starts_at_s: 30.0,
            estimated_throughput_mb: 50.0,
            status: :completed
          },
          %{
            id: :dl_rejected,
            type: :planned_contact,
            direction: :downlink,
            scenario_id: :leo_1,
            starts_at_s: 40.0,
            estimated_throughput_mb: 25.0,
            approval_status: :rejected
          },
          %{
            id: :dl_completed_rejected,
            type: :planned_contact,
            direction: :downlink,
            scenario_id: :leo_1,
            starts_at_s: 50.0,
            estimated_throughput_mb: 25.0,
            status: :completed,
            approval_status: :rejected
          }
        ],
        [
          %{
            spacecraft_id: :leo_1,
            storage_capacity_mb: 100.0,
            storage_used_mb: 10.0,
            downlink_capacity_mb: 100.0
          }
        ]
      )

    assert %{
             "projected_resources" => [
               %{
                 "activity_count" => 5,
                 "effective_activity_count" => 1,
                 "ignored_activity_count" => 4,
                 "ignored_activity_ids" => [
                   "obs_canceled",
                   "dl_completed",
                   "dl_rejected",
                   "dl_completed_rejected"
                 ],
                 "observation_count" => 1,
                 "downlink_count" => 0,
                 "estimated_storage_produced_mb" => 30.0,
                 "estimated_downlink_mb" => 0,
                 "storage_limited_downlinked_mb" => +0.0,
                 "projected_storage_used_mb" => 40.0,
                 "projected_downlink_margin" => 1.0,
                 "activity_resource_flow" => [
                   %{
                     "activity_id" => "obs_active",
                     "activity_status" => "planned",
                     "resource_effect_status" => "projected",
                     "resource_effect_reason" => "active_planning_activity",
                     "storage_produced_mb" => 30.0,
                     "storage_delta_mb" => 30.0,
                     "storage_used_after_mb" => 40.0,
                     "downlink_used_after_mb" => +0.0
                   },
                   %{
                     "activity_id" => "obs_canceled",
                     "activity_status" => "canceled",
                     "resource_effect_status" => "ignored",
                     "resource_effect_reason" => "activity_status_canceled",
                     "storage_produced_mb" => +0.0,
                     "storage_delta_mb" => +0.0,
                     "storage_used_after_mb" => 40.0,
                     "downlink_used_after_mb" => +0.0
                   },
                   %{
                     "activity_id" => "dl_completed",
                     "activity_status" => "completed",
                     "resource_effect_status" => "ignored",
                     "resource_effect_reason" => "activity_status_completed",
                     "planned_downlink_mb" => +0.0,
                     "downlinked_mb" => +0.0,
                     "storage_delta_mb" => +0.0,
                     "storage_used_after_mb" => 40.0,
                     "downlink_used_after_mb" => +0.0
                   },
                   %{
                     "activity_id" => "dl_rejected",
                     "activity_status" => "planned",
                     "approval_status" => "rejected",
                     "resource_effect_status" => "ignored",
                     "resource_effect_reason" => "approval_status_rejected",
                     "planned_downlink_mb" => +0.0,
                     "downlinked_mb" => +0.0,
                     "storage_delta_mb" => +0.0,
                     "storage_used_after_mb" => 40.0,
                     "downlink_used_after_mb" => +0.0
                   },
                   %{
                     "activity_id" => "dl_completed_rejected",
                     "activity_status" => "completed",
                     "approval_status" => "rejected",
                     "resource_effect_status" => "ignored",
                     "resource_effect_reason" => "approval_status_rejected",
                     "planned_downlink_mb" => +0.0,
                     "downlinked_mb" => +0.0,
                     "storage_delta_mb" => +0.0,
                     "storage_used_after_mb" => 40.0,
                     "downlink_used_after_mb" => +0.0
                   }
                 ]
               }
             ],
             "assumptions" => %{
               "activity_status_model" =>
                 "terminal_or_approval_rejected_activities_are_audited_with_zero_projected_resource_effect"
             }
           } = report

    assert {:ok, %{"schema_contract" => "resource_projection_report.v1"}} =
             Schema.validate_artifact(report)

    assert %{
             "schema_contract" => "resource_projection_flow_summary.v1",
             "ignored_activity_count" => 4,
             "ignored_activity_ids" => [
               "dl_completed",
               "dl_completed_rejected",
               "dl_rejected",
               "obs_canceled"
             ],
             "ignored_activity_reason_counts" => %{
               "activity_status_canceled" => 1,
               "activity_status_completed" => 1,
               "approval_status_rejected" => 2
             },
             "ignored_activity_ids_by_reason" => %{
               "activity_status_canceled" => ["obs_canceled"],
               "activity_status_completed" => ["dl_completed"],
               "approval_status_rejected" => ["dl_completed_rejected", "dl_rejected"]
             }
           } = flow_summary = ResourceProjection.flow_summary(report)

    assert {:ok, %{"schema_contract" => "resource_projection_flow_summary.v1"}} =
             Schema.validate_artifact(flow_summary)

    stale_ignored_summary =
      flow_summary
      |> Map.put("ignored_activity_count", 0)
      |> Map.put("ignored_activity_reason_counts", %{"stale" => 9})
      |> Map.put("ignored_activity_ids", ["stale"])
      |> Map.put("ignored_activity_ids_by_reason", %{"stale" => ["stale"]})

    assert {:error, %{"errors" => stale_ignored_errors}} =
             Schema.validate_artifact(stale_ignored_summary)

    assert Enum.any?(
             stale_ignored_errors,
             &(&1["path"] == "$.ignored_activity_count" and
                 &1["message"] == "must equal ignored activity_resource_flow row count")
           )

    assert Enum.any?(
             stale_ignored_errors,
             &(&1["path"] == "$.ignored_activity_reason_counts" and
                 &1["message"] == "must equal ignored activity_resource_flow reason counts")
           )

    assert Enum.any?(
             stale_ignored_errors,
             &(&1["path"] == "$.ignored_activity_ids" and
                 &1["message"] == "must equal ignored activity_resource_flow activity IDs")
           )

    assert Enum.any?(
             stale_ignored_errors,
             &(&1["path"] == "$.ignored_activity_ids_by_reason" and
                 &1["message"] ==
                   "must equal ignored activity_resource_flow activity IDs by reason")
           )

    negative_reason_counts =
      put_in(flow_summary, ["ignored_activity_reason_counts", "approval_status_rejected"], -1)

    assert {:error, %{"errors" => negative_reason_count_errors}} =
             Schema.validate_artifact(negative_reason_counts)

    assert Enum.any?(
             negative_reason_count_errors,
             &(&1["path"] == "$.ignored_activity_reason_counts.approval_status_rejected" and
                 &1["message"] == "must be a non-negative integer")
           )
  end

  test "audits spacecraft-unavailable summaries as resource pressure with zero activity effects" do
    report =
      ResourceProjection.report(
        [
          %{
            id: :obs_unavailable,
            type: :observe,
            scenario_id: :leo_1,
            starts_at_s: 10.0,
            estimated_storage_mb: 40.0
          },
          %{
            id: :dl_unavailable,
            type: :downlink,
            scenario_id: :leo_1,
            starts_at_s: 20.0,
            estimated_throughput_mb: 30.0
          }
        ],
        [
          %{
            spacecraft_id: :leo_1,
            spacecraft_status: "offline",
            storage_capacity_mb: 100.0,
            storage_used_mb: 10.0,
            downlink_capacity_mb: 100.0,
            source_quality: :operator_supplied,
            provenance: %{trust_boundary: :operator_declared_resource_summary}
          }
        ],
        approval_policy: %{policy_bundle_id: "conservative_ops_v1"}
      )

    assert %{
             "projected_resources" => [
               %{
                 "spacecraft_id" => "leo_1",
                 "spacecraft_available" => false,
                 "activity_count" => 2,
                 "effective_activity_count" => 0,
                 "ignored_activity_count" => 2,
                 "ignored_activity_ids" => ["obs_unavailable", "dl_unavailable"],
                 "estimated_storage_produced_mb" => 0,
                 "estimated_downlink_mb" => 0,
                 "projected_storage_used_mb" => 10.0,
                 "resource_pressure_status" => "spacecraft_unavailable",
                 "resource_pressure_types" => ["spacecraft_unavailable"],
                 "approval_status" => "blocked_by_policy",
                 "approval_requirements" => [
                   %{
                     "id" => "approval:resource_projection:leo_1:spacecraft_unavailable",
                     "activity_context" => %{
                       "spacecraft_available" => false,
                       "resource_pressure_status" => "spacecraft_unavailable",
                       "resource_pressure_types" => ["spacecraft_unavailable"]
                     }
                   }
                 ],
                 "approval_rule_matches" => [
                   %{
                     "rule_id" => "resource_pressure_block",
                     "risk_type" => "spacecraft_unavailable"
                   }
                 ],
                 "activity_resource_flow" => [
                   %{
                     "activity_id" => "obs_unavailable",
                     "resource_effect_status" => "ignored",
                     "resource_effect_reason" => "spacecraft_unavailable",
                     "storage_produced_mb" => +0.0,
                     "storage_used_after_mb" => 10.0
                   },
                   %{
                     "activity_id" => "dl_unavailable",
                     "resource_effect_status" => "ignored",
                     "resource_effect_reason" => "spacecraft_unavailable",
                     "downlinked_mb" => +0.0,
                     "downlink_used_after_mb" => +0.0
                   }
                 ],
                 "warnings" => [
                   "spacecraft unavailable; projected activity resource effects are ignored"
                 ]
               }
             ],
             "warnings" => [
               "spacecraft unavailable; projected activity resource effects are ignored"
             ]
           } = report

    assert {:ok, %{"schema_contract" => "resource_projection_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_resource_projection_report(report)

    assert [
             %{
               "review_type" => "resource_projection_review",
               "spacecraft_available" => false,
               "resource_pressure_status" => "spacecraft_unavailable",
               "resource_pressure_types" => ["spacecraft_unavailable"],
               "source_resource_projection" => %{"spacecraft_available" => false}
             }
           ] = review["rows"]

    manifest = CadenceImport.from_resource_projection_report(report)

    assert [
             %{
               "import_action" => "review_resource_projection",
               "spacecraft_available" => false,
               "resource_pressure_status" => "spacecraft_unavailable",
               "resource_pressure_types" => ["spacecraft_unavailable"],
               "source_resource_projection" => %{"spacecraft_available" => false}
             }
           ] = manifest["rows"]
  end

  test "audits payload and antenna unavailable summaries as zero-effect activity pressure" do
    report =
      ResourceProjection.report(
        [
          %{
            id: :obs_payload_down,
            type: :observe,
            scenario_id: :leo_1,
            starts_at_s: 10.0,
            estimated_storage_mb: 40.0
          },
          %{
            id: :dl_antenna_down,
            type: :planned_contact,
            direction: :downlink,
            scenario_id: :leo_1,
            ground_station_id: :equator_prime,
            starts_at_s: 20.0,
            estimated_throughput_mb: 30.0
          }
        ],
        [
          %{
            spacecraft_id: :leo_1,
            payload_status: "down",
            antenna_status: "maintenance",
            storage_capacity_mb: 100.0,
            storage_used_mb: 10.0,
            downlink_capacity_mb: 100.0,
            source_quality: :operator_supplied,
            provenance: %{trust_boundary: :operator_resource_health}
          }
        ],
        approval_policy: %{policy_bundle_id: "resource_projection_authority_v1"}
      )

    assert [row] = report["projected_resources"]

    assert %{
             "spacecraft_id" => "leo_1",
             "payload_available" => false,
             "antenna_available" => false,
             "activity_count" => 2,
             "effective_activity_count" => 0,
             "ignored_activity_count" => 2,
             "ignored_activity_ids" => ["obs_payload_down", "dl_antenna_down"],
             "estimated_storage_produced_mb" => 0,
             "estimated_downlink_mb" => 0,
             "projected_storage_used_mb" => 10.0,
             "resource_pressure_status" => "resource_availability_pressure",
             "resource_pressure_types" => ["antenna_unavailable", "payload_unavailable"],
             "first_resource_pressure_activity_id" => "obs_payload_down",
             "first_resource_pressure_activity_type" => "observe",
             "first_resource_pressure_kind" => "payload_unavailable",
             "approval_status" => "operator_review_required",
             "approval_rule_matches" => rule_matches,
             "warnings" => [
               "payload unavailable; projected observation resource effects are ignored",
               "antenna unavailable; projected contact resource effects are ignored"
             ]
           } = row

    assert [
             %{
               "activity_id" => "obs_payload_down",
               "resource_effect_status" => "ignored",
               "resource_effect_reason" => "payload_unavailable",
               "storage_produced_mb" => +0.0,
               "storage_used_after_mb" => 10.0
             },
             %{
               "activity_id" => "dl_antenna_down",
               "resource_effect_status" => "ignored",
               "resource_effect_reason" => "antenna_unavailable",
               "downlinked_mb" => +0.0,
               "downlink_used_after_mb" => +0.0
             }
           ] = row["activity_resource_flow"]

    assert Enum.sort(report["warnings"]) == [
             "antenna unavailable; projected contact resource effects are ignored",
             "payload unavailable; projected observation resource effects are ignored"
           ]

    assert Enum.any?(
             rule_matches,
             &(&1["rule_id"] == "resource_pressure_review" and
                 &1["resource_pressure_types"] == [
                   "antenna_unavailable",
                   "payload_unavailable"
                 ])
           )

    assert {:ok, %{"schema_contract" => "resource_projection_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_resource_projection_report(report)

    assert [
             %{
               "review_type" => "resource_projection_review",
               "resource_pressure_status" => "resource_availability_pressure",
               "resource_pressure_types" => ["antenna_unavailable", "payload_unavailable"],
               "first_resource_pressure_activity_id" => "obs_payload_down",
               "first_resource_pressure_kind" => "payload_unavailable",
               "payload_available" => false,
               "antenna_available" => false
             }
           ] = review["rows"]

    manifest = CadenceImport.from_resource_projection_report(report)

    assert [
             %{
               "import_action" => "review_resource_projection",
               "resource_pressure_status" => "resource_availability_pressure",
               "resource_pressure_types" => ["antenna_unavailable", "payload_unavailable"],
               "payload_available" => false,
               "antenna_available" => false
             }
           ] = manifest["rows"]
  end

  test "audits resource-summary activity type suppressions as zero-effect pressure" do
    report =
      ResourceProjection.report(
        [
          %{
            id: :obs_safe_mode,
            type: :observe,
            scenario_id: :sat_mode,
            starts_at_s: 10.0,
            estimated_storage_mb: 40.0
          },
          %{
            id: :cmd_safe_mode,
            type: :planned_contact,
            direction: :uplink,
            scenario_id: :sat_mode,
            ground_station_id: :equator_prime,
            starts_at_s: 20.0,
            estimated_throughput_mb: 30.0
          },
          %{
            id: :tracking_safe_mode,
            type: :tracking,
            scenario_id: :sat_mode,
            ground_station_id: :equator_prime,
            starts_at_s: 30.0,
            estimated_throughput_mb: 10.0
          }
        ],
        [
          %{
            spacecraft_id: :sat_mode,
            mode: :safe,
            suppressed_activity_types: "observe",
            incompatible_activity_types: ["command"],
            storage_capacity_mb: 100.0,
            storage_used_mb: 10.0,
            downlink_capacity_mb: 100.0,
            source_quality: :operator_supplied,
            provenance: %{trust_boundary: :resource_mode_summary}
          }
        ],
        approval_policy: %{policy_bundle_id: "resource_projection_authority_v1"}
      )

    assert [row] = report["projected_resources"]

    assert %{
             "spacecraft_id" => "sat_mode",
             "mode" => "safe",
             "suppressed_activity_types" => ["observe"],
             "incompatible_activity_types" => ["command"],
             "activity_count" => 3,
             "effective_activity_count" => 1,
             "ignored_activity_count" => 2,
             "ignored_activity_ids" => ["obs_safe_mode", "cmd_safe_mode"],
             "resource_pressure_status" => "resource_availability_pressure",
             "resource_pressure_types" => [
               "activity_type_incompatible_with_resource_summary",
               "activity_type_suppressed_by_resource_summary"
             ],
             "first_resource_pressure_activity_id" => "obs_safe_mode",
             "first_resource_pressure_kind" => "activity_type_suppressed_by_resource_summary",
             "approval_status" => "operator_review_required",
             "warnings" => warnings
           } = row

    assert [
             %{
               "activity_id" => "obs_safe_mode",
               "resource_effect_status" => "ignored",
               "resource_effect_reason" => "activity_type_suppressed_by_resource_summary",
               "mode" => "safe",
               "suppressed_activity_types" => ["observe"],
               "storage_produced_mb" => +0.0
             },
             %{
               "activity_id" => "cmd_safe_mode",
               "resource_effect_status" => "ignored",
               "resource_effect_reason" => "activity_type_incompatible_with_resource_summary",
               "incompatible_activity_types" => ["command"]
             },
             %{
               "activity_id" => "tracking_safe_mode",
               "resource_effect_status" => "projected"
             }
           ] = row["activity_resource_flow"]

    assert "resource summary suppresses one or more selected activity types; projected resource effects are ignored" in warnings

    assert "resource summary marks one or more selected activity types incompatible; projected resource effects are ignored" in warnings

    review = OperatorReview.from_resource_projection_report(report)

    assert [
             %{
               "review_type" => "resource_projection_review",
               "mode" => "safe",
               "suppressed_activity_types" => ["observe"],
               "incompatible_activity_types" => ["command"],
               "source_resource_projection" => ^row
             }
           ] = review["rows"]

    manifest = CadenceImport.from_resource_projection_report(report)

    assert [
             %{
               "import_action" => "review_resource_projection",
               "mode" => "safe",
               "suppressed_activity_types" => ["observe"],
               "incompatible_activity_types" => ["command"],
               "source_resource_projection" => ^row
             }
           ] = manifest["rows"]

    assert {:ok, %{"schema_contract" => "resource_projection_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "preserves realized data volume evidence without reconciling resource state" do
    report =
      ResourceProjection.report(
        [
          %{
            id: :obs_partial,
            type: :observe,
            scenario_id: :leo_1,
            starts_at_s: 10.0,
            estimated_storage_mb: 50.0,
            data_volume_mb: 50.0,
            delivered_data_mb: 35.0,
            completed_fraction: 0.7,
            status: :partial
          },
          %{
            id: :obs_planned,
            type: :observe,
            scenario_id: :leo_1,
            starts_at_s: 20.0,
            estimated_storage_mb: 10.0
          }
        ],
        [
          %{
            spacecraft_id: :leo_1,
            storage_capacity_mb: 100.0,
            storage_used_mb: 20.0
          }
        ]
      )

    assert %{
             "projected_resources" => [
               %{
                 "effective_activity_count" => 1,
                 "ignored_activity_count" => 1,
                 "ignored_activity_ids" => ["obs_partial"],
                 "estimated_storage_produced_mb" => 10.0,
                 "projected_storage_used_mb" => 30.0,
                 "activity_resource_flow" => [
                   %{
                     "activity_id" => "obs_partial",
                     "activity_status" => "partial",
                     "resource_effect_status" => "ignored",
                     "resource_effect_reason" => "activity_status_partial",
                     "planned_data_volume_mb" => 50.0,
                     "actual_data_volume_mb" => 35.0,
                     "data_volume_delta_mb" => -15.0,
                     "data_volume_completion_fraction" => 0.7,
                     "completed_fraction" => 0.7,
                     "storage_produced_mb" => +0.0,
                     "storage_delta_mb" => +0.0,
                     "storage_used_after_mb" => 20.0
                   },
                   %{
                     "activity_id" => "obs_planned",
                     "resource_effect_status" => "projected",
                     "storage_produced_mb" => 10.0,
                     "storage_used_after_mb" => 30.0
                   }
                 ]
               } = projection
             ],
             "assumptions" => %{
               "realized_data_volume_model" =>
                 "actual data-volume fields and delivered/received aliases are preserved as evidence and do not reconcile projected resource state"
             }
           } = report

    assert {:ok, %{"schema_contract" => "resource_projection_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_resource_projection_report(report)

    assert [
             %{
               "source_resource_projection" => ^projection
             }
           ] = review["rows"]

    manifest = CadenceImport.from_resource_projection_report(report)

    assert [
             %{
               "source_resource_projection" => ^projection
             }
           ] = manifest["rows"]
  end

  test "review-gates out-of-range completed fraction evidence before flow rows" do
    report =
      ResourceProjection.report(
        [
          %{
            id: :obs_overcomplete,
            type: :observe,
            scenario_id: :leo_1,
            starts_at_s: 10.0,
            estimated_storage_mb: 10.0,
            completed_fraction: 1.4,
            status: :partial
          },
          %{
            id: :obs_undercomplete,
            type: :observe,
            scenario_id: :leo_1,
            starts_at_s: 20.0,
            estimated_storage_mb: 10.0,
            metadata: %{completion_fraction: -0.25},
            status: :partial
          }
        ],
        [
          %{
            spacecraft_id: :leo_1,
            storage_capacity_mb: 100.0,
            storage_used_mb: 20.0
          }
        ],
        approval_policy: %{policy_bundle_id: "resource_projection_authority_v1"}
      )

    assert %{
             "activity_count" => 2,
             "valid_activity_count" => 0,
             "invalid_activity_input_count" => 2,
             "invalid_activity_input_ids" => ["obs_overcomplete", "obs_undercomplete"],
             "invalid_activity_inputs" => invalid_inputs,
             "projected_resources" => [
               %{
                 "activity_count" => 0,
                 "activity_resource_flow" => []
               }
             ],
             "assumptions" => %{
               "invalid_activity_input" =>
                 "selected activity inputs missing stable identity, activity type, valid unit-interval completion or capacity-fraction evidence, or valid non-negative resource quantities are preserved for operator review and excluded from resource projection"
             }
           } = report

    assert %{
             "activity_id" => "obs_overcomplete",
             "invalid_activity_input_reason" => "invalid_completed_fraction",
             "source_activity" => %{"completed_fraction" => 1.4},
             "approval_rule_matches" => [
               %{"rule_id" => "invalid_resource_projection_activity_input_review"}
             ],
             "policy_decision" => %{
               "policy_bundle_id" => "resource_projection_authority_v1"
             }
           } = Enum.find(invalid_inputs, &(&1["activity_id"] == "obs_overcomplete"))

    assert %{
             "activity_id" => "obs_undercomplete",
             "invalid_activity_input_reason" => "invalid_completion_fraction",
             "source_activity" => %{"metadata" => %{"completion_fraction" => -0.25}}
           } = Enum.find(invalid_inputs, &(&1["activity_id"] == "obs_undercomplete"))

    assert {:ok, %{"schema_contract" => "resource_projection_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_resource_projection_report(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert Enum.any?(review["rows"], fn row ->
             row["activity_id"] == "obs_overcomplete" and
               row["invalid_activity_input_reason"] == "invalid_completed_fraction" and
               get_in(row, ["source_activity", "completed_fraction"]) == 1.4
           end)

    manifest = CadenceImport.from_resource_projection_report(report)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    assert Enum.any?(manifest["rows"], fn row ->
             row["required_operator_action"] == "review_invalid_resource_projection_input" and
               row["activity_id"] == "obs_undercomplete" and
               row["invalid_activity_input_reason"] == "invalid_completion_fraction" and
               get_in(row, ["source_activity", "metadata", "completion_fraction"]) == -0.25
           end)
  end

  test "review-gates malformed realized data volume evidence before flow rows" do
    activities = [
      %{
        id: :obs_negative_actual,
        type: :observe,
        scenario_id: :leo_1,
        starts_at_s: 10.0,
        estimated_storage_mb: 10.0,
        delivered_data_mb: -1.0
      },
      %{
        id: :obs_bad_received,
        type: :observe,
        scenario_id: :leo_1,
        starts_at_s: 20.0,
        estimated_storage_mb: 10.0,
        metadata: %{received_data_mb: "unknown"}
      }
    ]

    summaries = [
      %{
        spacecraft_id: :leo_1,
        storage_capacity_mb: 100.0,
        storage_used_mb: 20.0
      }
    ]

    assert %{
             "activity_count" => 2,
             "valid_activity_count" => 0,
             "invalid_activity_input_count" => 2,
             "invalid_activity_input_ids" => ["obs_negative_actual", "obs_bad_received"],
             "invalid_activity_inputs" => invalid_inputs,
             "projected_resources" => [
               %{
                 "activity_count" => 0,
                 "activity_resource_flow" => []
               }
             ]
           } = report = ResourceProjection.report(activities, summaries)

    assert %{
             "activity_id" => "obs_negative_actual",
             "invalid_activity_input_reason" => "negative_delivered_data_mb",
             "source_activity" => %{"delivered_data_mb" => -1.0}
           } = Enum.find(invalid_inputs, &(&1["activity_id"] == "obs_negative_actual"))

    assert %{
             "activity_id" => "obs_bad_received",
             "invalid_activity_input_reason" => "invalid_received_data_mb",
             "source_activity" => %{"metadata" => %{"received_data_mb" => "unknown"}}
           } = Enum.find(invalid_inputs, &(&1["activity_id"] == "obs_bad_received"))

    assert {:ok, %{"schema_contract" => "resource_projection_report.v1"}} =
             Schema.validate_artifact(report)

    assert %{
             "resource_flow_status" => "review_required",
             "invalid_activity_input_count" => 2,
             "invalid_activity_input_ids" => ["obs_negative_actual", "obs_bad_received"],
             "flow_row_count" => 0,
             "activity_resource_flow" => []
           } = ResourceProjection.flow_report(activities, summaries)
  end

  test "schema validation rejects inconsistent resource effect counts" do
    report =
      ResourceProjection.report(
        [
          %{
            id: :obs_canceled,
            type: :observe,
            scenario_id: :leo_1,
            starts_at_s: 10.0,
            estimated_storage_mb: 100.0,
            status: :canceled
          }
        ],
        [
          %{
            spacecraft_id: :leo_1,
            storage_capacity_mb: 100.0,
            storage_used_mb: 10.0
          }
        ]
      )

    invalid_report =
      update_in(report, ["projected_resources", Access.at(0)], fn row ->
        row
        |> Map.put("ignored_activity_count", 0)
        |> Map.put("ignored_activity_ids", [])
      end)

    assert {:error, %{"errors" => errors}} = Schema.validate_artifact(invalid_report)

    assert Enum.any?(
             errors,
             &(&1["path"] == "$.projected_resources[0].ignored_activity_count" and
                 &1["message"] == "must equal 1")
           )

    assert Enum.any?(
             errors,
             &(&1["path"] == "$.projected_resources[0].ignored_activity_ids" and
                 &1["message"] == "must match ignored activity flow row IDs")
           )

    stale_flow_count_report =
      update_in(report, ["projected_resources", Access.at(0)], fn row ->
        row
        |> Map.put("activity_count", 0)
        |> Map.put("effective_activity_count", 1)
        |> Map.put("observation_count", 1)
        |> Map.put("downlink_count", 1)
      end)

    assert {:error, %{"errors" => stale_flow_count_errors}} =
             Schema.validate_artifact(stale_flow_count_report)

    assert Enum.any?(
             stale_flow_count_errors,
             &(&1["path"] == "$.projected_resources[0].activity_count" and
                 &1["message"] == "must equal activity_resource_flow row count")
           )

    assert Enum.any?(
             stale_flow_count_errors,
             &(&1["path"] == "$.projected_resources[0].effective_activity_count" and
                 &1["message"] == "must equal projected activity_resource_flow row count")
           )

    assert Enum.any?(
             stale_flow_count_errors,
             &(&1["path"] == "$.projected_resources[0].observation_count" and
                 &1["message"] == "must equal projected observe flow row count")
           )

    assert Enum.any?(
             stale_flow_count_errors,
             &(&1["path"] == "$.projected_resources[0].downlink_count" and
                 &1["message"] == "must equal projected downlink flow row count")
           )
  end

  test "rolls forward planned-contact downlinks without treating command contacts as downlink relief" do
    report =
      ResourceProjection.report(
        [
          %{
            id: :obs_1,
            type: :observe,
            scenario_id: :leo_1,
            starts_at_s: 10.0,
            estimated_storage_mb: 40.0
          },
          %{
            id: :planned_downlink,
            type: :planned_contact,
            direction: :downlink,
            scenario_id: :leo_1,
            starts_at_s: 20.0,
            estimated_throughput_mb: 30.0,
            station_capacity_fraction: 0.5
          },
          %{
            id: :planned_command,
            type: :planned_contact,
            direction: :command,
            scenario_id: :leo_1,
            starts_at_s: 30.0,
            estimated_throughput_mb: 100.0
          }
        ],
        [
          %{
            spacecraft_id: :leo_1,
            storage_capacity_mb: 100.0,
            storage_used_mb: 20.0,
            downlink_capacity_mb: 100.0
          }
        ]
      )

    assert %{
             "projected_resources" => [
               %{
                 "downlink_count" => 1,
                 "estimated_downlink_mb" => 15.0,
                 "activity_resource_flow" => [
                   %{"activity_id" => "obs_1", "downlinked_mb" => +0.0},
                   %{
                     "activity_id" => "planned_downlink",
                     "activity_type" => "planned_contact",
                     "downlinked_mb" => 15.0,
                     "storage_delta_mb" => -15.0
                   },
                   %{
                     "activity_id" => "planned_command",
                     "activity_type" => "planned_contact",
                     "downlinked_mb" => +0.0,
                     "storage_delta_mb" => +0.0
                   }
                 ],
                 "projected_storage_used_mb" => 45.0,
                 "projected_downlink_margin" => 0.85
               }
             ]
           } = report

    assert {:ok, %{"schema_contract" => "resource_projection_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "rolls forward provider contact downlinks with station id aliases" do
    report =
      ResourceProjection.report(
        [
          %{
            id: :obs_provider,
            type: :observe,
            scenario_id: :leo_1,
            starts_at_s: 10.0,
            estimated_storage_mb: 50.0
          },
          %{
            id: :provider_downlink,
            type: :contact,
            direction: "down",
            scenario_id: :leo_1,
            station_id: :equator_prime,
            starts_at_s: 20.0,
            estimated_throughput_mb: 40.0,
            station_capacity_fraction: 0.5,
            source_station_calendar_entry: %{
              id: :provider_downlink_calendar,
              directions: ["downlinking"]
            }
          },
          %{
            id: :provider_command,
            type: :contact,
            direction: "s-band command",
            scenario_id: :leo_1,
            station_id: :equator_prime,
            starts_at_s: 30.0,
            estimated_throughput_mb: 90.0,
            source_station_calendar_entry: %{
              id: :provider_command_calendar,
              directions: ["commands"]
            }
          }
        ],
        [
          %{
            spacecraft: %{id: :leo_1},
            storage_capacity_mb: 100.0,
            storage_used_mb: 10.0,
            downlink_capacity_mb: 80.0
          }
        ]
      )

    assert %{
             "projected_resources" => [
               %{
                 "downlink_count" => 1,
                 "estimated_downlink_mb" => 20.0,
                 "storage_limited_downlinked_mb" => 20.0,
                 "activity_resource_flow" => [
                   %{"activity_id" => "obs_provider", "storage_used_after_mb" => 60.0},
                   %{
                     "activity_id" => "provider_downlink",
                     "activity_type" => "contact",
                     "direction" => "downlink",
                     "ground_station_id" => "equator_prime",
                     "station_calendar_directions" => ["downlink"],
                     "planned_downlink_mb" => 20.0,
                     "downlinked_mb" => 20.0,
                     "storage_delta_mb" => -20.0,
                     "storage_used_after_mb" => 40.0,
                     "downlink_used_after_mb" => 20.0
                   },
                   %{
                     "activity_id" => "provider_command",
                     "activity_type" => "contact",
                     "direction" => "command",
                     "ground_station_id" => "equator_prime",
                     "station_calendar_directions" => ["command"],
                     "downlinked_mb" => +0.0,
                     "storage_delta_mb" => +0.0,
                     "storage_used_after_mb" => 40.0,
                     "downlink_used_after_mb" => 20.0
                   }
                 ],
                 "projected_storage_used_mb" => 40.0,
                 "projected_storage_margin" => 0.6,
                 "projected_downlink_margin" => 0.75
               }
             ]
           } = report

    assert {:ok, %{"schema_contract" => "resource_projection_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "rolls forward provider contact downlinks with nested station identity" do
    report =
      ResourceProjection.report(
        [
          %{
            id: :obs_provider,
            type: :observe,
            scenario_id: :leo_1,
            starts_at_s: 10.0,
            estimated_storage_mb: 60.0
          },
          %{
            id: :provider_nested_station_downlink,
            type: :contact,
            direction: :downlink,
            scenario_id: :leo_1,
            station: %{id: :equator_prime},
            starts_at_s: 20.0,
            estimated_throughput_mb: 40.0,
            station_capacity_fraction: 0.5
          },
          %{
            id: :provider_nested_ground_station_command,
            type: :contact,
            direction: :command,
            scenario_id: :leo_1,
            ground_station: %{ground_station_id: :equator_prime},
            starts_at_s: 30.0,
            estimated_throughput_mb: 90.0
          }
        ],
        [
          %{
            spacecraft_id: :leo_1,
            storage_capacity_mb: 100.0,
            storage_used_mb: 10.0,
            downlink_capacity_mb: 80.0
          }
        ]
      )

    assert %{
             "projected_resources" => [
               %{
                 "downlink_count" => 1,
                 "estimated_downlink_mb" => 20.0,
                 "storage_limited_downlinked_mb" => 20.0,
                 "activity_resource_flow" => [
                   %{"activity_id" => "obs_provider", "storage_used_after_mb" => 70.0},
                   %{
                     "activity_id" => "provider_nested_station_downlink",
                     "activity_type" => "contact",
                     "ground_station_id" => "equator_prime",
                     "planned_downlink_mb" => 20.0,
                     "downlinked_mb" => 20.0,
                     "storage_delta_mb" => -20.0,
                     "storage_used_after_mb" => 50.0
                   },
                   %{
                     "activity_id" => "provider_nested_ground_station_command",
                     "activity_type" => "contact",
                     "ground_station_id" => "equator_prime",
                     "downlinked_mb" => +0.0,
                     "storage_delta_mb" => +0.0,
                     "storage_used_after_mb" => 50.0
                   }
                 ]
               }
             ]
           } = report

    assert {:ok, %{"schema_contract" => "resource_projection_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "infers provider-shaped station contacts without type as downlink relief" do
    report =
      ResourceProjection.report(
        [
          %{
            id: :obs_provider,
            type: :observe,
            scenario_id: :leo_1,
            starts_at_s: 10.0,
            estimated_storage_mb: 50.0
          },
          %{
            id: :provider_downlink,
            scenario_id: :leo_1,
            station_id: :equator_prime,
            start_s: 20.0,
            end_s: 40.0,
            estimated_throughput_mb: 40.0,
            station_capacity_fraction: 0.5
          },
          %{
            id: :provider_command_without_type,
            scenario_id: :leo_1,
            station_id: :equator_prime,
            start_s: 50.0,
            end_s: 60.0,
            command_result: :accepted,
            estimated_throughput_mb: 90.0
          }
        ],
        [
          %{
            spacecraft_id: :leo_1,
            storage_capacity_mb: 100.0,
            storage_used_mb: 10.0,
            downlink_capacity_mb: 80.0
          }
        ]
      )

    assert %{
             "activity_count" => 3,
             "valid_activity_count" => 2,
             "invalid_activity_input_count" => 1,
             "invalid_activity_input_ids" => ["provider_command_without_type"],
             "projected_resources" => [
               %{
                 "activity_count" => 2,
                 "downlink_count" => 1,
                 "estimated_downlink_mb" => 20.0,
                 "storage_limited_downlinked_mb" => 20.0,
                 "activity_resource_flow" => [
                   %{"activity_id" => "obs_provider", "storage_used_after_mb" => 60.0},
                   %{
                     "activity_id" => "provider_downlink",
                     "activity_type" => "downlink",
                     "ground_station_id" => "equator_prime",
                     "starts_at_s" => 20.0,
                     "ends_at_s" => 40.0,
                     "planned_downlink_mb" => 20.0,
                     "downlinked_mb" => 20.0,
                     "storage_delta_mb" => -20.0,
                     "storage_used_after_mb" => 40.0
                   }
                 ],
                 "projected_storage_used_mb" => 40.0,
                 "projected_downlink_margin" => 0.75
               }
             ]
           } = report

    assert %{
             "activity_id" => "provider_command_without_type",
             "invalid_activity_input_reason" => "missing_activity_type",
             "source_activity" => %{"command_result" => "accepted"}
           } = hd(report["invalid_activity_inputs"])

    assert {:ok, %{"schema_contract" => "resource_projection_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "normalizes numeric string resource summaries and activity resource evidence" do
    report =
      ResourceProjection.report(
        [
          %{
            id: :obs_string,
            type: :observe,
            scenario_id: :leo_1,
            start_s: "10.0",
            end_s: "20.0",
            estimated_storage_mb: "25.0",
            estimated_energy_used_wh: "5.0"
          },
          %{
            id: :dl_string,
            type: :downlink,
            scenario_id: :leo_1,
            station_id: :equator_prime,
            start_s: "30.0",
            end_s: "40.0",
            throughput_model: %{
              estimated_throughput_mb: "40.0",
              station_capacity_fraction: "0.5"
            },
            completed_fraction: "0.75"
          }
        ],
        [
          %{
            spacecraft_id: :leo_1,
            storage_capacity_mb: "100.0",
            storage_used_mb: "10.0",
            downlink_capacity_mb: "80.0",
            battery_capacity_wh: "20.0",
            battery_energy_used_wh: "2.0"
          }
        ]
      )

    assert [
             %{
               "storage_capacity_mb" => 100.0,
               "starting_storage_used_mb" => 10.0,
               "downlink_capacity_mb" => 80.0,
               "battery_capacity_wh" => 20.0,
               "battery_energy_used_wh" => 2.0,
               "estimated_storage_produced_mb" => 25.0,
               "estimated_downlink_mb" => 20.0,
               "storage_limited_downlinked_mb" => 20.0,
               "projected_storage_used_mb" => 15.0,
               "projected_downlink_margin" => 0.75,
               "projected_power_margin" => 0.65,
               "activity_resource_flow" => [
                 %{
                   "activity_id" => "obs_string",
                   "starts_at_s" => 10.0,
                   "ends_at_s" => 20.0,
                   "storage_produced_mb" => 25.0,
                   "battery_energy_consumed_wh" => 5.0,
                   "battery_energy_used_after_wh" => 7.0
                 },
                 %{
                   "activity_id" => "dl_string",
                   "starts_at_s" => 30.0,
                   "ends_at_s" => 40.0,
                   "planned_downlink_mb" => 20.0,
                   "completed_fraction" => 0.75,
                   "downlinked_mb" => 20.0
                 }
               ]
             }
           ] = report["projected_resources"]

    assert {:ok, %{"schema_contract" => "resource_projection_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "accepts activity-type-only activity inputs for resource projection" do
    report =
      ResourceProjection.report(
        [
          %{
            id: :typed_observe,
            activity_type: :observe,
            scenario_id: :leo_1,
            starts_at_s: 10.0,
            ends_at_s: 40.0,
            estimated_storage_mb: 25.0
          },
          %{
            id: :blank_activity_type,
            activity_type: "",
            scenario_id: :leo_1,
            starts_at_s: 50.0,
            ends_at_s: 60.0
          }
        ],
        [
          %{
            spacecraft_id: :leo_1,
            storage_capacity_mb: 100.0,
            storage_used_mb: 10.0
          }
        ]
      )

    assert %{
             "activity_count" => 2,
             "valid_activity_count" => 1,
             "invalid_activity_input_count" => 1,
             "invalid_activity_input_ids" => ["blank_activity_type"],
             "projected_resources" => [
               %{
                 "activity_count" => 1,
                 "estimated_storage_produced_mb" => 25.0,
                 "activity_resource_flow" => [
                   %{
                     "activity_id" => "typed_observe",
                     "activity_type" => "observe",
                     "storage_delta_mb" => 25.0,
                     "storage_used_after_mb" => 35.0
                   }
                 ]
               }
             ]
           } = report

    assert %{
             "activity_id" => "blank_activity_type",
             "invalid_activity_input_reason" => "missing_activity_type",
             "source_activity" => %{"activity_type" => ""}
           } = hd(report["invalid_activity_inputs"])

    assert {:ok, %{"schema_contract" => "resource_projection_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "uses valid capacity fractions and review-gates invalid capacity evidence" do
    report =
      ResourceProjection.report(
        [
          %{
            id: :allocated_downlink,
            type: :downlink,
            scenario_id: :leo_1,
            starts_at_s: 20.0,
            estimated_throughput_mb: 80.0,
            capacity_percent: "25"
          },
          %{
            id: :clamped_downlink,
            type: :downlink,
            scenario_id: :leo_1,
            starts_at_s: 30.0,
            estimated_throughput_mb: 40.0,
            capacity_fraction: 2.0
          },
          %{
            id: :bad_percent_downlink,
            type: :downlink,
            scenario_id: :leo_1,
            starts_at_s: 40.0,
            estimated_throughput_mb: 40.0,
            source_station_calendar_entry: %{station_capacity_percent: "125"}
          },
          %{
            id: :bad_pack_fraction_downlink,
            type: :downlink,
            scenario_id: :leo_1,
            starts_at_s: 50.0,
            estimated_throughput_mb: 40.0,
            capacity_pack_capacity_fraction: 1.25
          }
        ],
        [
          %{
            spacecraft_id: :leo_1,
            storage_capacity_mb: 200.0,
            storage_used_mb: 100.0,
            downlink_capacity_mb: 100.0
          }
        ]
      )

    assert %{
             "activity_count" => 4,
             "valid_activity_count" => 1,
             "invalid_activity_input_count" => 3,
             "invalid_activity_input_ids" => [
               "clamped_downlink",
               "bad_percent_downlink",
               "bad_pack_fraction_downlink"
             ],
             "invalid_activity_inputs" => invalid_inputs,
             "projected_resources" => [
               %{
                 "estimated_downlink_mb" => 20.0,
                 "activity_resource_flow" => [
                   %{
                     "activity_id" => "allocated_downlink",
                     "capacity_fraction" => 0.25,
                     "downlinked_mb" => 20.0,
                     "storage_delta_mb" => -20.0
                   }
                 ],
                 "projected_storage_used_mb" => 80.0,
                 "projected_downlink_margin" => 0.8
               }
             ]
           } = report

    assert %{
             "invalid_activity_input_reason" => "invalid_capacity_fraction",
             "source_activity" => %{"capacity_fraction" => 2.0}
           } = Enum.find(invalid_inputs, &(&1["activity_id"] == "clamped_downlink"))

    assert %{
             "invalid_activity_input_reason" => "invalid_station_capacity_percent",
             "source_activity" => %{
               "source_station_calendar_entry" => %{"station_capacity_percent" => "125"}
             }
           } = Enum.find(invalid_inputs, &(&1["activity_id"] == "bad_percent_downlink"))

    assert %{
             "invalid_activity_input_reason" => "invalid_capacity_pack_capacity_fraction",
             "source_activity" => %{"capacity_pack_capacity_fraction" => 1.25}
           } = Enum.find(invalid_inputs, &(&1["activity_id"] == "bad_pack_fraction_downlink"))

    assert {:ok, %{"schema_contract" => "resource_projection_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "uses station calendar overlap capacity percent aliases for downlink relief" do
    report =
      ResourceProjection.report(
        [
          %{
            id: :overlap_allocated_downlink,
            type: :downlink,
            scenario_id: :leo_1,
            starts_at_s: 20.0,
            estimated_throughput_mb: 100.0,
            source_station_calendar_overlaps: [
              %{capacity_model: %{station_capacity_percent: "40"}}
            ]
          },
          %{
            id: :invalid_overlap_downlink,
            type: :downlink,
            scenario_id: :leo_1,
            starts_at_s: 30.0,
            estimated_throughput_mb: 100.0,
            source_station_calendar_overlaps: [
              %{activity_context: %{capacity_percent: "140"}}
            ]
          },
          %{
            id: :invalid_overlap_allocation_capacity,
            type: :downlink,
            scenario_id: :leo_1,
            starts_at_s: 40.0,
            estimated_throughput_mb: 100.0,
            source_station_calendar_overlaps: [
              %{
                source_contact_allocation: %{
                  allocation_status: :allocated,
                  effective_allocation_status: :allocated,
                  capacity_pack_capacity_fraction: 1.25
                }
              }
            ]
          }
        ],
        [
          %{
            spacecraft_id: :leo_1,
            storage_capacity_mb: 200.0,
            storage_used_mb: 100.0,
            downlink_capacity_mb: 100.0
          }
        ]
      )

    assert %{
             "activity_count" => 3,
             "valid_activity_count" => 1,
             "invalid_activity_input_count" => 2,
             "invalid_activity_input_ids" => [
               "invalid_overlap_downlink",
               "invalid_overlap_allocation_capacity"
             ],
             "projected_resources" => [
               %{
                 "estimated_downlink_mb" => 40.0,
                 "activity_resource_flow" => [
                   %{
                     "activity_id" => "overlap_allocated_downlink",
                     "capacity_fraction" => 0.4,
                     "downlinked_mb" => 40.0,
                     "storage_delta_mb" => -40.0
                   }
                 ],
                 "projected_storage_used_mb" => 60.0,
                 "projected_downlink_margin" => 0.6
               }
             ]
           } = report

    invalid_inputs = report["invalid_activity_inputs"]

    assert %{
             "activity_id" => "invalid_overlap_downlink",
             "invalid_activity_input_reason" => "invalid_capacity_percent",
             "source_activity" => %{
               "source_station_calendar_overlaps" => [
                 %{"activity_context" => %{"capacity_percent" => "140"}}
               ]
             }
           } = Enum.find(invalid_inputs, &(&1["activity_id"] == "invalid_overlap_downlink"))

    assert %{
             "activity_id" => "invalid_overlap_allocation_capacity",
             "invalid_activity_input_reason" => "invalid_capacity_pack_capacity_fraction",
             "source_activity" => %{
               "source_station_calendar_overlaps" => [
                 %{
                   "source_contact_allocation" => %{
                     "capacity_pack_capacity_fraction" => 1.25
                   }
                 }
               ]
             }
           } =
             Enum.find(
               invalid_inputs,
               &(&1["activity_id"] == "invalid_overlap_allocation_capacity")
             )

    assert {:ok, %{"schema_contract" => "resource_projection_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "uses source station-calendar capacity-pack fractions for downlink relief" do
    report =
      ResourceProjection.report(
        [
          %{
            id: :source_entry_capacity_pack_downlink,
            type: :downlink,
            scenario_id: :leo_1,
            starts_at_s: 20.0,
            estimated_throughput_mb: 100.0,
            source_station_calendar_entry: %{
              id: :provider_capacity_entry,
              capacity_pack_capacity_fraction: 0.25
            }
          },
          %{
            id: :source_overlap_capacity_pack_downlink,
            type: :downlink,
            scenario_id: :leo_1,
            starts_at_s: 30.0,
            estimated_throughput_mb: 100.0,
            source_station_calendar_overlaps: [
              %{id: :provider_capacity_overlap, capacity_pack_capacity_fraction: 0.4}
            ]
          }
        ],
        [
          %{
            spacecraft_id: :leo_1,
            storage_capacity_mb: 200.0,
            storage_used_mb: 100.0,
            downlink_capacity_mb: 100.0
          }
        ]
      )

    assert %{
             "activity_count" => 2,
             "valid_activity_count" => 2,
             "invalid_activity_input_count" => 0,
             "projected_resources" => [
               %{
                 "estimated_downlink_mb" => 65.0,
                 "projected_storage_used_mb" => 35.0,
                 "projected_downlink_margin" => 0.35,
                 "activity_resource_flow" => [
                   %{
                     "activity_id" => "source_entry_capacity_pack_downlink",
                     "capacity_fraction" => 0.25,
                     "planned_downlink_mb" => 25.0,
                     "downlinked_mb" => 25.0,
                     "storage_delta_mb" => -25.0
                   },
                   %{
                     "activity_id" => "source_overlap_capacity_pack_downlink",
                     "capacity_fraction" => 0.4,
                     "planned_downlink_mb" => 40.0,
                     "downlinked_mb" => 40.0,
                     "storage_delta_mb" => -40.0
                   }
                 ]
               }
             ]
           } = report

    assert {:ok, %{"schema_contract" => "resource_projection_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "ignores deferred or blocked contact allocation rows during downlink roll-forward" do
    report =
      ResourceProjection.report(
        [
          %{
            id: :obs_before_allocation,
            type: :observe,
            scenario_id: :leo_1,
            starts_at_s: 10.0,
            estimated_storage_mb: 120.0
          },
          %{
            id: :"contact_allocation:dl_allocated",
            contact_id: :dl_allocated,
            type: :downlink,
            direction: :downlink,
            scenario_id: :leo_1,
            ground_station_id: :equator_prime,
            starts_at_s: 20.0,
            estimated_throughput_mb: 40.0,
            allocation_status: :allocated,
            effective_allocation_status: :allocated,
            allocation_reason: :selected_by_reduced_station_capacity_pack,
            capacity_pack_status: :selected_by_reduced_station_capacity_pack,
            capacity_pack_capacity_fraction: 0.5
          },
          %{
            id: :"contact_allocation:dl_deferred",
            contact_id: :dl_deferred,
            type: :downlink,
            direction: :downlink,
            scenario_id: :leo_1,
            ground_station_id: :equator_prime,
            starts_at_s: 30.0,
            estimated_throughput_mb: 40.0,
            allocation_status: :deferred,
            effective_allocation_status: :deferred,
            allocation_reason: :same_station_contention,
            capacity_pack_status: :deferred_by_reduced_station_capacity_pack,
            capacity_pack_capacity_fraction: 0.5
          },
          %{
            id: :"contact_allocation:dl_policy_blocked",
            contact_id: :dl_policy_blocked,
            type: :downlink,
            direction: :downlink,
            scenario_id: :leo_1,
            ground_station_id: :equator_prime,
            starts_at_s: 40.0,
            estimated_throughput_mb: 40.0,
            allocation_status: :allocated,
            effective_allocation_status: :policy_blocked,
            allocation_reason: :selected_by_contention_resolution,
            capacity_pack_status: :selected_by_contention_resolution
          }
        ],
        [
          %{
            spacecraft_id: :leo_1,
            storage_capacity_mb: 200.0,
            storage_used_mb: 0.0,
            downlink_capacity_mb: 100.0
          }
        ]
      )

    assert %{
             "projected_resources" => [
               %{
                 "activity_count" => 4,
                 "effective_activity_count" => 2,
                 "ignored_activity_count" => 2,
                 "ignored_activity_ids" => [
                   "contact_allocation:dl_deferred",
                   "contact_allocation:dl_policy_blocked"
                 ],
                 "downlink_count" => 1,
                 "estimated_downlink_mb" => 20.0,
                 "storage_limited_downlinked_mb" => 20.0,
                 "projected_storage_used_mb" => 100.0,
                 "activity_resource_flow" => [
                   %{"activity_id" => "obs_before_allocation", "storage_used_after_mb" => 120.0},
                   %{
                     "activity_id" => "contact_allocation:dl_allocated",
                     "resource_effect_status" => "projected",
                     "resource_effect_reason" => "active_planning_activity",
                     "allocation_status" => "allocated",
                     "effective_allocation_status" => "allocated",
                     "allocation_reason" => "selected_by_reduced_station_capacity_pack",
                     "capacity_pack_status" => "selected_by_reduced_station_capacity_pack",
                     "capacity_fraction" => 0.5,
                     "planned_downlink_mb" => 20.0,
                     "downlinked_mb" => 20.0,
                     "storage_used_after_mb" => 100.0,
                     "downlink_used_after_mb" => 20.0
                   },
                   %{
                     "activity_id" => "contact_allocation:dl_deferred",
                     "resource_effect_status" => "ignored",
                     "resource_effect_reason" => "contact_allocation_deferred",
                     "allocation_status" => "deferred",
                     "effective_allocation_status" => "deferred",
                     "allocation_reason" => "same_station_contention",
                     "capacity_pack_status" => "deferred_by_reduced_station_capacity_pack",
                     "planned_downlink_mb" => +0.0,
                     "downlinked_mb" => +0.0,
                     "storage_used_after_mb" => 100.0,
                     "downlink_used_after_mb" => 20.0
                   },
                   %{
                     "activity_id" => "contact_allocation:dl_policy_blocked",
                     "resource_effect_status" => "ignored",
                     "resource_effect_reason" => "contact_allocation_policy_blocked",
                     "allocation_status" => "allocated",
                     "effective_allocation_status" => "policy_blocked",
                     "allocation_reason" => "selected_by_contention_resolution",
                     "capacity_pack_status" => "selected_by_contention_resolution",
                     "planned_downlink_mb" => +0.0,
                     "downlinked_mb" => +0.0,
                     "storage_used_after_mb" => 100.0,
                     "downlink_used_after_mb" => 20.0
                   }
                 ]
               }
             ]
           } = report

    assert {:ok, %{"schema_contract" => "resource_projection_report.v1"}} =
             Schema.validate_artifact(report)

    flow_summary = ResourceProjection.flow_summary(report)

    assert %{
             "total_planned_downlink_mb" => 20.0,
             "total_storage_limited_downlinked_mb" => 20.0,
             "activity_resource_flow" => [
               _observation,
               %{"allocation_status" => "allocated", "capacity_fraction" => 0.5},
               %{"resource_effect_reason" => "contact_allocation_deferred"},
               %{"resource_effect_reason" => "contact_allocation_policy_blocked"}
             ]
           } = flow_summary

    assert {:ok, %{"schema_contract" => "resource_projection_flow_summary.v1"}} =
             Schema.validate_artifact(flow_summary)
  end

  test "uses nested source contact allocation status during downlink roll-forward" do
    report =
      ResourceProjection.report(
        [
          %{
            id: :obs_before_nested_allocation,
            type: :observe,
            scenario_id: :leo_1,
            starts_at_s: 10.0,
            estimated_storage_mb: 120.0
          },
          %{
            id: :"contact_allocation:dl_nested_allocated",
            type: :downlink,
            direction: :downlink,
            scenario_id: :leo_1,
            ground_station_id: :equator_prime,
            starts_at_s: 20.0,
            estimated_throughput_mb: 40.0,
            source_station_calendar_entry: %{
              source_contact_allocation: %{
                allocation_status: :allocated,
                effective_allocation_status: :allocated,
                allocation_reason: :selected_by_reduced_station_capacity_pack,
                capacity_pack_status: :selected_by_reduced_station_capacity_pack,
                capacity_pack_capacity_fraction: 0.5
              }
            }
          },
          %{
            id: :"contact_allocation:dl_nested_deferred",
            type: :downlink,
            direction: :downlink,
            scenario_id: :leo_1,
            ground_station_id: :equator_prime,
            starts_at_s: 30.0,
            estimated_throughput_mb: 40.0,
            source_contact_allocation: %{
              allocation_status: :deferred,
              effective_allocation_status: :deferred,
              allocation_reason: :same_station_contention,
              capacity_pack_status: :deferred_by_reduced_station_capacity_pack
            }
          },
          %{
            id: :"contact_allocation:dl_nested_policy_blocked",
            type: :downlink,
            direction: :downlink,
            scenario_id: :leo_1,
            ground_station_id: :equator_prime,
            starts_at_s: 40.0,
            estimated_throughput_mb: 40.0,
            source_station_calendar_entry: %{
              source_contact_allocation: %{
                allocation_status: :allocated,
                effective_allocation_status: :policy_blocked,
                allocation_reason: :selected_by_contention_resolution,
                capacity_pack_status: :selected_by_contention_resolution
              }
            }
          }
        ],
        [
          %{
            spacecraft_id: :leo_1,
            storage_capacity_mb: 200.0,
            storage_used_mb: 0.0,
            downlink_capacity_mb: 100.0
          }
        ]
      )

    assert %{
             "projected_resources" => [
               %{
                 "effective_activity_count" => 2,
                 "ignored_activity_count" => 2,
                 "ignored_activity_ids" => [
                   "contact_allocation:dl_nested_deferred",
                   "contact_allocation:dl_nested_policy_blocked"
                 ],
                 "estimated_downlink_mb" => 20.0,
                 "storage_limited_downlinked_mb" => 20.0,
                 "projected_storage_used_mb" => 100.0,
                 "activity_resource_flow" => [
                   %{"activity_id" => "obs_before_nested_allocation"},
                   %{
                     "activity_id" => "contact_allocation:dl_nested_allocated",
                     "resource_effect_status" => "projected",
                     "allocation_status" => "allocated",
                     "effective_allocation_status" => "allocated",
                     "allocation_reason" => "selected_by_reduced_station_capacity_pack",
                     "capacity_pack_status" => "selected_by_reduced_station_capacity_pack",
                     "capacity_fraction" => 0.5,
                     "planned_downlink_mb" => 20.0,
                     "downlinked_mb" => 20.0
                   },
                   %{
                     "activity_id" => "contact_allocation:dl_nested_deferred",
                     "resource_effect_status" => "ignored",
                     "resource_effect_reason" => "contact_allocation_deferred",
                     "allocation_status" => "deferred",
                     "effective_allocation_status" => "deferred",
                     "allocation_reason" => "same_station_contention",
                     "capacity_pack_status" => "deferred_by_reduced_station_capacity_pack",
                     "planned_downlink_mb" => +0.0,
                     "downlinked_mb" => +0.0
                   },
                   %{
                     "activity_id" => "contact_allocation:dl_nested_policy_blocked",
                     "resource_effect_status" => "ignored",
                     "resource_effect_reason" => "contact_allocation_policy_blocked",
                     "allocation_status" => "allocated",
                     "effective_allocation_status" => "policy_blocked",
                     "allocation_reason" => "selected_by_contention_resolution",
                     "capacity_pack_status" => "selected_by_contention_resolution",
                     "planned_downlink_mb" => +0.0,
                     "downlinked_mb" => +0.0
                   }
                 ]
               }
             ]
           } = report

    assert {:ok, %{"schema_contract" => "resource_projection_report.v1"}} =
             Schema.validate_artifact(report)

    flow_summary = ResourceProjection.flow_summary(report)

    assert %{
             "total_planned_downlink_mb" => 20.0,
             "ignored_activity_reason_counts" => %{
               "contact_allocation_deferred" => 1,
               "contact_allocation_policy_blocked" => 1
             },
             "activity_resource_flow" => [
               _observation,
               %{"allocation_status" => "allocated", "capacity_fraction" => 0.5},
               %{"resource_effect_reason" => "contact_allocation_deferred"},
               %{"resource_effect_reason" => "contact_allocation_policy_blocked"}
             ]
           } = flow_summary

    assert {:ok, %{"schema_contract" => "resource_projection_flow_summary.v1"}} =
             Schema.validate_artifact(flow_summary)
  end

  test "uses overlap source contact allocation status during downlink roll-forward" do
    report =
      ResourceProjection.report(
        [
          %{
            id: :obs_before_overlap_allocation,
            type: :observe,
            scenario_id: :leo_1,
            starts_at_s: 10.0,
            estimated_storage_mb: 120.0
          },
          %{
            id: :"contact_allocation:dl_overlap_allocated",
            type: :downlink,
            direction: :downlink,
            scenario_id: :leo_1,
            ground_station_id: :equator_prime,
            starts_at_s: 20.0,
            estimated_throughput_mb: 40.0,
            source_station_calendar_overlaps: [
              %{
                id: :overlap_allocated,
                source_contact_allocation: %{
                  allocation_status: :allocated,
                  effective_allocation_status: :allocated,
                  allocation_reason: :selected_by_reduced_station_capacity_pack,
                  capacity_pack_status: :selected_by_reduced_station_capacity_pack,
                  capacity_pack_capacity_fraction: 0.5
                }
              }
            ]
          },
          %{
            id: :"contact_allocation:dl_overlap_deferred",
            type: :downlink,
            direction: :downlink,
            scenario_id: :leo_1,
            ground_station_id: :equator_prime,
            starts_at_s: 30.0,
            estimated_throughput_mb: 40.0,
            source_station_calendar_overlaps: [
              %{
                id: :overlap_deferred,
                source_contact_allocation: %{
                  allocation_status: :deferred,
                  effective_allocation_status: :deferred,
                  allocation_reason: :same_station_contention,
                  capacity_pack_status: :deferred_by_reduced_station_capacity_pack
                }
              }
            ]
          },
          %{
            id: :"contact_allocation:dl_overlap_conflict",
            type: :downlink,
            direction: :downlink,
            scenario_id: :leo_1,
            ground_station_id: :equator_prime,
            starts_at_s: 40.0,
            estimated_throughput_mb: 40.0,
            source_station_calendar_overlaps: [
              %{
                id: :overlap_conflict_allocated,
                source_contact_allocation: %{
                  allocation_status: :allocated,
                  effective_allocation_status: :allocated,
                  allocation_reason: :selected_by_contention_resolution,
                  capacity_pack_status: :selected_by_contention_resolution,
                  capacity_pack_capacity_fraction: 0.5
                }
              },
              %{
                id: :overlap_conflict_policy_blocked,
                source_contact_allocation: %{
                  allocation_status: :allocated,
                  effective_allocation_status: :policy_blocked,
                  allocation_reason: :blocked_by_policy,
                  capacity_pack_status: :selected_by_contention_resolution
                }
              }
            ]
          }
        ],
        [
          %{
            spacecraft_id: :leo_1,
            storage_capacity_mb: 200.0,
            storage_used_mb: 0.0,
            downlink_capacity_mb: 100.0
          }
        ]
      )

    assert %{
             "projected_resources" => [
               %{
                 "effective_activity_count" => 2,
                 "ignored_activity_count" => 2,
                 "ignored_activity_ids" => [
                   "contact_allocation:dl_overlap_deferred",
                   "contact_allocation:dl_overlap_conflict"
                 ],
                 "estimated_downlink_mb" => 20.0,
                 "storage_limited_downlinked_mb" => 20.0,
                 "projected_storage_used_mb" => 100.0,
                 "activity_resource_flow" => [
                   %{"activity_id" => "obs_before_overlap_allocation"},
                   %{
                     "activity_id" => "contact_allocation:dl_overlap_allocated",
                     "resource_effect_status" => "projected",
                     "allocation_status" => "allocated",
                     "effective_allocation_status" => "allocated",
                     "allocation_reason" => "selected_by_reduced_station_capacity_pack",
                     "capacity_pack_status" => "selected_by_reduced_station_capacity_pack",
                     "capacity_fraction" => 0.5,
                     "planned_downlink_mb" => 20.0,
                     "downlinked_mb" => 20.0
                   },
                   %{
                     "activity_id" => "contact_allocation:dl_overlap_deferred",
                     "resource_effect_status" => "ignored",
                     "resource_effect_reason" => "contact_allocation_deferred",
                     "allocation_status" => "deferred",
                     "effective_allocation_status" => "deferred",
                     "allocation_reason" => "same_station_contention",
                     "capacity_pack_status" => "deferred_by_reduced_station_capacity_pack",
                     "planned_downlink_mb" => +0.0,
                     "downlinked_mb" => +0.0
                   },
                   %{
                     "activity_id" => "contact_allocation:dl_overlap_conflict",
                     "resource_effect_status" => "ignored",
                     "resource_effect_reason" => "contact_allocation_policy_blocked",
                     "allocation_status" => "allocated",
                     "effective_allocation_status" => "policy_blocked",
                     "allocation_reason" => "blocked_by_policy",
                     "capacity_pack_status" => "selected_by_contention_resolution",
                     "planned_downlink_mb" => +0.0,
                     "downlinked_mb" => +0.0
                   }
                 ]
               }
             ]
           } = report

    assert {:ok, %{"schema_contract" => "resource_projection_report.v1"}} =
             Schema.validate_artifact(report)

    flow_summary = ResourceProjection.flow_summary(report)

    assert %{
             "total_planned_downlink_mb" => 20.0,
             "ignored_activity_reason_counts" => %{
               "contact_allocation_deferred" => 1,
               "contact_allocation_policy_blocked" => 1
             },
             "activity_resource_flow" => [
               _observation,
               %{"allocation_status" => "allocated", "capacity_fraction" => 0.5},
               %{"resource_effect_reason" => "contact_allocation_deferred"},
               %{"resource_effect_reason" => "contact_allocation_policy_blocked"}
             ]
           } = flow_summary

    assert {:ok, %{"schema_contract" => "resource_projection_flow_summary.v1"}} =
             Schema.validate_artifact(flow_summary)
  end

  test "preserves station-calendar direction context through resource pressure review" do
    report =
      ResourceProjection.report(
        [
          %{
            id: :pressure_downlink,
            type: :downlink,
            direction: :downlink,
            scenario_id: :leo_1,
            station_id: :equator_prime,
            starts_at_s: 20.0,
            estimated_throughput_mb: 80.0,
            metadata: %{
              source_window: %{
                window_id: :resource_window_1,
                kind: :ground_station_access,
                confidence: :declared
              }
            },
            source_station_calendar_entry: %{
              id: :provider_command_entry,
              provider_id: :ops_calendar,
              provider_entry_id: :provider_command_window,
              station_calendar_directions: [:uplink],
              capacity_model: %{station_capacity_percent: "75"}
            }
          }
        ],
        [
          %{
            spacecraft_id: :leo_1,
            storage_capacity_mb: 200.0,
            storage_used_mb: 100.0,
            downlink_capacity_mb: 50.0
          }
        ],
        approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
      )

    assert %{
             "projected_resources" => [
               %{
                 "approval_status" => "operator_review_required",
                 "estimated_downlink_mb" => 60.0,
                 "projected_downlink_shortfall_mb" => 10.0,
                 "first_resource_pressure_activity_id" => "pressure_downlink",
                 "first_resource_pressure_direction" => "downlink",
                 "first_resource_pressure_ground_station_id" => "equator_prime",
                 "first_resource_pressure_station_calendar_entry_id" => "provider_command_entry",
                 "first_resource_pressure_station_calendar_provider_id" => "ops_calendar",
                 "first_resource_pressure_station_calendar_provider_entry_id" =>
                   "provider_command_window",
                 "first_resource_pressure_station_calendar_directions" => ["command"],
                 "first_resource_pressure_capacity_fraction" => 0.75,
                 "first_resource_pressure_source_window_id" => "resource_window_1",
                 "first_resource_pressure_source_window_type" => "ground_station_access",
                 "first_resource_pressure_source_window" => %{
                   "id" => "resource_window_1",
                   "type" => "ground_station_access",
                   "window_id" => "resource_window_1",
                   "kind" => "ground_station_access"
                 },
                 "source_window_id" => "resource_window_1",
                 "source_window_type" => "ground_station_access",
                 "source_window" => %{
                   "id" => "resource_window_1",
                   "type" => "ground_station_access"
                 },
                 "activity_resource_flow" => [
                   %{
                     "activity_id" => "pressure_downlink",
                     "direction" => "downlink",
                     "ground_station_id" => "equator_prime",
                     "source_window_id" => "resource_window_1",
                     "source_window_type" => "ground_station_access",
                     "source_window" => %{
                       "id" => "resource_window_1",
                       "type" => "ground_station_access"
                     },
                     "capacity_fraction" => 0.75,
                     "station_calendar_entry_id" => "provider_command_entry",
                     "station_calendar_provider_id" => "ops_calendar",
                     "station_calendar_provider_entry_id" => "provider_command_window",
                     "station_calendar_directions" => ["command"],
                     "downlink_shortfall_mb" => 10.0
                   }
                 ],
                 "approval_requirements" => [
                   %{
                     "activity_context" => %{
                       "direction" => "downlink",
                       "ground_station_id" => "equator_prime",
                       "station_calendar_entry_id" => "provider_command_entry",
                       "station_calendar_provider_id" => "ops_calendar",
                       "station_calendar_provider_entry_id" => "provider_command_window",
                       "first_resource_pressure_station_calendar_provider_id" => "ops_calendar",
                       "first_resource_pressure_station_calendar_provider_entry_id" =>
                         "provider_command_window",
                       "station_calendar_directions" => ["command"],
                       "first_resource_pressure_station_calendar_directions" => ["command"],
                       "first_resource_pressure_capacity_fraction" => 0.75,
                       "capacity_fraction" => 0.75,
                       "first_resource_pressure_source_window_id" => "resource_window_1",
                       "first_resource_pressure_source_window_type" => "ground_station_access",
                       "first_resource_pressure_source_window" => %{
                         "id" => "resource_window_1",
                         "type" => "ground_station_access"
                       },
                       "source_window_id" => "resource_window_1",
                       "source_window_type" => "ground_station_access",
                       "source_window" => %{
                         "id" => "resource_window_1",
                         "type" => "ground_station_access"
                       }
                     }
                   }
                 ],
                 "approval_rule_matches" => [
                   %{
                     "rule_id" => "command_station_calendar_direction_review",
                     "direction" => "downlink",
                     "station_calendar_direction" => "command",
                     "station_calendar_directions" => ["command"]
                   }
                 ]
               } = projection
             ]
           } = report

    assert {:ok, %{"schema_contract" => "resource_projection_report.v1"}} =
             Schema.validate_artifact(report)

    flow_summary = ResourceProjection.flow_summary(report)

    assert %{
             "resource_pressure_station_calendar_directions_by_type" => %{
               "downlink_shortfall" => ["command"]
             },
             "resource_pressure_capacity_fractions_by_type" => %{
               "downlink_shortfall" => [0.75]
             },
             "projected_resources" => [
               %{
                 "first_resource_pressure_source_window_id" => "resource_window_1",
                 "first_resource_pressure_source_window_type" => "ground_station_access",
                 "first_resource_pressure_direction" => "downlink",
                 "first_resource_pressure_ground_station_id" => "equator_prime",
                 "first_resource_pressure_source_window" => %{
                   "id" => "resource_window_1",
                   "type" => "ground_station_access"
                 },
                 "first_resource_pressure_station_calendar_directions" => ["command"]
               }
             ]
           } = flow_summary

    assert {:ok, %{"schema_contract" => "resource_projection_flow_summary.v1"}} =
             Schema.validate_artifact(flow_summary)

    review = OperatorReview.from_resource_projection_report(report)

    assert [
             %{
               "review_type" => "resource_projection_review",
               "first_resource_pressure_direction" => "downlink",
               "first_resource_pressure_ground_station_id" => "equator_prime",
               "first_resource_pressure_station_calendar_entry_id" => "provider_command_entry",
               "first_resource_pressure_station_calendar_provider_id" => "ops_calendar",
               "first_resource_pressure_station_calendar_provider_entry_id" =>
                 "provider_command_window",
               "first_resource_pressure_station_calendar_directions" => ["command"],
               "first_resource_pressure_capacity_fraction" => 0.75,
               "first_resource_pressure_source_window_id" => "resource_window_1",
               "first_resource_pressure_source_window_type" => "ground_station_access",
               "source_window_id" => "resource_window_1",
               "source_window_type" => "ground_station_access",
               "source_resource_projection" => ^projection
             }
           ] = review["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    manifest = CadenceImport.from_resource_projection_report(report)

    assert [
             %{
               "import_action" => "review_resource_projection",
               "first_resource_pressure_direction" => "downlink",
               "first_resource_pressure_ground_station_id" => "equator_prime",
               "first_resource_pressure_station_calendar_entry_id" => "provider_command_entry",
               "first_resource_pressure_station_calendar_provider_id" => "ops_calendar",
               "first_resource_pressure_station_calendar_provider_entry_id" =>
                 "provider_command_window",
               "first_resource_pressure_station_calendar_directions" => ["command"],
               "first_resource_pressure_capacity_fraction" => 0.75,
               "first_resource_pressure_source_window_id" => "resource_window_1",
               "first_resource_pressure_source_window_type" => "ground_station_access",
               "source_window_id" => "resource_window_1",
               "source_window_type" => "ground_station_access",
               "source_resource_projection" => ^projection
             }
           ] = manifest["rows"]

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "preserves source-overlap station-calendar context through resource pressure review" do
    report =
      ResourceProjection.report(
        [
          %{
            id: :pressure_overlap_downlink,
            type: :downlink,
            direction: :downlink,
            scenario_id: :leo_1,
            station_id: :equator_prime,
            starts_at_s: 20.0,
            estimated_throughput_mb: 80.0,
            source_station_calendar_overlaps: [
              %{
                id: :provider_overlap_entry,
                provider_id: :ops_calendar,
                provider_entry_id: :provider_overlap_window,
                directions: [:downlink],
                capacity_model: %{station_capacity_percent: "75"}
              }
            ]
          }
        ],
        [
          %{
            spacecraft_id: :leo_1,
            storage_capacity_mb: 200.0,
            storage_used_mb: 100.0,
            downlink_capacity_mb: 50.0
          }
        ],
        approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
      )

    assert %{
             "projected_resources" => [
               %{
                 "estimated_downlink_mb" => 60.0,
                 "projected_downlink_shortfall_mb" => 10.0,
                 "first_resource_pressure_station_calendar_entry_id" => "provider_overlap_entry",
                 "first_resource_pressure_station_calendar_provider_id" => "ops_calendar",
                 "first_resource_pressure_station_calendar_provider_entry_id" =>
                   "provider_overlap_window",
                 "first_resource_pressure_station_calendar_directions" => ["downlink"],
                 "first_resource_pressure_capacity_fraction" => 0.75,
                 "activity_resource_flow" => [
                   %{
                     "activity_id" => "pressure_overlap_downlink",
                     "station_calendar_entry_id" => "provider_overlap_entry",
                     "station_calendar_provider_id" => "ops_calendar",
                     "station_calendar_provider_entry_id" => "provider_overlap_window",
                     "station_calendar_directions" => ["downlink"],
                     "capacity_fraction" => 0.75,
                     "downlink_shortfall_mb" => 10.0
                   }
                 ],
                 "approval_requirements" => [
                   %{
                     "activity_context" => %{
                       "station_calendar_entry_id" => "provider_overlap_entry",
                       "station_calendar_provider_id" => "ops_calendar",
                       "station_calendar_provider_entry_id" => "provider_overlap_window",
                       "first_resource_pressure_station_calendar_provider_id" => "ops_calendar",
                       "first_resource_pressure_station_calendar_provider_entry_id" =>
                         "provider_overlap_window",
                       "station_calendar_directions" => ["downlink"],
                       "first_resource_pressure_station_calendar_directions" => ["downlink"],
                       "first_resource_pressure_capacity_fraction" => 0.75,
                       "capacity_fraction" => 0.75
                     }
                   }
                 ]
               } = projection
             ]
           } = report

    assert {:ok, %{"schema_contract" => "resource_projection_report.v1"}} =
             Schema.validate_artifact(report)

    flow_summary = ResourceProjection.flow_summary(report)

    assert %{
             "resource_pressure_station_calendar_directions_by_type" => %{
               "downlink_shortfall" => ["downlink"]
             },
             "resource_pressure_capacity_fractions_by_type" => %{
               "downlink_shortfall" => [0.75]
             },
             "projected_resources" => [
               %{
                 "first_resource_pressure_station_calendar_entry_id" => "provider_overlap_entry",
                 "first_resource_pressure_station_calendar_provider_id" => "ops_calendar",
                 "first_resource_pressure_station_calendar_provider_entry_id" =>
                   "provider_overlap_window",
                 "first_resource_pressure_station_calendar_directions" => ["downlink"],
                 "first_resource_pressure_capacity_fraction" => 0.75
               }
             ],
             "activity_resource_flow" => [
               %{
                 "station_calendar_entry_id" => "provider_overlap_entry",
                 "station_calendar_provider_id" => "ops_calendar",
                 "station_calendar_provider_entry_id" => "provider_overlap_window",
                 "station_calendar_directions" => ["downlink"],
                 "capacity_fraction" => 0.75
               }
             ]
           } = flow_summary

    assert {:ok, %{"schema_contract" => "resource_projection_flow_summary.v1"}} =
             Schema.validate_artifact(flow_summary)

    review = OperatorReview.from_resource_projection_report(report)

    assert [
             %{
               "review_type" => "resource_projection_review",
               "first_resource_pressure_station_calendar_entry_id" => "provider_overlap_entry",
               "first_resource_pressure_station_calendar_provider_id" => "ops_calendar",
               "first_resource_pressure_station_calendar_provider_entry_id" =>
                 "provider_overlap_window",
               "first_resource_pressure_station_calendar_directions" => ["downlink"],
               "first_resource_pressure_capacity_fraction" => 0.75,
               "source_resource_projection" => ^projection
             }
           ] = review["rows"]

    manifest = CadenceImport.from_resource_projection_report(report)

    assert [
             %{
               "import_action" => "review_resource_projection",
               "first_resource_pressure_station_calendar_entry_id" => "provider_overlap_entry",
               "first_resource_pressure_station_calendar_provider_id" => "ops_calendar",
               "first_resource_pressure_station_calendar_provider_entry_id" =>
                 "provider_overlap_window",
               "first_resource_pressure_station_calendar_directions" => ["downlink"],
               "first_resource_pressure_capacity_fraction" => 0.75,
               "source_resource_projection" => ^projection
             }
           ] = manifest["rows"]
  end

  test "separates planned downlink capacity from storage-limited data relief" do
    report =
      ResourceProjection.report(
        [
          %{
            id: :dl_empty_buffer,
            type: :downlink,
            scenario_id: :leo_1,
            starts_at_s: 20.0,
            estimated_throughput_mb: 80.0
          }
        ],
        [
          %{
            spacecraft_id: :leo_1,
            storage_capacity_mb: 100.0,
            storage_used_mb: 25.0,
            downlink_capacity_mb: 100.0
          }
        ]
      )

    assert %{
             "projected_resources" => [
               %{
                 "estimated_downlink_mb" => 80.0,
                 "storage_limited_downlinked_mb" => 25.0,
                 "unused_downlink_capacity_mb" => 55.0,
                 "projected_storage_used_mb" => +0.0,
                 "projected_downlink_margin" => 0.2,
                 "activity_resource_flow" => [
                   %{
                     "activity_id" => "dl_empty_buffer",
                     "planned_downlink_mb" => 80.0,
                     "storage_available_before_downlink_mb" => 25.0,
                     "downlinked_mb" => 25.0,
                     "unused_downlink_capacity_mb" => 55.0,
                     "storage_delta_mb" => -25.0,
                     "storage_used_after_mb" => +0.0,
                     "downlink_used_after_mb" => 80.0
                   }
                 ],
                 "warnings" => warnings
               }
             ],
             "resource_pressure_count" => 0,
             "resource_pressure_types" => [],
             "resource_pressure_spacecraft_ids" => [],
             "resource_pressure_spacecraft_ids_by_type" => %{},
             "resource_pressure_activity_ids_by_type" => %{},
             "warnings" => report_warnings
           } = report

    assert "projected downlink capacity exceeds stored data by 55.0 MB" in warnings
    assert report_warnings == Enum.sort(warnings)

    assert {:ok, %{"schema_contract" => "resource_projection_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "orders activity resource flow by schedule and exposes intermediate pressure" do
    report =
      ResourceProjection.report(
        [
          %{
            id: :dl_late,
            type: :downlink,
            scenario_id: :leo_1,
            ground_station_id: :equator_prime,
            starts_at_s: 20.0,
            estimated_throughput_mb: 10.0
          },
          %{
            id: :obs_early,
            type: :observe,
            scenario_id: :leo_1,
            starts_at_s: 10.0,
            estimated_storage_mb: 30.0
          }
        ],
        [
          %{
            spacecraft_id: :leo_1,
            storage_capacity_mb: 50.0,
            storage_used_mb: 30.0,
            downlink_capacity_mb: 5.0
          }
        ]
      )

    assert %{
             "projected_resources" => [
               %{
                 "activity_resource_flow" => [
                   %{
                     "activity_id" => "obs_early",
                     "storage_used_before_mb" => 30.0,
                     "storage_used_after_mb" => 60.0,
                     "storage_overflow_mb" => 10.0
                   },
                   %{
                     "activity_id" => "dl_late",
                     "storage_used_before_mb" => 60.0,
                     "storage_used_after_mb" => 50.0,
                     "downlink_used_after_mb" => 10.0,
                     "downlink_shortfall_mb" => 5.0
                   }
                 ],
                 "projected_storage_used_mb" => 50.0,
                 "projected_storage_margin" => +0.0,
                 "projected_downlink_shortfall_mb" => 5.0,
                 "first_resource_pressure_activity_id" => "obs_early",
                 "first_resource_pressure_activity_type" => "observe",
                 "first_resource_pressure_kind" => "storage_overflow",
                 "first_resource_pressure_starts_at_s" => 10.0
               }
             ]
           } = report

    assert {:ok, %{"schema_contract" => "resource_projection_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "matches multiple summaries by spacecraft or scenario id" do
    activities = [
      %{id: :obs_1, type: :observe, scenario_id: :leo_1, estimated_storage_mb: 10.0},
      %{id: :obs_2, type: :observe, spacecraft_id: :leo_2, estimated_storage_mb: 20.0}
    ]

    summaries = [
      %{spacecraft_id: :leo_1, storage_capacity_mb: 100.0, storage_used_mb: 0.0},
      %{spacecraft_id: :leo_2, storage_capacity_mb: 100.0, storage_used_mb: 0.0}
    ]

    assert ["leo_1"] ==
             OrbitalDynamics.ResourceProjection.ResourceSummaryInput.projection_scope_ids(
               hd(activities),
               summaries
             )

    assert ["leo_2"] ==
             OrbitalDynamics.ResourceProjection.ResourceSummaryInput.projection_scope_ids(
               List.last(activities),
               summaries
             )

    report = ResourceProjection.report(activities, summaries)

    assert Enum.map(report["projected_resources"], fn row ->
             {row["spacecraft_id"], row["activity_count"], row["estimated_storage_produced_mb"]}
           end) == [
             {"leo_1", 1, 10.0},
             {"leo_2", 1, 20.0}
           ]
  end

  test "does not project unrelated activities from a single spacecraft-specific summary" do
    report =
      ResourceProjection.report(
        [
          %{
            id: :obs_scoped,
            type: :observe,
            scenario_id: :leo_1,
            estimated_storage_mb: 10.0
          },
          %{
            id: :obs_other,
            type: :observe,
            scenario_id: :leo_2,
            estimated_storage_mb: 25.0
          }
        ],
        [
          %{
            spacecraft_id: :leo_1,
            storage_capacity_mb: 100.0,
            storage_used_mb: 0.0
          }
        ]
      )

    assert %{
             "projected_resources" => [
               %{
                 "spacecraft_id" => "leo_1",
                 "activity_count" => 1,
                 "observation_count" => 1,
                 "estimated_storage_produced_mb" => 10.0,
                 "activity_resource_flow" => [
                   %{"activity_id" => "obs_scoped"}
                 ]
               }
             ],
             "assumptions" => %{
               "activity_match" =>
                 "spacecraft_id_or_scenario_id_match_id_less_single_summary_applies_to_all_activities"
             }
           } = report

    assert {:ok, %{"schema_contract" => "resource_projection_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "projects all activities from an id-less single summary wildcard" do
    summaries = [
      %{
        storage_capacity_mb: 100.0,
        storage_used_mb: 0.0
      }
    ]

    report =
      ResourceProjection.report(
        [
          %{
            id: :obs_1,
            type: :observe,
            scenario_id: :leo_1,
            spacecraft_id: :sat_1,
            estimated_storage_mb: 10.0
          },
          %{id: :obs_2, type: :observe, scenario_id: :leo_2, estimated_storage_mb: 25.0}
        ],
        summaries
      )

    assert ["all_spacecraft"] ==
             OrbitalDynamics.ResourceProjection.ResourceSummaryInput.projection_scope_ids(
               %{id: :obs_1, type: :observe, scenario_id: :leo_1, spacecraft_id: :sat_1},
               summaries
             )

    assert %{
             "projected_resources" => [
               %{
                 "spacecraft_id" => "all_spacecraft",
                 "activity_count" => 2,
                 "observation_count" => 2,
                 "estimated_storage_produced_mb" => 35.0,
                 "activity_resource_flow" => [
                   %{"activity_id" => "obs_1"},
                   %{"activity_id" => "obs_2"}
                 ]
               }
             ]
           } = report

    assert {:ok, %{"schema_contract" => "resource_projection_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "reports overflow and shortfall warnings" do
    report =
      ResourceProjection.report(
        [
          %{
            id: :obs_1,
            type: :observe,
            scenario_id: :leo_1,
            starts_at_s: 10.0,
            estimated_storage_mb: 50.0
          },
          %{
            id: :dl_1,
            type: :downlink,
            scenario_id: :leo_1,
            starts_at_s: 20.0,
            capacity_adjusted_throughput_mb: 20.0
          }
        ],
        [
          %{
            spacecraft_id: :leo_1,
            storage_capacity_mb: 100.0,
            storage_used_mb: 90.0,
            downlink_capacity_mb: 10.0
          }
        ]
      )

    assert %{
             "projected_resources" => [
               %{
                 "projected_storage_used_mb" => 120.0,
                 "projected_storage_margin" => projected_storage_margin,
                 "projected_storage_overflow_mb" => 20.0,
                 "projected_downlink_margin" => projected_downlink_margin,
                 "projected_downlink_shortfall_mb" => 10.0,
                 "resource_pressure_status" => "storage_and_downlink_pressure",
                 "resource_pressure_types" => ["downlink_shortfall", "storage_overflow"],
                 "first_resource_pressure_activity_id" => "obs_1",
                 "first_resource_pressure_activity_type" => "observe",
                 "first_resource_pressure_kind" => "storage_overflow",
                 "warnings" => warnings
               }
             ],
             "resource_pressure_count" => 1,
             "resource_pressure_types" => ["downlink_shortfall", "storage_overflow"],
             "resource_pressure_spacecraft_ids" => ["leo_1"],
             "resource_pressure_spacecraft_ids_by_type" => %{
               "downlink_shortfall" => ["leo_1"],
               "storage_overflow" => ["leo_1"]
             },
             "resource_pressure_activity_ids_by_type" => %{
               "downlink_shortfall" => ["dl_1"],
               "storage_overflow" => ["dl_1", "obs_1"]
             },
             "warnings" => report_warnings
           } = report

    assert projected_storage_margin == 0.0
    assert projected_downlink_margin == 0.0
    assert "projected storage exceeds declared capacity by 20.0 MB" in warnings
    assert "projected downlink demand exceeds declared capacity by 10.0 MB" in warnings
    assert report_warnings == Enum.sort(warnings)

    invalid_warnings = Map.put(report, "warnings", [])

    assert {:error, warning_validation} = Schema.validate_artifact(invalid_warnings)

    assert Enum.any?(
             warning_validation["errors"],
             &(&1["path"] == "$.warnings" and &1["message"] == "must equal row-derived warnings")
           )

    invalid_pressure_count = Map.put(report, "resource_pressure_count", 0)

    assert {:error, pressure_count_validation} = Schema.validate_artifact(invalid_pressure_count)

    assert Enum.any?(
             pressure_count_validation["errors"],
             &(&1["path"] == "$.resource_pressure_count" and
                 &1["message"] == "must equal row-derived resource_pressure_count")
           )

    invalid_pressure_spacecraft_ids =
      put_in(report, ["resource_pressure_spacecraft_ids_by_type", "storage_overflow"], [
        "wrong_sat"
      ])

    assert {:error, pressure_spacecraft_ids_validation} =
             Schema.validate_artifact(invalid_pressure_spacecraft_ids)

    assert Enum.any?(
             pressure_spacecraft_ids_validation["errors"],
             &(&1["path"] == "$.resource_pressure_spacecraft_ids_by_type" and
                 &1["message"] ==
                   "must equal row-derived resource_pressure_spacecraft_ids_by_type")
           )

    invalid_pressure_ids =
      put_in(report, ["resource_pressure_activity_ids_by_type", "storage_overflow"], ["dl_1"])

    assert {:error, pressure_ids_validation} = Schema.validate_artifact(invalid_pressure_ids)

    assert Enum.any?(
             pressure_ids_validation["errors"],
             &(&1["path"] == "$.resource_pressure_activity_ids_by_type" and
                 &1["message"] == "must equal row-derived resource_pressure_activity_ids_by_type")
           )
  end

  test "classifies projected resource pressure with approval policy decisions" do
    report =
      ResourceProjection.report(
        [
          %{
            id: :obs_1,
            type: :observe,
            scenario_id: :leo_1,
            starts_at_s: 10.0,
            estimated_storage_mb: 50.0
          },
          %{
            id: :dl_1,
            type: :downlink,
            scenario_id: :leo_1,
            starts_at_s: 20.0,
            capacity_adjusted_throughput_mb: 20.0
          }
        ],
        [
          %{
            spacecraft_id: :leo_1,
            storage_capacity_mb: 100.0,
            storage_used_mb: 90.0,
            downlink_capacity_mb: 10.0
          }
        ],
        approval_policy: %{policy_bundle_id: "conservative_ops_v1"}
      )

    assert [
             %{
               "projected_storage_overflow_mb" => 20.0,
               "projected_downlink_shortfall_mb" => 10.0,
               "resource_pressure_status" => "storage_and_downlink_pressure",
               "resource_pressure_types" => ["downlink_shortfall", "storage_overflow"],
               "approval_status" => "blocked_by_policy",
               "policy_decision" => %{
                 "schema_contract" => "policy_decision.v1",
                 "policy_bundle_id" => "conservative_ops_v1",
                 "classification" => "blocked_by_policy",
                 "approval_requirement_count" => 0
               },
               "approval_requirements" => approval_requirements,
               "approval_rule_matches" => rule_matches
             }
           ] = report["projected_resources"]

    assert [
             %{
               "schema_contract" => "approval_requirement.v1",
               "id" => "approval:resource_projection:leo_1:downlink_shortfall",
               "activity_id" => "resource_projection:leo_1",
               "activity_type" => "resource_projection",
               "action" => "review_resource_projection",
               "requirement_type" => "operator_review",
               "activity_context" => %{
                 "spacecraft_id" => "leo_1",
                 "risk_type" => "downlink_shortfall",
                 "first_resource_pressure_activity_id" => "obs_1",
                 "first_resource_pressure_activity_type" => "observe",
                 "first_resource_pressure_kind" => "storage_overflow",
                 "projected_downlink_shortfall_mb" => 10.0,
                 "projected_storage_overflow_mb" => 20.0,
                 "resource_pressure_status" => "storage_and_downlink_pressure",
                 "resource_pressure_types" => ["downlink_shortfall", "storage_overflow"],
                 "resource_source_quality" => "unknown"
               }
             },
             %{
               "schema_contract" => "approval_requirement.v1",
               "id" => "approval:resource_projection:leo_1:storage_overflow",
               "activity_id" => "resource_projection:leo_1",
               "activity_type" => "resource_projection",
               "action" => "review_resource_projection",
               "requirement_type" => "operator_review",
               "activity_context" => %{
                 "spacecraft_id" => "leo_1",
                 "risk_type" => "storage_overflow",
                 "first_resource_pressure_activity_id" => "obs_1",
                 "first_resource_pressure_activity_type" => "observe",
                 "first_resource_pressure_kind" => "storage_overflow",
                 "projected_downlink_shortfall_mb" => 10.0,
                 "projected_storage_overflow_mb" => 20.0,
                 "resource_pressure_status" => "storage_and_downlink_pressure",
                 "resource_pressure_types" => ["downlink_shortfall", "storage_overflow"],
                 "resource_source_quality" => "unknown"
               }
             }
           ] = approval_requirements

    assert Enum.any?(
             rule_matches,
             &(&1["rule_id"] == "resource_pressure_block" and
                 &1["risk_type"] == "storage_overflow")
           )

    assert Enum.any?(
             rule_matches,
             &(&1["rule_id"] == "resource_pressure_block" and
                 &1["risk_type"] == "downlink_shortfall")
           )

    assert {:ok, %{"schema_contract" => "resource_projection_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_resource_projection_report(report)

    assert [
             %{
               "resource_pressure_status" => "storage_and_downlink_pressure",
               "resource_pressure_types" => ["downlink_shortfall", "storage_overflow"]
             }
           ] = review["rows"]

    import = CadenceImport.from_resource_projection_report(report)

    assert [
             %{
               "resource_pressure_status" => "storage_and_downlink_pressure",
               "resource_pressure_types" => ["downlink_shortfall", "storage_overflow"]
             }
           ] = import["rows"]
  end

  test "public facade builds projection reports and empty summaries remain optional" do
    assert OrbitalDynamics.resource_projection_report([], []) == nil

    report =
      OrbitalDynamics.resource_projection_report(
        [%{id: :obs_1, type: :observe, scenario_id: :leo_1, estimated_storage_mb: 5.0}],
        [%{spacecraft_id: :leo_1, storage_capacity_mb: 10.0, storage_used_mb: 0.0}],
        source: "facade_test"
      )

    assert %{
             "assumptions" => %{"source" => "facade_test"},
             "projected_resources" => [%{"estimated_storage_produced_mb" => 5.0}]
           } = report

    assert ResourceProjection.report(report) == report
    assert OrbitalDynamics.resource_projection_report(report) == report

    atom_keyed_report =
      Map.new(report, fn {key, value} -> {String.to_atom(key), value} end)

    assert ResourceProjection.report(atom_keyed_report) == report
    assert OrbitalDynamics.resource_projection_report(atom_keyed_report) == report
  end

  test "builds public flow summaries from selected activity resource projection rows" do
    activities = [
      %{
        id: :dl_late,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        station_calendar_entry_id: :provider_window_1,
        station_calendar_provider_id: :ops_calendar,
        station_calendar_provider_entry_id: :provider_api_window_1,
        source_window: %{
          window_id: :downlink_window_1,
          type: :ground_station_access
        },
        starts_at_s: 20.0,
        estimated_throughput_mb: 10.0,
        estimated_energy_generated_wh: 5.0
      },
      %{
        id: :obs_early,
        type: :observe,
        scenario_id: :leo_1,
        source_window: %{
          window_id: :collection_window_1,
          type: :target_access
        },
        starts_at_s: 10.0,
        collection_ends_at_s: 15.0,
        planned_delivery_at_s: 45.0,
        max_latency_s: 20.0,
        data_volume_mb: 25.0,
        actual_data_volume_mb: 12.0,
        estimated_storage_mb: 30.0,
        estimated_energy_used_wh: 20.0
      }
    ]

    summaries = [
      %{
        spacecraft_id: :leo_1,
        storage_capacity_mb: 50.0,
        storage_used_mb: 30.0,
        downlink_capacity_mb: 5.0,
        battery_capacity_wh: 100.0,
        battery_energy_used_wh: 10.0
      }
    ]

    projection_report = ResourceProjection.report(activities, summaries, source: "flow_test")
    flow_report = ResourceProjection.flow_report(activities, summaries, source: "flow_test")

    assert %{
             "schema_contract" => "resource_projection_flow_summary.v1",
             "schema_version" => 1,
             "model" => "artifact_only_selected_activity_resource_flow_summary",
             "source" => "flow_test",
             "activity_count" => 2,
             "valid_activity_count" => 2,
             "invalid_activity_input_count" => 0,
             "invalid_activity_input_ids" => [],
             "input_resource_summary_count" => 1,
             "valid_resource_summary_count" => 1,
             "invalid_resource_summary_input_count" => 0,
             "invalid_resource_summary_input_ids" => [],
             "projected_resource_count" => 1,
             "flow_row_count" => 2,
             "resource_flow_status" => "review_required",
             "resource_pressure_status" => "review_required",
             "resource_pressure_count" => 1,
             "resource_pressure_types" => ["downlink_shortfall", "storage_overflow"],
             "resource_pressure_spacecraft_ids" => ["leo_1"],
             "resource_pressure_spacecraft_ids_by_type" => %{
               "downlink_shortfall" => ["leo_1"],
               "storage_overflow" => ["leo_1"]
             },
             "resource_pressure_activity_ids_by_type" => %{
               "downlink_shortfall" => ["dl_late"],
               "storage_overflow" => ["obs_early"]
             },
             "resource_pressure_ground_station_ids_by_type" => %{
               "downlink_shortfall" => ["equator_prime"]
             },
             "resource_pressure_source_window_ids_by_type" => %{
               "downlink_shortfall" => ["downlink_window_1"],
               "storage_overflow" => ["collection_window_1"]
             },
             "resource_pressure_station_calendar_entry_ids_by_type" => %{
               "downlink_shortfall" => ["provider_window_1"]
             },
             "resource_pressure_station_calendar_provider_ids_by_type" => %{
               "downlink_shortfall" => ["ops_calendar"]
             },
             "resource_pressure_station_calendar_provider_entry_ids_by_type" => %{
               "downlink_shortfall" => ["provider_api_window_1"]
             },
             "total_storage_produced_mb" => 30.0,
             "total_planned_downlink_mb" => 10.0,
             "total_storage_limited_downlinked_mb" => 10.0,
             "total_unused_downlink_capacity_mb" => +0.0,
             "total_storage_overflow_mb" => 10.0,
             "total_downlink_shortfall_mb" => 5.0,
             "actual_data_volume_evidence_count" => 1,
             "total_actual_data_volume_mb" => 12.0,
             "total_data_volume_delta_mb" => -13.0,
             "actual_data_volume_under_delivered_activity_ids" => ["obs_early"],
             "actual_data_volume_over_delivered_activity_ids" => [],
             "actual_data_volume_exact_activity_ids" => [],
             "total_projected_storage_remaining_mb" => +0.0,
             "minimum_projected_storage_remaining_mb" => +0.0,
             "total_projected_downlink_remaining_mb" => +0.0,
             "minimum_projected_downlink_remaining_mb" => +0.0,
             "latency_status" => "review_required",
             "latency_evidence_count" => 1,
             "latency_review_count" => 1,
             "latency_review_activity_ids" => ["obs_early"],
             "max_planned_latency_s" => 30.0,
             "total_battery_energy_consumed_wh" => 20.0,
             "total_battery_energy_generated_wh" => 5.0,
             "net_battery_energy_delta_wh" => 15.0,
             "peak_battery_overuse_wh" => +0.0,
             "projected_resources" => [
               %{
                 "spacecraft_id" => "leo_1",
                 "activity_count" => 2,
                 "effective_activity_count" => 2,
                 "estimated_storage_produced_mb" => 30.0,
                 "estimated_downlink_mb" => 10.0,
                 "storage_limited_downlinked_mb" => 10.0,
                 "unused_downlink_capacity_mb" => +0.0,
                 "starting_storage_used_mb" => 30.0,
                 "projected_storage_used_mb" => 50.0,
                 "storage_capacity_mb" => 50.0,
                 "projected_storage_remaining_mb" => +0.0,
                 "projected_storage_overflow_mb" => +0.0,
                 "downlink_capacity_mb" => 5.0,
                 "projected_downlink_remaining_mb" => +0.0,
                 "projected_downlink_shortfall_mb" => 5.0,
                 "projected_battery_energy_used_wh" => 25.0,
                 "projected_battery_state_of_charge" => 0.75,
                 "projected_battery_overuse_wh" => +0.0,
                 "resource_pressure_status" => "downlink_shortfall",
                 "resource_pressure_types" => ["downlink_shortfall"],
                 "first_resource_pressure_activity_id" => "obs_early",
                 "first_resource_pressure_activity_type" => "observe",
                 "first_resource_pressure_kind" => "storage_overflow",
                 "first_resource_pressure_starts_at_s" => 10.0
               }
             ],
             "activity_resource_flow" => [
               %{
                 "spacecraft_id" => "leo_1",
                 "activity_id" => "obs_early",
                 "collection_ends_at_s" => 15.0,
                 "planned_delivery_at_s" => 45.0,
                 "max_latency_s" => 20.0,
                 "planned_latency_s" => 30.0,
                 "latency_margin_s" => -10.0,
                 "latency_basis" => "planned",
                 "latency_status" => "late",
                 "storage_used_before_mb" => 30.0,
                 "storage_used_after_mb" => 60.0,
                 "storage_overflow_mb" => 10.0,
                 "battery_energy_consumed_wh" => 20.0,
                 "battery_energy_generated_wh" => +0.0,
                 "battery_energy_delta_wh" => 20.0,
                 "battery_energy_used_after_wh" => 30.0
               },
               %{
                 "spacecraft_id" => "leo_1",
                 "activity_id" => "dl_late",
                 "storage_used_before_mb" => 60.0,
                 "storage_used_after_mb" => 50.0,
                 "downlink_used_after_mb" => 10.0,
                 "downlink_shortfall_mb" => 5.0,
                 "battery_energy_consumed_wh" => +0.0,
                 "battery_energy_generated_wh" => 5.0,
                 "battery_energy_delta_wh" => -5.0,
                 "battery_energy_used_after_wh" => 25.0
               }
             ],
             "model_limits" => model_limits,
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_schedule_mutation",
               "projection_model" => "thin_time_ordered_resource_roll_forward",
               "latency_model" => "declared_activity_timestamps_only",
               "realized_state_reconciliation" => "not_performed",
               "subsystem_simulation" => "not_performed"
             }
           } = flow_report

    assert "thin_time_ordered_resource_roll_forward" in model_limits
    assert "no_subsystem_simulation" in model_limits
    assert "no_realized_state_resource_reconciliation" in model_limits

    assert get_in(flow_report, ["assumptions", "subsystem_model_capability_contract"]) ==
             "subsystem_model_capability.v1"

    assert get_in(flow_report, ["assumptions", "subsystem_model_capability_ids"]) == [
             "subsystem.power.battery.energy_storage.planning_grade",
             "subsystem.data_recorder.storage_buffer.planning_grade"
           ]

    assert get_in(flow_report, ["assumptions", "subsystem_model_capability_ids_by_resource"]) ==
             %{
               "battery" => "subsystem.power.battery.energy_storage.planning_grade",
               "storage" => "subsystem.data_recorder.storage_buffer.planning_grade"
             }

    assert ResourceProjection.flow_report(projection_report) == flow_report
    assert ResourceProjection.flow_report(flow_report) == flow_report
    assert ResourceProjection.flow_summary(projection_report) == flow_report
    assert ResourceProjection.flow_summary(flow_report) == flow_report
    assert OrbitalDynamics.resource_projection_flow_report(projection_report) == flow_report
    assert OrbitalDynamics.resource_projection_flow_report(flow_report) == flow_report
    assert OrbitalDynamics.resource_projection_flow_summary(projection_report) == flow_report
    assert OrbitalDynamics.resource_projection_flow_summary(flow_report) == flow_report

    assert ResourceProjection.flow_summary(%{
             schema_contract: "resource_projection_flow_summary.v1",
             model: "artifact_only_selected_activity_resource_flow_summary",
             source: "atom_keyed_fixture",
             activity_resource_flow: []
           }) == %{
             "schema_contract" => "resource_projection_flow_summary.v1",
             "model" => "artifact_only_selected_activity_resource_flow_summary",
             "source" => "atom_keyed_fixture",
             "activity_resource_flow" => []
           }

    assert {:ok, %{"schema_contract" => "resource_projection_flow_summary.v1"}} =
             Schema.validate_artifact(flow_report)

    stale_subsystem_contract =
      put_in(
        flow_report,
        ["assumptions", "subsystem_model_capability_contract"],
        "spacecraft_model.v1"
      )

    assert {:error, stale_subsystem_contract_report} =
             Schema.validate_artifact(stale_subsystem_contract)

    assert Enum.any?(
             stale_subsystem_contract_report["errors"],
             &(&1["path"] == "$.assumptions.subsystem_model_capability_contract" and
                 &1["message"] == "must equal \"subsystem_model_capability.v1\"")
           )

    stale_model = Map.put(flow_report, "model", "custom_selected_activity_resource_flow_summary")

    assert {:error, stale_model_report} = Schema.validate_artifact(stale_model)

    assert Enum.any?(
             stale_model_report["errors"],
             &(&1["path"] == "$.model" and
                 &1["message"] ==
                   "must equal \"artifact_only_selected_activity_resource_flow_summary\"")
           )

    stale_source = Map.put(flow_report, "source", %{"adapter" => "ops"})

    assert {:error, stale_source_report} = Schema.validate_artifact(stale_source)

    assert Enum.any?(
             stale_source_report["errors"],
             &(&1["path"] == "$.source" and &1["message"] == "must be a binary")
           )

    Enum.each(
      [
        {"resource_flow_status", "pending"},
        {"resource_pressure_status", "resource_pressure"},
        {"latency_status", "late"}
      ],
      fn {field, value} ->
        stale_status = Map.put(flow_report, field, value)

        assert {:error, stale_status_report} = Schema.validate_artifact(stale_status)

        assert Enum.any?(
                 stale_status_report["errors"],
                 &(&1["path"] == "$.#{field}" and
                     &1["message"] == "must be one of [\"clear\", \"review_required\"]")
               )
      end
    )

    stale_total = Map.put(flow_report, "total_downlink_shortfall_mb", 99.0)

    assert {:error, stale_total_report} = Schema.validate_artifact(stale_total)

    assert Enum.any?(
             stale_total_report["errors"],
             &(&1["path"] == "$.total_downlink_shortfall_mb" and
                 &1["message"] == "must equal activity_resource_flow downlink_shortfall_mb sum")
           )

    stale_actual_volume_total = Map.put(flow_report, "total_actual_data_volume_mb", 99.0)

    assert {:error, stale_actual_volume_total_report} =
             Schema.validate_artifact(stale_actual_volume_total)

    assert Enum.any?(
             stale_actual_volume_total_report["errors"],
             &(&1["path"] == "$.total_actual_data_volume_mb" and
                 &1["message"] == "must equal activity_resource_flow actual_data_volume_mb sum")
           )

    stale_actual_variance_ids =
      Map.put(flow_report, "actual_data_volume_under_delivered_activity_ids", ["dl_late"])

    assert {:error, stale_actual_variance_ids_report} =
             Schema.validate_artifact(stale_actual_variance_ids)

    assert Enum.any?(
             stale_actual_variance_ids_report["errors"],
             &(&1["path"] == "$.actual_data_volume_under_delivered_activity_ids" and
                 &1["message"] ==
                   "must equal activity_resource_flow under-delivered actual data-volume activity IDs")
           )

    stale_pressure_station_ids =
      put_in(
        flow_report,
        ["resource_pressure_ground_station_ids_by_type", "downlink_shortfall"],
        ["stale_station"]
      )

    assert {:error, stale_pressure_station_ids_report} =
             Schema.validate_artifact(stale_pressure_station_ids)

    assert Enum.any?(
             stale_pressure_station_ids_report["errors"],
             &(&1["path"] == "$.resource_pressure_ground_station_ids_by_type" and
                 &1["message"] ==
                   "must equal row-derived resource_pressure_ground_station_ids_by_type")
           )

    stale_pressure_source_window_ids =
      put_in(
        flow_report,
        ["resource_pressure_source_window_ids_by_type", "storage_overflow"],
        ["stale_window"]
      )

    assert {:error, stale_pressure_source_window_ids_report} =
             Schema.validate_artifact(stale_pressure_source_window_ids)

    assert Enum.any?(
             stale_pressure_source_window_ids_report["errors"],
             &(&1["path"] == "$.resource_pressure_source_window_ids_by_type" and
                 &1["message"] ==
                   "must equal row-derived resource_pressure_source_window_ids_by_type")
           )

    stale_pressure_station_calendar_entry_ids =
      put_in(
        flow_report,
        ["resource_pressure_station_calendar_entry_ids_by_type", "downlink_shortfall"],
        ["stale_entry"]
      )

    assert {:error, stale_pressure_station_calendar_entry_ids_report} =
             Schema.validate_artifact(stale_pressure_station_calendar_entry_ids)

    assert Enum.any?(
             stale_pressure_station_calendar_entry_ids_report["errors"],
             &(&1["path"] == "$.resource_pressure_station_calendar_entry_ids_by_type" and
                 &1["message"] ==
                   "must equal row-derived resource_pressure_station_calendar_entry_ids_by_type")
           )

    stale_pressure_station_calendar_provider_ids =
      put_in(
        flow_report,
        [
          "resource_pressure_station_calendar_provider_ids_by_type",
          "downlink_shortfall"
        ],
        ["stale_provider"]
      )

    assert {:error, stale_pressure_station_calendar_provider_ids_report} =
             Schema.validate_artifact(stale_pressure_station_calendar_provider_ids)

    assert Enum.any?(
             stale_pressure_station_calendar_provider_ids_report["errors"],
             &(&1["path"] ==
                 "$.resource_pressure_station_calendar_provider_ids_by_type" and
                 &1["message"] ==
                   "must equal row-derived resource_pressure_station_calendar_provider_ids_by_type")
           )

    stale_pressure_station_calendar_provider_entry_ids =
      put_in(
        flow_report,
        [
          "resource_pressure_station_calendar_provider_entry_ids_by_type",
          "downlink_shortfall"
        ],
        ["stale_provider_entry"]
      )

    assert {:error, stale_pressure_station_calendar_provider_entry_ids_report} =
             Schema.validate_artifact(stale_pressure_station_calendar_provider_entry_ids)

    assert Enum.any?(
             stale_pressure_station_calendar_provider_entry_ids_report["errors"],
             &(&1["path"] ==
                 "$.resource_pressure_station_calendar_provider_entry_ids_by_type" and
                 &1["message"] ==
                   "must equal row-derived resource_pressure_station_calendar_provider_entry_ids_by_type")
           )

    stale_pressure_station_calendar_directions =
      put_in(
        flow_report,
        [
          "resource_pressure_station_calendar_directions_by_type",
          "downlink_shortfall"
        ],
        ["uplink"]
      )

    assert {:error, stale_pressure_station_calendar_directions_report} =
             Schema.validate_artifact(stale_pressure_station_calendar_directions)

    assert Enum.any?(
             stale_pressure_station_calendar_directions_report["errors"],
             &(&1["path"] ==
                 "$.resource_pressure_station_calendar_directions_by_type" and
                 &1["message"] ==
                   "must equal row-derived resource_pressure_station_calendar_directions_by_type")
           )

    stale_pressure_capacity_fractions =
      put_in(
        flow_report,
        ["resource_pressure_capacity_fractions_by_type", "downlink_shortfall"],
        [0.5]
      )

    assert {:error, stale_pressure_capacity_fractions_report} =
             Schema.validate_artifact(stale_pressure_capacity_fractions)

    assert Enum.any?(
             stale_pressure_capacity_fractions_report["errors"],
             &(&1["path"] == "$.resource_pressure_capacity_fractions_by_type" and
                 &1["message"] ==
                   "must equal row-derived resource_pressure_capacity_fractions_by_type")
           )

    stale_remaining = Map.put(flow_report, "total_projected_storage_remaining_mb", 99.0)

    assert {:error, stale_remaining_report} = Schema.validate_artifact(stale_remaining)

    assert Enum.any?(
             stale_remaining_report["errors"],
             &(&1["path"] == "$.total_projected_storage_remaining_mb" and
                 &1["message"] == "must equal projected_resources storage remaining sum")
           )

    invalid_flow_row =
      put_in(flow_report, ["activity_resource_flow", Access.at(0), "storage_used_after_mb"], "60")

    assert {:error, invalid_flow_row_report} = Schema.validate_artifact(invalid_flow_row)

    assert Enum.any?(
             invalid_flow_row_report["errors"],
             &(&1["path"] == "$.activity_resource_flow[0].storage_used_after_mb" and
                 &1["message"] == "must be a number")
           )

    invalid_downlink_shortfall =
      put_in(flow_report, ["activity_resource_flow", Access.at(1), "downlink_shortfall_mb"], -1.0)

    assert {:error, invalid_downlink_shortfall_report} =
             Schema.validate_artifact(invalid_downlink_shortfall)

    assert Enum.any?(
             invalid_downlink_shortfall_report["errors"],
             &(&1["path"] == "$.activity_resource_flow[1].downlink_shortfall_mb" and
                 &1["message"] == "must be non-negative")
           )

    assert OrbitalDynamics.resource_projection_flow_report(activities, summaries,
             source: "flow_test"
           ) ==
             flow_report

    stale_activity_counts =
      projection_report
      |> Map.put("activity_count", 9)
      |> Map.put("valid_activity_count", 9)

    assert %{
             "activity_count" => 2,
             "valid_activity_count" => 2,
             "flow_row_count" => 2
           } = ResourceProjection.flow_summary(stale_activity_counts)

    assert %{
             "resource_flow_status" => "clear",
             "resource_pressure_status" => "clear",
             "resource_pressure_count" => 0,
             "resource_pressure_types" => []
           } =
             ResourceProjection.flow_report(
               [%{id: :obs_ok, type: :observe, scenario_id: :leo_1, estimated_storage_mb: 5.0}],
               [%{spacecraft_id: :leo_1, storage_capacity_mb: 10.0, storage_used_mb: 0.0}]
             )

    assert OrbitalDynamics.resource_projection_flow_report([], []) == nil

    stale_invalid_counts =
      projection_report
      |> Map.put("invalid_activity_input_count", 9)
      |> Map.put("invalid_activity_input_ids", ["stale_activity"])
      |> Map.put("invalid_resource_summary_input_count", 4)
      |> Map.put("invalid_resource_summary_input_ids", ["stale_summary"])
      |> Map.put("input_resource_summary_count", 99)
      |> Map.put("valid_resource_summary_count", 99)

    assert %{
             "resource_flow_status" => "review_required",
             "invalid_activity_input_count" => 0,
             "invalid_activity_input_ids" => [],
             "input_resource_summary_count" => 1,
             "valid_resource_summary_count" => 1,
             "invalid_resource_summary_input_count" => 0,
             "invalid_resource_summary_input_ids" => []
           } = ResourceProjection.flow_summary(stale_invalid_counts)

    report_with_invalid_rows =
      projection_report
      |> Map.put("invalid_activity_input_count", 0)
      |> Map.put("invalid_activity_input_ids", [])
      |> Map.put("invalid_resource_summary_input_count", 0)
      |> Map.put("invalid_resource_summary_input_ids", [])
      |> Map.put("invalid_activity_inputs", [
        %{"activity_id" => "bad_activity", "invalid_activity_input" => true}
      ])
      |> Map.put("invalid_resource_summary_inputs", [
        %{"resource_summary_id" => "bad_summary", "invalid_resource_summary_input" => true}
      ])

    assert %{
             "resource_flow_status" => "review_required",
             "activity_count" => 3,
             "invalid_activity_input_count" => 1,
             "invalid_activity_input_ids" => ["bad_activity"],
             "input_resource_summary_count" => 2,
             "valid_resource_summary_count" => 1,
             "invalid_resource_summary_input_count" => 1,
             "invalid_resource_summary_input_ids" => ["bad_summary"]
           } = ResourceProjection.flow_summary(report_with_invalid_rows)

    assert_raise ArgumentError, ~r/resource projection report is required/, fn ->
      ResourceProjection.flow_summary(%{"schema_contract" => "resource_summary.v1"})
    end

    assert_raise ArgumentError, ~r/activities and summaries must be lists/, fn ->
      ResourceProjection.flow_report(:not_a_list, [%{spacecraft_id: :leo_1}])
    end
  end

  test "rolls planned data-volume aliases into observation storage production" do
    activities = [
      %{
        id: :obs_planned_volume,
        type: :observe,
        scenario_id: :leo_1,
        data_volume_mb: 25.0,
        actual_data_volume_mb: 12.0,
        starts_at_s: 10.0,
        ends_at_s: 20.0
      },
      %{
        id: :obs_metadata_volume,
        type: :observe,
        scenario_id: :leo_1,
        metadata: %{estimated_data_volume_mb: 15.0},
        starts_at_s: 30.0,
        ends_at_s: 40.0
      }
    ]

    summaries = [
      %{
        spacecraft_id: :leo_1,
        storage_capacity_mb: 100.0,
        storage_used_mb: 10.0
      }
    ]

    assert %{
             "total_storage_produced_mb" => 40.0,
             "activity_resource_flow" => [
               %{
                 "activity_id" => "obs_planned_volume",
                 "planned_data_volume_mb" => 25.0,
                 "actual_data_volume_mb" => 12.0,
                 "data_volume_delta_mb" => -13.0,
                 "data_volume_completion_fraction" => 0.48,
                 "storage_produced_mb" => 25.0,
                 "storage_used_after_mb" => 35.0
               },
               %{
                 "activity_id" => "obs_metadata_volume",
                 "planned_data_volume_mb" => 15.0,
                 "storage_produced_mb" => 15.0,
                 "storage_used_after_mb" => 50.0
               }
             ],
             "actual_data_volume_evidence_count" => 1,
             "total_actual_data_volume_mb" => 12.0,
             "total_data_volume_delta_mb" => -13.0,
             "actual_data_volume_under_delivered_activity_ids" => ["obs_planned_volume"],
             "actual_data_volume_over_delivered_activity_ids" => [],
             "actual_data_volume_exact_activity_ids" => []
           } = ResourceProjection.flow_report(activities, summaries)

    invalid_report =
      ResourceProjection.flow_report(
        [%{id: :obs_bad_volume, type: :observe, scenario_id: :leo_1, data_volume_mb: -1.0}],
        summaries
      )

    assert %{
             "valid_activity_count" => 0,
             "invalid_activity_input_count" => 1,
             "invalid_activity_input_ids" => ["obs_bad_volume"],
             "activity_resource_flow" => []
           } = invalid_report

    assert {:ok, %{"schema_contract" => "resource_projection_flow_summary.v1"}} =
             Schema.validate_artifact(invalid_report)
  end
end
