defmodule OrbitalDynamics.CandidateRefreshTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "declares candidate refresh capabilities" do
    assert %{
             artifact_contract: "candidate_refresh.v1",
             planner: "OrbitalDynamics.CandidateRefresh.V1",
             validation_level: :artifact_contract,
             inputs: inputs,
             outputs: outputs,
             freshness_model: :accepted_snapshot_horizon_and_quality_freshness,
             candidate_diff_model: :candidate_id_set_diff_with_semantic_change_reasons,
             public_facades: public_facades,
             source_report_helpers: source_report_helpers,
             source_report_summary_semantics: source_report_summary_semantics,
             resource_availability_aliases: resource_availability_aliases,
             resource_margin_aliases: resource_margin_aliases,
             resource_power_margin_source_aliases: resource_power_margin_source_aliases,
             resource_availability_true_tokens: resource_availability_true_tokens,
             resource_availability_false_tokens: resource_availability_false_tokens,
             provider_direction_aliases: provider_direction_aliases,
             station_unavailable_aliases: station_unavailable_aliases,
             station_unavailable_tokens: station_unavailable_tokens,
             station_availability_precedence: station_availability_precedence,
             station_capacity_fraction_paths: station_capacity_fraction_paths,
             station_capacity_percent_paths: station_capacity_percent_paths,
             station_capacity_value_paths: station_capacity_value_paths,
             prior_candidate_optional_stable_identity_fields:
               prior_candidate_optional_stable_identity_fields,
             station_calendar_id_list_fields: station_calendar_id_list_fields,
             station_calendar_number_list_fields: station_calendar_number_list_fields,
             event_timing_keys: event_timing_keys,
             operational_timeline_integrity_issue_fields:
               operational_timeline_integrity_issue_fields,
             operational_timeline_dependency_integrity_issue_fields:
               operational_timeline_dependency_integrity_issue_fields,
             operational_timeline_exclusivity_integrity_issue_fields:
               operational_timeline_exclusivity_integrity_issue_fields,
             row_semantics: row_semantics,
             known_limits: known_limits
           } = CandidateRefresh.capabilities()

    assert :accepted_planning_state in inputs
    assert :mission_state in inputs
    assert :refreshed_event_results in inputs
    assert :station_calendar in inputs
    assert :station_calendar_report in inputs
    assert :station_calendar_precedence_summary in inputs
    assert :contact_intents in inputs
    assert :contact_intent_summary in inputs
    assert :resource_projection_report in inputs
    assert :resource_projection_flow_summary in inputs
    assert :relay_data_path_summary in inputs
    assert :resource_filter_report in inputs
    assert :resource_filter_summary in inputs
    assert :contact_filter_report in inputs
    assert :timeline_integrity_report in inputs
    assert :timeline_activity_state in inputs
    assert :timeline_activity_lifecycle_state in inputs
    assert :timeline_activity_precondition_summary in inputs
    assert :timeline_diff_report in inputs
    assert :timeline_diff_summary in inputs
    assert :timeline_lifecycle_state_summary in inputs
    assert :timeline_dependency_impact_summary in inputs
    assert :timeline_publication_summary in inputs
    assert :timeline_transition_application_report in inputs
    assert :timeline_transition_application_summary in inputs
    assert :objective_satisfaction_report in inputs
    assert :objective_tradeoff_report in inputs
    assert :score_term_report in inputs
    assert :constraint_report in inputs
    assert :candidate_diff_report in inputs
    assert :candidate_rejection_report in inputs
    assert :freshness_report in inputs
    assert :refresh_budget_report in inputs
    assert :schema_validation_report in inputs
    assert :schema_validation_batch_report in inputs
    assert :operational_readiness_report in inputs
    assert :operational_import_eligibility_summary in inputs
    assert :operational_readiness_gate_summary in inputs
    assert :operational_execution_boundary_summary in inputs
    assert :command_window_report in inputs
    assert :maneuver_review_report in inputs
    assert :provider_counteroffer_report in inputs
    assert :provider_counteroffer_review_summary in inputs
    assert :provider_counteroffer_import_readiness_summary in inputs
    assert :provider_counteroffer_plan_impact_summary in inputs
    assert :contact_allocation_report in inputs
    assert :contact_allocation_summary in inputs
    assert :contact_allocation_station_pressure_summary in inputs
    assert :contact_allocation_reservation_conflict_summary in inputs
    assert :contact_allocation_capacity_pack_summary in inputs
    assert :contact_allocation_provider_reservation_request_summary in inputs
    assert :station_reservation_report in inputs
    assert :station_reservation_review_summary in inputs
    assert :station_reservation_hold_summary in inputs
    assert :station_reservation_hold_import_readiness_summary in inputs
    assert :contact_contention_report in inputs
    assert :contact_contention_resolution_report in inputs
    assert :contact_contention_resolution_summary in inputs
    assert :link_capacity_report in inputs
    assert :link_capacity_summary in inputs
    assert :quality_gate_report in inputs
    assert :model_acceptance_report in inputs
    assert :validation_safety_case_summary in inputs
    assert :candidate_activities in outputs
    assert :freshness_report in outputs
    assert :contact_allocation_report in outputs
    assert :refresh_budget_report in outputs
    assert :candidate_refresh_source_report_summary in public_facades
    assert :candidate_refresh_operational_readiness_replay_summary in public_facades
    assert :candidate_refresh_quality_gate_replay_summary in public_facades
    assert :candidate_refresh_model_acceptance_replay_summary in public_facades
    assert :candidate_refresh_validation_safety_case_replay_summary in public_facades
    assert :candidate_refresh_freshness_replay_summary in public_facades
    assert :candidate_refresh_refresh_budget_replay_summary in public_facades
    assert :candidate_refresh_schema_validation_replay_summary in public_facades
    assert :candidate_refresh_candidate_diff_replay_summary in public_facades
    assert :candidate_refresh_candidate_rejection_replay_summary in public_facades
    assert :candidate_refresh_provider_counteroffer_replay_summary in public_facades
    assert :candidate_refresh_contact_contention_replay_summary in public_facades
    assert :candidate_refresh_contact_contention_resolution_replay_summary in public_facades
    assert :candidate_refresh_contact_allocation_replay_summary in public_facades
    assert :candidate_refresh_link_capacity_replay_summary in public_facades
    assert :candidate_refresh_contact_filter_replay_summary in public_facades
    assert :candidate_refresh_resource_filter_replay_summary in public_facades
    assert :candidate_refresh_resource_projection_replay_summary in public_facades
    assert :candidate_refresh_storage_downlink_pressure_replay_summary in public_facades
    assert :candidate_refresh_station_calendar_replay_summary in public_facades
    assert :candidate_refresh_station_reservation_replay_summary in public_facades
    assert :candidate_refresh_command_window_replay_summary in public_facades
    assert :candidate_refresh_maneuver_review_replay_summary in public_facades
    assert :candidate_refresh_contact_intent_replay_summary in public_facades
    assert :candidate_refresh_timeline_activity_state_replay_summary in public_facades
    assert :candidate_refresh_timeline_activity_status_state_replay_summary in public_facades
    assert :candidate_refresh_timeline_activity_approval_state_replay_summary in public_facades
    assert :candidate_refresh_timeline_activity_lifecycle_state_replay_summary in public_facades
    assert :candidate_refresh_timeline_activity_precondition_replay_summary in public_facades
    assert :candidate_refresh_timeline_preservation_replay_summary in public_facades
    assert :candidate_refresh_timeline_integrity_replay_summary in public_facades
    assert :candidate_refresh_timeline_diff_replay_summary in public_facades
    assert :candidate_refresh_timeline_lifecycle_state_replay_summary in public_facades
    assert :candidate_refresh_timeline_dependency_impact_replay_summary in public_facades
    assert :candidate_refresh_timeline_publication_replay_summary in public_facades
    assert :candidate_refresh_timeline_transition_application_replay_summary in public_facades
    assert :candidate_refresh_objective_gap_replay_summary in public_facades
    assert :candidate_refresh_constraint_replay_summary in public_facades
    assert :candidate_refresh_timeline_feedback_replay_summary in public_facades
    assert :candidate_refresh_operational_timeline_replay_summary in public_facades
    assert :source_report_summary in source_report_helpers
    assert :candidate_diff_replay_summary in source_report_helpers
    assert :candidate_rejection_replay_summary in source_report_helpers
    assert :provider_counteroffer_replay_summary in source_report_helpers
    assert :contact_contention_replay_summary in source_report_helpers
    assert :contact_contention_resolution_replay_summary in source_report_helpers
    assert :contact_allocation_replay_summary in source_report_helpers
    assert :link_capacity_replay_summary in source_report_helpers
    assert :contact_filter_replay_summary in source_report_helpers
    assert :resource_filter_replay_summary in source_report_helpers
    assert :resource_projection_replay_summary in source_report_helpers
    assert :storage_downlink_pressure_replay_summary in source_report_helpers
    assert :station_calendar_replay_summary in source_report_helpers
    assert :station_reservation_replay_summary in source_report_helpers
    assert :command_window_replay_summary in source_report_helpers
    assert :maneuver_review_replay_summary in source_report_helpers
    assert :contact_intent_replay_summary in source_report_helpers
    assert :timeline_activity_state_replay_summary in source_report_helpers
    assert :timeline_activity_status_state_replay_summary in source_report_helpers
    assert :timeline_activity_approval_state_replay_summary in source_report_helpers
    assert :timeline_activity_lifecycle_state_replay_summary in source_report_helpers
    assert :timeline_activity_precondition_replay_summary in source_report_helpers
    assert :timeline_preservation_replay_summary in source_report_helpers
    assert :timeline_integrity_replay_summary in source_report_helpers
    assert :timeline_diff_replay_summary in source_report_helpers
    assert :timeline_lifecycle_state_replay_summary in source_report_helpers
    assert :timeline_dependency_impact_replay_summary in source_report_helpers
    assert :timeline_publication_replay_summary in source_report_helpers
    assert :timeline_transition_application_replay_summary in source_report_helpers
    assert :objective_gap_replay_summary in source_report_helpers
    assert :constraint_replay_summary in source_report_helpers
    assert :timeline_feedback_replay_summary in source_report_helpers
    assert :operational_timeline_replay_summary in source_report_helpers
    assert :operational_readiness_replay_summary in source_report_helpers
    assert :quality_gate_replay_summary in source_report_helpers
    assert :model_acceptance_replay_summary in source_report_helpers
    assert :validation_safety_case_replay_summary in source_report_helpers
    assert :freshness_replay_summary in source_report_helpers
    assert :refresh_budget_replay_summary in source_report_helpers
    assert :schema_validation_replay_summary in source_report_helpers
    assert :source_report_contract_counts in source_report_summary_semantics
    assert :source_report_counts_by_family in source_report_summary_semantics
    assert :source_report_row_counts_by_family in source_report_summary_semantics
    assert :source_report_counts_by_contract in source_report_summary_semantics
    assert :source_report_row_counts_by_contract in source_report_summary_semantics
    assert :source_report_counts_by_trust_boundary_status in source_report_summary_semantics
    assert :source_report_row_counts_by_trust_boundary_status in source_report_summary_semantics
    assert :source_report_paths_by_family in source_report_summary_semantics
    assert :source_report_paths_by_contract in source_report_summary_semantics
    assert :source_report_paths_by_trust_boundary_status in source_report_summary_semantics
    assert :source_report_trust_boundary_status_counts in source_report_summary_semantics
    assert :source_report_status_count_maps in source_report_summary_semantics
    assert :source_report_readiness_quality_gate_count_maps in source_report_summary_semantics

    assert :source_report_readiness_quality_gate_analysis_mode_count_maps in source_report_summary_semantics

    assert :source_report_adapter_boundary_count_maps in source_report_summary_semantics
    assert :source_report_resource_availability_count_maps in source_report_summary_semantics
    assert :source_report_station_availability_reason_ids in source_report_summary_semantics

    assert :source_report_station_availability_reason_count_maps in source_report_summary_semantics

    assert :source_report_station_pressure_count_maps in source_report_summary_semantics

    assert :source_report_contact_allocation_capacity_pack_routing_maps in source_report_summary_semantics

    assert :source_report_contact_allocation_capacity_pack_demand_maps in source_report_summary_semantics

    assert :source_report_contact_allocation_provider_reservation_request_routing_maps in source_report_summary_semantics

    assert :source_report_contact_allocation_direction_routing_maps in source_report_summary_semantics

    assert :source_report_link_capacity_routing_count_maps in source_report_summary_semantics

    assert :source_report_link_capacity_direction_lists in source_report_summary_semantics

    assert :source_report_link_capacity_direction_routing_maps in source_report_summary_semantics

    assert :source_report_link_capacity_contact_pressure_routing_maps in source_report_summary_semantics

    assert :source_report_link_capacity_source_window_routing_maps in source_report_summary_semantics

    assert :source_report_link_capacity_spacecraft_routing_maps in source_report_summary_semantics

    assert :source_report_link_capacity_station_calendar_routing_maps in source_report_summary_semantics

    assert :source_report_link_capacity_adjusted_throughput_maps in source_report_summary_semantics

    assert :source_report_constraint_routing_count_maps in source_report_summary_semantics

    assert :source_report_constraint_id_routing_maps in source_report_summary_semantics

    assert :source_report_constraint_activity_routing_maps in source_report_summary_semantics

    assert :source_report_resource_projection_routing_count_maps in source_report_summary_semantics

    assert :source_report_resource_projection_direction_lists in source_report_summary_semantics

    assert :source_report_resource_projection_direction_routing_maps in source_report_summary_semantics

    assert :source_report_resource_projection_activity_pressure_routing_maps in source_report_summary_semantics

    assert :source_report_resource_filter_routing_count_maps in source_report_summary_semantics

    assert :source_report_resource_filter_direction_lists in source_report_summary_semantics

    assert :source_report_resource_filter_direction_routing_maps in source_report_summary_semantics

    assert :source_report_resource_filter_suppression_reason_candidate_routing_maps in source_report_summary_semantics

    assert :source_report_resource_filter_blocking_candidate_routing_maps in source_report_summary_semantics

    assert :source_report_contact_contention_routing_count_maps in source_report_summary_semantics

    assert :source_report_contact_contention_capacity_pack_demand_maps in source_report_summary_semantics

    assert :source_report_contact_contention_direction_routing_maps in source_report_summary_semantics

    assert :source_report_contact_contention_resolution_direction_routing_maps in source_report_summary_semantics

    assert :source_report_contact_contention_resolution_required_action_routing_maps in source_report_summary_semantics

    assert :source_report_candidate_diff_routing_count_maps in source_report_summary_semantics

    assert :source_report_candidate_rejection_routing_count_maps in source_report_summary_semantics

    assert :source_report_objective_gap_routing_count_maps in source_report_summary_semantics

    assert :source_report_objective_gap_aggregate_routing_maps in source_report_summary_semantics

    assert :source_report_objective_gap_activity_routing_maps in source_report_summary_semantics

    assert :source_report_contact_intent_station_feedback_count_maps in source_report_summary_semantics

    assert :source_report_contact_intent_capacity_pack_demand_maps in source_report_summary_semantics

    assert :source_report_contact_intent_direction_lists in source_report_summary_semantics

    assert :source_report_contact_intent_direction_routing_maps in source_report_summary_semantics

    assert :source_report_contact_filter_direction_lists in source_report_summary_semantics

    assert :source_report_contact_filter_direction_routing_maps in source_report_summary_semantics

    assert :source_report_contact_filter_station_suppression_count_maps in source_report_summary_semantics

    assert :source_report_station_calendar_affected_contact_count_maps in source_report_summary_semantics

    assert :source_report_station_calendar_provider_contention_count_maps in source_report_summary_semantics

    assert :source_report_station_calendar_direction_routing_maps in source_report_summary_semantics

    assert :source_report_station_reservation_report_count_maps in source_report_summary_semantics

    assert :source_report_station_reservation_evidence_counts in source_report_summary_semantics

    assert :source_report_station_reservation_hold_summary_maps in source_report_summary_semantics

    assert :source_report_station_reservation_hold_import_readiness_maps in source_report_summary_semantics

    assert :source_contact_allocation_summary_input_provenance in row_semantics

    assert :source_contact_allocation_station_pressure_summary_input_provenance in row_semantics

    assert :source_contact_allocation_reservation_conflict_summary_input_provenance in row_semantics

    assert :source_contact_allocation_capacity_pack_summary_input_provenance in row_semantics

    assert :source_station_reservation_review_summary_input_provenance in row_semantics

    assert :source_station_reservation_hold_summary_input_provenance in row_semantics

    assert :source_station_reservation_hold_import_readiness_summary_input_provenance in row_semantics

    assert :source_provider_counteroffer_import_readiness_summary_input_provenance in row_semantics

    assert :source_report_timeline_diff_routing_count_maps in source_report_summary_semantics

    assert :source_report_timeline_diff_activity_routing_maps in source_report_summary_semantics

    assert :source_report_timeline_activity_state_routing_maps in source_report_summary_semantics

    assert :source_report_timeline_activity_status_state_routing_maps in source_report_summary_semantics

    assert :source_report_timeline_activity_approval_state_routing_maps in source_report_summary_semantics

    assert :source_report_timeline_activity_lifecycle_state_routing_maps in source_report_summary_semantics

    assert :source_report_timeline_activity_precondition_routing_maps in source_report_summary_semantics

    assert :source_report_timeline_dependency_impact_routing_maps in source_report_summary_semantics

    assert :source_report_timeline_publication_routing_maps in source_report_summary_semantics

    assert :source_report_timeline_transition_application_routing_count_maps in source_report_summary_semantics

    assert :source_report_timeline_transition_application_selected_activity_routing_maps in source_report_summary_semantics

    assert :source_report_command_window_direction_routing_maps in source_report_summary_semantics

    assert :source_report_command_window_feedback_count_maps in source_report_summary_semantics

    assert :source_report_command_window_required_action_routing_maps in source_report_summary_semantics

    assert :source_report_maneuver_review_feedback_count_maps in source_report_summary_semantics

    assert :source_report_maneuver_review_maneuver_routing_maps in source_report_summary_semantics

    assert :source_report_maneuver_review_required_action_routing_maps in source_report_summary_semantics

    assert :source_report_provider_counteroffer_routing_maps in source_report_summary_semantics

    assert :source_report_provider_counteroffer_review_summary_maps in source_report_summary_semantics

    assert :source_report_provider_counteroffer_import_readiness_maps in source_report_summary_semantics

    assert :source_report_freshness_status_count_maps in source_report_summary_semantics

    assert :source_report_refresh_budget_count_maps in source_report_summary_semantics

    assert :source_report_schema_validation_count_maps in source_report_summary_semantics

    assert :source_report_quality_gate_import_readiness_maps in source_report_summary_semantics

    assert :source_report_quality_gate_row_derived_counts in source_report_summary_semantics

    assert :source_report_operational_readiness_branch_replay_summary in source_report_summary_semantics

    assert :source_report_quality_gate_branch_replay_summary in source_report_summary_semantics

    assert :source_report_model_acceptance_branch_replay_summary in source_report_summary_semantics

    assert :source_report_validation_safety_case_branch_replay_summary in source_report_summary_semantics

    assert :source_report_freshness_branch_replay_summary in source_report_summary_semantics

    assert :source_report_refresh_budget_branch_replay_summary in source_report_summary_semantics

    assert :source_report_schema_validation_branch_replay_summary in source_report_summary_semantics

    assert :source_report_candidate_diff_branch_replay_summary in source_report_summary_semantics

    assert :source_report_candidate_rejection_branch_replay_summary in source_report_summary_semantics

    assert :source_report_provider_counteroffer_branch_replay_summary in source_report_summary_semantics

    assert :source_report_contact_contention_branch_replay_summary in source_report_summary_semantics

    assert :source_report_contact_contention_resolution_branch_replay_summary in source_report_summary_semantics

    assert :source_report_contact_allocation_branch_replay_summary in source_report_summary_semantics

    assert :source_report_link_capacity_branch_replay_summary in source_report_summary_semantics

    assert :source_report_contact_filter_branch_replay_summary in source_report_summary_semantics

    assert :source_report_resource_filter_branch_replay_summary in source_report_summary_semantics

    assert :source_report_resource_projection_branch_replay_summary in source_report_summary_semantics

    assert :source_report_storage_downlink_pressure_branch_replay_summary in source_report_summary_semantics

    assert :source_report_storage_downlink_pressure_provider_routing_maps in source_report_summary_semantics

    assert :source_report_station_calendar_branch_replay_summary in source_report_summary_semantics

    assert :source_report_station_reservation_branch_replay_summary in source_report_summary_semantics

    assert :source_report_station_reservation_direction_routing_maps in source_report_summary_semantics

    assert :source_report_command_window_branch_replay_summary in source_report_summary_semantics

    assert :source_report_maneuver_review_branch_replay_summary in source_report_summary_semantics

    assert :source_report_contact_intent_branch_replay_summary in source_report_summary_semantics

    assert :source_report_timeline_activity_state_branch_replay_summary in source_report_summary_semantics

    assert :source_report_timeline_activity_status_state_branch_replay_summary in source_report_summary_semantics

    assert :source_report_timeline_activity_approval_state_branch_replay_summary in source_report_summary_semantics

    assert :source_report_timeline_activity_lifecycle_state_branch_replay_summary in source_report_summary_semantics

    assert :source_report_timeline_activity_precondition_branch_replay_summary in source_report_summary_semantics

    assert :source_report_timeline_preservation_branch_replay_summary in source_report_summary_semantics

    assert :source_report_timeline_integrity_routing_maps in source_report_summary_semantics

    assert :source_report_timeline_integrity_branch_replay_summary in source_report_summary_semantics

    assert :source_report_timeline_diff_branch_replay_summary in source_report_summary_semantics

    assert :source_report_timeline_dependency_impact_branch_replay_summary in source_report_summary_semantics

    assert :source_report_timeline_publication_branch_replay_summary in source_report_summary_semantics

    assert :source_report_timeline_transition_application_branch_replay_summary in source_report_summary_semantics

    assert :source_report_objective_gap_branch_replay_summary in source_report_summary_semantics

    assert :source_report_constraint_branch_replay_summary in source_report_summary_semantics

    assert :source_report_timeline_feedback_activity_routing_maps in source_report_summary_semantics

    assert :source_report_timeline_feedback_import_status_routing_maps in source_report_summary_semantics

    assert :source_report_timeline_feedback_branch_replay_summary in source_report_summary_semantics

    assert :source_report_operational_timeline_activity_routing_maps in source_report_summary_semantics

    assert :source_report_operational_timeline_row_routing_maps in source_report_summary_semantics

    assert :source_report_operational_timeline_branch_replay_summary in source_report_summary_semantics

    assert :source_report_operational_readiness_routing_maps in source_report_summary_semantics

    assert :source_report_model_acceptance_routing_maps in source_report_summary_semantics
    assert :source_report_validation_safety_case_routing_maps in source_report_summary_semantics

    assert :resource_margin_aliases in row_semantics
    assert :resource_power_margin_source_aliases in row_semantics
    assert :resource_availability_aliases in row_semantics

    assert resource_margin_aliases == %{
             "storage_margin" => ["storage_capacity_margin"],
             "downlink_margin" => ["downlink_capacity_margin"],
             "battery_state_of_charge" => ["battery_soc"]
           }

    assert resource_power_margin_source_aliases == [
             "battery_state_of_charge",
             "battery_soc"
           ]

    assert resource_availability_aliases == %{
             "payload_available" => ["payload_available?", "payload_status"],
             "antenna_available" => ["antenna_available?", "antenna_status"],
             "spacecraft_available" => [
               "spacecraft_available?",
               "spacecraft_availability",
               "spacecraft_status"
             ]
           }

    assert "enabled" in resource_availability_true_tokens
    assert "operational" in resource_availability_true_tokens
    assert "outage" in resource_availability_false_tokens
    assert "maintenance" in resource_availability_false_tokens
    assert provider_direction_aliases["s_band_command"] == "command"
    assert provider_direction_aliases["downlinking"] == "downlink"
    assert provider_direction_aliases["tracking_pass"] == "tracking"
    assert station_unavailable_aliases == ["outage", "down", "offline"]

    assert station_unavailable_tokens == [
             "unavailable",
             "maintenance",
             "outage",
             "down",
             "offline"
           ]

    assert station_availability_precedence == %{
             "unavailable" => 5,
             "maintenance" => 5,
             "reserved" => 4,
             "reduced_capacity" => 3,
             "available" => 1
           }

    assert ["availability"] in station_capacity_fraction_paths
    assert ["capacity_fraction"] in station_capacity_fraction_paths
    assert ["station_capacity_fraction"] in station_capacity_fraction_paths
    assert ["capacity_pack_capacity_fraction"] in station_capacity_fraction_paths
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
    assert ["activity_context", "capacity_percent"] in station_capacity_percent_paths
    assert %{unit: :fraction, path: ["capacity_fraction"]} in station_capacity_value_paths
    assert %{unit: :fraction, path: ["station_capacity_fraction"]} in station_capacity_value_paths

    assert %{unit: :fraction, path: ["capacity_pack_capacity_fraction"]} in station_capacity_value_paths

    assert %{unit: :percent, path: ["capacity_percent"]} in station_capacity_value_paths
    assert %{unit: :percent, path: ["station_capacity_percent"]} in station_capacity_value_paths

    assert %{unit: :percent, path: ["throughput_model", "capacity_percent"]} in station_capacity_value_paths

    assert %{unit: :fraction, path: ["availability"]} in station_capacity_value_paths

    assert %{unit: :fraction, path: ["capacity_model", "availability"]} in station_capacity_value_paths

    assert "source_window_id" in prior_candidate_optional_stable_identity_fields
    assert "station_calendar_provider_entry_id" in prior_candidate_optional_stable_identity_fields
    assert "station_reservation_id" in prior_candidate_optional_stable_identity_fields
    assert "station_calendar_overlap_entry_ids" in station_calendar_id_list_fields
    assert "station_calendar_ambiguous_entry_ids" in station_calendar_id_list_fields
    assert "station_calendar_reservation_ids" in station_calendar_id_list_fields
    assert "station_calendar_reservation_expires_at_s" in station_calendar_number_list_fields
    assert :event_detector in event_timing_keys
    assert :event_time_tolerance_s in event_timing_keys
    assert :confidence in event_timing_keys

    assert "missing_dependency_activity_ids" in operational_timeline_dependency_integrity_issue_fields

    assert "dependency_cycle_timeline_ids" in operational_timeline_dependency_integrity_issue_fields

    assert "exclusivity_violation_activity_ids" in operational_timeline_exclusivity_integrity_issue_fields

    assert "exclusivity_violation_group" in operational_timeline_exclusivity_integrity_issue_fields

    assert Enum.sort(
             operational_timeline_dependency_integrity_issue_fields ++
               operational_timeline_exclusivity_integrity_issue_fields
           ) == Enum.sort(operational_timeline_integrity_issue_fields)

    assert :canonical_event_order_identity_generation in row_semantics
    assert :event_timing_metadata_keys in row_semantics
    assert :prior_candidate_optional_stable_identity_fields in row_semantics
    assert :direction_scoped_station_calendar in row_semantics
    assert :station_calendar_id_list_fields in row_semantics
    assert :station_calendar_reservation_expiration_context in row_semantics
    assert :provider_direction_aliases in row_semantics
    assert :station_reservation_owner_match in row_semantics
    assert :station_reservation_match_status_counts in row_semantics
    assert :operational_feedback_unit_interval_input_validation in row_semantics
    assert :operational_feedback_invalid_entry_review in row_semantics
    assert :station_capacity_value_paths in row_semantics
    assert :source_operational_timeline_report_activity_feedback in row_semantics
    assert :source_operational_timeline_report_integrity_provenance in row_semantics
    assert :operational_timeline_integrity_issue_fields in row_semantics
    assert :source_timeline_feedback_report_feedback in row_semantics
    assert :source_timeline_diff_removed_downlink_feedback in row_semantics
    assert :source_timeline_diff_removed_observation_objectives in row_semantics
    assert :source_timeline_diff_changed_downlink_shortfall_feedback in row_semantics
    assert :source_timeline_diff_changed_contact_success_feedback in row_semantics
    assert :source_timeline_diff_changed_observation_objectives in row_semantics
    assert :source_timeline_diff_changed_observation_quality_feedback in row_semantics
    assert :source_timeline_diff_changed_command_success_feedback in row_semantics
    assert :source_timeline_diff_changed_maneuver_success_feedback in row_semantics
    assert :source_timeline_transition_application_replay in row_semantics
    assert :source_timeline_diff_review_import_replay in row_semantics
    assert :source_realized_activity_feedback_replay in row_semantics
    assert :source_realized_feedback_review_import_replay in row_semantics
    assert :source_command_window_report_command_success_feedback in row_semantics
    assert :source_maneuver_review_report_maneuver_feedback in row_semantics
    assert :source_timeline_feedback_report_input_provenance in row_semantics
    assert :source_operational_timeline_report_input_provenance in row_semantics
    assert :source_timeline_integrity_report_input_provenance in row_semantics
    assert :source_timeline_activity_state_input_provenance in row_semantics
    assert :source_timeline_activity_lifecycle_state_input_provenance in row_semantics
    assert :source_timeline_preservation_input_provenance in row_semantics
    assert :source_timeline_diff_report_input_provenance in row_semantics
    assert :source_timeline_diff_summary_input_provenance in row_semantics
    assert :source_timeline_lifecycle_state_summary_input_provenance in row_semantics
    assert :source_timeline_dependency_impact_summary_input_provenance in row_semantics
    assert :source_timeline_transition_application_report_input_provenance in row_semantics
    assert :source_timeline_transition_application_summary_input_provenance in row_semantics
    assert :source_command_window_report_input_provenance in row_semantics
    assert :source_maneuver_review_report_input_provenance in row_semantics
    assert :source_objective_satisfaction_report_objectives in row_semantics
    assert :source_objective_tradeoff_report_objectives in row_semantics
    assert :source_score_term_report_objectives in row_semantics
    assert :source_constraint_report_downlink_objectives in row_semantics
    assert :source_resource_projection_report_downlink_objectives in row_semantics
    assert :source_contact_contention_resolution_report_downlink_objectives in row_semantics
    assert :source_contact_allocation_report_downlink_objectives in row_semantics
    assert :source_link_capacity_report_downlink_objectives in row_semantics
    assert :source_link_capacity_report_station_throughput_feedback in row_semantics
    assert :source_station_calendar_report_station_feedback in row_semantics
    assert :source_contact_intent_station_feedback in row_semantics
    assert :source_contact_intent_input_provenance in row_semantics
    assert :source_contact_intent_summary_input_provenance in row_semantics
    assert :source_contact_filter_report_station_feedback in row_semantics
    assert :source_contact_allocation_report_station_feedback in row_semantics
    assert :contact_allocation_policy_handoff in row_semantics
    assert :contact_allocation_reduced_capacity_policy_handoff in row_semantics
    assert :source_resource_projection_report_resource_feedback in row_semantics
    assert :source_resource_filter_report_resource_feedback in row_semantics
    assert :source_candidate_diff_report_input_provenance in row_semantics
    assert :source_candidate_rejection_report_input_provenance in row_semantics
    assert :source_provider_counteroffer_report_input_provenance in row_semantics
    assert :source_provider_counteroffer_review_summary_input_provenance in row_semantics
    assert :source_provider_counteroffer_plan_impact_summary_input_provenance in row_semantics
    assert :source_freshness_report_input_provenance in row_semantics
    assert :source_refresh_budget_report_input_provenance in row_semantics
    assert :source_operational_readiness_report_input_provenance in row_semantics
    assert :source_operational_import_eligibility_summary_input_provenance in row_semantics
    assert :source_operational_readiness_gate_summary_input_provenance in row_semantics
    assert :source_operational_execution_boundary_summary_input_provenance in row_semantics
    assert :source_quality_gate_report_input_provenance in row_semantics
    assert :source_model_acceptance_report_input_provenance in row_semantics
    assert :source_validation_safety_case_summary_input_provenance in row_semantics
    assert :source_operational_readiness_review_import_replay in row_semantics
    assert :source_timeline_dependency_impact_review_import_replay in row_semantics
    assert :source_schema_validation_report_input_provenance in row_semantics
    assert :source_schema_validation_batch_report_input_provenance in row_semantics
    assert :source_station_calendar_report_input_provenance in row_semantics
    assert :source_station_calendar_precedence_summary_input_provenance in row_semantics
    assert :source_constraint_report_input_provenance in row_semantics
    assert :source_objective_satisfaction_report_input_provenance in row_semantics
    assert :source_objective_tradeoff_report_input_provenance in row_semantics
    assert :source_score_term_report_input_provenance in row_semantics
    assert :source_resource_projection_report_input_provenance in row_semantics
    assert :source_resource_projection_flow_summary_input_provenance in row_semantics
    assert :source_resource_filter_report_input_provenance in row_semantics
    assert :source_resource_filter_summary_input_provenance in row_semantics
    assert :source_contact_filter_report_input_provenance in row_semantics
    assert :source_link_capacity_report_input_provenance in row_semantics
    assert :source_link_capacity_summary_input_provenance in row_semantics
    assert :source_relay_data_path_summary_input_provenance in row_semantics
    assert :source_contact_allocation_report_input_provenance in row_semantics

    assert :source_contact_allocation_provider_reservation_request_summary_input_provenance in row_semantics

    assert :source_contact_contention_resolution_report_input_provenance in row_semantics
    assert :source_contact_contention_resolution_summary_input_provenance in row_semantics
    assert :source_report_summary in row_semantics
    assert :mission_state_target_resource_and_ground_network_fallbacks in row_semantics
    assert :mission_state_spacecraft_identity_precedence in row_semantics
    assert :accepted_planning_state_spacecraft_state_fallback in row_semantics
    assert :accepted_planning_state_target_fallback in row_semantics
    assert :accepted_planning_state_ground_network_fallback in row_semantics
    assert :accepted_planning_state_resource_summary_fallback in row_semantics
    assert :mission_state_current_epoch_fallback in row_semantics
    assert :accepted_planning_state_current_epoch_fallback in row_semantics
    assert :mission_state_remaining_horizon_fallback in row_semantics
    assert :accepted_planning_state_remaining_horizon_fallback in row_semantics
    assert :mission_state_station_calendar_fallback in row_semantics
    assert :mission_state_station_calendar_provider_list_fallback in row_semantics
    assert :accepted_planning_state_station_calendar_fallback in row_semantics
    assert :accepted_planning_state_station_calendar_provider_list_fallback in row_semantics
    assert :station_calendar_provider_precedence in row_semantics
    assert :run_input_source_provenance in row_semantics
    assert :source_report_summary_routing_maps in row_semantics
    assert :requires_precomputed_refreshed_event_results in known_limits
    assert :candidate_budget_is_deterministic_post_filter_selection in known_limits
    assert :artifact_only_no_schedule_mutation in known_limits
  end
end
