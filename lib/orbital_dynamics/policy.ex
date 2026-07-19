defmodule OrbitalDynamics.Policy do
  @moduledoc """
  Shared policy classification for planning artifacts.

  The module returns artifact rows only. It does not approve, schedule, or
  execute operational work; it classifies planner recommendations so Cadence and
  operators can see which rule or fallback boundary was applied.
  """

  alias OrbitalDynamics.Policy.RequirementContext

  @classifications ["auto_approvable", "operator_review_required", "blocked_by_policy"]
  @stable_id_pattern ~r/^[A-Za-z0-9][A-Za-z0-9._:@-]*$/
  @default_blocked_risk_types ["spacecraft_degraded_unprotected", "no_viable_downlink"]
  @unit_interval_rule_fields ~w(
    capacity_fraction_min
    capacity_fraction_max
    actual_completion_fraction_min
    actual_completion_fraction_max
    contact_success_factor_min
    contact_success_factor_max
    command_success_factor_min
    command_success_factor_max
    observation_success_factor_min
    observation_success_factor_max
    maneuver_success_factor_min
    maneuver_success_factor_max
  )
  @non_negative_number_rule_fields ~w(
    contention_window_s_min
    total_contact_duration_s_min
    overlap_duration_s_min
  )
  @non_negative_integer_rule_fields ~w(
    station_calendar_ambiguous_entry_count_min
    station_calendar_ambiguous_entry_count_max
    max_concurrent_contacts_min
    overlap_contact_pair_count_min
    priority_fields_without_numeric_evidence_count_min
  )
  @boolean_rule_fields ~w(
    contact_success
    command_success
    station_calendar_entry_ambiguous
    locked
    degraded
    payload_available
    antenna_available
  )
  @string_rule_fields ~w(
    action
    activity_type
    requirement_type
    risk_type
    spacecraft_id
    target_id
    event_type
    feasibility_status
    direction
    ground_station_id
    station_id
    station_availability
    station_contention_status
    station_reservation_id
    station_reserved_by
    station_reservation_status
    station_reservation_match_status
    station_calendar_entry_id
    station_calendar_reserved_by
    station_calendar_reservation_status
    station_calendar_status
    station_calendar_ambiguous_entry_id
    station_calendar_trust_boundary_status
    station_calendar_direction
    resource_scope
    selection_reason
    selected_priority_source
    contact_result
    command_result
    observation_result
    maneuver_result
    priority_field_without_numeric_evidence
    resolution_status
    resolution_issue
    station_calendar_provider_id
    station_calendar_provider_entry_id
    station_calendar_reservation_id
    required_operator_action
    operator_action_reason
    allocation_status
    effective_allocation_status
    allocation_reason
    suppressed_reason
    resource_blocking_dimension
    transition_decision
    application_status
    planned_protection_decision
    planned_protection_category
    timeline_integrity_status
    timeline_integrity_issue_type
    source_timeline_integrity_status
    source_timeline_integrity_issue_type
    replacement_timeline_integrity_status
    replacement_timeline_integrity_issue_type
    source_protection_decision
    source_protection_category
    replacement_protection_decision
    replacement_protection_category
    review_queue
    review_queue_key
    cadence_import_status
    status
    approval_status
    policy_classification
    resource_pressure_status
    resource_pressure_type
    resource_source_quality
    resource_trust_boundary
    resource_trust_boundary_status
    first_resource_pressure_kind
    feedback_source
    feedback_scope
    trust_boundary
    source_event_type
    escalation_level
    escalation_queue
    escalation_role
    required_authority
    reason
  )
  @string_list_rule_fields ~w(
    actions
    activity_types
    requirement_types
    risk_types
    spacecraft_ids
    target_ids
    event_types
    directions
    ground_station_ids
    station_ids
    station_availabilities
    station_contention_statuses
    station_reservation_ids
    station_reserved_bys
    station_reservation_statuses
    station_reservation_match_statuses
    station_calendar_entry_ids
    station_calendar_reserved_bys
    station_calendar_reservation_statuses
    station_calendar_statuses
    station_calendar_ambiguous_entry_ids
    station_calendar_trust_boundary_statuses
    station_calendar_directions
    resource_scopes
    selection_reasons
    selected_priority_sources
    contact_results
    command_results
    observation_results
    maneuver_results
    priority_fields_without_numeric_evidence
    resolution_statuses
    resolution_issues
    station_calendar_provider_ids
    station_calendar_provider_entry_ids
    station_calendar_reservation_ids
    required_operator_actions
    operator_action_reasons
    allocation_statuses
    effective_allocation_statuses
    allocation_reasons
    suppressed_reasons
    resource_blocking_dimensions
    transition_decisions
    application_statuses
    planned_protection_decisions
    planned_protection_categories
    timeline_integrity_statuses
    timeline_integrity_issue_types
    source_timeline_integrity_statuses
    source_timeline_integrity_issue_types
    replacement_timeline_integrity_statuses
    replacement_timeline_integrity_issue_types
    source_protection_decisions
    source_protection_categories
    replacement_protection_decisions
    replacement_protection_categories
    review_queues
    review_queue_keys
    cadence_import_statuses
    statuses
    approval_statuses
    policy_classifications
    resource_pressure_statuses
    resource_pressure_types
    resource_source_qualities
    resource_trust_boundaries
    resource_trust_boundary_statuses
    first_resource_pressure_kinds
    feedback_sources
    feedback_scopes
    trust_boundaries
    source_event_types
  )
  @default_approval_policy %{
    "auto_approvable_risk_limit" => 0,
    "auto_approvable_approval_count_limit" => 0,
    "operator_review_risk_limit" => 3,
    "blocked_risk_types" => @default_blocked_risk_types,
    "action_rules" => []
  }
  @escalation_fields [
    "escalation_level",
    "escalation_queue",
    "escalation_role",
    "required_authority",
    "sla_s"
  ]
  @policy_bundles %{
    "default_v1" => %{
      "schema_contract" => "policy_bundle.v1",
      "id" => "default_v1",
      "description" => "Default artifact-only branch approval fallback policy.",
      "approval_policy" => @default_approval_policy
    },
    "contact_command_review_v1" => %{
      "schema_contract" => "policy_bundle.v1",
      "id" => "contact_command_review_v1",
      "description" =>
        "Require operator review for contact schedule and command review boundaries.",
      "approval_policy" => %{
        "auto_approvable_risk_limit" => 0,
        "auto_approvable_approval_count_limit" => 0,
        "operator_review_risk_limit" => 2,
        "blocked_risk_types" => @default_blocked_risk_types,
        "action_rules" => [
          %{
            "id" => "contact_schedule_review",
            "requirement_types" => ["contact_schedule_change", "downstream_window_review"],
            "classification" => "operator_review_required",
            "reason" => "contact schedule changes require operator review"
          },
          %{
            "id" => "command_health_review",
            "requirement_types" => ["command_review", "health_check_review"],
            "classification" => "operator_review_required",
            "reason" => "command and health-review boundaries require operator review"
          },
          %{
            "id" => "invalid_contact_intent_input_review",
            "activity_types" => ["invalid_activity_input"],
            "actions" => ["review_invalid_activity_input"],
            "requirement_types" => ["operator_review"],
            "classification" => "operator_review_required",
            "reason" => "invalid contact-intent inputs require operator review"
          }
        ]
      }
    },
    "command_contact_authority_v1" => %{
      "schema_contract" => "policy_bundle.v1",
      "id" => "command_contact_authority_v1",
      "description" =>
        "Classify command, uplink, tracking, and downlink contact authority boundaries by direction.",
      "approval_policy" => %{
        "auto_approvable_risk_limit" => 0,
        "auto_approvable_approval_count_limit" => 0,
        "operator_review_risk_limit" => 2,
        "blocked_risk_types" => @default_blocked_risk_types,
        "action_rules" => [
          %{
            "id" => "command_uplink_authority_review",
            "directions" => ["command", "uplink"],
            "requirement_types" => [
              "command_review",
              "contact_schedule_change",
              "downstream_window_review"
            ],
            "classification" => "operator_review_required",
            "reason" => "command and uplink windows require command authority review",
            "escalation_level" => "shift_lead",
            "escalation_queue" => "mission_operations",
            "escalation_role" => "command_authority",
            "required_authority" => "command_authority",
            "sla_s" => 900
          },
          %{
            "id" => "failed_command_success_review",
            "requirement_types" => ["command_review", "health_check_review"],
            "command_success" => false,
            "classification" => "operator_review_required",
            "reason" => "failed command execution evidence requires command authority review",
            "escalation_level" => "shift_lead",
            "escalation_queue" => "mission_operations",
            "escalation_role" => "command_authority",
            "required_authority" => "command_authority",
            "sla_s" => 600
          },
          %{
            "id" => "low_command_success_confidence_review",
            "requirement_types" => ["command_review", "health_check_review"],
            "command_success_factor_max" => 0.8,
            "classification" => "operator_review_required",
            "reason" => "low command success confidence requires command authority review",
            "escalation_level" => "shift_lead",
            "escalation_queue" => "mission_operations",
            "escalation_role" => "command_authority",
            "required_authority" => "command_authority",
            "sla_s" => 600
          },
          %{
            "id" => "command_result_failure_review",
            "requirement_types" => ["command_review", "health_check_review"],
            "command_results" => [
              "rejected",
              "failed",
              "failure",
              "timeout",
              "timed_out",
              "aborted",
              "error"
            ],
            "classification" => "operator_review_required",
            "reason" => "failed command-result evidence requires command authority review",
            "escalation_level" => "shift_lead",
            "escalation_queue" => "mission_operations",
            "escalation_role" => "command_authority",
            "required_authority" => "command_authority",
            "sla_s" => 600
          },
          %{
            "id" => "failed_contact_success_review",
            "requirement_types" => ["contact_schedule_change", "downstream_window_review"],
            "contact_success" => false,
            "classification" => "operator_review_required",
            "reason" => "failed contact execution evidence requires ground-network review",
            "escalation_level" => "ops_lead",
            "escalation_queue" => "ground_network",
            "escalation_role" => "contact_scheduler",
            "required_authority" => "contact_schedule_authority",
            "sla_s" => 900
          },
          %{
            "id" => "low_contact_success_confidence_review",
            "requirement_types" => ["contact_schedule_change", "downstream_window_review"],
            "contact_success_factor_max" => 0.8,
            "classification" => "operator_review_required",
            "reason" => "low contact success confidence requires ground-network review",
            "escalation_level" => "ops_lead",
            "escalation_queue" => "ground_network",
            "escalation_role" => "contact_scheduler",
            "required_authority" => "contact_schedule_authority",
            "sla_s" => 900
          },
          %{
            "id" => "contact_result_failure_review",
            "requirement_types" => ["contact_schedule_change", "downstream_window_review"],
            "contact_results" => [
              "failed",
              "failure",
              "timeout",
              "timed_out",
              "aborted",
              "error",
              "dropped",
              "lost",
              "missed",
              "no_contact"
            ],
            "classification" => "operator_review_required",
            "reason" => "failed contact-result evidence requires ground-network review",
            "escalation_level" => "ops_lead",
            "escalation_queue" => "ground_network",
            "escalation_role" => "contact_scheduler",
            "required_authority" => "contact_schedule_authority",
            "sla_s" => 900
          },
          %{
            "id" => "missing_cadence_import_review",
            "cadence_import_statuses" => ["missing", "invalid"],
            "requirement_types" => [
              "command_review",
              "health_check_review",
              "contact_schedule_change",
              "downstream_window_review"
            ],
            "classification" => "operator_review_required",
            "reason" => "missing or invalid Cadence import context requires adapter review",
            "escalation_level" => "planning_lead",
            "escalation_queue" => "mission_planning",
            "escalation_role" => "mission_planner",
            "required_authority" => "cadence_import_boundary_authority",
            "sla_s" => 900
          },
          %{
            "id" => "invalid_command_window_input_review",
            "activity_types" => ["invalid_activity_input"],
            "actions" => ["review_invalid_activity_input"],
            "requirement_types" => [
              "command_review",
              "health_check_review",
              "contact_schedule_change",
              "downstream_window_review"
            ],
            "classification" => "operator_review_required",
            "reason" => "invalid command-window inputs require mission-planning review",
            "escalation_level" => "planning_lead",
            "escalation_queue" => "mission_planning",
            "escalation_role" => "mission_planner",
            "required_authority" => "mission_planning_authority",
            "sla_s" => 900
          },
          %{
            "id" => "tracking_coordination_review",
            "directions" => ["tracking"],
            "requirement_types" => ["contact_schedule_change", "downstream_window_review"],
            "classification" => "operator_review_required",
            "reason" => "tracking windows require tracking coordination review",
            "escalation_level" => "ops_lead",
            "escalation_queue" => "tracking_operations",
            "escalation_role" => "tracking_coordinator",
            "required_authority" => "tracking_coordination_authority",
            "sla_s" => 1200
          },
          %{
            "id" => "downlink_schedule_authority_review",
            "directions" => ["downlink"],
            "requirement_types" => ["contact_schedule_change", "downstream_window_review"],
            "classification" => "operator_review_required",
            "reason" => "downlink windows require ground-network scheduling authority review",
            "escalation_level" => "ops_lead",
            "escalation_queue" => "ground_network",
            "escalation_role" => "contact_scheduler",
            "required_authority" => "contact_schedule_authority",
            "sla_s" => 1800
          },
          %{
            "id" => "health_command_authority_review",
            "activity_types" => ["health_check"],
            "requirement_types" => ["health_check_review"],
            "classification" => "operator_review_required",
            "reason" => "health-check commanding requires command authority review",
            "escalation_level" => "shift_lead",
            "escalation_queue" => "mission_operations",
            "escalation_role" => "command_authority",
            "required_authority" => "command_authority",
            "sla_s" => 900
          },
          %{
            "id" => "command_window_station_calendar_block",
            "required_operator_actions" => ["review_command_window_station_calendar"],
            "station_availabilities" => ["unavailable", "maintenance"],
            "classification" => "blocked_by_policy",
            "reason" => "command windows on unavailable station time are blocked by policy",
            "escalation_level" => "ops_lead",
            "escalation_queue" => "ground_network",
            "escalation_role" => "contact_scheduler",
            "required_authority" => "contact_schedule_authority",
            "sla_s" => 600
          },
          %{
            "id" => "command_window_station_calendar_review",
            "required_operator_actions" => ["review_command_window_station_calendar"],
            "station_availabilities" => ["reserved", "reduced_capacity"],
            "classification" => "operator_review_required",
            "reason" =>
              "command windows on reserved or reduced-capacity station time require review",
            "escalation_level" => "ops_lead",
            "escalation_queue" => "ground_network",
            "escalation_role" => "contact_scheduler",
            "required_authority" => "contact_schedule_authority",
            "sla_s" => 900
          }
        ]
      }
    },
    "conservative_ops_v1" => %{
      "schema_contract" => "policy_bundle.v1",
      "id" => "conservative_ops_v1",
      "description" =>
        "Block high-risk resource and downlink branches; review all approval requirements.",
      "approval_policy" => %{
        "auto_approvable_risk_limit" => 0,
        "auto_approvable_approval_count_limit" => 0,
        "operator_review_risk_limit" => 0,
        "blocked_risk_types" =>
          @default_blocked_risk_types ++
            [
              "fuel_margin_low",
              "downlink_capacity_low",
              "storage_overflow",
              "downlink_shortfall",
              "battery_depletion",
              "spacecraft_unavailable"
            ],
        "action_rules" => [
          %{
            "id" => "resource_pressure_block",
            "risk_types" => [
              "storage_overflow",
              "downlink_shortfall",
              "battery_depletion",
              "spacecraft_unavailable"
            ],
            "classification" => "blocked_by_policy",
            "reason" => "resource projection pressure exceeds declared planning capacity"
          },
          %{
            "id" => "all_requirements_review",
            "actions" => [
              "approve_moved_contact",
              "approve_reassigned_observation",
              "approve_delayed_maneuver",
              "approve_strategic_addition",
              "cancel"
            ],
            "classification" => "operator_review_required",
            "reason" => "conservative operations bundle requires explicit review"
          }
        ]
      }
    },
    "timeline_protection_v1" => %{
      "schema_contract" => "policy_bundle.v1",
      "id" => "timeline_protection_v1",
      "description" =>
        "Protect locked, approved, and executed timeline items from silent replanning changes.",
      "approval_policy" => %{
        "auto_approvable_risk_limit" => 0,
        "auto_approvable_approval_count_limit" => 0,
        "operator_review_risk_limit" => 2,
        "blocked_risk_types" => @default_blocked_risk_types,
        "action_rules" => [
          %{
            "id" => "locked_timeline_item_review",
            "locked" => true,
            "classification" => "operator_review_required",
            "reason" => "locked timeline items require operator review before change",
            "escalation_level" => "planning_lead",
            "escalation_queue" => "mission_planning",
            "escalation_role" => "mission_planner",
            "required_authority" => "timeline_protection_authority",
            "sla_s" => 1800
          },
          %{
            "id" => "approved_timeline_item_review",
            "approval_statuses" => ["approved", "auto_approvable"],
            "classification" => "operator_review_required",
            "reason" => "approved timeline items require operator review before change",
            "escalation_level" => "planning_lead",
            "escalation_queue" => "mission_planning",
            "escalation_role" => "mission_planner",
            "required_authority" => "timeline_protection_authority",
            "sla_s" => 1800
          },
          %{
            "id" => "executed_timeline_item_block",
            "statuses" => ["completed", "executed"],
            "classification" => "blocked_by_policy",
            "reason" => "executed timeline items cannot be changed by planner policy",
            "escalation_level" => "flight_director",
            "escalation_queue" => "mission_operations",
            "escalation_role" => "flight_director",
            "required_authority" => "flight_director",
            "sla_s" => 300
          },
          %{
            "id" => "source_preserved_transition_review",
            "transition_decisions" => ["preserve_source"],
            "application_statuses" => ["source_preserved_pending_review"],
            "classification" => "operator_review_required",
            "reason" =>
              "preserved source timeline items require operator review before replacement",
            "escalation_level" => "planning_lead",
            "escalation_queue" => "mission_planning",
            "escalation_role" => "mission_planner",
            "required_authority" => "timeline_protection_authority",
            "sla_s" => 1800
          },
          %{
            "id" => "source_protection_decision_review",
            "source_protection_decisions" => ["preserve", "review_change"],
            "source_protection_categories" => ["locked_or_approved"],
            "classification" => "operator_review_required",
            "reason" => "source timeline protection decisions require operator review",
            "escalation_level" => "planning_lead",
            "escalation_queue" => "mission_planning",
            "escalation_role" => "mission_planner",
            "required_authority" => "timeline_protection_authority",
            "sla_s" => 1800
          },
          %{
            "id" => "planned_protection_decision_review",
            "planned_protection_decisions" => ["preserve", "review_change"],
            "planned_protection_categories" => ["executed", "locked_or_approved"],
            "classification" => "operator_review_required",
            "reason" => "planned timeline protection decisions require operator review",
            "escalation_level" => "planning_lead",
            "escalation_queue" => "mission_planning",
            "escalation_role" => "mission_planner",
            "required_authority" => "timeline_protection_authority",
            "sla_s" => 1800
          },
          %{
            "id" => "timeline_integrity_issue_review",
            "timeline_integrity_statuses" => ["review_required"],
            "timeline_integrity_issue_types" => [
              "dependency_cycle",
              "dependency_order_violation",
              "exclusivity_group_overlap",
              "exclusivity_overlap",
              "invalid_activity_input",
              "missing_dependency_activity",
              "missing_dependency_timeline"
            ],
            "classification" => "operator_review_required",
            "reason" => "timeline dependency or exclusivity integrity issues require review",
            "escalation_level" => "planning_lead",
            "escalation_queue" => "mission_planning",
            "escalation_role" => "mission_planner",
            "required_authority" => "timeline_protection_authority",
            "sla_s" => 1800
          },
          %{
            "id" => "source_timeline_integrity_issue_review",
            "source_timeline_integrity_statuses" => ["review_required"],
            "source_timeline_integrity_issue_types" => [
              "dependency_cycle",
              "dependency_order_violation",
              "exclusivity_group_overlap",
              "exclusivity_overlap",
              "invalid_activity_input",
              "missing_dependency_activity",
              "missing_dependency_timeline"
            ],
            "classification" => "operator_review_required",
            "reason" =>
              "source timeline dependency or exclusivity integrity issues require review",
            "escalation_level" => "planning_lead",
            "escalation_queue" => "mission_planning",
            "escalation_role" => "mission_planner",
            "required_authority" => "timeline_protection_authority",
            "sla_s" => 1800
          },
          %{
            "id" => "replacement_timeline_integrity_issue_review",
            "replacement_timeline_integrity_statuses" => ["review_required"],
            "replacement_timeline_integrity_issue_types" => [
              "dependency_cycle",
              "dependency_order_violation",
              "exclusivity_group_overlap",
              "exclusivity_overlap",
              "invalid_activity_input",
              "missing_dependency_activity",
              "missing_dependency_timeline"
            ],
            "classification" => "operator_review_required",
            "reason" =>
              "replacement timeline dependency or exclusivity integrity issues require review",
            "escalation_level" => "planning_lead",
            "escalation_queue" => "mission_planning",
            "escalation_role" => "mission_planner",
            "required_authority" => "timeline_protection_authority",
            "sla_s" => 1800
          }
        ]
      }
    },
    "degraded_payload_guard_v1" => %{
      "schema_contract" => "policy_bundle.v1",
      "id" => "degraded_payload_guard_v1",
      "description" =>
        "Block degraded-spacecraft payload activity while preserving command and health-review exemptions.",
      "approval_policy" => %{
        "auto_approvable_risk_limit" => 1,
        "auto_approvable_approval_count_limit" => 2,
        "operator_review_risk_limit" => 3,
        "blocked_risk_types" => @default_blocked_risk_types,
        "action_rules" => [
          %{
            "id" => "degraded_payload_observation_block",
            "activity_types" => ["observe"],
            "degraded" => true,
            "classification" => "blocked_by_policy",
            "reason" => "degraded spacecraft cannot accept payload observation changes"
          },
          %{
            "id" => "payload_unavailable_observation_block",
            "activity_types" => ["observe"],
            "payload_available" => false,
            "classification" => "blocked_by_policy",
            "reason" => "payload-unavailable spacecraft cannot accept observation changes"
          },
          %{
            "id" => "antenna_unavailable_contact_block",
            "activity_types" => ["downlink", "contact", "planned_contact", "tracking"],
            "antenna_available" => false,
            "classification" => "blocked_by_policy",
            "reason" => "antenna-unavailable spacecraft cannot accept contact changes"
          },
          %{
            "id" => "invalid_resource_filter_candidate_input_review",
            "activity_types" => ["invalid_candidate_input"],
            "actions" => ["review_invalid_resource_filter_input"],
            "classification" => "operator_review_required",
            "reason" => "invalid resource-filter candidate inputs require resource review",
            "escalation_level" => "planning_lead",
            "escalation_queue" => "resource_planning",
            "escalation_role" => "resource_planner",
            "required_authority" => "resource_model_authority",
            "sla_s" => 1200
          },
          %{
            "id" => "invalid_resource_filter_summary_input_review",
            "activity_types" => ["resource_filter_invalid_summary"],
            "actions" => ["review_invalid_resource_filter_summary"],
            "classification" => "operator_review_required",
            "reason" => "invalid resource-filter summary inputs require resource review",
            "escalation_level" => "planning_lead",
            "escalation_queue" => "resource_planning",
            "escalation_role" => "resource_planner",
            "required_authority" => "resource_model_authority",
            "sla_s" => 1200
          },
          %{
            "id" => "degraded_command_health_exemption",
            "activity_types" => ["command", "health_check"],
            "requirement_types" => ["command_review", "health_check_review"],
            "degraded" => true,
            "classification" => "auto_approvable",
            "reason" => "command and health-review activities remain allowed in degraded mode"
          }
        ]
      }
    },
    "mission_ops_escalation_v1" => %{
      "schema_contract" => "policy_bundle.v1",
      "id" => "mission_ops_escalation_v1",
      "description" =>
        "Classify common mission-operations authority boundaries with artifact-only escalation metadata.",
      "approval_policy" => %{
        "auto_approvable_risk_limit" => 0,
        "auto_approvable_approval_count_limit" => 0,
        "operator_review_risk_limit" => 2,
        "blocked_risk_types" => @default_blocked_risk_types,
        "action_rules" => [
          %{
            "id" => "command_authority_escalation",
            "requirement_types" => ["command_review", "health_check_review"],
            "classification" => "operator_review_required",
            "reason" => "command and health-review boundaries require command authority review",
            "escalation_level" => "shift_lead",
            "escalation_queue" => "mission_operations",
            "escalation_role" => "command_authority",
            "required_authority" => "command_authority",
            "sla_s" => 900
          },
          %{
            "id" => "contact_execution_coordination",
            "requirement_types" => ["contact_schedule_change", "downstream_window_review"],
            "classification" => "operator_review_required",
            "reason" => "contact execution changes require ground-network coordination",
            "escalation_level" => "ops_lead",
            "escalation_queue" => "ground_network",
            "escalation_role" => "contact_scheduler",
            "required_authority" => "contact_schedule_authority",
            "sla_s" => 1800
          },
          %{
            "id" => "reserved_station_contact_escalation",
            "station_contention_statuses" => ["reserved_overlap"],
            "classification" => "operator_review_required",
            "reason" =>
              "contacts overlapping declared reserved station time require ground-network authority review",
            "escalation_level" => "ops_lead",
            "escalation_queue" => "ground_network",
            "escalation_role" => "contact_scheduler",
            "required_authority" => "contact_schedule_authority",
            "sla_s" => 600
          },
          %{
            "id" => "high_overlap_contact_contention_escalation",
            "activity_types" => ["contact_contention", "contact_contention_resolution"],
            "overlap_duration_s_min" => 60.0,
            "max_concurrent_contacts_min" => 3,
            "overlap_contact_pair_count_min" => 3,
            "classification" => "operator_review_required",
            "reason" =>
              "high-overlap contact contention requires priority contact-schedule authority review",
            "escalation_level" => "ops_lead",
            "escalation_queue" => "ground_network_priority",
            "escalation_role" => "contact_scheduler",
            "required_authority" => "contact_schedule_authority",
            "sla_s" => 600
          },
          %{
            "id" => "strategic_priority_escalation",
            "actions" => ["approve_strategic_addition"],
            "classification" => "operator_review_required",
            "reason" => "strategic additions require mission-planning authority review",
            "escalation_level" => "planning_lead",
            "escalation_queue" => "mission_planning",
            "escalation_role" => "mission_planner",
            "required_authority" => "mission_planning_authority",
            "sla_s" => 3600
          },
          %{
            "id" => "downlink_loss_director_escalation",
            "risk_types" => ["no_viable_downlink"],
            "classification" => "blocked_by_policy",
            "reason" => "no viable downlink requires flight-director escalation before execution",
            "escalation_level" => "flight_director",
            "escalation_queue" => "mission_operations",
            "escalation_role" => "flight_director",
            "required_authority" => "flight_director",
            "sla_s" => 300
          }
        ]
      }
    },
    "maneuver_authority_v1" => %{
      "schema_contract" => "policy_bundle.v1",
      "id" => "maneuver_authority_v1",
      "description" =>
        "Require maneuver authority review for maneuver timing, invalid recommendations, and impulsive-burn approval boundaries.",
      "approval_policy" => %{
        "auto_approvable_risk_limit" => 0,
        "auto_approvable_approval_count_limit" => 0,
        "operator_review_risk_limit" => 2,
        "blocked_risk_types" => @default_blocked_risk_types,
        "action_rules" => [
          %{
            "id" => "maneuver_timing_authority_review",
            "requirement_types" => ["maneuver_timing_change", "maneuver_authority_review"],
            "classification" => "operator_review_required",
            "reason" => "maneuver timing changes require maneuver authority review",
            "escalation_level" => "flight_dynamics",
            "escalation_queue" => "flight_dynamics",
            "escalation_role" => "maneuver_authority",
            "required_authority" => "maneuver_authority",
            "sla_s" => 1800
          },
          %{
            "id" => "impulsive_burn_authority_review",
            "activity_types" => ["impulsive_burn"],
            "classification" => "operator_review_required",
            "reason" => "impulsive burns require maneuver authority review",
            "escalation_level" => "flight_dynamics",
            "escalation_queue" => "flight_dynamics",
            "escalation_role" => "maneuver_authority",
            "required_authority" => "maneuver_authority",
            "sla_s" => 1800
          },
          %{
            "id" => "invalid_maneuver_recommendation_review",
            "actions" => ["review_invalid_maneuver_recommendation"],
            "classification" => "operator_review_required",
            "reason" => "invalid maneuver recommendations require maneuver authority review",
            "escalation_level" => "flight_dynamics",
            "escalation_queue" => "flight_dynamics",
            "escalation_role" => "maneuver_authority",
            "required_authority" => "maneuver_authority",
            "sla_s" => 1200
          },
          %{
            "id" => "maneuver_result_failure_review",
            "activity_types" => ["impulsive_burn"],
            "maneuver_results" => [
              "rejected",
              "failed",
              "failure",
              "timeout",
              "timed_out",
              "aborted",
              "error"
            ],
            "classification" => "operator_review_required",
            "reason" => "failed maneuver-result evidence requires maneuver authority review",
            "escalation_level" => "flight_dynamics",
            "escalation_queue" => "flight_dynamics",
            "escalation_role" => "maneuver_authority",
            "required_authority" => "maneuver_authority",
            "sla_s" => 1200
          }
        ]
      }
    },
    "ground_network_allocation_v1" => %{
      "schema_contract" => "policy_bundle.v1",
      "id" => "ground_network_allocation_v1",
      "description" =>
        "Classify station availability, reservation, reduced-capacity, and priority-evidence contact allocation boundaries.",
      "approval_policy" => %{
        "auto_approvable_risk_limit" => 0,
        "auto_approvable_approval_count_limit" => 0,
        "operator_review_risk_limit" => 2,
        "blocked_risk_types" => @default_blocked_risk_types,
        "action_rules" => [
          %{
            "id" => "unavailable_station_contact_block",
            "station_availabilities" => ["unavailable", "maintenance"],
            "classification" => "blocked_by_policy",
            "reason" => "contacts on unavailable station time are blocked by planning policy",
            "escalation_level" => "ops_lead",
            "escalation_queue" => "ground_network",
            "escalation_role" => "contact_scheduler",
            "required_authority" => "contact_schedule_authority",
            "sla_s" => 600
          },
          %{
            "id" => "reserved_station_contact_review",
            "station_contention_statuses" => ["reserved_overlap"],
            "classification" => "operator_review_required",
            "reason" =>
              "contacts overlapping declared station reservations require operator review",
            "escalation_level" => "ops_lead",
            "escalation_queue" => "ground_network",
            "escalation_role" => "contact_scheduler",
            "required_authority" => "contact_schedule_authority",
            "sla_s" => 600
          },
          %{
            "id" => "severe_capacity_reduction_review",
            "station_availabilities" => ["reduced_capacity"],
            "capacity_fraction_max" => 0.5,
            "classification" => "operator_review_required",
            "reason" => "severely reduced station capacity requires contact allocation review",
            "escalation_level" => "ops_lead",
            "escalation_queue" => "ground_network",
            "escalation_role" => "contact_scheduler",
            "required_authority" => "contact_schedule_authority",
            "sla_s" => 1200
          },
          %{
            "id" => "low_actual_downlink_completion_review",
            "requirement_types" => ["contact_schedule_change", "downstream_window_review"],
            "actual_completion_fraction_max" => 0.8,
            "classification" => "operator_review_required",
            "reason" => "low realized downlink completion requires ground-network review",
            "escalation_level" => "ops_lead",
            "escalation_queue" => "ground_network",
            "escalation_role" => "contact_scheduler",
            "required_authority" => "contact_schedule_authority",
            "sla_s" => 1200
          },
          %{
            "id" => "missing_station_calendar_trust_review",
            "station_calendar_trust_boundary_status" => "missing",
            "classification" => "operator_review_required",
            "reason" => "station calendar trust boundary missing",
            "escalation_level" => "ops_lead",
            "escalation_queue" => "ground_network",
            "escalation_role" => "contact_scheduler",
            "required_authority" => "contact_schedule_authority",
            "sla_s" => 1200
          },
          %{
            "id" => "command_station_calendar_direction_review",
            "station_calendar_directions" => ["command"],
            "classification" => "operator_review_required",
            "reason" =>
              "command-direction station calendar evidence requires ground-network review",
            "escalation_level" => "ops_lead",
            "escalation_queue" => "ground_network",
            "escalation_role" => "contact_scheduler",
            "required_authority" => "contact_schedule_authority",
            "sla_s" => 1200
          },
          %{
            "id" => "same_station_contact_contention_review",
            "activity_types" => ["contact_contention", "contact_contention_resolution"],
            "resource_scopes" => ["ground_station"],
            "required_operator_actions" => [
              "review_contact_contention",
              "recommend_preferred_contact_for_operator_review"
            ],
            "classification" => "operator_review_required",
            "reason" => "same-station contact contention requires ground-network review",
            "escalation_level" => "ops_lead",
            "escalation_queue" => "ground_network",
            "escalation_role" => "contact_scheduler",
            "required_authority" => "contact_schedule_authority",
            "sla_s" => 900
          },
          %{
            "id" => "declared_provider_calendar_contention_review",
            "activity_types" => ["contact_contention", "contact_contention_resolution"],
            "station_calendar_trust_boundary_statuses" => ["declared"],
            "classification" => "operator_review_required",
            "reason" => "provider-calendar contention requires ground-network authority review",
            "escalation_level" => "ops_lead",
            "escalation_queue" => "ground_network",
            "escalation_role" => "contact_scheduler",
            "required_authority" => "contact_schedule_authority",
            "sla_s" => 900
          },
          %{
            "id" => "missing_priority_field_evidence_review",
            "activity_types" => ["contact_allocation", "contact_contention_resolution"],
            "priority_fields_without_numeric_evidence_count_min" => 1,
            "classification" => "operator_review_required",
            "reason" => "custom contact-priority fields without numeric evidence require review",
            "escalation_level" => "ops_lead",
            "escalation_queue" => "ground_network",
            "escalation_role" => "contact_scheduler",
            "required_authority" => "contact_schedule_authority",
            "sla_s" => 900
          },
          %{
            "id" => "high_overlap_contact_contention_review",
            "activity_types" => ["contact_contention", "contact_contention_resolution"],
            "resource_scopes" => ["ground_station"],
            "overlap_duration_s_min" => 60.0,
            "max_concurrent_contacts_min" => 3,
            "overlap_contact_pair_count_min" => 3,
            "classification" => "operator_review_required",
            "reason" => "high-overlap station contention requires priority ground-network review",
            "escalation_level" => "ops_lead",
            "escalation_queue" => "ground_network_priority",
            "escalation_role" => "contact_scheduler",
            "required_authority" => "contact_schedule_authority",
            "sla_s" => 600
          },
          %{
            "id" => "invalid_contact_contention_input_review",
            "activity_types" => ["contact_contention"],
            "required_operator_actions" => ["review_invalid_contact_contention_input"],
            "classification" => "operator_review_required",
            "reason" =>
              "invalid contact-contention inputs require ground-network authority review",
            "escalation_level" => "ops_lead",
            "escalation_queue" => "ground_network",
            "escalation_role" => "contact_scheduler",
            "required_authority" => "contact_schedule_authority",
            "sla_s" => 900
          },
          %{
            "id" => "invalid_link_capacity_input_review",
            "activity_types" => ["link_capacity"],
            "actions" => ["review_invalid_link_capacity_input"],
            "classification" => "operator_review_required",
            "reason" => "invalid link-capacity inputs require ground-network authority review",
            "escalation_level" => "ops_lead",
            "escalation_queue" => "ground_network",
            "escalation_role" => "contact_scheduler",
            "required_authority" => "contact_schedule_authority",
            "sla_s" => 900
          },
          %{
            "id" => "duplicate_contact_identity_block",
            "activity_types" => ["contact_contention", "contact_contention_resolution"],
            "resolution_issues" => ["duplicate_contact_id"],
            "classification" => "blocked_by_policy",
            "reason" => "duplicate contact identities require manual resolution before routing",
            "escalation_level" => "ops_lead",
            "escalation_queue" => "ground_network",
            "escalation_role" => "contact_scheduler",
            "required_authority" => "contact_schedule_authority",
            "sla_s" => 600
          },
          %{
            "id" => "reduced_station_capacity_insufficient_block",
            "station_availabilities" => ["reduced_capacity"],
            "allocation_reasons" => ["ground_station_reduced_capacity_insufficient"],
            "suppressed_reasons" => ["ground_station_reduced_capacity_insufficient"],
            "classification" => "blocked_by_policy",
            "reason" =>
              "contacts requiring more than available reduced station capacity are blocked",
            "escalation_level" => "ops_lead",
            "escalation_queue" => "ground_network",
            "escalation_role" => "contact_scheduler",
            "required_authority" => "contact_schedule_authority",
            "sla_s" => 600
          }
        ]
      }
    },
    "resource_projection_authority_v1" => %{
      "schema_contract" => "policy_bundle.v1",
      "id" => "resource_projection_authority_v1",
      "description" =>
        "Classify resource projection pressure, source-quality, and trust-boundary review evidence.",
      "approval_policy" => %{
        "auto_approvable_risk_limit" => 0,
        "auto_approvable_approval_count_limit" => 0,
        "operator_review_risk_limit" => 2,
        "blocked_risk_types" => @default_blocked_risk_types,
        "action_rules" => [
          %{
            "id" => "missing_resource_trust_boundary_review",
            "activity_types" => ["resource_projection"],
            "resource_trust_boundary_statuses" => ["missing"],
            "classification" => "operator_review_required",
            "reason" =>
              "resource projection inputs without declared trust boundaries require review",
            "escalation_level" => "planning_lead",
            "escalation_queue" => "mission_planning",
            "escalation_role" => "resource_planner",
            "required_authority" => "resource_model_authority",
            "sla_s" => 1800
          },
          %{
            "id" => "unknown_resource_source_quality_review",
            "activity_types" => ["resource_projection"],
            "resource_source_qualities" => ["unknown", "adapter_inferred"],
            "classification" => "operator_review_required",
            "reason" => "resource projection inputs with uncertain source quality require review",
            "escalation_level" => "planning_lead",
            "escalation_queue" => "mission_planning",
            "escalation_role" => "resource_planner",
            "required_authority" => "resource_model_authority",
            "sla_s" => 1800
          },
          %{
            "id" => "resource_pressure_review",
            "activity_types" => ["resource_projection"],
            "resource_pressure_types" => [
              "storage_overflow",
              "downlink_shortfall",
              "battery_depletion",
              "thermal_margin_below_limit",
              "payload_unavailable",
              "spacecraft_degraded_payload_unavailable",
              "antenna_unavailable"
            ],
            "classification" => "operator_review_required",
            "reason" =>
              "resource projection pressure requires resource-planning authority review",
            "escalation_level" => "planning_lead",
            "escalation_queue" => "mission_planning",
            "escalation_role" => "resource_planner",
            "required_authority" => "resource_model_authority",
            "sla_s" => 1200
          },
          %{
            "id" => "invalid_resource_projection_activity_input_review",
            "activity_types" => ["resource_projection_invalid_activity"],
            "actions" => ["review_invalid_resource_projection_input"],
            "classification" => "operator_review_required",
            "reason" => "invalid resource-projection activity inputs require resource review",
            "escalation_level" => "planning_lead",
            "escalation_queue" => "resource_planning",
            "escalation_role" => "resource_planner",
            "required_authority" => "resource_model_authority",
            "sla_s" => 1200
          },
          %{
            "id" => "invalid_resource_projection_summary_input_review",
            "activity_types" => ["resource_projection_invalid_summary"],
            "actions" => ["review_invalid_resource_projection_summary"],
            "classification" => "operator_review_required",
            "reason" => "invalid resource-projection summary inputs require resource review",
            "escalation_level" => "planning_lead",
            "escalation_queue" => "resource_planning",
            "escalation_role" => "resource_planner",
            "required_authority" => "resource_model_authority",
            "sla_s" => 1200
          },
          %{
            "id" => "combined_resource_pressure_director_block",
            "activity_types" => ["resource_projection"],
            "resource_pressure_statuses" => ["storage_and_downlink_pressure"],
            "classification" => "blocked_by_policy",
            "reason" =>
              "combined storage and downlink pressure requires flight-director review before promotion",
            "escalation_level" => "flight_director",
            "escalation_queue" => "mission_operations",
            "escalation_role" => "flight_director",
            "required_authority" => "flight_director",
            "sla_s" => 600
          },
          %{
            "id" => "first_storage_pressure_review",
            "activity_types" => ["resource_projection"],
            "first_resource_pressure_kinds" => ["storage_overflow"],
            "classification" => "operator_review_required",
            "reason" => "storage is the first projected resource pressure event",
            "escalation_level" => "planning_lead",
            "escalation_queue" => "mission_planning",
            "escalation_role" => "resource_planner",
            "required_authority" => "resource_model_authority",
            "sla_s" => 1200
          }
        ]
      }
    },
    "operator_review_queue_authority_v1" => %{
      "schema_contract" => "policy_bundle.v1",
      "id" => "operator_review_queue_authority_v1",
      "description" =>
        "Route deterministic operator-review queues to artifact-only authority boundaries.",
      "approval_policy" => %{
        "auto_approvable_risk_limit" => 0,
        "auto_approvable_approval_count_limit" => 0,
        "operator_review_risk_limit" => 2,
        "blocked_risk_types" => @default_blocked_risk_types,
        "action_rules" => [
          %{
            "id" => "resource_review_queue_authority",
            "review_queues" => [
              "review_invalid_resource_filter_input",
              "review_invalid_resource_filter_summary",
              "review_invalid_resource_projection_input",
              "review_invalid_resource_projection_summary",
              "review_resource_projection",
              "review_resource_suppression",
              "review_suppressed_candidate",
              "review_suppressed_observation"
            ],
            "classification" => "operator_review_required",
            "reason" => "resource review queues require resource-planning authority",
            "escalation_level" => "planning_lead",
            "escalation_queue" => "mission_planning",
            "escalation_role" => "resource_planner",
            "required_authority" => "resource_model_authority",
            "sla_s" => 1200
          },
          %{
            "id" => "ground_network_review_queue_authority",
            "review_queues" => [
              "approve_manual_contact",
              "review_contact_allocation",
              "review_contact_contention",
              "review_contact_contention_resolution",
              "review_contact_intent",
              "review_contact_suppression",
              "review_contact_exception",
              "review_contact_variance",
              "review_invalid_contact_contention_input",
              "review_invalid_contact_filter_input",
              "review_invalid_link_capacity_input",
              "review_link_capacity",
              "review_link_capacity_summary",
              "review_reduced_station_capacity",
              "review_station_availability",
              "review_station_calendar",
              "review_station_reservation_overlap",
              "review_suppressed_contact"
            ],
            "classification" => "operator_review_required",
            "reason" => "contact and link-capacity queues require ground-network review",
            "escalation_level" => "ops_lead",
            "escalation_queue" => "ground_network",
            "escalation_role" => "contact_scheduler",
            "required_authority" => "contact_schedule_authority",
            "sla_s" => 900
          },
          %{
            "id" => "timeline_review_queue_authority",
            "review_queues" => [
              "prepare_cadence_import",
              "review_activity_approval",
              "review_added_activity",
              "review_changed_executed_activity",
              "review_changed_executed_timeline_item",
              "review_changed_protected_activity",
              "review_changed_protected_timeline_item",
              "review_command_window",
              "review_duplicate_timeline_identity",
              "review_invalid_activity_input",
              "review_moved_timeline_item",
              "review_operational_timeline",
              "review_plan_delta",
              "review_removed_activity",
              "review_removed_executed_activity",
              "review_removed_protected_activity",
              "review_replaced_timeline_item",
              "review_terminal_activity_exception",
              "review_timeline_change",
              "review_timeline_diff",
              "review_timeline_integrity",
              "review_timeline_protection"
            ],
            "classification" => "operator_review_required",
            "reason" => "timeline review queues require mission-planning authority",
            "escalation_level" => "planning_lead",
            "escalation_queue" => "mission_planning",
            "escalation_role" => "mission_planner",
            "required_authority" => "timeline_protection_authority",
            "sla_s" => 1800
          },
          %{
            "id" => "maneuver_review_queue_authority",
            "review_queues" => [
              "review_invalid_maneuver_recommendation",
              "review_maneuver",
              "review_maneuver_exception",
              "review_maneuver_recommendation"
            ],
            "classification" => "operator_review_required",
            "reason" => "maneuver review queues require flight-dynamics authority",
            "escalation_level" => "flight_dynamics",
            "escalation_queue" => "flight_dynamics",
            "escalation_role" => "maneuver_authority",
            "required_authority" => "maneuver_authority",
            "sla_s" => 1200
          },
          %{
            "id" => "policy_escalation_review_queue_authority",
            "review_queue_keys" => [
              "policy_escalation|review_policy_escalation|operator_review_required"
            ],
            "classification" => "operator_review_required",
            "reason" => "policy escalation queues require mission-operations authority",
            "escalation_level" => "shift_lead",
            "escalation_queue" => "mission_operations",
            "escalation_role" => "duty_officer",
            "required_authority" => "mission_operations_authority",
            "sla_s" => 600
          }
        ]
      }
    }
  }

  @doc """
  Declares the policy artifact model, match dimensions, and known limits.
  """
  def capabilities do
    %{
      artifact_contract: "policy_decision.v1",
      model: :artifact_only_approval_policy_classification,
      validation_level: :artifact_contract,
      classifications: @classifications,
      cadence_import_statuses: cadence_import_statuses(),
      direction_aliases: RequirementContext.direction_aliases(),
      match_dimensions: [
        :action,
        :actions,
        :activity_type,
        :activity_types,
        :requirement_type,
        :requirement_types,
        :risk_type,
        :risk_types,
        :spacecraft_id,
        :spacecraft_ids,
        :target_id,
        :target_ids,
        :event_type,
        :event_types,
        :feasibility_status,
        :direction,
        :directions,
        :ground_station_id,
        :ground_station_ids,
        :station_id,
        :station_ids,
        :station_availability,
        :station_availabilities,
        :station_contention_status,
        :station_contention_statuses,
        :station_reservation_id,
        :station_reservation_ids,
        :station_reserved_by,
        :station_reserved_bys,
        :station_reservation_status,
        :station_reservation_statuses,
        :station_reservation_match_status,
        :station_reservation_match_statuses,
        :station_calendar_entry_id,
        :station_calendar_entry_ids,
        :station_calendar_reserved_by,
        :station_calendar_reserved_bys,
        :station_calendar_reservation_status,
        :station_calendar_reservation_statuses,
        :station_calendar_status,
        :station_calendar_statuses,
        :station_calendar_entry_ambiguous,
        :station_calendar_ambiguous_entry_id,
        :station_calendar_ambiguous_entry_ids,
        :station_calendar_ambiguous_entry_count_min,
        :station_calendar_ambiguous_entry_count_max,
        :contention_window_s_min,
        :total_contact_duration_s_min,
        :overlap_duration_s_min,
        :max_concurrent_contacts_min,
        :overlap_contact_pair_count_min,
        :station_calendar_trust_boundary_status,
        :station_calendar_trust_boundary_statuses,
        :station_calendar_direction,
        :station_calendar_directions,
        :resource_scope,
        :resource_scopes,
        :selection_reason,
        :selection_reasons,
        :selected_priority_source,
        :selected_priority_sources,
        :contact_result,
        :contact_results,
        :command_result,
        :command_results,
        :observation_result,
        :observation_results,
        :maneuver_result,
        :maneuver_results,
        :priority_field_without_numeric_evidence,
        :priority_fields_without_numeric_evidence_count_min,
        :priority_fields_without_numeric_evidence,
        :resolution_status,
        :resolution_statuses,
        :resolution_issue,
        :resolution_issues,
        :station_calendar_provider_id,
        :station_calendar_provider_ids,
        :station_calendar_provider_entry_id,
        :station_calendar_provider_entry_ids,
        :station_calendar_reservation_id,
        :station_calendar_reservation_ids,
        :required_operator_action,
        :required_operator_actions,
        :operator_action_reason,
        :operator_action_reasons,
        :allocation_status,
        :allocation_statuses,
        :effective_allocation_status,
        :effective_allocation_statuses,
        :allocation_reason,
        :allocation_reasons,
        :suppressed_reason,
        :suppressed_reasons,
        :resource_blocking_dimension,
        :resource_blocking_dimensions,
        :transition_decision,
        :transition_decisions,
        :application_status,
        :application_statuses,
        :planned_protection_decision,
        :planned_protection_decisions,
        :planned_protection_category,
        :planned_protection_categories,
        :timeline_integrity_status,
        :timeline_integrity_statuses,
        :timeline_integrity_issue_type,
        :timeline_integrity_issue_types,
        :source_timeline_integrity_status,
        :source_timeline_integrity_statuses,
        :source_timeline_integrity_issue_type,
        :source_timeline_integrity_issue_types,
        :replacement_timeline_integrity_status,
        :replacement_timeline_integrity_statuses,
        :replacement_timeline_integrity_issue_type,
        :replacement_timeline_integrity_issue_types,
        :source_protection_decision,
        :source_protection_decisions,
        :source_protection_category,
        :source_protection_categories,
        :replacement_protection_decision,
        :replacement_protection_decisions,
        :replacement_protection_category,
        :replacement_protection_categories,
        :review_queue,
        :review_queues,
        :review_queue_key,
        :review_queue_keys,
        :cadence_import_status,
        :cadence_import_statuses,
        :capacity_fraction_min,
        :capacity_fraction_max,
        :actual_completion_fraction_min,
        :actual_completion_fraction_max,
        :contact_success,
        :contact_success_factor_min,
        :contact_success_factor_max,
        :command_success,
        :command_success_factor_min,
        :command_success_factor_max,
        :observation_success_factor_min,
        :observation_success_factor_max,
        :maneuver_success_factor_min,
        :maneuver_success_factor_max,
        :status,
        :statuses,
        :approval_status,
        :approval_statuses,
        :policy_classification,
        :policy_classifications,
        :resource_pressure_status,
        :resource_pressure_statuses,
        :resource_pressure_type,
        :resource_pressure_types,
        :resource_source_quality,
        :resource_source_qualities,
        :resource_trust_boundary,
        :resource_trust_boundaries,
        :resource_trust_boundary_status,
        :resource_trust_boundary_statuses,
        :first_resource_pressure_kind,
        :first_resource_pressure_kinds,
        :feedback_source,
        :feedback_sources,
        :feedback_scope,
        :feedback_scopes,
        :trust_boundary,
        :trust_boundaries,
        :source_event_type,
        :source_event_types,
        :locked,
        :degraded,
        :payload_available,
        :antenna_available
      ],
      fallback_policy_fields: [
        :auto_approvable_risk_limit,
        :auto_approvable_approval_count_limit,
        :operator_review_risk_limit,
        :blocked_risk_types
      ],
      escalation_fields: Enum.map(@escalation_fields, &String.to_atom/1),
      adapter_hooks: [
        :organization_policy_bundle,
        :inline_policy_bundle
      ],
      policy_bundles: Map.keys(@policy_bundles) |> Enum.sort(),
      provider_result_map_value_keys: RequirementContext.provider_result_map_value_keys(),
      known_limits: [
        :artifact_classification_only,
        :no_command_execution,
        :no_schedule_mutation,
        :no_external_authority_lookup,
        :no_multi_step_workflow_execution
      ]
    }
  end

  @doc """
  Returns built-in reusable approval policy bundles.
  """
  def bundles, do: @policy_bundles |> Map.values() |> Enum.sort_by(& &1["id"])

  @doc """
  Returns a built-in approval policy bundle by ID.
  """
  def bundle!(id) do
    id = to_string(id)

    case Map.fetch(@policy_bundles, id) do
      {:ok, bundle} -> bundle
      :error -> raise ArgumentError, "unknown policy bundle #{inspect(id)}"
    end
  end

  @doc """
  Returns a checked-in-artifact shaped built-in approval policy bundle by ID.

  The artifact wrapper preserves the runtime bundle exactly, then adds explicit
  provenance and artifact-only assumptions for import-gate fixtures.
  """
  def bundle_artifact!(id) do
    id = to_string(id)

    id
    |> bundle!()
    |> Map.put("provenance", %{
      "source" => "OrbitalDynamics.Policy.bundle!",
      "bundle_id" => id
    })
    |> Map.put("model_limits", model_limits())
    |> Map.put("assumptions", %{
      "boundary" => "artifact_only_no_authority_lookup",
      "workflow_execution" => "none"
    })
  end

  @doc """
  Returns checked-in-artifact shaped built-in approval policy bundles.
  """
  def bundle_artifacts,
    do: @policy_bundles |> Map.keys() |> Enum.sort() |> Enum.map(&bundle_artifact!/1)

  @doc """
  Builds a schema-valid organization-specific policy bundle.

  The returned bundle is still artifact-only: it can classify work and carry
  adapter provenance, but it does not call an external authority system or
  execute a workflow.
  """
  def organization_policy_bundle(id, approval_policy, opts \\ []) do
    opts = opts |> Enum.into(%{}) |> stringify_keys()
    provenance = Map.get(opts, "provenance", %{})

    %{
      "schema_contract" => "policy_bundle.v1",
      "id" => to_string(id),
      "description" =>
        Map.get(
          opts,
          "description",
          "Organization-specific artifact-only approval policy bundle."
        ),
      "approval_policy" =>
        approval_policy
        |> normalize_approval_policy()
        |> Map.drop(["policy_bundle_id", "policy_bundle_provenance"]),
      "model_limits" => model_limits(),
      "provenance" =>
        %{
          "source" => "organization_policy_adapter",
          "adapter" => Map.get(opts, "adapter"),
          "organization_id" => Map.get(opts, "organization_id"),
          "policy_source" => Map.get(opts, "policy_source"),
          "trust_boundary" => Map.get(opts, "trust_boundary", "organization_policy_adapter")
        }
        |> Map.merge(provenance)
        |> compact_map()
    }
    |> maybe_put("assumptions", Map.get(opts, "assumptions"))
  end

  @doc """
  Normalizes approval policy maps into deterministic string-keyed maps.
  """
  def normalize_approval_policy(policy) do
    policy = stringify_keys(policy || %{})
    bundle = policy_bundle(policy)
    bundle_policy = Map.get(bundle || %{}, "approval_policy", %{})
    explicit_rules = Map.get(policy, "action_rules")
    policy = Map.merge(bundle_policy, Map.drop(policy, ["bundle", "policy_bundle_id"]))
    action_rules = Map.get(bundle_policy, "action_rules", []) ++ List.wrap(explicit_rules || [])

    %{
      "policy_bundle_id" => Map.get(bundle || %{}, "id"),
      "policy_bundle_provenance" => Map.get(bundle || %{}, "provenance"),
      "auto_approvable_risk_limit" =>
        normalize_non_negative_integer_field(policy, "auto_approvable_risk_limit", 0),
      "auto_approvable_approval_count_limit" =>
        normalize_non_negative_integer_field(policy, "auto_approvable_approval_count_limit", 0),
      "operator_review_risk_limit" =>
        normalize_non_negative_integer_field(policy, "operator_review_risk_limit", 3),
      "blocked_risk_types" => Map.get(policy, "blocked_risk_types", @default_blocked_risk_types),
      "action_rules" => normalize_action_rules(action_rules)
    }
    |> validate_approval_policy!()
  end

  @doc """
  Classifies a branch approval boundary.
  """
  def decide(approval_requirements, risk_indicators, branch, candidate_plan, policy) do
    policy = normalize_approval_policy(policy)

    rule_matches =
      policy["action_rules"]
      |> Enum.flat_map(fn rule ->
        approval_rule_matches(
          rule,
          approval_requirements,
          risk_indicators,
          branch,
          candidate_plan
        )
      end)
      |> Enum.map(&add_policy_bundle_provenance_fields(&1, policy["policy_bundle_provenance"]))
      |> Enum.sort_by(&rule_match_sort_key/1)

    enriched_requirements =
      Enum.map(approval_requirements, fn requirement ->
        matches =
          Enum.filter(rule_matches, fn match ->
            cond do
              not is_nil(match["activity_id"]) ->
                match["activity_id"] == requirement["activity_id"]

              not is_nil(match["action"]) ->
                match["action"] == requirement["action"]

              true ->
                false
            end
          end)

        case matches do
          [] ->
            requirement

          _matches ->
            strongest = strongest_classification(matches)

            requirement
            |> Map.put("approval_rule_matches", matches)
            |> Map.put("policy_classification", strongest)
        end
      end)

    status =
      cond do
        Enum.any?(rule_matches, &(&1["classification"] == "blocked_by_policy")) ->
          "blocked_by_policy"

        Enum.any?(rule_matches, &(&1["classification"] == "operator_review_required")) ->
          "operator_review_required"

        approval_requirements != [] and
          Enum.all?(
            enriched_requirements,
            &(&1["policy_classification"] == "auto_approvable")
          ) and
            length(risk_indicators) <= policy["auto_approvable_risk_limit"] ->
          "auto_approvable"

        true ->
          fallback_status(enriched_requirements, risk_indicators, policy)
      end

    decision =
      %{
        "schema_contract" => "policy_decision.v1",
        "classification" => status,
        "model_limits" => model_limits(),
        "rule_matches" => rule_matches,
        "escalations" => non_empty_list(escalation_summaries(rule_matches)),
        "approval_requirement_count" =>
          policy_decision_approval_requirement_count(rule_matches, approval_requirements),
        "risk_count" => policy_decision_risk_count(rule_matches, risk_indicators),
        "policy_bundle_id" => policy["policy_bundle_id"],
        "policy_bundle_provenance" => policy["policy_bundle_provenance"],
        "fallback_policy" => %{
          "auto_approvable_risk_limit" => policy["auto_approvable_risk_limit"],
          "auto_approvable_approval_count_limit" =>
            policy["auto_approvable_approval_count_limit"],
          "operator_review_risk_limit" => policy["operator_review_risk_limit"],
          "blocked_risk_types" => policy["blocked_risk_types"]
        }
      }
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)
      |> Map.new()

    {status, enriched_requirements, rule_matches, decision}
  end

  defp policy_decision_approval_requirement_count(rule_matches, _approval_requirements)
       when is_list(rule_matches) and rule_matches != [] do
    Enum.count(rule_matches, &(&1["classification"] == "operator_review_required"))
  end

  defp policy_decision_approval_requirement_count(_rule_matches, approval_requirements),
    do: length(approval_requirements)

  defp policy_decision_risk_count(rule_matches, _risk_indicators)
       when is_list(rule_matches) and rule_matches != [] do
    Enum.count(rule_matches, &is_binary(&1["risk_type"]))
  end

  defp policy_decision_risk_count(_rule_matches, risk_indicators), do: length(risk_indicators)

  defp policy_bundle(%{"policy_bundle" => %{} = bundle}) do
    normalize_inline_policy_bundle(bundle)
  end

  defp policy_bundle(%{"policy_bundle" => id}) when id not in [nil, ""], do: bundle!(id)
  defp policy_bundle(%{"policy_bundle_id" => id}) when id not in [nil, ""], do: bundle!(id)
  defp policy_bundle(%{"bundle" => id}) when id not in [nil, ""], do: bundle!(id)
  defp policy_bundle(_policy), do: nil

  defp normalize_inline_policy_bundle(bundle) do
    bundle = stringify_keys(bundle)

    unless Map.get(bundle, "schema_contract", "policy_bundle.v1") == "policy_bundle.v1" do
      raise ArgumentError, "inline policy bundle must use schema_contract policy_bundle.v1"
    end

    unless is_binary(Map.get(bundle, "id")) and Map.get(bundle, "id") != "" do
      raise ArgumentError, "inline policy bundle requires a non-empty id"
    end

    unless is_map(Map.get(bundle, "approval_policy")) do
      raise ArgumentError, "inline policy bundle requires an approval_policy map"
    end

    Map.put_new(bundle, "schema_contract", "policy_bundle.v1")
  end

  defp normalize_action_rules(rules) when is_list(rules) do
    rules
    |> Enum.with_index()
    |> Enum.map(fn {rule_input, index} ->
      unless is_map(rule_input) do
        raise ArgumentError, "policy action rule #{index + 1} must be a map"
      end

      rule = stringify_keys(rule_input)

      classification =
        Map.get(rule, "classification", Map.get(rule, "status", "operator_review_required"))

      unless classification in @classifications do
        raise ArgumentError, "policy classification must be one of #{inspect(@classifications)}"
      end

      rule
      |> normalize_rule_station_aliases()
      |> normalize_rule_station_status_fields()
      |> normalize_rule_direction_fields()
      |> normalize_action_rule_numeric_fields()
      |> Map.put_new("id", "approval_rule_#{index + 1}")
      |> Map.put("classification", classification)
      |> Map.put_new("reason", "approval_policy_action_rule")
      |> validate_action_rule!()
    end)
    |> validate_unique_action_rule_ids!()
    |> Enum.sort_by(& &1["id"])
  end

  defp normalize_action_rules(_rules), do: []

  defp validate_unique_action_rule_ids!(rules) do
    duplicate_ids =
      rules
      |> Enum.map(& &1["id"])
      |> Enum.frequencies()
      |> Enum.filter(fn {_id, count} -> count > 1 end)
      |> Enum.map(fn {id, _count} -> id end)

    if duplicate_ids != [] do
      raise ArgumentError,
            "policy action rule ids must be unique: #{Enum.join(Enum.sort(duplicate_ids), ", ")}"
    end

    rules
  end

  defp validate_approval_policy!(policy) do
    Enum.each(
      [
        "auto_approvable_risk_limit",
        "auto_approvable_approval_count_limit",
        "operator_review_risk_limit"
      ],
      fn field ->
        unless non_negative_integer?(policy[field]) do
          raise ArgumentError, "approval policy #{field} must be a non-negative integer"
        end
      end
    )

    case policy["blocked_risk_types"] do
      values when is_list(values) ->
        unless Enum.all?(values, &(is_binary(&1) and &1 != "")) do
          raise ArgumentError, "approval policy blocked_risk_types must be a list of strings"
        end

      _value ->
        raise ArgumentError, "approval policy blocked_risk_types must be a list of strings"
    end

    policy
  end

  defp non_negative_integer?(value), do: is_integer(value) and value >= 0

  defp normalize_non_negative_integer_field(policy, field, default) do
    value = Map.get(policy, field, default)

    case non_negative_integer_value(value) do
      nil -> value
      integer -> integer
    end
  end

  defp normalize_action_rule_numeric_fields(rule) do
    rule =
      Enum.reduce(@unit_interval_rule_fields, rule, fn field, rule ->
        normalize_numeric_field(rule, field)
      end)

    rule =
      Enum.reduce(@non_negative_number_rule_fields, rule, fn field, rule ->
        normalize_numeric_field(rule, field)
      end)

    rule =
      Enum.reduce(@non_negative_integer_rule_fields, rule, fn field, rule ->
        normalize_non_negative_integer_rule_field(rule, field)
      end)

    normalize_numeric_field(rule, "sla_s")
  end

  defp normalize_numeric_field(rule, field) do
    case Map.fetch(rule, field) do
      {:ok, value} ->
        case numeric_value(value) do
          nil -> rule
          number -> Map.put(rule, field, number)
        end

      :error ->
        rule
    end
  end

  defp normalize_non_negative_integer_rule_field(rule, field) do
    case Map.fetch(rule, field) do
      {:ok, value} ->
        case non_negative_integer_value(value) do
          nil -> rule
          integer -> Map.put(rule, field, integer)
        end

      :error ->
        rule
    end
  end

  defp non_negative_integer_value(value) when is_integer(value) and value >= 0, do: value

  defp non_negative_integer_value(value) when is_float(value) and value >= 0.0 do
    rounded = round(value)

    if rounded == value, do: rounded
  end

  defp non_negative_integer_value(value) when is_binary(value) do
    value
    |> numeric_value()
    |> non_negative_integer_value()
  end

  defp non_negative_integer_value(_value), do: nil

  defp numeric_value(value) when is_integer(value) or is_float(value), do: value

  defp numeric_value(value) when is_binary(value) do
    case Float.parse(String.trim(value)) do
      {number, ""} -> number
      _other -> nil
    end
  end

  defp numeric_value(_value), do: nil

  defp validate_action_rule!(rule) do
    unless stable_id?(rule["id"]) do
      raise ArgumentError, "policy action rule id must be a stable identifier"
    end

    Enum.each(@unit_interval_rule_fields, fn field ->
      case Map.get(rule, field) do
        nil ->
          :ok

        value when is_number(value) and value >= 0.0 and value <= 1.0 ->
          :ok

        _value ->
          raise ArgumentError, "policy action rule #{field} must be a number from 0.0 to 1.0"
      end
    end)

    Enum.each(@boolean_rule_fields, fn field ->
      case Map.get(rule, field) do
        nil ->
          :ok

        value when is_boolean(value) ->
          :ok

        _value ->
          raise ArgumentError, "policy action rule #{field} must be a boolean"
      end
    end)

    Enum.each(@non_negative_number_rule_fields, fn field ->
      case Map.get(rule, field) do
        nil ->
          :ok

        value when is_number(value) and value >= 0.0 ->
          :ok

        _value ->
          raise ArgumentError,
                "policy action rule #{field} must be a non-negative number"
      end
    end)

    Enum.each(@non_negative_integer_rule_fields, fn field ->
      case Map.get(rule, field) do
        nil ->
          :ok

        value when is_integer(value) and value >= 0 ->
          :ok

        _value ->
          raise ArgumentError,
                "policy action rule #{field} must be a non-negative integer"
      end
    end)

    Enum.each(@string_rule_fields, fn field ->
      case Map.get(rule, field) do
        nil ->
          :ok

        value when is_binary(value) and value != "" ->
          :ok

        _value ->
          raise ArgumentError, "policy action rule #{field} must be a non-empty string"
      end
    end)

    Enum.each(@string_list_rule_fields, fn field ->
      case Map.get(rule, field) do
        nil ->
          :ok

        values when is_list(values) ->
          unless Enum.all?(values, &(is_binary(&1) and &1 != "")) do
            raise ArgumentError,
                  "policy action rule #{field} must be a list of non-empty strings"
          end

        _value ->
          raise ArgumentError, "policy action rule #{field} must be a list of non-empty strings"
      end
    end)

    validate_cadence_import_status_rule!(rule)
    validate_policy_classification_rule!(rule)

    case Map.get(rule, "sla_s") do
      nil ->
        :ok

      value when is_number(value) ->
        :ok

      _value ->
        raise ArgumentError, "policy action rule sla_s must be a number"
    end

    rule
  end

  defp validate_cadence_import_status_rule!(rule) do
    allowed = cadence_import_statuses()

    case Map.get(rule, "cadence_import_status") do
      nil ->
        :ok

      value when is_binary(value) ->
        unless value in allowed do
          raise ArgumentError,
                "policy action rule cadence_import_status must be one of #{inspect(allowed)}"
        end

      _value ->
        :ok
    end

    case Map.get(rule, "cadence_import_statuses") do
      nil ->
        :ok

      values when is_list(values) ->
        unless Enum.all?(values, &(&1 in allowed)) do
          raise ArgumentError,
                "policy action rule cadence_import_statuses must use values from #{inspect(allowed)}"
        end

      _value ->
        :ok
    end
  end

  defp validate_policy_classification_rule!(rule) do
    case Map.get(rule, "policy_classification") do
      nil ->
        :ok

      value when is_binary(value) ->
        unless value in @classifications do
          raise ArgumentError,
                "policy action rule policy_classification must be one of #{inspect(@classifications)}"
        end

      _value ->
        :ok
    end

    case Map.get(rule, "policy_classifications") do
      nil ->
        :ok

      values when is_list(values) ->
        unless Enum.all?(values, &(&1 in @classifications)) do
          raise ArgumentError,
                "policy action rule policy_classifications must use values from #{inspect(@classifications)}"
        end

      _value ->
        :ok
    end
  end

  defp cadence_import_statuses do
    OrbitalDynamics.CadenceImport.capability().cadence_import_statuses
  end

  defp model_limits do
    __MODULE__.capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&to_string/1)
  end

  defp stable_id?(value) when is_binary(value), do: Regex.match?(@stable_id_pattern, value)
  defp stable_id?(_value), do: false

  defp normalize_rule_station_aliases(rule) do
    rule
    |> put_alias_if_missing("ground_station_id", "station_id")
    |> put_alias_if_missing("ground_station_ids", "station_ids")
  end

  defp put_alias_if_missing(rule, canonical, alias_field) do
    case {Map.get(rule, canonical), Map.get(rule, alias_field)} do
      {nil, alias_value} when not is_nil(alias_value) -> Map.put(rule, canonical, alias_value)
      _other -> rule
    end
  end

  defp normalize_rule_station_status_fields(rule) do
    rule
    |> normalize_status_field("station_availability")
    |> normalize_status_field("station_availabilities")
    |> normalize_status_field("station_contention_status")
    |> normalize_status_field("station_contention_statuses")
    |> normalize_status_field("station_reservation_status")
    |> normalize_status_field("station_reservation_statuses")
    |> normalize_status_field("station_reservation_match_status")
    |> normalize_status_field("station_reservation_match_statuses")
    |> normalize_status_field("station_calendar_reservation_status")
    |> normalize_status_field("station_calendar_reservation_statuses")
    |> normalize_status_field("station_calendar_status")
    |> normalize_status_field("station_calendar_statuses")
  end

  defp normalize_rule_direction_fields(rule) do
    rule
    |> normalize_direction_field("direction")
    |> normalize_direction_field("directions")
    |> normalize_direction_field("station_calendar_direction")
    |> normalize_direction_field("station_calendar_directions")
  end

  defp normalize_status_field(map, field) do
    case Map.fetch(map, field) do
      {:ok, value} -> Map.put(map, field, normalize_station_status_value(value))
      :error -> map
    end
  end

  defp approval_rule_matches(rule, approval_requirements, risk_indicators, branch, candidate_plan) do
    requirement_matches =
      approval_requirements
      |> Enum.filter(&approval_rule_requirement_match?(rule, &1))
      |> Enum.map(fn requirement ->
        %{
          "rule_id" => rule["id"],
          "classification" => rule["classification"],
          "reason" => rule["reason"],
          "action" => requirement["action"],
          "activity_id" => requirement["activity_id"],
          "activity_type" => requirement["activity_type"],
          "requirement_type" => requirement["requirement_type"],
          "spacecraft_id" => requirement_context_value(requirement, "spacecraft_id"),
          "spacecraft_ids" =>
            non_empty_list(requirement_context_values(requirement, "spacecraft_id")),
          "target_id" => requirement_context_value(requirement, "target_id"),
          "target_ids" => non_empty_list(requirement_context_values(requirement, "target_id")),
          "direction" => List.first(requirement_context_values(requirement, "direction")),
          "directions" => non_empty_list(requirement_context_values(requirement, "direction")),
          "ground_station_id" => requirement_context_value(requirement, "ground_station_id"),
          "ground_station_ids" =>
            non_empty_list(requirement_context_values(requirement, "ground_station_id")),
          "station_availability" =>
            requirement_context_value(requirement, "station_availability"),
          "station_availabilities" =>
            non_empty_list(requirement_context_values(requirement, "station_availability")),
          "capacity_fraction" => requirement_context_value(requirement, "capacity_fraction"),
          "required_capacity_fraction" =>
            requirement_context_value(requirement, "required_capacity_fraction"),
          "actual_completion_fraction" =>
            requirement_context_value(requirement, "actual_completion_fraction"),
          "station_contention_status" =>
            requirement_context_value(requirement, "station_contention_status"),
          "station_contention_statuses" =>
            non_empty_list(requirement_context_values(requirement, "station_contention_status")),
          "station_reservation_id" =>
            requirement_context_value(requirement, "station_reservation_id"),
          "station_reservation_ids" =>
            non_empty_list(requirement_context_values(requirement, "station_reservation_id")),
          "station_reserved_by" => requirement_context_value(requirement, "station_reserved_by"),
          "station_reserved_bys" =>
            non_empty_list(requirement_context_values(requirement, "station_reserved_by")),
          "station_reservation_status" =>
            requirement_context_value(requirement, "station_reservation_status"),
          "station_reservation_statuses" =>
            non_empty_list(requirement_context_values(requirement, "station_reservation_status")),
          "station_reservation_match_status" =>
            requirement_context_value(requirement, "station_reservation_match_status"),
          "station_reservation_match_statuses" =>
            non_empty_list(
              requirement_context_values(requirement, "station_reservation_match_status")
            ),
          "station_calendar_entry_id" =>
            requirement_context_value(requirement, "station_calendar_entry_id"),
          "station_calendar_entry_ids" =>
            non_empty_list(requirement_context_values(requirement, "station_calendar_entry_id")),
          "station_calendar_reserved_by" =>
            non_empty_list(
              requirement_context_values(requirement, "station_calendar_reserved_by")
            ),
          "station_calendar_reserved_bys" =>
            non_empty_list(
              requirement_context_values(requirement, "station_calendar_reserved_by")
            ),
          "station_calendar_reservation_status" =>
            requirement_context_value(requirement, "station_calendar_reservation_status") ||
              List.first(
                requirement_context_values(requirement, "station_calendar_reservation_status")
              ),
          "station_calendar_reservation_statuses" =>
            non_empty_list(
              requirement_context_values(requirement, "station_calendar_reservation_status")
            ),
          "station_calendar_reservation_expires_at_s" =>
            non_empty_list(
              requirement_context_values(requirement, "station_calendar_reservation_expires_at_s")
            ),
          "station_calendar_status" =>
            requirement_context_value(requirement, "station_calendar_status"),
          "station_calendar_statuses" =>
            non_empty_list(requirement_context_values(requirement, "station_calendar_status")),
          "station_calendar_entry_ambiguous" =>
            requirement_context_value(requirement, "station_calendar_entry_ambiguous"),
          "station_calendar_ambiguous_entry_count" =>
            requirement_context_value(requirement, "station_calendar_ambiguous_entry_count"),
          "contention_window_s" => requirement_context_value(requirement, "contention_window_s"),
          "total_contact_duration_s" =>
            requirement_context_value(requirement, "total_contact_duration_s"),
          "overlap_duration_s" => requirement_context_value(requirement, "overlap_duration_s"),
          "max_concurrent_contacts" =>
            requirement_context_value(requirement, "max_concurrent_contacts"),
          "overlap_contact_pair_count" =>
            requirement_context_value(requirement, "overlap_contact_pair_count"),
          "station_calendar_ambiguous_entry_ids" =>
            non_empty_list(
              requirement_context_values(requirement, "station_calendar_ambiguous_entry_id")
            ),
          "station_calendar_trust_boundary_status" =>
            requirement_context_value(requirement, "station_calendar_trust_boundary_status"),
          "station_calendar_trust_boundary_statuses" =>
            non_empty_list(
              requirement_context_values(requirement, "station_calendar_trust_boundary_status")
            ),
          "station_calendar_direction" =>
            List.first(requirement_context_values(requirement, "station_calendar_direction")),
          "station_calendar_directions" =>
            non_empty_list(requirement_context_values(requirement, "station_calendar_direction")),
          "resource_scope" => requirement_context_value(requirement, "resource_scope"),
          "resource_scopes" =>
            non_empty_list(requirement_context_values(requirement, "resource_scope")),
          "selection_reason" => requirement_context_value(requirement, "selection_reason"),
          "selection_reasons" =>
            non_empty_list(requirement_context_values(requirement, "selection_reason")),
          "selected_priority_source" =>
            requirement_context_value(requirement, "selected_priority_source"),
          "selected_priority_sources" =>
            non_empty_list(requirement_context_values(requirement, "selected_priority_source")),
          "priority_fields_without_numeric_evidence_count" =>
            requirement_context_value(
              requirement,
              "priority_fields_without_numeric_evidence_count"
            ),
          "priority_fields_without_numeric_evidence" =>
            non_empty_list(
              requirement_context_values(requirement, "priority_fields_without_numeric_evidence")
            ),
          "resolution_status" => requirement_context_value(requirement, "resolution_status"),
          "resolution_statuses" =>
            non_empty_list(requirement_context_values(requirement, "resolution_status")),
          "resolution_issue" => requirement_context_value(requirement, "resolution_issue"),
          "resolution_issues" =>
            non_empty_list(requirement_context_values(requirement, "resolution_issue")),
          "station_calendar_provider_ids" =>
            non_empty_list(
              requirement_context_values(requirement, "station_calendar_provider_id")
            ),
          "station_calendar_provider_entry_ids" =>
            non_empty_list(
              requirement_context_values(requirement, "station_calendar_provider_entry_id")
            ),
          "station_calendar_reservation_id" =>
            requirement_context_value(requirement, "station_calendar_reservation_id") ||
              List.first(
                requirement_context_values(requirement, "station_calendar_reservation_id")
              ),
          "station_calendar_reservation_ids" =>
            non_empty_list(
              requirement_context_values(requirement, "station_calendar_reservation_id")
            ),
          "required_operator_action" =>
            requirement_context_value(requirement, "required_operator_action"),
          "required_operator_actions" =>
            non_empty_list(requirement_context_values(requirement, "required_operator_action")),
          "operator_action_reason" =>
            requirement_context_value(requirement, "operator_action_reason"),
          "operator_action_reasons" =>
            non_empty_list(requirement_context_values(requirement, "operator_action_reason")),
          "allocation_status" => requirement_context_value(requirement, "allocation_status"),
          "allocation_statuses" =>
            non_empty_list(requirement_context_values(requirement, "allocation_status")),
          "effective_allocation_status" =>
            requirement_context_value(requirement, "effective_allocation_status"),
          "effective_allocation_statuses" =>
            non_empty_list(requirement_context_values(requirement, "effective_allocation_status")),
          "allocation_reason" => requirement_context_value(requirement, "allocation_reason"),
          "allocation_reasons" =>
            non_empty_list(requirement_context_values(requirement, "allocation_reason")),
          "suppressed_reason" => requirement_context_value(requirement, "suppressed_reason"),
          "suppressed_reasons" =>
            non_empty_list(requirement_context_values(requirement, "suppressed_reason")),
          "resource_blocking_dimension" =>
            requirement_context_value(requirement, "resource_blocking_dimension"),
          "resource_blocking_dimensions" =>
            non_empty_list(requirement_context_values(requirement, "resource_blocking_dimension")),
          "transition_decision" => requirement_context_value(requirement, "transition_decision"),
          "transition_decisions" =>
            non_empty_list(requirement_context_values(requirement, "transition_decision")),
          "application_status" => requirement_context_value(requirement, "application_status"),
          "application_statuses" =>
            non_empty_list(requirement_context_values(requirement, "application_status")),
          "planned_protection_decision" =>
            requirement_context_value(requirement, "planned_protection_decision"),
          "planned_protection_decisions" =>
            non_empty_list(requirement_context_values(requirement, "planned_protection_decision")),
          "planned_protection_category" =>
            requirement_context_value(requirement, "planned_protection_category"),
          "planned_protection_categories" =>
            non_empty_list(requirement_context_values(requirement, "planned_protection_category")),
          "timeline_integrity_status" =>
            requirement_context_value(requirement, "timeline_integrity_status"),
          "timeline_integrity_statuses" =>
            non_empty_list(requirement_context_values(requirement, "timeline_integrity_status")),
          "timeline_integrity_issue_types" =>
            non_empty_list(
              requirement_context_values(requirement, "timeline_integrity_issue_types")
            ),
          "source_timeline_integrity_status" =>
            requirement_context_value(requirement, "source_timeline_integrity_status"),
          "source_timeline_integrity_statuses" =>
            non_empty_list(
              requirement_context_values(requirement, "source_timeline_integrity_status")
            ),
          "source_timeline_integrity_issue_types" =>
            non_empty_list(
              requirement_context_values(requirement, "source_timeline_integrity_issue_types")
            ),
          "replacement_timeline_integrity_status" =>
            requirement_context_value(requirement, "replacement_timeline_integrity_status"),
          "replacement_timeline_integrity_statuses" =>
            non_empty_list(
              requirement_context_values(requirement, "replacement_timeline_integrity_status")
            ),
          "replacement_timeline_integrity_issue_types" =>
            non_empty_list(
              requirement_context_values(
                requirement,
                "replacement_timeline_integrity_issue_types"
              )
            ),
          "source_protection_decision" =>
            requirement_context_value(requirement, "source_protection_decision"),
          "source_protection_decisions" =>
            non_empty_list(requirement_context_values(requirement, "source_protection_decision")),
          "source_protection_category" =>
            requirement_context_value(requirement, "source_protection_category"),
          "source_protection_categories" =>
            non_empty_list(requirement_context_values(requirement, "source_protection_category")),
          "replacement_protection_decision" =>
            requirement_context_value(requirement, "replacement_protection_decision"),
          "replacement_protection_decisions" =>
            non_empty_list(
              requirement_context_values(requirement, "replacement_protection_decision")
            ),
          "replacement_protection_category" =>
            requirement_context_value(requirement, "replacement_protection_category"),
          "replacement_protection_categories" =>
            non_empty_list(
              requirement_context_values(requirement, "replacement_protection_category")
            ),
          "review_queue" => requirement_context_value(requirement, "review_queue"),
          "review_queues" =>
            non_empty_list(requirement_context_values(requirement, "review_queue")),
          "review_queue_key" => requirement_context_value(requirement, "review_queue_key"),
          "review_queue_keys" =>
            non_empty_list(requirement_context_values(requirement, "review_queue_key")),
          "cadence_import_status" =>
            requirement_context_value(requirement, "cadence_import_status"),
          "cadence_import_statuses" =>
            non_empty_list(requirement_context_values(requirement, "cadence_import_status")),
          "status" => requirement_context_value(requirement, "status"),
          "statuses" => non_empty_list(requirement_context_values(requirement, "status")),
          "approval_status" => requirement_context_value(requirement, "approval_status"),
          "approval_statuses" =>
            non_empty_list(requirement_context_values(requirement, "approval_status")),
          "policy_classification" =>
            requirement_context_value(requirement, "policy_classification"),
          "policy_classifications" =>
            non_empty_list(requirement_context_values(requirement, "policy_classification")),
          "locked" => requirement_context_value(requirement, "locked"),
          "degraded" => requirement_context_value(requirement, "degraded"),
          "payload_available" => requirement_context_value(requirement, "payload_available"),
          "antenna_available" => requirement_context_value(requirement, "antenna_available"),
          "contact_success" => requirement_context_value(requirement, "contact_success"),
          "contact_success_factor" =>
            requirement_context_value(requirement, "contact_success_factor"),
          "contact_success_factor_source" =>
            requirement_context_value(requirement, "contact_success_factor_source"),
          "contact_result" => provider_result_context_value(requirement, "contact_result"),
          "contact_results" =>
            non_empty_list(requirement_context_values(requirement, "contact_result")),
          "command_success" => requirement_context_value(requirement, "command_success"),
          "command_success_factor" =>
            requirement_context_value(requirement, "command_success_factor"),
          "command_success_factor_source" =>
            requirement_context_value(requirement, "command_success_factor_source"),
          "command_result" => provider_result_context_value(requirement, "command_result"),
          "command_results" =>
            non_empty_list(requirement_context_values(requirement, "command_result")),
          "observation_success_factor" =>
            requirement_context_value(requirement, "observation_success_factor"),
          "observation_success_factor_source" =>
            requirement_context_value(requirement, "observation_success_factor_source"),
          "observation_result" =>
            provider_result_context_value(requirement, "observation_result"),
          "observation_results" =>
            non_empty_list(requirement_context_values(requirement, "observation_result")),
          "maneuver_success_factor" =>
            requirement_context_value(requirement, "maneuver_success_factor"),
          "maneuver_success_factor_source" =>
            requirement_context_value(requirement, "maneuver_success_factor_source"),
          "maneuver_result" => provider_result_context_value(requirement, "maneuver_result"),
          "maneuver_results" =>
            non_empty_list(requirement_context_values(requirement, "maneuver_result")),
          "resource_pressure_status" =>
            requirement_context_value(requirement, "resource_pressure_status"),
          "resource_pressure_statuses" =>
            non_empty_list(requirement_context_values(requirement, "resource_pressure_status")),
          "resource_pressure_types" =>
            non_empty_list(requirement_context_values(requirement, "resource_pressure_types")),
          "resource_source_quality" =>
            requirement_context_value(requirement, "resource_source_quality"),
          "resource_source_qualities" =>
            non_empty_list(requirement_context_values(requirement, "resource_source_quality")),
          "resource_trust_boundary" =>
            requirement_context_value(requirement, "resource_trust_boundary"),
          "resource_trust_boundaries" =>
            non_empty_list(requirement_context_values(requirement, "resource_trust_boundary")),
          "resource_trust_boundary_status" =>
            requirement_context_value(requirement, "resource_trust_boundary_status"),
          "resource_trust_boundary_statuses" =>
            non_empty_list(
              requirement_context_values(requirement, "resource_trust_boundary_status")
            ),
          "first_resource_pressure_kind" =>
            requirement_context_value(requirement, "first_resource_pressure_kind"),
          "first_resource_pressure_kinds" =>
            non_empty_list(
              requirement_context_values(requirement, "first_resource_pressure_kind")
            ),
          "feedback_source" => requirement_context_value(requirement, "feedback_source"),
          "feedback_sources" =>
            non_empty_list(requirement_context_values(requirement, "feedback_source")),
          "feedback_scope" => requirement_context_value(requirement, "feedback_scope"),
          "feedback_scopes" =>
            non_empty_list(requirement_context_values(requirement, "feedback_scope")),
          "trust_boundary" => requirement_context_value(requirement, "trust_boundary"),
          "trust_boundaries" =>
            non_empty_list(requirement_context_values(requirement, "trust_boundary")),
          "source_event_type" => requirement_context_value(requirement, "source_event_type"),
          "source_event_types" =>
            non_empty_list(requirement_context_values(requirement, "source_event_type"))
        }
        |> add_rule_escalation_fields(rule)
        |> Enum.reject(fn {_key, value} -> is_nil(value) end)
        |> Map.new()
      end)

    risk_matches =
      risk_indicators
      |> Enum.filter(&approval_rule_risk_match?(rule, &1))
      |> Enum.map(fn risk ->
        %{
          "rule_id" => rule["id"],
          "classification" => rule["classification"],
          "reason" => rule["reason"],
          "risk_type" => risk["type"],
          "risk_reason" => risk["reason"],
          "ground_station_id" => risk_ground_station_id(risk),
          "spacecraft_id" => risk_spacecraft_id(risk),
          "target_id" => risk["target_id"],
          "station_availability" => risk_context_value(risk, "station_availability"),
          "station_contention_status" => risk_context_value(risk, "station_contention_status"),
          "station_calendar_entry_id" => risk_context_value(risk, "station_calendar_entry_id"),
          "station_calendar_entry_ids" =>
            non_empty_list(risk_context_values(risk, "station_calendar_entry_id")),
          "station_calendar_provider_id" =>
            risk_context_value(risk, "station_calendar_provider_id"),
          "station_calendar_provider_ids" =>
            non_empty_list(risk_context_values(risk, "station_calendar_provider_id")),
          "station_calendar_provider_entry_id" =>
            risk_context_value(risk, "station_calendar_provider_entry_id"),
          "station_calendar_provider_entry_ids" =>
            non_empty_list(risk_context_values(risk, "station_calendar_provider_entry_id")),
          "station_calendar_direction" =>
            List.first(risk_context_values(risk, "station_calendar_direction")),
          "station_calendar_directions" =>
            non_empty_list(risk_context_values(risk, "station_calendar_direction")),
          "station_calendar_status" => risk_context_value(risk, "station_calendar_status"),
          "station_calendar_statuses" =>
            non_empty_list(risk_context_values(risk, "station_calendar_status")),
          "station_calendar_trust_boundary_status" =>
            risk_context_value(risk, "station_calendar_trust_boundary_status"),
          "station_calendar_trust_boundary_statuses" =>
            non_empty_list(risk_context_values(risk, "station_calendar_trust_boundary_status")),
          "station_calendar_reservation_id" =>
            risk_context_value(risk, "station_calendar_reservation_id"),
          "station_calendar_reservation_ids" =>
            non_empty_list(risk_context_values(risk, "station_calendar_reservation_id")),
          "station_calendar_reserved_by" =>
            List.first(risk_context_values(risk, "station_calendar_reserved_by")),
          "station_calendar_reserved_bys" =>
            non_empty_list(risk_context_values(risk, "station_calendar_reserved_by")),
          "station_calendar_reservation_status" =>
            risk_context_value(risk, "station_calendar_reservation_status"),
          "station_calendar_reservation_statuses" =>
            non_empty_list(risk_context_values(risk, "station_calendar_reservation_status")),
          "station_calendar_reservation_expires_at_s" =>
            non_empty_list(risk_context_values(risk, "station_calendar_reservation_expires_at_s")),
          "station_reservation_id" => risk_context_value(risk, "station_reservation_id"),
          "station_reserved_by" => risk_context_value(risk, "station_reserved_by"),
          "station_reserved_bys" =>
            non_empty_list(risk_context_values(risk, "station_reserved_by")),
          "station_reservation_status" => risk_context_value(risk, "station_reservation_status"),
          "station_reservation_statuses" =>
            non_empty_list(risk_context_values(risk, "station_reservation_status")),
          "station_reservation_match_status" =>
            risk_context_value(risk, "station_reservation_match_status"),
          "station_reservation_match_statuses" =>
            non_empty_list(risk_context_values(risk, "station_reservation_match_status")),
          "direction" => risk_direction(risk),
          "directions" => non_empty_list(risk_direction_values(risk))
        }
        |> add_rule_escalation_fields(rule)
        |> Enum.reject(fn {_key, value} -> is_nil(value) end)
        |> Map.new()
      end)

    event_matches =
      branch["events"]
      |> Enum.filter(&approval_rule_event_match?(rule, &1))
      |> Enum.map(fn event ->
        %{
          "rule_id" => rule["id"],
          "classification" => rule["classification"],
          "reason" => rule["reason"],
          "event_type" => event["type"],
          "ground_station_id" => event_ground_station_id(event),
          "spacecraft_id" => event_spacecraft_id(event),
          "target_id" => event["target_id"],
          "activity_id" => event["activity_id"],
          "status" => event["status"],
          "approval_status" => event["approval_status"],
          "policy_classification" => event["policy_classification"],
          "allocation_status" => event["allocation_status"],
          "effective_allocation_status" => event["effective_allocation_status"],
          "allocation_reason" => event["allocation_reason"],
          "direction" => event_direction(event),
          "directions" => non_empty_list(event_direction_values(event)),
          "station_calendar_entry_id" => event["station_calendar_entry_id"],
          "station_calendar_entry_ids" =>
            non_empty_list(event_context_values(event, "station_calendar_entry_id")),
          "station_calendar_provider_id" => event["station_calendar_provider_id"],
          "station_calendar_provider_ids" =>
            non_empty_list(event_context_values(event, "station_calendar_provider_id")),
          "station_calendar_provider_entry_id" => event["station_calendar_provider_entry_id"],
          "station_calendar_provider_entry_ids" =>
            non_empty_list(event_context_values(event, "station_calendar_provider_entry_id")),
          "station_calendar_direction" =>
            List.first(event_context_values(event, "station_calendar_direction")),
          "station_calendar_directions" =>
            non_empty_list(event_context_values(event, "station_calendar_direction")),
          "station_calendar_status" => event["station_calendar_status"],
          "station_calendar_statuses" =>
            non_empty_list(event_context_values(event, "station_calendar_status")),
          "station_calendar_trust_boundary_status" =>
            event["station_calendar_trust_boundary_status"],
          "station_calendar_trust_boundary_statuses" =>
            non_empty_list(event_context_values(event, "station_calendar_trust_boundary_status")),
          "station_calendar_reservation_id" =>
            List.first(event_context_values(event, "station_calendar_reservation_id")),
          "station_calendar_reservation_ids" =>
            non_empty_list(event_context_values(event, "station_calendar_reservation_id")),
          "station_calendar_reserved_by" =>
            List.first(event_context_values(event, "station_calendar_reserved_by")),
          "station_calendar_reserved_bys" =>
            non_empty_list(event_context_values(event, "station_calendar_reserved_by")),
          "station_calendar_reservation_status" =>
            List.first(event_context_values(event, "station_calendar_reservation_status")),
          "station_calendar_reservation_statuses" =>
            non_empty_list(event_context_values(event, "station_calendar_reservation_status")),
          "station_calendar_reservation_expires_at_s" =>
            non_empty_list(
              event_context_values(event, "station_calendar_reservation_expires_at_s")
            ),
          "station_reservation_id" => event["station_reservation_id"] || event["reservation_id"],
          "station_reserved_by" => event["station_reserved_by"] || event["reserved_by"],
          "station_reservation_status" =>
            event["station_reservation_status"] || event["reservation_status"],
          "station_reservation_match_status" => event["station_reservation_match_status"],
          "feedback_source" => event["feedback_source"],
          "feedback_scope" => event["feedback_scope"],
          "trust_boundary" => event["trust_boundary"],
          "source_event_type" => event["type"]
        }
        |> add_rule_escalation_fields(rule)
        |> Enum.reject(fn {_key, value} -> is_nil(value) end)
        |> Map.new()
      end)

    feasibility_matches =
      candidate_plan
      |> Map.get("strategic_additions", [])
      |> Enum.filter(&approval_rule_feasibility_match?(rule, &1))
      |> Enum.map(fn activity ->
        %{
          "rule_id" => rule["id"],
          "classification" => rule["classification"],
          "reason" => rule["reason"],
          "activity_id" => activity["id"],
          "activity_type" => activity["type"],
          "ground_station_id" => activity_ground_station_id(activity),
          "spacecraft_id" => activity_spacecraft_id(activity),
          "target_id" => activity_target_id(activity),
          "direction" => activity_direction(activity),
          "directions" => non_empty_list(activity_direction_values(activity)),
          "feasibility_status" => get_in(activity, ["feasibility", "status"]),
          "feedback_source" => activity_provenance_value(activity, "feedback_source"),
          "feedback_scope" => activity_provenance_value(activity, "feedback_scope"),
          "trust_boundary" => activity_provenance_value(activity, "trust_boundary"),
          "source_event_type" => activity_provenance_value(activity, "source_event_type")
        }
        |> add_rule_escalation_fields(rule)
        |> Enum.reject(fn {_key, value} -> is_nil(value) end)
        |> Map.new()
      end)

    requirement_matches ++ risk_matches ++ event_matches ++ feasibility_matches
  end

  defp add_policy_bundle_provenance_fields(match, provenance) when is_map(provenance) do
    match
    |> maybe_put("policy_bundle_provenance_source", provenance["source"])
    |> maybe_put("policy_bundle_adapter", provenance["adapter"])
    |> maybe_put("policy_bundle_organization_id", provenance["organization_id"])
    |> maybe_put("policy_bundle_policy_source", provenance["policy_source"])
    |> maybe_put("policy_bundle_trust_boundary", provenance["trust_boundary"])
  end

  defp add_policy_bundle_provenance_fields(match, _provenance), do: match

  defp rule_match_sort_key(match) do
    {
      match["rule_id"] || "",
      match["activity_id"] || "",
      match["action"] || "",
      match["activity_type"] || "",
      match["requirement_type"] || "",
      match["risk_type"] || "",
      match["event_type"] || "",
      match["feasibility_status"] || "",
      match["ground_station_id"] || "",
      match["spacecraft_id"] || "",
      match["target_id"] || "",
      match["resource_scope"] || "",
      match["resolution_status"] || "",
      match["resolution_issue"] || "",
      match["allocation_status"] || "",
      match["effective_allocation_status"] || "",
      match["allocation_reason"] || "",
      match["selection_reason"] || "",
      match["selected_priority_source"] || "",
      match["station_contention_status"] || "",
      match["station_reservation_id"] || "",
      match["station_reserved_by"] || "",
      stable_sort_values(match["station_reserved_bys"]),
      match["station_reservation_status"] || "",
      stable_sort_values(match["station_reservation_statuses"]),
      match["station_reservation_match_status"] || "",
      stable_sort_values(match["station_reservation_match_statuses"]),
      match["station_calendar_entry_id"] || "",
      stable_sort_values(match["station_calendar_entry_ids"]),
      stable_sort_values(match["station_calendar_provider_ids"]),
      stable_sort_values(match["station_calendar_provider_entry_ids"]),
      match["station_calendar_status"] || "",
      stable_sort_values(match["station_calendar_statuses"]),
      stable_sort_values(match["station_calendar_reservation_ids"]),
      stable_sort_values(match["station_calendar_reservation_expires_at_s"]),
      match["risk_reason"] || "",
      match["reason"] || ""
    }
  end

  defp stable_sort_values(values) when is_list(values) do
    values
    |> Enum.map(&to_string/1)
    |> Enum.sort()
    |> Enum.join("|")
  end

  defp stable_sort_values(value) when is_binary(value), do: value
  defp stable_sort_values(_value), do: ""

  defp approval_rule_requirement_match?(rule, requirement) do
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
          rule["direction"] in requirement_context_values(requirement, "direction")

        not is_nil(rule["directions"]) ->
          Enum.any?(
            requirement_context_values(requirement, "direction"),
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
          requirement_context_value(requirement, "station_calendar_entry_ambiguous")
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
        requirement_context_value(requirement, "station_calendar_ambiguous_entry_count"),
        rule["station_calendar_ambiguous_entry_count_min"],
        rule["station_calendar_ambiguous_entry_count_max"]
      )

    contention_window_s_match? =
      non_negative_number_min_match?(
        requirement_context_value(requirement, "contention_window_s"),
        rule["contention_window_s_min"]
      )

    total_contact_duration_s_match? =
      non_negative_number_min_match?(
        requirement_context_value(requirement, "total_contact_duration_s"),
        rule["total_contact_duration_s_min"]
      )

    overlap_duration_s_match? =
      non_negative_number_min_match?(
        requirement_context_value(requirement, "overlap_duration_s"),
        rule["overlap_duration_s_min"]
      )

    max_concurrent_contacts_match? =
      non_negative_integer_range_match?(
        requirement_context_value(requirement, "max_concurrent_contacts"),
        rule["max_concurrent_contacts_min"],
        nil
      )

    overlap_contact_pair_count_match? =
      non_negative_integer_range_match?(
        requirement_context_value(requirement, "overlap_contact_pair_count"),
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
        requirement_context_value(requirement, "priority_fields_without_numeric_evidence_count"),
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
        requirement_context_value(requirement, "capacity_fraction"),
        rule["capacity_fraction_min"],
        rule["capacity_fraction_max"]
      )

    actual_completion_fraction_match? =
      capacity_fraction_match?(
        requirement_context_value(requirement, "actual_completion_fraction"),
        rule["actual_completion_fraction_min"],
        rule["actual_completion_fraction_max"]
      )

    contact_success_match? =
      if is_nil(rule["contact_success"]) do
        true
      else
        rule["contact_success"] == requirement_context_value(requirement, "contact_success")
      end

    contact_success_factor_match? =
      capacity_fraction_match?(
        requirement_context_value(requirement, "contact_success_factor"),
        rule["contact_success_factor_min"],
        rule["contact_success_factor_max"]
      )

    contact_result_match? =
      provider_result_match?(rule, requirement, "contact_result", "contact_results")

    command_success_match? =
      if is_nil(rule["command_success"]) do
        true
      else
        rule["command_success"] == requirement_context_value(requirement, "command_success")
      end

    command_success_factor_match? =
      capacity_fraction_match?(
        requirement_context_value(requirement, "command_success_factor"),
        rule["command_success_factor_min"],
        rule["command_success_factor_max"]
      )

    command_result_match? =
      provider_result_match?(rule, requirement, "command_result", "command_results")

    observation_success_factor_match? =
      capacity_fraction_match?(
        requirement_context_value(requirement, "observation_success_factor"),
        rule["observation_success_factor_min"],
        rule["observation_success_factor_max"]
      )

    observation_result_match? =
      provider_result_match?(rule, requirement, "observation_result", "observation_results")

    maneuver_success_factor_match? =
      capacity_fraction_match?(
        requirement_context_value(requirement, "maneuver_success_factor"),
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
        rule["locked"] == requirement_context_value(requirement, "locked")
      end

    degraded_match? =
      if is_nil(rule["degraded"]) do
        true
      else
        rule["degraded"] == requirement_context_value(requirement, "degraded")
      end

    payload_available_match? =
      if is_nil(rule["payload_available"]) do
        true
      else
        rule["payload_available"] == requirement_context_value(requirement, "payload_available")
      end

    antenna_available_match? =
      if is_nil(rule["antenna_available"]) do
        true
      else
        rule["antenna_available"] == requirement_context_value(requirement, "antenna_available")
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
          requirement_context_values(requirement, field),
          &(&1 in rule_values)
        )

      not is_nil(rule[plural_rule_field]) ->
        Enum.any?(
          requirement_context_values(requirement, field),
          &(&1 in List.wrap(rule[plural_rule_field]))
        )

      true ->
        true
    end
  end

  defp provider_result_match?(rule, requirement, singular_rule_field, plural_rule_field) do
    cond do
      not is_nil(rule[singular_rule_field]) ->
        normalize_provider_result_token(rule[singular_rule_field]) in requirement_context_values(
          requirement,
          singular_rule_field
        )

      not is_nil(rule[plural_rule_field]) ->
        rule_values =
          rule[plural_rule_field]
          |> List.wrap()
          |> Enum.map(&normalize_provider_result_token/1)
          |> Enum.reject(&(&1 in [nil, ""]))

        Enum.any?(
          requirement_context_values(requirement, singular_rule_field),
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

  defp requirement_context_value(requirement, field),
    do: RequirementContext.value(requirement, field)

  defp requirement_context_values(requirement, field),
    do: RequirementContext.values(requirement, field)

  defp normalize_station_status_value(value),
    do: RequirementContext.normalize_station_status(value)

  defp normalize_direction_field(map, field),
    do: RequirementContext.normalize_direction_field(map, field)

  defp normalize_direction_value(value),
    do: RequirementContext.normalize_direction(value)

  defp direction_values(value),
    do: RequirementContext.direction_values(value)

  defp canonical_direction_values(value),
    do: RequirementContext.canonical_direction_values(value)

  defp provider_result_context_value(requirement, field),
    do: RequirementContext.provider_result_context_value(requirement, field)

  defp normalize_provider_result_token(value),
    do: RequirementContext.normalize_provider_result_token(value)

  defp approval_rule_risk_match?(rule, risk) do
    risk_type_match? =
      cond do
        not is_nil(rule["risk_type"]) ->
          rule["risk_type"] == risk["type"]

        not is_nil(rule["risk_types"]) ->
          risk["type"] in List.wrap(rule["risk_types"])

        true ->
          false
      end

    risk_type_match? and risk_direction_match?(rule, risk) and
      risk_ground_station_match?(rule, risk) and risk_spacecraft_match?(rule, risk) and
      risk_target_match?(rule, risk) and
      risk_context_match?(
        rule,
        risk,
        "station_availability",
        "station_availabilities",
        "station_availability"
      ) and
      risk_context_match?(
        rule,
        risk,
        "station_contention_status",
        "station_contention_statuses",
        "station_contention_status"
      ) and
      risk_context_match?(
        rule,
        risk,
        "station_reservation_id",
        "station_reservation_ids",
        "station_reservation_id"
      ) and
      risk_context_match?(
        rule,
        risk,
        "station_reserved_by",
        "station_reserved_bys",
        "station_reserved_by"
      ) and
      risk_context_match?(
        rule,
        risk,
        "station_reservation_status",
        "station_reservation_statuses",
        "station_reservation_status"
      ) and
      risk_context_match?(
        rule,
        risk,
        "station_reservation_match_status",
        "station_reservation_match_statuses",
        "station_reservation_match_status"
      ) and
      risk_context_match?(
        rule,
        risk,
        "station_calendar_entry_id",
        "station_calendar_entry_ids",
        "station_calendar_entry_id"
      ) and
      risk_context_match?(
        rule,
        risk,
        "station_calendar_provider_id",
        "station_calendar_provider_ids",
        "station_calendar_provider_id"
      ) and
      risk_context_match?(
        rule,
        risk,
        "station_calendar_provider_entry_id",
        "station_calendar_provider_entry_ids",
        "station_calendar_provider_entry_id"
      ) and
      risk_context_match?(
        rule,
        risk,
        "station_calendar_direction",
        "station_calendar_directions",
        "station_calendar_direction"
      ) and
      risk_context_match?(
        rule,
        risk,
        "station_calendar_status",
        "station_calendar_statuses",
        "station_calendar_status"
      ) and
      risk_context_match?(
        rule,
        risk,
        "station_calendar_trust_boundary_status",
        "station_calendar_trust_boundary_statuses",
        "station_calendar_trust_boundary_status"
      ) and
      risk_context_match?(
        rule,
        risk,
        "station_calendar_reservation_id",
        "station_calendar_reservation_ids",
        "station_calendar_reservation_id"
      ) and
      risk_context_match?(
        rule,
        risk,
        "station_calendar_reserved_by",
        "station_calendar_reserved_bys",
        "station_calendar_reserved_by"
      ) and
      risk_context_match?(
        rule,
        risk,
        "station_calendar_reservation_status",
        "station_calendar_reservation_statuses",
        "station_calendar_reservation_status"
      )
  end

  defp risk_direction_match?(rule, risk) do
    direction_match?(rule, risk_direction_values(risk))
  end

  defp risk_direction(%{"direction" => direction}) when is_binary(direction),
    do: normalize_direction_value(direction)

  defp risk_direction(%{"direction" => direction}) when is_atom(direction),
    do: normalize_direction_value(direction)

  defp risk_direction(%{"directions" => directions}) when is_list(directions) do
    directions
    |> canonical_direction_values()
    |> Enum.find(&(is_binary(&1) and &1 != ""))
  end

  defp risk_direction(_risk), do: nil

  defp risk_direction_values(risk) do
    (canonical_direction_values(Map.get(risk, "direction")) ++
       canonical_direction_values(Map.get(risk, "directions")))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  defp risk_ground_station_match?(rule, risk) do
    risk_station_id = risk_ground_station_id(risk)

    cond do
      not is_nil(rule["ground_station_id"]) ->
        rule["ground_station_id"] == risk_station_id

      not is_nil(rule["ground_station_ids"]) ->
        risk_station_id in List.wrap(rule["ground_station_ids"])

      true ->
        true
    end
  end

  defp risk_ground_station_id(risk) do
    Map.get(risk, "ground_station_id") || Map.get(risk, "station_id")
  end

  defp risk_spacecraft_match?(rule, risk) do
    risk_spacecraft_id = risk_spacecraft_id(risk)

    cond do
      not is_nil(rule["spacecraft_id"]) ->
        rule["spacecraft_id"] == risk_spacecraft_id

      not is_nil(rule["spacecraft_ids"]) ->
        risk_spacecraft_id in List.wrap(rule["spacecraft_ids"])

      true ->
        true
    end
  end

  defp risk_spacecraft_id(risk) do
    Map.get(risk, "spacecraft_id") || Map.get(risk, "scenario_id")
  end

  defp risk_context_match?(rule, risk, singular_rule_field, plural_rule_field, field) do
    values = risk_context_values(risk, field)

    cond do
      not is_nil(rule[singular_rule_field]) ->
        rule[singular_rule_field] in values

      not is_nil(rule[plural_rule_field]) ->
        Enum.any?(values, &(&1 in List.wrap(rule[plural_rule_field])))

      true ->
        true
    end
  end

  defp risk_context_value(risk, field) do
    risk
    |> risk_context_values(field)
    |> List.first()
  end

  defp risk_context_values(risk, "station_reservation_id") do
    direction_values(Map.get(risk, "station_reservation_id")) ++
      direction_values(Map.get(risk, "reservation_id")) ++
      direction_values(Map.get(risk, "station_reservation_ids"))
  end

  defp risk_context_values(risk, "station_reserved_by") do
    direction_values(Map.get(risk, "station_reserved_by")) ++
      direction_values(Map.get(risk, "reserved_by")) ++
      direction_values(Map.get(risk, "station_reserved_bys"))
  end

  defp risk_context_values(risk, "station_reservation_status") do
    direction_values(Map.get(risk, "station_reservation_status")) ++
      direction_values(Map.get(risk, "reservation_status")) ++
      direction_values(Map.get(risk, "station_reservation_statuses"))
  end

  defp risk_context_values(risk, "station_reservation_match_status") do
    direction_values(Map.get(risk, "station_reservation_match_status")) ++
      direction_values(Map.get(risk, "reservation_match_status")) ++
      direction_values(Map.get(risk, "station_reservation_match_statuses"))
  end

  defp risk_context_values(risk, "station_calendar_provider_id") do
    direction_values(Map.get(risk, "station_calendar_provider_id")) ++
      direction_values(Map.get(risk, "station_calendar_provider_ids"))
  end

  defp risk_context_values(risk, "station_calendar_provider_entry_id") do
    direction_values(Map.get(risk, "station_calendar_provider_entry_id")) ++
      direction_values(Map.get(risk, "station_calendar_provider_entry_ids"))
  end

  defp risk_context_values(risk, "station_calendar_entry_id") do
    direction_values(Map.get(risk, "station_calendar_entry_id")) ++
      direction_values(Map.get(risk, "station_calendar_entry_ids"))
  end

  defp risk_context_values(risk, "station_calendar_direction") do
    canonical_direction_values(Map.get(risk, "station_calendar_direction")) ++
      canonical_direction_values(Map.get(risk, "station_calendar_directions"))
  end

  defp risk_context_values(risk, "station_calendar_status") do
    direction_values(Map.get(risk, "station_calendar_status")) ++
      direction_values(Map.get(risk, "station_calendar_statuses"))
  end

  defp risk_context_values(risk, "station_calendar_trust_boundary_status") do
    direction_values(Map.get(risk, "station_calendar_trust_boundary_status")) ++
      direction_values(Map.get(risk, "station_calendar_trust_boundary_statuses"))
  end

  defp risk_context_values(risk, "station_calendar_reservation_id") do
    direction_values(Map.get(risk, "station_calendar_reservation_id")) ++
      direction_values(Map.get(risk, "station_calendar_reservation_ids")) ++
      direction_values(Map.get(risk, "station_reservation_id")) ++
      direction_values(Map.get(risk, "reservation_id")) ++
      direction_values(Map.get(risk, "station_reservation_ids"))
  end

  defp risk_context_values(risk, "station_calendar_reserved_by") do
    direction_values(Map.get(risk, "station_calendar_reserved_by")) ++
      direction_values(Map.get(risk, "station_calendar_reserved_bys")) ++
      direction_values(Map.get(risk, "station_reserved_by")) ++
      direction_values(Map.get(risk, "reserved_by")) ++
      direction_values(Map.get(risk, "station_reserved_bys"))
  end

  defp risk_context_values(risk, "station_calendar_reservation_status") do
    direction_values(Map.get(risk, "station_calendar_reservation_status")) ++
      direction_values(Map.get(risk, "station_calendar_reservation_statuses")) ++
      direction_values(Map.get(risk, "station_reservation_status")) ++
      direction_values(Map.get(risk, "reservation_status")) ++
      direction_values(Map.get(risk, "station_reservation_statuses"))
  end

  defp risk_context_values(risk, field) do
    risk
    |> Map.get(field)
    |> direction_values()
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  defp risk_target_match?(rule, risk) do
    cond do
      not is_nil(rule["target_id"]) ->
        rule["target_id"] == risk["target_id"]

      not is_nil(rule["target_ids"]) ->
        risk["target_id"] in List.wrap(rule["target_ids"])

      true ->
        true
    end
  end

  defp approval_rule_event_match?(rule, event) do
    event_type_match? =
      cond do
        not is_nil(rule["event_type"]) ->
          rule["event_type"] == event["type"]

        not is_nil(rule["event_types"]) ->
          event["type"] in List.wrap(rule["event_types"])

        true ->
          false
      end

    event_type_match? and event_direction_match?(rule, event) and
      event_ground_station_match?(rule, event) and event_spacecraft_match?(rule, event) and
      event_target_match?(rule, event) and event_status_match?(rule, event) and
      event_allocation_match?(rule, event) and event_station_calendar_match?(rule, event) and
      event_provenance_match?(rule, event)
  end

  defp event_status_match?(rule, event) do
    event_context_match?(rule, event, "status", "statuses", "status") and
      event_context_match?(rule, event, "approval_status", "approval_statuses", "approval_status") and
      event_context_match?(
        rule,
        event,
        "policy_classification",
        "policy_classifications",
        "policy_classification"
      )
  end

  defp event_allocation_match?(rule, event) do
    event_context_match?(
      rule,
      event,
      "allocation_status",
      "allocation_statuses",
      "allocation_status"
    ) and
      event_context_match?(
        rule,
        event,
        "effective_allocation_status",
        "effective_allocation_statuses",
        "effective_allocation_status"
      ) and
      event_context_match?(
        rule,
        event,
        "allocation_reason",
        "allocation_reasons",
        "allocation_reason"
      )
  end

  defp event_station_calendar_match?(rule, event) do
    event_context_match?(
      rule,
      event,
      "station_calendar_entry_id",
      "station_calendar_entry_ids",
      "station_calendar_entry_id"
    ) and
      event_context_match?(
        rule,
        event,
        "station_calendar_provider_id",
        "station_calendar_provider_ids",
        "station_calendar_provider_id"
      ) and
      event_context_match?(
        rule,
        event,
        "station_calendar_provider_entry_id",
        "station_calendar_provider_entry_ids",
        "station_calendar_provider_entry_id"
      ) and
      event_context_match?(
        rule,
        event,
        "station_calendar_direction",
        "station_calendar_directions",
        "station_calendar_direction"
      ) and
      event_context_match?(
        rule,
        event,
        "station_calendar_status",
        "station_calendar_statuses",
        "station_calendar_status"
      ) and
      event_context_match?(
        rule,
        event,
        "station_calendar_trust_boundary_status",
        "station_calendar_trust_boundary_statuses",
        "station_calendar_trust_boundary_status"
      ) and
      event_context_match?(
        rule,
        event,
        "station_calendar_reservation_id",
        "station_calendar_reservation_ids",
        "station_calendar_reservation_id"
      ) and
      event_context_match?(
        rule,
        event,
        "station_calendar_reserved_by",
        "station_calendar_reserved_bys",
        "station_calendar_reserved_by"
      ) and
      event_context_match?(
        rule,
        event,
        "station_calendar_reservation_status",
        "station_calendar_reservation_statuses",
        "station_calendar_reservation_status"
      )
  end

  defp event_provenance_match?(rule, event) do
    event_context_match?(rule, event, "feedback_source", "feedback_sources", "feedback_source") and
      event_context_match?(rule, event, "feedback_scope", "feedback_scopes", "feedback_scope") and
      event_context_match?(rule, event, "trust_boundary", "trust_boundaries", "trust_boundary") and
      event_context_match?(rule, event, "source_event_type", "source_event_types", "type")
  end

  defp event_context_match?(rule, event, singular_rule_field, plural_rule_field, field) do
    values = event_context_values(event, field)

    cond do
      not is_nil(rule[singular_rule_field]) ->
        rule[singular_rule_field] in values

      not is_nil(rule[plural_rule_field]) ->
        Enum.any?(values, &(&1 in List.wrap(rule[plural_rule_field])))

      true ->
        true
    end
  end

  defp event_context_values(event, "station_calendar_provider_id") do
    direction_values(Map.get(event, "station_calendar_provider_id")) ++
      direction_values(Map.get(event, "station_calendar_provider_ids"))
  end

  defp event_context_values(event, "station_calendar_provider_entry_id") do
    direction_values(Map.get(event, "station_calendar_provider_entry_id")) ++
      direction_values(Map.get(event, "station_calendar_provider_entry_ids"))
  end

  defp event_context_values(event, "station_calendar_entry_id") do
    direction_values(Map.get(event, "station_calendar_entry_id")) ++
      direction_values(Map.get(event, "station_calendar_entry_ids"))
  end

  defp event_context_values(event, "station_calendar_direction") do
    canonical_direction_values(Map.get(event, "station_calendar_direction")) ++
      canonical_direction_values(Map.get(event, "station_calendar_directions"))
  end

  defp event_context_values(event, "station_calendar_status") do
    direction_values(Map.get(event, "station_calendar_status")) ++
      direction_values(Map.get(event, "station_calendar_statuses"))
  end

  defp event_context_values(event, "station_calendar_trust_boundary_status") do
    direction_values(Map.get(event, "station_calendar_trust_boundary_status")) ++
      direction_values(Map.get(event, "station_calendar_trust_boundary_statuses"))
  end

  defp event_context_values(event, "station_calendar_reservation_id") do
    direction_values(Map.get(event, "station_calendar_reservation_id")) ++
      direction_values(Map.get(event, "station_calendar_reservation_ids")) ++
      direction_values(Map.get(event, "station_reservation_id")) ++
      direction_values(Map.get(event, "reservation_id")) ++
      direction_values(Map.get(event, "station_reservation_ids"))
  end

  defp event_context_values(event, "station_calendar_reserved_by") do
    direction_values(Map.get(event, "station_calendar_reserved_by")) ++
      direction_values(Map.get(event, "station_calendar_reserved_bys")) ++
      direction_values(Map.get(event, "station_reserved_by")) ++
      direction_values(Map.get(event, "reserved_by")) ++
      direction_values(Map.get(event, "station_reserved_bys"))
  end

  defp event_context_values(event, "station_calendar_reservation_status") do
    direction_values(Map.get(event, "station_calendar_reservation_status")) ++
      direction_values(Map.get(event, "station_calendar_reservation_statuses")) ++
      direction_values(Map.get(event, "station_reservation_status")) ++
      direction_values(Map.get(event, "reservation_status")) ++
      direction_values(Map.get(event, "station_reservation_statuses"))
  end

  defp event_context_values(event, field) do
    event
    |> Map.get(field)
    |> direction_values()
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  defp event_direction_match?(rule, event) do
    direction_match?(rule, event_direction_values(event))
  end

  defp event_direction(%{"direction" => direction}) when is_binary(direction),
    do: normalize_direction_value(direction)

  defp event_direction(%{"direction" => direction}) when is_atom(direction),
    do: normalize_direction_value(direction)

  defp event_direction(%{"directions" => directions}) when is_list(directions) do
    directions
    |> canonical_direction_values()
    |> Enum.find(&(is_binary(&1) and &1 != ""))
  end

  defp event_direction(_event), do: nil

  defp event_direction_values(event) do
    (canonical_direction_values(Map.get(event, "direction")) ++
       canonical_direction_values(Map.get(event, "directions")))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  defp event_ground_station_match?(rule, event) do
    event_station_id = event_ground_station_id(event)

    cond do
      not is_nil(rule["ground_station_id"]) ->
        rule["ground_station_id"] == event_station_id

      not is_nil(rule["ground_station_ids"]) ->
        event_station_id in List.wrap(rule["ground_station_ids"])

      true ->
        true
    end
  end

  defp event_ground_station_id(event) do
    Map.get(event, "ground_station_id") || Map.get(event, "station_id")
  end

  defp event_spacecraft_match?(rule, event) do
    event_spacecraft_id = event_spacecraft_id(event)

    cond do
      not is_nil(rule["spacecraft_id"]) ->
        rule["spacecraft_id"] == event_spacecraft_id

      not is_nil(rule["spacecraft_ids"]) ->
        event_spacecraft_id in List.wrap(rule["spacecraft_ids"])

      true ->
        true
    end
  end

  defp event_spacecraft_id(event) do
    Map.get(event, "spacecraft_id") || Map.get(event, "scenario_id")
  end

  defp event_target_match?(rule, event) do
    cond do
      not is_nil(rule["target_id"]) ->
        rule["target_id"] == event["target_id"]

      not is_nil(rule["target_ids"]) ->
        event["target_id"] in List.wrap(rule["target_ids"])

      true ->
        true
    end
  end

  defp approval_rule_feasibility_match?(rule, activity) do
    not is_nil(rule["feasibility_status"]) and
      rule["feasibility_status"] == get_in(activity, ["feasibility", "status"]) and
      activity_direction_match?(rule, activity) and
      activity_ground_station_match?(rule, activity) and
      activity_spacecraft_match?(rule, activity) and
      activity_target_match?(rule, activity) and
      activity_provenance_match?(rule, activity)
  end

  defp activity_provenance_match?(rule, activity) do
    activity_context_match?(
      rule,
      activity,
      "feedback_source",
      "feedback_sources",
      "feedback_source"
    ) and
      activity_context_match?(
        rule,
        activity,
        "feedback_scope",
        "feedback_scopes",
        "feedback_scope"
      ) and
      activity_context_match?(
        rule,
        activity,
        "trust_boundary",
        "trust_boundaries",
        "trust_boundary"
      ) and
      activity_context_match?(
        rule,
        activity,
        "source_event_type",
        "source_event_types",
        "source_event_type"
      )
  end

  defp activity_context_match?(rule, activity, singular_rule_field, plural_rule_field, field) do
    values = activity_context_values(activity, field)

    cond do
      not is_nil(rule[singular_rule_field]) ->
        rule[singular_rule_field] in values

      not is_nil(rule[plural_rule_field]) ->
        Enum.any?(values, &(&1 in List.wrap(rule[plural_rule_field])))

      true ->
        true
    end
  end

  defp activity_provenance_value(activity, field) do
    activity_context_values(activity, field)
    |> List.first()
  end

  defp activity_context_values(activity, field) do
    (direction_values(Map.get(activity, field)) ++
       direction_values(get_in(activity, ["feasibility", field])))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  defp activity_direction_match?(rule, activity) do
    direction_match?(rule, activity_direction_values(activity))
  end

  defp activity_direction(%{"direction" => direction}) when is_binary(direction),
    do: normalize_direction_value(direction)

  defp activity_direction(%{"direction" => direction}) when is_atom(direction),
    do: normalize_direction_value(direction)

  defp activity_direction(%{"directions" => directions}) when is_list(directions) do
    directions
    |> canonical_direction_values()
    |> Enum.find(&(is_binary(&1) and &1 != ""))
  end

  defp activity_direction(%{"feasibility" => %{} = feasibility}),
    do: activity_direction(feasibility)

  defp activity_direction(_activity), do: nil

  defp activity_direction_values(activity) do
    (canonical_direction_values(Map.get(activity, "direction")) ++
       canonical_direction_values(Map.get(activity, "directions")) ++
       canonical_direction_values(get_in(activity, ["feasibility", "direction"])) ++
       canonical_direction_values(get_in(activity, ["feasibility", "directions"])))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  defp direction_match?(rule, values) do
    cond do
      not is_nil(rule["direction"]) ->
        rule["direction"] in values

      not is_nil(rule["directions"]) ->
        Enum.any?(values, &(&1 in List.wrap(rule["directions"])))

      true ->
        true
    end
  end

  defp activity_ground_station_match?(rule, activity) do
    activity_station_id = activity_ground_station_id(activity)

    cond do
      not is_nil(rule["ground_station_id"]) ->
        rule["ground_station_id"] == activity_station_id

      not is_nil(rule["ground_station_ids"]) ->
        activity_station_id in List.wrap(rule["ground_station_ids"])

      true ->
        true
    end
  end

  defp activity_ground_station_id(activity) do
    Map.get(activity, "ground_station_id") || Map.get(activity, "station_id") ||
      get_in(activity, ["feasibility", "ground_station_id"]) ||
      get_in(activity, ["feasibility", "station_id"])
  end

  defp activity_spacecraft_match?(rule, activity) do
    activity_spacecraft_id = activity_spacecraft_id(activity)

    cond do
      not is_nil(rule["spacecraft_id"]) ->
        rule["spacecraft_id"] == activity_spacecraft_id

      not is_nil(rule["spacecraft_ids"]) ->
        activity_spacecraft_id in List.wrap(rule["spacecraft_ids"])

      true ->
        true
    end
  end

  defp activity_spacecraft_id(activity) do
    Map.get(activity, "spacecraft_id") || Map.get(activity, "scenario_id") ||
      get_in(activity, ["feasibility", "spacecraft_id"]) ||
      get_in(activity, ["feasibility", "scenario_id"])
  end

  defp activity_target_match?(rule, activity) do
    activity_target_id = activity_target_id(activity)

    cond do
      not is_nil(rule["target_id"]) ->
        rule["target_id"] == activity_target_id

      not is_nil(rule["target_ids"]) ->
        activity_target_id in List.wrap(rule["target_ids"])

      true ->
        true
    end
  end

  defp activity_target_id(activity) do
    Map.get(activity, "target_id") || get_in(activity, ["feasibility", "target_id"])
  end

  defp strongest_classification(matches) do
    cond do
      Enum.any?(matches, &(&1["classification"] == "blocked_by_policy")) ->
        "blocked_by_policy"

      Enum.any?(matches, &(&1["classification"] == "operator_review_required")) ->
        "operator_review_required"

      true ->
        "auto_approvable"
    end
  end

  defp add_rule_escalation_fields(match, rule) do
    Enum.reduce(@escalation_fields, match, fn field, acc ->
      case Map.fetch(rule, field) do
        {:ok, value} -> Map.put(acc, field, value)
        :error -> acc
      end
    end)
  end

  defp escalation_summaries(rule_matches) do
    rule_matches
    |> Enum.map(fn match ->
      @escalation_fields
      |> Enum.reduce(
        %{"rule_id" => match["rule_id"], "classification" => match["classification"]},
        fn
          field, acc ->
            case Map.fetch(match, field) do
              {:ok, value} -> Map.put(acc, field, value)
              :error -> acc
            end
        end
      )
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)
      |> Map.new()
    end)
    |> Enum.filter(&(map_size(&1) > 2))
    |> Enum.uniq()
    |> Enum.sort_by(&{&1["escalation_level"] || "", &1["rule_id"] || ""})
  end

  defp non_empty_list([]), do: nil
  defp non_empty_list(values), do: values

  defp fallback_status(approval_requirements, risk_indicators, policy) do
    risk_count = length(risk_indicators)
    approval_count = length(approval_requirements)

    cond do
      Enum.any?(risk_indicators, &blocked_risk_indicator?(&1, policy["blocked_risk_types"])) ->
        "blocked_by_policy"

      risk_count <= policy["auto_approvable_risk_limit"] and
          approval_count <= policy["auto_approvable_approval_count_limit"] ->
        "auto_approvable"

      risk_count <= policy["operator_review_risk_limit"] ->
        "operator_review_required"

      true ->
        "blocked_by_policy"
    end
  end

  defp blocked_risk_indicator?(risk, blocked_risk_types) do
    Enum.any?(blocked_risk_types, &risk_matches_blocked_type?(risk, &1))
  end

  defp risk_matches_blocked_type?(%{"type" => type}, blocked_type) when type == blocked_type,
    do: true

  defp risk_matches_blocked_type?(
         %{"type" => "operational_readiness_pressure"} = risk,
         "operational_readiness_blocked"
       ) do
    blocked_value?(risk["operational_readiness_status"]) or
      blocked_value?(risk["readiness_gate_status"]) or
      blocked_value?(risk["import_classification"]) or
      blocked_value?(risk["readiness_gate_classification"]) or
      positive_count?(risk["blocked_gate_count"]) or
      risk["required_operator_action"] == "review_blocked_operational_readiness"
  end

  defp risk_matches_blocked_type?(
         %{"type" => "quality_gate_pressure"} = risk,
         "quality_gate_blocked"
       ) do
    blocked_value?(risk["quality_gate_status"]) or
      blocked_value?(risk["gate_status"]) or
      blocked_value?(risk["import_classification"]) or
      blocked_value?(risk["gate_classification"]) or
      positive_count?(risk["blocked_gate_count"]) or
      risk["required_operator_action"] == "review_blocked_operational_readiness"
  end

  defp risk_matches_blocked_type?(
         %{"type" => "operational_readiness_pressure"} = risk,
         "import_readiness_blocked"
       ) do
    blocked_import_readiness_pressure?(risk)
  end

  defp risk_matches_blocked_type?(
         %{"type" => "quality_gate_pressure"} = risk,
         "import_readiness_blocked"
       ) do
    blocked_import_readiness_pressure?(risk)
  end

  defp risk_matches_blocked_type?(
         %{"type" => "downlink_completion_gap", "feedback_scope" => "contact_intent"} = risk,
         "contact_intent_blocked"
       ) do
    blocked_value?(risk["contact_intent_gate_status"]) or
      blocked_value?(risk["policy_classification"]) or
      blocked_value?(risk["approval_status"])
  end

  defp risk_matches_blocked_type?(
         %{"type" => "downlink_completion_gap", "feedback_scope" => "link_capacity"} = risk,
         "link_capacity_blocked"
       ) do
    blocked_value?(risk["link_capacity_status"]) or
      blocked_value?(risk["downlink_requirement_status"]) or
      blocked_value?(risk["actual_downlink_requirement_status"]) or
      blocked_value?(risk["policy_classification"]) or
      blocked_value?(risk["approval_status"])
  end

  defp risk_matches_blocked_type?(
         %{"type" => "downlink_completion_gap", "feedback_scope" => "resource_projection"} =
           risk,
         "resource_projection_blocked"
       ) do
    blocked_value?(risk["resource_projection_status"]) or
      blocked_value?(risk["projected_resource_status"]) or
      blocked_value?(risk["policy_classification"]) or
      blocked_value?(risk["approval_status"])
  end

  defp risk_matches_blocked_type?(
         %{"type" => "downlink_completion_gap", "feedback_scope" => "contact_filter"} = risk,
         "contact_filter_blocked"
       ) do
    blocked_value?(risk["contact_filter_status"]) or
      blocked_value?(risk["suppression_status"]) or
      blocked_value?(risk["policy_classification"]) or
      blocked_value?(risk["approval_status"])
  end

  defp risk_matches_blocked_type?(
         %{"type" => "downlink_completion_gap", "feedback_scope" => scope} = risk,
         "contact_contention_blocked"
       )
       when scope in ["contact_contention", "contact_contention_resolution"] do
    blocked_value?(risk["policy_classification"]) or
      blocked_value?(risk["approval_status"])
  end

  defp risk_matches_blocked_type?(
         %{"feedback_scope" => "resource_filter"} = risk,
         "resource_filter_availability_blocked"
       ) do
    resource_availability_blocked?(risk) and
      (blocked_value?(risk["resource_filter_status"]) or
         blocked_value?(risk["suppression_status"]) or
         blocked_value?(risk["policy_classification"]) or
         blocked_value?(risk["approval_status"]) or
         risk["resource_availability_value"] == false)
  end

  defp risk_matches_blocked_type?(
         %{"type" => "model_acceptance_pressure"} = risk,
         "model_acceptance_blocked"
       ) do
    blocked_model_acceptance_pressure?(risk)
  end

  defp risk_matches_blocked_type?(
         %{"feedback_scope" => "model_acceptance"} = risk,
         "model_acceptance_blocked"
       ) do
    blocked_model_acceptance_pressure?(risk)
  end

  defp risk_matches_blocked_type?(
         %{"type" => "validation_safety_case_pressure"} = risk,
         "validation_safety_case_blocked"
       ) do
    blocked_validation_safety_case_pressure?(risk)
  end

  defp risk_matches_blocked_type?(
         %{"feedback_scope" => "validation_safety_case"} = risk,
         "validation_safety_case_blocked"
       ) do
    blocked_validation_safety_case_pressure?(risk)
  end

  defp risk_matches_blocked_type?(
         %{"type" => "schema_validation_pressure"} = risk,
         "schema_validation_blocked"
       ) do
    blocked_schema_validation_pressure?(risk)
  end

  defp risk_matches_blocked_type?(
         %{"feedback_scope" => "schema_validation"} = risk,
         "schema_validation_blocked"
       ) do
    blocked_schema_validation_pressure?(risk)
  end

  defp risk_matches_blocked_type?(
         %{"type" => "refresh_budget_pressure"} = risk,
         "refresh_budget_blocked"
       ) do
    blocked_refresh_budget_pressure?(risk)
  end

  defp risk_matches_blocked_type?(
         %{"feedback_scope" => "refresh_budget"} = risk,
         "refresh_budget_blocked"
       ) do
    blocked_refresh_budget_pressure?(risk)
  end

  defp risk_matches_blocked_type?(
         %{"type" => "refresh_freshness_pressure"} = risk,
         "refresh_freshness_blocked"
       ) do
    blocked_refresh_freshness_pressure?(risk)
  end

  defp risk_matches_blocked_type?(
         %{"feedback_scope" => "refresh_freshness"} = risk,
         "refresh_freshness_blocked"
       ) do
    blocked_refresh_freshness_pressure?(risk)
  end

  defp risk_matches_blocked_type?(risk, "station_reservation_expiration_blocked") do
    blocked_station_reservation_expiration_pressure?(risk)
  end

  defp risk_matches_blocked_type?(
         %{"type" => "provider_counteroffer_pressure"} = risk,
         "provider_counteroffer_blocked"
       ) do
    blocked_provider_counteroffer_pressure?(risk)
  end

  defp risk_matches_blocked_type?(
         %{"type" => "provider_counteroffer_review"} = risk,
         "provider_counteroffer_blocked"
       ) do
    blocked_provider_counteroffer_pressure?(risk)
  end

  defp risk_matches_blocked_type?(
         %{"feedback_scope" => "provider_counteroffer"} = risk,
         "provider_counteroffer_blocked"
       ) do
    blocked_provider_counteroffer_pressure?(risk)
  end

  defp risk_matches_blocked_type?(
         %{"type" => "provider_reservation_request_review"} = risk,
         "provider_reservation_request_blocked"
       ) do
    blocked_provider_reservation_request_pressure?(risk)
  end

  defp risk_matches_blocked_type?(
         %{"feedback_scope" => "contact_allocation_provider_reservation_request"} = risk,
         "provider_reservation_request_blocked"
       ) do
    blocked_provider_reservation_request_pressure?(risk)
  end

  defp risk_matches_blocked_type?(_risk, _blocked_type), do: false

  defp blocked_model_acceptance_pressure?(risk) do
    blocked_value?(risk["model_acceptance_status"]) or
      blocked_value?(risk["model_status"]) or
      positive_count?(risk["blocked_count"]) or
      risk["branch_local_blocking_pressure"] == true or
      risk["required_operator_action"] == "review_blocked_model_acceptance"
  end

  defp blocked_validation_safety_case_pressure?(risk) do
    blocked_value?(risk["validation_safety_case_status"]) or
      blocked_value?(risk["evidence_status"]) or
      positive_count?(risk["blocked_evidence_count"]) or
      positive_count?(risk["schema_error_count"]) or
      positive_count?(risk["model_blocked_count"]) or
      positive_count?(risk["quality_gate_blocked_count"]) or
      risk["branch_local_blocking_pressure"] == true or
      risk["required_operator_action"] == "review_blocked_validation_safety_case"
  end

  defp blocked_schema_validation_pressure?(risk) do
    blocked_value?(risk["validation_status"]) or
      risk["validation_status"] == "fail" or
      risk["issue_severity"] == "error" or
      positive_count?(risk["error_count"]) or
      risk["branch_local_schema_error_pressure"] == true
  end

  defp blocked_import_readiness_pressure?(risk) do
    risk["import_blocked"] == true or
      positive_count?(risk["blocked_import_count"]) or
      nonempty_list?(risk["blocked_import_quality_gate_row_ids"]) or
      positive_count_for_key?(risk["import_status_counts"], "blocked") or
      positive_count_for_key?(risk["import_status_counts"], "blocked_missing_cadence_import")
  end

  defp blocked_refresh_budget_pressure?(risk) do
    blocked_value?(risk["refresh_budget_status"]) or
      risk["refresh_budget_status"] == "invalid" or
      risk["candidate_limit_status"] == "invalid" or
      risk["invalid_candidate_limit_policy"] == true or
      positive_count?(risk["invalid_candidate_limit_policy_count"]) or
      risk["branch_local_invalid_limit_pressure"] == true
  end

  defp blocked_refresh_freshness_pressure?(risk) do
    blocked_value?(risk["freshness_status"]) or
      risk["freshness_status"] == "stale" or
      risk["state_quality_status"] == "stale" or
      "stale" in List.wrap(risk["freshness_statuses"]) or
      positive_count?(risk["stale_reason_count"]) or
      risk["branch_local_stale_pressure"] == true
  end

  defp blocked_station_reservation_expiration_pressure?(risk) do
    risk["station_reservation_expiration_status"] in ["expired", "missing"] or
      risk["station_reservation_hold_expiration_status"] in ["expired", "missing"] or
      "expired" in List.wrap(risk["station_reservation_expiration_statuses"]) or
      "missing" in List.wrap(risk["station_reservation_expiration_statuses"]) or
      "expired" in List.wrap(risk["station_reservation_hold_expiration_statuses"]) or
      "missing" in List.wrap(risk["station_reservation_hold_expiration_statuses"])
  end

  defp blocked_provider_counteroffer_pressure?(risk) do
    blocked_value?(risk["provider_counteroffer_import_status"]) or
      blocked_value?(risk["import_readiness_status"]) or
      blocked_value?(risk["import_classification"]) or
      risk["provider_counteroffer_lock_deadline_status"] in ["expired", "missing"] or
      "expired" in List.wrap(risk["provider_counteroffer_lock_deadline_statuses"]) or
      "missing" in List.wrap(risk["provider_counteroffer_lock_deadline_statuses"]) or
      positive_count_for_key?(risk["counteroffer_lock_deadline_status_counts"], "expired") or
      positive_count_for_key?(risk["counteroffer_lock_deadline_status_counts"], "missing") or
      positive_count_for_key?(risk["provider_counteroffer_import_status_counts"], "blocked") or
      positive_count_for_key?(risk["import_readiness_status_counts"], "blocked") or
      positive_count_for_key?(risk["import_classification_counts"], "blocked")
  end

  defp blocked_provider_reservation_request_pressure?(risk) do
    blocked_value?(risk["provider_reservation_request_status"]) or
      risk["provider_reservation_request_status"] == "review_required" or
      risk["provider_reservation_row_scope"] == "review" or
      risk["station_reservation_match_status"] in [
        "overlap",
        "conflict",
        "unmatched",
        "owner_mismatch"
      ] or
      Enum.any?(List.wrap(risk["station_reservation_match_statuses"]), fn status ->
        status in ["overlap", "conflict", "unmatched", "owner_mismatch"]
      end)
  end

  defp nonempty_list?(value), do: is_list(value) and value != []

  defp positive_count_for_key?(%{} = counts, key), do: positive_count?(Map.get(counts, key))
  defp positive_count_for_key?(_counts, _key), do: false

  defp resource_availability_blocked?(risk) do
    is_binary(risk["resource_field"]) and
      Map.has_key?(risk, "resource_availability_value")
  end

  defp blocked_value?(value) when is_binary(value),
    do: value in ["blocked", "blocked_by_policy"]

  defp blocked_value?(_value), do: false

  defp positive_count?(value) when is_integer(value), do: value > 0
  defp positive_count?(value) when is_float(value), do: value > 0.0
  defp positive_count?(_value), do: false

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp stringify_keys(%_struct{} = struct) do
    struct
    |> Map.from_struct()
    |> stringify_keys()
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_key(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(nil), do: nil
  defp stringify_keys(value) when is_boolean(value), do: value
  defp stringify_keys(value) when is_atom(value), do: Atom.to_string(value)
  defp stringify_keys(value), do: value

  defp encode_key(key) when is_atom(key), do: Atom.to_string(key)
  defp encode_key(key), do: key
end
