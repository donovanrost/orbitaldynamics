Code.require_file("support.exs", __DIR__)

Code.require_file(
  "../../support/campaign_planner/strategy_recommendation_pressure_handoff_case.ex",
  __DIR__
)

defmodule OrbitalDynamics.CampaignPlanner.StrategyRecommendationPressureHandoffExecutionContextTest do
  use OrbitalDynamics.CampaignPlanner.StrategyRecommendationPressureHandoffCase

  @relay_data_path_context_contracts [
    {"risk type", "relay_data_path_risk_types", ["type", "risk_type"],
     ["relay_data_path_pressure"], ["stale_relay_data_path_pressure"]},
    {"ground-station identity", "relay_data_path_ground_station_ids", "ground_station_id",
     ["dss_14"], ["stale_dss_14"]},
    {"route identities", "relay_data_path_route_ids", ["route_id", "route_ids"],
     ["relay_route_review", "relay_route_backup"], ["stale_relay_route"]},
    {"source-spacecraft identity", "relay_data_path_source_spacecraft_ids",
     ["source_spacecraft_id", "source_spacecraft_ids"], ["leo_1"], ["stale_leo_1"]},
    {"relay-spacecraft identity", "relay_data_path_relay_spacecraft_ids",
     ["relay_spacecraft_ids"], ["relay_a"], ["stale_relay"]},
    {"relay-chain identity", "relay_data_path_relay_chain_spacecraft_ids",
     ["relay_chain_spacecraft_ids"], ["relay_a", "relay_b"], ["stale_relay_chain"]},
    {"relay-hop count", "relay_data_path_relay_hop_count_values", "relay_hop_count", [2], [3]},
    {"ground-downlink contact identities", "relay_data_path_ground_downlink_contact_ids",
     ["ground_downlink_contact_id", "ground_downlink_contact_ids"],
     ["downlink_relay_review", "downlink_relay_backup"], ["stale_downlink_relay"]},
    {"custody status", "relay_data_path_custody_statuses", "custody_status", ["missing_ack"],
     ["stale_custody"]},
    {"latency", "relay_data_path_latency_values_s", "latency_s", [500.0], [501.0]},
    {"latency limit", "relay_data_path_latency_limit_values_s", "latency_limit_s", [300.0],
     [301.0]},
    {"latency status", "relay_data_path_latency_statuses", "latency_status", ["exceeds_limit"],
     ["stale_latency"]},
    {"risk status", "relay_data_path_risk_statuses", "risk_status", ["high"], ["stale_risk"]},
    {"risk reasons", "relay_data_path_risk_reasons", ["risk_reasons"],
     ["custody_missing_ack", "latency_exceeds_limit"], ["stale_risk_reason"]},
    {"product identities", "relay_data_path_product_ids", ["product_ids"], ["product_relay"],
     ["stale_product"]},
    {"collection identities", "relay_data_path_collection_ids", ["collection_ids"],
     ["collection_relay"], ["stale_collection"]},
    {"route count", "relay_data_path_route_count_values", "route_count", [2], [3]},
    {"relay-route count", "relay_data_path_relay_route_count_values", "relay_route_count", [2],
     [3]},
    {"direct-downlink route count", "relay_data_path_direct_downlink_route_count_values",
     "direct_downlink_route_count", [0], [1]},
    {"custody-status counts", "relay_data_path_custody_status_count_maps",
     "custody_status_counts", [%{"missing_ack" => 2}], [%{"missing_ack" => 3}]},
    {"latency-status counts", "relay_data_path_latency_status_count_maps",
     "latency_status_counts", [%{"exceeds_limit" => 2}], [%{"exceeds_limit" => 3}]},
    {"risk-status counts", "relay_data_path_risk_status_count_maps", "risk_status_counts",
     [%{"high" => 2}], [%{"high" => 3}]},
    {"routes by custody status", "relay_data_path_route_ids_by_custody_status",
     "route_ids_by_custody_status",
     [%{"missing_ack" => ["relay_route_review", "relay_route_backup"]}],
     [%{"missing_ack" => ["stale_relay_route"]}]},
    {"routes by latency status", "relay_data_path_route_ids_by_latency_status",
     "route_ids_by_latency_status",
     [%{"exceeds_limit" => ["relay_route_review", "relay_route_backup"]}],
     [%{"exceeds_limit" => ["stale_relay_route"]}]},
    {"routes by risk status", "relay_data_path_route_ids_by_risk_status",
     "route_ids_by_risk_status", [%{"high" => ["relay_route_review", "relay_route_backup"]}],
     [%{"high" => ["stale_relay_route"]}]},
    {"routes by ground station", "relay_data_path_route_ids_by_ground_station_id",
     "route_ids_by_ground_station_id",
     [%{"dss_14" => ["relay_route_review", "relay_route_backup"]}],
     [%{"dss_14" => ["stale_relay_route"]}]},
    {"feedback source", "relay_data_path_feedback_sources", "feedback_source",
     ["mission_state.source_relay_data_path_summary.rows"],
     ["mission_state.stale_relay_data_path_summary.rows"]},
    {"feedback scope", "relay_data_path_feedback_scopes", "feedback_scope", ["link_capacity"],
     ["stale_link_capacity"]},
    {"feedback key", "relay_data_path_feedback_keys", "feedback_key", ["relay_route_review"],
     ["stale_relay_route"]},
    {"trust boundary", "relay_data_path_trust_boundaries", "trust_boundary",
     ["mission_state_relay_data_path_summary"], ["stale_relay_data_path_summary"]},
    {"derivation reasons", "relay_data_path_derivation_reasons", ["derivation_reasons"],
     [
       "relay_data_path_custody_missing_ack",
       "relay_data_path_latency_exceeds_limit",
       "relay_data_path_risk_high"
     ], ["stale_relay_derivation"]},
    {"safety assumptions", "relay_data_path_assumption_maps", "assumptions",
     [
       %{
         "execution_boundary" => "artifact_only_no_relay_scheduling_or_schedule_mutation",
         "operator_authority" => "not_granted_by_summary",
         "provider_reservation" => "not_performed"
       }
     ],
     [
       %{
         "execution_boundary" => "stale_execution_boundary",
         "operator_authority" => "not_granted_by_summary",
         "provider_reservation" => "not_performed"
       }
     ]}
  ]

  for {description, field, source_field, expected_value, stale_value} <-
        @relay_data_path_context_contracts do
    test "relay-data-path #{description} remains source exact across handoffs", %{
      handoff: handoff
    } do
      assert_risk_context_contract(
        handoff,
        unquote(field),
        {"type", "relay_data_path_pressure"},
        unquote(Macro.escape(source_field)),
        unquote(Macro.escape(expected_value)),
        unquote(Macro.escape(stale_value))
      )
    end
  end

  @maneuver_execution_uncertainty_context_contracts [
    {"risk type", "maneuver_execution_uncertainty_risk_types", ["type", "risk_type"],
     ["maneuver_execution_uncertainty_high"], ["maneuver_execution_uncertainty_missing"]},
    {"activity identity", "maneuver_execution_uncertainty_activity_ids", "activity_id",
     ["burn_uncertain_review"], ["stale_burn"]},
    {"timeline identity", "maneuver_execution_uncertainty_timeline_ids", "timeline_id",
     ["timeline:maneuver:burn_uncertain_review"], ["timeline:maneuver:stale_burn"]},
    {"maneuver identity", "maneuver_execution_uncertainty_maneuver_ids", "maneuver_id",
     ["burn_uncertain_review"], ["stale_burn"]},
    {"scenario identity", "maneuver_execution_uncertainty_scenario_ids", "scenario_id", ["leo_1"],
     ["stale_leo_1"]},
    {"source-activity identity", "maneuver_execution_uncertainty_source_activity_ids",
     ["source_activity_id", "source_activity_ids"],
     ["burn_uncertain_source", "burn_uncertain_review"], ["stale_burn_source"]},
    {"replacement-activity identity", "maneuver_execution_uncertainty_replacement_activity_ids",
     "replacement_activity_id", ["burn_uncertain_review"], ["stale_burn_replacement"]},
    {"status", "maneuver_execution_uncertainty_statuses", "execution_uncertainty_status",
     ["declared"], ["stale_status"]},
    {"source", "maneuver_execution_uncertainty_sources", "execution_uncertainty_source",
     ["ops_covariance_review"], ["stale_covariance_source"]},
    {"uncertainty map", "maneuver_execution_uncertainty_maps", "execution_uncertainty",
     [
       %{
         "delta_v_3sigma_km_s" => [0.0, 0.003, 0.004],
         "source" => "ops_covariance_review",
         "timing_3sigma_s" => 75.0
       }
     ],
     [
       %{
         "delta_v_3sigma_km_s" => [0.0, 0.003, 0.005],
         "source" => "ops_covariance_review",
         "timing_3sigma_s" => 75.0
       }
     ]},
    {"timing three-sigma", "maneuver_execution_uncertainty_timing_3sigma_values_s",
     "timing_3sigma_s", [75.0], [76.0]},
    {"timing three-sigma threshold",
     "maneuver_execution_uncertainty_timing_3sigma_threshold_values_s",
     "timing_3sigma_threshold_s", [60.0], [61.0]},
    {"delta-v three-sigma vector", "maneuver_execution_uncertainty_delta_v_3sigma_vectors_km_s",
     "delta_v_3sigma_km_s", [[0.0, 0.003, 0.004]], [[0.0, 0.003, 0.005]]},
    {"delta-v three-sigma magnitude",
     "maneuver_execution_uncertainty_delta_v_3sigma_magnitude_values_km_s",
     "delta_v_3sigma_magnitude_km_s", [0.005], [0.006]},
    {"delta-v three-sigma magnitude threshold",
     "maneuver_execution_uncertainty_delta_v_3sigma_magnitude_threshold_values_km_s",
     "delta_v_3sigma_magnitude_threshold_km_s", [0.002], [0.003]},
    {"start timing", "maneuver_execution_uncertainty_start_values_s", "starts_at_s", [620.0],
     [621.0]},
    {"end timing", "maneuver_execution_uncertainty_end_values_s", "ends_at_s", [620.0], [621.0]},
    {"changed fields", "maneuver_execution_uncertainty_changed_fields", ["changed_fields"],
     ["execution_uncertainty"], ["stale_uncertainty"]},
    {"required operator action", "maneuver_execution_uncertainty_required_operator_actions",
     "required_operator_action", ["review_maneuver_execution_uncertainty"],
     ["stale_operator_action"]},
    {"operator-review requirement",
     "maneuver_execution_uncertainty_requires_operator_review_values", "requires_operator_review",
     [true], [false]},
    {"feedback source", "maneuver_execution_uncertainty_feedback_sources", "feedback_source",
     ["mission_state.source_maneuver_review.rows"], ["mission_state.stale_maneuver_review.rows"]},
    {"feedback scope", "maneuver_execution_uncertainty_feedback_scopes", "feedback_scope",
     ["maneuver_execution_uncertainty"], ["stale_maneuver_execution_uncertainty"]},
    {"feedback key", "maneuver_execution_uncertainty_feedback_keys", "feedback_key",
     ["burn_uncertain_review"], ["stale_burn"]},
    {"trust boundary", "maneuver_execution_uncertainty_trust_boundaries", "trust_boundary",
     ["mission_state_maneuver_review"], ["stale_maneuver_review"]},
    {"derivation reasons", "maneuver_execution_uncertainty_derivation_reasons",
     ["derivation_reasons"], ["maneuver_review_execution_uncertainty_pressure"],
     ["stale_maneuver_uncertainty_derivation"]}
  ]

  for {description, field, source_field, expected_value, stale_value} <-
        @maneuver_execution_uncertainty_context_contracts do
    test "maneuver-execution uncertainty #{description} remains source exact across handoffs", %{
      handoff: handoff
    } do
      assert_risk_context_contract(
        handoff,
        unquote(field),
        {"feedback_scope", "maneuver_execution_uncertainty"},
        unquote(Macro.escape(source_field)),
        unquote(Macro.escape(expected_value)),
        unquote(Macro.escape(stale_value))
      )
    end
  end

  @execution_success_feedback_context_contracts [
    {"risk types", "execution_success_feedback_risk_types", ["type", "risk_type"],
     ["command_success_rate_low", "maneuver_success_rate_low"], ["stale_success_rate_low"]},
    {"activity identities", "execution_success_feedback_activity_ids", "activity_id",
     ["cmd_success_review", "burn_success_review"], ["stale_success_activity"]},
    {"scenario identity", "execution_success_feedback_scenario_ids", "scenario_id", ["leo_1"],
     ["stale_leo_1"]},
    {"timeline identities", "execution_success_feedback_timeline_ids", "timeline_id",
     ["timeline:cmd_success_review", "timeline:burn_success_review"], ["timeline:stale_success"]},
    {"source-activity identities", "execution_success_feedback_source_activity_ids",
     ["source_activity_id", "source_activity_ids"],
     ["cmd_success_source", "cmd_success_review", "burn_success_source", "burn_success_review"],
     ["stale_success_source"]},
    {"replacement-activity identities", "execution_success_feedback_replacement_activity_ids",
     "replacement_activity_id", ["cmd_success_review", "burn_success_review"],
     ["stale_success_replacement"]},
    {"command success factor", "execution_success_feedback_command_success_factor_values",
     "command_success_factor", [0.25], [0.5]},
    {"maneuver success factor", "execution_success_feedback_maneuver_success_factor_values",
     "maneuver_success_factor", [0.4], [0.5]},
    {"command result", "execution_success_feedback_command_results", "command_result",
     ["timeout"], ["stale_command_result"]},
    {"maneuver result", "execution_success_feedback_maneuver_results", "maneuver_result",
     ["accepted, failed"], ["stale_maneuver_result"]},
    {"realized status", "execution_success_feedback_realized_statuses", "realized_status",
     ["failed"], ["stale_realized_status"]},
    {"ground-station identity", "execution_success_feedback_ground_station_ids",
     "ground_station_id", ["equator_prime"], ["stale_equator_prime"]},
    {"planned ground-station identity", "execution_success_feedback_planned_ground_station_ids",
     "planned_ground_station_id", ["polar_prime"], ["stale_polar_prime"]},
    {"realized ground-station identity", "execution_success_feedback_realized_ground_station_ids",
     "realized_ground_station_id", ["equator_prime"], ["stale_equator_prime"]},
    {"ground-station match status", "execution_success_feedback_ground_station_match_statuses",
     "ground_station_match_status", ["mismatch"], ["stale_match"]},
    {"direction", "execution_success_feedback_directions", "direction", ["command"],
     ["stale_direction"]},
    {"planned direction", "execution_success_feedback_planned_directions", "planned_direction",
     ["uplink"], ["stale_planned_direction"]},
    {"realized direction", "execution_success_feedback_realized_directions", "realized_direction",
     ["command"], ["stale_realized_direction"]},
    {"direction match status", "execution_success_feedback_direction_match_statuses",
     "direction_match_status", ["mismatch"], ["stale_match"]},
    {"source-window identity", "execution_success_feedback_source_window_ids", "source_window_id",
     ["window_equator_command"], ["stale_source_window"]},
    {"planned source-window identity", "execution_success_feedback_planned_source_window_ids",
     "planned_source_window_id", ["window_polar_uplink"], ["stale_planned_window"]},
    {"realized source-window identity", "execution_success_feedback_realized_source_window_ids",
     "realized_source_window_id", ["window_equator_command"], ["stale_realized_window"]},
    {"source-window match status", "execution_success_feedback_source_window_match_statuses",
     "source_window_match_status", ["mismatch"], ["stale_match"]},
    {"command identity mismatch fields",
     "execution_success_feedback_command_identity_mismatch_fields",
     ["command_identity_mismatch_fields"], ["direction", "ground_station", "source_window"],
     ["stale_identity_field"]},
    {"start timing", "execution_success_feedback_start_values_s", "starts_at_s", [700.0, 760.0],
     [701.0]},
    {"end timing", "execution_success_feedback_end_values_s", "ends_at_s", [730.0, 760.0],
     [731.0]},
    {"changed fields", "execution_success_feedback_changed_fields", ["changed_fields"],
     ["command_result", "command_success_factor", "maneuver_result", "maneuver_success_factor"],
     ["stale_changed_field"]},
    {"status transitions", "execution_success_feedback_status_transition_maps",
     "status_transition",
     [
       %{
         "field" => "status",
         "from" => "planned",
         "requires_operator_review" => true,
         "to" => "failed",
         "transition_category" => "terminal_exception",
         "transition_reason" => "command execution timed out",
         "transition_type" => "status_changed"
       },
       %{
         "field" => "status",
         "from" => "planned",
         "requires_operator_review" => true,
         "to" => "failed",
         "transition_category" => "terminal_exception",
         "transition_reason" => "maneuver failed after acceptance",
         "transition_type" => "status_changed"
       }
     ],
     [
       %{
         "field" => "status",
         "from" => "planned",
         "requires_operator_review" => true,
         "to" => "stale",
         "transition_category" => "terminal_exception",
         "transition_reason" => "stale transition",
         "transition_type" => "status_changed"
       }
     ]},
    {"transition type", "execution_success_feedback_transition_types", "transition_type",
     ["status_changed"], ["stale_transition_type"]},
    {"transition category", "execution_success_feedback_transition_categories",
     "transition_category", ["terminal_exception"], ["stale_transition_category"]},
    {"transition reasons", "execution_success_feedback_transition_reasons", "transition_reason",
     ["command execution timed out", "maneuver failed after acceptance"],
     ["stale_transition_reason"]},
    {"required operator actions", "execution_success_feedback_required_operator_actions",
     "required_operator_action",
     ["review_command_execution_feedback", "review_maneuver_execution_feedback"],
     ["stale_operator_action"]},
    {"operator-review requirement", "execution_success_feedback_requires_operator_review_values",
     "requires_operator_review", [true], [false]},
    {"feedback sources", "execution_success_feedback_feedback_sources", "feedback_source",
     [
       "mission_state.source_command_window_report.rows",
       "mission_state.source_maneuver_review.rows"
     ], ["mission_state.stale_execution_feedback.rows"]},
    {"feedback scopes", "execution_success_feedback_feedback_scopes", "feedback_scope",
     ["command_execution_feedback", "maneuver_execution_feedback"], ["stale_execution_feedback"]},
    {"feedback keys", "execution_success_feedback_feedback_keys", "feedback_key",
     ["cmd_success_review", "burn_success_review"], ["stale_success_feedback"]},
    {"trust boundaries", "execution_success_feedback_trust_boundaries", "trust_boundary",
     ["mission_state_command_window_report", "mission_state_maneuver_review"],
     ["stale_execution_feedback_boundary"]},
    {"derivation reasons", "execution_success_feedback_derivation_reasons",
     ["derivation_reasons"],
     ["command_window_execution_feedback_pressure", "maneuver_review_success_feedback_pressure"],
     ["stale_execution_feedback_derivation"]}
  ]

  for {description, field, source_field, expected_value, stale_value} <-
        @execution_success_feedback_context_contracts do
    test "execution-success feedback #{description} remains source exact across handoffs", %{
      handoff: handoff
    } do
      assert_risk_context_contract(
        handoff,
        unquote(field),
        {"type", ["command_success_rate_low", "maneuver_success_rate_low"]},
        unquote(Macro.escape(source_field)),
        unquote(Macro.escape(expected_value)),
        unquote(Macro.escape(stale_value))
      )
    end
  end

  @timeline_dependency_impact_context_contracts [
    {"activity identity", "timeline_dependency_impact_activity_ids", "activity_id",
     ["cmd_dependency_review"], ["stale_dependency_activity"]},
    {"timeline identity", "timeline_dependency_impact_timeline_ids", "timeline_id",
     ["timeline:cmd_dependency_review"], ["timeline:stale_dependency"]},
    {"scope", "timeline_dependency_impact_scopes", "dependency_impact_scope", ["source"],
     ["stale_scope"]},
    {"status", "timeline_dependency_impact_statuses", "dependency_impact_status",
     ["review_required"], ["stale_status"]},
    {"required operator action", "timeline_dependency_impact_required_operator_actions",
     "required_operator_action", ["review_timeline_dependency_impact"],
     ["stale_operator_action"]},
    {"operator-action reason", "timeline_dependency_impact_operator_action_reasons",
     "operator_action_reason", ["dependency_link_impacted_by_timeline_change"],
     ["stale_action_reason"]},
    {"dependency activity identities", "timeline_dependency_impact_dependency_activity_ids",
     ["dependency_activity_ids"], ["health_check"], ["stale_dependency_activity"]},
    {"dependency timeline identities", "timeline_dependency_impact_dependency_timeline_ids",
     ["dependency_timeline_ids"], ["timeline:health_check"], ["timeline:stale_dependency"]},
    {"exclusive activity identities", "timeline_dependency_impact_exclusive_with_activity_ids",
     ["exclusive_with_activity_ids"], ["downlink_conflict"], ["stale_exclusive_activity"]},
    {"exclusive timeline identities", "timeline_dependency_impact_exclusive_with_timeline_ids",
     ["exclusive_with_timeline_ids"], ["timeline:downlink_conflict"],
     ["timeline:stale_exclusive"]},
    {"impacted dependency activity identities",
     "timeline_dependency_impact_impacted_dependency_activity_ids",
     ["impacted_dependency_activity_ids"], ["health_check"], ["stale_impacted_dependency"]},
    {"impacted dependency timeline identities",
     "timeline_dependency_impact_impacted_dependency_timeline_ids",
     ["impacted_dependency_timeline_ids"], ["timeline:health_check"],
     ["timeline:stale_impacted_dependency"]},
    {"impacted exclusive activity identities",
     "timeline_dependency_impact_impacted_exclusive_with_activity_ids",
     ["impacted_exclusive_with_activity_ids"], ["downlink_conflict"],
     ["stale_impacted_exclusive"]},
    {"impacted exclusive timeline identities",
     "timeline_dependency_impact_impacted_exclusive_with_timeline_ids",
     ["impacted_exclusive_with_timeline_ids"], ["timeline:downlink_conflict"],
     ["timeline:stale_impacted_exclusive"]},
    {"feedback source", "timeline_dependency_impact_feedback_sources", "feedback_source",
     ["mission_state.source_timeline_dependency_impact_summary.dependency_impact_rows"],
     ["mission_state.stale_timeline_dependency_impact_summary.rows"]},
    {"feedback scope", "timeline_dependency_impact_feedback_scopes", "feedback_scope",
     ["timeline_dependency_impact"], ["stale_timeline_dependency_impact"]},
    {"feedback key", "timeline_dependency_impact_feedback_keys", "feedback_key",
     ["cmd_dependency_review"], ["stale_dependency_key"]},
    {"trust boundary", "timeline_dependency_impact_trust_boundaries", "trust_boundary",
     ["mission_state_timeline_dependency_impact_summary"], ["stale_dependency_boundary"]},
    {"derivation reasons", "timeline_dependency_impact_derivation_reasons",
     ["derivation_reasons"], ["timeline_dependency_impact_summary_pressure"],
     ["stale_dependency_derivation"]}
  ]

  for {description, field, source_field, expected_value, stale_value} <-
        @timeline_dependency_impact_context_contracts do
    test "timeline-dependency impact #{description} remains source exact across handoffs", %{
      handoff: handoff
    } do
      assert_risk_context_contract(
        handoff,
        unquote(field),
        {"feedback_scope", "timeline_dependency_impact"},
        unquote(Macro.escape(source_field)),
        unquote(Macro.escape(expected_value)),
        unquote(Macro.escape(stale_value))
      )
    end
  end
end
