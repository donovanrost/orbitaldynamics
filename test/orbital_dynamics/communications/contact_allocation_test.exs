defmodule OrbitalDynamics.Communications.ContactAllocationTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.OperatorReview
  alias OrbitalDynamics.CadenceImport
  alias OrbitalDynamics.Communications.{ContactAllocation, ContactContention}
  alias OrbitalDynamics.Schema

  test "declares contact allocation capabilities" do
    capabilities = ContactAllocation.capabilities()

    assert %{
             artifact_contract: "contact_allocation_report.v1",
             summary_artifact_contract: "contact_allocation_summary.v1",
             station_pressure_summary_artifact_contract:
               "contact_allocation_station_pressure_summary.v1",
             capacity_pack_summary_artifact_contract:
               "contact_allocation_capacity_pack_summary.v1",
             reservation_conflict_summary_artifact_contract:
               "contact_allocation_reservation_conflict_summary.v1",
             provider_reservation_request_summary_artifact_contract:
               "contact_allocation_provider_reservation_request_summary.v1",
             validation_level: :artifact_contract,
             model: :deterministic_station_contact_allocation,
             row_statuses: ["allocated", "deferred", "blocked"],
             row_review_statuses: ["accepted_for_planning", "operator_review_required"],
             station_unavailable_aliases: station_unavailable_aliases,
             station_blocking_availability: station_blocking_availability,
             station_availability_precedence: station_availability_precedence,
             station_capacity_fraction_paths: station_capacity_fraction_paths,
             station_capacity_percent_paths: station_capacity_percent_paths,
             station_capacity_value_paths: station_capacity_value_paths,
             source_station_capacity_fraction_paths: source_station_capacity_fraction_paths,
             source_station_capacity_percent_paths: source_station_capacity_percent_paths,
             source_station_capacity_value_paths: source_station_capacity_value_paths,
             required_capacity_fraction_paths: required_capacity_fraction_paths,
             required_capacity_percent_paths: required_capacity_percent_paths,
             required_capacity_value_paths: required_capacity_value_paths,
             required_capacity_fraction_source_values: required_capacity_fraction_source_values,
             capacity_pack_statuses: capacity_pack_statuses,
             reduced_capacity_pack_statuses: reduced_capacity_pack_statuses,
             station_reservation_match_statuses: station_reservation_match_statuses,
             reservation_conflict_match_statuses: reservation_conflict_match_statuses,
             station_reservation_expiration_statuses: station_reservation_expiration_statuses,
             provider_reservation_request_statuses: provider_reservation_request_statuses,
             default_required_capacity_fraction_paths: default_required_capacity_fraction_paths,
             default_required_capacity_value_paths: default_required_capacity_value_paths,
             provider_direction_aliases: provider_direction_aliases,
             provider_result_map_value_keys: provider_result_map_value_keys,
             provider_counteroffer_fields: provider_counteroffer_fields,
             contact_stable_identity_fields: contact_stable_identity_fields,
             command_contact_directions: command_contact_directions,
             contention_resolution_selection_rules: contention_resolution_selection_rules,
             contention_resolution_tie_breakers: contention_resolution_tie_breakers,
             contention_default_resolution_priority_fields:
               contention_default_resolution_priority_fields,
             contention_resolution_priority_override_aliases:
               contention_resolution_priority_override_aliases,
             public_facades: public_facades,
             handoff_artifacts: handoff_artifacts,
             handoff_review_types: handoff_review_types,
             handoff_import_actions: handoff_import_actions,
             known_limits: known_limits,
             row_semantics: row_semantics
           } = capabilities

    assert station_unavailable_aliases == ["outage", "down", "offline"]
    assert station_blocking_availability == ["unavailable", "maintenance"]

    assert station_availability_precedence == %{
             "unavailable" => 5,
             "maintenance" => 5,
             "reserved" => 4,
             "reduced_capacity" => 3,
             "available" => 1
           }

    assert ["availability"] in station_capacity_fraction_paths
    assert ["capacity_pack_capacity_fraction"] in station_capacity_fraction_paths
    assert ["station_capacity_fraction"] in station_capacity_fraction_paths
    assert ["capacity_fraction"] in station_capacity_fraction_paths
    assert ["throughput_model", "availability"] in station_capacity_fraction_paths
    assert ["throughput_model", "station_capacity_fraction"] in station_capacity_fraction_paths
    assert ["capacity_model", "availability"] in station_capacity_fraction_paths
    assert ["capacity_model", "capacity_fraction"] in station_capacity_fraction_paths
    assert ["activity_context", "availability"] in station_capacity_fraction_paths
    assert ["activity_context", "capacity_fraction"] in station_capacity_fraction_paths

    assert ["capacity_percent"] in station_capacity_percent_paths
    assert ["station_capacity_percent"] in station_capacity_percent_paths
    assert ["throughput_model", "station_capacity_percent"] in station_capacity_percent_paths
    assert ["capacity_model", "capacity_percent"] in station_capacity_percent_paths
    assert ["activity_context", "station_capacity_percent"] in station_capacity_percent_paths

    assert source_station_capacity_fraction_paths == station_capacity_fraction_paths
    assert source_station_capacity_percent_paths == station_capacity_percent_paths
    assert source_station_capacity_value_paths == station_capacity_value_paths

    assert %{unit: :fraction, path: ["availability"]} in station_capacity_value_paths
    assert %{unit: :fraction, path: ["capacity_fraction"]} in station_capacity_value_paths

    assert %{unit: :fraction, path: ["throughput_model", "availability"]} in station_capacity_value_paths

    assert %{unit: :fraction, path: ["capacity_model", "availability"]} in station_capacity_value_paths

    assert %{unit: :fraction, path: ["activity_context", "availability"]} in station_capacity_value_paths

    assert %{unit: :fraction, path: ["capacity_pack_capacity_fraction"]} in station_capacity_value_paths

    assert %{unit: :percent, path: ["capacity_percent"]} in station_capacity_value_paths

    assert %{unit: :fraction, path: ["activity_context", "capacity_fraction"]} in source_station_capacity_value_paths

    assert %{unit: :percent, path: ["capacity_model", "station_capacity_percent"]} in source_station_capacity_value_paths

    assert ["required_capacity_fraction"] in required_capacity_fraction_paths
    assert ["required_station_capacity_fraction"] in required_capacity_fraction_paths
    assert ["station_capacity_requirement"] in required_capacity_fraction_paths
    assert ["throughput_model", "required_capacity_fraction"] in required_capacity_fraction_paths
    assert ["capacity_model", "station_capacity_requirement"] in required_capacity_fraction_paths

    assert ["activity_context", "required_station_capacity_fraction"] in required_capacity_fraction_paths

    assert ["required_capacity_percent"] in required_capacity_percent_paths
    assert ["required_station_capacity_percent"] in required_capacity_percent_paths
    assert ["station_capacity_requirement_percent"] in required_capacity_percent_paths

    assert ["throughput_model", "required_station_capacity_percent"] in required_capacity_percent_paths

    assert ["capacity_model", "required_capacity_percent"] in required_capacity_percent_paths

    assert ["activity_context", "station_capacity_requirement_percent"] in required_capacity_percent_paths

    assert %{unit: :fraction, path: ["required_station_capacity_fraction"]} in required_capacity_value_paths

    assert %{unit: :percent, path: ["throughput_model", "required_capacity_percent"]} in required_capacity_value_paths

    assert %{unit: :fraction, path: ["capacity_model", "station_capacity_requirement"]} in required_capacity_value_paths

    assert %{unit: :percent, path: ["activity_context", "station_capacity_requirement_percent"]} in required_capacity_value_paths

    assert "contact_required_capacity_fraction" in required_capacity_fraction_source_values
    assert "default_reduced_capacity_policy" in required_capacity_fraction_source_values
    assert "implicit_full_station_capacity" in required_capacity_fraction_source_values

    assert capacity_pack_statuses == [
             "selected_by_contention_resolution",
             "selected_by_reduced_station_capacity_pack",
             "deferred_by_reduced_station_capacity_pack"
           ]

    assert reduced_capacity_pack_statuses == ["all_fit", "capacity_limited"]

    assert station_reservation_match_statuses == ["matched", "owner_matched", "overlap"]
    assert reservation_conflict_match_statuses == ["overlap"]
    assert station_reservation_expiration_statuses == ["missing", "declared", "active", "expired"]
    assert provider_reservation_request_statuses == ["clear", "request_ready", "review_required"]

    assert default_required_capacity_fraction_paths == [
             ["default_required_capacity_fraction"],
             ["capacity_policy", "default_required_capacity_fraction"],
             ["policy", "default_required_capacity_fraction"]
           ]

    assert %{unit: :fraction, path: ["default_required_capacity_fraction"]} in default_required_capacity_value_paths

    assert %{
             unit: :fraction,
             path: ["capacity_policy", "default_required_capacity_fraction"]
           } in default_required_capacity_value_paths

    assert %{
             unit: :fraction,
             path: ["policy", "default_required_capacity_fraction"]
           } in default_required_capacity_value_paths

    assert "scenario_id" in contact_stable_identity_fields
    assert "spacecraft_id" in contact_stable_identity_fields
    assert "satellite_id" in contact_stable_identity_fields
    assert "ground_station_id" in contact_stable_identity_fields
    assert "source_window_id" in contact_stable_identity_fields
    assert "station_calendar_entry_id" in contact_stable_identity_fields
    assert "station_reservation_id" in contact_stable_identity_fields

    assert command_contact_directions == ["command", "uplink"]

    assert Map.take(provider_direction_aliases, [
             "cmd",
             "commanding",
             "commands",
             "sband_command",
             "s_band_command",
             "up",
             "up_link",
             "dl",
             "down",
             "downlinking",
             "down_link",
             "track",
             "track_ing",
             "tracking_pass",
             "health",
             "healthcheck",
             "health_check_window"
           ]) == %{
             "cmd" => "command",
             "commanding" => "command",
             "commands" => "command",
             "sband_command" => "command",
             "s_band_command" => "command",
             "up" => "uplink",
             "up_link" => "uplink",
             "dl" => "downlink",
             "down" => "downlink",
             "downlinking" => "downlink",
             "down_link" => "downlink",
             "track" => "tracking",
             "track_ing" => "tracking",
             "tracking_pass" => "tracking",
             "health" => "health_check",
             "healthcheck" => "health_check",
             "health_check_window" => "health_check"
           }

    assert "result" in provider_result_map_value_keys
    assert "provider_status" in provider_result_map_value_keys
    assert "provider_outcome" in provider_result_map_value_keys
    assert "diagnostics" in provider_result_map_value_keys

    assert provider_counteroffer_fields == [
             "provider_counteroffer_id",
             "provider_counteroffer_status",
             "provider_counteroffer_negotiation_state",
             "provider_counteroffer_reason_code",
             "provider_counteroffer_cost_delta",
             "provider_counteroffer_lock_deadline_s",
             "provider_counteroffer_starts_at_s",
             "provider_counteroffer_ends_at_s",
             "provider_counteroffer_start_delta_s",
             "provider_counteroffer_end_delta_s",
             "provider_counteroffer_duration_delta_s"
           ]

    assert contention_resolution_selection_rules ==
             ContactContention.capabilities().resolution_selection_rules

    assert "highest_priority_highest_score" in contention_resolution_selection_rules

    assert contention_resolution_tie_breakers ==
             ContactContention.capabilities().resolution_tie_breakers

    assert "policy_contact_priority" in contention_resolution_tie_breakers
    assert "station_reservation_priority" in contention_resolution_tie_breakers

    assert contention_default_resolution_priority_fields ==
             ContactContention.capabilities().default_resolution_priority_fields

    assert "contention_priority" in contention_default_resolution_priority_fields
    assert "command_contact_priority" in contention_default_resolution_priority_fields

    assert contention_resolution_priority_override_aliases ==
             ContactContention.capabilities().resolution_priority_override_aliases

    assert "contact_priorities" in contention_resolution_priority_override_aliases

    assert :realized_contact_evidence_preservation in row_semantics
    assert :invalid_contact_input_review in row_semantics
    assert :station_reservation_identity_match in row_semantics
    assert :same_spacecraft_contention_resolution in row_semantics
    assert :priority_aware_contention_resolution in row_semantics
    assert :contention_priority_evidence_handoff in row_semantics
    assert :contention_priority_field_evidence_handoff in row_semantics
    assert :nested_contention_policy_evidence in row_semantics
    assert :direction_scoped_station_calendar in row_semantics
    assert :station_calendar_provider_input in row_semantics
    assert :station_calendar_provider_list_input in row_semantics
    assert :station_capacity_value_paths in row_semantics
    assert :source_station_capacity_value_paths in row_semantics
    assert :required_capacity_value_paths in row_semantics
    assert :default_required_capacity_value_paths in row_semantics
    assert :contact_stable_identity_fields in row_semantics
    assert :command_contact_directions in row_semantics
    assert :provider_direction_aliases in row_semantics
    assert :provider_result_map_value_keys in row_semantics
    assert :provider_counteroffer_review_handoff in row_semantics
    assert :provider_counteroffer_fields in row_semantics
    assert :station_calendar_trust_evidence_preservation in row_semantics
    assert :station_calendar_entry_identity_preservation in row_semantics
    assert :station_calendar_precedence_evidence_preservation in row_semantics
    assert :station_calendar_counts_derive_from_id_sets in row_semantics
    assert :contact_source_window_provenance in row_semantics
    assert :station_reservation_owner_match in row_semantics
    assert :station_calendar_reservation_expiration_context in row_semantics
    assert :station_calendar_trust_policy_boundary in row_semantics
    assert :status_blocked_station_calendar_context in row_semantics
    assert :realized_status_blocked_throughput_preservation in row_semantics
    assert :realized_status_blocked_data_rate_throughput_preservation in row_semantics
    assert :realized_status_blocked_completion_fraction_preservation in row_semantics
    assert :feedback_unit_interval_input_validation in row_semantics
    assert :resource_summary_filter_allocation_boundary in row_semantics
    assert :resource_battery_mode_evidence_preservation in row_semantics
    assert :resource_thermal_margin_evidence_preservation in row_semantics
    assert :resource_activity_type_constraint_evidence_preservation in row_semantics
    assert :allocation_capacity_fraction_validation in row_semantics
    assert :reduced_station_capacity_requirement in row_semantics
    assert :default_reduced_station_capacity_requirement in row_semantics
    assert :reduced_station_capacity_packing in row_semantics
    assert :reduced_station_capacity_pack_ledger in row_semantics
    assert :capacity_pack_status_values in row_semantics
    assert :reduced_capacity_pack_status_values in row_semantics
    assert :contact_allocation_summary in row_semantics
    assert :contact_allocation_summary_routing_id_sets in row_semantics
    assert :contact_allocation_summary_status_station_routing in row_semantics
    assert :contact_allocation_summary_reason_routing in row_semantics
    assert :contact_allocation_summary_canonical_station_status_routing in row_semantics
    assert :contact_allocation_summary_capacity_pack_routing in row_semantics
    assert :contact_allocation_capacity_pack_summary in row_semantics
    assert :contact_allocation_resource_pressure_summary in row_semantics
    assert :contact_allocation_station_pressure_summary in row_semantics
    assert :contact_allocation_station_pressure_count_maps in row_semantics
    assert :contact_allocation_station_precedence_summary in row_semantics
    assert :contact_allocation_summary_reservation_status_routing in row_semantics
    assert :contact_allocation_summary_reservation_owner_routing in row_semantics
    assert :contact_allocation_summary_reservation_id_routing in row_semantics
    assert :contact_allocation_summary_reservation_expiration_routing in row_semantics
    assert :contact_allocation_reservation_conflict_summary in row_semantics
    assert :contact_allocation_reservation_conflict_status_values in row_semantics
    assert :contact_allocation_reservation_conflict_review_handoff in row_semantics
    assert :contact_allocation_provider_reservation_request_summary in row_semantics
    assert :contact_allocation_provider_reservation_request_status_values in row_semantics
    assert :contact_allocation_provider_reservation_request_review_handoff in row_semantics
    assert :station_reservation_expiration_status_values in row_semantics
    assert :contact_allocation_summary_direct_station_availability_routing in row_semantics
    assert :contact_allocation_summary_required_capacity_source_routing in row_semantics
    assert :contact_allocation_summary_row_derived_counts in row_semantics
    assert :station_reservation_match_status_counts in row_semantics
    assert :downlink_completion_evidence_preservation in row_semantics
    assert :artifact_level_only in known_limits
    assert :declared_ground_network_only in known_limits
    assert :optional_externally_supplied_resource_summary in known_limits
    assert :no_full_realized_contact_reconciliation in known_limits
    assert :no_provider_reservation in known_limits
    assert :no_schedule_mutation in known_limits
    refute :limited_realized_status_blocked_throughput_preservation in known_limits
    refute :limited_realized_status_blocked_completion_fraction_preservation in known_limits
    assert capabilities.approval_policy_boundary == :optional_policy_decision_v1
    assert "health_check" in capabilities.contact_directions

    assert public_facades == [
             :allocate_contacts,
             :contact_allocation_report,
             :contact_allocation_summary,
             :contact_allocation_capacity_pack_summary,
             :contact_allocation_station_pressure_summary,
             :contact_allocation_reservation_conflict_summary,
             :contact_allocation_provider_reservation_request_summary
           ]

    assert handoff_artifacts == ["operator_review_package.v1", "cadence_import_manifest.v1"]

    assert handoff_review_types == [
             "contact_allocation_review",
             "contact_allocation_capacity_pack_review",
             "station_reservation_review"
           ]

    assert handoff_import_actions == [
             "review_contact_allocation",
             "review_contact_allocation_capacity_pack",
             "review_provider_reservation_request",
             "review_station_reservation"
           ]

    assert OrbitalDynamics.capability_catalog().operations.contact_allocation.public_facades ==
             public_facades
  end

  test "allocates available contacts, defers contention, and blocks reserved contacts" do
    contacts = [
      contact(:dl_1, starts_at_s: 100.0, ends_at_s: 160.0, score: 5.0),
      contact(:dl_2, starts_at_s: 120.0, ends_at_s: 180.0, score: 2.0),
      contact(:dl_3, starts_at_s: 250.0, ends_at_s: 280.0, score: 4.0)
    ]

    ground_network = [
      %{
        ground_station_id: :equator_prime,
        status: :reserved,
        starts_at_s: 240.0,
        ends_at_s: 300.0,
        reservation_id: :reservation_1,
        reserved_by: "network_partner",
        reservation_status: :reserved,
        reservation_hold_expires_at_s: "420.0"
      }
    ]

    {allocated, report} =
      ContactAllocation.allocate_contacts(contacts, ground_network,
        source: "unit_test.contacts",
        approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
      )

    assert Enum.map(allocated, & &1["id"]) == ["dl_1"]
    assert hd(allocated)["allocation_reason"] == "selected_by_contention_resolution"

    assert %{
             "schema_contract" => "contact_allocation_report.v1",
             "model" => "deterministic_station_contact_allocation",
             "source" => "unit_test.contacts",
             "input_contact_count" => 3,
             "allocated_contact_count" => 1,
             "deferred_contact_count" => 1,
             "blocked_contact_count" => 1,
             "allocation_status_counts" => %{
               "allocated" => 1,
               "blocked" => 1,
               "deferred" => 1
             },
             "effective_allocation_status_counts" => %{
               "allocated" => 1,
               "blocked" => 1,
               "deferred" => 1
             },
             "allocation_reason_counts" => %{
               "ground_station_reserved" => 1,
               "same_station_contention" => 1,
               "selected_by_contention_resolution" => 1
             },
             "station_reservation_expiration_status_counts" => %{"declared" => 1},
             "station_reservation_declared_expiration_contact_count" => 1,
             "station_reservation_missing_expiration_contact_count" => 0,
             "earliest_station_reservation_expires_at_s" => 420.0,
             "station_reservation_contact_ids_by_expiration_status" => %{
               "declared" => ["dl_3"]
             },
             "station_reservation_ids_by_expiration_status" => %{
               "declared" => ["reservation_1"]
             },
             "model_limits" => model_limits,
             "contact_filter_report" => %{
               "suppressed_candidate_count" => 1,
               "suppressed_candidates" => [
                 %{
                   "id" => "dl_3",
                   "suppressed_reason" => "ground_station_reserved",
                   "station_calendar_entry_id" => "declared:equator_prime:240.000000:300.000000",
                   "station_calendar_overlap_count" => 1,
                   "station_calendar_overlap_entry_ids" => [
                     "declared:equator_prime:240.000000:300.000000"
                   ],
                   "station_reservation_id" => "reservation_1",
                   "station_reservation_expires_at_s" => 420.0,
                   "station_calendar_reservation_expires_at_s" => [420.0]
                 }
               ]
             },
             "contact_contention_report" => %{
               "conflict_group_count" => 1,
               "conflicted_contact_count" => 2
             },
             "contact_contention_resolution_report" => %{
               "recommendation_count" => 1,
               "recommendations" => [
                 %{
                   "selected_contact_id" => "dl_1",
                   "deferred_contact_ids" => ["dl_2"]
                 }
               ]
             }
           } = report

    assert "no_provider_reservation" in model_limits
    assert "no_schedule_mutation" in model_limits
    assert "no_full_realized_contact_reconciliation" in model_limits
    refute "limited_realized_status_blocked_throughput_preservation" in model_limits
    refute "limited_realized_status_blocked_completion_fraction_preservation" in model_limits

    assert model_limits ==
             ContactAllocation.capabilities().known_limits
             |> Enum.map(&Atom.to_string/1)

    assert Enum.map(report["rows"], &{&1["contact_id"], &1["allocation_status"]}) == [
             {"dl_1", "allocated"},
             {"dl_2", "deferred"},
             {"dl_3", "blocked"}
           ]

    assert %{
             "contact_id" => "dl_2",
             "allocation_reason" => "same_station_contention",
             "selected_contact_id" => "dl_1",
             "review_status" => "operator_review_required"
           } = Enum.find(report["rows"], &(&1["contact_id"] == "dl_2"))

    assert %{
             "contact_id" => "dl_3",
             "allocation_status" => "blocked",
             "station_calendar_entry_id" => "declared:equator_prime:240.000000:300.000000",
             "station_calendar_status" => "reserved",
             "station_calendar_overlap_count" => 1,
             "station_calendar_overlap_entry_ids" => [
               "declared:equator_prime:240.000000:300.000000"
             ],
             "station_calendar_overlap_availabilities" => ["reserved"],
             "station_calendar_reservation_overlap_count" => 1,
             "station_calendar_reservation_ids" => ["reservation_1"],
             "station_calendar_reserved_by" => ["network_partner"],
             "station_calendar_reservation_statuses" => ["reserved"],
             "station_calendar_reservation_expires_at_s" => [420.0],
             "station_reservation_id" => "reservation_1",
             "station_reservation_expires_at_s" => 420.0
           } = Enum.find(report["rows"], &(&1["contact_id"] == "dl_3"))

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, contact_allocation_report_schema} =
             Schema.json_schema("contact_allocation_report.v1")

    assert get_in(contact_allocation_report_schema, ["properties", "model", "const"]) ==
             "deterministic_station_contact_allocation"

    assert get_in(contact_allocation_report_schema, ["properties", "source", "type"]) ==
             "string"

    assert get_in(contact_allocation_report_schema, ["properties", "model_limits", "const"]) ==
             model_limits

    assert get_in(contact_allocation_report_schema, [
             "properties",
             "model_limits",
             "items",
             "enum"
           ]) == model_limits

    stale_report_model = Map.put(report, "model", "stale_contact_allocation_report")

    assert {:error, stale_report_model_errors} = Schema.validate_artifact(stale_report_model)

    assert Enum.any?(
             stale_report_model_errors["errors"],
             &(&1["path"] == "$.model" and
                 &1["message"] == "must equal \"deterministic_station_contact_allocation\"")
           )

    stale_report_source = Map.put(report, "source", %{"source" => "unit_test.contacts"})

    assert {:error, stale_report_source_errors} = Schema.validate_artifact(stale_report_source)

    assert Enum.any?(
             stale_report_source_errors["errors"],
             &(&1["path"] == "$.source" and &1["message"] == "must be a binary")
           )

    stale_report_model_limits = Map.put(report, "model_limits", ["artifact_level_only"])

    assert {:error, stale_report_model_limits_errors} =
             Schema.validate_artifact(stale_report_model_limits)

    assert Enum.any?(
             stale_report_model_limits_errors["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] == "must match contact allocation model limits")
           )

    expected_summary_capability_assumptions =
      contact_allocation_summary_capability_assumptions()

    summary = ContactAllocation.summary(report)

    assert %{
             "schema_contract" => "contact_allocation_summary.v1",
             "model" => "artifact_only_contact_allocation_summary",
             "model_limits" => summary_model_limits,
             "source_artifact_type" => "contact_allocation_report.v1",
             "source" => "unit_test.contacts",
             "input_contact_count" => 3,
             "allocated_contact_count" => 1,
             "returned_allocated_contact_count" => 1,
             "policy_blocked_allocated_contact_count" => 0,
             "deferred_contact_count" => 1,
             "blocked_contact_count" => 1,
             "invalid_contact_input_count" => 0,
             "status_blocked_contact_count" => 0,
             "resource_blocked_contact_count" => 0,
             "duplicate_contact_id_count" => 0,
             "allocation_status_counts" => %{
               "allocated" => 1,
               "blocked" => 1,
               "deferred" => 1
             },
             "allocation_reason_counts" => %{
               "ground_station_reserved" => 1,
               "same_station_contention" => 1,
               "selected_by_contention_resolution" => 1
             },
             "contact_ids_by_allocation_reason" => %{
               "ground_station_reserved" => ["dl_3"],
               "same_station_contention" => ["dl_2"],
               "selected_by_contention_resolution" => ["dl_1"]
             },
             "station_reservation_ids" => ["reservation_1"],
             "station_reservation_expires_at_s" => [420.0],
             "station_reservation_expiration_status_counts" => %{"declared" => 1},
             "station_reservation_declared_expiration_contact_count" => 1,
             "station_reservation_active_contact_count" => 0,
             "station_reservation_expired_contact_count" => 0,
             "station_reservation_missing_expiration_contact_count" => 0,
             "earliest_station_reservation_expires_at_s" => 420.0,
             "allocated_contact_ids" => ["dl_1"],
             "allocated_contact_ids_by_ground_station_id" => %{
               "equator_prime" => ["dl_1"]
             },
             "returned_allocated_contact_ids" => ["dl_1"],
             "returned_allocated_contact_ids_by_ground_station_id" => %{
               "equator_prime" => ["dl_1"]
             },
             "deferred_contact_ids" => ["dl_2"],
             "deferred_contact_ids_by_ground_station_id" => %{
               "equator_prime" => ["dl_2"]
             },
             "blocked_contact_ids" => ["dl_3"],
             "blocked_contact_ids_by_ground_station_id" => %{
               "equator_prime" => ["dl_3"]
             },
             "policy_blocked_contact_ids" => [],
             "policy_blocked_contact_ids_by_ground_station_id" => %{},
             "invalid_contact_input_ids" => [],
             "status_blocked_contact_ids" => [],
             "resource_blocked_contact_ids" => [],
             "resource_blocking_dimension_counts" => %{},
             "resource_blocked_contact_ids_by_blocking_dimension" => %{},
             "resource_blocked_contact_ids_by_spacecraft_id" => %{},
             "station_pressure_contact_ids_by_ground_station_id" => %{
               "equator_prime" => ["dl_3"]
             },
             "station_pressure_contact_counts_by_ground_station_id" => %{
               "equator_prime" => 1
             },
             "station_pressure_contact_ids_by_availability" => %{"reserved" => ["dl_3"]},
             "station_pressure_contact_counts_by_availability" => %{"reserved" => 1},
             "station_pressure_contact_counts_by_precedence_availability" => %{},
             "station_pressure_contact_counts_by_precedence_rank" => %{},
             "station_reservation_contact_ids_by_match_status" => %{},
             "station_reservation_contact_ids_by_expiration_status" => %{
               "declared" => ["dl_3"]
             },
             "station_reservation_ids_by_expiration_status" => %{
               "declared" => ["reservation_1"]
             },
             "reduced_capacity_packed_contact_ids" => [],
             "reduced_capacity_deferred_contact_ids" => [],
             "rows" => summary_rows,
             "review_contact_ids" => ["dl_1", "dl_2", "dl_3"],
             "review_row_count" => 3,
             "review_rows" => review_rows,
             "assumptions" => %{
               "execution_boundary" =>
                 "artifact_only_no_provider_reservation_or_schedule_mutation",
               "source" => "contact_allocation_report.v1",
               "operator_authority" => "not_granted_by_summary"
             }
           } = summary

    assert summary_model_limits ==
             ContactAllocation.capabilities().known_limits
             |> Enum.map(&Atom.to_string/1)

    assert Map.take(
             summary["assumptions"],
             Map.keys(expected_summary_capability_assumptions)
           ) == expected_summary_capability_assumptions

    assert length(summary_rows) == 3
    assert Enum.map(review_rows, & &1["contact_id"]) == ["dl_1", "dl_2", "dl_3"]

    assert {:ok, %{"schema_contract" => "contact_allocation_summary.v1"}} =
             Schema.validate_artifact(summary)

    assert {:ok, contact_allocation_summary_schema} =
             Schema.json_schema("contact_allocation_summary.v1")

    assert get_in(contact_allocation_summary_schema, ["properties", "model", "const"]) ==
             "artifact_only_contact_allocation_summary"

    assert get_in(contact_allocation_summary_schema, ["properties", "model_limits", "const"]) ==
             summary_model_limits

    assert get_in(contact_allocation_summary_schema, [
             "properties",
             "model_limits",
             "items",
             "enum"
           ]) == summary_model_limits

    summary_assumptions_schema =
      get_in(contact_allocation_summary_schema, ["properties", "assumptions", "properties"])

    for {field, expected_value} <- expected_summary_capability_assumptions do
      assert get_in(summary_assumptions_schema, [field, "const"]) == expected_value
    end

    stale_summary_model = Map.put(summary, "model", "stale_contact_allocation_summary")

    assert {:error, stale_summary_model_errors} = Schema.validate_artifact(stale_summary_model)

    assert Enum.any?(
             stale_summary_model_errors["errors"],
             &(&1["path"] == "$.model" and
                 &1["message"] == "must equal \"artifact_only_contact_allocation_summary\"")
           )

    stale_summary_model_limits = Map.put(summary, "model_limits", ["artifact_level_only"])

    assert {:error, stale_summary_model_limits_errors} =
             Schema.validate_artifact(stale_summary_model_limits)

    assert Enum.any?(
             stale_summary_model_limits_errors["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] == "must match contact allocation model limits")
           )

    stale_summary_count = Map.put(summary, "allocated_contact_count", 0)

    assert {:error, stale_summary_count_errors} = Schema.validate_artifact(stale_summary_count)

    assert Enum.any?(
             stale_summary_count_errors["errors"],
             &(&1["path"] == "$.allocated_contact_count" and
                 &1["message"] == "must equal 1")
           )

    stale_summary_review_rows =
      Map.update!(summary, "rows", fn rows ->
        Enum.map(rows, fn
          %{"contact_id" => "dl_2"} = row ->
            row
            |> Map.put("allocation_status", "allocated")
            |> Map.put("effective_allocation_status", "allocated")
            |> Map.put("review_status", "accepted_for_planning")

          row ->
            row
        end)
      end)

    assert {:error, stale_summary_review_row_errors} =
             Schema.validate_artifact(stale_summary_review_rows)

    assert Enum.any?(
             stale_summary_review_row_errors["errors"],
             &(&1["path"] == "$.review_rows" and
                 &1["message"] == "must equal row-derived review_rows")
           )

    for {field, stale_value, expected_message} <- [
          {"row_statuses", ["allocated"], "must match ContactAllocation row statuses"},
          {"effective_row_statuses", ["allocated"],
           "must match ContactAllocation effective row statuses"},
          {"station_unavailable_aliases", ["offline"],
           "must match ContactAllocation station unavailable aliases"},
          {"station_blocking_availability", ["reserved"],
           "must match ContactAllocation station blocking availability"},
          {"station_availability_precedence", %{"available" => 99},
           "must match ContactAllocation station availability precedence"},
          {"capacity_pack_statuses", ["none"],
           "must match ContactAllocation capacity pack statuses"},
          {"reduced_capacity_pack_statuses", ["none"],
           "must match ContactAllocation reduced capacity pack statuses"},
          {"station_reservation_match_statuses", ["none"],
           "must match ContactAllocation station reservation match statuses"},
          {"station_reservation_expiration_statuses", ["none"],
           "must match ContactAllocation station reservation expiration statuses"},
          {"required_capacity_fraction_source_values", ["none"],
           "must match ContactAllocation required capacity fraction source values"},
          {"required_capacity_value_paths", [],
           "must match ContactAllocation required capacity value paths"},
          {"default_required_capacity_value_paths", [],
           "must match ContactAllocation default required capacity value paths"},
          {"provider_direction_aliases", %{"dl" => "command"},
           "must match ContactAllocation provider direction aliases"}
        ] do
      stale_summary_assumption = put_in(summary, ["assumptions", field], stale_value)

      assert {:error, stale_summary_assumption_errors} =
               Schema.validate_artifact(stale_summary_assumption)

      assert Enum.any?(
               stale_summary_assumption_errors["errors"],
               &(&1["path"] == "$.assumptions.#{field}" and
                   &1["message"] == expected_message)
             )
    end

    omitted_summary_capability_assumptions =
      drop_contact_allocation_summary_capability_assumptions(summary)

    assert {:ok, %{"schema_contract" => "contact_allocation_summary.v1"}} =
             Schema.validate_artifact(omitted_summary_capability_assumptions)

    assert_summary_handoff(
      summary,
      &ContactAllocation.summary/1,
      &ContactAllocation.summary(&1, now_s: 999.0),
      &OrbitalDynamics.contact_allocation_summary/1,
      &OrbitalDynamics.contact_allocation_summary(&1, now_s: 999.0)
    )

    expected_station_pressure_capability_assumptions =
      contact_allocation_station_pressure_capability_assumptions()

    expected_station_unavailable_aliases =
      expected_station_pressure_capability_assumptions["station_unavailable_aliases"]

    expected_station_blocking_availability =
      expected_station_pressure_capability_assumptions["station_blocking_availability"]

    expected_station_availability_precedence =
      expected_station_pressure_capability_assumptions["station_availability_precedence"]

    expected_provider_direction_aliases =
      expected_station_pressure_capability_assumptions["provider_direction_aliases"]

    assert %{
             "schema_contract" => "contact_allocation_station_pressure_summary.v1",
             "model" => "artifact_only_contact_allocation_station_pressure_summary",
             "model_limits" => station_pressure_model_limits,
             "source_artifact_type" => "contact_allocation_report.v1",
             "source" => "unit_test.contacts",
             "input_contact_count" => 3,
             "station_pressure_contact_count" => 1,
             "station_pressure_review_contact_count" => 1,
             "station_pressure_contact_ids" => ["dl_3"],
             "station_pressure_review_contact_ids" => ["dl_3"],
             "station_pressure_contact_ids_by_ground_station_id" => %{
               "equator_prime" => ["dl_3"]
             },
             "station_pressure_contact_counts_by_ground_station_id" => %{
               "equator_prime" => 1
             },
             "station_pressure_contact_ids_by_availability" => %{"reserved" => ["dl_3"]},
             "station_pressure_contact_counts_by_availability" => %{"reserved" => 1},
             "station_pressure_contact_ids_by_precedence_availability" => %{},
             "station_pressure_contact_counts_by_precedence_availability" => %{},
             "station_pressure_contact_ids_by_precedence_rank" => %{},
             "station_pressure_contact_counts_by_precedence_rank" => %{},
             "rows" => station_pressure_source_rows,
             "review_rows" => station_pressure_review_rows,
             "assumptions" => %{
               "execution_boundary" =>
                 "artifact_only_no_provider_reservation_or_schedule_mutation",
               "source" => "contact_allocation_report.v1",
               "operator_authority" => "not_granted_by_station_pressure_summary",
               "station_unavailable_aliases" => ^expected_station_unavailable_aliases,
               "station_blocking_availability" => ^expected_station_blocking_availability,
               "station_availability_precedence" => ^expected_station_availability_precedence,
               "provider_direction_aliases" => ^expected_provider_direction_aliases
             }
           } = station_pressure_summary = ContactAllocation.station_pressure_summary(report)

    assert station_pressure_model_limits ==
             ContactAllocation.capabilities().known_limits
             |> Enum.map(&Atom.to_string/1)

    assert length(station_pressure_source_rows) == 3
    assert Enum.map(station_pressure_review_rows, & &1["contact_id"]) == ["dl_3"]

    assert {:ok, %{"schema_contract" => "contact_allocation_station_pressure_summary.v1"}} =
             Schema.validate_artifact(station_pressure_summary)

    assert {:ok, station_pressure_schema} =
             Schema.json_schema("contact_allocation_station_pressure_summary.v1")

    assert get_in(station_pressure_schema, ["properties", "model", "const"]) ==
             "artifact_only_contact_allocation_station_pressure_summary"

    assert get_in(station_pressure_schema, ["properties", "model_limits", "const"]) ==
             station_pressure_model_limits

    assert get_in(station_pressure_schema, ["properties", "model_limits", "items", "enum"]) ==
             station_pressure_model_limits

    station_pressure_assumptions_schema =
      get_in(station_pressure_schema, ["properties", "assumptions", "properties"])

    assert get_in(station_pressure_assumptions_schema, [
             "station_unavailable_aliases",
             "const"
           ]) == expected_station_unavailable_aliases

    assert get_in(station_pressure_assumptions_schema, [
             "station_blocking_availability",
             "const"
           ]) == expected_station_blocking_availability

    assert get_in(station_pressure_assumptions_schema, [
             "station_availability_precedence",
             "const"
           ]) == expected_station_availability_precedence

    assert get_in(station_pressure_assumptions_schema, [
             "provider_direction_aliases",
             "const"
           ]) == expected_provider_direction_aliases

    stale_station_pressure_model =
      Map.put(
        station_pressure_summary,
        "model",
        "stale_contact_allocation_station_pressure_summary"
      )

    assert {:error, stale_station_pressure_model_errors} =
             Schema.validate_artifact(stale_station_pressure_model)

    assert Enum.any?(
             stale_station_pressure_model_errors["errors"],
             &(&1["path"] == "$.model" and
                 &1["message"] ==
                   "must equal \"artifact_only_contact_allocation_station_pressure_summary\"")
           )

    stale_station_pressure_model_limits =
      Map.put(station_pressure_summary, "model_limits", ["artifact_level_only"])

    assert {:error, stale_station_pressure_model_limits_errors} =
             Schema.validate_artifact(stale_station_pressure_model_limits)

    assert Enum.any?(
             stale_station_pressure_model_limits_errors["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] == "must match contact allocation model limits")
           )

    stale_station_pressure_count =
      Map.put(station_pressure_summary, "station_pressure_contact_count", 0)

    assert {:error, stale_station_pressure_count_errors} =
             Schema.validate_artifact(stale_station_pressure_count)

    assert Enum.any?(
             stale_station_pressure_count_errors["errors"],
             &(&1["path"] == "$.station_pressure_contact_count" and
                 &1["message"] == "must equal row-derived station_pressure_contact_count")
           )

    stale_station_pressure_review_rows =
      Map.update!(station_pressure_summary, "rows", fn rows ->
        Enum.map(rows, fn
          %{"contact_id" => "dl_3"} = row ->
            row
            |> Map.put("allocation_status", "allocated")
            |> Map.put("effective_allocation_status", "allocated")
            |> Map.put("review_status", "accepted_for_planning")

          row ->
            row
        end)
      end)

    assert {:error, stale_station_pressure_review_row_errors} =
             Schema.validate_artifact(stale_station_pressure_review_rows)

    assert Enum.any?(
             stale_station_pressure_review_row_errors["errors"],
             &(&1["path"] == "$.review_rows" and
                 &1["message"] == "must equal row-derived review_rows")
           )

    for {field, stale_value, expected_message} <- [
          {"station_unavailable_aliases", ["offline"],
           "must match ContactAllocation station unavailable aliases"},
          {"station_blocking_availability", ["reserved"],
           "must match ContactAllocation station blocking availability"},
          {"station_availability_precedence", %{"available" => 99},
           "must match ContactAllocation station availability precedence"},
          {"provider_direction_aliases", %{"dl" => "command"},
           "must match ContactAllocation provider direction aliases"}
        ] do
      stale_station_pressure_assumption =
        put_in(station_pressure_summary, ["assumptions", field], stale_value)

      assert {:error, stale_station_pressure_assumption_errors} =
               Schema.validate_artifact(stale_station_pressure_assumption)

      assert Enum.any?(
               stale_station_pressure_assumption_errors["errors"],
               &(&1["path"] == "$.assumptions.#{field}" and
                   &1["message"] == expected_message)
             )
    end

    omitted_station_pressure_capability_assumptions =
      drop_contact_allocation_station_pressure_capability_assumptions(station_pressure_summary)

    assert {:ok, %{"schema_contract" => "contact_allocation_station_pressure_summary.v1"}} =
             Schema.validate_artifact(omitted_station_pressure_capability_assumptions)

    assert_summary_handoff(
      station_pressure_summary,
      &ContactAllocation.station_pressure_summary/1,
      &ContactAllocation.station_pressure_summary(&1, now_s: 999.0),
      &OrbitalDynamics.contact_allocation_station_pressure_summary/1,
      &OrbitalDynamics.contact_allocation_station_pressure_summary(&1, now_s: 999.0)
    )

    assert ContactAllocation.station_pressure_summary(contacts, ground_network,
             source: "unit_test.contacts",
             approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
           ) == station_pressure_summary

    assert OrbitalDynamics.contact_allocation_station_pressure_summary(report) ==
             station_pressure_summary

    assert OrbitalDynamics.contact_allocation_station_pressure_summary(contacts, ground_network,
             source: "unit_test.contacts",
             approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
           ) == station_pressure_summary

    assert %{
             "station_reservation_expiration_now_s" => 400.0,
             "station_reservation_expiration_status_counts" => %{"active" => 1},
             "station_reservation_active_contact_count" => 1,
             "station_reservation_expired_contact_count" => 0,
             "station_reservation_contact_ids_by_expiration_status" => %{
               "active" => ["dl_3"]
             },
             "station_reservation_ids_by_expiration_status" => %{
               "active" => ["reservation_1"]
             }
           } = ContactAllocation.summary(report, now_s: 400.0)

    assert %{
             "station_reservation_expiration_now_s" => 500.0,
             "station_reservation_expiration_status_counts" => %{"expired" => 1},
             "station_reservation_expired_contact_count" => 1,
             "station_reservation_contact_ids_by_expiration_status" => %{
               "expired" => ["dl_3"]
             }
           } = OrbitalDynamics.contact_allocation_summary(report, now_s: 500.0)

    stale_reason_routing_report =
      Map.put(report, "contact_ids_by_allocation_reason", %{"stale_reason" => ["stale"]})

    assert %{
             "contact_ids_by_allocation_reason" => %{
               "ground_station_reserved" => ["dl_3"],
               "same_station_contention" => ["dl_2"],
               "selected_by_contention_resolution" => ["dl_1"]
             }
           } = ContactAllocation.summary(stale_reason_routing_report)

    stale_status_station_routing_report =
      report
      |> Map.put("allocated_contact_ids_by_ground_station_id", %{"stale" => ["stale_allocated"]})
      |> Map.put("deferred_contact_ids_by_ground_station_id", %{"stale" => ["stale_deferred"]})
      |> Map.put("blocked_contact_ids_by_ground_station_id", %{"stale" => ["stale_blocked"]})

    assert %{
             "allocated_contact_ids_by_ground_station_id" => %{
               "equator_prime" => ["dl_1"]
             },
             "deferred_contact_ids_by_ground_station_id" => %{
               "equator_prime" => ["dl_2"]
             },
             "blocked_contact_ids_by_ground_station_id" => %{
               "equator_prime" => ["dl_3"]
             }
           } = ContactAllocation.summary(stale_status_station_routing_report)

    duplicate_review_row_report =
      Map.put(report, "rows", [
        Enum.at(report["rows"], 2),
        Enum.at(report["rows"], 0),
        Enum.at(report["rows"], 1),
        Enum.at(report["rows"], 2)
      ])

    assert %{"review_contact_ids" => ["dl_1", "dl_2", "dl_3"]} =
             ContactAllocation.summary(duplicate_review_row_report)

    assert ContactAllocation.summary(contacts, ground_network,
             source: "unit_test.contacts",
             approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
           ) == summary

    assert %{
             "station_reservation_expiration_now_s" => 500.0,
             "station_reservation_expiration_status_counts" => %{"expired" => 1}
           } =
             ContactAllocation.summary(contacts, ground_network,
               source: "unit_test.contacts",
               approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"},
               now_s: 500.0
             )

    assert OrbitalDynamics.contact_allocation_summary(report) == summary

    assert OrbitalDynamics.contact_allocation_summary(contacts, ground_network,
             source: "unit_test.contacts",
             approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
           ) == summary

    stale_count_report =
      Map.merge(report, %{
        "input_contact_count" => 99,
        "allocated_contact_count" => 99,
        "returned_allocated_contact_count" => 99,
        "policy_blocked_allocated_contact_count" => 99,
        "deferred_contact_count" => 99,
        "blocked_contact_count" => 99,
        "invalid_contact_input_count" => 99,
        "status_blocked_contact_count" => 99,
        "resource_blocked_contact_count" => 99,
        "duplicate_contact_id_count" => 99
      })

    assert %{
             "input_contact_count" => 3,
             "allocated_contact_count" => 1,
             "returned_allocated_contact_count" => 1,
             "policy_blocked_allocated_contact_count" => 0,
             "deferred_contact_count" => 1,
             "blocked_contact_count" => 1,
             "invalid_contact_input_count" => 0,
             "status_blocked_contact_count" => 0,
             "resource_blocked_contact_count" => 0,
             "duplicate_contact_id_count" => 0
           } = ContactAllocation.summary(stale_count_report)

    stale_id_report =
      Map.merge(report, %{
        "station_reservation_ids" => ["stale_reservation"],
        "station_calendar_trust_boundary_status_counts" => %{"stale" => 1},
        "invalid_contact_input_ids" => ["stale_invalid_contact"],
        "status_blocked_contact_ids" => ["stale_status_contact"],
        "resource_blocked_contact_ids" => ["stale_resource_contact"]
      })

    assert %{
             "station_reservation_ids" => ["reservation_1"],
             "station_calendar_trust_boundary_status_counts" => %{},
             "invalid_contact_input_ids" => [],
             "status_blocked_contact_ids" => [],
             "resource_blocked_contact_ids" => []
           } = ContactAllocation.summary(stale_id_report)
  end

  test "summary derives station status routing maps from existing rows" do
    report = %{
      schema_contract: "contact_allocation_report.v1",
      source: "unit_test.existing_contact_allocation_report",
      allocation_status_counts: %{"blocked" => 99},
      effective_allocation_status_counts: %{"allocated" => 99},
      allocation_reason_counts: %{"stale_reason" => 99},
      rows: [
        %{
          contact_id: :dl_outage,
          allocation_status: :blocked,
          effective_allocation_status: :blocked,
          allocation_reason: :ground_station_reserved,
          review_status: :operator_review_required,
          ground_station_id: :equator_prime,
          station_calendar_overlap_count: 1,
          station_calendar_overlap_availabilities: ["Offline", :reserved],
          station_reservation_match_status: "Owner Matched",
          station_calendar_reservation_statuses: ["Confirmed"]
        },
        %{
          "contact_id" => "dl_reserved",
          "allocation_status" => "allocated",
          "effective_allocation_status" => "allocated",
          "allocation_reason" => "selected_by_contention_resolution",
          "review_status" => "operator_review_required",
          "ground_station_id" => "polar_prime",
          "station_calendar_entry_id" => "calendar_entry_1",
          "station_calendar_overlap_availabilities" => "Reserved",
          "station_reservation_match_status" => "owner-matched"
        },
        %{
          "contact_id" => "dl_direct_maintenance",
          "allocation_status" => "blocked",
          "effective_allocation_status" => "blocked",
          "allocation_reason" => "ground_station_unavailable",
          "review_status" => "operator_review_required",
          "ground_station_id" => "polar_prime",
          "station_calendar_entry_id" => "calendar_entry_2",
          "station_availability" => "Maintenance"
        }
      ],
      station_reservation_match_status_counts: %{
        "Owner Matched" => 1,
        :"owner-matched" => 1,
        "Overlap" => 1
      }
    }

    assert %{
             "allocation_status_counts" => %{
               "allocated" => 1,
               "blocked" => 2
             },
             "effective_allocation_status_counts" => %{
               "allocated" => 1,
               "blocked" => 2
             },
             "allocation_reason_counts" => %{
               "ground_station_reserved" => 1,
               "ground_station_unavailable" => 1,
               "selected_by_contention_resolution" => 1
             },
             "station_reservation_match_status_counts" => %{
               "owner_matched" => 2
             },
             "station_reservation_expiration_status_counts" => %{"missing" => 2},
             "station_reservation_missing_expiration_contact_count" => 2,
             "station_reservation_contact_ids_by_match_status" => %{
               "owner_matched" => ["dl_outage", "dl_reserved"]
             },
             "station_reservation_contact_ids_by_expiration_status" => %{
               "missing" => ["dl_outage", "dl_reserved"]
             },
             "station_pressure_contact_ids_by_availability" => %{
               "maintenance" => ["dl_direct_maintenance"],
               "reserved" => ["dl_outage", "dl_reserved"],
               "unavailable" => ["dl_outage"]
             },
             "station_pressure_contact_counts_by_availability" => %{
               "maintenance" => 1,
               "reserved" => 2,
               "unavailable" => 1
             },
             "review_contact_ids" => ["dl_direct_maintenance", "dl_outage", "dl_reserved"],
             "review_rows" => review_rows
           } = OrbitalDynamics.contact_allocation_summary(report)

    assert %{
             "contact_id" => "dl_outage",
             "station_calendar_overlap_availabilities" => ["unavailable", "reserved"],
             "station_calendar_reservation_statuses" => ["confirmed"],
             "station_reservation_match_status" => "owner_matched"
           } = Enum.find(review_rows, &(&1["contact_id"] == "dl_outage"))
  end

  test "derives allocation row station-calendar counts from id sets" do
    {_allocated, report} =
      ContactAllocation.allocate_contacts(
        [
          contact(:stale_calendar_counts,
            station_calendar_overlap_count: 99,
            station_calendar_overlap_entry_ids: [:station_a, :station_b],
            station_calendar_ambiguous_entry_count: 99,
            station_calendar_ambiguous_entry_ids: [:station_b],
            station_calendar_reservation_overlap_count: 99,
            station_calendar_reservation_ids: [:reservation_1]
          )
        ],
        []
      )

    assert [
             %{
               "station_calendar_overlap_count" => 2,
               "station_calendar_overlap_entry_ids" => ["station_a", "station_b"],
               "station_calendar_ambiguous_entry_count" => 1,
               "station_calendar_ambiguous_entry_ids" => ["station_b"],
               "station_calendar_reservation_overlap_count" => 1,
               "station_calendar_reservation_ids" => ["reservation_1"]
             }
           ] = report["rows"]

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)

    stale_overlap_count =
      put_in(report, ["rows", Access.at(0), "station_calendar_overlap_count"], 1)

    assert {:error, overlap_validation} = Schema.validate_artifact(stale_overlap_count)

    assert Enum.any?(
             overlap_validation["errors"],
             &(&1["path"] == "$.rows[0].station_calendar_overlap_count" and
                 &1["message"] == "must equal 2")
           )

    stale_ambiguous_count =
      put_in(report, ["rows", Access.at(0), "station_calendar_ambiguous_entry_count"], 2)

    assert {:error, ambiguous_validation} = Schema.validate_artifact(stale_ambiguous_count)

    assert Enum.any?(
             ambiguous_validation["errors"],
             &(&1["path"] == "$.rows[0].station_calendar_ambiguous_entry_count" and
                 &1["message"] == "must equal 1")
           )

    stale_reservation_count =
      put_in(report, ["rows", Access.at(0), "station_calendar_reservation_overlap_count"], 2)

    assert {:error, reservation_validation} = Schema.validate_artifact(stale_reservation_count)

    assert Enum.any?(
             reservation_validation["errors"],
             &(&1["path"] == "$.rows[0].station_calendar_reservation_overlap_count" and
                 &1["message"] == "must equal 1")
           )
  end

  test "allocation honors priority-aware contention resolution policy" do
    contacts = [
      contact(:routine_downlink,
        starts_at_s: 100.0,
        ends_at_s: 160.0,
        score: 20.0,
        contention_priority: 1.0
      ),
      contact(:urgent_command,
        type: :command,
        direction: :uplink,
        starts_at_s: 120.0,
        ends_at_s: 150.0,
        score: 2.0,
        contention_priority: 10.0
      )
    ]

    {allocated, report} =
      ContactAllocation.allocate_contacts(contacts, [],
        policy: %{selection_rule: :highest_priority_highest_score}
      )

    assert [
             %{
               "id" => "urgent_command",
               "selected_priority" => 10.0,
               "selected_priority_source" => "contention_priority",
               "deferred_contact_priorities" => [
                 %{"contact_id" => "routine_downlink", "priority" => 1.0}
               ]
             }
           ] = allocated

    assert %{
             "contact_contention_resolution_report" => %{
               "policy" => %{"selection_rule" => "highest_priority_highest_score"},
               "recommendations" => [
                 %{
                   "selected_contact_id" => "urgent_command",
                   "selected_priority" => 10.0,
                   "deferred_contact_ids" => ["routine_downlink"]
                 }
               ]
             }
           } = report

    assert %{
             "contact_id" => "routine_downlink",
             "allocation_status" => "deferred",
             "selected_contact_id" => "urgent_command",
             "selected_priority" => 10.0,
             "selected_priority_source" => "contention_priority",
             "deferred_contact_priorities" => [
               %{"contact_id" => "routine_downlink", "priority" => 1.0}
             ]
           } = Enum.find(report["rows"], &(&1["contact_id"] == "routine_downlink"))

    assert %{
             "contact_id" => "urgent_command",
             "allocation_status" => "allocated",
             "allocation_reason" => "selected_by_contention_resolution",
             "selected_priority" => 10.0,
             "selected_priority_source" => "contention_priority",
             "deferred_contact_priorities" => [
               %{"contact_id" => "routine_downlink", "priority" => 1.0}
             ]
           } = Enum.find(report["rows"], &(&1["contact_id"] == "urgent_command"))

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "allocation preserves custom priority field evidence from contention resolution" do
    contacts = [
      contact(:routine_downlink,
        starts_at_s: 100.0,
        ends_at_s: 160.0,
        score: 20.0
      ),
      contact(:priority_command,
        type: :command,
        direction: :uplink,
        starts_at_s: 120.0,
        ends_at_s: 150.0,
        score: 2.0,
        priority: "5.0"
      )
    ]

    {allocated, report} =
      ContactAllocation.allocate_contacts(contacts, [],
        policy: %{
          selection_rule: :highest_priority_highest_score,
          priority_fields: [:missing_priority, :priority]
        }
      )

    assert [
             %{
               "id" => "priority_command",
               "selected_priority_source" => "priority",
               "requested_priority_fields" => ["missing_priority", "priority"],
               "priority_field_evidence_counts" => %{
                 "missing_priority" => 0,
                 "priority" => 1
               },
               "priority_fields_without_numeric_evidence_count" => 1,
               "priority_fields_without_numeric_evidence" => ["missing_priority"]
             }
           ] = allocated

    assert %{
             "contact_contention_resolution_report" => %{
               "recommendations" => [
                 %{
                   "selected_contact_id" => "priority_command",
                   "requested_priority_fields" => ["missing_priority", "priority"],
                   "priority_field_evidence_counts" => %{
                     "missing_priority" => 0,
                     "priority" => 1
                   },
                   "priority_fields_without_numeric_evidence_count" => 1,
                   "priority_fields_without_numeric_evidence" => ["missing_priority"]
                 }
               ]
             }
           } = report

    assert %{
             "contact_id" => "routine_downlink",
             "allocation_status" => "deferred",
             "selected_contact_id" => "priority_command",
             "requested_priority_fields" => ["missing_priority", "priority"],
             "priority_field_evidence_counts" => %{
               "missing_priority" => 0,
               "priority" => 1
             },
             "priority_fields_without_numeric_evidence_count" => 1,
             "priority_fields_without_numeric_evidence" => ["missing_priority"]
           } = Enum.find(report["rows"], &(&1["contact_id"] == "routine_downlink"))

    review = OperatorReview.from_contact_allocation_report(report)

    assert %{
             "review_type" => "contact_allocation_review",
             "contact_id" => "priority_command",
             "requested_priority_fields" => ["missing_priority", "priority"],
             "priority_field_evidence_counts" => %{
               "missing_priority" => 0,
               "priority" => 1
             },
             "priority_fields_without_numeric_evidence_count" => 1,
             "priority_fields_without_numeric_evidence" => ["missing_priority"],
             "source_contact_allocation" => %{
               "priority_fields_without_numeric_evidence_count" => 1,
               "priority_fields_without_numeric_evidence" => ["missing_priority"]
             }
           } = Enum.find(review["rows"], &(&1["contact_id"] == "priority_command"))

    manifest = CadenceImport.from_contact_allocation_report(report)

    assert %{
             "import_action" => "review_contact_allocation",
             "contact_id" => "routine_downlink",
             "requested_priority_fields" => ["missing_priority", "priority"],
             "priority_field_evidence_counts" => %{
               "missing_priority" => 0,
               "priority" => 1
             },
             "priority_fields_without_numeric_evidence_count" => 1,
             "priority_fields_without_numeric_evidence" => ["missing_priority"],
             "source_contact_allocation" => %{
               "priority_field_evidence_counts" => %{
                 "missing_priority" => 0,
                 "priority" => 1
               },
               "priority_fields_without_numeric_evidence_count" => 1
             }
           } = Enum.find(manifest["rows"], &(&1["contact_id"] == "routine_downlink"))

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "allocation preserves reservation aliases selected by contention priority" do
    contacts = [
      contact(:high_score_unreserved, starts_at_s: 100.0, ends_at_s: 160.0, score: 20.0),
      contact(:alias_reserved_candidate,
        starts_at_s: 120.0,
        ends_at_s: 150.0,
        score: 2.0,
        reservation_id: :reservation_alpha,
        reserved_by: :leo_2,
        reservation_status: :confirmed,
        reservation_match_status: :matched
      )
    ]

    {allocated, report} =
      ContactAllocation.allocate_contacts(contacts, [],
        policy: %{
          selection_rule: :highest_priority_highest_score,
          priority_fields: [:station_reservation_priority]
        }
      )

    assert [
             %{
               "id" => "alias_reserved_candidate",
               "selected_priority" => 1.0,
               "selected_priority_source" => "station_reservation_priority",
               "station_reservation_id" => "reservation_alpha",
               "station_reserved_by" => "leo_2",
               "station_reservation_status" => "confirmed",
               "station_reservation_match_status" => "matched"
             }
           ] = allocated

    assert %{
             "contact_contention_resolution_report" => %{
               "recommendations" => [
                 %{
                   "selected_contact_id" => "alias_reserved_candidate",
                   "selected_priority_source" => "station_reservation_priority",
                   "station_reservation_ids" => ["reservation_alpha"],
                   "station_reserved_bys" => ["leo_2"],
                   "station_reservation_statuses" => ["confirmed"],
                   "station_reservation_match_statuses" => ["matched"]
                 }
               ]
             }
           } = report

    assert %{
             "contact_id" => "alias_reserved_candidate",
             "allocation_status" => "allocated",
             "allocation_reason" => "selected_by_contention_resolution",
             "selected_priority_source" => "station_reservation_priority",
             "station_reservation_id" => "reservation_alpha",
             "station_reserved_by" => "leo_2",
             "station_reservation_status" => "confirmed",
             "station_reservation_match_status" => "matched"
           } = Enum.find(report["rows"], &(&1["contact_id"] == "alias_reserved_candidate"))

    assert %{
             "contact_id" => "high_score_unreserved",
             "allocation_status" => "deferred",
             "selected_contact_id" => "alias_reserved_candidate",
             "selected_priority_source" => "station_reservation_priority"
           } = Enum.find(report["rows"], &(&1["contact_id"] == "high_score_unreserved"))

    review = OperatorReview.from_contact_allocation_report(report)

    assert %{
             "review_type" => "contact_allocation_review",
             "contact_id" => "alias_reserved_candidate",
             "allocation_status" => "allocated",
             "selected_priority_source" => "station_reservation_priority",
             "station_reservation_id" => "reservation_alpha",
             "station_reserved_by" => "leo_2",
             "station_reservation_status" => "confirmed",
             "station_reservation_match_status" => "matched",
             "source_contact_allocation" => %{
               "station_reservation_id" => "reservation_alpha",
               "station_reservation_match_status" => "matched"
             }
           } = Enum.find(review["rows"], &(&1["contact_id"] == "alias_reserved_candidate"))

    manifest = CadenceImport.from_contact_allocation_report(report)

    assert %{
             "import_action" => "review_contact_allocation",
             "contact_id" => "alias_reserved_candidate",
             "allocation_status" => "allocated",
             "selected_priority_source" => "station_reservation_priority",
             "station_reservation_id" => "reservation_alpha",
             "station_reserved_by" => "leo_2",
             "station_reservation_status" => "confirmed",
             "station_reservation_match_status" => "matched",
             "source_contact_allocation" => %{
               "station_reservation_id" => "reservation_alpha",
               "station_reservation_match_status" => "matched"
             }
           } = Enum.find(manifest["rows"], &(&1["contact_id"] == "alias_reserved_candidate"))

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)

    assert %{
             "station_reservation_contact_ids_by_match_status" => %{
               "matched" => ["alias_reserved_candidate"]
             }
           } = ContactAllocation.summary(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "honors station-calendar direction aliases through allocation filtering" do
    contacts = [
      contact(:dl_1,
        starts_at_s: 100.0,
        ends_at_s: 160.0,
        direction: "Down Link"
      ),
      contact(:tracking_1,
        type: :tracking,
        starts_at_s: 105.0,
        ends_at_s: 140.0,
        direction: "Track-ing"
      ),
      contact(:command_1,
        type: :planned_contact,
        starts_at_s: 110.0,
        ends_at_s: 130.0,
        direction: "commands"
      )
    ]

    ground_network = [
      %{
        id: :tracking_outage,
        ground_station_id: :equator_prime,
        status: :maintenance,
        station_calendar_directions: [:tracking],
        starts_at_s: 90.0,
        ends_at_s: 170.0
      },
      %{
        id: :command_outage,
        ground_station_id: :equator_prime,
        status: :maintenance,
        station_calendar_directions: [:command],
        starts_at_s: 90.0,
        ends_at_s: 170.0
      }
    ]

    {allocated, report} =
      ContactAllocation.allocate_contacts(contacts, ground_network,
        source: "unit_test.direction_aliases"
      )

    assert Enum.map(allocated, & &1["id"]) == ["dl_1"]

    assert %{
             "contact_id" => "command_1",
             "allocation_status" => "blocked",
             "effective_allocation_status" => "blocked",
             "allocation_reason" => "ground_station_unavailable",
             "direction" => "command",
             "station_calendar_entry_id" => "command_outage",
             "station_calendar_directions" => ["command"],
             "source_station_calendar_entry" => %{
               "directions" => ["command"]
             }
           } = Enum.find(report["rows"], &(&1["contact_id"] == "command_1"))

    assert %{
             "contact_id" => "tracking_1",
             "allocation_status" => "blocked",
             "effective_allocation_status" => "blocked",
             "allocation_reason" => "ground_station_unavailable",
             "direction" => "tracking",
             "station_calendar_entry_id" => "tracking_outage",
             "station_calendar_directions" => ["tracking"],
             "source_station_calendar_entry" => %{
               "directions" => ["tracking"]
             }
           } = Enum.find(report["rows"], &(&1["contact_id"] == "tracking_1"))

    refute Enum.any?(
             report["rows"],
             &(&1["contact_id"] == "dl_1" and &1["allocation_status"] == "blocked")
           )

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "preserves declared station-calendar trust evidence on allocation review and import rows" do
    contacts = [
      contact(:dl_declared_trust, starts_at_s: 100.0, ends_at_s: 160.0)
    ]

    station_calendar_provider = %{
      schema_contract: "station_calendar_provider.v1",
      provider_id: "ground_partner_a",
      trust_boundary: "ground_partner_api",
      entries: [
        %{
          id: "partner_reduced_capacity",
          ground_station_id: :equator_prime,
          directions: [:downlink],
          status: :available,
          capacity_fraction: 0.4,
          starts_at_s: 90.0,
          ends_at_s: 170.0
        }
      ]
    }

    {_allocated, report} =
      ContactAllocation.allocate_contacts(contacts, station_calendar_provider,
        source: "unit_test.trusted_station_calendar",
        approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
      )

    assert report["station_calendar_trust_boundary_status_counts"] == %{"declared" => 1}
    assert report["calendar_entry_trust_boundary_status_counts"] == %{"declared" => 1}

    assert [
             %{
               "contact_id" => "dl_declared_trust",
               "allocation_status" => "allocated",
               "station_availability" => "reduced_capacity",
               "station_calendar_entry_id" => "partner_reduced_capacity",
               "station_calendar_provider_id" => "ground_partner_a",
               "station_calendar_provider_entry_id" => "partner_reduced_capacity",
               "station_calendar_directions" => ["downlink"],
               "station_calendar_trust_boundary_status" => "declared",
               "trust_boundary" => "ground_partner_api",
               "provenance" => %{
                 "source" => "station_calendar_provider",
                 "provider_id" => "ground_partner_a",
                 "trust_boundary" => "ground_partner_api"
               },
               "source_station_calendar_entry" => %{
                 "id" => "partner_reduced_capacity",
                 "provenance" => %{"trust_boundary" => "ground_partner_api"}
               },
               "source_station_calendar_overlaps" => [
                 %{"id" => "partner_reduced_capacity"}
               ],
               "approval_requirements" => [
                 %{
                   "activity_context" => %{
                     "station_calendar_entry_id" => "partner_reduced_capacity",
                     "station_calendar_provider_id" => "ground_partner_a",
                     "station_calendar_provider_entry_id" => "partner_reduced_capacity",
                     "station_calendar_directions" => ["downlink"],
                     "station_calendar_trust_boundary_status" => "declared",
                     "trust_boundary" => "ground_partner_api",
                     "source_station_calendar_entry" => %{"id" => "partner_reduced_capacity"}
                   }
                 }
               ]
             }
           ] = report["rows"]

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)

    invalid_ratio =
      put_in(report, ["rows", Access.at(0), "downlink_completion_ratio"], 1.5)

    assert {:error, invalid_ratio_report} = Schema.validate_artifact(invalid_ratio)

    assert Enum.any?(
             invalid_ratio_report["errors"],
             &(&1["path"] == "$.rows[0].downlink_completion_ratio")
           )

    invalid_sources =
      put_in(report, ["rows", Access.at(0), "downlink_completion_sources"], [42])

    assert {:error, invalid_sources_report} = Schema.validate_artifact(invalid_sources)

    assert Enum.any?(
             invalid_sources_report["errors"],
             &(&1["path"] == "$.rows[0].downlink_completion_sources[0]")
           )

    invalid_directions =
      put_in(report, ["rows", Access.at(0), "station_calendar_directions"], [42])

    assert {:error, invalid_directions_report} = Schema.validate_artifact(invalid_directions)

    assert Enum.any?(
             invalid_directions_report["errors"],
             &(&1["path"] == "$.rows[0].station_calendar_directions[0]")
           )

    invalid_provenance =
      put_in(report, ["rows", Access.at(0), "provenance"], "ground_partner_api")

    assert {:error, invalid_provenance_report} = Schema.validate_artifact(invalid_provenance)

    assert Enum.any?(
             invalid_provenance_report["errors"],
             &(&1["path"] == "$.rows[0].provenance")
           )

    invalid_provider_id =
      put_in(report, ["rows", Access.at(0), "station_calendar_provider_id"], "bad provider")

    assert {:error, invalid_provider_id_report} = Schema.validate_artifact(invalid_provider_id)

    assert Enum.any?(
             invalid_provider_id_report["errors"],
             &(&1["path"] == "$.rows[0].station_calendar_provider_id")
           )

    review = OperatorReview.from_contact_allocation_report(report)

    assert review["calendar_entry_trust_boundary_status_counts"] == %{"declared" => 1}

    assert [
             %{
               "review_type" => "contact_allocation_review",
               "station_calendar_entry_id" => "partner_reduced_capacity",
               "station_calendar_provider_id" => "ground_partner_a",
               "station_calendar_provider_entry_id" => "partner_reduced_capacity",
               "station_calendar_directions" => ["downlink"],
               "station_calendar_trust_boundary_status" => "declared",
               "trust_boundary" => "ground_partner_api",
               "provenance" => %{"provider_id" => "ground_partner_a"},
               "source_station_calendar_entry" => %{"id" => "partner_reduced_capacity"},
               "source_station_calendar_overlaps" => [
                 %{"id" => "partner_reduced_capacity"}
               ]
             }
           ] = review["rows"]

    manifest = CadenceImport.from_contact_allocation_report(report)

    assert manifest["calendar_entry_trust_boundary_status_counts"] == %{"declared" => 1}

    assert [
             %{
               "import_action" => "review_contact_allocation",
               "station_calendar_entry_id" => "partner_reduced_capacity",
               "station_calendar_provider_id" => "ground_partner_a",
               "station_calendar_provider_entry_id" => "partner_reduced_capacity",
               "station_calendar_directions" => ["downlink"],
               "station_calendar_trust_boundary_status" => "declared",
               "trust_boundary" => "ground_partner_api",
               "provenance" => %{"provider_id" => "ground_partner_a"},
               "source_station_calendar_entry" => %{"id" => "partner_reduced_capacity"},
               "source_station_calendar_overlaps" => [
                 %{"id" => "partner_reduced_capacity"}
               ]
             }
           ] = manifest["rows"]
  end

  test "accepts station calendar provider artifact lists directly" do
    contacts = [
      contact(:dl_partner_list, starts_at_s: 100.0, ends_at_s: 160.0)
    ]

    station_calendar_providers = [
      %{
        schema_contract: "station_calendar_provider.v1",
        provider_id: "ground_partner_aux",
        trust_boundary: "ground_partner_api",
        entries: [
          %{
            id: "aux_available",
            ground_station_id: :polar_aux,
            status: :available,
            starts_at_s: 90.0,
            ends_at_s: 170.0
          }
        ]
      },
      %{
        schema_contract: "station_calendar_provider.v1",
        provider_id: "ground_partner_primary",
        trust_boundary: "ground_partner_api",
        entries: [
          %{
            id: "primary_reduced_capacity",
            ground_station_id: :equator_prime,
            directions: [:downlink],
            status: :available,
            capacity_fraction: 0.4,
            starts_at_s: 90.0,
            ends_at_s: 170.0
          }
        ]
      }
    ]

    {allocated, report} =
      ContactAllocation.allocate_contacts(contacts, station_calendar_providers,
        source: "unit_test.provider_list"
      )

    assert [
             %{
               "id" => "dl_partner_list",
               "station_calendar_provider_id" => "ground_partner_primary",
               "station_calendar_provider_entry_id" => "primary_reduced_capacity"
             }
           ] = allocated

    assert [
             %{
               "contact_id" => "dl_partner_list",
               "allocation_status" => "allocated",
               "station_availability" => "reduced_capacity",
               "station_calendar_entry_id" => "primary_reduced_capacity",
               "station_calendar_provider_id" => "ground_partner_primary",
               "station_calendar_provider_entry_id" => "primary_reduced_capacity",
               "station_calendar_directions" => ["downlink"],
               "station_calendar_trust_boundary_status" => "declared",
               "source_station_calendar_entry" => %{
                 "id" => "primary_reduced_capacity",
                 "provenance" => %{"provider_id" => "ground_partner_primary"}
               }
             }
           ] = report["rows"]

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "preserves station-calendar entry trust counts when allocation rows are unaffected" do
    contacts = [
      contact(:dl_unaffected, starts_at_s: 100.0, ends_at_s: 160.0)
    ]

    station_calendar_provider = %{
      schema_contract: "station_calendar_provider.v1",
      provider_id: "ground_partner_a",
      trust_boundary: "ground_partner_api",
      entries: [
        %{
          id: "deep_space_outage",
          ground_station_id: :deep_space_net,
          status: :unavailable,
          starts_at_s: 90.0,
          ends_at_s: 170.0
        }
      ]
    }

    {_allocated, report} =
      ContactAllocation.allocate_contacts(contacts, station_calendar_provider,
        source: "unit_test.unaffected_station_calendar"
      )

    assert report["calendar_entry_trust_boundary_status_counts"] == %{"declared" => 1}
    refute Map.has_key?(report, "station_calendar_trust_boundary_status_counts")
    assert get_in(report, ["station_calendar_report", "affected_contact_count"]) == 0
    assert report["rows"] |> Enum.all?(&(not Map.has_key?(&1, "station_calendar_entry_id")))

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_contact_allocation_report(report)
    manifest = CadenceImport.from_contact_allocation_report(report)

    assert review["calendar_entry_trust_boundary_status_counts"] == %{"declared" => 1}
    assert manifest["calendar_entry_trust_boundary_status_counts"] == %{"declared" => 1}
    assert review["rows"] |> Enum.all?(&(not Map.has_key?(&1, "station_calendar_entry_id")))
    assert manifest["rows"] |> Enum.all?(&(not Map.has_key?(&1, "station_calendar_entry_id")))

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "surfaces provider calendar contention from allocation reports into review and import rows" do
    contacts = [
      contact(:dl_provider_contention, starts_at_s: 100.0, ends_at_s: 160.0)
    ]

    station_calendar_provider = %{
      schema_contract: "station_calendar_provider.v1",
      provider_id: "ground_partner_a",
      trust_boundary: "ground_partner_api",
      entries: [
        %{
          id: "partner_outage",
          ground_station_id: :equator_prime,
          directions: [:downlink],
          status: :unavailable,
          starts_at_s: 90.0,
          ends_at_s: 170.0
        },
        %{
          id: "partner_reservation",
          ground_station_id: :equator_prime,
          directions: [:downlink],
          status: :reserved,
          reservation_id: :reservation_partner,
          reserved_by: :partner_team,
          starts_at_s: 120.0,
          ends_at_s: 180.0
        }
      ]
    }

    {_allocated, report} =
      ContactAllocation.allocate_contacts(contacts, station_calendar_provider,
        source: "unit_test.provider_contention"
      )

    assert %{
             "station_calendar_report" => %{
               "provider_calendar_contention_group_count" => 1,
               "provider_calendar_contention_groups" => [
                 %{
                   "id" => "station_calendar_provider_contention:equator_prime:1",
                   "provider_calendar_contention_status" => "provider_calendar_overlap",
                   "entry_ids" => ["partner_outage", "partner_reservation"],
                   "reservation_ids" => ["partner_outage", "reservation_partner"],
                   "reserved_by" => ["partner_team"],
                   "trust_boundary_statuses" => ["declared"]
                 } = group
               ]
             }
           } = report

    review = OperatorReview.from_contact_allocation_report(report)

    assert %{
             "review_type" => "station_calendar_review",
             "source" =>
               "contact_allocation_report.station_calendar_report.provider_calendar_contention_groups",
             "subject_id" => "station_calendar_provider_contention:equator_prime:1",
             "action" => "review_station_provider_contention",
             "provider_calendar_contention_status" => "provider_calendar_overlap",
             "provider_calendar_contention_entry_count" => 2,
             "provider_calendar_contention_entry_ids" => [
               "partner_outage",
               "partner_reservation"
             ],
             "provider_calendar_contention_reservation_ids" => [
               "partner_outage",
               "reservation_partner"
             ],
             "provider_calendar_contention_reserved_by" => ["partner_team"],
             "provider_calendar_contention_trust_boundary_statuses" => ["declared"],
             "source_station_calendar_provider_contention" => ^group
           } =
             Enum.find(
               review["rows"],
               &(&1["review_type"] == "station_calendar_review" and
                   &1["provider_calendar_contention_status"] == "provider_calendar_overlap")
             )

    manifest = CadenceImport.from_contact_allocation_report(report)

    assert %{
             "import_action" => "review_station_calendar",
             "source_review_type" => "station_calendar_review",
             "source_review_action" => "review_station_provider_contention",
             "provider_calendar_contention_status" => "provider_calendar_overlap",
             "provider_calendar_contention_entry_ids" => [
               "partner_outage",
               "partner_reservation"
             ],
             "provider_calendar_contention_reservation_ids" => [
               "partner_outage",
               "reservation_partner"
             ],
             "source_station_calendar_provider_contention" => ^group
           } =
             Enum.find(
               manifest["rows"],
               &(&1["source_review_type"] == "station_calendar_review" and
                   &1["provider_calendar_contention_status"] == "provider_calendar_overlap")
             )

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "flattens nested station-calendar entry id on allocation review and import rows" do
    contacts = [
      contact(:dl_nested_calendar_entry,
        starts_at_s: 100.0,
        ends_at_s: 160.0,
        station_calendar_trust_boundary_status: :declared,
        trust_boundary: :ground_partner_api,
        source_station_calendar_entry: %{
          id: :provider_entry_only,
          provenance: %{trust_boundary: :ground_partner_api}
        },
        source_station_calendar_overlaps: [
          %{id: :provider_entry_only}
        ]
      )
    ]

    {allocated, report} =
      ContactAllocation.allocate_contacts(contacts, [],
        source: "unit_test.nested_station_calendar_entry",
        approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
      )

    assert [
             %{
               "id" => "dl_nested_calendar_entry",
               "station_calendar_entry_id" => "provider_entry_only"
             }
           ] = allocated

    assert [
             %{
               "contact_id" => "dl_nested_calendar_entry",
               "allocation_status" => "allocated",
               "station_calendar_entry_id" => "provider_entry_only",
               "station_calendar_trust_boundary_status" => "declared",
               "approval_requirements" => [
                 %{
                   "activity_context" => %{
                     "station_calendar_entry_id" => "provider_entry_only",
                     "source_station_calendar_entry" => %{"id" => "provider_entry_only"}
                   }
                 }
               ]
             }
           ] = report["rows"]

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)

    assert [
             %{
               "review_type" => "contact_allocation_review",
               "station_calendar_entry_id" => "provider_entry_only",
               "source_station_calendar_entry" => %{"id" => "provider_entry_only"}
             }
           ] = OperatorReview.from_contact_allocation_report(report)["rows"]

    assert [
             %{
               "import_action" => "review_contact_allocation",
               "station_calendar_entry_id" => "provider_entry_only",
               "source_station_calendar_entry" => %{"id" => "provider_entry_only"}
             }
           ] = CadenceImport.from_contact_allocation_report(report)["rows"]
  end

  test "classifies allocation rows by missing station-calendar trust boundary" do
    contacts = [
      contact(:dl_missing_trust, starts_at_s: 100.0, ends_at_s: 160.0)
    ]

    station_calendar_provider = %{
      schema_contract: "station_calendar_provider.v1",
      provider_id: "ground_partner_a",
      entries: [
        %{
          id: "partner_reduced_capacity",
          ground_station_id: :equator_prime,
          status: :available,
          capacity_fraction: 0.9,
          starts_at_s: 90.0,
          ends_at_s: 170.0
        }
      ]
    }

    {allocated, report} =
      ContactAllocation.allocate_contacts(contacts, station_calendar_provider,
        source: "unit_test.missing_station_calendar_trust",
        approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
      )

    assert [
             %{
               "id" => "dl_missing_trust",
               "approval_status" => "operator_review_required",
               "approval_rule_matches" => [
                 %{
                   "rule_id" => "missing_station_calendar_trust_review",
                   "station_calendar_trust_boundary_status" => "missing"
                 }
               ]
             }
           ] = allocated

    assert [
             %{
               "contact_id" => "dl_missing_trust",
               "allocation_status" => "allocated",
               "effective_allocation_status" => "allocated",
               "station_calendar_trust_boundary_status" => "missing",
               "approval_status" => "operator_review_required",
               "approval_requirements" => [
                 %{
                   "activity_context" => %{
                     "station_calendar_trust_boundary_status" => "missing",
                     "source_station_calendar_entry" => %{"id" => "partner_reduced_capacity"}
                   }
                 }
               ],
               "approval_rule_matches" => [
                 %{
                   "rule_id" => "missing_station_calendar_trust_review",
                   "station_calendar_trust_boundary_status" => "missing"
                 }
               ]
             }
           ] = report["rows"]

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "allocates downlink contacts that match provider reservation identity" do
    contacts = [
      contact(:dl_reserved_owner,
        starts_at_s: 100.0,
        ends_at_s: 160.0,
        station_reservation_id: :reservation_1
      ),
      contact(:dl_reserved_intruder, starts_at_s: 100.0, ends_at_s: 160.0)
    ]

    ground_network = [
      %{
        ground_station_id: :equator_prime,
        status: :reserved,
        starts_at_s: 90.0,
        ends_at_s: 170.0,
        reservation_id: :reservation_1,
        reserved_by: "ops_team_b",
        reservation_status: :confirmed,
        reservation_expires_at_s: 360.0,
        provider_counteroffer_negotiation_state: :unknown
      }
    ]

    {allocated, report} =
      ContactAllocation.allocate_contacts(contacts, ground_network,
        source: "unit_test.reservation_owner"
      )

    assert Enum.map(allocated, & &1["id"]) == ["dl_reserved_owner"]

    assert %{
             "allocated_contact_count" => 1,
             "blocked_contact_count" => 1,
             "contact_filter_report" => %{
               "kept_candidate_count" => 1,
               "suppressed_candidate_count" => 1
             },
             "station_reservation_match_status_counts" => %{
               "matched" => 1,
               "overlap" => 1
             },
             "station_reservation_ids" => ["reservation_1"],
             "station_reservation_expires_at_s" => [360.0],
             "station_reserved_bys" => ["ops_team_b"],
             "station_reservation_statuses" => ["confirmed"]
           } = report

    assert %{
             "contact_id" => "dl_reserved_owner",
             "allocation_status" => "allocated",
             "station_contention_status" => "reserved_overlap",
             "station_reservation_id" => "reservation_1",
             "station_reservation_expires_at_s" => 360.0,
             "station_reservation_match_status" => "matched"
           } = Enum.find(report["rows"], &(&1["contact_id"] == "dl_reserved_owner"))

    assert %{
             "contact_id" => "dl_reserved_intruder",
             "allocation_status" => "blocked",
             "allocation_reason" => "ground_station_reserved",
             "station_reservation_id" => "reservation_1",
             "station_reservation_expires_at_s" => 360.0,
             "station_reservation_match_status" => "overlap"
           } = Enum.find(report["rows"], &(&1["contact_id"] == "dl_reserved_intruder"))

    Enum.each(report["rows"], fn row ->
      refute Map.has_key?(row, "provider_counteroffer_negotiation_state")
      refute Map.has_key?(row, "provider_counteroffer_id")
    end)

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_contact_allocation_report(report)

    assert %{
             "station_reservation_match_status_counts" => %{
               "matched" => 1,
               "overlap" => 1
             },
             "station_reservation_ids" => ["reservation_1"],
             "station_reservation_expires_at_s" => [360.0],
             "station_reserved_bys" => ["ops_team_b"],
             "station_reservation_statuses" => ["confirmed"]
           } = review

    assert Enum.any?(
             review["rows"],
             &(&1["contact_id"] == "dl_reserved_owner" and
                 &1["station_reservation_match_status"] == "matched")
           )

    Enum.each(review["rows"], fn row ->
      refute Map.has_key?(row, "provider_counteroffer_negotiation_state")
      refute Map.has_key?(row, "provider_counteroffer_id")
    end)

    manifest = CadenceImport.from_contact_allocation_report(report)

    assert %{
             "station_reservation_match_status_counts" => %{
               "matched" => 1,
               "overlap" => 1
             },
             "station_reservation_ids" => ["reservation_1"],
             "station_reservation_expires_at_s" => [360.0],
             "station_reserved_bys" => ["ops_team_b"],
             "station_reservation_statuses" => ["confirmed"]
           } = manifest

    assert Enum.any?(
             manifest["rows"],
             &(&1["contact_id"] == "dl_reserved_owner" and
                 &1["station_reservation_match_status"] == "matched")
           )

    Enum.each(manifest["rows"], fn row ->
      refute Map.has_key?(row, "provider_counteroffer_negotiation_state")
      refute Map.has_key?(row, "provider_counteroffer_id")
    end)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "summarizes reservation conflicts from allocation reports" do
    contacts = [
      contact(:dl_reserved_owner,
        starts_at_s: 100.0,
        ends_at_s: 160.0,
        station_reservation_id: :reservation_1
      ),
      contact(:dl_reserved_intruder, starts_at_s: 100.0, ends_at_s: 160.0)
    ]

    ground_network = [
      %{
        ground_station_id: :equator_prime,
        status: :reserved,
        starts_at_s: 90.0,
        ends_at_s: 170.0,
        reservation_id: :reservation_1,
        reserved_by: "ops_team_b",
        reservation_status: :confirmed,
        reservation_expires_at_s: 360.0
      }
    ]

    {_allocated, report} =
      ContactAllocation.allocate_contacts(contacts, ground_network,
        source: "unit_test.reservation_conflict_summary"
      )

    summary = ContactAllocation.reservation_conflict_summary(report, now_s: 400.0)

    expected_capability_assumptions =
      contact_allocation_reservation_conflict_capability_assumptions()

    expected_station_reservation_match_statuses =
      expected_capability_assumptions["station_reservation_match_statuses"]

    expected_reservation_conflict_match_statuses =
      expected_capability_assumptions["reservation_conflict_match_statuses"]

    expected_station_reservation_expiration_statuses =
      expected_capability_assumptions["station_reservation_expiration_statuses"]

    expected_provider_direction_aliases =
      expected_capability_assumptions["provider_direction_aliases"]

    assert %{
             "schema_contract" => "contact_allocation_reservation_conflict_summary.v1",
             "model" => "artifact_only_contact_allocation_reservation_conflict_summary",
             "model_limits" => reservation_conflict_model_limits,
             "source_artifact_type" => "contact_allocation_report.v1",
             "source" => "unit_test.reservation_conflict_summary",
             "input_contact_count" => 2,
             "station_reservation_contact_count" => 2,
             "reservation_conflict_contact_count" => 1,
             "reservation_review_contact_count" => 1,
             "station_reservation_match_status_counts" => %{
               "matched" => 1,
               "overlap" => 1
             },
             "reservation_conflict_match_status_counts" => %{"overlap" => 1},
             "station_reservation_status_counts" => %{"confirmed" => 2},
             "station_reserved_by_counts" => %{"ops_team_b" => 2},
             "station_reservation_ids" => ["reservation_1"],
             "station_reservation_expires_at_s" => [360.0],
             "station_reservation_expiration_now_s" => 400.0,
             "station_reservation_expiration_status_counts" => %{"expired" => 2},
             "earliest_station_reservation_expires_at_s" => 360.0,
             "reservation_conflict_contact_ids" => ["dl_reserved_intruder"],
             "reservation_review_contact_ids" => ["dl_reserved_intruder"],
             "station_reservation_contact_ids_by_match_status" => %{
               "matched" => ["dl_reserved_owner"],
               "overlap" => ["dl_reserved_intruder"]
             },
             "reservation_conflict_contact_ids_by_match_status" => %{
               "overlap" => ["dl_reserved_intruder"]
             },
             "reservation_conflict_contact_ids_by_direction" => %{
               "downlink" => ["dl_reserved_intruder"]
             },
             "reservation_conflict_contact_ids_by_direction_and_ground_station_id" => %{
               "downlink" => %{"equator_prime" => ["dl_reserved_intruder"]}
             },
             "station_reservation_contact_ids_by_status" => %{
               "confirmed" => ["dl_reserved_intruder", "dl_reserved_owner"]
             },
             "station_reservation_contact_ids_by_reserved_by" => %{
               "ops_team_b" => ["dl_reserved_intruder", "dl_reserved_owner"]
             },
             "station_reservation_contact_ids_by_expiration_status" => %{
               "expired" => ["dl_reserved_intruder", "dl_reserved_owner"]
             },
             "station_reservation_ids_by_match_status" => %{
               "matched" => ["reservation_1"],
               "overlap" => ["reservation_1"]
             },
             "reservation_conflict_reservation_ids_by_match_status" => %{
               "overlap" => ["reservation_1"]
             },
             "station_reservation_ids_by_status" => %{
               "confirmed" => ["reservation_1"]
             },
             "station_reservation_ids_by_reserved_by" => %{
               "ops_team_b" => ["reservation_1"]
             },
             "station_reservation_ids_by_expiration_status" => %{
               "expired" => ["reservation_1"]
             },
             "rows" => rows,
             "reservation_conflict_rows" => conflict_rows,
             "reservation_review_rows" => review_rows,
             "assumptions" => %{
               "execution_boundary" =>
                 "artifact_only_no_provider_reservation_or_schedule_mutation",
               "source" => "contact_allocation_report.v1",
               "operator_authority" => "not_granted_by_reservation_conflict_summary",
               "station_reservation_match_statuses" =>
                 ^expected_station_reservation_match_statuses,
               "reservation_conflict_match_statuses" =>
                 ^expected_reservation_conflict_match_statuses,
               "station_reservation_expiration_statuses" =>
                 ^expected_station_reservation_expiration_statuses,
               "provider_direction_aliases" => ^expected_provider_direction_aliases
             }
           } = summary

    assert reservation_conflict_model_limits ==
             ContactAllocation.capabilities().known_limits
             |> Enum.map(&Atom.to_string/1)

    assert length(rows) == 2
    assert Enum.map(conflict_rows, & &1["contact_id"]) == ["dl_reserved_intruder"]
    assert Enum.map(review_rows, & &1["contact_id"]) == ["dl_reserved_intruder"]

    assert {:ok, %{"schema_contract" => "contact_allocation_reservation_conflict_summary.v1"}} =
             Schema.validate_artifact(summary)

    assert {:ok, reservation_conflict_schema} =
             Schema.json_schema("contact_allocation_reservation_conflict_summary.v1")

    assert get_in(reservation_conflict_schema, ["properties", "model", "const"]) ==
             "artifact_only_contact_allocation_reservation_conflict_summary"

    assert get_in(reservation_conflict_schema, ["properties", "model_limits", "const"]) ==
             reservation_conflict_model_limits

    assert get_in(reservation_conflict_schema, ["properties", "model_limits", "items", "enum"]) ==
             reservation_conflict_model_limits

    assert get_in(reservation_conflict_schema, [
             "properties",
             "assumptions",
             "properties",
             "station_reservation_match_statuses",
             "const"
           ]) == expected_capability_assumptions["station_reservation_match_statuses"]

    assert get_in(reservation_conflict_schema, [
             "properties",
             "assumptions",
             "properties",
             "reservation_conflict_match_statuses",
             "const"
           ]) == expected_capability_assumptions["reservation_conflict_match_statuses"]

    assert get_in(reservation_conflict_schema, [
             "properties",
             "assumptions",
             "properties",
             "station_reservation_expiration_statuses",
             "const"
           ]) == expected_capability_assumptions["station_reservation_expiration_statuses"]

    assert get_in(reservation_conflict_schema, [
             "properties",
             "assumptions",
             "properties",
             "provider_direction_aliases",
             "const"
           ]) == expected_capability_assumptions["provider_direction_aliases"]

    for {field, stale_value, message} <- [
          {"station_reservation_match_statuses", ["stale_match_status"],
           "must match ContactAllocation station reservation match statuses"},
          {"reservation_conflict_match_statuses", ["stale_conflict_match_status"],
           "must match ContactAllocation reservation conflict match statuses"},
          {"station_reservation_expiration_statuses", ["stale_expiration_status"],
           "must match ContactAllocation station reservation expiration statuses"},
          {"provider_direction_aliases", %{"dl" => "command"},
           "must match ContactAllocation provider direction aliases"}
        ] do
      stale_reservation_conflict_assumption =
        put_in(summary, ["assumptions", field], stale_value)

      assert {:error, stale_reservation_conflict_assumption_errors} =
               Schema.validate_artifact(stale_reservation_conflict_assumption)

      assert Enum.any?(
               stale_reservation_conflict_assumption_errors["errors"],
               &(&1["path"] == "$.assumptions.#{field}" and &1["message"] == message)
             )
    end

    summary_without_optional_capability_assumptions =
      drop_contact_allocation_reservation_conflict_capability_assumptions(summary)

    assert {:ok, %{"schema_contract" => "contact_allocation_reservation_conflict_summary.v1"}} =
             Schema.validate_artifact(summary_without_optional_capability_assumptions)

    stale_conflict_model =
      Map.put(summary, "model", "stale_contact_allocation_reservation_conflict_summary")

    assert {:error, stale_conflict_model_errors} =
             Schema.validate_artifact(stale_conflict_model)

    assert Enum.any?(
             stale_conflict_model_errors["errors"],
             &(&1["path"] == "$.model" and
                 &1["message"] ==
                   "must equal \"artifact_only_contact_allocation_reservation_conflict_summary\"")
           )

    stale_conflict_model_limits = Map.put(summary, "model_limits", ["artifact_level_only"])

    assert {:error, stale_conflict_model_limits_errors} =
             Schema.validate_artifact(stale_conflict_model_limits)

    assert Enum.any?(
             stale_conflict_model_limits_errors["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] == "must match contact allocation model limits")
           )

    stale_conflict_count =
      Map.put(summary, "reservation_conflict_contact_count", 0)

    assert {:error, stale_conflict_count_errors} =
             Schema.validate_artifact(stale_conflict_count)

    assert Enum.any?(
             stale_conflict_count_errors["errors"],
             &(&1["path"] == "$.reservation_conflict_contact_count" and
                 &1["message"] == "must equal row-derived reservation_conflict_contact_count")
           )

    stale_conflict_direction =
      Map.put(summary, "reservation_conflict_contact_ids_by_direction", %{
        "uplink" => ["dl_reserved_intruder"]
      })

    assert {:error, stale_conflict_direction_errors} =
             Schema.validate_artifact(stale_conflict_direction)

    assert Enum.any?(
             stale_conflict_direction_errors["errors"],
             &(&1["path"] == "$.reservation_conflict_contact_ids_by_direction" and
                 &1["message"] ==
                   "must equal row-derived reservation_conflict_contact_ids_by_direction")
           )

    stale_conflict_direction_station =
      Map.put(summary, "reservation_conflict_contact_ids_by_direction_and_ground_station_id", %{
        "uplink" => %{"equator_prime" => ["dl_reserved_intruder"]}
      })

    assert {:error, stale_conflict_direction_station_errors} =
             Schema.validate_artifact(stale_conflict_direction_station)

    assert Enum.any?(
             stale_conflict_direction_station_errors["errors"],
             &(&1["path"] ==
                 "$.reservation_conflict_contact_ids_by_direction_and_ground_station_id" and
                 &1["message"] ==
                   "must equal row-derived reservation_conflict_contact_ids_by_direction_and_ground_station_id")
           )

    stale_conflict_rows =
      Map.update!(summary, "rows", fn rows ->
        Enum.map(rows, fn
          %{"contact_id" => "dl_reserved_intruder"} = row ->
            Map.put(row, "station_reservation_match_status", "matched")

          row ->
            row
        end)
      end)

    assert {:error, stale_conflict_row_errors} = Schema.validate_artifact(stale_conflict_rows)

    assert Enum.any?(
             stale_conflict_row_errors["errors"],
             &(&1["path"] == "$.reservation_conflict_rows" and
                 &1["message"] == "must equal row-derived reservation_conflict_rows")
           )

    assert_summary_handoff(
      summary,
      &ContactAllocation.reservation_conflict_summary/1,
      &ContactAllocation.reservation_conflict_summary(&1, now_s: 999.0),
      &OrbitalDynamics.contact_allocation_reservation_conflict_summary/1,
      &OrbitalDynamics.contact_allocation_reservation_conflict_summary(&1, now_s: 999.0)
    )

    assert OrbitalDynamics.contact_allocation_reservation_conflict_summary(report,
             now_s: 400.0
           ) == summary

    assert ContactAllocation.reservation_conflict_summary(contacts, ground_network,
             source: "unit_test.reservation_conflict_summary",
             now_s: 400.0
           ) == summary

    assert_raise ArgumentError, ~r/contact allocation report is required/, fn ->
      ContactAllocation.reservation_conflict_summary(%{"schema_contract" => "unknown"})
    end
  end

  test "summarizes provider reservation requests from allocated reservation rows" do
    contacts = [
      contact(:dl_reserved_owner,
        direction: :downlink,
        starts_at_s: 100.0,
        ends_at_s: 160.0,
        station_reservation_id: :reservation_1
      ),
      contact(:dl_review_overlap,
        direction: :command,
        starts_at_s: 210.0,
        ends_at_s: 240.0,
        station_reservation_id: :reservation_review,
        station_reservation_match_status: :overlap,
        station_reservation_status: :confirmed
      ),
      contact(:dl_reserved_intruder,
        direction: :tracking,
        starts_at_s: 100.0,
        ends_at_s: 160.0
      ),
      contact(:dl_unreserved,
        direction: :uplink,
        starts_at_s: 320.0,
        ends_at_s: 360.0
      )
    ]

    ground_network = [
      %{
        ground_station_id: :equator_prime,
        status: :reserved,
        starts_at_s: 90.0,
        ends_at_s: 170.0,
        reservation_id: :reservation_1,
        reserved_by: "ops_team_b",
        reservation_status: :confirmed,
        reservation_expires_at_s: 360.0
      }
    ]

    {_allocated, report} =
      ContactAllocation.allocate_contacts(contacts, ground_network,
        source: "unit_test.provider_reservation_request_summary"
      )

    summary = ContactAllocation.provider_reservation_request_summary(report)

    expected_capability_assumptions =
      contact_allocation_provider_reservation_request_capability_assumptions()

    expected_provider_reservation_request_statuses =
      expected_capability_assumptions["provider_reservation_request_statuses"]

    expected_station_reservation_match_statuses =
      expected_capability_assumptions["station_reservation_match_statuses"]

    expected_provider_direction_aliases =
      expected_capability_assumptions["provider_direction_aliases"]

    assert %{
             "schema_contract" => "contact_allocation_provider_reservation_request_summary.v1",
             "model" => "artifact_only_contact_allocation_provider_reservation_request_summary",
             "model_limits" => provider_reservation_request_model_limits,
             "source_artifact_type" => "contact_allocation_report.v1",
             "source" => "unit_test.provider_reservation_request_summary",
             "input_contact_count" => 4,
             "provider_reservation_candidate_contact_count" => 2,
             "provider_reservation_request_contact_count" => 1,
             "provider_reservation_review_contact_count" => 1,
             "provider_reservation_no_request_contact_count" => 2,
             "provider_reservation_request_status" => "review_required",
             "provider_reservation_request_contact_ids" => ["dl_reserved_owner"],
             "provider_reservation_review_contact_ids" => ["dl_review_overlap"],
             "provider_reservation_no_request_contact_ids" => [
               "dl_reserved_intruder",
               "dl_unreserved"
             ],
             "provider_reservation_request_contact_ids_by_ground_station_id" => %{
               "equator_prime" => ["dl_reserved_owner"]
             },
             "provider_reservation_review_contact_ids_by_ground_station_id" => %{
               "equator_prime" => ["dl_review_overlap"]
             },
             "provider_reservation_no_request_contact_ids_by_direction" => %{
               "tracking" => ["dl_reserved_intruder"],
               "uplink" => ["dl_unreserved"]
             },
             "provider_reservation_request_contact_ids_by_direction" => %{
               "downlink" => ["dl_reserved_owner"]
             },
             "provider_reservation_review_contact_ids_by_direction" => %{
               "command" => ["dl_review_overlap"]
             },
             "provider_reservation_no_request_contact_ids_by_direction_and_ground_station_id" =>
               %{
                 "tracking" => %{"equator_prime" => ["dl_reserved_intruder"]},
                 "uplink" => %{"equator_prime" => ["dl_unreserved"]}
               },
             "provider_reservation_request_contact_ids_by_direction_and_ground_station_id" => %{
               "downlink" => %{"equator_prime" => ["dl_reserved_owner"]}
             },
             "provider_reservation_review_contact_ids_by_direction_and_ground_station_id" => %{
               "command" => %{"equator_prime" => ["dl_review_overlap"]}
             },
             "provider_reservation_request_contact_ids_by_match_status" => %{
               "matched" => ["dl_reserved_owner"]
             },
             "provider_reservation_review_contact_ids_by_match_status" => %{
               "overlap" => ["dl_review_overlap"]
             },
             "provider_reservation_request_ids_by_match_status" => %{
               "matched" => ["reservation_1"]
             },
             "provider_reservation_review_ids_by_match_status" => %{
               "overlap" => ["reservation_review"]
             },
             "rows" => rows,
             "provider_reservation_request_rows" => request_rows,
             "provider_reservation_review_rows" => review_rows,
             "assumptions" => %{
               "execution_boundary" =>
                 "artifact_only_no_provider_reservation_or_schedule_mutation",
               "source" => "contact_allocation_report.v1",
               "provider_reservation_execution" => "not_performed_by_summary",
               "operator_authority" => "not_granted_by_provider_reservation_request_summary",
               "provider_reservation_request_statuses" =>
                 ^expected_provider_reservation_request_statuses,
               "station_reservation_match_statuses" =>
                 ^expected_station_reservation_match_statuses,
               "provider_direction_aliases" => ^expected_provider_direction_aliases
             }
           } = summary

    assert provider_reservation_request_model_limits ==
             ContactAllocation.capabilities().known_limits
             |> Enum.map(&Atom.to_string/1)

    assert length(rows) == 4

    assert [%{"contact_id" => "dl_reserved_owner", "allocation_status" => "allocated"}] =
             request_rows

    assert [%{"contact_id" => "dl_review_overlap", "allocation_status" => "allocated"}] =
             review_rows

    assert {:ok,
            %{"schema_contract" => "contact_allocation_provider_reservation_request_summary.v1"}} =
             Schema.validate_artifact(summary)

    assert {:ok, provider_reservation_request_schema} =
             Schema.json_schema("contact_allocation_provider_reservation_request_summary.v1")

    assert get_in(provider_reservation_request_schema, ["properties", "model", "const"]) ==
             "artifact_only_contact_allocation_provider_reservation_request_summary"

    assert get_in(provider_reservation_request_schema, ["properties", "source", "type"]) ==
             "string"

    assert get_in(provider_reservation_request_schema, ["properties", "model_limits", "const"]) ==
             provider_reservation_request_model_limits

    assert get_in(provider_reservation_request_schema, [
             "properties",
             "model_limits",
             "items",
             "enum"
           ]) == provider_reservation_request_model_limits

    assert get_in(provider_reservation_request_schema, [
             "properties",
             "assumptions",
             "properties",
             "provider_reservation_request_statuses",
             "const"
           ]) == expected_capability_assumptions["provider_reservation_request_statuses"]

    assert get_in(provider_reservation_request_schema, [
             "properties",
             "assumptions",
             "properties",
             "station_reservation_match_statuses",
             "const"
           ]) == expected_capability_assumptions["station_reservation_match_statuses"]

    assert get_in(provider_reservation_request_schema, [
             "properties",
             "assumptions",
             "properties",
             "provider_direction_aliases",
             "const"
           ]) == expected_capability_assumptions["provider_direction_aliases"]

    for {field, stale_value, message} <- [
          {"provider_reservation_request_statuses", ["stale_request_status"],
           "must match ContactAllocation provider reservation request statuses"},
          {"station_reservation_match_statuses", ["stale_match_status"],
           "must match ContactAllocation station reservation match statuses"},
          {"provider_direction_aliases", %{"dl" => "command"},
           "must match ContactAllocation provider direction aliases"}
        ] do
      stale_provider_request_assumption =
        put_in(summary, ["assumptions", field], stale_value)

      assert {:error, stale_provider_request_assumption_errors} =
               Schema.validate_artifact(stale_provider_request_assumption)

      assert Enum.any?(
               stale_provider_request_assumption_errors["errors"],
               &(&1["path"] == "$.assumptions.#{field}" and &1["message"] == message)
             )
    end

    summary_without_optional_capability_assumptions =
      drop_contact_allocation_provider_reservation_request_capability_assumptions(summary)

    assert {:ok,
            %{"schema_contract" => "contact_allocation_provider_reservation_request_summary.v1"}} =
             Schema.validate_artifact(summary_without_optional_capability_assumptions)

    stale_request_model =
      Map.put(
        summary,
        "model",
        "stale_contact_allocation_provider_reservation_request_summary"
      )

    assert {:error, stale_request_model_errors} = Schema.validate_artifact(stale_request_model)

    assert Enum.any?(
             stale_request_model_errors["errors"],
             &(&1["path"] == "$.model" and
                 &1["message"] ==
                   "must equal \"artifact_only_contact_allocation_provider_reservation_request_summary\"")
           )

    stale_request_source = Map.put(summary, "source", %{"source" => "stale"})

    assert {:error, stale_request_source_errors} = Schema.validate_artifact(stale_request_source)

    assert Enum.any?(
             stale_request_source_errors["errors"],
             &(&1["path"] == "$.source" and &1["message"] == "must be a binary")
           )

    stale_request_model_limits = Map.put(summary, "model_limits", ["artifact_level_only"])

    assert {:error, stale_request_model_limits_errors} =
             Schema.validate_artifact(stale_request_model_limits)

    assert Enum.any?(
             stale_request_model_limits_errors["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] == "must match contact allocation model limits")
           )

    stale_request_count =
      Map.put(summary, "provider_reservation_request_contact_count", 2)

    assert {:error, stale_request_count_errors} = Schema.validate_artifact(stale_request_count)

    assert Enum.any?(
             stale_request_count_errors["errors"],
             &(&1["path"] == "$.provider_reservation_request_contact_count" and
                 &1["message"] ==
                   "must equal row-derived provider_reservation_request_contact_count")
           )

    stale_request_direction_map =
      Map.put(summary, "provider_reservation_request_contact_ids_by_direction", %{
        "downlink" => ["stale_contact"]
      })

    assert {:error, stale_request_direction_map_errors} =
             Schema.validate_artifact(stale_request_direction_map)

    assert Enum.any?(
             stale_request_direction_map_errors["errors"],
             &(&1["path"] == "$.provider_reservation_request_contact_ids_by_direction" and
                 &1["message"] ==
                   "must equal row-derived provider_reservation_request_contact_ids_by_direction")
           )

    stale_request_direction_station_map =
      Map.put(
        summary,
        "provider_reservation_request_contact_ids_by_direction_and_ground_station_id",
        %{
          "downlink" => %{"equator_prime" => ["stale_contact"]}
        }
      )

    assert {:error, stale_request_direction_station_map_errors} =
             Schema.validate_artifact(stale_request_direction_station_map)

    assert Enum.any?(
             stale_request_direction_station_map_errors["errors"],
             &(&1["path"] ==
                 "$.provider_reservation_request_contact_ids_by_direction_and_ground_station_id" and
                 &1["message"] ==
                   "must equal row-derived provider_reservation_request_contact_ids_by_direction_and_ground_station_id")
           )

    stale_no_request_direction_station_map =
      Map.put(
        summary,
        "provider_reservation_no_request_contact_ids_by_direction_and_ground_station_id",
        %{
          "tracking" => %{"equator_prime" => ["stale_contact"]}
        }
      )

    assert {:error, stale_no_request_direction_station_map_errors} =
             Schema.validate_artifact(stale_no_request_direction_station_map)

    assert Enum.any?(
             stale_no_request_direction_station_map_errors["errors"],
             &(&1["path"] ==
                 "$.provider_reservation_no_request_contact_ids_by_direction_and_ground_station_id" and
                 &1["message"] ==
                   "must equal row-derived provider_reservation_no_request_contact_ids_by_direction_and_ground_station_id")
           )

    stale_request_rows =
      Map.update!(summary, "rows", fn rows ->
        Enum.map(rows, fn
          %{"contact_id" => "dl_reserved_owner"} = row ->
            Map.put(row, "station_reservation_match_status", "overlap")

          row ->
            row
        end)
      end)

    assert {:error, stale_request_row_errors} = Schema.validate_artifact(stale_request_rows)

    assert Enum.any?(
             stale_request_row_errors["errors"],
             &(&1["path"] == "$.provider_reservation_request_rows" and
                 &1["message"] == "must equal row-derived provider_reservation_request_rows")
           )

    assert_summary_handoff(
      summary,
      &ContactAllocation.provider_reservation_request_summary/1,
      &ContactAllocation.provider_reservation_request_summary(&1, now_s: 999.0),
      &OrbitalDynamics.contact_allocation_provider_reservation_request_summary/1,
      &OrbitalDynamics.contact_allocation_provider_reservation_request_summary(&1,
        now_s: 999.0
      )
    )

    assert OrbitalDynamics.contact_allocation_provider_reservation_request_summary(report) ==
             summary

    assert ContactAllocation.provider_reservation_request_summary(contacts, ground_network,
             source: "unit_test.provider_reservation_request_summary"
           ) == summary

    candidate_refresh = %{
      "schema_contract" => "candidate_refresh.v1",
      "contact_allocation_provider_reservation_request_summary" => summary
    }

    review = OrbitalDynamics.operator_review_package(candidate_refresh)

    assert %{
             "action" => "review_provider_reservation_request",
             "required_operator_action" => "review_provider_reservation_request",
             "provider_reservation_request_status" => "request_ready",
             "provider_reservation_request_execution_boundary" =>
               "artifact_only_no_provider_reservation_or_schedule_mutation",
             "provider_reservation_execution" => "not_performed_by_summary"
           } =
             Enum.find(
               review["rows"],
               &(&1["contact_id"] == "dl_reserved_owner" and
                   &1["review_type"] == "contact_allocation_review")
             )

    assert %{
             "action" => "review_contact_allocation",
             "required_operator_action" => "review_contact_allocation",
             "provider_reservation_request_status" => "review_required"
           } =
             Enum.find(
               review["rows"],
               &(&1["contact_id"] == "dl_review_overlap" and
                   &1["review_type"] == "contact_allocation_review")
             )

    manifest = OrbitalDynamics.cadence_import_manifest(candidate_refresh)

    assert %{
             "import_action" => "review_provider_reservation_request",
             "provider_reservation_request_status" => "request_ready",
             "provider_reservation_execution" => "not_performed_by_summary"
           } =
             Enum.find(
               manifest["rows"],
               &(&1["contact_id"] == "dl_reserved_owner" and
                   &1["source_review_type"] == "contact_allocation_review")
             )

    assert %{
             "import_action" => "review_contact_allocation",
             "provider_reservation_request_status" => "review_required"
           } =
             Enum.find(
               manifest["rows"],
               &(&1["contact_id"] == "dl_review_overlap" and
                   &1["source_review_type"] == "contact_allocation_review")
             )

    request_ready_summary =
      ContactAllocation.provider_reservation_request_summary(%{
        "schema_contract" => "contact_allocation_report.v1",
        "rows" => request_rows
      })

    assert %{
             "provider_reservation_request_status" => "request_ready",
             "provider_reservation_candidate_contact_count" => 1,
             "provider_reservation_request_contact_ids" => ["dl_reserved_owner"],
             "provider_reservation_review_contact_ids" => []
           } = request_ready_summary

    assert {:ok,
            %{"schema_contract" => "contact_allocation_provider_reservation_request_summary.v1"}} =
             Schema.validate_artifact(request_ready_summary)

    assert %{
             "provider_reservation_request_status" => "clear",
             "provider_reservation_candidate_contact_count" => 0,
             "provider_reservation_request_contact_ids" => [],
             "provider_reservation_review_contact_ids" => []
           } =
             ContactAllocation.provider_reservation_request_summary(%{
               "schema_contract" => "contact_allocation_report.v1",
               "rows" => []
             })
  end

  test "provider reservation request summary excludes policy-blocked allocated rows" do
    summary =
      ContactAllocation.provider_reservation_request_summary(%{
        "schema_contract" => "contact_allocation_report.v1",
        "source" => "unit_test.provider_reservation_policy_block",
        "rows" => [
          %{
            "id" => "contact_allocation:dl_policy_blocked_reservation",
            "contact_id" => "dl_policy_blocked_reservation",
            "ground_station_id" => "equator_prime",
            "direction" => "downlink",
            "allocation_status" => "allocated",
            "effective_allocation_status" => "policy_blocked",
            "approval_status" => "blocked_by_policy",
            "station_reservation_id" => "reservation_1",
            "station_reservation_match_status" => "matched"
          }
        ]
      })

    assert %{
             "provider_reservation_candidate_contact_count" => 0,
             "provider_reservation_request_contact_count" => 0,
             "provider_reservation_review_contact_count" => 0,
             "provider_reservation_no_request_contact_count" => 1,
             "provider_reservation_request_status" => "clear",
             "provider_reservation_request_contact_ids" => [],
             "provider_reservation_review_contact_ids" => [],
             "provider_reservation_no_request_contact_ids" => [
               "dl_policy_blocked_reservation"
             ],
             "provider_reservation_no_request_contact_ids_by_direction" => %{
               "downlink" => ["dl_policy_blocked_reservation"]
             },
             "provider_reservation_no_request_contact_ids_by_direction_and_ground_station_id" =>
               %{
                 "downlink" => %{"equator_prime" => ["dl_policy_blocked_reservation"]}
               }
           } = summary

    assert {:ok,
            %{"schema_contract" => "contact_allocation_provider_reservation_request_summary.v1"}} =
             Schema.validate_artifact(summary)
  end

  test "provider reservation routes preserve scalar and list reservation identities" do
    summary =
      ContactAllocation.provider_reservation_request_summary(%{
        "schema_contract" => "contact_allocation_report.v1",
        "source" => "unit_test.provider_reservation_list_identities",
        "rows" => [
          %{
            "id" => "contact_allocation:request_a",
            "contact_id" => "request_a",
            "allocation_status" => "allocated",
            "effective_allocation_status" => "allocated",
            "station_reservation_match_status" => "matched",
            "station_reservation_id" => "reservation_shared",
            "station_calendar_reservation_ids" => [
              "reservation_extra",
              "reservation_shared"
            ]
          },
          %{
            "id" => "contact_allocation:request_b",
            "contact_id" => "request_b",
            "allocation_status" => "allocated",
            "effective_allocation_status" => "allocated",
            "station_reservation_match_status" => "matched",
            "station_calendar_reservation_ids" => ["reservation_shared"]
          },
          %{
            "id" => "contact_allocation:review_a",
            "contact_id" => "review_a",
            "allocation_status" => "allocated",
            "effective_allocation_status" => "allocated",
            "station_reservation_match_status" => "overlap",
            "station_calendar_reservation_ids" => ["reservation_review"]
          }
        ]
      })

    assert summary["provider_reservation_request_contact_ids_by_match_status"] == %{
             "matched" => ["request_a", "request_b"]
           }

    assert summary["provider_reservation_request_ids_by_match_status"] == %{
             "matched" => ["reservation_extra", "reservation_shared"]
           }

    assert summary["provider_reservation_review_contact_ids_by_match_status"] == %{
             "overlap" => ["review_a"]
           }

    assert summary["provider_reservation_review_ids_by_match_status"] == %{
             "overlap" => ["reservation_review"]
           }

    assert {:ok,
            %{"schema_contract" => "contact_allocation_provider_reservation_request_summary.v1"}} =
             Schema.validate_artifact(summary)
  end

  test "provider reservation request summary normalizes legacy allocated rows" do
    summary =
      ContactAllocation.provider_reservation_request_summary(%{
        "schema_contract" => "contact_allocation_report.v1",
        "source" => "unit_test.provider_reservation_legacy_rows",
        "rows" => [
          %{
            "id" => "contact_allocation:dl_legacy_reservation",
            "contact_id" => "dl_legacy_reservation",
            "ground_station_id" => "equator_prime",
            "direction" => "downlink",
            "allocation_status" => "allocated",
            "station_reservation_id" => "reservation_1",
            "station_reservation_match_status" => "matched"
          }
        ]
      })

    assert %{
             "provider_reservation_candidate_contact_count" => 1,
             "provider_reservation_request_contact_count" => 1,
             "provider_reservation_review_contact_count" => 0,
             "provider_reservation_no_request_contact_count" => 0,
             "provider_reservation_request_status" => "request_ready",
             "provider_reservation_request_contact_ids" => ["dl_legacy_reservation"],
             "provider_reservation_request_rows" => [
               %{
                 "contact_id" => "dl_legacy_reservation",
                 "effective_allocation_status" => "allocated"
               }
             ]
           } = summary

    assert {:ok,
            %{"schema_contract" => "contact_allocation_provider_reservation_request_summary.v1"}} =
             Schema.validate_artifact(summary)
  end

  test "allocates downlink contacts that match provider reservation ownership" do
    contacts = [
      contact(:dl_reserved_owner,
        starts_at_s: 100.0,
        ends_at_s: 160.0,
        station_reserved_by: :ops_team_b
      ),
      contact(:dl_reserved_intruder, starts_at_s: 100.0, ends_at_s: 160.0)
    ]

    ground_network = [
      %{
        ground_station_id: :equator_prime,
        status: :reserved,
        starts_at_s: 90.0,
        ends_at_s: 170.0,
        reservation_id: :reservation_1,
        reserved_by: "ops_team_b",
        reservation_status: :confirmed
      }
    ]

    {allocated, report} =
      ContactAllocation.allocate_contacts(contacts, ground_network,
        source: "unit_test.reservation_ownership"
      )

    assert Enum.map(allocated, & &1["id"]) == ["dl_reserved_owner"]

    assert %{
             "allocated_contact_count" => 1,
             "blocked_contact_count" => 1,
             "station_reservation_match_status_counts" => %{
               "owner_matched" => 1,
               "overlap" => 1
             },
             "station_reservation_ids" => ["reservation_1"],
             "station_reserved_bys" => ["ops_team_b"],
             "station_reservation_statuses" => ["confirmed"]
           } = report

    assert %{
             "contact_id" => "dl_reserved_owner",
             "allocation_status" => "allocated",
             "station_contention_status" => "reserved_overlap",
             "station_reservation_id" => "reservation_1",
             "station_reserved_by" => "ops_team_b",
             "station_reservation_match_status" => "owner_matched"
           } = Enum.find(report["rows"], &(&1["contact_id"] == "dl_reserved_owner"))

    assert %{
             "contact_id" => "dl_reserved_intruder",
             "allocation_status" => "blocked",
             "allocation_reason" => "ground_station_reserved",
             "station_reservation_id" => "reservation_1",
             "station_reserved_by" => "ops_team_b",
             "station_reservation_match_status" => "overlap"
           } = Enum.find(report["rows"], &(&1["contact_id"] == "dl_reserved_intruder"))

    review = OperatorReview.from_contact_allocation_report(report)
    manifest = CadenceImport.from_contact_allocation_report(report)

    assert %{
             "station_reservation_match_status_counts" => %{
               "owner_matched" => 1,
               "overlap" => 1
             }
           } = review

    assert %{
             "station_reserved_by_counts" => %{"ops_team_b" => 2},
             "station_reservation_contact_ids_by_reserved_by" => %{
               "ops_team_b" => ["dl_reserved_intruder", "dl_reserved_owner"]
             },
             "station_reservation_contact_ids_by_status" => %{
               "confirmed" => ["dl_reserved_intruder", "dl_reserved_owner"]
             },
             "station_reservation_ids_by_reserved_by" => %{
               "ops_team_b" => ["reservation_1"]
             },
             "station_reservation_ids_by_status" => %{
               "confirmed" => ["reservation_1"]
             },
             "station_reservation_ids_by_match_status" => %{
               "owner_matched" => ["reservation_1"],
               "overlap" => ["reservation_1"]
             }
           } = ContactAllocation.summary(report)

    assert Enum.any?(
             manifest["rows"],
             &(&1["contact_id"] == "dl_reserved_owner" and
                 &1["station_reservation_match_status"] == "owner_matched")
           )

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "rejects contact allocation summaries that diverge from rows" do
    contacts = [
      contact(:trusted_contact, starts_at_s: 100.0, ends_at_s: 160.0),
      contact(:completed_contact, starts_at_s: 200.0, ends_at_s: 240.0, status: :completed),
      contact(:duplicate_contact, starts_at_s: 300.0, ends_at_s: 340.0),
      contact(:duplicate_contact, starts_at_s: 360.0, ends_at_s: 400.0),
      %{
        id: :missing_station,
        type: :downlink,
        scenario_id: :leo_1,
        starts_at_s: 420.0,
        ends_at_s: 460.0
      }
    ]

    station_calendar_provider = %{
      schema_contract: "station_calendar_provider.v1",
      provider_id: "ground_partner_a",
      trust_boundary: "ground_partner_api",
      entries: [
        %{
          id: "partner_capacity",
          ground_station_id: :equator_prime,
          status: :available,
          capacity_fraction: 0.8,
          starts_at_s: 90.0,
          ends_at_s: 170.0
        }
      ]
    }

    {_allocated, report} =
      ContactAllocation.allocate_contacts(contacts, station_calendar_provider)

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)

    invalid_trust_counts =
      Map.put(report, "station_calendar_trust_boundary_status_counts", %{"missing" => 1})

    assert {:error, trust_count_report} = Schema.validate_artifact(invalid_trust_counts)

    assert Enum.any?(
             trust_count_report["errors"],
             &(&1["path"] == "$.station_calendar_trust_boundary_status_counts" and
                 &1["message"] ==
                   "must equal row-derived station_calendar_trust_boundary_status_counts")
           )

    invalid_calendar_entry_trust_counts =
      Map.put(report, "calendar_entry_trust_boundary_status_counts", %{"missing" => 1})

    assert {:error, calendar_entry_trust_count_report} =
             Schema.validate_artifact(invalid_calendar_entry_trust_counts)

    assert Enum.any?(
             calendar_entry_trust_count_report["errors"],
             &(&1["path"] == "$.calendar_entry_trust_boundary_status_counts" and
                 &1["message"] ==
                   "must match station_calendar_report.calendar_entry_trust_boundary_status_counts")
           )

    invalid_input_ids = Map.put(report, "invalid_contact_input_ids", ["other_contact"])

    assert {:error, invalid_input_ids_report} = Schema.validate_artifact(invalid_input_ids)

    assert Enum.any?(
             invalid_input_ids_report["errors"],
             &(&1["path"] == "$.invalid_contact_input_ids" and
                 &1["message"] == "must equal row-derived invalid_contact_input_ids")
           )

    omitted_invalid_input_ids = Map.put(report, "invalid_contact_input_ids", [])

    assert {:error, omitted_invalid_input_ids_report} =
             Schema.validate_artifact(omitted_invalid_input_ids)

    assert Enum.any?(
             omitted_invalid_input_ids_report["errors"],
             &(&1["path"] == "$.invalid_contact_input_ids" and
                 &1["message"] == "must equal row-derived invalid_contact_input_ids")
           )

    status_ids = Map.put(report, "status_blocked_contact_ids", ["other_contact"])

    assert {:error, status_ids_report} = Schema.validate_artifact(status_ids)

    assert Enum.any?(
             status_ids_report["errors"],
             &(&1["path"] == "$.status_blocked_contact_ids" and
                 &1["message"] == "must equal row-derived status_blocked_contact_ids")
           )

    omitted_status_ids = Map.put(report, "status_blocked_contact_ids", [])

    assert {:error, omitted_status_ids_report} = Schema.validate_artifact(omitted_status_ids)

    assert Enum.any?(
             omitted_status_ids_report["errors"],
             &(&1["path"] == "$.status_blocked_contact_ids" and
                 &1["message"] == "must equal row-derived status_blocked_contact_ids")
           )

    reservation_ids = Map.put(report, "station_reservation_ids", ["other_reservation"])

    assert {:error, reservation_ids_report} = Schema.validate_artifact(reservation_ids)

    assert Enum.any?(
             reservation_ids_report["errors"],
             &(&1["path"] == "$.station_reservation_ids" and
                 &1["message"] == "must equal row-derived station_reservation_ids")
           )

    duplicate_count = Map.put(report, "duplicate_contact_candidate_count", 1)

    assert {:error, duplicate_count_report} = Schema.validate_artifact(duplicate_count)

    assert Enum.any?(
             duplicate_count_report["errors"],
             &(&1["path"] == "$.duplicate_contact_candidate_count" and
                 &1["message"] == "must equal 2")
           )
  end

  test "defers overlapping same-spacecraft contacts across stations" do
    contacts = [
      contact(:dl_equator,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 170.0,
        score: 2.0
      ),
      contact(:dl_dsn,
        ground_station_id: :deep_space_net,
        starts_at_s: 130.0,
        ends_at_s: 180.0,
        score: 5.0
      )
    ]

    {allocated, report} =
      ContactAllocation.allocate_contacts(contacts, [], source: "unit_test.spacecraft_contention")

    assert Enum.map(allocated, & &1["id"]) == ["dl_dsn"]

    assert %{
             "allocated_contact_count" => 1,
             "deferred_contact_count" => 1,
             "contact_contention_report" => %{
               "conflict_groups" => [
                 %{
                   "resource_scope" => "spacecraft",
                   "spacecraft_id" => "leo_1",
                   "ground_station_ids" => ["deep_space_net", "equator_prime"]
                 }
               ]
             }
           } = report

    assert %{
             "contact_id" => "dl_equator",
             "spacecraft_id" => "leo_1",
             "allocation_status" => "deferred",
             "allocation_reason" => "same_spacecraft_contention",
             "contention_group_id" => "spacecraft:leo_1:contention:1",
             "selected_contact_id" => "dl_dsn"
           } = Enum.find(report["rows"], &(&1["contact_id"] == "dl_equator"))

    assert %{
             "contact_id" => "dl_dsn",
             "spacecraft_id" => "leo_1",
             "allocation_status" => "allocated",
             "deferred_contact_ids" => ["dl_equator"]
           } = Enum.find(report["rows"], &(&1["contact_id"] == "dl_dsn"))

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_contact_allocation_report(report)

    assert Enum.any?(
             review["rows"],
             &(&1["contact_id"] == "dl_equator" and &1["spacecraft_id"] == "leo_1" and
                 &1["allocation_reason"] == "same_spacecraft_contention")
           )

    manifest = CadenceImport.from_contact_allocation_report(report)

    assert Enum.any?(
             manifest["rows"],
             &(&1["contact_id"] == "dl_equator" and &1["spacecraft_id"] == "leo_1" and
                 &1["allocation_reason"] == "same_spacecraft_contention")
           )
  end

  test "blocks duplicate contact ids before contention allocation" do
    contacts = [
      contact(:dup_contact, starts_at_s: 100.0, ends_at_s: 160.0, score: 5.0),
      contact(:dup_contact, starts_at_s: 120.0, ends_at_s: 180.0, score: 10.0),
      contact(:unique_contact, starts_at_s: 220.0, ends_at_s: 260.0)
    ]

    ground_network = [
      %{
        id: :reduced_provider_window,
        ground_station_id: :equator_prime,
        status: :available,
        capacity_fraction: 0.5,
        starts_at_s: 90.0,
        ends_at_s: 150.0
      }
    ]

    {allocated, report} =
      ContactAllocation.allocate_contacts(contacts, ground_network,
        approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
      )

    assert Enum.map(allocated, & &1["id"]) == ["unique_contact"]

    assert %{
             "input_contact_count" => 3,
             "allocated_contact_count" => 1,
             "blocked_contact_count" => 2,
             "duplicate_contact_id_count" => 1,
             "duplicate_contact_candidate_count" => 2,
             "contact_filter_report" => %{"input_candidate_count" => 1},
             "contact_contention_report" => %{"input_contact_count" => 1}
           } = report

    duplicate_rows =
      Enum.filter(report["rows"], &(&1["allocation_reason"] == "duplicate_contact_id"))

    assert Enum.map(duplicate_rows, & &1["id"]) == [
             "contact_allocation:duplicate_contact_id:dup_contact:1",
             "contact_allocation:duplicate_contact_id:dup_contact:2"
           ]

    assert Enum.all?(duplicate_rows, & &1["duplicate_contact_id_collision"])
    assert Enum.all?(duplicate_rows, &(&1["duplicate_contact_candidate_count"] == 2))

    assert Enum.all?(
             duplicate_rows,
             &(&1["duplicate_contact_candidate_ids"] == ["dup_contact", "dup_contact"])
           )

    assert Enum.all?(duplicate_rows, &(&1["review_status"] == "operator_review_required"))
    assert Enum.all?(duplicate_rows, &(&1["source_contact_candidate"]["id"] == "dup_contact"))

    assert [%{"allocation_status" => "allocated"}] =
             Enum.filter(report["rows"], &(&1["contact_id"] == "unique_contact"))

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)

    duplicate_row_index =
      Enum.find_index(report["rows"], &(&1["allocation_reason"] == "duplicate_contact_id"))

    mismatched_duplicate_candidate_ids =
      put_in(
        report,
        ["rows", Access.at(duplicate_row_index), "duplicate_contact_candidate_ids"],
        ["dup_contact"]
      )

    assert {:error, mismatched_duplicate_candidate_ids_report} =
             Schema.validate_artifact(mismatched_duplicate_candidate_ids)

    assert Enum.any?(
             mismatched_duplicate_candidate_ids_report["errors"],
             &(&1["path"] ==
                 "$.rows[#{duplicate_row_index}].duplicate_contact_candidate_count" and
                 &1["message"] == "must equal 1")
           )

    invalid_duplicate_candidate_id =
      put_in(
        report,
        ["rows", Access.at(duplicate_row_index), "duplicate_contact_candidate_ids"],
        ["bad contact id", "dup_contact"]
      )

    assert {:error, invalid_duplicate_candidate_id_report} =
             Schema.validate_artifact(invalid_duplicate_candidate_id)

    assert Enum.any?(
             invalid_duplicate_candidate_id_report["errors"],
             &(&1["path"] ==
                 "$.rows[#{duplicate_row_index}].duplicate_contact_candidate_ids[0]" and
                 &1["message"] =~ "must match stable ID pattern")
           )

    missing_duplicate_evidence =
      update_in(
        report,
        ["rows", Access.at(duplicate_row_index)],
        &Map.delete(&1, "duplicate_contact_candidate_ids")
      )

    assert {:error, missing_duplicate_evidence_report} =
             Schema.validate_artifact(missing_duplicate_evidence)

    assert Enum.any?(
             missing_duplicate_evidence_report["errors"],
             &(&1["path"] ==
                 "$.rows[#{duplicate_row_index}].duplicate_contact_candidate_ids" and
                 &1["message"] == "is required")
           )

    review = OperatorReview.from_contact_allocation_report(report)

    assert Enum.count(
             review["rows"],
             &(&1["contact_id"] == "dup_contact" and &1["duplicate_contact_id_collision"])
           ) == 2

    manifest = CadenceImport.from_contact_allocation_report(report)

    assert Enum.count(
             manifest["rows"],
             &(&1["contact_id"] == "dup_contact" and &1["duplicate_contact_id_collision"])
           ) == 2
  end

  test "applies approval policy decisions to reviewable allocation boundaries" do
    contacts = [
      contact(:dl_unavailable, starts_at_s: 10.0, ends_at_s: 20.0),
      contact(:dl_reduced, starts_at_s: 100.0, ends_at_s: 160.0),
      contact(:cmd_reserved,
        type: :planned_contact,
        direction: :command,
        starts_at_s: 220.0,
        ends_at_s: 260.0
      )
    ]

    ground_network = [
      %{
        ground_station_id: :equator_prime,
        status: :unavailable,
        starts_at_s: 0.0,
        ends_at_s: 30.0
      },
      %{
        ground_station_id: :equator_prime,
        status: :available,
        capacity_fraction: 0.4,
        starts_at_s: 90.0,
        ends_at_s: 170.0
      },
      %{
        ground_station_id: :equator_prime,
        status: :reserved,
        starts_at_s: 210.0,
        ends_at_s: 270.0,
        reservation_id: :reservation_cmd,
        reserved_by: "network_partner",
        reservation_status: :confirmed
      }
    ]

    {allocated, report} =
      ContactAllocation.allocate_contacts(contacts, ground_network,
        source: "unit_test.policy_contacts",
        approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
      )

    assert %{
             "affected_contact_count" => 3,
             "affected_contacts" => affected_contacts
           } = report["station_calendar_report"]

    assert Enum.any?(
             affected_contacts,
             &(&1["contact_id"] == "dl_reduced" and
                 &1["station_availability"] == "reduced_capacity" and
                 &1["capacity_fraction"] == 0.4)
           )

    assert Enum.any?(
             affected_contacts,
             &(&1["contact_id"] == "dl_unavailable" and
                 &1["approval_status"] == "blocked_by_policy" and
                 get_in(&1, ["policy_decision", "classification"]) == "blocked_by_policy" and
                 Enum.any?(
                   &1["approval_rule_matches"],
                   fn match ->
                     match["rule_id"] == "unavailable_station_contact_block" and
                       match["station_availability"] == "unavailable"
                   end
                 ))
           )

    assert Enum.any?(
             affected_contacts,
             &(&1["contact_id"] == "cmd_reserved" and
                 &1["approval_status"] == "operator_review_required" and
                 get_in(&1, ["policy_decision", "classification"]) ==
                   "operator_review_required" and
                 Enum.any?(
                   &1["approval_rule_matches"],
                   fn match ->
                     match["rule_id"] == "reserved_station_contact_review" and
                       match["station_reservation_status"] == "confirmed"
                   end
                 ))
           )

    unavailable = Enum.find(report["rows"], &(&1["contact_id"] == "dl_unavailable"))
    reduced = Enum.find(report["rows"], &(&1["contact_id"] == "dl_reduced"))
    reserved = Enum.find(report["rows"], &(&1["contact_id"] == "cmd_reserved"))
    returned_reduced = Enum.find(allocated, &(&1["id"] == "dl_reduced"))
    returned_reserved = Enum.find(allocated, &(&1["id"] == "cmd_reserved"))

    assert unavailable["allocation_status"] == "blocked"
    assert unavailable["approval_status"] == "blocked_by_policy"
    assert unavailable["policy_decision"]["classification"] == "blocked_by_policy"

    assert %{
             "suppressed_candidates" => [
               %{
                 "id" => "dl_unavailable",
                 "approval_status" => "blocked_by_policy",
                 "approval_rule_matches" => filter_rule_matches,
                 "policy_decision" => %{"classification" => "blocked_by_policy"}
               }
             ]
           } = report["contact_filter_report"]

    assert Enum.any?(
             filter_rule_matches,
             &(&1["rule_id"] == "unavailable_station_contact_block" and
                 &1["station_availability"] == "unavailable")
           )

    assert Enum.any?(
             unavailable["approval_rule_matches"],
             &(&1["rule_id"] == "unavailable_station_contact_block" and
                 &1["station_availability"] == "unavailable")
           )

    assert reduced["allocation_status"] == "allocated"
    assert reduced["station_availability"] == "reduced_capacity"
    assert reduced["capacity_fraction"] == 0.4
    assert reduced["approval_status"] == "operator_review_required"
    assert returned_reduced["effective_allocation_status"] == "allocated"
    assert returned_reduced["review_status"] == "accepted_for_planning"
    assert returned_reduced["approval_status"] == "operator_review_required"
    assert returned_reduced["approval_requirements"] == reduced["approval_requirements"]
    assert returned_reduced["approval_rule_matches"] == reduced["approval_rule_matches"]
    assert returned_reduced["policy_decision"] == reduced["policy_decision"]

    assert Enum.any?(
             reduced["approval_rule_matches"],
             &(&1["rule_id"] == "severe_capacity_reduction_review" and
                 &1["capacity_fraction"] == 0.4)
           )

    assert reserved["allocation_status"] == "allocated"
    assert reserved["direction"] == "command"
    assert reserved["station_contention_status"] == "reserved_overlap"
    assert reserved["station_calendar_overlap_count"] == 1
    assert reserved["station_calendar_reservation_ids"] == ["reservation_cmd"]
    assert reserved["approval_status"] == "operator_review_required"
    assert returned_reserved["effective_allocation_status"] == "allocated"
    assert returned_reserved["station_reservation_id"] == "reservation_cmd"
    assert returned_reserved["approval_requirements"] == reserved["approval_requirements"]
    assert returned_reserved["approval_rule_matches"] == reserved["approval_rule_matches"]

    assert Enum.any?(
             reserved["approval_rule_matches"],
             &(&1["rule_id"] == "reserved_station_contact_review" and
                 &1["station_reservation_status"] == "confirmed")
           )

    assert [
             %{
               "activity_context" => %{
                 "station_reservation_id" => "reservation_cmd",
                 "station_reserved_by" => "network_partner",
                 "station_reservation_status" => "confirmed",
                 "station_calendar_reservation_ids" => ["reservation_cmd"],
                 "station_calendar_reserved_by" => ["network_partner"],
                 "station_calendar_reservation_statuses" => ["confirmed"]
               }
             }
           ] = reserved["approval_requirements"]

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_contact_allocation_report(report)

    assert Enum.any?(
             review["rows"],
             &(&1["contact_id"] == "dl_unavailable" and
                 &1["approval_status"] == "blocked_by_policy" and
                 get_in(&1, ["source_policy_decision", "classification"]) == "blocked_by_policy")
           )

    assert Enum.any?(
             review["rows"],
             &(&1["contact_id"] == "cmd_reserved" and
                 &1["station_calendar_overlap_count"] == 1 and
                 &1["station_calendar_reservation_ids"] == ["reservation_cmd"])
           )
  end

  test "passes approval policy evidence through nested contention reports" do
    contacts = [
      contact(:dl_1, starts_at_s: 100.0, ends_at_s: 170.0, score: 5.0),
      contact(:dl_2, starts_at_s: 120.0, ends_at_s: 180.0, score: 2.0)
    ]

    {_allocated, report} =
      ContactAllocation.allocate_contacts(contacts, [],
        source: "unit_test.nested_contention_policy",
        approval_policy: %{policy_bundle_id: "contact_command_review_v1"}
      )

    assert %{
             "conflict_groups" => [
               %{
                 "id" => "station:equator_prime:contention:1",
                 "approval_status" => "operator_review_required",
                 "approval_requirements" => [
                   %{
                     "activity_type" => "contact_contention",
                     "requirement_type" => "contact_schedule_change",
                     "activity_context" => %{
                       "contact_ids" => ["dl_1", "dl_2"],
                       "ground_station_id" => "equator_prime"
                     }
                   }
                 ],
                 "policy_decision" => %{
                   "schema_contract" => "policy_decision.v1",
                   "policy_bundle_id" => "contact_command_review_v1"
                 }
               }
             ]
           } = report["contact_contention_report"]

    assert %{
             "recommendations" => [
               %{
                 "group_id" => "station:equator_prime:contention:1",
                 "review_status" => "operator_review_required",
                 "approval_requirements" => [
                   %{
                     "activity_type" => "contact_contention_resolution",
                     "requirement_type" => "contact_schedule_change",
                     "activity_context" => %{
                       "selected_contact_id" => "dl_1",
                       "deferred_contact_ids" => ["dl_2"]
                     }
                   }
                 ],
                 "policy_decision" => %{
                   "schema_contract" => "policy_decision.v1",
                   "policy_bundle_id" => "contact_command_review_v1"
                 }
               }
             ]
           } = report["contact_contention_resolution_report"]

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_contact_allocation_report(report)

    assert Enum.any?(
             review["rows"],
             &(&1["contact_id"] == "dl_2" and
                 get_in(&1, [
                   "source_contention_recommendation",
                   "approval_requirements",
                   Access.at(0),
                   "activity_type"
                 ]) == "contact_contention_resolution")
           )

    manifest = CadenceImport.from_contact_allocation_report(report)

    assert Enum.any?(
             manifest["rows"],
             &(&1["contact_id"] == "dl_2" and
                 get_in(&1, [
                   "source_contention_recommendation",
                   "approval_requirements",
                   Access.at(0),
                   "activity_type"
                 ]) == "contact_contention_resolution")
           )
  end

  test "classifies uplink allocation policy requirements as command review" do
    contacts = [
      contact(:uplink_reserved,
        type: :planned_contact,
        direction: :uplink,
        starts_at_s: 220.0,
        ends_at_s: 260.0
      )
    ]

    ground_network = [
      %{
        ground_station_id: :equator_prime,
        status: :reserved,
        starts_at_s: 210.0,
        ends_at_s: 270.0,
        reservation_id: :reservation_uplink,
        reserved_by: "network_partner",
        reservation_status: :confirmed
      }
    ]

    {_allocated, report} =
      ContactAllocation.allocate_contacts(contacts, ground_network,
        source: "unit_test.uplink_allocation",
        approval_policy: %{policy_bundle_id: "command_contact_authority_v1"}
      )

    assert %{"suppressed_candidate_count" => 0} = report["contact_filter_report"]

    row = Enum.find(report["rows"], &(&1["contact_id"] == "uplink_reserved"))

    assert %{
             "direction" => "uplink",
             "allocation_status" => "allocated",
             "approval_status" => "operator_review_required",
             "approval_requirements" => [
               %{
                 "requirement_type" => "command_review",
                 "reason" => "command contact allocation allocated: available",
                 "activity_context" => %{
                   "contact_id" => "uplink_reserved",
                   "type" => "planned_contact",
                   "direction" => "uplink",
                   "starts_at_s" => 220.0,
                   "ends_at_s" => 260.0,
                   "station_reservation_id" => "reservation_uplink"
                 }
               }
             ]
           } = row

    assert Enum.any?(
             row["approval_rule_matches"],
             &(&1["rule_id"] == "command_uplink_authority_review" and
                 &1["direction"] == "uplink" and
                 &1["requirement_type"] == "command_review" and
                 &1["required_authority"] == "command_authority")
           )

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_contact_allocation_report(report)

    assert Enum.any?(
             review["rows"],
             &(&1["contact_id"] == "uplink_reserved" and
                 &1["direction"] == "uplink" and
                 get_in(&1, [
                   "source_contact_allocation",
                   "approval_requirements",
                   Access.at(0),
                   "requirement_type"
                 ]) == "command_review")
           )

    manifest = CadenceImport.from_contact_allocation_report(report)

    assert Enum.any?(
             manifest["rows"],
             &(&1["contact_id"] == "uplink_reserved" and
                 &1["direction"] == "uplink" and
                 get_in(&1, [
                   "source_contact_allocation",
                   "approval_requirements",
                   Access.at(0),
                   "requirement_type"
                 ]) == "command_review")
           )
  end

  test "carries contact feedback evidence into allocation policy, review, and import rows" do
    contacts = [
      contact(:dl_failed_feedback,
        metadata: %{
          contact_success: " FALSE ",
          contact_result: %{
            outcome: :accepted,
            provider_status: :dropped
          },
          contact_success_factor: "0.25",
          contact_success_factor_source: :operational_feedback_contact_success,
          command_success: " False ",
          command_result: %{
            outcome: :accepted,
            status: :rejected
          },
          command_success_factor: "0.5",
          command_success_factor_source: :operational_feedback_command_success
        }
      )
    ]

    {_allocated, report} =
      ContactAllocation.allocate_contacts(contacts, [],
        source: "unit_test.feedback_allocation",
        approval_policy: %{policy_bundle_id: "command_contact_authority_v1"}
      )

    assert [
             %{
               "contact_id" => "dl_failed_feedback",
               "allocation_status" => "allocated",
               "approval_status" => "operator_review_required",
               "contact_success" => false,
               "contact_result" => "accepted,dropped",
               "contact_success_factor" => 0.25,
               "contact_success_factor_source" => "operational_feedback_contact_success",
               "command_success" => false,
               "command_result" => "accepted,rejected",
               "command_success_factor" => 0.5,
               "command_success_factor_source" => "operational_feedback_command_success",
               "approval_requirements" => [
                 %{
                   "requirement_type" => "contact_schedule_change",
                   "activity_context" => %{
                     "contact_success" => false,
                     "contact_result" => "accepted,dropped",
                     "contact_success_factor" => 0.25,
                     "contact_success_factor_source" => "operational_feedback_contact_success",
                     "command_success" => false,
                     "command_result" => "accepted,rejected",
                     "command_success_factor" => 0.5,
                     "command_success_factor_source" => "operational_feedback_command_success"
                   }
                 }
               ]
             } = row
           ] = report["rows"]

    assert Enum.any?(
             row["approval_rule_matches"],
             &(&1["rule_id"] == "failed_contact_success_review" and
                 &1["contact_success"] == false and
                 &1["required_authority"] == "contact_schedule_authority")
           )

    assert Enum.any?(
             row["approval_rule_matches"],
             &(&1["rule_id"] == "low_contact_success_confidence_review" and
                 &1["contact_success_factor"] == 0.25 and
                 &1["contact_success_factor_source"] ==
                   "operational_feedback_contact_success")
           )

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_contact_allocation_report(report)

    assert [
             %{
               "review_type" => "contact_allocation_review",
               "contact_success" => false,
               "contact_result" => "accepted,dropped",
               "contact_success_factor" => 0.25,
               "contact_success_factor_source" => "operational_feedback_contact_success",
               "command_success" => false,
               "command_result" => "accepted,rejected",
               "command_success_factor" => 0.5,
               "command_success_factor_source" => "operational_feedback_command_success",
               "source_contact_allocation" => %{
                 "approval_requirements" => [
                   %{
                     "activity_context" => %{
                       "contact_success" => false,
                       "contact_result" => "accepted,dropped",
                       "contact_success_factor" => 0.25,
                       "command_success" => false,
                       "command_success_factor" => 0.5
                     }
                   }
                 ]
               }
             }
           ] = review["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    manifest = CadenceImport.from_contact_allocation_report(report)

    assert [
             %{
               "import_action" => "review_contact_allocation",
               "contact_success" => false,
               "contact_result" => "accepted,dropped",
               "contact_success_factor" => 0.25,
               "contact_success_factor_source" => "operational_feedback_contact_success",
               "command_success" => false,
               "command_result" => "accepted,rejected",
               "command_success_factor" => 0.5,
               "command_success_factor_source" => "operational_feedback_command_success",
               "source_contact_allocation" => %{
                 "approval_requirements" => [
                   %{
                     "activity_context" => %{
                       "contact_success" => false,
                       "contact_result" => "accepted,dropped",
                       "contact_success_factor" => 0.25,
                       "command_success" => false,
                       "command_success_factor" => 0.5
                     }
                   }
                 ]
               }
             }
           ] = manifest["rows"]

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "preserves actual throughput evidence on status-blocked realized contacts" do
    contacts = [
      contact(:dl_completed,
        status: :completed,
        delivered_data_mb: 42.0,
        contact_success: true
      )
    ]

    {_allocated, report} =
      ContactAllocation.allocate_contacts(contacts, [],
        source: "unit_test.realized_allocation",
        approval_policy: %{policy_bundle_id: "command_contact_authority_v1"}
      )

    assert %{
             "allocated_contact_count" => 0,
             "blocked_contact_count" => 1,
             "status_blocked_contact_count" => 1,
             "status_blocked_contact_ids" => ["dl_completed"],
             "rows" => [
               %{
                 "contact_id" => "dl_completed",
                 "allocation_status" => "blocked",
                 "allocation_reason" => "activity_status_completed",
                 "contact_allocation_effect_status" => "blocked",
                 "contact_allocation_effect_reason" => "activity_status_completed",
                 "actual_throughput_mb" => 42.0,
                 "approval_requirements" => [
                   %{
                     "activity_context" => %{
                       "actual_throughput_mb" => 42.0,
                       "contact_success" => true
                     }
                   }
                 ],
                 "source_contact_candidate" => %{"delivered_data_mb" => 42.0}
               }
             ]
           } = report

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_contact_allocation_report(report)

    assert [
             %{
               "review_type" => "contact_allocation_review",
               "actual_throughput_mb" => 42.0,
               "source_contact_allocation" => %{"actual_throughput_mb" => 42.0},
               "source_contact_candidate" => %{"delivered_data_mb" => 42.0}
             }
           ] = review["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    manifest = CadenceImport.from_contact_allocation_report(report)

    assert [
             %{
               "import_action" => "review_contact_allocation",
               "actual_throughput_mb" => 42.0,
               "source_contact_allocation" => %{"actual_throughput_mb" => 42.0},
               "source_review_row" => %{"actual_throughput_mb" => 42.0}
             }
           ] = manifest["rows"]

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "derives status-blocked actual throughput from realized data rate evidence" do
    contacts = [
      contact(:dl_actual_rate,
        status: :completed,
        actual_data_rate_mbps: 8.0,
        actual_duration_s: 60.0
      ),
      contact(:dl_nested_actual_rate,
        status: :partial,
        throughput_model: %{
          actual_data_rate_mb_s: 0.5,
          actual_duration_s: 30.0,
          contact_completion_fraction: 0.25
        }
      )
    ]

    {_allocated, report} =
      ContactAllocation.allocate_contacts(contacts, [],
        source: "unit_test.realized_data_rate_allocation",
        approval_policy: %{policy_bundle_id: "command_contact_authority_v1"}
      )

    assert %{
             "allocated_contact_count" => 0,
             "blocked_contact_count" => 2,
             "status_blocked_contact_count" => 2
           } = report

    mbps_derivation = %{
      "derivation" => "actual_data_rate_mbps * duration_s / 8",
      "rate_unit" => "Mbps",
      "actual_data_rate_mbps" => 8.0,
      "duration_s" => 60.0,
      "actual_throughput_mb" => 60.0
    }

    mb_s_derivation = %{
      "derivation" => "actual_data_rate_mb_s * duration_s",
      "rate_unit" => "MB/s",
      "actual_data_rate_mb_s" => 0.5,
      "duration_s" => 30.0,
      "actual_throughput_mb" => 15.0
    }

    assert %{
             "allocation_status" => "blocked",
             "allocation_reason" => "activity_status_completed",
             "actual_throughput_mb" => 60.0,
             "actual_data_rate_throughput_derivation" => ^mbps_derivation,
             "approval_requirements" => [
               %{
                 "activity_context" => %{
                   "actual_throughput_mb" => 60.0,
                   "actual_data_rate_throughput_derivation" => ^mbps_derivation
                 }
               }
             ]
           } = Enum.find(report["rows"], &(&1["contact_id"] == "dl_actual_rate"))

    assert %{
             "allocation_status" => "blocked",
             "allocation_reason" => "activity_status_partial",
             "actual_throughput_mb" => 15.0,
             "actual_data_rate_throughput_derivation" => ^mb_s_derivation,
             "completed_fraction" => 0.25
           } = Enum.find(report["rows"], &(&1["contact_id"] == "dl_nested_actual_rate"))

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_contact_allocation_report(report)

    assert Enum.any?(
             review["rows"],
             &(&1["contact_id"] == "dl_actual_rate" and &1["actual_throughput_mb"] == 60.0 and
                 &1["actual_data_rate_throughput_derivation"] == mbps_derivation)
           )

    manifest = CadenceImport.from_contact_allocation_report(report)

    assert Enum.any?(
             manifest["rows"],
             &(&1["contact_id"] == "dl_nested_actual_rate" and
                 &1["actual_throughput_mb"] == 15.0 and &1["completed_fraction"] == 0.25)
           )

    assert Enum.any?(
             manifest["rows"],
             &(&1["contact_id"] == "dl_nested_actual_rate" and
                 &1["actual_data_rate_throughput_derivation"] == mb_s_derivation)
           )
  end

  test "preserves downlink completion evidence through allocation review and import" do
    completion_sources = [
      "candidate_refresh.objectives.collection_latency",
      "operational_feedback.downlink_demand_mb.station"
    ]

    contacts = [
      contact(:dl_requirement,
        status: :completed,
        required_downlink_mb: 420.0,
        candidate_downlink_mb: 360.0,
        downlink_completion_ratio: 360.0 / 420.0,
        selected_downlink_shortfall_mb: 60.0,
        downlink_requirement_status: :shortfall,
        downlink_completion_source:
          "candidate_refresh.downlink_demand.objectives_and_operational_feedback",
        downlink_completion_sources: completion_sources
      )
    ]

    {_allocated, report} =
      ContactAllocation.allocate_contacts(contacts, [],
        source: "unit_test.downlink_completion_allocation",
        approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
      )

    assert %{
             "allocated_contact_count" => 0,
             "blocked_contact_count" => 1,
             "rows" => [
               %{
                 "contact_id" => "dl_requirement",
                 "allocation_status" => "blocked",
                 "allocation_reason" => "activity_status_completed",
                 "required_downlink_mb" => 420.0,
                 "candidate_downlink_mb" => 360.0,
                 "downlink_completion_ratio" => ratio,
                 "selected_downlink_shortfall_mb" => 60.0,
                 "downlink_requirement_status" => "shortfall",
                 "downlink_completion_source" =>
                   "candidate_refresh.downlink_demand.objectives_and_operational_feedback",
                 "downlink_completion_sources" => ^completion_sources,
                 "approval_requirements" => [
                   %{
                     "activity_context" => %{
                       "required_downlink_mb" => 420.0,
                       "candidate_downlink_mb" => 360.0,
                       "downlink_completion_ratio" => context_ratio,
                       "selected_downlink_shortfall_mb" => 60.0,
                       "downlink_requirement_status" => "shortfall",
                       "downlink_completion_source" =>
                         "candidate_refresh.downlink_demand.objectives_and_operational_feedback",
                       "downlink_completion_sources" => ^completion_sources
                     }
                   }
                 ]
               }
             ]
           } = report

    assert_in_delta ratio, 360.0 / 420.0, 1.0e-12
    assert_in_delta context_ratio, 360.0 / 420.0, 1.0e-12

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_contact_allocation_report(report)

    assert [
             %{
               "review_type" => "contact_allocation_review",
               "required_downlink_mb" => 420.0,
               "candidate_downlink_mb" => 360.0,
               "downlink_completion_ratio" => review_ratio,
               "selected_downlink_shortfall_mb" => 60.0,
               "downlink_requirement_status" => "shortfall",
               "downlink_completion_source" =>
                 "candidate_refresh.downlink_demand.objectives_and_operational_feedback",
               "downlink_completion_sources" => ^completion_sources,
               "source_contact_allocation" => %{
                 "required_downlink_mb" => 420.0,
                 "candidate_downlink_mb" => 360.0,
                 "downlink_completion_sources" => ^completion_sources
               }
             }
           ] = review["rows"]

    assert_in_delta review_ratio, 360.0 / 420.0, 1.0e-12

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    manifest = CadenceImport.from_contact_allocation_report(report)

    assert [
             %{
               "import_action" => "review_contact_allocation",
               "required_downlink_mb" => 420.0,
               "candidate_downlink_mb" => 360.0,
               "downlink_completion_ratio" => import_ratio,
               "selected_downlink_shortfall_mb" => 60.0,
               "downlink_requirement_status" => "shortfall",
               "downlink_completion_source" =>
                 "candidate_refresh.downlink_demand.objectives_and_operational_feedback",
               "downlink_completion_sources" => ^completion_sources,
               "source_contact_allocation" => %{
                 "required_downlink_mb" => 420.0,
                 "candidate_downlink_mb" => 360.0,
                 "downlink_completion_sources" => ^completion_sources
               },
               "source_review_row" => %{
                 "required_downlink_mb" => 420.0,
                 "candidate_downlink_mb" => 360.0,
                 "downlink_completion_sources" => ^completion_sources
               }
             }
           ] = manifest["rows"]

    assert_in_delta import_ratio, 360.0 / 420.0, 1.0e-12

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "reads downlink completion evidence from nested throughput model" do
    {_allocated, report} =
      ContactAllocation.allocate_contacts(
        [
          contact(:dl_nested_requirement,
            throughput_model: %{
              required_downlink_mb: 180.0,
              candidate_downlink_mb: 120.0,
              downlink_completion_ratio: 120.0 / 180.0,
              selected_downlink_shortfall_mb: 60.0,
              downlink_requirement_status: :shortfall,
              downlink_completion_source: :candidate_refresh_downlink_demand,
              downlink_completion_sources: [
                :candidate_refresh_objectives,
                "operational_feedback.downlink_demand_mb.station",
                nil
              ]
            }
          )
        ],
        [],
        source: "unit_test.nested_downlink_completion_allocation"
      )

    assert %{
             "rows" => [
               %{
                 "contact_id" => "dl_nested_requirement",
                 "required_downlink_mb" => 180.0,
                 "candidate_downlink_mb" => 120.0,
                 "downlink_completion_ratio" => ratio,
                 "selected_downlink_shortfall_mb" => 60.0,
                 "downlink_requirement_status" => "shortfall",
                 "downlink_completion_source" => "candidate_refresh_downlink_demand",
                 "downlink_completion_sources" => [
                   "candidate_refresh_objectives",
                   "operational_feedback.downlink_demand_mb.station"
                 ]
               }
             ]
           } = report

    assert_in_delta ratio, 120.0 / 180.0, 1.0e-12

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "preserves station-calendar context on status-blocked realized contacts" do
    contacts = [
      contact(:dl_completed_reserved,
        status: :completed,
        delivered_data_mb: 42.0,
        contact_success: true
      )
    ]

    ground_network = [
      %{
        ground_station_id: :equator_prime,
        status: :reserved,
        starts_at_s: 90.0,
        ends_at_s: 170.0,
        reservation_id: :reservation_completed,
        reserved_by: "network_partner",
        reservation_status: :confirmed
      }
    ]

    {_allocated, report} =
      ContactAllocation.allocate_contacts(contacts, ground_network,
        source: "unit_test.realized_reserved_allocation",
        approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
      )

    assert %{
             "allocated_contact_count" => 0,
             "blocked_contact_count" => 1,
             "status_blocked_contact_count" => 1,
             "rows" => [
               %{
                 "contact_id" => "dl_completed_reserved",
                 "allocation_status" => "blocked",
                 "allocation_reason" => "activity_status_completed",
                 "actual_throughput_mb" => 42.0,
                 "station_calendar_status" => "reserved",
                 "station_contention_status" => "reserved_overlap",
                 "station_calendar_reservation_overlap_count" => 1,
                 "station_calendar_reservation_ids" => ["reservation_completed"],
                 "station_calendar_reserved_by" => ["network_partner"],
                 "station_calendar_reservation_statuses" => ["confirmed"],
                 "station_reservation_id" => "reservation_completed",
                 "station_reserved_by" => "network_partner",
                 "station_reservation_status" => "confirmed",
                 "approval_requirements" => [
                   %{
                     "activity_context" => %{
                       "actual_throughput_mb" => 42.0,
                       "station_reservation_id" => "reservation_completed",
                       "station_calendar_reservation_ids" => ["reservation_completed"]
                     }
                   }
                 ]
               }
             ]
           } = report

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_contact_allocation_report(report)

    assert [
             %{
               "review_type" => "contact_allocation_review",
               "actual_throughput_mb" => 42.0,
               "station_reservation_id" => "reservation_completed",
               "station_calendar_reservation_ids" => ["reservation_completed"],
               "source_contact_allocation" => %{
                 "station_reservation_id" => "reservation_completed"
               }
             }
           ] = review["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    manifest = CadenceImport.from_contact_allocation_report(report)

    assert [
             %{
               "import_action" => "review_contact_allocation",
               "actual_throughput_mb" => 42.0,
               "station_reservation_id" => "reservation_completed",
               "station_calendar_reservation_ids" => ["reservation_completed"],
               "source_contact_allocation" => %{
                 "station_reservation_id" => "reservation_completed"
               }
             }
           ] = manifest["rows"]

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "station overlays do not overwrite status-blocked allocation reasons" do
    contacts = [
      contact(:dl_completed_unavailable,
        status: :completed,
        delivered_data_mb: 42.0
      ),
      contact(:dl_rejected_unavailable,
        starts_at_s: 200.0,
        ends_at_s: 260.0,
        metadata: %{approval_status: :rejected}
      )
    ]

    ground_network = [
      %{
        ground_station_id: :equator_prime,
        status: :unavailable,
        starts_at_s: 90.0,
        ends_at_s: 270.0,
        trust_boundary: :declared
      }
    ]

    {_allocated, report} =
      ContactAllocation.allocate_contacts(contacts, ground_network,
        source: "unit_test.status_blocked_unavailable_station",
        approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
      )

    assert %{
             "status_blocked_contact_count" => 2,
             "blocked_contact_count" => 2
           } = report

    assert %{
             "contact_id" => "dl_completed_unavailable",
             "allocation_reason" => "activity_status_completed",
             "suppressed_reason" => "activity_status_completed",
             "station_calendar_status" => "unavailable",
             "station_availability" => "unavailable",
             "station_calendar_trust_boundary_status" => "declared"
           } = Enum.find(report["rows"], &(&1["contact_id"] == "dl_completed_unavailable"))

    assert %{
             "contact_id" => "dl_rejected_unavailable",
             "allocation_reason" => "approval_status_rejected",
             "suppressed_reason" => "approval_status_rejected",
             "station_calendar_status" => "unavailable",
             "station_availability" => "unavailable",
             "station_calendar_trust_boundary_status" => "declared"
           } = Enum.find(report["rows"], &(&1["contact_id"] == "dl_rejected_unavailable"))

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_contact_allocation_report(report)
    manifest = CadenceImport.from_contact_allocation_report(report)

    assert Enum.any?(
             review["rows"],
             &(&1["contact_id"] == "dl_completed_unavailable" and
                 &1["allocation_reason"] == "activity_status_completed" and
                 &1["station_availability"] == "unavailable")
           )

    assert Enum.any?(
             manifest["rows"],
             &(&1["contact_id"] == "dl_rejected_unavailable" and
                 &1["allocation_reason"] == "approval_status_rejected" and
                 &1["station_availability"] == "unavailable")
           )
  end

  test "status-blocked aggregates follow final row reasons after station availability precedence" do
    contacts = [
      contact(:dl_policy_blocked_unavailable,
        metadata: %{approval_status: :blocked_by_policy}
      )
    ]

    ground_network = [
      %{
        ground_station_id: :equator_prime,
        status: :unavailable,
        starts_at_s: 90.0,
        ends_at_s: 170.0
      }
    ]

    {_allocated, report} =
      ContactAllocation.allocate_contacts(contacts, ground_network,
        source: "unit_test.status_aggregate_station_precedence",
        approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
      )

    assert %{
             "blocked_contact_count" => 1,
             "status_blocked_contact_count" => 0,
             "status_blocked_contact_ids" => [],
             "rows" => [
               %{
                 "contact_id" => "dl_policy_blocked_unavailable",
                 "allocation_status" => "blocked",
                 "allocation_reason" => "ground_station_unavailable",
                 "station_availability" => "unavailable",
                 "source_approval_status" => "blocked_by_policy"
               }
             ]
           } = report

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)

    assert %{
             "status_blocked_contact_count" => 0,
             "status_blocked_contact_ids" => []
           } = ContactAllocation.summary(report)
  end

  test "preserves completed fraction evidence on status-blocked partial contacts" do
    contacts = [
      contact(:dl_partial,
        status: :partial,
        actual_downlink_mb: 40.0,
        completed_fraction: 0.4
      ),
      contact(:dl_overcomplete,
        status: :partial,
        throughput_model: %{contact_completion_fraction: 1.2}
      )
    ]

    {_allocated, report} =
      ContactAllocation.allocate_contacts(contacts, [],
        source: "unit_test.realized_allocation",
        approval_policy: %{policy_bundle_id: "command_contact_authority_v1"}
      )

    assert %{
             "allocated_contact_count" => 0,
             "blocked_contact_count" => 2,
             "invalid_contact_input_count" => 1,
             "status_blocked_contact_count" => 1
           } = report

    partial_row = Enum.find(report["rows"], &(&1["contact_id"] == "dl_partial"))
    overcomplete_row = Enum.find(report["rows"], &(&1["contact_id"] == "dl_overcomplete"))

    assert %{
             "allocation_status" => "blocked",
             "allocation_reason" => "activity_status_partial",
             "contact_allocation_effect_status" => "blocked",
             "contact_allocation_effect_reason" => "activity_status_partial",
             "actual_throughput_mb" => 40.0,
             "completed_fraction" => 0.4,
             "approval_requirements" => [
               %{
                 "activity_context" => %{
                   "actual_throughput_mb" => 40.0,
                   "completed_fraction" => 0.4
                 }
               }
             ],
             "source_contact_candidate" => %{"completed_fraction" => 0.4}
           } = partial_row

    assert %{
             "allocation_status" => "blocked",
             "allocation_reason" => "invalid_completed_fraction",
             "invalid_contact_input" => true,
             "invalid_contact_input_reason" => "invalid_completed_fraction",
             "review_status" => "operator_review_required",
             "source_contact_candidate" => %{
               "throughput_model" => %{"contact_completion_fraction" => 1.2}
             }
           } = overcomplete_row

    refute Map.has_key?(overcomplete_row, "completed_fraction")

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_contact_allocation_report(report)
    partial_review_row = Enum.find(review["rows"], &(&1["contact_id"] == "dl_partial"))

    assert %{
             "review_type" => "contact_allocation_review",
             "actual_throughput_mb" => 40.0,
             "completed_fraction" => 0.4,
             "source_contact_allocation" => %{
               "actual_throughput_mb" => 40.0,
               "completed_fraction" => 0.4
             },
             "source_contact_candidate" => %{"completed_fraction" => 0.4}
           } = partial_review_row

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    manifest = CadenceImport.from_contact_allocation_report(report)
    partial_import_row = Enum.find(manifest["rows"], &(&1["contact_id"] == "dl_partial"))

    assert %{
             "import_action" => "review_contact_allocation",
             "actual_throughput_mb" => 40.0,
             "completed_fraction" => 0.4,
             "source_contact_allocation" => %{"completed_fraction" => 0.4},
             "source_review_row" => %{"completed_fraction" => 0.4}
           } = partial_import_row

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "review-gates out-of-range contact and command success factors" do
    contacts = [
      contact(:dl_bad_contact_factor, contact_success_factor: "1.2"),
      contact(:cmd_bad_command_factor,
        type: :command,
        direction: :command,
        command_success_factor: -0.1
      )
    ]

    {_allocated, report} =
      ContactAllocation.allocate_contacts(contacts, [], source: "unit_test.realized_allocation")

    assert %{
             "allocated_contact_count" => 0,
             "blocked_contact_count" => 2,
             "invalid_contact_input_count" => 2,
             "invalid_contact_input_ids" => [
               "dl_bad_contact_factor",
               "cmd_bad_command_factor"
             ]
           } = report

    assert %{
             "allocation_reason" => "invalid_contact_success_factor",
             "invalid_contact_input_reason" => "invalid_contact_success_factor",
             "source_contact_candidate" => %{"contact_success_factor" => "1.2"}
           } = Enum.find(report["rows"], &(&1["contact_id"] == "dl_bad_contact_factor"))

    assert %{
             "allocation_reason" => "invalid_command_success_factor",
             "invalid_contact_input_reason" => "invalid_command_success_factor",
             "source_contact_candidate" => %{"command_success_factor" => -0.1}
           } = Enum.find(report["rows"], &(&1["contact_id"] == "cmd_bad_command_factor"))

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_contact_allocation_report(report)
    manifest = CadenceImport.from_contact_allocation_report(report)

    assert Enum.any?(
             review["rows"],
             &(&1["contact_id"] == "dl_bad_contact_factor" and
                 &1["allocation_reason"] == "invalid_contact_success_factor")
           )

    assert Enum.any?(
             manifest["rows"],
             &(&1["contact_id"] == "cmd_bad_command_factor" and
                 &1["allocation_reason"] == "invalid_command_success_factor")
           )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "preserves ambiguous station-calendar context on allocation review and import rows" do
    contacts = [
      contact(:dl_ambiguous, starts_at_s: 100.0, ends_at_s: 160.0)
    ]

    ground_network = [
      %{
        ground_station_id: :equator_prime,
        id: :equator_capacity_low,
        status: :available,
        capacity_fraction: 0.25,
        starts_at_s: 90.0,
        ends_at_s: 170.0
      },
      %{
        ground_station_id: :equator_prime,
        id: :equator_capacity_high,
        status: :available,
        capacity_fraction: 0.75,
        starts_at_s: 90.0,
        ends_at_s: 170.0
      }
    ]

    {_allocated, report} =
      ContactAllocation.allocate_contacts(contacts, ground_network,
        source: "unit_test.contacts",
        approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
      )

    assert [
             %{
               "contact_id" => "dl_ambiguous",
               "allocation_status" => "allocated",
               "station_availability" => "reduced_capacity",
               "station_calendar_entry_ambiguous" => true,
               "station_calendar_ambiguous_entry_count" => 2,
               "station_calendar_ambiguous_entry_ids" => ambiguous_entry_ids
             } = row
           ] = report["rows"]

    assert ambiguous_entry_ids == [
             "equator_capacity_high",
             "equator_capacity_low"
           ]

    refute Map.has_key?(row, "capacity_fraction")

    assert [
             %{
               "activity_context" => %{
                 "station_availability" => "reduced_capacity",
                 "station_calendar_entry_ambiguous" => true,
                 "station_calendar_ambiguous_entry_count" => 2,
                 "station_calendar_ambiguous_entry_ids" => ^ambiguous_entry_ids
               }
             }
           ] = row["approval_requirements"]

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_contact_allocation_report(report)

    assert %{
             "review_type" => "contact_allocation_review",
             "station_calendar_entry_ambiguous" => true,
             "station_calendar_ambiguous_entry_count" => 2,
             "station_calendar_ambiguous_entry_ids" => ^ambiguous_entry_ids
           } = Enum.find(review["rows"], &(&1["review_type"] == "contact_allocation_review"))

    manifest = CadenceImport.from_contact_allocation_report(report)

    assert %{
             "import_action" => "review_contact_allocation",
             "station_calendar_entry_ambiguous" => true,
             "station_calendar_ambiguous_entry_count" => 2,
             "station_calendar_ambiguous_entry_ids" => ^ambiguous_entry_ids
           } = Enum.find(manifest["rows"], &(&1["import_action"] == "review_contact_allocation"))
  end

  test "allocates direct command and tracking station windows through contention review" do
    contacts = [
      contact(:cmd_window,
        type: :command,
        starts_at_s: 100.0,
        ends_at_s: 160.0,
        score: 3.0
      ),
      contact(:tracking_window,
        type: :tracking,
        starts_at_s: 120.0,
        ends_at_s: 180.0,
        score: 4.0
      )
    ]

    {_allocated, report} = ContactAllocation.allocate_contacts(contacts, [])

    assert %{
             "input_contact_count" => 2,
             "allocated_contact_count" => 1,
             "deferred_contact_count" => 1
           } = report

    assert %{
             "contact_id" => "cmd_window",
             "type" => "command",
             "direction" => "command",
             "allocation_status" => "deferred",
             "allocation_reason" => "same_station_contention",
             "selected_contact_id" => "tracking_window"
           } = Enum.find(report["rows"], &(&1["contact_id"] == "cmd_window"))

    assert %{
             "contact_id" => "tracking_window",
             "type" => "tracking",
             "direction" => "tracking",
             "allocation_status" => "allocated",
             "deferred_contact_ids" => ["cmd_window"]
           } = Enum.find(report["rows"], &(&1["contact_id"] == "tracking_window"))

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "allocates direction-only station windows and blocks direction-only downlinks" do
    contacts = [
      contact(:cmd_direction_only,
        type: nil,
        direction: :command,
        starts_at_s: 100.0,
        ends_at_s: 160.0,
        score: 3.0
      ),
      contact(:tracking_direction_only,
        type: nil,
        direction: :tracking,
        starts_at_s: 120.0,
        ends_at_s: 180.0,
        score: 4.0
      ),
      contact(:uplink_direction_only,
        type: nil,
        direction: :uplink,
        starts_at_s: 200.0,
        ends_at_s: 230.0
      ),
      contact(:dl_direction_only,
        type: nil,
        direction: :downlink,
        starts_at_s: 250.0,
        ends_at_s: 280.0
      )
    ]

    ground_network = [
      %{
        ground_station_id: :equator_prime,
        status: :unavailable,
        starts_at_s: 240.0,
        ends_at_s: 300.0
      }
    ]

    {_allocated, report} = ContactAllocation.allocate_contacts(contacts, ground_network)

    assert %{
             "input_contact_count" => 4,
             "allocated_contact_count" => 2,
             "deferred_contact_count" => 1,
             "blocked_contact_count" => 1
           } = report

    assert %{
             "contact_id" => "cmd_direction_only",
             "direction" => "command",
             "allocation_status" => "deferred",
             "allocation_reason" => "same_station_contention",
             "selected_contact_id" => "tracking_direction_only"
           } = Enum.find(report["rows"], &(&1["contact_id"] == "cmd_direction_only"))

    assert %{
             "contact_id" => "tracking_direction_only",
             "direction" => "tracking",
             "allocation_status" => "allocated",
             "deferred_contact_ids" => ["cmd_direction_only"]
           } = Enum.find(report["rows"], &(&1["contact_id"] == "tracking_direction_only"))

    assert %{
             "contact_id" => "uplink_direction_only",
             "type" => "planned_contact",
             "direction" => "uplink",
             "allocation_status" => "allocated"
           } = Enum.find(report["rows"], &(&1["contact_id"] == "uplink_direction_only"))

    assert %{
             "contact_id" => "dl_direction_only",
             "direction" => "downlink",
             "allocation_status" => "blocked",
             "allocation_reason" => "ground_station_unavailable"
           } = Enum.find(report["rows"], &(&1["contact_id"] == "dl_direction_only"))

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "allocates station-id-only provider contacts" do
    contacts = [
      %{
        id: :provider_contact,
        type: :contact,
        direction: :downlink,
        scenario_id: :leo_1,
        station_id: :equator_prime,
        starts_at_s: 250.0,
        ends_at_s: 280.0
      }
    ]

    ground_network = [
      %{
        ground_station_id: :equator_prime,
        status: :unavailable,
        starts_at_s: 240.0,
        ends_at_s: 300.0
      }
    ]

    {_allocated, report} = ContactAllocation.allocate_contacts(contacts, ground_network)

    assert %{
             "input_contact_count" => 1,
             "blocked_contact_count" => 1,
             "rows" => [
               %{
                 "contact_id" => "provider_contact",
                 "type" => "contact",
                 "direction" => "downlink",
                 "ground_station_id" => "equator_prime",
                 "allocation_status" => "blocked",
                 "allocation_reason" => "ground_station_unavailable"
               }
             ]
           } = report

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "allocates provider contacts with nested station identity objects" do
    contacts = [
      %{
        id: :provider_nested_station,
        direction: :downlink,
        scenario_id: :leo_1,
        spacecraft: %{id: :sat_1},
        station: %{id: :equator_prime},
        starts_at_s: 250.0,
        ends_at_s: 280.0
      },
      %{
        id: :provider_nested_ground_station,
        direction: :downlink,
        scenario_id: :leo_2,
        satellite: %{satellite_id: :sat_2},
        ground_station: %{ground_station_id: :equator_prime},
        starts_at_s: 260.0,
        ends_at_s: 290.0
      }
    ]

    ground_network = [
      %{
        ground_station_id: :equator_prime,
        status: :unavailable,
        starts_at_s: 240.0,
        ends_at_s: 300.0
      }
    ]

    {_allocated, report} = ContactAllocation.allocate_contacts(contacts, ground_network)

    assert %{
             "input_contact_count" => 2,
             "blocked_contact_count" => 2,
             "rows" => rows
           } = report

    assert Enum.all?(rows, &(&1["ground_station_id"] == "equator_prime"))
    assert Enum.all?(rows, &(&1["allocation_reason"] == "ground_station_unavailable"))
    assert Enum.map(rows, & &1["spacecraft_id"]) |> Enum.sort() == ["sat_1", "sat_2"]

    assert Enum.any?(
             rows,
             &(&1["contact_id"] == "provider_nested_station" and
                 &1["ground_station_id"] == "equator_prime")
           )

    assert Enum.any?(
             rows,
             &(&1["contact_id"] == "provider_nested_ground_station" and
                 &1["ground_station_id"] ==
                   "equator_prime")
           )

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "blocks non-downlink station windows when station calendar marks station unavailable" do
    contacts = [
      contact(:cmd_unavailable,
        type: nil,
        direction: :command,
        starts_at_s: 100.0,
        ends_at_s: 160.0
      ),
      contact(:tracking_zero_capacity,
        type: nil,
        direction: :tracking,
        starts_at_s: 220.0,
        ends_at_s: 260.0
      ),
      contact(:cmd_reserved,
        type: nil,
        direction: :command,
        starts_at_s: 320.0,
        ends_at_s: 360.0
      )
    ]

    ground_network = [
      %{
        ground_station_id: :equator_prime,
        status: :unavailable,
        starts_at_s: 90.0,
        ends_at_s: 170.0
      },
      %{
        ground_station_id: :equator_prime,
        status: :available,
        capacity_fraction: 0.0,
        starts_at_s: 210.0,
        ends_at_s: 270.0
      },
      %{
        ground_station_id: :equator_prime,
        status: :reserved,
        starts_at_s: 310.0,
        ends_at_s: 370.0,
        reservation_id: :reservation_cmd
      }
    ]

    {_allocated, report} = ContactAllocation.allocate_contacts(contacts, ground_network)

    assert %{
             "allocated_contact_count" => 1,
             "deferred_contact_count" => 0,
             "blocked_contact_count" => 2
           } = report

    assert %{
             "contact_id" => "cmd_unavailable",
             "direction" => "command",
             "allocation_status" => "blocked",
             "allocation_reason" => "ground_station_unavailable",
             "station_availability" => "unavailable",
             "source_station_calendar_contact" => %{
               "id" => "cmd_unavailable",
               "direction" => "command"
             }
           } = Enum.find(report["rows"], &(&1["contact_id"] == "cmd_unavailable"))

    assert %{
             "contact_id" => "tracking_zero_capacity",
             "direction" => "tracking",
             "allocation_status" => "blocked",
             "allocation_reason" => "ground_station_capacity_zero",
             "station_availability" => "reduced_capacity",
             "capacity_fraction" => capacity_fraction
           } = Enum.find(report["rows"], &(&1["contact_id"] == "tracking_zero_capacity"))

    assert capacity_fraction == 0.0

    assert %{
             "contact_id" => "cmd_reserved",
             "direction" => "command",
             "allocation_status" => "allocated",
             "station_contention_status" => "reserved_overlap",
             "station_calendar_reservation_ids" => ["reservation_cmd"]
           } = Enum.find(report["rows"], &(&1["contact_id"] == "cmd_reserved"))

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "accepts station calendar provider artifacts as ground network input" do
    contacts = [
      %{
        id: :planned_1,
        type: :planned_contact,
        direction: :downlink,
        ground_station_id: :ksat_svalbard,
        starts_at_s: 10.0,
        ends_at_s: 20.0
      }
    ]

    provider = %{
      schema_contract: "station_calendar_provider.v1",
      id: :provider_1,
      entries: [
        %{
          ground_station_id: :ksat_svalbard,
          availability: :unavailable,
          starts_at_s: 0.0,
          ends_at_s: 30.0
        }
      ]
    }

    {_allocated, report} = ContactAllocation.allocate_contacts(contacts, provider)

    assert report["allocated_contact_count"] == 0
    assert report["blocked_contact_count"] == 1

    assert [
             %{
               "contact_id" => "planned_1",
               "allocation_status" => "blocked",
               "allocation_reason" => "ground_station_unavailable",
               "station_calendar_provider_id" => "provider_1",
               "station_calendar_provider_entry_id" =>
                 "provider_1:ksat_svalbard:0.000000:30.000000"
             }
           ] = report["rows"]
  end

  test "does not return allocated contacts blocked by approval policy" do
    contacts = [
      contact(:dl_policy_blocked, starts_at_s: 100.0, ends_at_s: 160.0)
    ]

    ground_network = [
      %{
        ground_station_id: :equator_prime,
        status: :available,
        capacity_fraction: 0.4,
        starts_at_s: 90.0,
        ends_at_s: 170.0
      }
    ]

    approval_policy = %{
      action_rules: [
        %{
          id: :block_reduced_capacity_allocation,
          station_availabilities: [:reduced_capacity],
          classification: :blocked_by_policy,
          reason: "reduced capacity blocked for this allocation run"
        }
      ]
    }

    {allocated, report} =
      ContactAllocation.allocate_contacts(contacts, ground_network,
        approval_policy: approval_policy
      )

    assert allocated == []

    assert [
             %{
               "contact_id" => "dl_policy_blocked",
               "allocation_status" => "allocated",
               "effective_allocation_status" => "policy_blocked",
               "approval_status" => "blocked_by_policy",
               "station_availability" => "reduced_capacity",
               "policy_decision" => %{"classification" => "blocked_by_policy"}
             }
           ] = report["rows"]

    assert report["allocated_contact_count"] == 1
    assert report["returned_allocated_contact_count"] == 0
    assert report["policy_blocked_allocated_contact_count"] == 1

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)

    assert %{
             "allocated_contact_ids_by_ground_station_id" => %{
               "equator_prime" => ["dl_policy_blocked"]
             },
             "returned_allocated_contact_ids_by_ground_station_id" => %{},
             "policy_blocked_contact_ids_by_ground_station_id" => %{
               "equator_prime" => ["dl_policy_blocked"]
             }
           } = ContactAllocation.summary(report)

    review = OperatorReview.from_contact_allocation_report(report)

    assert [
             %{
               "contact_id" => "dl_policy_blocked",
               "allocation_status" => "allocated",
               "effective_allocation_status" => "policy_blocked"
             }
           ] = review["rows"]

    manifest = CadenceImport.from_contact_allocation_report(report)

    assert [
             %{
               "contact_id" => "dl_policy_blocked",
               "allocation_status" => "allocated",
               "effective_allocation_status" => "policy_blocked"
             }
           ] = manifest["rows"]
  end

  test "passes allocation status and reason into approval policy evidence" do
    contacts = [
      contact(:dl_contention_a, starts_at_s: 100.0, ends_at_s: 180.0, score: 5.0),
      contact(:dl_contention_b, starts_at_s: 120.0, ends_at_s: 190.0, score: 2.0)
    ]

    approval_policy = %{
      action_rules: [
        %{
          id: :deferred_station_contention_review,
          allocation_statuses: [:deferred],
          allocation_reasons: [:same_station_contention],
          classification: :operator_review_required,
          reason: "deferred station contention remains a ground-network review item"
        }
      ]
    }

    {_allocated, report} =
      ContactAllocation.allocate_contacts(contacts, [], approval_policy: approval_policy)

    deferred = Enum.find(report["rows"], &(&1["contact_id"] == "dl_contention_b"))

    assert %{
             "allocation_status" => "deferred",
             "effective_allocation_status" => "deferred",
             "allocation_reason" => "same_station_contention",
             "approval_status" => "operator_review_required",
             "approval_requirements" => [
               %{
                 "activity_context" => %{
                   "allocation_status" => "deferred",
                   "allocation_reason" => "same_station_contention"
                 }
               }
             ],
             "approval_rule_matches" => [
               %{
                 "rule_id" => "deferred_station_contention_review",
                 "allocation_status" => "deferred",
                 "allocation_reason" => "same_station_contention"
               }
             ]
           } = deferred

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "passes allocation contention priority into approval policy evidence" do
    contacts = [
      contact(:high_score_unreserved, starts_at_s: 100.0, ends_at_s: 160.0, score: 20.0),
      contact(:alias_reserved_candidate,
        starts_at_s: 120.0,
        ends_at_s: 150.0,
        score: 2.0,
        reservation_id: :reservation_alpha,
        reserved_by: :leo_2,
        reservation_status: :confirmed,
        reservation_match_status: :matched
      )
    ]

    approval_policy = %{
      action_rules: [
        %{
          id: :reservation_priority_allocation_review,
          selected_priority_sources: [:station_reservation_priority],
          classification: :operator_review_required,
          reason: "reservation-priority allocation requires ground-network review"
        }
      ]
    }

    {_allocated, report} =
      ContactAllocation.allocate_contacts(contacts, [],
        policy: %{
          selection_rule: :highest_priority_highest_score,
          priority_fields: [:station_reservation_priority]
        },
        approval_policy: approval_policy
      )

    selected = Enum.find(report["rows"], &(&1["contact_id"] == "alias_reserved_candidate"))

    assert %{
             "allocation_status" => "allocated",
             "selected_priority" => 1.0,
             "selected_priority_source" => "station_reservation_priority",
             "approval_requirements" => [
               %{
                 "activity_context" => %{
                   "deferred_contact_ids" => ["high_score_unreserved"],
                   "selected_priority" => 1.0,
                   "selected_priority_source" => "station_reservation_priority",
                   "deferred_contact_priorities" => []
                 }
               }
             ],
             "approval_rule_matches" => [
               %{
                 "rule_id" => "reservation_priority_allocation_review",
                 "selected_priority_source" => "station_reservation_priority"
               }
             ]
           } = selected

    deferred = Enum.find(report["rows"], &(&1["contact_id"] == "high_score_unreserved"))

    assert %{
             "allocation_status" => "deferred",
             "selected_contact_id" => "alias_reserved_candidate",
             "selected_priority" => 1.0,
             "selected_priority_source" => "station_reservation_priority",
             "approval_rule_matches" => [
               %{
                 "rule_id" => "reservation_priority_allocation_review",
                 "selected_priority_source" => "station_reservation_priority"
               }
             ]
           } = deferred

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "blocks terminal rejected or policy-blocked contacts before allocation" do
    contacts = [
      contact(:dl_active, starts_at_s: 100.0, ends_at_s: 160.0),
      contact(:dl_completed, starts_at_s: 200.0, ends_at_s: 260.0, status: :completed),
      contact(:dl_rejected,
        starts_at_s: 300.0,
        ends_at_s: 360.0,
        metadata: %{approval_status: :rejected}
      ),
      contact(:dl_status_blocked,
        starts_at_s: 370.0,
        ends_at_s: 390.0,
        status: :blocked_by_policy,
        approval_status: :approved
      ),
      contact(:dl_approval_blocked,
        starts_at_s: 392.0,
        ends_at_s: 398.0,
        metadata: %{approval_status: :blocked_by_policy}
      ),
      contact(:dl_completed_rejected,
        starts_at_s: 400.0,
        ends_at_s: 460.0,
        status: :completed,
        metadata: %{approval_status: :rejected}
      )
    ]

    {allocated, report} =
      ContactAllocation.allocate_contacts(contacts, [],
        approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
      )

    assert Enum.map(allocated, & &1["id"]) == ["dl_active"]

    assert %{
             "input_contact_count" => 6,
             "allocated_contact_count" => 1,
             "returned_allocated_contact_count" => 1,
             "blocked_contact_count" => 5,
             "status_blocked_contact_count" => 5,
             "status_blocked_contact_ids" => [
               "dl_approval_blocked",
               "dl_completed",
               "dl_completed_rejected",
               "dl_rejected",
               "dl_status_blocked"
             ],
             "contact_filter_report" => %{"input_candidate_count" => 1},
             "contact_contention_report" => %{"input_contact_count" => 1}
           } = report

    assert get_in(report, ["assumptions", "contact_status_model"]) ==
             "terminal_or_source_policy_blocked_contacts_are_audited_as_blocked_without_station_allocation"

    assert %{
             "contact_id" => "dl_completed",
             "allocation_status" => "blocked",
             "effective_allocation_status" => "blocked",
             "allocation_reason" => "activity_status_completed",
             "suppressed_reason" => "activity_status_completed",
             "contact_status" => "completed",
             "contact_allocation_effect_status" => "blocked",
             "contact_allocation_effect_reason" => "activity_status_completed",
             "source_contact_candidate" => %{"status" => "completed"}
           } = Enum.find(report["rows"], &(&1["contact_id"] == "dl_completed"))

    assert %{
             "contact_id" => "dl_rejected",
             "allocation_status" => "blocked",
             "effective_allocation_status" => "blocked",
             "allocation_reason" => "approval_status_rejected",
             "source_approval_status" => "rejected",
             "source_contact_candidate" => %{
               "metadata" => %{"approval_status" => "rejected"}
             }
           } = Enum.find(report["rows"], &(&1["contact_id"] == "dl_rejected"))

    assert %{
             "contact_id" => "dl_status_blocked",
             "allocation_status" => "blocked",
             "effective_allocation_status" => "blocked",
             "allocation_reason" => "activity_status_blocked_by_policy",
             "suppressed_reason" => "activity_status_blocked_by_policy",
             "contact_status" => "blocked_by_policy",
             "source_approval_status" => "approved",
             "source_contact_candidate" => %{
               "status" => "blocked_by_policy",
               "approval_status" => "approved"
             }
           } = Enum.find(report["rows"], &(&1["contact_id"] == "dl_status_blocked"))

    assert %{
             "contact_id" => "dl_approval_blocked",
             "allocation_status" => "blocked",
             "effective_allocation_status" => "blocked",
             "allocation_reason" => "approval_status_blocked_by_policy",
             "suppressed_reason" => "approval_status_blocked_by_policy",
             "source_approval_status" => "blocked_by_policy",
             "source_contact_candidate" => %{
               "metadata" => %{"approval_status" => "blocked_by_policy"}
             }
           } = Enum.find(report["rows"], &(&1["contact_id"] == "dl_approval_blocked"))

    assert %{
             "contact_id" => "dl_completed_rejected",
             "allocation_status" => "blocked",
             "effective_allocation_status" => "blocked",
             "allocation_reason" => "approval_status_rejected",
             "suppressed_reason" => "approval_status_rejected",
             "contact_status" => "completed",
             "source_approval_status" => "rejected",
             "source_contact_candidate" => %{
               "status" => "completed",
               "metadata" => %{"approval_status" => "rejected"}
             }
           } = Enum.find(report["rows"], &(&1["contact_id"] == "dl_completed_rejected"))

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_contact_allocation_report(report)
    manifest = CadenceImport.from_contact_allocation_report(report)

    assert %{
             "contact_id" => "dl_status_blocked",
             "allocation_reason" => "activity_status_blocked_by_policy",
             "source_contact_allocation" => %{
               "allocation_reason" => "activity_status_blocked_by_policy"
             }
           } = Enum.find(review["rows"], &(&1["contact_id"] == "dl_status_blocked"))

    assert %{
             "contact_id" => "dl_approval_blocked",
             "allocation_reason" => "approval_status_blocked_by_policy",
             "source_contact_allocation" => %{
               "allocation_reason" => "approval_status_blocked_by_policy"
             }
           } = Enum.find(review["rows"], &(&1["contact_id"] == "dl_approval_blocked"))

    assert %{
             "contact_id" => "dl_status_blocked",
             "allocation_reason" => "activity_status_blocked_by_policy",
             "source_review_row" => %{
               "allocation_reason" => "activity_status_blocked_by_policy"
             }
           } = Enum.find(manifest["rows"], &(&1["contact_id"] == "dl_status_blocked"))

    assert %{
             "contact_id" => "dl_approval_blocked",
             "allocation_reason" => "approval_status_blocked_by_policy",
             "source_review_row" => %{
               "allocation_reason" => "approval_status_blocked_by_policy"
             }
           } = Enum.find(manifest["rows"], &(&1["contact_id"] == "dl_approval_blocked"))

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "blocks invalid contact-like inputs instead of silently dropping them" do
    contacts = [
      contact(:dl_active, starts_at_s: 100.0, ends_at_s: 160.0),
      contact(:dl_missing_station, starts_at_s: 200.0, ends_at_s: 260.0)
      |> Map.delete(:ground_station_id),
      %{
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 300.0,
        ends_at_s: 360.0
      },
      {:bad_contact_shape, :not_a_map}
    ]

    {allocated, report} = ContactAllocation.allocate_contacts(contacts, [])

    assert Enum.map(allocated, & &1["id"]) == ["dl_active"]

    assert %{
             "input_contact_count" => 4,
             "allocated_contact_count" => 1,
             "blocked_contact_count" => 3,
             "invalid_contact_input_count" => 3,
             "invalid_contact_input_ids" => [
               "dl_missing_station",
               "missing_contact_id:3",
               "missing_contact_id:4"
             ],
             "contact_filter_report" => %{"input_candidate_count" => 1},
             "contact_contention_report" => %{"input_contact_count" => 1}
           } = report

    assert %{
             "contact_id" => "dl_missing_station",
             "allocation_status" => "blocked",
             "effective_allocation_status" => "blocked",
             "allocation_reason" => "missing_ground_station_id",
             "invalid_contact_input" => true,
             "invalid_contact_input_reason" => "missing_ground_station_id",
             "source_contact_candidate" => %{"id" => "dl_missing_station"}
           } = Enum.find(report["rows"], &(&1["contact_id"] == "dl_missing_station"))

    assert %{
             "contact_id" => "missing_contact_id:3",
             "allocation_status" => "blocked",
             "allocation_reason" => "missing_contact_id",
             "invalid_contact_input" => true,
             "source_contact_candidate" => %{"ground_station_id" => "equator_prime"}
           } = Enum.find(report["rows"], &(&1["contact_id"] == "missing_contact_id:3"))

    assert %{
             "contact_id" => "missing_contact_id:4",
             "allocation_status" => "blocked",
             "allocation_reason" => "invalid_contact_shape",
             "invalid_contact_input" => true,
             "invalid_contact_input_reason" => "invalid_contact_shape",
             "source_contact_candidate" => %{
               "invalid_contact_shape" => true,
               "raw_input" => "{:bad_contact_shape, :not_a_map}"
             }
           } = Enum.find(report["rows"], &(&1["contact_id"] == "missing_contact_id:4"))

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_contact_allocation_report(report)

    assert Enum.any?(
             review["rows"],
             &(&1["contact_id"] == "dl_missing_station" and
                 &1["allocation_reason"] == "missing_ground_station_id" and
                 get_in(&1, ["source_contact_allocation", "invalid_contact_input"]) == true)
           )

    manifest = CadenceImport.from_contact_allocation_report(report)

    assert Enum.any?(
             manifest["rows"],
             &(&1["contact_id"] == "dl_missing_station" and
                 &1["allocation_reason"] == "missing_ground_station_id" and
                 get_in(&1, ["source_contact_allocation", "invalid_contact_input"]) == true)
           )
  end

  test "preserves malformed contact allocation identity fields for review" do
    contacts = [
      %{
        id: "bad contact id",
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 160.0
      },
      %{
        id: :bad_station,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: "bad station id",
        starts_at_s: 200.0,
        ends_at_s: 260.0
      },
      %{
        id: :bad_source_window,
        type: :tracking,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        source_window_id: "bad source window",
        starts_at_s: 300.0,
        ends_at_s: 360.0
      },
      %{
        id: :bad_scenario,
        type: :command,
        scenario_id: "bad scenario id",
        ground_station_id: :equator_prime,
        starts_at_s: 400.0,
        ends_at_s: 460.0
      }
    ]

    {allocated, report} = ContactAllocation.allocate_contacts(contacts, [])

    assert allocated == []

    assert %{
             "input_contact_count" => 4,
             "allocated_contact_count" => 0,
             "blocked_contact_count" => 4,
             "invalid_contact_input_count" => 4,
             "invalid_contact_input_ids" => [
               "invalid_contact_id:1",
               "bad_station",
               "bad_source_window",
               "bad_scenario"
             ],
             "contact_filter_report" => %{"input_candidate_count" => 0},
             "contact_contention_report" => %{"input_contact_count" => 0}
           } = report

    assert %{
             "contact_id" => "invalid_contact_id:1",
             "allocation_status" => "blocked",
             "allocation_reason" => "invalid_contact_id",
             "invalid_contact_input" => true,
             "source_contact_candidate" => %{"id" => "bad contact id"}
           } = Enum.find(report["rows"], &(&1["contact_id"] == "invalid_contact_id:1"))

    bad_station_row = Enum.find(report["rows"], &(&1["contact_id"] == "bad_station"))

    assert %{
             "allocation_reason" => "invalid_ground_station_id",
             "invalid_contact_input_reason" => "invalid_ground_station_id",
             "source_contact_candidate" => %{"ground_station_id" => "bad station id"}
           } = bad_station_row

    refute Map.has_key?(bad_station_row, "ground_station_id")

    bad_source_window_row =
      Enum.find(report["rows"], &(&1["contact_id"] == "bad_source_window"))

    assert %{
             "allocation_reason" => "invalid_source_window_id",
             "invalid_contact_input_reason" => "invalid_source_window_id",
             "source_contact_candidate" => %{"source_window_id" => "bad source window"}
           } = bad_source_window_row

    refute Map.has_key?(bad_source_window_row, "source_window_id")

    bad_scenario_row = Enum.find(report["rows"], &(&1["contact_id"] == "bad_scenario"))

    assert %{
             "allocation_reason" => "invalid_scenario_id",
             "invalid_contact_input_reason" => "invalid_scenario_id",
             "scenario_id" => "missing_scenario_id:4",
             "source_contact_candidate" => %{"scenario_id" => "bad scenario id"}
           } = bad_scenario_row

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_contact_allocation_report(report)

    assert Enum.any?(
             review["rows"],
             &(&1["contact_id"] == "bad_source_window" and
                 &1["allocation_reason"] == "invalid_source_window_id" and
                 get_in(&1, [
                   "source_contact_allocation",
                   "source_contact_candidate",
                   "source_window_id"
                 ]) == "bad source window")
           )

    manifest = CadenceImport.from_contact_allocation_report(report)

    assert Enum.any?(
             manifest["rows"],
             &(&1["contact_id"] == "bad_station" and
                 &1["allocation_reason"] == "invalid_ground_station_id" and
                 get_in(&1, [
                   "source_contact_allocation",
                   "source_contact_candidate",
                   "ground_station_id"
                 ]) == "bad station id")
           )
  end

  test "allocates provider-shaped contacts without explicit type or direction" do
    contacts = [
      %{
        id: :provider_allocated,
        scenario_id: :leo_1,
        station_id: :equator_prime,
        start_s: 100.0,
        end_s: 140.0,
        estimated_throughput_mb: 100.0
      },
      %{
        id: :provider_unavailable,
        scenario_id: :leo_1,
        station_id: :equator_prime,
        start_s: 220.0,
        end_s: 260.0,
        estimated_throughput_mb: 50.0
      },
      %{
        id: :provider_missing_time,
        scenario_id: :leo_1,
        station_id: :equator_prime,
        estimated_throughput_mb: 25.0
      },
      %{
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 300.0,
        ends_at_s: 340.0,
        actual_throughput_mb: 8.0
      }
    ]

    ground_network = [
      %{
        ground_station_id: :equator_prime,
        status: :unavailable,
        starts_at_s: 200.0,
        ends_at_s: 280.0
      }
    ]

    {allocated, report} = ContactAllocation.allocate_contacts(contacts, ground_network)

    assert Enum.map(allocated, & &1["id"]) == ["provider_allocated"]

    assert %{
             "input_contact_count" => 4,
             "allocated_contact_count" => 1,
             "blocked_contact_count" => 3,
             "invalid_contact_input_count" => 2,
             "contact_filter_report" => %{
               "input_candidate_count" => 2,
               "suppressed_candidate_count" => 1
             },
             "contact_contention_report" => %{"input_contact_count" => 1}
           } = report

    assert %{
             "contact_id" => "provider_allocated",
             "type" => "downlink",
             "direction" => "downlink",
             "allocation_status" => "allocated",
             "allocation_reason" => "available",
             "ground_station_id" => "equator_prime"
           } = Enum.find(report["rows"], &(&1["contact_id"] == "provider_allocated"))

    assert %{
             "contact_id" => "provider_unavailable",
             "type" => "downlink",
             "direction" => "downlink",
             "allocation_status" => "blocked",
             "allocation_reason" => "ground_station_unavailable",
             "source_contact_suppression" => %{
               "direction" => "downlink",
               "suppressed_reason" => "ground_station_unavailable"
             }
           } = Enum.find(report["rows"], &(&1["contact_id"] == "provider_unavailable"))

    assert %{
             "contact_id" => "provider_missing_time",
             "direction" => "downlink",
             "allocation_status" => "blocked",
             "allocation_reason" => "missing_contact_starts_at_s",
             "invalid_contact_input" => true,
             "source_contact_candidate" => %{
               "ground_station_id" => "equator_prime",
               "estimated_throughput_mb" => 25.0
             }
           } = Enum.find(report["rows"], &(&1["contact_id"] == "provider_missing_time"))

    assert %{
             "contact_id" => "missing_contact_id:4",
             "direction" => "downlink",
             "allocation_status" => "blocked",
             "allocation_reason" => "missing_contact_id",
             "invalid_contact_input" => true,
             "source_contact_candidate" => %{
               "ground_station_id" => "equator_prime",
               "actual_throughput_mb" => 8.0
             }
           } = Enum.find(report["rows"], &(&1["contact_id"] == "missing_contact_id:4"))

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_contact_allocation_report(report)

    assert Enum.any?(
             review["rows"],
             &(&1["contact_id"] == "provider_unavailable" and
                 &1["allocation_reason"] == "ground_station_unavailable")
           )

    manifest = CadenceImport.from_contact_allocation_report(report)

    assert Enum.any?(
             manifest["rows"],
             &(&1["contact_id"] == "missing_contact_id:4" and
                 &1["allocation_reason"] == "missing_contact_id" and
                 get_in(&1, ["source_contact_allocation", "invalid_contact_input"]) == true)
           )
  end

  test "preserves provider counteroffer suppressions through allocation review and import" do
    provider = %{
      schema_contract: "station_calendar_provider.v1",
      id: :ops_calendar,
      trust_boundary: :declared_station_calendar,
      entries: [
        %{
          id: :provider_counteroffer_window,
          station_id: :equator_prime,
          availability: :available,
          directions: [:downlink],
          start_s: 130.0,
          end_s: 170.0,
          counteroffer_id: :provider_offer_1,
          counteroffer_status: :proposed,
          counteroffer_reason_code: :provider_shifted_window,
          price_delta: "125.5",
          schedule_lock_deadline_s: "150.0",
          offered_start_s: "130.0",
          offered_end_s: "170.0"
        }
      ]
    }

    {allocated, report} =
      ContactAllocation.allocate_contacts(
        [contact(:dl_counteroffer, direction: :downlink)],
        provider,
        approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
      )

    assert allocated == []

    assert %{
             "blocked_contact_count" => 1,
             "contact_filter_report" => %{
               "suppression_reason_counts" => %{"provider_counteroffer_review" => 1}
             }
           } = report

    row = Enum.find(report["rows"], &(&1["contact_id"] == "dl_counteroffer"))

    assert %{
             "allocation_status" => "blocked",
             "allocation_reason" => "provider_counteroffer_review",
             "suppressed_reason" => "provider_counteroffer_review",
             "provider_counteroffer_id" => "provider_offer_1",
             "provider_counteroffer_status" => "proposed",
             "provider_counteroffer_negotiation_state" => "proposed",
             "provider_counteroffer_reason_code" => "provider_shifted_window",
             "provider_counteroffer_cost_delta" => 125.5,
             "provider_counteroffer_lock_deadline_s" => 150.0,
             "provider_counteroffer_starts_at_s" => 130.0,
             "provider_counteroffer_ends_at_s" => 170.0,
             "provider_counteroffer_start_delta_s" => 30.0,
             "provider_counteroffer_end_delta_s" => 10.0,
             "provider_counteroffer_duration_delta_s" => -20.0,
             "approval_requirements" => [
               %{
                 "activity_context" => %{
                   "provider_counteroffer_id" => "provider_offer_1",
                   "provider_counteroffer_status" => "proposed",
                   "provider_counteroffer_negotiation_state" => "proposed",
                   "provider_counteroffer_reason_code" => "provider_shifted_window",
                   "provider_counteroffer_cost_delta" => 125.5,
                   "provider_counteroffer_lock_deadline_s" => 150.0,
                   "provider_counteroffer_starts_at_s" => 130.0,
                   "provider_counteroffer_ends_at_s" => 170.0,
                   "provider_counteroffer_start_delta_s" => 30.0,
                   "provider_counteroffer_end_delta_s" => 10.0,
                   "provider_counteroffer_duration_delta_s" => -20.0
                 }
               }
             ],
             "source_contact_suppression" => %{
               "provider_counteroffer_id" => "provider_offer_1",
               "suppressed_reason" => "provider_counteroffer_review"
             }
           } = row

    review = OperatorReview.from_contact_allocation_report(report)
    review_row = Enum.find(review["rows"], &(&1["contact_id"] == "dl_counteroffer"))

    assert %{
             "review_type" => "contact_allocation_review",
             "provider_counteroffer_id" => "provider_offer_1",
             "provider_counteroffer_status" => "proposed",
             "provider_counteroffer_negotiation_state" => "proposed",
             "provider_counteroffer_reason_code" => "provider_shifted_window",
             "provider_counteroffer_cost_delta" => 125.5,
             "provider_counteroffer_lock_deadline_s" => 150.0,
             "provider_counteroffer_starts_at_s" => 130.0,
             "provider_counteroffer_ends_at_s" => 170.0,
             "provider_counteroffer_start_delta_s" => 30.0,
             "provider_counteroffer_end_delta_s" => 10.0,
             "provider_counteroffer_duration_delta_s" => -20.0,
             "source_contact_allocation" => %{
               "provider_counteroffer_id" => "provider_offer_1",
               "provider_counteroffer_duration_delta_s" => -20.0
             }
           } = review_row

    manifest = CadenceImport.from_contact_allocation_report(report)
    import_row = Enum.find(manifest["rows"], &(&1["contact_id"] == "dl_counteroffer"))

    assert %{
             "import_action" => "review_contact_allocation",
             "provider_counteroffer_id" => "provider_offer_1",
             "provider_counteroffer_status" => "proposed",
             "provider_counteroffer_negotiation_state" => "proposed",
             "provider_counteroffer_reason_code" => "provider_shifted_window",
             "provider_counteroffer_cost_delta" => 125.5,
             "provider_counteroffer_lock_deadline_s" => 150.0,
             "provider_counteroffer_starts_at_s" => 130.0,
             "provider_counteroffer_ends_at_s" => 170.0,
             "provider_counteroffer_start_delta_s" => 30.0,
             "provider_counteroffer_end_delta_s" => 10.0,
             "provider_counteroffer_duration_delta_s" => -20.0,
             "source_review_row" => %{
               "provider_counteroffer_id" => "provider_offer_1",
               "provider_counteroffer_duration_delta_s" => -20.0
             }
           } = import_row

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "preserves provider counteroffer evidence from source station-calendar overlaps" do
    contacts = [
      contact(:dl_overlap_counteroffer,
        direction: :downlink,
        required_operator_action: "review_provider_counteroffer",
        source_station_calendar_overlaps: [
          %{
            id: :provider_counteroffer_overlap,
            provider_counteroffer_id: :provider_offer_overlap,
            provider_counteroffer_status: :proposed,
            provider_counteroffer_negotiation_state: :proposed,
            provider_counteroffer_reason_code: :provider_shifted_window,
            provider_counteroffer_cost_delta: 80.5,
            provider_counteroffer_lock_deadline_s: 150.0,
            provider_counteroffer_starts_at_s: 130.0,
            provider_counteroffer_ends_at_s: 170.0
          }
        ]
      )
    ]

    {[], report} = ContactAllocation.allocate_contacts(contacts, [])
    row = Enum.find(report["rows"], &(&1["contact_id"] == "dl_overlap_counteroffer"))

    assert %{
             "allocation_status" => "blocked",
             "allocation_reason" => "provider_counteroffer_review",
             "suppressed_reason" => "provider_counteroffer_review",
             "provider_counteroffer_id" => "provider_offer_overlap",
             "provider_counteroffer_status" => "proposed",
             "provider_counteroffer_negotiation_state" => "proposed",
             "provider_counteroffer_reason_code" => "provider_shifted_window",
             "provider_counteroffer_cost_delta" => 80.5,
             "provider_counteroffer_lock_deadline_s" => 150.0,
             "provider_counteroffer_starts_at_s" => 130.0,
             "provider_counteroffer_ends_at_s" => 170.0,
             "provider_counteroffer_start_delta_s" => 30.0,
             "provider_counteroffer_end_delta_s" => 10.0,
             "provider_counteroffer_duration_delta_s" => -20.0,
             "source_station_calendar_overlaps" => [
               %{"id" => "provider_counteroffer_overlap"}
             ]
           } = row

    review = OperatorReview.from_contact_allocation_report(report)
    review_row = Enum.find(review["rows"], &(&1["contact_id"] == "dl_overlap_counteroffer"))

    assert %{
             "provider_counteroffer_id" => "provider_offer_overlap",
             "provider_counteroffer_duration_delta_s" => -20.0,
             "source_contact_allocation" => %{
               "provider_counteroffer_id" => "provider_offer_overlap",
               "provider_counteroffer_duration_delta_s" => -20.0
             }
           } = review_row

    manifest = CadenceImport.from_contact_allocation_report(report)
    import_row = Enum.find(manifest["rows"], &(&1["contact_id"] == "dl_overlap_counteroffer"))

    assert %{
             "provider_counteroffer_id" => "provider_offer_overlap",
             "provider_counteroffer_duration_delta_s" => -20.0,
             "source_review_row" => %{
               "provider_counteroffer_id" => "provider_offer_overlap",
               "provider_counteroffer_duration_delta_s" => -20.0
             }
           } = import_row

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "preserves provider counteroffer evidence from wrapped station-calendar overlaps" do
    contacts = [
      contact(:ul_wrapped_overlap_counteroffer,
        type: :planned_contact,
        direction: :uplink,
        required_operator_action: "review_provider_counteroffer",
        source_station_calendar_overlaps: [
          %{
            id: :wrapped_station_overlap,
            source_station_calendar_overlaps: [
              %{
                id: :provider_counteroffer_overlap,
                provider_counteroffer_id: :provider_offer_overlap,
                provider_counteroffer_status: :proposed,
                provider_counteroffer_negotiation_state: :proposed,
                provider_counteroffer_reason_code: :provider_shifted_window,
                provider_counteroffer_cost_delta: 80.5,
                provider_counteroffer_lock_deadline_s: 150.0,
                provider_counteroffer_starts_at_s: 130.0,
                provider_counteroffer_ends_at_s: 170.0
              }
            ]
          }
        ]
      )
    ]

    {[_allocated], report} = ContactAllocation.allocate_contacts(contacts, [])
    row = Enum.find(report["rows"], &(&1["contact_id"] == "ul_wrapped_overlap_counteroffer"))

    assert %{
             "allocation_status" => "allocated",
             "allocation_reason" => "available",
             "direction" => "uplink",
             "provider_counteroffer_id" => "provider_offer_overlap",
             "provider_counteroffer_status" => "proposed",
             "provider_counteroffer_negotiation_state" => "proposed",
             "provider_counteroffer_reason_code" => "provider_shifted_window",
             "provider_counteroffer_cost_delta" => 80.5,
             "provider_counteroffer_lock_deadline_s" => 150.0,
             "provider_counteroffer_starts_at_s" => 130.0,
             "provider_counteroffer_ends_at_s" => 170.0,
             "provider_counteroffer_start_delta_s" => 30.0,
             "provider_counteroffer_end_delta_s" => 10.0,
             "provider_counteroffer_duration_delta_s" => -20.0,
             "source_station_calendar_overlaps" => [
               %{
                 "source_station_calendar_overlaps" => [
                   %{"id" => "provider_counteroffer_overlap"}
                 ]
               }
             ]
           } = row

    review = OperatorReview.from_contact_allocation_report(report)

    review_row =
      Enum.find(review["rows"], &(&1["contact_id"] == "ul_wrapped_overlap_counteroffer"))

    assert %{
             "provider_counteroffer_id" => "provider_offer_overlap",
             "provider_counteroffer_duration_delta_s" => -20.0,
             "source_contact_allocation" => %{
               "provider_counteroffer_id" => "provider_offer_overlap",
               "provider_counteroffer_duration_delta_s" => -20.0
             }
           } = review_row

    manifest = CadenceImport.from_contact_allocation_report(report)

    import_row =
      Enum.find(manifest["rows"], &(&1["contact_id"] == "ul_wrapped_overlap_counteroffer"))

    assert %{
             "provider_counteroffer_id" => "provider_offer_overlap",
             "provider_counteroffer_duration_delta_s" => -20.0,
             "source_review_row" => %{
               "provider_counteroffer_id" => "provider_offer_overlap",
               "provider_counteroffer_duration_delta_s" => -20.0
             }
           } = import_row

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "lifts nested provider source windows into allocation rows" do
    contacts = [
      %{
        id: :provider_source_window,
        scenario_id: :leo_1,
        station_id: :equator_prime,
        start_s: 100.0,
        end_s: 140.0,
        estimated_throughput_mb: 100.0,
        contact_success: true,
        metadata: %{
          source_window: %{
            window_id: :provider_window_1,
            kind: :ground_station_access,
            confidence: :declared
          }
        }
      }
    ]

    {allocated, report} =
      ContactAllocation.allocate_contacts(contacts, [],
        approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
      )

    assert [
             %{
               "id" => "provider_source_window",
               "source_window_id" => "provider_window_1",
               "source_window_type" => "ground_station_access",
               "source_window" => %{
                 "window_id" => "provider_window_1",
                 "kind" => "ground_station_access",
                 "confidence" => "declared"
               }
             }
           ] = allocated

    assert %{
             "contact_id" => "provider_source_window",
             "allocation_status" => "allocated",
             "source_window_id" => "provider_window_1",
             "source_window_type" => "ground_station_access",
             "source_window" => %{
               "window_id" => "provider_window_1",
               "kind" => "ground_station_access"
             },
             "approval_requirements" => [
               %{
                 "activity_context" => %{
                   "source_window_id" => "provider_window_1",
                   "source_window_type" => "ground_station_access",
                   "source_window" => %{"window_id" => "provider_window_1"}
                 }
               }
             ]
           } = List.first(report["rows"])

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_contact_allocation_report(report)

    assert %{
             "contact_id" => "provider_source_window",
             "source_window_id" => "provider_window_1",
             "source_window_type" => "ground_station_access",
             "source_window" => %{
               "window_id" => "provider_window_1",
               "kind" => "ground_station_access"
             },
             "approval_requirements" => [
               %{
                 "activity_context" => %{
                   "source_window_id" => "provider_window_1",
                   "source_window_type" => "ground_station_access",
                   "source_window" => %{"window_id" => "provider_window_1"}
                 }
               }
             ]
           } = Enum.find(review["rows"], &(&1["contact_id"] == "provider_source_window"))

    manifest = CadenceImport.from_contact_allocation_report(report)

    assert %{
             "contact_id" => "provider_source_window",
             "source_window_id" => "provider_window_1",
             "source_window_type" => "ground_station_access",
             "source_window" => %{
               "window_id" => "provider_window_1",
               "kind" => "ground_station_access"
             },
             "approval_requirements" => [
               %{
                 "activity_context" => %{
                   "source_window_id" => "provider_window_1",
                   "source_window_type" => "ground_station_access",
                   "source_window" => %{"window_id" => "provider_window_1"}
                 }
               }
             ]
           } = Enum.find(manifest["rows"], &(&1["contact_id"] == "provider_source_window"))

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "review-gates malformed nested provider source-window identity" do
    contacts = [
      %{
        id: :bad_nested_source_window,
        scenario_id: :leo_1,
        station_id: :equator_prime,
        start_s: 100.0,
        end_s: 140.0,
        estimated_throughput_mb: 100.0,
        activity_context: %{
          source_window: %{
            id: "bad source window",
            type: :ground_station_access
          }
        }
      }
    ]

    {allocated, report} = ContactAllocation.allocate_contacts(contacts, [])

    assert allocated == []

    assert %{
             "invalid_contact_input_count" => 1,
             "blocked_contact_count" => 1
           } = report

    assert %{
             "contact_id" => "bad_nested_source_window",
             "allocation_status" => "blocked",
             "allocation_reason" => "invalid_source_window_id",
             "invalid_contact_input_reason" => "invalid_source_window_id",
             "source_contact_candidate" => %{
               "source_window_id" => "bad source window",
               "source_window" => %{"id" => "bad source window"}
             }
           } = List.first(report["rows"])

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "public facades allocate contacts and build reports" do
    contacts = [contact(:dl_1, starts_at_s: 10.0, ends_at_s: 20.0)]

    {allocated, report} = OrbitalDynamics.allocate_contacts(contacts)

    assert Enum.map(allocated, & &1["id"]) == ["dl_1"]
    assert report["allocated_contact_count"] == 1

    assert OrbitalDynamics.contact_allocation_report(contacts) == report
    assert ContactAllocation.report(report) == report
    assert OrbitalDynamics.contact_allocation_report(report) == report

    atom_keyed_report =
      Map.new(report, fn {key, value} -> {String.to_atom(key), value} end)

    assert ContactAllocation.report(atom_keyed_report) == report
    assert OrbitalDynamics.contact_allocation_report(atom_keyed_report) == report
  end

  test "blocks resource-suppressed contacts before station allocation" do
    contacts = [
      contact(:dl_antenna_unavailable, spacecraft_id: :sat_low_resource),
      contact(:dl_thermal_low,
        spacecraft_id: :sat_thermal_low,
        starts_at_s: 170.0,
        ends_at_s: 190.0
      ),
      contact(:dl_activity_suppressed,
        spacecraft_id: :sat_activity_restricted,
        starts_at_s: 192.0,
        ends_at_s: 198.0
      ),
      contact(:dl_resource_ready, spacecraft_id: :sat_ready, starts_at_s: 200.0, ends_at_s: 260.0)
    ]

    resource_summaries = [
      %{
        spacecraft_id: :sat_low_resource,
        antenna_available: false,
        power_margin: 0.9,
        battery_capacity_wh: 1200.0,
        battery_energy_used_wh: 876.0,
        battery_state_of_charge: 0.27,
        thermal_margin_c: 4.0,
        mode: :degraded_payload,
        source_quality: :operator_supplied,
        provenance: %{trust_boundary: :operator_declared_resource_summary}
      },
      %{
        spacecraft_id: :sat_thermal_low,
        antenna_available: true,
        thermal_margin_c: 1.5,
        power_margin: 0.9,
        source_quality: :operator_supplied,
        provenance: %{trust_boundary: :operator_declared_resource_summary}
      },
      %{
        spacecraft_id: :sat_activity_restricted,
        antenna_available: true,
        suppressed_activity_types: [:downlink],
        incompatible_activity_types: [:tracking],
        source_quality: :operator_supplied,
        provenance: %{trust_boundary: :operator_declared_resource_summary}
      },
      %{
        spacecraft_id: :sat_ready,
        antenna_available: true,
        thermal_margin_c: 5.0,
        power_margin: 0.9,
        battery_capacity_wh: 1400.0,
        battery_energy_used_wh: 350.0,
        battery_state_of_charge: 0.75,
        mode: :nominal,
        source_quality: :operator_supplied,
        provenance: %{trust_boundary: :operator_declared_resource_summary}
      }
    ]

    {allocated, report} =
      ContactAllocation.allocate_contacts(contacts, [],
        source: "unit_test.resource_allocation",
        resource_summaries: resource_summaries,
        resource_filter_policy: %{min_activity_thermal_margin_c: 2.0}
      )

    assert Enum.map(allocated, & &1["id"]) == ["dl_resource_ready"]

    assert %{
             "id" => "dl_resource_ready",
             "resource_source_quality" => "operator_supplied",
             "resource_trust_boundary_status" => "declared",
             "battery_capacity_wh" => 1400.0,
             "battery_energy_used_wh" => 350.0,
             "battery_state_of_charge" => 0.75,
             "thermal_margin_c" => 5.0,
             "mode" => "nominal",
             "source_resource_summary" => %{
               "battery_state_of_charge" => 0.75,
               "thermal_margin_c" => 5.0
             }
           } = hd(allocated)

    assert %{
             "allocated_contact_count" => 1,
             "blocked_contact_count" => 3,
             "resource_blocked_contact_count" => 3,
             "resource_blocked_contact_ids" => [
               "dl_activity_suppressed",
               "dl_antenna_unavailable",
               "dl_thermal_low"
             ],
             "resource_blocking_dimension_counts" => %{
               "activity_type" => 1,
               "antenna" => 1,
               "thermal" => 1
             },
             "resource_blocked_contact_ids_by_blocking_dimension" => %{
               "activity_type" => ["dl_activity_suppressed"],
               "antenna" => ["dl_antenna_unavailable"],
               "thermal" => ["dl_thermal_low"]
             },
             "resource_blocked_contact_ids_by_spacecraft_id" => %{
               "sat_activity_restricted" => ["dl_activity_suppressed"],
               "sat_low_resource" => ["dl_antenna_unavailable"],
               "sat_thermal_low" => ["dl_thermal_low"]
             },
             "resource_filter_report" => %{
               "schema_contract" => "resource_filter_report.v1",
               "suppressed_candidate_count" => 3
             }
           } = report

    assert %{
             "contact_id" => "dl_antenna_unavailable",
             "allocation_status" => "blocked",
             "allocation_reason" => "antenna_unavailable",
             "suppressed_reason" => "antenna_unavailable",
             "resource_blocking_dimension" => "antenna",
             "resource_source_quality" => "operator_supplied",
             "resource_trust_boundary" => "operator_declared_resource_summary",
             "resource_trust_boundary_status" => "declared",
             "battery_capacity_wh" => 1200.0,
             "battery_energy_used_wh" => 876.0,
             "battery_state_of_charge" => 0.27,
             "thermal_margin_c" => 4.0,
             "antenna_available" => false,
             "mode" => "degraded_payload",
             "source_resource_suppression" => %{
               "suppressed_reason" => "antenna_unavailable",
               "resource_blocking_dimension" => "antenna",
               "battery_state_of_charge" => 0.27,
               "thermal_margin_c" => 4.0,
               "mode" => "degraded_payload"
             }
           } = Enum.find(report["rows"], &(&1["contact_id"] == "dl_antenna_unavailable"))

    assert %{
             "contact_id" => "dl_thermal_low",
             "allocation_status" => "blocked",
             "allocation_reason" => "thermal_margin_below_policy",
             "suppressed_reason" => "thermal_margin_below_policy",
             "resource_blocking_dimension" => "thermal",
             "resource_source_quality" => "operator_supplied",
             "resource_trust_boundary_status" => "declared",
             "thermal_margin_c" => 1.5,
             "source_resource_suppression" => %{
               "suppressed_reason" => "thermal_margin_below_policy",
               "resource_blocking_dimension" => "thermal",
               "thermal_margin_c" => 1.5
             }
           } = Enum.find(report["rows"], &(&1["contact_id"] == "dl_thermal_low"))

    assert %{
             "contact_id" => "dl_activity_suppressed",
             "allocation_status" => "blocked",
             "allocation_reason" => "activity_type_suppressed_by_resource_summary",
             "suppressed_reason" => "activity_type_suppressed_by_resource_summary",
             "resource_blocking_dimension" => "activity_type",
             "suppressed_activity_types" => ["downlink"],
             "incompatible_activity_types" => ["tracking"],
             "source_resource_suppression" => %{
               "suppressed_activity_types" => ["downlink"],
               "incompatible_activity_types" => ["tracking"]
             }
           } = Enum.find(report["rows"], &(&1["contact_id"] == "dl_activity_suppressed"))

    assert %{
             "contact_id" => "dl_resource_ready",
             "allocation_status" => "allocated",
             "resource_source_quality" => "operator_supplied",
             "resource_trust_boundary_status" => "declared",
             "battery_capacity_wh" => 1400.0,
             "battery_energy_used_wh" => 350.0,
             "battery_state_of_charge" => 0.75,
             "thermal_margin_c" => 5.0,
             "mode" => "nominal",
             "source_resource_summary" => %{
               "spacecraft_id" => "sat_ready",
               "battery_state_of_charge" => 0.75,
               "thermal_margin_c" => 5.0
             }
           } = Enum.find(report["rows"], &(&1["contact_id"] == "dl_resource_ready"))

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)

    assert %{
             "resource_blocking_dimension_counts" => %{
               "activity_type" => 1,
               "antenna" => 1,
               "thermal" => 1
             },
             "resource_blocked_contact_ids_by_blocking_dimension" => %{
               "activity_type" => ["dl_activity_suppressed"],
               "antenna" => ["dl_antenna_unavailable"],
               "thermal" => ["dl_thermal_low"]
             },
             "resource_blocked_contact_ids_by_spacecraft_id" => %{
               "sat_activity_restricted" => ["dl_activity_suppressed"],
               "sat_low_resource" => ["dl_antenna_unavailable"],
               "sat_thermal_low" => ["dl_thermal_low"]
             }
           } = ContactAllocation.summary(report)

    review = OperatorReview.from_contact_allocation_report(report)

    assert Enum.any?(
             review["rows"],
             &(&1["contact_id"] == "dl_antenna_unavailable" and
                 &1["resource_blocking_dimension"] == "antenna" and
                 &1["battery_state_of_charge"] == 0.27 and
                 &1["thermal_margin_c"] == 4.0 and
                 &1["mode"] == "degraded_payload" and
                 get_in(&1, ["source_resource_suppression", "suppressed_reason"]) ==
                   "antenna_unavailable")
           )

    assert Enum.any?(
             review["rows"],
             &(&1["contact_id"] == "dl_thermal_low" and
                 &1["resource_blocking_dimension"] == "thermal" and
                 &1["thermal_margin_c"] == 1.5 and
                 get_in(&1, ["source_resource_suppression", "suppressed_reason"]) ==
                   "thermal_margin_below_policy")
           )

    assert Enum.any?(
             review["rows"],
             &(&1["contact_id"] == "dl_activity_suppressed" and
                 &1["suppressed_activity_types"] == ["downlink"] and
                 &1["incompatible_activity_types"] == ["tracking"] and
                 get_in(&1, ["source_resource_suppression", "suppressed_activity_types"]) == [
                   "downlink"
                 ])
           )

    assert Enum.any?(
             review["rows"],
             &(&1["contact_id"] == "dl_resource_ready" and
                 &1["battery_state_of_charge"] == 0.75 and
                 &1["thermal_margin_c"] == 5.0 and
                 get_in(&1, ["source_resource_summary", "spacecraft_id"]) == "sat_ready")
           )

    manifest = CadenceImport.from_contact_allocation_report(report)

    assert Enum.any?(
             manifest["rows"],
             &(&1["contact_id"] == "dl_antenna_unavailable" and
                 &1["resource_blocking_dimension"] == "antenna" and
                 get_in(&1, [
                   "source_contact_allocation",
                   "source_resource_suppression",
                   "resource_trust_boundary_status"
                 ]) == "declared" and
                 get_in(&1, [
                   "source_contact_allocation",
                   "source_resource_suppression",
                   "battery_state_of_charge"
                 ]) == 0.27 and
                 get_in(&1, [
                   "source_contact_allocation",
                   "source_resource_suppression",
                   "thermal_margin_c"
                 ]) == 4.0)
           )

    assert Enum.any?(
             manifest["rows"],
             &(&1["contact_id"] == "dl_thermal_low" and
                 &1["resource_blocking_dimension"] == "thermal" and
                 &1["thermal_margin_c"] == 1.5 and
                 get_in(&1, [
                   "source_contact_allocation",
                   "source_resource_suppression",
                   "thermal_margin_c"
                 ]) == 1.5)
           )

    assert Enum.any?(
             manifest["rows"],
             &(&1["contact_id"] == "dl_activity_suppressed" and
                 &1["suppressed_activity_types"] == ["downlink"] and
                 &1["incompatible_activity_types"] == ["tracking"] and
                 get_in(&1, [
                   "source_contact_allocation",
                   "source_resource_suppression",
                   "incompatible_activity_types"
                 ]) == ["tracking"])
           )

    assert Enum.any?(
             manifest["rows"],
             &(&1["contact_id"] == "dl_resource_ready" and
                 &1["battery_state_of_charge"] == 0.75 and
                 &1["thermal_margin_c"] == 5.0 and
                 get_in(&1, ["source_resource_summary", "spacecraft_id"]) == "sat_ready")
           )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    invalid_resource_evidence_report =
      update_in(report, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"contact_id" => "dl_activity_suppressed"} = row ->
            Map.put(row, "suppressed_activity_types", ["downlink", 7])

          row ->
            row
        end)
      end)

    assert {:error, invalid_resource_evidence} =
             Schema.validate_artifact(invalid_resource_evidence_report)

    assert Enum.any?(
             invalid_resource_evidence["errors"],
             &(String.contains?(&1["path"], ".suppressed_activity_types[1]") and
                 &1["message"] in ["must be a binary", "must be a string"])
           )
  end

  test "rejects non-list resource summaries for contact allocation" do
    assert_raise ArgumentError, ~r/resource summaries must be a list/, fn ->
      ContactAllocation.allocate_contacts(
        [contact(:dl_1, starts_at_s: 10.0, ends_at_s: 20.0)],
        [],
        resource_summaries: %{spacecraft_id: :sat_1}
      )
    end
  end

  test "accepts activity-type-only tracking command and health-check rows for allocation" do
    contacts = [
      %{
        id: :provider_tracking,
        activity_type: :tracking,
        scenario_id: :leo_1,
        station_id: :equator_prime,
        start_s: 100.0,
        end_s: 160.0,
        score: 2.0
      },
      %{
        id: :provider_command,
        activity_type: :command,
        scenario_id: :leo_1,
        station_id: :equator_prime,
        start_s: 200.0,
        end_s: 260.0,
        score: 1.0
      },
      %{
        id: :provider_health_check,
        activity_type: :health_check,
        scenario_id: :leo_1,
        station_id: :equator_prime,
        start_s: 300.0,
        end_s: 360.0,
        score: 1.5
      }
    ]

    {allocated, report} = ContactAllocation.allocate_contacts(contacts)

    assert Enum.map(allocated, &{&1["id"], &1["type"], &1["direction"]}) == [
             {"provider_tracking", "tracking", "tracking"},
             {"provider_command", "command", "command"},
             {"provider_health_check", "health_check", "health_check"}
           ]

    assert Enum.map(report["rows"], &{&1["contact_id"], &1["type"], &1["direction"]}) == [
             {"provider_tracking", "tracking", "tracking"},
             {"provider_command", "command", "command"},
             {"provider_health_check", "health_check", "health_check"}
           ]

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "uses health-check review requirements at allocation policy boundaries" do
    contacts = [
      contact(:health_reduced_capacity,
        type: :health_check,
        starts_at_s: 100.0,
        ends_at_s: 160.0
      )
    ]

    ground_network = [
      %{
        ground_station_id: :equator_prime,
        status: :available,
        capacity_fraction: 0.5,
        starts_at_s: 90.0,
        ends_at_s: 170.0
      }
    ]

    {_allocated, report} =
      ContactAllocation.allocate_contacts(contacts, ground_network,
        approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
      )

    assert [
             %{
               "contact_id" => "health_reduced_capacity",
               "type" => "health_check",
               "direction" => "health_check",
               "allocation_status" => "allocated",
               "station_availability" => "reduced_capacity",
               "approval_requirements" => [
                 %{
                   "requirement_type" => "health_check_review",
                   "reason" => "health-check contact allocation allocated: available"
                 }
               ]
             }
           ] = report["rows"]

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "canonicalizes direct station calendar statuses before allocation policy decisions" do
    contacts = [
      contact(:dl_direct_unavailable,
        starts_at_s: 100.0,
        ends_at_s: 160.0,
        station_availability: "Down",
        station_calendar_status: "Maintenance Window",
        source_station_calendar_entry: %{
          id: :direct_outage,
          availability: "Offline",
          status: "Maintenance Window"
        },
        station_calendar_precedence_rank: 0,
        station_calendar_precedence_availability: "Unavailable"
      ),
      contact(:dl_calendar_status_unavailable,
        starts_at_s: 165.0,
        ends_at_s: 175.0,
        station_calendar_status: "Offline"
      ),
      contact(:dl_nested_outage_overrides_flat_available,
        starts_at_s: 176.0,
        ends_at_s: 178.0,
        station_availability: "Available",
        source_station_calendar_entry: %{
          id: :nested_provider_outage,
          availability: "Offline"
        }
      ),
      contact(:dl_direct_reserved,
        starts_at_s: 180.0,
        ends_at_s: 220.0,
        station_availability: "Reserved",
        station_contention_status: "Reserved Overlap",
        station_reservation_id: :reservation_direct,
        station_reservation_status: "Confirmed",
        station_reservation_expires_at_s: "540.0",
        station_reservation_match_status: "Overlap",
        station_calendar_reservation_statuses: ["Confirmed"],
        station_calendar_reservation_expires_at_s: ["540.0"],
        source_station_calendar_overlaps: [
          %{
            id: :direct_reservation,
            availability: "Reserved",
            reservation_status: "Confirmed",
            reservation_expires_at_s: "540.0"
          }
        ]
      )
    ]

    {_allocated, report} =
      ContactAllocation.allocate_contacts(contacts, [],
        approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
      )

    unavailable = Enum.find(report["rows"], &(&1["contact_id"] == "dl_direct_unavailable"))

    status_only =
      Enum.find(report["rows"], &(&1["contact_id"] == "dl_calendar_status_unavailable"))

    nested_outage =
      Enum.find(
        report["rows"],
        &(&1["contact_id"] == "dl_nested_outage_overrides_flat_available")
      )

    reserved = Enum.find(report["rows"], &(&1["contact_id"] == "dl_direct_reserved"))

    assert %{
             "allocation_status" => "blocked",
             "allocation_reason" => "ground_station_unavailable",
             "station_availability" => "unavailable",
             "station_calendar_status" => "maintenance_window",
             "station_calendar_precedence_rank" => 0,
             "station_calendar_precedence_availability" => "unavailable",
             "source_station_calendar_entry" => %{
               "availability" => "unavailable",
               "status" => "maintenance_window"
             },
             "approval_status" => "blocked_by_policy"
           } = unavailable

    assert Enum.any?(
             unavailable["approval_rule_matches"],
             &(&1["rule_id"] == "unavailable_station_contact_block" and
                 &1["station_availability"] == "unavailable")
           )

    assert %{
             "allocation_status" => "blocked",
             "allocation_reason" => "ground_station_unavailable",
             "station_availability" => "unavailable",
             "station_calendar_status" => "unavailable",
             "approval_status" => "blocked_by_policy"
           } = status_only

    assert Enum.any?(
             status_only["approval_rule_matches"],
             &(&1["rule_id"] == "unavailable_station_contact_block" and
                 &1["station_availability"] == "unavailable")
           )

    assert %{
             "allocation_status" => "blocked",
             "allocation_reason" => "ground_station_unavailable",
             "station_availability" => "unavailable",
             "source_station_calendar_entry" => %{
               "availability" => "unavailable"
             },
             "approval_status" => "blocked_by_policy"
           } = nested_outage

    assert Enum.any?(
             nested_outage["approval_rule_matches"],
             &(&1["rule_id"] == "unavailable_station_contact_block" and
                 &1["station_availability"] == "unavailable")
           )

    assert %{
             "allocation_status" => "allocated",
             "station_availability" => "reserved",
             "station_contention_status" => "reserved_overlap",
             "station_reservation_status" => "confirmed",
             "station_reservation_expires_at_s" => 540.0,
             "station_reservation_match_status" => "overlap",
             "station_calendar_reservation_statuses" => ["confirmed"],
             "station_calendar_reservation_expires_at_s" => [540.0],
             "source_station_calendar_overlaps" => [
               %{
                 "availability" => "reserved",
                 "reservation_status" => "confirmed",
                 "reservation_expires_at_s" => "540.0"
               }
             ],
             "approval_status" => "operator_review_required"
           } = reserved

    assert Enum.any?(
             reserved["approval_rule_matches"],
             &(&1["rule_id"] == "reserved_station_contact_review" and
                 &1["station_reservation_status"] == "confirmed")
           )

    assert %{
             "station_pressure_contact_ids_by_ground_station_id" => %{
               "equator_prime" => [
                 "dl_direct_reserved",
                 "dl_direct_unavailable",
                 "dl_nested_outage_overrides_flat_available"
               ]
             },
             "station_pressure_contact_counts_by_ground_station_id" => %{
               "equator_prime" => 3
             },
             "station_pressure_contact_ids_by_availability" => %{
               "reserved" => ["dl_direct_reserved"],
               "unavailable" => [
                 "dl_direct_unavailable",
                 "dl_nested_outage_overrides_flat_available"
               ]
             },
             "station_pressure_contact_counts_by_availability" => %{
               "reserved" => 1,
               "unavailable" => 2
             },
             "station_pressure_contact_ids_by_precedence_availability" => %{
               "unavailable" => ["dl_direct_unavailable"]
             },
             "station_pressure_contact_counts_by_precedence_availability" => %{
               "unavailable" => 1
             },
             "station_pressure_contact_ids_by_precedence_rank" => %{
               "0" => ["dl_direct_unavailable"]
             },
             "station_pressure_contact_counts_by_precedence_rank" => %{
               "0" => 1
             },
             "station_pressure_contact_ids_by_status" => %{
               "maintenance_window" => ["dl_direct_unavailable"]
             },
             "station_pressure_contact_counts_by_status" => %{
               "maintenance_window" => 1
             },
             "station_pressure_contact_ids_by_direction_and_ground_station_id" => %{
               "downlink" => %{
                 "equator_prime" => [
                   "dl_direct_reserved",
                   "dl_direct_unavailable",
                   "dl_nested_outage_overrides_flat_available"
                 ]
               }
             }
           } = report

    assert %{
             "station_reservation_status_counts" => %{"confirmed" => 1},
             "station_reservation_contact_ids_by_status" => %{
               "confirmed" => ["dl_direct_reserved"]
             },
             "station_reservation_contact_ids_by_match_status" => %{
               "overlap" => ["dl_direct_reserved"]
             },
             "station_pressure_contact_ids_by_precedence_availability" => %{
               "unavailable" => ["dl_direct_unavailable"]
             },
             "station_pressure_contact_ids_by_precedence_rank" => %{
               "0" => ["dl_direct_unavailable"]
             },
             "station_pressure_contact_ids_by_status" => %{
               "maintenance_window" => ["dl_direct_unavailable"]
             },
             "station_pressure_contact_counts_by_status" => %{
               "maintenance_window" => 1
             },
             "station_pressure_contact_ids_by_direction_and_ground_station_id" => %{
               "downlink" => %{
                 "equator_prime" => [
                   "dl_direct_reserved",
                   "dl_direct_unavailable",
                   "dl_nested_outage_overrides_flat_available"
                 ]
               }
             }
           } = ContactAllocation.summary(report)

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)

    assert %{
             "schema_contract" => "contact_allocation_station_pressure_summary.v1",
             "station_pressure_contact_ids_by_status" => %{
               "maintenance_window" => ["dl_direct_unavailable"]
             },
             "station_pressure_contact_counts_by_status" => %{
               "maintenance_window" => 1
             }
           } = station_pressure_summary = ContactAllocation.station_pressure_summary(report)

    assert {:ok, %{"schema_contract" => "contact_allocation_station_pressure_summary.v1"}} =
             Schema.validate_artifact(station_pressure_summary)

    stale_precedence_rank_report =
      Map.put(report, "station_pressure_contact_ids_by_precedence_rank", %{
        "0" => ["dl_direct_reserved"]
      })

    assert {:error, stale_precedence_rank_validation} =
             Schema.validate_artifact(stale_precedence_rank_report)

    assert Enum.any?(
             stale_precedence_rank_validation["errors"],
             &(&1["path"] == "$.station_pressure_contact_ids_by_precedence_rank" and
                 &1["message"] ==
                   "must equal row-derived station_pressure_contact_ids_by_precedence_rank")
           )

    stale_precedence_rank_count_report =
      Map.put(report, "station_pressure_contact_counts_by_precedence_rank", %{
        "0" => 2
      })

    assert {:error, stale_precedence_rank_count_validation} =
             Schema.validate_artifact(stale_precedence_rank_count_report)

    assert Enum.any?(
             stale_precedence_rank_count_validation["errors"],
             &(&1["path"] == "$.station_pressure_contact_counts_by_precedence_rank" and
                 &1["message"] ==
                   "must equal row-derived station_pressure_contact_counts_by_precedence_rank")
           )

    stale_direction_station_report =
      Map.put(report, "station_pressure_contact_ids_by_direction_and_ground_station_id", %{
        "uplink" => %{"equator_prime" => ["dl_direct_reserved"]}
      })

    assert {:error, stale_direction_station_validation} =
             Schema.validate_artifact(stale_direction_station_report)

    assert Enum.any?(
             stale_direction_station_validation["errors"],
             &(&1["path"] ==
                 "$.station_pressure_contact_ids_by_direction_and_ground_station_id" and
                 &1["message"] ==
                   "must equal row-derived station_pressure_contact_ids_by_direction_and_ground_station_id")
           )

    stale_status_report =
      Map.put(report, "station_pressure_contact_ids_by_status", %{
        "maintenance_window" => ["dl_direct_reserved"]
      })

    assert {:error, stale_status_validation} =
             Schema.validate_artifact(stale_status_report)

    assert Enum.any?(
             stale_status_validation["errors"],
             &(&1["path"] == "$.station_pressure_contact_ids_by_status" and
                 &1["message"] ==
                   "must equal row-derived station_pressure_contact_ids_by_status")
           )
  end

  test "summary derives station pressure routing from source station-calendar provenance" do
    report = %{
      "schema_contract" => "contact_allocation_report.v1",
      "source" => "allocation_summary_test",
      "rows" => [
        %{
          "contact_id" => "dl_source_outage",
          "ground_station_id" => "dss_14",
          "allocation_status" => "blocked",
          "source_station_calendar_entry" => %{
            "id" => "provider_outage",
            "availability" => "Offline"
          }
        },
        %{
          "contact_id" => "dl_source_reserved",
          "ground_station_id" => "dss_14",
          "allocation_status" => "blocked",
          "source_station_calendar_overlaps" => [
            %{"id" => "provider_reservation", "availability" => "Reserved"}
          ]
        },
        %{
          "contact_id" => "dl_source_available",
          "ground_station_id" => "dss_14",
          "allocation_status" => "allocated",
          "source_station_calendar_entry" => %{
            "id" => "provider_available",
            "availability" => "Available"
          }
        }
      ]
    }

    assert %{
             "station_pressure_contact_ids_by_ground_station_id" => %{
               "dss_14" => ["dl_source_outage", "dl_source_reserved"]
             },
             "station_pressure_contact_ids_by_availability" => %{
               "reserved" => ["dl_source_reserved"],
               "unavailable" => ["dl_source_outage"]
             }
           } = ContactAllocation.summary(report)
  end

  test "blocks contacts whose declared capacity need exceeds reduced station capacity" do
    contacts = [
      contact(:dl_capacity_heavy,
        starts_at_s: 100.0,
        ends_at_s: 160.0,
        required_station_capacity_fraction: 0.75
      ),
      contact(:dl_capacity_light,
        starts_at_s: 200.0,
        ends_at_s: 260.0,
        required_capacity_fraction: 0.25
      )
    ]

    ground_network = [
      %{
        ground_station_id: :equator_prime,
        status: :available,
        capacity_fraction: 0.5,
        starts_at_s: 90.0,
        ends_at_s: 270.0
      }
    ]

    {allocated, report} =
      ContactAllocation.allocate_contacts(contacts, ground_network,
        source: "unit_test.contacts",
        approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
      )

    assert Enum.map(allocated, & &1["id"]) == ["dl_capacity_light"]

    assert %{
             "contact_id" => "dl_capacity_heavy",
             "allocation_status" => "blocked",
             "allocation_reason" => "ground_station_reduced_capacity_insufficient",
             "suppressed_reason" => "ground_station_reduced_capacity_insufficient",
             "station_availability" => "reduced_capacity",
             "capacity_fraction" => 0.5,
             "required_capacity_fraction" => 0.75,
             "approval_status" => "blocked_by_policy"
           } = Enum.find(report["rows"], &(&1["contact_id"] == "dl_capacity_heavy"))

    blocked_row = Enum.find(report["rows"], &(&1["contact_id"] == "dl_capacity_heavy"))

    assert Enum.any?(
             blocked_row["approval_rule_matches"],
             &(&1["rule_id"] == "reduced_station_capacity_insufficient_block" and
                 &1["capacity_fraction"] == 0.5 and
                 &1["required_capacity_fraction"] == 0.75 and
                 &1["allocation_reason"] == "ground_station_reduced_capacity_insufficient" and
                 &1["suppressed_reason"] == "ground_station_reduced_capacity_insufficient")
           )

    assert %{
             "contact_id" => "dl_capacity_light",
             "allocation_status" => "allocated",
             "capacity_fraction" => 0.5,
             "required_capacity_fraction" => 0.25
           } = Enum.find(report["rows"], &(&1["contact_id"] == "dl_capacity_light"))

    review = OperatorReview.from_contact_allocation_report(report)
    review_row = Enum.find(review["rows"], &(&1["contact_id"] == "dl_capacity_heavy"))

    assert %{
             "allocation_reason" => "ground_station_reduced_capacity_insufficient",
             "required_capacity_fraction" => 0.75,
             "capacity_fraction" => 0.5
           } = review_row

    manifest = CadenceImport.from_contact_allocation_report(report)
    import_row = Enum.find(manifest["rows"], &(&1["contact_id"] == "dl_capacity_heavy"))

    assert %{
             "import_action" => "review_contact_allocation",
             "allocation_reason" => "ground_station_reduced_capacity_insufficient",
             "required_capacity_fraction" => 0.75,
             "capacity_fraction" => 0.5
           } = import_row

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "uses source station calendar capacity aliases for reduced capacity allocation" do
    contacts = [
      contact(:dl_direct_availability_capacity_heavy,
        starts_at_s: 40.0,
        ends_at_s: 90.0,
        required_station_capacity_fraction: 0.75,
        availability: "0.5"
      ),
      contact(:dl_nested_availability_capacity_heavy,
        starts_at_s: 45.0,
        ends_at_s: 95.0,
        required_station_capacity_fraction: 0.75,
        capacity_model: %{availability: "0.5"}
      ),
      contact(:dl_source_entry_capacity_heavy,
        starts_at_s: 100.0,
        ends_at_s: 160.0,
        required_station_capacity_fraction: 0.75,
        source_station_calendar_entry: %{
          id: :provider_reduced_capacity,
          availability: "0.5"
        }
      ),
      contact(:dl_source_overlap_capacity_light,
        starts_at_s: 200.0,
        ends_at_s: 260.0,
        required_capacity_fraction: 0.25,
        source_station_calendar_overlaps: [
          %{availability: 0.5}
        ]
      ),
      contact(:dl_bad_source_overlap_capacity,
        starts_at_s: 300.0,
        ends_at_s: 360.0,
        required_capacity_fraction: 0.25,
        source_station_calendar_overlaps: [
          %{capacity_model: %{station_capacity_percent: "125"}}
        ]
      )
    ]

    {allocated, report} =
      ContactAllocation.allocate_contacts(contacts, [], source: "unit_test.contacts")

    assert Enum.map(allocated, & &1["id"]) == ["dl_source_overlap_capacity_light"]

    assert %{
             "invalid_contact_input_count" => 1,
             "blocked_contact_count" => 4,
             "allocated_contact_count" => 1
           } = report

    assert %{
             "contact_id" => "dl_direct_availability_capacity_heavy",
             "allocation_status" => "blocked",
             "allocation_reason" => "ground_station_reduced_capacity_insufficient",
             "capacity_fraction" => 0.5,
             "required_capacity_fraction" => 0.75,
             "source_station_calendar_contact" => %{
               "availability" => "0.5"
             }
           } =
             Enum.find(
               report["rows"],
               &(&1["contact_id"] == "dl_direct_availability_capacity_heavy")
             )

    assert %{
             "contact_id" => "dl_nested_availability_capacity_heavy",
             "allocation_status" => "blocked",
             "allocation_reason" => "ground_station_reduced_capacity_insufficient",
             "capacity_fraction" => 0.5,
             "required_capacity_fraction" => 0.75,
             "source_station_calendar_contact" => %{
               "capacity_model" => %{"availability" => "0.5"}
             }
           } =
             Enum.find(
               report["rows"],
               &(&1["contact_id"] == "dl_nested_availability_capacity_heavy")
             )

    assert %{
             "contact_id" => "dl_source_entry_capacity_heavy",
             "allocation_status" => "blocked",
             "allocation_reason" => "ground_station_reduced_capacity_insufficient",
             "capacity_fraction" => 0.5,
             "required_capacity_fraction" => 0.75,
             "source_station_calendar_entry" => %{
               "availability" => "0.5"
             }
           } = Enum.find(report["rows"], &(&1["contact_id"] == "dl_source_entry_capacity_heavy"))

    assert %{
             "contact_id" => "dl_source_overlap_capacity_light",
             "allocation_status" => "allocated",
             "capacity_fraction" => 0.5,
             "required_capacity_fraction" => 0.25,
             "source_station_calendar_overlaps" => [
               %{"availability" => 0.5}
             ]
           } =
             Enum.find(report["rows"], &(&1["contact_id"] == "dl_source_overlap_capacity_light"))

    assert %{
             "contact_id" => "dl_bad_source_overlap_capacity",
             "allocation_status" => "blocked",
             "allocation_reason" => "invalid_capacity_fraction",
             "invalid_contact_input" => true,
             "source_contact_candidate" => %{
               "source_station_calendar_overlaps" => [
                 %{"capacity_model" => %{"station_capacity_percent" => "125"}}
               ]
             }
           } = Enum.find(report["rows"], &(&1["contact_id"] == "dl_bad_source_overlap_capacity"))

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "normalizes numeric string timing and capacity fields for reduced capacity allocation" do
    contacts = [
      %{
        id: :dl_capacity_heavy,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        start_s: "100.0",
        end_s: "160.0",
        required_station_capacity_fraction: "0.75"
      },
      %{
        id: :dl_capacity_light,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: "200.0",
        ends_at_s: "260.0",
        throughput_model: %{required_capacity_percent: "25"}
      },
      %{
        id: :dl_capacity_model,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: "300.0",
        ends_at_s: "360.0",
        capacity_model: %{required_station_capacity_percent: "40"}
      },
      %{
        id: :dl_capacity_context,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: "400.0",
        ends_at_s: "460.0",
        activity_context: %{station_capacity_requirement_percent: "30"}
      }
    ]

    ground_network = [
      %{
        ground_station_id: :equator_prime,
        status: :available,
        capacity_percent: "50",
        starts_at_s: 90.0,
        ends_at_s: 470.0
      }
    ]

    {allocated, report} =
      ContactAllocation.allocate_contacts(contacts, ground_network, source: "unit_test.contacts")

    assert Enum.map(allocated, & &1["id"]) == [
             "dl_capacity_light",
             "dl_capacity_model",
             "dl_capacity_context"
           ]

    assert %{
             "contact_id" => "dl_capacity_heavy",
             "starts_at_s" => 100.0,
             "ends_at_s" => 160.0,
             "allocation_status" => "blocked",
             "allocation_reason" => "ground_station_reduced_capacity_insufficient",
             "capacity_fraction" => 0.5,
             "required_capacity_fraction" => 0.75
           } = Enum.find(report["rows"], &(&1["contact_id"] == "dl_capacity_heavy"))

    assert %{
             "contact_id" => "dl_capacity_light",
             "starts_at_s" => 200.0,
             "ends_at_s" => 260.0,
             "allocation_status" => "allocated",
             "required_capacity_fraction" => 0.25,
             "required_capacity_fraction_source" => "throughput_model"
           } = Enum.find(report["rows"], &(&1["contact_id"] == "dl_capacity_light"))

    assert %{
             "contact_id" => "dl_capacity_model",
             "allocation_status" => "allocated",
             "required_capacity_fraction" => 0.4,
             "required_capacity_fraction_source" => "capacity_model"
           } = Enum.find(report["rows"], &(&1["contact_id"] == "dl_capacity_model"))

    assert %{
             "contact_id" => "dl_capacity_context",
             "allocation_status" => "allocated",
             "required_capacity_fraction" => 0.3,
             "required_capacity_fraction_source" => "activity_context"
           } = Enum.find(report["rows"], &(&1["contact_id"] == "dl_capacity_context"))

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "blocks out-of-range allocation capacity fractions as invalid inputs" do
    contacts = [
      contact(:dl_bad_required_capacity,
        starts_at_s: 100.0,
        ends_at_s: 160.0,
        required_capacity_fraction: 1.2
      ),
      %{
        id: :dl_bad_nested_required_capacity,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 200.0,
        ends_at_s: 260.0,
        throughput_model: %{required_capacity_fraction: "-0.1"}
      },
      %{
        id: :dl_bad_percent_required_capacity,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 250.0,
        ends_at_s: 290.0,
        capacity_model: %{required_capacity_percent: "125"}
      },
      contact(:dl_bad_station_capacity,
        starts_at_s: 300.0,
        ends_at_s: 360.0,
        station_capacity_fraction: "1.1"
      ),
      contact(:dl_bad_capacity_pack_fraction,
        starts_at_s: 400.0,
        ends_at_s: 460.0,
        capacity_pack_capacity_fraction: "1.2"
      )
    ]

    {allocated, report} =
      ContactAllocation.allocate_contacts(contacts, [], source: "unit_test.contacts")

    assert allocated == []
    assert report["invalid_contact_input_count"] == 5
    assert report["blocked_contact_count"] == 5

    assert %{
             "contact_id" => "dl_bad_required_capacity",
             "allocation_status" => "blocked",
             "allocation_reason" => "invalid_required_capacity_fraction",
             "invalid_contact_input" => true,
             "invalid_contact_input_reason" => "invalid_required_capacity_fraction"
           } = Enum.find(report["rows"], &(&1["contact_id"] == "dl_bad_required_capacity"))

    assert %{
             "contact_id" => "dl_bad_nested_required_capacity",
             "allocation_status" => "blocked",
             "allocation_reason" => "invalid_required_capacity_fraction",
             "source_contact_candidate" => %{
               "throughput_model" => %{"required_capacity_fraction" => "-0.1"}
             }
           } =
             Enum.find(
               report["rows"],
               &(&1["contact_id"] == "dl_bad_nested_required_capacity")
             )

    assert %{
             "contact_id" => "dl_bad_percent_required_capacity",
             "allocation_status" => "blocked",
             "allocation_reason" => "invalid_required_capacity_fraction",
             "source_contact_candidate" => %{
               "capacity_model" => %{"required_capacity_percent" => "125"}
             }
           } =
             Enum.find(
               report["rows"],
               &(&1["contact_id"] == "dl_bad_percent_required_capacity")
             )

    assert %{
             "contact_id" => "dl_bad_station_capacity",
             "allocation_status" => "blocked",
             "allocation_reason" => "invalid_capacity_fraction",
             "invalid_contact_input_reason" => "invalid_capacity_fraction"
           } = Enum.find(report["rows"], &(&1["contact_id"] == "dl_bad_station_capacity"))

    assert %{
             "contact_id" => "dl_bad_capacity_pack_fraction",
             "allocation_status" => "blocked",
             "allocation_reason" => "invalid_capacity_fraction",
             "invalid_contact_input_reason" => "invalid_capacity_fraction",
             "source_contact_candidate" => %{"capacity_pack_capacity_fraction" => "1.2"}
           } = Enum.find(report["rows"], &(&1["contact_id"] == "dl_bad_capacity_pack_fraction"))

    refute Enum.any?(report["rows"], &Map.has_key?(&1, "required_capacity_fraction"))

    invalid_required_capacity_report =
      update_in(report, ["rows", Access.at(0)], fn row ->
        Map.put(row, "required_capacity_fraction", 1.2)
      end)

    assert {:error, validation_report} =
             Schema.validate_artifact(invalid_required_capacity_report)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.rows[0].required_capacity_fraction" and
                 &1["message"] == "must be between 0.0 and 1.0")
           )

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "packs overlapping reduced-capacity contacts when declared capacity requirements fit" do
    contacts = [
      contact(:dl_capacity_primary,
        starts_at_s: 100.0,
        ends_at_s: 180.0,
        required_capacity_fraction: 0.25,
        score: 10.0
      ),
      contact(:dl_capacity_secondary,
        starts_at_s: 120.0,
        ends_at_s: 170.0,
        required_capacity_fraction: 0.25,
        score: 5.0
      ),
      contact(:dl_capacity_overflow,
        starts_at_s: 130.0,
        ends_at_s: 160.0,
        required_capacity_fraction: 0.25,
        score: 1.0
      )
    ]

    ground_network = [
      %{
        ground_station_id: :equator_prime,
        status: :available,
        capacity_fraction: 0.5,
        starts_at_s: 90.0,
        ends_at_s: 190.0
      }
    ]

    {allocated, report} =
      ContactAllocation.allocate_contacts(contacts, ground_network, source: "unit_test.contacts")

    assert Enum.map(allocated, & &1["id"]) == ["dl_capacity_primary", "dl_capacity_secondary"]

    assert %{
             "reduced_capacity_pack_group_count" => 1,
             "reduced_capacity_pack_status_counts" => %{"capacity_limited" => 1},
             "capacity_pack_status_counts" => %{
               "deferred_by_reduced_station_capacity_pack" => 1,
               "selected_by_contention_resolution" => 1,
               "selected_by_reduced_station_capacity_pack" => 1
             },
             "capacity_pack_contact_ids_by_status" => %{
               "deferred_by_reduced_station_capacity_pack" => ["dl_capacity_overflow"],
               "selected_by_contention_resolution" => ["dl_capacity_primary"],
               "selected_by_reduced_station_capacity_pack" => ["dl_capacity_secondary"]
             },
             "capacity_pack_required_capacity_fraction" => 0.75,
             "capacity_pack_selected_required_capacity_fraction" => 0.5,
             "capacity_pack_deferred_required_capacity_fraction" => 0.25,
             "capacity_pack_required_capacity_fraction_by_status" => %{
               "deferred_by_reduced_station_capacity_pack" => 0.25,
               "selected_by_contention_resolution" => 0.25,
               "selected_by_reduced_station_capacity_pack" => 0.25
             },
             "capacity_pack_required_capacity_fraction_by_ground_station_id" => %{
               "equator_prime" => 0.75
             },
             "capacity_pack_selected_required_capacity_fraction_by_ground_station_id" => %{
               "equator_prime" => 0.5
             },
             "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id" => %{
               "equator_prime" => 0.25
             },
             "required_capacity_fraction_source_counts" => %{
               "contact_required_capacity_fraction" => 3
             },
             "required_capacity_fraction_contact_ids_by_source" => %{
               "contact_required_capacity_fraction" => [
                 "dl_capacity_overflow",
                 "dl_capacity_primary",
                 "dl_capacity_secondary"
               ]
             },
             "reduced_capacity_packed_contact_ids" => ["dl_capacity_secondary"],
             "reduced_capacity_deferred_contact_ids" => ["dl_capacity_overflow"],
             "reduced_capacity_pack_groups" => [
               %{
                 "capacity_fraction" => 0.5,
                 "used_capacity_fraction" => 0.5,
                 "unused_capacity_fraction" => unused_capacity_fraction,
                 "selected_contact_ids" => ["dl_capacity_primary"],
                 "capacity_packed_contact_ids" => ["dl_capacity_secondary"],
                 "deferred_contact_ids" => ["dl_capacity_overflow"],
                 "capacity_requirement_rows" => capacity_requirement_rows,
                 "pack_status" => "capacity_limited"
               }
             ],
             "rows" => rows
           } = report

    assert_in_delta unused_capacity_fraction, 0.0, 1.0e-12

    assert [
             %{
               "contact_id" => "dl_capacity_primary",
               "allocation_status" => "allocated",
               "allocation_reason" => "selected_by_contention_resolution",
               "capacity_pack_status" => "selected_by_contention_resolution",
               "required_capacity_fraction" => 0.25,
               "required_capacity_fraction_source" => "contact_required_capacity_fraction"
             },
             %{
               "contact_id" => "dl_capacity_secondary",
               "allocation_status" => "allocated",
               "allocation_reason" => "selected_by_reduced_station_capacity_pack",
               "capacity_pack_status" => "selected_by_reduced_station_capacity_pack",
               "required_capacity_fraction" => 0.25,
               "required_capacity_fraction_source" => "contact_required_capacity_fraction"
             },
             %{
               "contact_id" => "dl_capacity_overflow",
               "allocation_status" => "deferred",
               "allocation_reason" => "same_station_contention",
               "capacity_pack_status" => "deferred_by_reduced_station_capacity_pack",
               "required_capacity_fraction" => 0.25,
               "required_capacity_fraction_source" => "contact_required_capacity_fraction"
             }
           ] = capacity_requirement_rows

    pack_group_id =
      report
      |> Map.fetch!("reduced_capacity_pack_groups")
      |> List.first()
      |> Map.fetch!("contention_group_id")

    assert %{
             "id" => "dl_capacity_secondary",
             "allocation_status" => "allocated",
             "allocation_reason" => "selected_by_reduced_station_capacity_pack",
             "capacity_pack_group_id" => ^pack_group_id,
             "capacity_pack_status" => "selected_by_reduced_station_capacity_pack",
             "capacity_pack_capacity_fraction" => 0.5,
             "capacity_pack_used_fraction" => 0.5
           } = Enum.find(allocated, &(&1["id"] == "dl_capacity_secondary"))

    assert %{
             "contact_id" => "dl_capacity_primary",
             "allocation_status" => "allocated",
             "allocation_reason" => "selected_by_contention_resolution",
             "capacity_fraction" => 0.5,
             "required_capacity_fraction" => 0.25,
             "required_capacity_fraction_source" => "contact_required_capacity_fraction",
             "capacity_pack_group_id" => ^pack_group_id,
             "capacity_pack_status" => "selected_by_contention_resolution",
             "capacity_pack_capacity_fraction" => 0.5,
             "capacity_pack_used_fraction" => 0.5
           } = Enum.find(rows, &(&1["contact_id"] == "dl_capacity_primary"))

    assert %{
             "contact_id" => "dl_capacity_secondary",
             "allocation_status" => "allocated",
             "allocation_reason" => "selected_by_reduced_station_capacity_pack",
             "capacity_fraction" => 0.5,
             "required_capacity_fraction" => 0.25,
             "required_capacity_fraction_source" => "contact_required_capacity_fraction",
             "capacity_pack_group_id" => ^pack_group_id,
             "capacity_pack_status" => "selected_by_reduced_station_capacity_pack",
             "capacity_pack_capacity_fraction" => 0.5,
             "capacity_pack_used_fraction" => 0.5
           } = Enum.find(rows, &(&1["contact_id"] == "dl_capacity_secondary"))

    assert %{
             "contact_id" => "dl_capacity_overflow",
             "allocation_status" => "deferred",
             "allocation_reason" => "same_station_contention",
             "capacity_fraction" => 0.5,
             "required_capacity_fraction" => 0.25,
             "required_capacity_fraction_source" => "contact_required_capacity_fraction",
             "capacity_pack_group_id" => ^pack_group_id,
             "capacity_pack_status" => "deferred_by_reduced_station_capacity_pack",
             "capacity_pack_capacity_fraction" => 0.5,
             "capacity_pack_used_fraction" => 0.5
           } = Enum.find(rows, &(&1["contact_id"] == "dl_capacity_overflow"))

    review = OperatorReview.from_contact_allocation_report(report)

    pack_review =
      Enum.find(
        review["rows"],
        &(&1["review_type"] == "contact_allocation_capacity_pack_review")
      )

    assert %{
             "action" => "review_contact_allocation_capacity_pack",
             "required_operator_action" => "review_contact_allocation_capacity_pack",
             "contention_group_id" => ^pack_group_id,
             "ground_station_id" => "equator_prime",
             "capacity_fraction" => 0.5,
             "used_capacity_fraction" => 0.5,
             "selected_contact_ids" => ["dl_capacity_primary"],
             "capacity_packed_contact_ids" => ["dl_capacity_secondary"],
             "deferred_contact_ids" => ["dl_capacity_overflow"],
             "capacity_requirement_rows" => ^capacity_requirement_rows,
             "pack_status" => "capacity_limited",
             "source_contact_allocation_capacity_pack" => %{
               "contention_group_id" => ^pack_group_id
             }
           } = pack_review

    secondary_review = Enum.find(review["rows"], &(&1["contact_id"] == "dl_capacity_secondary"))

    assert %{
             "allocation_reason" => "selected_by_reduced_station_capacity_pack",
             "required_capacity_fraction" => 0.25,
             "capacity_fraction" => 0.5,
             "capacity_pack_status" => "selected_by_reduced_station_capacity_pack",
             "capacity_pack_used_fraction" => 0.5
           } = secondary_review

    manifest = CadenceImport.from_contact_allocation_report(report)

    pack_import =
      Enum.find(
        manifest["rows"],
        &(&1["source_review_type"] == "contact_allocation_capacity_pack_review")
      )

    assert %{
             "import_action" => "review_contact_allocation_capacity_pack",
             "contention_group_id" => ^pack_group_id,
             "ground_station_id" => "equator_prime",
             "capacity_fraction" => 0.5,
             "used_capacity_fraction" => 0.5,
             "capacity_packed_contact_ids" => ["dl_capacity_secondary"],
             "capacity_requirement_rows" => ^capacity_requirement_rows,
             "pack_status" => "capacity_limited",
             "source_contact_allocation_capacity_pack" => %{
               "contention_group_id" => ^pack_group_id
             }
           } = pack_import

    secondary_import = Enum.find(manifest["rows"], &(&1["contact_id"] == "dl_capacity_secondary"))

    assert %{
             "import_action" => "review_contact_allocation",
             "allocation_reason" => "selected_by_reduced_station_capacity_pack",
             "required_capacity_fraction" => 0.25,
             "capacity_fraction" => 0.5,
             "capacity_pack_status" => "selected_by_reduced_station_capacity_pack",
             "capacity_pack_used_fraction" => 0.5
           } = secondary_import

    assert %{
             "allocated_contact_ids" => ["dl_capacity_primary", "dl_capacity_secondary"],
             "returned_allocated_contact_ids" => [
               "dl_capacity_primary",
               "dl_capacity_secondary"
             ],
             "deferred_contact_ids" => ["dl_capacity_overflow"],
             "blocked_contact_ids" => [],
             "reduced_capacity_pack_status_counts" => %{"capacity_limited" => 1},
             "capacity_pack_status_counts" => %{
               "deferred_by_reduced_station_capacity_pack" => 1,
               "selected_by_contention_resolution" => 1,
               "selected_by_reduced_station_capacity_pack" => 1
             },
             "capacity_pack_contact_ids_by_status" => %{
               "deferred_by_reduced_station_capacity_pack" => ["dl_capacity_overflow"],
               "selected_by_contention_resolution" => ["dl_capacity_primary"],
               "selected_by_reduced_station_capacity_pack" => ["dl_capacity_secondary"]
             },
             "capacity_pack_contact_ids_by_ground_station_id" => %{
               "equator_prime" => [
                 "dl_capacity_overflow",
                 "dl_capacity_primary",
                 "dl_capacity_secondary"
               ]
             },
             "capacity_pack_selected_contact_ids_by_ground_station_id" => %{
               "equator_prime" => ["dl_capacity_primary", "dl_capacity_secondary"]
             },
             "capacity_pack_deferred_contact_ids_by_ground_station_id" => %{
               "equator_prime" => ["dl_capacity_overflow"]
             },
             "capacity_pack_required_capacity_fraction" => 0.75,
             "capacity_pack_selected_required_capacity_fraction" => 0.5,
             "capacity_pack_deferred_required_capacity_fraction" => 0.25,
             "capacity_pack_required_capacity_fraction_by_status" => %{
               "deferred_by_reduced_station_capacity_pack" => 0.25,
               "selected_by_contention_resolution" => 0.25,
               "selected_by_reduced_station_capacity_pack" => 0.25
             },
             "capacity_pack_required_capacity_fraction_by_ground_station_id" => %{
               "equator_prime" => 0.75
             },
             "capacity_pack_selected_required_capacity_fraction_by_ground_station_id" => %{
               "equator_prime" => 0.5
             },
             "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id" => %{
               "equator_prime" => 0.25
             },
             "required_capacity_fraction_source_counts" => %{
               "contact_required_capacity_fraction" => 3
             },
             "required_capacity_fraction_contact_ids_by_source" => %{
               "contact_required_capacity_fraction" => [
                 "dl_capacity_overflow",
                 "dl_capacity_primary",
                 "dl_capacity_secondary"
               ]
             },
             "reduced_capacity_packed_contact_ids" => ["dl_capacity_secondary"],
             "reduced_capacity_deferred_contact_ids" => ["dl_capacity_overflow"],
             "review_contact_ids" => [
               "dl_capacity_overflow",
               "dl_capacity_primary",
               "dl_capacity_secondary"
             ]
           } = ContactAllocation.summary(report)

    expected_capability_assumptions = contact_allocation_capacity_pack_capability_assumptions()
    expected_capacity_pack_statuses = expected_capability_assumptions["capacity_pack_statuses"]

    expected_reduced_capacity_pack_statuses =
      expected_capability_assumptions["reduced_capacity_pack_statuses"]

    expected_required_capacity_fraction_source_values =
      expected_capability_assumptions["required_capacity_fraction_source_values"]

    expected_required_capacity_value_paths =
      expected_capability_assumptions["required_capacity_value_paths"]

    expected_default_required_capacity_value_paths =
      expected_capability_assumptions["default_required_capacity_value_paths"]

    assert %{
             "schema_contract" => "contact_allocation_capacity_pack_summary.v1",
             "model" => "artifact_only_contact_allocation_capacity_pack_summary",
             "model_limits" => model_limits,
             "source_artifact_type" => "contact_allocation_report.v1",
             "source" => "unit_test.contacts",
             "input_contact_count" => 3,
             "capacity_pack_contact_count" => 3,
             "capacity_pack_review_status" => "review_required",
             "reduced_capacity_pack_group_count" => 1,
             "reduced_capacity_pack_status_counts" => %{"capacity_limited" => 1},
             "capacity_pack_status_counts" => %{
               "deferred_by_reduced_station_capacity_pack" => 1,
               "selected_by_contention_resolution" => 1,
               "selected_by_reduced_station_capacity_pack" => 1
             },
             "capacity_pack_contact_ids_by_status" => %{
               "deferred_by_reduced_station_capacity_pack" => ["dl_capacity_overflow"],
               "selected_by_contention_resolution" => ["dl_capacity_primary"],
               "selected_by_reduced_station_capacity_pack" => ["dl_capacity_secondary"]
             },
             "capacity_pack_contact_ids_by_ground_station_id" => %{
               "equator_prime" => [
                 "dl_capacity_overflow",
                 "dl_capacity_primary",
                 "dl_capacity_secondary"
               ]
             },
             "capacity_pack_selected_contact_ids_by_ground_station_id" => %{
               "equator_prime" => ["dl_capacity_primary", "dl_capacity_secondary"]
             },
             "capacity_pack_deferred_contact_ids_by_ground_station_id" => %{
               "equator_prime" => ["dl_capacity_overflow"]
             },
             "capacity_pack_required_capacity_fraction" => 0.75,
             "capacity_pack_selected_required_capacity_fraction" => 0.5,
             "capacity_pack_deferred_required_capacity_fraction" => 0.25,
             "capacity_pack_required_capacity_fraction_by_status" => %{
               "deferred_by_reduced_station_capacity_pack" => 0.25,
               "selected_by_contention_resolution" => 0.25,
               "selected_by_reduced_station_capacity_pack" => 0.25
             },
             "capacity_pack_required_capacity_fraction_by_ground_station_id" => %{
               "equator_prime" => 0.75
             },
             "capacity_pack_selected_required_capacity_fraction_by_ground_station_id" => %{
               "equator_prime" => 0.5
             },
             "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id" => %{
               "equator_prime" => 0.25
             },
             "required_capacity_fraction_source_counts" => %{
               "contact_required_capacity_fraction" => 3
             },
             "required_capacity_fraction_contact_ids_by_source" => %{
               "contact_required_capacity_fraction" => [
                 "dl_capacity_overflow",
                 "dl_capacity_primary",
                 "dl_capacity_secondary"
               ]
             },
             "reduced_capacity_packed_contact_ids" => ["dl_capacity_secondary"],
             "reduced_capacity_deferred_contact_ids" => ["dl_capacity_overflow"],
             "capacity_pack_group_ids" => [^pack_group_id],
             "capacity_pack_group_ids_by_status" => %{"capacity_limited" => [^pack_group_id]},
             "rows" => capacity_pack_source_rows,
             "reduced_capacity_pack_groups" => reduced_capacity_pack_groups,
             "review_rows" => capacity_pack_review_rows,
             "assumptions" => %{
               "execution_boundary" =>
                 "artifact_only_no_provider_reservation_or_schedule_mutation",
               "operator_authority" => "not_granted_by_capacity_pack_summary",
               "source" => "contact_allocation_report.v1",
               "capacity_pack_statuses" => ^expected_capacity_pack_statuses,
               "reduced_capacity_pack_statuses" => ^expected_reduced_capacity_pack_statuses,
               "required_capacity_fraction_source_values" =>
                 ^expected_required_capacity_fraction_source_values,
               "required_capacity_value_paths" => ^expected_required_capacity_value_paths,
               "default_required_capacity_value_paths" =>
                 ^expected_default_required_capacity_value_paths
             }
           } = capacity_pack_summary = ContactAllocation.capacity_pack_summary(report)

    assert model_limits ==
             ContactAllocation.capabilities().known_limits
             |> Enum.map(&Atom.to_string/1)

    assert length(capacity_pack_source_rows) == 3

    assert [%{"contention_group_id" => ^pack_group_id, "pack_status" => "capacity_limited"}] =
             reduced_capacity_pack_groups

    assert Enum.map(capacity_pack_review_rows, & &1["contact_id"]) == [
             "dl_capacity_primary",
             "dl_capacity_secondary",
             "dl_capacity_overflow"
           ]

    assert {:ok, %{"schema_contract" => "contact_allocation_capacity_pack_summary.v1"}} =
             Schema.validate_artifact(capacity_pack_summary)

    assert {:ok, capacity_pack_schema} =
             Schema.json_schema("contact_allocation_capacity_pack_summary.v1")

    assert get_in(capacity_pack_schema, ["properties", "model", "const"]) ==
             "artifact_only_contact_allocation_capacity_pack_summary"

    assert get_in(capacity_pack_schema, ["properties", "model_limits", "const"]) ==
             model_limits

    assert get_in(capacity_pack_schema, ["properties", "model_limits", "items", "enum"]) ==
             model_limits

    assert get_in(capacity_pack_schema, [
             "properties",
             "capacity_pack_required_capacity_fraction_by_direction",
             "additionalProperties",
             "minimum"
           ]) == 0.0

    assert get_in(capacity_pack_schema, [
             "properties",
             "capacity_pack_contact_ids_by_direction",
             "additionalProperties",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(capacity_pack_schema, [
             "properties",
             "assumptions",
             "properties",
             "capacity_pack_statuses",
             "const"
           ]) == expected_capability_assumptions["capacity_pack_statuses"]

    assert get_in(capacity_pack_schema, [
             "properties",
             "assumptions",
             "properties",
             "required_capacity_value_paths",
             "const"
           ]) == expected_capability_assumptions["required_capacity_value_paths"]

    for {field, stale_value, message} <- [
          {"capacity_pack_statuses", ["stale_capacity_pack_status"],
           "must match ContactAllocation capacity pack statuses"},
          {"reduced_capacity_pack_statuses", ["stale_reduced_capacity_pack_status"],
           "must match ContactAllocation reduced capacity pack statuses"},
          {"required_capacity_fraction_source_values", ["stale_required_capacity_source"],
           "must match ContactAllocation required capacity source values"},
          {"required_capacity_value_paths",
           [%{"unit" => "fraction", "path" => ["stale_required_capacity_fraction"]}],
           "must match ContactAllocation required capacity value paths"},
          {"default_required_capacity_value_paths",
           [%{"unit" => "fraction", "path" => ["stale_default_required_capacity_fraction"]}],
           "must match ContactAllocation default required capacity value paths"}
        ] do
      stale_capacity_pack_assumption =
        put_in(capacity_pack_summary, ["assumptions", field], stale_value)

      assert {:error, stale_capacity_pack_assumption_errors} =
               Schema.validate_artifact(stale_capacity_pack_assumption)

      assert Enum.any?(
               stale_capacity_pack_assumption_errors["errors"],
               &(&1["path"] == "$.assumptions.#{field}" and &1["message"] == message)
             )
    end

    capacity_pack_summary_without_optional_capability_assumptions =
      drop_contact_allocation_capacity_pack_capability_assumptions(capacity_pack_summary)

    assert {:ok, %{"schema_contract" => "contact_allocation_capacity_pack_summary.v1"}} =
             Schema.validate_artifact(
               capacity_pack_summary_without_optional_capability_assumptions
             )

    stale_capacity_pack_model =
      Map.put(capacity_pack_summary, "model", "stale_contact_allocation_capacity_pack_summary")

    assert {:error, stale_capacity_pack_model_errors} =
             Schema.validate_artifact(stale_capacity_pack_model)

    assert Enum.any?(
             stale_capacity_pack_model_errors["errors"],
             &(&1["path"] == "$.model" and
                 &1["message"] ==
                   "must equal \"artifact_only_contact_allocation_capacity_pack_summary\"")
           )

    stale_capacity_pack_model_limits =
      Map.put(capacity_pack_summary, "model_limits", ["artifact_level_only"])

    assert {:error, stale_capacity_pack_model_limits_errors} =
             Schema.validate_artifact(stale_capacity_pack_model_limits)

    assert Enum.any?(
             stale_capacity_pack_model_limits_errors["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] == "must match contact allocation model limits")
           )

    stale_capacity_pack_count =
      Map.put(capacity_pack_summary, "capacity_pack_contact_count", 2)

    assert {:error, stale_capacity_pack_count_errors} =
             Schema.validate_artifact(stale_capacity_pack_count)

    assert Enum.any?(
             stale_capacity_pack_count_errors["errors"],
             &(&1["path"] == "$.capacity_pack_contact_count" and
                 &1["message"] == "must equal row-derived capacity_pack_contact_count")
           )

    stale_capacity_pack_direction =
      put_in(
        capacity_pack_summary,
        ["capacity_pack_required_capacity_fraction_by_direction", "downlink"],
        0.5
      )

    assert {:error, stale_capacity_pack_direction_errors} =
             Schema.validate_artifact(stale_capacity_pack_direction)

    assert Enum.any?(
             stale_capacity_pack_direction_errors["errors"],
             &(&1["path"] == "$.capacity_pack_required_capacity_fraction_by_direction" and
                 &1["message"] ==
                   "must equal row-derived capacity_pack_required_capacity_fraction_by_direction")
           )

    stale_capacity_pack_rows =
      Map.update!(capacity_pack_summary, "rows", fn rows ->
        Enum.map(rows, fn
          %{"contact_id" => "dl_capacity_overflow"} = row ->
            Map.put(row, "capacity_pack_status", "selected_by_contention_resolution")

          row ->
            row
        end)
      end)

    assert {:error, stale_capacity_pack_row_errors} =
             Schema.validate_artifact(stale_capacity_pack_rows)

    assert Enum.any?(
             stale_capacity_pack_row_errors["errors"],
             &(&1["path"] == "$.review_rows" and
                 &1["message"] == "must equal row-derived review_rows")
           )

    assert_summary_handoff(
      capacity_pack_summary,
      &ContactAllocation.capacity_pack_summary/1,
      &ContactAllocation.capacity_pack_summary(&1, now_s: 999.0),
      &OrbitalDynamics.contact_allocation_capacity_pack_summary/1,
      &OrbitalDynamics.contact_allocation_capacity_pack_summary(&1, now_s: 999.0)
    )

    assert OrbitalDynamics.contact_allocation_capacity_pack_summary(report) ==
             capacity_pack_summary

    assert ContactAllocation.capacity_pack_summary(contacts, ground_network,
             source: "unit_test.contacts"
           ) == capacity_pack_summary

    assert %{
             "capacity_pack_review_status" => "clear",
             "capacity_pack_contact_count" => 0,
             "capacity_pack_status_counts" => %{},
             "capacity_pack_selected_contact_ids_by_ground_station_id" => %{},
             "capacity_pack_deferred_contact_ids_by_ground_station_id" => %{},
             "capacity_pack_contact_ids_by_direction" => %{},
             "capacity_pack_selected_contact_ids_by_direction" => %{},
             "capacity_pack_deferred_contact_ids_by_direction" => %{}
           } =
             ContactAllocation.capacity_pack_summary(%{
               "schema_contract" => "contact_allocation_report.v1",
               "rows" => []
             })

    stale_pack_group_report =
      Map.put(report, "reduced_capacity_pack_groups", [
        %{
          "pack_status" => "capacity_limited",
          "capacity_packed_contact_ids" => ["stale_packed"],
          "deferred_contact_ids" => ["stale_deferred"]
        }
      ])

    assert %{
             "reduced_capacity_packed_contact_ids" => ["dl_capacity_secondary"],
             "reduced_capacity_deferred_contact_ids" => ["dl_capacity_overflow"],
             "capacity_pack_contact_ids_by_ground_station_id" => %{
               "equator_prime" => [
                 "dl_capacity_overflow",
                 "dl_capacity_primary",
                 "dl_capacity_secondary"
               ]
             }
           } = ContactAllocation.summary(stale_pack_group_report)

    stale_capacity_pack_station_ids_report =
      Map.put(report, "capacity_pack_contact_ids_by_ground_station_id", %{
        "stale_station" => ["stale_capacity_contact"]
      })

    assert %{
             "capacity_pack_contact_ids_by_ground_station_id" => %{
               "equator_prime" => [
                 "dl_capacity_overflow",
                 "dl_capacity_primary",
                 "dl_capacity_secondary"
               ]
             }
           } = ContactAllocation.summary(stale_capacity_pack_station_ids_report)

    stale_required_source_summary_report =
      report
      |> Map.put("required_capacity_fraction_source_counts", %{"stale" => 1})
      |> Map.put("required_capacity_fraction_contact_ids_by_source", %{"stale" => ["stale"]})

    assert %{
             "required_capacity_fraction_source_counts" => %{
               "contact_required_capacity_fraction" => 3
             },
             "required_capacity_fraction_contact_ids_by_source" => %{
               "contact_required_capacity_fraction" => [
                 "dl_capacity_overflow",
                 "dl_capacity_primary",
                 "dl_capacity_secondary"
               ]
             }
           } = ContactAllocation.summary(stale_required_source_summary_report)

    stale_required_source_counts_report =
      Map.put(report, "required_capacity_fraction_source_counts", %{})

    assert {:error, stale_required_source_counts_errors} =
             Schema.validate_artifact(stale_required_source_counts_report)

    assert Enum.any?(
             stale_required_source_counts_errors["errors"],
             &(&1["path"] == "$.required_capacity_fraction_source_counts" and
                 &1["message"] ==
                   "must equal row-derived required_capacity_fraction_source_counts")
           )

    stale_required_source_ids_report =
      Map.put(report, "required_capacity_fraction_contact_ids_by_source", %{})

    assert {:error, stale_required_source_ids_errors} =
             Schema.validate_artifact(stale_required_source_ids_report)

    assert Enum.any?(
             stale_required_source_ids_errors["errors"],
             &(&1["path"] == "$.required_capacity_fraction_contact_ids_by_source" and
                 &1["message"] ==
                   "must equal row-derived required_capacity_fraction_contact_ids_by_source")
           )

    stale_capacity_pack_demand_report =
      Map.put(report, "capacity_pack_required_capacity_fraction", 99.0)

    assert {:error, stale_capacity_pack_demand_errors} =
             Schema.validate_artifact(stale_capacity_pack_demand_report)

    assert Enum.any?(
             stale_capacity_pack_demand_errors["errors"],
             &(&1["path"] == "$.capacity_pack_required_capacity_fraction" and
                 &1["message"] ==
                   "must equal row-derived capacity_pack_required_capacity_fraction")
           )

    stale_capacity_pack_status_demand_report =
      Map.put(report, "capacity_pack_required_capacity_fraction_by_status", %{})

    assert {:error, stale_capacity_pack_status_demand_errors} =
             Schema.validate_artifact(stale_capacity_pack_status_demand_report)

    assert Enum.any?(
             stale_capacity_pack_status_demand_errors["errors"],
             &(&1["path"] == "$.capacity_pack_required_capacity_fraction_by_status" and
                 &1["message"] ==
                   "must equal row-derived capacity_pack_required_capacity_fraction_by_status")
           )

    stale_reduced_capacity_packed_ids_report =
      Map.put(report, "reduced_capacity_packed_contact_ids", [])

    assert {:error, stale_reduced_capacity_packed_ids_errors} =
             Schema.validate_artifact(stale_reduced_capacity_packed_ids_report)

    assert Enum.any?(
             stale_reduced_capacity_packed_ids_errors["errors"],
             &(&1["path"] == "$.reduced_capacity_packed_contact_ids" and
                 &1["message"] == "must equal row-derived reduced_capacity_packed_contact_ids")
           )

    stale_pack_used_report =
      put_in(
        report,
        ["reduced_capacity_pack_groups", Access.at(0), "used_capacity_fraction"],
        0.25
      )

    assert {:error, stale_pack_used_errors} =
             Schema.validate_artifact(stale_pack_used_report)

    assert Enum.any?(
             stale_pack_used_errors["errors"],
             &(&1["path"] == "$.reduced_capacity_pack_groups[0].used_capacity_fraction" and
                 &1["message"] == "must equal capacity requirement rows selected capacity")
           )

    stale_pack_unused_report =
      put_in(
        report,
        ["reduced_capacity_pack_groups", Access.at(0), "unused_capacity_fraction"],
        0.25
      )

    assert {:error, stale_pack_unused_errors} =
             Schema.validate_artifact(stale_pack_unused_report)

    assert Enum.any?(
             stale_pack_unused_errors["errors"],
             &(&1["path"] == "$.reduced_capacity_pack_groups[0].unused_capacity_fraction" and
                 &1["message"] == "must equal capacity minus selected capacity")
           )

    stale_pack_deferred_ids_report =
      put_in(
        report,
        ["reduced_capacity_pack_groups", Access.at(0), "deferred_contact_ids"],
        []
      )

    assert {:error, stale_pack_deferred_ids_errors} =
             Schema.validate_artifact(stale_pack_deferred_ids_report)

    assert Enum.any?(
             stale_pack_deferred_ids_errors["errors"],
             &(&1["path"] == "$.reduced_capacity_pack_groups[0].deferred_contact_ids" and
                 &1["message"] == "must equal capacity requirement rows deferred contact IDs")
           )

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "packs reduced-capacity contacts with a declared default capacity requirement" do
    contacts = [
      contact(:dl_default_primary, starts_at_s: 100.0, ends_at_s: 180.0, score: 10.0),
      contact(:dl_default_secondary, starts_at_s: 120.0, ends_at_s: 170.0, score: 5.0),
      contact(:dl_default_overflow, starts_at_s: 130.0, ends_at_s: 160.0, score: 1.0)
    ]

    ground_network = [
      %{
        ground_station_id: :equator_prime,
        status: :available,
        capacity_fraction: 0.5,
        starts_at_s: 90.0,
        ends_at_s: 190.0
      }
    ]

    {allocated, report} =
      ContactAllocation.allocate_contacts(contacts, ground_network,
        source: "unit_test.default_capacity",
        capacity_policy: %{"default_required_capacity_fraction" => "0.25"}
      )

    assert Enum.map(allocated, & &1["id"]) == ["dl_default_primary", "dl_default_secondary"]

    assert %{
             "reduced_capacity_pack_group_count" => 1,
             "reduced_capacity_pack_groups" => [
               %{
                 "capacity_fraction" => 0.5,
                 "default_required_capacity_fraction" => 0.25,
                 "used_capacity_fraction" => 0.5,
                 "capacity_packed_contact_ids" => ["dl_default_secondary"],
                 "deferred_contact_ids" => ["dl_default_overflow"],
                 "capacity_requirement_rows" => capacity_requirement_rows,
                 "pack_status" => "capacity_limited"
               }
             ],
             "rows" => rows
           } = report

    assert [
             %{
               "contact_id" => "dl_default_primary",
               "required_capacity_fraction" => 0.25,
               "required_capacity_fraction_source" => "default_reduced_capacity_policy"
             },
             %{
               "contact_id" => "dl_default_secondary",
               "required_capacity_fraction" => 0.25,
               "required_capacity_fraction_source" => "default_reduced_capacity_policy"
             },
             %{
               "contact_id" => "dl_default_overflow",
               "required_capacity_fraction" => 0.25,
               "required_capacity_fraction_source" => "default_reduced_capacity_policy"
             }
           ] = capacity_requirement_rows

    pack_group_id =
      report
      |> Map.fetch!("reduced_capacity_pack_groups")
      |> List.first()
      |> Map.fetch!("contention_group_id")

    assert %{
             "id" => "dl_default_secondary",
             "allocation_status" => "allocated",
             "allocation_reason" => "selected_by_reduced_station_capacity_pack",
             "required_capacity_fraction" => 0.25,
             "required_capacity_fraction_source" => "default_reduced_capacity_policy",
             "capacity_pack_group_id" => ^pack_group_id,
             "capacity_pack_status" => "selected_by_reduced_station_capacity_pack"
           } = Enum.find(allocated, &(&1["id"] == "dl_default_secondary"))

    assert %{
             "contact_id" => "dl_default_secondary",
             "allocation_status" => "allocated",
             "allocation_reason" => "selected_by_reduced_station_capacity_pack",
             "required_capacity_fraction" => 0.25,
             "required_capacity_fraction_source" => "default_reduced_capacity_policy",
             "capacity_pack_group_id" => ^pack_group_id,
             "capacity_pack_status" => "selected_by_reduced_station_capacity_pack"
           } = Enum.find(rows, &(&1["contact_id"] == "dl_default_secondary"))

    review = OperatorReview.from_contact_allocation_report(report)
    secondary_review = Enum.find(review["rows"], &(&1["contact_id"] == "dl_default_secondary"))

    assert %{
             "required_capacity_fraction" => 0.25,
             "required_capacity_fraction_source" => "default_reduced_capacity_policy"
           } = secondary_review

    manifest = CadenceImport.from_contact_allocation_report(report)
    secondary_import = Enum.find(manifest["rows"], &(&1["contact_id"] == "dl_default_secondary"))

    assert %{
             "required_capacity_fraction" => 0.25,
             "required_capacity_fraction_source" => "default_reduced_capacity_policy"
           } = secondary_import

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "does not allocate reduced-capacity contacts whose default demand exceeds station capacity" do
    contacts = [
      contact(:dl_default_too_large_primary, starts_at_s: 100.0, ends_at_s: 180.0, score: 10.0),
      contact(:dl_default_too_large_secondary, starts_at_s: 120.0, ends_at_s: 170.0, score: 5.0)
    ]

    ground_network = [
      %{
        ground_station_id: :equator_prime,
        status: :available,
        capacity_fraction: 0.5,
        starts_at_s: 90.0,
        ends_at_s: 190.0
      }
    ]

    {allocated, report} =
      ContactAllocation.allocate_contacts(contacts, ground_network,
        source: "unit_test.default_capacity_over_limit",
        capacity_policy: %{"default_required_capacity_fraction" => "0.75"}
      )

    assert allocated == []

    assert %{
             "allocated_contact_count" => 0,
             "returned_allocated_contact_count" => 0,
             "deferred_contact_count" => 2,
             "reduced_capacity_pack_group_count" => 1,
             "reduced_capacity_pack_groups" => [
               %{
                 "capacity_fraction" => 0.5,
                 "default_required_capacity_fraction" => 0.75,
                 "used_capacity_fraction" => used_capacity_fraction,
                 "unused_capacity_fraction" => 0.5,
                 "selected_contact_ids" => [],
                 "capacity_packed_contact_ids" => [],
                 "deferred_contact_ids" => [
                   "dl_default_too_large_primary",
                   "dl_default_too_large_secondary"
                 ],
                 "pack_status" => "capacity_limited",
                 "capacity_requirement_rows" => capacity_requirement_rows
               }
             ],
             "rows" => rows
           } = report

    assert_in_delta used_capacity_fraction, 0.0, 1.0e-12

    assert [
             %{
               "contact_id" => "dl_default_too_large_primary",
               "allocation_status" => "deferred",
               "allocation_reason" => "deferred_by_reduced_station_capacity_pack",
               "capacity_pack_status" => "deferred_by_reduced_station_capacity_pack",
               "required_capacity_fraction" => 0.75,
               "required_capacity_fraction_source" => "default_reduced_capacity_policy"
             },
             %{
               "contact_id" => "dl_default_too_large_secondary",
               "allocation_status" => "deferred",
               "allocation_reason" => "same_station_contention",
               "capacity_pack_status" => "deferred_by_reduced_station_capacity_pack",
               "required_capacity_fraction" => 0.75,
               "required_capacity_fraction_source" => "default_reduced_capacity_policy"
             }
           ] = capacity_requirement_rows

    assert %{
             "contact_id" => "dl_default_too_large_primary",
             "allocation_status" => "deferred",
             "allocation_reason" => "deferred_by_reduced_station_capacity_pack",
             "selected" => false,
             "required_capacity_fraction" => 0.75,
             "required_capacity_fraction_source" => "default_reduced_capacity_policy",
             "capacity_pack_status" => "deferred_by_reduced_station_capacity_pack",
             "capacity_pack_capacity_fraction" => 0.5,
             "capacity_pack_used_fraction" => primary_capacity_pack_used_fraction
           } = Enum.find(rows, &(&1["contact_id"] == "dl_default_too_large_primary"))

    assert_in_delta primary_capacity_pack_used_fraction, 0.0, 1.0e-12

    assert %{
             "contact_id" => "dl_default_too_large_secondary",
             "allocation_status" => "deferred",
             "allocation_reason" => "same_station_contention",
             "required_capacity_fraction" => 0.75,
             "required_capacity_fraction_source" => "default_reduced_capacity_policy",
             "capacity_pack_status" => "deferred_by_reduced_station_capacity_pack",
             "capacity_pack_capacity_fraction" => 0.5,
             "capacity_pack_used_fraction" => secondary_capacity_pack_used_fraction
           } = Enum.find(rows, &(&1["contact_id"] == "dl_default_too_large_secondary"))

    assert_in_delta secondary_capacity_pack_used_fraction, 0.0, 1.0e-12

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "rejects invalid default reduced-capacity requirements" do
    assert_raise ArgumentError, ~r/default_required_capacity_fraction/, fn ->
      ContactAllocation.allocate_contacts(
        [contact(:dl_bad_default, starts_at_s: 100.0, ends_at_s: 180.0)],
        [
          %{
            ground_station_id: :equator_prime,
            status: :available,
            capacity_fraction: 0.5,
            starts_at_s: 90.0,
            ends_at_s: 190.0
          }
        ],
        default_required_capacity_fraction: 1.5
      )
    end
  end

  defp contact(id, attrs) do
    defaults = %{
      id: id,
      type: :downlink,
      scenario_id: :leo_1,
      ground_station_id: :equator_prime,
      starts_at_s: 100.0,
      ends_at_s: 160.0,
      source_window_id: :"window_#{id}",
      score: 1.0
    }

    Map.merge(defaults, Map.new(attrs))
  end

  defp assert_summary_handoff(
         summary,
         module_summary,
         module_summary_with_opts,
         facade_summary,
         facade_summary_with_opts
       ) do
    assert module_summary.(summary) == summary
    assert module_summary_with_opts.(summary) == summary
    assert facade_summary.(summary) == summary
    assert facade_summary_with_opts.(summary) == summary

    atom_keyed_summary =
      Map.new(summary, fn {key, value} -> {String.to_atom(key), value} end)

    assert module_summary.(atom_keyed_summary) == summary
    assert facade_summary.(atom_keyed_summary) == summary
  end

  defp contact_allocation_capacity_pack_capability_assumptions do
    capabilities = ContactAllocation.capabilities()

    %{
      "capacity_pack_statuses" => capabilities.capacity_pack_statuses,
      "reduced_capacity_pack_statuses" => capabilities.reduced_capacity_pack_statuses,
      "required_capacity_fraction_source_values" =>
        capabilities.required_capacity_fraction_source_values,
      "required_capacity_value_paths" =>
        json_capacity_value_paths(capabilities.required_capacity_value_paths),
      "default_required_capacity_value_paths" =>
        json_capacity_value_paths(capabilities.default_required_capacity_value_paths)
    }
  end

  defp json_capacity_value_paths(paths) do
    Enum.map(paths, fn %{unit: unit, path: path} ->
      %{"unit" => Atom.to_string(unit), "path" => path}
    end)
  end

  defp drop_contact_allocation_capacity_pack_capability_assumptions(artifact) do
    update_in(artifact, ["assumptions"], fn assumptions ->
      Map.drop(assumptions, [
        "capacity_pack_statuses",
        "reduced_capacity_pack_statuses",
        "required_capacity_fraction_source_values",
        "required_capacity_value_paths",
        "default_required_capacity_value_paths"
      ])
    end)
  end

  defp contact_allocation_provider_reservation_request_capability_assumptions do
    capabilities = ContactAllocation.capabilities()

    %{
      "provider_reservation_request_statuses" =>
        capabilities.provider_reservation_request_statuses,
      "station_reservation_match_statuses" => capabilities.station_reservation_match_statuses,
      "provider_direction_aliases" => capabilities.provider_direction_aliases
    }
  end

  defp drop_contact_allocation_provider_reservation_request_capability_assumptions(artifact) do
    update_in(artifact, ["assumptions"], fn assumptions ->
      Map.drop(assumptions, [
        "provider_reservation_request_statuses",
        "station_reservation_match_statuses",
        "provider_direction_aliases"
      ])
    end)
  end

  defp contact_allocation_summary_capability_assumptions do
    capabilities = ContactAllocation.capabilities()

    %{
      "row_statuses" => capabilities.row_statuses,
      "effective_row_statuses" => capabilities.effective_row_statuses,
      "station_unavailable_aliases" => capabilities.station_unavailable_aliases,
      "station_blocking_availability" => capabilities.station_blocking_availability,
      "station_availability_precedence" => capabilities.station_availability_precedence,
      "capacity_pack_statuses" => capabilities.capacity_pack_statuses,
      "reduced_capacity_pack_statuses" => capabilities.reduced_capacity_pack_statuses,
      "station_reservation_match_statuses" => capabilities.station_reservation_match_statuses,
      "station_reservation_expiration_statuses" =>
        capabilities.station_reservation_expiration_statuses,
      "required_capacity_fraction_source_values" =>
        capabilities.required_capacity_fraction_source_values,
      "required_capacity_value_paths" =>
        json_capacity_value_paths(capabilities.required_capacity_value_paths),
      "default_required_capacity_value_paths" =>
        json_capacity_value_paths(capabilities.default_required_capacity_value_paths),
      "provider_direction_aliases" => capabilities.provider_direction_aliases
    }
  end

  defp drop_contact_allocation_summary_capability_assumptions(artifact) do
    update_in(artifact, ["assumptions"], fn assumptions ->
      Map.drop(assumptions, [
        "row_statuses",
        "effective_row_statuses",
        "station_unavailable_aliases",
        "station_blocking_availability",
        "station_availability_precedence",
        "capacity_pack_statuses",
        "reduced_capacity_pack_statuses",
        "station_reservation_match_statuses",
        "station_reservation_expiration_statuses",
        "required_capacity_fraction_source_values",
        "required_capacity_value_paths",
        "default_required_capacity_value_paths",
        "provider_direction_aliases"
      ])
    end)
  end

  defp contact_allocation_station_pressure_capability_assumptions do
    capabilities = ContactAllocation.capabilities()

    %{
      "station_unavailable_aliases" => capabilities.station_unavailable_aliases,
      "station_blocking_availability" => capabilities.station_blocking_availability,
      "station_availability_precedence" => capabilities.station_availability_precedence,
      "provider_direction_aliases" => capabilities.provider_direction_aliases
    }
  end

  defp drop_contact_allocation_station_pressure_capability_assumptions(artifact) do
    update_in(artifact, ["assumptions"], fn assumptions ->
      Map.drop(assumptions, [
        "station_unavailable_aliases",
        "station_blocking_availability",
        "station_availability_precedence",
        "provider_direction_aliases"
      ])
    end)
  end

  defp contact_allocation_reservation_conflict_capability_assumptions do
    capabilities = ContactAllocation.capabilities()

    %{
      "station_reservation_match_statuses" => capabilities.station_reservation_match_statuses,
      "reservation_conflict_match_statuses" => capabilities.reservation_conflict_match_statuses,
      "station_reservation_expiration_statuses" =>
        capabilities.station_reservation_expiration_statuses,
      "provider_direction_aliases" => capabilities.provider_direction_aliases
    }
  end

  defp drop_contact_allocation_reservation_conflict_capability_assumptions(artifact) do
    update_in(artifact, ["assumptions"], fn assumptions ->
      Map.drop(assumptions, [
        "station_reservation_match_statuses",
        "reservation_conflict_match_statuses",
        "station_reservation_expiration_statuses",
        "provider_direction_aliases"
      ])
    end)
  end
end
