defmodule OrbitalDynamics.ResourceFilterTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, OperatorReview, ResourceFilter, Schema}

  test "declares resource filter capabilities" do
    assert %{
             artifact_contract: "resource_filter_report.v1",
             summary_artifact_contract: "resource_filter_summary.v1",
             validation_level: :artifact_contract,
             model: :resource_summary_availability_and_margin_filter,
             row_semantics: row_semantics,
             suppression_reasons: suppression_reasons,
             row_review_statuses: ["operator_review_required"],
             known_limits: known_limits,
             resource_availability_aliases: resource_availability_aliases,
             resource_degraded_aliases: resource_degraded_aliases,
             resource_margin_aliases: resource_margin_aliases,
             resource_power_margin_source_aliases: resource_power_margin_source_aliases,
             resource_availability_true_tokens: resource_availability_true_tokens,
             resource_availability_false_tokens: resource_availability_false_tokens,
             provider_direction_aliases: provider_direction_aliases,
             station_calendar_direction_aliases: station_calendar_direction_aliases,
             provider_result_map_value_keys: provider_result_map_value_keys,
             public_facades: public_facades,
             resource_filter_policy_fields: resource_filter_policy_fields,
             candidate_stable_identity_fields: candidate_stable_identity_fields,
             station_calendar_id_list_fields: station_calendar_id_list_fields
           } = ResourceFilter.capabilities()

    assert :resource_summary_availability_suppression in row_semantics
    assert :resource_filter_summary in row_semantics
    assert :resource_filter_summary_routing_id_sets in row_semantics
    assert :resource_availability_aliases in row_semantics
    assert :resource_availability_status_tokens in row_semantics
    assert :resource_degraded_aliases in row_semantics
    assert :resource_margin_aliases in row_semantics
    assert :resource_power_margin_source_aliases in row_semantics
    assert :resource_margin_policy_suppression in row_semantics
    assert :resource_thermal_margin_policy_suppression in row_semantics
    assert :resource_source_quality_counts in row_semantics
    assert :resource_trust_boundary_status_counts in row_semantics
    assert :suppressed_resource_source_quality_candidate_id_routing in row_semantics
    assert :suppressed_resource_trust_boundary_status_candidate_id_routing in row_semantics
    assert :resource_provenance_alias_normalization in row_semantics
    assert :resource_battery_mode_evidence_preservation in row_semantics
    assert :resource_summary_activity_type_suppression in row_semantics
    assert :duplicate_resource_summary_ambiguity in row_semantics
    assert :candidate_stable_identity_fields in row_semantics
    assert :station_calendar_id_list_fields in row_semantics
    assert :station_calendar_direction_context in row_semantics
    assert :provider_direction_aliases in row_semantics
    assert :station_calendar_direction_aliases in row_semantics
    assert :station_calendar_entry_identity_preservation in row_semantics
    assert :invalid_candidate_input_review in row_semantics
    assert :feedback_unit_interval_input_validation in row_semantics
    assert :provider_result_map_value_keys in row_semantics
    assert :derived_resource_summary_margin_consistency in row_semantics
    assert :invalid_resource_summary_input_review in row_semantics
    assert "payload_unavailable" in suppression_reasons
    assert "spacecraft_unavailable" in suppression_reasons
    assert "activity_type_suppressed_by_resource_summary" in suppression_reasons
    assert "activity_type_incompatible_with_resource_summary" in suppression_reasons
    assert "ambiguous_resource_summary" in suppression_reasons
    assert "thermal_margin_below_policy" in suppression_reasons
    assert "downlink_margin_below_policy" in suppression_reasons
    assert "invalid_resource_summary_input" in suppression_reasons
    assert :artifact_level_only in known_limits
    assert :no_subsystem_simulation in known_limits
    assert :no_resource_time_propagation in known_limits
    assert :no_schedule_mutation in known_limits

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

    assert resource_power_margin_source_aliases == ["battery_state_of_charge", "battery_soc"]

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
    assert "result" in provider_result_map_value_keys
    assert "provider_status" in provider_result_map_value_keys
    assert "provider_outcome" in provider_result_map_value_keys
    assert "diagnostics" in provider_result_map_value_keys
    assert "scenario_id" in candidate_stable_identity_fields
    assert "source_window_id" in candidate_stable_identity_fields
    assert "station_reservation_id" in candidate_stable_identity_fields
    assert "station_calendar_overlap_entry_ids" in station_calendar_id_list_fields
    assert "station_calendar_ambiguous_entry_ids" in station_calendar_id_list_fields
    assert "station_calendar_reservation_ids" in station_calendar_id_list_fields

    assert public_facades == [
             :filter_resource_candidates,
             :resource_filter_report,
             :resource_filter_summary,
             :resource_filter_policy
           ]

    assert resource_filter_policy_fields == [
             "min_activity_fuel_margin",
             "min_activity_thermal_margin_c",
             "min_observe_power_margin",
             "min_observe_storage_margin",
             "min_downlink_power_margin",
             "min_downlink_margin"
           ]
  end

  test "normalizes resource filter policy thresholds through public facades" do
    policy = %{
      :min_activity_fuel_margin => "0.25",
      "min_activity_thermal_margin_c" => 2,
      "min_observe_power_margin" => "invalid",
      :min_observe_storage_margin => nil,
      :min_downlink_power_margin => 0.4,
      :min_downlink_margin => "0.5"
    }

    assert ResourceFilter.resource_filter_policy(policy) == %{
             "min_activity_fuel_margin" => 0.25,
             "min_activity_thermal_margin_c" => 2.0,
             "min_downlink_power_margin" => 0.4,
             "min_downlink_margin" => 0.5
           }

    assert OrbitalDynamics.resource_filter_policy(policy) ==
             ResourceFilter.resource_filter_policy(policy)
  end

  test "preserves invalid resource summaries without suppressing candidates" do
    candidates = [
      %{
        id: :obs_1,
        type: :observe,
        scenario_id: :leo_1,
        spacecraft_id: :sat_1,
        target_id: :target_alpha,
        starts_at_s: 10.0,
        ends_at_s: 20.0
      }
    ]

    summaries = [
      %{
        spacecraft_id: :sat_1,
        payload_available: false,
        power_margin: 1.2,
        source_quality: :operator_supplied
      },
      %{
        spacecraft_id: "bad spacecraft id",
        payload_available: false
      }
    ]

    {kept, report} =
      ResourceFilter.filter_candidates(candidates, summaries,
        approval_policy: %{policy_bundle_id: "degraded_payload_guard_v1"}
      )

    assert Enum.map(kept, & &1["id"]) == ["obs_1"]

    assert %{
             "input_resource_summary_count" => 2,
             "valid_resource_summary_count" => 0,
             "invalid_resource_summary_input_count" => 2,
             "invalid_resource_summary_input_ids" => ["sat_1", "resource_summary:2"],
             "invalid_resource_summary_inputs" => [
               %{
                 "resource_summary_id" => "sat_1",
                 "spacecraft_id" => "sat_1",
                 "required_operator_action" => "review_invalid_resource_filter_summary",
                 "invalid_resource_summary_input" => true,
                 "invalid_resource_summary_input_reason" => "invalid_power_margin",
                 "source_resource_summary" => %{"power_margin" => 1.2}
               },
               %{
                 "resource_summary_id" => "resource_summary:2",
                 "invalid_resource_summary_input_reason" => "invalid_spacecraft_id",
                 "source_resource_summary" => %{"spacecraft_id" => "bad spacecraft id"}
               }
             ],
             "resource_source_quality_counts" => %{},
             "resource_trust_boundary_status_counts" => %{},
             "suppressed_candidate_count" => 0,
             "suppressed_candidates" => []
           } = report

    first_invalid_summary = List.first(report["invalid_resource_summary_inputs"])

    assert first_invalid_summary["approval_status"] == "operator_review_required"

    assert [
             %{
               "activity_id" => "resource_filter:invalid_resource_summary:sat_1",
               "activity_type" => "resource_filter_invalid_summary",
               "action" => "review_invalid_resource_filter_summary",
               "policy_classification" => "operator_review_required"
             }
           ] = first_invalid_summary["approval_requirements"]

    assert [
             %{
               "rule_id" => "invalid_resource_filter_summary_input_review",
               "classification" => "operator_review_required"
             }
           ] = first_invalid_summary["approval_rule_matches"]

    assert get_in(first_invalid_summary, ["policy_decision", "policy_bundle_id"]) ==
             "degraded_payload_guard_v1"

    assert {:ok, %{"schema_contract" => "resource_filter_report.v1"}} =
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

    invalid_summary_ids =
      Map.put(report, "invalid_resource_summary_input_ids", ["resource_summary:2"])

    assert {:error, invalid_summary_ids_validation} =
             Schema.validate_artifact(invalid_summary_ids)

    assert Enum.any?(
             invalid_summary_ids_validation["errors"],
             &(&1["path"] == "$.invalid_resource_summary_input_ids" and
                 &1["message"] == "must equal row-derived invalid_resource_summary_input_ids")
           )

    review = OperatorReview.from_resource_filter_report(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert Enum.any?(
             review["rows"],
             &(&1["required_operator_action"] == "review_invalid_resource_filter_summary" and
                 &1["invalid_resource_summary_input_reason"] == "invalid_power_margin" and
                 &1["policy_bundle_id"] == "degraded_payload_guard_v1" and
                 &1["rule_id"] == "invalid_resource_filter_summary_input_review" and
                 get_in(&1, ["source_policy_decision", "classification"]) ==
                   "operator_review_required" and
                 get_in(&1, ["source_resource_summary", "power_margin"]) == 1.2)
           )

    manifest = CadenceImport.from_resource_filter_report(report)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    assert Enum.any?(
             manifest["rows"],
             &(&1["import_action"] == "review_resource_suppression" and
                 &1["required_operator_action"] == "review_invalid_resource_filter_summary" and
                 &1["invalid_resource_summary_input"] == true and
                 &1["policy_bundle_id"] == "degraded_payload_guard_v1" and
                 &1["rule_id"] == "invalid_resource_filter_summary_input_review" and
                 get_in(&1, ["source_policy_decision", "classification"]) ==
                   "operator_review_required" and
                 get_in(&1, ["source_resource_summary", "spacecraft_id"]) == "bad spacecraft id")
           )
  end

  test "normalizes resource margin aliases before policy suppression" do
    candidates = [
      %{
        id: :obs_storage,
        type: :observe,
        scenario_id: :storage_scope,
        spacecraft_id: :storage_scope,
        target_id: :target_alpha
      },
      %{
        id: :dl_downlink,
        type: :downlink,
        scenario_id: :downlink_scope,
        spacecraft_id: :downlink_scope,
        ground_station_id: :gs_a,
        starts_at_s: 10.0,
        ends_at_s: 20.0
      },
      %{
        id: :dl_power,
        type: :downlink,
        scenario_id: :power_scope,
        spacecraft_id: :power_scope,
        ground_station_id: :gs_a,
        starts_at_s: 30.0,
        ends_at_s: 40.0
      }
    ]

    summaries = [
      %{
        spacecraft_id: :storage_scope,
        storage_capacity_margin: "0.4",
        payload_available: true,
        antenna_available: true
      },
      %{
        spacecraft_id: :downlink_scope,
        downlink_capacity_margin: "0.7",
        battery_soc: "0.9",
        antenna_available: true
      },
      %{
        spacecraft_id: :power_scope,
        downlink_capacity_margin: "0.9",
        battery_soc: "0.4",
        antenna_available: true
      }
    ]

    {kept, report} =
      ResourceFilter.filter_candidates(candidates, summaries,
        policy: %{
          min_observe_storage_margin: 0.6,
          min_downlink_margin: 0.8,
          min_downlink_power_margin: 0.5
        }
      )

    assert kept == []

    assert %{
             "suppressed_candidate_count" => 3,
             "suppressed_candidates" => suppressed
           } = report

    assert %{
             "suppressed_reason" => "storage_margin_below_observe_policy",
             "storage_margin" => 0.4,
             "source_resource_summary" => %{
               "storage_capacity_margin" => "0.4",
               "storage_margin" => 0.4
             }
           } = Enum.find(suppressed, &(&1["id"] == "obs_storage"))

    assert %{
             "suppressed_reason" => "downlink_margin_below_policy",
             "downlink_margin" => 0.7,
             "power_margin" => 0.9,
             "battery_state_of_charge" => 0.9,
             "source_resource_summary" => %{
               "downlink_capacity_margin" => "0.7",
               "battery_soc" => "0.9"
             }
           } = Enum.find(suppressed, &(&1["id"] == "dl_downlink"))

    assert %{
             "suppressed_reason" => "power_margin_below_downlink_policy",
             "downlink_margin" => 0.9,
             "power_margin" => 0.4,
             "battery_state_of_charge" => 0.4,
             "source_resource_summary" => %{"battery_soc" => "0.4"}
           } = Enum.find(suppressed, &(&1["id"] == "dl_power"))

    assert {:ok, %{"schema_contract" => "resource_filter_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "preserves stale derived-margin resource summaries without suppressing candidates" do
    candidates = [
      %{
        id: :obs_1,
        type: :observe,
        scenario_id: :leo_1,
        spacecraft_id: :sat_1,
        target_id: :target_alpha,
        starts_at_s: 10.0,
        ends_at_s: 20.0
      }
    ]

    summaries = [
      %{
        spacecraft_id: :sat_1,
        battery_capacity_wh: 100.0,
        battery_energy_used_wh: 20.0,
        battery_state_of_charge: 0.7
      },
      %{
        spacecraft_id: :sat_2,
        storage_capacity_mb: 100.0,
        storage_used_mb: 10.0,
        storage_margin: 0.75
      }
    ]

    {kept, report} =
      ResourceFilter.filter_candidates(candidates, summaries,
        approval_policy: %{policy_bundle_id: "degraded_payload_guard_v1"}
      )

    assert Enum.map(kept, & &1["id"]) == ["obs_1"]

    assert %{
             "input_resource_summary_count" => 2,
             "valid_resource_summary_count" => 0,
             "invalid_resource_summary_input_count" => 2,
             "invalid_resource_summary_input_ids" => ["sat_1", "sat_2"],
             "invalid_resource_summary_inputs" => [
               %{
                 "resource_summary_id" => "sat_1",
                 "invalid_resource_summary_input_reason" => "stale_battery_state_of_charge",
                 "source_resource_summary" => %{
                   "battery_capacity_wh" => 100.0,
                   "battery_energy_used_wh" => 20.0,
                   "battery_state_of_charge" => 0.7
                 }
               },
               %{
                 "resource_summary_id" => "sat_2",
                 "invalid_resource_summary_input_reason" => "stale_storage_margin",
                 "source_resource_summary" => %{
                   "storage_capacity_mb" => 100.0,
                   "storage_used_mb" => 10.0,
                   "storage_margin" => 0.75
                 }
               }
             ],
             "suppressed_candidate_count" => 0,
             "suppressed_candidates" => []
           } = report

    assert {:ok, %{"schema_contract" => "resource_filter_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_resource_filter_report(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert Enum.any?(review["rows"], fn row ->
             row["invalid_resource_summary_input_reason"] == "stale_battery_state_of_charge" and
               get_in(row, ["source_resource_summary", "battery_state_of_charge"]) == 0.7
           end)

    manifest = CadenceImport.from_resource_filter_report(report)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    assert Enum.any?(manifest["rows"], fn row ->
             row["invalid_resource_summary_input_reason"] == "stale_storage_margin" and
               get_in(row, ["source_resource_summary", "storage_margin"]) == 0.75
           end)
  end

  test "suppresses explicit resource-summary activity type lists" do
    candidates = [
      %{
        id: :obs_suppressed,
        type: :observe,
        scenario_id: :sat_mode,
        spacecraft_id: :sat_mode,
        starts_at_s: 10.0,
        ends_at_s: 20.0
      },
      %{
        id: :cmd_incompatible,
        type: :planned_contact,
        direction: :uplink,
        scenario_id: :sat_mode,
        spacecraft_id: :sat_mode,
        ground_station_id: :equator_prime,
        starts_at_s: 30.0,
        ends_at_s: 40.0
      },
      %{
        id: :tracking_kept,
        type: :tracking,
        scenario_id: :sat_mode,
        spacecraft_id: :sat_mode,
        ground_station_id: :equator_prime,
        starts_at_s: 50.0,
        ends_at_s: 60.0
      }
    ]

    summaries = [
      %{
        spacecraft_id: :sat_mode,
        mode: :safe,
        suppressed_activity_types: [:observe],
        incompatible_activity_types: "command, health-check",
        source_quality: :operator_supplied,
        provenance: %{trust_boundary: :resource_mode_summary}
      }
    ]

    {kept, report} =
      ResourceFilter.filter_candidates(candidates, summaries,
        approval_policy: %{policy_bundle_id: "degraded_payload_guard_v1"}
      )

    assert Enum.map(kept, & &1["id"]) == ["tracking_kept"]

    rows = Map.new(report["suppressed_candidates"], &{&1["id"], &1})

    assert %{
             "suppressed_reason" => "activity_type_suppressed_by_resource_summary",
             "resource_blocking_dimension" => "activity_type",
             "mode" => "safe",
             "suppressed_activity_types" => ["observe"],
             "incompatible_activity_types" => ["command", "health_check"],
             "approval_status" => "auto_approvable",
             "policy_decision" => %{"policy_bundle_id" => "degraded_payload_guard_v1"}
           } = rows["obs_suppressed"]

    assert %{
             "suppressed_reason" => "activity_type_incompatible_with_resource_summary",
             "resource_blocking_dimension" => "activity_type",
             "direction" => "uplink",
             "incompatible_activity_types" => ["command", "health_check"]
           } = rows["cmd_incompatible"]

    review = OperatorReview.from_resource_filter_report(report)

    assert Enum.any?(
             review["rows"],
             &(&1["activity_id"] == "obs_suppressed" and
                 &1["suppressed_activity_types"] == ["observe"] and
                 &1["incompatible_activity_types"] == ["command", "health_check"])
           )

    manifest = CadenceImport.from_resource_filter_report(report)

    assert Enum.any?(
             manifest["rows"],
             &(&1["activity_id"] == "obs_suppressed" and
                 &1["suppressed_activity_types"] == ["observe"])
           )

    assert {:ok, %{"schema_contract" => "resource_filter_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "filters candidates using a wildcard resource summary" do
    candidates = [
      %{
        id: :obs_1,
        type: :observe,
        scenario_id: :leo_1,
        target_id: :target_alpha,
        starts_at_s: 10.0,
        ends_at_s: 20.0,
        source_window_id: :window_1
      },
      %{
        id: :dl_1,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 30.0,
        ends_at_s: 60.0
      }
    ]

    summaries = [
      %{
        payload_available: false,
        antenna_available: true,
        battery_capacity_wh: 1400.0,
        battery_energy_used_wh: 420.0,
        battery_state_of_charge: 0.7,
        mode: :nominal,
        source_quality: :operator_supplied,
        provenance: %{
          source: :operator_summary,
          trust_boundary: :operator_declared_resource_summary
        }
      }
    ]

    {kept, report} =
      ResourceFilter.filter_candidates(candidates, summaries,
        approval_policy: %{policy_bundle_id: "degraded_payload_guard_v1"}
      )

    assert Enum.map(kept, & &1["id"]) == ["dl_1"]

    assert %{
             "id" => "dl_1",
             "resource_source_quality" => "operator_supplied",
             "resource_trust_boundary" => "operator_declared_resource_summary",
             "resource_trust_boundary_status" => "declared",
             "battery_capacity_wh" => 1400.0,
             "battery_energy_used_wh" => 420.0,
             "battery_state_of_charge" => 0.7,
             "mode" => "nominal",
             "source_resource_summary" => %{
               "battery_state_of_charge" => 0.7,
               "mode" => "nominal"
             }
           } = hd(kept)

    assert %{
             "schema_contract" => "resource_filter_report.v1",
             "model" => "resource_summary_availability_and_margin_filter",
             "model_limits" => model_limits,
             "resource_source_quality_counts" => %{"operator_supplied" => 1},
             "resource_trust_boundary_status_counts" => %{"declared" => 1},
             "suppressed_resource_source_quality_counts" => %{"operator_supplied" => 1},
             "suppressed_candidate_ids_by_resource_source_quality" => %{
               "operator_supplied" => ["obs_1"]
             },
             "suppressed_resource_trust_boundary_status_counts" => %{"declared" => 1},
             "suppressed_candidate_ids_by_resource_trust_boundary_status" => %{
               "declared" => ["obs_1"]
             },
             "input_candidate_count" => 2,
             "kept_candidate_count" => 1,
             "suppressed_candidate_count" => 1,
             "invalid_candidate_input_count" => 0,
             "invalid_candidate_input_ids" => [],
             "suppressed_candidates" => [
               %{
                 "id" => "obs_1",
                 "type" => "observe",
                 "scenario_id" => "leo_1",
                 "starts_at_s" => 10.0,
                 "ends_at_s" => 20.0,
                 "source_window_id" => "window_1",
                 "suppressed_reason" => "payload_unavailable",
                 "resource_blocking_dimension" => "payload",
                 "resource_trust_boundary" => "operator_declared_resource_summary",
                 "resource_trust_boundary_status" => "declared",
                 "resource_provenance" => %{
                   "source" => "operator_summary",
                   "trust_boundary" => "operator_declared_resource_summary"
                 }
               }
             ]
           } = report

    assert "no_subsystem_simulation" in model_limits
    assert "no_schedule_mutation" in model_limits

    expected_report_assumptions = resource_filter_report_capability_assumptions()

    assert Map.take(report["assumptions"], Map.keys(expected_report_assumptions)) ==
             expected_report_assumptions

    assert %{
             "schema_contract" => "resource_filter_summary.v1",
             "model" => "artifact_only_resource_filter_summary",
             "source_artifact_type" => "resource_filter_report.v1",
             "model_limits" => ^model_limits,
             "input_candidate_count" => 2,
             "kept_candidate_count" => 1,
             "suppressed_candidate_count" => 1,
             "suppression_review_status" => "review_required",
             "suppressed_candidate_ids" => ["obs_1"],
             "suppressed_reason_counts" => %{"payload_unavailable" => 1},
             "suppressed_candidate_ids_by_reason" => %{
               "payload_unavailable" => ["obs_1"]
             },
             "resource_blocking_dimension_counts" => %{"payload" => 1},
             "suppressed_candidate_ids_by_resource_blocking_dimension" => %{
               "payload" => ["obs_1"]
             },
             "suppressed_candidate_ids_by_scenario_id" => %{"leo_1" => ["obs_1"]},
             "suppressed_resource_source_quality_counts" => %{"operator_supplied" => 1},
             "suppressed_candidate_ids_by_resource_source_quality" => %{
               "operator_supplied" => ["obs_1"]
             },
             "suppressed_resource_trust_boundary_status_counts" => %{"declared" => 1},
             "suppressed_candidate_ids_by_resource_trust_boundary_status" => %{
               "declared" => ["obs_1"]
             },
             "invalid_candidate_input_count" => 0,
             "invalid_candidate_input_ids" => [],
             "invalid_resource_summary_input_count" => 0,
             "invalid_resource_summary_input_ids" => [],
             "duplicate_suppressed_candidate_id_count" => 0,
             "duplicate_suppressed_candidate_row_count" => 0,
             "review_rows" => [%{"id" => "obs_1", "suppressed_reason" => "payload_unavailable"}],
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_schedule_mutation",
               "operator_authority" => "not_granted_by_resource_filter_summary",
               "resource_state_propagation" => "not_performed"
             }
           } = summary = ResourceFilter.summary(report)

    assert OrbitalDynamics.resource_filter_summary(report) == summary
    assert ResourceFilter.summary(summary) == summary

    assert ResourceFilter.summary(summary, approval_policy: %{policy_bundle_id: "ignored"}) ==
             summary

    assert OrbitalDynamics.resource_filter_summary(summary) == summary

    atom_keyed_summary =
      Map.new(summary, fn {key, value} -> {String.to_atom(key), value} end)

    assert ResourceFilter.summary(atom_keyed_summary) == summary
    assert OrbitalDynamics.resource_filter_summary(atom_keyed_summary) == summary

    assert {:ok, %{"schema_contract" => "resource_filter_summary.v1"}} =
             Schema.validate_artifact(summary)

    stale_summary_model_limits = Map.put(summary, "model_limits", ["artifact_level_only"])

    assert {:error, stale_summary_model_limits_report} =
             Schema.validate_artifact(stale_summary_model_limits)

    assert Enum.any?(
             stale_summary_model_limits_report["errors"],
             &(&1["message"] == "must match resource filter report model limits")
           )

    stale_summary_count = Map.put(summary, "suppressed_candidate_count", 99)

    assert {:error, stale_summary_count_report} = Schema.validate_artifact(stale_summary_count)

    assert Enum.any?(
             stale_summary_count_report["errors"],
             &match?(
               %{
                 "path" => "$.suppressed_candidate_count",
                 "message" => "must equal review_rows count"
               },
               &1
             )
           )

    stale_summary_map =
      put_in(summary, ["suppressed_reason_counts", "payload_unavailable"], 99)

    assert {:error, stale_summary_map_report} = Schema.validate_artifact(stale_summary_map)

    assert Enum.any?(
             stale_summary_map_report["errors"],
             &match?(
               %{
                 "path" => "$.suppressed_reason_counts",
                 "message" => "must equal review_rows suppressed_reason counts"
               },
               &1
             )
           )

    assert ResourceFilter.summary(candidates, summaries,
             approval_policy: %{policy_bundle_id: "degraded_payload_guard_v1"}
           ) == summary

    expected_model_limits =
      ResourceFilter.capabilities()
      |> Map.fetch!(:known_limits)
      |> Enum.map(&to_string/1)

    assert model_limits == expected_model_limits

    assert {:ok, %{"schema_contract" => "resource_filter_report.v1"}} =
             Schema.validate_artifact(report)

    stale_report_assumptions = [
      {"resource_filter_policy_fields", ["min_downlink_margin"],
       "must match ResourceFilter policy fields"},
      {"resource_availability_aliases", %{"payload_available" => []},
       "must match ResourceFilter resource availability aliases"},
      {"resource_degraded_aliases", [], "must match ResourceFilter resource degraded aliases"},
      {"resource_margin_aliases", %{"storage_margin" => []},
       "must match ResourceFilter resource margin aliases"},
      {"resource_power_margin_source_aliases", [],
       "must match ResourceFilter resource power margin source aliases"},
      {"resource_availability_true_tokens", ["true"],
       "must match ResourceFilter resource availability true tokens"},
      {"resource_availability_false_tokens", ["false"],
       "must match ResourceFilter resource availability false tokens"},
      {"provider_direction_aliases", %{"dl" => "command"},
       "must match ResourceFilter provider direction aliases"},
      {"station_calendar_direction_aliases", %{"up" => "uplink"},
       "must match ResourceFilter station calendar direction aliases"},
      {"provider_result_map_value_keys", ["result"],
       "must match ResourceFilter provider result map value keys"},
      {"candidate_stable_identity_fields", ["scenario_id"],
       "must match ResourceFilter candidate stable identity fields"},
      {"station_calendar_id_list_fields", ["station_calendar_reservation_ids"],
       "must match ResourceFilter station calendar ID list fields"},
      {"suppression_reasons", ["payload_unavailable"],
       "must match ResourceFilter suppression reasons"},
      {"row_review_statuses", [], "must match ResourceFilter row review statuses"}
    ]

    for {field, value, message} <- stale_report_assumptions do
      stale_report = put_in(report, ["assumptions", field], value)

      assert {:error, stale_validation_report} = Schema.validate_artifact(stale_report)

      assert Enum.any?(
               stale_validation_report["errors"],
               &(&1["path"] == "$.assumptions.#{field}" and &1["message"] == message)
             )
    end

    compatible_report = drop_resource_filter_report_capability_assumptions(report)

    assert {:ok, %{"schema_contract" => "resource_filter_report.v1"}} =
             Schema.validate_artifact(compatible_report)

    assert {:ok, %{"schema_contract" => "resource_filter_report.v1"}} =
             report
             |> Map.delete("assumptions")
             |> Schema.validate_artifact()

    stale_report_model_limits = Map.put(report, "model_limits", ["artifact_level_only"])

    assert {:error, stale_report_model_limits_report} =
             Schema.validate_artifact(stale_report_model_limits)

    assert Enum.any?(
             stale_report_model_limits_report["errors"],
             &(&1["message"] == "must match resource filter report model limits")
           )

    invalid_review_status =
      put_in(
        report,
        ["suppressed_candidates", Access.at(0), "review_status"],
        "ready_without_review"
      )

    assert {:error, invalid_review_status_report} =
             Schema.validate_artifact(invalid_review_status)

    assert Enum.any?(
             invalid_review_status_report["errors"],
             &(&1["path"] == "$.suppressed_candidates[0].review_status")
           )

    invalid_kept_count = Map.put(report, "kept_candidate_count", 99)

    assert {:error, kept_count_report} = Schema.validate_artifact(invalid_kept_count)

    assert Enum.any?(
             kept_count_report["errors"],
             &(&1["path"] == "$.kept_candidate_count" and &1["message"] == "must equal 1")
           )

    invalid_quality_counts =
      Map.put(report, "suppressed_resource_source_quality_counts", %{"unknown" => 1})

    assert {:error, quality_count_report} = Schema.validate_artifact(invalid_quality_counts)

    assert Enum.any?(
             quality_count_report["errors"],
             &(&1["path"] == "$.suppressed_resource_source_quality_counts" and
                 &1["message"] ==
                   "must equal row-derived suppressed_resource_source_quality_counts")
           )

    invalid_quality_ids =
      Map.put(report, "suppressed_candidate_ids_by_resource_source_quality", %{
        "operator_supplied" => ["obs_2"]
      })

    assert {:error, quality_id_report} = Schema.validate_artifact(invalid_quality_ids)

    assert Enum.any?(
             quality_id_report["errors"],
             &(&1["path"] == "$.suppressed_candidate_ids_by_resource_source_quality" and
                 &1["message"] ==
                   "must equal row-derived suppressed_candidate_ids_by_resource_source_quality")
           )

    invalid_trust_counts =
      Map.put(report, "suppressed_resource_trust_boundary_status_counts", %{"missing" => 1})

    assert {:error, trust_count_report} = Schema.validate_artifact(invalid_trust_counts)

    assert Enum.any?(
             trust_count_report["errors"],
             &(&1["path"] == "$.suppressed_resource_trust_boundary_status_counts" and
                 &1["message"] ==
                   "must equal row-derived suppressed_resource_trust_boundary_status_counts")
           )

    invalid_trust_ids =
      Map.put(report, "suppressed_candidate_ids_by_resource_trust_boundary_status", %{
        "declared" => ["obs_2"]
      })

    assert {:error, trust_id_report} = Schema.validate_artifact(invalid_trust_ids)

    assert Enum.any?(
             trust_id_report["errors"],
             &(&1["path"] == "$.suppressed_candidate_ids_by_resource_trust_boundary_status" and
                 &1["message"] ==
                   "must equal row-derived suppressed_candidate_ids_by_resource_trust_boundary_status")
           )
  end

  test "suppresses matching candidates when duplicate resource summaries share a scope" do
    candidates = [
      %{
        id: :obs_1,
        type: :observe,
        scenario_id: :leo_1,
        spacecraft_id: :sat_1,
        target_id: :target_alpha,
        starts_at_s: 10.0,
        ends_at_s: 20.0
      },
      %{
        id: :obs_2,
        type: :observe,
        scenario_id: :leo_2,
        spacecraft_id: :sat_2,
        target_id: :target_beta,
        starts_at_s: 30.0,
        ends_at_s: 40.0
      }
    ]

    summaries = [
      %{
        spacecraft_id: :sat_1,
        payload_available: false,
        source_quality: :ops_console,
        provenance: %{trust_boundary: :operator_declared_resource_summary}
      },
      %{
        spacecraft_id: :sat_1,
        payload_available: true,
        source_quality: :partner_report,
        provenance: %{trust_boundary: :partner_resource_report}
      }
    ]

    {kept, report} = ResourceFilter.filter_candidates(candidates, summaries)

    assert Enum.map(kept, & &1["id"]) == ["obs_2"]

    assert %{
             "input_resource_summary_count" => 2,
             "valid_resource_summary_count" => 2,
             "resource_source_quality_counts" => %{
               "ops_console" => 1,
               "partner_report" => 1
             },
             "resource_trust_boundary_status_counts" => %{"declared" => 2},
             "suppressed_resource_source_quality_counts" => %{"ambiguous" => 1},
             "suppressed_candidate_ids_by_resource_source_quality" => %{"ambiguous" => ["obs_1"]},
             "suppressed_resource_trust_boundary_status_counts" => %{"ambiguous" => 1},
             "suppressed_candidate_ids_by_resource_trust_boundary_status" => %{
               "ambiguous" => ["obs_1"]
             },
             "kept_candidate_count" => 1,
             "suppressed_candidate_count" => 1,
             "suppressed_candidates" => [
               %{
                 "id" => "obs_1",
                 "type" => "observe",
                 "scenario_id" => "leo_1",
                 "spacecraft_id" => "sat_1",
                 "suppressed_reason" => "ambiguous_resource_summary",
                 "resource_blocking_dimension" => "resource_summary",
                 "ambiguous_resource_summary" => true,
                 "resource_summary_key" => "sat_1",
                 "resource_summary_count" => 2,
                 "resource_source_quality" => "ambiguous",
                 "resource_source_qualities" => ["ops_console", "partner_report"],
                 "resource_trust_boundary_status" => "ambiguous",
                 "resource_trust_boundary_statuses" => ["declared"],
                 "source_resource_summaries" => [
                   %{"payload_available" => false, "source_quality" => "ops_console"},
                   %{"payload_available" => true, "source_quality" => "partner_report"}
                 ]
               }
             ]
           } = report

    assert {:ok, %{"schema_contract" => "resource_filter_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_resource_filter_report(report)
    review_row = Enum.find(review["rows"], &(&1["review_type"] == "resource_suppression"))

    assert %{
             "activity_id" => "obs_1",
             "suppressed_reason" => "ambiguous_resource_summary",
             "resource_blocking_dimension" => "resource_summary",
             "source_resource_suppression" => %{
               "ambiguous_resource_summary" => true,
               "resource_summary_count" => 2
             }
           } = review_row

    manifest = CadenceImport.from_resource_filter_report(report)

    manifest_row =
      Enum.find(manifest["rows"], &(&1["import_action"] == "review_resource_suppression"))

    assert %{
             "activity_id" => "obs_1",
             "suppressed_reason" => "ambiguous_resource_summary",
             "resource_blocking_dimension" => "resource_summary",
             "source_resource_suppression" => %{
               "ambiguous_resource_summary" => true,
               "resource_summary_count" => 2
             }
           } = manifest_row

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "suppresses candidates below externally supplied thermal margin policy" do
    candidates = [
      %{
        id: :obs_hot,
        type: :observe,
        scenario_id: :leo_1,
        spacecraft_id: :sat_hot,
        target_id: :target_alpha,
        starts_at_s: 10.0,
        ends_at_s: 20.0
      },
      %{
        id: :dl_hot,
        type: :downlink,
        scenario_id: :leo_1,
        spacecraft_id: :sat_hot,
        ground_station_id: :equator_prime,
        starts_at_s: 30.0,
        ends_at_s: 60.0
      },
      %{
        id: :obs_nominal,
        type: :observe,
        scenario_id: :leo_1,
        spacecraft_id: :sat_nominal,
        target_id: :target_beta,
        starts_at_s: 70.0,
        ends_at_s: 80.0
      }
    ]

    summaries = [
      %{
        spacecraft_id: :sat_hot,
        thermal_margin_c: 1.5,
        payload_available: true,
        antenna_available: true,
        source_quality: :operator_supplied,
        provenance: %{trust_boundary: :operator_declared_resource_summary}
      },
      %{
        spacecraft_id: :sat_nominal,
        thermal_margin_c: 5.0,
        payload_available: true
      }
    ]

    {kept, report} =
      ResourceFilter.filter_candidates(candidates, summaries,
        policy: %{min_activity_thermal_margin_c: 2.0}
      )

    assert Enum.map(kept, & &1["id"]) == ["obs_nominal"]

    rows = Map.new(report["suppressed_candidates"], &{&1["id"], &1})

    assert %{
             "suppressed_reason" => "thermal_margin_below_policy",
             "resource_blocking_dimension" => "thermal",
             "thermal_margin_c" => 1.5
           } = rows["obs_hot"]

    assert %{
             "suppressed_reason" => "thermal_margin_below_policy",
             "resource_blocking_dimension" => "thermal",
             "thermal_margin_c" => 1.5
           } = rows["dl_hot"]

    assert {:ok, %{"schema_contract" => "resource_filter_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_resource_filter_report(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert Enum.any?(
             review["rows"],
             &(get_in(&1, ["source_resource_suppression", "thermal_margin_c"]) == 1.5 and
                 &1["resource_blocking_dimension"] == "thermal")
           )

    manifest = CadenceImport.from_resource_filter_report(report)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    assert Enum.any?(
             manifest["rows"],
             &(get_in(&1, ["source_resource_suppression", "thermal_margin_c"]) == 1.5 and
                 &1["resource_blocking_dimension"] == "thermal")
           )
  end

  test "filters all spacecraft candidates when resource summary marks spacecraft unavailable" do
    candidates = [
      %{
        id: :obs_sat_down,
        type: :observe,
        scenario_id: :leo_1,
        spacecraft_id: :sat_down,
        target_id: :target_alpha,
        starts_at_s: 10.0,
        ends_at_s: 20.0
      },
      %{
        id: :dl_sat_down,
        type: :downlink,
        scenario_id: :leo_1,
        spacecraft_id: :sat_down,
        ground_station_id: :equator_prime,
        starts_at_s: 30.0,
        ends_at_s: 60.0
      },
      %{
        id: :obs_sat_alias,
        type: :observe,
        scenario_id: :leo_2,
        spacecraft_id: :sat_alias_down,
        target_id: :target_beta,
        starts_at_s: 15.0,
        ends_at_s: 25.0
      },
      %{
        id: :obs_sat_nominal,
        type: :observe,
        scenario_id: :leo_3,
        spacecraft_id: :sat_nominal,
        target_id: :target_gamma,
        starts_at_s: 20.0,
        ends_at_s: 30.0
      }
    ]

    summaries = [
      %{
        spacecraft_id: :sat_down,
        spacecraft_status: "Down",
        payload_status: "enabled",
        antenna_status: "available",
        source_quality: :operator_supplied,
        provenance: %{trust_boundary: :operator_resource_health}
      },
      %{
        spacecraft_id: :sat_alias_down,
        spacecraft_availability: "maintenance",
        source_quality: :operator_supplied
      },
      %{spacecraft_id: :sat_nominal, spacecraft_status: "operational", payload_status: "enabled"}
    ]

    {kept, report} =
      ResourceFilter.filter_candidates(candidates, summaries,
        approval_policy: %{policy_bundle_id: "degraded_payload_guard_v1"}
      )

    assert Enum.map(kept, & &1["id"]) == ["obs_sat_nominal"]

    rows = Map.new(report["suppressed_candidates"], &{&1["id"], &1})

    assert %{
             "suppressed_reason" => "spacecraft_unavailable",
             "resource_blocking_dimension" => "spacecraft_health",
             "spacecraft_id" => "sat_down",
             "spacecraft_available" => false,
             "payload_available" => true,
             "antenna_available" => true,
             "resource_trust_boundary" => "operator_resource_health",
             "resource_trust_boundary_status" => "declared"
           } = rows["obs_sat_down"]

    assert %{
             "suppressed_reason" => "spacecraft_unavailable",
             "resource_blocking_dimension" => "spacecraft_health",
             "spacecraft_id" => "sat_down",
             "spacecraft_available" => false
           } = rows["dl_sat_down"]

    assert %{
             "suppressed_reason" => "spacecraft_unavailable",
             "resource_blocking_dimension" => "spacecraft_health",
             "spacecraft_id" => "sat_alias_down",
             "spacecraft_available" => false
           } = rows["obs_sat_alias"]

    assert {:ok, %{"schema_contract" => "resource_filter_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_resource_filter_report(report)
    review_rows = Map.new(review["rows"], &{&1["activity_id"], &1})

    assert %{
             "resource_blocking_dimension" => "spacecraft_health",
             "spacecraft_available" => false,
             "reason" => "resource filter suppressed candidate: spacecraft_unavailable",
             "source_resource_suppression" => %{
               "suppressed_reason" => "spacecraft_unavailable",
               "spacecraft_available" => false
             }
           } = review_rows["obs_sat_down"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    manifest = CadenceImport.from_resource_filter_report(report)
    import_rows = Map.new(manifest["rows"], &{&1["activity_id"], &1})

    assert %{
             "import_action" => "review_resource_suppression",
             "resource_blocking_dimension" => "spacecraft_health",
             "spacecraft_available" => false,
             "suppressed_reason" => "spacecraft_unavailable"
           } = import_rows["dl_sat_down"]

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "filters command uplink and health-check contacts when antenna is unavailable" do
    candidates = [
      %{
        id: :cmd_upload,
        type: :command,
        scenario_id: :leo_1,
        spacecraft_id: :sat_a,
        ground_station_id: :equator_prime,
        starts_at_s: 10.0,
        ends_at_s: 20.0,
        command_success_factor: 0.8
      },
      %{
        id: :uplink_contact,
        type: :planned_contact,
        direction: :uplink,
        scenario_id: :leo_1,
        spacecraft_id: :sat_a,
        ground_station_id: :equator_prime,
        starts_at_s: 30.0,
        ends_at_s: 50.0
      },
      %{
        id: :health_check,
        type: :health_check,
        scenario_id: :leo_1,
        spacecraft_id: :sat_a,
        ground_station_id: :equator_prime,
        starts_at_s: 60.0,
        ends_at_s: 70.0
      },
      %{
        id: :payload_obs,
        type: :observe,
        scenario_id: :leo_1,
        spacecraft_id: :sat_a,
        target_id: :target_alpha,
        starts_at_s: 80.0,
        ends_at_s: 100.0
      }
    ]

    summaries = [
      %{
        spacecraft_id: :sat_a,
        payload_status: "available",
        antenna_status: "outage",
        battery_capacity_wh: 1200.0,
        battery_energy_used_wh: 936.0,
        battery_state_of_charge: 0.22,
        mode: :degraded_payload,
        source_quality: :operator_supplied,
        provenance: %{trust_boundary: :operator_resource_health}
      }
    ]

    {kept, report} =
      ResourceFilter.filter_candidates(
        candidates,
        summaries,
        approval_policy: %{policy_bundle_id: "mission_ops_escalation_v1"}
      )

    assert Enum.map(kept, & &1["id"]) == ["payload_obs"]

    rows = Map.new(report["suppressed_candidates"], &{&1["id"], &1})

    assert %{
             "suppressed_reason" => "antenna_unavailable",
             "resource_blocking_dimension" => "antenna",
             "direction" => "command",
             "command_success_factor" => 0.8,
             "antenna_available" => false,
             "battery_capacity_wh" => 1200.0,
             "battery_energy_used_wh" => 936.0,
             "battery_state_of_charge" => 0.22,
             "mode" => "degraded_payload",
             "approval_status" => "operator_review_required",
             "approval_requirements" => [
               %{
                 "action" => "review_suppressed_contact",
                 "requirement_type" => "command_review",
                 "activity_context" => %{
                   "direction" => "command",
                   "command_success_factor" => 0.8,
                   "resource_blocking_dimension" => "antenna",
                   "battery_state_of_charge" => 0.22,
                   "mode" => "degraded_payload"
                 }
               }
             ],
             "approval_rule_matches" => [
               %{
                 "rule_id" => "command_authority_escalation",
                 "required_authority" => "command_authority"
               }
             ]
           } = rows["cmd_upload"]

    assert %{
             "suppressed_reason" => "antenna_unavailable",
             "resource_blocking_dimension" => "antenna",
             "direction" => "uplink",
             "antenna_available" => false,
             "approval_status" => "operator_review_required",
             "approval_requirements" => [
               %{
                 "action" => "review_suppressed_contact",
                 "requirement_type" => "command_review",
                 "activity_context" => %{
                   "direction" => "uplink",
                   "resource_blocking_dimension" => "antenna"
                 }
               }
             ]
           } = rows["uplink_contact"]

    assert %{
             "suppressed_reason" => "antenna_unavailable",
             "resource_blocking_dimension" => "antenna",
             "direction" => "health_check",
             "antenna_available" => false,
             "approval_status" => "operator_review_required",
             "approval_requirements" => [
               %{
                 "action" => "review_suppressed_contact",
                 "requirement_type" => "health_check_review",
                 "activity_context" => %{
                   "direction" => "health_check",
                   "resource_blocking_dimension" => "antenna"
                 }
               }
             ]
           } = rows["health_check"]

    review = OperatorReview.from_resource_filter_report(report)
    review_rows = Map.new(review["rows"], &{&1["activity_id"], &1})

    assert %{
             "required_operator_action" => "review_suppressed_contact",
             "requirement_type" => "command_review",
             "required_authority" => "command_authority",
             "direction" => "command",
             "command_success_factor" => 0.8,
             "battery_state_of_charge" => 0.22,
             "mode" => "degraded_payload",
             "source_resource_suppression" => %{
               "suppressed_reason" => "antenna_unavailable",
               "approval_requirements" => [
                 %{"requirement_type" => "command_review"}
               ],
               "command_success_factor" => 0.8,
               "battery_state_of_charge" => 0.22,
               "mode" => "degraded_payload"
             }
           } = review_rows["cmd_upload"]

    manifest = CadenceImport.from_resource_filter_report(report)
    import_rows = Map.new(manifest["rows"], &{&1["activity_id"], &1})

    assert %{
             "import_action" => "review_resource_suppression",
             "suppressed_reason" => "antenna_unavailable",
             "resource_blocking_dimension" => "antenna",
             "direction" => "uplink",
             "approval_requirements" => [
               %{"requirement_type" => "command_review"}
             ],
             "source_resource_suppression" => %{
               "approval_requirements" => [
                 %{"requirement_type" => "command_review"}
               ]
             }
           } = import_rows["uplink_contact"]

    assert {:ok, %{"schema_contract" => "resource_filter_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "preserves malformed candidate inputs for resource review" do
    candidates = [
      %{
        id: :obs_1,
        type: :observe,
        scenario_id: :leo_1,
        target_id: :target_alpha,
        starts_at_s: 10.0,
        ends_at_s: 20.0
      },
      {:bad_resource_candidate, :not_a_map}
    ]

    {kept, report} =
      ResourceFilter.filter_candidates(candidates, [],
        approval_policy: %{policy_bundle_id: "degraded_payload_guard_v1"}
      )

    assert Enum.map(kept, & &1["id"]) == ["obs_1"]

    assert %{
             "input_candidate_count" => 2,
             "kept_candidate_count" => 1,
             "suppressed_candidate_count" => 1,
             "invalid_candidate_input_count" => 1,
             "invalid_candidate_input_ids" => ["missing_candidate_id"],
             "suppressed_candidates" => [
               %{
                 "id" => "missing_candidate_id",
                 "type" => "invalid_candidate_input",
                 "scenario_id" => "missing_scenario_id",
                 "suppressed_reason" => "invalid_candidate_input",
                 "invalid_candidate_input" => true,
                 "invalid_candidate_input_reason" => "invalid_candidate_shape",
                 "source_candidate" => %{
                   "raw_input" => "{:bad_resource_candidate, :not_a_map}"
                 }
               }
             ]
           } = report

    invalid_candidate = List.first(report["suppressed_candidates"])

    assert [
             %{
               "activity_id" => "missing_candidate_id",
               "activity_type" => "invalid_candidate_input",
               "action" => "review_invalid_resource_filter_input",
               "policy_classification" => "operator_review_required"
             }
           ] = invalid_candidate["approval_requirements"]

    assert [
             %{
               "rule_id" => "invalid_resource_filter_candidate_input_review",
               "classification" => "operator_review_required"
             }
           ] = invalid_candidate["approval_rule_matches"]

    assert {:ok, %{"schema_contract" => "resource_filter_report.v1"}} =
             Schema.validate_artifact(report)

    invalid_input_count = Map.put(report, "invalid_candidate_input_count", 0)

    assert {:error, invalid_input_count_report} = Schema.validate_artifact(invalid_input_count)

    assert Enum.any?(
             invalid_input_count_report["errors"],
             &(&1["path"] == "$.invalid_candidate_input_count" and
                 &1["message"] == "must equal 1")
           )

    invalid_input_ids = Map.put(report, "invalid_candidate_input_ids", [])

    assert {:error, invalid_input_id_report} = Schema.validate_artifact(invalid_input_ids)

    assert Enum.any?(
             invalid_input_id_report["errors"],
             &(&1["path"] == "$.invalid_candidate_input_ids" and
                 &1["message"] == "must equal row-derived invalid_candidate_input_ids")
           )

    review = OperatorReview.from_resource_filter_report(report)

    assert %{
             "review_type" => "resource_suppression",
             "required_operator_action" => "review_suppressed_candidate",
             "invalid_candidate_input" => true,
             "invalid_candidate_input_reason" => "invalid_candidate_shape",
             "source_candidate" => %{"raw_input" => "{:bad_resource_candidate, :not_a_map}"},
             "policy_bundle_id" => "degraded_payload_guard_v1",
             "rule_id" => "invalid_resource_filter_candidate_input_review",
             "source_policy_decision" => %{"classification" => "operator_review_required"},
             "source_resource_suppression" => %{"invalid_candidate_input" => true}
           } = List.first(review["rows"])

    manifest = CadenceImport.from_resource_filter_report(report)

    assert %{
             "import_action" => "review_resource_suppression",
             "invalid_candidate_input" => true,
             "invalid_candidate_input_reason" => "invalid_candidate_shape",
             "source_candidate" => %{"raw_input" => "{:bad_resource_candidate, :not_a_map}"},
             "policy_bundle_id" => "degraded_payload_guard_v1",
             "rule_id" => "invalid_resource_filter_candidate_input_review",
             "source_policy_decision" => %{"classification" => "operator_review_required"},
             "source_resource_suppression" => %{"invalid_candidate_input" => true}
           } = List.first(manifest["rows"])
  end

  test "preserves malformed map candidate inputs for resource review" do
    candidates = [
      %{
        id: :obs_1,
        type: :observe,
        scenario_id: :leo_1,
        starts_at_s: 10.0,
        ends_at_s: 20.0
      },
      %{
        type: :observe,
        scenario_id: :leo_1,
        starts_at_s: 30.0,
        ends_at_s: 40.0,
        source_station_calendar_entry: %{id: :provider_entry_only},
        source_station_calendar_overlaps: [%{id: :provider_entry_only}]
      },
      %{
        id: :missing_type,
        scenario_id: :leo_1,
        starts_at_s: 50.0,
        ends_at_s: 60.0
      }
    ]

    {kept, report} = ResourceFilter.filter_candidates(candidates, [])

    assert Enum.map(kept, & &1["id"]) == ["obs_1"]

    assert %{
             "input_candidate_count" => 3,
             "kept_candidate_count" => 1,
             "suppressed_candidate_count" => 2,
             "invalid_candidate_input_count" => 2,
             "invalid_candidate_input_ids" => ["missing_candidate_id:2", "missing_type"],
             "suppressed_candidates" => suppressed
           } = report

    assert %{
             "id" => "missing_candidate_id:2",
             "type" => "observe",
             "suppressed_reason" => "invalid_candidate_input",
             "invalid_candidate_input" => true,
             "invalid_candidate_input_reason" => "missing_candidate_id",
             "station_calendar_entry_id" => "provider_entry_only",
             "source_station_calendar_entry" => %{"id" => "provider_entry_only"},
             "source_candidate" => %{"type" => "observe"}
           } = Enum.find(suppressed, &(&1["id"] == "missing_candidate_id:2"))

    assert %{
             "id" => "missing_type",
             "type" => "invalid_candidate_input",
             "suppressed_reason" => "invalid_candidate_input",
             "invalid_candidate_input" => true,
             "invalid_candidate_input_reason" => "missing_candidate_type",
             "source_candidate" => %{"id" => "missing_type"}
           } = Enum.find(suppressed, &(&1["id"] == "missing_type"))

    review = OperatorReview.from_resource_filter_report(report)
    import = CadenceImport.from_resource_filter_report(report)

    assert Enum.any?(
             review["rows"],
             &(&1["subject_id"] == "missing_candidate_id:2" and
                 &1["invalid_candidate_input_reason"] == "missing_candidate_id" and
                 &1["station_calendar_entry_id"] == "provider_entry_only" and
                 get_in(&1, ["source_station_calendar_entry", "id"]) == "provider_entry_only")
           )

    assert Enum.any?(
             import["rows"],
             &(&1["subject_id"] == "missing_type" and
                 &1["invalid_candidate_input_reason"] == "missing_candidate_type")
           )

    assert Enum.any?(
             import["rows"],
             &(&1["subject_id"] == "missing_candidate_id:2" and
                 &1["station_calendar_entry_id"] == "provider_entry_only" and
                 get_in(&1, ["source_station_calendar_entry", "id"]) == "provider_entry_only")
           )

    assert {:ok, %{"schema_contract" => "resource_filter_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "preserves malformed resource filter stable identity fields for review" do
    candidates = [
      %{
        id: "bad candidate id",
        type: :observe,
        scenario_id: :leo_1,
        target_id: :target_alpha,
        starts_at_s: 10.0,
        ends_at_s: 20.0
      },
      %{
        id: :bad_scenario,
        type: :observe,
        scenario_id: "bad scenario id",
        target_id: :target_alpha,
        starts_at_s: 30.0,
        ends_at_s: 40.0
      },
      %{
        id: :bad_source_window,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        source_window_id: "bad source window",
        station_calendar_overlap_entry_ids: [
          :overlap_1,
          "bad overlap id",
          %{id: :overlap_2},
          %{id: "bad nested overlap id"}
        ],
        starts_at_s: 50.0,
        ends_at_s: 60.0
      }
    ]

    {_kept, report} = ResourceFilter.filter_candidates(candidates, [])

    assert %{
             "input_candidate_count" => 3,
             "kept_candidate_count" => 0,
             "suppressed_candidate_count" => 3,
             "suppressed_candidates" => suppressed
           } = report

    assert %{
             "id" => "invalid_candidate_id:1",
             "invalid_candidate_input_reason" => "invalid_candidate_id",
             "source_candidate" => %{"id" => "bad candidate id"}
           } = Enum.find(suppressed, &(&1["id"] == "invalid_candidate_id:1"))

    bad_scenario = Enum.find(suppressed, &(&1["id"] == "bad_scenario"))

    assert %{
             "scenario_id" => "missing_scenario_id:bad_scenario",
             "invalid_candidate_input_reason" => "invalid_scenario_id",
             "source_candidate" => %{"scenario_id" => "bad scenario id"}
           } = bad_scenario

    bad_source_window = Enum.find(suppressed, &(&1["id"] == "bad_source_window"))

    assert %{
             "invalid_candidate_input_reason" => "invalid_source_window_id",
             "source_candidate" => %{"source_window_id" => "bad source window"}
           } = bad_source_window

    refute Map.has_key?(bad_source_window, "source_window_id")
    assert bad_source_window["station_calendar_overlap_entry_ids"] == ["overlap_1", "overlap_2"]

    assert {:ok, %{"schema_contract" => "resource_filter_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_resource_filter_report(report)

    assert Enum.any?(
             review["rows"],
             &(&1["subject_id"] == "bad_source_window" and
                 &1["invalid_candidate_input_reason"] == "invalid_source_window_id" and
                 get_in(&1, ["source_candidate", "source_window_id"]) == "bad source window")
           )

    manifest = CadenceImport.from_resource_filter_report(report)

    assert Enum.any?(
             manifest["rows"],
             &(&1["subject_id"] == "bad_scenario" and
                 &1["invalid_candidate_input_reason"] == "invalid_scenario_id" and
                 get_in(&1, ["source_candidate", "scenario_id"]) == "bad scenario id")
           )
  end

  test "applies spacecraft-specific summaries and threshold policy" do
    candidates = [
      %{
        id: :obs_1,
        type: :observe,
        scenario_id: :leo_1,
        starts_at_s: 10.0,
        ends_at_s: 20.0
      },
      %{
        id: :dl_2,
        type: :downlink,
        scenario_id: :leo_2,
        ground_station_id: :equator_prime,
        starts_at_s: 30.0,
        ends_at_s: 60.0
      }
    ]

    summaries = [
      %{
        spacecraft_id: :leo_1,
        payload_available: true,
        power_margin: 0.1,
        storage_margin: 0.8
      },
      %{
        spacecraft_id: :leo_2,
        antenna_available: true,
        downlink_margin: 0.05
      }
    ]

    {_kept, report} =
      ResourceFilter.filter_candidates(candidates, summaries,
        policy: %{
          min_observe_power_margin: 0.2,
          min_downlink_margin: 0.2
        }
      )

    assert report["policy"] == %{
             "min_observe_power_margin" => 0.2,
             "min_downlink_margin" => 0.2
           }

    assert Enum.map(report["suppressed_candidates"], &{&1["id"], &1["suppressed_reason"]}) == [
             {"obs_1", "power_margin_below_observe_policy"},
             {"dl_2", "downlink_margin_below_policy"}
           ]

    assert Enum.map(
             report["suppressed_candidates"],
             &{&1["id"], &1["resource_blocking_dimension"]}
           ) == [
             {"obs_1", "power"},
             {"dl_2", "downlink"}
           ]
  end

  test "normalizes numeric string summary policy and candidate timing fields" do
    candidates = [
      %{
        id: :provider_obs,
        type: :observe,
        scenario_id: :leo_1,
        start_s: "10.0",
        end_s: "20.0"
      }
    ]

    summaries = [
      %{
        spacecraft_id: :leo_1,
        payload_available: true,
        power_margin: "0.10",
        storage_capacity_mb: "100.0",
        storage_used_mb: "25.0"
      }
    ]

    {_kept, report} =
      ResourceFilter.filter_candidates(candidates, summaries,
        policy: %{min_observe_power_margin: "0.2"}
      )

    assert report["policy"] == %{"min_observe_power_margin" => 0.2}

    assert [
             %{
               "id" => "provider_obs",
               "starts_at_s" => 10.0,
               "ends_at_s" => 20.0,
               "suppressed_reason" => "power_margin_below_observe_policy",
               "power_margin" => 0.1
             }
           ] = report["suppressed_candidates"]

    assert {:ok, %{"schema_contract" => "resource_filter_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "filters planned-contact command and downlink rows when antenna is unavailable" do
    candidates = [
      %{
        id: :planned_downlink,
        type: :planned_contact,
        direction: :downlink,
        scenario_id: :leo_1,
        spacecraft_id: :sat_contact,
        ground_station_id: :equator_prime
      },
      %{
        id: :planned_tracking,
        type: :planned_contact,
        direction: :tracking,
        scenario_id: :leo_1,
        spacecraft_id: :sat_contact,
        ground_station_id: :equator_prime
      },
      %{
        id: :planned_command,
        type: :planned_contact,
        direction: :command,
        scenario_id: :leo_1,
        spacecraft_id: :sat_contact,
        ground_station_id: :equator_prime
      }
    ]

    {kept, report} =
      ResourceFilter.filter_candidates(
        candidates,
        [%{spacecraft_id: :sat_contact, antenna_available: false}],
        approval_policy: %{policy_bundle_id: "degraded_payload_guard_v1"}
      )

    assert Enum.map(kept, & &1["id"]) == []

    rows = Map.new(report["suppressed_candidates"], &{&1["id"], &1})

    assert %{
             "type" => "planned_contact",
             "direction" => "downlink",
             "suppressed_reason" => "antenna_unavailable",
             "resource_blocking_dimension" => "antenna",
             "approval_status" => "blocked_by_policy",
             "approval_requirements" => [
               %{
                 "action" => "review_suppressed_contact",
                 "requirement_type" => "contact_schedule_change",
                 "activity_context" => %{"resource_blocking_dimension" => "antenna"}
               }
             ],
             "approval_rule_matches" => [
               %{"rule_id" => "antenna_unavailable_contact_block"}
             ]
           } = rows["planned_downlink"]

    assert %{
             "type" => "planned_contact",
             "direction" => "tracking",
             "suppressed_reason" => "antenna_unavailable",
             "resource_blocking_dimension" => "antenna",
             "approval_status" => "blocked_by_policy",
             "approval_rule_matches" => [
               %{"rule_id" => "antenna_unavailable_contact_block"}
             ]
           } = rows["planned_tracking"]

    assert %{
             "type" => "planned_contact",
             "direction" => "command",
             "suppressed_reason" => "antenna_unavailable",
             "resource_blocking_dimension" => "antenna",
             "approval_status" => "blocked_by_policy",
             "approval_rule_matches" => [
               %{"rule_id" => "antenna_unavailable_contact_block"}
             ]
           } = rows["planned_command"]

    assert {:ok, %{"schema_contract" => "resource_filter_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "passes suppressed reason and resource blocking dimension into approval policy evidence" do
    candidates = [
      %{
        id: :planned_downlink,
        type: :planned_contact,
        direction: :downlink,
        scenario_id: :leo_1,
        spacecraft_id: :sat_contact,
        ground_station_id: :equator_prime
      }
    ]

    approval_policy = %{
      action_rules: [
        %{
          id: :antenna_resource_suppression_review,
          suppressed_reasons: [:antenna_unavailable],
          resource_blocking_dimensions: [:antenna],
          classification: :operator_review_required,
          reason: "antenna resource suppressions require ground-network review"
        }
      ]
    }

    {_kept, report} =
      ResourceFilter.filter_candidates(
        candidates,
        [%{spacecraft_id: :sat_contact, antenna_available: false}],
        approval_policy: approval_policy
      )

    assert %{
             "id" => "planned_downlink",
             "suppressed_reason" => "antenna_unavailable",
             "resource_blocking_dimension" => "antenna",
             "approval_status" => "operator_review_required",
             "approval_requirements" => [
               %{
                 "activity_context" => %{
                   "suppressed_reason" => "antenna_unavailable",
                   "resource_blocking_dimension" => "antenna"
                 }
               }
             ],
             "approval_rule_matches" => [
               %{
                 "rule_id" => "antenna_resource_suppression_review",
                 "suppressed_reason" => "antenna_unavailable",
                 "resource_blocking_dimension" => "antenna"
               }
             ]
           } = hd(report["suppressed_candidates"])

    assert {:ok, %{"schema_contract" => "resource_filter_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "filters provider contact downlinks with station id aliases" do
    candidates = [
      %{
        id: :provider_downlink,
        type: :contact,
        direction: :downlink,
        scenario_id: :leo_1,
        spacecraft_id: :sat_contact,
        station_id: :equator_prime
      },
      %{
        id: :provider_tracking,
        type: :contact,
        direction: :tracking,
        scenario_id: :leo_1,
        spacecraft_id: :sat_contact,
        station_id: :equator_prime
      },
      %{
        id: :provider_command,
        type: :contact,
        direction: :command,
        scenario_id: :leo_1,
        spacecraft_id: :sat_contact,
        station_id: :equator_prime
      }
    ]

    {kept, report} =
      ResourceFilter.filter_candidates(
        candidates,
        [%{spacecraft_id: :sat_contact, antenna_available: false}],
        approval_policy: %{policy_bundle_id: "degraded_payload_guard_v1"}
      )

    assert Enum.map(kept, & &1["id"]) == []

    rows = Map.new(report["suppressed_candidates"], &{&1["id"], &1})

    assert %{
             "type" => "contact",
             "direction" => "downlink",
             "ground_station_id" => "equator_prime",
             "suppressed_reason" => "antenna_unavailable",
             "resource_blocking_dimension" => "antenna",
             "approval_requirements" => [
               %{
                 "action" => "review_suppressed_contact",
                 "requirement_type" => "contact_schedule_change",
                 "activity_context" => %{
                   "direction" => "downlink",
                   "ground_station_id" => "equator_prime",
                   "resource_blocking_dimension" => "antenna"
                 }
               }
             ]
           } = rows["provider_downlink"]

    assert %{
             "type" => "contact",
             "direction" => "tracking",
             "ground_station_id" => "equator_prime",
             "suppressed_reason" => "antenna_unavailable",
             "resource_blocking_dimension" => "antenna",
             "approval_requirements" => [
               %{
                 "action" => "review_suppressed_contact",
                 "requirement_type" => "contact_schedule_change",
                 "activity_context" => %{
                   "direction" => "tracking",
                   "ground_station_id" => "equator_prime",
                   "resource_blocking_dimension" => "antenna"
                 }
               }
             ]
           } = rows["provider_tracking"]

    assert %{
             "type" => "contact",
             "direction" => "command",
             "ground_station_id" => "equator_prime",
             "suppressed_reason" => "antenna_unavailable",
             "resource_blocking_dimension" => "antenna",
             "approval_requirements" => [
               %{
                 "action" => "review_suppressed_contact",
                 "requirement_type" => "command_review",
                 "activity_context" => %{
                   "direction" => "command",
                   "ground_station_id" => "equator_prime",
                   "resource_blocking_dimension" => "antenna"
                 }
               }
             ]
           } = rows["provider_command"]

    assert {:ok, %{"schema_contract" => "resource_filter_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_resource_filter_report(report)

    review_rows = Map.new(review["rows"], &{&1["activity_id"], &1})

    assert %{
             "activity_type" => "contact",
             "required_operator_action" => "review_suppressed_contact",
             "ground_station_id" => "equator_prime",
             "source_resource_suppression" => %{"ground_station_id" => "equator_prime"}
           } = review_rows["provider_downlink"]

    assert %{
             "activity_type" => "contact",
             "direction" => "tracking",
             "required_operator_action" => "review_suppressed_contact",
             "ground_station_id" => "equator_prime",
             "source_resource_suppression" => %{"ground_station_id" => "equator_prime"}
           } = review_rows["provider_tracking"]

    assert %{
             "activity_type" => "contact",
             "direction" => "command",
             "required_operator_action" => "review_suppressed_contact",
             "ground_station_id" => "equator_prime",
             "source_resource_suppression" => %{"ground_station_id" => "equator_prime"}
           } = review_rows["provider_command"]

    manifest = CadenceImport.from_resource_filter_report(report)

    import_rows = Map.new(manifest["rows"], &{&1["activity_id"], &1})

    assert %{
             "activity_type" => "contact",
             "import_action" => "review_resource_suppression",
             "source_review_action" => "review_suppressed_contact",
             "ground_station_id" => "equator_prime",
             "source_resource_suppression" => %{"ground_station_id" => "equator_prime"}
           } = import_rows["provider_downlink"]

    assert %{
             "activity_type" => "contact",
             "direction" => "tracking",
             "import_action" => "review_resource_suppression",
             "source_review_action" => "review_suppressed_contact",
             "ground_station_id" => "equator_prime",
             "source_resource_suppression" => %{"ground_station_id" => "equator_prime"}
           } = import_rows["provider_tracking"]

    assert %{
             "activity_type" => "contact",
             "direction" => "command",
             "import_action" => "review_resource_suppression",
             "source_review_action" => "review_suppressed_contact",
             "ground_station_id" => "equator_prime",
             "source_resource_suppression" => %{"ground_station_id" => "equator_prime"}
           } = import_rows["provider_command"]
  end

  test "infers provider-shaped station contacts without type for resource suppression" do
    candidates = [
      %{
        id: :provider_downlink,
        direction: "down",
        scenario_id: :leo_1,
        spacecraft_id: :sat_contact,
        station_id: :equator_prime,
        start_s: 20.0,
        end_s: 40.0,
        source_station_calendar_entry: %{
          id: :provider_downlink_calendar,
          directions: ["downlinking"]
        }
      },
      %{
        id: :provider_command_without_type,
        scenario_id: :leo_1,
        spacecraft_id: :sat_contact,
        station_id: :equator_prime,
        start_s: 50.0,
        end_s: 60.0,
        command_result: :accepted
      },
      %{
        id: :direction_only_command,
        direction: "s-band command",
        scenario_id: :leo_1,
        spacecraft_id: :sat_contact,
        station_id: :equator_prime,
        start_s: 65.0,
        end_s: 68.0,
        source_station_calendar_entry: %{
          id: :provider_command_calendar,
          directions: ["commands"]
        }
      },
      %{
        id: :direction_only_health_check,
        direction: :health_check,
        scenario_id: :leo_1,
        spacecraft_id: :sat_contact,
        station_id: :equator_prime,
        start_s: 68.0,
        end_s: 69.0
      },
      %{
        id: :provider_command,
        type: :contact,
        direction: :command,
        scenario_id: :leo_1,
        spacecraft_id: :sat_contact,
        station_id: :equator_prime,
        start_s: 70.0,
        end_s: 80.0
      }
    ]

    {kept, report} =
      ResourceFilter.filter_candidates(
        candidates,
        [%{spacecraft_id: :sat_contact, antenna_available: false}],
        approval_policy: %{policy_bundle_id: "mission_ops_escalation_v1"}
      )

    assert Enum.map(kept, & &1["id"]) == []

    rows = Map.new(report["suppressed_candidates"], &{&1["id"], &1})

    assert %{
             "id" => "provider_downlink",
             "type" => "downlink",
             "direction" => "downlink",
             "ground_station_id" => "equator_prime",
             "starts_at_s" => 20.0,
             "ends_at_s" => 40.0,
             "station_calendar_directions" => ["downlink"],
             "suppressed_reason" => "antenna_unavailable",
             "resource_blocking_dimension" => "antenna"
           } = rows["provider_downlink"]

    assert %{
             "id" => "provider_command_without_type",
             "type" => "invalid_candidate_input",
             "invalid_candidate_input_reason" => "missing_candidate_type",
             "suppressed_reason" => "invalid_candidate_input",
             "source_candidate" => %{"command_result" => "accepted"}
           } = rows["provider_command_without_type"]

    assert %{
             "id" => "direction_only_command",
             "type" => "planned_contact",
             "direction" => "command",
             "ground_station_id" => "equator_prime",
             "starts_at_s" => 65.0,
             "ends_at_s" => 68.0,
             "station_calendar_directions" => ["command"],
             "suppressed_reason" => "antenna_unavailable",
             "resource_blocking_dimension" => "antenna",
             "approval_requirements" => [
               %{
                 "action" => "review_suppressed_contact",
                 "requirement_type" => "command_review",
                 "activity_context" => %{
                   "direction" => "command",
                   "ground_station_id" => "equator_prime"
                 }
               }
             ],
             "approval_rule_matches" => [
               %{"rule_id" => "command_authority_escalation"}
             ]
           } = rows["direction_only_command"]

    assert %{
             "id" => "direction_only_health_check",
             "type" => "health_check",
             "direction" => "health_check",
             "ground_station_id" => "equator_prime",
             "starts_at_s" => 68.0,
             "ends_at_s" => 69.0,
             "suppressed_reason" => "antenna_unavailable",
             "resource_blocking_dimension" => "antenna",
             "approval_requirements" => [
               %{
                 "action" => "review_suppressed_contact",
                 "requirement_type" => "health_check_review",
                 "activity_context" => %{
                   "direction" => "health_check",
                   "ground_station_id" => "equator_prime"
                 }
               }
             ],
             "approval_rule_matches" => [
               %{
                 "rule_id" => "command_authority_escalation",
                 "required_authority" => "command_authority"
               }
             ]
           } = rows["direction_only_health_check"]

    assert %{
             "id" => "provider_command",
             "type" => "contact",
             "direction" => "command",
             "ground_station_id" => "equator_prime",
             "suppressed_reason" => "antenna_unavailable",
             "resource_blocking_dimension" => "antenna"
           } = rows["provider_command"]

    assert {:ok, %{"schema_contract" => "resource_filter_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "suppresses provider-shaped contacts with nested station identity" do
    candidates = [
      %{
        id: :provider_nested_downlink,
        scenario_id: :leo_1,
        spacecraft_id: :sat_contact,
        ground_station: %{ground_station_id: :equator_prime},
        start_s: 20.0,
        end_s: 40.0
      },
      %{
        id: :provider_nested_command,
        type: :contact,
        direction: :command,
        scenario_id: :leo_1,
        spacecraft_id: :sat_contact,
        station: %{id: :equator_prime},
        start_s: 50.0,
        end_s: 60.0
      }
    ]

    {kept, report} =
      ResourceFilter.filter_candidates(
        candidates,
        [%{spacecraft: %{id: :sat_contact}, antenna_available: false}]
      )

    assert kept == []

    rows = Map.new(report["suppressed_candidates"], &{&1["id"], &1})

    assert %{
             "type" => "downlink",
             "direction" => "downlink",
             "ground_station_id" => "equator_prime",
             "starts_at_s" => 20.0,
             "ends_at_s" => 40.0,
             "suppressed_reason" => "antenna_unavailable"
           } = rows["provider_nested_downlink"]

    assert %{
             "type" => "contact",
             "direction" => "command",
             "ground_station_id" => "equator_prime",
             "starts_at_s" => 50.0,
             "ends_at_s" => 60.0,
             "suppressed_reason" => "antenna_unavailable"
           } = rows["provider_nested_command"]

    assert {:ok, %{"schema_contract" => "resource_filter_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "accepts activity-type-only candidate inputs for resource suppression" do
    candidates = [
      %{
        id: :typed_observe,
        activity_type: :observe,
        scenario_id: :leo_1,
        spacecraft_id: :sat_payload,
        starts_at_s: 20.0,
        ends_at_s: 40.0
      },
      %{
        id: :blank_activity_type,
        activity_type: "",
        scenario_id: :leo_1,
        spacecraft_id: :sat_payload,
        starts_at_s: 50.0,
        ends_at_s: 60.0
      }
    ]

    {_kept, report} =
      ResourceFilter.filter_candidates(candidates, [
        %{spacecraft_id: :sat_payload, payload_available: false}
      ])

    rows = Map.new(report["suppressed_candidates"], &{&1["id"], &1})

    assert %{
             "id" => "typed_observe",
             "type" => "observe",
             "suppressed_reason" => "payload_unavailable",
             "resource_blocking_dimension" => "payload"
           } = rows["typed_observe"]

    assert %{
             "id" => "blank_activity_type",
             "type" => "invalid_candidate_input",
             "invalid_candidate_input_reason" => "missing_candidate_type",
             "source_candidate" => %{"activity_type" => ""}
           } = rows["blank_activity_type"]

    assert {:ok, %{"schema_contract" => "resource_filter_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "preserves station reservation match status through resource suppression handoffs" do
    candidates = [
      %{
        id: :reserved_downlink,
        type: :downlink,
        scenario_id: :leo_1,
        spacecraft_id: :sat_contact,
        ground_station_id: :equator_prime,
        starts_at_s: 30.0,
        ends_at_s: 60.0,
        station_availability: :reserved,
        station_contention_status: :reserved_overlap,
        station_reservation_id: :reservation_1,
        station_reserved_by: :network_partner,
        station_reservation_status: :confirmed,
        station_reservation_match_status: :overlap
      }
    ]

    {_kept, report} =
      ResourceFilter.filter_candidates(
        candidates,
        [%{spacecraft_id: :sat_contact, antenna_available: false}],
        approval_policy: %{policy_bundle_id: "degraded_payload_guard_v1"}
      )

    reservation_context = %{
      "station_availability" => "reserved",
      "station_contention_status" => "reserved_overlap",
      "station_reservation_id" => "reservation_1",
      "station_reserved_by" => "network_partner",
      "station_reservation_status" => "confirmed",
      "station_reservation_match_status" => "overlap"
    }

    assert [
             %{
               "id" => "reserved_downlink",
               "suppressed_reason" => "antenna_unavailable",
               "approval_requirements" => [
                 %{"activity_context" => activity_context}
               ]
             } = suppressed
           ] = report["suppressed_candidates"]

    assert Map.take(suppressed, Map.keys(reservation_context)) == reservation_context
    assert Map.take(activity_context, Map.keys(reservation_context)) == reservation_context

    review = OperatorReview.from_resource_filter_report(report)
    [review_row] = review["rows"]

    assert Map.take(review_row, Map.keys(reservation_context)) == reservation_context

    manifest = CadenceImport.from_resource_filter_report(report)
    [import_row] = manifest["rows"]

    assert Map.take(import_row, Map.keys(reservation_context)) == reservation_context

    assert {:ok, %{"schema_contract" => "resource_filter_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "flattens nested station calendar entry id through resource suppression handoffs" do
    candidates = [
      %{
        id: :downlink_nested_calendar,
        type: :downlink,
        scenario_id: :leo_1,
        spacecraft_id: :sat_contact,
        ground_station_id: :equator_prime,
        starts_at_s: 30.0,
        ends_at_s: 60.0,
        source_station_calendar_entry: %{
          id: :provider_entry_only,
          provenance: %{trust_boundary: :ground_partner_api}
        },
        source_station_calendar_overlaps: [
          %{id: :provider_entry_only}
        ]
      }
    ]

    {_kept, report} =
      ResourceFilter.filter_candidates(
        candidates,
        [%{spacecraft_id: :sat_contact, antenna_available: false}],
        approval_policy: %{policy_bundle_id: "degraded_payload_guard_v1"}
      )

    assert [
             %{
               "id" => "downlink_nested_calendar",
               "station_calendar_entry_id" => "provider_entry_only",
               "source_station_calendar_entry" => %{"id" => "provider_entry_only"},
               "approval_requirements" => [
                 %{
                   "activity_context" => %{
                     "station_calendar_entry_id" => "provider_entry_only",
                     "source_station_calendar_entry" => %{"id" => "provider_entry_only"}
                   }
                 }
               ]
             }
           ] = report["suppressed_candidates"]

    review = OperatorReview.from_resource_filter_report(report)
    [review_row] = review["rows"]

    assert %{
             "station_calendar_entry_id" => "provider_entry_only",
             "source_station_calendar_entry" => %{"id" => "provider_entry_only"}
           } = review_row

    manifest = CadenceImport.from_resource_filter_report(report)
    [import_row] = manifest["rows"]

    assert %{
             "station_calendar_entry_id" => "provider_entry_only",
             "source_station_calendar_entry" => %{"id" => "provider_entry_only"}
           } = import_row

    assert {:ok, %{"schema_contract" => "resource_filter_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "falls back to scenario id when candidate spacecraft id does not match summary" do
    {_kept, report} =
      ResourceFilter.filter_candidates(
        [
          %{
            id: :obs_1,
            type: :observe,
            scenario_id: :leo_1,
            spacecraft_id: :sat_runtime_1
          }
        ],
        [
          %{
            spacecraft_id: :leo_1,
            payload_available: false
          }
        ]
      )

    assert %{
             "suppressed_candidate_count" => 1,
             "suppressed_candidates" => [
               %{
                 "id" => "obs_1",
                 "spacecraft_id" => "sat_runtime_1",
                 "suppressed_reason" => "payload_unavailable"
               }
             ]
           } = report
  end

  test "does not apply a single spacecraft-specific summary as a wildcard" do
    candidates = [
      %{
        id: :obs_scoped,
        type: :observe,
        scenario_id: :leo_1,
        spacecraft_id: :sat_with_summary,
        starts_at_s: 10.0,
        ends_at_s: 20.0
      },
      %{
        id: :obs_other,
        type: :observe,
        scenario_id: :leo_2,
        spacecraft_id: :sat_without_summary,
        starts_at_s: 30.0,
        ends_at_s: 40.0
      }
    ]

    {kept, report} =
      ResourceFilter.filter_candidates(candidates, [
        %{
          spacecraft_id: :sat_with_summary,
          payload_available: false,
          source_quality: :operator_supplied
        }
      ])

    assert Enum.map(kept, & &1["id"]) == ["obs_other"]

    assert %{
             "kept_candidate_count" => 1,
             "suppressed_candidate_count" => 1,
             "suppressed_candidates" => [
               %{
                 "id" => "obs_scoped",
                 "spacecraft_id" => "sat_with_summary",
                 "suppressed_reason" => "payload_unavailable"
               }
             ]
           } = report

    assert {:ok, %{"schema_contract" => "resource_filter_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "surfaces missing resource trust boundaries in suppression review rows" do
    {_kept, report} =
      ResourceFilter.filter_candidates(
        [
          %{
            id: :obs_missing_trust,
            type: :observe,
            scenario_id: :leo_1,
            spacecraft_id: :sat_with_summary
          }
        ],
        [
          %{
            spacecraft_id: :sat_with_summary,
            payload_available: false,
            source_quality: :operator_supplied
          }
        ]
      )

    assert %{
             "resource_source_quality_counts" => %{"operator_supplied" => 1},
             "resource_trust_boundary_status_counts" => %{"missing" => 1},
             "suppressed_resource_source_quality_counts" => %{"operator_supplied" => 1},
             "suppressed_resource_trust_boundary_status_counts" => %{"missing" => 1},
             "suppressed_candidates" => [
               %{
                 "id" => "obs_missing_trust",
                 "resource_source_quality" => "operator_supplied",
                 "resource_trust_boundary_status" => "missing"
               }
             ]
           } = report

    refute Map.has_key?(hd(report["suppressed_candidates"]), "resource_trust_boundary")

    assert {:ok, %{"schema_contract" => "resource_filter_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "normalizes flattened resource provenance aliases in filter summaries" do
    {_kept, report} =
      ResourceFilter.filter_candidates(
        [
          %{
            id: :obs_alias_provenance,
            type: :observe,
            scenario_id: :leo_1,
            spacecraft_id: :sat_alias_provenance
          }
        ],
        [
          %{
            spacecraft_id: :sat_alias_provenance,
            payload_available: false,
            resource_source_quality: :branch_generated,
            resource_trust_boundary: :branch_resource_projection
          }
        ]
      )

    assert %{
             "resource_source_quality_counts" => %{"branch_generated" => 1},
             "resource_trust_boundary_status_counts" => %{"declared" => 1},
             "suppressed_resource_source_quality_counts" => %{"branch_generated" => 1},
             "suppressed_resource_trust_boundary_status_counts" => %{"declared" => 1},
             "suppressed_candidates" => [
               %{
                 "id" => "obs_alias_provenance",
                 "resource_source_quality" => "branch_generated",
                 "resource_trust_boundary" => "branch_resource_projection",
                 "resource_trust_boundary_status" => "declared"
               }
             ]
           } = report

    assert {:ok, %{"schema_contract" => "resource_filter_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "keeps id-less wildcard summary as fallback alongside scoped summaries" do
    candidates = [
      %{
        id: :obs_scoped,
        type: :observe,
        scenario_id: :leo_1,
        spacecraft_id: :sat_with_summary
      },
      %{
        id: :dl_wildcard,
        type: :downlink,
        scenario_id: :leo_2,
        spacecraft_id: :sat_without_summary,
        ground_station_id: :equator_prime
      }
    ]

    {_kept, report} =
      ResourceFilter.filter_candidates(candidates, [
        %{payload_available: true, antenna_available: false, source_quality: :wildcard},
        %{
          spacecraft_id: :sat_with_summary,
          payload_available: false,
          antenna_available: true,
          source_quality: :scoped
        }
      ])

    assert Enum.map(
             report["suppressed_candidates"],
             &{&1["id"], &1["suppressed_reason"], &1["resource_source_quality"]}
           ) == [
             {"obs_scoped", "payload_unavailable", "scoped"},
             {"dl_wildcard", "antenna_unavailable", "wildcard"}
           ]

    assert {:ok, %{"schema_contract" => "resource_filter_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "disambiguates duplicate suppressed candidate ids for review and import artifacts" do
    candidates = [
      %{
        id: :dup_activity,
        type: :observe,
        scenario_id: :leo_1,
        spacecraft_id: :sat_1,
        starts_at_s: 10.0,
        ends_at_s: 20.0
      },
      %{
        id: :dup_activity,
        type: :observe,
        scenario_id: :leo_2,
        spacecraft_id: :sat_2,
        starts_at_s: 30.0,
        ends_at_s: 40.0
      }
    ]

    summaries = [
      %{spacecraft_id: :sat_1, payload_available: false, source_quality: :operator_supplied},
      %{spacecraft_id: :sat_2, payload_available: false, source_quality: :operator_supplied}
    ]

    {_kept, report} = ResourceFilter.filter_candidates(candidates, summaries)

    assert %{
             "suppressed_candidate_count" => 2,
             "duplicate_suppressed_candidate_id_count" => 1,
             "duplicate_suppressed_candidate_row_count" => 2,
             "suppressed_candidates" => suppressed_candidates
           } = report

    assert Enum.map(suppressed_candidates, & &1["id"]) == [
             "dup_activity:1",
             "dup_activity:2"
           ]

    assert Enum.map(suppressed_candidates, & &1["scenario_id"]) == ["leo_1", "leo_2"]

    assert Enum.all?(
             suppressed_candidates,
             &(&1["base_candidate_id"] == "dup_activity" and
                 &1["duplicate_suppressed_candidate_id_collision"])
           )

    assert Enum.map(suppressed_candidates, & &1["duplicate_suppressed_candidate_index"]) == [
             1,
             2
           ]

    assert Enum.all?(suppressed_candidates, &(&1["duplicate_suppressed_candidate_count"] == 2))

    assert {:ok, %{"schema_contract" => "resource_filter_report.v1"}} =
             Schema.validate_artifact(report)

    invalid_row_duplicate_count =
      update_in(
        report,
        ["suppressed_candidates", Access.at(0)],
        &Map.put(&1, "duplicate_suppressed_candidate_count", 1)
      )

    assert {:error, row_duplicate_count_report} =
             Schema.validate_artifact(invalid_row_duplicate_count)

    assert Enum.any?(
             row_duplicate_count_report["errors"],
             &(&1["path"] == "$.suppressed_candidates[0].duplicate_suppressed_candidate_count" and
                 &1["message"] == "must equal 2")
           )

    duplicate_index_collision =
      update_in(
        report,
        ["suppressed_candidates", Access.at(1)],
        &Map.put(&1, "duplicate_suppressed_candidate_index", 1)
      )

    assert {:error, duplicate_index_report} =
             Schema.validate_artifact(duplicate_index_collision)

    assert Enum.any?(
             duplicate_index_report["errors"],
             &(&1["path"] == "$.suppressed_candidates" and
                 String.starts_with?(
                   &1["message"],
                   "duplicate_suppressed_candidate_index values must cover 1..2"
                 ))
           )

    invalid_duplicate_count = Map.put(report, "duplicate_suppressed_candidate_row_count", 1)

    assert {:error, duplicate_count_report} = Schema.validate_artifact(invalid_duplicate_count)

    assert Enum.any?(
             duplicate_count_report["errors"],
             &(&1["path"] == "$.duplicate_suppressed_candidate_row_count" and
                 &1["message"] == "must equal 2")
           )

    review = OperatorReview.from_resource_filter_report(report)

    assert Enum.count(
             review["rows"],
             &(&1["base_candidate_id"] == "dup_activity" and
                 &1["duplicate_suppressed_candidate_id_collision"])
           ) == 2

    manifest = CadenceImport.from_resource_filter_report(report)

    assert Enum.count(
             manifest["rows"],
             &(&1["base_candidate_id"] == "dup_activity" and
                 &1["duplicate_suppressed_candidate_id_collision"])
           ) == 2
  end

  test "preserves station calendar ambiguity on resource suppression review and import rows" do
    candidate = %{
      id: :dl_ambiguous_station_calendar,
      type: :downlink,
      scenario_id: :leo_1,
      spacecraft_id: :sat_1,
      ground_station_id: :equator_prime,
      direction: :downlink,
      starts_at_s: 240.0,
      ends_at_s: 300.0,
      source_window_id: :window_1,
      station_availability: :ambiguous,
      station_calendar_status: :ambiguous,
      station_calendar_overlap_count: 2,
      station_calendar_overlap_entry_ids: [:calendar_a, :calendar_b],
      station_calendar_overlap_availabilities: [:reserved, :reduced_capacity],
      station_calendar_directions: [:downlink],
      station_calendar_entry_ambiguous: true,
      station_calendar_ambiguous_entry_count: 2,
      station_calendar_ambiguous_entry_ids: [:calendar_a, :calendar_b],
      station_calendar_reservation_overlap_count: 2,
      station_calendar_reservation_ids: [:reservation_a, :reservation_b],
      station_calendar_reserved_by: [:mission_ops, :station_owner],
      station_calendar_reservation_statuses: [:held, :tentative]
    }

    {_kept, report} =
      ResourceFilter.filter_candidates(
        [candidate],
        [
          %{
            spacecraft_id: :sat_1,
            antenna_available: false,
            source_quality: :operator_supplied
          }
        ],
        approval_policy: %{policy_bundle_id: "degraded_payload_guard_v1"}
      )

    assert [
             %{
               "id" => "dl_ambiguous_station_calendar",
               "suppressed_reason" => "antenna_unavailable",
               "station_availability" => "ambiguous",
               "station_calendar_status" => "ambiguous",
               "station_calendar_overlap_count" => 2,
               "station_calendar_overlap_entry_ids" => ["calendar_a", "calendar_b"],
               "station_calendar_overlap_availabilities" => [
                 "reserved",
                 "reduced_capacity"
               ],
               "station_calendar_directions" => ["downlink"],
               "station_calendar_entry_ambiguous" => true,
               "station_calendar_ambiguous_entry_count" => 2,
               "station_calendar_ambiguous_entry_ids" => ["calendar_a", "calendar_b"],
               "station_calendar_reservation_overlap_count" => 2,
               "station_calendar_reservation_ids" => ["reservation_a", "reservation_b"],
               "station_calendar_reserved_by" => ["mission_ops", "station_owner"],
               "station_calendar_reservation_statuses" => ["held", "tentative"]
             }
           ] = report["suppressed_candidates"]

    assert [
             %{
               "activity_context" => %{
                 "station_availability" => "ambiguous",
                 "station_calendar_directions" => ["downlink"],
                 "station_calendar_entry_ambiguous" => true,
                 "station_calendar_ambiguous_entry_ids" => ["calendar_a", "calendar_b"],
                 "station_calendar_reservation_ids" => ["reservation_a", "reservation_b"]
               }
             }
           ] = get_in(report, ["suppressed_candidates", Access.at(0), "approval_requirements"])

    assert {:ok, %{"schema_contract" => "resource_filter_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_resource_filter_report(report)
    review_row = Enum.find(review["rows"], &(&1["review_type"] == "resource_suppression"))

    assert %{
             "activity_id" => "dl_ambiguous_station_calendar",
             "station_availability" => "ambiguous",
             "requirement_type" => "contact_schedule_change",
             "station_calendar_directions" => ["downlink"],
             "station_calendar_entry_ambiguous" => true,
             "station_calendar_ambiguous_entry_count" => 2,
             "station_calendar_ambiguous_entry_ids" => ["calendar_a", "calendar_b"],
             "station_calendar_reservation_overlap_count" => 2,
             "station_calendar_reservation_ids" => ["reservation_a", "reservation_b"],
             "source_resource_suppression" => %{
               "station_calendar_entry_ambiguous" => true
             }
           } = review_row

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    manifest = CadenceImport.from_resource_filter_report(report)

    import_row =
      Enum.find(manifest["rows"], &(&1["import_action"] == "review_resource_suppression"))

    assert %{
             "activity_id" => "dl_ambiguous_station_calendar",
             "station_availability" => "ambiguous",
             "requirement_type" => "contact_schedule_change",
             "station_calendar_directions" => ["downlink"],
             "station_calendar_entry_ambiguous" => true,
             "station_calendar_ambiguous_entry_count" => 2,
             "station_calendar_ambiguous_entry_ids" => ["calendar_a", "calendar_b"],
             "station_calendar_reservation_overlap_count" => 2,
             "station_calendar_reservation_ids" => ["reservation_a", "reservation_b"],
             "source_resource_suppression" => %{
               "station_calendar_reservation_ids" => ["reservation_a", "reservation_b"]
             }
           } = import_row

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "carries contact feedback evidence into resource suppression policy, review, and import rows" do
    candidate = %{
      id: :dl_feedback_suppressed_by_resource,
      type: :planned_contact,
      direction: :downlink,
      scenario_id: :leo_1,
      spacecraft_id: :sat_1,
      ground_station_id: :equator_prime,
      starts_at_s: 120.0,
      ends_at_s: 180.0,
      source_window_id: :window_1,
      contact_success: false,
      contact_result: %{
        outcome: :accepted,
        provider_status: :dropped
      },
      contact_success_factor: 0.42,
      contact_success_factor_source: :operational_feedback_contact_rate,
      command_success: false,
      command_result: %{
        outcome: :accepted,
        status: :rejected
      },
      command_success_factor: 0.31,
      command_success_factor_source: :operational_feedback_command_rate
    }

    {_kept, report} =
      ResourceFilter.filter_candidates(
        [candidate],
        [
          %{
            spacecraft_id: :sat_1,
            antenna_available: false,
            source_quality: :operator_supplied
          }
        ],
        approval_policy: %{policy_bundle_id: "command_contact_authority_v1"}
      )

    assert [
             %{
               "id" => "dl_feedback_suppressed_by_resource",
               "type" => "planned_contact",
               "direction" => "downlink",
               "suppressed_reason" => "antenna_unavailable",
               "contact_success" => false,
               "contact_result" => "accepted,dropped",
               "contact_success_factor" => 0.42,
               "contact_success_factor_source" => "operational_feedback_contact_rate",
               "command_success" => false,
               "command_result" => "accepted,rejected",
               "command_success_factor" => 0.31,
               "command_success_factor_source" => "operational_feedback_command_rate",
               "approval_requirements" => [
                 %{
                   "action" => "review_suppressed_contact",
                   "requirement_type" => "contact_schedule_change",
                   "activity_context" => %{
                     "contact_success" => false,
                     "contact_result" => "accepted,dropped",
                     "contact_success_factor" => 0.42,
                     "contact_success_factor_source" => "operational_feedback_contact_rate",
                     "command_success" => false,
                     "command_result" => "accepted,rejected",
                     "command_success_factor" => 0.31,
                     "command_success_factor_source" => "operational_feedback_command_rate"
                   }
                 }
               ],
               "approval_rule_matches" => rule_matches
             }
           ] = report["suppressed_candidates"]

    assert Enum.any?(
             rule_matches,
             &(&1["rule_id"] == "failed_contact_success_review" and
                 &1["contact_success"] == false)
           )

    assert Enum.any?(
             rule_matches,
             &(&1["rule_id"] == "low_contact_success_confidence_review" and
                 &1["contact_success_factor"] == 0.42 and
                 &1["contact_success_factor_source"] == "operational_feedback_contact_rate")
           )

    assert {:ok, %{"schema_contract" => "resource_filter_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_resource_filter_report(report)
    review_row = Enum.find(review["rows"], &(&1["review_type"] == "resource_suppression"))

    assert %{
             "activity_id" => "dl_feedback_suppressed_by_resource",
             "contact_success" => false,
             "contact_result" => "accepted,dropped",
             "contact_success_factor" => 0.42,
             "contact_success_factor_source" => "operational_feedback_contact_rate",
             "command_success" => false,
             "command_result" => "accepted,rejected",
             "command_success_factor" => 0.31,
             "command_success_factor_source" => "operational_feedback_command_rate",
             "source_resource_suppression" => %{
               "contact_success" => false,
               "contact_result" => "accepted,dropped",
               "command_success" => false
             }
           } = review_row

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    manifest = CadenceImport.from_resource_filter_report(report)

    import_row =
      Enum.find(manifest["rows"], &(&1["import_action"] == "review_resource_suppression"))

    assert %{
             "activity_id" => "dl_feedback_suppressed_by_resource",
             "contact_success" => false,
             "contact_result" => "accepted,dropped",
             "contact_success_factor" => 0.42,
             "contact_success_factor_source" => "operational_feedback_contact_rate",
             "command_success" => false,
             "command_result" => "accepted,rejected",
             "command_success_factor" => 0.31,
             "command_success_factor_source" => "operational_feedback_command_rate",
             "source_resource_suppression" => %{
               "contact_result" => "accepted,dropped",
               "contact_success_factor_source" => "operational_feedback_contact_rate"
             }
           } = import_row

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "review-gates out-of-range contact feedback confidence factors" do
    candidate = %{
      id: :dl_invalid_resource_feedback,
      type: :planned_contact,
      direction: :downlink,
      scenario_id: :leo_1,
      spacecraft_id: :sat_1,
      ground_station_id: :equator_prime,
      starts_at_s: 120.0,
      ends_at_s: 180.0,
      source_window_id: :window_1,
      contact_success_factor: 1.4,
      contact_success_factor_source: :operator_feedback,
      command_success_factor: -0.25,
      command_success_factor_source: :command_adapter
    }

    {_kept, report} =
      ResourceFilter.filter_candidates(
        [candidate],
        [
          %{
            spacecraft_id: :sat_1,
            antenna_available: false,
            source_quality: :operator_supplied
          }
        ],
        approval_policy: %{policy_bundle_id: "command_contact_authority_v1"}
      )

    assert [
             %{
               "id" => "dl_invalid_resource_feedback",
               "suppressed_reason" => "invalid_candidate_input",
               "invalid_candidate_input" => true,
               "invalid_candidate_input_reason" => "invalid_contact_success_factor",
               "source_candidate" => %{
                 "contact_success_factor" => 1.4,
                 "command_success_factor" => -0.25
               }
             }
           ] = report["suppressed_candidates"]

    refute Map.has_key?(List.first(report["suppressed_candidates"]), "contact_success_factor")
    refute Map.has_key?(List.first(report["suppressed_candidates"]), "command_success_factor")

    assert report["invalid_candidate_input_count"] == 1
    assert report["invalid_candidate_input_ids"] == ["dl_invalid_resource_feedback"]

    review = OperatorReview.from_resource_filter_report(report)
    manifest = CadenceImport.from_resource_filter_report(report)

    assert Enum.any?(
             review["rows"],
             &(&1["activity_id"] == "dl_invalid_resource_feedback" and
                 &1["invalid_candidate_input_reason"] == "invalid_contact_success_factor")
           )

    assert Enum.any?(
             manifest["rows"],
             &(&1["activity_id"] == "dl_invalid_resource_feedback" and
                 &1["invalid_candidate_input_reason"] == "invalid_contact_success_factor")
           )

    assert {:ok, %{"schema_contract" => "resource_filter_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "classifies suppressed candidates with approval policy" do
    report =
      ResourceFilter.report(
        [
          %{
            id: :obs_payload,
            type: :observe,
            scenario_id: :leo_1,
            spacecraft_id: :sat_payload,
            starts_at_s: 10.0,
            ends_at_s: 20.0
          },
          %{
            id: :obs_degraded,
            type: :observe,
            scenario_id: :leo_1,
            spacecraft_id: :sat_degraded,
            starts_at_s: 30.0,
            ends_at_s: 40.0
          },
          %{
            id: :dl_antenna,
            type: :downlink,
            scenario_id: :leo_1,
            spacecraft_id: :sat_antenna,
            ground_station_id: :equator_prime,
            starts_at_s: 50.0,
            ends_at_s: 70.0
          }
        ],
        [
          %{
            spacecraft_id: :sat_payload,
            payload_available: false,
            degraded: false,
            source_quality: :operator_supplied
          },
          %{
            spacecraft_id: :sat_degraded,
            payload_available: true,
            degraded: true,
            source_quality: :operator_supplied
          },
          %{
            spacecraft_id: :sat_antenna,
            antenna_available: false,
            source_quality: :operator_supplied
          }
        ],
        approval_policy: %{policy_bundle_id: "degraded_payload_guard_v1"}
      )

    rows = Map.new(report["suppressed_candidates"], &{&1["id"], &1})

    assert %{
             "approval_status" => "blocked_by_policy",
             "spacecraft_id" => "sat_payload",
             "payload_available" => false,
             "resource_blocking_dimension" => "payload",
             "approval_rule_matches" => [
               %{"rule_id" => "payload_unavailable_observation_block"}
             ],
             "policy_decision" => %{
               "policy_bundle_id" => "degraded_payload_guard_v1",
               "risk_count" => 0,
               "rule_matches" => [
                 %{"rule_id" => "payload_unavailable_observation_block"}
               ]
             }
           } = rows["obs_payload"]

    assert %{
             "approval_status" => "blocked_by_policy",
             "spacecraft_id" => "sat_degraded",
             "degraded" => true,
             "resource_blocking_dimension" => "spacecraft_health",
             "approval_rule_matches" => [
               %{"rule_id" => "degraded_payload_observation_block"}
             ],
             "policy_decision" => %{"risk_count" => 0}
           } = rows["obs_degraded"]

    assert %{
             "approval_status" => "blocked_by_policy",
             "spacecraft_id" => "sat_antenna",
             "antenna_available" => false,
             "resource_blocking_dimension" => "antenna",
             "approval_rule_matches" => [
               %{
                 "rule_id" => "antenna_unavailable_contact_block",
                 "antenna_available" => false
               }
             ],
             "policy_decision" => %{
               "risk_count" => 0,
               "rule_matches" => [
                 %{"rule_id" => "antenna_unavailable_contact_block"}
               ]
             }
           } = rows["dl_antenna"]

    pressure_report =
      ResourceFilter.report(
        [
          %{
            id: :dl_shortfall,
            type: :downlink,
            scenario_id: :leo_1,
            spacecraft_id: :sat_downlink,
            ground_station_id: :equator_prime
          }
        ],
        [
          %{
            spacecraft_id: :sat_downlink,
            antenna_available: true,
            downlink_margin: 0.05
          }
        ],
        policy: %{min_downlink_margin: 0.2},
        approval_policy: %{policy_bundle_id: "conservative_ops_v1"}
      )

    assert [
             %{
               "id" => "dl_shortfall",
               "approval_status" => "blocked_by_policy",
               "resource_blocking_dimension" => "downlink",
               "approval_rule_matches" => [
                 %{"rule_id" => "resource_pressure_block", "risk_type" => "downlink_shortfall"}
               ],
               "policy_decision" => %{
                 "policy_bundle_id" => "conservative_ops_v1",
                 "risk_count" => 1
               }
             }
           ] = pressure_report["suppressed_candidates"]

    assert {:ok, %{"schema_contract" => "resource_filter_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "resource_filter_report.v1"}} =
             Schema.validate_artifact(pressure_report)
  end

  test "preserves scoped resource risk evidence for policy decisions" do
    report =
      ResourceFilter.report(
        [
          %{
            id: :dl_sat_a,
            type: :downlink,
            scenario_id: :leo_1,
            spacecraft_id: :sat_a,
            target_id: :target_alpha,
            ground_station_id: :equator_prime,
            starts_at_s: 10.0,
            ends_at_s: 20.0
          },
          %{
            id: :dl_sat_b,
            type: :downlink,
            scenario_id: :leo_2,
            spacecraft_id: :sat_b,
            target_id: :target_beta,
            ground_station_id: :equator_prime,
            starts_at_s: 30.0,
            ends_at_s: 40.0
          }
        ],
        [
          %{spacecraft_id: :sat_a, antenna_available: false},
          %{spacecraft_id: :sat_b, antenna_available: false}
        ],
        approval_policy: %{
          action_rules: [
            %{
              id: :sat_a_antenna_block,
              risk_types: [:antenna_unavailable],
              spacecraft_id: :sat_a,
              classification: :blocked_by_policy,
              reason: "sat_a antenna outage blocks contact promotion"
            }
          ]
        }
      )

    rows = Map.new(report["suppressed_candidates"], &{&1["id"], &1})

    assert rows["dl_sat_a"]["approval_status"] == "blocked_by_policy"

    assert Enum.any?(
             get_in(rows, ["dl_sat_a", "policy_decision", "rule_matches"]),
             &(&1["rule_id"] == "sat_a_antenna_block" and
                 &1["risk_type"] == "antenna_unavailable" and
                 &1["spacecraft_id"] == "sat_a" and
                 &1["target_id"] == "target_alpha" and
                 &1["ground_station_id"] == "equator_prime" and
                 &1["direction"] == "downlink")
           )

    assert %{
             "approval_status" => "operator_review_required",
             "policy_decision" => %{"rule_matches" => []}
           } = rows["dl_sat_b"]

    assert {:ok, %{"schema_contract" => "resource_filter_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_resource_filter_report(report)
    review_rows = Map.new(review["rows"], &{&1["activity_id"], &1})

    assert %{
             "scenario_id" => "leo_1",
             "spacecraft_id" => "sat_a",
             "resource_blocking_dimension" => "antenna",
             "target_id" => "target_alpha",
             "ground_station_id" => "equator_prime",
             "direction" => "downlink"
           } = review_rows["dl_sat_a"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    manifest = CadenceImport.from_resource_filter_report(report)
    import_rows = Map.new(manifest["rows"], &{&1["activity_id"], &1})

    assert %{
             "scenario_id" => "leo_1",
             "spacecraft_id" => "sat_a",
             "resource_blocking_dimension" => "antenna",
             "target_id" => "target_alpha",
             "ground_station_id" => "equator_prime",
             "direction" => "downlink"
           } = import_rows["dl_sat_a"]

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "public facades filter candidates and build reports" do
    candidates = [
      %{id: :obs_1, type: :observe, scenario_id: :leo_1},
      %{id: :dl_1, type: :downlink, scenario_id: :leo_1, ground_station_id: :equator_prime}
    ]

    summaries = [%{payload_available: false, antenna_available: true}]

    {kept, report} = OrbitalDynamics.filter_resource_candidates(candidates, summaries)

    assert Enum.map(kept, & &1["id"]) == ["dl_1"]
    assert report["suppressed_candidate_count"] == 1

    assert OrbitalDynamics.resource_filter_report(candidates, summaries) == report
    assert ResourceFilter.report(report) == report
    assert OrbitalDynamics.resource_filter_report(report) == report

    atom_keyed_report =
      Map.new(report, fn {key, value} -> {String.to_atom(key), value} end)

    assert ResourceFilter.report(atom_keyed_report) == report
    assert OrbitalDynamics.resource_filter_report(atom_keyed_report) == report

    assert %{
             "suppression_review_status" => "review_required",
             "suppressed_candidate_ids" => ["obs_1"],
             "suppressed_reason_counts" => %{"payload_unavailable" => 1}
           } = OrbitalDynamics.resource_filter_summary(candidates, summaries)

    assert OrbitalDynamics.resource_filter_policy(%{
             min_activity_thermal_margin_c: "2.0",
             min_downlink_margin: 0.5
           }) == %{
             "min_activity_thermal_margin_c" => 2.0,
             "min_downlink_margin" => 0.5
           }
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

  defp drop_resource_filter_report_capability_assumptions(report) do
    update_in(
      report,
      ["assumptions"],
      &Map.drop(&1, Map.keys(resource_filter_report_capability_assumptions()))
    )
  end

  test "returns no suppressions when summaries do not match any candidate" do
    candidates = [
      %{id: :obs_1, type: :observe, scenario_id: :leo_1}
    ]

    {_kept, report} =
      ResourceFilter.filter_candidates(candidates, [
        %{spacecraft_id: :leo_2, payload_available: false},
        %{spacecraft_id: :leo_3, payload_available: false}
      ])

    assert report["input_candidate_count"] == 1
    assert report["kept_candidate_count"] == 1
    assert report["suppressed_candidate_count"] == 0
    assert report["suppressed_candidates"] == []

    assert %{
             "suppression_review_status" => "clear",
             "suppressed_candidate_count" => 0,
             "suppressed_candidate_ids" => [],
             "review_rows" => []
           } = ResourceFilter.summary(report)
  end
end
