defmodule OrbitalDynamics.Schema.PolicyFieldGroups do
  @moduledoc false

  @string_fields [
    "action",
    "activity_type",
    "requirement_type",
    "risk_type",
    "risk_reason",
    "event_type",
    "feasibility_status",
    "direction",
    "spacecraft_id",
    "target_id",
    "ground_station_id",
    "station_id",
    "station_availability",
    "station_contention_status",
    "station_reservation_id",
    "station_reserved_by",
    "station_reservation_status",
    "station_reservation_match_status",
    "station_calendar_reservation_status",
    "station_calendar_ambiguous_entry_id",
    "station_calendar_trust_boundary_status",
    "station_calendar_direction",
    "resource_scope",
    "selection_reason",
    "selected_priority_source",
    "priority_field_without_numeric_evidence",
    "resolution_status",
    "resolution_issue",
    "station_calendar_provider_id",
    "station_calendar_provider_entry_id",
    "station_calendar_reservation_id",
    "required_operator_action",
    "operator_action_reason",
    "allocation_status",
    "effective_allocation_status",
    "allocation_reason",
    "suppressed_reason",
    "resource_blocking_dimension",
    "transition_decision",
    "application_status",
    "planned_protection_decision",
    "planned_protection_category",
    "timeline_integrity_status",
    "timeline_integrity_issue_type",
    "source_timeline_integrity_status",
    "source_timeline_integrity_issue_type",
    "replacement_timeline_integrity_status",
    "replacement_timeline_integrity_issue_type",
    "source_protection_decision",
    "source_protection_category",
    "replacement_protection_decision",
    "replacement_protection_category",
    "review_queue",
    "review_queue_key",
    "cadence_import_status",
    "status",
    "approval_status",
    "policy_classification",
    "contact_success_factor_source",
    "contact_result",
    "command_success_factor_source",
    "command_result",
    "observation_success_factor_source",
    "observation_result",
    "maneuver_success_factor_source",
    "maneuver_result",
    "resource_pressure_status",
    "resource_pressure_type",
    "resource_source_quality",
    "resource_trust_boundary",
    "resource_trust_boundary_status",
    "first_resource_pressure_kind",
    "feedback_source",
    "feedback_scope",
    "trust_boundary",
    "source_event_type"
  ]

  @string_array_fields [
    "actions",
    "activity_types",
    "requirement_types",
    "risk_types",
    "event_types",
    "directions",
    "spacecraft_ids",
    "target_ids",
    "ground_station_ids",
    "station_ids",
    "station_availabilities",
    "station_contention_statuses",
    "station_reservation_ids",
    "station_reserved_bys",
    "station_reservation_statuses",
    "station_reservation_match_statuses",
    "station_calendar_reserved_bys",
    "station_calendar_reservation_statuses",
    "station_calendar_ambiguous_entry_ids",
    "station_calendar_trust_boundary_statuses",
    "station_calendar_directions",
    "resource_scopes",
    "selection_reasons",
    "selected_priority_sources",
    "priority_fields_without_numeric_evidence",
    "resolution_statuses",
    "resolution_issues",
    "station_calendar_provider_ids",
    "station_calendar_provider_entry_ids",
    "station_calendar_reservation_ids",
    "required_operator_actions",
    "operator_action_reasons",
    "allocation_statuses",
    "effective_allocation_statuses",
    "allocation_reasons",
    "suppressed_reasons",
    "resource_blocking_dimensions",
    "transition_decisions",
    "application_statuses",
    "planned_protection_decisions",
    "planned_protection_categories",
    "timeline_integrity_statuses",
    "timeline_integrity_issue_types",
    "source_timeline_integrity_statuses",
    "source_timeline_integrity_issue_types",
    "replacement_timeline_integrity_statuses",
    "replacement_timeline_integrity_issue_types",
    "source_protection_decisions",
    "source_protection_categories",
    "replacement_protection_decisions",
    "replacement_protection_categories",
    "review_queues",
    "review_queue_keys",
    "cadence_import_statuses",
    "statuses",
    "approval_statuses",
    "policy_classifications",
    "contact_results",
    "command_results",
    "observation_results",
    "maneuver_results",
    "resource_pressure_statuses",
    "resource_pressure_types",
    "resource_source_qualities",
    "resource_trust_boundaries",
    "resource_trust_boundary_statuses",
    "first_resource_pressure_kinds",
    "feedback_sources",
    "feedback_scopes",
    "trust_boundaries",
    "source_event_types"
  ]

  @string_or_array_fields ["station_calendar_reserved_by"]

  @number_fields [
    "capacity_fraction",
    "station_reservation_expires_at_s",
    "required_capacity_fraction",
    "actual_completion_fraction",
    "actual_downlink_completion_ratio",
    "contention_window_s",
    "total_contact_duration_s",
    "overlap_duration_s",
    "max_concurrent_contacts",
    "overlap_contact_pair_count",
    "contact_success_factor",
    "command_success_factor",
    "observation_success_factor",
    "maneuver_success_factor"
  ]

  @integer_fields [
    "station_calendar_ambiguous_entry_count",
    "priority_fields_without_numeric_evidence_count"
  ]

  @non_negative_integer_fields [
    "max_concurrent_contacts",
    "overlap_contact_pair_count",
    "station_calendar_ambiguous_entry_count",
    "priority_fields_without_numeric_evidence_count"
  ]

  @boolean_fields [
    "station_calendar_entry_ambiguous",
    "locked",
    "degraded",
    "payload_available",
    "antenna_available",
    "contact_success",
    "command_success"
  ]

  @action_rule_number_fields [
    "capacity_fraction_min",
    "capacity_fraction_max",
    "actual_completion_fraction_min",
    "actual_completion_fraction_max",
    "contact_success_factor_min",
    "contact_success_factor_max",
    "command_success_factor_min",
    "command_success_factor_max",
    "observation_success_factor_min",
    "observation_success_factor_max",
    "maneuver_success_factor_min",
    "maneuver_success_factor_max",
    "contention_window_s_min",
    "total_contact_duration_s_min",
    "overlap_duration_s_min"
  ]

  @action_rule_integer_fields [
    "station_calendar_ambiguous_entry_count_min",
    "station_calendar_ambiguous_entry_count_max",
    "max_concurrent_contacts_min",
    "overlap_contact_pair_count_min",
    "priority_fields_without_numeric_evidence_count_min"
  ]

  def json_schema do
    %{
      string: @string_fields,
      string_array: @string_array_fields,
      string_or_array: @string_or_array_fields,
      number: @number_fields,
      integer: @integer_fields,
      non_negative_integer: @non_negative_integer_fields,
      boolean: @boolean_fields
    }
  end

  def rule_match do
    [
      string_fields: @string_fields,
      string_array_fields: @string_array_fields,
      string_or_array_fields: @string_or_array_fields,
      number_fields: @number_fields,
      integer_fields: @integer_fields,
      boolean_fields: @boolean_fields
    ]
  end

  def action_rule do
    [
      string_fields: @string_fields,
      string_array_fields: @string_array_fields,
      string_or_array_fields: @string_or_array_fields,
      number_fields: @action_rule_number_fields,
      integer_fields: @action_rule_integer_fields,
      boolean_fields: @boolean_fields
    ]
  end
end
