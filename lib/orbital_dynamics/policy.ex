defmodule OrbitalDynamics.Policy do
  @moduledoc """
  Shared policy classification for planning artifacts.

  The module returns artifact rows only. It does not approve, schedule, or
  execute operational work; it classifies planner recommendations so Cadence and
  operators can see which rule or fallback boundary was applied.
  """

  alias OrbitalDynamics.Policy.{
    ApprovalPolicyNormalizer,
    DecisionBuilder,
    RequirementContext,
    RuleMatchBuilder
  }

  @classifications ["auto_approvable", "operator_review_required", "blocked_by_policy"]
  @default_blocked_risk_types ["spacecraft_degraded_unprotected", "no_viable_downlink"]
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
    ApprovalPolicyNormalizer.normalize(policy, &bundle!/1, @default_blocked_risk_types)
  end

  @doc """
  Classifies a branch approval boundary.
  """
  def decide(approval_requirements, risk_indicators, branch, candidate_plan, policy) do
    policy = normalize_approval_policy(policy)

    raw_rule_matches =
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

    DecisionBuilder.build(
      raw_rule_matches,
      approval_requirements,
      risk_indicators,
      policy,
      model_limits(),
      @escalation_fields
    )
  end

  @doc """
  Classifies a branch with an optional caller-supplied authority context.

  `:authority_context_mode` must be `:explicit` or `"explicit"` to activate
  fail-closed authority evaluation. The legacy `/5` function remains the exact
  default and does not inspect application or process configuration.
  """
  def decide(approval_requirements, risk_indicators, branch, candidate_plan, policy, opts)
      when is_list(opts) or is_map(opts) do
    result = decide(approval_requirements, risk_indicators, branch, candidate_plan, policy)
    opts = Map.new(opts)

    apply_authority_context(result, opts)
  end

  defp cadence_import_statuses do
    OrbitalDynamics.CadenceImport.capability().cadence_import_statuses
  end

  defp model_limits do
    __MODULE__.capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&to_string/1)
  end

  defp approval_rule_matches(rule, approval_requirements, risk_indicators, branch, candidate_plan) do
    RuleMatchBuilder.build(
      rule,
      approval_requirements,
      risk_indicators,
      branch,
      candidate_plan,
      @escalation_fields
    )
  end

  defp apply_authority_context(result, opts) do
    case OrbitalDynamics.AuthorityContext.evaluate_options(opts) do
      :legacy ->
        result

      {:ok, authority_context, evaluation} ->
        {status, requirements, matches, decision} = result
        eligibility_status = substantive_eligibility(status)

        {status, requirements, matches,
         decision
         |> Map.put("eligibility_status", eligibility_status)
         |> Map.put("authority_context", authority_context)
         |> Map.put("authority_context_evaluation", evaluation)}

      {:error, evaluation} ->
        {_status, requirements, matches, decision} = result

        {"blocked_by_policy", requirements, matches,
         decision
         |> Map.put("classification", "blocked_by_policy")
         |> Map.put("eligibility_status", "non_eligible")
         |> Map.put("authority_context_evaluation", evaluation)}
    end
  end

  defp substantive_eligibility("blocked_by_policy"), do: "non_eligible"
  defp substantive_eligibility(_classification), do: "eligible"

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
