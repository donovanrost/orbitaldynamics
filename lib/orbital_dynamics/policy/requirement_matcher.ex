defmodule OrbitalDynamics.Policy.RequirementMatcher do
  @moduledoc false

  alias OrbitalDynamics.Policy.RequirementContext

  def match?(rule, requirement) do
    requirement_rule? =
      not is_nil(rule["action"]) or not is_nil(rule["actions"]) or
        not is_nil(rule["activity_type"]) or not is_nil(rule["activity_types"]) or
        not is_nil(rule["requirement_type"]) or not is_nil(rule["requirement_types"]) or
        not is_nil(rule["spacecraft_id"]) or not is_nil(rule["spacecraft_ids"]) or
        not is_nil(rule["target_id"]) or not is_nil(rule["target_ids"]) or
        not is_nil(rule["direction"]) or not is_nil(rule["directions"]) or
        not is_nil(rule["ground_station_id"]) or not is_nil(rule["ground_station_ids"]) or
        not is_nil(rule["station_availability"]) or
        not is_nil(rule["station_availabilities"]) or
        not is_nil(rule["station_contention_status"]) or
        not is_nil(rule["station_contention_statuses"]) or
        not is_nil(rule["station_reservation_id"]) or
        not is_nil(rule["station_reservation_ids"]) or
        not is_nil(rule["station_reserved_by"]) or
        not is_nil(rule["station_reserved_bys"]) or
        not is_nil(rule["station_reservation_status"]) or
        not is_nil(rule["station_reservation_statuses"]) or
        not is_nil(rule["station_reservation_match_status"]) or
        not is_nil(rule["station_reservation_match_statuses"]) or
        not is_nil(rule["station_calendar_entry_id"]) or
        not is_nil(rule["station_calendar_entry_ids"]) or
        not is_nil(rule["station_calendar_reserved_by"]) or
        not is_nil(rule["station_calendar_reserved_bys"]) or
        not is_nil(rule["station_calendar_reservation_status"]) or
        not is_nil(rule["station_calendar_reservation_statuses"]) or
        not is_nil(rule["station_calendar_status"]) or
        not is_nil(rule["station_calendar_statuses"]) or
        not is_nil(rule["station_calendar_entry_ambiguous"]) or
        not is_nil(rule["station_calendar_ambiguous_entry_id"]) or
        not is_nil(rule["station_calendar_ambiguous_entry_ids"]) or
        not is_nil(rule["station_calendar_ambiguous_entry_count_min"]) or
        not is_nil(rule["station_calendar_ambiguous_entry_count_max"]) or
        not is_nil(rule["contention_window_s_min"]) or
        not is_nil(rule["total_contact_duration_s_min"]) or
        not is_nil(rule["overlap_duration_s_min"]) or
        not is_nil(rule["max_concurrent_contacts_min"]) or
        not is_nil(rule["overlap_contact_pair_count_min"]) or
        not is_nil(rule["station_calendar_trust_boundary_status"]) or
        not is_nil(rule["station_calendar_trust_boundary_statuses"]) or
        not is_nil(rule["station_calendar_direction"]) or
        not is_nil(rule["station_calendar_directions"]) or
        not is_nil(rule["resource_scope"]) or not is_nil(rule["resource_scopes"]) or
        not is_nil(rule["selection_reason"]) or not is_nil(rule["selection_reasons"]) or
        not is_nil(rule["selected_priority_source"]) or
        not is_nil(rule["selected_priority_sources"]) or
        not is_nil(rule["priority_field_without_numeric_evidence"]) or
        not is_nil(rule["priority_fields_without_numeric_evidence_count_min"]) or
        not is_nil(rule["priority_fields_without_numeric_evidence"]) or
        not is_nil(rule["resolution_status"]) or not is_nil(rule["resolution_statuses"]) or
        not is_nil(rule["resolution_issue"]) or not is_nil(rule["resolution_issues"]) or
        not is_nil(rule["station_calendar_provider_id"]) or
        not is_nil(rule["station_calendar_provider_ids"]) or
        not is_nil(rule["station_calendar_provider_entry_id"]) or
        not is_nil(rule["station_calendar_provider_entry_ids"]) or
        not is_nil(rule["station_calendar_reservation_id"]) or
        not is_nil(rule["station_calendar_reservation_ids"]) or
        not is_nil(rule["required_operator_action"]) or
        not is_nil(rule["required_operator_actions"]) or
        not is_nil(rule["operator_action_reason"]) or
        not is_nil(rule["operator_action_reasons"]) or
        not is_nil(rule["allocation_status"]) or
        not is_nil(rule["allocation_statuses"]) or
        not is_nil(rule["effective_allocation_status"]) or
        not is_nil(rule["effective_allocation_statuses"]) or
        not is_nil(rule["allocation_reason"]) or
        not is_nil(rule["allocation_reasons"]) or
        not is_nil(rule["suppressed_reason"]) or
        not is_nil(rule["suppressed_reasons"]) or
        not is_nil(rule["resource_blocking_dimension"]) or
        not is_nil(rule["resource_blocking_dimensions"]) or
        not is_nil(rule["transition_decision"]) or
        not is_nil(rule["transition_decisions"]) or
        not is_nil(rule["application_status"]) or
        not is_nil(rule["application_statuses"]) or
        not is_nil(rule["planned_protection_decision"]) or
        not is_nil(rule["planned_protection_decisions"]) or
        not is_nil(rule["planned_protection_category"]) or
        not is_nil(rule["planned_protection_categories"]) or
        not is_nil(rule["timeline_integrity_status"]) or
        not is_nil(rule["timeline_integrity_statuses"]) or
        not is_nil(rule["timeline_integrity_issue_type"]) or
        not is_nil(rule["timeline_integrity_issue_types"]) or
        not is_nil(rule["source_timeline_integrity_status"]) or
        not is_nil(rule["source_timeline_integrity_statuses"]) or
        not is_nil(rule["source_timeline_integrity_issue_type"]) or
        not is_nil(rule["source_timeline_integrity_issue_types"]) or
        not is_nil(rule["replacement_timeline_integrity_status"]) or
        not is_nil(rule["replacement_timeline_integrity_statuses"]) or
        not is_nil(rule["replacement_timeline_integrity_issue_type"]) or
        not is_nil(rule["replacement_timeline_integrity_issue_types"]) or
        not is_nil(rule["source_protection_decision"]) or
        not is_nil(rule["source_protection_decisions"]) or
        not is_nil(rule["source_protection_category"]) or
        not is_nil(rule["source_protection_categories"]) or
        not is_nil(rule["replacement_protection_decision"]) or
        not is_nil(rule["replacement_protection_decisions"]) or
        not is_nil(rule["replacement_protection_category"]) or
        not is_nil(rule["replacement_protection_categories"]) or
        not is_nil(rule["review_queue"]) or not is_nil(rule["review_queues"]) or
        not is_nil(rule["review_queue_key"]) or not is_nil(rule["review_queue_keys"]) or
        not is_nil(rule["cadence_import_status"]) or
        not is_nil(rule["cadence_import_statuses"]) or
        not is_nil(rule["capacity_fraction_min"]) or
        not is_nil(rule["capacity_fraction_max"]) or
        not is_nil(rule["actual_completion_fraction_min"]) or
        not is_nil(rule["actual_completion_fraction_max"]) or
        not is_nil(rule["contact_success"]) or
        not is_nil(rule["contact_success_factor_min"]) or
        not is_nil(rule["contact_success_factor_max"]) or
        not is_nil(rule["contact_result"]) or not is_nil(rule["contact_results"]) or
        not is_nil(rule["command_success"]) or
        not is_nil(rule["command_success_factor_min"]) or
        not is_nil(rule["command_success_factor_max"]) or
        not is_nil(rule["command_result"]) or not is_nil(rule["command_results"]) or
        not is_nil(rule["observation_success_factor_min"]) or
        not is_nil(rule["observation_success_factor_max"]) or
        not is_nil(rule["observation_result"]) or
        not is_nil(rule["observation_results"]) or
        not is_nil(rule["maneuver_success_factor_min"]) or
        not is_nil(rule["maneuver_success_factor_max"]) or
        not is_nil(rule["maneuver_result"]) or not is_nil(rule["maneuver_results"]) or
        not is_nil(rule["status"]) or not is_nil(rule["statuses"]) or
        not is_nil(rule["approval_status"]) or not is_nil(rule["approval_statuses"]) or
        not is_nil(rule["policy_classification"]) or
        not is_nil(rule["policy_classifications"]) or
        not is_nil(rule["resource_pressure_status"]) or
        not is_nil(rule["resource_pressure_statuses"]) or
        not is_nil(rule["resource_pressure_type"]) or
        not is_nil(rule["resource_pressure_types"]) or
        not is_nil(rule["resource_source_quality"]) or
        not is_nil(rule["resource_source_qualities"]) or
        not is_nil(rule["resource_trust_boundary"]) or
        not is_nil(rule["resource_trust_boundaries"]) or
        not is_nil(rule["resource_trust_boundary_status"]) or
        not is_nil(rule["resource_trust_boundary_statuses"]) or
        not is_nil(rule["first_resource_pressure_kind"]) or
        not is_nil(rule["first_resource_pressure_kinds"]) or
        not is_nil(rule["feedback_source"]) or not is_nil(rule["feedback_sources"]) or
        not is_nil(rule["feedback_scope"]) or not is_nil(rule["feedback_scopes"]) or
        not is_nil(rule["trust_boundary"]) or not is_nil(rule["trust_boundaries"]) or
        not is_nil(rule["source_event_type"]) or not is_nil(rule["source_event_types"]) or
        not is_nil(rule["locked"]) or not is_nil(rule["degraded"]) or
        not is_nil(rule["payload_available"]) or not is_nil(rule["antenna_available"])

    action_match? =
      cond do
        not is_nil(rule["action"]) -> rule["action"] == requirement["action"]
        not is_nil(rule["actions"]) -> requirement["action"] in List.wrap(rule["actions"])
        true -> true
      end

    activity_type_match? =
      cond do
        not is_nil(rule["activity_type"]) ->
          rule["activity_type"] == requirement["activity_type"]

        not is_nil(rule["activity_types"]) ->
          requirement["activity_type"] in List.wrap(rule["activity_types"])

        true ->
          true
      end

    requirement_type_match? =
      cond do
        not is_nil(rule["requirement_type"]) ->
          rule["requirement_type"] == requirement["requirement_type"]

        not is_nil(rule["requirement_types"]) ->
          requirement["requirement_type"] in List.wrap(rule["requirement_types"])

        true ->
          true
      end

    spacecraft_match? =
      requirement_context_match?(
        rule,
        requirement,
        "spacecraft_id",
        "spacecraft_ids",
        "spacecraft_id"
      )

    target_match? =
      requirement_context_match?(rule, requirement, "target_id", "target_ids", "target_id")

    status_match? =
      requirement_context_match?(rule, requirement, "status", "statuses", "status")

    direction_match? =
      cond do
        not is_nil(rule["direction"]) ->
          rule["direction"] in RequirementContext.values(requirement, "direction")

        not is_nil(rule["directions"]) ->
          Enum.any?(
            RequirementContext.values(requirement, "direction"),
            &(&1 in List.wrap(rule["directions"]))
          )

        true ->
          true
      end

    ground_station_match? =
      requirement_context_match?(
        rule,
        requirement,
        "ground_station_id",
        "ground_station_ids",
        "ground_station_id"
      )

    approval_status_match? =
      requirement_context_match?(
        rule,
        requirement,
        "approval_status",
        "approval_statuses",
        "approval_status"
      )

    policy_classification_match? =
      requirement_context_match?(
        rule,
        requirement,
        "policy_classification",
        "policy_classifications",
        "policy_classification"
      )

    station_contention_status_match? =
      requirement_context_match?(
        rule,
        requirement,
        "station_contention_status",
        "station_contention_statuses",
        "station_contention_status"
      )

    station_availability_match? =
      requirement_context_match?(
        rule,
        requirement,
        "station_availability",
        "station_availabilities",
        "station_availability"
      )

    station_reservation_id_match? =
      requirement_context_match?(
        rule,
        requirement,
        "station_reservation_id",
        "station_reservation_ids",
        "station_reservation_id"
      )

    station_reserved_by_match? =
      requirement_context_match?(
        rule,
        requirement,
        "station_reserved_by",
        "station_reserved_bys",
        "station_reserved_by"
      )

    station_reservation_status_match? =
      requirement_context_match?(
        rule,
        requirement,
        "station_reservation_status",
        "station_reservation_statuses",
        "station_reservation_status"
      )

    station_reservation_match_status_match? =
      requirement_context_match?(
        rule,
        requirement,
        "station_reservation_match_status",
        "station_reservation_match_statuses",
        "station_reservation_match_status"
      )

    station_calendar_reserved_by_match? =
      requirement_context_match?(
        rule,
        requirement,
        "station_calendar_reserved_by",
        "station_calendar_reserved_bys",
        "station_calendar_reserved_by"
      )

    station_calendar_reservation_status_match? =
      requirement_context_match?(
        rule,
        requirement,
        "station_calendar_reservation_status",
        "station_calendar_reservation_statuses",
        "station_calendar_reservation_status"
      )

    station_calendar_status_match? =
      requirement_context_match?(
        rule,
        requirement,
        "station_calendar_status",
        "station_calendar_statuses",
        "station_calendar_status"
      )

    station_calendar_entry_match? =
      requirement_context_match?(
        rule,
        requirement,
        "station_calendar_entry_id",
        "station_calendar_entry_ids",
        "station_calendar_entry_id"
      )

    station_calendar_entry_ambiguous_match? =
      if is_nil(rule["station_calendar_entry_ambiguous"]) do
        true
      else
        rule["station_calendar_entry_ambiguous"] ==
          RequirementContext.value(requirement, "station_calendar_entry_ambiguous")
      end

    station_calendar_ambiguous_entry_match? =
      requirement_context_match?(
        rule,
        requirement,
        "station_calendar_ambiguous_entry_id",
        "station_calendar_ambiguous_entry_ids",
        "station_calendar_ambiguous_entry_id"
      )

    station_calendar_ambiguous_entry_count_match? =
      non_negative_integer_range_match?(
        RequirementContext.value(requirement, "station_calendar_ambiguous_entry_count"),
        rule["station_calendar_ambiguous_entry_count_min"],
        rule["station_calendar_ambiguous_entry_count_max"]
      )

    contention_window_s_match? =
      non_negative_number_min_match?(
        RequirementContext.value(requirement, "contention_window_s"),
        rule["contention_window_s_min"]
      )

    total_contact_duration_s_match? =
      non_negative_number_min_match?(
        RequirementContext.value(requirement, "total_contact_duration_s"),
        rule["total_contact_duration_s_min"]
      )

    overlap_duration_s_match? =
      non_negative_number_min_match?(
        RequirementContext.value(requirement, "overlap_duration_s"),
        rule["overlap_duration_s_min"]
      )

    max_concurrent_contacts_match? =
      non_negative_integer_range_match?(
        RequirementContext.value(requirement, "max_concurrent_contacts"),
        rule["max_concurrent_contacts_min"],
        nil
      )

    overlap_contact_pair_count_match? =
      non_negative_integer_range_match?(
        RequirementContext.value(requirement, "overlap_contact_pair_count"),
        rule["overlap_contact_pair_count_min"],
        nil
      )

    station_calendar_trust_boundary_status_match? =
      requirement_context_match?(
        rule,
        requirement,
        "station_calendar_trust_boundary_status",
        "station_calendar_trust_boundary_statuses",
        "station_calendar_trust_boundary_status"
      )

    station_calendar_direction_match? =
      requirement_context_match?(
        rule,
        requirement,
        "station_calendar_direction",
        "station_calendar_directions",
        "station_calendar_direction"
      )

    resource_scope_match? =
      requirement_context_match?(
        rule,
        requirement,
        "resource_scope",
        "resource_scopes",
        "resource_scope"
      )

    selection_reason_match? =
      requirement_context_match?(
        rule,
        requirement,
        "selection_reason",
        "selection_reasons",
        "selection_reason"
      )

    selected_priority_source_match? =
      requirement_context_match?(
        rule,
        requirement,
        "selected_priority_source",
        "selected_priority_sources",
        "selected_priority_source"
      )

    priority_field_without_numeric_evidence_match? =
      requirement_context_match?(
        rule,
        requirement,
        "priority_field_without_numeric_evidence",
        "priority_fields_without_numeric_evidence",
        "priority_fields_without_numeric_evidence"
      )

    priority_fields_without_numeric_evidence_count_match? =
      non_negative_integer_range_match?(
        RequirementContext.value(requirement, "priority_fields_without_numeric_evidence_count"),
        rule["priority_fields_without_numeric_evidence_count_min"],
        nil
      )

    resolution_status_match? =
      requirement_context_match?(
        rule,
        requirement,
        "resolution_status",
        "resolution_statuses",
        "resolution_status"
      )

    resolution_issue_match? =
      requirement_context_match?(
        rule,
        requirement,
        "resolution_issue",
        "resolution_issues",
        "resolution_issue"
      )

    station_calendar_provider_match? =
      requirement_context_match?(
        rule,
        requirement,
        "station_calendar_provider_id",
        "station_calendar_provider_ids",
        "station_calendar_provider_id"
      )

    station_calendar_provider_entry_match? =
      requirement_context_match?(
        rule,
        requirement,
        "station_calendar_provider_entry_id",
        "station_calendar_provider_entry_ids",
        "station_calendar_provider_entry_id"
      )

    station_calendar_reservation_match? =
      requirement_context_match?(
        rule,
        requirement,
        "station_calendar_reservation_id",
        "station_calendar_reservation_ids",
        "station_calendar_reservation_id"
      )

    required_operator_action_match? =
      requirement_context_match?(
        rule,
        requirement,
        "required_operator_action",
        "required_operator_actions",
        "required_operator_action"
      )

    operator_action_reason_match? =
      requirement_context_match?(
        rule,
        requirement,
        "operator_action_reason",
        "operator_action_reasons",
        "operator_action_reason"
      )

    allocation_status_match? =
      requirement_context_match?(
        rule,
        requirement,
        "allocation_status",
        "allocation_statuses",
        "allocation_status"
      )

    effective_allocation_status_match? =
      requirement_context_match?(
        rule,
        requirement,
        "effective_allocation_status",
        "effective_allocation_statuses",
        "effective_allocation_status"
      )

    allocation_reason_match? =
      requirement_context_match?(
        rule,
        requirement,
        "allocation_reason",
        "allocation_reasons",
        "allocation_reason"
      )

    suppressed_reason_match? =
      requirement_context_match?(
        rule,
        requirement,
        "suppressed_reason",
        "suppressed_reasons",
        "suppressed_reason"
      )

    resource_blocking_dimension_match? =
      requirement_context_match?(
        rule,
        requirement,
        "resource_blocking_dimension",
        "resource_blocking_dimensions",
        "resource_blocking_dimension"
      )

    transition_decision_match? =
      requirement_context_match?(
        rule,
        requirement,
        "transition_decision",
        "transition_decisions",
        "transition_decision"
      )

    application_status_match? =
      requirement_context_match?(
        rule,
        requirement,
        "application_status",
        "application_statuses",
        "application_status"
      )

    planned_protection_decision_match? =
      requirement_context_match?(
        rule,
        requirement,
        "planned_protection_decision",
        "planned_protection_decisions",
        "planned_protection_decision"
      )

    planned_protection_category_match? =
      requirement_context_match?(
        rule,
        requirement,
        "planned_protection_category",
        "planned_protection_categories",
        "planned_protection_category"
      )

    timeline_integrity_status_match? =
      requirement_context_match?(
        rule,
        requirement,
        "timeline_integrity_status",
        "timeline_integrity_statuses",
        "timeline_integrity_status"
      )

    timeline_integrity_issue_type_match? =
      requirement_context_match?(
        rule,
        requirement,
        "timeline_integrity_issue_type",
        "timeline_integrity_issue_types",
        "timeline_integrity_issue_types"
      )

    source_timeline_integrity_status_match? =
      requirement_context_match?(
        rule,
        requirement,
        "source_timeline_integrity_status",
        "source_timeline_integrity_statuses",
        "source_timeline_integrity_status"
      )

    source_timeline_integrity_issue_type_match? =
      requirement_context_match?(
        rule,
        requirement,
        "source_timeline_integrity_issue_type",
        "source_timeline_integrity_issue_types",
        "source_timeline_integrity_issue_types"
      )

    replacement_timeline_integrity_status_match? =
      requirement_context_match?(
        rule,
        requirement,
        "replacement_timeline_integrity_status",
        "replacement_timeline_integrity_statuses",
        "replacement_timeline_integrity_status"
      )

    replacement_timeline_integrity_issue_type_match? =
      requirement_context_match?(
        rule,
        requirement,
        "replacement_timeline_integrity_issue_type",
        "replacement_timeline_integrity_issue_types",
        "replacement_timeline_integrity_issue_types"
      )

    source_protection_decision_match? =
      requirement_context_match?(
        rule,
        requirement,
        "source_protection_decision",
        "source_protection_decisions",
        "source_protection_decision"
      )

    source_protection_category_match? =
      requirement_context_match?(
        rule,
        requirement,
        "source_protection_category",
        "source_protection_categories",
        "source_protection_category"
      )

    replacement_protection_decision_match? =
      requirement_context_match?(
        rule,
        requirement,
        "replacement_protection_decision",
        "replacement_protection_decisions",
        "replacement_protection_decision"
      )

    replacement_protection_category_match? =
      requirement_context_match?(
        rule,
        requirement,
        "replacement_protection_category",
        "replacement_protection_categories",
        "replacement_protection_category"
      )

    review_queue_match? =
      requirement_context_match?(
        rule,
        requirement,
        "review_queue",
        "review_queues",
        "review_queue"
      )

    review_queue_key_match? =
      requirement_context_match?(
        rule,
        requirement,
        "review_queue_key",
        "review_queue_keys",
        "review_queue_key"
      )

    cadence_import_status_match? =
      requirement_context_match?(
        rule,
        requirement,
        "cadence_import_status",
        "cadence_import_statuses",
        "cadence_import_status"
      )

    capacity_fraction_match? =
      capacity_fraction_match?(
        RequirementContext.value(requirement, "capacity_fraction"),
        rule["capacity_fraction_min"],
        rule["capacity_fraction_max"]
      )

    actual_completion_fraction_match? =
      capacity_fraction_match?(
        RequirementContext.value(requirement, "actual_completion_fraction"),
        rule["actual_completion_fraction_min"],
        rule["actual_completion_fraction_max"]
      )

    contact_success_match? =
      if is_nil(rule["contact_success"]) do
        true
      else
        rule["contact_success"] == RequirementContext.value(requirement, "contact_success")
      end

    contact_success_factor_match? =
      capacity_fraction_match?(
        RequirementContext.value(requirement, "contact_success_factor"),
        rule["contact_success_factor_min"],
        rule["contact_success_factor_max"]
      )

    contact_result_match? =
      provider_result_match?(rule, requirement, "contact_result", "contact_results")

    command_success_match? =
      if is_nil(rule["command_success"]) do
        true
      else
        rule["command_success"] == RequirementContext.value(requirement, "command_success")
      end

    command_success_factor_match? =
      capacity_fraction_match?(
        RequirementContext.value(requirement, "command_success_factor"),
        rule["command_success_factor_min"],
        rule["command_success_factor_max"]
      )

    command_result_match? =
      provider_result_match?(rule, requirement, "command_result", "command_results")

    observation_success_factor_match? =
      capacity_fraction_match?(
        RequirementContext.value(requirement, "observation_success_factor"),
        rule["observation_success_factor_min"],
        rule["observation_success_factor_max"]
      )

    observation_result_match? =
      provider_result_match?(rule, requirement, "observation_result", "observation_results")

    maneuver_success_factor_match? =
      capacity_fraction_match?(
        RequirementContext.value(requirement, "maneuver_success_factor"),
        rule["maneuver_success_factor_min"],
        rule["maneuver_success_factor_max"]
      )

    maneuver_result_match? =
      provider_result_match?(rule, requirement, "maneuver_result", "maneuver_results")

    resource_pressure_status_match? =
      requirement_context_match?(
        rule,
        requirement,
        "resource_pressure_status",
        "resource_pressure_statuses",
        "resource_pressure_status"
      )

    resource_pressure_type_match? =
      requirement_context_match?(
        rule,
        requirement,
        "resource_pressure_type",
        "resource_pressure_types",
        "resource_pressure_types"
      )

    resource_source_quality_match? =
      requirement_context_match?(
        rule,
        requirement,
        "resource_source_quality",
        "resource_source_qualities",
        "resource_source_quality"
      )

    resource_trust_boundary_match? =
      requirement_context_match?(
        rule,
        requirement,
        "resource_trust_boundary",
        "resource_trust_boundaries",
        "resource_trust_boundary"
      )

    resource_trust_boundary_status_match? =
      requirement_context_match?(
        rule,
        requirement,
        "resource_trust_boundary_status",
        "resource_trust_boundary_statuses",
        "resource_trust_boundary_status"
      )

    first_resource_pressure_kind_match? =
      requirement_context_match?(
        rule,
        requirement,
        "first_resource_pressure_kind",
        "first_resource_pressure_kinds",
        "first_resource_pressure_kind"
      )

    feedback_source_match? =
      requirement_context_match?(
        rule,
        requirement,
        "feedback_source",
        "feedback_sources",
        "feedback_source"
      )

    feedback_scope_match? =
      requirement_context_match?(
        rule,
        requirement,
        "feedback_scope",
        "feedback_scopes",
        "feedback_scope"
      )

    trust_boundary_match? =
      requirement_context_match?(
        rule,
        requirement,
        "trust_boundary",
        "trust_boundaries",
        "trust_boundary"
      )

    source_event_type_match? =
      requirement_context_match?(
        rule,
        requirement,
        "source_event_type",
        "source_event_types",
        "source_event_type"
      )

    locked_match? =
      if is_nil(rule["locked"]) do
        true
      else
        rule["locked"] == RequirementContext.value(requirement, "locked")
      end

    degraded_match? =
      if is_nil(rule["degraded"]) do
        true
      else
        rule["degraded"] == RequirementContext.value(requirement, "degraded")
      end

    payload_available_match? =
      if is_nil(rule["payload_available"]) do
        true
      else
        rule["payload_available"] == RequirementContext.value(requirement, "payload_available")
      end

    antenna_available_match? =
      if is_nil(rule["antenna_available"]) do
        true
      else
        rule["antenna_available"] == RequirementContext.value(requirement, "antenna_available")
      end

    requirement_rule? and action_match? and activity_type_match? and requirement_type_match? and
      spacecraft_match? and target_match? and direction_match? and ground_station_match? and
      status_match? and approval_status_match? and policy_classification_match? and
      station_availability_match? and
      station_contention_status_match? and station_reservation_id_match? and
      station_reserved_by_match? and station_reservation_status_match? and
      station_reservation_match_status_match? and
      station_calendar_reserved_by_match? and station_calendar_reservation_status_match? and
      station_calendar_status_match? and
      station_calendar_entry_match? and
      station_calendar_entry_ambiguous_match? and
      station_calendar_ambiguous_entry_match? and
      station_calendar_ambiguous_entry_count_match? and
      contention_window_s_match? and total_contact_duration_s_match? and
      overlap_duration_s_match? and max_concurrent_contacts_match? and
      overlap_contact_pair_count_match? and
      station_calendar_trust_boundary_status_match? and
      station_calendar_direction_match? and
      resource_scope_match? and selection_reason_match? and selected_priority_source_match? and
      priority_field_without_numeric_evidence_match? and
      priority_fields_without_numeric_evidence_count_match? and
      resolution_status_match? and resolution_issue_match? and station_calendar_provider_match? and
      station_calendar_provider_entry_match? and station_calendar_reservation_match? and
      required_operator_action_match? and operator_action_reason_match? and
      allocation_status_match? and effective_allocation_status_match? and allocation_reason_match? and
      suppressed_reason_match? and resource_blocking_dimension_match? and
      transition_decision_match? and application_status_match? and
      planned_protection_decision_match? and planned_protection_category_match? and
      timeline_integrity_status_match? and timeline_integrity_issue_type_match? and
      source_timeline_integrity_status_match? and
      source_timeline_integrity_issue_type_match? and
      replacement_timeline_integrity_status_match? and
      replacement_timeline_integrity_issue_type_match? and
      source_protection_decision_match? and source_protection_category_match? and
      replacement_protection_decision_match? and replacement_protection_category_match? and
      review_queue_match? and review_queue_key_match? and
      cadence_import_status_match? and
      capacity_fraction_match? and actual_completion_fraction_match? and contact_success_match? and
      contact_success_factor_match? and
      contact_result_match? and
      command_success_match? and command_success_factor_match? and command_result_match? and
      observation_success_factor_match? and observation_result_match? and
      maneuver_success_factor_match? and maneuver_result_match? and locked_match? and
      resource_pressure_status_match? and resource_pressure_type_match? and
      resource_source_quality_match? and resource_trust_boundary_match? and
      resource_trust_boundary_status_match? and first_resource_pressure_kind_match? and
      feedback_source_match? and feedback_scope_match? and trust_boundary_match? and
      source_event_type_match? and
      degraded_match? and payload_available_match? and antenna_available_match?
  end

  defp requirement_context_match?(
         rule,
         requirement,
         singular_rule_field,
         plural_rule_field,
         field
       ) do
    cond do
      not is_nil(rule[singular_rule_field]) ->
        rule_values = List.wrap(rule[singular_rule_field])

        Enum.any?(
          RequirementContext.values(requirement, field),
          &(&1 in rule_values)
        )

      not is_nil(rule[plural_rule_field]) ->
        Enum.any?(
          RequirementContext.values(requirement, field),
          &(&1 in List.wrap(rule[plural_rule_field]))
        )

      true ->
        true
    end
  end

  defp provider_result_match?(rule, requirement, singular_rule_field, plural_rule_field) do
    cond do
      not is_nil(rule[singular_rule_field]) ->
        RequirementContext.normalize_provider_result_token(rule[singular_rule_field]) in RequirementContext.values(
          requirement,
          singular_rule_field
        )

      not is_nil(rule[plural_rule_field]) ->
        rule_values =
          rule[plural_rule_field]
          |> List.wrap()
          |> Enum.map(&RequirementContext.normalize_provider_result_token/1)
          |> Enum.reject(&(&1 in [nil, ""]))

        Enum.any?(
          RequirementContext.values(requirement, singular_rule_field),
          &(&1 in rule_values)
        )

      true ->
        true
    end
  end

  defp capacity_fraction_match?(_value, nil, nil), do: true

  defp capacity_fraction_match?(value, min_value, max_value) when is_number(value) do
    min_match? = is_nil(min_value) or value >= min_value
    max_match? = is_nil(max_value) or value <= max_value
    min_match? and max_match?
  end

  defp capacity_fraction_match?(_value, _min_value, _max_value), do: false

  defp non_negative_number_min_match?(_value, nil), do: true

  defp non_negative_number_min_match?(value, min_value)
       when is_number(value) and value >= 0.0 and is_number(min_value) do
    value >= min_value
  end

  defp non_negative_number_min_match?(_value, _min_value), do: false

  defp non_negative_integer_range_match?(_value, nil, nil), do: true

  defp non_negative_integer_range_match?(value, min_value, max_value)
       when is_integer(value) and value >= 0 do
    min_match? = is_nil(min_value) or value >= min_value
    max_match? = is_nil(max_value) or value <= max_value
    min_match? and max_match?
  end

  defp non_negative_integer_range_match?(_value, _min_value, _max_value), do: false
end
