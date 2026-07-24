defmodule OrbitalDynamics.CampaignPlanner.StrategyRecommendationPressureExpectedHandoffFixture do
  def expected_handoff do
    expected_handoff =
      %{
        "operational_readiness_report_ids" => [
          "operational_readiness:resource_projection_report.v1:live_ops"
        ],
        "operational_readiness_source_artifact_types" => ["resource_projection_report.v1"],
        "operational_readiness_source_artifact_ids" => ["live_ops"],
        "operational_readiness_levels" => ["operator_review"],
        "operational_readiness_import_classifications" => ["review_only"],
        "operational_readiness_statuses" => ["review_required"],
        "operational_readiness_gate_ids" => ["operator_training"],
        "operational_readiness_gate_statuses" => ["review_required"],
        "operational_readiness_gate_classifications" => ["review_only"],
        "operational_readiness_required_operator_actions" => ["review_operational_readiness"],
        "operational_readiness_feedback_sources" => [
          "mission_state.source_operational_readiness_report.gates"
        ],
        "operational_readiness_feedback_scopes" => ["operational_readiness"],
        "operational_readiness_feedback_keys" => ["operator_training"],
        "operational_readiness_trust_boundaries" => [
          "mission_state_operational_readiness_report"
        ],
        "quality_gate_report_ids" => ["quality_gate:resource_projection_report.v1:live_ops"],
        "quality_gate_source_artifact_types" => ["resource_projection_report.v1"],
        "quality_gate_source_artifact_ids" => ["live_ops"],
        "quality_gate_source_readiness_report_ids" => [
          "operational_readiness:resource_projection_report.v1:live_ops"
        ],
        "quality_gate_readiness_levels" => ["operator_review"],
        "quality_gate_import_classifications" => ["review_only"],
        "quality_gate_pressure_statuses" => ["review_required"],
        "quality_gate_ids" => ["resource_availability"],
        "quality_gate_statuses" => ["review_required"],
        "quality_gate_classifications" => ["review_only"],
        "quality_gate_required_operator_actions" => ["review_operational_readiness"],
        "quality_gate_feedback_sources" => ["mission_state.source_quality_gate_report.rows"],
        "quality_gate_feedback_scopes" => ["quality_gate"],
        "quality_gate_feedback_keys" => ["resource_availability"],
        "quality_gate_trust_boundaries" => ["mission_state_quality_gate_report"],
        "quality_gate_resource_availability_reason_ids" => [
          "antenna_unavailable",
          "payload_unavailable"
        ],
        "approval_boundary_ids" => ["command_execution"],
        "approval_boundary_statuses" => ["operator_review_required"],
        "approval_boundary_reasons" => [
          "command execution requires flight director approval"
        ],
        "automation_boundaries" => ["no_command_execution"],
        "execution_boundaries" => ["flight_director_approval"],
        "approval_boundary_import_classifications" => ["review_only"],
        "approval_boundary_required_operator_actions" => ["review_approval_boundary"],
        "approval_boundary_required_authorities" => ["flight_director"],
        "approval_boundary_policy_bundle_ids" => ["flight_rules_v3"],
        "approval_boundary_rule_ids" => ["no_unapproved_command_execution"],
        "approval_boundary_feedback_sources" => [
          "mission_state.source_approval_boundary_policy.rules"
        ],
        "approval_boundary_feedback_scopes" => ["approval_boundary"],
        "approval_boundary_feedback_keys" => ["no_unapproved_command_execution"],
        "approval_boundary_trust_boundaries" => ["mission_state_approval_boundary_policy"],
        "timeline_activity_precondition_activity_ids" => ["cmd_precondition_review"],
        "timeline_activity_precondition_timeline_ids" => ["timeline:cmd_precondition_review"],
        "timeline_activity_precondition_activity_types" => ["command"],
        "timeline_activity_precondition_statuses" => ["blocked"],
        "timeline_activity_precondition_blocked_count_values" => [2],
        "timeline_activity_precondition_review_count_values" => [1],
        "timeline_activity_precondition_blocked_types" => [
          "command_safety_failed",
          "payload_unavailable"
        ],
        "timeline_activity_precondition_review_types" => ["command_authority_missing"],
        "timeline_activity_precondition_dependency_activity_ids" => ["health_check"],
        "timeline_activity_precondition_dependency_timeline_ids" => ["timeline:health_check"],
        "timeline_activity_precondition_exclusive_with_activity_ids" => ["downlink_conflict"],
        "timeline_activity_precondition_exclusive_with_timeline_ids" => [
          "timeline:downlink_conflict"
        ],
        "timeline_activity_precondition_duplicate_dependency_activity_ids" => ["health_check"],
        "timeline_activity_precondition_duplicate_dependency_timeline_ids" => [
          "timeline:health_check"
        ],
        "timeline_activity_precondition_duplicate_exclusivity_activity_ids" => [
          "downlink_conflict"
        ],
        "timeline_activity_precondition_duplicate_exclusivity_timeline_ids" => [
          "timeline:downlink_conflict"
        ],
        "timeline_activity_precondition_allow_overlap_values" => [true],
        "timeline_activity_precondition_invalid_activity_input_values" => [false],
        "timeline_activity_precondition_required_operator_actions" => [
          "review_blocked_activity_precondition"
        ],
        "timeline_activity_precondition_requires_operator_review_values" => [true],
        "timeline_activity_precondition_feedback_sources" => [
          "mission_state.source_timeline_activity_precondition_summary"
        ],
        "timeline_activity_precondition_feedback_scopes" => [
          "timeline_activity_precondition"
        ],
        "timeline_activity_precondition_feedback_keys" => ["cmd_precondition_review"],
        "timeline_activity_precondition_trust_boundaries" => [
          "mission_state_timeline_activity_precondition_summary"
        ],
        "timeline_activity_precondition_derivation_reasons" => [
          "timeline_activity_precondition_summary_pressure"
        ],
        "timeline_activity_precondition_assumption_maps" => [
          %{
            "activity_precondition_evaluation" => "not_performed_by_strategy_branch",
            "timeline_mutation" => "not_performed_by_strategy_branch",
            "operator_authority" => "not_granted_by_strategy_branch",
            "cadence_import" => "not_performed_by_strategy_branch"
          }
        ],
        "timeline_dependency_impact_activity_ids" => ["cmd_dependency_review"],
        "timeline_dependency_impact_timeline_ids" => ["timeline:cmd_dependency_review"],
        "timeline_dependency_impact_scopes" => ["source"],
        "timeline_dependency_impact_statuses" => ["review_required"],
        "timeline_dependency_impact_required_operator_actions" => [
          "review_timeline_dependency_impact"
        ],
        "timeline_dependency_impact_operator_action_reasons" => [
          "dependency_link_impacted_by_timeline_change"
        ],
        "timeline_dependency_impact_dependency_activity_ids" => ["health_check"],
        "timeline_dependency_impact_dependency_timeline_ids" => ["timeline:health_check"],
        "timeline_dependency_impact_exclusive_with_activity_ids" => ["downlink_conflict"],
        "timeline_dependency_impact_exclusive_with_timeline_ids" => [
          "timeline:downlink_conflict"
        ],
        "timeline_dependency_impact_impacted_dependency_activity_ids" => ["health_check"],
        "timeline_dependency_impact_impacted_dependency_timeline_ids" => [
          "timeline:health_check"
        ],
        "timeline_dependency_impact_impacted_exclusive_with_activity_ids" => [
          "downlink_conflict"
        ],
        "timeline_dependency_impact_impacted_exclusive_with_timeline_ids" => [
          "timeline:downlink_conflict"
        ],
        "timeline_dependency_impact_feedback_sources" => [
          "mission_state.source_timeline_dependency_impact_summary.dependency_impact_rows"
        ],
        "timeline_dependency_impact_feedback_scopes" => ["timeline_dependency_impact"],
        "timeline_dependency_impact_feedback_keys" => ["cmd_dependency_review"],
        "timeline_dependency_impact_trust_boundaries" => [
          "mission_state_timeline_dependency_impact_summary"
        ],
        "timeline_dependency_impact_derivation_reasons" => [
          "timeline_dependency_impact_summary_pressure"
        ],
        "timeline_integrity_risk_types" => ["timeline_integrity_issue"],
        "timeline_integrity_activity_ids" => ["cmd_integrity_review"],
        "timeline_integrity_timeline_ids" => ["timeline:cmd_integrity_review"],
        "timeline_integrity_statuses" => ["review_required"],
        "timeline_integrity_issue_count_values" => [2],
        "timeline_integrity_issue_types" => [
          "missing_dependency_activity",
          "exclusivity_overlap"
        ],
        "timeline_integrity_issue_maps" => [
          [
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
          ]
        ],
        "timeline_integrity_missing_dependency_activity_ids" => ["cmd_power_on"],
        "timeline_integrity_exclusivity_violation_activity_ids" => ["downlink_conflict"],
        "timeline_integrity_exclusivity_violation_timeline_ids" => [
          "timeline:downlink_conflict"
        ],
        "timeline_integrity_exclusivity_violation_groups" => ["equator_prime"],
        "timeline_integrity_required_operator_actions" => ["review_timeline_integrity"],
        "timeline_integrity_feedback_sources" => [
          "mission_state.source_timeline_integrity_report.rows"
        ],
        "timeline_integrity_feedback_scopes" => ["timeline_integrity"],
        "timeline_integrity_feedback_keys" => ["cmd_integrity_review"],
        "timeline_integrity_trust_boundaries" => [
          "mission_state_timeline_integrity_report"
        ],
        "timeline_integrity_derivation_reasons" => ["timeline_integrity_report_pressure"],
        "execution_success_feedback_risk_types" => [
          "command_success_rate_low",
          "maneuver_success_rate_low"
        ],
        "execution_success_feedback_activity_ids" => [
          "cmd_success_review",
          "burn_success_review"
        ],
        "execution_success_feedback_scenario_ids" => ["leo_1"],
        "execution_success_feedback_timeline_ids" => [
          "timeline:cmd_success_review",
          "timeline:burn_success_review"
        ],
        "execution_success_feedback_source_activity_ids" => [
          "cmd_success_source",
          "cmd_success_review",
          "burn_success_source",
          "burn_success_review"
        ],
        "execution_success_feedback_replacement_activity_ids" => [
          "cmd_success_review",
          "burn_success_review"
        ],
        "execution_success_feedback_command_success_factor_values" => [0.25],
        "execution_success_feedback_maneuver_success_factor_values" => [0.4],
        "execution_success_feedback_command_results" => ["timeout"],
        "execution_success_feedback_maneuver_results" => ["accepted, failed"],
        "execution_success_feedback_realized_statuses" => ["failed"],
        "execution_success_feedback_ground_station_ids" => ["equator_prime"],
        "execution_success_feedback_planned_ground_station_ids" => ["polar_prime"],
        "execution_success_feedback_realized_ground_station_ids" => ["equator_prime"],
        "execution_success_feedback_ground_station_match_statuses" => ["mismatch"],
        "execution_success_feedback_directions" => ["command"],
        "execution_success_feedback_planned_directions" => ["uplink"],
        "execution_success_feedback_realized_directions" => ["command"],
        "execution_success_feedback_direction_match_statuses" => ["mismatch"],
        "execution_success_feedback_source_window_ids" => ["window_equator_command"],
        "execution_success_feedback_planned_source_window_ids" => ["window_polar_uplink"],
        "execution_success_feedback_realized_source_window_ids" => ["window_equator_command"],
        "execution_success_feedback_source_window_match_statuses" => ["mismatch"],
        "execution_success_feedback_command_identity_mismatch_fields" => [
          "direction",
          "ground_station",
          "source_window"
        ],
        "execution_success_feedback_start_values_s" => [700.0, 760.0],
        "execution_success_feedback_end_values_s" => [730.0, 760.0],
        "execution_success_feedback_changed_fields" => [
          "command_result",
          "command_success_factor",
          "maneuver_result",
          "maneuver_success_factor"
        ],
        "execution_success_feedback_status_transition_maps" => [
          %{
            "field" => "status",
            "from" => "planned",
            "to" => "failed",
            "transition_type" => "status_changed",
            "transition_category" => "terminal_exception",
            "transition_reason" => "command execution timed out",
            "requires_operator_review" => true
          },
          %{
            "field" => "status",
            "from" => "planned",
            "to" => "failed",
            "transition_type" => "status_changed",
            "transition_category" => "terminal_exception",
            "transition_reason" => "maneuver failed after acceptance",
            "requires_operator_review" => true
          }
        ],
        "execution_success_feedback_transition_types" => ["status_changed"],
        "execution_success_feedback_transition_categories" => ["terminal_exception"],
        "execution_success_feedback_transition_reasons" => [
          "command execution timed out",
          "maneuver failed after acceptance"
        ],
        "execution_success_feedback_required_operator_actions" => [
          "review_command_execution_feedback",
          "review_maneuver_execution_feedback"
        ],
        "execution_success_feedback_requires_operator_review_values" => [true],
        "execution_success_feedback_feedback_sources" => [
          "mission_state.source_command_window_report.rows",
          "mission_state.source_maneuver_review.rows"
        ],
        "execution_success_feedback_feedback_scopes" => [
          "command_execution_feedback",
          "maneuver_execution_feedback"
        ],
        "execution_success_feedback_feedback_keys" => [
          "cmd_success_review",
          "burn_success_review"
        ],
        "execution_success_feedback_trust_boundaries" => [
          "mission_state_command_window_report",
          "mission_state_maneuver_review"
        ],
        "execution_success_feedback_derivation_reasons" => [
          "command_window_execution_feedback_pressure",
          "maneuver_review_success_feedback_pressure"
        ],
        "strategy_operational_feedback_risk_types" => [
          "contact_success_rate_low",
          "observation_success_rate_low",
          "station_throughput_factor_low"
        ],
        "strategy_operational_feedback_activity_ids" => [
          "contact_feedback_review",
          "obs_feedback_review",
          "station_feedback_review"
        ],
        "strategy_operational_feedback_scenario_ids" => ["leo_1"],
        "strategy_operational_feedback_timeline_ids" => [
          "timeline:contact_feedback_review",
          "timeline:obs_feedback_review",
          "timeline:station_feedback_review"
        ],
        "strategy_operational_feedback_source_activity_ids" => [
          "contact_feedback_source",
          "contact_feedback_review",
          "obs_feedback_source",
          "obs_feedback_review",
          "station_feedback_source",
          "station_feedback_review"
        ],
        "strategy_operational_feedback_replacement_activity_ids" => [
          "contact_feedback_review",
          "obs_feedback_review",
          "station_feedback_review"
        ],
        "strategy_operational_feedback_contact_success_factor_values" => [0.35],
        "strategy_operational_feedback_observation_success_factor_values" => [0.45],
        "strategy_operational_feedback_station_throughput_factor_values" => [0.5],
        "strategy_operational_feedback_contact_results" => ["no-contact"],
        "strategy_operational_feedback_observation_results" => ["accepted, degraded"],
        "strategy_operational_feedback_realized_statuses" => ["missed", "degraded"],
        "strategy_operational_feedback_ground_station_ids" => ["equator_prime"],
        "strategy_operational_feedback_planned_ground_station_ids" => ["polar_prime"],
        "strategy_operational_feedback_realized_ground_station_ids" => ["equator_prime"],
        "strategy_operational_feedback_ground_station_match_statuses" => ["mismatch"],
        "strategy_operational_feedback_directions" => ["downlink"],
        "strategy_operational_feedback_planned_directions" => ["uplink"],
        "strategy_operational_feedback_realized_directions" => ["downlink"],
        "strategy_operational_feedback_direction_match_statuses" => ["mismatch"],
        "strategy_operational_feedback_source_window_ids" => ["window_equator_contact"],
        "strategy_operational_feedback_planned_source_window_ids" => ["window_polar_contact"],
        "strategy_operational_feedback_realized_source_window_ids" => ["window_equator_contact"],
        "strategy_operational_feedback_source_window_match_statuses" => ["mismatch"],
        "strategy_operational_feedback_contact_identity_mismatch_fields" => [
          "direction",
          "ground_station",
          "source_window"
        ],
        "strategy_operational_feedback_target_ids" => ["target_hot"],
        "strategy_operational_feedback_planned_target_ids" => ["target_hot"],
        "strategy_operational_feedback_realized_target_ids" => ["target_shadow"],
        "strategy_operational_feedback_target_match_statuses" => ["mismatch"],
        "strategy_operational_feedback_collection_ids" => ["collection_hot"],
        "strategy_operational_feedback_planned_collection_ids" => ["collection_hot"],
        "strategy_operational_feedback_realized_collection_ids" => ["collection_shadow"],
        "strategy_operational_feedback_collection_match_statuses" => ["mismatch"],
        "strategy_operational_feedback_product_ids" => ["product_hot"],
        "strategy_operational_feedback_planned_product_ids" => ["product_hot"],
        "strategy_operational_feedback_realized_product_ids" => ["product_shadow"],
        "strategy_operational_feedback_product_match_statuses" => ["mismatch"],
        "strategy_operational_feedback_payload_ids" => ["payload_nadir"],
        "strategy_operational_feedback_planned_payload_ids" => ["payload_nadir"],
        "strategy_operational_feedback_realized_payload_ids" => ["payload_wide"],
        "strategy_operational_feedback_payload_match_statuses" => ["mismatch"],
        "strategy_operational_feedback_instrument_ids" => ["camera_nadir"],
        "strategy_operational_feedback_planned_instrument_ids" => ["camera_nadir"],
        "strategy_operational_feedback_realized_instrument_ids" => ["camera_wide"],
        "strategy_operational_feedback_instrument_match_statuses" => ["mismatch"],
        "strategy_operational_feedback_observation_identity_mismatch_fields" => [
          "collection",
          "instrument",
          "target"
        ],
        "strategy_operational_feedback_pointing_statuses" => ["degraded"],
        "strategy_operational_feedback_pointing_error_values_deg" => [1.2],
        "strategy_operational_feedback_attitude_statuses" => ["degraded"],
        "strategy_operational_feedback_attitude_error_values_deg" => [0.8],
        "strategy_operational_feedback_lighting_condition_match_statuses" => ["mismatch"],
        "strategy_operational_feedback_planned_lighting_conditions" => ["sunlit"],
        "strategy_operational_feedback_realized_lighting_conditions" => ["penumbra"],
        "strategy_operational_feedback_lighting_condition_details" => ["low sun angle"],
        "strategy_operational_feedback_lighting_confidence_values" => [0.7],
        "strategy_operational_feedback_eclipse_overlap_fraction_values" => [0.2],
        "strategy_operational_feedback_image_quality_score_values" => [0.45],
        "strategy_operational_feedback_image_quality_statuses" => ["marginal"],
        "strategy_operational_feedback_image_quality_sources" => ["provider_imagery_quality"],
        "strategy_operational_feedback_cloud_cover_fraction_values" => [0.55],
        "strategy_operational_feedback_blur_score_values" => [0.25],
        "strategy_operational_feedback_actual_throughput_values_mb" => [50.0],
        "strategy_operational_feedback_estimated_throughput_values_mb" => [100.0],
        "strategy_operational_feedback_start_values_s" => [790.0, 870.0, 950.0],
        "strategy_operational_feedback_end_values_s" => [850.0, 930.0, 1_010.0],
        "strategy_operational_feedback_changed_fields" => [
          "contact_result",
          "contact_success_factor",
          "observation_result",
          "observation_success_factor",
          "actual_throughput_mb",
          "station_throughput_factor"
        ],
        "strategy_operational_feedback_status_transition_maps" => [
          %{
            "field" => "status",
            "from" => "planned",
            "to" => "missed",
            "transition_type" => "status_changed",
            "transition_category" => "terminal_exception",
            "transition_reason" => "contact was missed by provider report",
            "requires_operator_review" => true
          },
          %{
            "field" => "status",
            "from" => "planned",
            "to" => "degraded",
            "transition_type" => "status_changed",
            "transition_category" => "quality_exception",
            "transition_reason" => "observation quality degraded",
            "requires_operator_review" => true
          },
          %{
            "field" => "throughput_status",
            "from" => "planned",
            "to" => "degraded",
            "transition_type" => "throughput_changed",
            "transition_category" => "capacity_exception",
            "transition_reason" => "station throughput below plan",
            "requires_operator_review" => true
          }
        ],
        "strategy_operational_feedback_transition_types" => [
          "status_changed",
          "throughput_changed"
        ],
        "strategy_operational_feedback_transition_categories" => [
          "terminal_exception",
          "quality_exception",
          "capacity_exception"
        ],
        "strategy_operational_feedback_transition_reasons" => [
          "contact was missed by provider report",
          "observation quality degraded",
          "station throughput below plan"
        ],
        "strategy_operational_feedback_required_operator_actions" => [
          "review_contact_execution_feedback",
          "review_observation_execution_feedback",
          "review_station_throughput_feedback"
        ],
        "strategy_operational_feedback_requires_operator_review_values" => [true],
        "strategy_operational_feedback_feedback_sources" => [
          "mission_state.source_contact_review.rows",
          "mission_state.source_observation_review.rows",
          "mission_state.source_station_throughput_review.rows"
        ],
        "strategy_operational_feedback_feedback_scopes" => [
          "contact_execution_feedback",
          "observation_execution_feedback",
          "station_throughput_feedback"
        ],
        "strategy_operational_feedback_feedback_keys" => [
          "contact_feedback_review",
          "obs_feedback_review",
          "station_feedback_review"
        ],
        "strategy_operational_feedback_trust_boundaries" => [
          "mission_state_contact_review",
          "mission_state_observation_review",
          "mission_state_station_throughput_review"
        ],
        "strategy_operational_feedback_derivation_reasons" => [
          "contact_execution_feedback_pressure",
          "observation_execution_feedback_pressure",
          "station_throughput_feedback_pressure"
        ],
        "link_capacity_pressure_risk_types" => ["downlink_completion_gap"],
        "link_capacity_pressure_ground_station_ids" => ["equator_prime"],
        "link_capacity_pressure_required_contact_values" => [1],
        "link_capacity_pressure_planned_contact_values" => [0],
        "link_capacity_pressure_required_downlink_values_mb" => [45.0],
        "link_capacity_pressure_planned_downlink_values_mb" => [10.0],
        "link_capacity_pressure_start_values_s" => [1_020.0],
        "link_capacity_pressure_end_values_s" => [1_080.0],
        "link_capacity_pressure_source_activity_ids" => ["dl_link_capacity_source"],
        "link_capacity_pressure_source_window_ids" => [
          "window_link_capacity",
          "window_link_capacity_backup"
        ],
        "link_capacity_pressure_selected_capacity_adjusted_throughput_values_mb" => [10.0],
        "link_capacity_pressure_selected_downlink_shortfall_values_mb" => [35.0],
        "link_capacity_pressure_actual_throughput_values_mb" => [8.0],
        "link_capacity_pressure_actual_downlink_completion_ratio_values" => [0.22],
        "link_capacity_pressure_actual_downlink_shortfall_values_mb" => [37.0],
        "link_capacity_pressure_downlink_requirement_statuses" => ["shortfall"],
        "link_capacity_pressure_actual_downlink_requirement_statuses" => ["shortfall"],
        "link_capacity_pressure_downlink_demand_sources" => [
          "mission_objective:relay_collection"
        ],
        "link_capacity_pressure_downlink_completion_sources" => [
          "link_capacity_report:selected_contacts"
        ],
        "link_capacity_pressure_feedback_sources" => [
          "mission_state.source_link_capacity_report.rows"
        ],
        "link_capacity_pressure_feedback_scopes" => ["link_capacity"],
        "link_capacity_pressure_trust_boundaries" => ["mission_state_link_capacity_report"],
        "link_capacity_pressure_derivation_reasons" => [
          "link_capacity_selected_downlink_shortfall"
        ],
        "contact_intent_pressure_risk_types" => ["downlink_completion_gap"],
        "contact_intent_pressure_contact_ids" => ["contact_intent:selected_blocked"],
        "contact_intent_pressure_source_activity_ids" => ["dl_contact_intent_selected"],
        "contact_intent_pressure_ground_station_ids" => ["deep_space_net"],
        "contact_intent_pressure_required_contact_values" => [1],
        "contact_intent_pressure_planned_contact_values" => [0],
        "contact_intent_pressure_required_downlink_values_mb" => [42.0],
        "contact_intent_pressure_planned_downlink_values_mb" => [0.0],
        "contact_intent_pressure_start_values_s" => [1_100.0],
        "contact_intent_pressure_end_values_s" => [1_160.0],
        "contact_intent_pressure_source_window_ids" => ["window_contact_intent_selected"],
        "contact_intent_pressure_timeline_ids" => [
          "timeline:contact_intent:selected_blocked"
        ],
        "contact_intent_pressure_approval_statuses" => ["blocked_by_policy"],
        "contact_intent_pressure_required_operator_actions" => ["review_contact_intent"],
        "contact_intent_pressure_cadence_import_statuses" => ["missing"],
        "contact_intent_pressure_invalid_cadence_import_values" => [true],
        "contact_intent_pressure_invalid_cadence_import_reasons" => [
          "missing_cadence_import_row"
        ],
        "contact_intent_pressure_invalid_activity_input_values" => [false],
        "contact_intent_pressure_gate_statuses" => ["blocked_by_policy"],
        "contact_intent_pressure_policy_classifications" => ["blocked_by_policy"],
        "contact_intent_pressure_policy_bundle_ids" => ["contact_command_review_v1"],
        "contact_intent_pressure_station_availabilities" => ["reserved"],
        "contact_intent_pressure_station_contention_statuses" => [
          "operator_review_required"
        ],
        "contact_intent_pressure_station_calendar_entry_ids" => [
          "intent_selected_calendar_entry"
        ],
        "contact_intent_pressure_station_calendar_provider_ids" => ["partner_calendar"],
        "contact_intent_pressure_station_calendar_provider_entry_ids" => [
          "partner_entry_selected"
        ],
        "contact_intent_pressure_station_calendar_directions" => ["downlink"],
        "contact_intent_pressure_station_calendar_statuses" => ["reserved"],
        "contact_intent_pressure_station_calendar_trust_boundary_statuses" => ["declared"],
        "contact_intent_pressure_station_reservation_ids" => ["reservation_intent_selected"],
        "contact_intent_pressure_station_reserved_by" => ["partner_team"],
        "contact_intent_pressure_station_reservation_statuses" => ["confirmed"],
        "contact_intent_pressure_station_reservation_match_statuses" => [
          "unmatched_overlap"
        ],
        "contact_intent_pressure_feedback_sources" => [
          "mission_state.source_contact_intent.rows"
        ],
        "contact_intent_pressure_feedback_scopes" => ["contact_intent"],
        "contact_intent_pressure_trust_boundaries" => [
          "mission_state_contact_intent_review"
        ],
        "contact_intent_pressure_derivation_reasons" => [
          "contact_intent_blocked_by_policy",
          "review_contact_intent",
          "reserved",
          "unmatched_overlap"
        ],
        "station_calendar_pressure_risk_types" => ["ground_station_reserved"],
        "station_calendar_pressure_ground_station_ids" => ["canberra"],
        "station_calendar_pressure_start_values_s" => [1_170.0],
        "station_calendar_pressure_end_values_s" => [1_230.0],
        "station_calendar_pressure_capacity_fraction_values" => [0.4],
        "station_calendar_pressure_station_availabilities" => ["reserved"],
        "station_calendar_pressure_station_contention_statuses" => ["reserved_overlap"],
        "station_calendar_pressure_station_calendar_entry_ids" => [
          "calendar_selected_reserved"
        ],
        "station_calendar_pressure_station_calendar_provider_ids" => ["partner_calendar"],
        "station_calendar_pressure_station_calendar_provider_entry_ids" => [
          "partner_entry_calendar_selected"
        ],
        "station_calendar_pressure_station_calendar_directions" => ["downlink"],
        "station_calendar_pressure_station_calendar_statuses" => ["reserved"],
        "station_calendar_pressure_station_calendar_overlap_count_values" => [2],
        "station_calendar_pressure_station_calendar_overlap_entry_ids" => [
          "calendar_selected_reserved",
          "calendar_selected_maintenance"
        ],
        "station_calendar_pressure_station_calendar_overlap_availabilities" => [
          "reserved",
          "maintenance"
        ],
        "station_calendar_pressure_station_calendar_entry_ambiguous_values" => [true],
        "station_calendar_pressure_station_calendar_ambiguous_entry_count_values" => [2],
        "station_calendar_pressure_station_calendar_ambiguous_entry_ids" => [
          "calendar_selected_reserved",
          "calendar_selected_backup"
        ],
        "station_calendar_pressure_station_calendar_reservation_overlap_count_values" => [1],
        "station_calendar_pressure_station_calendar_reservation_ids" => [
          "reservation_calendar_selected"
        ],
        "station_calendar_pressure_station_calendar_reserved_by" => ["partner_team"],
        "station_calendar_pressure_station_calendar_reservation_statuses" => [
          "confirmed"
        ],
        "station_calendar_pressure_station_calendar_trust_boundary_statuses" => [
          "declared"
        ],
        "station_calendar_pressure_station_reservation_ids" => [
          "reservation_calendar_selected"
        ],
        "station_calendar_pressure_station_reserved_by" => ["partner_team"],
        "station_calendar_pressure_station_reservation_statuses" => ["confirmed"],
        "station_calendar_pressure_station_reservation_match_statuses" => ["overlap"],
        "station_calendar_pressure_station_reservation_expires_at_values_s" => [1_260.0],
        "station_calendar_pressure_station_reservation_expiration_statuses" => ["active"],
        "station_calendar_pressure_provider_calendar_contention_group_ids" => [
          "provider_contention_selected"
        ],
        "station_calendar_pressure_provider_calendar_contention_statuses" => [
          "review_required"
        ],
        "station_calendar_pressure_provider_calendar_contention_entry_ids" => [
          "calendar_selected_reserved",
          "calendar_selected_maintenance"
        ],
        "station_calendar_pressure_provider_calendar_contention_provider_ids" => [
          "partner_calendar"
        ],
        "station_calendar_pressure_provider_calendar_contention_provider_entry_ids" => [
          "partner_entry_calendar_selected",
          "partner_entry_calendar_maintenance"
        ],
        "station_calendar_pressure_provider_calendar_contention_availabilities" => [
          "reserved",
          "maintenance"
        ],
        "station_calendar_pressure_provider_calendar_contention_directions" => ["downlink"],
        "station_calendar_pressure_provider_calendar_contention_reservation_ids" => [
          "reservation_calendar_selected"
        ],
        "station_calendar_pressure_provider_calendar_contention_reserved_by" => [
          "partner_team"
        ],
        "station_calendar_pressure_provider_calendar_contention_reservation_statuses" => [
          "confirmed"
        ],
        "station_calendar_pressure_provider_calendar_contention_trust_boundary_statuses" => [
          "declared"
        ],
        "station_calendar_pressure_provider_calendar_contention_overlap_pairs" => [
          %{
            "left_entry_id" => "calendar_selected_reserved",
            "right_entry_id" => "calendar_selected_maintenance",
            "overlap_starts_at_s" => 1_170.0,
            "overlap_ends_at_s" => 1_230.0,
            "overlap_duration_s" => 60.0
          }
        ],
        "station_calendar_pressure_required_operator_actions" => [
          "review_station_calendar"
        ],
        "station_calendar_pressure_feedback_sources" => [
          "mission_state.source_station_calendar_report.affected_contacts"
        ],
        "station_calendar_pressure_feedback_scopes" => ["station_calendar"],
        "station_calendar_pressure_trust_boundaries" => [
          "mission_state_station_calendar_report"
        ],
        "station_calendar_pressure_derivation_reasons" => [
          "station_calendar_reserved",
          "reserved_overlap",
          "overlap"
        ],
        "score_term_pressure_risk_types" => ["downlink_completion_gap"],
        "score_term_pressure_objective_ids" => ["score_term:downlink_shortfall"],
        "score_term_pressure_objective_types" => ["score_term_gap"],
        "score_term_pressure_latency_objective_values" => [true],
        "score_term_pressure_target_ids" => ["target_score_term"],
        "score_term_pressure_scenario_ids" => ["leo_1"],
        "score_term_pressure_branch_ids" => ["urgent"],
        "score_term_pressure_ground_station_ids" => ["polar_prime"],
        "score_term_pressure_collection_ids" => [
          "collection_score_alpha",
          "collection_score_beta"
        ],
        "score_term_pressure_product_ids" => [
          "product_score_alpha",
          "product_score_beta"
        ],
        "score_term_pressure_payload_ids" => [
          "payload_score_alpha",
          "payload_score_beta"
        ],
        "score_term_pressure_instrument_ids" => [
          "instrument_score_alpha",
          "instrument_score_beta"
        ],
        "score_term_pressure_start_values_s" => [1_240.0],
        "score_term_pressure_end_values_s" => [1_360.0],
        "score_term_pressure_required_contact_values" => [2],
        "score_term_pressure_planned_contact_values" => [1],
        "score_term_pressure_required_downlink_values_mb" => [80.0],
        "score_term_pressure_planned_downlink_values_mb" => [35.0],
        "score_term_pressure_max_latency_values_s" => [300.0],
        "score_term_pressure_planned_latency_values_s" => [420.0],
        "score_term_pressure_source_activity_ids" => [
          "obs_score_source",
          "dl_score_source"
        ],
        "score_term_pressure_keys" => ["collection_latency_gap_s"],
        "score_term_pressure_values" => [120.0],
        "score_term_pressure_timeline_score_values" => [9.5],
        "score_term_pressure_score_term_maps" => [
          %{
            "collection_latency_gap_s" => 120.0,
            "downlink_shortfall_mb" => 45.0
          }
        ],
        "score_term_pressure_downlink_demand_sources" => [
          "score_term:score_term:downlink_shortfall:collection_latency_gap_s"
        ],
        "score_term_pressure_downlink_completion_sources" => [
          "score_term:score_term:downlink_shortfall:collection_latency_gap_s"
        ],
        "score_term_pressure_feedback_sources" => [
          "mission_state.source_score_term_report.rows"
        ],
        "score_term_pressure_feedback_scopes" => ["score_term"],
        "score_term_pressure_trust_boundaries" => ["mission_state_score_term_report"],
        "score_term_pressure_derivation_reasons" => [
          "collection_latency_gap",
          "score_term_collection_latency_gap",
          "score_term_collection_latency_gap_s"
        ],
        "objective_satisfaction_pressure_risk_types" => [
          "downlink_completion_gap",
          "observation_success_feedback"
        ],
        "objective_satisfaction_pressure_objective_ids" => ["objective:target_quality"],
        "objective_satisfaction_pressure_objective_types" => ["observation_quality"],
        "objective_satisfaction_pressure_objective_statuses" => ["at_risk"],
        "objective_satisfaction_pressure_source_objective_statuses" => [
          "missed_quality_threshold"
        ],
        "objective_satisfaction_pressure_latency_objective_values" => [true],
        "objective_satisfaction_pressure_target_ids" => ["target_objective_quality"],
        "objective_satisfaction_pressure_scenario_ids" => ["leo_1"],
        "objective_satisfaction_pressure_spacecraft_ids" => ["leo_1"],
        "objective_satisfaction_pressure_branch_ids" => ["urgent"],
        "objective_satisfaction_pressure_ground_station_ids" => ["madrid_objective"],
        "objective_satisfaction_pressure_collection_ids" => [
          "collection_objective_quality",
          "collection_objective_quality_backup"
        ],
        "objective_satisfaction_pressure_product_ids" => [
          "product_objective_quality",
          "product_objective_quality_backup"
        ],
        "objective_satisfaction_pressure_payload_ids" => [
          "payload_objective_quality",
          "payload_objective_quality_backup"
        ],
        "objective_satisfaction_pressure_instrument_ids" => [
          "instrument_objective_quality",
          "instrument_objective_quality_backup"
        ],
        "objective_satisfaction_pressure_start_values_s" => [1_380.0],
        "objective_satisfaction_pressure_end_values_s" => [1_440.0],
        "objective_satisfaction_pressure_required_contact_values" => [3],
        "objective_satisfaction_pressure_planned_contact_values" => [1],
        "objective_satisfaction_pressure_required_downlink_values_mb" => [120.0],
        "objective_satisfaction_pressure_planned_downlink_values_mb" => [70.0],
        "objective_satisfaction_pressure_max_latency_values_s" => [300.0],
        "objective_satisfaction_pressure_planned_latency_values_s" => [480.0],
        "objective_satisfaction_pressure_required_observation_values" => [2],
        "objective_satisfaction_pressure_planned_observation_values" => [1],
        "objective_satisfaction_pressure_priorities" => [32.0],
        "objective_satisfaction_pressure_latitude_values_deg" => [34.1],
        "objective_satisfaction_pressure_longitude_values_deg" => [-118.2],
        "objective_satisfaction_pressure_minimum_elevation_values_deg" => [15.0],
        "objective_satisfaction_pressure_source_activity_ids" => [
          "obs_objective_quality_source",
          "obs_objective_quality_selected"
        ],
        "objective_satisfaction_pressure_missed_downlink_activity_ids" => [
          "dl_objective_missed",
          "dl_objective_selected"
        ],
        "objective_satisfaction_pressure_realized_statuses" => ["missed"],
        "objective_satisfaction_pressure_contact_results" => ["missed"],
        "objective_satisfaction_pressure_observation_success_factor_values" => [0.35],
        "objective_satisfaction_pressure_image_quality_score_values" => [0.42],
        "objective_satisfaction_pressure_image_quality_statuses" => ["marginal"],
        "objective_satisfaction_pressure_image_quality_sources" => [
          "provider_imagery_quality"
        ],
        "objective_satisfaction_pressure_cloud_cover_fraction_values" => [0.62],
        "objective_satisfaction_pressure_blur_score_values" => [0.31],
        "objective_satisfaction_pressure_quality_feedback_sources" => [
          "mission_state.source_imagery_quality.rows"
        ],
        "objective_satisfaction_pressure_candidate_window_maps" => [
          %{
            "id" => "window_objective_quality_primary",
            "scenario_id" => "leo_1",
            "starts_at_s" => 1_380.0,
            "ends_at_s" => 1_440.0
          }
        ],
        "objective_satisfaction_pressure_allowed_scenario_ids" => ["leo_1", "leo_2"],
        "objective_satisfaction_pressure_spacecraft_constraint_maps" => ["leo_1", "leo_2"],
        "objective_satisfaction_pressure_coverage_objective_ids" => [
          "coverage:target_quality"
        ],
        "objective_satisfaction_pressure_downlink_demand_sources" => [
          "objective_satisfaction.required_downlink"
        ],
        "objective_satisfaction_pressure_downlink_completion_sources" => [
          "objective_satisfaction.realized_downlink"
        ],
        "objective_satisfaction_pressure_feedback_sources" => [
          "mission_state.source_objective_satisfaction_report.rows"
        ],
        "objective_satisfaction_pressure_feedback_scopes" => ["objective_satisfaction"],
        "objective_satisfaction_pressure_trust_boundaries" => [
          "mission_state_objective_satisfaction_report"
        ],
        "objective_satisfaction_pressure_derivation_reasons" => [
          "objective_satisfaction_observation_quality_gap",
          "objective_satisfaction_image_quality_marginal"
        ],
        "objective_tradeoff_pressure_risk_types" => ["downlink_completion_gap"],
        "objective_tradeoff_pressure_objective_ids" => ["objective_tradeoff:latency_gap"],
        "objective_tradeoff_pressure_objective_types" => ["collection_latency"],
        "objective_tradeoff_pressure_latency_objective_values" => [true],
        "objective_tradeoff_pressure_target_ids" => ["target_tradeoff"],
        "objective_tradeoff_pressure_scenario_ids" => ["leo_1"],
        "objective_tradeoff_pressure_branch_ids" => ["urgent"],
        "objective_tradeoff_pressure_ground_station_ids" => ["madrid"],
        "objective_tradeoff_pressure_collection_ids" => [
          "collection_tradeoff_alpha",
          "collection_tradeoff_beta"
        ],
        "objective_tradeoff_pressure_product_ids" => [
          "product_tradeoff_alpha",
          "product_tradeoff_beta"
        ],
        "objective_tradeoff_pressure_payload_ids" => [
          "payload_tradeoff_alpha",
          "payload_tradeoff_beta"
        ],
        "objective_tradeoff_pressure_instrument_ids" => [
          "instrument_tradeoff_alpha",
          "instrument_tradeoff_beta"
        ],
        "objective_tradeoff_pressure_start_values_s" => [1_460.0],
        "objective_tradeoff_pressure_end_values_s" => [1_580.0],
        "objective_tradeoff_pressure_required_contact_values" => [2],
        "objective_tradeoff_pressure_planned_contact_values" => [1],
        "objective_tradeoff_pressure_required_downlink_values_mb" => [90.0],
        "objective_tradeoff_pressure_planned_downlink_values_mb" => [45.0],
        "objective_tradeoff_pressure_max_latency_values_s" => [240.0],
        "objective_tradeoff_pressure_planned_latency_values_s" => [390.0],
        "objective_tradeoff_pressure_source_activity_ids" => [
          "obs_tradeoff_source",
          "dl_tradeoff_selected"
        ],
        "objective_tradeoff_pressure_score_values" => [7.25],
        "objective_tradeoff_pressure_score_delta_from_selected_values" => [-2.75],
        "objective_tradeoff_pressure_score_term_maps" => [
          %{
            "collection_latency_gap_s" => 150.0,
            "downlink_shortfall_mb" => 45.0
          }
        ],
        "objective_tradeoff_pressure_feedback_sources" => [
          "mission_state.source_objective_tradeoff_report.tradeoffs"
        ],
        "objective_tradeoff_pressure_feedback_scopes" => ["objective_tradeoff"],
        "objective_tradeoff_pressure_trust_boundaries" => [
          "mission_state_objective_tradeoff_report"
        ],
        "objective_tradeoff_pressure_derivation_reasons" => [
          "objective_tradeoff_downlink_gap",
          "collection_latency_gap",
          "objective_tradeoff_latency_gap",
          "objective_tradeoff_unselected"
        ],
        "relay_data_path_risk_types" => ["relay_data_path_pressure"],
        "relay_data_path_ground_station_ids" => ["dss_14"],
        "relay_data_path_route_ids" => ["relay_route_review", "relay_route_backup"],
        "relay_data_path_source_spacecraft_ids" => ["leo_1"],
        "relay_data_path_relay_spacecraft_ids" => ["relay_a"],
        "relay_data_path_relay_chain_spacecraft_ids" => ["relay_a", "relay_b"],
        "relay_data_path_relay_hop_count_values" => [2],
        "relay_data_path_ground_downlink_contact_ids" => [
          "downlink_relay_review",
          "downlink_relay_backup"
        ],
        "relay_data_path_custody_statuses" => ["missing_ack"],
        "relay_data_path_latency_values_s" => [500.0],
        "relay_data_path_latency_limit_values_s" => [300.0],
        "relay_data_path_latency_statuses" => ["exceeds_limit"],
        "relay_data_path_risk_statuses" => ["high"],
        "relay_data_path_risk_reasons" => ["custody_missing_ack", "latency_exceeds_limit"],
        "relay_data_path_product_ids" => ["product_relay"],
        "relay_data_path_collection_ids" => ["collection_relay"],
        "relay_data_path_route_count_values" => [2],
        "relay_data_path_relay_route_count_values" => [2],
        "relay_data_path_direct_downlink_route_count_values" => [0],
        "relay_data_path_custody_status_count_maps" => [%{"missing_ack" => 2}],
        "relay_data_path_latency_status_count_maps" => [%{"exceeds_limit" => 2}],
        "relay_data_path_risk_status_count_maps" => [%{"high" => 2}],
        "relay_data_path_route_ids_by_custody_status" => [
          %{"missing_ack" => ["relay_route_review", "relay_route_backup"]}
        ],
        "relay_data_path_route_ids_by_latency_status" => [
          %{"exceeds_limit" => ["relay_route_review", "relay_route_backup"]}
        ],
        "relay_data_path_route_ids_by_risk_status" => [
          %{"high" => ["relay_route_review", "relay_route_backup"]}
        ],
        "relay_data_path_route_ids_by_ground_station_id" => [
          %{"dss_14" => ["relay_route_review", "relay_route_backup"]}
        ],
        "relay_data_path_feedback_sources" => [
          "mission_state.source_relay_data_path_summary.rows"
        ],
        "relay_data_path_feedback_scopes" => ["link_capacity"],
        "relay_data_path_feedback_keys" => ["relay_route_review"],
        "relay_data_path_trust_boundaries" => ["mission_state_relay_data_path_summary"],
        "relay_data_path_derivation_reasons" => [
          "relay_data_path_custody_missing_ack",
          "relay_data_path_latency_exceeds_limit",
          "relay_data_path_risk_high"
        ],
        "relay_data_path_assumption_maps" => [
          %{
            "execution_boundary" => "artifact_only_no_relay_scheduling_or_schedule_mutation",
            "operator_authority" => "not_granted_by_summary",
            "provider_reservation" => "not_performed"
          }
        ],
        "resource_projection_pressure_risk_types" => ["downlink_completion_gap"],
        "resource_projection_pressure_scenario_ids" => ["leo_projection_selected"],
        "resource_projection_pressure_spacecraft_ids" => ["leo_projection_selected"],
        "resource_projection_pressure_ground_station_ids" => ["polar_prime"],
        "resource_projection_pressure_source_activity_ids" => [
          "obs_projection_pressure"
        ],
        "resource_projection_pressure_required_contact_values" => [1],
        "resource_projection_pressure_planned_contact_values" => [0],
        "resource_projection_pressure_required_downlink_values_mb" => [52.0],
        "resource_projection_pressure_planned_downlink_values_mb" => [12.0],
        "resource_projection_pressure_start_values_s" => [1_590.0],
        "resource_projection_pressure_end_values_s" => [1_650.0],
        "resource_projection_pressure_downlink_demand_sources" => [
          "resource_projection.projected_downlink_shortfall:obs_projection_pressure"
        ],
        "resource_projection_pressure_downlink_completion_sources" => [
          "resource_projection.projected_downlink_shortfall:obs_projection_pressure"
        ],
        "resource_projection_pressure_feedback_sources" => [
          "mission_state.source_resource_projection_report"
        ],
        "resource_projection_pressure_feedback_scopes" => ["resource_projection"],
        "resource_projection_pressure_trust_boundaries" => [
          "mission_state_resource_projection_report"
        ],
        "resource_projection_pressure_derivation_reasons" => [
          "projected_downlink_shortfall"
        ],
        "resource_margin_risk_types" => [
          "downlink_margin_low",
          "fuel_margin_low",
          "power_margin_low",
          "storage_margin_low",
          "thermal_margin_c_low"
        ],
        "resource_margin_spacecraft_ids" => ["leo_1"],
        "resource_margin_scenario_ids" => ["leo_1"],
        "resource_margin_timeline_ids" => ["timeline:resource_margin:power"],
        "resource_margin_source_activity_ids" => [
          "dl_resource_filter_downlink",
          "obs_resource_filter_fuel",
          "obs_power_pressure",
          "obs_resource_filter_power",
          "obs_resource_filter_storage",
          "obs_resource_filter_thermal"
        ],
        "resource_margin_replacement_activity_ids" => ["obs_power_pressure_replanned"],
        "resource_margin_fields" => [
          "downlink_margin",
          "fuel_margin",
          "power_margin",
          "storage_margin",
          "thermal_margin_c"
        ],
        "resource_margin_values" => [8.0, 0.05, 0.08, 12.0, 2.0],
        "resource_margin_threshold_values" => [15.0, 0.1, 0.2, 20.0, 5.0],
        "resource_margin_field_value_maps" => [
          %{
            "field" => "downlink_margin",
            "value" => 8.0,
            "threshold" => 15.0
          },
          %{
            "field" => "fuel_margin",
            "value" => 0.05,
            "threshold" => 0.1
          },
          %{
            "field" => "power_margin",
            "value" => 0.08,
            "threshold" => 0.2
          },
          %{
            "field" => "storage_margin",
            "value" => 12.0,
            "threshold" => 20.0
          },
          %{
            "field" => "thermal_margin_c",
            "value" => 2.0,
            "threshold" => 5.0
          }
        ],
        "resource_margin_source_quality_values" => ["operator_supplied", "declared"],
        "resource_margin_start_values_s" => [
          1_510.0,
          1_300.0,
          500.0,
          1_370.0,
          1_440.0,
          1_580.0
        ],
        "resource_margin_end_values_s" => [
          1_570.0,
          1_360.0,
          560.0,
          1_430.0,
          1_500.0,
          1_640.0
        ],
        "resource_margin_diff_statuses" => ["changed"],
        "resource_margin_changed_fields" => ["power_margin"],
        "resource_margin_required_operator_actions" => ["review_resource_margin"],
        "resource_margin_requires_operator_review_values" => [true],
        "resource_margin_feedback_sources" => [
          "mission_state.source_resource_filter_report.suppressed_candidates",
          "mission_state.source_resource_projection_report.rows"
        ],
        "resource_margin_feedback_scopes" => ["resource_filter", "resource_margin"],
        "resource_margin_feedback_keys" => ["leo_1.power_margin"],
        "resource_margin_trust_boundaries" => [
          "mission_state_resource_filter_report",
          "mission_state_resource_projection_report"
        ],
        "resource_margin_derivation_reasons" => [
          "resource_filter_suppressed",
          "downlink_margin_below_policy",
          "fuel_margin_below_policy",
          "resource_projection_power_margin_low",
          "power_margin_below_observe_policy",
          "storage_margin_below_observe_policy",
          "thermal_margin_below_policy"
        ],
        "maneuver_execution_uncertainty_risk_types" => [
          "maneuver_execution_uncertainty_high"
        ],
        "maneuver_execution_uncertainty_activity_ids" => ["burn_uncertain_review"],
        "maneuver_execution_uncertainty_timeline_ids" => [
          "timeline:maneuver:burn_uncertain_review"
        ],
        "maneuver_execution_uncertainty_maneuver_ids" => ["burn_uncertain_review"],
        "maneuver_execution_uncertainty_scenario_ids" => ["leo_1"],
        "maneuver_execution_uncertainty_source_activity_ids" => [
          "burn_uncertain_source",
          "burn_uncertain_review"
        ],
        "maneuver_execution_uncertainty_replacement_activity_ids" => [
          "burn_uncertain_review"
        ],
        "maneuver_execution_uncertainty_statuses" => ["declared"],
        "maneuver_execution_uncertainty_sources" => ["ops_covariance_review"],
        "maneuver_execution_uncertainty_maps" => [
          %{
            "timing_3sigma_s" => 75.0,
            "delta_v_3sigma_km_s" => [0.0, 0.003, 0.004],
            "source" => "ops_covariance_review"
          }
        ],
        "maneuver_execution_uncertainty_timing_3sigma_values_s" => [75.0],
        "maneuver_execution_uncertainty_timing_3sigma_threshold_values_s" => [60.0],
        "maneuver_execution_uncertainty_delta_v_3sigma_vectors_km_s" => [
          [0.0, 0.003, 0.004]
        ],
        "maneuver_execution_uncertainty_delta_v_3sigma_magnitude_values_km_s" => [0.005],
        "maneuver_execution_uncertainty_delta_v_3sigma_magnitude_threshold_values_km_s" => [
          0.002
        ],
        "maneuver_execution_uncertainty_start_values_s" => [620.0],
        "maneuver_execution_uncertainty_end_values_s" => [620.0],
        "maneuver_execution_uncertainty_changed_fields" => ["execution_uncertainty"],
        "maneuver_execution_uncertainty_required_operator_actions" => [
          "review_maneuver_execution_uncertainty"
        ],
        "maneuver_execution_uncertainty_requires_operator_review_values" => [true],
        "maneuver_execution_uncertainty_feedback_sources" => [
          "mission_state.source_maneuver_review.rows"
        ],
        "maneuver_execution_uncertainty_feedback_scopes" => [
          "maneuver_execution_uncertainty"
        ],
        "maneuver_execution_uncertainty_feedback_keys" => ["burn_uncertain_review"],
        "maneuver_execution_uncertainty_trust_boundaries" => [
          "mission_state_maneuver_review"
        ],
        "maneuver_execution_uncertainty_derivation_reasons" => [
          "maneuver_review_execution_uncertainty_pressure"
        ],
        "timeline_publication_ids" => [
          "timeline_publication:9:timeline:selected_plan:v2:timeline:selected_plan:v1"
        ],
        "timeline_publication_sequences" => [9],
        "timeline_publication_statuses" => ["published_with_downstream_invalidations"],
        "timeline_publication_downstream_invalidation_statuses" => ["invalidated"],
        "timeline_publication_dependency_impact_statuses" => ["review_required"],
        "timeline_publication_source_artifact_ids" => ["timeline:selected_plan:v2"],
        "timeline_publication_source_artifact_types" => ["operational_timeline_report.v1"],
        "timeline_publication_authorities" => ["mission_operations"],
        "timeline_publication_supersedes_artifact_ids" => ["timeline:selected_plan:v1"],
        "timeline_publication_downstream_product_ids" => [
          "operator_review:selected:v1",
          "cadence_import:selected:v1"
        ],
        "timeline_publication_invalidated_downstream_product_ids" => [
          "cadence_import:selected:v1",
          "operator_review:selected:v1"
        ],
        "timeline_publication_downstream_invalidation_reason_count_maps" => [
          %{"dependency_impact_review_required" => 2}
        ],
        "timeline_publication_downstream_invalidation_reasons" => [
          "dependency_impact_review_required"
        ],
        "timeline_publication_invalidated_downstream_product_ids_by_reason" => [
          %{
            "dependency_impact_review_required" => [
              "cadence_import:selected:v1",
              "operator_review:selected:v1"
            ]
          }
        ],
        "timeline_publication_dependency_impact_row_count_values" => [2],
        "timeline_publication_timeline_diff_row_count_values" => [3],
        "timeline_publication_timeline_diff_changed_count_values" => [2],
        "timeline_publication_timeline_diff_review_required_count_values" => [1],
        "timeline_publication_changed_field_count_maps" => [%{"timeline_presence" => 2}],
        "timeline_publication_changed_fields" => ["timeline_presence"],
        "timeline_publication_changed_timeline_ids" => ["timeline:health_check:0.0"],
        "timeline_publication_review_timeline_ids" => [
          "timeline:health_check:0.0",
          "timeline:health_check:5.0"
        ],
        "timeline_publication_timeline_ids_by_changed_field" => [
          %{
            "timeline_presence" => [
              "timeline:health_check:0.0",
              "timeline:health_check:5.0"
            ]
          }
        ],
        "timeline_publication_feedback_sources" => [
          "mission_state.source_timeline_publication_summary"
        ],
        "timeline_publication_feedback_scopes" => ["timeline_publication"],
        "timeline_publication_feedback_keys" => [
          "timeline_publication:9:timeline:selected_plan:v2:timeline:selected_plan:v1"
        ],
        "timeline_publication_trust_boundaries" => [
          "mission_state_timeline_publication_summary"
        ],
        "timeline_publication_derivation_reasons" => [
          "timeline_publication_summary_pressure"
        ],
        "timeline_publication_assumption_maps" => [
          %{
            "publication_execution" => "not_performed_by_strategy_branch",
            "notification_delivery" => "not_performed_by_strategy_branch",
            "operator_authority" => "not_granted_by_strategy_branch",
            "import_approval" => "not_granted_by_strategy_branch"
          }
        ],
        "timeline_lifecycle_state_statuses" => ["review_required"],
        "timeline_lifecycle_state_planned_activity_count_values" => [4],
        "timeline_lifecycle_state_realized_activity_count_values" => [1],
        "timeline_lifecycle_state_row_count_values" => [4],
        "timeline_lifecycle_state_recordable_count_values" => [3],
        "timeline_lifecycle_state_preserved_count_values" => [1],
        "timeline_lifecycle_state_review_required_count_values" => [3],
        "timeline_lifecycle_state_duplicate_identity_count_values" => [1],
        "timeline_lifecycle_state_invalid_activity_input_count_values" => [1],
        "timeline_lifecycle_state_transition_decision_count_maps" => [
          %{"record" => 3, "none" => 1}
        ],
        "timeline_lifecycle_state_required_operator_action_count_maps" => [
          %{
            "review_activity_approval" => 1,
            "review_duplicate_timeline_identity" => 1,
            "review_invalid_activity_input" => 1
          }
        ],
        "timeline_lifecycle_state_operator_action_reason_count_maps" => [
          %{
            "activity_approval_pending" => 1,
            "duplicate_timeline_identity" => 1,
            "missing_activity_type" => 1
          }
        ],
        "timeline_lifecycle_state_import_action_count_maps" => [
          %{"review_timeline_diff" => 3}
        ],
        "timeline_lifecycle_state_planned_status_category_count_maps" => [
          %{"planned" => 4}
        ],
        "timeline_lifecycle_state_realized_status_category_count_maps" => [
          %{"executed" => 1}
        ],
        "timeline_lifecycle_state_status_transition_category_count_maps" => [
          %{"changed" => 1}
        ],
        "timeline_lifecycle_state_approval_transition_category_count_maps" => [
          %{"changed" => 1}
        ],
        "timeline_lifecycle_state_recordable_timeline_ids" => [
          "timeline:lifecycle:cmd_pending",
          "timeline:lifecycle:dup",
          "timeline:invalid_activity_input:lifecycle_bad_missing_type"
        ],
        "timeline_lifecycle_state_preserved_timeline_ids" => [
          "timeline:lifecycle:obs_preserved"
        ],
        "timeline_lifecycle_state_review_timeline_ids" => [
          "timeline:lifecycle:cmd_pending",
          "timeline:lifecycle:dup",
          "timeline:invalid_activity_input:lifecycle_bad_missing_type"
        ],
        "timeline_lifecycle_state_review_activity_ids" => [
          "lifecycle_cmd_pending",
          "lifecycle_dup_a",
          "lifecycle_dup_b",
          "timeline_row:4:lifecycle_bad_missing_type"
        ],
        "timeline_lifecycle_state_invalid_activity_input_ids" => [
          "timeline_row:4:lifecycle_bad_missing_type"
        ],
        "timeline_lifecycle_state_review_timeline_ids_by_required_operator_action" => [
          %{
            "review_activity_approval" => ["timeline:lifecycle:cmd_pending"],
            "review_duplicate_timeline_identity" => ["timeline:lifecycle:dup"],
            "review_invalid_activity_input" => [
              "timeline:invalid_activity_input:lifecycle_bad_missing_type"
            ]
          }
        ],
        "timeline_lifecycle_state_review_timeline_ids_by_operator_action_reason" => [
          %{
            "activity_approval_pending" => ["timeline:lifecycle:cmd_pending"],
            "duplicate_timeline_identity" => ["timeline:lifecycle:dup"],
            "missing_activity_type" => [
              "timeline:invalid_activity_input:lifecycle_bad_missing_type"
            ]
          }
        ],
        "timeline_lifecycle_state_review_timeline_ids_by_status_transition_category" => [
          %{"changed" => ["timeline:lifecycle:cmd_pending"]}
        ],
        "timeline_lifecycle_state_review_timeline_ids_by_approval_transition_category" => [
          %{"changed" => ["timeline:lifecycle:cmd_pending"]}
        ],
        "timeline_lifecycle_state_required_operator_actions" => [
          "review_timeline_lifecycle_state"
        ],
        "timeline_lifecycle_state_requires_operator_review_values" => [true],
        "timeline_lifecycle_state_feedback_sources" => [
          "mission_state.source_timeline_lifecycle_state_summary"
        ],
        "timeline_lifecycle_state_feedback_scopes" => ["timeline_lifecycle_state"],
        "timeline_lifecycle_state_feedback_keys" => ["mission.lifecycle.summary"],
        "timeline_lifecycle_state_trust_boundaries" => [
          "mission_state_timeline_lifecycle_state_summary"
        ],
        "timeline_lifecycle_state_derivation_reasons" => [
          "timeline_lifecycle_state_summary_pressure"
        ],
        "timeline_lifecycle_state_assumption_maps" => [
          %{
            "timeline_lifecycle_application" => "not_performed_by_strategy_branch",
            "timeline_mutation" => "not_performed_by_strategy_branch",
            "operator_authority" => "not_granted_by_strategy_branch",
            "cadence_import" => "not_performed_by_strategy_branch",
            "command_execution" => "not_performed_by_strategy_branch"
          }
        ],
        "timeline_activity_lifecycle_state_activity_ids" => [
          "activity_lifecycle_cmd_pending"
        ],
        "timeline_activity_lifecycle_state_timeline_ids" => [
          "timeline:activity_lifecycle:cmd_pending"
        ],
        "timeline_activity_lifecycle_state_planned_activity_ids" => [
          "activity_lifecycle_cmd_pending"
        ],
        "timeline_activity_lifecycle_state_realized_activity_ids" => [
          "activity_lifecycle_cmd_pending"
        ],
        "timeline_activity_lifecycle_state_planned_timeline_ids" => [
          "timeline:activity_lifecycle:cmd_pending"
        ],
        "timeline_activity_lifecycle_state_realized_timeline_ids" => [
          "timeline:activity_lifecycle:cmd_pending"
        ],
        "timeline_activity_lifecycle_state_transition_decisions" => ["review"],
        "timeline_activity_lifecycle_state_status_transition_decisions" => ["record"],
        "timeline_activity_lifecycle_state_approval_transition_decisions" => ["review"],
        "timeline_activity_lifecycle_state_review_required_values" => [true],
        "timeline_activity_lifecycle_state_requires_operator_review_values" => [true],
        "timeline_activity_lifecycle_state_required_operator_actions" => [
          "review_activity_approval",
          "record_timeline_change"
        ],
        "timeline_activity_lifecycle_state_operator_action_reasons" => [
          "activity_execution_recorded",
          "approval_grant_requires_operator_authority"
        ],
        "timeline_activity_lifecycle_state_import_actions" => ["review_timeline_diff"],
        "timeline_activity_lifecycle_state_invalid_activity_input_values" => [false],
        "timeline_activity_lifecycle_state_invalid_activity_input_count_values" => [0],
        "timeline_activity_lifecycle_state_planned_statuses" => ["planned"],
        "timeline_activity_lifecycle_state_realized_statuses" => ["executed"],
        "timeline_activity_lifecycle_state_planned_status_categories" => ["planned"],
        "timeline_activity_lifecycle_state_realized_status_categories" => ["executed"],
        "timeline_activity_lifecycle_state_planned_approval_statuses" => ["pending"],
        "timeline_activity_lifecycle_state_realized_approval_statuses" => ["approved"],
        "timeline_activity_lifecycle_state_planned_approval_categories" => ["pending"],
        "timeline_activity_lifecycle_state_realized_approval_categories" => [
          "approval_granted"
        ],
        "timeline_activity_lifecycle_state_planned_locked_values" => [false],
        "timeline_activity_lifecycle_state_realized_locked_values" => [false],
        "timeline_activity_lifecycle_state_planned_executed_values" => [false],
        "timeline_activity_lifecycle_state_realized_executed_values" => [true],
        "timeline_activity_lifecycle_state_status_transitions" => [
          %{
            "field" => "status",
            "from" => "planned",
            "to" => "executed",
            "transition_type" => "status_changed",
            "transition_category" => "planned_to_executed",
            "transition_reason" => "activity execution recorded",
            "requires_operator_review" => false
          }
        ],
        "timeline_activity_lifecycle_state_approval_transitions" => [
          %{
            "field" => "approval_status",
            "from" => "pending",
            "to" => "approved",
            "transition_type" => "approval_state_changed",
            "transition_category" => "pending_to_approved",
            "transition_reason" => "approval grant requires operator authority",
            "requires_operator_review" => true
          }
        ],
        "timeline_activity_lifecycle_state_planned_protection_decisions" => ["record"],
        "timeline_activity_lifecycle_state_realized_protection_decisions" => ["review"],
        "timeline_activity_lifecycle_state_feedback_sources" => [
          "mission_state.source_timeline_activity_lifecycle_state"
        ],
        "timeline_activity_lifecycle_state_feedback_scopes" => [
          "timeline_activity_lifecycle_state"
        ],
        "timeline_activity_lifecycle_state_feedback_keys" => [
          "activity_lifecycle_cmd_pending"
        ],
        "timeline_activity_lifecycle_state_trust_boundaries" => [
          "mission_state_timeline_activity_lifecycle_state"
        ],
        "timeline_activity_lifecycle_state_derivation_reasons" => [
          "timeline_activity_lifecycle_state_pressure"
        ],
        "timeline_activity_lifecycle_state_assumption_maps" => [
          %{
            "timeline_lifecycle_application" => "not_performed_by_strategy_branch",
            "timeline_mutation" => "not_performed_by_strategy_branch",
            "operator_authority" => "not_granted_by_strategy_branch",
            "cadence_import" => "not_performed_by_strategy_branch",
            "command_execution" => "not_performed_by_strategy_branch"
          }
        ],
        "timeline_preservation_activity_ids" => ["contact_locked_review"],
        "timeline_preservation_timeline_ids" => ["timeline:contact_locked_review"],
        "timeline_preservation_statuses" => ["review_required"],
        "timeline_preservation_requires_preservation_values" => [false],
        "timeline_preservation_requires_operator_review_values" => [true],
        "timeline_preservation_protection_decisions" => ["preserve"],
        "timeline_preservation_protection_categories" => ["locked_or_approved"],
        "timeline_preservation_protection_reasons" => ["activity_locked_or_approved"],
        "timeline_preservation_preserve_activity_count_values" => [2],
        "timeline_preservation_review_change_activity_count_values" => [1],
        "timeline_preservation_sensitive_activity_count_values" => [2],
        "timeline_preservation_preserve_activity_ids" => [
          "contact_locked_review",
          "obs_done_review"
        ],
        "timeline_preservation_preserve_timeline_ids" => [
          "timeline:contact_locked_review",
          "timeline:obs_done_review"
        ],
        "timeline_preservation_review_change_activity_ids" => ["bad_missing_type_review"],
        "timeline_preservation_review_change_timeline_ids" => [
          "timeline:bad_missing_type_review"
        ],
        "timeline_preservation_sensitive_activity_ids" => [
          "contact_locked_review",
          "obs_done_review"
        ],
        "timeline_preservation_sensitive_timeline_ids" => [
          "timeline:contact_locked_review",
          "timeline:obs_done_review"
        ],
        "timeline_preservation_invalid_activity_input_values" => [false],
        "timeline_preservation_required_operator_actions" => ["review_timeline_preservation"],
        "timeline_preservation_feedback_sources" => [
          "mission_state.source_timeline_preservation_report.rows[0]"
        ],
        "timeline_preservation_feedback_scopes" => ["timeline_preservation"],
        "timeline_preservation_feedback_keys" => ["contact_locked_review"],
        "timeline_preservation_trust_boundaries" => [
          "mission_state_timeline_preservation_report"
        ],
        "timeline_preservation_derivation_reasons" => ["timeline_preservation_pressure"],
        "timeline_preservation_assumption_maps" => [
          %{
            "timeline_preservation_application" => "not_performed_by_strategy_branch",
            "timeline_mutation" => "not_performed_by_strategy_branch",
            "operator_authority" => "not_granted_by_strategy_branch",
            "cadence_import" => "not_performed_by_strategy_branch"
          }
        ],
        "provider_reservation_request_contact_ids" => ["dl_provider_review"],
        "provider_reservation_request_source_activity_ids" => ["dl_provider_review"],
        "provider_reservation_request_ground_station_ids" => ["equator_prime"],
        "provider_reservation_request_directions" => ["downlink"],
        "provider_reservation_request_station_reservation_ids" => [
          "provider_reservation_review"
        ],
        "provider_reservation_request_station_reserved_by" => ["partner_calendar"],
        "provider_reservation_request_station_reservation_statuses" => ["confirmed"],
        "provider_reservation_request_station_reservation_expiration_statuses" => ["active"],
        "provider_reservation_request_station_reservation_match_statuses" => ["overlap"],
        "provider_reservation_request_statuses" => ["review_required"],
        "provider_reservation_request_row_scopes" => ["review"],
        "provider_reservation_request_required_operator_actions" => [
          "review_provider_reservation_request"
        ],
        "provider_reservation_request_assumption_maps" => [
          %{
            "provider_reservation_execution" => "not_performed_by_strategy_branch",
            "schedule_mutation" => "not_performed_by_strategy_branch",
            "operator_authority" => "not_granted_by_strategy_branch"
          }
        ],
        "provider_reservation_request_feedback_sources" => [
          "mission_state.source_contact_allocation_provider_reservation_request_summary"
        ],
        "provider_reservation_request_feedback_scopes" => [
          "contact_allocation_provider_reservation_request"
        ],
        "provider_reservation_request_trust_boundaries" => [
          "mission_state_provider_reservation_request_summary"
        ],
        "capacity_pack_risk_contact_ids" => ["dl_capacity_overflow"],
        "capacity_pack_risk_source_activity_ids" => ["dl_capacity_overflow"],
        "capacity_pack_risk_ground_station_ids" => ["equator_prime"],
        "capacity_pack_risk_group_ids" => ["capacity_pack_equator_prime"],
        "capacity_pack_risk_statuses" => ["deferred_by_reduced_station_capacity_pack"],
        "capacity_pack_risk_capacity_fraction_values" => [0.5],
        "capacity_pack_risk_used_fraction_values" => [0.5],
        "capacity_pack_risk_unused_fraction_values" => [0.0],
        "capacity_pack_risk_required_capacity_fraction_values" => [0.25],
        "capacity_pack_risk_required_capacity_fraction_sources" => [
          "contact_required_capacity_fraction"
        ],
        "capacity_pack_contact_ids_by_direction" => %{
          "downlink" => ["dl_capacity_overflow", "dl_capacity_selected"]
        },
        "capacity_pack_selected_contact_ids_by_direction" => %{
          "downlink" => ["dl_capacity_selected"]
        },
        "capacity_pack_deferred_contact_ids_by_direction" => %{
          "downlink" => ["dl_capacity_overflow"]
        },
        "capacity_pack_required_capacity_fraction_by_direction" => %{"downlink" => 0.75},
        "capacity_pack_selected_required_capacity_fraction_by_direction" => %{
          "downlink" => 0.5
        },
        "capacity_pack_deferred_required_capacity_fraction_by_direction" => %{
          "downlink" => 0.25
        },
        "capacity_pack_risk_derivation_reasons" => [
          "contact_contention_deferred",
          "deferred_by_reduced_station_capacity_pack"
        ],
        "capacity_pack_risk_feedback_sources" => [
          "mission_state.source_contact_allocation_capacity_pack_summary"
        ],
        "capacity_pack_risk_feedback_scopes" => ["contact_contention_resolution"],
        "capacity_pack_risk_trust_boundaries" => ["mission_state_capacity_pack_summary"],
        "contact_contention_resolution_pressure_risk_types" => ["downlink_completion_gap"],
        "contact_contention_resolution_pressure_contact_ids" => ["dl_capacity_overflow"],
        "contact_contention_resolution_pressure_selected_contact_ids" => [
          "dl_capacity_selected"
        ],
        "contact_contention_resolution_pressure_scenario_ids" => ["leo_1"],
        "contact_contention_resolution_pressure_spacecraft_ids" => ["leo_1"],
        "contact_contention_resolution_pressure_ground_station_ids" => ["equator_prime"],
        "contact_contention_resolution_pressure_source_activity_ids" => [
          "dl_capacity_overflow"
        ],
        "contact_contention_resolution_pressure_source_window_ids" => [
          "window_capacity_overflow"
        ],
        "contact_contention_resolution_pressure_required_contact_values" => [1],
        "contact_contention_resolution_pressure_planned_contact_values" => [0],
        "contact_contention_resolution_pressure_required_downlink_values_mb" => [47.0],
        "contact_contention_resolution_pressure_planned_downlink_values_mb" => [0.0],
        "contact_contention_resolution_pressure_start_values_s" => [1_560.0],
        "contact_contention_resolution_pressure_end_values_s" => [1_620.0],
        "contact_contention_resolution_pressure_selected_priority_sources" => [
          "policy_contact_priority"
        ],
        "contact_contention_resolution_pressure_selection_reasons" => [
          "highest_priority_highest_score"
        ],
        "contact_contention_resolution_pressure_resolution_selection_rules" => [
          "highest_priority_highest_score"
        ],
        "contact_contention_resolution_pressure_priority_override_count_values" => [2],
        "contact_contention_resolution_pressure_priority_override_contact_ids" => [
          "dl_capacity_selected",
          "dl_capacity_overflow"
        ],
        "contact_contention_resolution_pressure_review_statuses" => [
          "operator_review_required"
        ],
        "contact_contention_resolution_pressure_downlink_demand_sources" => [
          "contention_resolution.required_downlink:dl_capacity_overflow"
        ],
        "contact_contention_resolution_pressure_downlink_completion_sources" => [
          "contact_contention_resolution_report:recommendations"
        ],
        "contact_contention_resolution_pressure_feedback_sources" => [
          "mission_state.source_contact_allocation_capacity_pack_summary"
        ],
        "contact_contention_resolution_pressure_feedback_scopes" => [
          "contact_contention_resolution"
        ],
        "contact_contention_resolution_pressure_trust_boundaries" => [
          "mission_state_capacity_pack_summary"
        ],
        "contact_contention_resolution_pressure_derivation_reasons" => [
          "contact_contention_deferred",
          "deferred_by_reduced_station_capacity_pack"
        ],
        "contact_contention_pressure_risk_types" => ["downlink_completion_gap"],
        "contact_contention_pressure_contact_ids" => ["dl_contention_conflict"],
        "contact_contention_pressure_scenario_ids" => ["leo_1"],
        "contact_contention_pressure_spacecraft_ids" => ["leo_1"],
        "contact_contention_pressure_ground_station_ids" => ["equator_prime"],
        "contact_contention_pressure_source_activity_ids" => ["dl_contention_conflict"],
        "contact_contention_pressure_source_window_ids" => [
          "window_contention_conflict",
          "window_contention_primary"
        ],
        "contact_contention_pressure_required_contact_values" => [1],
        "contact_contention_pressure_planned_contact_values" => [0],
        "contact_contention_pressure_required_downlink_values_mb" => [39.0],
        "contact_contention_pressure_planned_downlink_values_mb" => [0.0],
        "contact_contention_pressure_start_values_s" => [1_580.0],
        "contact_contention_pressure_end_values_s" => [1_640.0],
        "contact_contention_pressure_group_ids" => [
          "station:equator_prime:contention:selected"
        ],
        "contact_contention_pressure_resource_scopes" => ["ground_station"],
        "contact_contention_pressure_contention_contact_ids" => [
          "dl_contention_primary",
          "dl_contention_conflict"
        ],
        "contact_contention_pressure_required_operator_actions" => [
          "review_contact_contention"
        ],
        "contact_contention_pressure_approval_statuses" => ["operator_review_required"],
        "contact_contention_pressure_operator_action_reasons" => [
          "same_station_overlapping_contact_windows"
        ],
        "contact_contention_pressure_downlink_demand_sources" => [
          "contact_contention.required_downlink:dl_contention_conflict"
        ],
        "contact_contention_pressure_downlink_completion_sources" => [
          "contact_contention_report:conflict_groups"
        ],
        "contact_contention_pressure_feedback_sources" => [
          "mission_state.source_contact_contention_report.conflict_groups"
        ],
        "contact_contention_pressure_feedback_scopes" => ["contact_contention"],
        "contact_contention_pressure_trust_boundaries" => [
          "mission_state_contact_contention_report"
        ],
        "contact_contention_pressure_derivation_reasons" => [
          "contact_contention_conflict",
          "same_station_overlapping_contact_windows",
          "ground_station",
          "operator_review_required"
        ],
        "contact_allocation_pressure_risk_types" => ["downlink_completion_gap"],
        "contact_allocation_pressure_contact_ids" => ["dl_reservation_conflict"],
        "contact_allocation_pressure_scenario_ids" => ["leo_1"],
        "contact_allocation_pressure_spacecraft_ids" => ["leo_1"],
        "contact_allocation_pressure_ground_station_ids" => ["equator_prime"],
        "contact_allocation_pressure_source_activity_ids" => ["dl_reservation_conflict"],
        "contact_allocation_pressure_source_window_ids" => ["window_allocation_deferred"],
        "contact_allocation_pressure_required_contact_values" => [1],
        "contact_allocation_pressure_planned_contact_values" => [0],
        "contact_allocation_pressure_required_downlink_values_mb" => [43.0],
        "contact_allocation_pressure_planned_downlink_values_mb" => [0.0],
        "contact_allocation_pressure_start_values_s" => [1_620.0],
        "contact_allocation_pressure_end_values_s" => [1_680.0],
        "contact_allocation_pressure_realized_statuses" => ["deferred"],
        "contact_allocation_pressure_contact_results" => ["same_station_contention"],
        "contact_allocation_pressure_allocation_statuses" => ["deferred"],
        "contact_allocation_pressure_effective_allocation_statuses" => ["deferred"],
        "contact_allocation_pressure_allocation_reasons" => ["same_station_contention"],
        "contact_allocation_pressure_review_statuses" => ["operator_review_required"],
        "contact_allocation_pressure_approval_statuses" => ["operator_review_required"],
        "contact_allocation_pressure_policy_classifications" => ["review_only"],
        "contact_allocation_pressure_policy_bundle_ids" => ["contact_allocation_policy_v1"],
        "contact_allocation_pressure_station_reservation_ids" => ["reservation_conflict_1"],
        "contact_allocation_pressure_station_reserved_by" => ["ops_team_b"],
        "contact_allocation_pressure_station_reservation_statuses" => ["confirmed"],
        "contact_allocation_pressure_station_reservation_match_statuses" => ["overlap"],
        "contact_allocation_pressure_station_calendar_entry_ids" => [
          "calendar_allocation_deferred"
        ],
        "contact_allocation_pressure_station_calendar_entry_statuses" => ["reserved"],
        "contact_allocation_pressure_station_calendar_directions" => ["downlink"],
        "contact_allocation_pressure_downlink_demand_sources" => [
          "contact_allocation:dl_reservation_conflict"
        ],
        "contact_allocation_pressure_downlink_completion_sources" => [
          "contact_allocation_report:selected_contacts"
        ],
        "contact_allocation_pressure_feedback_sources" => [
          "mission_state.source_contact_allocation_reservation_conflict_summary"
        ],
        "contact_allocation_pressure_feedback_scopes" => ["contact_allocation"],
        "contact_allocation_pressure_trust_boundaries" => [
          "mission_state_reservation_conflict_summary"
        ],
        "contact_allocation_pressure_derivation_reasons" => [
          "contact_allocation_reservation_conflict"
        ],
        "contact_filter_pressure_risk_types" => ["downlink_completion_gap"],
        "contact_filter_pressure_contact_ids" => ["dl_contact_filter_suppressed"],
        "contact_filter_pressure_scenario_ids" => ["leo_1"],
        "contact_filter_pressure_spacecraft_ids" => ["leo_1"],
        "contact_filter_pressure_ground_station_ids" => ["goldstone"],
        "contact_filter_pressure_source_activity_ids" => ["dl_contact_filter_suppressed"],
        "contact_filter_pressure_source_window_ids" => ["window_contact_filter_suppressed"],
        "contact_filter_pressure_required_contact_values" => [1],
        "contact_filter_pressure_planned_contact_values" => [0],
        "contact_filter_pressure_required_downlink_values_mb" => [38.0],
        "contact_filter_pressure_planned_downlink_values_mb" => [0.0],
        "contact_filter_pressure_start_values_s" => [1_165.0],
        "contact_filter_pressure_end_values_s" => [1_225.0],
        "contact_filter_pressure_suppressed_reasons" => ["station_reserved"],
        "contact_filter_pressure_review_statuses" => ["operator_review_required"],
        "contact_filter_pressure_station_reservation_ids" => ["reservation_contact_filter"],
        "contact_filter_pressure_station_reserved_by" => ["partner_calendar"],
        "contact_filter_pressure_station_reservation_statuses" => ["confirmed"],
        "contact_filter_pressure_station_reservation_match_statuses" => ["overlap"],
        "contact_filter_pressure_station_calendar_entry_ids" => [
          "calendar_contact_filter_suppressed"
        ],
        "contact_filter_pressure_station_calendar_entry_statuses" => ["reserved"],
        "contact_filter_pressure_downlink_demand_sources" => [
          "contact_filter:dl_contact_filter_suppressed"
        ],
        "contact_filter_pressure_downlink_completion_sources" => [
          "contact_filter_report:suppressed_candidates"
        ],
        "contact_filter_pressure_feedback_sources" => [
          "mission_state.source_contact_filter_report.suppressed_candidates"
        ],
        "contact_filter_pressure_feedback_scopes" => ["contact_filter"],
        "contact_filter_pressure_trust_boundaries" => [
          "mission_state_contact_filter_report"
        ],
        "contact_filter_pressure_derivation_reasons" => [
          "contact_filter_suppressed",
          "station_reserved"
        ],
        "resource_filter_pressure_risk_types" => [
          "downlink_margin_low",
          "fuel_margin_low",
          "payload_unavailable",
          "power_margin_low",
          "storage_margin_low",
          "thermal_margin_c_low"
        ],
        "resource_filter_pressure_scenario_ids" => ["leo_1"],
        "resource_filter_pressure_spacecraft_ids" => ["leo_1"],
        "resource_filter_pressure_resource_fields" => [
          "downlink_margin",
          "fuel_margin",
          "payload_available",
          "power_margin",
          "storage_margin",
          "thermal_margin_c"
        ],
        "resource_filter_pressure_available_values" => [false],
        "resource_filter_pressure_source_activity_ids" => [
          "dl_resource_filter_downlink",
          "obs_resource_filter_fuel",
          "obs_resource_filter_suppressed",
          "obs_resource_filter_power",
          "obs_resource_filter_storage",
          "obs_resource_filter_thermal"
        ],
        "resource_filter_pressure_start_values_s" => [
          1_510.0,
          1_300.0,
          1_230.0,
          1_370.0,
          1_440.0,
          1_580.0
        ],
        "resource_filter_pressure_end_values_s" => [
          1_570.0,
          1_360.0,
          1_290.0,
          1_430.0,
          1_500.0,
          1_640.0
        ],
        "resource_filter_pressure_suppressed_reasons" => [
          "downlink_margin_below_policy",
          "fuel_margin_below_policy",
          "payload_unavailable",
          "power_margin_below_observe_policy",
          "storage_margin_below_observe_policy",
          "thermal_margin_below_policy"
        ],
        "resource_filter_pressure_source_quality_values" => ["operator_supplied"],
        "resource_filter_pressure_resource_trust_boundary_statuses" => ["declared"],
        "resource_filter_pressure_fuel_margin_values" => [0.05],
        "resource_filter_pressure_fuel_margin_threshold_values" => [0.1],
        "resource_filter_pressure_power_margin_values" => [0.08],
        "resource_filter_pressure_power_margin_threshold_values" => [0.2],
        "resource_filter_pressure_storage_margin_values" => [12.0],
        "resource_filter_pressure_storage_margin_threshold_values" => [20.0],
        "resource_filter_pressure_downlink_margin_values" => [8.0],
        "resource_filter_pressure_downlink_margin_threshold_values" => [15.0],
        "resource_filter_pressure_thermal_margin_values_c" => [2.0],
        "resource_filter_pressure_thermal_margin_threshold_values_c" => [5.0],
        "resource_filter_pressure_operator_training_requirement_count_values" => [2],
        "resource_filter_pressure_required_operator_roles" => [
          "contact_operator",
          "resource_operator"
        ],
        "resource_filter_pressure_feedback_sources" => [
          "mission_state.source_resource_filter_report.suppressed_candidates"
        ],
        "resource_filter_pressure_feedback_scopes" => ["resource_filter"],
        "resource_filter_pressure_trust_boundaries" => [
          "mission_state_resource_filter_report"
        ],
        "resource_filter_pressure_derivation_reasons" => [
          "resource_filter_suppressed",
          "downlink_margin_below_policy",
          "fuel_margin_below_policy",
          "payload_unavailable",
          "power_margin_below_observe_policy",
          "storage_margin_below_observe_policy",
          "thermal_margin_below_policy"
        ],
        "station_reservation_conflict_contact_ids" => ["dl_reservation_conflict"],
        "station_reservation_conflict_source_activity_ids" => ["dl_reservation_conflict"],
        "station_reservation_conflict_ground_station_ids" => ["equator_prime"],
        "station_reservation_conflict_reservation_ids" => ["reservation_conflict_1"],
        "station_reservation_conflict_reserved_by" => ["ops_team_b"],
        "station_reservation_conflict_statuses" => ["confirmed"],
        "station_reservation_conflict_expiration_statuses" => ["active"],
        "station_reservation_conflict_match_statuses" => ["overlap"],
        "station_reservation_conflict_expires_at_values_s" => [360.0],
        "station_reservation_conflict_derivation_reasons" => [
          "contact_allocation_reservation_conflict"
        ],
        "station_reservation_conflict_feedback_sources" => [
          "mission_state.source_contact_allocation_reservation_conflict_summary"
        ],
        "station_reservation_conflict_feedback_scopes" => ["contact_allocation"],
        "station_reservation_conflict_trust_boundaries" => [
          "mission_state_reservation_conflict_summary"
        ],
        "station_reservation_hold_import_statuses" => ["review_required_before_import"],
        "station_reservation_hold_expiration_statuses" => ["active"],
        "station_reservation_hold_import_readiness_summary_models" => [
          "artifact_only_station_reservation_hold_import_readiness_summary"
        ],
        "station_reservation_hold_import_readiness_sources" => [
          "station_calendar_report.reservation_evidence"
        ],
        "station_reservation_hold_import_readiness_source_artifact_types" => [
          "station_reservation_report.v1"
        ],
        "station_reservation_hold_import_readiness_statuses" => ["review_required"],
        "station_reservation_hold_import_classifications" => ["review_only"],
        "station_reservation_hold_count_values" => [2],
        "station_reservation_hold_ids" => [
          "reservation_hold_active",
          "reservation_hold_missing"
        ],
        "station_reservation_hold_ids_by_import_status" => [
          %{
            "review_required_before_import" => [
              "reservation_hold_active",
              "reservation_hold_missing"
            ]
          }
        ],
        "station_reservation_hold_ids_by_required_import_action" => [
          %{
            "review_station_provider_contention" => ["reservation_hold_missing"],
            "review_station_reservation_overlap" => ["reservation_hold_active"]
          }
        ],
        "station_reservation_hold_ids_by_direction" => [
          %{
            "downlink" => ["reservation_hold_active"],
            "uplink" => ["reservation_hold_missing"]
          }
        ],
        "station_reservation_hold_ids_by_direction_and_ground_station_id" => [
          %{
            "downlink:equator_prime" => ["reservation_hold_active"],
            "uplink:equator_prime" => ["reservation_hold_missing"]
          }
        ],
        "station_reservation_hold_contact_ids" => ["dl_hold_import_review"],
        "station_reservation_hold_contact_ids_by_import_status" => [
          %{"review_required_before_import" => ["dl_hold_import_review"]}
        ],
        "station_reservation_hold_contact_ids_by_expiration_status" => [
          %{"active" => ["dl_hold_import_review"]}
        ],
        "station_reservation_hold_contact_ids_by_direction" => [
          %{"downlink" => ["dl_hold_import_review"]}
        ],
        "station_reservation_hold_contact_ids_by_direction_and_ground_station_id" => [
          %{"downlink:equator_prime" => ["dl_hold_import_review"]}
        ],
        "station_reservation_hold_import_status_count_maps" => [
          %{"review_required_before_import" => 2}
        ],
        "station_reservation_hold_required_import_action_count_maps" => [
          %{
            "review_station_provider_contention" => 1,
            "review_station_reservation_overlap" => 1
          }
        ],
        "station_reservation_hold_import_execution_boundaries" => [
          "artifact_only_no_provider_or_cadence_writes"
        ],
        "station_reservation_hold_provider_write_values" => ["not_performed_by_summary"],
        "station_reservation_hold_cadence_write_values" => ["not_performed_by_summary"],
        "station_reservation_hold_reservation_acceptance_values" => [
          "not_performed_by_summary"
        ],
        "station_reservation_hold_feedback_sources" => [
          "mission_state.source_station_reservation_hold_import_readiness_summary"
        ],
        "station_reservation_hold_feedback_scopes" => [
          "station_reservation_hold_import_readiness"
        ],
        "station_reservation_hold_trust_boundaries" => [
          "mission_state_station_reservation_hold_import_readiness_summary"
        ],
        "source_station_reservation_hold_import_readiness_summaries" => [
          %{
            "model" => "artifact_only_station_reservation_hold_import_readiness_summary",
            "source_artifact_type" => "station_reservation_report.v1",
            "source" => "station_calendar_report.reservation_evidence",
            "reservation_hold_count" => 2,
            "import_readiness_status" => "review_required",
            "import_classification" => "review_only"
          }
        ],
        "provider_counteroffer_ids" => ["provider_offer_urgent"],
        "provider_counteroffer_statuses" => ["proposed"],
        "provider_counteroffer_negotiation_states" => ["proposed"],
        "provider_counteroffer_reason_codes" => ["provider_shifted_window"],
        "provider_counteroffer_cost_deltas" => [125.5],
        "provider_counteroffer_lock_deadline_values_s" => [150.0],
        "provider_counteroffer_starts_at_values_s" => [530.0],
        "provider_counteroffer_ends_at_values_s" => [590.0],
        "provider_counteroffer_start_delta_values_s" => [30.0],
        "provider_counteroffer_end_delta_values_s" => [30.0],
        "provider_counteroffer_duration_delta_values_s" => [0.0],
        "provider_counteroffer_plan_impact_statuses" => ["review_required"],
        "provider_counteroffer_affected_station_calendar_entry_ids" => ["contact_original"],
        "provider_counteroffer_affected_provider_entry_ids" => ["partner_entry_42"],
        "provider_counteroffer_impact_counteroffer_ids" => ["provider_offer_urgent"],
        "provider_counteroffer_required_operator_actions" => ["review_provider_counteroffer"],
        "provider_counteroffer_feedback_sources" => [
          "mission_state.source_provider_counteroffer_report.rows"
        ],
        "provider_counteroffer_feedback_scopes" => ["provider_counteroffer"],
        "provider_counteroffer_feedback_keys" => ["provider_offer_urgent"],
        "provider_counteroffer_trust_boundaries" => [
          "mission_state_provider_counteroffer_report"
        ],
        "candidate_rejection_candidate_ids" => ["dl_rejected_hot"],
        "candidate_rejection_activity_ids" => ["dl_rejected_hot"],
        "candidate_rejection_activity_types" => ["downlink"],
        "candidate_rejection_scenario_ids" => ["leo_1"],
        "candidate_rejection_ground_station_ids" => ["equator_prime"],
        "candidate_rejection_source_window_ids" => ["equator_prime_rejected_window"],
        "candidate_rejection_source_window_types" => ["ground_station_contact"],
        "candidate_rejection_statuses" => ["rejected"],
        "candidate_rejection_primary_reasons" => ["contact_too_short"],
        "candidate_rejection_reason_ids" => [
          "contact_too_short",
          "station_capacity_reduced",
          "station_reserved"
        ],
        "candidate_rejection_violated_constraints" => ["min_duration_s"],
        "candidate_rejection_required_margin_values" => [10.0],
        "candidate_rejection_actual_margin_values" => [5.0],
        "candidate_rejection_required_operator_actions" => ["review_candidate_rejection"],
        "candidate_rejection_feedback_sources" => [
          "mission_state.source_candidate_rejection_report.rows"
        ],
        "candidate_rejection_feedback_scopes" => ["candidate_rejection"],
        "candidate_rejection_feedback_keys" => ["dl_rejected_hot"],
        "candidate_rejection_trust_boundaries" => [
          "mission_state_candidate_rejection_report"
        ],
        "model_acceptance_report_ids" => ["model_acceptance:operational_import:live_ops"],
        "model_acceptance_intended_uses" => ["operational_import"],
        "model_acceptance_statuses" => ["review_required"],
        "model_acceptance_model_ids" => ["live_analysis_model"],
        "model_acceptance_model_statuses" => ["review_required"],
        "model_acceptance_validation_levels" => ["analysis"],
        "model_acceptance_model_reasons" => [
          "analysis evidence requires operator review for operational_import"
        ],
        "model_acceptance_status_count_maps" => [%{"review_required" => 1}],
        "model_acceptance_validation_level_count_maps" => [%{"analysis" => 1}],
        "model_acceptance_model_ids_by_status" => [
          %{"review_required" => ["live_analysis_model"]}
        ],
        "model_acceptance_model_ids_by_validation_level" => [
          %{"analysis" => ["live_analysis_model"]}
        ],
        "model_acceptance_model_ids_by_intended_use" => [
          %{"operational_import" => ["live_analysis_model"]}
        ],
        "model_acceptance_required_operator_actions" => ["review_model_acceptance"],
        "model_acceptance_feedback_sources" => [
          "mission_state.source_model_acceptance_report.rows"
        ],
        "model_acceptance_feedback_scopes" => ["model_acceptance"],
        "model_acceptance_feedback_keys" => ["live_analysis_model"],
        "model_acceptance_trust_boundaries" => [
          "mission_state_model_acceptance_report"
        ],
        "schema_validation_statuses" => ["fail"],
        "schema_validation_modes" => ["artifact_file"],
        "schema_validation_validated_contracts" => ["candidate_refresh.v1"],
        "schema_validation_artifact_families" => ["candidate_refresh"],
        "schema_validation_artifact_paths" => ["study_results/candidate_refresh.json"],
        "schema_validation_issue_severities" => ["error"],
        "schema_validation_issue_paths" => ["$.candidate_plan.activities[0].id"],
        "schema_validation_error_count_values" => [1],
        "schema_validation_warning_count_values" => [0],
        "schema_validation_remediation_count_values" => [1],
        "schema_validation_remediation_categories" => ["schema_contract"],
        "schema_validation_remediation_actions" => ["regenerate_candidate_refresh"],
        "schema_validation_required_operator_actions" => ["review_schema_validation"],
        "schema_validation_feedback_sources" => [
          "mission_state.source_schema_validation_report.errors"
        ],
        "schema_validation_feedback_scopes" => ["schema_validation"],
        "schema_validation_feedback_keys" => ["$.candidate_plan.activities[0].id"],
        "schema_validation_trust_boundaries" => [
          "mission_state_schema_validation_report"
        ],
        "validation_safety_case_report_ids" => ["validation_safety_case:live_ops"],
        "validation_safety_case_statuses" => ["blocked"],
        "validation_safety_case_evidence_statuses" => ["blocked"],
        "validation_safety_case_input_contracts" => [
          "model_acceptance_report.v1",
          "quality_gate_report.v1"
        ],
        "validation_safety_case_evidence_refs" => [
          "model_acceptance_report.v1:model.blocked"
        ],
        "validation_safety_case_evidence_count_values" => [2],
        "validation_safety_case_accepted_evidence_count_values" => [0],
        "validation_safety_case_review_required_evidence_count_values" => [1],
        "validation_safety_case_blocked_evidence_count_values" => [1],
        "validation_safety_case_model_blocked_count_values" => [1],
        "validation_safety_case_quality_gate_review_count_values" => [1],
        "validation_safety_case_quality_gate_blocked_count_values" => [1],
        "validation_safety_case_schema_error_count_values" => [1],
        "validation_safety_case_schema_warning_count_values" => [2],
        "validation_safety_case_evidence_status_count_maps" => [
          %{"blocked" => 1, "review_required" => 1}
        ],
        "validation_safety_case_evidence_refs_by_status" => [
          %{
            "blocked" => ["model_acceptance_report.v1:model.blocked"],
            "review_required" => ["quality_gate_report.v1:gate.review"]
          }
        ],
        "validation_safety_case_evidence_refs_by_contract" => [
          %{
            "model_acceptance_report.v1" => ["model_acceptance_report.v1:model.blocked"],
            "quality_gate_report.v1" => ["quality_gate_report.v1:gate.review"]
          }
        ],
        "validation_safety_case_required_operator_actions" => [
          "review_blocked_validation_safety_case"
        ],
        "validation_safety_case_feedback_sources" => [
          "mission_state.source_validation_safety_case_summary.evidence"
        ],
        "validation_safety_case_feedback_scopes" => ["validation_safety_case"],
        "validation_safety_case_feedback_keys" => [
          "model_acceptance_report.v1:model.blocked"
        ],
        "validation_safety_case_trust_boundaries" => [
          "mission_state_validation_safety_case_summary"
        ],
        "refresh_budget_statuses" => ["review_required"],
        "refresh_budget_candidate_limit_statuses" => ["relaxed_required"],
        "refresh_budget_input_candidate_count_values" => [8],
        "refresh_budget_kept_candidate_count_values" => [4],
        "refresh_budget_dropped_candidate_count_values" => [4],
        "refresh_budget_invalid_limit_count_values" => [0],
        "refresh_budget_current_max_candidate_activity_values" => [4],
        "refresh_budget_relaxed_max_candidate_activity_values" => [8],
        "refresh_budget_required_operator_actions" => ["review_refresh_budget"],
        "refresh_budget_feedback_sources" => ["mission_state.source_refresh_budget_report"],
        "refresh_budget_feedback_scopes" => ["refresh_budget"],
        "refresh_budget_feedback_keys" => ["refresh_budget:limit"],
        "refresh_budget_trust_boundaries" => [
          "mission_state_refresh_budget_report"
        ],
        "refresh_freshness_statuses" => ["stale"],
        "refresh_freshness_state_quality_statuses" => ["stale"],
        "refresh_freshness_accepted_snapshot_age_values_s" => [3600.0],
        "refresh_freshness_horizon_start_offset_values_s" => [120.0],
        "refresh_freshness_max_snapshot_age_values_s" => [60.0],
        "refresh_freshness_max_horizon_start_offset_values_s" => [30.0],
        "refresh_freshness_stale_reason_ids" => [
          "accepted_snapshot_older_than_policy",
          "horizon_start_offset_exceeds_policy"
        ],
        "refresh_freshness_required_operator_actions" => ["review_refresh_freshness"],
        "refresh_freshness_feedback_sources" => ["mission_state.source_freshness_report"],
        "refresh_freshness_feedback_scopes" => ["refresh_freshness"],
        "refresh_freshness_feedback_keys" => ["freshness:stale"],
        "refresh_freshness_trust_boundaries" => [
          "mission_state_freshness_report"
        ]
      }
      |> Map.merge(%{
        "strategy_operational_feedback_collection_ids" => [
          "collection_hot",
          "collection_objective_quality",
          "collection_objective_quality_backup"
        ],
        "strategy_operational_feedback_start_values_s" => [790.0, 870.0, 1380.0, 950.0],
        "strategy_operational_feedback_feedback_sources" => [
          "mission_state.source_contact_review.rows",
          "mission_state.source_observation_review.rows",
          "mission_state.source_objective_satisfaction_report.rows",
          "mission_state.source_station_throughput_review.rows"
        ],
        "strategy_operational_feedback_source_activity_ids" => [
          "contact_feedback_source",
          "contact_feedback_review",
          "obs_feedback_source",
          "obs_feedback_review",
          "obs_objective_quality_source",
          "obs_objective_quality_selected",
          "station_feedback_source",
          "station_feedback_review"
        ],
        "strategy_operational_feedback_product_ids" => [
          "product_hot",
          "product_objective_quality",
          "product_objective_quality_backup"
        ],
        "strategy_operational_feedback_trust_boundaries" => [
          "mission_state_contact_review",
          "mission_state_observation_review",
          "mission_state_objective_satisfaction_report",
          "mission_state_station_throughput_review"
        ],
        "strategy_operational_feedback_target_ids" => [
          "target_hot",
          "target_objective_quality"
        ],
        "strategy_operational_feedback_observation_success_factor_values" => [0.45, 0.35],
        "strategy_operational_feedback_cloud_cover_fraction_values" => [0.55, 0.62],
        "strategy_operational_feedback_end_values_s" => [850.0, 930.0, 1440.0, 1010.0],
        "strategy_operational_feedback_derivation_reasons" => [
          "contact_execution_feedback_pressure",
          "observation_execution_feedback_pressure",
          "objective_satisfaction_observation_quality_gap",
          "objective_satisfaction_image_quality_marginal",
          "station_throughput_feedback_pressure"
        ],
        "strategy_operational_feedback_feedback_scopes" => [
          "contact_execution_feedback",
          "observation_execution_feedback",
          "objective_satisfaction",
          "station_throughput_feedback"
        ],
        "strategy_operational_feedback_blur_score_values" => [0.25, 0.31],
        "strategy_operational_feedback_instrument_ids" => [
          "camera_nadir",
          "instrument_objective_quality",
          "instrument_objective_quality_backup"
        ],
        "strategy_operational_feedback_image_quality_score_values" => [0.45, 0.42],
        "objective_satisfaction_pressure_risk_types" => [
          "downlink_completion_gap",
          "observation_success_rate_low"
        ],
        "strategy_operational_feedback_payload_ids" => [
          "payload_nadir",
          "payload_objective_quality",
          "payload_objective_quality_backup"
        ]
      })

    expected_handoff
  end
end
