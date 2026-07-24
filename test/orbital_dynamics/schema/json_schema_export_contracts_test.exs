defmodule OrbitalDynamics.Schema.JsonSchemaExportContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  test "exports top-level JSON Schema documents for executable contracts" do
    assert {:ok, schema} = Schema.json_schema("campaign_plan.v1")

    assert schema["$schema"] == "https://json-schema.org/draft/2020-12/schema"
    assert schema["$id"] =~ "campaign_plan.v1.schema.json"
    assert schema["type"] == "object"
    assert "plan_id" in schema["required"]
    assert schema["properties"]["schema_version"]["type"] == "integer"
    assert schema["properties"]["schema_version"]["const"] == 1
    assert schema["properties"]["activities"]["type"] == "array"

    assert %{
             "schema_contract" => "campaign_plan.v1",
             "artifact_family" => "campaign_plan",
             "compatibility_policy_version" => 1,
             "executable_contract" => true
           } = schema["x-orbital-dynamics"]
  end

  test "exports selected recommendation reservation expiration context" do
    assert {:ok, schema} = Schema.json_schema("campaign_strategy.v3")

    assert get_in(schema, [
             "properties",
             "recommendation",
             "properties",
             "explanation",
             "items",
             "properties",
             "branch_station_reservation_expiration_statuses",
             "items",
             "type"
           ]) == "string"
  end

  test "exports recommendation risk context" do
    assert {:ok, strategy_schema} = Schema.json_schema("campaign_strategy.v3")
    assert {:ok, review_schema} = Schema.json_schema("operator_review_package.v1")
    assert {:ok, import_schema} = Schema.json_schema("cadence_import_manifest.v1")

    scalar_field = "station_reservation_expiration_status"
    stable_id_pattern = Schema.identity_policy()["stable_id_pattern"]

    aggregate_fields = [
      {"provider_reservation_request_contact_ids", "string", stable_id_pattern},
      {"provider_reservation_request_source_activity_ids", "string", stable_id_pattern},
      {"provider_reservation_request_ground_station_ids", "string", stable_id_pattern},
      {"provider_reservation_request_directions", "string", nil},
      {"provider_reservation_request_station_reservation_ids", "string", stable_id_pattern},
      {"provider_reservation_request_station_reserved_by", "string", nil},
      {"provider_reservation_request_station_reservation_statuses", "string", nil},
      {"provider_reservation_request_station_reservation_match_statuses", "string", nil},
      {"provider_reservation_request_statuses", "string", nil},
      {"provider_reservation_request_row_scopes", "string", nil},
      {"provider_reservation_request_required_operator_actions", "string", nil},
      {"provider_reservation_request_assumption_maps", "object", nil},
      {"provider_reservation_request_feedback_sources", "string", nil},
      {"provider_reservation_request_feedback_scopes", "string", nil},
      {"provider_reservation_request_trust_boundaries", "string", nil},
      {"provider_reservation_request_station_reservation_expiration_statuses", "string", nil},
      {"capacity_pack_risk_contact_ids", "string", stable_id_pattern},
      {"capacity_pack_risk_source_activity_ids", "string", stable_id_pattern},
      {"capacity_pack_risk_ground_station_ids", "string", stable_id_pattern},
      {"capacity_pack_risk_group_ids", "string", stable_id_pattern},
      {"capacity_pack_risk_statuses", "string", nil},
      {"capacity_pack_risk_capacity_fraction_values", "number", nil},
      {"capacity_pack_risk_used_fraction_values", "number", nil},
      {"capacity_pack_risk_unused_fraction_values", "number", nil},
      {"capacity_pack_risk_required_capacity_fraction_values", "number", nil},
      {"capacity_pack_risk_required_capacity_fraction_sources", "string", nil},
      {"capacity_pack_risk_derivation_reasons", "string", nil},
      {"capacity_pack_risk_feedback_sources", "string", nil},
      {"capacity_pack_risk_feedback_scopes", "string", nil},
      {"capacity_pack_risk_trust_boundaries", "string", nil},
      {"contact_contention_resolution_pressure_risk_types", "string", nil},
      {"contact_contention_resolution_pressure_contact_ids", "string", stable_id_pattern},
      {"contact_contention_resolution_pressure_selected_contact_ids", "string",
       stable_id_pattern},
      {"contact_contention_resolution_pressure_scenario_ids", "string", stable_id_pattern},
      {"contact_contention_resolution_pressure_spacecraft_ids", "string", stable_id_pattern},
      {"contact_contention_resolution_pressure_ground_station_ids", "string", stable_id_pattern},
      {"contact_contention_resolution_pressure_source_activity_ids", "string", stable_id_pattern},
      {"contact_contention_resolution_pressure_source_window_ids", "string", stable_id_pattern},
      {"contact_contention_resolution_pressure_required_contact_values", "number", nil},
      {"contact_contention_resolution_pressure_planned_contact_values", "number", nil},
      {"contact_contention_resolution_pressure_required_downlink_values_mb", "number", nil},
      {"contact_contention_resolution_pressure_planned_downlink_values_mb", "number", nil},
      {"contact_contention_resolution_pressure_start_values_s", "number", nil},
      {"contact_contention_resolution_pressure_end_values_s", "number", nil},
      {"contact_contention_resolution_pressure_selected_priority_sources", "string", nil},
      {"contact_contention_resolution_pressure_selection_reasons", "string", nil},
      {"contact_contention_resolution_pressure_resolution_selection_rules", "string", nil},
      {"contact_contention_resolution_pressure_priority_override_count_values", "integer", nil},
      {"contact_contention_resolution_pressure_priority_override_contact_ids", "string",
       stable_id_pattern},
      {"contact_contention_resolution_pressure_review_statuses", "string", nil},
      {"contact_contention_resolution_pressure_downlink_demand_sources", "string", nil},
      {"contact_contention_resolution_pressure_downlink_completion_sources", "string", nil},
      {"contact_contention_resolution_pressure_feedback_sources", "string", nil},
      {"contact_contention_resolution_pressure_feedback_scopes", "string", nil},
      {"contact_contention_resolution_pressure_trust_boundaries", "string", nil},
      {"contact_contention_resolution_pressure_derivation_reasons", "string", nil},
      {"contact_contention_pressure_risk_types", "string", nil},
      {"contact_contention_pressure_contact_ids", "string", stable_id_pattern},
      {"contact_contention_pressure_scenario_ids", "string", stable_id_pattern},
      {"contact_contention_pressure_spacecraft_ids", "string", stable_id_pattern},
      {"contact_contention_pressure_ground_station_ids", "string", stable_id_pattern},
      {"contact_contention_pressure_source_activity_ids", "string", stable_id_pattern},
      {"contact_contention_pressure_source_window_ids", "string", stable_id_pattern},
      {"contact_contention_pressure_required_contact_values", "number", nil},
      {"contact_contention_pressure_planned_contact_values", "number", nil},
      {"contact_contention_pressure_required_downlink_values_mb", "number", nil},
      {"contact_contention_pressure_planned_downlink_values_mb", "number", nil},
      {"contact_contention_pressure_start_values_s", "number", nil},
      {"contact_contention_pressure_end_values_s", "number", nil},
      {"contact_contention_pressure_group_ids", "string", stable_id_pattern},
      {"contact_contention_pressure_resource_scopes", "string", nil},
      {"contact_contention_pressure_contention_contact_ids", "string", stable_id_pattern},
      {"contact_contention_pressure_required_operator_actions", "string", nil},
      {"contact_contention_pressure_approval_statuses", "string", nil},
      {"contact_contention_pressure_operator_action_reasons", "string", nil},
      {"contact_contention_pressure_downlink_demand_sources", "string", nil},
      {"contact_contention_pressure_downlink_completion_sources", "string", nil},
      {"contact_contention_pressure_feedback_sources", "string", nil},
      {"contact_contention_pressure_feedback_scopes", "string", nil},
      {"contact_contention_pressure_trust_boundaries", "string", nil},
      {"contact_contention_pressure_derivation_reasons", "string", nil},
      {"contact_filter_pressure_risk_types", "string", nil},
      {"contact_filter_pressure_contact_ids", "string", stable_id_pattern},
      {"contact_filter_pressure_scenario_ids", "string", stable_id_pattern},
      {"contact_filter_pressure_spacecraft_ids", "string", stable_id_pattern},
      {"contact_filter_pressure_ground_station_ids", "string", stable_id_pattern},
      {"contact_filter_pressure_source_activity_ids", "string", stable_id_pattern},
      {"contact_filter_pressure_source_window_ids", "string", stable_id_pattern},
      {"station_reservation_conflict_contact_ids", "string", stable_id_pattern},
      {"station_reservation_conflict_source_activity_ids", "string", stable_id_pattern},
      {"station_reservation_conflict_ground_station_ids", "string", stable_id_pattern},
      {"station_reservation_conflict_reservation_ids", "string", stable_id_pattern},
      {"station_reservation_conflict_reserved_by", "string", nil},
      {"station_reservation_conflict_statuses", "string", nil},
      {"station_reservation_conflict_match_statuses", "string", nil},
      {"station_reservation_conflict_expires_at_values_s", "number", nil},
      {"station_reservation_conflict_expiration_statuses", "string", nil},
      {"station_reservation_conflict_derivation_reasons", "string", nil},
      {"station_reservation_conflict_feedback_sources", "string", nil},
      {"station_reservation_conflict_feedback_scopes", "string", nil},
      {"station_reservation_conflict_trust_boundaries", "string", nil},
      {"station_reservation_hold_import_statuses", "string", nil},
      {"station_reservation_hold_import_readiness_summary_models", "string", nil},
      {"station_reservation_hold_import_readiness_sources", "string", nil},
      {"station_reservation_hold_import_readiness_source_artifact_types", "string", nil},
      {"station_reservation_hold_import_readiness_statuses", "string", nil},
      {"station_reservation_hold_import_classifications", "string", nil},
      {"station_reservation_hold_count_values", "integer", nil},
      {"station_reservation_hold_ids", "string", stable_id_pattern},
      {"station_reservation_hold_ids_by_import_status", "object", nil},
      {"station_reservation_hold_ids_by_required_import_action", "object", nil},
      {"station_reservation_hold_ids_by_direction", "object", nil},
      {"station_reservation_hold_ids_by_direction_and_ground_station_id", "object", nil},
      {"station_reservation_hold_contact_ids", "string", stable_id_pattern},
      {"station_reservation_hold_contact_ids_by_import_status", "object", nil},
      {"station_reservation_hold_contact_ids_by_expiration_status", "object", nil},
      {"station_reservation_hold_contact_ids_by_direction", "object", nil},
      {"station_reservation_hold_contact_ids_by_direction_and_ground_station_id", "object", nil},
      {"station_reservation_hold_import_status_count_maps", "object", nil},
      {"station_reservation_hold_required_import_action_count_maps", "object", nil},
      {"station_reservation_hold_import_execution_boundaries", "string", nil},
      {"station_reservation_hold_provider_write_values", "string", nil},
      {"station_reservation_hold_cadence_write_values", "string", nil},
      {"station_reservation_hold_reservation_acceptance_values", "string", nil},
      {"station_reservation_hold_feedback_sources", "string", nil},
      {"station_reservation_hold_feedback_scopes", "string", nil},
      {"station_reservation_hold_trust_boundaries", "string", nil},
      {"source_station_reservation_hold_import_readiness_summaries", "object", nil},
      {"station_reservation_hold_expiration_statuses", "string", nil},
      {"contact_allocation_pressure_risk_types", "string", nil},
      {"contact_allocation_pressure_contact_ids", "string", stable_id_pattern},
      {"contact_allocation_pressure_scenario_ids", "string", stable_id_pattern},
      {"contact_allocation_pressure_spacecraft_ids", "string", stable_id_pattern},
      {"contact_allocation_pressure_ground_station_ids", "string", stable_id_pattern},
      {"contact_allocation_pressure_source_activity_ids", "string", stable_id_pattern},
      {"contact_allocation_pressure_source_window_ids", "string", stable_id_pattern},
      {"contact_allocation_pressure_required_contact_values", "number", nil},
      {"contact_allocation_pressure_planned_contact_values", "number", nil},
      {"contact_allocation_pressure_required_downlink_values_mb", "number", nil},
      {"contact_allocation_pressure_planned_downlink_values_mb", "number", nil},
      {"contact_allocation_pressure_start_values_s", "number", nil},
      {"contact_allocation_pressure_end_values_s", "number", nil},
      {"contact_allocation_pressure_realized_statuses", "string", nil},
      {"contact_allocation_pressure_contact_results", "string", nil},
      {"contact_allocation_pressure_allocation_statuses", "string", nil},
      {"contact_allocation_pressure_effective_allocation_statuses", "string", nil},
      {"contact_allocation_pressure_allocation_reasons", "string", nil},
      {"contact_allocation_pressure_review_statuses", "string", nil},
      {"contact_allocation_pressure_approval_statuses", "string", nil},
      {"contact_allocation_pressure_policy_classifications", "string", nil},
      {"contact_allocation_pressure_policy_bundle_ids", "string", stable_id_pattern},
      {"contact_allocation_pressure_station_reservation_ids", "string", stable_id_pattern},
      {"contact_allocation_pressure_station_reserved_by", "string", nil},
      {"contact_allocation_pressure_station_reservation_statuses", "string", nil},
      {"contact_allocation_pressure_station_reservation_match_statuses", "string", nil},
      {"contact_allocation_pressure_station_calendar_entry_ids", "string", stable_id_pattern},
      {"contact_allocation_pressure_station_calendar_entry_statuses", "string", nil},
      {"contact_allocation_pressure_station_calendar_directions", "string", nil},
      {"contact_allocation_pressure_downlink_demand_sources", "string", nil},
      {"contact_allocation_pressure_downlink_completion_sources", "string", nil},
      {"contact_allocation_pressure_feedback_sources", "string", nil},
      {"contact_allocation_pressure_feedback_scopes", "string", nil},
      {"contact_allocation_pressure_trust_boundaries", "string", nil},
      {"contact_allocation_pressure_derivation_reasons", "string", nil},
      {"contact_intent_pressure_risk_types", "string", nil},
      {"contact_intent_pressure_contact_ids", "string", stable_id_pattern},
      {"contact_intent_pressure_source_activity_ids", "string", stable_id_pattern},
      {"contact_intent_pressure_ground_station_ids", "string", stable_id_pattern},
      {"contact_intent_pressure_required_contact_values", "number", nil},
      {"contact_intent_pressure_planned_contact_values", "number", nil},
      {"contact_intent_pressure_required_downlink_values_mb", "number", nil},
      {"contact_intent_pressure_planned_downlink_values_mb", "number", nil},
      {"contact_intent_pressure_start_values_s", "number", nil},
      {"contact_intent_pressure_end_values_s", "number", nil},
      {"contact_intent_pressure_source_window_ids", "string", stable_id_pattern},
      {"contact_intent_pressure_timeline_ids", "string", stable_id_pattern},
      {"contact_intent_pressure_approval_statuses", "string", nil},
      {"contact_intent_pressure_required_operator_actions", "string", nil},
      {"contact_intent_pressure_cadence_import_statuses", "string", nil},
      {"contact_intent_pressure_gate_statuses", "string", nil},
      {"contact_intent_pressure_policy_classifications", "string", nil},
      {"contact_intent_pressure_policy_bundle_ids", "string", stable_id_pattern},
      {"contact_intent_pressure_invalid_cadence_import_values", "boolean", nil},
      {"contact_intent_pressure_invalid_cadence_import_reasons", "string", nil},
      {"contact_intent_pressure_invalid_activity_input_values", "boolean", nil},
      {"contact_intent_pressure_invalid_activity_input_reasons", "string", nil},
      {"contact_intent_pressure_station_availabilities", "string", nil},
      {"contact_intent_pressure_station_contention_statuses", "string", nil},
      {"contact_intent_pressure_station_calendar_entry_ids", "string", stable_id_pattern},
      {"contact_intent_pressure_station_calendar_provider_ids", "string", stable_id_pattern},
      {"contact_intent_pressure_station_calendar_provider_entry_ids", "string",
       stable_id_pattern},
      {"contact_intent_pressure_station_calendar_directions", "string", nil},
      {"contact_intent_pressure_station_calendar_statuses", "string", nil},
      {"contact_intent_pressure_station_calendar_trust_boundary_statuses", "string", nil},
      {"contact_intent_pressure_station_reservation_ids", "string", stable_id_pattern},
      {"contact_intent_pressure_station_reserved_by", "string", nil},
      {"contact_intent_pressure_station_reservation_statuses", "string", nil},
      {"contact_intent_pressure_station_reservation_match_statuses", "string", nil},
      {"contact_intent_pressure_feedback_sources", "string", nil},
      {"contact_intent_pressure_feedback_scopes", "string", nil},
      {"contact_intent_pressure_trust_boundaries", "string", nil},
      {"contact_intent_pressure_derivation_reasons", "string", nil},
      {"station_calendar_pressure_risk_types", "string", nil},
      {"station_calendar_pressure_ground_station_ids", "string", stable_id_pattern},
      {"station_calendar_pressure_start_values_s", "number", nil},
      {"station_calendar_pressure_end_values_s", "number", nil},
      {"station_calendar_pressure_capacity_fraction_values", "number", nil},
      {"station_calendar_pressure_station_reservation_expiration_statuses", "string", nil},
      {"station_calendar_pressure_station_reservation_expires_at_values_s", "number", nil},
      {"station_calendar_pressure_station_reservation_ids", "string", stable_id_pattern},
      {"station_calendar_pressure_station_reserved_by", "string", nil},
      {"station_calendar_pressure_station_reservation_statuses", "string", nil},
      {"station_calendar_pressure_station_reservation_match_statuses", "string", nil},
      {"station_calendar_pressure_station_calendar_entry_ids", "string", stable_id_pattern},
      {"station_calendar_pressure_station_calendar_provider_ids", "string", stable_id_pattern},
      {"station_calendar_pressure_station_calendar_provider_entry_ids", "string",
       stable_id_pattern},
      {"station_calendar_pressure_station_calendar_directions", "string", nil},
      {"station_calendar_pressure_station_calendar_statuses", "string", nil},
      {"station_calendar_pressure_station_availabilities", "string", nil},
      {"station_calendar_pressure_station_contention_statuses", "string", nil},
      {"station_calendar_pressure_station_calendar_overlap_count_values", "integer", nil},
      {"station_calendar_pressure_station_calendar_overlap_entry_ids", "string",
       stable_id_pattern},
      {"station_calendar_pressure_station_calendar_overlap_availabilities", "string", nil},
      {"station_calendar_pressure_station_calendar_entry_ambiguous_values", "boolean", nil},
      {"station_calendar_pressure_station_calendar_ambiguous_entry_count_values", "integer", nil},
      {"station_calendar_pressure_station_calendar_ambiguous_entry_ids", "string",
       stable_id_pattern},
      {"station_calendar_pressure_station_calendar_reservation_overlap_count_values", "integer",
       nil},
      {"station_calendar_pressure_station_calendar_reservation_ids", "string", stable_id_pattern},
      {"station_calendar_pressure_station_calendar_reserved_by", "string", nil},
      {"station_calendar_pressure_station_calendar_reservation_statuses", "string", nil},
      {"station_calendar_pressure_station_calendar_trust_boundary_statuses", "string", nil},
      {"station_calendar_pressure_provider_calendar_contention_group_ids", "string",
       stable_id_pattern},
      {"station_calendar_pressure_provider_calendar_contention_statuses", "string", nil},
      {"station_calendar_pressure_provider_calendar_contention_entry_ids", "string",
       stable_id_pattern},
      {"station_calendar_pressure_provider_calendar_contention_provider_ids", "string",
       stable_id_pattern},
      {"station_calendar_pressure_provider_calendar_contention_provider_entry_ids", "string",
       stable_id_pattern},
      {"station_calendar_pressure_provider_calendar_contention_availabilities", "string", nil},
      {"station_calendar_pressure_provider_calendar_contention_directions", "string", nil},
      {"station_calendar_pressure_provider_calendar_contention_reservation_ids", "string",
       stable_id_pattern},
      {"station_calendar_pressure_provider_calendar_contention_reserved_by", "string", nil},
      {"station_calendar_pressure_provider_calendar_contention_reservation_statuses", "string",
       nil},
      {"station_calendar_pressure_provider_calendar_contention_trust_boundary_statuses", "string",
       nil},
      {"station_calendar_pressure_required_operator_actions", "string", nil},
      {"station_calendar_pressure_feedback_sources", "string", nil},
      {"station_calendar_pressure_feedback_scopes", "string", nil},
      {"station_calendar_pressure_trust_boundaries", "string", nil},
      {"station_calendar_pressure_derivation_reasons", "string", nil}
    ]

    stable_id_array_map_fields = [
      "station_reservation_hold_ids_by_import_status",
      "station_reservation_hold_ids_by_required_import_action",
      "station_reservation_hold_ids_by_direction",
      "station_reservation_hold_ids_by_direction_and_ground_station_id",
      "station_reservation_hold_contact_ids_by_import_status",
      "station_reservation_hold_contact_ids_by_expiration_status",
      "station_reservation_hold_contact_ids_by_direction",
      "station_reservation_hold_contact_ids_by_direction_and_ground_station_id"
    ]

    non_negative_integer_count_map_fields = [
      "station_reservation_hold_import_status_count_maps",
      "station_reservation_hold_required_import_action_count_maps"
    ]

    item_minimums = %{
      "capacity_pack_risk_capacity_fraction_values" => 0.0,
      "capacity_pack_risk_used_fraction_values" => 0.0,
      "capacity_pack_risk_unused_fraction_values" => 0.0,
      "capacity_pack_risk_required_capacity_fraction_values" => 0.0,
      "contact_contention_resolution_pressure_priority_override_count_values" => 0,
      "station_calendar_pressure_capacity_fraction_values" => 0.0,
      "station_reservation_hold_count_values" => 0,
      "station_calendar_pressure_station_calendar_overlap_count_values" => 0,
      "station_calendar_pressure_station_calendar_ambiguous_entry_count_values" => 0,
      "station_calendar_pressure_station_calendar_reservation_overlap_count_values" => 0
    }

    item_maximums = %{
      "capacity_pack_risk_capacity_fraction_values" => 1.0,
      "capacity_pack_risk_used_fraction_values" => 1.0,
      "capacity_pack_risk_unused_fraction_values" => 1.0,
      "capacity_pack_risk_required_capacity_fraction_values" => 1.0,
      "station_calendar_pressure_capacity_fraction_values" => 1.0
    }

    assert get_in(strategy_schema, [
             "properties",
             "recommendation",
             "properties",
             "risks_remaining",
             "items",
             "properties",
             scalar_field,
             "type"
           ]) == "string"

    assert get_in(strategy_schema, [
             "properties",
             "recommendation",
             "properties",
             "explanation",
             "items",
             "properties",
             scalar_field,
             "type"
           ]) == "string"

    Enum.each(aggregate_fields, fn {aggregate_field, item_type, item_pattern} ->
      item_schemas = [
        get_in(review_schema, [
          "properties",
          "rows",
          "items",
          "properties",
          aggregate_field,
          "items"
        ]),
        get_in(import_schema, [
          "properties",
          "rows",
          "items",
          "properties",
          aggregate_field,
          "items"
        ]),
        get_in(import_schema, [
          "properties",
          "rows",
          "items",
          "properties",
          "source_review_row",
          "properties",
          aggregate_field,
          "items"
        ])
      ]

      Enum.each(item_schemas, fn item_schema ->
        assert item_schema["type"] == item_type

        if item_pattern do
          assert item_schema["pattern"] == item_pattern
        end

        if item_minimum = item_minimums[aggregate_field] do
          assert item_schema["minimum"] == item_minimum
        end

        if item_maximum = item_maximums[aggregate_field] do
          assert item_schema["maximum"] == item_maximum
        end
      end)
    end)

    Enum.each(stable_id_array_map_fields, fn aggregate_field ->
      item_schemas = [
        get_in(review_schema, [
          "properties",
          "rows",
          "items",
          "properties",
          aggregate_field,
          "items"
        ]),
        get_in(import_schema, [
          "properties",
          "rows",
          "items",
          "properties",
          aggregate_field,
          "items"
        ]),
        get_in(import_schema, [
          "properties",
          "rows",
          "items",
          "properties",
          "source_review_row",
          "properties",
          aggregate_field,
          "items"
        ])
      ]

      Enum.each(item_schemas, fn item_schema ->
        assert item_schema["type"] == "object"
        assert get_in(item_schema, ["additionalProperties", "type"]) == "array"

        assert get_in(item_schema, ["additionalProperties", "items", "pattern"]) ==
                 stable_id_pattern
      end)
    end)

    Enum.each(non_negative_integer_count_map_fields, fn aggregate_field ->
      item_schemas = [
        get_in(review_schema, [
          "properties",
          "rows",
          "items",
          "properties",
          aggregate_field,
          "items"
        ]),
        get_in(import_schema, [
          "properties",
          "rows",
          "items",
          "properties",
          aggregate_field,
          "items"
        ]),
        get_in(import_schema, [
          "properties",
          "rows",
          "items",
          "properties",
          "source_review_row",
          "properties",
          aggregate_field,
          "items"
        ])
      ]

      Enum.each(item_schemas, fn item_schema ->
        assert item_schema["type"] == "object"
        assert get_in(item_schema, ["additionalProperties", "type"]) == "integer"
        assert get_in(item_schema, ["additionalProperties", "minimum"]) == 0
      end)
    end)

    hold_summary_field = "source_station_reservation_hold_import_readiness_summaries"

    hold_summary_schemas = [
      get_in(review_schema, [
        "properties",
        "rows",
        "items",
        "properties",
        hold_summary_field,
        "items"
      ]),
      get_in(import_schema, [
        "properties",
        "rows",
        "items",
        "properties",
        hold_summary_field,
        "items"
      ]),
      get_in(import_schema, [
        "properties",
        "rows",
        "items",
        "properties",
        "source_review_row",
        "properties",
        hold_summary_field,
        "items"
      ])
    ]

    Enum.each(hold_summary_schemas, fn summary_schema ->
      assert summary_schema["type"] == "object"

      assert summary_schema["required"] == [
               "model",
               "source_artifact_type",
               "source",
               "reservation_hold_count",
               "import_readiness_status",
               "import_classification"
             ]

      assert get_in(summary_schema, ["properties", "model", "const"]) ==
               "artifact_only_station_reservation_hold_import_readiness_summary"

      assert get_in(summary_schema, ["properties", "source_artifact_type", "enum"]) ==
               ["station_reservation_report.v1"]

      assert get_in(summary_schema, ["properties", "source", "type"]) == "string"

      assert get_in(summary_schema, ["properties", "reservation_hold_count", "type"]) ==
               "integer"

      assert get_in(summary_schema, ["properties", "reservation_hold_count", "minimum"]) == 0

      assert get_in(summary_schema, ["properties", "import_readiness_status", "enum"]) ==
               ["clear", "review_required"]

      assert get_in(summary_schema, ["properties", "import_classification", "enum"]) ==
               ["not_applicable", "review_only"]
    end)

    overlap_pair_field =
      "station_calendar_pressure_provider_calendar_contention_overlap_pairs"

    overlap_pair_schemas = [
      get_in(review_schema, [
        "properties",
        "rows",
        "items",
        "properties",
        overlap_pair_field,
        "items"
      ]),
      get_in(import_schema, [
        "properties",
        "rows",
        "items",
        "properties",
        overlap_pair_field,
        "items"
      ]),
      get_in(import_schema, [
        "properties",
        "rows",
        "items",
        "properties",
        "source_review_row",
        "properties",
        overlap_pair_field,
        "items"
      ])
    ]

    Enum.each(overlap_pair_schemas, fn pair_schema ->
      assert pair_schema["type"] == "object"

      assert pair_schema["required"] == [
               "left_entry_id",
               "right_entry_id",
               "overlap_starts_at_s",
               "overlap_ends_at_s",
               "overlap_duration_s"
             ]

      assert get_in(pair_schema, ["properties", "left_entry_id", "pattern"]) ==
               stable_id_pattern

      assert get_in(pair_schema, ["properties", "right_entry_id", "pattern"]) ==
               stable_id_pattern

      Enum.each(
        ["overlap_starts_at_s", "overlap_ends_at_s", "overlap_duration_s"],
        fn field ->
          assert get_in(pair_schema, ["properties", field, "type"]) == "number"
        end
      )
    end)
  end

  test "exports nested branch comparison report row schema" do
    assert {:ok, schema} = Schema.json_schema("branch_comparison_report.v1")

    row_schema = get_in(schema, ["properties", "rows", "items"])

    assert get_in(schema, ["properties", "branch_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(schema, ["properties", "model_limits", "items", "enum"]) ==
             OrbitalDynamics.CampaignPlanner.branch_comparison_model_limits()

    assert get_in(schema, ["properties", "model", "const"]) ==
             "deterministic_strategy_branch_score_comparison"

    assert get_in(schema, ["properties", "source", "const"]) == "campaign_strategy.branches"

    assert row_schema["type"] == "object"
    assert "score_terms" in row_schema["required"]

    assert get_in(row_schema, ["properties", "branch_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, ["properties", "branch_probability", "minimum"]) == 0.0
    assert get_in(row_schema, ["properties", "branch_probability", "maximum"]) == 1.0
    assert get_in(row_schema, ["properties", "projected_storage_margin", "type"]) == "number"

    assert get_in(row_schema, ["properties", "projected_storage_remaining_mb", "type"]) ==
             "number"

    assert get_in(row_schema, ["properties", "projected_downlink_remaining_mb", "type"]) ==
             "number"

    assert get_in(row_schema, ["properties", "repair_score", "type"]) == "number"
    assert get_in(row_schema, ["properties", "antenna_availability", "type"]) == "number"

    assert get_in(row_schema, [
             "properties",
             "first_resource_pressure_station_calendar_provider_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, [
             "properties",
             "first_resource_pressure_station_calendar_provider_entry_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    Enum.each(
      [
        "approval_requirement_count",
        "branch_event_count",
        "branch_requires_operator_review_count",
        "candidate_activity_count",
        "coverage_observed_target_count",
        "priority_commitment_missed_target_count",
        "priority_commitment_required_target_count",
        "priority_commitment_satisfied_target_count",
        "repair_delta_count",
        "repair_link_contact_count",
        "repair_link_selected_contact_count",
        "repair_score_term_count",
        "resource_projection_antenna_unavailable_count",
        "resource_projection_degraded_payload_unavailable_count",
        "resource_projection_flow_count",
        "resource_projection_payload_unavailable_count",
        "resource_projection_spacecraft_count",
        "resource_projection_unavailable_spacecraft_count",
        "resource_projection_warning_count",
        "revisit_count",
        "risk_count"
      ],
      fn field ->
        assert get_in(row_schema, ["properties", field]) == %{
                 "type" => "integer",
                 "minimum" => 0
               }
      end
    )

    Enum.each(["downlink_completion_ratio", "observation_success_factor"], fn field ->
      assert get_in(row_schema, ["properties", field]) == %{
               "type" => "number",
               "minimum" => 0.0,
               "maximum" => 1.0
             }
    end)

    Enum.each(
      ["downlink_completion_required_contacts", "downlink_completion_planned_contacts"],
      fn field ->
        assert get_in(row_schema, ["properties", field]) == %{
                 "type" => "integer",
                 "minimum" => 0
               }
      end
    )

    assert get_in(row_schema, ["properties", "risk_types", "items", "type"]) == "string"
    assert get_in(row_schema, ["properties", "high_risk_types", "items", "type"]) == "string"

    assert get_in(row_schema, ["properties", "resource_pressure_statuses", "items", "type"]) ==
             "string"

    assert get_in(row_schema, ["properties", "resource_pressure_types", "items", "type"]) ==
             "string"

    assert get_in(row_schema, ["properties", "first_resource_pressure_kinds", "items", "type"]) ==
             "string"

    assert get_in(row_schema, ["properties", "feedback_risk_types", "items", "type"]) == "string"

    assert get_in(row_schema, [
             "properties",
             "priority_commitment_required_target_ids",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, ["properties", "revisit_count", "type"]) == "integer"

    assert get_in(row_schema, ["properties", "branch_event_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(row_schema, ["properties", "branch_event_types", "items", "type"]) == "string"

    Enum.each(
      [
        "branch_contact_allocation_statuses",
        "branch_contact_allocation_effective_statuses",
        "branch_contact_allocation_reasons",
        "branch_contact_allocation_review_statuses",
        "branch_contact_allocation_approval_statuses",
        "branch_contact_allocation_policy_classifications"
      ],
      fn field ->
        assert get_in(row_schema, ["properties", field, "items", "type"]) == "string"
      end
    )

    assert get_in(row_schema, [
             "properties",
             "branch_event_trust_boundary_status_counts",
             "propertyNames",
             "enum"
           ]) == ["declared", "missing", "untrusted"]

    assert get_in(row_schema, [
             "properties",
             "combined_source_branch_ids",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, [
             "properties",
             "branch_station_calendar_provider_ids",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, [
             "properties",
             "branch_station_calendar_provider_entry_ids",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, [
             "properties",
             "branch_collection_ids",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, [
             "properties",
             "branch_objective_types",
             "items",
             "type"
           ]) == "string"

    assert get_in(row_schema, ["properties", "branch_max_latency_s", "type"]) == "number"

    assert get_in(row_schema, [
             "properties",
             "branch_source_window_ids",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, [
             "properties",
             "branch_source_window_bounds",
             "items",
             "properties",
             "source_window_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    for field <- ["earliest_starts_at_s", "latest_ends_at_s"] do
      assert get_in(row_schema, [
               "properties",
               "branch_source_window_bounds",
               "items",
               "properties",
               field,
               "type"
             ]) == "number"
    end

    for field <- [
          "branch_source_window_count",
          "branch_source_window_bound_count",
          "branch_untimed_source_window_count"
        ] do
      assert get_in(row_schema, ["properties", field]) == %{
               "type" => "integer",
               "minimum" => 0
             }
    end

    assert get_in(row_schema, [
             "properties",
             "branch_untimed_source_window_ids",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, [
             "properties",
             "branch_partially_timed_source_window_ids",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, [
             "properties",
             "branch_partially_timed_source_window_count"
           ]) == %{"type" => "integer", "minimum" => 0}

    assert get_in(row_schema, [
             "properties",
             "branch_source_window_timing_coverage_status",
             "enum"
           ]) == ["complete", "partial", "untimed"]

    assert get_in(row_schema, ["properties", "branch_earliest_starts_at_s", "type"]) ==
             "number"

    assert get_in(row_schema, ["properties", "branch_latest_ends_at_s", "type"]) == "number"

    assert get_in(row_schema, [
             "properties",
             "branch_station_calendar_directions",
             "items",
             "type"
           ]) == "string"

    assert get_in(row_schema, [
             "properties",
             "branch_station_reservation_ids",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, [
             "properties",
             "branch_station_reservation_conflict_contact_ids",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, [
             "properties",
             "branch_station_reservation_conflict_reservation_ids",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, [
             "properties",
             "branch_station_reservation_conflict_match_statuses",
             "items",
             "type"
           ]) == "string"

    assert get_in(row_schema, [
             "properties",
             "branch_station_reservation_expiration_statuses",
             "items",
             "type"
           ]) == "string"

    assert get_in(row_schema, ["properties", "repair_score_term_keys", "items", "type"]) ==
             "string"

    assert get_in(row_schema, [
             "properties",
             "repair_link_selected_capacity_adjusted_throughput_mb",
             "type"
           ]) == "number"

    assert get_in(row_schema, ["properties", "capacity_pack_group_ids", "items", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, ["properties", "capacity_pack_statuses", "items", "type"]) ==
             "string"

    Enum.each(
      [
        "capacity_pack_min_capacity_fraction",
        "capacity_pack_max_used_fraction",
        "capacity_pack_max_required_capacity_fraction"
      ],
      fn field ->
        assert get_in(row_schema, ["properties", field]) == %{
                 "type" => "number",
                 "minimum" => 0.0,
                 "maximum" => 1.0
               }
      end
    )

    assert get_in(row_schema, [
             "properties",
             "capacity_pack_total_required_capacity_fraction",
             "minimum"
           ]) == 0.0

    assert get_in(row_schema, [
             "properties",
             "capacity_pack_required_capacity_sources",
             "items",
             "type"
           ]) == "string"

    assert get_in(row_schema, [
             "properties",
             "score_terms",
             "additionalProperties",
             "type"
           ]) == "number"
  end

  test "exports nested score term report row schema" do
    assert {:ok, schema} = Schema.json_schema("score_term_report.v1")

    row_schema = get_in(schema, ["properties", "rows", "items"])

    assert get_in(schema, ["properties", "model", "enum"]) == [
             "ranked_timeline_score_terms",
             "repair_score_terms",
             "strategy_branch_score_terms"
           ]

    assert get_in(schema, ["properties", "source", "type"]) == "string"

    assert row_schema["type"] == "object"

    assert row_schema["required"] == [
             "id",
             "rank",
             "scenario_id",
             "term_key",
             "value",
             "timeline_score",
             "selected"
           ]

    assert get_in(row_schema, ["properties", "id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, ["properties", "scenario_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, ["properties", "selected", "type"]) == "boolean"
    assert get_in(schema, ["properties", "score_term_keys", "items", "type"]) == "string"

    assert get_in(schema, ["properties", "row_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(schema, ["properties", "model_limits", "items", "enum"]) ==
             OrbitalDynamics.CampaignPlanner.score_report_model_limits()
  end

  test "exports nested link capacity report row schema" do
    assert {:ok, schema} = Schema.json_schema("link_capacity_report.v1")

    row_schema = get_in(schema, ["properties", "rows", "items"])

    assert row_schema["type"] == "object"
    assert "ground_station_id" in row_schema["required"]

    assert get_in(schema, ["properties", "model", "const"]) ==
             "fixed_rate_downlink_capacity_summary"

    assert get_in(schema, ["properties", "source", "type"]) == "string"

    assert get_in(schema, ["properties", "contact_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(schema, ["properties", "ignored_contact_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(schema, ["properties", "selected_capacity_utilization_fraction"]) == %{
             "type" => "number",
             "minimum" => 0.0,
             "maximum" => 1.0
           }

    assert get_in(schema, [
             "properties",
             "ignored_contact_reason_counts",
             "additionalProperties"
           ]) == %{"type" => "integer", "minimum" => 0}

    assert get_in(schema, [
             "properties",
             "ignored_selected_contact_reason_counts",
             "additionalProperties"
           ]) == %{"type" => "integer", "minimum" => 0}

    assert get_in(row_schema, ["properties", "ground_station_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, ["properties", "station_availability", "type"]) == "string"

    assert get_in(row_schema, ["properties", "estimated_throughput_mb", "type"]) == "number"

    assert get_in(row_schema, ["properties", "contact_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(row_schema, ["properties", "actual_throughput_contact_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(row_schema, ["properties", "selected_capacity_utilization_fraction"]) == %{
             "type" => "number",
             "minimum" => 0.0,
             "maximum" => 1.0
           }

    Enum.each(["capacity_fraction_min", "capacity_fraction_max"], fn field ->
      assert get_in(row_schema, ["properties", field]) == %{
               "type" => "number",
               "minimum" => 0.0,
               "maximum" => 1.0
             }
    end)

    assert get_in(row_schema, ["properties", "capacity_adjusted_throughput_mb", "type"]) ==
             "number"

    assert get_in(row_schema, [
             "properties",
             "selected_capacity_adjusted_throughput_mb",
             "type"
           ]) == "number"

    assert get_in(row_schema, ["properties", "actual_throughput_mb", "type"]) == "number"

    assert get_in(row_schema, [
             "properties",
             "actual_data_rate_throughput_derivations",
             "items",
             "type"
           ]) == "object"

    assert get_in(row_schema, [
             "properties",
             "actual_data_rate_throughput_derivations",
             "items",
             "properties",
             "duration_s",
             "type"
           ]) == "number"

    assert get_in(row_schema, [
             "properties",
             "ignored_contact_reason_counts",
             "additionalProperties"
           ]) == %{"type" => "integer", "minimum" => 0}

    assert get_in(row_schema, [
             "properties",
             "ignored_selected_contact_reason_counts",
             "additionalProperties"
           ]) == %{"type" => "integer", "minimum" => 0}

    Enum.each(
      [
        "ignored_contact_ids",
        "ignored_selected_contact_ids",
        "ambiguous_selected_contact_ids",
        "unmatched_selected_contact_ids",
        "actual_throughput_contact_ids",
        "actual_completion_contact_ids",
        "unmatched_actual_throughput_contact_ids",
        "ambiguous_actual_throughput_contact_ids",
        "unmatched_actual_completion_contact_ids",
        "ambiguous_actual_completion_contact_ids",
        "station_reservation_ids"
      ],
      fn field ->
        assert get_in(schema, ["properties", field, "items", "pattern"]) ==
                 Schema.identity_policy()["stable_id_pattern"]
      end
    )

    Enum.each(
      [
        "ignored_contact_ids",
        "ignored_selected_contact_ids",
        "ambiguous_selected_contact_ids",
        "duplicate_contact_ids",
        "station_calendar_entry_ids",
        "station_calendar_provider_ids",
        "station_calendar_provider_entry_ids",
        "station_reservation_ids",
        "actual_throughput_contact_ids",
        "actual_completion_contact_ids",
        "unmatched_actual_throughput_contact_ids",
        "ambiguous_actual_throughput_contact_ids",
        "unmatched_actual_completion_contact_ids",
        "ambiguous_actual_completion_contact_ids"
      ],
      fn field ->
        assert get_in(row_schema, ["properties", field, "items", "pattern"]) ==
                 Schema.identity_policy()["stable_id_pattern"]
      end
    )

    assert get_in(row_schema, ["properties", "contact_ids", "items", "type"]) == "string"
  end

  test "exports relay data-path summary row schema" do
    assert {:ok, schema} = Schema.json_schema("relay_data_path_summary.v1")

    row_schema = get_in(schema, ["properties", "rows", "items"])

    assert row_schema["type"] == "object"
    assert "route_id" in row_schema["required"]
    assert "relay_hop_count" in row_schema["required"]

    assert get_in(schema, ["properties", "model", "const"]) ==
             "artifact_only_relay_data_path_summary"

    assert get_in(schema, ["properties", "route_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(schema, ["properties", "custody_status_counts", "additionalProperties"]) ==
             %{"type" => "integer", "minimum" => 0}

    assert get_in(schema, [
             "properties",
             "assumptions",
             "properties",
             "custody_acknowledgement_delivery",
             "const"
           ]) == "not_performed"

    assert get_in(row_schema, ["properties", "route_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, ["properties", "relay_hop_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(row_schema, ["properties", "relay_chain_spacecraft_ids", "items", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, ["properties", "latency_s", "type"]) == "number"
    assert get_in(row_schema, ["properties", "risk_reasons", "items", "type"]) == "string"
  end

  test "exports nested objective satisfaction report row schema" do
    assert {:ok, schema} = Schema.json_schema("objective_satisfaction_report.v1")

    row_schema = get_in(schema, ["properties", "rows", "items"])

    assert row_schema["type"] == "object"
    assert "objective" in row_schema["required"]

    assert get_in(schema, ["properties", "model", "const"]) ==
             "campaign_v1_selected_activity_objective_summary"

    assert get_in(row_schema, ["properties", "status", "enum"]) == [
             "met",
             "partial",
             "unmet",
             "selected",
             "candidate_available",
             "no_candidate_window",
             "no_requirement"
           ]

    assert get_in(row_schema, ["properties", "target_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, ["properties", "selected_activity_ids", "items", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, ["properties", "selected_downlink_mb", "type"]) == "number"
    assert get_in(row_schema, ["properties", "required_downlink_mb", "type"]) == "number"

    assert get_in(schema, ["properties", "objective_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    Enum.each(
      ["required_count", "candidate_count", "selected_count", "satisfied_count"],
      fn field ->
        assert get_in(row_schema, ["properties", field]) == %{
                 "type" => "integer",
                 "minimum" => 0
               }
      end
    )

    assert get_in(schema, ["properties", "model_limits", "items", "enum"]) ==
             OrbitalDynamics.CampaignPlanner.objective_satisfaction_model_limits()
  end

  test "exports nested timeline diff report row schema" do
    assert {:ok, schema} = Schema.json_schema("timeline_diff_report.v1")

    row_schema = get_in(schema, ["properties", "rows", "items"])

    assert get_in(row_schema, [
             "properties",
             "source_activity_context",
             "properties",
             "activity_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, [
             "properties",
             "replacement_activity_context",
             "properties",
             "timeline_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, ["properties", "source_protection_decision", "type"]) ==
             "object"

    assert get_in(row_schema, ["properties", "replacement_protection_reason", "type"]) ==
             "string"

    assert get_in(row_schema, ["properties", "diff_status", "enum"]) ==
             OrbitalDynamics.Timeline.capabilities().timeline_diff_statuses

    assert get_in(row_schema, ["properties", "transition_decision", "enum"]) ==
             OrbitalDynamics.Timeline.capabilities().transition_decisions
  end

  test "exports nested objective tradeoff report row schema" do
    assert {:ok, schema} = Schema.json_schema("objective_tradeoff_report.v1")

    row_schema = get_in(schema, ["properties", "tradeoffs", "items"])

    assert row_schema["type"] == "object"
    assert "score_terms" in row_schema["required"]

    assert get_in(schema, ["properties", "model", "enum"]) == [
             "ranked_timeline_score_term_tradeoffs",
             "repair_score_term_tradeoffs",
             "strategy_branch_score_term_tradeoffs"
           ]

    assert get_in(row_schema, ["properties", "scenario_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, ["properties", "score_delta_from_selected", "type"]) == "number"
    assert get_in(row_schema, ["properties", "activity_ids", "items", "type"]) == "string"

    assert get_in(row_schema, ["properties", "score_terms", "additionalProperties", "type"]) ==
             "number"

    Enum.each(
      ["activity_count", "selected_observation_count", "selected_contact_count"],
      fn field ->
        assert get_in(row_schema, ["properties", field]) == %{
                 "type" => "integer",
                 "minimum" => 0
               }
      end
    )

    assert get_in(schema, ["properties", "score_term_keys", "items", "type"]) == "string"
    assert get_in(schema, ["properties", "policy", "type"]) == "object"

    assert get_in(schema, ["properties", "ranking_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(schema, ["properties", "model_limits", "items", "enum"]) ==
             OrbitalDynamics.CampaignPlanner.score_report_model_limits()
  end

  test "exports nested ranking comparison report row schema" do
    assert {:ok, schema} = Schema.json_schema("ranking_comparison_report.v1")

    row_schema = get_in(schema, ["properties", "rows", "items"])

    assert row_schema["type"] == "object"
    assert "scenario_id" in row_schema["required"]

    assert get_in(row_schema, ["properties", "scenario_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, ["properties", "status", "enum"]) == [
             "matched",
             "left_only",
             "right_only"
           ]

    assert get_in(row_schema, ["properties", "left_rank", "type"]) == ["integer", "null"]
    assert get_in(row_schema, ["properties", "value_delta", "type"]) == ["number", "null"]
    assert get_in(schema, ["properties", "winner", "properties", "changed", "type"]) == "boolean"

    assert get_in(schema, ["properties", "model", "const"]) == "scenario_ranking_pairwise_delta"

    assert get_in(schema, ["properties", "left_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(schema, ["properties", "row_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(schema, ["properties", "model_limits", "items", "enum"]) ==
             OrbitalDynamics.Optimizer.ranking_comparison_model_limits()
  end

  test "exports nested Pareto frontier report row schema" do
    assert {:ok, schema} = Schema.json_schema("pareto_frontier_report.v1")

    row_schema = get_in(schema, ["properties", "rows", "items"])

    assert row_schema["type"] == "object"
    assert "id" in row_schema["required"]
    assert "frontier" in row_schema["required"]

    assert get_in(row_schema, ["properties", "id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, ["properties", "objective_values", "additionalProperties", "type"]) ==
             "number"

    assert get_in(row_schema, ["properties", "objective_keys", "items", "type"]) == "string"
    assert get_in(row_schema, ["properties", "frontier", "type"]) == "boolean"

    assert get_in(row_schema, ["properties", "dominates_ids", "items", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(schema, ["properties", "frontier_ids", "items", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(schema, ["properties", "alternative_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(schema, ["properties", "frontier_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(schema, ["properties", "objective_directions", "type"]) == "object"

    assert get_in(schema, ["properties", "model", "const"]) == "objective_vector_pareto_frontier"

    assert get_in(schema, ["properties", "model_limits", "items", "enum"]) ==
             OrbitalDynamics.Optimizer.pareto_frontier_model_limits()
  end

  test "exports nested constraint report row schema" do
    assert {:ok, schema} = Schema.json_schema("constraint_report.v1")

    row_schema = get_in(schema, ["properties", "rows", "items"])

    assert row_schema["type"] == "object"
    assert "constraint_id" in row_schema["required"]

    assert get_in(row_schema, ["properties", "constraint_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, ["properties", "operator", "enum"]) == ["<", "<=", "==", ">=", ">"]
    assert get_in(row_schema, ["properties", "status", "enum"]) == ["pass", "fail", "warning"]

    assert get_in(schema, ["properties", "constraint_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(schema, ["properties", "row_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(schema, ["properties", "model_limits", "items", "enum"]) ==
             [
               "artifact_level_only",
               "evaluated_after_candidate_generation_filters",
               "link_capacity_constraints_are_fixed_rate_summaries",
               "missing_or_nil_values_fail",
               "no_rerun_propagation",
               "not_a_general_constraint_solver",
               "numeric_threshold_violations_can_be_warnings",
               "planner_local_constraints_only",
               "resource_projection_constraints_are_planning_grade",
               "uses_report_metric_rows"
             ]

    campaign_local_limits = [
      "planner_local_constraints_only",
      "evaluated_after_candidate_generation_filters",
      "resource_projection_constraints_are_planning_grade",
      "link_capacity_constraints_are_fixed_rate_summaries",
      "not_a_general_constraint_solver"
    ]

    assert Enum.any?(
             schema["allOf"],
             &(get_in(&1, ["if", "properties", "model", "const"]) == "artifact_metric_threshold" and
                 get_in(&1, ["then", "properties", "model_limits", "const"]) ==
                   [
                     "artifact_level_only",
                     "no_rerun_propagation",
                     "missing_or_nil_values_fail",
                     "numeric_threshold_violations_can_be_warnings",
                     "uses_report_metric_rows"
                   ])
           )

    assert Enum.any?(
             schema["allOf"],
             &(get_in(&1, ["if", "properties", "model", "const"]) ==
                 "campaign_repair_local_constraint_summary" and
                 get_in(&1, ["then", "properties", "model_limits", "const"]) ==
                   campaign_local_limits)
           )
  end

  test "validates checked-in constraint report example" do
    report = read_json!("study_results/constraint_report_v1.json")

    assert {:ok, %{"schema_contract" => "constraint_report.v1"}} =
             Schema.validate_artifact(report)

    assert %{
             "constraint_count" => 2,
             "row_count" => 3,
             "status" => "fail",
             "status_counts" => %{"pass" => 1, "fail" => 1, "warning" => 1},
             "rows" => [
               %{"constraint_id" => "minimum_operational_altitude", "status" => "pass"},
               %{"constraint_id" => "minimum_operational_altitude", "status" => "fail"},
               %{"constraint_id" => "downlink_margin", "status" => "warning"}
             ]
           } = report

    invalid_model_limits = Map.put(report, "model_limits", ["artifact_level_only"])

    assert {:error, validation_report} = Schema.validate_artifact(invalid_model_limits)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] =~ "must match constraint report model limits")
           )

    invalid_model = Map.put(report, "model", "ad_hoc_constraint_report_model")

    assert {:error, invalid_model_report} = Schema.validate_artifact(invalid_model)

    assert Enum.any?(
             invalid_model_report["errors"],
             &(&1["path"] == "$.model")
           )

    campaign_local_limits = [
      "planner_local_constraints_only",
      "evaluated_after_candidate_generation_filters",
      "resource_projection_constraints_are_planning_grade",
      "link_capacity_constraints_are_fixed_rate_summaries",
      "not_a_general_constraint_solver"
    ]

    repair_constraint_report =
      report
      |> Map.put("model", "campaign_repair_local_constraint_summary")
      |> Map.put("model_limits", campaign_local_limits)

    assert {:ok, %{"schema_contract" => "constraint_report.v1"}} =
             Schema.validate_artifact(repair_constraint_report)

    invalid_repair_model_limits =
      Map.put(repair_constraint_report, "model_limits", ["planner_local_constraints_only"])

    assert {:error, repair_validation_report} =
             Schema.validate_artifact(invalid_repair_model_limits)

    assert Enum.any?(
             repair_validation_report["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] =~ "must match constraint report model limits")
           )

    invalid_constraint_count = Map.put(report, "constraint_count", 2.0)

    assert {:error, constraint_count_report} = Schema.validate_artifact(invalid_constraint_count)

    assert Enum.any?(
             constraint_count_report["errors"],
             &(&1["path"] == "$.constraint_count")
           )

    invalid_row_count = Map.put(report, "row_count", -1)

    assert {:error, row_count_report} = Schema.validate_artifact(invalid_row_count)

    assert Enum.any?(
             row_count_report["errors"],
             &(&1["path"] == "$.row_count")
           )
  end

  test "exported schemas do not leave identity fields as opaque object schemas" do
    violations =
      Schema.contracts()
      |> Enum.flat_map(fn {contract_name, _contract} ->
        assert {:ok, schema} = Schema.json_schema(contract_name)

        schema
        |> opaque_identity_property_paths()
        |> Enum.map(&"#{contract_name}:#{&1}")
      end)

    assert violations == []
  end

  test "exported schemas and executable validators treat report counts as integers" do
    assert {:ok, manifest_field_reference_schema} =
             Schema.json_schema("manifest_field_reference.v1")

    assert {:ok, refreshed_window_schema} = Schema.json_schema("refreshed_window.v1")

    assert get_in(manifest_field_reference_schema, ["properties", "field_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(refreshed_window_schema, ["properties", "sample_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    violations =
      Schema.contracts()
      |> Enum.flat_map(fn {contract_name, contract} ->
        assert {:ok, schema} = Schema.json_schema(contract_name)

        fields =
          ((contract["required_fields"] || []) ++ (contract["optional_fields"] || []))
          |> Enum.filter(&String.ends_with?(&1, "_count"))

        fields
        |> Enum.filter(&(get_in(schema, ["properties", &1, "type"]) == "object"))
        |> Enum.map(&"#{contract_name}:#{&1}")
      end)

    assert violations == []

    for {path, field} <- [
          {"study_results/candidate_diff_report_v1.json", "prior_candidate_count"},
          {"study_results/contact_allocation_report_v1.json", "deferred_contact_count"},
          {"study_results/contact_contention_report_v1.json", "conflict_group_count"},
          {"study_results/contact_contention_resolution_report_v1.json", "conflict_group_count"},
          {"study_results/cadence_import_manifest_v1.json", "ready_count"},
          {"study_results/timeline_transition_application_report_v1.json", "application_count"},
          {"study_results/manifest_field_reference.json", "field_count"},
          {"study_results/refreshed_window_v1.json", "sample_count"},
          {"study_results/study_manifest_lint_v1.json", "error_count"}
        ] do
      artifact = path |> read_json!() |> Map.put(field, 1.5)

      assert {:error, report} = Schema.validate_artifact(artifact)
      assert Enum.any?(report["errors"], &(&1["path"] == "$.#{field}"))
    end

    for {path, field} <- [
          {"study_results/manifest_field_reference.json", "field_count"},
          {"study_results/refreshed_window_v1.json", "sample_count"}
        ] do
      artifact = path |> read_json!() |> Map.put(field, -1)

      assert {:error, report} = Schema.validate_artifact(artifact)
      assert Enum.any?(report["errors"], &(&1["path"] == "$.#{field}"))
    end
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end

  defp opaque_identity_property_paths(schema) do
    schema
    |> collect_opaque_identity_property_paths([], [])
    |> Enum.reverse()
  end

  defp collect_opaque_identity_property_paths(%{} = schema, path, acc) do
    acc =
      schema
      |> Map.get("properties", %{})
      |> Enum.reduce(acc, fn {field, property}, acc ->
        property_path = path ++ ["properties", field]

        if identity_property_name?(field) and opaque_identity_property?(property) do
          [Enum.join(property_path, ".") | acc]
        else
          acc
        end
      end)

    Enum.reduce(schema, acc, fn {key, value}, acc ->
      collect_opaque_identity_property_paths(value, path ++ [to_string(key)], acc)
    end)
  end

  defp collect_opaque_identity_property_paths(values, path, acc) when is_list(values) do
    values
    |> Enum.with_index()
    |> Enum.reduce(acc, fn {value, index}, acc ->
      collect_opaque_identity_property_paths(value, path ++ [Integer.to_string(index)], acc)
    end)
  end

  defp collect_opaque_identity_property_paths(_value, _path, acc), do: acc

  defp identity_property_name?("id"), do: true

  defp identity_property_name?(field) when is_binary(field),
    do: String.ends_with?(field, "_id") or String.ends_with?(field, "_ids")

  defp opaque_identity_property?(%{"type" => "object", "additionalProperties" => property})
       when is_map(property),
       do: opaque_identity_property?(property)

  defp opaque_identity_property?(%{} = property) do
    Map.get(property, "type") == "object" or
      (not Map.has_key?(property, "type") and not Map.has_key?(property, "pattern") and
         not Map.has_key?(property, "items"))
  end
end
