defmodule OrbitalDynamics.Schema.JsonSchemaExportContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  test "exports stable-id hints for standalone artifact identity fields" do
    stable_id_pattern = Schema.identity_policy()["stable_id_pattern"]

    assert {:ok, cadence_schema} = Schema.json_schema("cadence_import_manifest.v1")
    assert {:ok, operator_review_schema} = Schema.json_schema("operator_review_package.v1")

    assert {:ok, provider_request_schema} =
             Schema.json_schema("contact_allocation_provider_reservation_request_summary.v1")

    assert get_in(cadence_schema, ["properties", "manifest_id", "pattern"]) ==
             stable_id_pattern

    assert get_in(cadence_schema, [
             "properties",
             "import_action_counts",
             "propertyNames",
             "enum"
           ]) == OrbitalDynamics.CadenceImport.capability().import_actions

    assert get_in(cadence_schema, [
             "properties",
             "import_status_counts",
             "propertyNames",
             "enum"
           ]) == OrbitalDynamics.CadenceImport.capability().import_statuses

    assert get_in(cadence_schema, [
             "properties",
             "cadence_import_status_counts",
             "propertyNames",
             "enum"
           ]) == OrbitalDynamics.CadenceImport.capability().cadence_import_statuses

    assert get_in(cadence_schema, [
             "properties",
             "source_review_type_counts",
             "propertyNames",
             "enum"
           ]) == OrbitalDynamics.CadenceImport.capability().source_review_types

    assert get_in(cadence_schema, [
             "properties",
             "source_review_queue_counts",
             "additionalProperties"
           ]) == %{"type" => "integer", "minimum" => 0}

    Enum.each(
      [
        "capacity_pack_contact_ids_by_ground_station_id",
        "capacity_pack_selected_contact_ids_by_ground_station_id",
        "capacity_pack_deferred_contact_ids_by_ground_station_id",
        "required_capacity_fraction_contact_ids_by_source",
        "provider_reservation_request_contact_ids_by_ground_station_id",
        "provider_reservation_review_contact_ids_by_ground_station_id",
        "provider_reservation_no_request_contact_ids_by_direction",
        "provider_reservation_request_contact_ids_by_direction",
        "provider_reservation_review_contact_ids_by_direction",
        "provider_reservation_request_contact_ids_by_match_status",
        "provider_reservation_review_contact_ids_by_match_status",
        "provider_reservation_request_ids_by_match_status",
        "provider_reservation_review_ids_by_match_status",
        "gate_ids_by_status",
        "gate_ids_by_classification",
        "quality_gate_row_ids_by_status",
        "quality_gate_row_ids_by_classification",
        "capacity_pack_group_ids_by_status",
        "station_reservation_contact_ids_by_match_status",
        "station_reservation_contact_ids_by_status",
        "station_reservation_contact_ids_by_reserved_by",
        "station_reservation_ids_by_match_status",
        "station_reservation_ids_by_status",
        "station_reservation_ids_by_reserved_by",
        "station_pressure_contact_ids_by_ground_station_id",
        "station_pressure_contact_ids_by_availability",
        "station_pressure_contact_ids_by_precedence_availability",
        "station_pressure_contact_ids_by_precedence_rank",
        "station_pressure_contact_ids_by_direction",
        "reservation_conflict_contact_ids_by_direction"
      ],
      fn field ->
        assert get_in(cadence_schema, [
                 "properties",
                 field,
                 "additionalProperties",
                 "items",
                 "pattern"
               ]) == stable_id_pattern

        assert get_in(operator_review_schema, [
                 "properties",
                 field,
                 "additionalProperties",
                 "items",
                 "pattern"
               ]) == stable_id_pattern
      end
    )

    Enum.each(
      [
        "provider_reservation_no_request_contact_ids_by_direction_and_ground_station_id",
        "provider_reservation_request_contact_ids_by_direction_and_ground_station_id",
        "provider_reservation_review_contact_ids_by_direction_and_ground_station_id",
        "reservation_conflict_contact_ids_by_direction_and_ground_station_id"
      ],
      fn field ->
        assert get_in(cadence_schema, [
                 "properties",
                 field,
                 "additionalProperties",
                 "additionalProperties",
                 "items",
                 "pattern"
               ]) == stable_id_pattern

        assert get_in(operator_review_schema, [
                 "properties",
                 field,
                 "additionalProperties",
                 "additionalProperties",
                 "items",
                 "pattern"
               ]) == stable_id_pattern
      end
    )

    Enum.each(
      [
        "provider_reservation_no_request_contact_ids_by_direction",
        "provider_reservation_request_contact_ids_by_direction",
        "provider_reservation_review_contact_ids_by_direction"
      ],
      fn field ->
        assert get_in(provider_request_schema, [
                 "properties",
                 field,
                 "additionalProperties",
                 "items",
                 "pattern"
               ]) == stable_id_pattern

        refute field in provider_request_schema["required"]
      end
    )

    Enum.each(
      [
        "provider_reservation_no_request_contact_ids_by_direction_and_ground_station_id",
        "provider_reservation_request_contact_ids_by_direction_and_ground_station_id",
        "provider_reservation_review_contact_ids_by_direction_and_ground_station_id"
      ],
      fn field ->
        assert get_in(provider_request_schema, [
                 "properties",
                 field,
                 "additionalProperties",
                 "additionalProperties",
                 "items",
                 "pattern"
               ]) == stable_id_pattern

        refute field in provider_request_schema["required"]
      end
    )

    Enum.each(
      [
        "capacity_pack_group_ids",
        "provider_reservation_request_contact_ids",
        "provider_reservation_review_contact_ids",
        "provider_reservation_no_request_contact_ids",
        "passed_gate_ids",
        "review_required_gate_ids",
        "analysis_only_gate_ids",
        "blocked_gate_ids",
        "reduced_capacity_packed_contact_ids",
        "reduced_capacity_deferred_contact_ids"
      ],
      fn field ->
        assert get_in(cadence_schema, ["properties", field, "items", "pattern"]) ==
                 stable_id_pattern

        assert get_in(operator_review_schema, ["properties", field, "items", "pattern"]) ==
                 stable_id_pattern
      end
    )

    Enum.each(
      [
        "station_pressure_contact_counts_by_ground_station_id",
        "station_pressure_contact_counts_by_availability",
        "station_pressure_contact_counts_by_precedence_availability",
        "station_pressure_contact_counts_by_precedence_rank",
        "gate_status_counts",
        "gate_classification_counts",
        "required_capacity_fraction_source_counts",
        "provider_reservation_request_status_counts",
        "reduced_capacity_pack_status_counts"
      ],
      fn field ->
        assert get_in(cadence_schema, ["properties", field, "additionalProperties"]) == %{
                 "type" => "integer",
                 "minimum" => 0
               }

        assert get_in(operator_review_schema, ["properties", field, "additionalProperties"]) ==
                 %{"type" => "integer", "minimum" => 0}
      end
    )

    Enum.each(
      [
        "row_count",
        "ready_count",
        "review_required_count",
        "blocked_count",
        "missing_import_count"
      ],
      fn field ->
        assert get_in(cadence_schema, ["properties", field]) == %{
                 "type" => "integer",
                 "minimum" => 0
               }
      end
    )

    cadence_row_schema = get_in(cadence_schema, ["properties", "rows", "items"])

    assert get_in(cadence_row_schema, ["properties", "selected_timeline_integrity_issue_count"]) ==
             %{"type" => "integer", "minimum" => 0}

    assert get_in(cadence_row_schema, [
             "properties",
             "selected_duplicate_exclusivity_activity_ids",
             "items",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "source_review_row",
             "properties",
             "selected_timeline_integrity_issue_count"
           ]) == %{"type" => "integer", "minimum" => 0}

    assert get_in(cadence_row_schema, [
             "properties",
             "source_review_row",
             "properties",
             "selected_dependency_order_violation_timeline_ids",
             "items",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(cadence_row_schema, ["properties", "contention_group_id", "pattern"]) ==
             stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "capacity_packed_contact_ids",
             "items",
             "type"
           ]) == "string"

    assert get_in(cadence_row_schema, ["properties", "collection_id", "pattern"]) ==
             stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "branch_collection_ids",
             "items",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "source_timeline_application",
             "properties",
             "application_status",
             "type"
           ]) == "string"

    assert get_in(cadence_row_schema, [
             "properties",
             "source_timeline_diff_summary",
             "properties",
             "review_required_count"
           ]) == %{"type" => "integer", "minimum" => 0}

    assert get_in(cadence_row_schema, [
             "properties",
             "source_timeline_diff_summary",
             "properties",
             "review_timeline_ids",
             "items",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "source_timeline_transition_application_summary",
             "properties",
             "review_required_count"
           ]) == %{"type" => "integer", "minimum" => 0}

    assert get_in(cadence_row_schema, [
             "properties",
             "source_timeline_transition_application_summary",
             "properties",
             "selected_activity_ids",
             "items",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "source_timeline_integrity",
             "properties",
             "timeline_integrity_issue_types",
             "items",
             "enum"
           ]) == OrbitalDynamics.Timeline.capabilities().timeline_integrity_issue_types

    assert get_in(cadence_row_schema, [
             "properties",
             "source_timeline_protection",
             "properties",
             "preserved_locked_or_approved_activity_ids",
             "items",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "source_timeline_activity_state",
             "properties",
             "schema_contract",
             "const"
           ]) == "timeline_activity_state.v1"

    assert get_in(cadence_row_schema, [
             "properties",
             "source_timeline_activity_state",
             "properties",
             "timeline_id",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "source_timeline_lifecycle_state",
             "properties",
             "timeline_id",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "source_timeline_lifecycle_state",
             "properties",
             "invalid_activity_input_count"
           ]) == %{"type" => "integer", "minimum" => 0}

    assert get_in(cadence_row_schema, [
             "properties",
             "source_timeline_lifecycle_state",
             "properties",
             "invalid_activity_input_reasons",
             "items",
             "type"
           ]) == "string"

    assert get_in(cadence_row_schema, [
             "properties",
             "source_timeline_preservation",
             "properties",
             "activity_id",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "source_candidate_rejection",
             "properties",
             "candidate_id",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "source_candidate_rejection",
             "properties",
             "primary_rejection_reason",
             "enum"
           ]) == OrbitalDynamics.Timeline.capabilities().candidate_rejection_reasons

    assert get_in(cadence_row_schema, [
             "properties",
             "source_timeline_dependency_impact",
             "properties",
             "scope",
             "enum"
           ]) == ["source", "replacement"]

    assert get_in(cadence_row_schema, [
             "properties",
             "source_timeline_identity",
             "properties",
             "timeline_id",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "replacement_timeline_identity",
             "properties",
             "timeline_id",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "timeline_link",
             "properties",
             "source_timeline_id",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(operator_review_schema, [
             "properties",
             "rows",
             "items",
             "properties",
             "source_timeline_id",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(cadence_row_schema, ["properties", "eclipse_overlap_fraction", "type"]) ==
             "number"

    assert get_in(cadence_row_schema, ["properties", "planned_eclipse_overlap_s", "type"]) ==
             "number"

    assert get_in(cadence_row_schema, ["properties", "lighting_condition", "type"]) ==
             "string"

    assert get_in(cadence_row_schema, ["properties", "target_id", "pattern"]) ==
             stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "first_resource_pressure_station_calendar_provider_id",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "first_resource_pressure_station_calendar_provider_entry_id",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(cadence_row_schema, ["properties", "import_side", "type"]) == "string"

    assert get_in(cadence_row_schema, ["properties", "replacement_activity_id", "pattern"]) ==
             stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "source_window",
             "properties",
             "id",
             "pattern"
           ]) ==
             stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "replacement_source_window_lineage",
             "properties",
             "candidate_activity_id",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "source_delta",
             "properties",
             "activity_id",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "source_requirement",
             "properties",
             "activity_id",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "source_contact_suppression",
             "properties",
             "source_window_id",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "source_link_capacity",
             "properties",
             "ground_station_id",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "source_resource_projection",
             "properties",
             "spacecraft_id",
             "pattern"
           ]) == stable_id_pattern

    Enum.each(
      [
        "total_battery_energy_consumed_wh",
        "total_battery_energy_generated_wh",
        "net_battery_energy_delta_wh",
        "peak_battery_overuse_wh"
      ],
      fn field ->
        assert get_in(cadence_row_schema, ["properties", field, "type"]) == "number"

        assert get_in(cadence_row_schema, [
                 "properties",
                 "source_resource_projection",
                 "properties",
                 field,
                 "type"
               ]) == "number"

        assert get_in(cadence_row_schema, [
                 "properties",
                 "source_review_row",
                 "properties",
                 field,
                 "type"
               ]) == "number"
      end
    )

    assert get_in(cadence_row_schema, [
             "properties",
             "source_timeline_diff",
             "properties",
             "timeline_id",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "source_command_window",
             "properties",
             "activity_id",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "source_maneuver_review",
             "properties",
             "maneuver_id",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "source_ranking_comparison",
             "properties",
             "scenario_id",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "source_contention_group",
             "properties",
             "ground_station_id",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "source_station_calendar_review",
             "properties",
             "ground_station_id",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "source_feedback",
             "properties",
             "activity_id",
             "pattern"
           ]) == stable_id_pattern

    Enum.each(
      [
        "contact_success_factor",
        "command_success_factor",
        "observation_success_factor",
        "maneuver_success_factor",
        "cloud_cover_fraction",
        "planned_cloud_cover_fraction",
        "realized_cloud_cover_fraction",
        "blur_score",
        "planned_blur_score",
        "realized_blur_score"
      ],
      fn field ->
        assert get_in(cadence_row_schema, [
                 "properties",
                 "source_feedback",
                 "properties",
                 field
               ]) == %{
                 "type" => "number",
                 "minimum" => 0.0,
                 "maximum" => 1.0
               }
      end
    )

    assert get_in(cadence_row_schema, ["properties", "branch_event_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(cadence_row_schema, ["properties", "branch_event_types", "items", "type"]) ==
             "string"

    assert get_in(cadence_row_schema, [
             "properties",
             "branch_event_trust_boundary_status_counts",
             "additionalProperties",
             "type"
           ]) == "integer"

    assert get_in(cadence_row_schema, [
             "properties",
             "combined_source_branch_ids",
             "items",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "branch_station_calendar_provider_ids",
             "items",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "source_review_row",
             "properties",
             "source_delta",
             "properties",
             "activity_id",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "source_review_row",
             "properties",
             "source_requirement",
             "properties",
             "activity_id",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "source_review_row",
             "properties",
             "source_resource_suppression",
             "properties",
             "id",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "source_review_row",
             "properties",
             "source_link_capacity",
             "properties",
             "ground_station_id",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "source_review_row",
             "properties",
             "source_timeline_diff",
             "properties",
             "timeline_id",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "source_review_row",
             "properties",
             "source_command_window",
             "properties",
             "activity_id",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "source_review_row",
             "properties",
             "source_maneuver_review",
             "properties",
             "maneuver_id",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "source_review_row",
             "properties",
             "source_ranking_comparison",
             "properties",
             "scenario_id",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "source_review_row",
             "properties",
             "source_contention_group",
             "properties",
             "ground_station_id",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "source_review_row",
             "properties",
             "source_station_calendar_review",
             "properties",
             "ground_station_id",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "source_review_row",
             "properties",
             "source_feedback",
             "properties",
             "activity_id",
             "pattern"
           ]) == stable_id_pattern

    Enum.each(
      [
        "contact_success_factor",
        "command_success_factor",
        "observation_success_factor",
        "maneuver_success_factor",
        "cloud_cover_fraction",
        "planned_cloud_cover_fraction",
        "realized_cloud_cover_fraction",
        "blur_score",
        "planned_blur_score",
        "realized_blur_score"
      ],
      fn field ->
        assert get_in(cadence_row_schema, [
                 "properties",
                 "source_review_row",
                 "properties",
                 "source_feedback",
                 "properties",
                 field
               ]) == %{
                 "type" => "number",
                 "minimum" => 0.0,
                 "maximum" => 1.0
               }
      end
    )

    assert get_in(cadence_row_schema, [
             "properties",
             "source_review_row",
             "properties",
             "branch_event_count"
           ]) == %{"type" => "integer", "minimum" => 0}

    assert get_in(cadence_row_schema, [
             "properties",
             "source_review_row",
             "properties",
             "branch_station_calendar_provider_ids",
             "items",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "capacity_pack_group_ids",
             "items",
             "pattern"
           ]) == stable_id_pattern

    Enum.each(
      [
        "capacity_pack_min_capacity_fraction",
        "capacity_pack_max_used_fraction",
        "capacity_pack_max_required_capacity_fraction"
      ],
      fn field ->
        assert get_in(cadence_row_schema, ["properties", field]) == %{
                 "type" => "number",
                 "minimum" => 0.0,
                 "maximum" => 1.0
               }

        assert get_in(cadence_row_schema, [
                 "properties",
                 "source_review_row",
                 "properties",
                 field
               ]) == %{
                 "type" => "number",
                 "minimum" => 0.0,
                 "maximum" => 1.0
               }
      end
    )

    Enum.each(
      [
        "capacity_fraction",
        "capacity_fraction_min",
        "capacity_fraction_max",
        "used_capacity_fraction",
        "unused_capacity_fraction"
      ],
      fn field ->
        assert get_in(cadence_row_schema, ["properties", field]) == %{
                 "type" => "number",
                 "minimum" => 0.0,
                 "maximum" => 1.0
               }

        assert get_in(cadence_row_schema, [
                 "properties",
                 "source_review_row",
                 "properties",
                 field
               ]) == %{
                 "type" => "number",
                 "minimum" => 0.0,
                 "maximum" => 1.0
               }
      end
    )

    assert get_in(cadence_row_schema, [
             "properties",
             "default_required_capacity_fraction",
             "maximum"
           ]) == 1.0

    assert get_in(cadence_row_schema, [
             "properties",
             "capacity_requirement_rows",
             "items",
             "properties",
             "required_capacity_fraction",
             "maximum"
           ]) == 1.0

    assert get_in(cadence_row_schema, [
             "properties",
             "source_review_row",
             "properties",
             "capacity_pack_required_capacity_sources",
             "items",
             "type"
           ]) == "string"

    assert get_in(cadence_row_schema, [
             "properties",
             "source_review_row",
             "properties",
             "default_required_capacity_fraction",
             "maximum"
           ]) == 1.0

    operator_review_row_schema = get_in(operator_review_schema, ["properties", "rows", "items"])

    assert get_in(operator_review_row_schema, [
             "properties",
             "selected_timeline_integrity_issue_count"
           ]) == %{"type" => "integer", "minimum" => 0}

    assert get_in(operator_review_row_schema, [
             "properties",
             "source_timeline_integrity",
             "properties",
             "timeline_integrity_issue_types",
             "items",
             "enum"
           ]) == OrbitalDynamics.Timeline.capabilities().timeline_integrity_issue_types

    assert get_in(operator_review_row_schema, [
             "properties",
             "source_timeline_diff_summary",
             "properties",
             "review_required_count"
           ]) == %{"type" => "integer", "minimum" => 0}

    assert get_in(operator_review_row_schema, [
             "properties",
             "source_timeline_diff_summary",
             "properties",
             "review_timeline_ids",
             "items",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(operator_review_row_schema, [
             "properties",
             "source_timeline_transition_application_summary",
             "properties",
             "review_required_count"
           ]) == %{"type" => "integer", "minimum" => 0}

    assert get_in(operator_review_row_schema, [
             "properties",
             "source_timeline_activity_state",
             "properties",
             "schema_contract",
             "const"
           ]) == "timeline_activity_state.v1"

    assert get_in(operator_review_row_schema, [
             "properties",
             "source_timeline_activity_state",
             "properties",
             "timeline_id",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(operator_review_row_schema, [
             "properties",
             "source_timeline_lifecycle_state",
             "properties",
             "timeline_id",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(operator_review_row_schema, [
             "properties",
             "source_timeline_lifecycle_state",
             "properties",
             "transition_decision",
             "enum"
           ]) == OrbitalDynamics.Timeline.capabilities().transition_decisions

    assert get_in(operator_review_row_schema, [
             "properties",
             "source_timeline_lifecycle_state",
             "properties",
             "invalid_activity_input_count"
           ]) == %{"type" => "integer", "minimum" => 0}

    assert get_in(operator_review_row_schema, [
             "properties",
             "source_timeline_lifecycle_state",
             "properties",
             "invalid_activity_input_reasons",
             "items",
             "type"
           ]) == "string"

    assert get_in(operator_review_row_schema, [
             "properties",
             "source_timeline_preservation",
             "properties",
             "activity_id",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(operator_review_row_schema, [
             "properties",
             "source_timeline_preservation",
             "properties",
             "timeline_preservation_status",
             "enum"
           ]) == ["clear", "preservation_required", "review_required"]

    assert get_in(operator_review_row_schema, [
             "properties",
             "source_timeline_transition_application_summary",
             "properties",
             "selected_activity_ids",
             "items",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(operator_review_row_schema, [
             "properties",
             "source_timeline_protection",
             "properties",
             "preserved_locked_or_approved_activity_ids",
             "items",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(operator_review_row_schema, ["properties", "branch_event_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(operator_review_schema, [
             "properties",
             "review_type_counts",
             "propertyNames",
             "enum"
           ]) == OrbitalDynamics.OperatorReview.capabilities().review_types

    assert get_in(operator_review_schema, [
             "properties",
             "cadence_import_status_counts",
             "propertyNames",
             "enum"
           ]) == OrbitalDynamics.OperatorReview.capabilities().cadence_import_statuses

    assert get_in(operator_review_schema, [
             "properties",
             "source_cadence_import_status_counts",
             "propertyNames",
             "enum"
           ]) == OrbitalDynamics.OperatorReview.capabilities().cadence_import_statuses

    assert get_in(operator_review_schema, [
             "properties",
             "review_queue_counts",
             "additionalProperties"
           ]) == %{"type" => "integer", "minimum" => 0}

    assert get_in(operator_review_row_schema, [
             "properties",
             "branch_station_calendar_provider_ids",
             "items",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(operator_review_row_schema, [
             "properties",
             "capacity_pack_total_required_capacity_fraction",
             "minimum"
           ]) == 0.0

    Enum.each(
      [
        "capacity_pack_min_capacity_fraction",
        "capacity_pack_max_used_fraction",
        "capacity_pack_max_required_capacity_fraction",
        "capacity_fraction",
        "capacity_fraction_min",
        "capacity_fraction_max",
        "used_capacity_fraction",
        "unused_capacity_fraction"
      ],
      fn field ->
        assert get_in(operator_review_row_schema, ["properties", field]) == %{
                 "type" => "number",
                 "minimum" => 0.0,
                 "maximum" => 1.0
               }
      end
    )

    assert get_in(operator_review_row_schema, [
             "properties",
             "default_required_capacity_fraction",
             "maximum"
           ]) == 1.0

    assert get_in(operator_review_row_schema, [
             "properties",
             "capacity_pack_required_capacity_sources",
             "items",
             "type"
           ]) == "string"

    Enum.each(
      [
        "total_battery_energy_consumed_wh",
        "total_battery_energy_generated_wh",
        "net_battery_energy_delta_wh",
        "peak_battery_overuse_wh"
      ],
      fn field ->
        assert get_in(operator_review_row_schema, ["properties", field, "type"]) == "number"

        assert get_in(operator_review_row_schema, [
                 "properties",
                 "source_resource_projection",
                 "properties",
                 field,
                 "type"
               ]) == "number"
      end
    )

    Enum.each(
      [
        "branch_image_quality_min_score",
        "branch_cloud_cover_max_fraction",
        "branch_blur_max_score"
      ],
      fn field ->
        assert get_in(cadence_row_schema, ["properties", field]) == %{
                 "type" => "number",
                 "minimum" => 0.0,
                 "maximum" => 1.0
               }

        assert get_in(cadence_row_schema, [
                 "properties",
                 "source_review_row",
                 "properties",
                 field
               ]) == %{
                 "type" => "number",
                 "minimum" => 0.0,
                 "maximum" => 1.0
               }
      end
    )

    assert get_in(cadence_row_schema, [
             "properties",
             "branch_image_quality_statuses",
             "items",
             "type"
           ]) == "string"

    assert get_in(cadence_row_schema, [
             "properties",
             "import_activity_context",
             "properties",
             "activity_id",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "source_activity_context",
             "properties",
             "lighting_condition",
             "type"
           ]) == "string"

    assert get_in(cadence_row_schema, [
             "properties",
             "source_activity_context",
             "properties",
             "observation_objective_ids",
             "items",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "source_activity_context",
             "properties",
             "collection_latency_objective_count",
             "type"
           ]) == "integer"

    assert get_in(cadence_row_schema, [
             "properties",
             "source_activity_context",
             "properties",
             "dependency_activity_ids",
             "items",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "source_activity_context",
             "properties",
             "exclusive_with_timeline_ids",
             "items",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "source_activity_context",
             "properties",
             "timeline_integrity_issues",
             "items",
             "type"
           ]) == "object"

    assert get_in(cadence_row_schema, [
             "properties",
             "import_activity_context",
             "properties",
             "link_margin_db",
             "type"
           ]) == "number"

    assert get_in(cadence_row_schema, [
             "properties",
             "import_activity_context",
             "properties",
             "carrier_lock",
             "type"
           ]) == "boolean"

    assert get_in(cadence_row_schema, [
             "properties",
             "import_activity_context",
             "properties",
             "station_calendar_provider_entry_id",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "import_activity_context",
             "properties",
             "battery_state_of_charge",
             "type"
           ]) == "number"

    assert get_in(cadence_row_schema, [
             "properties",
             "import_activity_context",
             "properties",
             "blur_score"
           ]) == %{"type" => "number", "minimum" => 0.0, "maximum" => 1.0}

    assert get_in(cadence_row_schema, [
             "properties",
             "import_activity_context",
             "properties",
             "image_quality_score"
           ]) == %{"type" => "number", "minimum" => 0.0, "maximum" => 1.0}

    assert get_in(operator_review_row_schema, [
             "properties",
             "realized_activity_context",
             "properties",
             "pointing_target_id",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(operator_review_row_schema, [
             "properties",
             "realized_activity_context",
             "properties",
             "thermal_margin_c",
             "type"
           ]) == "number"

    assert get_in(operator_review_row_schema, [
             "properties",
             "realized_activity_context",
             "properties",
             "blur_score"
           ]) == %{"type" => "number", "minimum" => 0.0, "maximum" => 1.0}

    assert get_in(operator_review_row_schema, [
             "properties",
             "realized_activity_context",
             "properties",
             "image_quality_score"
           ]) == %{"type" => "number", "minimum" => 0.0, "maximum" => 1.0}

    assert get_in(cadence_row_schema, [
             "properties",
             "source_review_row",
             "properties",
             "branch_image_quality_sources",
             "items",
             "type"
           ]) == "string"

    assert get_in(cadence_row_schema, [
             "properties",
             "source_review_row",
             "properties",
             "lighting_condition_match_status",
             "type"
           ]) == "string"

    assert get_in(cadence_row_schema, [
             "properties",
             "source_review_row",
             "properties",
             "lighting_confidence",
             "type"
           ]) == ["number", "string"]

    Enum.each(["attitude_confidence", "thermal_confidence"], fn field ->
      assert get_in(cadence_row_schema, ["properties", field]) == %{
               "type" => "number",
               "minimum" => 0.0,
               "maximum" => 1.0
             }

      assert get_in(cadence_row_schema, [
               "properties",
               "source_review_row",
               "properties",
               field
             ]) == %{
               "type" => "number",
               "minimum" => 0.0,
               "maximum" => 1.0
             }

      assert get_in(operator_review_row_schema, ["properties", field]) == %{
               "type" => "number",
               "minimum" => 0.0,
               "maximum" => 1.0
             }
    end)

    thermal_row_schemas = [
      cadence_row_schema,
      get_in(cadence_row_schema, ["properties", "source_review_row"]),
      operator_review_row_schema
    ]

    Enum.each(thermal_row_schemas, fn row_schema ->
      assert get_in(row_schema, ["properties", "thermal_zone_id", "pattern"]) ==
               stable_id_pattern

      for field <- [
            "temperature_c",
            "planned_temperature_c",
            "actual_temperature_c",
            "temperature_delta_c",
            "min_operating_temperature_c",
            "max_operating_temperature_c",
            "thermal_margin_c"
          ] do
        assert get_in(row_schema, ["properties", field, "type"]) == "number"
      end

      for field <- ["thermal_status", "thermal_model", "thermal_source"] do
        assert get_in(row_schema, ["properties", field, "type"]) == "string"
      end
    end)

    eclipse_lighting_row_schemas = [
      cadence_row_schema,
      get_in(cadence_row_schema, ["properties", "source_review_row"]),
      operator_review_row_schema
    ]

    Enum.each(eclipse_lighting_row_schemas, fn row_schema ->
      for field <- [
            "eclipse_overlap_fraction",
            "planned_eclipse_overlap_fraction",
            "realized_eclipse_overlap_fraction"
          ] do
        assert get_in(row_schema, ["properties", field]) == %{
                 "type" => "number",
                 "minimum" => 0.0,
                 "maximum" => 1.0
               }
      end

      for field <- [
            "eclipse_overlap_s",
            "planned_eclipse_overlap_s",
            "realized_eclipse_overlap_s"
          ] do
        assert get_in(row_schema, ["properties", field, "type"]) == "number"
      end

      assert get_in(row_schema, ["properties", "lighting_confidence", "type"]) == [
               "number",
               "string"
             ]

      for field <- [
            "lighting_condition",
            "planned_lighting_condition",
            "realized_lighting_condition",
            "lighting_condition_match_status",
            "lighting_condition_detail",
            "lighting_condition_model",
            "lighting_detail_model"
          ] do
        assert get_in(row_schema, ["properties", field, "type"]) == "string"
      end
    end)

    observation_quality_row_schemas = [
      cadence_row_schema,
      get_in(cadence_row_schema, ["properties", "source_review_row"]),
      operator_review_row_schema
    ]

    Enum.each(observation_quality_row_schemas, fn row_schema ->
      for field <- [
            "image_quality_score",
            "planned_image_quality_score",
            "realized_image_quality_score",
            "cloud_cover_fraction",
            "planned_cloud_cover_fraction",
            "realized_cloud_cover_fraction",
            "blur_score",
            "planned_blur_score",
            "realized_blur_score"
          ] do
        assert get_in(row_schema, ["properties", field]) == %{
                 "type" => "number",
                 "minimum" => 0.0,
                 "maximum" => 1.0
               }
      end

      for field <- [
            "image_quality_score_delta",
            "cloud_cover_fraction_delta",
            "blur_score_delta"
          ] do
        assert get_in(row_schema, ["properties", field, "type"]) == "number"
      end

      for field <- [
            "image_quality_status",
            "planned_image_quality_status",
            "realized_image_quality_status",
            "image_quality_status_match_status",
            "image_quality_source"
          ] do
        assert get_in(row_schema, ["properties", field, "type"]) == "string"
      end
    end)

    feedback_maneuver_row_schemas = [
      cadence_row_schema,
      get_in(cadence_row_schema, ["properties", "source_review_row"]),
      operator_review_row_schema
    ]

    Enum.each(feedback_maneuver_row_schemas, fn row_schema ->
      assert get_in(row_schema, ["properties", "feedback_weight"]) == %{
               "type" => "number",
               "minimum" => 0.0
             }

      assert get_in(row_schema, ["properties", "maneuver_success_factor"]) == %{
               "type" => "number",
               "minimum" => 0.0,
               "maximum" => 1.0
             }

      assert get_in(row_schema, ["properties", "maneuver_success", "type"]) == "boolean"

      for field <- [
            "feedback_weight_source",
            "maneuver_result",
            "maneuver_success_factor_source"
          ] do
        assert get_in(row_schema, ["properties", field, "type"]) == "string"
      end
    end)

    link_row_schemas = [
      cadence_row_schema,
      get_in(cadence_row_schema, ["properties", "source_review_row"]),
      operator_review_row_schema
    ]

    Enum.each(link_row_schemas, fn row_schema ->
      for field <- [
            "link_protocol",
            "planned_link_protocol",
            "realized_link_protocol",
            "link_protocol_match_status",
            "frequency_band",
            "planned_frequency_band",
            "realized_frequency_band",
            "frequency_band_match_status",
            "modulation",
            "planned_modulation",
            "realized_modulation",
            "modulation_match_status",
            "coding_scheme",
            "planned_coding_scheme",
            "realized_coding_scheme",
            "coding_scheme_match_status",
            "polarization",
            "planned_polarization",
            "realized_polarization",
            "polarization_match_status",
            "link_quality_status",
            "planned_link_quality_status",
            "realized_link_quality_status"
          ] do
        assert get_in(row_schema, ["properties", field, "type"]) == "string"
      end

      for field <- [
            "data_rate_mbps",
            "downlink_rate_mbps",
            "data_rate_mb_s",
            "downlink_rate_mb_s",
            "actual_data_rate_mbps",
            "actual_downlink_rate_mbps",
            "actual_data_rate_mb_s",
            "actual_downlink_rate_mb_s",
            "delivered_rate_mbps",
            "received_rate_mbps",
            "delivered_rate_mb_s",
            "received_rate_mb_s",
            "actual_duration_s",
            "actual_contact_duration_s",
            "contact_duration_s",
            "planned_data_rate_mbps",
            "realized_data_rate_mbps",
            "data_rate_delta_mbps",
            "link_margin_db",
            "planned_link_margin_db",
            "realized_link_margin_db",
            "link_margin_delta_db",
            "snr_db",
            "planned_snr_db",
            "realized_snr_db",
            "snr_delta_db",
            "eb_no_db",
            "planned_eb_no_db",
            "realized_eb_no_db",
            "eb_no_delta_db"
          ] do
        assert get_in(row_schema, ["properties", field, "type"]) == "number"
      end

      for field <- [
            "carrier_lock",
            "planned_carrier_lock",
            "realized_carrier_lock",
            "symbol_lock",
            "planned_symbol_lock",
            "realized_symbol_lock"
          ] do
        assert get_in(row_schema, ["properties", field, "type"]) == "boolean"
      end
    end)

    Enum.each(["throughput_completion_fraction", "completed_fraction"], fn field ->
      assert get_in(cadence_row_schema, [
               "properties",
               "source_review_row",
               "properties",
               field
             ]) == %{
               "type" => "number",
               "minimum" => 0.0,
               "maximum" => 1.0
             }
    end)

    Enum.each(
      [
        "eclipse_overlap_fraction",
        "planned_eclipse_overlap_fraction",
        "realized_eclipse_overlap_fraction"
      ],
      fn field ->
        assert get_in(cadence_row_schema, [
                 "properties",
                 "source_review_row",
                 "properties",
                 field
               ]) == %{
                 "type" => "number",
                 "minimum" => 0.0,
                 "maximum" => 1.0
               }
      end
    )

    Enum.each(
      [
        "cloud_cover_fraction",
        "planned_cloud_cover_fraction",
        "realized_cloud_cover_fraction",
        "blur_score",
        "planned_blur_score",
        "realized_blur_score",
        "image_quality_score",
        "planned_image_quality_score",
        "realized_image_quality_score",
        "bit_error_rate",
        "planned_bit_error_rate",
        "realized_bit_error_rate",
        "packet_loss_rate",
        "planned_packet_loss_rate",
        "realized_packet_loss_rate",
        "frame_loss_rate",
        "planned_frame_loss_rate",
        "realized_frame_loss_rate"
      ],
      fn field ->
        assert get_in(cadence_row_schema, ["properties", field]) == %{
                 "type" => "number",
                 "minimum" => 0.0,
                 "maximum" => 1.0
               }

        assert get_in(cadence_row_schema, [
                 "properties",
                 "source_review_row",
                 "properties",
                 field
               ]) == %{
                 "type" => "number",
                 "minimum" => 0.0,
                 "maximum" => 1.0
               }

        assert get_in(operator_review_row_schema, ["properties", field]) == %{
                 "type" => "number",
                 "minimum" => 0.0,
                 "maximum" => 1.0
               }
      end
    )

    assert get_in(cadence_row_schema, [
             "properties",
             "source_review_row",
             "properties",
             "import_activity_context",
             "properties",
             "timeline_id",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "source_review_row",
             "properties",
             "source_branch_comparison",
             "properties",
             "first_resource_pressure_station_calendar_provider_id",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "source_branch_comparison",
             "properties",
             "first_resource_pressure_station_calendar_provider_entry_id",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "source_branch_comparison",
             "properties",
             "downlink_completion_planned_contacts"
           ]) == %{"type" => "integer", "minimum" => 0}

    assert get_in(cadence_row_schema, [
             "properties",
             "source_branch_comparison",
             "properties",
             "coverage_observed_target_count"
           ]) == %{"type" => "integer", "minimum" => 0}

    Enum.each(["downlink_completion_ratio", "observation_success_factor"], fn field ->
      assert get_in(cadence_row_schema, [
               "properties",
               "source_branch_comparison",
               "properties",
               field
             ]) == %{"type" => "number", "minimum" => 0.0, "maximum" => 1.0}

      assert get_in(operator_review_row_schema, [
               "properties",
               "source_branch_comparison",
               "properties",
               field
             ]) == %{"type" => "number", "minimum" => 0.0, "maximum" => 1.0}
    end)

    assert get_in(cadence_row_schema, [
             "properties",
             "source_review_row",
             "properties",
             "source_branch_comparison",
             "properties",
             "downlink_completion_required_contacts"
           ]) == %{"type" => "integer", "minimum" => 0}

    assert get_in(cadence_row_schema, [
             "properties",
             "source_review_row",
             "properties",
             "source_branch_comparison",
             "properties",
             "revisit_count"
           ]) == %{"type" => "integer", "minimum" => 0}

    Enum.each(["downlink_completion_ratio", "observation_success_factor"], fn field ->
      assert get_in(cadence_row_schema, [
               "properties",
               "source_review_row",
               "properties",
               "source_branch_comparison",
               "properties",
               field
             ]) == %{"type" => "number", "minimum" => 0.0, "maximum" => 1.0}
    end)

    assert get_in(cadence_row_schema, [
             "properties",
             "source_review_row",
             "properties",
             "source_window_lineage",
             "properties",
             "source_window_id",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "source_review_row",
             "properties",
             "source_timeline_application",
             "properties",
             "source_timeline_diff",
             "properties",
             "diff_status",
             "enum"
           ]) == ["added", "removed", "changed", "unchanged"]

    assert get_in(cadence_row_schema, [
             "properties",
             "source_review_row",
             "properties",
             "source_timeline_diff_summary",
             "properties",
             "review_required_count"
           ]) == %{"type" => "integer", "minimum" => 0}

    assert get_in(cadence_row_schema, [
             "properties",
             "source_review_row",
             "properties",
             "source_timeline_diff_summary",
             "properties",
             "review_timeline_ids",
             "items",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "source_review_row",
             "properties",
             "source_timeline_transition_application_summary",
             "properties",
             "review_required_count"
           ]) == %{"type" => "integer", "minimum" => 0}

    assert get_in(cadence_row_schema, [
             "properties",
             "source_review_row",
             "properties",
             "source_timeline_transition_application_summary",
             "properties",
             "review_activity_ids",
             "items",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "source_review_row",
             "properties",
             "source_timeline_integrity",
             "properties",
             "timeline_integrity_issue_types",
             "items",
             "enum"
           ]) == OrbitalDynamics.Timeline.capabilities().timeline_integrity_issue_types

    assert get_in(cadence_row_schema, [
             "properties",
             "source_review_row",
             "properties",
             "source_timeline_protection",
             "properties",
             "preserved_locked_or_approved_activity_ids",
             "items",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "source_review_row",
             "properties",
             "source_timeline_activity_state",
             "properties",
             "schema_contract",
             "const"
           ]) == "timeline_activity_state.v1"

    assert get_in(cadence_row_schema, [
             "properties",
             "source_review_row",
             "properties",
             "source_timeline_activity_state",
             "properties",
             "timeline_id",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "source_review_row",
             "properties",
             "source_timeline_lifecycle_state",
             "properties",
             "timeline_id",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "source_review_row",
             "properties",
             "source_timeline_preservation",
             "properties",
             "activity_id",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "source_review_row",
             "properties",
             "source_candidate_rejection",
             "properties",
             "candidate_id",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "source_review_row",
             "properties",
             "source_candidate_rejection",
             "properties",
             "primary_rejection_reason",
             "enum"
           ]) == OrbitalDynamics.Timeline.capabilities().candidate_rejection_reasons

    assert get_in(cadence_row_schema, [
             "properties",
             "source_review_row",
             "properties",
             "source_timeline_dependency_impact",
             "properties",
             "scope",
             "enum"
           ]) == ["source", "replacement"]

    assert get_in(cadence_row_schema, [
             "properties",
             "source_review_row",
             "properties",
             "source_timeline_identity",
             "properties",
             "timeline_id",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "source_review_row",
             "properties",
             "replacement_timeline_identity",
             "properties",
             "timeline_id",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(cadence_row_schema, [
             "properties",
             "source_review_row",
             "properties",
             "timeline_link",
             "properties",
             "source_timeline_id",
             "pattern"
           ]) == stable_id_pattern

    assert {:ok, refresh_schema} = Schema.json_schema("candidate_refresh.v1")

    assert get_in(refresh_schema, ["properties", "refresh_id", "pattern"]) ==
             stable_id_pattern

    assert get_in(refresh_schema, [
             "properties",
             "operational_feedback",
             "properties",
             "image_quality_score",
             "additionalProperties",
             "maximum"
           ]) == 1.0

    assert get_in(refresh_schema, [
             "properties",
             "operational_feedback",
             "properties",
             "image_quality_status",
             "additionalProperties",
             "type"
           ]) == "string"

    assert {:ok, allocation_schema} = Schema.json_schema("contact_allocation_report.v1")

    Enum.each(
      ["invalid_contact_input_ids", "resource_blocked_contact_ids", "status_blocked_contact_ids"],
      fn field ->
        assert get_in(allocation_schema, ["properties", field, "items", "pattern"]) ==
                 stable_id_pattern
      end
    )

    allocation_row_schema = get_in(allocation_schema, ["properties", "rows", "items"])

    assert get_in(allocation_row_schema, [
             "properties",
             "station_calendar_provider_id",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(allocation_row_schema, [
             "properties",
             "station_calendar_provider_entry_id",
             "pattern"
           ]) == stable_id_pattern

    pack_group_schema =
      get_in(allocation_schema, ["properties", "reduced_capacity_pack_groups", "items"])

    assert get_in(pack_group_schema, ["properties", "contention_group_id", "pattern"]) ==
             stable_id_pattern

    assert get_in(pack_group_schema, [
             "properties",
             "capacity_packed_contact_ids",
             "items",
             "pattern"
           ]) ==
             stable_id_pattern

    assert get_in(pack_group_schema, [
             "properties",
             "default_required_capacity_fraction",
             "type"
           ]) == "number"

    row_schema = get_in(allocation_schema, ["properties", "rows", "items"])

    assert get_in(row_schema, ["required"]) == [
             "id",
             "contact_id",
             "allocation_status",
             "effective_allocation_status"
           ]

    assert get_in(allocation_schema, [
             "properties",
             "allocation_status_counts",
             "propertyNames",
             "enum"
           ]) == OrbitalDynamics.Communications.ContactAllocation.capabilities().row_statuses

    assert get_in(allocation_schema, ["properties", "input_contact_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(allocation_schema, ["properties", "invalid_contact_input_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(allocation_schema, [
             "properties",
             "effective_allocation_status_counts",
             "propertyNames",
             "enum"
           ]) ==
             OrbitalDynamics.Communications.ContactAllocation.capabilities().effective_row_statuses

    assert get_in(allocation_schema, [
             "properties",
             "allocation_reason_counts",
             "additionalProperties"
           ]) == %{"type" => "integer", "minimum" => 0}

    Enum.each(
      ["reduced_capacity_pack_status_counts", "capacity_pack_status_counts"],
      fn field ->
        assert get_in(allocation_schema, [
                 "properties",
                 field,
                 "additionalProperties"
               ]) == %{"type" => "integer", "minimum" => 0}
      end
    )

    assert get_in(allocation_schema, [
             "properties",
             "capacity_pack_contact_ids_by_status",
             "additionalProperties",
             "items",
             "pattern"
           ]) == stable_id_pattern

    Enum.each(
      [
        "station_pressure_contact_ids_by_ground_station_id",
        "station_pressure_contact_ids_by_availability",
        "station_pressure_contact_ids_by_precedence_availability",
        "station_pressure_contact_ids_by_precedence_rank"
      ],
      fn field ->
        assert get_in(allocation_schema, [
                 "properties",
                 field,
                 "additionalProperties",
                 "items",
                 "pattern"
               ]) == stable_id_pattern
      end
    )

    assert get_in(row_schema, ["properties", "allocation_status", "enum"]) ==
             OrbitalDynamics.Communications.ContactAllocation.capabilities().row_statuses

    assert get_in(row_schema, ["properties", "effective_allocation_status", "enum"]) ==
             OrbitalDynamics.Communications.ContactAllocation.capabilities().effective_row_statuses

    assert get_in(row_schema, ["properties", "required_capacity_fraction"]) == %{
             "type" => "number",
             "minimum" => 0.0,
             "maximum" => 1.0
           }

    assert get_in(row_schema, ["properties", "required_capacity_fraction_source", "type"]) ==
             "string"

    assert get_in(row_schema, ["properties", "actual_throughput_mb", "type"]) == "number"

    assert get_in(row_schema, [
             "properties",
             "actual_data_rate_throughput_derivation",
             "type"
           ]) == "object"

    assert get_in(row_schema, [
             "properties",
             "actual_data_rate_throughput_derivation",
             "properties",
             "actual_data_rate_mbps",
             "type"
           ]) == "number"

    assert get_in(row_schema, ["properties", "completed_fraction", "maximum"]) == 1.0

    assert get_in(row_schema, ["properties", "required_downlink_mb", "minimum"]) == 0.0

    assert get_in(row_schema, ["properties", "downlink_completion_ratio", "maximum"]) == 1.0

    assert get_in(row_schema, ["properties", "downlink_completion_sources", "items", "type"]) ==
             "string"

    assert get_in(row_schema, ["properties", "contact_success", "type"]) == "boolean"

    assert get_in(row_schema, ["properties", "contact_success_factor", "maximum"]) == 1.0

    assert get_in(row_schema, ["properties", "command_success", "type"]) == "boolean"

    assert get_in(row_schema, ["properties", "command_success_factor", "maximum"]) == 1.0

    assert get_in(row_schema, ["properties", "station_calendar_entry_id", "pattern"]) ==
             stable_id_pattern

    assert get_in(row_schema, ["properties", "station_calendar_directions", "items", "type"]) ==
             "string"

    assert get_in(row_schema, ["properties", "provenance", "type"]) == "object"

    assert get_in(row_schema, [
             "properties",
             "station_calendar_overlap_entry_ids",
             "items",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(row_schema, [
             "properties",
             "station_calendar_reservation_ids",
             "items",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(row_schema, [
             "properties",
             "station_calendar_reservation_overlap_count",
             "minimum"
           ]) == 0

    assert get_in(row_schema, ["properties", "station_calendar_entry_ambiguous", "type"]) ==
             "boolean"

    assert get_in(row_schema, ["properties", "station_calendar_ambiguous_entry_count", "minimum"]) ==
             0

    assert get_in(row_schema, [
             "properties",
             "station_calendar_ambiguous_entry_ids",
             "items",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(row_schema, ["properties", "station_contention_status", "type"]) ==
             "string"

    assert get_in(row_schema, ["properties", "source_resource_suppression", "type"]) ==
             "object"

    assert get_in(row_schema, ["properties", "antenna_available", "type"]) == "boolean"

    assert {:ok, validation_schema} = Schema.json_schema("validation_reference_report.v1")

    assert get_in(validation_schema, ["properties", "fixture_id", "pattern"]) ==
             stable_id_pattern

    assert get_in(validation_schema, ["properties", "model_id", "pattern"]) ==
             stable_id_pattern
  end

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
