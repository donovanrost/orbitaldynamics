defmodule OrbitalDynamics.TimelineTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.MissionPlan.Activity
  alias OrbitalDynamics.{CadenceImport, OperatorReview, Schema, Timeline, TimelineFeedback}

  test "declares operational timeline capabilities" do
    assert %{
             artifact_contract: "operational_timeline_report.v1",
             diff_artifact_contract: "timeline_diff_report.v1",
             diff_summary_artifact_contract: "timeline_diff_summary.v1",
             integrity_report_artifact_contract: "timeline_integrity_report.v1",
             dependency_impact_summary_artifact_contract: "timeline_dependency_impact_summary.v1",
             publication_summary_artifact_contract: "timeline_publication_summary.v1",
             activity_state_artifact_contract: "timeline_activity_state.v1",
             activity_precondition_summary_artifact_contract:
               "timeline_activity_precondition_summary.v1",
             activity_status_state_artifact_contract: "timeline_activity_status_state.v1",
             activity_approval_state_artifact_contract: "timeline_activity_approval_state.v1",
             activity_lifecycle_state_artifact_contract: "timeline_activity_lifecycle_state.v1",
             preservation_report_artifact_contract: "timeline_preservation_report.v1",
             preservation_status_artifact_contract: "timeline_preservation_status.v1",
             lifecycle_state_summary_artifact_contract: "timeline_lifecycle_state_summary.v1",
             transition_application_artifact_contract:
               "timeline_transition_application_report.v1",
             transition_application_summary_artifact_contract:
               "timeline_transition_application_summary.v1",
             candidate_rejection_artifact_contract: "candidate_rejection_report.v1",
             validation_level: :artifact_contract,
             classification_counts: counts,
             identity_fields: identity_fields,
             activity_stable_identity_paths: activity_stable_identity_paths,
             row_semantics: row_semantics,
             supported_activity_types: supported_activity_types,
             operational_kinds: operational_kinds,
             activity_statuses: activity_statuses,
             approval_statuses: approval_statuses,
             provider_direction_aliases: provider_direction_aliases,
             activity_status_aliases: activity_status_aliases,
             approval_status_aliases: approval_status_aliases,
             provider_result_map_value_keys: provider_result_map_value_keys,
             activity_lighting_field_aliases: activity_lighting_field_aliases,
             unit_interval_activity_field_aliases: unit_interval_activity_field_aliases,
             required_operator_actions: required_operator_actions,
             timeline_diff_required_operator_actions: timeline_diff_required_operator_actions,
             transition_decision_required_operator_actions:
               transition_decision_required_operator_actions,
             transition_decisions: transition_decisions,
             transition_application_statuses: transition_application_statuses,
             lifecycle_transition_types: lifecycle_transition_types,
             status_transition_categories: status_transition_categories,
             approval_transition_categories: approval_transition_categories,
             activity_precondition_statuses: activity_precondition_statuses,
             activity_precondition_types: activity_precondition_types,
             activity_precondition_row_semantics: activity_precondition_row_semantics,
             diff_helpers: diff_helpers,
             timeline_integrity_helpers: timeline_integrity_helpers,
             lifecycle_preservation_helpers: lifecycle_preservation_helpers,
             normalization_helpers: normalization_helpers,
             candidate_rejection_helpers: candidate_rejection_helpers,
             transition_helpers: transition_helpers,
             public_facades: public_facades,
             cadence_import_statuses: cadence_import_statuses,
             execution_boundaries: execution_boundaries,
             timeline_diff_compare_fields: timeline_diff_compare_fields,
             timeline_diff_activity_context_compare_fields:
               timeline_diff_activity_context_compare_fields,
             timeline_integrity_issue_types: timeline_integrity_issue_types,
             dependency_impact_summary_fields: dependency_impact_summary_fields,
             dependency_impact_statuses: dependency_impact_statuses,
             publication_summary_fields: publication_summary_fields,
             publication_dependency_impact_statuses: publication_dependency_impact_statuses,
             publication_statuses: publication_statuses,
             candidate_rejection_reasons: candidate_rejection_reasons,
             candidate_rejection_station_capacity_fraction_paths:
               candidate_rejection_station_capacity_fraction_paths,
             candidate_rejection_station_capacity_value_paths:
               candidate_rejection_station_capacity_value_paths,
             candidate_rejection_actions: candidate_rejection_actions,
             command_contact_directions: command_contact_directions,
             known_limits: known_limits
           } = Timeline.capabilities()

    assert "contact" in supported_activity_types
    assert "attitude" in supported_activity_types
    assert "activity" in operational_kinds
    assert "command" in operational_kinds
    assert "contact" in operational_kinds
    assert "attitude" in operational_kinds
    assert "observation" in operational_kinds
    assert "draft" in activity_statuses
    assert "executing" in activity_statuses
    assert "completed" in activity_statuses
    assert "failed" in activity_statuses
    assert "blocked_by_policy" in activity_statuses
    assert provider_direction_aliases["cmd"] == "command"
    assert provider_direction_aliases["commands"] == "command"
    assert provider_direction_aliases["s_band_command"] == "command"
    assert provider_direction_aliases["dl"] == "downlink"
    assert provider_direction_aliases["downlinking"] == "downlink"
    assert provider_direction_aliases["track_ing"] == "tracking"
    assert provider_direction_aliases["tracking_pass"] == "tracking"
    assert provider_direction_aliases["healthcheck"] == "health_check"
    assert Timeline.normalize_contact_direction("S-Band Command") == "command"
    assert Timeline.normalize_contact_direction(:dl) == "downlink"
    assert Timeline.normalize_contact_direction("Health Check Window") == "health_check"
    assert Timeline.normalize_contact_direction("Ka-Band Special") == "ka_band_special"
    assert Timeline.normalize_contact_direction("nil") == nil

    for {provider_alias, canonical_direction} <- provider_direction_aliases do
      assert Timeline.normalize_contact_direction(provider_alias) == canonical_direction
    end

    assert "result" in provider_result_map_value_keys
    assert "provider_status" in provider_result_map_value_keys
    assert "provider_outcome" in provider_result_map_value_keys
    assert "diagnostics" in provider_result_map_value_keys
    assert activity_status_aliases["succeeded"] == "completed"
    assert activity_status_aliases["in_progress"] == "executing"
    assert activity_status_aliases["timed_out"] == "failed"
    assert approval_status_aliases["review_required"] == "operator_review_required"
    assert approval_status_aliases["policy_blocked"] == "blocked_by_policy"
    assert approval_status_aliases["no_review_required"] == "not_required"

    assert %{
             field: "lighting_condition",
             aliases: ["lighting_condition", "lighting_status"]
           } in activity_lighting_field_aliases

    assert %{
             field: "lighting_condition_detail",
             aliases: ["lighting_condition_detail", "lighting_detail"]
           } in activity_lighting_field_aliases

    assert %{
             field: "lighting_condition_model",
             aliases: ["lighting_condition_model", "lighting_model"]
           } in activity_lighting_field_aliases

    assert %{
             field: "lighting_detail_model",
             aliases: ["lighting_detail_model", "lighting_detail_source"]
           } in activity_lighting_field_aliases

    assert %{
             field: "lighting_confidence",
             aliases: ["lighting_confidence", "lighting_confidence_label"]
           } in activity_lighting_field_aliases

    assert %{field: "contact_success_factor", aliases: ["contact_success_factor"]} in unit_interval_activity_field_aliases

    assert %{
             field: "cloud_cover_fraction",
             aliases: ["cloud_cover_fraction", "cloud_fraction", "cloud_cover"]
           } in unit_interval_activity_field_aliases

    assert %{
             field: "storage_margin",
             aliases: ["storage_margin", "storage_capacity_margin"]
           } in unit_interval_activity_field_aliases

    assert %{
             field: "battery_state_of_charge",
             aliases: ["battery_state_of_charge", "battery_soc"]
           } in unit_interval_activity_field_aliases

    assert "approved" in approval_statuses
    assert "operator_review_required" in approval_statuses
    assert "blocked_by_policy" in approval_statuses
    assert "not_required" in approval_statuses
    assert "rejected" in approval_statuses
    assert "monitor_activity" in required_operator_actions
    assert "prepare_cadence_import" in required_operator_actions
    assert "review_invalid_activity_input" in required_operator_actions
    assert "review_timeline_integrity" in required_operator_actions
    assert "review_added_activity" in timeline_diff_required_operator_actions
    assert "review_removed_activity" in timeline_diff_required_operator_actions
    assert "review_removed_executed_activity" in timeline_diff_required_operator_actions
    assert "review_changed_protected_activity" in timeline_diff_required_operator_actions
    assert "record_timeline_change" in timeline_diff_required_operator_actions
    assert "review_activity_transition" in transition_decision_required_operator_actions
    assert transition_decisions == ["none", "preserve_source", "record", "review"]
    assert "operator_review_required" in transition_application_statuses
    assert "source_preserved_pending_review" in transition_application_statuses
    assert "replacement_recorded" in transition_application_statuses
    assert lifecycle_transition_types == ["added", "changed", "removed"]
    assert "status_added" in status_transition_categories
    assert "execution_recorded" in status_transition_categories
    assert "approval_review_required" in approval_transition_categories
    assert "protected_approval_removed" in approval_transition_categories
    assert activity_precondition_statuses == ["blocked", "clear", "review_required"]
    assert "payload_unavailable" in activity_precondition_types
    assert "fuel_margin_depleted" in activity_precondition_types
    assert "subsystem_state_required" in activity_precondition_types
    assert :precondition_rows in activity_precondition_row_semantics
    assert diff_helpers == [:diff_report, :diff_summary]
    assert :integrity_report in timeline_integrity_helpers
    assert :dependency_impact_summary in timeline_integrity_helpers
    assert :publication_summary in timeline_integrity_helpers
    assert :preservation_status in lifecycle_preservation_helpers
    assert :preservation_report in lifecycle_preservation_helpers
    assert :normalize_activity in normalization_helpers
    assert :normalize_activities in normalization_helpers
    assert :timeline_identity in normalization_helpers
    assert :activity_precondition_summary in normalization_helpers
    assert :activity_context in normalization_helpers
    assert :candidate_rejection_report in candidate_rejection_helpers
    assert :activity_transition in transition_helpers
    assert :activity_lifecycle_state in transition_helpers
    assert :lifecycle_state_summary in transition_helpers
    assert :activity_status_state in transition_helpers
    assert :activity_approval_state in transition_helpers
    assert :status_transition in transition_helpers
    assert :approval_transition in transition_helpers
    assert :transition_activity_status in transition_helpers
    assert :transition_activity_approval_status in transition_helpers
    assert :apply_lifecycle_event in transition_helpers
    assert :protection_decision in transition_helpers
    assert :transition_decision in transition_helpers
    assert :transition_application in transition_helpers
    assert :transition_application_summary in transition_helpers
    assert :transition_application_report in transition_helpers
    assert :transition_selected_activities in transition_helpers
    assert :normalize_timeline_activity in public_facades
    assert :normalize_timeline_activities in public_facades
    assert :timeline_activity_transition in public_facades
    assert :timeline_activity_context in public_facades
    assert :timeline_activity_precondition_summary in public_facades
    assert :timeline_identity in public_facades
    assert :timeline_preservation_report in public_facades
    assert :timeline_dependency_impact_summary in public_facades
    assert :timeline_publication_summary in public_facades
    assert :timeline_diff_summary in public_facades
    assert :timeline_activity_state in public_facades
    assert :timeline_activity_lifecycle_state in public_facades
    assert :timeline_lifecycle_state_summary in public_facades
    assert :timeline_activity_status_state in public_facades
    assert :timeline_activity_approval_state in public_facades
    assert :timeline_status_transition in public_facades
    assert :timeline_approval_transition in public_facades
    assert :timeline_transition_activity_status in public_facades
    assert :timeline_transition_activity_status! in public_facades
    assert :timeline_transition_activity_approval_status in public_facades
    assert :timeline_transition_activity_approval_status! in public_facades
    assert :timeline_apply_lifecycle_event in public_facades
    assert :timeline_apply_lifecycle_event! in public_facades
    assert :timeline_protection_decision in public_facades
    assert :timeline_preservation_status in public_facades
    assert :timeline_integrity_report in public_facades
    assert :candidate_rejection_report in public_facades
    assert :timeline_transition_decision in public_facades
    assert :timeline_transition_application in public_facades
    assert :timeline_transition_application_summary in public_facades
    assert :timeline_transition_application_report in public_facades
    assert :timeline_transition_selected_activities in public_facades
    assert "present" in cadence_import_statuses
    assert "invalid" in cadence_import_statuses
    assert "missing" in cadence_import_statuses
    assert "not_applicable" in cadence_import_statuses
    assert execution_boundaries == ["planned_not_commanded"]
    assert "status" in timeline_diff_compare_fields
    assert "approval_status" in timeline_diff_compare_fields
    assert "allow_overlap" in timeline_diff_compare_fields
    assert "station_reservation_id" in timeline_diff_compare_fields
    assert "station_reservation_expires_at_s" in timeline_diff_compare_fields
    assert "station_calendar_reservation_expires_at_s" in timeline_diff_compare_fields
    assert "dependency_activity_ids" in timeline_diff_compare_fields
    assert "maneuver_success_factor" in timeline_diff_compare_fields
    assert "attitude_status" in timeline_diff_activity_context_compare_fields
    assert "actual_data_rate_mbps" in timeline_diff_activity_context_compare_fields
    assert "thermal_margin_c" in timeline_diff_activity_context_compare_fields
    assert "dependency_cycle" in timeline_integrity_issue_types
    assert "dependency_order_violation" in timeline_integrity_issue_types
    assert "exclusivity_overlap" in timeline_integrity_issue_types
    assert "invalid_activity_input" in timeline_integrity_issue_types
    assert "missing_dependency_activity" in timeline_integrity_issue_types
    assert "source_dependent_activity_ids" in dependency_impact_summary_fields
    assert "source_dependent_timeline_ids" in dependency_impact_summary_fields
    assert "replacement_dependent_activity_ids" in dependency_impact_summary_fields
    assert "replacement_dependent_timeline_ids" in dependency_impact_summary_fields
    assert "impacted_dependency_activity_ids" in dependency_impact_summary_fields
    assert "impacted_dependency_timeline_ids" in dependency_impact_summary_fields
    assert "impacted_exclusive_with_activity_ids" in dependency_impact_summary_fields
    assert "impacted_exclusive_with_timeline_ids" in dependency_impact_summary_fields
    assert dependency_impact_statuses == ["clear", "review_required"]
    assert "publication_sequence" in publication_summary_fields
    assert "invalidated_downstream_product_ids" in publication_summary_fields
    assert "dependency_impact_row_count" in publication_summary_fields
    assert "changed_field_counts" in publication_summary_fields
    assert "timeline_ids_by_changed_field" in publication_summary_fields
    assert publication_dependency_impact_statuses == ["clear", "not_evaluated", "review_required"]

    assert publication_statuses == [
             "published",
             "published_with_downstream_invalidations",
             "review_required"
           ]

    assert "station_reserved" in candidate_rejection_reasons
    assert "station_capacity_reduced" in candidate_rejection_reasons
    assert "quality_gate_failed" in candidate_rejection_reasons
    assert "invalid_candidate_input" in candidate_rejection_reasons
    assert ["capacity_fraction"] in candidate_rejection_station_capacity_fraction_paths

    assert ["metadata", "capacity_fraction"] in candidate_rejection_station_capacity_fraction_paths

    assert ["source_station_calendar_entry", "capacity_fraction"] in candidate_rejection_station_capacity_fraction_paths

    assert ["source_station_calendar_overlaps", "capacity_fraction"] in candidate_rejection_station_capacity_fraction_paths

    assert ["station_capacity_fraction"] in candidate_rejection_station_capacity_fraction_paths

    assert ["metadata", "station_capacity_fraction"] in candidate_rejection_station_capacity_fraction_paths

    assert ["capacity_pack_capacity_fraction"] in candidate_rejection_station_capacity_fraction_paths

    assert ["metadata", "capacity_pack_capacity_fraction"] in candidate_rejection_station_capacity_fraction_paths

    assert ["source_station_calendar_entry", "capacity_pack_capacity_fraction"] in candidate_rejection_station_capacity_fraction_paths

    assert ["source_station_calendar_overlaps", "capacity_pack_capacity_fraction"] in candidate_rejection_station_capacity_fraction_paths

    assert %{unit: :fraction, path: ["capacity_fraction"]} in candidate_rejection_station_capacity_value_paths

    assert %{
             unit: :fraction,
             path: ["metadata", "capacity_fraction"]
           } in candidate_rejection_station_capacity_value_paths

    assert %{unit: :fraction, path: ["station_capacity_fraction"]} in candidate_rejection_station_capacity_value_paths

    assert %{
             unit: :fraction,
             path: ["metadata", "station_capacity_fraction"]
           } in candidate_rejection_station_capacity_value_paths

    assert %{
             unit: :fraction,
             path: ["capacity_pack_capacity_fraction"]
           } in candidate_rejection_station_capacity_value_paths

    assert %{
             unit: :fraction,
             path: ["metadata", "capacity_pack_capacity_fraction"]
           } in candidate_rejection_station_capacity_value_paths

    assert %{
             unit: :fraction,
             path: ["source_station_calendar_entry", "capacity_pack_capacity_fraction"]
           } in candidate_rejection_station_capacity_value_paths

    assert %{
             unit: :fraction,
             path: ["source_station_calendar_overlaps", "capacity_pack_capacity_fraction"]
           } in candidate_rejection_station_capacity_value_paths

    assert "review_candidate_rejection" in candidate_rejection_actions
    assert "none" in candidate_rejection_actions
    assert command_contact_directions == ["command", "uplink"]
    assert :contact_count in counts
    assert :command_count in counts
    assert :timeline_id in identity_fields
    assert :spacecraft_id in identity_fields

    assert %{field: "source_window_id", path: ["source_window", "id"]} in activity_stable_identity_paths

    assert %{field: "source_window_id", path: ["metadata", "source_window_id"]} in activity_stable_identity_paths

    assert %{field: "timeline_id", path: ["metadata", "timeline_id"]} in activity_stable_identity_paths

    assert %{field: "product_id", path: ["data_product_id"]} in activity_stable_identity_paths

    assert :operational_kind_counts in row_semantics
    assert :activity_status_counts in row_semantics
    assert :activity_status_aliases in row_semantics
    assert :approval_status_aliases in row_semantics
    assert :approval_status_counts in row_semantics
    assert :activity_lighting_field_aliases in row_semantics
    assert :unit_interval_activity_field_aliases in row_semantics
    assert :activity_stable_identity_paths in row_semantics
    assert :command_contact_directions in row_semantics
    assert :required_operator_action in row_semantics
    assert :required_operator_action_counts in row_semantics
    assert :cadence_import_status in row_semantics
    assert :cadence_import_status_counts in row_semantics
    assert :cadence_import_identity in row_semantics
    assert :normalized_activity in row_semantics
    assert :activity_template_provenance in row_semantics
    assert :activity_precondition_status in row_semantics
    assert :activity_precondition_counts in row_semantics
    assert :activity_precondition_types in row_semantics
    assert :activity_precondition_rows in row_semantics
    assert :timeline_diff_compare_fields in row_semantics
    assert :timeline_diff_activity_context_compare_fields in row_semantics
    assert :timeline_diff_changed_field_counts in row_semantics
    assert :timeline_diff_summary in row_semantics
    assert :timeline_diff_summary_status_id_sets in row_semantics
    assert :activity_transition in row_semantics
    assert :transition_decision_counts in row_semantics
    assert :transition_application in row_semantics
    assert :transition_application_status in row_semantics
    assert :transition_application_status_counts in row_semantics
    assert :transition_application_summary in row_semantics
    assert :transition_application_timeline_id_sets in row_semantics
    assert :transition_application_summary_row_derived_counts in row_semantics
    assert :transition_application_report in row_semantics
    assert :status_transition_counts in row_semantics
    assert :approval_transition_counts in row_semantics
    assert :status_transition_category_counts in row_semantics
    assert :approval_transition_category_counts in row_semantics
    assert :activity_lifecycle_state in row_semantics
    assert :activity_lifecycle_state_transition_decision in row_semantics
    assert :activity_lifecycle_state_required_operator_actions in row_semantics
    assert :lifecycle_state_summary in row_semantics
    assert :lifecycle_state_summary_row_derived_counts in row_semantics
    assert :lifecycle_state_summary_transition_decision_counts in row_semantics
    assert :lifecycle_state_summary_required_operator_action_counts in row_semantics
    assert :lifecycle_state_summary_import_action_counts in row_semantics
    assert :lifecycle_state_summary_status_approval_category_counts in row_semantics
    assert :lifecycle_state_summary_timeline_id_sets in row_semantics
    assert :lifecycle_state_summary_review_routing in row_semantics
    assert :lifecycle_state_summary_duplicate_timeline_identity in row_semantics
    assert :lifecycle_state_summary_invalid_activity_input in row_semantics
    assert :candidate_rejection_report in row_semantics
    assert :candidate_rejection_status in row_semantics
    assert :candidate_rejection_reason in row_semantics
    assert :candidate_rejection_reason_counts in row_semantics
    assert :candidate_rejection_routing_id_sets in row_semantics
    assert :candidate_rejection_reason_id_sets in row_semantics
    assert :candidate_rejection_action_id_sets in row_semantics
    assert :candidate_rejection_station_capacity_value_paths in row_semantics
    assert :timeline_integrity_report in row_semantics
    assert :timeline_integrity_status in row_semantics
    assert :timeline_integrity_review_count in row_semantics
    assert :timeline_integrity_issue_count in row_semantics
    assert :timeline_integrity_issue_type_counts in row_semantics
    assert :timeline_integrity_routing_id_sets in row_semantics
    assert :timeline_integrity_issue_id_sets in row_semantics
    assert :timeline_integrity_issue_type_routing in row_semantics
    assert :timeline_integrity_action_routing in row_semantics
    assert :dependency_issue_count in row_semantics
    assert :exclusivity_issue_count in row_semantics
    assert :dependency_impact_summary in row_semantics
    assert :dependency_impact_dependent_id_sets in row_semantics
    assert :dependency_impact_impacted_source_id_sets in row_semantics
    assert :dependency_impact_impacted_dependency_id_sets in row_semantics
    assert :dependency_impact_impacted_exclusivity_id_sets in row_semantics
    assert :publication_summary in row_semantics
    assert :publication_summary_downstream_invalidation in row_semantics
    assert :publication_summary_dependency_impact in row_semantics
    assert :publication_summary_changed_field_audit in row_semantics
    assert :single_activity_transition_integrity_gate in row_semantics
    assert :lifecycle_preservation_report in row_semantics
    assert :lifecycle_preservation_status in row_semantics
    assert :preserve_activity_count in row_semantics
    assert :review_change_activity_count in row_semantics
    assert :mutable_activity_count in row_semantics
    assert :preservation_sensitive_activity_count in row_semantics
    assert :protection_decision_counts in row_semantics
    assert :protection_category_counts in row_semantics
    assert :lifecycle_preservation_routing_id_sets in row_semantics
    assert :lifecycle_preservation_category_id_sets in row_semantics
    assert :lifecycle_preservation_reason_id_sets in row_semantics
    assert :lifecycle_preservation_timeline_id_sets in row_semantics
    assert :protection_decision in row_semantics
    assert :product_identity in row_semantics
    assert :data_volume_evidence in row_semantics
    assert :link_context in row_semantics
    assert :thermal_context in row_semantics
    assert :downlink_completion_evidence in row_semantics
    assert :execution_uncertainty in row_semantics
    assert :unit_interval_activity_context_validation in row_semantics
    assert :maneuver_success_factor in row_semantics
    assert :provider_result_map_value_keys in row_semantics
    assert :terminal_exception_review in row_semantics
    assert :dependency_activity_ids in row_semantics
    assert :exclusive_with_activity_ids in row_semantics
    assert :station_reservation_context in row_semantics
    assert :invalid_activity_input_review in row_semantics
    assert :no_schedule_mutation in known_limits
    assert :no_command_execution in known_limits

    assert {:ok, schema} = Schema.json_schema("operational_timeline_report.v1")

    assert get_in(schema, ["properties", "model_limits", "const"]) == Timeline.model_limits()

    assert get_in(schema, ["properties", "model_limits", "items", "enum"]) ==
             Timeline.model_limits()

    schema_operational_kinds =
      get_in(schema, ["properties", "rows", "items", "properties", "operational_kind", "enum"])

    assert Enum.sort(schema_operational_kinds) == Enum.sort(operational_kinds)

    schema_activity_statuses =
      get_in(schema, ["properties", "rows", "items", "properties", "status", "enum"])

    assert Enum.sort(schema_activity_statuses) == Enum.sort(activity_statuses)

    assert get_in(schema, ["properties", "rows", "items", "properties", "allow_overlap"]) ==
             %{"type" => "boolean"}

    assert get_in(schema, [
             "properties",
             "rows",
             "items",
             "properties",
             "activity_context",
             "properties",
             "allow_overlap"
           ]) == %{"type" => "boolean"}

    schema_approval_statuses =
      get_in(schema, ["properties", "rows", "items", "properties", "approval_status", "enum"])

    assert Enum.sort(schema_approval_statuses) == Enum.sort(approval_statuses)

    schema_required_operator_actions =
      get_in(schema, [
        "properties",
        "rows",
        "items",
        "properties",
        "required_operator_action",
        "enum"
      ])

    assert Enum.sort(schema_required_operator_actions) == Enum.sort(required_operator_actions)

    schema_cadence_import_statuses =
      get_in(schema, [
        "properties",
        "rows",
        "items",
        "properties",
        "cadence_import_status",
        "enum"
      ])

    assert Enum.sort(schema_cadence_import_statuses) == Enum.sort(cadence_import_statuses)

    schema_execution_boundaries =
      get_in(schema, [
        "properties",
        "rows",
        "items",
        "properties",
        "execution_boundary",
        "enum"
      ])

    assert Enum.sort(schema_execution_boundaries) == Enum.sort(execution_boundaries)

    schema_timeline_integrity_issue_types =
      get_in(schema, [
        "properties",
        "rows",
        "items",
        "properties",
        "timeline_integrity_issue_types",
        "items",
        "enum"
      ])

    assert Enum.sort(schema_timeline_integrity_issue_types) ==
             Enum.sort(timeline_integrity_issue_types)

    assert get_in(schema, [
             "properties",
             "rows",
             "items",
             "properties",
             "station_calendar_provider_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(schema, [
             "properties",
             "rows",
             "items",
             "properties",
             "station_calendar_provider_entry_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert {:ok, diff_schema} = Schema.json_schema("timeline_diff_report.v1")

    assert get_in(diff_schema, ["properties", "model_limits", "const"]) == Timeline.model_limits()

    assert get_in(diff_schema, ["properties", "model_limits", "items", "enum"]) ==
             Timeline.model_limits()

    schema_timeline_diff_required_operator_actions =
      get_in(diff_schema, [
        "properties",
        "rows",
        "items",
        "properties",
        "required_operator_action",
        "enum"
      ])

    assert Enum.sort(schema_timeline_diff_required_operator_actions) ==
             Enum.sort(timeline_diff_required_operator_actions)

    assert get_in(diff_schema, [
             "properties",
             "rows",
             "items",
             "properties",
             "source_allow_overlap"
           ]) == %{"type" => "boolean"}

    assert get_in(diff_schema, [
             "properties",
             "rows",
             "items",
             "properties",
             "replacement_allow_overlap"
           ]) == %{"type" => "boolean"}

    assert {:ok, dependency_impact_schema} =
             Schema.json_schema("timeline_dependency_impact_summary.v1")

    assert get_in(dependency_impact_schema, ["properties", "dependency_impact_status", "enum"]) ==
             dependency_impact_statuses

    assert {:ok, publication_schema} = Schema.json_schema("timeline_publication_summary.v1")

    assert get_in(publication_schema, ["properties", "dependency_impact_status", "enum"]) ==
             publication_dependency_impact_statuses

    assert get_in(publication_schema, ["properties", "publication_status", "enum"]) ==
             publication_statuses
  end

  test "advertised activity-state facade preserves feedback artifact semantics" do
    planned = %{
      id: :downlink_equator,
      type: :downlink,
      status: :planned,
      metadata: %{timeline_id: :"timeline:downlink_equator"}
    }

    realized = %{
      id: :downlink_equator,
      type: :downlink,
      status: :completed,
      actual_throughput_mb: 72.0,
      metadata: %{timeline_id: :"timeline:downlink_equator"}
    }

    assert :timeline_activity_state in Timeline.capabilities().public_facades
    assert Code.ensure_loaded?(OrbitalDynamics)
    assert function_exported?(OrbitalDynamics, :timeline_activity_state, 3)

    state = TimelineFeedback.activity_state(planned, realized)

    assert %{
             "schema_contract" => "timeline_activity_state.v1",
             "model" => "artifact_only_timeline_activity_state",
             "state_status" => "matched",
             "activity_id" => "downlink_equator",
             "status_transition" => %{
               "transition_type" => "changed",
               "from" => "planned",
               "to" => "completed"
             }
           } = OrbitalDynamics.timeline_activity_state(planned, realized)

    assert OrbitalDynamics.timeline_activity_state(planned, realized) == state

    assert {:ok, %{"schema_contract" => "timeline_activity_state.v1"}} =
             Schema.validate_artifact(state)
  end

  test "preserves invalid operational timeline activity inputs for review" do
    report =
      Timeline.operational_report([
        %{
          id: :obs_valid,
          type: :observe,
          target_id: :target_a,
          starts_at_s: 10.0,
          ends_at_s: 20.0
        },
        %{
          type: :command,
          starts_at_s: 30.0,
          ends_at_s: 40.0
        },
        %{
          id: :missing_type,
          starts_at_s: 50.0,
          ends_at_s: 60.0
        }
      ])

    assert %{
             "activity_count" => 3,
             "valid_activity_count" => 1,
             "invalid_activity_input_count" => 2,
             "invalid_activity_input_ids" => ["missing_activity_id:2", "missing_type"],
             "timeline_integrity_review_count" => 2,
             "required_operator_action_counts" => %{
               "review_activity_approval" => 1,
               "review_invalid_activity_input" => 2
             },
             "assumptions" => %{
               "invalid_activity_input" =>
                 "activity inputs missing stable identity or activity type are preserved as operator-review rows and excluded from typed activity semantics"
             }
           } = report

    assert %{
             "activity_id" => "missing_activity_id:2",
             "activity_type" => "invalid_activity_input",
             "status" => "invalid",
             "required_operator_action" => "review_invalid_activity_input",
             "operator_action_reason" => "missing_activity_id",
             "invalid_activity_input" => true,
             "invalid_activity_input_reason" => "missing_activity_id",
             "source_activity" => %{"type" => "command"},
             "timeline_identity" => %{
               "timeline_id" => "timeline:invalid_activity_input:missing_activity_id:2"
             }
           } = Enum.find(report["rows"], &(&1["activity_id"] == "missing_activity_id:2"))

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_operational_timeline_report(report)

    assert %{
             "review_type" => "operational_timeline_review",
             "required_operator_action" => "review_invalid_activity_input",
             "invalid_activity_input" => true,
             "invalid_activity_input_reason" => "missing_activity_id",
             "source_activity" => %{"type" => "command"}
           } =
             Enum.find(
               review["rows"],
               &(&1["activity_id"] == "missing_activity_id:2")
             )

    manifest = CadenceImport.from_operator_review_package(review)

    assert %{
             "import_action" => "review_operational_timeline",
             "required_operator_action" => "review_invalid_activity_input",
             "invalid_activity_input" => true,
             "invalid_activity_input_reason" => "missing_activity_id",
             "source_activity" => %{"type" => "command"}
           } =
             Enum.find(
               manifest["rows"],
               &(&1["activity_id"] == "missing_activity_id:2")
             )

    normalized = Timeline.normalize_activities([%{type: :command}, %{id: :missing_type}])

    assert [
             %{
               "activity_id" => "missing_activity_id:1",
               "invalid_activity_input_reason" => "missing_activity_id"
             },
             %{
               "activity_id" => "missing_type",
               "invalid_activity_input_reason" => "missing_activity_type"
             }
           ] = normalized
  end

  test "preserves out-of-range unit interval activity context as invalid timeline input" do
    report =
      Timeline.operational_report([
        %{
          id: :valid_feedback,
          type: :downlink,
          ground_station_id: :equator_prime,
          starts_at_s: 10.0,
          ends_at_s: 20.0,
          contact_success_factor: "0.75",
          fuel_margin: 0.25
        },
        %{
          id: :bad_contact_factor,
          type: :downlink,
          ground_station_id: :equator_prime,
          starts_at_s: 30.0,
          ends_at_s: 40.0,
          contact_success_factor: 1.2
        },
        %{
          id: :bad_resource_margin,
          type: :observe,
          target_id: :target_a,
          starts_at_s: 50.0,
          ends_at_s: 60.0,
          metadata: %{"storage_margin" => "-0.1"}
        },
        %{
          id: :bad_quality_factor,
          type: :observe,
          target_id: :target_b,
          starts_at_s: 70.0,
          ends_at_s: 80.0,
          cloud_cover_fraction: "1.1"
        }
      ])

    assert report["activity_count"] == 4
    assert report["valid_activity_count"] == 1
    assert report["invalid_activity_input_count"] == 3

    assert report["invalid_activity_input_ids"] == [
             "bad_contact_factor",
             "bad_resource_margin",
             "bad_quality_factor"
           ]

    assert %{
             "activity_id" => "valid_feedback",
             "activity_context" => %{
               "contact_success_factor" => 0.75,
               "fuel_margin" => 0.25
             }
           } = Enum.find(report["rows"], &(&1["activity_id"] == "valid_feedback"))

    assert %{
             "activity_id" => "bad_contact_factor",
             "status" => "invalid",
             "required_operator_action" => "review_invalid_activity_input",
             "operator_action_reason" => "invalid_contact_success_factor",
             "invalid_activity_input" => true,
             "invalid_activity_input_reason" => "invalid_contact_success_factor",
             "source_activity" => %{"contact_success_factor" => 1.2}
           } = Enum.find(report["rows"], &(&1["activity_id"] == "bad_contact_factor"))

    assert %{
             "activity_id" => "bad_resource_margin",
             "operator_action_reason" => "invalid_storage_margin",
             "source_activity" => %{"metadata" => %{"storage_margin" => "-0.1"}}
           } = Enum.find(report["rows"], &(&1["activity_id"] == "bad_resource_margin"))

    assert %{
             "activity_id" => "bad_quality_factor",
             "operator_action_reason" => "invalid_cloud_cover_fraction",
             "source_activity" => %{"cloud_cover_fraction" => 1.1}
           } = Enum.find(report["rows"], &(&1["activity_id"] == "bad_quality_factor"))

    invalid_activity_context_report =
      update_in(report, ["rows", Access.at(0), "activity_context"], fn context ->
        Map.put(context, "contact_success_factor", 1.2)
      end)

    assert {:error, validation_report} = Schema.validate_artifact(invalid_activity_context_report)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.rows[0].activity_context.contact_success_factor" and
                 &1["message"] == "must be between 0.0 and 1.0")
           )

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(report)

    stale_model_limits = Map.put(report, "model_limits", ["timeline_model_is_read_only"])

    assert {:error, stale_model_limits_report} = Schema.validate_artifact(stale_model_limits)

    assert Enum.any?(
             stale_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] == "must match timeline model limits")
           )

    invalid_allow_overlap =
      put_in(report, ["rows", Access.at(0), "allow_overlap"], "true")

    assert {:error, validation_report} = Schema.validate_artifact(invalid_allow_overlap)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.rows[0].allow_overlap")
           )
  end

  test "single activity normalization preserves invalid inputs for review" do
    assert %{
             "activity_id" => "missing_activity_id:7",
             "activity_type" => "invalid_activity_input",
             "status" => "invalid",
             "approval_status" => "operator_review_required",
             "required_operator_action" => "review_invalid_activity_input",
             "operator_action_reason" => "missing_activity_id",
             "invalid_activity_input" => true,
             "invalid_activity_input_reason" => "missing_activity_id",
             "source_activity" => %{"type" => "command"},
             "timeline_identity" => %{
               "timeline_id" => "timeline:invalid_activity_input:missing_activity_id:7"
             }
           } = Timeline.normalize_activity(%{type: :command}, sequence: 7)

    assert Timeline.normalize_activity(%{type: :command}) ==
             Timeline.normalize_activities([%{type: :command}])
             |> List.first()

    assert OrbitalDynamics.normalize_timeline_activity(%{type: :command}, sequence: 7) ==
             Timeline.normalize_activity(%{type: :command}, sequence: 7)
  end

  test "single activity identity context and protection preserve invalid inputs" do
    invalid_activity = %{type: :command}

    assert %{
             "timeline_id" => "timeline:invalid_activity_input:missing_activity_id:1",
             "activity_id" => "missing_activity_id:1",
             "activity_type" => "invalid_activity_input"
           } = Timeline.timeline_identity(invalid_activity)

    assert %{
             "invalid_activity_input" => true,
             "invalid_activity_input_reason" => "missing_activity_id",
             "source_activity" => %{"type" => "command"},
             "timeline_identity" => %{
               "timeline_id" => "timeline:invalid_activity_input:missing_activity_id:1"
             }
           } = Timeline.activity_context(invalid_activity)

    assert %{
             "activity_id" => "missing_activity_id:3",
             "timeline_id" => "timeline:invalid_activity_input:missing_activity_id:3",
             "invalid_activity_input" => true,
             "invalid_activity_input_reason" => "missing_activity_id",
             "protection_decision" => "review_change",
             "protection_category" => "invalid_activity_input",
             "reason" => "missing_activity_id"
           } = Timeline.protection_decision(invalid_activity, sequence: 3)

    assert OrbitalDynamics.timeline_identity(invalid_activity) ==
             Timeline.timeline_identity(invalid_activity)

    assert OrbitalDynamics.timeline_activity_context(invalid_activity) ==
             Timeline.activity_context(invalid_activity)

    assert OrbitalDynamics.timeline_protection_decision(invalid_activity, sequence: 3) ==
             Timeline.protection_decision(invalid_activity, sequence: 3)
  end

  test "timeline links preserve invalid source or replacement activity inputs" do
    replacement = %{id: :cmd_ok, type: :command}

    assert %{
             "source_timeline_id" => "timeline:invalid_activity_input:missing_activity_id:1",
             "source_activity_id" => "missing_activity_id:1",
             "source_invalid_activity_input" => true,
             "source_invalid_activity_input_reason" => "missing_activity_id",
             "source_activity" => %{"type" => "command"},
             "source_timeline_identity" => %{
               "timeline_id" => "timeline:invalid_activity_input:missing_activity_id:1"
             },
             "replacement_timeline_id" => "timeline:command",
             "replacement_activity_id" => "cmd_ok"
           } = Timeline.timeline_link(%{type: :command}, replacement)

    assert %{
             "source_timeline_id" => "timeline:command",
             "source_activity_id" => "cmd_ok",
             "replacement_timeline_id" => "timeline:invalid_activity_input:missing_activity_id:1",
             "replacement_activity_id" => "missing_activity_id:1",
             "replacement_invalid_activity_input" => true,
             "replacement_invalid_activity_input_reason" => "missing_activity_id",
             "replacement_activity" => %{"type" => "downlink"}
           } = Timeline.timeline_link(replacement, %{type: :downlink})

    assert OrbitalDynamics.timeline_link(%{type: :command}, replacement) ==
             Timeline.timeline_link(%{type: :command}, replacement)
  end

  test "preserves spacecraft identity through operational timeline review and import" do
    report =
      Timeline.operational_report([
        %{
          id: :cmd_payload_mode,
          type: :command,
          scenario_id: :leo_1,
          spacecraft: %{id: :leo_1},
          ground_station_id: :dss_14,
          starts_at_s: 30.0,
          ends_at_s: 40.0,
          approval_status: :pending
        }
      ])

    assert %{
             "activity_id" => "cmd_payload_mode",
             "spacecraft_id" => "leo_1",
             "activity_context" => %{
               "spacecraft_id" => "leo_1",
               "timeline_identity" => %{
                 "scenario_id" => "leo_1"
               }
             }
           } = List.first(report["rows"])

    review = OperatorReview.from_operational_timeline_report(report)
    import = CadenceImport.from_operational_timeline_report(report)

    assert %{
             "activity_id" => "cmd_payload_mode",
             "spacecraft_id" => "leo_1",
             "source_activity_context" => %{"spacecraft_id" => "leo_1"},
             "source_operational_timeline" => %{"spacecraft_id" => "leo_1"}
           } = List.first(review["rows"])

    assert %{
             "activity_id" => "cmd_payload_mode",
             "spacecraft_id" => "leo_1",
             "source_activity_context" => %{"spacecraft_id" => "leo_1"},
             "source_operational_timeline" => %{"spacecraft_id" => "leo_1"}
           } = List.first(import["rows"])

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(report)

    invalid_reservation_ids =
      put_in(report, ["rows", Access.at(0), "station_calendar_reservation_ids"], ["bad id"])

    assert {:error, invalid_reservation_ids_report} =
             Schema.validate_artifact(invalid_reservation_ids)

    assert Enum.any?(
             invalid_reservation_ids_report["errors"],
             &(&1["path"] == "$.rows[0].station_calendar_reservation_ids[0]")
           )

    invalid_reservation_expirations =
      put_in(report, ["rows", Access.at(0), "station_calendar_reservation_expires_at_s"], [
        "soon"
      ])

    assert {:error, invalid_reservation_expirations_report} =
             Schema.validate_artifact(invalid_reservation_expirations)

    assert Enum.any?(
             invalid_reservation_expirations_report["errors"],
             &(&1["path"] == "$.rows[0].station_calendar_reservation_expires_at_s[0]")
           )

    invalid_reservation_expiration =
      put_in(report, ["rows", Access.at(0), "station_reservation_expires_at_s"], "soon")

    assert {:error, invalid_reservation_expiration_report} =
             Schema.validate_artifact(invalid_reservation_expiration)

    assert Enum.any?(
             invalid_reservation_expiration_report["errors"],
             &(&1["path"] == "$.rows[0].station_reservation_expires_at_s")
           )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "preserves command authority and safety through operational timeline review and import" do
    report =
      Timeline.operational_report([
        %{
          id: :cmd_auth,
          timeline_id: "timeline:cmd_auth",
          type: :command,
          starts_at_s: 30.0,
          ends_at_s: 40.0,
          status: :planned,
          approval_status: :pending,
          direction: :command,
          command_authority_status: :operator_required,
          required_authority: :flight_director,
          command_safety_status: :checked,
          command_authorized: false,
          command_safety_checked: true
        }
      ])

    assert %{
             "command_authority_status" => "operator_required",
             "required_authority" => "flight_director",
             "command_safety_status" => "checked",
             "command_authorized" => false,
             "command_safety_checked" => true,
             "activity_context" => %{
               "command_authority_status" => "operator_required",
               "required_authority" => "flight_director",
               "command_safety_status" => "checked",
               "command_authorized" => false,
               "command_safety_checked" => true
             }
           } = List.first(report["rows"])

    review = OperatorReview.from_operational_timeline_report(report)
    import = CadenceImport.from_operational_timeline_report(report)

    assert %{
             "review_type" => "operational_timeline_review",
             "command_authority_status" => "operator_required",
             "required_authority" => "flight_director",
             "command_safety_status" => "checked",
             "command_authorized" => false,
             "command_safety_checked" => true,
             "source_activity_context" => %{
               "command_authority_status" => "operator_required",
               "required_authority" => "flight_director",
               "command_safety_status" => "checked",
               "command_authorized" => false,
               "command_safety_checked" => true
             },
             "source_operational_timeline" => %{
               "command_authority_status" => "operator_required",
               "required_authority" => "flight_director",
               "command_safety_status" => "checked",
               "command_authorized" => false,
               "command_safety_checked" => true
             }
           } = List.first(review["rows"])

    assert %{
             "import_action" => "review_operational_timeline",
             "command_authority_status" => "operator_required",
             "required_authority" => "flight_director",
             "command_safety_status" => "checked",
             "command_authorized" => false,
             "command_safety_checked" => true,
             "source_review_row" => %{
               "command_authority_status" => "operator_required",
               "required_authority" => "flight_director",
               "command_safety_status" => "checked",
               "command_authorized" => false,
               "command_safety_checked" => true
             },
             "source_operational_timeline" => %{
               "command_authority_status" => "operator_required",
               "required_authority" => "flight_director",
               "command_safety_status" => "checked",
               "command_authorized" => false,
               "command_safety_checked" => true
             }
           } = List.first(import["rows"])

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)

    stale_review =
      put_in(review, ["rows", Access.at(0), "command_safety_checked"], false)

    assert {:error, stale_review_report} = Schema.validate_artifact(stale_review)

    assert Enum.any?(
             stale_review_report["errors"],
             &(&1["path"] == "$.rows[0].command_safety_checked" and
                 &1["message"] ==
                   "must match source_operational_timeline.command_safety_checked")
           )

    stale_import =
      put_in(import, ["rows", Access.at(0), "command_authority_status"], "stale")

    assert {:error, stale_import_report} = Schema.validate_artifact(stale_import)

    assert Enum.any?(
             stale_import_report["errors"],
             &(&1["path"] == "$.rows[0].command_authority_status" and
                 &1["message"] ==
                   "must match source_operational_timeline.command_authority_status")
           )
  end

  test "rejects unknown operational timeline kind values" do
    report =
      Timeline.operational_report([
        %{id: :cmd_1, type: :command, starts_at_s: 10.0, ends_at_s: 20.0}
      ])

    invalid_report = put_in(report, ["rows", Access.at(0), "operational_kind"], "provider_custom")

    assert {:error, validation_report} = Schema.validate_artifact(invalid_report)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.rows[0].operational_kind" and
                 &1["message"] =~ "must be one of")
           )
  end

  test "rejects unknown operational timeline required operator actions" do
    report =
      Timeline.operational_report([
        %{id: :cmd_1, type: :command, starts_at_s: 10.0, ends_at_s: 20.0}
      ])

    invalid_report =
      put_in(report, ["rows", Access.at(0), "required_operator_action"], "provider_custom")

    assert {:error, validation_report} = Schema.validate_artifact(invalid_report)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.rows[0].required_operator_action" and
                 &1["message"] =~ "must be one of")
           )
  end

  test "rejects malformed persisted operational timeline identity row fields" do
    report =
      Timeline.operational_report([
        %{
          id: :dl_1,
          type: :downlink,
          scenario_id: :leo_1,
          spacecraft_id: :leo_1,
          ground_station_id: :dss_14,
          source_window_id: :dss_14_pass_1,
          starts_at_s: 10.0,
          ends_at_s: 20.0
        }
      ])

    invalid_report =
      report
      |> put_in(["rows", Access.at(0), "ground_station_id"], "bad station id")
      |> put_in(["rows", Access.at(0), "target_id"], "bad target id")
      |> put_in(["rows", Access.at(0), "source_window_id"], "bad source window id")

    assert {:error, validation_report} = Schema.validate_artifact(invalid_report)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.rows[0].ground_station_id" and &1["message"] =~ "stable ID")
           )

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.rows[0].target_id" and &1["message"] =~ "stable ID")
           )

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.rows[0].source_window_id" and &1["message"] =~ "stable ID")
           )
  end

  test "rejects unknown timeline diff required operator actions" do
    report =
      Timeline.diff_report(
        [%{id: :cmd_1, type: :command, starts_at_s: 10.0, ends_at_s: 20.0}],
        [%{id: :cmd_1, type: :command, starts_at_s: 15.0, ends_at_s: 25.0}]
      )

    invalid_report =
      put_in(report, ["rows", Access.at(0), "required_operator_action"], "provider_custom")

    assert {:error, validation_report} = Schema.validate_artifact(invalid_report)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.rows[0].required_operator_action" and
                 &1["message"] =~ "must be one of")
           )
  end

  test "rejects unknown operational timeline Cadence import statuses" do
    report =
      Timeline.operational_report([
        %{id: :cmd_1, type: :command, starts_at_s: 10.0, ends_at_s: 20.0}
      ])

    invalid_report = put_in(report, ["rows", Access.at(0), "cadence_import_status"], "custom")

    assert {:error, validation_report} = Schema.validate_artifact(invalid_report)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.rows[0].cadence_import_status" and
                 &1["message"] =~ "must be one of")
           )
  end

  test "rejects non-artifact operational timeline execution boundaries" do
    report =
      Timeline.operational_report([
        %{id: :cmd_1, type: :command, starts_at_s: 10.0, ends_at_s: 20.0}
      ])

    invalid_report = put_in(report, ["rows", Access.at(0), "execution_boundary"], "commanded")

    assert {:error, validation_report} = Schema.validate_artifact(invalid_report)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.rows[0].execution_boundary" and
                 &1["message"] =~ "must be one of")
           )
  end

  test "rejects unknown operational timeline integrity issue types" do
    report =
      Timeline.operational_report(
        [
          %{
            id: :cmd_1,
            type: :command,
            starts_at_s: 10.0,
            ends_at_s: 20.0,
            dependencies: [:missing_gate]
          }
        ],
        validate_missing_dependencies?: true
      )

    invalid_report =
      put_in(report, ["rows", Access.at(0), "timeline_integrity_issue_types"], [
        "provider_custom"
      ])

    assert {:error, validation_report} = Schema.validate_artifact(invalid_report)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.rows[0].timeline_integrity_issue_types[0]" and
                 &1["message"] =~ "must be one of")
           )
  end

  test "rejects malformed operational timeline integrity issue evidence" do
    report =
      Timeline.operational_report(
        [
          %{
            id: :cmd_1,
            type: :command,
            starts_at_s: 10.0,
            ends_at_s: 20.0,
            dependencies: [:missing_gate]
          }
        ],
        validate_missing_dependencies?: true
      )

    missing_type_report =
      put_in(report, ["rows", Access.at(0), "timeline_integrity_issues"], [
        %{"missing_dependency_activity_id" => "missing_gate"}
      ])

    assert {:error, missing_type_validation} = Schema.validate_artifact(missing_type_report)

    assert Enum.any?(
             missing_type_validation["errors"],
             &(&1["path"] == "$.rows[0].timeline_integrity_issues[0].type" and
                 &1["message"] == "is required")
           )

    bad_id_report =
      put_in(report, ["rows", Access.at(0), "timeline_integrity_issues"], [
        %{"type" => "missing_dependency_activity", "missing_dependency_activity_id" => "bad id"}
      ])

    assert {:error, bad_id_validation} = Schema.validate_artifact(bad_id_report)

    assert Enum.any?(
             bad_id_validation["errors"],
             &(&1["path"] ==
                 "$.rows[0].timeline_integrity_issues[0].missing_dependency_activity_id" and
                 &1["message"] =~ "stable ID")
           )

    missing_evidence_report =
      put_in(report, ["rows", Access.at(0), "timeline_integrity_issues"], [
        %{"type" => "dependency_cycle"}
      ])

    assert {:error, missing_evidence_validation} =
             Schema.validate_artifact(missing_evidence_report)

    assert Enum.any?(
             missing_evidence_validation["errors"],
             &(&1["path"] == "$.rows[0].timeline_integrity_issues[0]" and
                 &1["message"] =~ "must include one of")
           )

    missing_group_report =
      put_in(report, ["rows", Access.at(0), "timeline_integrity_issues"], [
        %{
          "type" => "exclusivity_group_overlap",
          "exclusivity_violation_activity_id" => "other",
          "exclusivity_violation_timeline_id" => "timeline:other"
        }
      ])

    assert {:error, missing_group_validation} = Schema.validate_artifact(missing_group_report)

    assert Enum.any?(
             missing_group_validation["errors"],
             &(&1["path"] ==
                 "$.rows[0].timeline_integrity_issues[0].exclusivity_violation_group" and
                 &1["message"] == "is required")
           )
  end

  test "rejects operational timeline integrity summaries that diverge from issue evidence" do
    report =
      Timeline.operational_report(
        [
          %{
            id: :cmd_1,
            type: :command,
            starts_at_s: 10.0,
            ends_at_s: 20.0,
            dependencies: [:missing_gate]
          }
        ],
        validate_missing_dependencies?: true
      )

    count_mismatch_report =
      put_in(report, ["rows", Access.at(0), "timeline_integrity_issue_count"], 2)

    assert {:error, count_validation} = Schema.validate_artifact(count_mismatch_report)

    assert Enum.any?(
             count_validation["errors"],
             &(&1["path"] == "$.rows[0].timeline_integrity_issue_count" and
                 &1["message"] =~ "must match timeline_integrity_issues length")
           )

    type_mismatch_report =
      put_in(report, ["rows", Access.at(0), "timeline_integrity_issue_types"], [])

    assert {:error, type_validation} = Schema.validate_artifact(type_mismatch_report)

    assert Enum.any?(
             type_validation["errors"],
             &(&1["path"] == "$.rows[0].timeline_integrity_issue_types" and
                 &1["message"] =~ "must match timeline_integrity_issues types")
           )

    ids_mismatch_report =
      put_in(report, ["rows", Access.at(0), "missing_dependency_activity_ids"], ["other_gate"])

    assert {:error, ids_validation} = Schema.validate_artifact(ids_mismatch_report)

    assert Enum.any?(
             ids_validation["errors"],
             &(&1["path"] == "$.rows[0].missing_dependency_activity_ids" and
                 &1["message"] =~
                   "must match timeline_integrity_issues missing_dependency_activity_id values")
           )
  end

  test "preserves unsupported operational timeline approval status for review" do
    report =
      Timeline.operational_report([
        %{
          id: :cmd_bad_approval,
          type: :command,
          approval_status: :provider_custom,
          starts_at_s: 10.0,
          ends_at_s: 20.0
        }
      ])

    assert %{
             "valid_activity_count" => 0,
             "invalid_activity_input_count" => 1,
             "invalid_activity_input_ids" => ["cmd_bad_approval"]
           } = report

    assert %{
             "activity_id" => "cmd_bad_approval",
             "activity_type" => "invalid_activity_input",
             "status" => "invalid",
             "approval_status" => "operator_review_required",
             "required_operator_action" => "review_invalid_activity_input",
             "operator_action_reason" => "unsupported_approval_status",
             "invalid_activity_input" => true,
             "invalid_activity_input_reason" => "unsupported_approval_status",
             "source_activity" => %{"approval_status" => "provider_custom"}
           } = List.first(report["rows"])

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "preserves unsupported operational timeline activity status for review" do
    report =
      Timeline.operational_report([
        %{
          id: :cmd_bad_status,
          type: :command,
          status: "provider magic",
          starts_at_s: 10.0,
          ends_at_s: 20.0
        }
      ])

    assert %{
             "valid_activity_count" => 0,
             "invalid_activity_input_count" => 1,
             "invalid_activity_input_ids" => ["cmd_bad_status"]
           } = report

    assert %{
             "activity_id" => "cmd_bad_status",
             "activity_type" => "invalid_activity_input",
             "status" => "invalid",
             "approval_status" => "operator_review_required",
             "required_operator_action" => "review_invalid_activity_input",
             "operator_action_reason" => "unsupported_activity_status",
             "invalid_activity_input" => true,
             "invalid_activity_input_reason" => "unsupported_activity_status",
             "source_activity" => %{"status" => "provider magic"}
           } = List.first(report["rows"])

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "preserves malformed operational timeline activity ids for review" do
    report =
      Timeline.operational_report([
        %{
          id: "bad activity id",
          type: :observe,
          target_id: :target_a,
          starts_at_s: 10.0,
          ends_at_s: 20.0
        }
      ])

    assert %{
             "activity_count" => 1,
             "valid_activity_count" => 0,
             "invalid_activity_input_count" => 1,
             "invalid_activity_input_ids" => ["invalid_activity_id:1"],
             "timeline_integrity_review_count" => 1
           } = report

    assert %{
             "activity_id" => "invalid_activity_id:1",
             "activity_type" => "invalid_activity_input",
             "required_operator_action" => "review_invalid_activity_input",
             "operator_action_reason" => "invalid_activity_id",
             "invalid_activity_input" => true,
             "invalid_activity_input_reason" => "invalid_activity_id",
             "source_activity" => %{"id" => "bad activity id", "type" => "observe"},
             "timeline_identity" => %{
               "timeline_id" => "timeline:invalid_activity_input:invalid_activity_id:1"
             }
           } = List.first(report["rows"])

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_operational_timeline_report(report)

    assert %{
             "required_operator_action" => "review_invalid_activity_input",
             "invalid_activity_input_reason" => "invalid_activity_id",
             "source_activity" => %{"id" => "bad activity id"}
           } = List.first(review["rows"])

    manifest = CadenceImport.from_operator_review_package(review)

    assert %{
             "import_action" => "review_operational_timeline",
             "invalid_activity_input_reason" => "invalid_activity_id",
             "source_activity" => %{"id" => "bad activity id"}
           } = List.first(manifest["rows"])

    assert [
             %{
               "activity_id" => "invalid_activity_id:1",
               "invalid_activity_input_reason" => "invalid_activity_id"
             }
           ] = Timeline.normalize_activities([%{id: "bad activity id", type: :observe}])
  end

  test "preserves malformed operational timeline identity fields for review" do
    activities = [
      %{
        id: :obs_bad_scenario,
        type: :observe,
        scenario_id: "bad scenario id",
        target_id: :target_a,
        starts_at_s: 10.0,
        ends_at_s: 20.0
      },
      %{
        id: :dl_bad_station,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: "bad station id",
        starts_at_s: 30.0,
        ends_at_s: 40.0
      },
      %{
        id: :cmd_bad_timeline,
        type: :command,
        scenario_id: :leo_1,
        ground_station_id: :dss_14,
        starts_at_s: 50.0,
        ends_at_s: 60.0,
        metadata: %{timeline_id: "timeline bad"}
      },
      %{
        id: :obs_bad_source_window,
        type: :observe,
        scenario_id: :leo_1,
        target_id: :target_b,
        starts_at_s: 70.0,
        ends_at_s: 80.0,
        source_window: %{id: "bad source window"}
      }
    ]

    report = Timeline.operational_report(activities)
    rows_by_id = Map.new(report["rows"], &{&1["activity_id"], &1})

    assert %{
             "activity_count" => 4,
             "valid_activity_count" => 0,
             "invalid_activity_input_count" => 4,
             "invalid_activity_input_ids" => [
               "obs_bad_scenario",
               "dl_bad_station",
               "cmd_bad_timeline",
               "obs_bad_source_window"
             ],
             "timeline_integrity_review_count" => 4,
             "required_operator_action_counts" => %{"review_invalid_activity_input" => 4}
           } = report

    assert %{
             "activity_id" => "obs_bad_scenario",
             "invalid_activity_input_reason" => "invalid_scenario_id",
             "source_activity" => %{"scenario_id" => "bad scenario id"},
             "timeline_identity" => %{
               "timeline_id" => "timeline:invalid_activity_input:obs_bad_scenario"
             }
           } = rows_by_id["obs_bad_scenario"]

    assert %{
             "activity_id" => "dl_bad_station",
             "invalid_activity_input_reason" => "invalid_ground_station_id",
             "source_activity" => %{"ground_station_id" => "bad station id"}
           } = rows_by_id["dl_bad_station"]

    assert %{
             "activity_id" => "cmd_bad_timeline",
             "invalid_activity_input_reason" => "invalid_timeline_id",
             "source_activity" => %{"metadata" => %{"timeline_id" => "timeline bad"}}
           } = rows_by_id["cmd_bad_timeline"]

    assert %{
             "activity_id" => "obs_bad_source_window",
             "invalid_activity_input_reason" => "invalid_source_window_id",
             "source_activity" => %{"source_window" => %{"id" => "bad source window"}}
           } = rows_by_id["obs_bad_source_window"]

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_operational_timeline_report(report)

    assert %{
             "required_operator_action" => "review_invalid_activity_input",
             "invalid_activity_input_reason" => "invalid_timeline_id",
             "source_activity" => %{"metadata" => %{"timeline_id" => "timeline bad"}}
           } = Enum.find(review["rows"], &(&1["activity_id"] == "cmd_bad_timeline"))

    manifest = CadenceImport.from_operator_review_package(review)

    assert %{
             "import_action" => "review_operational_timeline",
             "invalid_activity_input_reason" => "invalid_source_window_id",
             "source_activity" => %{"source_window" => %{"id" => "bad source window"}}
           } = Enum.find(manifest["rows"], &(&1["activity_id"] == "obs_bad_source_window"))

    assert [
             %{
               "activity_id" => "obs_bad_scenario",
               "invalid_activity_input_reason" => "invalid_scenario_id"
             },
             %{
               "activity_id" => "dl_bad_station",
               "invalid_activity_input_reason" => "invalid_ground_station_id"
             },
             %{
               "activity_id" => "cmd_bad_timeline",
               "invalid_activity_input_reason" => "invalid_timeline_id"
             },
             %{
               "activity_id" => "obs_bad_source_window",
               "invalid_activity_input_reason" => "invalid_source_window_id"
             }
           ] = Timeline.normalize_activities(activities)
  end

  test "preserves malformed operational timeline product and overlay identity fields for review" do
    activities = [
      %{
        id: :obs_bad_collection,
        type: :observe,
        scenario_id: :leo_1,
        target_id: :target_a,
        collection_id: "bad collection id",
        starts_at_s: 10.0,
        ends_at_s: 20.0
      },
      %{
        id: :obs_bad_product,
        type: :observe,
        scenario_id: :leo_1,
        target_id: :target_a,
        product_id: "bad product id",
        starts_at_s: 30.0,
        ends_at_s: 40.0
      },
      %{
        id: :obs_bad_payload,
        type: :observe,
        scenario_id: :leo_1,
        target_id: :target_a,
        payload_id: "bad payload id",
        instrument_id: :camera_a,
        starts_at_s: 50.0,
        ends_at_s: 60.0
      },
      %{
        id: :dl_bad_calendar_entry,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :dss_14,
        station_calendar_entry_id: "bad calendar id",
        starts_at_s: 70.0,
        ends_at_s: 80.0
      },
      %{
        id: :dl_bad_calendar_provider,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :dss_14,
        station_calendar_provider_id: "bad provider id",
        starts_at_s: 82.0,
        ends_at_s: 88.0
      },
      %{
        id: :dl_bad_calendar_provider_entry,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :dss_14,
        station_calendar_provider_entry_id: "bad provider entry id",
        starts_at_s: 89.0,
        ends_at_s: 95.0
      },
      %{
        id: :dl_bad_reservation,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :dss_14,
        station_reservation_id: "bad reservation id",
        starts_at_s: 90.0,
        ends_at_s: 100.0
      }
    ]

    report = Timeline.operational_report(activities)
    rows_by_id = Map.new(report["rows"], &{&1["activity_id"], &1})

    assert %{
             "activity_count" => 7,
             "valid_activity_count" => 0,
             "invalid_activity_input_count" => 7,
             "invalid_activity_input_ids" => [
               "obs_bad_collection",
               "obs_bad_product",
               "obs_bad_payload",
               "dl_bad_calendar_entry",
               "dl_bad_calendar_provider",
               "dl_bad_calendar_provider_entry",
               "dl_bad_reservation"
             ],
             "required_operator_action_counts" => %{"review_invalid_activity_input" => 7}
           } = report

    assert %{
             "invalid_activity_input_reason" => "invalid_collection_id",
             "source_activity" => %{"collection_id" => "bad collection id"}
           } = rows_by_id["obs_bad_collection"]

    assert %{
             "invalid_activity_input_reason" => "invalid_product_id",
             "source_activity" => %{"product_id" => "bad product id"}
           } = rows_by_id["obs_bad_product"]

    assert %{
             "invalid_activity_input_reason" => "invalid_payload_id",
             "source_activity" => %{"payload_id" => "bad payload id"}
           } = rows_by_id["obs_bad_payload"]

    assert %{
             "invalid_activity_input_reason" => "invalid_station_calendar_entry_id",
             "source_activity" => %{"station_calendar_entry_id" => "bad calendar id"}
           } = rows_by_id["dl_bad_calendar_entry"]

    assert %{
             "invalid_activity_input_reason" => "invalid_station_calendar_provider_id",
             "source_activity" => %{"station_calendar_provider_id" => "bad provider id"}
           } = rows_by_id["dl_bad_calendar_provider"]

    assert %{
             "invalid_activity_input_reason" => "invalid_station_calendar_provider_entry_id",
             "source_activity" => %{
               "station_calendar_provider_entry_id" => "bad provider entry id"
             }
           } = rows_by_id["dl_bad_calendar_provider_entry"]

    assert %{
             "invalid_activity_input_reason" => "invalid_station_reservation_id",
             "source_activity" => %{"station_reservation_id" => "bad reservation id"}
           } = rows_by_id["dl_bad_reservation"]

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_operational_timeline_report(report)
    manifest = CadenceImport.from_operator_review_package(review)

    assert %{
             "required_operator_action" => "review_invalid_activity_input",
             "invalid_activity_input_reason" => "invalid_station_reservation_id",
             "source_activity" => %{"station_reservation_id" => "bad reservation id"}
           } = Enum.find(review["rows"], &(&1["activity_id"] == "dl_bad_reservation"))

    assert %{
             "import_action" => "review_operational_timeline",
             "invalid_activity_input_reason" => "invalid_product_id",
             "source_activity" => %{"product_id" => "bad product id"}
           } = Enum.find(manifest["rows"], &(&1["activity_id"] == "obs_bad_product"))

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "preserves malformed cadence import context for operational timeline review" do
    report =
      Timeline.operational_report([
        %{
          id: :cmd_bad_import,
          type: :command,
          direction: :command,
          ground_station_id: :dss_14,
          starts_at_s: 1.0,
          ends_at_s: 2.0,
          approval_status: :approved,
          cadence_import: :bad_import_context
        }
      ])

    assert %{
             "cadence_import_status_counts" => %{"invalid" => 1},
             "required_operator_action_counts" => %{"review_invalid_cadence_import" => 1}
           } = report

    assert %{
             "activity_id" => "cmd_bad_import",
             "operational_kind" => "command",
             "required_operator_action" => "review_invalid_cadence_import",
             "operator_action_reason" => "cadence_import_must_be_object",
             "cadence_import_status" => "invalid",
             "has_cadence_import" => false,
             "invalid_cadence_import" => true,
             "invalid_cadence_import_reason" => "cadence_import_must_be_object",
             "source_cadence_import" => %{"invalid_import_shape" => "bad_import_context"},
             "activity_context" => %{
               "invalid_cadence_import" => true,
               "invalid_cadence_import_reason" => "cadence_import_must_be_object",
               "source_cadence_import" => %{"invalid_import_shape" => "bad_import_context"}
             }
           } = row = List.first(report["rows"])

    refute Map.has_key?(row["activity_context"], "cadence_import")

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_operational_timeline_report(report)

    assert %{
             "review_type" => "operational_timeline_review",
             "required_operator_action" => "review_invalid_cadence_import",
             "operator_action_reason" => "cadence_import_must_be_object",
             "cadence_import_status" => "invalid",
             "invalid_cadence_import" => true,
             "invalid_cadence_import_reason" => "cadence_import_must_be_object",
             "source_cadence_import" => %{"invalid_import_shape" => "bad_import_context"}
           } = List.first(review["rows"])

    manifest = CadenceImport.from_operator_review_package(review)

    assert %{
             "import_action" => "review_operational_timeline",
             "import_status" => "review_required_before_import",
             "required_operator_action" => "review_invalid_cadence_import",
             "cadence_import_status" => "invalid",
             "invalid_cadence_import" => true,
             "source_cadence_import" => %{"invalid_import_shape" => "bad_import_context"}
           } = List.first(manifest["rows"])

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "review-gates cadence import adapter context missing trust boundary" do
    report =
      Timeline.operational_report([
        %{
          id: :cmd_missing_import_trust,
          type: :command,
          direction: :command,
          ground_station_id: :dss_14,
          starts_at_s: 1.0,
          ends_at_s: 2.0,
          approval_status: :approved,
          cadence_import: %{
            provider: :cadence,
            adapter: :cadence_command_adapter,
            external_id: :cmd_missing_import_trust
          }
        }
      ])

    assert %{
             "cadence_import_status_counts" => %{"invalid" => 1},
             "required_operator_action_counts" => %{"review_invalid_cadence_import" => 1}
           } = report

    assert %{
             "activity_id" => "cmd_missing_import_trust",
             "cadence_import_status" => "invalid",
             "has_cadence_import" => false,
             "invalid_cadence_import" => true,
             "invalid_cadence_import_reason" => "missing_cadence_import_trust_boundary",
             "source_cadence_import" => %{
               "provider" => "cadence",
               "adapter" => "cadence_command_adapter",
               "external_id" => "cmd_missing_import_trust"
             },
             "activity_context" => %{
               "invalid_cadence_import" => true,
               "invalid_cadence_import_reason" => "missing_cadence_import_trust_boundary"
             }
           } = row = List.first(report["rows"])

    refute Map.has_key?(row, "cadence_import_provider")
    refute Map.has_key?(row, "cadence_import_id")
    refute Map.has_key?(row["activity_context"], "cadence_import")

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_operational_timeline_report(report)
    manifest = CadenceImport.from_operator_review_package(review)

    assert %{
             "required_operator_action" => "review_invalid_cadence_import",
             "invalid_cadence_import_reason" => "missing_cadence_import_trust_boundary",
             "source_cadence_import" => %{"adapter" => "cadence_command_adapter"}
           } = List.first(review["rows"])

    assert %{
             "import_action" => "review_operational_timeline",
             "import_status" => "review_required_before_import",
             "invalid_cadence_import_reason" => "missing_cadence_import_trust_boundary",
             "source_cadence_import" => %{"provider" => "cadence"}
           } = List.first(manifest["rows"])

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "review-gates cadence import context with malformed external id" do
    report =
      Timeline.operational_report([
        %{
          id: :cmd_bad_external_import,
          type: :command,
          direction: :command,
          ground_station_id: :dss_14,
          starts_at_s: 1.0,
          ends_at_s: 2.0,
          approval_status: :approved,
          cadence_import: %{
            provider: :cadence,
            adapter: :cadence_command_adapter,
            trust_boundary: :orbital_dynamics_to_cadence_adapter,
            external_id: "bad external id"
          }
        }
      ])

    assert %{
             "cadence_import_status_counts" => %{"invalid" => 1},
             "required_operator_action_counts" => %{"review_invalid_cadence_import" => 1}
           } = report

    assert %{
             "activity_id" => "cmd_bad_external_import",
             "cadence_import_status" => "invalid",
             "invalid_cadence_import" => true,
             "invalid_cadence_import_reason" => "invalid_cadence_import_external_id",
             "source_cadence_import" => %{"external_id" => "bad external id"}
           } = row = List.first(report["rows"])

    refute Map.has_key?(row, "cadence_import_id")

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "preserves invalid timeline diff source and replacement inputs for review" do
    report =
      Timeline.diff_report(
        [
          %{
            type: :command,
            starts_at_s: 10.0,
            ends_at_s: 20.0
          }
        ],
        [
          %{
            id: :missing_type,
            starts_at_s: 30.0,
            ends_at_s: 40.0
          }
        ],
        source: "repair.activities"
      )

    assert %{
             "source_activity_count" => 1,
             "replacement_activity_count" => 1,
             "valid_source_activity_count" => 0,
             "valid_replacement_activity_count" => 0,
             "invalid_source_activity_input_count" => 1,
             "invalid_replacement_activity_input_count" => 1,
             "invalid_source_activity_input_ids" => ["missing_activity_id:1"],
             "invalid_replacement_activity_input_ids" => ["missing_type"],
             "required_operator_action_counts" => %{"review_invalid_activity_input" => 2},
             "assumptions" => %{
               "invalid_activity_input" =>
                 "source and replacement inputs missing stable identity or activity type are preserved as reviewable diff rows"
             }
           } = report

    source_row =
      Enum.find(report["rows"], &(&1["source_invalid_activity_input"] == true))

    replacement_row =
      Enum.find(report["rows"], &(&1["replacement_invalid_activity_input"] == true))

    assert %{
             "diff_status" => "removed",
             "source_activity_id" => "missing_activity_id:1",
             "source_invalid_activity_input" => true,
             "source_invalid_activity_input_reason" => "missing_activity_id",
             "source_activity" => %{"type" => "command"},
             "required_operator_action" => "review_invalid_activity_input"
           } = source_row

    assert %{
             "diff_status" => "added",
             "replacement_activity_id" => "missing_type",
             "replacement_invalid_activity_input" => true,
             "replacement_invalid_activity_input_reason" => "missing_activity_type",
             "replacement_activity" => %{"id" => "missing_type"},
             "required_operator_action" => "review_invalid_activity_input"
           } = replacement_row

    assert {:ok, %{"schema_contract" => "timeline_diff_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_timeline_diff_report(report)

    assert %{
             "review_type" => "timeline_diff_review",
             "required_operator_action" => "review_invalid_activity_input",
             "source_invalid_activity_input" => true,
             "source_activity" => %{"type" => "command"}
           } =
             Enum.find(review["rows"], &(&1["source_invalid_activity_input"] == true))

    assert %{
             "review_type" => "timeline_diff_review",
             "required_operator_action" => "review_invalid_activity_input",
             "replacement_invalid_activity_input" => true,
             "replacement_activity" => %{"id" => "missing_type"}
           } =
             Enum.find(review["rows"], &(&1["replacement_invalid_activity_input"] == true))

    import = CadenceImport.from_timeline_diff_report(report)

    assert %{
             "import_action" => "review_timeline_diff",
             "source_review_action" => "review_invalid_activity_input",
             "source_invalid_activity_input" => true,
             "source_activity" => %{"type" => "command"}
           } =
             Enum.find(import["rows"], &(&1["source_invalid_activity_input"] == true))

    assert %{
             "import_action" => "review_timeline_diff",
             "source_review_action" => "review_invalid_activity_input",
             "replacement_invalid_activity_input" => true,
             "replacement_activity" => %{"id" => "missing_type"}
           } =
             Enum.find(import["rows"], &(&1["replacement_invalid_activity_input"] == true))
  end

  test "builds operational report rows for command contact and payload activities" do
    report =
      Timeline.operational_report(
        [
          Activity.observe!(:obs_1, 10.0, 20.0, :target_a,
            status: :approved,
            approval_status: :approved,
            source_window_id: :target_a_pass_1,
            metadata: %{
              collection_id: :collection_alpha,
              product_id: :image_alpha_1,
              product_ids: [:image_alpha_1, :image_alpha_2],
              payload_id: :payload_camera,
              instrument_id: :narrow_angle_camera,
              estimated_data_volume_mb: 42.5,
              estimated_storage_mb: 42.5,
              estimated_downlink_mb: 40.0,
              required_downlink_mb: 40.0
            }
          ),
          Activity.command!(:cmd_1, 30.0, 40.0,
            ground_station_id: :dss_14,
            approval_status: :pending,
            locked?: true
          ),
          %{
            id: :trk_1,
            type: :tracking,
            scenario_id: :leo_1,
            starts_at_s: 50.0,
            ends_at_s: 60.0,
            ground_station_id: :dss_14,
            direction: :tracking,
            cadence_import: %{
              activity_type: :tracking,
              external_id: :track_1,
              schema_contract: :"planned_activity.v1",
              provider: :cadence,
              adapter: :cadence_tracking_adapter,
              adapter_version: :"2026-05",
              provenance: %{trust_boundary: :orbital_dynamics_to_cadence_adapter}
            }
          },
          Activity.planned_contact!(:cmd_contact, 70.0, 80.0, :dss_14, :command,
            approval_status: :pending
          ),
          Activity.planned_contact!(:uplink_contact, 90.0, 100.0, :dss_14, :uplink,
            approval_status: :pending
          )
        ],
        source: "mission_plan.activities",
        source_assumption: "planned mission activities"
      )

    assert report["schema_contract"] == "operational_timeline_report.v1"
    assert report["source"] == "mission_plan.activities"
    assert report["activity_count"] == 5
    assert report["contact_count"] == 4
    assert report["command_count"] == 3
    assert report["locked_count"] == 1
    assert report["approved_count"] == 1
    assert report["source_window_lineage_count"] == 1
    assert report["activity_status_counts"] == %{"approved" => 1, "planned" => 4}

    assert report["approval_status_counts"] == %{
             "approved" => 1,
             "not_evaluated" => 1,
             "pending" => 3
           }

    assert report["required_operator_action_counts"] == %{
             "monitor_activity" => 1,
             "review_activity_approval" => 1,
             "review_command_contact" => 3
           }

    assert report["cadence_import_status_counts"] == %{
             "missing" => 3,
             "not_applicable" => 1,
             "present" => 1
           }

    assert report["operational_kind_counts"] == %{
             "command" => 3,
             "contact" => 1,
             "observation" => 1
           }

    assert "no_schedule_mutation" in report["model_limits"]
    assert "no_command_execution" in report["model_limits"]

    assert %{
             "activity_id" => "obs_1",
             "activity_type" => "observe",
             "approval_status" => "approved",
             "collection_id" => "collection_alpha",
             "product_id" => "image_alpha_1",
             "product_ids" => ["image_alpha_1", "image_alpha_2"],
             "payload_id" => "payload_camera",
             "instrument_id" => "narrow_angle_camera",
             "data_volume_mb" => 42.5,
             "estimated_data_volume_mb" => 42.5,
             "estimated_storage_mb" => 42.5,
             "estimated_downlink_mb" => 40.0,
             "required_downlink_mb" => 40.0,
             "source_window_id" => "target_a_pass_1",
             "timeline_id" => "timeline:observe:target_a:target_a_pass_1",
             "activity_context" => %{
               "collection_id" => "collection_alpha",
               "product_id" => "image_alpha_1",
               "product_ids" => ["image_alpha_1", "image_alpha_2"],
               "payload_id" => "payload_camera",
               "instrument_id" => "narrow_angle_camera",
               "data_volume_mb" => 42.5,
               "estimated_storage_mb" => 42.5,
               "estimated_downlink_mb" => 40.0,
               "required_downlink_mb" => 40.0
             }
           } = Enum.find(report["rows"], &(&1["activity_id"] == "obs_1"))

    assert %{
             "activity_id" => "cmd_1",
             "activity_type" => "command",
             "direction" => "command",
             "ground_station_id" => "dss_14",
             "locked" => true,
             "operational_kind" => "command",
             "required_operator_action" => "review_command_contact",
             "operator_action_reason" => "command_boundary_requires_review",
             "execution_boundary" => "planned_not_commanded",
             "cadence_import_status" => "missing",
             "activity_context" => %{
               "approval_status" => "pending",
               "ground_station_id" => "dss_14",
               "locked" => true,
               "starts_at_s" => 30.0,
               "ends_at_s" => 40.0,
               "timeline_identity" => %{
                 "activity_id" => "cmd_1",
                 "activity_type" => "command",
                 "subject_id" => "dss_14"
               }
             }
           } = Enum.find(report["rows"], &(&1["activity_id"] == "cmd_1"))

    assert %{
             "activity_id" => "trk_1",
             "activity_type" => "tracking",
             "direction" => "tracking",
             "has_cadence_import" => true,
             "cadence_import_type" => "tracking",
             "cadence_import_id" => "track_1",
             "cadence_import_contract" => "planned_activity.v1",
             "cadence_import_provider" => "cadence",
             "cadence_import_adapter" => "cadence_tracking_adapter",
             "cadence_import_adapter_version" => "2026-05",
             "cadence_import_trust_boundary" => "orbital_dynamics_to_cadence_adapter",
             "cadence_import_provenance" => %{
               "trust_boundary" => "orbital_dynamics_to_cadence_adapter"
             },
             "operational_kind" => "contact",
             "required_operator_action" => "review_activity_approval",
             "cadence_import_status" => "present"
           } = Enum.find(report["rows"], &(&1["activity_id"] == "trk_1"))

    assert %{
             "activity_id" => "cmd_contact",
             "activity_type" => "planned_contact",
             "direction" => "command",
             "ground_station_id" => "dss_14",
             "operational_kind" => "command",
             "required_operator_action" => "review_command_contact",
             "operator_action_reason" => "command_boundary_requires_review",
             "cadence_import_status" => "missing"
           } = Enum.find(report["rows"], &(&1["activity_id"] == "cmd_contact"))

    assert %{
             "activity_id" => "uplink_contact",
             "activity_type" => "planned_contact",
             "direction" => "uplink",
             "ground_station_id" => "dss_14",
             "operational_kind" => "command",
             "required_operator_action" => "review_command_contact",
             "operator_action_reason" => "command_boundary_requires_review",
             "cadence_import_status" => "missing"
           } = Enum.find(report["rows"], &(&1["activity_id"] == "uplink_contact"))

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "canonicalizes provider-shaped cadence import aliases in timeline rows" do
    report =
      Timeline.operational_report([
        %{
          id: :cmd_alias_import,
          type: :command,
          direction: :command,
          ground_station_id: :dss_14,
          starts_at_s: 1.0,
          ends_at_s: 2.0,
          approval_status: :approved,
          cadence_import: %{
            id: :cadence_cmd_alias_import,
            import_type: :command,
            contract: :"proposed_contact.v1",
            provider: :cadence,
            adapter: :cadence_command_adapter,
            trust_boundary: :orbital_dynamics_to_cadence_adapter
          }
        }
      ])

    assert %{
             "cadence_import_status_counts" => %{"present" => 1},
             "required_operator_action_counts" => %{"monitor_activity" => 1}
           } = report

    row = List.first(report["rows"])

    assert %{
             "activity_id" => "cmd_alias_import",
             "cadence_import_status" => "present",
             "has_cadence_import" => true,
             "cadence_import_id" => "cadence_cmd_alias_import",
             "cadence_import_type" => "command",
             "cadence_import_contract" => "proposed_contact.v1",
             "cadence_import_provider" => "cadence",
             "cadence_import_adapter" => "cadence_command_adapter",
             "cadence_import_trust_boundary" => "orbital_dynamics_to_cadence_adapter",
             "activity_context" => %{
               "cadence_import" => %{
                 "external_id" => "cadence_cmd_alias_import",
                 "activity_type" => "command",
                 "schema_contract" => "proposed_contact.v1"
               }
             }
           } = row

    refute Map.has_key?(row["activity_context"]["cadence_import"], "id")
    refute Map.has_key?(row["activity_context"]["cadence_import"], "import_type")
    refute Map.has_key?(row["activity_context"]["cadence_import"], "contract")

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "preserves planned and actual data-volume evidence in activity context" do
    report =
      Timeline.operational_report([
        %{
          id: :obs_product_feedback,
          type: :observe,
          target_id: :target_a,
          starts_at_s: 10.0,
          ends_at_s: 20.0,
          collection_id: :collection_alpha,
          product_id: :image_alpha_1,
          planned_data_volume_mb: 80.0,
          delivered_data_mb: 60.0
        }
      ])

    assert %{
             "activity_id" => "obs_product_feedback",
             "data_volume_mb" => 80.0,
             "planned_data_volume_mb" => 80.0,
             "actual_data_volume_mb" => 60.0,
             "data_volume_delta_mb" => -20.0,
             "data_volume_completion_fraction" => 0.75,
             "activity_context" => %{
               "data_volume_mb" => 80.0,
               "planned_data_volume_mb" => 80.0,
               "actual_data_volume_mb" => 60.0,
               "data_volume_delta_mb" => -20.0,
               "data_volume_completion_fraction" => 0.75
             }
           } = List.first(report["rows"])

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "preserves dependency and exclusivity metadata in timeline rows" do
    report =
      Timeline.operational_report([
        %{
          id: :cmd_2,
          type: :command,
          scenario_id: :leo_1,
          starts_at_s: 20.0,
          ends_at_s: 30.0,
          ground_station_id: :dss_14,
          allow_overlap?: true,
          dependencies: [
            %{activity_id: :obs_1, timeline_id: :"timeline:obs_1"},
            :cmd_prereq
          ],
          metadata: %{
            exclusive_with: [
              %{id: :dl_conflict, timeline_id: :"timeline:dl_conflict"}
            ]
          }
        }
      ])

    assert report["dependency_count"] == 1
    assert report["exclusivity_count"] == 1

    assert [
             %{
               "activity_id" => "cmd_2",
               "allow_overlap" => true,
               "dependency_activity_ids" => ["cmd_prereq", "obs_1"],
               "dependency_timeline_ids" => ["timeline:obs_1"],
               "exclusive_with_activity_ids" => ["dl_conflict"],
               "exclusive_with_timeline_ids" => ["timeline:dl_conflict"],
               "activity_context" => %{
                 "allow_overlap" => true
               }
             }
           ] = report["rows"]

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "normalizes provider scalar dependency and exclusivity id strings in timeline rows" do
    report =
      Timeline.operational_report(
        [
          %{
            id: :cmd_prereq,
            timeline_id: :"timeline:cmd_prereq",
            type: :command,
            scenario_id: :leo_1,
            starts_at_s: 0.0,
            ends_at_s: 5.0,
            ground_station_id: :dss_14
          },
          %{
            id: :dl_conflict,
            timeline_id: :"timeline:dl_conflict",
            type: :downlink,
            scenario_id: :leo_1,
            starts_at_s: 12.0,
            ends_at_s: 22.0,
            ground_station_id: :dss_14
          },
          %{
            id: :cmd_execute,
            timeline_id: :"timeline:cmd_execute",
            type: :command,
            scenario_id: :leo_1,
            starts_at_s: 10.0,
            ends_at_s: 20.0,
            ground_station_id: :dss_14,
            depends_on: "cmd_prereq, missing_gate",
            depends_on_timeline_ids: "timeline:cmd_prereq",
            exclusive_with: "dl_conflict",
            exclusive_with_timeline_ids: "timeline:dl_conflict"
          }
        ],
        validate_missing_dependencies?: true
      )

    assert report["dependency_count"] == 1
    assert report["exclusivity_count"] == 1

    assert %{
             "dependency_activity_ids" => ["cmd_prereq", "missing_gate"],
             "dependency_timeline_ids" => ["timeline:cmd_prereq"],
             "exclusive_with_activity_ids" => ["dl_conflict"],
             "exclusive_with_timeline_ids" => ["timeline:dl_conflict"],
             "missing_dependency_activity_ids" => ["missing_gate"],
             "exclusivity_violation_activity_ids" => ["dl_conflict"]
           } = Enum.find(report["rows"], &(&1["activity_id"] == "cmd_execute"))

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "ignores malformed dependency and exclusivity ids instead of creating phantom links" do
    report =
      Timeline.operational_report(
        [
          %{
            id: :cmd_2,
            type: :command,
            scenario_id: :leo_1,
            starts_at_s: 20.0,
            ends_at_s: 30.0,
            ground_station_id: :dss_14,
            dependencies: [
              nil,
              false,
              "bad dependency id",
              %{activity_id: nil, timeline_id: nil},
              %{activity_id: "bad nested dependency id", timeline_id: "bad timeline id"},
              %{activity_id: :obs_1, timeline_id: :"timeline:obs_1"},
              :cmd_prereq
            ],
            exclusive_with: [
              nil,
              true,
              "bad exclusive id",
              %{id: nil, timeline_id: nil},
              %{id: "bad nested exclusive id", timeline_id: "bad exclusive timeline id"},
              %{id: :dl_conflict, timeline_id: :"timeline:dl_conflict"}
            ]
          }
        ],
        validate_missing_dependencies?: true
      )

    assert [
             %{
               "dependency_activity_ids" => ["cmd_prereq", "obs_1"],
               "dependency_timeline_ids" => ["timeline:obs_1"],
               "exclusive_with_activity_ids" => ["dl_conflict"],
               "exclusive_with_timeline_ids" => ["timeline:dl_conflict"]
             } = row
           ] = report["rows"]

    refute "nil" in row["dependency_activity_ids"]
    refute "false" in row["dependency_activity_ids"]
    refute "bad dependency id" in row["dependency_activity_ids"]
    refute "bad nested dependency id" in row["dependency_activity_ids"]
    refute "bad timeline id" in row["dependency_timeline_ids"]
    refute "true" in row["exclusive_with_activity_ids"]
    refute "bad exclusive id" in row["exclusive_with_activity_ids"]
    refute "bad nested exclusive id" in row["exclusive_with_activity_ids"]
    refute "bad exclusive timeline id" in row["exclusive_with_timeline_ids"]

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "preserves station reservation ownership context through timeline review and import" do
    activity = %{
      id: :dl_reserved_owner,
      type: :downlink,
      scenario_id: :leo_1,
      starts_at_s: 100.0,
      ends_at_s: 160.0,
      ground_station_id: :equator_prime,
      station_availability: "Reserved",
      station_contention_status: "Reserved Overlap",
      station_calendar_status: "Reserved Overlap",
      station_calendar_overlap_availabilities: ["Reserved", "Reduced Capacity"],
      station_calendar_provider_id: :ground_partner_a,
      station_calendar_provider_entry_id: :partner_reserved_window,
      station_reservation_id: :reservation_42,
      station_reservation_expires_at_s: "240.0",
      station_reserved_by: :ops_team_b,
      station_reservation_status: "Confirmed",
      station_reservation_match_status: "Matched",
      station_calendar_reservation_overlap_count: 1,
      station_calendar_reservation_ids: [:reservation_42],
      station_calendar_reservation_expires_at_s: ["240.0", "bad expires"],
      station_calendar_reserved_by: [:ops_team_b],
      station_calendar_reservation_statuses: ["Confirmed"],
      source_station_calendar_entry: %{
        id: :partner_reserved_window,
        availability: "Reserved",
        status: "Reserved Overlap",
        reservation_expires_at_s: "360.0",
        reservation_status: "Confirmed",
        directions: ["s-band command"]
      },
      source_station_calendar_overlaps: [
        %{
          id: :partner_reserved_window,
          availability: "Reserved",
          reservation_expires_at_s: "360.0"
        },
        %{
          id: :partner_capacity_window,
          availability: "Reduced Capacity",
          station_reservation_expires_at_s: 420.0
        }
      ]
    }

    report = Timeline.operational_report([activity])

    assert [
             %{
               "activity_id" => "dl_reserved_owner",
               "station_availability" => "reserved",
               "station_contention_status" => "reserved_overlap",
               "station_calendar_status" => "reserved_overlap",
               "station_calendar_overlap_availabilities" => [
                 "reserved",
                 "reduced_capacity"
               ],
               "station_calendar_provider_id" => "ground_partner_a",
               "station_calendar_provider_entry_id" => "partner_reserved_window",
               "station_reservation_id" => "reservation_42",
               "station_reservation_expires_at_s" => 240.0,
               "station_reserved_by" => "ops_team_b",
               "station_reservation_status" => "confirmed",
               "station_reservation_match_status" => "matched",
               "station_calendar_reservation_expires_at_s" => [240.0, 360.0, 420.0],
               "station_calendar_directions" => ["command"],
               "activity_context" => %{
                 "station_availability" => "reserved",
                 "station_contention_status" => "reserved_overlap",
                 "station_calendar_status" => "reserved_overlap",
                 "station_calendar_overlap_availabilities" => [
                   "reserved",
                   "reduced_capacity"
                 ],
                 "station_calendar_provider_id" => "ground_partner_a",
                 "station_calendar_provider_entry_id" => "partner_reserved_window",
                 "station_reservation_id" => "reservation_42",
                 "station_reservation_expires_at_s" => 240.0,
                 "station_reservation_status" => "confirmed",
                 "station_reservation_match_status" => "matched",
                 "station_calendar_reservation_expires_at_s" => [240.0, 360.0, 420.0],
                 "station_calendar_directions" => ["command"],
                 "source_station_calendar_entry" => %{
                   "id" => "partner_reserved_window",
                   "availability" => "reserved",
                   "status" => "reserved_overlap",
                   "reservation_expires_at_s" => "360.0",
                   "reservation_status" => "confirmed",
                   "directions" => ["s-band command"]
                 },
                 "source_station_calendar_overlaps" => [
                   %{"id" => "partner_reserved_window", "availability" => "reserved"},
                   %{"id" => "partner_capacity_window", "availability" => "reduced_capacity"}
                 ]
               }
             }
           ] = report["rows"]

    assert %{
             "station_calendar_provider_id" => "ground_partner_a",
             "station_calendar_provider_entry_id" => "partner_reserved_window",
             "station_reservation_id" => "reservation_42",
             "station_reservation_expires_at_s" => 240.0,
             "station_reservation_status" => "confirmed",
             "station_reservation_match_status" => "matched",
             "station_calendar_reservation_expires_at_s" => [240.0, 360.0, 420.0],
             "station_calendar_directions" => ["command"],
             "activity_context" => %{
               "station_calendar_provider_id" => "ground_partner_a",
               "station_calendar_provider_entry_id" => "partner_reserved_window",
               "station_reservation_id" => "reservation_42",
               "station_reservation_expires_at_s" => 240.0,
               "station_reservation_status" => "confirmed",
               "station_reservation_match_status" => "matched",
               "station_calendar_reservation_expires_at_s" => [240.0, 360.0, 420.0],
               "station_calendar_directions" => ["command"]
             }
           } = Timeline.normalize_activity(activity)

    review = OperatorReview.from_operational_timeline_report(report)
    import = CadenceImport.from_operational_timeline_report(report)

    assert %{
             "activity_id" => "dl_reserved_owner",
             "station_reservation_id" => "reservation_42",
             "station_reservation_expires_at_s" => 240.0,
             "station_calendar_reservation_expires_at_s" => [240.0, 360.0, 420.0],
             "station_reservation_match_status" => "matched",
             "source_activity_context" => %{
               "station_reservation_id" => "reservation_42",
               "station_reservation_expires_at_s" => 240.0,
               "station_calendar_reservation_expires_at_s" => [240.0, 360.0, 420.0],
               "station_reservation_match_status" => "matched"
             }
           } = List.first(review["rows"])

    assert %{
             "activity_id" => "dl_reserved_owner",
             "station_reservation_id" => "reservation_42",
             "station_reservation_expires_at_s" => 240.0,
             "station_calendar_reservation_expires_at_s" => [240.0, 360.0, 420.0],
             "station_reservation_match_status" => "matched",
             "import_activity_context" => %{
               "station_reservation_id" => "reservation_42",
               "station_reservation_expires_at_s" => 240.0,
               "station_calendar_reservation_expires_at_s" => [240.0, 360.0, 420.0],
               "station_reservation_match_status" => "matched"
             }
           } = List.first(import["rows"])

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "ignores malformed station-calendar overlay list ids instead of creating phantom links" do
    report =
      Timeline.operational_report([
        %{
          id: :dl_calendar_overlay,
          type: :downlink,
          scenario_id: :leo_1,
          starts_at_s: 100.0,
          ends_at_s: 160.0,
          ground_station_id: :equator_prime,
          station_availability: :reserved,
          station_calendar_overlap_entry_ids: [
            :calendar_entry_1,
            "bad calendar entry id",
            %{id: :calendar_entry_2},
            %{id: "bad nested calendar id"}
          ],
          station_calendar_ambiguous_entry_ids: [
            :calendar_entry_3,
            "bad ambiguous calendar id"
          ],
          station_calendar_reservation_ids: [
            :reservation_42,
            "bad reservation id",
            %{station_reservation_id: :reservation_43},
            %{station_reservation_id: "bad nested reservation id"}
          ]
        }
      ])

    assert [
             %{
               "station_calendar_overlap_entry_ids" => [
                 "calendar_entry_1",
                 "calendar_entry_2"
               ],
               "station_calendar_ambiguous_entry_ids" => ["calendar_entry_3"],
               "station_calendar_reservation_ids" => ["reservation_42", "reservation_43"],
               "activity_context" => %{
                 "station_calendar_overlap_entry_ids" => [
                   "calendar_entry_1",
                   "calendar_entry_2"
                 ],
                 "station_calendar_ambiguous_entry_ids" => ["calendar_entry_3"],
                 "station_calendar_reservation_ids" => ["reservation_42", "reservation_43"]
               }
             } = row
           ] = report["rows"]

    refute "bad calendar entry id" in row["station_calendar_overlap_entry_ids"]
    refute "bad nested calendar id" in row["station_calendar_overlap_entry_ids"]
    refute "bad ambiguous calendar id" in row["station_calendar_ambiguous_entry_ids"]
    refute "bad reservation id" in row["station_calendar_reservation_ids"]
    refute "bad nested reservation id" in row["station_calendar_reservation_ids"]

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "routes timeline dependency and exclusivity integrity issues to review" do
    report =
      Timeline.operational_report(
        [
          %{
            id: :health_gate,
            type: :health_check,
            scenario_id: :leo_1,
            starts_at_s: 0.0,
            ends_at_s: 15.0,
            ground_station_id: :dss_14,
            direction: :command
          },
          %{
            id: :cmd_main,
            type: :command,
            scenario_id: :leo_1,
            starts_at_s: 10.0,
            ends_at_s: 20.0,
            ground_station_id: :dss_14,
            direction: :command,
            dependencies: [:health_gate, :missing_gate],
            exclusive_with: [:dl_conflict],
            exclusivity_group: :station_dss_14
          },
          %{
            id: :dl_conflict,
            type: :downlink,
            scenario_id: :leo_1,
            starts_at_s: 12.0,
            ends_at_s: 22.0,
            ground_station_id: :dss_14,
            direction: :downlink,
            exclusivity_group: :station_dss_14,
            cadence_import: %{
              activity_type: :contact,
              external_id: :dl_conflict,
              schema_contract: :"proposed_contact.v1"
            }
          }
        ],
        validate_missing_dependencies?: true
      )

    assert report["timeline_integrity_review_count"] == 2
    assert report["timeline_integrity_issue_count"] == 5
    assert report["dependency_issue_count"] == 2
    assert report["exclusivity_issue_count"] == 3

    assert %{
             "activity_id" => "cmd_main",
             "required_operator_action" => "review_timeline_integrity",
             "operator_action_reason" => "timeline_integrity_issue",
             "superseded_required_operator_action" => "review_command_contact",
             "timeline_integrity_status" => "review_required",
             "timeline_integrity_issue_count" => 4,
             "missing_dependency_activity_ids" => ["missing_gate"],
             "dependency_order_violation_activity_ids" => ["health_gate"],
             "exclusivity_violation_activity_ids" => ["dl_conflict"],
             "exclusivity_violation_timeline_ids" => ["timeline:leo_1:downlink:dss_14:12.0"],
             "exclusivity_violation_group" => "station_dss_14"
           } = cmd_row = Enum.find(report["rows"], &(&1["activity_id"] == "cmd_main"))

    assert "dependency_order_violation" in cmd_row["timeline_integrity_issue_types"]
    assert "missing_dependency_activity" in cmd_row["timeline_integrity_issue_types"]
    assert "exclusivity_group_overlap" in cmd_row["timeline_integrity_issue_types"]
    assert "exclusivity_overlap" in cmd_row["timeline_integrity_issue_types"]

    assert %{
             "activity_id" => "dl_conflict",
             "required_operator_action" => "review_timeline_integrity",
             "superseded_required_operator_action" => "review_activity_approval",
             "timeline_integrity_status" => "review_required",
             "exclusivity_violation_activity_ids" => ["cmd_main"],
             "exclusivity_violation_timeline_ids" => ["timeline:leo_1:command:dss_14:10.0"],
             "exclusivity_violation_group" => "station_dss_14"
           } = Enum.find(report["rows"], &(&1["activity_id"] == "dl_conflict"))

    review = OperatorReview.from_operational_timeline_report(report)
    import = CadenceImport.from_operational_timeline_report(report)

    assert %{
             "required_operator_action" => "review_timeline_integrity",
             "timeline_integrity_status" => "review_required",
             "missing_dependency_activity_ids" => ["missing_gate"],
             "dependency_order_violation_activity_ids" => ["health_gate"],
             "exclusivity_violation_activity_ids" => ["dl_conflict"],
             "exclusivity_violation_timeline_ids" => ["timeline:leo_1:downlink:dss_14:12.0"]
           } = Enum.find(review["rows"], &(&1["activity_id"] == "cmd_main"))

    assert %{
             "source_review_action" => "review_timeline_integrity",
             "timeline_integrity_status" => "review_required",
             "missing_dependency_activity_ids" => ["missing_gate"],
             "dependency_order_violation_activity_ids" => ["health_gate"],
             "exclusivity_violation_activity_ids" => ["dl_conflict"],
             "exclusivity_violation_timeline_ids" => ["timeline:leo_1:downlink:dss_14:12.0"]
           } = Enum.find(import["rows"], &(&1["activity_id"] == "cmd_main"))

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "preserves timeline-id dependency integrity evidence in review and import handoffs" do
    report =
      Timeline.operational_report(
        [
          %{
            id: :prep,
            timeline_id: "timeline:prep",
            type: :health_check,
            scenario_id: :leo_1,
            starts_at_s: 20.0,
            ends_at_s: 30.0,
            ground_station_id: :dss_14,
            direction: :command
          },
          %{
            id: :cmd,
            timeline_id: "timeline:cmd",
            type: :command,
            scenario_id: :leo_1,
            starts_at_s: 10.0,
            ends_at_s: 15.0,
            ground_station_id: :dss_14,
            direction: :command,
            dependency_timeline_ids: ["timeline:prep", "timeline:missing", "timeline:cmd"],
            exclusive_with_timeline_ids: ["timeline:dl_conflict"]
          },
          %{
            id: :dl_conflict,
            timeline_id: "timeline:dl_conflict",
            type: :downlink,
            scenario_id: :leo_1,
            starts_at_s: 12.0,
            ends_at_s: 18.0,
            ground_station_id: :dss_14,
            direction: :downlink
          }
        ],
        validate_missing_dependencies?: true
      )

    assert report["timeline_integrity_review_count"] == 1
    assert report["timeline_integrity_issue_count"] == 4

    expected_dependency_context = %{
      "missing_dependency_timeline_ids" => ["timeline:missing"],
      "self_dependency_timeline_ids" => ["timeline:cmd"],
      "dependency_order_violation_timeline_ids" => ["timeline:prep"],
      "exclusivity_violation_activity_ids" => ["dl_conflict"],
      "exclusivity_violation_timeline_ids" => ["timeline:dl_conflict"]
    }

    assert expected_dependency_context
           |> Map.merge(%{
             "required_operator_action" => "review_timeline_integrity",
             "timeline_integrity_issue_types" => [
               "dependency_order_violation",
               "exclusivity_overlap",
               "missing_dependency_timeline",
               "self_dependency_timeline"
             ]
           })
           |> Map.take(
             Map.keys(expected_dependency_context) ++
               [
                 "required_operator_action",
                 "timeline_integrity_issue_types"
               ]
           ) ==
             report["rows"]
             |> Enum.find(&(&1["activity_id"] == "cmd"))
             |> Map.take(
               Map.keys(expected_dependency_context) ++
                 [
                   "required_operator_action",
                   "timeline_integrity_issue_types"
                 ]
             )

    review = OperatorReview.from_operational_timeline_report(report)
    import = CadenceImport.from_operational_timeline_report(report)

    review_row = Enum.find(review["rows"], &(&1["activity_id"] == "cmd"))
    import_row = Enum.find(import["rows"], &(&1["activity_id"] == "cmd"))

    assert Map.take(review_row, Map.keys(expected_dependency_context)) ==
             expected_dependency_context

    assert Map.take(import_row, Map.keys(expected_dependency_context)) ==
             expected_dependency_context

    assert Map.take(import_row["source_review_row"], Map.keys(expected_dependency_context)) ==
             expected_dependency_context

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "builds public timeline integrity summaries for dependency and exclusivity review" do
    activities = [
      %{
        id: :health_gate,
        type: :health_check,
        starts_at_s: 0.0,
        ends_at_s: 15.0,
        ground_station_id: :dss_14,
        direction: :command
      },
      %{
        id: :cmd_main,
        type: :command,
        starts_at_s: 10.0,
        ends_at_s: 20.0,
        ground_station_id: :dss_14,
        direction: :command,
        dependencies: [:health_gate, :missing_gate],
        exclusive_with: [:dl_conflict]
      },
      %{
        id: :dl_conflict,
        type: :downlink,
        starts_at_s: 12.0,
        ends_at_s: 22.0,
        ground_station_id: :dss_14,
        direction: :downlink
      }
    ]

    assert %{
             "schema_contract" => "timeline_integrity_report.v1",
             "model" => "artifact_only_timeline_integrity_summary",
             "validation_level" => "artifact_contract",
             "source" => "timeline.activities",
             "activity_count" => 3,
             "valid_activity_count" => 3,
             "invalid_activity_input_count" => 0,
             "timeline_integrity_status" => "review_required",
             "timeline_integrity_review_count" => 1,
             "timeline_integrity_issue_count" => 3,
             "timeline_integrity_issue_types" => [
               "dependency_order_violation",
               "exclusivity_overlap",
               "missing_dependency_activity"
             ],
             "timeline_integrity_issue_type_counts" => %{
               "dependency_order_violation" => 1,
               "exclusivity_overlap" => 1,
               "missing_dependency_activity" => 1
             },
             "required_operator_action_counts" => %{"review_timeline_integrity" => 1},
             "operator_action_reason_counts" => %{"timeline_integrity_issue" => 1},
             "dependency_issue_count" => 2,
             "exclusivity_issue_count" => 1,
             "review_activity_ids" => ["cmd_main"],
             "review_timeline_ids" => ["timeline:command:dss_14:10.0"],
             "review_activity_ids_by_issue_type" => %{
               "dependency_order_violation" => ["cmd_main"],
               "exclusivity_overlap" => ["cmd_main"],
               "missing_dependency_activity" => ["cmd_main"]
             },
             "review_timeline_ids_by_issue_type" => %{
               "dependency_order_violation" => ["timeline:command:dss_14:10.0"],
               "exclusivity_overlap" => ["timeline:command:dss_14:10.0"],
               "missing_dependency_activity" => ["timeline:command:dss_14:10.0"]
             },
             "review_activity_ids_by_required_operator_action" => %{
               "review_timeline_integrity" => ["cmd_main"]
             },
             "review_timeline_ids_by_required_operator_action" => %{
               "review_timeline_integrity" => ["timeline:command:dss_14:10.0"]
             },
             "review_activity_ids_by_operator_action_reason" => %{
               "timeline_integrity_issue" => ["cmd_main"]
             },
             "review_timeline_ids_by_operator_action_reason" => %{
               "timeline_integrity_issue" => ["timeline:command:dss_14:10.0"]
             },
             "dependency_review_activity_ids" => ["cmd_main"],
             "dependency_review_timeline_ids" => ["timeline:command:dss_14:10.0"],
             "exclusivity_review_activity_ids" => ["cmd_main"],
             "exclusivity_review_timeline_ids" => ["timeline:command:dss_14:10.0"],
             "invalid_activity_input_ids" => [],
             "missing_dependency_activity_ids" => ["missing_gate"],
             "missing_dependency_timeline_ids" => [],
             "dependency_cycle_activity_ids" => [],
             "dependency_cycle_timeline_ids" => [],
             "dependency_order_violation_activity_ids" => ["health_gate"],
             "dependency_order_violation_timeline_ids" => [],
             "exclusivity_violation_activity_ids" => ["dl_conflict"],
             "exclusivity_violation_timeline_ids" => ["timeline:downlink:dss_14:12.0"],
             "rows" => [
               %{
                 "activity_id" => "cmd_main",
                 "required_operator_action" => "review_timeline_integrity",
                 "timeline_integrity_status" => "review_required",
                 "missing_dependency_activity_ids" => ["missing_gate"],
                 "dependency_order_violation_activity_ids" => ["health_gate"],
                 "exclusivity_violation_activity_ids" => ["dl_conflict"],
                 "exclusivity_violation_timeline_ids" => ["timeline:downlink:dss_14:12.0"]
               }
             ],
             "assumptions" => %{
               "missing_dependency_validation" => "enabled",
               "execution_boundary" => "artifact_only_no_schedule_mutation"
             },
             "model_limits" => model_limits
           } = integrity_report = Timeline.integrity_report(activities)

    assert "no_schedule_mutation" in model_limits
    assert "no_command_execution" in model_limits
    assert OrbitalDynamics.timeline_integrity_report(activities) == integrity_report

    assert {:ok, %{"schema_contract" => "timeline_integrity_report.v1"}} =
             Schema.validate_artifact(integrity_report)

    atom_key_integrity_report =
      integrity_report
      |> Map.delete("schema_contract")
      |> Map.put(:schema_contract, "timeline_integrity_report.v1")

    assert Timeline.integrity_report(integrity_report) == integrity_report
    assert Timeline.integrity_report(atom_key_integrity_report) == integrity_report
    assert OrbitalDynamics.timeline_integrity_report(integrity_report) == integrity_report

    invalid_template_report =
      Timeline.integrity_report([
        %{
          id: :cmd_invalid_template,
          type: :command,
          starts_at_s: 10.0,
          ends_at_s: 20.0,
          dependency_activity_ids: [:missing_gate],
          activity_template: "not-a-map"
        }
      ])

    invalid_template_row = hd(invalid_template_report["rows"])
    refute Map.has_key?(invalid_template_row, "activity_template")
    refute Map.has_key?(invalid_template_row["activity_context"], "activity_template")

    template_hint_activity = %{
      id: :cmd_template_hints,
      type: :command,
      activity_template: %{
        schema_contract: :"activity_template.v1",
        id: :command_template,
        activity_type: :command,
        operational_hints: %{
          setup_duration_s: 42.0,
          cooldown_duration_s: 6.0,
          telemetry_confirmation_required: true,
          telemetry_confirmation_status: :required
        }
      }
    }

    assert %{
             "setup_duration_s" => 42.0,
             "cooldown_duration_s" => 6.0,
             "telemetry_confirmation_required" => true,
             "telemetry_confirmation_status" => "required",
             "activity_context" => %{
               "setup_duration_s" => 42.0,
               "cooldown_duration_s" => 6.0,
               "telemetry_confirmation_required" => true,
               "telemetry_confirmation_status" => "required"
             }
           } =
             template_hint_row = hd(Timeline.operational_report([template_hint_activity])["rows"])

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(Timeline.operational_report([template_hint_activity]))

    assert Timeline.activity_context(template_hint_activity)
           |> Map.take([
             "setup_duration_s",
             "cooldown_duration_s",
             "telemetry_confirmation_required",
             "telemetry_confirmation_status"
           ]) == %{
             "setup_duration_s" => 42.0,
             "cooldown_duration_s" => 6.0,
             "telemetry_confirmation_required" => true,
             "telemetry_confirmation_status" => "required"
           }

    assert get_in(template_hint_row, [
             "activity_template",
             "operational_hints",
             "setup_duration_s"
           ]) == 42.0

    explicit_hint_activity =
      template_hint_activity
      |> Map.put(:id, :cmd_explicit_hints)
      |> Map.merge(%{
        setup_duration_s: 12.0,
        cooldown_duration_s: 3.0,
        telemetry_confirmation_required: false,
        telemetry_confirmation_status: :waived
      })

    assert %{
             "setup_duration_s" => 12.0,
             "cooldown_duration_s" => 3.0,
             "telemetry_confirmation_required" => false,
             "telemetry_confirmation_status" => "waived",
             "activity_context" => %{
               "setup_duration_s" => 12.0,
               "cooldown_duration_s" => 3.0,
               "telemetry_confirmation_required" => false,
               "telemetry_confirmation_status" => "waived"
             }
           } = hd(Timeline.operational_report([explicit_hint_activity])["rows"])

    malformed_hint_activity =
      template_hint_activity
      |> Map.put(:id, :cmd_malformed_hints)
      |> put_in([:activity_template, :operational_hints], "not-a-map")
      |> Map.merge(%{
        setup_duration_s: "soon",
        telemetry_confirmation_required: "maybe"
      })

    malformed_hint_row = hd(Timeline.operational_report([malformed_hint_activity])["rows"])
    refute Map.has_key?(malformed_hint_row, "setup_duration_s")
    refute Map.has_key?(malformed_hint_row, "telemetry_confirmation_required")
    refute Map.has_key?(malformed_hint_row["activity_context"], "setup_duration_s")
    refute Map.has_key?(malformed_hint_row["activity_context"], "telemetry_confirmation_required")
    refute Map.has_key?(malformed_hint_row["activity_template"], "operational_hints")

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(Timeline.operational_report([malformed_hint_activity]))

    stale_review_count = Map.put(integrity_report, "timeline_integrity_review_count", 99)

    assert {:error, stale_review_count_validation} =
             Schema.validate_artifact(stale_review_count)

    assert Enum.any?(
             stale_review_count_validation["errors"],
             &(&1["path"] == "$.timeline_integrity_review_count" and
                 &1["message"] == "must equal row-derived timeline_integrity_review_count")
           )

    assert %{
             "schema_contract" => "timeline_integrity_report.v1",
             "timeline_integrity_status" => "clear",
             "timeline_integrity_review_count" => 0,
             "timeline_integrity_issue_count" => 0,
             "timeline_integrity_issue_types" => [],
             "timeline_integrity_issue_type_counts" => %{},
             "required_operator_action_counts" => %{},
             "operator_action_reason_counts" => %{},
             "review_activity_ids" => [],
             "review_timeline_ids" => [],
             "review_activity_ids_by_issue_type" => %{},
             "review_timeline_ids_by_issue_type" => %{},
             "review_activity_ids_by_required_operator_action" => %{},
             "review_timeline_ids_by_required_operator_action" => %{},
             "rows" => []
           } =
             Timeline.integrity_report([
               %{id: :cmd_ok, type: :command, starts_at_s: 20.0, ends_at_s: 30.0}
             ])

    assert %{
             "assumptions" => %{"missing_dependency_validation" => "disabled"},
             "timeline_integrity_issue_types" => disabled_missing_issue_types
           } = Timeline.integrity_report(activities, validate_missing_dependencies?: false)

    assert "dependency_order_violation" in disabled_missing_issue_types
    assert "exclusivity_overlap" in disabled_missing_issue_types
    refute "missing_dependency_activity" in disabled_missing_issue_types

    assert_raise ArgumentError, ~r/activities must be a list/, fn ->
      Timeline.integrity_report(:not_a_list)
    end
  end

  test "summarizes downstream dependency impact from changed or removed source work" do
    source = [
      %{
        id: :health_gate,
        type: :health_check,
        starts_at_s: 0.0,
        ends_at_s: 10.0
      },
      %{
        id: :cmd_main,
        type: :command,
        starts_at_s: 20.0,
        ends_at_s: 30.0,
        dependencies: [:health_gate]
      },
      %{
        id: :dl_followup,
        timeline_id: :"timeline:dl_followup",
        type: :downlink,
        starts_at_s: 40.0,
        ends_at_s: 55.0,
        dependencies: [:cmd_main]
      },
      %{
        id: :obs_parallel,
        type: :observe,
        starts_at_s: 60.0,
        ends_at_s: 70.0,
        exclusive_with: [:dl_followup],
        exclusive_with_timeline_ids: [:"timeline:dl_followup"]
      }
    ]

    replacement = [
      %{
        id: :health_gate,
        type: :health_check,
        starts_at_s: 5.0,
        ends_at_s: 15.0
      },
      %{
        id: :cmd_main,
        type: :command,
        starts_at_s: 20.0,
        ends_at_s: 30.0,
        dependencies: [:health_gate]
      },
      %{
        id: :obs_parallel,
        type: :observe,
        starts_at_s: 60.0,
        ends_at_s: 70.0,
        exclusive_with: [:dl_followup],
        exclusive_with_timeline_ids: [:"timeline:dl_followup"]
      }
    ]

    assert %{
             "schema_contract" => "timeline_dependency_impact_summary.v1",
             "model" => "artifact_only_timeline_dependency_impact_summary",
             "validation_level" => "artifact_contract",
             "source" => "timeline_diff_report.v1",
             "source_activity_count" => 4,
             "replacement_activity_count" => 3,
             "changed_source_activity_count" => 2,
             "changed_source_timeline_count" => 2,
             "dependency_impact_status" => "review_required",
             "dependent_activity_count" => 4,
             "source_dependent_activity_count" => 2,
             "replacement_dependent_activity_count" => 2,
             "impacted_source_activity_ids" => ["dl_followup", "health_gate"],
             "impacted_source_timeline_ids" => [
               "timeline:dl_followup",
               "timeline:health_check:0.0"
             ],
             "dependent_activity_ids" => ["cmd_main", "obs_parallel"],
             "dependent_timeline_ids" => [
               "timeline:command:20.0",
               "timeline:observe:60.0"
             ],
             "source_dependent_activity_ids" => ["cmd_main", "obs_parallel"],
             "source_dependent_timeline_ids" => [
               "timeline:command:20.0",
               "timeline:observe:60.0"
             ],
             "replacement_dependent_activity_ids" => ["cmd_main", "obs_parallel"],
             "replacement_dependent_timeline_ids" => [
               "timeline:command:20.0",
               "timeline:observe:60.0"
             ],
             "impacted_dependency_activity_ids" => ["health_gate"],
             "impacted_dependency_timeline_ids" => [],
             "impacted_exclusive_with_activity_ids" => ["dl_followup"],
             "impacted_exclusive_with_timeline_ids" => ["timeline:dl_followup"],
             "dependency_impact_rows" => [
               %{
                 "scope" => "source",
                 "activity_id" => "cmd_main",
                 "required_operator_action" => "review_timeline_integrity",
                 "operator_action_reason" => "dependency_changed_or_removed_source_activity",
                 "impacted_dependency_activity_ids" => ["health_gate"]
               },
               %{
                 "scope" => "source",
                 "activity_id" => "obs_parallel",
                 "required_operator_action" => "review_timeline_integrity",
                 "operator_action_reason" => "exclusivity_changed_or_removed_source_activity",
                 "exclusive_with_activity_ids" => ["dl_followup"],
                 "exclusive_with_timeline_ids" => ["timeline:dl_followup"],
                 "impacted_exclusive_with_activity_ids" => ["dl_followup"],
                 "impacted_exclusive_with_timeline_ids" => ["timeline:dl_followup"]
               },
               %{
                 "scope" => "replacement",
                 "activity_id" => "cmd_main",
                 "required_operator_action" => "review_timeline_integrity",
                 "operator_action_reason" => "dependency_changed_or_removed_source_activity",
                 "impacted_dependency_activity_ids" => ["health_gate"]
               },
               %{
                 "scope" => "replacement",
                 "activity_id" => "obs_parallel",
                 "required_operator_action" => "review_timeline_integrity",
                 "operator_action_reason" => "exclusivity_changed_or_removed_source_activity",
                 "exclusive_with_activity_ids" => ["dl_followup"],
                 "exclusive_with_timeline_ids" => ["timeline:dl_followup"],
                 "impacted_exclusive_with_activity_ids" => ["dl_followup"],
                 "impacted_exclusive_with_timeline_ids" => ["timeline:dl_followup"]
               }
             ],
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_schedule_mutation",
               "operator_authority" => "not_granted_by_summary"
             },
             "model_limits" => model_limits
           } = summary = Timeline.dependency_impact_summary(source, replacement)

    assert "artifact_level_only" in model_limits
    assert OrbitalDynamics.timeline_dependency_impact_summary(source, replacement) == summary
    advertised_statuses = Timeline.capabilities().dependency_impact_statuses
    assert summary["dependency_impact_status"] in advertised_statuses

    assert {:ok, %{"schema_contract" => "timeline_dependency_impact_summary.v1"}} =
             Schema.validate_artifact(summary)

    stale_dependent_count = Map.put(summary, "dependent_activity_count", 3)

    assert {:error, stale_dependent_count_report} =
             Schema.validate_artifact(stale_dependent_count)

    assert Enum.any?(
             stale_dependent_count_report["errors"],
             &(&1["path"] == "$.dependent_activity_count" and
                 &1["message"] == "must equal row-derived dependent_activity_count")
           )

    stale_impacted_ids = Map.put(summary, "impacted_dependency_activity_ids", ["wrong_gate"])

    assert {:error, stale_impacted_ids_report} = Schema.validate_artifact(stale_impacted_ids)

    assert Enum.any?(
             stale_impacted_ids_report["errors"],
             &(&1["path"] == "$.impacted_dependency_activity_ids" and
                 &1["message"] == "must equal row-derived impacted_dependency_activity_ids")
           )

    stale_exclusivity_activity_ids =
      Map.put(summary, "impacted_exclusive_with_activity_ids", ["wrong_exclusive_activity"])

    assert {:error, stale_exclusivity_activity_ids_report} =
             Schema.validate_artifact(stale_exclusivity_activity_ids)

    assert Enum.any?(
             stale_exclusivity_activity_ids_report["errors"],
             &(&1["path"] == "$.impacted_exclusive_with_activity_ids" and
                 &1["message"] == "must equal row-derived impacted_exclusive_with_activity_ids")
           )

    stale_exclusivity_timeline_ids =
      Map.put(summary, "impacted_exclusive_with_timeline_ids", ["timeline:wrong_exclusive"])

    assert {:error, stale_exclusivity_timeline_ids_report} =
             Schema.validate_artifact(stale_exclusivity_timeline_ids)

    assert Enum.any?(
             stale_exclusivity_timeline_ids_report["errors"],
             &(&1["path"] == "$.impacted_exclusive_with_timeline_ids" and
                 &1["message"] == "must equal row-derived impacted_exclusive_with_timeline_ids")
           )

    assert %{
             "schema_contract" => "timeline_dependency_impact_summary.v1",
             "dependency_impact_status" => "clear",
             "dependent_activity_count" => 0,
             "dependency_impact_rows" => []
           } = Timeline.dependency_impact_summary(source, source)

    assert "clear" in advertised_statuses

    assert_raise ArgumentError, ~r/source and replacement activities must be lists/, fn ->
      Timeline.dependency_impact_summary(:not_a_list, replacement)
    end
  end

  test "summarizes dependency impact from timeline-id dependencies and combined exclusivity" do
    source = [
      %{
        id: :health_gate,
        type: :health_check,
        starts_at_s: 0.0,
        ends_at_s: 10.0
      },
      %{
        id: :cmd_combo,
        type: :command,
        starts_at_s: 20.0,
        ends_at_s: 30.0,
        dependency_timeline_ids: [:"timeline:health_check:0.0"],
        exclusive_with: [:health_gate]
      }
    ]

    replacement = [
      %{
        id: :health_gate,
        type: :health_check,
        starts_at_s: 5.0,
        ends_at_s: 15.0
      },
      %{
        id: :cmd_combo,
        type: :command,
        starts_at_s: 20.0,
        ends_at_s: 30.0,
        dependency_timeline_ids: [:"timeline:health_check:0.0"],
        exclusive_with: [:health_gate]
      }
    ]

    assert %{
             "dependency_impact_status" => "review_required",
             "dependent_activity_count" => 2,
             "source_dependent_activity_ids" => ["cmd_combo"],
             "replacement_dependent_activity_ids" => ["cmd_combo"],
             "impacted_source_activity_ids" => ["health_gate"],
             "impacted_source_timeline_ids" => ["timeline:health_check:0.0"],
             "impacted_dependency_activity_ids" => [],
             "impacted_dependency_timeline_ids" => ["timeline:health_check:0.0"],
             "impacted_exclusive_with_activity_ids" => ["health_gate"],
             "dependency_impact_rows" => [
               %{
                 "scope" => "source",
                 "activity_id" => "cmd_combo",
                 "dependency_timeline_ids" => ["timeline:health_check:0.0"],
                 "exclusive_with_activity_ids" => ["health_gate"],
                 "operator_action_reason" =>
                   "dependency_and_exclusivity_changed_or_removed_source_activity",
                 "impacted_dependency_timeline_ids" => ["timeline:health_check:0.0"],
                 "impacted_exclusive_with_activity_ids" => ["health_gate"]
               },
               %{
                 "scope" => "replacement",
                 "activity_id" => "cmd_combo",
                 "dependency_timeline_ids" => ["timeline:health_check:0.0"],
                 "exclusive_with_activity_ids" => ["health_gate"],
                 "operator_action_reason" =>
                   "dependency_and_exclusivity_changed_or_removed_source_activity",
                 "impacted_dependency_timeline_ids" => ["timeline:health_check:0.0"],
                 "impacted_exclusive_with_activity_ids" => ["health_gate"]
               }
             ]
           } = summary = Timeline.dependency_impact_summary(source, replacement)

    assert OrbitalDynamics.timeline_dependency_impact_summary(source, replacement) == summary
  end

  test "builds artifact-only timeline publication summaries with downstream impact metadata" do
    source = [
      %{id: :health_gate, type: :health_check, starts_at_s: 0.0, ends_at_s: 10.0},
      %{
        id: :cmd_main,
        type: :command,
        starts_at_s: 20.0,
        ends_at_s: 30.0,
        dependencies: [:health_gate]
      }
    ]

    replacement = [
      %{id: :health_gate, type: :health_check, starts_at_s: 5.0, ends_at_s: 15.0},
      %{
        id: :cmd_main,
        type: :command,
        starts_at_s: 20.0,
        ends_at_s: 30.0,
        dependencies: [:health_gate]
      }
    ]

    dependency_impact = Timeline.dependency_impact_summary(source, replacement)
    timeline_diff_summary = Timeline.diff_summary(source, replacement)

    source_artifact = %{
      "schema_contract" => "operational_timeline_report.v1",
      "id" => "timeline:published_plan:v2"
    }

    assert %{
             "schema_contract" => "timeline_publication_summary.v1",
             "model" => "artifact_only_timeline_publication_summary",
             "validation_level" => "artifact_contract",
             "source" => "operational_timeline_report.v1",
             "publication_id" =>
               "timeline_publication:7:timeline:published_plan:v2:timeline:published_plan:v1",
             "publication_sequence" => 7,
             "publication_status" => "published_with_downstream_invalidations",
             "publication_authority" => "mission_operations",
             "source_artifact_id" => "timeline:published_plan:v2",
             "source_artifact_type" => "operational_timeline_report.v1",
             "supersedes_artifact_ids" => ["timeline:published_plan:v1"],
             "downstream_product_ids" => ["cadence_import:plan:v1", "operator_review:plan:v1"],
             "invalidated_downstream_product_ids" => [
               "cadence_import:plan:v1",
               "operator_review:plan:v1"
             ],
             "dependency_impact_status" => "review_required",
             "dependency_impact_row_count" => 2,
             "impacted_dependency_activity_ids" => ["health_gate"],
             "impacted_dependency_timeline_ids" => [],
             "impacted_exclusive_with_activity_ids" => [],
             "impacted_exclusive_with_timeline_ids" => [],
             "source_timeline_diff_summary" => ^timeline_diff_summary,
             "timeline_diff_row_count" => 3,
             "timeline_diff_changed_count" => 0,
             "timeline_diff_review_required_count" => 2,
             "changed_field_counts" => %{"timeline_presence" => 2},
             "changed_timeline_ids" => [],
             "review_timeline_ids" => ["timeline:health_check:0.0", "timeline:health_check:5.0"],
             "timeline_ids_by_changed_field" => %{
               "timeline_presence" => ["timeline:health_check:0.0", "timeline:health_check:5.0"]
             },
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_schedule_mutation",
               "notification_delivery" => "host_system_owned",
               "publication_authority" => "mission_operations",
               "operator_authority" => "not_granted_by_summary"
             },
             "model_limits" => model_limits
           } =
             summary =
             Timeline.publication_summary(source_artifact,
               publication_sequence: "7",
               publication_authority: :mission_operations,
               supersedes_artifact_ids: ["timeline:published_plan:v1"],
               downstream_product_ids: [
                 "operator_review:plan:v1",
                 "cadence_import:plan:v1",
                 "operator_review:plan:v1"
               ],
               dependency_impact_summary: dependency_impact,
               timeline_diff_summary: timeline_diff_summary
             )

    assert "artifact_level_only" in model_limits
    advertised_statuses = Timeline.capabilities()

    assert summary["publication_status"] in advertised_statuses.publication_statuses

    assert summary["dependency_impact_status"] in advertised_statuses.publication_dependency_impact_statuses

    assert OrbitalDynamics.timeline_publication_summary(source_artifact,
             publication_sequence: 7,
             publication_authority: :mission_operations,
             supersedes_artifact_ids: ["timeline:published_plan:v1"],
             downstream_product_ids: ["operator_review:plan:v1", "cadence_import:plan:v1"],
             dependency_impact_summary: dependency_impact,
             timeline_diff_summary: timeline_diff_summary
           ) == summary

    assert {:ok, %{"schema_contract" => "timeline_publication_summary.v1"}} =
             Schema.validate_artifact(summary)

    stale_status = Map.put(summary, "publication_status", "published")

    assert {:error, stale_status_report} = Schema.validate_artifact(stale_status)

    assert Enum.any?(
             stale_status_report["errors"],
             &(&1["path"] == "$.publication_status" and
                 &1["message"] ==
                   "must equal downstream invalidation and dependency impact state")
           )

    assert %{
             "publication_status" => "published",
             "dependency_impact_status" => "not_evaluated",
             "dependency_impact_row_count" => 0,
             "invalidated_downstream_product_ids" => []
           } = no_impact_summary = Timeline.publication_summary(source_artifact)

    assert no_impact_summary["publication_status"] in advertised_statuses.publication_statuses

    assert no_impact_summary["dependency_impact_status"] in advertised_statuses.publication_dependency_impact_statuses

    stale_dependency_count = Map.put(no_impact_summary, "dependency_impact_row_count", 1)

    assert {:error, stale_dependency_count_report} =
             Schema.validate_artifact(stale_dependency_count)

    assert Enum.any?(
             stale_dependency_count_report["errors"],
             &(&1["path"] == "$.dependency_impact_row_count" and
                 &1["message"] ==
                   "must be zero unless dependency_impact_status is review_required")
           )

    stale_diff_count = Map.put(summary, "timeline_diff_changed_count", 2)

    assert {:error, stale_diff_count_report} = Schema.validate_artifact(stale_diff_count)

    assert Enum.any?(
             stale_diff_count_report["errors"],
             &(&1["path"] == "$.timeline_diff_changed_count" and
                 &1["message"] == "must equal source_timeline_diff_summary.changed_count")
           )

    assert_raise ArgumentError,
                 ~r/invalidated_downstream_product_ids must be included in downstream_product_ids/,
                 fn ->
                   Timeline.publication_summary(source_artifact,
                     downstream_product_ids: ["cadence_import:plan:v1"],
                     invalidated_downstream_product_ids: ["operator_review:plan:v1"]
                   )
                 end

    assert_raise ArgumentError, ~r/source artifact must be a map/, fn ->
      Timeline.publication_summary(:not_an_artifact)
    end
  end

  test "keeps self-dependency integrity evidence separate from missing dependencies" do
    activities = [
      %{
        id: :cmd_self_activity,
        type: :command,
        starts_at_s: 10.0,
        ends_at_s: 20.0,
        dependencies: [:cmd_self_activity]
      },
      %{
        id: :cmd_self_timeline,
        timeline_id: :timeline_self,
        type: :command,
        starts_at_s: 30.0,
        ends_at_s: 40.0,
        dependency_timeline_ids: [:timeline_self]
      }
    ]

    assert %{
             "timeline_integrity_status" => "review_required",
             "timeline_integrity_issue_count" => 2,
             "timeline_integrity_issue_types" => [
               "self_dependency_activity",
               "self_dependency_timeline"
             ],
             "missing_dependency_activity_ids" => [],
             "missing_dependency_timeline_ids" => [],
             "self_dependency_activity_ids" => ["cmd_self_activity"],
             "self_dependency_timeline_ids" => ["timeline_self"],
             "rows" => [
               %{
                 "activity_id" => "cmd_self_activity",
                 "timeline_integrity_issue_types" => ["self_dependency_activity"],
                 "self_dependency_activity_ids" => ["cmd_self_activity"],
                 "timeline_integrity_issues" => [
                   %{
                     "type" => "self_dependency_activity",
                     "self_dependency_activity_id" => "cmd_self_activity"
                   }
                 ]
               },
               %{
                 "activity_id" => "cmd_self_timeline",
                 "timeline_integrity_issue_types" => ["self_dependency_timeline"],
                 "self_dependency_timeline_ids" => ["timeline_self"],
                 "timeline_integrity_issues" => [
                   %{
                     "type" => "self_dependency_timeline",
                     "self_dependency_timeline_id" => "timeline_self"
                   }
                 ]
               }
             ]
           } = integrity_report = Timeline.integrity_report(activities)

    refute Enum.any?(
             integrity_report["rows"],
             &Map.has_key?(&1, "missing_dependency_activity_ids")
           )

    refute Enum.any?(
             integrity_report["rows"],
             &Map.has_key?(&1, "missing_dependency_timeline_ids")
           )

    report = Timeline.operational_report(activities)

    assert [
             %{
               "activity_id" => "cmd_self_activity",
               "self_dependency_activity_ids" => ["cmd_self_activity"]
             },
             %{
               "activity_id" => "cmd_self_timeline",
               "self_dependency_timeline_ids" => ["timeline_self"]
             }
           ] = report["rows"]

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(report)

    stale_self_evidence =
      update_in(report, ["rows", Access.at(0)], fn row ->
        Map.put(row, "self_dependency_activity_ids", ["other_activity"])
      end)

    assert {:error, validation_report} = Schema.validate_artifact(stale_self_evidence)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.rows[0].self_dependency_activity_ids" and
                 &1["message"] ==
                   "must match timeline_integrity_issues self_dependency_activity_id values")
           )
  end

  test "routes duplicate dependency and exclusivity references to timeline integrity review" do
    activities = [
      %{
        id: :health_gate,
        timeline_id: :"timeline:health_gate",
        type: :health_check,
        starts_at_s: 0.0,
        ends_at_s: 5.0
      },
      %{
        id: :dl_clear,
        timeline_id: :"timeline:dl_clear",
        type: :downlink,
        starts_at_s: 40.0,
        ends_at_s: 50.0
      },
      %{
        id: :cmd_duplicate_refs,
        timeline_id: :"timeline:cmd_duplicate_refs",
        type: :command,
        starts_at_s: 20.0,
        ends_at_s: 25.0,
        dependencies: [:health_gate, :health_gate],
        dependency_timeline_ids: [:"timeline:health_gate", :"timeline:health_gate"],
        exclusive_with_activity_ids: [:dl_clear, :dl_clear],
        exclusive_with_timeline_ids: [:"timeline:dl_clear", :"timeline:dl_clear"]
      }
    ]

    assert %{
             "timeline_integrity_status" => "review_required",
             "timeline_integrity_review_count" => 1,
             "timeline_integrity_issue_count" => 4,
             "timeline_integrity_issue_types" => [
               "duplicate_dependency_activity",
               "duplicate_dependency_timeline",
               "duplicate_exclusivity_activity",
               "duplicate_exclusivity_timeline"
             ],
             "timeline_integrity_issue_type_counts" => %{
               "duplicate_dependency_activity" => 1,
               "duplicate_dependency_timeline" => 1,
               "duplicate_exclusivity_activity" => 1,
               "duplicate_exclusivity_timeline" => 1
             },
             "dependency_issue_count" => 2,
             "exclusivity_issue_count" => 2,
             "duplicate_dependency_activity_ids" => ["health_gate"],
             "duplicate_dependency_timeline_ids" => ["timeline:health_gate"],
             "duplicate_exclusivity_activity_ids" => ["dl_clear"],
             "duplicate_exclusivity_timeline_ids" => ["timeline:dl_clear"],
             "rows" => [
               %{
                 "activity_id" => "cmd_duplicate_refs",
                 "timeline_integrity_issue_count" => 4,
                 "timeline_integrity_issue_types" => [
                   "duplicate_dependency_activity",
                   "duplicate_dependency_timeline",
                   "duplicate_exclusivity_activity",
                   "duplicate_exclusivity_timeline"
                 ],
                 "dependency_activity_ids" => ["health_gate"],
                 "dependency_timeline_ids" => ["timeline:health_gate"],
                 "exclusive_with_activity_ids" => ["dl_clear"],
                 "exclusive_with_timeline_ids" => ["timeline:dl_clear"],
                 "duplicate_dependency_activity_ids" => ["health_gate"],
                 "duplicate_dependency_timeline_ids" => ["timeline:health_gate"],
                 "duplicate_exclusivity_activity_ids" => ["dl_clear"],
                 "duplicate_exclusivity_timeline_ids" => ["timeline:dl_clear"],
                 "timeline_integrity_issues" => [
                   %{
                     "type" => "duplicate_dependency_activity",
                     "duplicate_dependency_activity_id" => "health_gate"
                   },
                   %{
                     "type" => "duplicate_dependency_timeline",
                     "duplicate_dependency_timeline_id" => "timeline:health_gate"
                   },
                   %{
                     "type" => "duplicate_exclusivity_activity",
                     "duplicate_exclusivity_activity_id" => "dl_clear"
                   },
                   %{
                     "type" => "duplicate_exclusivity_timeline",
                     "duplicate_exclusivity_timeline_id" => "timeline:dl_clear"
                   }
                 ]
               }
             ]
           } = Timeline.integrity_report(activities)

    report = Timeline.operational_report(activities)

    assert report["duplicate_dependency_activity_ids"] == ["health_gate"]
    assert report["duplicate_exclusivity_timeline_ids"] == ["timeline:dl_clear"]

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(report)

    stale_duplicate_evidence =
      update_in(report, ["rows", Access.at(2)], fn row ->
        Map.put(row, "duplicate_dependency_activity_ids", ["other_gate"])
      end)

    assert {:error, validation_report} = Schema.validate_artifact(stale_duplicate_evidence)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.rows[2].duplicate_dependency_activity_ids" and
                 &1["message"] ==
                   "must match timeline_integrity_issues duplicate_dependency_activity_id values")
           )
  end

  test "routes dependency cycles to timeline integrity review" do
    report =
      Timeline.operational_report(
        [
          %{
            id: :cmd_prepare,
            type: :command,
            scenario_id: :leo_1,
            dependencies: [:cmd_execute],
            dependency_timeline_ids: [:"timeline:cmd_execute"],
            metadata: %{timeline_id: :"timeline:cmd_prepare"}
          },
          %{
            id: :cmd_execute,
            type: :command,
            scenario_id: :leo_1,
            dependencies: [:cmd_prepare],
            dependency_timeline_ids: [:"timeline:cmd_prepare"],
            metadata: %{timeline_id: :"timeline:cmd_execute"}
          }
        ],
        validate_missing_dependencies?: true
      )

    assert report["timeline_integrity_review_count"] == 2
    assert report["timeline_integrity_issue_count"] == 4
    assert report["dependency_issue_count"] == 4
    assert report["exclusivity_issue_count"] == 0

    assert %{
             "activity_id" => "cmd_prepare",
             "required_operator_action" => "review_timeline_integrity",
             "timeline_integrity_status" => "review_required",
             "timeline_integrity_issue_count" => 2,
             "dependency_cycle_activity_ids" => ["cmd_execute"],
             "dependency_cycle_timeline_ids" => ["timeline:cmd_execute"],
             "timeline_integrity_issue_types" => ["dependency_cycle"]
           } = prepare_row = Enum.find(report["rows"], &(&1["activity_id"] == "cmd_prepare"))

    assert [
             %{
               "type" => "dependency_cycle",
               "dependency_cycle_activity_id" => "cmd_execute"
             },
             %{
               "type" => "dependency_cycle",
               "dependency_cycle_timeline_id" => "timeline:cmd_execute"
             }
           ] = prepare_row["timeline_integrity_issues"]

    assert %{
             "activity_id" => "cmd_execute",
             "dependency_cycle_activity_ids" => ["cmd_prepare"],
             "dependency_cycle_timeline_ids" => ["timeline:cmd_prepare"],
             "timeline_integrity_issue_types" => ["dependency_cycle"]
           } = Enum.find(report["rows"], &(&1["activity_id"] == "cmd_execute"))

    review = OperatorReview.from_operational_timeline_report(report)
    import = CadenceImport.from_operational_timeline_report(report)

    assert %{
             "required_operator_action" => "review_timeline_integrity",
             "dependency_cycle_activity_ids" => ["cmd_execute"]
           } = Enum.find(review["rows"], &(&1["activity_id"] == "cmd_prepare"))

    assert %{
             "source_review_action" => "review_timeline_integrity",
             "dependency_cycle_timeline_ids" => ["timeline:cmd_prepare"]
           } = Enum.find(import["rows"], &(&1["activity_id"] == "cmd_execute"))

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "preserves planning score and feedback evidence in activity context" do
    activity = %{
      id: :obs_feedback,
      type: :observe,
      scenario_id: :leo_1,
      target_id: :target_a,
      starts_at_s: 120.0,
      ends_at_s: 240.0,
      score: 300.0,
      score_terms: %{"target_value" => 300.0},
      target_priority: 2.5,
      pointing_mode: :target_track,
      pointing_target_id: :target_a,
      boresight_axis: "+Z",
      off_nadir_angle_deg: 12.5,
      pointing_model: :declared_observation_attitude,
      pointing_confidence: 0.8,
      attitude_mode: :inertial_hold,
      attitude_target_id: :target_a,
      roll_deg: 1.0,
      pitch_deg: -0.5,
      yaw_deg: 3.25,
      attitude_error_deg: 0.15,
      attitude_status: :within_tolerance,
      attitude_model: :declared_euler_attitude,
      attitude_source: :mission_plan,
      attitude_confidence: 0.75,
      observation_success_factor: 0.5,
      observation_success_factor_source: :"operational_feedback.observation_success_rate.target",
      source_window_id: :target_a_window_1
    }

    report = Timeline.operational_report([activity])
    assert [row] = report["rows"]

    assert %{
             "activity_id" => "obs_feedback",
             "activity_context" => %{
               "duration_s" => 120.0,
               "score" => 300.0,
               "score_terms" => %{"target_value" => 300.0},
               "target_priority" => 2.5,
               "pointing_mode" => "target_track",
               "pointing_target_id" => "target_a",
               "boresight_axis" => "+Z",
               "off_nadir_angle_deg" => 12.5,
               "pointing_model" => "declared_observation_attitude",
               "pointing_confidence" => 0.8,
               "attitude_mode" => "inertial_hold",
               "attitude_target_id" => "target_a",
               "roll_deg" => 1.0,
               "pitch_deg" => -0.5,
               "yaw_deg" => 3.25,
               "attitude_error_deg" => 0.15,
               "attitude_status" => "within_tolerance",
               "attitude_model" => "declared_euler_attitude",
               "attitude_source" => "mission_plan",
               "attitude_confidence" => 0.75,
               "observation_success_factor" => 0.5,
               "observation_success_factor_source" =>
                 "operational_feedback.observation_success_rate.target",
               "timeline_identity" => %{
                 "timeline_id" => "timeline:leo_1:observe:target_a:target_a_window_1"
               }
             }
           } = row

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "classifies first-class attitude activities as attitude operations" do
    activity =
      Activity.attitude!(:target_hold, 120.0, 180.0,
        scenario_id: :leo_1,
        spacecraft_id: :sat_1,
        attitude_mode: :target_track,
        attitude_target_id: :target_a,
        roll_deg: 1.0,
        pitch_deg: -0.5,
        yaw_deg: 3.25,
        attitude_error_deg: 0.05,
        attitude_status: :within_tolerance,
        attitude_model: :declared_euler_attitude,
        attitude_source: :mission_plan,
        attitude_confidence: 0.9,
        source_window_id: :attitude_window_1,
        cadence_import: %{
          activity_type: :attitude,
          external_id: :cadence_attitude_hold,
          schema_contract: :"planned_activity.v1"
        }
      )

    report = Timeline.operational_report([activity])
    assert [row] = report["rows"]

    assert %{
             "activity_id" => "target_hold",
             "activity_type" => "attitude",
             "operational_kind" => "attitude",
             "cadence_import_status" => "present",
             "activity_context" => %{
               "timeline_identity" => %{
                 "timeline_id" => "timeline:leo_1:attitude:sat_1:attitude_window_1"
               },
               "attitude_mode" => "target_track",
               "attitude_target_id" => "target_a",
               "roll_deg" => 1.0,
               "pitch_deg" => -0.5,
               "yaw_deg" => 3.25,
               "attitude_error_deg" => 0.05,
               "attitude_status" => "within_tolerance",
               "attitude_model" => "declared_euler_attitude",
               "attitude_source" => "mission_plan",
               "attitude_confidence" => 0.9
             }
           } = row

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "preserves contact success feedback in downlink activity context" do
    activity = %{
      id: :dl_feedback,
      type: :downlink,
      scenario_id: :leo_1,
      ground_station_id: :equator_prime,
      direction: :downlink,
      starts_at_s: 300.0,
      ends_at_s: 420.0,
      estimated_throughput_mb: 144.0,
      actual_downlink_mb: 72.0,
      contact_success: true,
      contact_success_factor: 0.4,
      contact_success_factor_source: :"operational_feedback.contact_success_rate.station",
      throughput_model: %{
        contact_success_factor: 0.4,
        confidence_source: :"operational_feedback.contact_success_rate.station"
      },
      cadence_import: %{
        activity_type: :contact,
        external_id: :dl_feedback,
        schema_contract: :"proposed_contact.v1"
      }
    }

    report = Timeline.operational_report([activity])
    assert [row] = report["rows"]

    assert %{
             "activity_id" => "dl_feedback",
             "planned_estimated_throughput_mb" => 144.0,
             "actual_throughput_mb" => 72.0,
             "throughput_delta_mb" => -72.0,
             "throughput_completion_fraction" => 0.5,
             "activity_context" => %{
               "planned_estimated_throughput_mb" => 144.0,
               "actual_throughput_mb" => 72.0,
               "throughput_delta_mb" => -72.0,
               "throughput_completion_fraction" => 0.5,
               "contact_success" => true,
               "contact_success_factor" => 0.4,
               "contact_success_factor_source" =>
                 "operational_feedback.contact_success_rate.station",
               "throughput_model" => %{
                 "contact_success_factor" => 0.4,
                 "confidence_source" => "operational_feedback.contact_success_rate.station"
               }
             }
           } = row

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "preserves command result and success evidence in command activity context" do
    activity = %{
      id: :cmd_feedback,
      type: :command,
      scenario_id: :leo_1,
      ground_station_id: :equator_prime,
      direction: :command,
      starts_at_s: 300.0,
      ends_at_s: 330.0,
      status: :completed,
      command_success: false,
      command_result: :rejected,
      command_success_factor: 0.25,
      command_success_factor_source: :"operational_feedback.command_success_rate.activity"
    }

    report = Timeline.operational_report([activity])
    assert [row] = report["rows"]

    assert %{
             "activity_id" => "cmd_feedback",
             "activity_context" => %{
               "command_window_id" => "command_window:cmd_feedback",
               "command_window_type" => "command_window",
               "command_success" => false,
               "command_result" => "rejected",
               "command_success_factor" => 0.25,
               "command_success_factor_source" =>
                 "operational_feedback.command_success_rate.activity"
             }
           } = row

    assert %{
             "command_window_id" => "command_window:cmd_feedback",
             "command_window_type" => "command_window",
             "command_success" => false,
             "command_result" => "rejected",
             "command_success_factor" => 0.25
           } = Timeline.normalize_activity(activity)["activity_context"]

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "activity context preserves explicit command-window provenance for review handoff" do
    activity = %{
      id: :uplink_contact,
      type: :planned_contact,
      scenario_id: :leo_1,
      ground_station_id: :equator_prime,
      direction: :uplink,
      starts_at_s: 300.0,
      ends_at_s: 330.0,
      command_window: %{
        id: :"command_window:uplink_contact:declared",
        window_type: :uplink_window
      }
    }

    assert %{
             "command_window_id" => "command_window:uplink_contact:declared",
             "command_window_type" => "uplink_window"
           } = Timeline.activity_context(activity)

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             [activity]
             |> Timeline.operational_report()
             |> Schema.validate_artifact()
  end

  test "preserves maneuver execution uncertainty metadata in timeline review and import rows" do
    report =
      Timeline.operational_report([
        %{
          id: :burn_declared,
          type: :impulsive_burn,
          scenario_id: :leo_1,
          starts_at_s: 500.0,
          ends_at_s: 501.0,
          approval_status: :pending,
          execution_uncertainty: %{
            timing_3sigma_s: 2.0,
            delta_v_3sigma_km_s: [0.001, 0.002, 0.002],
            source: :operator_estimate
          }
        },
        %{
          id: :burn_missing,
          type: :impulsive_burn,
          scenario_id: :leo_1,
          starts_at_s: 600.0,
          ends_at_s: 601.0,
          approval_status: :pending
        }
      ])

    assert %{
             "execution_uncertainty_declared_count" => 1,
             "execution_uncertainty_missing_count" => 1
           } = report

    assert %{
             "activity_id" => "burn_declared",
             "execution_uncertainty_status" => "declared",
             "execution_uncertainty" => %{
               "timing_3sigma_s" => 2.0,
               "delta_v_3sigma_km_s" => [0.001, 0.002, 0.002],
               "source" => "operator_estimate"
             },
             "timing_3sigma_s" => 2.0,
             "delta_v_3sigma_km_s" => [0.001, 0.002, 0.002],
             "delta_v_3sigma_magnitude_km_s" => 0.0029999999999999996,
             "execution_uncertainty_source" => "operator_estimate",
             "activity_context" => %{
               "execution_uncertainty_status" => "declared",
               "execution_uncertainty" => %{"source" => "operator_estimate"},
               "timing_3sigma_s" => 2.0,
               "delta_v_3sigma_km_s" => [0.001, 0.002, 0.002],
               "delta_v_3sigma_magnitude_km_s" => 0.0029999999999999996,
               "execution_uncertainty_source" => "operator_estimate"
             }
           } = Enum.find(report["rows"], &(&1["activity_id"] == "burn_declared"))

    assert %{
             "activity_id" => "burn_missing",
             "execution_uncertainty_status" => "missing",
             "activity_context" => %{"execution_uncertainty_status" => "missing"}
           } = Enum.find(report["rows"], &(&1["activity_id"] == "burn_missing"))

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_operational_timeline_report(report)

    assert %{
             "activity_id" => "burn_declared",
             "execution_uncertainty_status" => "declared",
             "execution_uncertainty" => %{"source" => "operator_estimate"},
             "delta_v_3sigma_km_s" => [0.001, 0.002, 0.002],
             "source_activity_context" => %{
               "execution_uncertainty_status" => "declared",
               "execution_uncertainty" => %{"source" => "operator_estimate"}
             },
             "source_operational_timeline" => %{
               "execution_uncertainty_status" => "declared"
             }
           } = Enum.find(review["rows"], &(&1["activity_id"] == "burn_declared"))

    manifest = CadenceImport.from_operational_timeline_report(report)

    assert %{
             "activity_id" => "burn_declared",
             "execution_uncertainty_status" => "declared",
             "delta_v_3sigma_km_s" => [0.001, 0.002, 0.002],
             "import_activity_context" => %{
               "execution_uncertainty_status" => "declared",
               "execution_uncertainty" => %{"source" => "operator_estimate"}
             },
             "source_review_row" => %{
               "execution_uncertainty_status" => "declared"
             }
           } = Enum.find(manifest["rows"], &(&1["activity_id"] == "burn_declared"))

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "normalizes numeric string activity timing and execution uncertainty" do
    report =
      Timeline.operational_report([
        %{
          "id" => "burn_string_uncertainty",
          "type" => "impulsive_burn",
          "scenario_id" => "leo_1",
          "start_s" => "500.0",
          "end_s" => "501.5",
          "approval_status" => "pending",
          "execution_uncertainty" => %{
            "timing_3sigma_s" => "2.0",
            "delta_v_3sigma_km_s" => ["0.001", "0.002", "0.002"],
            "source" => "operator_estimate"
          }
        }
      ])

    assert %{
             "activity_id" => "burn_string_uncertainty",
             "starts_at_s" => 500.0,
             "ends_at_s" => 501.5,
             "execution_uncertainty_status" => "declared",
             "timing_3sigma_s" => 2.0,
             "delta_v_3sigma_km_s" => [0.001, 0.002, 0.002],
             "delta_v_3sigma_magnitude_km_s" => 0.0029999999999999996,
             "activity_context" => %{
               "timing_3sigma_s" => 2.0,
               "delta_v_3sigma_km_s" => [0.001, 0.002, 0.002]
             }
           } = List.first(report["rows"])

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "normalizes numeric string activity context resource throughput and pointing fields" do
    report =
      Timeline.operational_report([
        %{
          "id" => "obs_string_context",
          "type" => "observe",
          "scenario_id" => "leo_1",
          "target_id" => "target_a",
          "starts_at_s" => 100.0,
          "ends_at_s" => 120.0,
          "planned_data_volume_mb" => "80.0",
          "actual_data_volume_mb" => "40.0",
          "estimated_throughput_mb" => "12.5",
          "actual_throughput_mb" => "6.25",
          "fuel_margin" => "0.8",
          "power_margin" => "0.7",
          "estimated_battery_energy_generated_wh" => "21.5",
          "battery_state_of_charge" => "0.6",
          "off_nadir_angle_deg" => "12.0",
          "pointing_confidence" => "0.9",
          "roll_deg" => "1.5",
          "pitch_deg" => "-0.25",
          "yaw_deg" => "2.75",
          "attitude_confidence" => "0.85"
        }
      ])

    assert %{
             "activity_id" => "obs_string_context",
             "activity_context" => %{
               "planned_data_volume_mb" => 80.0,
               "actual_data_volume_mb" => 40.0,
               "data_volume_delta_mb" => -40.0,
               "data_volume_completion_fraction" => 0.5,
               "planned_estimated_throughput_mb" => 12.5,
               "actual_throughput_mb" => 6.25,
               "throughput_delta_mb" => -6.25,
               "throughput_completion_fraction" => 0.5,
               "fuel_margin" => 0.8,
               "power_margin" => 0.7,
               "battery_energy_generated_wh" => 21.5,
               "battery_state_of_charge" => 0.6,
               "off_nadir_angle_deg" => 12.0,
               "pointing_confidence" => 0.9,
               "roll_deg" => 1.5,
               "pitch_deg" => -0.25,
               "yaw_deg" => 2.75,
               "attitude_confidence" => 0.85
             }
           } = List.first(report["rows"])

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "preserves link profile and quality evidence in activity context" do
    report =
      Timeline.operational_report([
        %{
          "id" => "x_band_contact",
          "type" => "planned_contact",
          "scenario_id" => "leo_1",
          "ground_station_id" => "equator_prime",
          "direction" => "downlink",
          "starts_at_s" => 100.0,
          "ends_at_s" => 160.0,
          "command_result" => "rejected",
          "link_protocol" => "space_packet",
          "rf_band" => "x_band",
          "modulation" => "qpsk",
          "coding_scheme" => "ldpc",
          "polarization" => "rhcp",
          "data_rate_mbps" => "64.0",
          "downlink_rate_mbps" => "48.0",
          "data_rate_mb_s" => "8.0",
          "downlink_rate_mb_s" => "6.0",
          "actual_data_rate_mbps" => "32.0",
          "actual_downlink_rate_mbps" => "28.0",
          "actual_data_rate_mb_s" => "4.0",
          "actual_downlink_rate_mb_s" => "3.5",
          "delivered_rate_mbps" => "24.0",
          "received_rate_mbps" => "20.0",
          "delivered_rate_mb_s" => "3.0",
          "received_rate_mb_s" => "2.5",
          "actual_duration_s" => "55.0",
          "actual_contact_duration_s" => "54.0",
          "contact_duration_s" => "60.0",
          "link_margin_d_b" => "3.5",
          "snr_db" => "12.0",
          "ebn0_db" => "9.0",
          "ber" => "1.0e-6",
          "packet_loss_rate" => "0.01",
          "frame_loss_rate" => "0.02",
          "carrier_locked" => "true",
          "symbol_locked" => "true",
          "rf_status" => "nominal"
        }
      ])

    assert [
             %{
               "activity_id" => "x_band_contact",
               "activity_context" => %{
                 "link_protocol" => "space_packet",
                 "frequency_band" => "x_band",
                 "modulation" => "qpsk",
                 "coding_scheme" => "ldpc",
                 "polarization" => "rhcp",
                 "data_rate_mbps" => 64.0,
                 "downlink_rate_mbps" => 48.0,
                 "data_rate_mb_s" => 8.0,
                 "downlink_rate_mb_s" => 6.0,
                 "actual_data_rate_mbps" => 32.0,
                 "actual_downlink_rate_mbps" => 28.0,
                 "actual_data_rate_mb_s" => 4.0,
                 "actual_downlink_rate_mb_s" => 3.5,
                 "delivered_rate_mbps" => 24.0,
                 "received_rate_mbps" => 20.0,
                 "delivered_rate_mb_s" => 3.0,
                 "received_rate_mb_s" => 2.5,
                 "actual_duration_s" => 55.0,
                 "actual_throughput_mb" => 220.0,
                 "actual_data_rate_throughput_derivation" => %{
                   "derivation" => "actual_data_rate_times_duration",
                   "rate_unit" => "MB/s",
                   "actual_data_rate_mb_s" => 4.0,
                   "duration_s" => 55.0,
                   "actual_throughput_mb" => 220.0
                 },
                 "actual_contact_duration_s" => 54.0,
                 "contact_duration_s" => 60.0,
                 "link_margin_db" => 3.5,
                 "snr_db" => 12.0,
                 "eb_no_db" => 9.0,
                 "bit_error_rate" => 1.0e-6,
                 "packet_loss_rate" => 0.01,
                 "frame_loss_rate" => 0.02,
                 "carrier_lock" => true,
                 "symbol_lock" => true,
                 "link_quality_status" => "nominal"
               }
             }
           ] = report["rows"]

    review = OperatorReview.from_operational_timeline_report(report)
    import = CadenceImport.from_operational_timeline_report(report)

    assert [
             %{
               "actual_throughput_mb" => 220.0,
               "actual_data_rate_throughput_derivation" => %{
                 "derivation" => "actual_data_rate_times_duration",
                 "rate_unit" => "MB/s",
                 "actual_data_rate_mb_s" => 4.0,
                 "duration_s" => 55.0,
                 "actual_throughput_mb" => 220.0
               }
             }
           ] = review["rows"]

    assert [
             %{
               "actual_throughput_mb" => 220.0,
               "actual_data_rate_throughput_derivation" => %{
                 "derivation" => "actual_data_rate_times_duration",
                 "rate_unit" => "MB/s",
                 "actual_data_rate_mb_s" => 4.0,
                 "duration_s" => 55.0,
                 "actual_throughput_mb" => 220.0
               }
             }
           ] = import["rows"]

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "preserves thermal evidence in activity context and import handoff" do
    report =
      Timeline.operational_report([
        %{
          id: :payload_thermal_check,
          type: :command,
          scenario_id: :leo_1,
          spacecraft_id: :leo_1,
          starts_at_s: 300.0,
          ends_at_s: 330.0,
          thermal_zone_id: :payload_deck,
          planned_temperature_c: "18.5",
          actual_temperature_c: "42.0",
          min_operating_temperature_c: "-10.0",
          max_operating_temperature_c: "45.0",
          thermal_status: :near_limit,
          thermal_model: :declared_payload_thermal_budget,
          thermal_source: :provider_telemetry,
          thermal_confidence: "0.75"
        }
      ])

    assert [
             %{
               "activity_id" => "payload_thermal_check",
               "planned_temperature_c" => 18.5,
               "actual_temperature_c" => 42.0,
               "temperature_delta_c" => 23.5,
               "thermal_margin_c" => 3.0,
               "activity_context" => %{
                 "thermal_zone_id" => "payload_deck",
                 "planned_temperature_c" => 18.5,
                 "actual_temperature_c" => 42.0,
                 "temperature_delta_c" => 23.5,
                 "min_operating_temperature_c" => -10.0,
                 "max_operating_temperature_c" => 45.0,
                 "thermal_margin_c" => 3.0,
                 "thermal_status" => "near_limit",
                 "thermal_model" => "declared_payload_thermal_budget",
                 "thermal_source" => "provider_telemetry",
                 "thermal_confidence" => 0.75
               }
             }
           ] = report["rows"]

    review = OperatorReview.from_operational_timeline_report(report)
    import = CadenceImport.from_operational_timeline_report(report)

    assert [
             %{
               "source_activity_context" => %{
                 "thermal_zone_id" => "payload_deck",
                 "actual_temperature_c" => 42.0,
                 "thermal_margin_c" => 3.0
               }
             }
           ] = review["rows"]

    assert [
             %{
               "import_activity_context" => %{
                 "thermal_zone_id" => "payload_deck",
                 "actual_temperature_c" => 42.0,
                 "thermal_margin_c" => 3.0
               }
             }
           ] = import["rows"]

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "preserves maneuver success feedback in burn activity context and diffs" do
    report =
      Timeline.operational_report([
        %{
          id: :burn_cleanup,
          type: :impulsive_burn,
          scenario_id: :leo_1,
          starts_at_s: 100.0,
          ends_at_s: 100.0,
          maneuver_success_factor: 0.9,
          maneuver_success_factor_source: :preburn_confidence_model
        }
      ])

    assert [
             %{
               "activity_id" => "burn_cleanup",
               "activity_context" => %{
                 "maneuver_success_factor" => 0.9,
                 "maneuver_success_factor_source" => "preburn_confidence_model"
               }
             }
           ] = report["rows"]

    diff =
      Timeline.diff_report(
        [
          %{
            id: :burn_cleanup,
            type: :impulsive_burn,
            scenario_id: :leo_1,
            starts_at_s: 100.0,
            ends_at_s: 100.0,
            maneuver_success_factor: 0.9,
            maneuver_success_factor_source: :preburn_confidence_model,
            attitude_mode: :inertial_hold,
            roll_deg: 0.5,
            attitude_status: :planned,
            metadata: %{timeline_id: :"timeline:burn_cleanup"}
          }
        ],
        [
          %{
            id: :burn_cleanup,
            type: :impulsive_burn,
            scenario_id: :leo_1,
            starts_at_s: 100.0,
            ends_at_s: 100.0,
            maneuver_success_factor: 0.4,
            maneuver_success_factor_source: :provider_execution_feedback,
            attitude_mode: :inertial_hold,
            roll_deg: 1.25,
            attitude_status: :off_nominal,
            metadata: %{timeline_id: :"timeline:burn_cleanup"}
          }
        ]
      )

    assert %{
             "changed_count" => 1,
             "review_required_count" => 1,
             "rows" => [
               %{
                 "changed_fields" => changed_fields,
                 "required_operator_action" => "review_timeline_change",
                 "source_activity_context" => %{
                   "maneuver_success_factor" => 0.9,
                   "maneuver_success_factor_source" => "preburn_confidence_model",
                   "attitude_mode" => "inertial_hold",
                   "roll_deg" => 0.5,
                   "attitude_status" => "planned"
                 },
                 "replacement_activity_context" => %{
                   "maneuver_success_factor" => 0.4,
                   "maneuver_success_factor_source" => "provider_execution_feedback",
                   "attitude_mode" => "inertial_hold",
                   "roll_deg" => 1.25,
                   "attitude_status" => "off_nominal"
                 }
               }
             ]
           } = diff

    assert "maneuver_success_factor" in changed_fields
    assert "maneuver_success_factor_source" in changed_fields
    assert "roll_deg" in changed_fields
    assert "attitude_status" in changed_fields

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "timeline_diff_report.v1"}} =
             Schema.validate_artifact(diff)
  end

  test "flags duplicate operational timeline identities for review" do
    report =
      Timeline.operational_report([
        %{
          id: :cmd_a,
          type: :command,
          scenario_id: :leo_1,
          starts_at_s: 10.0,
          ends_at_s: 20.0,
          ground_station_id: :dss_14,
          approval_status: :approved,
          metadata: %{timeline_id: :"timeline:cmd_duplicate"}
        },
        %{
          id: :cmd_b,
          type: :command,
          scenario_id: :leo_1,
          starts_at_s: 30.0,
          ends_at_s: 40.0,
          ground_station_id: :dss_14,
          approval_status: :pending,
          metadata: %{timeline_id: :"timeline:cmd_duplicate"}
        }
      ])

    assert %{
             "duplicate_timeline_identity_count" => 1,
             "duplicate_timeline_identity_activity_count" => 2,
             "rows" => rows
           } = report

    assert Enum.map(rows, & &1["activity_id"]) == ["cmd_a", "cmd_b"]

    Enum.each(rows, fn row ->
      assert row["timeline_identity_collision"]
      assert row["required_operator_action"] == "review_duplicate_timeline_identity"
      assert row["operator_action_reason"] == "duplicate_timeline_identity_collision"
      assert row["duplicate_timeline_identity_activity_count"] == 2
      assert row["duplicate_timeline_identity_activity_ids"] == ["cmd_a", "cmd_b"]

      assert Enum.map(row["duplicate_timeline_identity_activities"], & &1["activity_id"]) == [
               "cmd_a",
               "cmd_b"
             ]
    end)

    assert %{
             "activity_id" => "cmd_a",
             "superseded_required_operator_action" => "prepare_cadence_import",
             "superseded_operator_action_reason" => "cadence_import_missing"
           } = Enum.find(rows, &(&1["activity_id"] == "cmd_a"))

    assert %{
             "activity_id" => "cmd_b",
             "superseded_required_operator_action" => "review_command_contact",
             "superseded_operator_action_reason" => "command_boundary_requires_review"
           } = Enum.find(rows, &(&1["activity_id"] == "cmd_b"))

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_operational_timeline_report(report)

    assert Enum.map(review["rows"], & &1["required_operator_action"]) == [
             "review_duplicate_timeline_identity",
             "review_duplicate_timeline_identity"
           ]

    assert %{
             "timeline_identity_collision" => true,
             "duplicate_timeline_identity_activity_ids" => ["cmd_a", "cmd_b"],
             "superseded_required_operator_action" => "prepare_cadence_import",
             "source_operational_timeline" => %{
               "timeline_identity_collision" => true,
               "duplicate_timeline_identity_activity_count" => 2
             },
             "source_activity_context" => %{
               "timeline_identity" => %{
                 "timeline_id" => "timeline:cmd_duplicate",
                 "activity_id" => "cmd_a"
               }
             }
           } = List.first(review["rows"])

    import = CadenceImport.from_operational_timeline_report(report)

    assert %{
             "import_action" => "review_operational_timeline",
             "source_review_action" => "review_duplicate_timeline_identity",
             "timeline_identity_collision" => true,
             "duplicate_timeline_identity_activity_ids" => ["cmd_a", "cmd_b"],
             "import_activity_context" => %{
               "timeline_identity" => %{
                 "timeline_id" => "timeline:cmd_duplicate",
                 "activity_id" => "cmd_a"
               }
             },
             "source_operational_timeline" => %{"timeline_identity_collision" => true}
           } = List.first(import["rows"])

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "builds timeline identity from persistent metadata before deriving one" do
    assert %{
             "timeline_id" => "persistent:timeline",
             "activity_id" => "dl_1",
             "activity_type" => "downlink",
             "scenario_id" => "leo_1",
             "subject_id" => "equator_prime"
           } =
             Timeline.timeline_identity(%{
               "id" => "dl_1",
               "type" => "downlink",
               "scenario_id" => "leo_1",
               "ground_station_id" => "equator_prime",
               "metadata" => %{"timeline_id" => "persistent:timeline"}
             })
  end

  test "normalizes station-id-only provider contact activities" do
    row =
      Timeline.operational_timeline_row(
        %{
          id: :provider_contact,
          type: :contact,
          direction: :downlink,
          scenario_id: :leo_1,
          station_id: :equator_prime,
          start_s: 10.0,
          end_s: 70.0,
          source_window_id: :provider_window
        },
        1
      )

    assert %{
             "activity_id" => "provider_contact",
             "activity_type" => "contact",
             "direction" => "downlink",
             "ground_station_id" => "equator_prime",
             "operational_kind" => "contact",
             "timeline_id" => "timeline:leo_1:contact:equator_prime:provider_window",
             "activity_context" => %{
               "ground_station_id" => "equator_prime",
               "source_window_id" => "provider_window",
               "timeline_identity" => %{
                 "timeline_id" => "timeline:leo_1:contact:equator_prime:provider_window",
                 "subject_id" => "equator_prime"
               }
             }
           } = row

    assert %{
             "timeline_id" => "timeline:leo_1:contact:equator_prime:provider_window",
             "subject_id" => "equator_prime"
           } =
             Timeline.timeline_identity(%{
               id: :provider_contact,
               type: :contact,
               direction: :downlink,
               scenario_id: :leo_1,
               station_id: :equator_prime,
               source_window_id: :provider_window
             })
  end

  test "normalizes provider-shaped target and station objects before timeline identity" do
    observation =
      Timeline.normalize_activity(%{
        id: :provider_observation,
        type: :observe,
        scenario_id: :leo_1,
        start_s: 10.0,
        end_s: 20.0,
        target: %{id: :target_a},
        source_window_id: :observation_window
      })

    downlink =
      Timeline.normalize_activity(%{
        id: :provider_downlink_object,
        scenario_id: :leo_1,
        start_s: 30.0,
        end_s: 40.0,
        station: %{id: :equator_prime},
        estimated_throughput_mb: 42.0,
        source_window_id: :provider_window
      })

    command_contact =
      Timeline.normalize_activity(%{
        id: :provider_command_object,
        direction: :command,
        scenario_id: :leo_1,
        start_s: 50.0,
        end_s: 60.0,
        ground_station: %{station_id: :dss_14},
        source_window_id: :command_window
      })

    assert %{
             "activity_id" => "provider_observation",
             "activity_type" => "observe",
             "target_id" => "target_a",
             "timeline_id" => "timeline:leo_1:observe:target_a:observation_window",
             "activity_context" => %{
               "target_id" => "target_a",
               "timeline_identity" => %{
                 "subject_id" => "target_a"
               }
             }
           } = observation

    assert %{
             "activity_id" => "provider_downlink_object",
             "activity_type" => "downlink",
             "direction" => "downlink",
             "ground_station_id" => "equator_prime",
             "timeline_id" => "timeline:leo_1:downlink:equator_prime:provider_window",
             "activity_context" => %{
               "ground_station_id" => "equator_prime",
               "estimated_throughput_mb" => 42.0,
               "timeline_identity" => %{
                 "subject_id" => "equator_prime"
               }
             }
           } = downlink

    assert %{
             "activity_id" => "provider_command_object",
             "activity_type" => "planned_contact",
             "direction" => "command",
             "ground_station_id" => "dss_14",
             "operational_kind" => "command",
             "activity_context" => %{
               "ground_station_id" => "dss_14",
               "timeline_identity" => %{
                 "subject_id" => "dss_14"
               }
             }
           } = command_contact
  end

  test "infers provider-shaped station contacts without type as downlink timeline rows" do
    report =
      Timeline.operational_report([
        %{
          id: :provider_downlink,
          scenario_id: :leo_1,
          station_id: :equator_prime,
          start_s: 10.0,
          end_s: 70.0,
          estimated_throughput_mb: 42.0,
          source_window_id: :provider_window
        },
        %{
          id: :provider_command_without_type,
          scenario_id: :leo_1,
          station_id: :equator_prime,
          start_s: 80.0,
          end_s: 90.0,
          command_result: :accepted
        },
        %{
          id: :direction_only_command,
          scenario_id: :leo_1,
          station_id: :equator_prime,
          direction: :cmd,
          start_s: 100.0,
          end_s: 110.0
        },
        %{
          id: :direction_only_health_check,
          scenario_id: :leo_1,
          station_id: :equator_prime,
          direction: "Health Check Window",
          start_s: 120.0,
          end_s: 125.0
        }
      ])

    assert %{
             "activity_count" => 4,
             "valid_activity_count" => 3,
             "invalid_activity_input_count" => 1,
             "contact_count" => 3,
             "command_count" => 2
           } = report

    assert %{
             "activity_id" => "provider_downlink",
             "activity_type" => "downlink",
             "direction" => "downlink",
             "ground_station_id" => "equator_prime",
             "starts_at_s" => 10.0,
             "ends_at_s" => 70.0,
             "operational_kind" => "contact",
             "cadence_import_status" => "missing",
             "activity_context" => %{
               "estimated_throughput_mb" => 42.0,
               "ground_station_id" => "equator_prime",
               "starts_at_s" => 10.0,
               "ends_at_s" => 70.0,
               "timeline_identity" => %{
                 "timeline_id" => "timeline:leo_1:downlink:equator_prime:provider_window",
                 "activity_type" => "downlink",
                 "subject_id" => "equator_prime"
               }
             }
           } = Enum.find(report["rows"], &(&1["activity_id"] == "provider_downlink"))

    assert %{
             "activity_id" => "provider_command_without_type",
             "required_operator_action" => "review_invalid_activity_input",
             "invalid_activity_input_reason" => "missing_activity_type"
           } = Enum.find(report["rows"], &(&1["activity_id"] == "provider_command_without_type"))

    assert %{
             "activity_id" => "direction_only_command",
             "activity_type" => "planned_contact",
             "direction" => "command",
             "ground_station_id" => "equator_prime",
             "operational_kind" => "command",
             "required_operator_action" => "review_command_contact",
             "activity_context" => %{
               "direction" => "command",
               "ground_station_id" => "equator_prime",
               "timeline_identity" => %{
                 "activity_type" => "planned_contact",
                 "subject_id" => "equator_prime"
               }
             }
           } = Enum.find(report["rows"], &(&1["activity_id"] == "direction_only_command"))

    assert %{
             "activity_id" => "direction_only_health_check",
             "activity_type" => "health_check",
             "direction" => "health_check",
             "ground_station_id" => "equator_prime",
             "operational_kind" => "health_check",
             "activity_context" => %{
               "direction" => "health_check",
               "ground_station_id" => "equator_prime",
               "timeline_identity" => %{
                 "activity_type" => "health_check",
                 "subject_id" => "equator_prime"
               }
             }
           } = Enum.find(report["rows"], &(&1["activity_id"] == "direction_only_health_check"))

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "accepts activity-type-only timeline activity inputs" do
    report =
      Timeline.operational_report([
        %{
          id: :provider_tracking,
          activity_type: :tracking,
          scenario_id: :leo_1,
          station_id: :equator_prime,
          start_s: 15.0,
          end_s: 75.0,
          source_window_id: :provider_tracking_window
        },
        %{
          id: :blank_activity_type,
          activity_type: "",
          scenario_id: :leo_1,
          starts_at_s: 80.0,
          ends_at_s: 90.0
        }
      ])

    assert %{
             "activity_count" => 2,
             "valid_activity_count" => 1,
             "invalid_activity_input_count" => 1,
             "contact_count" => 1
           } = report

    assert %{
             "activity_id" => "provider_tracking",
             "activity_type" => "tracking",
             "ground_station_id" => "equator_prime",
             "starts_at_s" => 15.0,
             "ends_at_s" => 75.0,
             "operational_kind" => "contact",
             "activity_context" => %{
               "ground_station_id" => "equator_prime",
               "source_window_id" => "provider_tracking_window",
               "timeline_identity" => %{
                 "timeline_id" =>
                   "timeline:leo_1:tracking:equator_prime:provider_tracking_window",
                 "activity_type" => "tracking",
                 "subject_id" => "equator_prime"
               }
             }
           } = Enum.find(report["rows"], &(&1["activity_id"] == "provider_tracking"))

    refute Enum.find(report["rows"], &(&1["activity_id"] == "provider_tracking"))["direction"] ==
             "downlink"

    assert %{
             "activity_id" => "blank_activity_type",
             "required_operator_action" => "review_invalid_activity_input",
             "invalid_activity_input_reason" => "missing_activity_type"
           } = Enum.find(report["rows"], &(&1["activity_id"] == "blank_activity_type"))

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "normalizes one typed operational activity outside report rows" do
    activity =
      Activity.planned_contact!(:cmd_contact, 70.0, 80.0, :dss_14, :command,
        approval_status: :pending,
        source_window_id: :cmd_window_1
      )

    assert %{
             "activity_id" => "cmd_contact",
             "activity_type" => "planned_contact",
             "timeline_id" => "timeline:planned_contact:dss_14:cmd_window_1",
             "operational_kind" => "command",
             "direction" => "command",
             "ground_station_id" => "dss_14",
             "approval_status" => "pending",
             "locked" => false,
             "approved" => false,
             "required_operator_action" => "review_command_contact",
             "operator_action_reason" => "command_boundary_requires_review",
             "cadence_import_status" => "missing",
             "protection_decision" => "mutable",
             "protection_category" => "none",
             "protection_reason" => "no_timeline_protection",
             "activity_context" => %{
               "approval_status" => "pending",
               "direction" => "command",
               "ground_station_id" => "dss_14",
               "source_window_id" => "cmd_window_1",
               "timeline_identity" => %{
                 "timeline_id" => "timeline:planned_contact:dss_14:cmd_window_1",
                 "activity_id" => "cmd_contact",
                 "activity_type" => "planned_contact",
                 "subject_id" => "dss_14",
                 "source_window_id" => "cmd_window_1"
               }
             }
           } = Timeline.normalize_activity(activity)

    refute Map.has_key?(Timeline.normalize_activity(activity), "id")

    assert OrbitalDynamics.normalize_timeline_activity(activity) ==
             Timeline.normalize_activity(activity)

    assert_raise ArgumentError, ~r/activity must be a map or MissionPlan.Activity/, fn ->
      Timeline.normalize_activity(:not_an_activity)
    end
  end

  test "normalizes typed operational activity lists and preserves duplicate identity review" do
    activities = [
      %{
        id: :cmd_a,
        type: :command,
        starts_at_s: 10.0,
        ends_at_s: 20.0,
        ground_station_id: :dss_14,
        direction: :command,
        metadata: %{timeline_id: :"timeline:shared_command"}
      },
      %{
        id: :cmd_b,
        type: :command,
        starts_at_s: 30.0,
        ends_at_s: 40.0,
        ground_station_id: :dss_14,
        direction: :command,
        metadata: %{timeline_id: :"timeline:shared_command"}
      }
    ]

    assert [
             %{
               "activity_id" => "cmd_a",
               "timeline_identity_collision" => true,
               "duplicate_timeline_identity_activity_count" => 2,
               "duplicate_timeline_identity_activity_ids" => ["cmd_a", "cmd_b"],
               "required_operator_action" => "review_duplicate_timeline_identity",
               "superseded_required_operator_action" => "review_command_contact"
             },
             %{
               "activity_id" => "cmd_b",
               "timeline_identity_collision" => true,
               "duplicate_timeline_identity_activity_count" => 2,
               "duplicate_timeline_identity_activity_ids" => ["cmd_a", "cmd_b"],
               "required_operator_action" => "review_duplicate_timeline_identity",
               "superseded_required_operator_action" => "review_command_contact"
             }
           ] = Timeline.normalize_activities(activities)

    refute Enum.any?(Timeline.normalize_activities(activities), &Map.has_key?(&1, "id"))

    assert OrbitalDynamics.normalize_timeline_activities(activities) ==
             Timeline.normalize_activities(activities)

    assert_raise ArgumentError, ~r/activities must be a list/, fn ->
      Timeline.normalize_activities(:not_a_list)
    end
  end

  test "normalizes activity lists with timeline integrity review annotations" do
    activities = [
      %{
        id: :health_gate,
        type: :health_check,
        starts_at_s: 0.0,
        ends_at_s: 15.0,
        ground_station_id: :dss_14,
        direction: :command
      },
      %{
        id: :cmd_main,
        type: :command,
        starts_at_s: 10.0,
        ends_at_s: 20.0,
        ground_station_id: :dss_14,
        direction: :command,
        dependencies: [:health_gate, :missing_gate],
        exclusive_with: [:dl_conflict],
        exclusivity_group: :station_dss_14
      },
      %{
        id: :dl_conflict,
        type: :downlink,
        starts_at_s: 12.0,
        ends_at_s: 22.0,
        ground_station_id: :dss_14,
        direction: :downlink,
        exclusivity_group: :station_dss_14
      }
    ]

    normalized =
      Timeline.normalize_activities(activities, validate_missing_dependencies?: true)

    assert Enum.all?(normalized, &(not Map.has_key?(&1, "id")))

    assert %{
             "activity_id" => "cmd_main",
             "required_operator_action" => "review_timeline_integrity",
             "operator_action_reason" => "timeline_integrity_issue",
             "superseded_required_operator_action" => "review_command_contact",
             "timeline_integrity_status" => "review_required",
             "missing_dependency_activity_ids" => ["missing_gate"],
             "dependency_order_violation_activity_ids" => ["health_gate"],
             "exclusivity_violation_activity_ids" => ["dl_conflict"],
             "exclusivity_violation_group" => "station_dss_14",
             "activity_context" => %{
               "dependency_activity_ids" => ["health_gate", "missing_gate"],
               "exclusive_with_activity_ids" => ["dl_conflict"]
             }
           } = Enum.find(normalized, &(&1["activity_id"] == "cmd_main"))

    assert "missing_dependency_activity" in Enum.find(
             normalized,
             &(&1["activity_id"] == "cmd_main")
           )[
             "timeline_integrity_issue_types"
           ]

    assert %{
             "activity_id" => "dl_conflict",
             "required_operator_action" => "review_timeline_integrity",
             "exclusivity_violation_activity_ids" => ["cmd_main"]
           } = Enum.find(normalized, &(&1["activity_id"] == "dl_conflict"))

    refute Enum.any?(
             Timeline.normalize_activities(activities),
             &("missing_dependency_activity" in Map.get(&1, "timeline_integrity_issue_types", []))
           )

    assert OrbitalDynamics.normalize_timeline_activities(
             activities,
             validate_missing_dependencies?: true
           ) == normalized
  end

  test "normalizes auto-approvable activities as protected timeline work" do
    activity = %{
      id: :auto_contact,
      type: :planned_contact,
      starts_at_s: 70.0,
      ends_at_s: 80.0,
      ground_station_id: :dss_14,
      direction: :downlink,
      approval_status: :auto_approvable
    }

    assert %{
             "activity_id" => "auto_contact",
             "approval_status" => "auto_approvable",
             "approved" => true,
             "protection_decision" => "preserve",
             "protection_category" => "locked_or_approved",
             "protection_reason" => "activity_locked_or_approved"
           } = Timeline.normalize_activity(activity)

    assert %{
             "protection_decision" => "review_change",
             "protection_category" => "locked_or_approved",
             "reason" => "realized_status_failed_requires_repair_review"
           } = Timeline.protection_decision(activity, realized_status: :failed)

    assert %{
             "protection_decision" => "review_change",
             "protection_category" => "locked_or_approved",
             "reason" => "locked_or_approved_changes_allowed_with_review"
           } = Timeline.protection_decision(activity, allow_locked_changes?: true)
  end

  test "builds lifecycle preservation summaries for protected selected activities" do
    activities = [
      %{
        id: :cmd_mutable,
        type: :command,
        status: :planned,
        approval_status: :pending
      },
      %{
        id: :contact_locked,
        type: :planned_contact,
        locked: true,
        approval_status: :pending
      },
      %{
        id: :obs_done,
        type: :observe,
        status: :completed
      },
      %{
        id: :bad_missing_type,
        status: :planned
      }
    ]

    assert %{
             "schema_contract" => "timeline_preservation_report.v1",
             "model" => "artifact_only_lifecycle_preservation_summary",
             "source" => "selected_activities",
             "activity_count" => 4,
             "mutable_activity_count" => 1,
             "preserve_activity_count" => 2,
             "review_change_activity_count" => 1,
             "preservation_sensitive_activity_count" => 3,
             "timeline_preservation_status" => "review_required",
             "protection_decision_counts" => %{
               "mutable" => 1,
               "preserve" => 2,
               "review_change" => 1
             },
             "protection_category_counts" => %{
               "executed" => 1,
               "invalid_activity_input" => 1,
               "locked_or_approved" => 1,
               "none" => 1
             },
             "protection_reason_counts" => %{
               "activity_already_completed" => 1,
               "activity_locked_or_approved" => 1,
               "missing_activity_type" => 1,
               "no_timeline_protection" => 1
             },
             "preserve_activity_ids" => ["contact_locked", "obs_done"],
             "preserve_timeline_ids" => [
               "timeline:observe",
               "timeline:planned_contact"
             ],
             "review_change_activity_ids" => ["bad_missing_type"],
             "review_change_timeline_ids" => ["timeline:invalid_activity_input:bad_missing_type"],
             "mutable_activity_ids" => ["cmd_mutable"],
             "preservation_sensitive_activity_ids" => [
               "bad_missing_type",
               "contact_locked",
               "obs_done"
             ],
             "preservation_sensitive_timeline_ids" => [
               "timeline:invalid_activity_input:bad_missing_type",
               "timeline:observe",
               "timeline:planned_contact"
             ],
             "activity_id_sets_by_protection_decision" => %{
               "mutable" => ["cmd_mutable"],
               "preserve" => ["contact_locked", "obs_done"],
               "review_change" => ["bad_missing_type"]
             },
             "timeline_id_sets_by_protection_decision" => %{
               "mutable" => ["timeline:command"],
               "preserve" => [
                 "timeline:observe",
                 "timeline:planned_contact"
               ],
               "review_change" => ["timeline:invalid_activity_input:bad_missing_type"]
             },
             "activity_id_sets_by_protection_category" => %{
               "executed" => ["obs_done"],
               "invalid_activity_input" => ["bad_missing_type"],
               "locked_or_approved" => ["contact_locked"],
               "none" => ["cmd_mutable"]
             },
             "timeline_id_sets_by_protection_category" => %{
               "executed" => ["timeline:observe"],
               "invalid_activity_input" => ["timeline:invalid_activity_input:bad_missing_type"],
               "locked_or_approved" => ["timeline:planned_contact"],
               "none" => ["timeline:command"]
             },
             "activity_id_sets_by_protection_reason" => %{
               "activity_already_completed" => ["obs_done"],
               "activity_locked_or_approved" => ["contact_locked"],
               "missing_activity_type" => ["bad_missing_type"],
               "no_timeline_protection" => ["cmd_mutable"]
             },
             "timeline_id_sets_by_protection_reason" => %{
               "activity_already_completed" => ["timeline:observe"],
               "activity_locked_or_approved" => ["timeline:planned_contact"],
               "missing_activity_type" => ["timeline:invalid_activity_input:bad_missing_type"],
               "no_timeline_protection" => ["timeline:command"]
             },
             "model_limits" => model_limits,
             "rows" => [
               %{
                 "activity_id" => "contact_locked",
                 "protection_decision" => "preserve",
                 "protection_category" => "locked_or_approved",
                 "reason" => "activity_locked_or_approved"
               },
               %{
                 "activity_id" => "obs_done",
                 "status" => "completed",
                 "protection_decision" => "preserve",
                 "protection_category" => "executed",
                 "reason" => "activity_already_completed"
               },
               %{
                 "activity_id" => "bad_missing_type",
                 "invalid_activity_input" => true,
                 "protection_decision" => "review_change",
                 "protection_category" => "invalid_activity_input",
                 "reason" => "missing_activity_type"
               }
             ],
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_schedule_mutation",
               "scope" => "lifecycle_lock_approval_and_executed_preservation_review",
               "source" => "selected_activities"
             }
           } =
             preservation_report =
             Timeline.preservation_report(activities, source: "selected_activities")

    assert model_limits == Timeline.model_limits()

    assert OrbitalDynamics.timeline_preservation_report(activities, source: "selected_activities") ==
             preservation_report

    assert {:ok, %{"schema_contract" => "timeline_preservation_report.v1"}} =
             Schema.validate_artifact(preservation_report)

    atom_key_preservation_report =
      preservation_report
      |> Map.delete("schema_contract")
      |> Map.put(:schema_contract, "timeline_preservation_report.v1")

    assert Timeline.preservation_report(preservation_report) == preservation_report
    assert Timeline.preservation_report(atom_key_preservation_report) == preservation_report

    assert OrbitalDynamics.timeline_preservation_report(preservation_report) ==
             preservation_report

    stale_model_limits =
      Map.put(preservation_report, "model_limits", ["timeline_model_is_read_only"])

    assert {:error, stale_model_limits_report} = Schema.validate_artifact(stale_model_limits)

    assert Enum.any?(
             stale_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] == "must match timeline report model limits")
           )

    stale_preservation_count =
      Map.put(preservation_report, "preservation_sensitive_activity_count", 1)

    assert {:error, stale_preservation_count_validation} =
             Schema.validate_artifact(stale_preservation_count)

    assert Enum.any?(
             stale_preservation_count_validation["errors"],
             &(&1["path"] == "$.preservation_sensitive_activity_count" and
                 &1["message"] ==
                   "must equal preserve_activity_count plus review_change_activity_count")
           )

    assert %{
             "timeline_preservation_status" => "preservation_required",
             "preserve_activity_count" => 1,
             "review_change_activity_count" => 0
           } =
             Timeline.preservation_report([
               %{id: :cmd_approved, type: :command, approval_status: :approved}
             ])

    assert %{
             "timeline_preservation_status" => "clear",
             "rows" => []
           } =
             Timeline.preservation_report([
               %{id: :cmd_clear, type: :command, approval_status: :pending}
             ])

    assert_raise ArgumentError, ~r/activities must be a list/, fn ->
      Timeline.preservation_report(:not_a_list)
    end
  end

  test "classifies single activity lifecycle preservation status" do
    assert %{
             "schema_contract" => "timeline_preservation_status.v1",
             "model" => "artifact_only_lifecycle_preservation_status",
             "timeline_preservation_status" => "clear",
             "requires_preservation" => false,
             "requires_operator_review" => false,
             "activity_id" => "cmd_clear",
             "protection_decision" => "mutable",
             "protection_category" => "none",
             "protection_reason" => "no_timeline_protection",
             "model_limits" => clear_model_limits,
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_schedule_mutation",
               "scope" => "single_activity_lifecycle_preservation_preflight"
             }
           } =
             Timeline.preservation_status(%{
               id: :cmd_clear,
               type: :command,
               approval_status: :pending
             })

    assert clear_model_limits == Timeline.model_limits()

    locked = %{
      id: :dl_locked,
      type: :downlink,
      timeline_id: :"timeline:dl_locked",
      locked: true,
      approval_status: :pending
    }

    assert %{
             "timeline_preservation_status" => "preservation_required",
             "requires_preservation" => true,
             "requires_operator_review" => false,
             "activity_id" => "dl_locked",
             "timeline_id" => "timeline:dl_locked",
             "locked" => true,
             "protection_decision" => "preserve",
             "protection_category" => "locked_or_approved",
             "protection_reason" => "activity_locked_or_approved",
             "model_limits" => locked_model_limits
           } = preservation_status = Timeline.preservation_status(locked)

    assert locked_model_limits == Timeline.model_limits()

    assert OrbitalDynamics.timeline_preservation_status(locked) == preservation_status

    assert {:ok, %{"schema_contract" => "timeline_preservation_status.v1"}} =
             Schema.validate_artifact(preservation_status)

    atom_key_preservation_status =
      preservation_status
      |> Map.delete("schema_contract")
      |> Map.put(:schema_contract, "timeline_preservation_status.v1")

    assert Timeline.preservation_status(preservation_status) == preservation_status
    assert Timeline.preservation_status(atom_key_preservation_status) == preservation_status

    assert OrbitalDynamics.timeline_preservation_status(preservation_status) ==
             preservation_status

    stale_model_limits =
      Map.put(preservation_status, "model_limits", ["timeline_model_is_read_only"])

    assert {:error, stale_model_limits_report} = Schema.validate_artifact(stale_model_limits)

    assert Enum.any?(
             stale_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] == "must match timeline report model limits")
           )

    stale_status = Map.put(preservation_status, "requires_preservation", false)

    assert {:error, stale_status_validation} = Schema.validate_artifact(stale_status)

    assert Enum.any?(
             stale_status_validation["errors"],
             &(&1["path"] == "$.requires_preservation" and
                 &1["message"] ==
                   "must equal timeline_preservation_status-derived requires_preservation")
           )

    assert %{
             "timeline_preservation_status" => "review_required",
             "requires_preservation" => false,
             "requires_operator_review" => true,
             "activity_id" => "bad_missing_type",
             "invalid_activity_input" => true,
             "invalid_activity_input_reason" => "missing_activity_type",
             "protection_decision" => "review_change",
             "protection_category" => "invalid_activity_input",
             "protection_reason" => "missing_activity_type"
           } = Timeline.preservation_status(%{id: :bad_missing_type, status: :planned})
  end

  test "builds reusable operational activity context and timeline links" do
    source = %{
      id: :cmd_source,
      type: :command,
      scenario_id: :leo_1,
      starts_at_s: 10.0,
      ends_at_s: 20.0,
      ground_station_id: :dss_14,
      resource_id: :power_bus,
      resource_source_quality: :declared,
      resource_trust_boundary: :operator_supplied,
      resource_trust_boundary_status: :declared,
      resource_provenance: %{source: :planner_input},
      resource_blocking_dimension: :power,
      fuel_margin: 0.92,
      power_margin: 0.44,
      storage_margin: 0.81,
      downlink_margin: 0.67,
      battery_capacity_wh: 1200.0,
      battery_energy_used_wh: 560.0,
      battery_energy_generated_wh: 84.0,
      battery_state_of_charge: 0.53,
      spacecraft_available: "true",
      payload_available: "false",
      degraded: "true",
      activity_template: %{
        schema_contract: :"activity_template.v1",
        id: :command_template,
        activity_type: :command,
        subsystem_state_hints: %{
          required_states: [
            %{subsystem: :thermal},
            %{
              subsystem: :commanding,
              state: :armed,
              reason: "template requires armed commanding state",
              blocking: true
            }
          ],
          produced_states: [
            %{subsystem: :commanding, state: :executed}
          ]
        }
      },
      mode: :degraded_payload,
      incompatible_activity_types: [:observe],
      suppressed_activity_types: [:downlink],
      direction: :command,
      station_availability: :reserved,
      station_calendar_entry_id: :"declared:dss_14:10:20",
      station_calendar_status: :reserved_overlap,
      station_calendar_overlap_count: 1,
      station_calendar_overlap_entry_ids: [:"declared:dss_14:10:20"],
      station_calendar_overlap_availabilities: [:reserved],
      station_calendar_reservation_overlap_count: 1,
      station_calendar_reservation_ids: [:reservation_cmd],
      station_calendar_reserved_by: [:ops],
      station_calendar_reservation_statuses: [:active],
      schedule_conflict_status: :contention_detected,
      command_authority_status: :operator_required,
      required_authority: :flight_director,
      command_authorized: false,
      command_safety_status: :unsafe,
      command_safety_checked: false,
      command_result: :rejected,
      approval_status: :approved,
      locked: true,
      cadence_import: %{
        activity_type: :command,
        external_id: :cadence_cmd_source,
        schema_contract: :"planned_activity.v1"
      },
      dependencies: [
        :obs_1,
        %{activity_id: :health_check_1, timeline_id: :"timeline:health_check_1"}
      ],
      allow_overlap: true,
      metadata: %{
        antenna_available: 1,
        timeline_id: :"timeline:cmd_source",
        exclusive_with: [%{id: :dl_conflict, timeline_id: :"timeline:dl_conflict"}]
      }
    }

    replacement = %{
      id: :cmd_replacement,
      type: :command,
      scenario_id: :leo_1,
      starts_at_s: 30.0,
      ends_at_s: 40.0,
      ground_station_id: :dss_14,
      direction: :command,
      metadata: %{timeline_id: :"timeline:cmd_replacement"}
    }

    assert %{
             "approval_status" => "approved",
             "direction" => "command",
             "starts_at_s" => 10.0,
             "ends_at_s" => 20.0,
             "resource_id" => "power_bus",
             "resource_source_quality" => "declared",
             "resource_trust_boundary" => "operator_supplied",
             "resource_trust_boundary_status" => "declared",
             "resource_provenance" => %{"source" => "planner_input"},
             "resource_blocking_dimension" => "power",
             "fuel_margin" => 0.92,
             "power_margin" => 0.44,
             "storage_margin" => 0.81,
             "downlink_margin" => 0.67,
             "battery_capacity_wh" => 1200.0,
             "battery_energy_used_wh" => 560.0,
             "battery_energy_generated_wh" => 84.0,
             "battery_state_of_charge" => 0.53,
             "spacecraft_available" => true,
             "payload_available" => false,
             "antenna_available" => true,
             "degraded" => true,
             "mode" => "degraded_payload",
             "incompatible_activity_types" => ["observe"],
             "suppressed_activity_types" => ["downlink"],
             "ground_station_id" => "dss_14",
             "station_availability" => "reserved",
             "station_calendar_entry_id" => "declared:dss_14:10:20",
             "station_calendar_status" => "reserved_overlap",
             "station_calendar_overlap_count" => 1,
             "station_calendar_overlap_entry_ids" => ["declared:dss_14:10:20"],
             "station_calendar_overlap_availabilities" => ["reserved"],
             "station_calendar_reservation_overlap_count" => 1,
             "station_calendar_reservation_ids" => ["reservation_cmd"],
             "station_calendar_reserved_by" => ["ops"],
             "station_calendar_reservation_statuses" => ["active"],
             "schedule_conflict_status" => "contention_detected",
             "command_authority_status" => "operator_required",
             "required_authority" => "flight_director",
             "command_authorized" => false,
             "command_safety_status" => "unsafe",
             "command_safety_checked" => false,
             "locked" => true,
             "cadence_import" => %{
               "activity_type" => "command",
               "external_id" => "cadence_cmd_source",
               "schema_contract" => "planned_activity.v1"
             },
             "dependencies" => [
               "obs_1",
               %{
                 "activity_id" => "health_check_1",
                 "timeline_id" => "timeline:health_check_1"
               }
             ],
             "dependency_activity_ids" => ["health_check_1", "obs_1"],
             "dependency_timeline_ids" => ["timeline:health_check_1"],
             "exclusive_with_activity_ids" => ["dl_conflict"],
             "exclusive_with_timeline_ids" => ["timeline:dl_conflict"],
             "allow_overlap" => true,
             "timeline_identity" => %{
               "timeline_id" => "timeline:cmd_source",
               "activity_id" => "cmd_source",
               "activity_type" => "command",
               "scenario_id" => "leo_1",
               "subject_id" => "dss_14"
             }
           } = Timeline.activity_context(source)

    report = Timeline.operational_report([source])

    assert %{
             "precondition_status" => "blocked",
             "blocked_precondition_count" => 3,
             "review_precondition_count" => 4,
             "blocked_precondition_types" => [
               "command_safety_failed",
               "payload_unavailable",
               "resource_block_declared"
             ],
             "review_precondition_types" => [
               "command_authority_missing",
               "command_safety_unchecked",
               "degraded_mode",
               "subsystem_state_required"
             ],
             "preconditions" => preconditions
           } = List.first(report["rows"])

    assert %{
             "type" => "resource_block_declared",
             "status" => "blocked",
             "field" => "resource_blocking_dimension",
             "reason" => "resource blocking dimension is explicitly declared",
             "value" => "power"
           } in preconditions

    assert %{
             "type" => "command_authority_missing",
             "status" => "review_required",
             "field" => "command_authorized",
             "reason" => "command authority is explicitly not granted",
             "value" => false
           } in preconditions

    assert %{
             "type" => "command_safety_failed",
             "status" => "blocked",
             "field" => "command_safety_status",
             "reason" => "command safety status is explicitly unsafe or failed",
             "value" => "unsafe"
           } in preconditions

    assert %{
             "type" => "command_safety_unchecked",
             "status" => "review_required",
             "field" => "command_safety_checked",
             "reason" => "command safety check requires review before command handoff",
             "value" => false
           } in preconditions

    assert %{
             "type" => "subsystem_state_required",
             "status" => "review_required",
             "field" => "activity_template.subsystem_state_hints.required_states[1]",
             "reason" => "template requires armed commanding state",
             "value" => %{
               "subsystem" => "commanding",
               "state" => "armed",
               "blocking" => true
             }
           } in preconditions

    refute Enum.any?(preconditions, &(&1["type"] == "subsystem_state_produced"))

    assert %{
             "model" => "artifact_only_timeline_activity_precondition_summary",
             "schema_contract" => "timeline_activity_precondition_summary.v1",
             "validation_level" => "artifact_contract",
             "activity_id" => "cmd_source",
             "timeline_id" => "timeline:cmd_source",
             "activity_type" => "command",
             "precondition_status" => "blocked",
             "blocked_precondition_count" => 3,
             "review_precondition_count" => 4,
             "blocked_precondition_types" => [
               "command_safety_failed",
               "payload_unavailable",
               "resource_block_declared"
             ],
             "review_precondition_types" => [
               "command_authority_missing",
               "command_safety_unchecked",
               "degraded_mode",
               "subsystem_state_required"
             ],
             "preconditions" => ^preconditions,
             "dependency_activity_ids" => ["health_check_1", "obs_1"],
             "dependency_timeline_ids" => ["timeline:health_check_1"],
             "exclusive_with_activity_ids" => ["dl_conflict"],
             "exclusive_with_timeline_ids" => ["timeline:dl_conflict"],
             "allow_overlap" => true,
             "timeline_identity" => %{
               "timeline_id" => "timeline:cmd_source",
               "activity_id" => "cmd_source",
               "activity_type" => "command",
               "scenario_id" => "leo_1",
               "subject_id" => "dss_14"
             },
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_schedule_mutation",
               "operator_authority" => "not_granted_by_precondition_summary",
               "resource_authority" => "not_reserved_by_precondition_summary"
             }
           } = precondition_summary = Timeline.activity_precondition_summary(source)

    assert OrbitalDynamics.timeline_activity_precondition_summary(source) == precondition_summary

    assert {:ok, %{"schema_contract" => "timeline_activity_precondition_summary.v1"}} =
             Schema.validate_artifact(precondition_summary)

    assert %{
             "schema_contract" => "timeline_activity_precondition_summary.v1",
             "validation_level" => "artifact_contract",
             "precondition_status" => "clear",
             "blocked_precondition_count" => 0,
             "review_precondition_count" => 0,
             "preconditions" => []
           } =
             Timeline.activity_precondition_summary(%{
               id: :cmd_clear,
               type: :command,
               spacecraft_available: true,
               payload_available: true
             })

    assert %{
             "schema_contract" => "timeline_activity_precondition_summary.v1",
             "validation_level" => "artifact_contract",
             "precondition_status" => "review_required",
             "invalid_activity_input" => true,
             "invalid_activity_input_reason" => "missing_activity_type",
             "preconditions" => []
           } = Timeline.activity_precondition_summary(%{id: :bad_missing_type})

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_operational_timeline_report(report)
    import = CadenceImport.from_operational_timeline_report(report)

    assert %{
             "precondition_status" => "blocked",
             "blocked_precondition_count" => 3,
             "review_precondition_count" => 4,
             "blocked_precondition_types" => [
               "command_safety_failed",
               "payload_unavailable",
               "resource_block_declared"
             ],
             "review_precondition_types" => [
               "command_authority_missing",
               "command_safety_unchecked",
               "degraded_mode",
               "subsystem_state_required"
             ],
             "preconditions" => ^preconditions,
             "source_operational_timeline" => %{
               "precondition_status" => "blocked",
               "blocked_precondition_count" => 3,
               "review_precondition_count" => 4,
               "blocked_precondition_types" => [
                 "command_safety_failed",
                 "payload_unavailable",
                 "resource_block_declared"
               ],
               "review_precondition_types" => [
                 "command_authority_missing",
                 "command_safety_unchecked",
                 "degraded_mode",
                 "subsystem_state_required"
               ],
               "preconditions" => ^preconditions
             }
           } = List.first(review["rows"])

    assert %{
             "precondition_status" => "blocked",
             "blocked_precondition_count" => 3,
             "review_precondition_count" => 4,
             "blocked_precondition_types" => [
               "command_safety_failed",
               "payload_unavailable",
               "resource_block_declared"
             ],
             "review_precondition_types" => [
               "command_authority_missing",
               "command_safety_unchecked",
               "degraded_mode",
               "subsystem_state_required"
             ],
             "preconditions" => ^preconditions,
             "source_review_row" => %{
               "precondition_status" => "blocked",
               "blocked_precondition_count" => 3,
               "review_precondition_count" => 4,
               "blocked_precondition_types" => [
                 "command_safety_failed",
                 "payload_unavailable",
                 "resource_block_declared"
               ],
               "review_precondition_types" => [
                 "command_authority_missing",
                 "command_safety_unchecked",
                 "degraded_mode",
                 "subsystem_state_required"
               ],
               "preconditions" => ^preconditions
             },
             "source_operational_timeline" => %{
               "precondition_status" => "blocked",
               "blocked_precondition_count" => 3,
               "review_precondition_count" => 4,
               "blocked_precondition_types" => [
                 "command_safety_failed",
                 "payload_unavailable",
                 "resource_block_declared"
               ],
               "review_precondition_types" => [
                 "command_authority_missing",
                 "command_safety_unchecked",
                 "degraded_mode",
                 "subsystem_state_required"
               ],
               "preconditions" => ^preconditions
             }
           } = List.first(import["rows"])

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)

    invalid_report = put_in(report, ["rows", Access.at(0), "precondition_status"], "custom")

    assert {:error, validation_report} = Schema.validate_artifact(invalid_report)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.rows[0].precondition_status" and
                 &1["message"] =~ "must be one of")
           )

    stale_review =
      put_in(review, ["rows", Access.at(0), "blocked_precondition_count"], 0)

    assert {:error, stale_review_report} = Schema.validate_artifact(stale_review)

    assert Enum.any?(
             stale_review_report["errors"],
             &(&1["path"] == "$.rows[0].blocked_precondition_count" and
                 &1["message"] ==
                   "must match source_operational_timeline.blocked_precondition_count")
           )

    stale_import =
      put_in(import, ["rows", Access.at(0), "source_review_row", "precondition_status"], "clear")

    assert {:error, stale_import_report} = Schema.validate_artifact(stale_import)

    assert Enum.any?(
             stale_import_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.precondition_status" and
                 &1["message"] == "must match precondition_status on Cadence import row")
           )

    stale_import_source_timeline =
      put_in(
        import,
        ["rows", Access.at(0), "source_operational_timeline", "blocked_precondition_count"],
        0
      )

    assert {:error, stale_import_source_timeline_report} =
             Schema.validate_artifact(stale_import_source_timeline)

    assert Enum.any?(
             stale_import_source_timeline_report["errors"],
             &(&1["path"] == "$.rows[0].blocked_precondition_count" and
                 &1["message"] ==
                   "must match source_operational_timeline.blocked_precondition_count")
           )

    stale_import_source_review_timeline =
      put_in(
        import,
        [
          "rows",
          Access.at(0),
          "source_review_row",
          "source_operational_timeline",
          "blocked_precondition_count"
        ],
        0
      )

    assert {:error, stale_import_source_review_timeline_report} =
             Schema.validate_artifact(stale_import_source_review_timeline)

    assert Enum.any?(
             stale_import_source_review_timeline_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.blocked_precondition_count" and
                 &1["message"] ==
                   "must match source_operational_timeline.blocked_precondition_count")
           )

    assert %{
             "source_timeline_id" => "timeline:cmd_source",
             "replacement_timeline_id" => "timeline:cmd_replacement",
             "source_activity_id" => "cmd_source",
             "replacement_activity_id" => "cmd_replacement"
           } = Timeline.timeline_link(source, replacement)

    assert OrbitalDynamics.timeline_activity_context(source) == Timeline.activity_context(source)

    assert OrbitalDynamics.timeline_identity(source) == Timeline.timeline_identity(source)

    assert OrbitalDynamics.timeline_link(source, replacement) ==
             Timeline.timeline_link(source, replacement)
  end

  test "activity context flattens station calendar entry id from nested source evidence" do
    activity = %{
      id: :dl_nested_station_calendar,
      type: :downlink,
      scenario_id: :leo_1,
      starts_at_s: 10.0,
      ends_at_s: 20.0,
      ground_station_id: :dss_14,
      source_station_calendar_entry: %{
        id: :provider_entry_only,
        provenance: %{trust_boundary: :ground_partner_api}
      },
      source_station_calendar_overlaps: [
        %{id: :provider_entry_only}
      ],
      station_calendar_trust_boundary_status: :declared,
      trust_boundary: :ground_partner_api
    }

    assert %{
             "station_calendar_entry_id" => "provider_entry_only",
             "station_calendar_trust_boundary_status" => "declared",
             "trust_boundary" => "ground_partner_api",
             "source_station_calendar_entry" => %{"id" => "provider_entry_only"},
             "source_station_calendar_overlaps" => [%{"id" => "provider_entry_only"}]
           } = Timeline.activity_context(activity)

    assert %{
             "activity_context" => %{
               "station_calendar_entry_id" => "provider_entry_only",
               "source_station_calendar_entry" => %{"id" => "provider_entry_only"}
             }
           } = Timeline.normalize_activity(activity)
  end

  test "activity context preserves observation lighting evidence for review handoff" do
    activity = %{
      id: :obs_lighting,
      type: :observe,
      scenario_id: :leo_1,
      starts_at_s: 10.0,
      ends_at_s: 20.0,
      target_id: :target_a,
      source_window: %{
        id: :target_visibility_window,
        type: :target_visibility,
        boundary_refinement: :linear_sample_crossing,
        start_boundary_detail: %{
          boundary: :visibility_start,
          interpolation: :linear_sample_crossing,
          interpolation_fraction: 0.5
        }
      },
      eclipse_overlap_s: 4.0,
      eclipse_overlap_fraction: 0.4,
      lighting_condition: :partial_eclipse,
      lighting_condition_detail: :mixed_lighting,
      lighting_condition_model: :sampled_eclipse_overlap_tag,
      lighting_detail_model: :sampled_eclipse_overlap_fraction_tag,
      lighting_confidence: :bounded_by_sampled_eclipse_overlap
    }

    assert %{
             "eclipse_overlap_s" => 4.0,
             "eclipse_overlap_fraction" => 0.4,
             "source_window_id" => "target_visibility_window",
             "source_window_type" => "target_visibility",
             "source_window" => %{
               "id" => "target_visibility_window",
               "boundary_refinement" => "linear_sample_crossing",
               "start_boundary_detail" => %{"interpolation_fraction" => 0.5}
             },
             "lighting_condition" => "partial_eclipse",
             "lighting_condition_detail" => "mixed_lighting",
             "lighting_condition_model" => "sampled_eclipse_overlap_tag",
             "lighting_detail_model" => "sampled_eclipse_overlap_fraction_tag",
             "lighting_confidence" => "bounded_by_sampled_eclipse_overlap"
           } = Timeline.activity_context(activity)

    assert {:ok, feedback_schema} = Schema.json_schema("timeline_feedback_report.v1")

    assert get_in(feedback_schema, [
             "properties",
             "rows",
             "items",
             "properties",
             "source_activity_context",
             "properties",
             "lighting_confidence",
             "type"
           ]) == ["number", "string"]

    assert %{
             "activity_context" => %{
               "source_window_type" => "target_visibility",
               "lighting_condition" => "partial_eclipse",
               "eclipse_overlap_fraction" => 0.4
             }
           } = Timeline.normalize_activity(activity)
  end

  test "activity context normalizes provider lighting aliases on raw timeline maps" do
    activity = %{
      "id" => "obs_provider_lighting_aliases",
      "type" => "observe",
      "starts_at_s" => 10.0,
      "ends_at_s" => 20.0,
      "target_id" => "target_a",
      "lighting_status" => "partial_eclipse",
      "lighting_detail" => "mixed_lighting",
      "lighting_model" => "sampled_eclipse_overlap_tag",
      "lighting_detail_source" => "sampled_eclipse_overlap_fraction_tag",
      "lighting_confidence_label" => "bounded_by_sampled_eclipse_overlap"
    }

    assert %{
             "lighting_condition" => "partial_eclipse",
             "lighting_condition_detail" => "mixed_lighting",
             "lighting_condition_model" => "sampled_eclipse_overlap_tag",
             "lighting_detail_model" => "sampled_eclipse_overlap_fraction_tag",
             "lighting_confidence" => "bounded_by_sampled_eclipse_overlap"
           } = Timeline.activity_context(activity)

    assert %{
             "activity_context" => %{
               "lighting_condition" => "partial_eclipse",
               "lighting_condition_detail" => "mixed_lighting",
               "lighting_condition_model" => "sampled_eclipse_overlap_tag",
               "lighting_detail_model" => "sampled_eclipse_overlap_fraction_tag",
               "lighting_confidence" => "bounded_by_sampled_eclipse_overlap"
             }
           } = Timeline.normalize_activity(activity)
  end

  test "activity context lifts provider metadata source-window provenance" do
    activity = %{
      id: :obs_metadata_window,
      type: :observe,
      scenario_id: :leo_1,
      starts_at_s: 10.0,
      ends_at_s: 20.0,
      target_id: :target_a,
      metadata: %{
        source_window: %{
          window_id: :provider_visibility_window,
          kind: :target_visibility,
          boundary_refinement: :linear_sample_crossing
        }
      }
    }

    assert %{
             "source_window_id" => "provider_visibility_window",
             "source_window_type" => "target_visibility",
             "source_window" => %{
               "window_id" => "provider_visibility_window",
               "kind" => "target_visibility",
               "boundary_refinement" => "linear_sample_crossing"
             }
           } = Timeline.activity_context(activity)

    report = Timeline.operational_report([activity])

    assert %{
             "source_window_id" => "provider_visibility_window",
             "source_window_type" => "target_visibility",
             "has_source_window" => true,
             "activity_context" => %{
               "source_window" => %{"window_id" => "provider_visibility_window"}
             }
           } = List.first(report["rows"])

    assert report["source_window_lineage_count"] == 1

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "builds reusable status and approval transition helpers" do
    source = %{
      id: :obs_1,
      type: :observe,
      status: :planned,
      approval_status: :pending,
      metadata: %{timeline_id: :"timeline:obs_1"}
    }

    replacement = %{
      id: :obs_1b,
      type: :observe,
      status: :completed,
      approval_status: :approved,
      metadata: %{timeline_id: :"timeline:obs_1"}
    }

    assert %{
             "status_transition" => %{
               "field" => "status",
               "transition_type" => "changed",
               "from" => "planned",
               "to" => "completed",
               "from_category" => "planned",
               "to_category" => "executed",
               "transition_category" => "execution_recorded",
               "requires_operator_review" => false,
               "operator_action_reason" => "activity_execution_recorded"
             },
             "approval_transition" => %{
               "field" => "approval_status",
               "transition_type" => "changed",
               "from" => "pending",
               "to" => "approved",
               "from_category" => "review_required",
               "to_category" => "protected",
               "transition_category" => "approval_granted",
               "requires_operator_review" => true,
               "operator_action_reason" => "approval_grant_requires_operator_authority"
             }
           } = Timeline.activity_transition(source, replacement)

    assert %{
             "field" => "status",
             "transition_type" => "added",
             "to" => "planned",
             "to_category" => "planned",
             "transition_category" => "status_added",
             "requires_operator_review" => false
           } = Timeline.status_transition(nil, %{id: :new_cmd, type: :command})

    assert %{
             "field" => "approval_status",
             "transition_type" => "removed",
             "from" => "approved",
             "from_category" => "protected",
             "transition_category" => "protected_approval_removed",
             "requires_operator_review" => true,
             "operator_action_reason" => "protected_approval_removed"
           } = Timeline.approval_transition(%{id: :old_cmd, approval_status: :approved}, nil)

    assert %{
             "transition_category" => "executed_activity_changed",
             "requires_operator_review" => true,
             "operator_action_reason" => "executed_status_changed"
           } =
             Timeline.status_transition(%{id: :done, status: :completed}, %{
               id: :done,
               status: :planned
             })

    assert %{
             "transition_category" => "status_blocked",
             "from_category" => "planned",
             "to_category" => "blocked",
             "requires_operator_review" => true,
             "operator_action_reason" => "activity_status_blocked_by_policy"
           } =
             Timeline.status_transition(%{id: :cmd_policy, status: :planned}, %{
               id: :cmd_policy,
               status: :blocked_by_policy
             })

    assert %{
             "transition_category" => "status_block_cleared",
             "from_category" => "blocked",
             "to_category" => "planned",
             "requires_operator_review" => true,
             "operator_action_reason" => "blocked_status_cleared"
           } =
             Timeline.status_transition(%{id: :cmd_policy, status: :blocked_by_policy}, %{
               id: :cmd_policy,
               status: :planned
             })

    assert %{
             "transition_category" => "approval_regressed",
             "requires_operator_review" => true,
             "operator_action_reason" => "protected_approval_regressed"
           } =
             Timeline.approval_transition(
               %{id: :approved, approval_status: :approved},
               %{id: :approved, approval_status: :pending}
             )

    assert %{
             "transition_category" => "approval_blocked",
             "requires_operator_review" => true,
             "operator_action_reason" => "approval_blocked_by_policy"
           } =
             Timeline.approval_transition(
               %{id: :pending_cmd, approval_status: :pending},
               %{id: :pending_cmd, approval_status: :blocked_by_policy}
             )

    assert is_nil(
             Timeline.status_transition(
               %{id: :done, status: " Completed "},
               %{id: :done, status: :completed}
             )
           )

    assert %{
             "field" => "status",
             "transition_type" => "changed",
             "from" => "provider_magic",
             "from_category" => "other",
             "to" => "planned",
             "to_category" => "planned",
             "transition_category" => "unsupported_status",
             "requires_operator_review" => true,
             "operator_action_reason" => "unsupported_source_status"
           } =
             Timeline.status_transition(
               %{id: :provider_cmd, status: "provider magic"},
               %{id: :provider_cmd, status: :planned}
             )

    assert %{
             "transition_category" => "unsupported_status",
             "requires_operator_review" => true,
             "operator_action_reason" => "unsupported_replacement_status"
           } =
             Timeline.status_transition(
               %{id: :provider_cmd, status: :planned},
               %{id: :provider_cmd, status: "provider magic"}
             )

    assert is_nil(
             Timeline.approval_transition(
               %{id: :approved, approval_status: " APPROVED "},
               %{id: :approved, approval_status: :approved}
             )
           )

    assert is_nil(
             Timeline.approval_transition(
               %{id: :review, approval_status: "operator review required"},
               %{id: :review, approval_status: :operator_review_required}
             )
           )

    assert %{
             "field" => "approval_status",
             "transition_type" => "changed",
             "from" => "provider_magic",
             "from_category" => "other",
             "to" => "approved",
             "to_category" => "protected",
             "transition_category" => "unsupported_approval_status",
             "requires_operator_review" => true,
             "operator_action_reason" => "unsupported_source_approval_status"
           } =
             Timeline.approval_transition(
               %{id: :provider_cmd, approval_status: "provider magic"},
               %{id: :provider_cmd, approval_status: :approved}
             )

    assert %{
             "transition_category" => "unsupported_approval_status",
             "requires_operator_review" => true,
             "operator_action_reason" => "unsupported_replacement_approval_status"
           } =
             Timeline.approval_transition(
               %{id: :provider_cmd, approval_status: :pending},
               %{id: :provider_cmd, approval_status: "provider magic"}
             )

    assert OrbitalDynamics.timeline_activity_transition(source, replacement) ==
             Timeline.activity_transition(source, replacement)

    assert OrbitalDynamics.timeline_status_transition(source, replacement) ==
             Timeline.status_transition(source, replacement)

    assert OrbitalDynamics.timeline_approval_transition(source, replacement) ==
             Timeline.approval_transition(source, replacement)
  end

  test "applies safe timeline activity status and approval transitions" do
    activity = %{
      id: :cmd_transition,
      type: :command,
      scenario_id: :leo_1,
      status: "In Progress",
      approval_status: :pending,
      metadata: %{
        timeline_id: :"timeline:cmd_transition",
        source_window_id: :"window:cmd_transition"
      }
    }

    assert {:ok,
            %{
              "activity_id" => "cmd_transition",
              "activity_type" => "command",
              "status" => "completed",
              "approval_status" => "pending",
              "timeline_id" => "timeline:cmd_transition",
              "source_window_id" => "window:cmd_transition",
              "activity_context" => %{
                "status" => "completed",
                "approval_status" => "pending",
                "timeline_identity" => %{
                  "activity_id" => "cmd_transition",
                  "timeline_id" => "timeline:cmd_transition",
                  "source_window_id" => "window:cmd_transition"
                }
              }
            } = completed} = Timeline.transition_activity_status(activity, "succeeded")

    assert completed == Timeline.transition_activity_status!(activity, "succeeded")

    assert %{
             "helper" => "transition_activity_status",
             "field" => "status",
             "transition_type" => "changed",
             "from" => "executing",
             "to" => "completed",
             "requires_operator_review" => false
           } = completed["transition_application_provenance"]

    assert completed["activity_context"]["transition_application_provenance"] ==
             completed["transition_application_provenance"]

    assert OrbitalDynamics.timeline_transition_activity_status(activity, "succeeded") ==
             {:ok, completed}

    assert OrbitalDynamics.timeline_transition_activity_status!(activity, "succeeded") ==
             completed

    assert {:ok,
            %{
              "activity_id" => "cmd_transition",
              "status" => "executing",
              "approval_status" => "not_required",
              "timeline_id" => "timeline:cmd_transition",
              "activity_context" => %{
                "approval_status" => "not_required",
                "timeline_identity" => %{"timeline_id" => "timeline:cmd_transition"}
              }
            } = no_review_required} =
             Timeline.transition_activity_approval_status(activity, "No Review Required")

    assert no_review_required ==
             Timeline.transition_activity_approval_status!(activity, "No Review Required")

    assert %{
             "helper" => "transition_activity_approval_status",
             "field" => "approval_status",
             "transition_type" => "changed",
             "from" => "pending",
             "to" => "not_required",
             "requires_operator_review" => false
           } = no_review_required["transition_application_provenance"]

    assert OrbitalDynamics.timeline_transition_activity_approval_status(
             activity,
             "No Review Required"
           ) == {:ok, no_review_required}

    assert OrbitalDynamics.timeline_transition_activity_approval_status!(
             activity,
             "No Review Required"
           ) == no_review_required

    assert {:ok,
            %{
              "activity_id" => "cmd_transition",
              "status" => "completed",
              "approval_status" => "pending",
              "timeline_id" => "timeline:cmd_transition",
              "activity_context" => %{
                "status" => "completed",
                "timeline_identity" => %{"timeline_id" => "timeline:cmd_transition"}
              }
            } = lifecycle_completed} =
             Timeline.apply_lifecycle_event(activity, "record completion")

    assert lifecycle_completed == Timeline.apply_lifecycle_event!(activity, "record completion")

    assert %{
             "helper" => "apply_lifecycle_event",
             "field" => "status",
             "transition_type" => "changed",
             "from" => "executing",
             "to" => "completed",
             "requires_operator_review" => false
           } = lifecycle_provenance = lifecycle_completed["transition_application_provenance"]

    assert lifecycle_completed["activity_context"]["transition_application_provenance"] ==
             lifecycle_provenance

    assert OrbitalDynamics.timeline_apply_lifecycle_event(activity, "record completion") ==
             {:ok, lifecycle_completed}

    assert OrbitalDynamics.timeline_apply_lifecycle_event!(activity, "record completion") ==
             lifecycle_completed

    assert %{
             "transition_decision" => "record",
             "application_status" => "replacement_recorded",
             "transition_application_provenance" => ^lifecycle_provenance,
             "selected_activity" => %{
               "activity_id" => "cmd_transition",
               "status" => "completed",
               "transition_application_provenance" => ^lifecycle_provenance
             }
           } = Timeline.transition_application(activity, lifecycle_completed)

    forged_lifecycle_completed = Map.put(lifecycle_completed, "locked", true)
    forged_application = Timeline.transition_application(activity, forged_lifecycle_completed)

    refute forged_application["application_status"] == "replacement_recorded"
    refute Map.has_key?(forged_application, "transition_application_provenance")

    forged_approval_completed = Map.put(lifecycle_completed, "approval_status", "not_required")

    forged_approval_application =
      Timeline.transition_application(activity, forged_approval_completed)

    refute forged_approval_application["application_status"] == "replacement_recorded"
    refute Map.has_key?(forged_approval_application, "transition_application_provenance")

    completed_activity = Map.put(activity, :status, :completed)

    assert {:error,
            %{
              "transition_category" => "executed_activity_changed",
              "requires_operator_review" => true,
              "operator_action_reason" => "executed_status_changed"
            }} = Timeline.transition_activity_status(completed_activity, :planned)

    assert_raise ArgumentError,
                 ~r/unsafe timeline activity status transition completed -> planned/,
                 fn ->
                   Timeline.transition_activity_status!(completed_activity, :planned)
                 end

    assert {:error,
            %{
              "field" => "status",
              "transition_category" => "executed_activity_changed",
              "requires_operator_review" => true,
              "operator_action_reason" => "executed_status_changed"
            }} = Timeline.apply_lifecycle_event(completed_activity, "record partial")

    assert_raise ArgumentError,
                 ~r/unsafe timeline activity lifecycle event status transition completed -> partial/,
                 fn ->
                   Timeline.apply_lifecycle_event!(completed_activity, "record partial")
                 end

    assert {:error,
            %{
              "field" => "approval_status",
              "transition_category" => "approval_granted",
              "requires_operator_review" => true,
              "operator_action_reason" => "approval_grant_requires_operator_authority"
            }} = Timeline.apply_lifecycle_event(activity, "lock")

    assert_raise ArgumentError,
                 ~r/unsafe timeline activity lifecycle event approval_status transition pending -> locked/,
                 fn ->
                   Timeline.apply_lifecycle_event!(activity, "lock")
                 end

    assert {:error,
            %{
              "field" => "status",
              "transition_category" => "invalid_activity_input",
              "requires_operator_review" => true,
              "operator_action_reason" => "invalid_activity_input"
            }} = Timeline.apply_lifecycle_event(%{id: :missing_type}, "record completion")

    assert {:error,
            %{
              "transition_category" => "approval_granted",
              "requires_operator_review" => true,
              "operator_action_reason" => "approval_grant_requires_operator_authority"
            }} = Timeline.transition_activity_approval_status(activity, :approved)

    assert_raise ArgumentError,
                 ~r/unsafe timeline activity approval transition pending -> approved/,
                 fn ->
                   Timeline.transition_activity_approval_status!(activity, :approved)
                 end

    assert {:error,
            %{
              "transition_category" => "invalid_activity_input",
              "operator_action_reason" => "invalid_activity_input"
            }} = Timeline.transition_activity_status(activity, "provider magic")
  end

  test "direct lifecycle helpers can gate selected activity integrity" do
    activity = %{
      id: :cmd_waiting_on_gate,
      type: :command,
      scenario_id: :leo_1,
      status: :executing,
      approval_status: :pending,
      starts_at_s: 10.0,
      ends_at_s: 20.0,
      depends_on: [:missing_gate],
      metadata: %{timeline_id: :"timeline:cmd_waiting_on_gate"}
    }

    assert {:ok, completed} = Timeline.transition_activity_status(activity, "succeeded")
    refute Map.has_key?(completed, "timeline_integrity_status")

    assert {:ok, completed_without_dependency_check} =
             Timeline.transition_activity_status(activity, "succeeded",
               validate_selected_integrity?: true,
               validate_selected_dependencies?: false
             )

    refute Map.has_key?(completed_without_dependency_check, "timeline_integrity_status")

    assert {:error,
            %{
              "field" => "timeline_integrity",
              "transition_category" => "selected_timeline_integrity_review_required",
              "requires_operator_review" => true,
              "required_operator_action" => "review_timeline_integrity",
              "operator_action_reason" =>
                "selected_timeline_integrity_issue_requires_review:missing_dependency_activity",
              "selected_timeline_integrity_status" => "review_required",
              "selected_timeline_integrity_issue_count" => 1,
              "selected_timeline_integrity_issue_types" => ["missing_dependency_activity"],
              "selected_missing_dependency_activity_ids" => ["missing_gate"]
            }} =
             Timeline.transition_activity_status(activity, "succeeded",
               validate_selected_integrity?: true
             )

    assert_raise ArgumentError,
                 ~r/unsafe timeline activity selected integrity: selected_timeline_integrity_issue_requires_review:missing_dependency_activity/,
                 fn ->
                   Timeline.transition_activity_status!(activity, "succeeded",
                     validate_selected_integrity?: true
                   )
                 end

    assert {:error,
            %{
              "field" => "timeline_integrity",
              "selected_timeline_integrity_issue_types" => ["missing_dependency_activity"]
            }} =
             Timeline.transition_activity_approval_status(activity, "No Review Required",
               validate_selected_integrity?: true
             )

    lifecycle_error =
      Timeline.apply_lifecycle_event(activity, "record completion",
        validate_selected_integrity?: true
      )

    assert {:error,
            %{
              "field" => "timeline_integrity",
              "selected_timeline_integrity_issue_types" => ["missing_dependency_activity"]
            }} = lifecycle_error

    assert OrbitalDynamics.timeline_apply_lifecycle_event(activity, "record completion",
             validate_selected_integrity?: true
           ) == lifecycle_error

    duplicate_exclusivity_activity =
      activity
      |> Map.delete(:depends_on)
      |> Map.put(:id, :cmd_duplicate_exclusivity)
      |> Map.put(:exclusive_with_activity_ids, [:dl_clear, :dl_clear])
      |> put_in([:metadata, :timeline_id], :"timeline:cmd_duplicate_exclusivity")

    assert {:error,
            %{
              "field" => "timeline_integrity",
              "required_operator_action" => "review_timeline_integrity",
              "selected_timeline_integrity_issue_count" => 1,
              "selected_timeline_integrity_issue_types" => [
                "duplicate_exclusivity_activity"
              ],
              "selected_timeline_integrity_issues" => [
                %{
                  "type" => "duplicate_exclusivity_activity",
                  "duplicate_exclusivity_activity_id" => "dl_clear"
                }
              ]
            }} =
             Timeline.transition_activity_status(duplicate_exclusivity_activity, "succeeded",
               validate_selected_integrity?: true,
               validate_selected_dependencies?: false
             )
  end

  test "normalizes planned and realized activity status state for review and import handoff" do
    planned = %{
      id: :obs_provider,
      type: :observe,
      scenario_id: :leo_1,
      status: "In Progress",
      metadata: %{
        timeline_id: :"timeline:obs_provider",
        source_window_id: :"visibility:obs_provider"
      }
    }

    realized = %{
      id: :obs_provider,
      type: :observe,
      scenario_id: :leo_1,
      status: "succeeded",
      metadata: %{timeline_id: :"timeline:obs_provider"}
    }

    assert %{
             "schema_contract" => "timeline_activity_status_state.v1",
             "model" => "artifact_only_timeline_activity_status_state",
             "model_limits" => model_limits,
             "validation_level" => "artifact_contract",
             "activity_id" => "obs_provider",
             "planned_activity_id" => "obs_provider",
             "realized_activity_id" => "obs_provider",
             "timeline_id" => "timeline:obs_provider",
             "planned_timeline_id" => "timeline:obs_provider",
             "realized_timeline_id" => "timeline:obs_provider",
             "planned_status" => "executing",
             "realized_status" => "completed",
             "planned_status_category" => "planned",
             "realized_status_category" => "executed",
             "transition_decision" => "record",
             "review_required" => false,
             "required_operator_action" => "record_timeline_change",
             "operator_action_reason" => "activity_execution_recorded",
             "import_action" => "import_replacement_activity",
             "status_transition" => %{
               "field" => "status",
               "transition_type" => "changed",
               "from" => "executing",
               "to" => "completed",
               "transition_category" => "execution_recorded",
               "requires_operator_review" => false
             },
             "planned_activity_context" => %{
               "status" => "executing",
               "source_window_id" => "visibility:obs_provider",
               "timeline_identity" => %{"activity_id" => "obs_provider"}
             },
             "realized_activity_context" => %{
               "status" => "completed",
               "timeline_identity" => %{"activity_id" => "obs_provider"}
             },
             "assumptions" => %{
               "artifact_only" => true,
               "no_schedule_mutation" => true,
               "no_operator_authority_grant" => true,
               "no_command_execution" => true
             }
           } = state = Timeline.activity_status_state(planned, realized)

    assert model_limits == Timeline.model_limits()
    assert OrbitalDynamics.timeline_activity_status_state(planned, realized) == state

    assert {:ok, %{"schema_contract" => "timeline_activity_status_state.v1"}} =
             Schema.validate_artifact(state)

    stale_model_limits = Map.put(state, "model_limits", ["timeline_model_is_read_only"])

    assert {:error, stale_model_limits_validation} =
             Schema.validate_artifact(stale_model_limits)

    assert Enum.any?(
             stale_model_limits_validation["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] == "must match timeline report model limits")
           )

    stale_transition_decision = Map.put(state, "transition_decision", "none")

    assert {:error, stale_transition_decision_validation} =
             Schema.validate_artifact(stale_transition_decision)

    assert Enum.any?(
             stale_transition_decision_validation["errors"],
             &(&1["path"] == "$.transition_decision" and
                 &1["message"] == "must equal transition-derived transition_decision")
           )

    assert %{
             "realized_status" => "blocked_by_policy",
             "realized_status_category" => "blocked",
             "transition_decision" => "review",
             "review_required" => true,
             "required_operator_action" => "review_activity_transition",
             "operator_action_reason" => "activity_status_blocked_by_policy",
             "import_action" => "review_timeline_diff"
           } =
             Timeline.activity_status_state(
               %{id: :obs_policy, type: :observe, status: :planned},
               %{id: :obs_policy, type: :observe, status: "blocked by policy"}
             )

    assert %{
             "transition_decision" => "none",
             "review_required" => false,
             "required_operator_action" => "none",
             "operator_action_reason" => "no_status_change",
             "import_action" => "record_preserved_activity"
           } =
             Timeline.activity_status_state(
               %{id: :obs_same, type: :observe, status: "done"},
               %{id: :obs_same, type: :observe, status: :completed}
             )

    assert %{
             "activity_id" => "obs_missing_type",
             "planned_activity_id" => "obs_missing_type",
             "realized_activity_id" => "obs_missing_type",
             "planned_status" => "invalid",
             "realized_status" => "completed",
             "transition_decision" => "review",
             "review_required" => true,
             "required_operator_action" => "review_activity_transition",
             "operator_action_reason" => "invalid_activity_input",
             "invalid_activity_input" => true,
             "invalid_activity_input_count" => 1,
             "invalid_activity_input_reasons" => ["missing_activity_type"],
             "status_transition" => %{
               "field" => "status",
               "transition_type" => "changed",
               "from" => "invalid",
               "to" => "completed",
               "transition_category" => "invalid_activity_input",
               "requires_operator_review" => true
             }
           } =
             invalid_state =
             Timeline.activity_status_state(
               %{id: :obs_missing_type, status: :planned},
               %{id: :obs_missing_type, type: :observe, status: :completed}
             )

    assert {:ok, %{"schema_contract" => "timeline_activity_status_state.v1"}} =
             Schema.validate_artifact(invalid_state)

    assert_raise ArgumentError, ~r/planned or realized activity is required/, fn ->
      Timeline.activity_status_state(nil, nil)
    end
  end

  test "normalizes planned and realized activity approval state for review and import handoff" do
    planned = %{
      id: :cmd_provider,
      type: :command,
      scenario_id: :leo_1,
      approval_status: "Review Required",
      metadata: %{
        timeline_id: :"timeline:cmd_provider",
        source_window_id: :"command:cmd_provider"
      }
    }

    realized = %{
      id: :cmd_provider,
      type: :command,
      scenario_id: :leo_1,
      approval_status: :approved,
      metadata: %{timeline_id: :"timeline:cmd_provider"}
    }

    assert %{
             "schema_contract" => "timeline_activity_approval_state.v1",
             "model" => "artifact_only_timeline_activity_approval_state",
             "model_limits" => model_limits,
             "validation_level" => "artifact_contract",
             "activity_id" => "cmd_provider",
             "planned_activity_id" => "cmd_provider",
             "realized_activity_id" => "cmd_provider",
             "timeline_id" => "timeline:cmd_provider",
             "planned_timeline_id" => "timeline:cmd_provider",
             "realized_timeline_id" => "timeline:cmd_provider",
             "planned_approval_status" => "operator_review_required",
             "realized_approval_status" => "approved",
             "planned_approval_category" => "review_required",
             "realized_approval_category" => "protected",
             "transition_decision" => "review",
             "review_required" => true,
             "required_operator_action" => "review_activity_approval",
             "operator_action_reason" => "approval_grant_requires_operator_authority",
             "import_action" => "review_timeline_diff",
             "approval_transition" => %{
               "field" => "approval_status",
               "transition_type" => "changed",
               "from" => "operator_review_required",
               "to" => "approved",
               "transition_category" => "approval_granted",
               "requires_operator_review" => true
             },
             "planned_activity_context" => %{
               "approval_status" => "operator_review_required",
               "source_window_id" => "command:cmd_provider",
               "timeline_identity" => %{"activity_id" => "cmd_provider"}
             },
             "realized_activity_context" => %{
               "approval_status" => "approved",
               "timeline_identity" => %{"activity_id" => "cmd_provider"}
             },
             "assumptions" => %{
               "artifact_only" => true,
               "no_schedule_mutation" => true,
               "no_operator_authority_grant" => true,
               "no_command_execution" => true
             }
           } = state = Timeline.activity_approval_state(planned, realized)

    assert model_limits == Timeline.model_limits()
    assert OrbitalDynamics.timeline_activity_approval_state(planned, realized) == state

    assert {:ok, %{"schema_contract" => "timeline_activity_approval_state.v1"}} =
             Schema.validate_artifact(state)

    stale_model_limits = Map.put(state, "model_limits", ["timeline_model_is_read_only"])

    assert {:error, stale_model_limits_validation} =
             Schema.validate_artifact(stale_model_limits)

    assert Enum.any?(
             stale_model_limits_validation["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] == "must match timeline report model limits")
           )

    stale_required_operator_action = Map.put(state, "required_operator_action", "none")

    assert {:error, stale_required_operator_action_validation} =
             Schema.validate_artifact(stale_required_operator_action)

    assert Enum.any?(
             stale_required_operator_action_validation["errors"],
             &(&1["path"] == "$.required_operator_action" and
                 &1["message"] == "must equal transition-derived required_operator_action")
           )

    assert %{
             "realized_approval_status" => "blocked_by_policy",
             "realized_approval_category" => "blocked",
             "transition_decision" => "review",
             "review_required" => true,
             "required_operator_action" => "review_activity_approval",
             "operator_action_reason" => "approval_blocked_by_policy",
             "import_action" => "review_timeline_diff"
           } =
             Timeline.activity_approval_state(
               %{id: :cmd_policy, type: :command, approval_status: :pending},
               %{id: :cmd_policy, type: :command, approval_status: "policy blocked"}
             )

    assert %{
             "transition_decision" => "none",
             "review_required" => false,
             "required_operator_action" => "none",
             "operator_action_reason" => "no_approval_status_change",
             "import_action" => "record_preserved_activity"
           } =
             Timeline.activity_approval_state(
               %{id: :cmd_same, type: :command, approval_status: "No Review Required"},
               %{id: :cmd_same, type: :command, approval_status: :not_required}
             )

    assert %{
             "activity_id" => "cmd_missing_type",
             "planned_activity_id" => "cmd_missing_type",
             "realized_activity_id" => "cmd_missing_type",
             "planned_approval_status" => "pending",
             "realized_approval_status" => "operator_review_required",
             "transition_decision" => "review",
             "review_required" => true,
             "required_operator_action" => "review_activity_approval",
             "operator_action_reason" => "invalid_activity_input",
             "invalid_activity_input" => true,
             "invalid_activity_input_count" => 1,
             "invalid_activity_input_reasons" => ["missing_activity_type"],
             "approval_transition" => %{
               "field" => "approval_status",
               "transition_type" => "changed",
               "from" => "pending",
               "to" => "operator_review_required",
               "transition_category" => "invalid_activity_input",
               "requires_operator_review" => true
             }
           } =
             invalid_state =
             Timeline.activity_approval_state(
               %{id: :cmd_missing_type, type: :command, approval_status: :pending},
               %{id: :cmd_missing_type, approval_status: :approved}
             )

    assert {:ok, %{"schema_contract" => "timeline_activity_approval_state.v1"}} =
             Schema.validate_artifact(invalid_state)

    assert_raise ArgumentError, ~r/planned or realized activity is required/, fn ->
      Timeline.activity_approval_state(nil, nil)
    end
  end

  test "combines planned and realized lifecycle state for review and import handoff" do
    planned = %{
      id: :cmd_provider,
      type: :command,
      scenario_id: :leo_1,
      status: "In Progress",
      approval_status: "Review Required",
      metadata: %{
        timeline_id: :"timeline:cmd_provider",
        source_window_id: :"command:cmd_provider"
      }
    }

    realized = %{
      id: :cmd_provider,
      type: :command,
      scenario_id: :leo_1,
      status: "succeeded",
      approval_status: :approved,
      metadata: %{timeline_id: :"timeline:cmd_provider"}
    }

    assert %{
             "schema_contract" => "timeline_activity_lifecycle_state.v1",
             "model" => "artifact_only_timeline_activity_lifecycle_state",
             "model_limits" => model_limits,
             "validation_level" => "artifact_contract",
             "activity_id" => "cmd_provider",
             "planned_activity_id" => "cmd_provider",
             "realized_activity_id" => "cmd_provider",
             "timeline_id" => "timeline:cmd_provider",
             "planned_status" => "executing",
             "realized_status" => "completed",
             "planned_status_category" => "planned",
             "realized_status_category" => "executed",
             "planned_approval_status" => "operator_review_required",
             "realized_approval_status" => "approved",
             "planned_approval_category" => "review_required",
             "realized_approval_category" => "protected",
             "planned_locked" => false,
             "realized_locked" => false,
             "planned_executed" => false,
             "realized_executed" => true,
             "transition_decision" => "review",
             "review_required" => true,
             "required_operator_action" => "review_activity_approval",
             "required_operator_actions" => [
               "record_timeline_change",
               "review_activity_approval"
             ],
             "operator_action_reasons" => [
               "activity_execution_recorded",
               "approval_grant_requires_operator_authority"
             ],
             "import_action" => "review_timeline_diff",
             "status_transition" => %{
               "transition_category" => "execution_recorded"
             },
             "approval_transition" => %{
               "transition_category" => "approval_granted"
             },
             "planned_protection_decision" => %{
               "protection_decision" => "mutable",
               "protection_category" => "none"
             },
             "realized_protection_decision" => %{
               "protection_decision" => "preserve",
               "protection_category" => "executed"
             },
             "planned_activity_context" => %{
               "status" => "executing",
               "approval_status" => "operator_review_required",
               "source_window_id" => "command:cmd_provider"
             },
             "realized_activity_context" => %{
               "status" => "completed",
               "approval_status" => "approved"
             },
             "assumptions" => %{
               "artifact_only" => true,
               "no_schedule_mutation" => true,
               "no_operator_authority_grant" => true,
               "no_cadence_import" => true,
               "no_command_execution" => true
             }
           } = state = Timeline.activity_lifecycle_state(planned, realized)

    assert model_limits == Timeline.model_limits()
    assert OrbitalDynamics.timeline_activity_lifecycle_state(planned, realized) == state

    assert {:ok, %{"schema_contract" => "timeline_activity_lifecycle_state.v1"}} =
             Schema.validate_artifact(state)

    stale_model_limits = Map.put(state, "model_limits", ["timeline_model_is_read_only"])

    assert {:error, stale_model_limits_validation} =
             Schema.validate_artifact(stale_model_limits)

    assert Enum.any?(
             stale_model_limits_validation["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] == "must match timeline report model limits")
           )

    stale_required_operator_actions = Map.put(state, "required_operator_actions", ["none"])

    assert {:error, stale_required_operator_actions_validation} =
             Schema.validate_artifact(stale_required_operator_actions)

    assert Enum.any?(
             stale_required_operator_actions_validation["errors"],
             &(&1["path"] == "$.required_operator_actions" and
                 &1["message"] == "must equal lifecycle-derived required_operator_actions")
           )

    assert %{
             "realized_status" => "blocked_by_policy",
             "realized_approval_status" => "blocked_by_policy",
             "realized_status_category" => "blocked",
             "realized_approval_category" => "blocked",
             "transition_decision" => "review",
             "review_required" => true,
             "required_operator_action" => "review_activity_transition",
             "required_operator_actions" => [
               "review_activity_approval",
               "review_activity_transition"
             ],
             "operator_action_reasons" => [
               "activity_status_blocked_by_policy",
               "approval_blocked_by_policy"
             ],
             "import_action" => "review_timeline_diff"
           } =
             Timeline.activity_lifecycle_state(
               %{id: :cmd_policy, type: :command, status: :planned, approval_status: :pending},
               %{
                 id: :cmd_policy,
                 type: :command,
                 status: "blocked by policy",
                 approval_status: "policy blocked"
               }
             )

    assert %{
             "planned_locked" => true,
             "planned_executed" => true,
             "realized_executed" => true,
             "status_transition_decision" => "none",
             "approval_transition_decision" => "review",
             "transition_decision" => "review",
             "required_operator_action" => "review_activity_approval",
             "required_operator_actions" => ["review_activity_approval"],
             "operator_action_reasons" => ["protected_approval_regressed"],
             "planned_protection_decision" => %{
               "protection_decision" => "preserve",
               "protection_category" => "executed"
             }
           } =
             Timeline.activity_lifecycle_state(
               %{
                 id: :done_cmd,
                 type: :command,
                 status: :completed,
                 approval_status: :approved,
                 locked: "true"
               },
               %{
                 id: :done_cmd,
                 type: :command,
                 status: :completed,
                 approval_status: :rejected
               }
             )

    assert %{
             "activity_id" => "cmd_missing_type",
             "planned_activity_id" => "cmd_missing_type",
             "planned_status" => "invalid",
             "planned_approval_status" => "operator_review_required",
             "transition_decision" => "review",
             "review_required" => true,
             "required_operator_action" => "review_activity_transition",
             "required_operator_actions" => [
               "review_activity_approval",
               "review_activity_transition",
               "review_timeline_change"
             ],
             "operator_action_reasons" => [
               "invalid_activity_input",
               "missing_activity_type"
             ],
             "invalid_activity_input" => true,
             "invalid_activity_input_count" => 1,
             "invalid_activity_input_reasons" => ["missing_activity_type"],
             "planned_protection_decision" => %{
               "protection_decision" => "review_change",
               "protection_category" => "invalid_activity_input",
               "reason" => "missing_activity_type"
             }
           } =
             invalid_state =
             Timeline.activity_lifecycle_state(
               %{id: :cmd_missing_type, status: :planned, approval_status: :pending},
               nil
             )

    assert {:ok, %{"schema_contract" => "timeline_activity_lifecycle_state.v1"}} =
             Schema.validate_artifact(invalid_state)

    assert_raise ArgumentError, ~r/planned or realized activity is required/, fn ->
      Timeline.activity_lifecycle_state(nil, nil)
    end
  end

  test "summarizes planned and realized lifecycle state across activity sets" do
    planned = [
      %{
        id: :cmd_provider,
        type: :command,
        status: "In Progress",
        approval_status: "Review Required",
        metadata: %{timeline_id: :"timeline:cmd_provider"}
      },
      %{
        id: :obs_record,
        type: :observe,
        status: :executing,
        approval_status: :not_required,
        metadata: %{timeline_id: :"timeline:obs_record"}
      },
      %{
        id: :done_keep,
        type: :command,
        status: :completed,
        approval_status: :approved,
        metadata: %{timeline_id: :"timeline:done_keep"}
      },
      %{
        id: :dup_a,
        type: :observe,
        status: :planned,
        metadata: %{timeline_id: :"timeline:dup"}
      },
      %{
        id: :dup_b,
        type: :observe,
        status: :planned,
        metadata: %{timeline_id: :"timeline:dup"}
      }
    ]

    realized = [
      %{
        id: :cmd_provider,
        type: :command,
        status: "succeeded",
        approval_status: :approved,
        metadata: %{timeline_id: :"timeline:cmd_provider"}
      },
      %{
        id: :obs_record,
        type: :observe,
        status: :completed,
        approval_status: :not_required,
        metadata: %{timeline_id: :"timeline:obs_record"}
      },
      %{
        id: :done_keep,
        type: :command,
        status: :completed,
        approval_status: :approved,
        metadata: %{timeline_id: :"timeline:done_keep"}
      }
    ]

    assert %{
             "schema_contract" => "timeline_lifecycle_state_summary.v1",
             "model" => "artifact_only_timeline_lifecycle_state_summary",
             "validation_level" => "artifact_contract",
             "planned_activity_count" => 5,
             "realized_activity_count" => 3,
             "row_count" => 4,
             "recordable_count" => 1,
             "preserved_count" => 1,
             "review_required_count" => 2,
             "duplicate_timeline_identity_count" => 1,
             "invalid_activity_input_count" => 0,
             "transition_decision_counts" => %{
               "none" => 1,
               "record" => 1,
               "review" => 2
             },
             "required_operator_action_counts" => %{
               "none" => 1,
               "record_timeline_change" => 1,
               "review_activity_approval" => 1,
               "review_duplicate_timeline_identity" => 1
             },
             "import_action_counts" => %{
               "import_replacement_activity" => 1,
               "record_preserved_activity" => 1,
               "review_timeline_diff" => 2
             },
             "planned_status_category_counts" => %{"executed" => 1, "planned" => 2},
             "realized_status_category_counts" => %{"executed" => 3},
             "status_transition_category_counts" => %{"execution_recorded" => 2},
             "approval_transition_category_counts" => %{"approval_granted" => 1},
             "recordable_timeline_ids" => ["timeline:obs_record"],
             "preserved_timeline_ids" => ["timeline:done_keep"],
             "review_timeline_ids" => ["timeline:cmd_provider", "timeline:dup"],
             "review_activity_ids" => ["cmd_provider", "dup_a", "dup_b"],
             "invalid_activity_input_ids" => [],
             "review_timeline_ids_by_required_operator_action" => %{
               "review_activity_approval" => ["timeline:cmd_provider"],
               "review_duplicate_timeline_identity" => ["timeline:dup"]
             },
             "review_timeline_ids_by_approval_transition_category" => %{
               "approval_granted" => ["timeline:cmd_provider"]
             },
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_schedule_mutation",
               "operator_authority" => "not_granted_by_summary",
               "cadence_import" => "not_performed_by_summary",
               "command_execution" => "not_performed_by_summary"
             }
           } = summary = Timeline.lifecycle_state_summary(planned, realized)

    assert [%{"timeline_id" => "timeline:cmd_provider"}, %{"timeline_id" => "timeline:dup"}] =
             summary["review_rows"]

    assert %{
             "timeline_identity_collision" => true,
             "planned_activity_ids" => ["dup_a", "dup_b"],
             "transition_decision" => "review",
             "required_operator_actions" => ["review_duplicate_timeline_identity"]
           } = Enum.find(summary["rows"], &(&1["timeline_id"] == "timeline:dup"))

    assert OrbitalDynamics.timeline_lifecycle_state_summary(planned, realized) == summary

    assert {:ok, %{"schema_contract" => "timeline_lifecycle_state_summary.v1"}} =
             Schema.validate_artifact(summary)

    stale_review_count = Map.put(summary, "review_required_count", 99)
    assert {:error, stale_review_count_report} = Schema.validate_artifact(stale_review_count)

    assert Enum.any?(
             stale_review_count_report["errors"],
             &(&1["path"] == "$.review_required_count" and
                 &1["message"] == "must equal 2")
           )

    stale_review_rows = Map.put(summary, "review_rows", [])
    assert {:error, stale_review_rows_report} = Schema.validate_artifact(stale_review_rows)

    assert Enum.any?(
             stale_review_rows_report["errors"],
             &(&1["path"] == "$.review_rows" and
                 &1["message"] == "must equal row-derived review rows")
           )

    stale_invalid_activity_ids = Map.put(summary, "invalid_activity_input_ids", ["stale"])

    assert {:error, stale_invalid_activity_ids_report} =
             Schema.validate_artifact(stale_invalid_activity_ids)

    assert Enum.any?(
             stale_invalid_activity_ids_report["errors"],
             &(&1["path"] == "$.invalid_activity_input_ids" and
                 &1["message"] == "must equal row-derived invalid_activity_input_ids")
           )

    invalid_summary =
      Timeline.lifecycle_state_summary([%{id: :bad_missing_type}], [])

    assert %{
             "invalid_activity_input_count" => 1,
             "invalid_activity_input_ids" => ["timeline_row:1:bad_missing_type"],
             "review_required_count" => 1,
             "review_timeline_ids_by_required_operator_action" => %{
               "review_invalid_activity_input" => [
                 "timeline:invalid_activity_input:bad_missing_type"
               ]
             }
           } = invalid_summary

    assert_raise ArgumentError, ~r/planned and realized activities must be lists/, fn ->
      Timeline.lifecycle_state_summary(%{}, [])
    end
  end

  test "classifies reusable transition decisions for proposed activity changes" do
    source = %{
      id: :cmd_lock,
      type: :command,
      status: :planned,
      approval_status: :approved,
      locked: true,
      starts_at_s: 10.0,
      ends_at_s: 20.0,
      metadata: %{timeline_id: :"timeline:cmd_lock"}
    }

    replacement = %{
      id: :cmd_lock,
      type: :command,
      status: :planned,
      approval_status: :approved,
      locked: true,
      starts_at_s: 15.0,
      ends_at_s: 25.0,
      metadata: %{timeline_id: :"timeline:cmd_lock"}
    }

    assert %{
             "timeline_id" => "timeline:cmd_lock",
             "diff_status" => "changed",
             "transition_decision" => "preserve_source",
             "transition_decision_reason" => "activity_locked_or_approved",
             "requires_operator_review" => true,
             "required_operator_action" => "review_changed_protected_activity",
             "changed_fields" => ["starts_at_s", "ends_at_s"],
             "source_protection_decision" => %{
               "protection_decision" => "preserve",
               "protection_category" => "locked_or_approved",
               "reason" => "activity_locked_or_approved"
             },
             "replacement_protection_decision" => %{
               "protection_decision" => "preserve",
               "protection_category" => "locked_or_approved"
             }
           } = Timeline.transition_decision(source, replacement)

    assert %{
             "transition_decision" => "none",
             "transition_decision_reason" => "no_source_or_replacement_activity",
             "diff_status" => "unchanged",
             "requires_operator_review" => false,
             "changed_fields" => []
           } = Timeline.transition_decision(nil, nil)

    identity_change =
      Timeline.transition_decision(
        %{id: :obs_1, type: :observe, metadata: %{timeline_id: :"timeline:obs_old"}},
        %{id: :obs_1, type: :observe, metadata: %{timeline_id: :"timeline:obs_new"}}
      )

    assert %{
             "transition_decision" => "review",
             "transition_decision_reason" => "activity_transition_changes_timeline_identity",
             "requires_operator_review" => true,
             "required_operator_action" => "review_activity_transition",
             "changed_fields" => ["timeline_identity"],
             "transition_row_count" => 2,
             "transition_rows" => transition_rows
           } = identity_change

    assert Enum.map(transition_rows, & &1["diff_status"]) |> Enum.sort() == ["added", "removed"]

    missing_dependency_source = %{
      id: :obs_waiting_on_gate,
      type: :observe,
      target_id: :target_alpha,
      starts_at_s: 30.0,
      ends_at_s: 40.0,
      depends_on: [:missing_gate],
      metadata: %{timeline_id: :"timeline:obs_waiting_on_gate"}
    }

    assert %{
             "transition_decision" => "review",
             "transition_decision_reason" =>
               "selected_timeline_integrity_issue_requires_review:missing_dependency_activity",
             "diff_status" => "unchanged",
             "requires_operator_review" => true,
             "required_operator_action" => "review_timeline_integrity",
             "selected_timeline_integrity_status" => "review_required",
             "selected_timeline_integrity_issue_count" => 1,
             "selected_timeline_integrity_issue_types" => ["missing_dependency_activity"],
             "selected_missing_dependency_activity_ids" => ["missing_gate"]
           } = Timeline.transition_decision(missing_dependency_source, missing_dependency_source)

    self_dependency_source = %{
      id: :obs_waiting_on_self,
      type: :observe,
      target_id: :target_alpha,
      starts_at_s: 45.0,
      ends_at_s: 55.0,
      depends_on: [:obs_waiting_on_self],
      metadata: %{timeline_id: :"timeline:obs_waiting_on_self"}
    }

    assert %{
             "transition_decision" => "review",
             "transition_decision_reason" =>
               "source and replacement timeline activities require integrity review",
             "required_operator_action" => "review_timeline_integrity"
           } = Timeline.transition_decision(self_dependency_source, self_dependency_source)

    assert [
             %{
               "source_timeline_integrity_issue_types" => ["self_dependency_activity"],
               "source_self_dependency_activity_ids" => ["obs_waiting_on_self"],
               "replacement_self_dependency_activity_ids" => ["obs_waiting_on_self"]
             }
           ] = Timeline.diff_report([self_dependency_source], [self_dependency_source])["rows"]

    assert %{
             "transition_decision" => "none",
             "requires_operator_review" => false
           } =
             Timeline.transition_decision(
               missing_dependency_source,
               missing_dependency_source,
               validate_selected_dependencies?: false
             )

    assert OrbitalDynamics.timeline_transition_decision(source, replacement) ==
             Timeline.transition_decision(source, replacement)
  end

  test "resolves reusable transition applications without mutating schedules" do
    protected_source = %{
      id: :cmd_lock,
      type: :command,
      status: :planned,
      approval_status: :approved,
      locked: true,
      starts_at_s: 10.0,
      ends_at_s: 20.0,
      metadata: %{timeline_id: :"timeline:cmd_lock"}
    }

    protected_replacement = %{
      id: :cmd_lock,
      type: :command,
      status: :planned,
      approval_status: :approved,
      locked: true,
      starts_at_s: 15.0,
      ends_at_s: 25.0,
      metadata: %{timeline_id: :"timeline:cmd_lock"}
    }

    assert %{
             "transition_decision" => "preserve_source",
             "application_status" => "source_preserved_pending_review",
             "selected_activity_source" => "source",
             "requires_operator_review" => true,
             "selected_activity" => %{
               "activity_id" => "cmd_lock",
               "starts_at_s" => 10.0,
               "ends_at_s" => 20.0,
               "protection_decision" => "preserve"
             }
           } = Timeline.transition_application(protected_source, protected_replacement)

    review_source = %{
      id: :obs_1,
      type: :observe,
      target_id: :target_a,
      starts_at_s: 10.0,
      ends_at_s: 20.0,
      metadata: %{timeline_id: :"timeline:obs_1"}
    }

    review_replacement = %{
      id: :obs_1,
      type: :observe,
      target_id: :target_a,
      starts_at_s: 12.0,
      ends_at_s: 22.0,
      metadata: %{timeline_id: :"timeline:obs_1"}
    }

    assert %{
             "transition_decision" => "review",
             "application_status" => "operator_review_required",
             "requires_operator_review" => true,
             "required_operator_action" => "review_timeline_change"
           } = mutable_review = Timeline.transition_application(review_source, review_replacement)

    refute Map.has_key?(mutable_review, "selected_activity")

    assert %{
             "transition_decision" => "none",
             "application_status" => "source_unchanged",
             "selected_activity_source" => "source",
             "selected_activity" => %{"activity_id" => "obs_1"}
           } = Timeline.transition_application(review_source, review_source)

    missing_dependency_source = %{
      id: :obs_waiting_on_gate,
      type: :observe,
      target_id: :target_alpha,
      starts_at_s: 30.0,
      ends_at_s: 40.0,
      depends_on: [:missing_gate],
      metadata: %{timeline_id: :"timeline:obs_waiting_on_gate"}
    }

    assert %{
             "transition_decision" => "none",
             "application_status" => "selected_timeline_integrity_review_required",
             "requires_operator_review" => true,
             "required_operator_action" => "review_timeline_integrity",
             "selected_timeline_integrity_issue_types" => ["missing_dependency_activity"],
             "selected_missing_dependency_activity_ids" => ["missing_gate"],
             "selected_activity" => %{
               "activity_id" => "obs_waiting_on_gate",
               "timeline_integrity_status" => "review_required",
               "timeline_integrity_issue_types" => ["missing_dependency_activity"],
               "missing_dependency_activity_ids" => ["missing_gate"]
             }
           } =
             Timeline.transition_application(missing_dependency_source, missing_dependency_source)

    self_dependency_source = %{
      id: :obs_waiting_on_self,
      type: :observe,
      target_id: :target_alpha,
      starts_at_s: 45.0,
      ends_at_s: 55.0,
      depends_on: [:obs_waiting_on_self],
      metadata: %{timeline_id: :"timeline:obs_waiting_on_self"}
    }

    assert %{
             "transition_decision" => "review",
             "application_status" => "operator_review_required",
             "requires_operator_review" => true,
             "required_operator_action" => "review_timeline_integrity",
             "transition_decision_reason" =>
               "source and replacement timeline activities require integrity review"
           } = Timeline.transition_application(self_dependency_source, self_dependency_source)

    dependency_check_disabled =
      Timeline.transition_application(
        missing_dependency_source,
        missing_dependency_source,
        validate_selected_dependencies?: false
      )

    assert %{
             "transition_decision" => "none",
             "application_status" => "source_unchanged",
             "requires_operator_review" => false,
             "selected_activity" => %{
               "activity_id" => "obs_waiting_on_gate"
             }
           } = dependency_check_disabled

    refute Map.has_key?(dependency_check_disabled, "selected_timeline_integrity_issue_types")

    refute Map.has_key?(
             dependency_check_disabled["selected_activity"],
             "timeline_integrity_status"
           )

    assert %{
             "transition_decision" => "review",
             "application_status" => "operator_review_required"
           } =
             identity_review =
             Timeline.transition_application(
               %{id: :obs_1, type: :observe, metadata: %{timeline_id: :"timeline:old"}},
               %{id: :obs_1, type: :observe, metadata: %{timeline_id: :"timeline:new"}}
             )

    refute Map.has_key?(identity_review, "selected_activity")

    assert %{
             "transition_decision" => "none",
             "application_status" => "no_activity"
           } = Timeline.transition_application(nil, nil)

    assert OrbitalDynamics.timeline_transition_application(
             protected_source,
             protected_replacement
           ) ==
             Timeline.transition_application(protected_source, protected_replacement)
  end

  test "preserves helper transition provenance through transition application reports" do
    activity = %{
      id: :cmd_transition,
      type: :command,
      scenario_id: :leo_1,
      status: "In Progress",
      approval_status: :pending,
      metadata: %{
        timeline_id: :"timeline:cmd_transition",
        source_window_id: :"window:cmd_transition"
      }
    }

    assert {:ok, completed} = Timeline.transition_activity_status(activity, "succeeded")

    assert %{
             "helper" => "transition_activity_status",
             "field" => "status",
             "transition_type" => "changed",
             "from" => "executing",
             "to" => "completed",
             "requires_operator_review" => false
           } = provenance = completed["transition_application_provenance"]

    assert %{
             "transition_decision" => "record",
             "application_status" => "replacement_recorded",
             "selected_activity_source" => "replacement",
             "transition_application_provenance" => ^provenance,
             "selected_activity" => %{
               "activity_id" => "cmd_transition",
               "status" => "completed",
               "transition_application_provenance" => ^provenance,
               "activity_context" => %{
                 "transition_application_provenance" => ^provenance
               }
             }
           } = Timeline.transition_application(activity, completed)

    protected_activity = Map.put(activity, :locked, true)

    assert {:ok, protected_completed} =
             Timeline.transition_activity_status(protected_activity, "succeeded")

    assert %{
             "transition_decision" => "preserve_source",
             "application_status" => "source_preserved_pending_review",
             "selected_activity_source" => "source",
             "selected_activity" => %{
               "activity_id" => "cmd_transition",
               "status" => "executing"
             }
           } =
             protected_application =
             Timeline.transition_application(protected_activity, protected_completed)

    refute Map.has_key?(protected_application, "transition_application_provenance")

    assert %{
             "applications" => [application],
             "selected_activities" => [selected]
           } = report = Timeline.transition_application_report([activity], [completed])

    assert application["transition_application_provenance"] == provenance

    assert get_in(application, ["selected_activity", "transition_application_provenance"]) ==
             provenance

    assert selected["transition_application_provenance"] == provenance

    assert get_in(selected, ["activity_context", "transition_application_provenance"]) ==
             provenance

    assert {:ok, %{"schema_contract" => "timeline_transition_application_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "builds batch transition application plans without selecting review gated changes" do
    protected_source = %{
      id: :cmd_lock,
      type: :command,
      status: :planned,
      approval_status: :approved,
      locked: true,
      starts_at_s: 10.0,
      ends_at_s: 20.0,
      metadata: %{timeline_id: :"timeline:cmd_lock"}
    }

    protected_replacement = %{
      id: :cmd_lock,
      type: :command,
      status: :planned,
      approval_status: :approved,
      locked: true,
      starts_at_s: 15.0,
      ends_at_s: 25.0,
      metadata: %{timeline_id: :"timeline:cmd_lock"}
    }

    unchanged = %{
      id: :obs_keep,
      type: :observe,
      target_id: :target_a,
      starts_at_s: 30.0,
      ends_at_s: 40.0,
      metadata: %{timeline_id: :"timeline:obs_keep"}
    }

    removed = %{
      id: :old_contact,
      type: :planned_contact,
      ground_station_id: :dss_14,
      starts_at_s: 50.0,
      ends_at_s: 60.0,
      metadata: %{timeline_id: :"timeline:old_contact"}
    }

    added = %{
      id: :new_cmd,
      type: :command,
      starts_at_s: 70.0,
      ends_at_s: 80.0,
      metadata: %{timeline_id: :"timeline:new_cmd"}
    }

    source = [protected_source, unchanged, removed]
    replacement = [protected_replacement, unchanged, added]

    assert %{
             "source_activity_count" => 3,
             "replacement_activity_count" => 3,
             "application_count" => 4,
             "selected_activity_count" => 2,
             "review_required_count" => 3,
             "preserved_source_count" => 1,
             "withheld_review_count" => 2,
             "application_status_counts" => %{
               "operator_review_required" => 2,
               "source_preserved_pending_review" => 1,
               "source_unchanged" => 1
             },
             "transition_decision_counts" => %{
               "none" => 1,
               "preserve_source" => 1,
               "review" => 2
             },
             "required_operator_action_counts" => %{
               "none" => 1,
               "review_added_activity" => 1,
               "review_changed_protected_activity" => 1,
               "review_removed_activity" => 1
             },
             "status_transition_counts" => %{"added" => 1, "removed" => 1},
             "approval_transition_counts" => %{"added" => 1, "removed" => 1},
             "status_transition_category_counts" => %{
               "status_added" => 1,
               "status_removed" => 1
             },
             "approval_transition_category_counts" => %{
               "approval_review_required" => 1,
               "approval_removed" => 1
             },
             "selected_activities" => selected,
             "applications" => applications
           } = Timeline.transition_application_report(source, replacement)

    assert Enum.map(selected, & &1["activity_id"]) |> Enum.sort() == ["cmd_lock", "obs_keep"]

    assert %{
             "timeline_id" => "timeline:cmd_lock",
             "transition_decision" => "preserve_source",
             "application_status" => "source_preserved_pending_review",
             "selected_activity_source" => "source",
             "selected_activity" => %{"activity_id" => "cmd_lock", "starts_at_s" => 10.0},
             "source_timeline_diff" => %{"requires_operator_review" => true}
           } = Enum.find(applications, &(&1["timeline_id"] == "timeline:cmd_lock"))

    assert %{
             "timeline_id" => "timeline:new_cmd",
             "transition_decision" => "review",
             "application_status" => "operator_review_required",
             "replacement_activity_type" => "command",
             "status_transition" => %{
               "field" => "status",
               "transition_type" => "added",
               "transition_category" => "status_added"
             },
             "approval_transition" => %{
               "field" => "approval_status",
               "transition_type" => "added",
               "transition_category" => "approval_review_required"
             },
             "source_timeline_diff" => %{
               "status_transition" => %{"transition_type" => "added"},
               "approval_transition" => %{"transition_type" => "added"}
             }
           } =
             added_application =
             Enum.find(applications, &(&1["timeline_id"] == "timeline:new_cmd"))

    refute Map.has_key?(added_application, "selected_activity")

    assert {:ok, %{"schema_contract" => "timeline_transition_application_report.v1"}} =
             Schema.validate_artifact(Timeline.transition_application_report(source, replacement))

    transition_report = Timeline.transition_application_report(source, replacement)
    review = OrbitalDynamics.operator_review_package(transition_report)
    manifest = OrbitalDynamics.cadence_import_manifest(transition_report)

    assert %{
             "source_artifact_type" => "timeline_transition_application_report.v1",
             "review_count" => 3,
             "timeline_diff_count" => 3
           } = review

    assert Enum.any?(
             review["rows"],
             &(&1["source"] == "timeline_transition_application_report.applications" and
                 &1["application_status"] == "source_preserved_pending_review" and
                 get_in(&1, ["selected_activity", "activity_id"]) == "cmd_lock")
           )

    assert %{
             "status_transition" => %{"transition_type" => "added"},
             "approval_transition" => %{"transition_type" => "added"},
             "source_timeline_application" => %{
               "status_transition" => %{"transition_category" => "status_added"},
               "approval_transition" => %{"transition_category" => "approval_review_required"}
             }
           } = Enum.find(review["rows"], &(&1["timeline_id"] == "timeline:new_cmd"))

    assert %{
             "source_artifact_type" => "timeline_transition_application_report.v1",
             "row_count" => 3,
             "review_required_count" => 3
           } = manifest

    assert Enum.any?(
             manifest["rows"],
             &(&1["source_review_type"] == "timeline_diff_review" and
                 &1["import_action"] == "review_timeline_diff" and
                 &1["application_status"] == "source_preserved_pending_review")
           )

    assert %{
             "status_transition" => %{"transition_type" => "added"},
             "approval_transition" => %{"transition_type" => "added"},
             "source_timeline_application" => %{
               "status_transition" => %{"transition_category" => "status_added"},
               "approval_transition" => %{"transition_category" => "approval_review_required"}
             }
           } = Enum.find(manifest["rows"], &(&1["timeline_id"] == "timeline:new_cmd"))

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    assert OrbitalDynamics.timeline_transition_application_report(source, replacement) ==
             Timeline.transition_application_report(source, replacement)
  end

  test "builds compact transition application summaries" do
    protected_source = %{
      id: :cmd_lock,
      type: :command,
      status: :planned,
      approval_status: :approved,
      locked: true,
      starts_at_s: 10.0,
      ends_at_s: 20.0,
      metadata: %{timeline_id: :"timeline:cmd_lock"}
    }

    protected_replacement = %{
      id: :cmd_lock,
      type: :command,
      status: :planned,
      approval_status: :approved,
      locked: true,
      starts_at_s: 12.0,
      ends_at_s: 22.0,
      metadata: %{timeline_id: :"timeline:cmd_lock"}
    }

    unchanged = %{
      id: :obs_keep,
      type: :observe,
      target_id: :target_a,
      starts_at_s: 30.0,
      ends_at_s: 40.0,
      metadata: %{timeline_id: :"timeline:obs_keep"}
    }

    added = %{
      id: :new_cmd,
      type: :command,
      starts_at_s: 70.0,
      ends_at_s: 80.0,
      metadata: %{timeline_id: :"timeline:new_cmd"}
    }

    source = [protected_source, unchanged]
    replacement = [protected_replacement, unchanged, added]
    report = Timeline.transition_application_report(source, replacement)
    summary = Timeline.transition_application_summary(report)

    assert Timeline.transition_application_report(report) == report
    assert OrbitalDynamics.timeline_transition_application_report(report) == report

    atom_keyed_report =
      Map.new(report, fn {key, value} -> {String.to_atom(key), value} end)

    assert Timeline.transition_application_report(atom_keyed_report) == report
    assert OrbitalDynamics.timeline_transition_application_report(atom_keyed_report) == report

    assert %{
             "schema_contract" => "timeline_transition_application_summary.v1",
             "model" => "artifact_only_timeline_transition_application_summary",
             "validation_level" => "artifact_contract",
             "source_artifact_type" => "timeline_transition_application_report.v1",
             "source_activity_count" => 2,
             "replacement_activity_count" => 3,
             "application_count" => 3,
             "selected_activity_count" => 2,
             "review_required_count" => 2,
             "preserved_source_count" => 1,
             "withheld_review_count" => 1,
             "application_status_counts" => %{
               "operator_review_required" => 1,
               "source_preserved_pending_review" => 1,
               "source_unchanged" => 1
             },
             "transition_decision_counts" => %{
               "none" => 1,
               "preserve_source" => 1,
               "review" => 1
             },
             "selected_activity_ids" => ["cmd_lock", "obs_keep"],
             "selected_timeline_ids" => ["timeline:cmd_lock", "timeline:obs_keep"],
             "review_timeline_ids" => ["timeline:cmd_lock", "timeline:new_cmd"],
             "review_activity_ids" => ["cmd_lock", "new_cmd"],
             "review_timeline_ids_by_required_operator_action" => %{
               "review_added_activity" => ["timeline:new_cmd"],
               "review_changed_protected_activity" => ["timeline:cmd_lock"]
             },
             "review_timeline_ids_by_status_transition_category" => %{
               "status_added" => ["timeline:new_cmd"]
             },
             "review_timeline_ids_by_approval_transition_category" => %{
               "approval_review_required" => ["timeline:new_cmd"]
             },
             "preserved_source_timeline_ids" => ["timeline:cmd_lock"],
             "recorded_replacement_timeline_ids" => [],
             "withheld_review_timeline_ids" => ["timeline:new_cmd"],
             "review_applications" => review_applications,
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_schedule_mutation",
               "operator_authority" => "not_granted_by_summary"
             },
             "model_limits" => model_limits
           } = summary

    assert "artifact_level_only" in model_limits

    assert Enum.map(review_applications, & &1["timeline_id"]) |> Enum.sort() == [
             "timeline:cmd_lock",
             "timeline:new_cmd"
           ]

    assert {:ok, %{"schema_contract" => "timeline_transition_application_summary.v1"}} =
             Schema.validate_artifact(summary)

    atom_keyed_summary =
      summary
      |> Map.delete("schema_contract")
      |> Map.put(:schema_contract, "timeline_transition_application_summary.v1")

    assert Timeline.transition_application_summary(summary) == summary
    assert Timeline.transition_application_summary(atom_keyed_summary) == summary
    assert OrbitalDynamics.timeline_transition_application_summary(summary) == summary

    stale_review_count = Map.put(summary, "review_required_count", 1)

    assert {:error, stale_review_count_report} = Schema.validate_artifact(stale_review_count)

    assert Enum.any?(
             stale_review_count_report["errors"],
             &(&1["path"] == "$.review_required_count" and
                 &1["message"] ==
                   "must equal review-application-derived review_required_count")
           )

    stale_review_ids = Map.put(summary, "review_timeline_ids", ["timeline:cmd_lock"])

    assert {:error, stale_review_ids_report} = Schema.validate_artifact(stale_review_ids)

    assert Enum.any?(
             stale_review_ids_report["errors"],
             &(&1["path"] == "$.review_timeline_ids" and
                 &1["message"] == "must equal review-application-derived review_timeline_ids")
           )

    stale_review_activity_ids = Map.put(summary, "review_activity_ids", ["cmd_lock"])

    assert {:error, stale_review_activity_ids_report} =
             Schema.validate_artifact(stale_review_activity_ids)

    assert Enum.any?(
             stale_review_activity_ids_report["errors"],
             &(&1["path"] == "$.review_activity_ids" and
                 &1["message"] == "must equal review-application-derived review_activity_ids")
           )

    stale_withheld_ids = Map.put(summary, "withheld_review_timeline_ids", [])

    assert {:error, stale_withheld_ids_report} = Schema.validate_artifact(stale_withheld_ids)

    assert Enum.any?(
             stale_withheld_ids_report["errors"],
             &(&1["path"] == "$.withheld_review_timeline_ids" and
                 &1["message"] ==
                   "must equal review-application-derived withheld_review_timeline_ids")
           )

    assert Timeline.transition_application_summary(source, replacement) == summary
    assert OrbitalDynamics.timeline_transition_application_summary(report) == summary
    assert OrbitalDynamics.timeline_transition_application_summary(source, replacement) == summary

    stale_summary_count_report =
      Map.merge(report, %{
        "application_count" => 99,
        "selected_activity_count" => 99,
        "review_required_count" => 99,
        "preserved_source_count" => 99,
        "recorded_replacement_count" => 99,
        "withheld_review_count" => 99,
        "selected_timeline_integrity_review_count" => 99,
        "selected_timeline_integrity_issue_count" => 99,
        "selected_timeline_integrity_issue_types" => ["stale_issue"],
        "application_status_counts" => %{"stale_status" => 99},
        "transition_decision_counts" => %{"stale_decision" => 99},
        "required_operator_action_counts" => %{"stale_action" => 99},
        "status_transition_category_counts" => %{"stale_status_category" => 99},
        "approval_transition_category_counts" => %{"stale_approval_category" => 99}
      })

    assert %{
             "application_count" => 3,
             "selected_activity_count" => 2,
             "review_required_count" => 2,
             "preserved_source_count" => 1,
             "withheld_review_count" => 1,
             "application_status_counts" => %{
               "operator_review_required" => 1,
               "source_preserved_pending_review" => 1,
               "source_unchanged" => 1
             },
             "transition_decision_counts" => %{
               "none" => 1,
               "preserve_source" => 1,
               "review" => 1
             },
             "required_operator_action_counts" => %{
               "none" => 1,
               "review_added_activity" => 1,
               "review_changed_protected_activity" => 1
             },
             "status_transition_category_counts" => %{
               "status_added" => 1
             },
             "approval_transition_category_counts" => %{
               "approval_review_required" => 1
             }
           } = stale_summary = Timeline.transition_application_summary(stale_summary_count_report)

    assert stale_summary["recorded_replacement_count"] == 0
    assert stale_summary["selected_timeline_integrity_review_count"] == 0
    assert stale_summary["selected_timeline_integrity_issue_count"] == 0
    assert stale_summary["selected_timeline_integrity_issue_types"] == []
  end

  test "extracts transition selected activities from reports and source timelines" do
    protected_source = %{
      id: :cmd_lock,
      type: :command,
      status: :planned,
      approval_status: :approved,
      locked: true,
      starts_at_s: 10.0,
      ends_at_s: 20.0,
      metadata: %{timeline_id: :"timeline:cmd_lock"}
    }

    protected_replacement = %{
      id: :cmd_lock,
      type: :command,
      status: :planned,
      approval_status: :approved,
      locked: true,
      starts_at_s: 12.0,
      ends_at_s: 22.0,
      metadata: %{timeline_id: :"timeline:cmd_lock"}
    }

    unchanged = %{
      id: :coast_keep,
      type: :coast,
      starts_at_s: 30.0,
      ends_at_s: 40.0,
      metadata: %{timeline_id: :"timeline:coast_keep"}
    }

    review_only_added = %{
      id: :cmd_new,
      type: :command,
      starts_at_s: 50.0,
      ends_at_s: 60.0,
      metadata: %{timeline_id: :"timeline:cmd_new"}
    }

    source = [protected_source, unchanged]
    replacement = [protected_replacement, unchanged, review_only_added]
    report = Timeline.transition_application_report(source, replacement)

    assert [
             %{
               "activity_id" => "cmd_lock",
               "starts_at_s" => 10.0,
               "protection_decision" => "preserve"
             },
             %{
               "activity_id" => "coast_keep",
               "starts_at_s" => 30.0,
               "ends_at_s" => 40.0
             }
           ] = Timeline.transition_selected_activities(report)

    refute Enum.any?(
             Timeline.transition_selected_activities(report),
             &(&1["activity_id"] == "cmd_new")
           )

    assert Timeline.transition_selected_activities(source, replacement) ==
             Timeline.transition_selected_activities(report)

    assert OrbitalDynamics.timeline_transition_selected_activities(source, replacement) ==
             Timeline.transition_selected_activities(report)

    assert OrbitalDynamics.timeline_transition_selected_activities(%{
             selected_activities: report["selected_activities"]
           }) == Timeline.transition_selected_activities(report)

    assert {:ok, %{"schema_contract" => "timeline_transition_application_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "rechecks selected transition application subset for withheld dependencies" do
    dependency = %{
      id: :cmd_prereq,
      type: :command,
      status: :planned,
      approval_status: :pending,
      starts_at_s: 0.0,
      ends_at_s: 5.0,
      metadata: %{timeline_id: :"timeline:cmd_prereq"}
    }

    protected_source = %{
      id: :cmd_lock,
      type: :command,
      status: :planned,
      approval_status: :approved,
      locked: true,
      starts_at_s: 10.0,
      ends_at_s: 20.0,
      depends_on: [:cmd_prereq],
      metadata: %{timeline_id: :"timeline:cmd_lock"}
    }

    protected_replacement = %{
      id: :cmd_lock,
      type: :command,
      status: :planned,
      approval_status: :approved,
      locked: true,
      starts_at_s: 12.0,
      ends_at_s: 22.0,
      depends_on: [:cmd_prereq],
      metadata: %{timeline_id: :"timeline:cmd_lock"}
    }

    report =
      Timeline.transition_application_report([dependency, protected_source], [
        protected_replacement
      ])

    assert %{
             "selected_activity_count" => 1,
             "selected_timeline_integrity_review_count" => 1,
             "selected_timeline_integrity_issue_count" => 1,
             "selected_timeline_integrity_issue_types" => ["missing_dependency_activity"]
           } = report

    assert %{
             "activity_id" => "cmd_lock",
             "timeline_integrity_status" => "review_required",
             "timeline_integrity_issue_types" => ["missing_dependency_activity"],
             "missing_dependency_activity_ids" => ["cmd_prereq"]
           } = List.first(report["selected_activities"])

    assert %{
             "application_status" => "source_preserved_pending_review",
             "selected_activity" => %{
               "activity_id" => "cmd_lock",
               "timeline_integrity_status" => "review_required",
               "missing_dependency_activity_ids" => ["cmd_prereq"]
             }
           } = Enum.find(report["applications"], &(&1["timeline_id"] == "timeline:cmd_lock"))

    assert report["assumptions"]["selected_missing_dependency_validation"] == "enabled"

    assert {:ok, %{"schema_contract" => "timeline_transition_application_report.v1"}} =
             Schema.validate_artifact(report)

    report_without_selected_dependency_check =
      Timeline.transition_application_report(
        [dependency, protected_source],
        [protected_replacement],
        validate_selected_dependencies?: false
      )

    assert report_without_selected_dependency_check["selected_timeline_integrity_issue_count"] ==
             0

    assert report_without_selected_dependency_check["selected_timeline_integrity_issue_types"] ==
             []

    assert report_without_selected_dependency_check["assumptions"][
             "selected_missing_dependency_validation"
           ] == "disabled"

    unchanged_with_missing_dependency = %{
      id: :obs_waiting_on_gate,
      type: :observe,
      target_id: :target_alpha,
      starts_at_s: 30.0,
      ends_at_s: 40.0,
      depends_on: [:missing_gate],
      metadata: %{timeline_id: :"timeline:obs_waiting_on_gate"}
    }

    gated_report =
      Timeline.transition_application_report(
        [unchanged_with_missing_dependency],
        [unchanged_with_missing_dependency]
      )

    assert %{
             "review_required_count" => 1,
             "withheld_review_count" => 0,
             "application_status_counts" => %{
               "selected_timeline_integrity_review_required" => 1
             }
           } = gated_report

    assert %{
             "timeline_id" => "timeline:obs_waiting_on_gate",
             "diff_status" => "unchanged",
             "transition_decision" => "none",
             "application_status" => "selected_timeline_integrity_review_required",
             "requires_operator_review" => true,
             "required_operator_action" => "review_timeline_integrity",
             "selected_timeline_integrity_issue_types" => ["missing_dependency_activity"],
             "selected_missing_dependency_activity_ids" => ["missing_gate"]
           } = List.first(gated_report["applications"])

    review = OrbitalDynamics.operator_review_package(gated_report)

    assert %{
             "review_count" => 1,
             "rows" => [
               %{
                 "timeline_id" => "timeline:obs_waiting_on_gate",
                 "required_operator_action" => "review_timeline_integrity",
                 "application_status" => "selected_timeline_integrity_review_required",
                 "selected_timeline_integrity_issue_types" => ["missing_dependency_activity"],
                 "selected_missing_dependency_activity_ids" => ["missing_gate"],
                 "source_timeline_application" => %{
                   "selected_timeline_integrity_issue_types" => ["missing_dependency_activity"]
                 }
               }
             ]
           } = review

    assert {:ok, %{"schema_contract" => "timeline_transition_application_report.v1"}} =
             Schema.validate_artifact(gated_report)

    unchanged_with_self_dependency = %{
      id: :obs_waiting_on_self,
      type: :observe,
      target_id: :target_alpha,
      starts_at_s: 45.0,
      ends_at_s: 55.0,
      depends_on: [:obs_waiting_on_self],
      metadata: %{timeline_id: :"timeline:obs_waiting_on_self"}
    }

    self_dependency_report =
      Timeline.transition_application_report(
        [unchanged_with_self_dependency],
        [unchanged_with_self_dependency]
      )

    assert %{
             "application_status" => "operator_review_required",
             "transition_decision" => "review",
             "required_operator_action" => "review_timeline_integrity",
             "source_timeline_diff" => %{
               "source_timeline_integrity_issue_types" => ["self_dependency_activity"],
               "source_self_dependency_activity_ids" => ["obs_waiting_on_self"],
               "replacement_self_dependency_activity_ids" => ["obs_waiting_on_self"]
             }
           } = List.first(self_dependency_report["applications"])

    assert {:ok, %{"schema_contract" => "timeline_transition_application_report.v1"}} =
             Schema.validate_artifact(self_dependency_report)

    manifest = CadenceImport.from_timeline_transition_application_report(gated_report)

    assert %{
             "row_count" => 1,
             "rows" => [
               %{
                 "timeline_id" => "timeline:obs_waiting_on_gate",
                 "required_operator_action" => "review_timeline_integrity",
                 "application_status" => "selected_timeline_integrity_review_required",
                 "selected_timeline_integrity_issue_types" => ["missing_dependency_activity"],
                 "selected_missing_dependency_activity_ids" => ["missing_gate"],
                 "source_review_row" => %{
                   "selected_timeline_integrity_issue_types" => ["missing_dependency_activity"],
                   "selected_missing_dependency_activity_ids" => ["missing_gate"]
                 },
                 "source_timeline_application" => %{
                   "selected_timeline_integrity_issue_types" => ["missing_dependency_activity"]
                 }
               }
             ]
           } = manifest

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "classifies lock approved and executed preservation decisions" do
    locked =
      %{
        id: :cmd_locked,
        type: :command,
        approval_status: :approved,
        locked: true,
        metadata: %{timeline_id: :"timeline:cmd_locked"}
      }

    assert %{
             "activity_id" => "cmd_locked",
             "timeline_id" => "timeline:cmd_locked",
             "locked" => true,
             "approved" => true,
             "protection_decision" => "preserve",
             "protection_category" => "locked_or_approved",
             "reason" => "activity_locked_or_approved",
             "timeline_identity" => %{"timeline_id" => "timeline:cmd_locked"}
           } = Timeline.protection_decision(locked, realized_status: :planned)

    assert %{
             "locked" => true,
             "approved" => false,
             "protection_decision" => "preserve",
             "protection_category" => "locked_or_approved",
             "reason" => "activity_locked_or_approved"
           } =
             Timeline.protection_decision(%{
               id: :cmd_locked_flag,
               type: :command,
               approval_status: :pending,
               locked: 1
             })

    assert %{
             "locked" => false,
             "approved" => true,
             "protection_decision" => "preserve",
             "protection_category" => "locked_or_approved",
             "reason" => "activity_locked_or_approved"
           } =
             Timeline.protection_decision(%{
               id: :cmd_approved_flag,
               type: :command,
               approval_status: :pending,
               metadata: %{approved: 1}
             })

    assert %{
             "protection_decision" => "review_change",
             "protection_category" => "locked_or_approved",
             "reason" => "realized_status_failed_requires_repair_review"
           } = Timeline.protection_decision(locked, realized_status: :failed)

    assert %{
             "protection_decision" => "review_change",
             "protection_category" => "locked_or_approved",
             "reason" => "realized_status_failed_requires_repair_review"
           } = Timeline.protection_decision(locked, realized_status: " FAILED ")

    assert %{
             "protection_decision" => "review_change",
             "protection_category" => "locked_or_approved",
             "reason" => "realized_status_cancelled_requires_repair_review"
           } = Timeline.protection_decision(locked, realized_status: "cancelled")

    assert %{
             "status" => "provider_magic",
             "protection_decision" => "review_change",
             "protection_category" => "unsupported_status",
             "reason" => "unsupported_realized_status"
           } = Timeline.protection_decision(locked, realized_status: "provider magic")

    assert %{
             "status" => "provider_magic",
             "protection_decision" => "review_change",
             "protection_category" => "unsupported_status",
             "reason" => "unsupported_realized_status"
           } =
             Timeline.protection_decision(%{id: :open_cmd, type: :command},
               realized_status: "provider magic"
             )

    assert %{
             "protection_decision" => "review_change",
             "reason" => "locked_or_approved_changes_allowed_with_review"
           } = Timeline.protection_decision(locked, allow_locked_changes?: true)

    assert %{
             "protection_decision" => "preserve",
             "protection_category" => "executed",
             "reason" => "activity_already_completed"
           } = Timeline.protection_decision(%{id: :dl_done, type: :downlink, status: :completed})

    assert %{
             "protection_decision" => "mutable",
             "protection_category" => "none",
             "reason" => "no_timeline_protection"
           } = Timeline.protection_decision(%{id: :obs_open, type: :observe, status: :planned})

    assert OrbitalDynamics.timeline_protection_decision(locked, realized_status: :planned) ==
             Timeline.protection_decision(locked, realized_status: :planned)
  end

  test "public facade builds operational timeline reports" do
    report =
      OrbitalDynamics.operational_timeline_report([
        %{id: "health_1", type: "health_check", starts_at_s: 0.0, ends_at_s: 5.0}
      ])

    assert report["command_count"] == 1
    assert [%{"activity_type" => "health_check"}] = report["rows"]
    assert Timeline.operational_report(report) == report
    assert OrbitalDynamics.operational_timeline_report(report) == report

    atom_keyed_report =
      Map.new(report, fn {key, value} -> {String.to_atom(key), value} end)

    assert Timeline.operational_report(atom_keyed_report) == report
    assert OrbitalDynamics.operational_timeline_report(atom_keyed_report) == report
  end

  test "builds candidate rejection reports from declared and derived evidence" do
    report =
      Timeline.candidate_rejection_report(
        [
          %{
            id: :obs_clouded,
            type: :observe,
            source_window_id: :target_a_window_1,
            starts_at_s: 10.0,
            ends_at_s: 20.0,
            rejection_reasons: "No target visibility window, external planner veto",
            quality_gate_status: :failed,
            violated_constraint: :target_visibility,
            required_margin: 0.1,
            actual_margin: -0.2
          },
          %{
            id: :dl_reserved,
            type: :downlink,
            ground_station_id: :dss_14,
            station_availability: "Reservation Hold",
            capacity_pack_capacity_fraction: 0.5,
            starts_at_s: 30.0,
            ends_at_s: 35.0,
            min_duration_s: 10.0,
            payload_available: false
          },
          %{id: :cmd_ready, type: :command, reviewable: false},
          %{type: :observe}
        ],
        source: :candidate_refresh
      )

    assert %{
             "schema_contract" => "candidate_rejection_report.v1",
             "source" => "candidate_refresh",
             "candidate_count" => 4,
             "row_count" => 4,
             "rejected_count" => 3,
             "not_rejected_count" => 1,
             "invalid_candidate_input_count" => 1,
             "reviewable_count" => 3,
             "rejected_candidate_ids" => [
               "dl_reserved",
               "missing_activity_id:4",
               "obs_clouded"
             ],
             "not_rejected_candidate_ids" => ["cmd_ready"],
             "reviewable_candidate_ids" => [
               "dl_reserved",
               "missing_activity_id:4",
               "obs_clouded"
             ],
             "invalid_candidate_input_ids" => ["missing_activity_id:4"]
           } = report

    assert report["rejection_reason_counts"] == %{
             "contact_too_short" => 1,
             "declared_rejection" => 1,
             "invalid_candidate_input" => 1,
             "no_target_visibility_window" => 1,
             "payload_unavailable" => 1,
             "quality_gate_failed" => 1,
             "station_capacity_reduced" => 1,
             "station_reserved" => 1
           }

    assert report["candidate_id_sets_by_rejection_reason"] == %{
             "contact_too_short" => ["dl_reserved"],
             "declared_rejection" => ["obs_clouded"],
             "invalid_candidate_input" => ["missing_activity_id:4"],
             "no_target_visibility_window" => ["obs_clouded"],
             "payload_unavailable" => ["dl_reserved"],
             "quality_gate_failed" => ["obs_clouded"],
             "station_capacity_reduced" => ["dl_reserved"],
             "station_reserved" => ["dl_reserved"]
           }

    assert report["candidate_ids_by_required_operator_action"] == %{
             "none" => ["cmd_ready"],
             "review_candidate_rejection" => [
               "dl_reserved",
               "missing_activity_id:4",
               "obs_clouded"
             ]
           }

    assert report["required_operator_action_counts"] == %{
             "none" => 1,
             "review_candidate_rejection" => 3
           }

    obs_row = Enum.find(report["rows"], &(&1["candidate_id"] == "obs_clouded"))

    assert %{
             "rejection_status" => "rejected",
             "reviewable" => true,
             "required_operator_action" => "review_candidate_rejection",
             "violated_constraint" => "target_visibility",
             "required_margin" => 0.1,
             "actual_margin" => -0.2,
             "declared_rejection_reasons" => [
               "No target visibility window",
               "external planner veto"
             ]
           } = obs_row

    assert "declared_rejection" in obs_row["rejection_reasons"]
    assert "no_target_visibility_window" in obs_row["rejection_reasons"]
    assert "quality_gate_failed" in obs_row["rejection_reasons"]

    reserved_row = Enum.find(report["rows"], &(&1["candidate_id"] == "dl_reserved"))

    assert "station_reserved" in reserved_row["rejection_reasons"]
    assert "station_capacity_reduced" in reserved_row["rejection_reasons"]
    assert "contact_too_short" in reserved_row["rejection_reasons"]
    assert "payload_unavailable" in reserved_row["rejection_reasons"]
    assert reserved_row["activity_context"]["ground_station_id"] == "dss_14"
    assert reserved_row["activity_context"]["capacity_pack_capacity_fraction"] == 0.5

    ready_row = Enum.find(report["rows"], &(&1["candidate_id"] == "cmd_ready"))

    assert %{
             "rejection_status" => "not_rejected",
             "rejection_reasons" => [],
             "reviewable" => false,
             "required_operator_action" => "none"
           } = ready_row

    assert {:ok, %{"schema_contract" => "candidate_rejection_report.v1"}} =
             Schema.validate_artifact(report)

    assert Timeline.candidate_rejection_report(report) == report
    assert OrbitalDynamics.candidate_rejection_report(report) == report

    atom_keyed_report =
      Map.new(report, fn {key, value} -> {String.to_atom(key), value} end)

    assert Timeline.candidate_rejection_report(atom_keyed_report) == report
    assert OrbitalDynamics.candidate_rejection_report(atom_keyed_report) == report

    assert OrbitalDynamics.candidate_rejection_report([%{id: :dl_reserved, type: :downlink}])[
             "schema_contract"
           ] == "candidate_rejection_report.v1"
  end

  test "derives candidate rejections from nested station-calendar capacity evidence" do
    report =
      Timeline.candidate_rejection_report([
        %{
          id: :dl_source_capacity_pack,
          type: :downlink,
          source_station_calendar_entry: %{
            id: :station_calendar_capacity_pack,
            capacity_pack_capacity_fraction: 0.4
          }
        },
        %{
          id: :dl_overlap_capacity_pack,
          type: :downlink,
          source_station_calendar_overlaps: [
            %{
              id: :station_calendar_overlap_capacity_pack,
              capacity_pack_capacity_fraction: 0.3
            }
          ]
        },
        %{
          id: :dl_source_reduced_status,
          type: :downlink,
          source_station_calendar_entry: %{
            id: :station_calendar_reduced,
            status: :reduced_capacity
          }
        },
        %{
          id: :dl_overlap_degraded_availability,
          type: :downlink,
          source_station_calendar_overlaps: [
            %{
              id: :station_calendar_degraded,
              availability: :degraded_capacity
            }
          ]
        }
      ])

    assert %{
             "candidate_count" => 4,
             "rejected_count" => 4,
             "rejection_reason_counts" => %{"station_capacity_reduced" => 4},
             "candidate_id_sets_by_rejection_reason" => %{
               "station_capacity_reduced" => [
                 "dl_overlap_capacity_pack",
                 "dl_overlap_degraded_availability",
                 "dl_source_capacity_pack",
                 "dl_source_reduced_status"
               ]
             }
           } = report

    assert Enum.all?(report["rows"], &("station_capacity_reduced" in &1["rejection_reasons"]))

    assert {:ok, %{"schema_contract" => "candidate_rejection_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "derives candidate rejections from nested station-calendar availability evidence" do
    report =
      Timeline.candidate_rejection_report([
        %{
          id: :dl_source_unavailable,
          type: :downlink,
          source_station_calendar_entry: %{
            id: :station_calendar_outage,
            availability: :unavailable
          }
        },
        %{
          id: :dl_overlap_reserved,
          type: :downlink,
          source_station_calendar_overlaps: [
            %{
              id: :station_calendar_reserved,
              status: :reserved
            }
          ]
        }
      ])

    assert %{
             "candidate_count" => 2,
             "rejected_count" => 2,
             "rejection_reason_counts" => %{
               "station_reserved" => 1,
               "station_unavailable" => 1
             },
             "candidate_id_sets_by_rejection_reason" => %{
               "station_reserved" => ["dl_overlap_reserved"],
               "station_unavailable" => ["dl_source_unavailable"]
             }
           } = report

    unavailable_row = Enum.find(report["rows"], &(&1["candidate_id"] == "dl_source_unavailable"))
    reserved_row = Enum.find(report["rows"], &(&1["candidate_id"] == "dl_overlap_reserved"))

    assert "station_unavailable" in unavailable_row["rejection_reasons"]
    assert "station_reserved" in reserved_row["rejection_reasons"]

    assert {:ok, %{"schema_contract" => "candidate_rejection_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "builds timeline diff reports from source and replacement activities" do
    source = [
      %{
        id: :obs_1,
        type: :observe,
        scenario_id: :leo_1,
        spacecraft_id: :leo_1,
        target_id: :target_a,
        source_window_id: :target_a_window_1,
        starts_at_s: 10.0,
        ends_at_s: 20.0,
        status: :approved,
        approval_status: :approved,
        metadata: %{timeline_id: :"timeline:obs_1"}
      },
      %{
        id: :dl_removed,
        type: :downlink,
        scenario_id: :leo_1,
        spacecraft_id: :leo_1,
        ground_station_id: :dss_14,
        source_window_id: :dss_14_pass_removed,
        starts_at_s: 30.0,
        ends_at_s: 40.0,
        metadata: %{timeline_id: :"timeline:dl_removed"}
      }
    ]

    replacement = [
      %{
        id: :obs_1b,
        type: :observe,
        scenario_id: :leo_1,
        spacecraft_id: :leo_1,
        target_id: :target_a,
        source_window_id: :target_a_window_1,
        starts_at_s: 12.0,
        ends_at_s: 22.0,
        status: :planned,
        approval_status: :pending,
        metadata: %{timeline_id: :"timeline:obs_1"}
      },
      %{
        id: :cmd_added,
        type: :command,
        scenario_id: :leo_1,
        spacecraft_id: :leo_1,
        ground_station_id: :dss_14,
        source_window_id: :dss_14_pass_added,
        starts_at_s: 50.0,
        ends_at_s: 55.0,
        metadata: %{timeline_id: :"timeline:cmd_added"}
      }
    ]

    report = Timeline.diff_report(source, replacement, source: "repair.activities")

    assert report["schema_contract"] == "timeline_diff_report.v1"
    assert report["source"] == "repair.activities"
    assert report["source_activity_count"] == 2
    assert report["replacement_activity_count"] == 2
    assert report["added_count"] == 1
    assert report["removed_count"] == 1
    assert report["changed_count"] == 1
    assert report["unchanged_count"] == 0
    assert report["review_required_count"] == 3
    assert report["diff_status_counts"] == %{"added" => 1, "changed" => 1, "removed" => 1}
    assert report["transition_decision_counts"] == %{"preserve_source" => 1, "review" => 2}

    assert report["required_operator_action_counts"] == %{
             "review_added_activity" => 1,
             "review_changed_protected_activity" => 1,
             "review_removed_activity" => 1
           }

    assert report["changed_field_counts"] == %{
             "activity_id" => 1,
             "approval_status" => 1,
             "ends_at_s" => 1,
             "starts_at_s" => 1,
             "status" => 1,
             "timeline_presence" => 2
           }

    assert report["status_transition_counts"] == %{"added" => 1, "changed" => 1, "removed" => 1}
    assert report["approval_transition_counts"] == %{"added" => 1, "changed" => 1, "removed" => 1}

    assert report["status_transition_category_counts"] == %{
             "status_added" => 1,
             "status_changed" => 1,
             "status_removed" => 1
           }

    assert report["approval_transition_category_counts"] == %{
             "approval_regressed" => 1,
             "approval_removed" => 1,
             "approval_review_required" => 1
           }

    assert "derived_identity_when_no_persistent_timeline_id" in report["model_limits"]

    assert %{
             "timeline_id" => "timeline:obs_1",
             "diff_status" => "changed",
             "source_activity_id" => "obs_1",
             "replacement_activity_id" => "obs_1b",
             "source_spacecraft_id" => "leo_1",
             "replacement_spacecraft_id" => "leo_1",
             "source_target_id" => "target_a",
             "replacement_target_id" => "target_a",
             "source_source_window_id" => "target_a_window_1",
             "replacement_source_window_id" => "target_a_window_1",
             "start_delta_s" => 2.0,
             "end_delta_s" => 2.0,
             "changed_fields" => changed_fields,
             "status_transition" => %{
               "field" => "status",
               "transition_type" => "changed",
               "from" => "approved",
               "to" => "planned"
             },
             "approval_transition" => %{
               "field" => "approval_status",
               "transition_type" => "changed",
               "from" => "approved",
               "to" => "pending"
             },
             "source_activity_context" => %{
               "timeline_identity" => %{
                 "activity_type" => "observe",
                 "timeline_id" => "timeline:obs_1"
               }
             },
             "replacement_activity_context" => %{
               "timeline_identity" => %{
                 "activity_type" => "observe",
                 "timeline_id" => "timeline:obs_1"
               }
             },
             "source_protection_decision" => %{
               "protection_decision" => "preserve",
               "protection_category" => "locked_or_approved",
               "reason" => "activity_locked_or_approved"
             },
             "source_protection_category" => "locked_or_approved",
             "source_protection_reason" => "activity_locked_or_approved",
             "transition_decision" => "preserve_source",
             "transition_decision_reason" => "activity_locked_or_approved",
             "replacement_protection_decision" => %{
               "protection_decision" => "mutable",
               "protection_category" => "none",
               "reason" => "no_timeline_protection"
             },
             "replacement_protection_category" => "none",
             "replacement_protection_reason" => "no_timeline_protection",
             "required_operator_action" => "review_changed_protected_activity",
             "reason" =>
               "replacement timeline changes approved activity obs_1: activity_id,status,approval_status,starts_at_s,ends_at_s"
           } = Enum.find(report["rows"], &(&1["timeline_id"] == "timeline:obs_1"))

    assert "starts_at_s" in changed_fields
    assert "approval_status" in changed_fields

    assert %{
             "diff_status" => "added",
             "replacement_activity_id" => "cmd_added",
             "replacement_spacecraft_id" => "leo_1",
             "replacement_ground_station_id" => "dss_14",
             "replacement_source_window_id" => "dss_14_pass_added",
             "status_transition" => %{
               "field" => "status",
               "transition_type" => "added",
               "to" => "planned"
             },
             "approval_transition" => %{
               "field" => "approval_status",
               "transition_type" => "added",
               "to" => "not_evaluated"
             },
             "replacement_activity_context" => %{
               "timeline_identity" => %{
                 "activity_type" => "command",
                 "timeline_id" => "timeline:cmd_added"
               }
             },
             "replacement_protection_decision" => %{
               "protection_decision" => "mutable",
               "protection_category" => "none"
             },
             "transition_decision" => "review",
             "transition_decision_reason" => "replacement timeline adds activity cmd_added",
             "required_operator_action" => "review_added_activity"
           } = Enum.find(report["rows"], &(&1["timeline_id"] == "timeline:cmd_added"))

    assert %{
             "diff_status" => "removed",
             "source_activity_id" => "dl_removed",
             "source_spacecraft_id" => "leo_1",
             "source_ground_station_id" => "dss_14",
             "source_source_window_id" => "dss_14_pass_removed",
             "status_transition" => %{
               "field" => "status",
               "transition_type" => "removed",
               "from" => "planned"
             },
             "approval_transition" => %{
               "field" => "approval_status",
               "transition_type" => "removed",
               "from" => "not_evaluated"
             },
             "source_activity_context" => %{
               "timeline_identity" => %{
                 "activity_type" => "downlink",
                 "timeline_id" => "timeline:dl_removed"
               }
             },
             "source_protection_decision" => %{
               "protection_decision" => "mutable",
               "protection_category" => "none"
             },
             "transition_decision" => "review",
             "transition_decision_reason" => "replacement timeline removes activity dl_removed",
             "required_operator_action" => "review_removed_activity"
           } = Enum.find(report["rows"], &(&1["timeline_id"] == "timeline:dl_removed"))

    assert {:ok, %{"schema_contract" => "timeline_diff_report.v1"}} =
             Schema.validate_artifact(report)

    stale_model_limits = Map.put(report, "model_limits", ["timeline_model_is_read_only"])

    assert {:error, stale_model_limits_report} = Schema.validate_artifact(stale_model_limits)

    assert Enum.any?(
             stale_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] == "must match timeline report model limits")
           )

    assert Timeline.diff_report(report) == report
    assert OrbitalDynamics.timeline_diff_report(report) == report

    atom_keyed_report =
      Map.new(report, fn {key, value} -> {String.to_atom(key), value} end)

    assert Timeline.diff_report(atom_keyed_report) == report
    assert OrbitalDynamics.timeline_diff_report(atom_keyed_report) == report

    review = OperatorReview.from_timeline_diff_report(report)
    import = CadenceImport.from_timeline_diff_report(report)

    assert %{
             "review_type" => "timeline_diff_review",
             "transition_decision" => "preserve_source",
             "transition_decision_reason" => "activity_locked_or_approved"
           } = Enum.find(review["rows"], &(&1["timeline_id"] == "timeline:obs_1"))

    assert %{
             "import_action" => "review_timeline_diff",
             "transition_decision" => "preserve_source",
             "transition_decision_reason" => "activity_locked_or_approved"
           } = Enum.find(import["rows"], &(&1["timeline_id"] == "timeline:obs_1"))

    summary = Timeline.diff_summary(report)

    assert %{
             "schema_contract" => "timeline_diff_summary.v1",
             "model" => "artifact_only_timeline_diff_summary",
             "validation_level" => "artifact_contract",
             "source_artifact_type" => "timeline_diff_report.v1",
             "source" => "repair.activities",
             "source_activity_count" => 2,
             "replacement_activity_count" => 2,
             "row_count" => 3,
             "added_count" => 1,
             "removed_count" => 1,
             "changed_count" => 1,
             "review_required_count" => 3,
             "diff_status_counts" => %{"added" => 1, "changed" => 1, "removed" => 1},
             "transition_decision_counts" => %{"preserve_source" => 1, "review" => 2},
             "changed_field_counts" => %{
               "activity_id" => 1,
               "approval_status" => 1,
               "ends_at_s" => 1,
               "starts_at_s" => 1,
               "status" => 1,
               "timeline_presence" => 2
             },
             "added_timeline_ids" => ["timeline:cmd_added"],
             "removed_timeline_ids" => ["timeline:dl_removed"],
             "changed_timeline_ids" => ["timeline:obs_1"],
             "unchanged_timeline_ids" => [],
             "duplicate_timeline_identity_ids" => [],
             "invalid_source_activity_input_ids" => [],
             "invalid_replacement_activity_input_ids" => [],
             "review_timeline_ids" => [
               "timeline:cmd_added",
               "timeline:dl_removed",
               "timeline:obs_1"
             ],
             "review_timeline_ids_by_required_operator_action" => %{
               "review_added_activity" => ["timeline:cmd_added"],
               "review_changed_protected_activity" => ["timeline:obs_1"],
               "review_removed_activity" => ["timeline:dl_removed"]
             },
             "review_timeline_ids_by_status_transition_category" => %{
               "status_added" => ["timeline:cmd_added"],
               "status_changed" => ["timeline:obs_1"],
               "status_removed" => ["timeline:dl_removed"]
             },
             "review_timeline_ids_by_approval_transition_category" => %{
               "approval_regressed" => ["timeline:obs_1"],
               "approval_removed" => ["timeline:dl_removed"],
               "approval_review_required" => ["timeline:cmd_added"]
             },
             "timeline_ids_by_changed_field" => %{
               "activity_id" => ["timeline:obs_1"],
               "approval_status" => ["timeline:obs_1"],
               "ends_at_s" => ["timeline:obs_1"],
               "starts_at_s" => ["timeline:obs_1"],
               "status" => ["timeline:obs_1"],
               "timeline_presence" => ["timeline:cmd_added", "timeline:dl_removed"]
             },
             "review_rows" => review_rows,
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_schedule_mutation",
               "operator_authority" => "not_granted_by_summary"
             },
             "model_limits" => model_limits
           } = summary

    assert length(review_rows) == 3
    assert "artifact_level_only" in model_limits

    assert {:ok, %{"schema_contract" => "timeline_diff_summary.v1"}} =
             Schema.validate_artifact(summary)

    atom_keyed_summary =
      summary
      |> Map.delete("schema_contract")
      |> Map.put(:schema_contract, "timeline_diff_summary.v1")

    assert Timeline.diff_summary(summary) == summary
    assert Timeline.diff_summary(atom_keyed_summary) == summary
    assert OrbitalDynamics.timeline_diff_summary(summary) == summary

    stale_review_count = Map.put(summary, "review_required_count", 2)

    assert {:error, stale_review_count_report} = Schema.validate_artifact(stale_review_count)

    assert Enum.any?(
             stale_review_count_report["errors"],
             &(&1["path"] == "$.review_required_count" and
                 &1["message"] == "must equal row-derived review_required_count")
           )

    stale_review_ids = Map.put(summary, "review_timeline_ids", ["timeline:obs_1"])

    assert {:error, stale_review_ids_report} = Schema.validate_artifact(stale_review_ids)

    assert Enum.any?(
             stale_review_ids_report["errors"],
             &(&1["path"] == "$.review_timeline_ids" and
                 &1["message"] == "must equal row-derived review_timeline_ids")
           )

    assert Timeline.diff_summary(source, replacement, source: "repair.activities") ==
             summary

    assert OrbitalDynamics.timeline_diff_summary(report) == summary

    assert OrbitalDynamics.timeline_diff_summary(source, replacement, source: "repair.activities") ==
             summary
  end

  test "preserves duplicate timeline identity collisions in diff review rows" do
    source = [
      %{
        id: :cmd_source_a,
        type: :command,
        scenario_id: :leo_1,
        starts_at_s: 10.0,
        ends_at_s: 20.0,
        ground_station_id: :dss_14,
        metadata: %{timeline_id: :"timeline:cmd_duplicate"}
      },
      %{
        id: :cmd_source_b,
        type: :command,
        scenario_id: :leo_1,
        starts_at_s: 25.0,
        ends_at_s: 35.0,
        ground_station_id: :dss_14,
        dependencies: [:obs_1],
        metadata: %{timeline_id: :"timeline:cmd_duplicate"}
      }
    ]

    replacement = [
      %{
        id: :cmd_replacement,
        type: :command,
        scenario_id: :leo_1,
        starts_at_s: 12.0,
        ends_at_s: 22.0,
        ground_station_id: :dss_14,
        metadata: %{timeline_id: :"timeline:cmd_duplicate"}
      }
    ]

    report = Timeline.diff_report(source, replacement)

    assert %{
             "row_count" => 1,
             "changed_count" => 1,
             "duplicate_timeline_identity_count" => 1,
             "duplicate_source_timeline_identity_count" => 1,
             "duplicate_replacement_timeline_identity_count" => 0,
             "review_required_count" => 1,
             "rows" => [
               %{
                 "timeline_id" => "timeline:cmd_duplicate",
                 "diff_status" => "changed",
                 "changed_fields" => ["timeline_identity_collision"],
                 "timeline_identity_collision" => true,
                 "duplicate_timeline_identity_scope" => "source",
                 "source_duplicate_activity_count" => 2,
                 "replacement_duplicate_activity_count" => 1,
                 "source_duplicate_activity_ids" => ["cmd_source_a", "cmd_source_b"],
                 "replacement_duplicate_activity_ids" => ["cmd_replacement"],
                 "source_duplicate_activities" => source_duplicates,
                 "replacement_duplicate_activities" => replacement_duplicates,
                 "required_operator_action" => "review_duplicate_timeline_identity",
                 "requires_operator_review" => true,
                 "reason" => reason
               }
             ]
           } = report

    assert Enum.map(source_duplicates, & &1["activity_id"]) == ["cmd_source_a", "cmd_source_b"]
    assert Enum.map(replacement_duplicates, & &1["activity_id"]) == ["cmd_replacement"]
    assert reason =~ "matches 2 source and 1 replacement activities"

    assert {:ok, %{"schema_contract" => "timeline_diff_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_timeline_diff_report(report)

    assert %{
             "review_type" => "timeline_diff_review",
             "required_operator_action" => "review_duplicate_timeline_identity",
             "timeline_identity_collision" => true,
             "source_duplicate_activity_ids" => ["cmd_source_a", "cmd_source_b"],
             "source_timeline_diff" => %{
               "timeline_identity_collision" => true,
               "source_duplicate_activity_count" => 2
             }
           } = List.first(review["rows"])

    import = CadenceImport.from_timeline_diff_report(report)

    assert %{
             "import_action" => "review_timeline_diff",
             "source_review_action" => "review_duplicate_timeline_identity",
             "timeline_identity_collision" => true,
             "source_duplicate_activity_ids" => ["cmd_source_a", "cmd_source_b"],
             "source_timeline_diff" => %{"timeline_identity_collision" => true}
           } = List.first(import["rows"])

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)

    application_report = Timeline.transition_application_report(source, replacement)

    assert %{
             "review_required_count" => 1,
             "applications" => [
               %{
                 "timeline_id" => "timeline:cmd_duplicate",
                 "application_status" => "operator_review_required",
                 "required_operator_action" => "review_duplicate_timeline_identity",
                 "timeline_identity_collision" => true,
                 "duplicate_timeline_identity_scope" => "source",
                 "source_duplicate_activity_count" => 2,
                 "replacement_duplicate_activity_count" => 1,
                 "source_duplicate_activity_ids" => ["cmd_source_a", "cmd_source_b"],
                 "replacement_duplicate_activity_ids" => ["cmd_replacement"],
                 "source_duplicate_activities" => application_source_duplicates,
                 "replacement_duplicate_activities" => application_replacement_duplicates,
                 "source_timeline_diff" => %{
                   "timeline_identity_collision" => true,
                   "source_duplicate_activity_count" => 2
                 }
               }
             ]
           } = application_report

    assert Enum.map(application_source_duplicates, & &1["activity_id"]) == [
             "cmd_source_a",
             "cmd_source_b"
           ]

    assert Enum.map(application_replacement_duplicates, & &1["activity_id"]) == [
             "cmd_replacement"
           ]

    application_review =
      OperatorReview.from_timeline_transition_application_report(application_report)

    application_import =
      CadenceImport.from_timeline_transition_application_report(application_report)

    assert %{
             "required_operator_action" => "review_duplicate_timeline_identity",
             "timeline_identity_collision" => true,
             "source_duplicate_activity_ids" => ["cmd_source_a", "cmd_source_b"],
             "source_timeline_application" => %{
               "timeline_identity_collision" => true,
               "source_duplicate_activity_ids" => ["cmd_source_a", "cmd_source_b"]
             }
           } = List.first(application_review["rows"])

    assert %{
             "source_review_action" => "review_duplicate_timeline_identity",
             "timeline_identity_collision" => true,
             "source_duplicate_activity_ids" => ["cmd_source_a", "cmd_source_b"],
             "source_timeline_application" => %{
               "timeline_identity_collision" => true,
               "source_duplicate_activity_ids" => ["cmd_source_a", "cmd_source_b"]
             }
           } = List.first(application_import["rows"])

    assert {:ok, %{"schema_contract" => "timeline_transition_application_report.v1"}} =
             Schema.validate_artifact(application_report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(application_review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(application_import)
  end

  test "routes source and replacement dependency cycles through timeline diff review" do
    source = [
      %{
        id: :cmd_prepare,
        type: :command,
        scenario_id: :leo_1,
        dependencies: [:cmd_execute],
        metadata: %{timeline_id: :"timeline:cmd_prepare"}
      },
      %{
        id: :cmd_execute,
        type: :command,
        scenario_id: :leo_1,
        dependencies: [:cmd_prepare],
        metadata: %{timeline_id: :"timeline:cmd_execute"}
      }
    ]

    report = Timeline.diff_report(source, source, validate_missing_dependencies?: true)

    assert %{
             "row_count" => 2,
             "changed_count" => 0,
             "unchanged_count" => 2,
             "review_required_count" => 2,
             "required_operator_action_counts" => %{"review_timeline_integrity" => 2},
             "transition_decision_counts" => %{"review" => 2}
           } = report

    assert %{
             "diff_status" => "unchanged",
             "requires_operator_review" => true,
             "required_operator_action" => "review_timeline_integrity",
             "reason" => "source and replacement timeline activities require integrity review",
             "transition_decision" => "review",
             "transition_decision_reason" =>
               "source and replacement timeline activities require integrity review",
             "source_timeline_integrity_status" => "review_required",
             "source_dependency_cycle_activity_ids" => ["cmd_execute"],
             "replacement_timeline_integrity_status" => "review_required",
             "replacement_dependency_cycle_activity_ids" => ["cmd_execute"]
           } = Enum.find(report["rows"], &(&1["timeline_id"] == "timeline:cmd_prepare"))

    assert {:ok, %{"schema_contract" => "timeline_diff_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_timeline_diff_report(report)
    import = CadenceImport.from_timeline_diff_report(report)

    assert %{
             "review_type" => "timeline_diff_review",
             "required_operator_action" => "review_timeline_integrity",
             "source_dependency_cycle_activity_ids" => ["cmd_execute"],
             "replacement_dependency_cycle_activity_ids" => ["cmd_execute"]
           } = Enum.find(review["rows"], &(&1["timeline_id"] == "timeline:cmd_prepare"))

    assert %{
             "import_action" => "review_timeline_diff",
             "source_review_action" => "review_timeline_integrity",
             "source_dependency_cycle_activity_ids" => ["cmd_execute"],
             "replacement_dependency_cycle_activity_ids" => ["cmd_execute"]
           } = Enum.find(import["rows"], &(&1["timeline_id"] == "timeline:cmd_prepare"))

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "public facade builds timeline diff reports" do
    report =
      OrbitalDynamics.timeline_diff_report(
        [%{id: "health_1", type: "health_check", starts_at_s: 0.0, ends_at_s: 5.0}],
        [%{id: "health_1", type: "health_check", starts_at_s: 0.0, ends_at_s: 5.0}]
      )

    assert report["unchanged_count"] == 1

    assert [%{"diff_status" => "unchanged", "required_operator_action" => "none"}] =
             report["rows"]
  end

  test "timeline diff treats dependency and exclusivity changes as reviewable" do
    source = [
      %{
        id: :cmd_2,
        type: :command,
        starts_at_s: 20.0,
        ends_at_s: 30.0,
        dependencies: [:obs_1],
        allow_overlap?: false,
        metadata: %{timeline_id: :"timeline:cmd_2"}
      }
    ]

    replacement = [
      %{
        id: :cmd_2,
        type: :command,
        starts_at_s: 20.0,
        ends_at_s: 30.0,
        dependencies: [:obs_1, :health_check_1],
        exclusive_with: [:dl_conflict],
        allow_overlap?: true,
        metadata: %{timeline_id: :"timeline:cmd_2"}
      }
    ]

    report = Timeline.diff_report(source, replacement)

    assert %{
             "diff_status" => "changed",
             "changed_fields" => changed_fields,
             "requires_operator_review" => true,
             "source_dependency_activity_ids" => ["obs_1"],
             "replacement_dependency_activity_ids" => ["health_check_1", "obs_1"],
             "replacement_exclusive_with_activity_ids" => ["dl_conflict"],
             "source_allow_overlap" => false,
             "replacement_allow_overlap" => true,
             "required_operator_action" => "review_timeline_change"
           } = hd(report["rows"])

    assert "dependency_activity_ids" in changed_fields
    assert "exclusive_with_activity_ids" in changed_fields
    assert "allow_overlap" in changed_fields

    assert {:ok, %{"schema_contract" => "timeline_diff_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "timeline diff treats station reservation ownership changes as reviewable" do
    source = [
      %{
        id: :dl_reserved,
        type: :downlink,
        starts_at_s: 20.0,
        ends_at_s: 30.0,
        ground_station_id: :equator_prime,
        station_contention_status: :reserved_overlap,
        station_reservation_id: :reservation_1,
        station_reservation_match_status: :overlap,
        metadata: %{timeline_id: :"timeline:dl_reserved"}
      }
    ]

    replacement = [
      %{
        id: :dl_reserved,
        type: :downlink,
        starts_at_s: 20.0,
        ends_at_s: 30.0,
        ground_station_id: :equator_prime,
        station_contention_status: :reserved_overlap,
        station_reservation_id: :reservation_2,
        station_reservation_match_status: :matched,
        metadata: %{timeline_id: :"timeline:dl_reserved"}
      }
    ]

    report = Timeline.diff_report(source, replacement)

    assert %{
             "diff_status" => "changed",
             "changed_fields" => changed_fields,
             "requires_operator_review" => true,
             "required_operator_action" => "review_timeline_change",
             "source_activity_context" => %{
               "station_reservation_id" => "reservation_1",
               "station_reservation_match_status" => "overlap"
             },
             "replacement_activity_context" => %{
               "station_reservation_id" => "reservation_2",
               "station_reservation_match_status" => "matched"
             }
           } = hd(report["rows"])

    assert "station_reservation_id" in changed_fields
    assert "station_reservation_match_status" in changed_fields

    assert {:ok, %{"schema_contract" => "timeline_diff_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "timeline diff gives changed protected and executed activities specific review actions" do
    source = [
      %{
        id: :executed_downlink,
        type: :downlink,
        scenario_id: :leo_1,
        starts_at_s: 10.0,
        ends_at_s: 20.0,
        status: :completed,
        metadata: %{timeline_id: :"timeline:executed_downlink"}
      },
      %{
        id: :locked_command,
        type: :command,
        scenario_id: :leo_1,
        starts_at_s: 30.0,
        ends_at_s: 40.0,
        direction: :uplink,
        locked: true,
        metadata: %{timeline_id: :"timeline:locked_command"}
      },
      %{
        id: :approved_downlink,
        type: :downlink,
        scenario_id: :leo_1,
        starts_at_s: 50.0,
        ends_at_s: 60.0,
        direction: :downlink,
        approval_status: :auto_approvable,
        metadata: %{timeline_id: :"timeline:approved_downlink"}
      }
    ]

    replacement = [
      %{
        id: :executed_downlink,
        type: :downlink,
        scenario_id: :leo_1,
        starts_at_s: 12.0,
        ends_at_s: 20.0,
        status: :completed,
        metadata: %{timeline_id: :"timeline:executed_downlink"}
      },
      %{
        id: :locked_command,
        type: :command,
        scenario_id: :leo_1,
        starts_at_s: 30.0,
        ends_at_s: 40.0,
        direction: :downlink,
        locked: true,
        metadata: %{timeline_id: :"timeline:locked_command"}
      },
      %{
        id: :approved_downlink,
        type: :downlink,
        scenario_id: :leo_1,
        starts_at_s: 50.0,
        ends_at_s: 60.0,
        direction: :uplink,
        approval_status: :auto_approvable,
        metadata: %{timeline_id: :"timeline:approved_downlink"}
      }
    ]

    report = Timeline.diff_report(source, replacement)

    assert report["review_required_count"] == 3

    assert %{
             "diff_status" => "changed",
             "source_activity_id" => "executed_downlink",
             "required_operator_action" => "review_changed_executed_activity",
             "reason" =>
               "replacement timeline changes executed activity executed_downlink: starts_at_s"
           } = Enum.find(report["rows"], &(&1["timeline_id"] == "timeline:executed_downlink"))

    assert %{
             "diff_status" => "changed",
             "source_activity_id" => "locked_command",
             "changed_fields" => ["direction"],
             "required_operator_action" => "review_changed_protected_activity",
             "reason" => "replacement timeline changes locked activity locked_command: direction"
           } = Enum.find(report["rows"], &(&1["timeline_id"] == "timeline:locked_command"))

    assert %{
             "diff_status" => "changed",
             "source_activity_id" => "approved_downlink",
             "source_approval_status" => "auto_approvable",
             "changed_fields" => ["direction"],
             "required_operator_action" => "review_changed_protected_activity",
             "reason" =>
               "replacement timeline changes approved activity approved_downlink: direction"
           } = Enum.find(report["rows"], &(&1["timeline_id"] == "timeline:approved_downlink"))

    review = OperatorReview.from_timeline_diff_report(report)
    import = CadenceImport.from_timeline_diff_report(report)

    assert Enum.any?(
             review["rows"],
             &(&1["activity_id"] == "executed_downlink" and
                 &1["required_operator_action"] == "review_changed_executed_activity")
           )

    assert Enum.any?(
             import["rows"],
             &(&1["activity_id"] == "approved_downlink" and
                 &1["source_review_action"] == "review_changed_protected_activity" and
                 get_in(&1, ["source_activity_context", "timeline_identity", "timeline_id"]) ==
                   "timeline:approved_downlink" and
                 get_in(&1, ["replacement_activity_context", "timeline_identity", "timeline_id"]) ==
                   "timeline:approved_downlink")
           )

    assert {:ok, %{"schema_contract" => "timeline_diff_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "timeline diff requires review for unprotected command contact direction changes" do
    source = [
      %{
        id: :contact_window,
        type: :planned_contact,
        scenario_id: :leo_1,
        starts_at_s: 30.0,
        ends_at_s: 40.0,
        ground_station_id: :dss_14,
        direction: :downlink,
        metadata: %{timeline_id: :"timeline:contact_window"}
      }
    ]

    replacement = [
      %{
        id: :contact_window,
        type: :planned_contact,
        scenario_id: :leo_1,
        starts_at_s: 30.0,
        ends_at_s: 40.0,
        ground_station_id: :dss_14,
        direction: :uplink,
        metadata: %{timeline_id: :"timeline:contact_window"}
      }
    ]

    report = Timeline.diff_report(source, replacement)

    assert %{
             "changed_count" => 1,
             "review_required_count" => 1,
             "rows" => [
               %{
                 "diff_status" => "changed",
                 "changed_fields" => ["direction"],
                 "requires_operator_review" => true,
                 "required_operator_action" => "review_timeline_change",
                 "reason" =>
                   "timeline activity contact_window changes to contact_window: direction",
                 "source_activity_context" => %{"direction" => "downlink"},
                 "replacement_activity_context" => %{"direction" => "uplink"}
               }
             ]
           } = report

    assert {:ok, %{"schema_contract" => "timeline_diff_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "timeline diff requires review for observation lighting evidence changes" do
    source = [
      %{
        id: :obs_window,
        type: :observe,
        scenario_id: :leo_1,
        starts_at_s: 30.0,
        ends_at_s: 40.0,
        target_id: :target_a,
        lighting_condition: :sunlit,
        eclipse_overlap_fraction: 0.0,
        metadata: %{timeline_id: :"timeline:obs_window"}
      }
    ]

    replacement = [
      %{
        id: :obs_window,
        type: :observe,
        scenario_id: :leo_1,
        starts_at_s: 30.0,
        ends_at_s: 40.0,
        target_id: :target_a,
        lighting_condition: :partial_eclipse,
        eclipse_overlap_fraction: 0.25,
        metadata: %{timeline_id: :"timeline:obs_window"}
      }
    ]

    report = Timeline.diff_report(source, replacement)

    assert %{
             "changed_count" => 1,
             "review_required_count" => 1,
             "rows" => [
               %{
                 "diff_status" => "changed",
                 "changed_fields" => ["eclipse_overlap_fraction", "lighting_condition"],
                 "source_activity_context" => source_activity_context,
                 "replacement_activity_context" => %{
                   "lighting_condition" => "partial_eclipse",
                   "eclipse_overlap_fraction" => 0.25
                 }
               }
             ]
           } = report

    assert source_activity_context["lighting_condition"] == "sunlit"
    assert source_activity_context["eclipse_overlap_fraction"] == 0.0

    assert {:ok, %{"schema_contract" => "timeline_diff_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "timeline diff requires review for source-window type changes" do
    source = [
      %{
        id: :obs_window,
        type: :observe,
        scenario_id: :leo_1,
        starts_at_s: 30.0,
        ends_at_s: 40.0,
        target_id: :target_a,
        source_window_id: :shared_window,
        source_window_type: :target_visibility,
        metadata: %{timeline_id: :"timeline:obs_window"}
      }
    ]

    replacement = [
      %{
        id: :obs_window,
        type: :observe,
        scenario_id: :leo_1,
        starts_at_s: 30.0,
        ends_at_s: 40.0,
        target_id: :target_a,
        source_window_id: :shared_window,
        source_window_type: :eclipse,
        metadata: %{timeline_id: :"timeline:obs_window"}
      }
    ]

    report = Timeline.diff_report(source, replacement)

    assert %{
             "changed_count" => 1,
             "rows" => [
               %{
                 "changed_fields" => ["source_window_type"],
                 "source_activity_context" => %{"source_window_type" => "target_visibility"},
                 "replacement_activity_context" => %{"source_window_type" => "eclipse"}
               }
             ]
           } = report

    assert {:ok, %{"schema_contract" => "timeline_diff_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "timeline diff requires review for command-window provenance changes" do
    source = [
      %{
        id: :cmd_window,
        type: :command,
        scenario_id: :leo_1,
        starts_at_s: 30.0,
        ends_at_s: 40.0,
        command_window_id: :"command_window:cmd_window:primary",
        command_window_type: :command_window,
        metadata: %{timeline_id: :"timeline:cmd_window"}
      }
    ]

    replacement = [
      %{
        id: :cmd_window,
        type: :command,
        scenario_id: :leo_1,
        starts_at_s: 30.0,
        ends_at_s: 40.0,
        command_window_id: :"command_window:cmd_window:backup",
        command_window_type: :uplink_window,
        metadata: %{timeline_id: :"timeline:cmd_window"}
      }
    ]

    report = Timeline.diff_report(source, replacement)

    assert %{
             "changed_count" => 1,
             "review_required_count" => 1,
             "rows" => [
               %{
                 "changed_fields" => ["command_window_id", "command_window_type"],
                 "source_activity_context" => %{
                   "command_window_id" => "command_window:cmd_window:primary",
                   "command_window_type" => "command_window"
                 },
                 "replacement_activity_context" => %{
                   "command_window_id" => "command_window:cmd_window:backup",
                   "command_window_type" => "uplink_window"
                 }
               }
             ]
           } = report

    assert {:ok, %{"schema_contract" => "timeline_diff_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "timeline diff requires review for nested source-window evidence changes" do
    source = [
      %{
        id: :obs_window,
        type: :observe,
        scenario_id: :leo_1,
        starts_at_s: 30.0,
        ends_at_s: 40.0,
        target_id: :target_a,
        source_window: %{
          id: :shared_window,
          type: :target_visibility,
          start_boundary_detail: %{interpolation_fraction: 0.25}
        },
        metadata: %{timeline_id: :"timeline:obs_window"}
      }
    ]

    replacement = [
      %{
        id: :obs_window,
        type: :observe,
        scenario_id: :leo_1,
        starts_at_s: 30.0,
        ends_at_s: 40.0,
        target_id: :target_a,
        source_window: %{
          id: :shared_window,
          type: :target_visibility,
          start_boundary_detail: %{interpolation_fraction: 0.75}
        },
        metadata: %{timeline_id: :"timeline:obs_window"}
      }
    ]

    report = Timeline.diff_report(source, replacement)

    assert %{
             "changed_count" => 1,
             "rows" => [
               %{
                 "changed_fields" => ["source_window"],
                 "source_activity_context" => %{
                   "source_window" => %{
                     "start_boundary_detail" => %{"interpolation_fraction" => 0.25}
                   }
                 },
                 "replacement_activity_context" => %{
                   "source_window" => %{
                     "start_boundary_detail" => %{"interpolation_fraction" => 0.75}
                   }
                 }
               }
             ]
           } = report

    assert {:ok, %{"schema_contract" => "timeline_diff_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "timeline diff requires review for station-calendar reservation context changes" do
    source = [
      %{
        id: :contact_window,
        type: :planned_contact,
        scenario_id: :leo_1,
        starts_at_s: 30.0,
        ends_at_s: 40.0,
        ground_station_id: :dss_14,
        direction: :downlink,
        station_availability: :reserved,
        station_calendar_entry_id: :"declared:dss_14:30:40",
        station_calendar_reservation_ids: [:reservation_a],
        station_calendar_reserved_by: [:ops_a],
        metadata: %{timeline_id: :"timeline:contact_window"}
      }
    ]

    replacement = [
      %{
        id: :contact_window,
        type: :planned_contact,
        scenario_id: :leo_1,
        starts_at_s: 30.0,
        ends_at_s: 40.0,
        ground_station_id: :dss_14,
        direction: :downlink,
        station_availability: :reserved,
        station_calendar_entry_id: :"declared:dss_14:30:40",
        station_calendar_reservation_ids: [:reservation_b],
        station_calendar_reserved_by: [:ops_b],
        metadata: %{timeline_id: :"timeline:contact_window"}
      }
    ]

    report = Timeline.diff_report(source, replacement)

    assert %{
             "changed_count" => 1,
             "review_required_count" => 1,
             "rows" => [
               %{
                 "diff_status" => "changed",
                 "changed_fields" => [
                   "station_calendar_reservation_ids",
                   "station_calendar_reserved_by"
                 ],
                 "requires_operator_review" => true,
                 "required_operator_action" => "review_timeline_change",
                 "source_activity_context" => %{
                   "station_calendar_reservation_ids" => ["reservation_a"],
                   "station_calendar_reserved_by" => ["ops_a"]
                 },
                 "replacement_activity_context" => %{
                   "station_calendar_reservation_ids" => ["reservation_b"],
                   "station_calendar_reserved_by" => ["ops_b"]
                 }
               }
             ]
           } = report

    assert {:ok, %{"schema_contract" => "timeline_diff_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "timeline diff requires review for station-calendar trust evidence changes" do
    source = [
      %{
        id: :contact_window,
        type: :planned_contact,
        scenario_id: :leo_1,
        starts_at_s: 30.0,
        ends_at_s: 40.0,
        ground_station_id: :dss_14,
        direction: :downlink,
        station_calendar_entry_id: :shared_partner_window,
        station_calendar_provider_id: :ground_partner_old,
        station_calendar_provider_entry_id: :shared_partner_window,
        station_calendar_trust_boundary_status: :missing,
        metadata: %{timeline_id: :"timeline:contact_window"}
      }
    ]

    replacement = [
      %{
        id: :contact_window,
        type: :planned_contact,
        scenario_id: :leo_1,
        starts_at_s: 30.0,
        ends_at_s: 40.0,
        ground_station_id: :dss_14,
        direction: :downlink,
        station_calendar_entry_id: :shared_partner_window,
        station_calendar_provider_id: :ground_partner_new,
        station_calendar_provider_entry_id: :shared_partner_window,
        station_calendar_trust_boundary_status: :declared,
        trust_boundary: :ground_partner_api,
        provenance: %{trust_boundary: :ground_partner_api},
        source_station_calendar_entry: %{id: :partner_capacity},
        source_station_calendar_overlaps: [%{id: :partner_capacity}],
        metadata: %{timeline_id: :"timeline:contact_window"}
      }
    ]

    report = Timeline.diff_report(source, replacement)

    assert %{
             "changed_count" => 1,
             "review_required_count" => 1,
             "rows" => [
               %{
                 "diff_status" => "changed",
                 "changed_fields" => changed_fields,
                 "requires_operator_review" => true,
                 "required_operator_action" => "review_timeline_change",
                 "source_activity_context" => %{
                   "station_calendar_provider_id" => "ground_partner_old",
                   "station_calendar_provider_entry_id" => "shared_partner_window",
                   "station_calendar_trust_boundary_status" => "missing"
                 },
                 "replacement_activity_context" => %{
                   "station_calendar_provider_id" => "ground_partner_new",
                   "station_calendar_provider_entry_id" => "shared_partner_window",
                   "station_calendar_trust_boundary_status" => "declared",
                   "trust_boundary" => "ground_partner_api",
                   "provenance" => %{"trust_boundary" => "ground_partner_api"},
                   "source_station_calendar_entry" => %{"id" => "partner_capacity"},
                   "source_station_calendar_overlaps" => [%{"id" => "partner_capacity"}]
                 }
               }
             ]
           } = report

    assert "station_calendar_provider_id" in changed_fields
    refute "station_calendar_provider_entry_id" in changed_fields
    assert "station_calendar_trust_boundary_status" in changed_fields
    assert "trust_boundary" in changed_fields
    assert "provenance" in changed_fields
    assert "source_station_calendar_entry" in changed_fields
    assert "source_station_calendar_overlaps" in changed_fields

    assert {:ok, %{"schema_contract" => "timeline_diff_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_timeline_diff_report(report)
    import = CadenceImport.from_timeline_diff_report(report)

    assert %{
             "review_type" => "timeline_diff_review",
             "changed_fields" => ^changed_fields,
             "source_activity_context" => %{
               "station_calendar_provider_id" => "ground_partner_old"
             },
             "replacement_activity_context" => %{
               "station_calendar_provider_id" => "ground_partner_new"
             }
           } =
             Enum.find(review["rows"], &(&1["review_type"] == "timeline_diff_review"))

    assert %{
             "source_review_type" => "timeline_diff_review",
             "changed_fields" => ^changed_fields,
             "source_activity_context" => %{
               "station_calendar_provider_id" => "ground_partner_old"
             },
             "replacement_activity_context" => %{
               "station_calendar_provider_id" => "ground_partner_new"
             }
           } =
             Enum.find(import["rows"], &(&1["source_review_type"] == "timeline_diff_review"))
  end

  test "timeline diff requires review for changed command success evidence" do
    source = [
      %{
        id: :cmd_window,
        type: :command,
        scenario_id: :leo_1,
        starts_at_s: 30.0,
        ends_at_s: 40.0,
        ground_station_id: :dss_14,
        direction: :command,
        command_success: true,
        command_result: :accepted,
        command_success_factor: 1.0,
        command_success_factor_source: :"operational_feedback.command_success_rate.activity",
        metadata: %{timeline_id: :"timeline:cmd_window"}
      }
    ]

    replacement = [
      %{
        id: :cmd_window,
        type: :command,
        scenario_id: :leo_1,
        starts_at_s: 30.0,
        ends_at_s: 40.0,
        ground_station_id: :dss_14,
        direction: :command,
        command_success: false,
        command_result: :rejected,
        command_success_factor: 0.25,
        command_success_factor_source: :"operational_feedback.command_success_rate.activity",
        metadata: %{timeline_id: :"timeline:cmd_window"}
      }
    ]

    report = Timeline.diff_report(source, replacement)

    assert %{
             "changed_count" => 1,
             "review_required_count" => 1,
             "rows" => [
               %{
                 "diff_status" => "changed",
                 "changed_fields" => changed_fields,
                 "requires_operator_review" => true,
                 "required_operator_action" => "review_timeline_change",
                 "source_activity_context" => %{
                   "command_success" => true,
                   "command_result" => "accepted",
                   "command_success_factor" => 1.0
                 },
                 "replacement_activity_context" => %{
                   "command_success" => false,
                   "command_result" => "rejected",
                   "command_success_factor" => 0.25
                 }
               }
             ]
           } = report

    assert "command_success" in changed_fields
    assert "command_result" in changed_fields
    assert "command_success_factor" in changed_fields

    review = OperatorReview.from_timeline_diff_report(report)
    import = CadenceImport.from_timeline_diff_report(report)

    assert [
             %{
               "review_type" => "timeline_diff_review",
               "changed_fields" => ^changed_fields,
               "replacement_activity_context" => %{"command_success" => false}
             }
           ] = review["rows"]

    assert [
             %{
               "import_action" => "review_timeline_diff",
               "source_review_type" => "timeline_diff_review",
               "changed_fields" => ^changed_fields,
               "replacement_activity_context" => %{"command_success" => false}
             }
           ] = import["rows"]

    assert {:ok, %{"schema_contract" => "timeline_diff_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "timeline diff requires review for changed data-volume evidence" do
    source = [
      %{
        id: :image_product,
        type: :observe,
        scenario_id: :leo_1,
        target_id: :target_a,
        starts_at_s: 30.0,
        ends_at_s: 40.0,
        collection_id: :collection_alpha,
        product_id: :image_alpha_1,
        planned_data_volume_mb: 80.0,
        delivered_data_mb: 80.0,
        collection_ends_at_s: 40.0,
        planned_delivery_at_s: 90.0,
        actual_delivery_at_s: 90.0,
        max_latency_s: 80.0,
        metadata: %{timeline_id: :"timeline:image_product"}
      }
    ]

    replacement = [
      %{
        id: :image_product,
        type: :observe,
        scenario_id: :leo_1,
        target_id: :target_a,
        starts_at_s: 30.0,
        ends_at_s: 40.0,
        collection_id: :collection_alpha,
        product_id: :image_alpha_1,
        planned_data_volume_mb: 80.0,
        delivered_data_mb: 60.0,
        collection_ends_at_s: 40.0,
        planned_delivery_at_s: 90.0,
        actual_delivery_at_s: 120.0,
        max_latency_s: 80.0,
        metadata: %{timeline_id: :"timeline:image_product"}
      }
    ]

    report = Timeline.diff_report(source, replacement)

    assert %{
             "changed_count" => 1,
             "review_required_count" => 1,
             "rows" => [
               %{
                 "diff_status" => "changed",
                 "changed_fields" => changed_fields,
                 "requires_operator_review" => true,
                 "required_operator_action" => "review_timeline_change",
                 "source_activity_context" => %{
                   "planned_data_volume_mb" => 80.0,
                   "actual_data_volume_mb" => 80.0,
                   "data_volume_delta_mb" => source_delta,
                   "data_volume_completion_fraction" => 1.0,
                   "collection_ends_at_s" => 40.0,
                   "planned_delivery_at_s" => 90.0,
                   "actual_delivery_at_s" => 90.0,
                   "max_latency_s" => 80.0,
                   "planned_latency_s" => 50.0,
                   "actual_latency_s" => 50.0,
                   "latency_delta_s" => source_latency_delta,
                   "latency_margin_s" => 30.0
                 },
                 "replacement_activity_context" => %{
                   "planned_data_volume_mb" => 80.0,
                   "actual_data_volume_mb" => 60.0,
                   "data_volume_delta_mb" => -20.0,
                   "data_volume_completion_fraction" => 0.75,
                   "collection_ends_at_s" => 40.0,
                   "planned_delivery_at_s" => 90.0,
                   "actual_delivery_at_s" => 120.0,
                   "max_latency_s" => 80.0,
                   "planned_latency_s" => 50.0,
                   "actual_latency_s" => 80.0,
                   "latency_delta_s" => 30.0,
                   "latency_margin_s" => replacement_latency_margin
                 }
               }
             ]
           } = report

    assert source_delta == 0.0
    assert source_latency_delta == 0.0
    assert replacement_latency_margin == 0.0
    assert "actual_data_volume_mb" in changed_fields
    assert "data_volume_delta_mb" in changed_fields
    assert "data_volume_completion_fraction" in changed_fields
    assert "actual_delivery_at_s" in changed_fields
    assert "actual_latency_s" in changed_fields
    assert "latency_delta_s" in changed_fields
    assert "latency_margin_s" in changed_fields

    assert {:ok, %{"schema_contract" => "timeline_diff_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "timeline diff requires review for changed throughput evidence" do
    source = [
      %{
        id: :downlink_product,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        direction: :downlink,
        starts_at_s: 30.0,
        ends_at_s: 40.0,
        estimated_throughput_mb: 144.0,
        actual_downlink_mb: 144.0,
        metadata: %{timeline_id: :"timeline:downlink_product"}
      }
    ]

    replacement = [
      %{
        id: :downlink_product,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        direction: :downlink,
        starts_at_s: 30.0,
        ends_at_s: 40.0,
        estimated_throughput_mb: 144.0,
        actual_downlink_mb: 72.0,
        metadata: %{timeline_id: :"timeline:downlink_product"}
      }
    ]

    report = Timeline.diff_report(source, replacement)

    assert %{
             "changed_count" => 1,
             "review_required_count" => 1,
             "rows" => [
               %{
                 "diff_status" => "changed",
                 "changed_fields" => changed_fields,
                 "requires_operator_review" => true,
                 "required_operator_action" => "review_timeline_change",
                 "source_activity_context" => %{
                   "planned_estimated_throughput_mb" => 144.0,
                   "actual_throughput_mb" => 144.0,
                   "throughput_delta_mb" => source_delta,
                   "throughput_completion_fraction" => 1.0
                 },
                 "replacement_activity_context" => %{
                   "planned_estimated_throughput_mb" => 144.0,
                   "actual_throughput_mb" => 72.0,
                   "throughput_delta_mb" => -72.0,
                   "throughput_completion_fraction" => 0.5
                 }
               }
             ]
           } = report

    assert source_delta == 0.0
    assert "actual_throughput_mb" in changed_fields
    assert "throughput_delta_mb" in changed_fields
    assert "throughput_completion_fraction" in changed_fields

    assert {:ok, %{"schema_contract" => "timeline_diff_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "timeline diff requires review for changed downlink completion evidence" do
    source = [
      %{
        id: :downlink_product,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        direction: :downlink,
        starts_at_s: 30.0,
        ends_at_s: 40.0,
        estimated_throughput_mb: 360.0,
        required_downlink_mb: 180.0,
        candidate_downlink_mb: 360.0,
        downlink_completion_ratio: 1.0,
        selected_downlink_shortfall_mb: 0.0,
        downlink_requirement_status: :satisfied,
        downlink_completion_source: "candidate_refresh.objectives.collection_latency",
        downlink_completion_sources: ["candidate_refresh.objectives.collection_latency"],
        metadata: %{timeline_id: :"timeline:downlink_product"}
      }
    ]

    replacement = [
      %{
        id: :downlink_product,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        direction: :downlink,
        starts_at_s: 30.0,
        ends_at_s: 40.0,
        estimated_throughput_mb: 360.0,
        required_downlink_mb: 420.0,
        candidate_downlink_mb: 360.0,
        downlink_completion_ratio: 360.0 / 420.0,
        selected_downlink_shortfall_mb: 60.0,
        downlink_requirement_status: :shortfall,
        downlink_completion_source:
          "candidate_refresh.downlink_demand.objectives_and_operational_feedback",
        downlink_completion_sources: [
          "candidate_refresh.objectives.collection_latency",
          "operational_feedback.downlink_demand_mb.station"
        ],
        metadata: %{timeline_id: :"timeline:downlink_product"}
      }
    ]

    report = Timeline.diff_report(source, replacement)

    assert %{
             "changed_count" => 1,
             "review_required_count" => 1,
             "changed_field_counts" => %{
               "downlink_completion_ratio" => 1,
               "downlink_completion_source" => 1,
               "downlink_completion_sources" => 1,
               "downlink_requirement_status" => 1,
               "required_downlink_mb" => 1,
               "selected_downlink_shortfall_mb" => 1
             },
             "rows" => [
               %{
                 "diff_status" => "changed",
                 "changed_fields" => changed_fields,
                 "requires_operator_review" => true,
                 "required_operator_action" => "review_timeline_change",
                 "source_activity_context" => %{
                   "required_downlink_mb" => 180.0,
                   "candidate_downlink_mb" => 360.0,
                   "downlink_completion_ratio" => 1.0,
                   "selected_downlink_shortfall_mb" => source_shortfall_mb,
                   "downlink_requirement_status" => "satisfied",
                   "downlink_completion_source" =>
                     "candidate_refresh.objectives.collection_latency",
                   "downlink_completion_sources" => [
                     "candidate_refresh.objectives.collection_latency"
                   ]
                 },
                 "replacement_activity_context" => %{
                   "required_downlink_mb" => 420.0,
                   "candidate_downlink_mb" => 360.0,
                   "selected_downlink_shortfall_mb" => 60.0,
                   "downlink_requirement_status" => "shortfall",
                   "downlink_completion_source" =>
                     "candidate_refresh.downlink_demand.objectives_and_operational_feedback",
                   "downlink_completion_sources" => [
                     "candidate_refresh.objectives.collection_latency",
                     "operational_feedback.downlink_demand_mb.station"
                   ]
                 }
               }
             ]
           } = report

    assert source_shortfall_mb == 0.0
    assert "required_downlink_mb" in changed_fields
    assert "downlink_completion_ratio" in changed_fields
    assert "selected_downlink_shortfall_mb" in changed_fields
    assert "downlink_requirement_status" in changed_fields
    assert "downlink_completion_source" in changed_fields
    assert "downlink_completion_sources" in changed_fields
    refute "candidate_downlink_mb" in changed_fields

    assert {:ok, %{"schema_contract" => "timeline_diff_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_timeline_diff_report(report)
    import = CadenceImport.from_timeline_diff_report(report)

    assert %{
             "review_type" => "timeline_diff_review",
             "changed_fields" => ^changed_fields,
             "source_activity_context" => %{
               "required_downlink_mb" => 180.0,
               "downlink_completion_source" => "candidate_refresh.objectives.collection_latency"
             },
             "replacement_activity_context" => %{
               "required_downlink_mb" => 420.0,
               "downlink_requirement_status" => "shortfall",
               "downlink_completion_sources" => [
                 "candidate_refresh.objectives.collection_latency",
                 "operational_feedback.downlink_demand_mb.station"
               ]
             }
           } = List.first(review["rows"])

    assert %{
             "import_action" => "review_timeline_diff",
             "changed_fields" => ^changed_fields,
             "source_review_type" => "timeline_diff_review",
             "source_activity_context" => %{
               "required_downlink_mb" => 180.0,
               "downlink_completion_source" => "candidate_refresh.objectives.collection_latency"
             },
             "replacement_activity_context" => %{
               "required_downlink_mb" => 420.0,
               "downlink_requirement_status" => "shortfall",
               "downlink_completion_sources" => [
                 "candidate_refresh.objectives.collection_latency",
                 "operational_feedback.downlink_demand_mb.station"
               ]
             }
           } = List.first(import["rows"])

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "timeline diff preserves provider data-volume aliases for downlink completion review" do
    source = [
      %{
        id: :provider_downlink_product,
        type: :contact,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        direction: :downlink,
        starts_at_s: 30.0,
        ends_at_s: 40.0,
        target_data_volume_mb: "120.0",
        selected_data_volume_mb: "120.0",
        selected_data_volume_shortfall_mb: "0.0",
        downlink_requirement_status: :satisfied,
        downlink_completion_sources: ["provider.collection:product_1"],
        metadata: %{timeline_id: :"timeline:provider_downlink_product"}
      }
    ]

    replacement = [
      %{
        id: :provider_downlink_product,
        type: :contact,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        direction: :downlink,
        starts_at_s: 30.0,
        ends_at_s: 40.0,
        target_data_volume_mb: "120.0",
        selected_data_volume_mb: "40.0",
        selected_data_volume_shortfall_mb: "80.0",
        downlink_requirement_status: :shortfall,
        downlink_completion_sources: ["provider.collection:product_1"],
        metadata: %{timeline_id: :"timeline:provider_downlink_product"}
      }
    ]

    operational_report = Timeline.operational_report(replacement)
    report = Timeline.diff_report(source, replacement)

    assert %{
             "activity_context" => %{
               "target_data_volume_mb" => 120.0,
               "selected_data_volume_mb" => 40.0,
               "selected_data_volume_shortfall_mb" => 80.0
             }
           } = List.first(operational_report["rows"])

    assert %{
             "changed_count" => 1,
             "review_required_count" => 1,
             "changed_field_counts" => %{
               "downlink_requirement_status" => 1,
               "selected_data_volume_mb" => 1,
               "selected_data_volume_shortfall_mb" => 1
             },
             "rows" => [
               %{
                 "diff_status" => "changed",
                 "changed_fields" => changed_fields,
                 "source_activity_context" => %{
                   "target_data_volume_mb" => 120.0,
                   "selected_data_volume_mb" => 120.0,
                   "selected_data_volume_shortfall_mb" => source_shortfall_mb
                 },
                 "replacement_activity_context" => %{
                   "target_data_volume_mb" => 120.0,
                   "selected_data_volume_mb" => 40.0,
                   "selected_data_volume_shortfall_mb" => 80.0,
                   "downlink_requirement_status" => "shortfall"
                 }
               }
             ]
           } = report

    assert source_shortfall_mb == 0.0
    assert "selected_data_volume_mb" in changed_fields
    assert "selected_data_volume_shortfall_mb" in changed_fields
    refute "target_data_volume_mb" in changed_fields

    review = OperatorReview.from_timeline_diff_report(report)
    import = CadenceImport.from_timeline_diff_report(report)

    assert %{
             "source_activity_context" => %{"target_data_volume_mb" => 120.0},
             "replacement_activity_context" => %{
               "selected_data_volume_mb" => 40.0,
               "selected_data_volume_shortfall_mb" => 80.0
             }
           } = List.first(review["rows"])

    assert %{
             "source_review_type" => "timeline_diff_review",
             "replacement_activity_context" => %{
               "selected_data_volume_mb" => 40.0,
               "selected_data_volume_shortfall_mb" => 80.0
             }
           } = List.first(import["rows"])

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(operational_report)

    assert {:ok, %{"schema_contract" => "timeline_diff_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "timeline diff requires review for changed resource assignment" do
    source = [
      %{
        id: :thermal_balance,
        type: :command,
        scenario_id: :leo_1,
        starts_at_s: 30.0,
        ends_at_s: 40.0,
        resource_id: :power_bus,
        resource_source_quality: :declared,
        resource_trust_boundary_status: :declared,
        fuel_margin: 0.7,
        payload_available: true,
        metadata: %{timeline_id: :"timeline:thermal_balance"}
      }
    ]

    replacement = [
      %{
        id: :thermal_balance,
        type: :command,
        scenario_id: :leo_1,
        starts_at_s: 30.0,
        ends_at_s: 40.0,
        resource_id: :battery_bus,
        resource_source_quality: :estimated,
        resource_trust_boundary_status: :missing,
        fuel_margin: 0.3,
        payload_available: false,
        metadata: %{timeline_id: :"timeline:thermal_balance"}
      }
    ]

    report = Timeline.diff_report(source, replacement)

    assert %{
             "changed_count" => 1,
             "review_required_count" => 1,
             "changed_field_counts" => %{
               "resource_id" => 1,
               "resource_source_quality" => 1,
               "resource_trust_boundary_status" => 1,
               "fuel_margin" => 1,
               "payload_available" => 1
             },
             "rows" => [
               %{
                 "diff_status" => "changed",
                 "changed_fields" => changed_fields,
                 "requires_operator_review" => true,
                 "required_operator_action" => "review_timeline_change",
                 "source_activity_context" => %{
                   "resource_id" => "power_bus",
                   "resource_source_quality" => "declared",
                   "resource_trust_boundary_status" => "declared",
                   "fuel_margin" => 0.7,
                   "payload_available" => true
                 },
                 "replacement_activity_context" => %{
                   "resource_id" => "battery_bus",
                   "resource_source_quality" => "estimated",
                   "resource_trust_boundary_status" => "missing",
                   "fuel_margin" => 0.3,
                   "payload_available" => false
                 }
               }
             ]
           } = report

    assert changed_fields == [
             "resource_id",
             "resource_source_quality",
             "resource_trust_boundary_status",
             "fuel_margin",
             "payload_available"
           ]

    review = OperatorReview.from_timeline_diff_report(report)
    import = CadenceImport.from_timeline_diff_report(report)

    assert [
             %{
               "review_type" => "timeline_diff_review",
               "changed_fields" => ^changed_fields,
               "source_activity_context" => %{
                 "resource_id" => "power_bus",
                 "resource_source_quality" => "declared",
                 "resource_trust_boundary_status" => "declared",
                 "fuel_margin" => 0.7,
                 "payload_available" => true
               },
               "replacement_activity_context" => %{
                 "resource_id" => "battery_bus",
                 "resource_source_quality" => "estimated",
                 "resource_trust_boundary_status" => "missing",
                 "fuel_margin" => 0.3,
                 "payload_available" => false
               }
             }
           ] = review["rows"]

    assert [
             %{
               "import_action" => "review_timeline_diff",
               "source_review_type" => "timeline_diff_review",
               "changed_fields" => ^changed_fields,
               "source_activity_context" => %{
                 "resource_id" => "power_bus",
                 "resource_source_quality" => "declared",
                 "resource_trust_boundary_status" => "declared",
                 "fuel_margin" => 0.7,
                 "payload_available" => true
               },
               "replacement_activity_context" => %{
                 "resource_id" => "battery_bus",
                 "resource_source_quality" => "estimated",
                 "resource_trust_boundary_status" => "missing",
                 "fuel_margin" => 0.3,
                 "payload_available" => false
               }
             }
           ] = import["rows"]

    assert {:ok, %{"schema_contract" => "timeline_diff_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "timeline diff requires review for changed thermal evidence" do
    source = [
      %{
        id: :payload_thermal_check,
        type: :command,
        scenario_id: :leo_1,
        starts_at_s: 30.0,
        ends_at_s: 40.0,
        thermal_zone_id: :payload_deck,
        planned_temperature_c: 20.0,
        actual_temperature_c: 35.0,
        max_operating_temperature_c: 45.0,
        thermal_status: :nominal,
        metadata: %{timeline_id: :"timeline:payload_thermal_check"}
      }
    ]

    replacement = [
      %{
        id: :payload_thermal_check,
        type: :command,
        scenario_id: :leo_1,
        starts_at_s: 30.0,
        ends_at_s: 40.0,
        thermal_zone_id: :payload_deck,
        planned_temperature_c: 20.0,
        actual_temperature_c: 43.0,
        max_operating_temperature_c: 45.0,
        thermal_status: :near_limit,
        metadata: %{timeline_id: :"timeline:payload_thermal_check"}
      }
    ]

    report = Timeline.diff_report(source, replacement)

    assert %{
             "changed_count" => 1,
             "review_required_count" => 1,
             "changed_field_counts" => %{
               "actual_temperature_c" => 1,
               "temperature_delta_c" => 1,
               "thermal_margin_c" => 1,
               "thermal_status" => 1
             },
             "rows" => [
               %{
                 "changed_fields" => changed_fields,
                 "required_operator_action" => "review_timeline_change",
                 "source_activity_context" => %{
                   "actual_temperature_c" => 35.0,
                   "temperature_delta_c" => 15.0,
                   "thermal_margin_c" => 10.0,
                   "thermal_status" => "nominal"
                 },
                 "replacement_activity_context" => %{
                   "actual_temperature_c" => 43.0,
                   "temperature_delta_c" => 23.0,
                   "thermal_margin_c" => 2.0,
                   "thermal_status" => "near_limit"
                 }
               }
             ]
           } = report

    assert changed_fields == [
             "actual_temperature_c",
             "temperature_delta_c",
             "thermal_margin_c",
             "thermal_status"
           ]

    assert {:ok, %{"schema_contract" => "timeline_diff_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "timeline diff requires review for changed spacecraft assignment" do
    source = [
      %{
        id: :payload_mode,
        type: :command,
        scenario_id: :leo_1,
        spacecraft: %{id: :leo_1},
        target_id: :payload_bus,
        source_window_id: :payload_mode_window,
        starts_at_s: 30.0,
        ends_at_s: 40.0,
        metadata: %{timeline_id: :"timeline:payload_mode"}
      }
    ]

    replacement = [
      %{
        id: :payload_mode,
        type: :command,
        scenario_id: :leo_1,
        satellite: %{satellite_id: :leo_2},
        target_id: :payload_bus,
        source_window_id: :payload_mode_window,
        starts_at_s: 30.0,
        ends_at_s: 40.0,
        metadata: %{timeline_id: :"timeline:payload_mode"}
      }
    ]

    report = Timeline.diff_report(source, replacement)

    assert %{
             "changed_count" => 1,
             "review_required_count" => 1,
             "changed_field_counts" => %{"spacecraft_id" => 1},
             "rows" => [
               %{
                 "diff_status" => "changed",
                 "changed_fields" => ["spacecraft_id"],
                 "requires_operator_review" => true,
                 "required_operator_action" => "review_timeline_change",
                 "source_spacecraft_id" => "leo_1",
                 "replacement_spacecraft_id" => "leo_2",
                 "source_target_id" => "payload_bus",
                 "replacement_target_id" => "payload_bus",
                 "source_source_window_id" => "payload_mode_window",
                 "replacement_source_window_id" => "payload_mode_window",
                 "source_activity_context" => %{"spacecraft_id" => "leo_1"},
                 "replacement_activity_context" => %{"spacecraft_id" => "leo_2"}
               }
             ]
           } = report

    review = OperatorReview.from_timeline_diff_report(report)
    import = CadenceImport.from_timeline_diff_report(report)

    assert [
             %{
               "review_type" => "timeline_diff_review",
               "changed_fields" => ["spacecraft_id"],
               "source_spacecraft_id" => "leo_1",
               "replacement_spacecraft_id" => "leo_2",
               "source_target_id" => "payload_bus",
               "replacement_target_id" => "payload_bus",
               "source_source_window_id" => "payload_mode_window",
               "replacement_source_window_id" => "payload_mode_window",
               "source_activity_context" => %{"spacecraft_id" => "leo_1"},
               "replacement_activity_context" => %{"spacecraft_id" => "leo_2"}
             }
           ] = review["rows"]

    assert [
             %{
               "import_action" => "review_timeline_diff",
               "changed_fields" => ["spacecraft_id"],
               "source_spacecraft_id" => "leo_1",
               "replacement_spacecraft_id" => "leo_2",
               "source_target_id" => "payload_bus",
               "replacement_target_id" => "payload_bus",
               "source_source_window_id" => "payload_mode_window",
               "replacement_source_window_id" => "payload_mode_window",
               "source_activity_context" => %{"spacecraft_id" => "leo_1"},
               "replacement_activity_context" => %{"spacecraft_id" => "leo_2"}
             }
           ] = import["rows"]

    assert {:ok, %{"schema_contract" => "timeline_diff_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "timeline diff requires review for changed execution uncertainty evidence" do
    source = [
      %{
        id: :raise_apogee,
        type: :impulsive_burn,
        scenario_id: :leo_1,
        starts_at_s: 30.0,
        ends_at_s: 30.0,
        execution_uncertainty: %{
          timing_3sigma_s: 1.0,
          delta_v_3sigma_km_s: [0.0, 0.0001, 0.0],
          source: :operator_estimate
        },
        metadata: %{timeline_id: :"timeline:raise_apogee"}
      }
    ]

    replacement = [
      %{
        id: :raise_apogee,
        type: :impulsive_burn,
        scenario_id: :leo_1,
        starts_at_s: 30.0,
        ends_at_s: 30.0,
        execution_uncertainty: %{
          timing_3sigma_s: 3.0,
          delta_v_3sigma_km_s: [0.0, 0.0003, 0.0],
          source: :navigation_update
        },
        metadata: %{timeline_id: :"timeline:raise_apogee"}
      }
    ]

    report = Timeline.diff_report(source, replacement)

    assert %{
             "changed_count" => 1,
             "review_required_count" => 1,
             "rows" => [
               %{
                 "diff_status" => "changed",
                 "changed_fields" => ["execution_uncertainty"],
                 "requires_operator_review" => true,
                 "required_operator_action" => "review_timeline_change",
                 "source_activity_context" => %{
                   "execution_uncertainty_status" => "declared",
                   "execution_uncertainty" => %{"timing_3sigma_s" => 1.0},
                   "execution_uncertainty_source" => "operator_estimate"
                 },
                 "replacement_activity_context" => %{
                   "execution_uncertainty_status" => "declared",
                   "execution_uncertainty" => %{"timing_3sigma_s" => 3.0},
                   "execution_uncertainty_source" => "navigation_update"
                 }
               }
             ]
           } = report

    review = OperatorReview.from_timeline_diff_report(report)
    import = CadenceImport.from_timeline_diff_report(report)

    assert [
             %{
               "review_type" => "timeline_diff_review",
               "changed_fields" => ["execution_uncertainty"],
               "replacement_activity_context" => %{
                 "execution_uncertainty_source" => "navigation_update"
               }
             }
           ] = review["rows"]

    assert [
             %{
               "import_action" => "review_timeline_diff",
               "source_review_type" => "timeline_diff_review",
               "changed_fields" => ["execution_uncertainty"],
               "replacement_activity_context" => %{
                 "execution_uncertainty_source" => "navigation_update"
               }
             }
           ] = import["rows"]

    assert {:ok, %{"schema_contract" => "timeline_diff_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "timeline diff gives removed protected and executed activities specific review actions" do
    source = [
      %{
        id: :executed_downlink,
        type: :downlink,
        scenario_id: :leo_1,
        starts_at_s: 10.0,
        ends_at_s: 20.0,
        status: :completed,
        approval_status: :approved,
        metadata: %{timeline_id: :"timeline:executed_downlink"}
      },
      %{
        id: :locked_command,
        type: :command,
        scenario_id: :leo_1,
        starts_at_s: 30.0,
        ends_at_s: 40.0,
        locked: true,
        metadata: %{timeline_id: :"timeline:locked_command"}
      }
    ]

    report = Timeline.diff_report(source, [])

    assert %{
             "diff_status" => "removed",
             "source_activity_id" => "executed_downlink",
             "source_status" => "completed",
             "required_operator_action" => "review_removed_executed_activity",
             "reason" => "replacement timeline removes executed activity executed_downlink"
           } = Enum.find(report["rows"], &(&1["timeline_id"] == "timeline:executed_downlink"))

    assert %{
             "diff_status" => "removed",
             "source_activity_id" => "locked_command",
             "source_locked" => true,
             "required_operator_action" => "review_removed_protected_activity",
             "reason" => "replacement timeline removes locked activity locked_command"
           } = Enum.find(report["rows"], &(&1["timeline_id"] == "timeline:locked_command"))

    review = OperatorReview.from_timeline_diff_report(report)

    assert Enum.any?(
             review["rows"],
             &(&1["activity_id"] == "executed_downlink" and
                 &1["required_operator_action"] == "review_removed_executed_activity")
           )

    assert Enum.any?(
             review["rows"],
             &(&1["activity_id"] == "locked_command" and
                 &1["required_operator_action"] == "review_removed_protected_activity")
           )

    assert {:ok, %{"schema_contract" => "timeline_diff_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)
  end

  test "reports contact conflict and terminal activity operator actions" do
    report =
      Timeline.operational_report([
        %{
          id: "dl_conflict",
          type: "downlink",
          scenario_id: "leo_1",
          starts_at_s: 10.0,
          ends_at_s: 20.0,
          ground_station_id: "dss_14",
          direction: "downlink",
          approval_status: "approved",
          cadence_import: %{activity_type: "contact"},
          schedule_conflict_status: "conflicted",
          station_availability: "available"
        },
        %{
          id: "cmd_done",
          type: "command",
          starts_at_s: 30.0,
          ends_at_s: 40.0,
          ground_station_id: "dss_14",
          status: "executed",
          approval_status: "approved"
        },
        %{
          id: "dl_missed",
          type: "downlink",
          scenario_id: "leo_1",
          starts_at_s: 50.0,
          ends_at_s: 60.0,
          ground_station_id: "dss_14",
          status: "missed",
          approval_status: "approved",
          collection_id: "collection_alpha",
          product_id: "image_alpha_1",
          product_ids: ["image_alpha_1", "image_alpha_2"],
          payload_id: "camera_a",
          instrument_id: "wide_field",
          resource_id: "payload_bus",
          resource_source_quality: "declared",
          resource_trust_boundary_status: "declared",
          resource_provenance: %{source: "resource_summary"},
          power_margin: 0.36,
          payload_available: false,
          estimated_throughput_mb: 144.0,
          actual_downlink_mb: 72.0,
          data_volume_mb: 80.0,
          planned_data_volume_mb: 80.0,
          actual_data_volume_mb: 60.0,
          estimated_data_volume_mb: 80.0,
          estimated_storage_mb: 80.0,
          estimated_downlink_mb: 75.0,
          required_downlink_mb: 70.0,
          delivered_data_mb: 60.0,
          collection_ends_at_s: 48.0,
          planned_delivery_at_s: 90.0,
          delivered_at_s: 120.0,
          max_latency_s: 80.0,
          score: 42.5,
          score_terms: %{"contact_value" => 42.5},
          target_priority: 3.0,
          target_priority_source: "objective:downlink_priority",
          target_priority_objective_ids: ["objective:priority_hot"],
          target_priority_objective_type: "downlink_priority",
          contact_success: false,
          contact_success_factor: 0.4,
          contact_success_factor_source: "operational_feedback.contact_success_rate.station",
          cadence_import: %{
            activity_type: "contact",
            external_id: "dl_missed",
            schema_contract: "proposed_contact.v1",
            provider: "cadence",
            adapter: "cadence_contact_adapter",
            adapter_version: "2026-05",
            provenance: %{"trust_boundary" => "orbital_dynamics_to_cadence_adapter"}
          }
        }
      ])

    assert %{
             "activity_id" => "dl_conflict",
             "operational_kind" => "contact",
             "station_availability" => "available",
             "schedule_conflict_status" => "conflicted",
             "required_operator_action" => "resolve_contact_conflict",
             "operator_action_reason" => "schedule_conflict_status_conflicted"
           } = Enum.find(report["rows"], &(&1["activity_id"] == "dl_conflict"))

    assert %{
             "activity_id" => "cmd_done",
             "required_operator_action" => "none_terminal_activity",
             "operator_action_reason" => "activity_status_terminal"
           } = Enum.find(report["rows"], &(&1["activity_id"] == "cmd_done"))

    assert %{
             "activity_id" => "dl_missed",
             "status" => "missed",
             "collection_id" => "collection_alpha",
             "product_id" => "image_alpha_1",
             "product_ids" => ["image_alpha_1", "image_alpha_2"],
             "payload_id" => "camera_a",
             "instrument_id" => "wide_field",
             "resource_id" => "payload_bus",
             "resource_source_quality" => "declared",
             "resource_trust_boundary_status" => "declared",
             "resource_provenance" => %{"source" => "resource_summary"},
             "power_margin" => 0.36,
             "payload_available" => false,
             "planned_estimated_throughput_mb" => 144.0,
             "actual_throughput_mb" => 72.0,
             "throughput_delta_mb" => -72.0,
             "throughput_completion_fraction" => 0.5,
             "data_volume_mb" => 80.0,
             "planned_data_volume_mb" => 80.0,
             "actual_data_volume_mb" => 60.0,
             "data_volume_delta_mb" => -20.0,
             "data_volume_completion_fraction" => 0.75,
             "estimated_data_volume_mb" => 80.0,
             "estimated_storage_mb" => 80.0,
             "estimated_downlink_mb" => 75.0,
             "required_downlink_mb" => 70.0,
             "collection_ends_at_s" => 48.0,
             "planned_delivery_at_s" => 90.0,
             "actual_delivery_at_s" => 120.0,
             "max_latency_s" => 80.0,
             "planned_latency_s" => 42.0,
             "actual_latency_s" => 72.0,
             "latency_delta_s" => 30.0,
             "latency_margin_s" => 8.0,
             "cadence_import_provider" => "cadence",
             "cadence_import_adapter" => "cadence_contact_adapter",
             "cadence_import_adapter_version" => "2026-05",
             "cadence_import_trust_boundary" => "orbital_dynamics_to_cadence_adapter",
             "cadence_import_provenance" => %{
               "trust_boundary" => "orbital_dynamics_to_cadence_adapter"
             },
             "activity_context" => %{
               "score" => 42.5,
               "score_terms" => %{"contact_value" => 42.5},
               "target_priority" => 3.0,
               "target_priority_source" => "objective:downlink_priority",
               "target_priority_objective_ids" => ["objective:priority_hot"],
               "target_priority_objective_type" => "downlink_priority",
               "contact_success" => false,
               "contact_success_factor" => 0.4,
               "contact_success_factor_source" =>
                 "operational_feedback.contact_success_rate.station"
             },
             "required_operator_action" => "review_terminal_activity_exception",
             "operator_action_reason" => "activity_status_missed_requires_review"
           } = Enum.find(report["rows"], &(&1["activity_id"] == "dl_missed"))

    assert report["executed_count"] == 1
    assert report["terminal_exception_count"] == 1

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_operational_timeline_report(report)

    assert %{
             "review_type" => "operational_timeline_review",
             "activity_id" => "dl_missed",
             "collection_id" => "collection_alpha",
             "product_id" => "image_alpha_1",
             "product_ids" => ["image_alpha_1", "image_alpha_2"],
             "payload_id" => "camera_a",
             "instrument_id" => "wide_field",
             "resource_id" => "payload_bus",
             "resource_source_quality" => "declared",
             "resource_trust_boundary_status" => "declared",
             "resource_provenance" => %{"source" => "resource_summary"},
             "power_margin" => 0.36,
             "payload_available" => false,
             "planned_estimated_throughput_mb" => 144.0,
             "actual_throughput_mb" => 72.0,
             "throughput_delta_mb" => -72.0,
             "throughput_completion_fraction" => 0.5,
             "data_volume_mb" => 80.0,
             "planned_data_volume_mb" => 80.0,
             "actual_data_volume_mb" => 60.0,
             "data_volume_delta_mb" => -20.0,
             "data_volume_completion_fraction" => 0.75,
             "estimated_data_volume_mb" => 80.0,
             "estimated_storage_mb" => 80.0,
             "estimated_downlink_mb" => 75.0,
             "required_downlink_mb" => 70.0,
             "collection_ends_at_s" => 48.0,
             "planned_delivery_at_s" => 90.0,
             "actual_delivery_at_s" => 120.0,
             "max_latency_s" => 80.0,
             "planned_latency_s" => 42.0,
             "actual_latency_s" => 72.0,
             "latency_delta_s" => 30.0,
             "latency_margin_s" => 8.0,
             "cadence_import_provider" => "cadence",
             "cadence_import_adapter" => "cadence_contact_adapter",
             "cadence_import_adapter_version" => "2026-05",
             "cadence_import_trust_boundary" => "orbital_dynamics_to_cadence_adapter",
             "cadence_import_provenance" => %{
               "trust_boundary" => "orbital_dynamics_to_cadence_adapter"
             },
             "score" => 42.5,
             "score_terms" => %{"contact_value" => 42.5},
             "target_priority" => 3.0,
             "target_priority_source" => "objective:downlink_priority",
             "target_priority_objective_ids" => ["objective:priority_hot"],
             "target_priority_objective_type" => "downlink_priority",
             "contact_success" => false,
             "contact_success_factor" => 0.4,
             "contact_success_factor_source" =>
               "operational_feedback.contact_success_rate.station",
             "approval_status" => "operator_review_required",
             "required_operator_action" => "review_terminal_activity_exception",
             "reason" => "activity_status_missed_requires_review"
           } = Enum.find(review["rows"], &(&1["activity_id"] == "dl_missed"))

    import = CadenceImport.from_operational_timeline_report(report)

    assert %{
             "import_action" => "review_operational_timeline",
             "source_review_action" => "review_terminal_activity_exception",
             "activity_id" => "dl_missed",
             "collection_id" => "collection_alpha",
             "product_id" => "image_alpha_1",
             "product_ids" => ["image_alpha_1", "image_alpha_2"],
             "payload_id" => "camera_a",
             "instrument_id" => "wide_field",
             "resource_id" => "payload_bus",
             "resource_source_quality" => "declared",
             "resource_trust_boundary_status" => "declared",
             "resource_provenance" => %{"source" => "resource_summary"},
             "power_margin" => 0.36,
             "payload_available" => false,
             "planned_estimated_throughput_mb" => 144.0,
             "actual_throughput_mb" => 72.0,
             "throughput_delta_mb" => -72.0,
             "throughput_completion_fraction" => 0.5,
             "data_volume_mb" => 80.0,
             "planned_data_volume_mb" => 80.0,
             "actual_data_volume_mb" => 60.0,
             "data_volume_delta_mb" => -20.0,
             "data_volume_completion_fraction" => 0.75,
             "estimated_data_volume_mb" => 80.0,
             "estimated_storage_mb" => 80.0,
             "estimated_downlink_mb" => 75.0,
             "required_downlink_mb" => 70.0,
             "collection_ends_at_s" => 48.0,
             "planned_delivery_at_s" => 90.0,
             "actual_delivery_at_s" => 120.0,
             "max_latency_s" => 80.0,
             "planned_latency_s" => 42.0,
             "actual_latency_s" => 72.0,
             "latency_delta_s" => 30.0,
             "latency_margin_s" => 8.0,
             "cadence_import_provider" => "cadence",
             "cadence_import_adapter" => "cadence_contact_adapter",
             "cadence_import_adapter_version" => "2026-05",
             "cadence_import_trust_boundary" => "orbital_dynamics_to_cadence_adapter",
             "cadence_import_provenance" => %{
               "trust_boundary" => "orbital_dynamics_to_cadence_adapter"
             },
             "score" => 42.5,
             "score_terms" => %{"contact_value" => 42.5},
             "target_priority" => 3.0,
             "target_priority_source" => "objective:downlink_priority",
             "target_priority_objective_ids" => ["objective:priority_hot"],
             "target_priority_objective_type" => "downlink_priority",
             "contact_success" => false,
             "contact_success_factor" => 0.4,
             "contact_success_factor_source" =>
               "operational_feedback.contact_success_rate.station",
             "import_status" => "review_required_before_import"
           } = Enum.find(import["rows"], &(&1["activity_id"] == "dl_missed"))

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "routes cancelled and rejected provider statuses to terminal exception review" do
    report =
      Timeline.operational_report([
        %{
          id: :dl_cancelled,
          type: :downlink,
          scenario_id: :leo_1,
          starts_at_s: 10.0,
          ends_at_s: 20.0,
          ground_station_id: :dss_14,
          status: :cancelled,
          approval_status: :approved
        },
        %{
          id: :cmd_rejected,
          type: :command,
          scenario_id: :leo_1,
          starts_at_s: 30.0,
          ends_at_s: 40.0,
          ground_station_id: :dss_14,
          status: :rejected,
          approval_status: :approved
        }
      ])

    assert report["terminal_exception_count"] == 2

    assert %{
             "activity_id" => "dl_cancelled",
             "status" => "cancelled",
             "required_operator_action" => "review_terminal_activity_exception",
             "operator_action_reason" => "activity_status_cancelled_requires_review"
           } = Enum.find(report["rows"], &(&1["activity_id"] == "dl_cancelled"))

    assert %{
             "activity_id" => "cmd_rejected",
             "status" => "rejected",
             "required_operator_action" => "review_terminal_activity_exception",
             "operator_action_reason" => "activity_status_rejected_requires_review"
           } = Enum.find(report["rows"], &(&1["activity_id"] == "cmd_rejected"))

    assert %{
             "protection_decision" => "review_change",
             "reason" => "realized_status_cancelled_requires_repair_review"
           } =
             Timeline.protection_decision(
               %{id: :approved_dl, type: :downlink, approval_status: :approved},
               realized_status: :cancelled
             )

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "normalizes provider status aliases in raw timeline activity maps" do
    report =
      Timeline.operational_report([
        %{
          id: :cmd_provider_running,
          type: :command,
          scenario_id: :leo_1,
          starts_at_s: 10.0,
          ends_at_s: 20.0,
          ground_station_id: :dss_14,
          direction: "uplink",
          status: "In Progress"
        },
        %{
          id: :dl_provider_success,
          type: :downlink,
          scenario_id: :leo_1,
          starts_at_s: 30.0,
          ends_at_s: 40.0,
          ground_station_id: :dss_14,
          status: :succeeded
        },
        %{
          id: :cmd_provider_timeout,
          type: :command,
          scenario_id: :leo_1,
          starts_at_s: 50.0,
          ends_at_s: 60.0,
          ground_station_id: :dss_14,
          direction: "uplink",
          status: "timed-out",
          approval_status: :approved
        },
        %{
          id: :dl_provider_partial,
          type: :downlink,
          scenario_id: :leo_1,
          starts_at_s: 70.0,
          ends_at_s: 90.0,
          ground_station_id: :dss_14,
          status: "partially executed"
        }
      ])

    assert report["activity_status_counts"] == %{
             "completed" => 1,
             "executing" => 1,
             "failed" => 1,
             "partial" => 1
           }

    assert report["executed_count"] == 2
    assert report["terminal_exception_count"] == 1

    assert %{"status" => "executing"} =
             Enum.find(report["rows"], &(&1["activity_id"] == "cmd_provider_running"))

    assert %{
             "status" => "completed",
             "activity_context" => %{"status" => "completed"}
           } =
             Enum.find(report["rows"], &(&1["activity_id"] == "dl_provider_success"))

    assert %{
             "status" => "failed",
             "required_operator_action" => "review_terminal_activity_exception",
             "operator_action_reason" => "activity_status_failed_requires_review",
             "activity_context" => %{"status" => "failed"}
           } = Enum.find(report["rows"], &(&1["activity_id"] == "cmd_provider_timeout"))

    assert %{
             "status" => "partial",
             "activity_context" => %{"status" => "partial"}
           } = Enum.find(report["rows"], &(&1["activity_id"] == "dl_provider_partial"))

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "normalizes provider approval aliases in raw timeline activity maps" do
    report =
      Timeline.operational_report([
        %{
          id: :cmd_provider_review,
          type: :command,
          scenario_id: :leo_1,
          starts_at_s: 10.0,
          ends_at_s: 20.0,
          ground_station_id: :dss_14,
          direction: "uplink",
          approval_status: "Review Required"
        },
        %{
          id: :dl_provider_no_review,
          type: :downlink,
          scenario_id: :leo_1,
          starts_at_s: 30.0,
          ends_at_s: 40.0,
          ground_station_id: :dss_14,
          approval_status: "No Review Required"
        },
        %{
          id: :cmd_provider_blocked,
          type: :command,
          scenario_id: :leo_1,
          starts_at_s: 50.0,
          ends_at_s: 60.0,
          ground_station_id: :dss_14,
          direction: "uplink",
          approval_status: :policy_blocked
        },
        %{
          id: :cmd_provider_under_review,
          type: :command,
          scenario_id: :leo_1,
          starts_at_s: 70.0,
          ends_at_s: 80.0,
          ground_station_id: :dss_14,
          direction: "uplink",
          approval_status: "under review"
        }
      ])

    assert report["approval_status_counts"] == %{
             "blocked_by_policy" => 1,
             "not_required" => 1,
             "operator_review_required" => 2
           }

    assert report["required_operator_action_counts"] == %{
             "prepare_cadence_import" => 1,
             "resolve_blocked_activity" => 1,
             "review_command_contact" => 2
           }

    assert %{
             "approval_status" => "operator_review_required",
             "required_operator_action" => "review_command_contact",
             "operator_action_reason" => "command_boundary_requires_review",
             "activity_context" => %{"approval_status" => "operator_review_required"}
           } = Enum.find(report["rows"], &(&1["activity_id"] == "cmd_provider_review"))

    assert %{
             "approval_status" => "not_required",
             "required_operator_action" => "prepare_cadence_import"
           } = Enum.find(report["rows"], &(&1["activity_id"] == "dl_provider_no_review"))

    assert %{
             "approval_status" => "blocked_by_policy",
             "required_operator_action" => "resolve_blocked_activity",
             "operator_action_reason" => "approval_status_blocked_by_policy",
             "activity_context" => %{"approval_status" => "blocked_by_policy"}
           } = Enum.find(report["rows"], &(&1["activity_id"] == "cmd_provider_blocked"))

    assert %{
             "approval_status" => "operator_review_required",
             "activity_context" => %{"approval_status" => "operator_review_required"}
           } = Enum.find(report["rows"], &(&1["activity_id"] == "cmd_provider_under_review"))

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "treats JSON string truthy protection flags as locked or approved" do
    assert %{
             "protection_decision" => "preserve",
             "protection_category" => "locked_or_approved",
             "locked" => true,
             "approved" => false
           } =
             Timeline.protection_decision(%{
               id: :locked_from_json,
               type: :command,
               locked: " TRUE "
             })

    assert %{
             "protection_decision" => "preserve",
             "protection_category" => "locked_or_approved",
             "locked" => false,
             "approved" => true
           } =
             Timeline.protection_decision(%{
               id: :approved_from_json,
               type: :downlink,
               metadata: %{approved: "1"}
             })
  end

  test "routes provider failure result aliases to terminal exception review" do
    report =
      Timeline.operational_report([
        %{
          id: :dl_provider_dropped,
          type: :contact,
          direction: :downlink,
          scenario_id: :leo_1,
          starts_at_s: 10.0,
          ends_at_s: 20.0,
          ground_station_id: :dss_14,
          status: :completed,
          approval_status: :approved,
          contact_result: ["accepted", " DROPPED "]
        },
        %{
          id: :cmd_provider_rejected,
          type: :command,
          scenario_id: :leo_1,
          starts_at_s: 30.0,
          ends_at_s: 40.0,
          ground_station_id: :dss_14,
          status: :executed,
          approval_status: :approved,
          command_result: ["accepted", "REJECTED"]
        },
        %{
          id: :dl_provider_delivered,
          type: :contact,
          direction: :downlink,
          scenario_id: :leo_1,
          starts_at_s: 50.0,
          ends_at_s: 60.0,
          ground_station_id: :dss_14,
          status: :completed,
          approval_status: :approved,
          contact_result: :delivered
        }
      ])

    assert report["terminal_exception_count"] == 2

    assert %{
             "activity_id" => "dl_provider_dropped",
             "status" => "completed",
             "contact_result" => "accepted,DROPPED",
             "required_operator_action" => "review_terminal_activity_exception",
             "operator_action_reason" => "contact_result_dropped_requires_review",
             "activity_context" => %{"contact_result" => "accepted,DROPPED"}
           } = Enum.find(report["rows"], &(&1["activity_id"] == "dl_provider_dropped"))

    assert %{
             "activity_id" => "cmd_provider_rejected",
             "status" => "executed",
             "command_result" => "accepted,REJECTED",
             "required_operator_action" => "review_terminal_activity_exception",
             "operator_action_reason" => "command_result_rejected_requires_review",
             "activity_context" => %{"command_result" => "accepted,REJECTED"}
           } = Enum.find(report["rows"], &(&1["activity_id"] == "cmd_provider_rejected"))

    assert %{
             "activity_id" => "dl_provider_delivered",
             "required_operator_action" => "none_terminal_activity"
           } = Enum.find(report["rows"], &(&1["activity_id"] == "dl_provider_delivered"))

    review = OperatorReview.from_operational_timeline_report(report)
    manifest = CadenceImport.from_operator_review_package(review)

    assert Enum.any?(
             review["rows"],
             &(&1["activity_id"] == "dl_provider_dropped" and
                 &1["contact_result"] == "accepted,DROPPED" and
                 &1["required_operator_action"] == "review_terminal_activity_exception")
           )

    assert Enum.any?(
             manifest["rows"],
             &(&1["activity_id"] == "cmd_provider_rejected" and
                 &1["command_result"] == "accepted,REJECTED" and
                 &1["import_action"] == "review_operational_timeline")
           )

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "routes provider failure result maps to terminal exception review" do
    report =
      Timeline.operational_report([
        %{
          id: :dl_provider_map,
          type: :contact,
          direction: :downlink,
          scenario_id: :leo_1,
          starts_at_s: 10.0,
          ends_at_s: 20.0,
          ground_station_id: :dss_14,
          status: :completed,
          approval_status: :approved,
          contact_result: %{
            outcome: :accepted,
            provider_status: :"NO-CONTACT"
          }
        },
        %{
          id: :cmd_provider_map,
          type: :command,
          scenario_id: :leo_1,
          starts_at_s: 30.0,
          ends_at_s: 40.0,
          ground_station_id: :dss_14,
          status: :executed,
          approval_status: :approved,
          command_result: %{
            status: :rejected,
            details: %{message: "timed out"}
          }
        }
      ])

    assert report["terminal_exception_count"] == 2

    assert %{
             "activity_id" => "dl_provider_map",
             "contact_result" => "accepted,NO-CONTACT",
             "required_operator_action" => "review_terminal_activity_exception",
             "operator_action_reason" => "contact_result_no_contact_requires_review",
             "activity_context" => %{"contact_result" => "accepted,NO-CONTACT"}
           } = Enum.find(report["rows"], &(&1["activity_id"] == "dl_provider_map"))

    assert %{
             "activity_id" => "cmd_provider_map",
             "command_result" => "rejected,timed out",
             "required_operator_action" => "review_terminal_activity_exception",
             "operator_action_reason" => "command_result_rejected_requires_review",
             "activity_context" => %{"command_result" => "rejected,timed out"}
           } = Enum.find(report["rows"], &(&1["activity_id"] == "cmd_provider_map"))

    review = OperatorReview.from_operational_timeline_report(report)
    manifest = CadenceImport.from_operator_review_package(review)

    assert Enum.any?(
             review["rows"],
             &(&1["activity_id"] == "dl_provider_map" and
                 &1["contact_result"] == "accepted,NO-CONTACT" and
                 &1["required_operator_action"] == "review_terminal_activity_exception")
           )

    assert Enum.any?(
             manifest["rows"],
             &(&1["activity_id"] == "cmd_provider_map" and
                 &1["command_result"] == "rejected,timed out" and
                 &1["import_action"] == "review_operational_timeline")
           )

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "does not hide rejected or blocked approval states behind terminal status" do
    report =
      Timeline.operational_report([
        %{
          id: :cmd_blocked_executed,
          type: :command,
          scenario_id: :leo_1,
          starts_at_s: 10.0,
          ends_at_s: 20.0,
          ground_station_id: :dss_14,
          status: :executed,
          approval_status: :blocked_by_policy
        },
        %{
          id: :dl_rejected_completed,
          type: :downlink,
          scenario_id: :leo_1,
          starts_at_s: 30.0,
          ends_at_s: 40.0,
          ground_station_id: :dss_14,
          status: :completed,
          approval_status: :rejected
        },
        %{
          id: :obs_status_blocked,
          type: :observe,
          scenario_id: :leo_1,
          starts_at_s: 50.0,
          ends_at_s: 60.0,
          target_id: :target_a,
          status: :blocked_by_policy,
          approval_status: :approved
        }
      ])

    assert %{
             "activity_id" => "cmd_blocked_executed",
             "status" => "executed",
             "approval_status" => "blocked_by_policy",
             "required_operator_action" => "resolve_blocked_activity",
             "operator_action_reason" => "approval_status_blocked_by_policy"
           } = Enum.find(report["rows"], &(&1["activity_id"] == "cmd_blocked_executed"))

    assert %{
             "activity_id" => "dl_rejected_completed",
             "status" => "completed",
             "approval_status" => "rejected",
             "required_operator_action" => "resolve_rejected_activity",
             "operator_action_reason" => "approval_status_rejected"
           } = Enum.find(report["rows"], &(&1["activity_id"] == "dl_rejected_completed"))

    assert %{
             "activity_id" => "obs_status_blocked",
             "status" => "blocked_by_policy",
             "approval_status" => "approved",
             "required_operator_action" => "resolve_blocked_activity",
             "operator_action_reason" => "activity_status_blocked_by_policy"
           } = Enum.find(report["rows"], &(&1["activity_id"] == "obs_status_blocked"))

    assert report["executed_count"] == 2

    assert report["required_operator_action_counts"] == %{
             "resolve_blocked_activity" => 2,
             "resolve_rejected_activity" => 1
           }

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_operational_timeline_report(report)
    manifest = CadenceImport.from_operational_timeline_report(report)

    assert %{
             "activity_id" => "obs_status_blocked",
             "status" => "blocked_by_policy",
             "approval_status" => "approved",
             "required_operator_action" => "resolve_blocked_activity",
             "operator_action_reason" => "activity_status_blocked_by_policy",
             "source_operational_timeline" => %{
               "required_operator_action" => "resolve_blocked_activity",
               "operator_action_reason" => "activity_status_blocked_by_policy"
             }
           } = Enum.find(review["rows"], &(&1["activity_id"] == "obs_status_blocked"))

    assert %{
             "activity_id" => "obs_status_blocked",
             "status" => "blocked_by_policy",
             "approval_status" => "approved",
             "required_operator_action" => "resolve_blocked_activity",
             "operator_action_reason" => "activity_status_blocked_by_policy",
             "source_review_row" => %{
               "required_operator_action" => "resolve_blocked_activity",
               "operator_action_reason" => "activity_status_blocked_by_policy"
             }
           } = Enum.find(manifest["rows"], &(&1["activity_id"] == "obs_status_blocked"))

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "timeline diff treats blocked approval transitions as review-required approval blocks" do
    source = [
      %{
        id: :cmd_policy,
        type: :command,
        status: :planned,
        approval_status: :pending,
        metadata: %{timeline_id: :"timeline:cmd_policy"}
      }
    ]

    replacement = [
      %{
        id: :cmd_policy,
        type: :command,
        status: :planned,
        approval_status: :blocked_by_policy,
        metadata: %{timeline_id: :"timeline:cmd_policy"}
      }
    ]

    report = Timeline.diff_report(source, replacement)

    assert %{
             "timeline_id" => "timeline:cmd_policy",
             "diff_status" => "changed",
             "changed_fields" => ["approval_status"],
             "requires_operator_review" => true,
             "required_operator_action" => "review_timeline_change",
             "approval_transition" => %{
               "transition_category" => "approval_blocked",
               "requires_operator_review" => true,
               "operator_action_reason" => "approval_blocked_by_policy"
             }
           } = List.first(report["rows"])

    assert report["approval_transition_category_counts"] == %{"approval_blocked" => 1}
    assert report["transition_decision_counts"] == %{"review" => 1}

    assert {:ok, %{"schema_contract" => "timeline_diff_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "timeline diff treats blocked activity statuses as review-required status blocks" do
    source = [
      %{
        id: :obs_policy,
        type: :observe,
        status: :planned,
        approval_status: :not_required,
        metadata: %{timeline_id: :"timeline:obs_policy"}
      }
    ]

    replacement = [
      %{
        id: :obs_policy,
        type: :observe,
        status: :blocked_by_policy,
        approval_status: :not_required,
        metadata: %{timeline_id: :"timeline:obs_policy"}
      }
    ]

    report = Timeline.diff_report(source, replacement)

    assert %{
             "timeline_id" => "timeline:obs_policy",
             "diff_status" => "changed",
             "changed_fields" => ["status"],
             "requires_operator_review" => true,
             "required_operator_action" => "review_timeline_change",
             "status_transition" => %{
               "transition_category" => "status_blocked",
               "from_category" => "planned",
               "to_category" => "blocked",
               "requires_operator_review" => true,
               "operator_action_reason" => "activity_status_blocked_by_policy"
             }
           } = List.first(report["rows"])

    assert report["status_transition_category_counts"] == %{"status_blocked" => 1}
    assert report["transition_decision_counts"] == %{"review" => 1}

    assert {:ok, %{"schema_contract" => "timeline_diff_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_timeline_diff_report(report)
    manifest = CadenceImport.from_timeline_diff_report(report)

    assert %{
             "review_type" => "timeline_diff_review",
             "timeline_id" => "timeline:obs_policy",
             "required_operator_action" => "review_timeline_change",
             "operator_action_reason" => "activity_status_blocked_by_policy",
             "status_transition" => %{
               "transition_category" => "status_blocked",
               "operator_action_reason" => "activity_status_blocked_by_policy"
             },
             "source_timeline_diff" => %{
               "status_transition" => %{
                 "transition_category" => "status_blocked"
               }
             }
           } = List.first(review["rows"])

    assert %{
             "source_review_type" => "timeline_diff_review",
             "timeline_id" => "timeline:obs_policy",
             "import_action" => "review_timeline_diff",
             "required_operator_action" => "review_timeline_change",
             "operator_action_reason" => "activity_status_blocked_by_policy",
             "status_transition" => %{
               "transition_category" => "status_blocked",
               "operator_action_reason" => "activity_status_blocked_by_policy"
             },
             "source_review_row" => %{
               "status_transition" => %{
                 "transition_category" => "status_blocked"
               }
             }
           } = List.first(manifest["rows"])

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "rejects non-list activities" do
    assert_raise ArgumentError, ~r/activities must be a list/, fn ->
      Timeline.operational_report(%{})
    end

    assert_raise ArgumentError, ~r/source and replacement activities must be lists/, fn ->
      Timeline.diff_report([], %{})
    end
  end
end
