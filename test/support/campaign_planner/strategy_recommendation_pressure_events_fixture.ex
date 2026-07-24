defmodule OrbitalDynamics.CampaignPlanner.StrategyRecommendationPressureEventsFixture do
  import OrbitalDynamics.CampaignPlanner.TestSupport

  def artifact(opts \\ []) do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [],
        "candidate_activities" => []
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([%{"type" => "priority_commitment", "target_id" => "target_hot"}]),
        strategy_policy: %{
          "mission_value_weight" => 10.0,
          "risk_weight" => 0.0,
          "approval_load_weight" => 0.0
        },
        approval_policy: %{
          "blocked_risk_types" => [],
          "operator_review_risk_limit" => 50
        },
        branches: [
          %{id: "baseline"},
          %{
            id: "urgent",
            events: [
              %{
                type: "urgent_target",
                target_id: "target_hot",
                starts_at_s: 500.0,
                ends_at_s: 560.0,
                priority: 20.0,
                candidate_windows: [
                  %{
                    id: "candidate_obs_hot",
                    type: "observe",
                    target_id: "target_hot",
                    scenario_id: "leo_1",
                    starts_at_s: 500.0,
                    ends_at_s: 560.0,
                    duration_s: 60.0,
                    score: 10.0
                  }
                ]
              },
              %{
                type: "operational_readiness_pressure",
                report_id: "operational_readiness:resource_projection_report.v1:live_ops",
                source_artifact_type: "resource_projection_report.v1",
                source_artifact_id: "live_ops",
                readiness_level: "operator_review",
                import_classification: "review_only",
                operational_readiness_status: "review_required",
                gate_count: 1,
                passed_gate_count: 0,
                review_gate_count: 1,
                analysis_gate_count: 0,
                blocked_gate_count: 0,
                readiness_gate_id: "operator_training",
                readiness_gate_status: "review_required",
                readiness_gate_classification: "review_only",
                readiness_gate_reason: "operator training requires role-qualified review",
                required_operator_action: "review_operational_readiness",
                feedback_source: "mission_state.source_operational_readiness_report.gates",
                feedback_scope: "operational_readiness",
                feedback_key: "operator_training",
                trust_boundary: "mission_state_operational_readiness_report",
                operator_training_requirement_count: 2,
                required_operator_roles: ["contact_operator"]
              },
              %{
                type: "quality_gate_pressure",
                report_id: "quality_gate:resource_projection_report.v1:live_ops",
                source_artifact_type: "resource_projection_report.v1",
                source_artifact_id: "live_ops",
                source_readiness_report_id:
                  "operational_readiness:resource_projection_report.v1:live_ops",
                readiness_level: "operator_review",
                import_classification: "review_only",
                quality_gate_status: "review_required",
                gate_count: 1,
                passed_gate_count: 0,
                review_gate_count: 1,
                analysis_gate_count: 0,
                blocked_gate_count: 0,
                gate_id: "resource_availability",
                gate_status: "review_required",
                gate_classification: "review_only",
                gate_reason:
                  "resource availability evidence requires operator review before import",
                required_operator_action: "review_operational_readiness",
                feedback_source: "mission_state.source_quality_gate_report.rows",
                feedback_scope: "quality_gate",
                feedback_key: "resource_availability",
                trust_boundary: "mission_state_quality_gate_report",
                resource_availability_pressure_count: 2,
                resource_availability_reason_ids: [
                  "antenna_unavailable",
                  "payload_unavailable"
                ]
              },
              %{
                type: "approval_boundary_pressure",
                approval_boundary: "command_execution",
                approval_boundary_status: "operator_review_required",
                approval_boundary_reason: "command execution requires flight director approval",
                automation_boundary: "no_command_execution",
                execution_boundary: "flight_director_approval",
                import_classification: "review_only",
                required_operator_action: "review_approval_boundary",
                required_authority: "flight_director",
                policy_bundle_id: "flight_rules_v3",
                rule_id: "no_unapproved_command_execution",
                feedback_source: "mission_state.source_approval_boundary_policy.rules",
                feedback_scope: "approval_boundary",
                feedback_key: "no_unapproved_command_execution",
                trust_boundary: "mission_state_approval_boundary_policy"
              },
              %{
                type: "timeline_activity_precondition_pressure",
                activity_id: "cmd_precondition_review",
                timeline_id: "timeline:cmd_precondition_review",
                activity_type: "command",
                precondition_status: "blocked",
                blocked_precondition_count: 2,
                review_precondition_count: 1,
                blocked_precondition_types: [
                  "command_safety_failed",
                  "payload_unavailable"
                ],
                review_precondition_types: ["command_authority_missing"],
                dependency_activity_ids: ["health_check"],
                dependency_timeline_ids: ["timeline:health_check"],
                exclusive_with_activity_ids: ["downlink_conflict"],
                exclusive_with_timeline_ids: ["timeline:downlink_conflict"],
                duplicate_dependency_activity_ids: ["health_check"],
                duplicate_dependency_timeline_ids: ["timeline:health_check"],
                duplicate_exclusivity_activity_ids: ["downlink_conflict"],
                duplicate_exclusivity_timeline_ids: ["timeline:downlink_conflict"],
                allow_overlap: true,
                invalid_activity_input: false,
                invalid_activity_input_reason: nil,
                requires_operator_review: true,
                required_operator_action: "review_blocked_activity_precondition",
                feedback_source: "mission_state.source_timeline_activity_precondition_summary",
                feedback_scope: "timeline_activity_precondition",
                feedback_key: "cmd_precondition_review",
                trust_boundary: "mission_state_timeline_activity_precondition_summary",
                derivation_reasons: ["timeline_activity_precondition_summary_pressure"],
                assumptions: %{
                  "activity_precondition_evaluation" => "not_performed_by_strategy_branch",
                  "timeline_mutation" => "not_performed_by_strategy_branch",
                  "operator_authority" => "not_granted_by_strategy_branch",
                  "cadence_import" => "not_performed_by_strategy_branch"
                }
              },
              %{
                type: "timeline_dependency_impact_pressure",
                activity_id: "cmd_dependency_review",
                timeline_id: "timeline:cmd_dependency_review",
                dependency_impact_scope: "source",
                dependency_impact_status: "review_required",
                operator_action_reason: "dependency_link_impacted_by_timeline_change",
                required_operator_action: "review_timeline_dependency_impact",
                dependency_activity_ids: ["health_check"],
                dependency_timeline_ids: ["timeline:health_check"],
                exclusive_with_activity_ids: ["downlink_conflict"],
                exclusive_with_timeline_ids: ["timeline:downlink_conflict"],
                impacted_dependency_activity_ids: ["health_check"],
                impacted_dependency_timeline_ids: ["timeline:health_check"],
                impacted_exclusive_with_activity_ids: ["downlink_conflict"],
                impacted_exclusive_with_timeline_ids: ["timeline:downlink_conflict"],
                feedback_source:
                  "mission_state.source_timeline_dependency_impact_summary.dependency_impact_rows",
                feedback_scope: "timeline_dependency_impact",
                feedback_key: "cmd_dependency_review",
                trust_boundary: "mission_state_timeline_dependency_impact_summary",
                derivation_reasons: ["timeline_dependency_impact_summary_pressure"]
              },
              %{
                type: "timeline_integrity_feedback",
                activity_id: "cmd_integrity_review",
                timeline_id: "timeline:cmd_integrity_review",
                timeline_integrity_status: "review_required",
                timeline_integrity_issue_count: 2,
                timeline_integrity_issue_types: [
                  "missing_dependency_activity",
                  "exclusivity_overlap"
                ],
                timeline_integrity_issues: [
                  %{
                    "type" => "missing_dependency_activity",
                    "missing_dependency_activity_id" => "cmd_power_on"
                  },
                  %{
                    "type" => "exclusivity_overlap",
                    "exclusivity_violation_activity_id" => "downlink_conflict",
                    "exclusivity_violation_timeline_id" => "timeline:downlink_conflict",
                    "exclusivity_violation_group" => "equator_prime"
                  }
                ],
                missing_dependency_activity_ids: ["cmd_power_on"],
                exclusivity_violation_activity_ids: ["downlink_conflict"],
                exclusivity_violation_timeline_ids: ["timeline:downlink_conflict"],
                exclusivity_violation_group: "equator_prime",
                required_operator_action: "review_timeline_integrity",
                feedback_source: "mission_state.source_timeline_integrity_report.rows",
                feedback_scope: "timeline_integrity",
                feedback_key: "cmd_integrity_review",
                trust_boundary: "mission_state_timeline_integrity_report",
                derivation_reasons: ["timeline_integrity_report_pressure"]
              },
              %{
                type: "command_success_feedback",
                activity_id: "cmd_success_review",
                scenario_id: "leo_1",
                timeline_id: "timeline:cmd_success_review",
                starts_at_s: 700.0,
                ends_at_s: 730.0,
                command_success_factor: 0.25,
                command_result: "timeout",
                realized_status: "failed",
                ground_station_id: "equator_prime",
                planned_ground_station_id: "polar_prime",
                realized_ground_station_id: "equator_prime",
                ground_station_match_status: "mismatch",
                direction: "command",
                planned_direction: "uplink",
                realized_direction: "command",
                direction_match_status: "mismatch",
                source_window_id: "window_equator_command",
                planned_source_window_id: "window_polar_uplink",
                realized_source_window_id: "window_equator_command",
                source_window_match_status: "mismatch",
                command_identity_mismatch_fields: [
                  "direction",
                  "ground_station",
                  "source_window"
                ],
                source_activity_id: "cmd_success_source",
                replacement_activity_id: "cmd_success_review",
                source_activity_ids: ["cmd_success_review", "cmd_success_source"],
                changed_fields: ["command_result", "command_success_factor"],
                required_operator_action: "review_command_execution_feedback",
                feedback_source: "mission_state.source_command_window_report.rows",
                feedback_scope: "command_execution_feedback",
                feedback_key: "cmd_success_review",
                trust_boundary: "mission_state_command_window_report",
                status_transition: %{
                  "field" => "status",
                  "from" => "planned",
                  "to" => "failed",
                  "transition_type" => "status_changed",
                  "transition_category" => "terminal_exception",
                  "transition_reason" => "command execution timed out",
                  "requires_operator_review" => true
                },
                transition_type: "status_changed",
                transition_category: "terminal_exception",
                transition_reason: "command execution timed out",
                requires_operator_review: true,
                derivation_reasons: ["command_window_execution_feedback_pressure"]
              },
              %{
                type: "maneuver_success_feedback",
                activity_id: "burn_success_review",
                scenario_id: "leo_1",
                timeline_id: "timeline:burn_success_review",
                starts_at_s: 760.0,
                ends_at_s: 760.0,
                maneuver_success_factor: 0.4,
                maneuver_result: "accepted, failed",
                realized_status: "failed",
                source_activity_id: "burn_success_source",
                replacement_activity_id: "burn_success_review",
                source_activity_ids: ["burn_success_review", "burn_success_source"],
                changed_fields: ["maneuver_result", "maneuver_success_factor"],
                required_operator_action: "review_maneuver_execution_feedback",
                feedback_source: "mission_state.source_maneuver_review.rows",
                feedback_scope: "maneuver_execution_feedback",
                feedback_key: "burn_success_review",
                trust_boundary: "mission_state_maneuver_review",
                status_transition: %{
                  "field" => "status",
                  "from" => "planned",
                  "to" => "failed",
                  "transition_type" => "status_changed",
                  "transition_category" => "terminal_exception",
                  "transition_reason" => "maneuver failed after acceptance",
                  "requires_operator_review" => true
                },
                transition_type: "status_changed",
                transition_category: "terminal_exception",
                transition_reason: "maneuver failed after acceptance",
                requires_operator_review: true,
                derivation_reasons: ["maneuver_review_success_feedback_pressure"]
              },
              %{
                type: "contact_success_feedback",
                activity_id: "contact_feedback_review",
                scenario_id: "leo_1",
                timeline_id: "timeline:contact_feedback_review",
                starts_at_s: 790.0,
                ends_at_s: 850.0,
                contact_success_factor: 0.35,
                contact_result: "no-contact",
                realized_status: "missed",
                ground_station_id: "equator_prime",
                planned_ground_station_id: "polar_prime",
                realized_ground_station_id: "equator_prime",
                ground_station_match_status: "mismatch",
                direction: "downlink",
                planned_direction: "uplink",
                realized_direction: "downlink",
                direction_match_status: "mismatch",
                source_window_id: "window_equator_contact",
                planned_source_window_id: "window_polar_contact",
                realized_source_window_id: "window_equator_contact",
                source_window_match_status: "mismatch",
                contact_identity_mismatch_fields: [
                  "direction",
                  "ground_station",
                  "source_window"
                ],
                source_activity_id: "contact_feedback_source",
                replacement_activity_id: "contact_feedback_review",
                source_activity_ids: ["contact_feedback_review", "contact_feedback_source"],
                changed_fields: ["contact_result", "contact_success_factor"],
                required_operator_action: "review_contact_execution_feedback",
                feedback_source: "mission_state.source_contact_review.rows",
                feedback_scope: "contact_execution_feedback",
                feedback_key: "contact_feedback_review",
                trust_boundary: "mission_state_contact_review",
                status_transition: %{
                  "field" => "status",
                  "from" => "planned",
                  "to" => "missed",
                  "transition_type" => "status_changed",
                  "transition_category" => "terminal_exception",
                  "transition_reason" => "contact was missed by provider report",
                  "requires_operator_review" => true
                },
                transition_type: "status_changed",
                transition_category: "terminal_exception",
                transition_reason: "contact was missed by provider report",
                requires_operator_review: true,
                derivation_reasons: ["contact_execution_feedback_pressure"]
              },
              %{
                type: "observation_success_feedback",
                activity_id: "obs_feedback_review",
                scenario_id: "leo_1",
                timeline_id: "timeline:obs_feedback_review",
                starts_at_s: 870.0,
                ends_at_s: 930.0,
                observation_success_factor: 0.45,
                observation_result: "accepted, degraded",
                realized_status: "degraded",
                target_id: "target_hot",
                planned_target_id: "target_hot",
                realized_target_id: "target_shadow",
                target_match_status: "mismatch",
                collection_id: "collection_hot",
                planned_collection_id: "collection_hot",
                realized_collection_id: "collection_shadow",
                collection_match_status: "mismatch",
                product_id: "product_hot",
                product_ids: ["product_hot"],
                planned_product_id: "product_hot",
                realized_product_id: "product_shadow",
                product_match_status: "mismatch",
                payload_id: "payload_nadir",
                planned_payload_id: "payload_nadir",
                realized_payload_id: "payload_wide",
                payload_match_status: "mismatch",
                instrument_id: "camera_nadir",
                planned_instrument_id: "camera_nadir",
                realized_instrument_id: "camera_wide",
                instrument_match_status: "mismatch",
                observation_identity_mismatch_fields: [
                  "collection",
                  "instrument",
                  "target"
                ],
                pointing_status: "degraded",
                pointing_error_deg: 1.2,
                attitude_status: "degraded",
                attitude_error_deg: 0.8,
                lighting_condition_match_status: "mismatch",
                planned_lighting_condition: "sunlit",
                realized_lighting_condition: "penumbra",
                lighting_condition_detail: "low sun angle",
                lighting_confidence: 0.7,
                eclipse_overlap_fraction: 0.2,
                image_quality_score: 0.45,
                image_quality_status: "marginal",
                image_quality_source: "provider_imagery_quality",
                cloud_cover_fraction: 0.55,
                blur_score: 0.25,
                source_activity_id: "obs_feedback_source",
                replacement_activity_id: "obs_feedback_review",
                source_activity_ids: ["obs_feedback_review", "obs_feedback_source"],
                changed_fields: ["observation_result", "observation_success_factor"],
                required_operator_action: "review_observation_execution_feedback",
                feedback_source: "mission_state.source_observation_review.rows",
                feedback_scope: "observation_execution_feedback",
                feedback_key: "obs_feedback_review",
                trust_boundary: "mission_state_observation_review",
                status_transition: %{
                  "field" => "status",
                  "from" => "planned",
                  "to" => "degraded",
                  "transition_type" => "status_changed",
                  "transition_category" => "quality_exception",
                  "transition_reason" => "observation quality degraded",
                  "requires_operator_review" => true
                },
                transition_type: "status_changed",
                transition_category: "quality_exception",
                transition_reason: "observation quality degraded",
                requires_operator_review: true,
                derivation_reasons: ["observation_execution_feedback_pressure"]
              },
              %{
                type: "station_throughput_feedback",
                activity_id: "station_feedback_review",
                scenario_id: "leo_1",
                timeline_id: "timeline:station_feedback_review",
                starts_at_s: 950.0,
                ends_at_s: 1_010.0,
                ground_station_id: "equator_prime",
                station_throughput_factor: 0.5,
                actual_throughput_mb: 50.0,
                estimated_throughput_mb: 100.0,
                source_activity_id: "station_feedback_source",
                replacement_activity_id: "station_feedback_review",
                source_activity_ids: ["station_feedback_review", "station_feedback_source"],
                changed_fields: ["actual_throughput_mb", "station_throughput_factor"],
                required_operator_action: "review_station_throughput_feedback",
                feedback_source: "mission_state.source_station_throughput_review.rows",
                feedback_scope: "station_throughput_feedback",
                feedback_key: "station_feedback_review",
                trust_boundary: "mission_state_station_throughput_review",
                status_transition: %{
                  "field" => "throughput_status",
                  "from" => "planned",
                  "to" => "degraded",
                  "transition_type" => "throughput_changed",
                  "transition_category" => "capacity_exception",
                  "transition_reason" => "station throughput below plan",
                  "requires_operator_review" => true
                },
                transition_type: "throughput_changed",
                transition_category: "capacity_exception",
                transition_reason: "station throughput below plan",
                requires_operator_review: true,
                derivation_reasons: ["station_throughput_feedback_pressure"]
              },
              %{
                type: "downlink_completion_gap",
                ground_station_id: "equator_prime",
                required_contacts: 1,
                planned_contacts: 0,
                required_downlink_mb: 45.0,
                planned_downlink_mb: 10.0,
                starts_at_s: 1_020.0,
                ends_at_s: 1_080.0,
                source_activity_ids: ["dl_link_capacity_source"],
                source_window_id: "window_link_capacity",
                source_window_ids: ["window_link_capacity", "window_link_capacity_backup"],
                selected_capacity_adjusted_throughput_mb: 10.0,
                selected_downlink_shortfall_mb: 35.0,
                actual_throughput_mb: 8.0,
                actual_downlink_completion_ratio: 0.22,
                actual_downlink_shortfall_mb: 37.0,
                downlink_requirement_status: "shortfall",
                actual_downlink_requirement_status: "shortfall",
                downlink_demand_sources: ["mission_objective:relay_collection"],
                downlink_completion_sources: ["link_capacity_report:selected_contacts"],
                derivation_reasons: ["link_capacity_selected_downlink_shortfall"],
                feedback_source: "mission_state.source_link_capacity_report.rows",
                feedback_scope: "link_capacity",
                trust_boundary: "mission_state_link_capacity_report"
              },
              %{
                type: "downlink_completion_gap",
                scenario_id: "leo_1",
                spacecraft_id: "leo_1",
                ground_station_id: "deep_space_net",
                required_contacts: 1,
                planned_contacts: 0,
                required_downlink_mb: 42.0,
                planned_downlink_mb: 0.0,
                starts_at_s: 1_100.0,
                ends_at_s: 1_160.0,
                contact_id: "contact_intent:selected_blocked",
                source_activity_id: "dl_contact_intent_selected",
                source_activity_ids: ["dl_contact_intent_selected"],
                source_window_id: "window_contact_intent_selected",
                timeline_id: "timeline:contact_intent:selected_blocked",
                approval_status: "blocked_by_policy",
                required_operator_action: "review_contact_intent",
                cadence_import_status: "missing",
                invalid_cadence_import: true,
                invalid_cadence_import_reason: "missing_cadence_import_row",
                invalid_activity_input: Keyword.get(opts, :invalid_activity_input, false),
                invalid_activity_input_reason: Keyword.get(opts, :invalid_activity_input_reason),
                contact_intent_gate_status: "blocked_by_policy",
                policy_classification: "blocked_by_policy",
                policy_bundle_id: "contact_command_review_v1",
                station_availability: "reserved",
                station_contention_status: "operator_review_required",
                station_calendar_entry_id: "intent_selected_calendar_entry",
                station_calendar_provider_id: "partner_calendar",
                station_calendar_provider_entry_id: "partner_entry_selected",
                station_calendar_directions: ["downlink"],
                station_calendar_status: "reserved",
                station_calendar_trust_boundary_status: "declared",
                station_reservation_id: "reservation_intent_selected",
                station_reserved_by: "partner_team",
                station_reservation_status: "confirmed",
                station_reservation_match_status: "unmatched_overlap",
                derivation_reasons: [
                  "contact_intent_blocked_by_policy",
                  "review_contact_intent",
                  "reserved",
                  "unmatched_overlap"
                ],
                feedback_source: "mission_state.source_contact_intent.rows",
                feedback_scope: "contact_intent",
                trust_boundary: "mission_state_contact_intent_review"
              },
              %{
                type: "downlink_completion_gap",
                scenario_id: "leo_1",
                spacecraft_id: "leo_1",
                ground_station_id: "goldstone",
                required_contacts: 1,
                planned_contacts: 0,
                required_downlink_mb: 38.0,
                planned_downlink_mb: 0.0,
                starts_at_s: 1_165.0,
                ends_at_s: 1_225.0,
                contact_id: "dl_contact_filter_suppressed",
                source_activity_id: "dl_contact_filter_suppressed",
                source_activity_ids: ["dl_contact_filter_suppressed"],
                source_window_id: "window_contact_filter_suppressed",
                suppressed_reason: "station_reserved",
                review_status: "operator_review_required",
                station_reservation_id: "reservation_contact_filter",
                station_reserved_by: "partner_calendar",
                station_reservation_status: "confirmed",
                station_reservation_match_status: "overlap",
                station_calendar_entry_id: "calendar_contact_filter_suppressed",
                station_calendar_entry_status: "reserved",
                downlink_demand_sources: ["contact_filter:dl_contact_filter_suppressed"],
                downlink_completion_sources: ["contact_filter_report:suppressed_candidates"],
                derivation_reasons: [
                  "contact_filter_suppressed",
                  "station_reserved"
                ],
                feedback_source:
                  "mission_state.source_contact_filter_report.suppressed_candidates",
                feedback_scope: "contact_filter",
                trust_boundary: "mission_state_contact_filter_report"
              },
              %{
                type: "resource_availability_constraint",
                scenario_id: "leo_1",
                spacecraft_id: "leo_1",
                resource_field: "payload_available",
                available: false,
                starts_at_s: 1_230.0,
                ends_at_s: 1_290.0,
                source_activity_id: "obs_resource_filter_suppressed",
                source_activity_ids: ["obs_resource_filter_suppressed"],
                suppressed_reason: "payload_unavailable",
                source_quality: "operator_supplied",
                resource_trust_boundary_status: "declared",
                derivation_reasons: [
                  "resource_filter_suppressed",
                  "payload_unavailable"
                ],
                feedback_source:
                  "mission_state.source_resource_filter_report.suppressed_candidates",
                feedback_scope: "resource_filter",
                trust_boundary: "mission_state_resource_filter_report"
              },
              %{
                type: "ground_station_reserved",
                ground_station_id: "canberra",
                starts_at_s: 1_170.0,
                ends_at_s: 1_230.0,
                capacity_fraction: 0.4,
                station_availability: "reserved",
                station_contention_status: "reserved_overlap",
                station_calendar_entry_id: "calendar_selected_reserved",
                station_calendar_provider_id: "partner_calendar",
                station_calendar_provider_entry_id: "partner_entry_calendar_selected",
                station_calendar_directions: ["downlink"],
                station_calendar_status: "reserved",
                station_calendar_overlap_count: 2,
                station_calendar_overlap_entry_ids: [
                  "calendar_selected_reserved",
                  "calendar_selected_maintenance"
                ],
                station_calendar_overlap_availabilities: ["reserved", "maintenance"],
                station_calendar_entry_ambiguous: true,
                station_calendar_ambiguous_entry_count: 2,
                station_calendar_ambiguous_entry_ids: [
                  "calendar_selected_reserved",
                  "calendar_selected_backup"
                ],
                station_calendar_reservation_overlap_count: 1,
                station_calendar_reservation_ids: ["reservation_calendar_selected"],
                station_calendar_reserved_by: ["partner_team"],
                station_calendar_reservation_statuses: ["confirmed"],
                station_calendar_trust_boundary_status: "declared",
                station_reservation_id: "reservation_calendar_selected",
                station_reserved_by: "partner_team",
                station_reservation_status: "confirmed",
                station_reservation_match_status: "overlap",
                station_reservation_expires_at_s: 1_260.0,
                station_reservation_expiration_status: "active",
                provider_calendar_contention_group_id: "provider_contention_selected",
                provider_calendar_contention_status: "review_required",
                provider_calendar_contention_entry_ids: [
                  "calendar_selected_reserved",
                  "calendar_selected_maintenance"
                ],
                provider_calendar_contention_provider_ids: ["partner_calendar"],
                provider_calendar_contention_provider_entry_ids: [
                  "partner_entry_calendar_selected",
                  "partner_entry_calendar_maintenance"
                ],
                provider_calendar_contention_availabilities: ["reserved", "maintenance"],
                provider_calendar_contention_directions: ["downlink"],
                provider_calendar_contention_reservation_ids: ["reservation_calendar_selected"],
                provider_calendar_contention_reserved_by: ["partner_team"],
                provider_calendar_contention_reservation_statuses: ["confirmed"],
                provider_calendar_contention_trust_boundary_statuses: ["declared"],
                provider_calendar_contention_overlap_pairs: [
                  %{
                    "left_entry_id" => "calendar_selected_reserved",
                    "right_entry_id" => "calendar_selected_maintenance",
                    "overlap_starts_at_s" => 1_170.0,
                    "overlap_ends_at_s" => 1_230.0,
                    "overlap_duration_s" => 60.0
                  }
                ],
                required_operator_action: "review_station_calendar",
                feedback_source: "mission_state.source_station_calendar_report.affected_contacts",
                feedback_scope: "station_calendar",
                trust_boundary: "mission_state_station_calendar_report",
                derivation_reasons: [
                  "station_calendar_reserved",
                  "reserved_overlap",
                  "overlap"
                ]
              },
              %{
                type: "downlink_completion_gap",
                objective_id: "score_term:downlink_shortfall",
                objective_type: "score_term_gap",
                latency_objective: true,
                target_id: "target_score_term",
                scenario_id: "leo_1",
                branch_id: "urgent",
                ground_station_id: "polar_prime",
                collection_id: "collection_score_alpha",
                collection_ids: ["collection_score_alpha", "collection_score_beta"],
                product_id: "product_score_alpha",
                product_ids: ["product_score_alpha", "product_score_beta"],
                payload_id: "payload_score_alpha",
                payload_ids: ["payload_score_alpha", "payload_score_beta"],
                instrument_id: "instrument_score_alpha",
                instrument_ids: ["instrument_score_alpha", "instrument_score_beta"],
                starts_at_s: 1_240.0,
                ends_at_s: 1_360.0,
                required_contacts: 2,
                planned_contacts: 1,
                required_downlink_mb: 80.0,
                planned_downlink_mb: 35.0,
                max_latency_s: 300.0,
                planned_latency_s: 420.0,
                required_observations: 2,
                planned_observations: 1,
                priority: 24.0,
                latitude_deg: 34.1,
                longitude_deg: -118.2,
                minimum_elevation_deg: 15.0,
                source_activity_id: "obs_score_source",
                source_activity_ids: ["dl_score_source", "obs_score_source"],
                score_term_key: "collection_latency_gap_s",
                score_term_value: 120.0,
                timeline_score: 9.5,
                score_terms: %{
                  "collection_latency_gap_s" => 120.0,
                  "downlink_shortfall_mb" => 45.0
                },
                downlink_demand_sources: [
                  "score_term:score_term:downlink_shortfall:collection_latency_gap_s"
                ],
                downlink_completion_sources: [
                  "score_term:score_term:downlink_shortfall:collection_latency_gap_s"
                ],
                derivation_reasons: [
                  "collection_latency_gap",
                  "score_term_collection_latency_gap",
                  "score_term_collection_latency_gap_s"
                ],
                feedback_source: "mission_state.source_score_term_report.rows",
                feedback_scope: "score_term",
                trust_boundary: "mission_state_score_term_report"
              },
              %{
                type: "observation_success_feedback",
                objective_id: "objective:target_quality",
                objective_type: "observation_quality",
                objective_status: "at_risk",
                source_objective_status: "missed_quality_threshold",
                target_id: "target_objective_quality",
                scenario_id: "leo_1",
                spacecraft_id: "leo_1",
                branch_id: "urgent",
                collection_id: "collection_objective_quality",
                collection_ids: [
                  "collection_objective_quality",
                  "collection_objective_quality_backup"
                ],
                product_id: "product_objective_quality",
                product_ids: [
                  "product_objective_quality",
                  "product_objective_quality_backup"
                ],
                payload_id: "payload_objective_quality",
                payload_ids: [
                  "payload_objective_quality",
                  "payload_objective_quality_backup"
                ],
                instrument_id: "instrument_objective_quality",
                instrument_ids: [
                  "instrument_objective_quality",
                  "instrument_objective_quality_backup"
                ],
                starts_at_s: 1_380.0,
                ends_at_s: 1_440.0,
                required_observations: 2,
                planned_observations: 1,
                priority: 32.0,
                latitude_deg: 34.1,
                longitude_deg: -118.2,
                minimum_elevation_deg: 15.0,
                observation_success_factor: 0.35,
                image_quality_score: 0.42,
                image_quality_status: "marginal",
                image_quality_source: "provider_imagery_quality",
                cloud_cover_fraction: 0.62,
                blur_score: 0.31,
                source_activity_id: "obs_objective_quality_source",
                source_activity_ids: [
                  "obs_objective_quality_selected",
                  "obs_objective_quality_source"
                ],
                quality_feedback_source: "mission_state.source_imagery_quality.rows",
                derivation_reasons: [
                  "objective_satisfaction_observation_quality_gap",
                  "objective_satisfaction_image_quality_marginal"
                ],
                feedback_source: "mission_state.source_objective_satisfaction_report.rows",
                feedback_scope: "objective_satisfaction",
                trust_boundary: "mission_state_objective_satisfaction_report"
              },
              %{
                type: "downlink_completion_gap",
                objective_id: "objective_tradeoff:latency_gap",
                objective_type: "collection_latency",
                latency_objective: true,
                target_id: "target_tradeoff",
                scenario_id: "leo_1",
                branch_id: "urgent",
                ground_station_id: "madrid",
                collection_id: "collection_tradeoff_alpha",
                collection_ids: [
                  "collection_tradeoff_alpha",
                  "collection_tradeoff_beta"
                ],
                product_id: "product_tradeoff_alpha",
                product_ids: [
                  "product_tradeoff_alpha",
                  "product_tradeoff_beta"
                ],
                payload_id: "payload_tradeoff_alpha",
                payload_ids: [
                  "payload_tradeoff_alpha",
                  "payload_tradeoff_beta"
                ],
                instrument_id: "instrument_tradeoff_alpha",
                instrument_ids: [
                  "instrument_tradeoff_alpha",
                  "instrument_tradeoff_beta"
                ],
                starts_at_s: 1_460.0,
                ends_at_s: 1_580.0,
                required_contacts: 2,
                planned_contacts: 1,
                required_downlink_mb: 90.0,
                planned_downlink_mb: 45.0,
                max_latency_s: 240.0,
                planned_latency_s: 390.0,
                source_activity_id: "obs_tradeoff_source",
                source_activity_ids: [
                  "dl_tradeoff_selected",
                  "obs_tradeoff_source"
                ],
                score: 7.25,
                score_delta_from_selected: -2.75,
                score_terms: %{
                  "collection_latency_gap_s" => 150.0,
                  "downlink_shortfall_mb" => 45.0
                },
                derivation_reasons: [
                  "objective_tradeoff_downlink_gap",
                  "collection_latency_gap",
                  "objective_tradeoff_latency_gap",
                  "objective_tradeoff_unselected"
                ],
                feedback_source: "mission_state.source_objective_tradeoff_report.tradeoffs",
                feedback_scope: "objective_tradeoff",
                trust_boundary: "mission_state_objective_tradeoff_report"
              },
              %{
                type: "relay_data_path_pressure",
                ground_station_id: "dss_14",
                route_id: "relay_route_review",
                route_ids: ["relay_route_review", "relay_route_backup"],
                source_spacecraft_id: "leo_1",
                source_spacecraft_ids: ["leo_1"],
                relay_spacecraft_ids: ["relay_a"],
                relay_chain_spacecraft_ids: ["relay_a", "relay_b"],
                relay_hop_count: 2,
                ground_downlink_contact_id: "downlink_relay_review",
                ground_downlink_contact_ids: [
                  "downlink_relay_review",
                  "downlink_relay_backup"
                ],
                custody_status: "missing_ack",
                latency_s: 500.0,
                latency_limit_s: 300.0,
                latency_status: "exceeds_limit",
                risk_status: "high",
                risk_reasons: ["custody_missing_ack", "latency_exceeds_limit"],
                product_ids: ["product_relay"],
                collection_ids: ["collection_relay"],
                route_count: 2,
                relay_route_count: 2,
                direct_downlink_route_count: 0,
                custody_status_counts: %{"missing_ack" => 2},
                latency_status_counts: %{"exceeds_limit" => 2},
                risk_status_counts: %{"high" => 2},
                route_ids_by_custody_status: %{
                  "missing_ack" => ["relay_route_review", "relay_route_backup"]
                },
                route_ids_by_latency_status: %{
                  "exceeds_limit" => ["relay_route_review", "relay_route_backup"]
                },
                route_ids_by_risk_status: %{
                  "high" => ["relay_route_review", "relay_route_backup"]
                },
                route_ids_by_ground_station_id: %{
                  "dss_14" => ["relay_route_review", "relay_route_backup"]
                },
                feedback_source: "mission_state.source_relay_data_path_summary.rows",
                feedback_scope: "link_capacity",
                feedback_key: "relay_route_review",
                trust_boundary: "mission_state_relay_data_path_summary",
                derivation_reasons: [
                  "relay_data_path_custody_missing_ack",
                  "relay_data_path_latency_exceeds_limit",
                  "relay_data_path_risk_high"
                ],
                assumptions: %{
                  "execution_boundary" =>
                    "artifact_only_no_relay_scheduling_or_schedule_mutation",
                  "operator_authority" => "not_granted_by_summary",
                  "provider_reservation" => "not_performed"
                }
              },
              %{
                type: "downlink_completion_gap",
                scenario_id: "leo_projection_selected",
                spacecraft_id: "leo_projection_selected",
                ground_station_id: "polar_prime",
                required_contacts: 1,
                planned_contacts: 0,
                required_downlink_mb: 52.0,
                planned_downlink_mb: 12.0,
                starts_at_s: 1_590.0,
                ends_at_s: 1_650.0,
                source_activity_id: "obs_projection_pressure",
                source_activity_ids: ["obs_projection_pressure"],
                downlink_demand_sources: [
                  "resource_projection.projected_downlink_shortfall:obs_projection_pressure"
                ],
                downlink_completion_sources: [
                  "resource_projection.projected_downlink_shortfall:obs_projection_pressure"
                ],
                derivation_reasons: ["projected_downlink_shortfall"],
                feedback_source: "mission_state.source_resource_projection_report",
                feedback_scope: "resource_projection",
                trust_boundary: "mission_state_resource_projection_report"
              },
              %{
                type: "resource_margin_pressure",
                spacecraft_id: "leo_1",
                scenario_id: "leo_1",
                timeline_id: "timeline:resource_margin:power",
                source_activity_id: "obs_power_pressure",
                replacement_activity_id: "obs_power_pressure_replanned",
                source_activity_ids: ["obs_power_pressure"],
                resource_field: "power_margin",
                power_margin: 0.08,
                power_margin_threshold: 0.2,
                source_quality: "declared",
                starts_at_s: 500.0,
                ends_at_s: 560.0,
                diff_status: "changed",
                changed_fields: ["power_margin"],
                required_operator_action: "review_resource_margin",
                requires_operator_review: true,
                feedback_source: "mission_state.source_resource_projection_report.rows",
                feedback_scope: "resource_margin",
                feedback_key: "leo_1.power_margin",
                trust_boundary: "mission_state_resource_projection_report",
                derivation_reasons: ["resource_projection_power_margin_low"]
              },
              %{
                type: "maneuver_execution_uncertainty_feedback",
                activity_id: "burn_uncertain_review",
                timeline_id: "timeline:maneuver:burn_uncertain_review",
                maneuver_id: "burn_uncertain_review",
                scenario_id: "leo_1",
                starts_at_s: 620.0,
                ends_at_s: 620.0,
                source_activity_id: "burn_uncertain_source",
                replacement_activity_id: "burn_uncertain_review",
                source_activity_ids: ["burn_uncertain_review", "burn_uncertain_source"],
                execution_uncertainty_status: "declared",
                execution_uncertainty: %{
                  "timing_3sigma_s" => 75.0,
                  "delta_v_3sigma_km_s" => [0.0, 0.003, 0.004],
                  "source" => "ops_covariance_review"
                },
                timing_3sigma_s: 75.0,
                timing_3sigma_threshold_s: 60.0,
                delta_v_3sigma_km_s: [0.0, 0.003, 0.004],
                delta_v_3sigma_magnitude_km_s: 0.005,
                delta_v_3sigma_magnitude_threshold_km_s: 0.002,
                execution_uncertainty_source: "ops_covariance_review",
                changed_fields: ["execution_uncertainty"],
                required_operator_action: "review_maneuver_execution_uncertainty",
                requires_operator_review: true,
                feedback_source: "mission_state.source_maneuver_review.rows",
                feedback_scope: "maneuver_execution_uncertainty",
                feedback_key: "burn_uncertain_review",
                trust_boundary: "mission_state_maneuver_review",
                derivation_reasons: ["maneuver_review_execution_uncertainty_pressure"]
              },
              %{
                type: "timeline_publication_pressure",
                publication_id:
                  "timeline_publication:9:timeline:selected_plan:v2:timeline:selected_plan:v1",
                publication_sequence: 9,
                publication_status: "published_with_downstream_invalidations",
                downstream_invalidation_status: "invalidated",
                dependency_impact_status: "review_required",
                source_artifact_id: "timeline:selected_plan:v2",
                source_artifact_type: "operational_timeline_report.v1",
                publication_authority: "mission_operations",
                supersedes_artifact_ids: ["timeline:selected_plan:v1"],
                downstream_product_ids: [
                  "operator_review:selected:v1",
                  "cadence_import:selected:v1"
                ],
                invalidated_downstream_product_ids: [
                  "cadence_import:selected:v1",
                  "operator_review:selected:v1"
                ],
                downstream_invalidation_reason_counts: %{
                  "dependency_impact_review_required" => 2
                },
                downstream_invalidation_reasons: ["dependency_impact_review_required"],
                invalidated_downstream_product_ids_by_reason: %{
                  "dependency_impact_review_required" => [
                    "cadence_import:selected:v1",
                    "operator_review:selected:v1"
                  ]
                },
                dependency_impact_row_count: 2,
                timeline_diff_row_count: 3,
                timeline_diff_changed_count: 2,
                timeline_diff_review_required_count: 1,
                changed_field_counts: %{"timeline_presence" => 2},
                changed_fields: ["timeline_presence"],
                changed_timeline_ids: ["timeline:health_check:0.0"],
                review_timeline_ids: ["timeline:health_check:0.0", "timeline:health_check:5.0"],
                timeline_ids_by_changed_field: %{
                  "timeline_presence" => [
                    "timeline:health_check:0.0",
                    "timeline:health_check:5.0"
                  ]
                },
                feedback_source: "mission_state.source_timeline_publication_summary",
                feedback_scope: "timeline_publication",
                feedback_key:
                  "timeline_publication:9:timeline:selected_plan:v2:timeline:selected_plan:v1",
                trust_boundary: "mission_state_timeline_publication_summary",
                derivation_reasons: ["timeline_publication_summary_pressure"],
                assumptions: %{
                  "publication_execution" => "not_performed_by_strategy_branch",
                  "notification_delivery" => "not_performed_by_strategy_branch",
                  "operator_authority" => "not_granted_by_strategy_branch",
                  "import_approval" => "not_granted_by_strategy_branch"
                }
              },
              %{
                type: "timeline_lifecycle_state_pressure",
                timeline_lifecycle_state_status: "review_required",
                planned_activity_count: 4,
                realized_activity_count: 1,
                row_count: 4,
                recordable_count: 3,
                preserved_count: 1,
                review_required_count: 3,
                duplicate_timeline_identity_count: 1,
                invalid_activity_input_count: 1,
                transition_decision_counts: %{"record" => 3, "none" => 1},
                required_operator_action_counts: %{
                  "review_activity_approval" => 1,
                  "review_duplicate_timeline_identity" => 1,
                  "review_invalid_activity_input" => 1
                },
                operator_action_reason_counts: %{
                  "activity_approval_pending" => 1,
                  "duplicate_timeline_identity" => 1,
                  "missing_activity_type" => 1
                },
                import_action_counts: %{"review_timeline_diff" => 3},
                planned_status_category_counts: %{"planned" => 4},
                realized_status_category_counts: %{"executed" => 1},
                status_transition_category_counts: %{"changed" => 1},
                approval_transition_category_counts: %{"changed" => 1},
                recordable_timeline_ids: [
                  "timeline:lifecycle:cmd_pending",
                  "timeline:lifecycle:dup",
                  "timeline:invalid_activity_input:lifecycle_bad_missing_type"
                ],
                preserved_timeline_ids: ["timeline:lifecycle:obs_preserved"],
                review_timeline_ids: [
                  "timeline:lifecycle:cmd_pending",
                  "timeline:lifecycle:dup",
                  "timeline:invalid_activity_input:lifecycle_bad_missing_type"
                ],
                review_activity_ids: [
                  "lifecycle_cmd_pending",
                  "lifecycle_dup_a",
                  "lifecycle_dup_b",
                  "timeline_row:4:lifecycle_bad_missing_type"
                ],
                invalid_activity_input_ids: ["timeline_row:4:lifecycle_bad_missing_type"],
                review_timeline_ids_by_required_operator_action: %{
                  "review_activity_approval" => ["timeline:lifecycle:cmd_pending"],
                  "review_duplicate_timeline_identity" => ["timeline:lifecycle:dup"],
                  "review_invalid_activity_input" => [
                    "timeline:invalid_activity_input:lifecycle_bad_missing_type"
                  ]
                },
                review_timeline_ids_by_operator_action_reason: %{
                  "activity_approval_pending" => ["timeline:lifecycle:cmd_pending"],
                  "duplicate_timeline_identity" => ["timeline:lifecycle:dup"],
                  "missing_activity_type" => [
                    "timeline:invalid_activity_input:lifecycle_bad_missing_type"
                  ]
                },
                review_timeline_ids_by_status_transition_category: %{
                  "changed" => ["timeline:lifecycle:cmd_pending"]
                },
                review_timeline_ids_by_approval_transition_category: %{
                  "changed" => ["timeline:lifecycle:cmd_pending"]
                },
                requires_operator_review: true,
                required_operator_action: "review_timeline_lifecycle_state",
                feedback_source: "mission_state.source_timeline_lifecycle_state_summary",
                feedback_scope: "timeline_lifecycle_state",
                feedback_key: "mission.lifecycle.summary",
                trust_boundary: "mission_state_timeline_lifecycle_state_summary",
                derivation_reasons: ["timeline_lifecycle_state_summary_pressure"],
                assumptions: %{
                  "timeline_lifecycle_application" => "not_performed_by_strategy_branch",
                  "timeline_mutation" => "not_performed_by_strategy_branch",
                  "operator_authority" => "not_granted_by_strategy_branch",
                  "cadence_import" => "not_performed_by_strategy_branch",
                  "command_execution" => "not_performed_by_strategy_branch"
                }
              },
              %{
                type: "timeline_activity_lifecycle_state_pressure",
                activity_id: "activity_lifecycle_cmd_pending",
                timeline_id: "timeline:activity_lifecycle:cmd_pending",
                planned_activity_id: "activity_lifecycle_cmd_pending",
                realized_activity_id: "activity_lifecycle_cmd_pending",
                planned_timeline_id: "timeline:activity_lifecycle:cmd_pending",
                realized_timeline_id: "timeline:activity_lifecycle:cmd_pending",
                transition_decision: "review",
                status_transition_decision: "record",
                approval_transition_decision: "review",
                review_required: true,
                requires_operator_review: true,
                required_operator_action: "review_activity_approval",
                required_operator_actions: [
                  "record_timeline_change",
                  "review_activity_approval"
                ],
                operator_action_reasons: [
                  "activity_execution_recorded",
                  "approval_grant_requires_operator_authority"
                ],
                import_action: "review_timeline_diff",
                invalid_activity_input: false,
                invalid_activity_input_count: 0,
                invalid_activity_input_reasons: [],
                planned_status: "planned",
                realized_status: "executed",
                planned_status_category: "planned",
                realized_status_category: "executed",
                planned_approval_status: "pending",
                realized_approval_status: "approved",
                planned_approval_category: "pending",
                realized_approval_category: "approval_granted",
                planned_locked: false,
                realized_locked: false,
                planned_executed: false,
                realized_executed: true,
                status_transition: %{
                  "field" => "status",
                  "from" => "planned",
                  "to" => "executed",
                  "transition_type" => "status_changed",
                  "transition_category" => "planned_to_executed",
                  "transition_reason" => "activity execution recorded",
                  "requires_operator_review" => false
                },
                approval_transition: %{
                  "field" => "approval_status",
                  "from" => "pending",
                  "to" => "approved",
                  "transition_type" => "approval_state_changed",
                  "transition_category" => "pending_to_approved",
                  "transition_reason" => "approval grant requires operator authority",
                  "requires_operator_review" => true
                },
                planned_protection_decision: "record",
                realized_protection_decision: "review",
                feedback_source: "mission_state.source_timeline_activity_lifecycle_state",
                feedback_scope: "timeline_activity_lifecycle_state",
                feedback_key: "activity_lifecycle_cmd_pending",
                trust_boundary: "mission_state_timeline_activity_lifecycle_state",
                derivation_reasons: ["timeline_activity_lifecycle_state_pressure"],
                assumptions: %{
                  "timeline_lifecycle_application" => "not_performed_by_strategy_branch",
                  "timeline_mutation" => "not_performed_by_strategy_branch",
                  "operator_authority" => "not_granted_by_strategy_branch",
                  "cadence_import" => "not_performed_by_strategy_branch",
                  "command_execution" => "not_performed_by_strategy_branch"
                }
              },
              %{
                type: "timeline_preservation_pressure",
                activity_id: "contact_locked_review",
                timeline_id: "timeline:contact_locked_review",
                timeline_preservation_status: "review_required",
                requires_preservation: false,
                requires_operator_review: true,
                status: "planned",
                approval_status: "approved",
                locked: true,
                approved: true,
                protection_decision: "preserve",
                protection_category: "locked_or_approved",
                protection_reason: "activity_locked_or_approved",
                activity_count: 3,
                preserve_activity_count: 2,
                review_change_activity_count: 1,
                preservation_sensitive_activity_count: 2,
                preserve_activity_ids: ["contact_locked_review", "obs_done_review"],
                preserve_timeline_ids: [
                  "timeline:contact_locked_review",
                  "timeline:obs_done_review"
                ],
                review_change_activity_ids: ["bad_missing_type_review"],
                review_change_timeline_ids: ["timeline:bad_missing_type_review"],
                preservation_sensitive_activity_ids: [
                  "contact_locked_review",
                  "obs_done_review"
                ],
                preservation_sensitive_timeline_ids: [
                  "timeline:contact_locked_review",
                  "timeline:obs_done_review"
                ],
                invalid_activity_input: false,
                required_operator_action: "review_timeline_preservation",
                feedback_source: "mission_state.source_timeline_preservation_report.rows[0]",
                feedback_scope: "timeline_preservation",
                feedback_key: "contact_locked_review",
                trust_boundary: "mission_state_timeline_preservation_report",
                derivation_reasons: ["timeline_preservation_pressure"],
                assumptions: %{
                  "timeline_preservation_application" => "not_performed_by_strategy_branch",
                  "timeline_mutation" => "not_performed_by_strategy_branch",
                  "operator_authority" => "not_granted_by_strategy_branch",
                  "cadence_import" => "not_performed_by_strategy_branch"
                }
              },
              %{
                type: "provider_reservation_request_pressure",
                contact_id: "dl_provider_review",
                source_activity_id: "dl_provider_review",
                source_activity_ids: ["dl_provider_review"],
                ground_station_id: "equator_prime",
                direction: "downlink",
                station_reservation_id: "provider_reservation_review",
                station_reserved_by: "partner_calendar",
                station_reservation_status: "confirmed",
                station_reservation_expiration_status: "active",
                station_reservation_match_status: "overlap",
                provider_reservation_request_status: "review_required",
                provider_reservation_row_scope: "review",
                required_operator_action: "review_provider_reservation_request",
                feedback_source:
                  "mission_state.source_contact_allocation_provider_reservation_request_summary",
                feedback_scope: "contact_allocation_provider_reservation_request",
                trust_boundary: "mission_state_provider_reservation_request_summary",
                assumptions: %{
                  "provider_reservation_execution" => "not_performed_by_strategy_branch",
                  "schedule_mutation" => "not_performed_by_strategy_branch",
                  "operator_authority" => "not_granted_by_strategy_branch"
                }
              },
              %{
                type: "downlink_completion_gap",
                scenario_id: "leo_1",
                spacecraft_id: "leo_1",
                contact_id: "dl_capacity_overflow",
                source_activity_id: "dl_capacity_overflow",
                source_activity_ids: ["dl_capacity_overflow"],
                ground_station_id: "equator_prime",
                starts_at_s: 1_560.0,
                ends_at_s: 1_620.0,
                source_window_id: "window_capacity_overflow",
                required_contacts: 1,
                planned_contacts: 0,
                required_downlink_mb: 47.0,
                planned_downlink_mb: 0.0,
                selected_contact_id: "dl_capacity_selected",
                selected_priority_source: "policy_contact_priority",
                selection_reason: "highest_priority_highest_score",
                resolution_selection_rule: "highest_priority_highest_score",
                resolution_priority_override_count: 2,
                resolution_priority_override_contact_ids: [
                  "dl_capacity_selected",
                  "dl_capacity_overflow"
                ],
                review_status: "operator_review_required",
                capacity_pack_group_id: "capacity_pack_equator_prime",
                capacity_pack_status: "deferred_by_reduced_station_capacity_pack",
                capacity_pack_capacity_fraction: 0.5,
                capacity_pack_used_fraction: 0.5,
                capacity_pack_unused_fraction: 0.0,
                required_capacity_fraction: 0.25,
                required_capacity_fraction_source: "contact_required_capacity_fraction",
                capacity_pack_contact_ids_by_direction: %{
                  "downlink" => ["dl_capacity_selected", "dl_capacity_overflow"]
                },
                capacity_pack_selected_contact_ids_by_direction: %{
                  "downlink" => ["dl_capacity_selected"]
                },
                capacity_pack_deferred_contact_ids_by_direction: %{
                  "downlink" => ["dl_capacity_overflow"]
                },
                capacity_pack_required_capacity_fraction_by_direction: %{
                  "downlink" => 0.75
                },
                capacity_pack_selected_required_capacity_fraction_by_direction: %{
                  "downlink" => 0.5
                },
                capacity_pack_deferred_required_capacity_fraction_by_direction: %{
                  "downlink" => 0.25
                },
                derivation_reasons: [
                  "contact_contention_deferred",
                  "deferred_by_reduced_station_capacity_pack"
                ],
                downlink_demand_sources: [
                  "contention_resolution.required_downlink:dl_capacity_overflow"
                ],
                downlink_completion_sources: [
                  "contact_contention_resolution_report:recommendations"
                ],
                feedback_source: "mission_state.source_contact_allocation_capacity_pack_summary",
                feedback_scope: "contact_contention_resolution",
                trust_boundary: "mission_state_capacity_pack_summary"
              },
              %{
                type: "downlink_completion_gap",
                scenario_id: "leo_1",
                spacecraft_id: "leo_1",
                contact_id: "dl_contention_conflict",
                source_activity_id: "dl_contention_conflict",
                source_activity_ids: ["dl_contention_conflict"],
                ground_station_id: "equator_prime",
                starts_at_s: 1_580.0,
                ends_at_s: 1_640.0,
                source_window_id: "window_contention_conflict",
                source_window_ids: [
                  "window_contention_primary",
                  "window_contention_conflict"
                ],
                required_contacts: 1,
                planned_contacts: 0,
                required_downlink_mb: 39.0,
                planned_downlink_mb: 0.0,
                contention_group_id: "station:equator_prime:contention:selected",
                contention_resource_scope: "ground_station",
                contention_contact_ids: [
                  "dl_contention_primary",
                  "dl_contention_conflict"
                ],
                required_operator_action: "review_contact_contention",
                approval_status: "operator_review_required",
                operator_action_reason: "same_station_overlapping_contact_windows",
                derivation_reasons: [
                  "contact_contention_conflict",
                  "same_station_overlapping_contact_windows",
                  "ground_station",
                  "operator_review_required"
                ],
                downlink_demand_sources: [
                  "contact_contention.required_downlink:dl_contention_conflict"
                ],
                downlink_completion_sources: [
                  "contact_contention_report:conflict_groups"
                ],
                feedback_source: "mission_state.source_contact_contention_report.conflict_groups",
                feedback_scope: "contact_contention",
                trust_boundary: "mission_state_contact_contention_report"
              },
              %{
                type: "downlink_completion_gap",
                scenario_id: "leo_1",
                spacecraft_id: "leo_1",
                contact_id: "dl_reservation_conflict",
                source_activity_id: "dl_reservation_conflict",
                source_activity_ids: ["dl_reservation_conflict"],
                ground_station_id: "equator_prime",
                required_contacts: 1,
                planned_contacts: 0,
                required_downlink_mb: 43.0,
                planned_downlink_mb: 0.0,
                starts_at_s: 1_620.0,
                ends_at_s: 1_680.0,
                source_window_id: "window_allocation_deferred",
                realized_status: "deferred",
                contact_result: "same_station_contention",
                allocation_status: "deferred",
                effective_allocation_status: "deferred",
                allocation_reason: "same_station_contention",
                review_status: "operator_review_required",
                approval_status: "operator_review_required",
                policy_classification: "review_only",
                policy_bundle_id: "contact_allocation_policy_v1",
                station_reservation_id: "reservation_conflict_1",
                station_reserved_by: "ops_team_b",
                station_reservation_status: "confirmed",
                station_reservation_expiration_status: "active",
                station_reservation_match_status: "overlap",
                station_reservation_expires_at_s: 360.0,
                station_calendar_entry_id: "calendar_allocation_deferred",
                station_calendar_entry_status: "reserved",
                station_calendar_directions: ["downlink"],
                downlink_demand_sources: ["contact_allocation:dl_reservation_conflict"],
                downlink_completion_sources: ["contact_allocation_report:selected_contacts"],
                derivation_reasons: ["contact_allocation_reservation_conflict"],
                feedback_source:
                  "mission_state.source_contact_allocation_reservation_conflict_summary",
                feedback_scope: "contact_allocation",
                trust_boundary: "mission_state_reservation_conflict_summary"
              },
              %{
                type: "downlink_completion_gap",
                contact_id: "dl_hold_import_review",
                source_activity_id: "dl_hold_import_review",
                source_activity_ids: ["dl_hold_import_review"],
                ground_station_id: "equator_prime",
                direction: "downlink",
                required_contacts: 1,
                planned_contacts: 0,
                required_downlink_mb: 41.0,
                planned_downlink_mb: 0.0,
                station_reservation_id: "reservation_hold_active",
                station_reserved_by: "ops_calendar",
                station_reservation_status: "held",
                station_reservation_expiration_status: "active",
                station_reservation_match_status: "overlap",
                station_reservation_expires_at_s: 120.0,
                station_reservation_hold_import_status: "review_required_before_import",
                station_reservation_hold_import_readiness_summary_model:
                  "artifact_only_station_reservation_hold_import_readiness_summary",
                station_reservation_hold_import_readiness_source:
                  "station_calendar_report.reservation_evidence",
                station_reservation_hold_import_readiness_source_artifact_type:
                  "station_reservation_report.v1",
                station_reservation_hold_import_readiness_status: "review_required",
                station_reservation_hold_import_classification: "review_only",
                station_reservation_hold_count: 2,
                station_reservation_hold_ids: [
                  "reservation_hold_active",
                  "reservation_hold_missing"
                ],
                station_reservation_hold_ids_by_import_status: %{
                  "review_required_before_import" => [
                    "reservation_hold_active",
                    "reservation_hold_missing"
                  ]
                },
                station_reservation_hold_ids_by_required_import_action: %{
                  "review_station_provider_contention" => ["reservation_hold_missing"],
                  "review_station_reservation_overlap" => ["reservation_hold_active"]
                },
                station_reservation_hold_ids_by_direction: %{
                  "downlink" => ["reservation_hold_active"],
                  "uplink" => ["reservation_hold_missing"]
                },
                station_reservation_hold_ids_by_direction_and_ground_station_id: %{
                  "downlink:equator_prime" => ["reservation_hold_active"],
                  "uplink:equator_prime" => ["reservation_hold_missing"]
                },
                station_reservation_hold_contact_ids_by_import_status: %{
                  "review_required_before_import" => ["dl_hold_import_review"]
                },
                station_reservation_hold_contact_ids_by_expiration_status: %{
                  "active" => ["dl_hold_import_review"]
                },
                station_reservation_hold_contact_ids_by_direction: %{
                  "downlink" => ["dl_hold_import_review"]
                },
                station_reservation_hold_contact_ids_by_direction_and_ground_station_id: %{
                  "downlink:equator_prime" => ["dl_hold_import_review"]
                },
                station_reservation_hold_import_status_counts: %{
                  "review_required_before_import" => 2
                },
                station_reservation_hold_required_import_action_counts: %{
                  "review_station_provider_contention" => 1,
                  "review_station_reservation_overlap" => 1
                },
                station_reservation_hold_import_execution_boundary:
                  "artifact_only_no_provider_or_cadence_writes",
                station_reservation_hold_provider_write: "not_performed_by_summary",
                station_reservation_hold_cadence_write: "not_performed_by_summary",
                station_reservation_hold_reservation_acceptance: "not_performed_by_summary",
                source_station_reservation_hold_import_readiness_summary: %{
                  "model" => "artifact_only_station_reservation_hold_import_readiness_summary",
                  "source_artifact_type" => "station_reservation_report.v1",
                  "source" => "station_calendar_report.reservation_evidence",
                  "reservation_hold_count" => 2,
                  "import_readiness_status" => "review_required",
                  "import_classification" => "review_only"
                },
                derivation_reasons: ["branch_local_reservation_hold_import_readiness_pressure"],
                feedback_source:
                  "mission_state.source_station_reservation_hold_import_readiness_summary",
                feedback_scope: "station_reservation_hold_import_readiness",
                trust_boundary: "mission_state_station_reservation_hold_import_readiness_summary"
              },
              %{
                type: "provider_counteroffer_pressure",
                provider_counteroffer_id: "provider_offer_urgent",
                provider_counteroffer_status: "proposed",
                provider_counteroffer_negotiation_state: "proposed",
                provider_counteroffer_reason_code: "provider_shifted_window",
                provider_counteroffer_cost_delta: 125.5,
                provider_counteroffer_lock_deadline_s: 150.0,
                provider_counteroffer_starts_at_s: 530.0,
                provider_counteroffer_ends_at_s: 590.0,
                provider_counteroffer_start_delta_s: 30.0,
                provider_counteroffer_end_delta_s: 30.0,
                provider_counteroffer_duration_delta_s: 0.0,
                plan_impact_status: "review_required",
                affected_station_calendar_entry_ids: ["contact_original"],
                affected_provider_entry_ids: ["partner_entry_42"],
                impact_counteroffer_ids: ["provider_offer_urgent"],
                ground_station_id: "equator_prime",
                starts_at_s: 500.0,
                ends_at_s: 560.0,
                station_calendar_entry_id: "contact_original",
                station_calendar_provider_id: "partner_calendar",
                station_calendar_provider_entry_id: "partner_entry_42",
                station_availability: "counteroffer",
                required_operator_action: "review_provider_counteroffer",
                feedback_source: "mission_state.source_provider_counteroffer_report.rows",
                feedback_scope: "provider_counteroffer",
                feedback_key: "provider_offer_urgent",
                trust_boundary: "mission_state_provider_counteroffer_report",
                source_provider_counteroffer: %{
                  "provider_counteroffer_id" => "provider_offer_urgent",
                  "required_operator_action" => "review_provider_counteroffer"
                }
              },
              %{
                type: "candidate_rejection_pressure",
                candidate_id: "dl_rejected_hot",
                activity_id: "dl_rejected_hot",
                activity_type: "downlink",
                scenario_id: "leo_1",
                ground_station_id: "equator_prime",
                source_window_id: "equator_prime_rejected_window",
                source_window_type: "ground_station_contact",
                rejection_status: "rejected",
                primary_rejection_reason: "contact_too_short",
                rejection_reasons: [
                  "contact_too_short",
                  "station_capacity_reduced",
                  "station_reserved"
                ],
                violated_constraint: "min_duration_s",
                required_margin: 10.0,
                actual_margin: 5.0,
                required_operator_action: "review_candidate_rejection",
                feedback_source: "mission_state.source_candidate_rejection_report.rows",
                feedback_scope: "candidate_rejection",
                feedback_key: "dl_rejected_hot",
                trust_boundary: "mission_state_candidate_rejection_report",
                source_candidate_rejection: %{
                  "candidate_id" => "dl_rejected_hot",
                  "required_operator_action" => "review_candidate_rejection"
                }
              },
              %{
                type: "model_acceptance_pressure",
                report_id: "model_acceptance:operational_import:live_ops",
                intended_use: "operational_import",
                model_acceptance_status: "review_required",
                model_count: 1,
                accepted_count: 0,
                review_required_count: 1,
                blocked_count: 0,
                unknown_model_count: 0,
                status_counts: %{"review_required" => 1},
                validation_level_counts: %{"analysis" => 1},
                model_ids_by_status: %{"review_required" => ["live_analysis_model"]},
                model_ids_by_validation_level: %{"analysis" => ["live_analysis_model"]},
                model_ids_by_intended_use: %{"operational_import" => ["live_analysis_model"]},
                model_id: "live_analysis_model",
                validation_level: "analysis",
                model_status: "review_required",
                model_reason: "analysis evidence requires operator review for operational_import",
                required_operator_action: "review_model_acceptance",
                feedback_source: "mission_state.source_model_acceptance_report.rows",
                feedback_scope: "model_acceptance",
                feedback_key: "live_analysis_model",
                trust_boundary: "mission_state_model_acceptance_report"
              },
              %{
                type: "schema_validation_pressure",
                validation_status: "fail",
                validation_mode: "artifact_file",
                validated_contract: "candidate_refresh.v1",
                validated_artifact_family: "candidate_refresh",
                artifact_path: "study_results/candidate_refresh.json",
                issue_severity: "error",
                issue_path: "$.candidate_plan.activities[0].id",
                error_count: 1,
                warning_count: 0,
                remediation_count: 1,
                remediation_category: "schema_contract",
                remediation_action: "regenerate_candidate_refresh",
                required_operator_action: "review_schema_validation",
                feedback_source: "mission_state.source_schema_validation_report.errors",
                feedback_scope: "schema_validation",
                feedback_key: "$.candidate_plan.activities[0].id",
                trust_boundary: "mission_state_schema_validation_report"
              },
              %{
                type: "validation_safety_case_pressure",
                report_id: "validation_safety_case:live_ops",
                validation_safety_case_status: "blocked",
                evidence_status: "blocked",
                input_contract: "model_acceptance_report.v1",
                input_contracts: ["model_acceptance_report.v1", "quality_gate_report.v1"],
                evidence_ref: "model_acceptance_report.v1:model.blocked",
                evidence_count: 2,
                accepted_evidence_count: 0,
                review_required_evidence_count: 1,
                blocked_evidence_count: 1,
                model_blocked_count: 1,
                quality_gate_review_count: 1,
                quality_gate_blocked_count: 1,
                schema_error_count: 1,
                schema_warning_count: 2,
                evidence_status_counts: %{"blocked" => 1, "review_required" => 1},
                evidence_refs_by_status: %{
                  "blocked" => ["model_acceptance_report.v1:model.blocked"],
                  "review_required" => ["quality_gate_report.v1:gate.review"]
                },
                evidence_refs_by_contract: %{
                  "model_acceptance_report.v1" => ["model_acceptance_report.v1:model.blocked"],
                  "quality_gate_report.v1" => ["quality_gate_report.v1:gate.review"]
                },
                required_operator_action: "review_blocked_validation_safety_case",
                feedback_source: "mission_state.source_validation_safety_case_summary.evidence",
                feedback_scope: "validation_safety_case",
                feedback_key: "model_acceptance_report.v1:model.blocked",
                trust_boundary: "mission_state_validation_safety_case_summary"
              },
              %{
                type: "refresh_budget_pressure",
                input_candidate_count: 8,
                kept_candidate_count: 4,
                dropped_candidate_count: 4,
                invalid_limit_count: 0,
                current_max_candidate_activities: 4,
                relaxed_max_candidate_activities: 8,
                candidate_limit_status: "relaxed_required",
                refresh_budget_status: "review_required",
                required_operator_action: "review_refresh_budget",
                feedback_source: "mission_state.source_refresh_budget_report",
                feedback_scope: "refresh_budget",
                feedback_key: "refresh_budget:limit",
                trust_boundary: "mission_state_refresh_budget_report"
              },
              %{
                type: "refresh_freshness_pressure",
                freshness_status: "stale",
                state_quality_status: "stale",
                accepted_snapshot_age_s: 3600.0,
                horizon_start_offset_s: 120.0,
                max_snapshot_age_s: 60.0,
                max_horizon_start_offset_s: 30.0,
                stale_reasons: [
                  "accepted_snapshot_older_than_policy",
                  "horizon_start_offset_exceeds_policy"
                ],
                unknown_reasons: [],
                required_operator_action: "review_refresh_freshness",
                feedback_source: "mission_state.source_freshness_report",
                feedback_scope: "refresh_freshness",
                feedback_key: "freshness:stale",
                trust_boundary: "mission_state_freshness_report"
              }
            ]
          }
        ],
        current_epoch_s: 0.0
      )

    artifact
  end

  def invalid_contact_intent_artifact do
    artifact(
      invalid_activity_input: true,
      invalid_activity_input_reason: "missing_activity_type"
    )
  end
end
