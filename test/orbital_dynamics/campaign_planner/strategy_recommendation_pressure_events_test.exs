Code.require_file("support.exs", __DIR__)

Code.require_file(
  "../../support/campaign_planner/strategy_recommendation_pressure_events_fixture.ex",
  __DIR__
)

defmodule OrbitalDynamics.CampaignPlanner.StrategyRecommendationPressureEventsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.StrategyRecommendationPressureEventsFixture

  test "strategy recommendation explains selected readiness, quality-gate, and approval-boundary pressure events" do
    artifact = StrategyRecommendationPressureEventsFixture.artifact()

    explanation = artifact["recommendation"]["explanation"]

    assert artifact["recommendation"]["recommended_branch_id"] == "urgent"

    assert %{
             "type" => "risk_driver",
             "risk_type" => "operational_readiness_pressure",
             "severity" => "medium",
             "report_id" => "operational_readiness:resource_projection_report.v1:live_ops",
             "source_artifact_type" => "resource_projection_report.v1",
             "source_artifact_id" => "live_ops",
             "readiness_level" => "operator_review",
             "import_classification" => "review_only",
             "operational_readiness_status" => "review_required",
             "readiness_gate_id" => "operator_training",
             "readiness_gate_status" => "review_required",
             "readiness_gate_classification" => "review_only",
             "required_operator_action" => "review_operational_readiness",
             "feedback_source" => "mission_state.source_operational_readiness_report.gates",
             "feedback_scope" => "operational_readiness",
             "feedback_key" => "operator_training",
             "trust_boundary" => "mission_state_operational_readiness_report"
           } =
             Enum.find(
               explanation,
               &(&1["type"] == "risk_driver" and
                   &1["risk_type"] == "operational_readiness_pressure")
             )

    assert %{
             "type" => "risk_driver",
             "risk_type" => "quality_gate_pressure",
             "severity" => "medium",
             "report_id" => "quality_gate:resource_projection_report.v1:live_ops",
             "source_artifact_type" => "resource_projection_report.v1",
             "source_artifact_id" => "live_ops",
             "source_readiness_report_id" =>
               "operational_readiness:resource_projection_report.v1:live_ops",
             "readiness_level" => "operator_review",
             "import_classification" => "review_only",
             "quality_gate_status" => "review_required",
             "gate_id" => "resource_availability",
             "gate_status" => "review_required",
             "gate_classification" => "review_only",
             "required_operator_action" => "review_operational_readiness",
             "feedback_source" => "mission_state.source_quality_gate_report.rows",
             "feedback_scope" => "quality_gate",
             "feedback_key" => "resource_availability",
             "trust_boundary" => "mission_state_quality_gate_report",
             "resource_availability_reason_ids" => [
               "antenna_unavailable",
               "payload_unavailable"
             ]
           } =
             Enum.find(
               explanation,
               &(&1["type"] == "risk_driver" and &1["risk_type"] == "quality_gate_pressure")
             )

    assert %{
             "type" => "risk_driver",
             "risk_type" => "approval_boundary_pressure",
             "severity" => "medium",
             "approval_boundary" => "command_execution",
             "approval_boundary_status" => "operator_review_required",
             "approval_boundary_reason" => "command execution requires flight director approval",
             "automation_boundary" => "no_command_execution",
             "execution_boundary" => "flight_director_approval",
             "import_classification" => "review_only",
             "required_operator_action" => "review_approval_boundary",
             "required_authority" => "flight_director",
             "policy_bundle_id" => "flight_rules_v3",
             "rule_id" => "no_unapproved_command_execution",
             "feedback_source" => "mission_state.source_approval_boundary_policy.rules",
             "feedback_scope" => "approval_boundary",
             "feedback_key" => "no_unapproved_command_execution",
             "trust_boundary" => "mission_state_approval_boundary_policy"
           } =
             Enum.find(
               explanation,
               &(&1["type"] == "risk_driver" and
                   &1["risk_type"] == "approval_boundary_pressure")
             )

    assert %{
             "type" => "risk_driver",
             "risk_type" => "timeline_activity_precondition_review",
             "severity" => "high",
             "activity_id" => "cmd_precondition_review",
             "timeline_id" => "timeline:cmd_precondition_review",
             "activity_type" => "command",
             "precondition_status" => "blocked",
             "blocked_precondition_count" => 2,
             "review_precondition_count" => 1,
             "blocked_precondition_types" => [
               "command_safety_failed",
               "payload_unavailable"
             ],
             "review_precondition_types" => ["command_authority_missing"],
             "dependency_activity_ids" => ["health_check"],
             "dependency_timeline_ids" => ["timeline:health_check"],
             "exclusive_with_activity_ids" => ["downlink_conflict"],
             "exclusive_with_timeline_ids" => ["timeline:downlink_conflict"],
             "duplicate_dependency_activity_ids" => ["health_check"],
             "duplicate_dependency_timeline_ids" => ["timeline:health_check"],
             "duplicate_exclusivity_activity_ids" => ["downlink_conflict"],
             "duplicate_exclusivity_timeline_ids" => ["timeline:downlink_conflict"],
             "allow_overlap" => true,
             "invalid_activity_input" => false,
             "requires_operator_review" => true,
             "required_operator_action" => "review_blocked_activity_precondition",
             "feedback_source" => "mission_state.source_timeline_activity_precondition_summary",
             "feedback_scope" => "timeline_activity_precondition",
             "feedback_key" => "cmd_precondition_review",
             "trust_boundary" => "mission_state_timeline_activity_precondition_summary",
             "derivation_reasons" => ["timeline_activity_precondition_summary_pressure"],
             "assumptions" => %{
               "activity_precondition_evaluation" => "not_performed_by_strategy_branch",
               "timeline_mutation" => "not_performed_by_strategy_branch",
               "operator_authority" => "not_granted_by_strategy_branch",
               "cadence_import" => "not_performed_by_strategy_branch"
             }
           } =
             Enum.find(
               explanation,
               &(&1["type"] == "risk_driver" and
                   &1["risk_type"] == "timeline_activity_precondition_review")
             )

    assert %{
             "type" => "risk_driver",
             "risk_type" => "timeline_dependency_impact",
             "severity" => "high",
             "activity_id" => "cmd_dependency_review",
             "timeline_id" => "timeline:cmd_dependency_review",
             "dependency_impact_scope" => "source",
             "dependency_impact_status" => "review_required",
             "operator_action_reason" => "dependency_link_impacted_by_timeline_change",
             "required_operator_action" => "review_timeline_dependency_impact",
             "dependency_activity_ids" => ["health_check"],
             "dependency_timeline_ids" => ["timeline:health_check"],
             "exclusive_with_activity_ids" => ["downlink_conflict"],
             "exclusive_with_timeline_ids" => ["timeline:downlink_conflict"],
             "impacted_dependency_activity_ids" => ["health_check"],
             "impacted_dependency_timeline_ids" => ["timeline:health_check"],
             "impacted_exclusive_with_activity_ids" => ["downlink_conflict"],
             "impacted_exclusive_with_timeline_ids" => ["timeline:downlink_conflict"],
             "feedback_source" =>
               "mission_state.source_timeline_dependency_impact_summary.dependency_impact_rows",
             "feedback_scope" => "timeline_dependency_impact",
             "feedback_key" => "cmd_dependency_review",
             "trust_boundary" => "mission_state_timeline_dependency_impact_summary",
             "derivation_reasons" => ["timeline_dependency_impact_summary_pressure"]
           } =
             Enum.find(
               explanation,
               &(&1["type"] == "risk_driver" and
                   &1["risk_type"] == "timeline_dependency_impact")
             )

    assert %{
             "type" => "risk_driver",
             "risk_type" => "timeline_integrity_issue",
             "severity" => "high",
             "activity_id" => "cmd_integrity_review",
             "timeline_id" => "timeline:cmd_integrity_review",
             "timeline_integrity_status" => "review_required",
             "timeline_integrity_issue_count" => 2,
             "timeline_integrity_issue_types" => [
               "missing_dependency_activity",
               "exclusivity_overlap"
             ],
             "timeline_integrity_issues" => [
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
             "missing_dependency_activity_ids" => ["cmd_power_on"],
             "exclusivity_violation_activity_ids" => ["downlink_conflict"],
             "exclusivity_violation_timeline_ids" => ["timeline:downlink_conflict"],
             "exclusivity_violation_group" => "equator_prime",
             "required_operator_action" => "review_timeline_integrity",
             "feedback_source" => "mission_state.source_timeline_integrity_report.rows",
             "feedback_scope" => "timeline_integrity",
             "feedback_key" => "cmd_integrity_review",
             "trust_boundary" => "mission_state_timeline_integrity_report",
             "derivation_reasons" => ["timeline_integrity_report_pressure"]
           } =
             Enum.find(
               explanation,
               &(&1["type"] == "risk_driver" and
                   &1["risk_type"] == "timeline_integrity_issue")
             )

    assert %{
             "type" => "risk_driver",
             "risk_type" => "command_success_rate_low",
             "severity" => "medium",
             "activity_id" => "cmd_success_review",
             "scenario_id" => "leo_1",
             "timeline_id" => "timeline:cmd_success_review",
             "starts_at_s" => 700.0,
             "ends_at_s" => 730.0,
             "value" => 0.25,
             "command_success_factor" => 0.25,
             "command_result" => "timeout",
             "realized_status" => "failed",
             "ground_station_id" => "equator_prime",
             "planned_ground_station_id" => "polar_prime",
             "realized_ground_station_id" => "equator_prime",
             "ground_station_match_status" => "mismatch",
             "direction" => "command",
             "planned_direction" => "uplink",
             "realized_direction" => "command",
             "direction_match_status" => "mismatch",
             "source_window_id" => "window_equator_command",
             "planned_source_window_id" => "window_polar_uplink",
             "realized_source_window_id" => "window_equator_command",
             "source_window_match_status" => "mismatch",
             "command_identity_mismatch_fields" => [
               "direction",
               "ground_station",
               "source_window"
             ],
             "source_activity_id" => "cmd_success_source",
             "replacement_activity_id" => "cmd_success_review",
             "source_activity_ids" => ["cmd_success_review", "cmd_success_source"],
             "changed_fields" => ["command_result", "command_success_factor"],
             "required_operator_action" => "review_command_execution_feedback",
             "feedback_source" => "mission_state.source_command_window_report.rows",
             "feedback_scope" => "command_execution_feedback",
             "feedback_key" => "cmd_success_review",
             "trust_boundary" => "mission_state_command_window_report",
             "transition_type" => "status_changed",
             "transition_category" => "terminal_exception",
             "transition_reason" => "command execution timed out",
             "requires_operator_review" => true,
             "derivation_reasons" => ["command_window_execution_feedback_pressure"]
           } =
             Enum.find(
               explanation,
               &(&1["type"] == "risk_driver" and
                   &1["risk_type"] == "command_success_rate_low")
             )

    assert %{
             "type" => "risk_driver",
             "risk_type" => "maneuver_success_rate_low",
             "severity" => "medium",
             "activity_id" => "burn_success_review",
             "scenario_id" => "leo_1",
             "timeline_id" => "timeline:burn_success_review",
             "starts_at_s" => 760.0,
             "ends_at_s" => 760.0,
             "value" => 0.4,
             "maneuver_success_factor" => 0.4,
             "maneuver_result" => "accepted, failed",
             "realized_status" => "failed",
             "source_activity_id" => "burn_success_source",
             "replacement_activity_id" => "burn_success_review",
             "source_activity_ids" => ["burn_success_review", "burn_success_source"],
             "changed_fields" => ["maneuver_result", "maneuver_success_factor"],
             "required_operator_action" => "review_maneuver_execution_feedback",
             "feedback_source" => "mission_state.source_maneuver_review.rows",
             "feedback_scope" => "maneuver_execution_feedback",
             "feedback_key" => "burn_success_review",
             "trust_boundary" => "mission_state_maneuver_review",
             "transition_type" => "status_changed",
             "transition_category" => "terminal_exception",
             "transition_reason" => "maneuver failed after acceptance",
             "requires_operator_review" => true,
             "derivation_reasons" => ["maneuver_review_success_feedback_pressure"]
           } =
             Enum.find(
               explanation,
               &(&1["type"] == "risk_driver" and
                   &1["risk_type"] == "maneuver_success_rate_low")
             )

    assert %{
             "type" => "resource_margin_pressure",
             "risk_type" => "power_margin_low",
             "severity" => "medium",
             "spacecraft_id" => "leo_1",
             "scenario_id" => "leo_1",
             "timeline_id" => "timeline:resource_margin:power",
             "source_activity_id" => "obs_power_pressure",
             "replacement_activity_id" => "obs_power_pressure_replanned",
             "source_activity_ids" => ["obs_power_pressure"],
             "resource_field" => "power_margin",
             "resource_margin_value" => 0.08,
             "resource_margin_threshold" => 0.2,
             "resource_margin_field_value" => %{
               "field" => "power_margin",
               "value" => 0.08,
               "threshold" => 0.2
             },
             "source_quality" => "declared",
             "starts_at_s" => 500.0,
             "ends_at_s" => 560.0,
             "diff_status" => "changed",
             "changed_fields" => ["power_margin"],
             "required_operator_action" => "review_resource_margin",
             "requires_operator_review" => true,
             "feedback_source" => "mission_state.source_resource_projection_report.rows",
             "feedback_scope" => "resource_margin",
             "feedback_key" => "leo_1.power_margin",
             "trust_boundary" => "mission_state_resource_projection_report",
             "derivation_reasons" => ["resource_projection_power_margin_low"]
           } =
             Enum.find(
               explanation,
               &(&1["type"] == "resource_margin_pressure" and
                   &1["risk_type"] == "power_margin_low")
             )

    assert %{
             "type" => "risk_driver",
             "risk_type" => "maneuver_execution_uncertainty_high",
             "severity" => "medium",
             "activity_id" => "burn_uncertain_review",
             "timeline_id" => "timeline:maneuver:burn_uncertain_review",
             "maneuver_id" => "burn_uncertain_review",
             "scenario_id" => "leo_1",
             "starts_at_s" => 620.0,
             "ends_at_s" => 620.0,
             "source_activity_id" => "burn_uncertain_source",
             "replacement_activity_id" => "burn_uncertain_review",
             "source_activity_ids" => ["burn_uncertain_review", "burn_uncertain_source"],
             "execution_uncertainty_status" => "declared",
             "execution_uncertainty_source" => "ops_covariance_review",
             "execution_uncertainty" => %{
               "timing_3sigma_s" => 75.0,
               "delta_v_3sigma_km_s" => [+0.0, 0.003, 0.004],
               "source" => "ops_covariance_review"
             },
             "timing_3sigma_s" => 75.0,
             "timing_3sigma_threshold_s" => 60.0,
             "delta_v_3sigma_km_s" => [+0.0, 0.003, 0.004],
             "delta_v_3sigma_magnitude_km_s" => 0.005,
             "delta_v_3sigma_magnitude_threshold_km_s" => 0.002,
             "changed_fields" => ["execution_uncertainty"],
             "required_operator_action" => "review_maneuver_execution_uncertainty",
             "requires_operator_review" => true,
             "feedback_source" => "mission_state.source_maneuver_review.rows",
             "feedback_scope" => "maneuver_execution_uncertainty",
             "feedback_key" => "burn_uncertain_review",
             "trust_boundary" => "mission_state_maneuver_review",
             "derivation_reasons" => ["maneuver_review_execution_uncertainty_pressure"]
           } =
             Enum.find(
               explanation,
               &(&1["type"] == "risk_driver" and
                   &1["risk_type"] == "maneuver_execution_uncertainty_high")
             )

    assert %{
             "type" => "risk_driver",
             "risk_type" => "timeline_publication_pressure",
             "severity" => "high",
             "publication_id" =>
               "timeline_publication:9:timeline:selected_plan:v2:timeline:selected_plan:v1",
             "publication_sequence" => 9,
             "publication_status" => "published_with_downstream_invalidations",
             "downstream_invalidation_status" => "invalidated",
             "dependency_impact_status" => "review_required",
             "source_artifact_id" => "timeline:selected_plan:v2",
             "source_artifact_type" => "operational_timeline_report.v1",
             "publication_authority" => "mission_operations",
             "supersedes_artifact_ids" => ["timeline:selected_plan:v1"],
             "downstream_product_ids" => [
               "operator_review:selected:v1",
               "cadence_import:selected:v1"
             ],
             "invalidated_downstream_product_ids" => [
               "cadence_import:selected:v1",
               "operator_review:selected:v1"
             ],
             "downstream_invalidation_reason_counts" => %{
               "dependency_impact_review_required" => 2
             },
             "downstream_invalidation_reasons" => ["dependency_impact_review_required"],
             "dependency_impact_row_count" => 2,
             "timeline_diff_row_count" => 3,
             "timeline_diff_changed_count" => 2,
             "timeline_diff_review_required_count" => 1,
             "changed_field_counts" => %{"timeline_presence" => 2},
             "changed_fields" => ["timeline_presence"],
             "changed_timeline_ids" => ["timeline:health_check:0.0"],
             "review_timeline_ids" => [
               "timeline:health_check:0.0",
               "timeline:health_check:5.0"
             ],
             "feedback_source" => "mission_state.source_timeline_publication_summary",
             "feedback_scope" => "timeline_publication",
             "feedback_key" =>
               "timeline_publication:9:timeline:selected_plan:v2:timeline:selected_plan:v1",
             "trust_boundary" => "mission_state_timeline_publication_summary",
             "derivation_reasons" => ["timeline_publication_summary_pressure"],
             "assumptions" => %{
               "publication_execution" => "not_performed_by_strategy_branch",
               "notification_delivery" => "not_performed_by_strategy_branch",
               "operator_authority" => "not_granted_by_strategy_branch",
               "import_approval" => "not_granted_by_strategy_branch"
             }
           } =
             Enum.find(
               explanation,
               &(&1["type"] == "risk_driver" and
                   &1["risk_type"] == "timeline_publication_pressure")
             )

    assert %{
             "type" => "risk_driver",
             "risk_type" => "timeline_lifecycle_state_review",
             "severity" => "high",
             "timeline_lifecycle_state_status" => "review_required",
             "planned_activity_count" => 4,
             "realized_activity_count" => 1,
             "row_count" => 4,
             "recordable_count" => 3,
             "preserved_count" => 1,
             "review_required_count" => 3,
             "duplicate_timeline_identity_count" => 1,
             "invalid_activity_input_count" => 1,
             "transition_decision_counts" => %{"record" => 3, "none" => 1},
             "required_operator_action_counts" => %{
               "review_activity_approval" => 1,
               "review_duplicate_timeline_identity" => 1,
               "review_invalid_activity_input" => 1
             },
             "operator_action_reason_counts" => %{
               "activity_approval_pending" => 1,
               "duplicate_timeline_identity" => 1,
               "missing_activity_type" => 1
             },
             "import_action_counts" => %{"review_timeline_diff" => 3},
             "review_timeline_ids" => [
               "timeline:lifecycle:cmd_pending",
               "timeline:lifecycle:dup",
               "timeline:invalid_activity_input:lifecycle_bad_missing_type"
             ],
             "review_activity_ids" => [
               "lifecycle_cmd_pending",
               "lifecycle_dup_a",
               "lifecycle_dup_b",
               "timeline_row:4:lifecycle_bad_missing_type"
             ],
             "invalid_activity_input_ids" => ["timeline_row:4:lifecycle_bad_missing_type"],
             "requires_operator_review" => true,
             "required_operator_action" => "review_timeline_lifecycle_state",
             "feedback_source" => "mission_state.source_timeline_lifecycle_state_summary",
             "feedback_scope" => "timeline_lifecycle_state",
             "feedback_key" => "mission.lifecycle.summary",
             "trust_boundary" => "mission_state_timeline_lifecycle_state_summary",
             "derivation_reasons" => ["timeline_lifecycle_state_summary_pressure"]
           } =
             Enum.find(
               explanation,
               &(&1["type"] == "risk_driver" and
                   &1["risk_type"] == "timeline_lifecycle_state_review")
             )

    assert %{
             "type" => "risk_driver",
             "risk_type" => "timeline_activity_lifecycle_state_review",
             "severity" => "high",
             "activity_id" => "activity_lifecycle_cmd_pending",
             "timeline_id" => "timeline:activity_lifecycle:cmd_pending",
             "planned_activity_id" => "activity_lifecycle_cmd_pending",
             "realized_activity_id" => "activity_lifecycle_cmd_pending",
             "planned_timeline_id" => "timeline:activity_lifecycle:cmd_pending",
             "realized_timeline_id" => "timeline:activity_lifecycle:cmd_pending",
             "transition_decision" => "review",
             "status_transition_decision" => "record",
             "approval_transition_decision" => "review",
             "review_required" => true,
             "requires_operator_review" => true,
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
             "invalid_activity_input" => false,
             "planned_status" => "planned",
             "realized_status" => "executed",
             "planned_approval_status" => "pending",
             "realized_approval_status" => "approved",
             "planned_protection_decision" => "record",
             "realized_protection_decision" => "review",
             "feedback_source" => "mission_state.source_timeline_activity_lifecycle_state",
             "feedback_scope" => "timeline_activity_lifecycle_state",
             "feedback_key" => "activity_lifecycle_cmd_pending",
             "trust_boundary" => "mission_state_timeline_activity_lifecycle_state",
             "derivation_reasons" => ["timeline_activity_lifecycle_state_pressure"]
           } =
             Enum.find(
               explanation,
               &(&1["type"] == "risk_driver" and
                   &1["risk_type"] == "timeline_activity_lifecycle_state_review")
             )

    assert %{
             "type" => "risk_driver",
             "risk_type" => "timeline_preservation_review",
             "severity" => "high",
             "activity_id" => "contact_locked_review",
             "timeline_id" => "timeline:contact_locked_review",
             "timeline_preservation_status" => "review_required",
             "requires_preservation" => false,
             "requires_operator_review" => true,
             "status" => "planned",
             "approval_status" => "approved",
             "locked" => true,
             "approved" => true,
             "protection_decision" => "preserve",
             "protection_category" => "locked_or_approved",
             "protection_reason" => "activity_locked_or_approved",
             "preserve_activity_count" => 2,
             "review_change_activity_count" => 1,
             "preservation_sensitive_activity_count" => 2,
             "preserve_activity_ids" => ["contact_locked_review", "obs_done_review"],
             "preserve_timeline_ids" => [
               "timeline:contact_locked_review",
               "timeline:obs_done_review"
             ],
             "review_change_activity_ids" => ["bad_missing_type_review"],
             "review_change_timeline_ids" => ["timeline:bad_missing_type_review"],
             "preservation_sensitive_activity_ids" => [
               "contact_locked_review",
               "obs_done_review"
             ],
             "preservation_sensitive_timeline_ids" => [
               "timeline:contact_locked_review",
               "timeline:obs_done_review"
             ],
             "invalid_activity_input" => false,
             "required_operator_action" => "review_timeline_preservation",
             "feedback_source" => "mission_state.source_timeline_preservation_report.rows[0]",
             "feedback_scope" => "timeline_preservation",
             "feedback_key" => "contact_locked_review",
             "trust_boundary" => "mission_state_timeline_preservation_report",
             "derivation_reasons" => ["timeline_preservation_pressure"],
             "assumptions" => %{
               "timeline_preservation_application" => "not_performed_by_strategy_branch",
               "timeline_mutation" => "not_performed_by_strategy_branch",
               "operator_authority" => "not_granted_by_strategy_branch",
               "cadence_import" => "not_performed_by_strategy_branch"
             }
           } =
             Enum.find(
               explanation,
               &(&1["type"] == "risk_driver" and
                   &1["risk_type"] == "timeline_preservation_review")
             )

    assert %{
             "type" => "risk_driver",
             "risk_type" => "provider_reservation_request_review",
             "severity" => "high",
             "contact_id" => "dl_provider_review",
             "source_activity_id" => "dl_provider_review",
             "source_activity_ids" => ["dl_provider_review"],
             "ground_station_id" => "equator_prime",
             "direction" => "downlink",
             "station_reservation_id" => "provider_reservation_review",
             "station_reserved_by" => "partner_calendar",
             "station_reservation_status" => "confirmed",
             "station_reservation_expiration_status" => "active",
             "station_reservation_match_status" => "overlap",
             "provider_reservation_request_status" => "review_required",
             "provider_reservation_row_scope" => "review",
             "required_operator_action" => "review_provider_reservation_request",
             "feedback_source" =>
               "mission_state.source_contact_allocation_provider_reservation_request_summary",
             "feedback_scope" => "contact_allocation_provider_reservation_request",
             "trust_boundary" => "mission_state_provider_reservation_request_summary",
             "assumptions" => %{
               "provider_reservation_execution" => "not_performed_by_strategy_branch",
               "schedule_mutation" => "not_performed_by_strategy_branch",
               "operator_authority" => "not_granted_by_strategy_branch"
             }
           } =
             Enum.find(
               explanation,
               &(&1["type"] == "risk_driver" and
                   &1["risk_type"] == "provider_reservation_request_review")
             )

    assert %{
             "type" => "risk_driver",
             "risk_type" => "downlink_completion_gap",
             "severity" => "medium",
             "contact_id" => "dl_capacity_overflow",
             "source_activity_id" => "dl_capacity_overflow",
             "source_activity_ids" => ["dl_capacity_overflow"],
             "ground_station_id" => "equator_prime",
             "required_contacts" => 1,
             "planned_contacts" => 0,
             "required_downlink_mb" => 47.0,
             "planned_downlink_mb" => planned_downlink_mb,
             "capacity_pack_group_id" => "capacity_pack_equator_prime",
             "capacity_pack_status" => "deferred_by_reduced_station_capacity_pack",
             "capacity_pack_capacity_fraction" => 0.5,
             "capacity_pack_used_fraction" => 0.5,
             "capacity_pack_unused_fraction" => capacity_pack_unused_fraction,
             "required_capacity_fraction" => 0.25,
             "required_capacity_fraction_source" => "contact_required_capacity_fraction",
             "capacity_pack_contact_ids_by_direction" => %{
               "downlink" => ["dl_capacity_selected", "dl_capacity_overflow"]
             },
             "capacity_pack_selected_contact_ids_by_direction" => %{
               "downlink" => ["dl_capacity_selected"]
             },
             "capacity_pack_deferred_contact_ids_by_direction" => %{
               "downlink" => ["dl_capacity_overflow"]
             },
             "capacity_pack_required_capacity_fraction_by_direction" => %{
               "downlink" => 0.75
             },
             "capacity_pack_selected_required_capacity_fraction_by_direction" => %{
               "downlink" => 0.5
             },
             "capacity_pack_deferred_required_capacity_fraction_by_direction" => %{
               "downlink" => 0.25
             },
             "derivation_reasons" => [
               "contact_contention_deferred",
               "deferred_by_reduced_station_capacity_pack"
             ],
             "feedback_source" => "mission_state.source_contact_allocation_capacity_pack_summary",
             "feedback_scope" => "contact_contention_resolution",
             "trust_boundary" => "mission_state_capacity_pack_summary"
           } =
             Enum.find(
               explanation,
               &(&1["type"] == "risk_driver" and &1["contact_id"] == "dl_capacity_overflow")
             )

    assert planned_downlink_mb == 0.0
    assert capacity_pack_unused_fraction == 0.0

    assert %{
             "type" => "risk_driver",
             "risk_type" => "downlink_completion_gap",
             "severity" => "medium",
             "contact_id" => "dl_reservation_conflict",
             "source_activity_id" => "dl_reservation_conflict",
             "source_activity_ids" => ["dl_reservation_conflict"],
             "ground_station_id" => "equator_prime",
             "required_contacts" => 1,
             "planned_contacts" => 0,
             "required_downlink_mb" => 43.0,
             "planned_downlink_mb" => reservation_planned_downlink_mb,
             "station_reservation_id" => "reservation_conflict_1",
             "station_reserved_by" => "ops_team_b",
             "station_reservation_status" => "confirmed",
             "station_reservation_match_status" => "overlap",
             "station_reservation_expires_at_s" => 360.0,
             "derivation_reasons" => ["contact_allocation_reservation_conflict"],
             "feedback_source" =>
               "mission_state.source_contact_allocation_reservation_conflict_summary",
             "feedback_scope" => "contact_allocation",
             "trust_boundary" => "mission_state_reservation_conflict_summary"
           } =
             Enum.find(
               explanation,
               &(&1["type"] == "risk_driver" and &1["contact_id"] == "dl_reservation_conflict")
             )

    assert reservation_planned_downlink_mb == 0.0

    assert %{
             "type" => "risk_driver",
             "risk_type" => "downlink_completion_gap",
             "severity" => "medium",
             "contact_id" => "dl_hold_import_review",
             "source_activity_id" => "dl_hold_import_review",
             "source_activity_ids" => ["dl_hold_import_review"],
             "ground_station_id" => "equator_prime",
             "direction" => "downlink",
             "required_contacts" => 1,
             "planned_contacts" => 0,
             "required_downlink_mb" => 41.0,
             "planned_downlink_mb" => hold_planned_downlink_mb,
             "station_reservation_id" => "reservation_hold_expired",
             "station_reserved_by" => "ops_calendar",
             "station_reservation_status" => "held",
             "station_reservation_match_status" => "overlap",
             "station_reservation_expires_at_s" => 120.0,
             "station_reservation_hold_import_status" => "review_required_before_import",
             "station_reservation_hold_import_readiness_summary_model" =>
               "artifact_only_station_reservation_hold_import_readiness_summary",
             "station_reservation_hold_import_readiness_source" =>
               "station_calendar_report.reservation_evidence",
             "station_reservation_hold_import_readiness_source_artifact_type" =>
               "station_reservation_report.v1",
             "station_reservation_hold_import_readiness_status" => "review_required",
             "station_reservation_hold_import_classification" => "review_only",
             "station_reservation_hold_count" => 2,
             "station_reservation_hold_ids" => [
               "reservation_hold_expired",
               "reservation_hold_missing"
             ],
             "station_reservation_hold_import_execution_boundary" =>
               "artifact_only_no_provider_or_cadence_writes",
             "station_reservation_hold_provider_write" => "not_performed_by_summary",
             "station_reservation_hold_cadence_write" => "not_performed_by_summary",
             "station_reservation_hold_reservation_acceptance" => "not_performed_by_summary",
             "feedback_source" =>
               "mission_state.source_station_reservation_hold_import_readiness_summary",
             "feedback_scope" => "station_reservation_hold_import_readiness",
             "trust_boundary" => "mission_state_station_reservation_hold_import_readiness_summary"
           } =
             Enum.find(
               explanation,
               &(&1["type"] == "risk_driver" and &1["contact_id"] == "dl_hold_import_review")
             )

    assert hold_planned_downlink_mb == 0.0

    assert %{
             "type" => "risk_driver",
             "risk_type" => "provider_counteroffer_pressure",
             "severity" => "medium",
             "provider_counteroffer_id" => "provider_offer_urgent",
             "provider_counteroffer_status" => "proposed",
             "provider_counteroffer_negotiation_state" => "proposed",
             "provider_counteroffer_reason_code" => "provider_shifted_window",
             "provider_counteroffer_cost_delta" => 125.5,
             "provider_counteroffer_lock_deadline_s" => 150.0,
             "provider_counteroffer_starts_at_s" => 530.0,
             "provider_counteroffer_ends_at_s" => 590.0,
             "provider_counteroffer_start_delta_s" => 30.0,
             "provider_counteroffer_end_delta_s" => 30.0,
             "provider_counteroffer_duration_delta_s" => duration_delta_s,
             "plan_impact_status" => "review_required",
             "affected_station_calendar_entry_ids" => ["contact_original"],
             "affected_provider_entry_ids" => ["partner_entry_42"],
             "impact_counteroffer_ids" => ["provider_offer_urgent"],
             "ground_station_id" => "equator_prime",
             "station_calendar_entry_id" => "contact_original",
             "station_calendar_provider_id" => "partner_calendar",
             "station_calendar_provider_entry_id" => "partner_entry_42",
             "station_availability" => "counteroffer",
             "required_operator_action" => "review_provider_counteroffer",
             "feedback_source" => "mission_state.source_provider_counteroffer_report.rows",
             "feedback_scope" => "provider_counteroffer",
             "feedback_key" => "provider_offer_urgent",
             "trust_boundary" => "mission_state_provider_counteroffer_report",
             "source_provider_counteroffer" => %{
               "provider_counteroffer_id" => "provider_offer_urgent",
               "required_operator_action" => "review_provider_counteroffer"
             }
           } =
             Enum.find(
               explanation,
               &(&1["type"] == "risk_driver" and
                   &1["risk_type"] == "provider_counteroffer_pressure")
             )

    assert duration_delta_s == 0.0

    assert %{
             "type" => "risk_driver",
             "risk_type" => "candidate_rejection_pressure",
             "severity" => "high",
             "candidate_id" => "dl_rejected_hot",
             "activity_id" => "dl_rejected_hot",
             "activity_type" => "downlink",
             "scenario_id" => "leo_1",
             "ground_station_id" => "equator_prime",
             "source_window_id" => "equator_prime_rejected_window",
             "source_window_type" => "ground_station_contact",
             "rejection_status" => "rejected",
             "primary_rejection_reason" => "contact_too_short",
             "rejection_reasons" => [
               "contact_too_short",
               "station_capacity_reduced",
               "station_reserved"
             ],
             "violated_constraint" => "min_duration_s",
             "required_margin" => 10.0,
             "actual_margin" => 5.0,
             "required_operator_action" => "review_candidate_rejection",
             "feedback_source" => "mission_state.source_candidate_rejection_report.rows",
             "feedback_scope" => "candidate_rejection",
             "feedback_key" => "dl_rejected_hot",
             "trust_boundary" => "mission_state_candidate_rejection_report",
             "source_candidate_rejection" => %{
               "candidate_id" => "dl_rejected_hot",
               "required_operator_action" => "review_candidate_rejection"
             }
           } =
             Enum.find(
               explanation,
               &(&1["type"] == "risk_driver" and
                   &1["risk_type"] == "candidate_rejection_pressure")
             )

    assert %{
             "type" => "risk_driver",
             "risk_type" => "model_acceptance_pressure",
             "severity" => "medium",
             "report_id" => "model_acceptance:operational_import:live_ops",
             "intended_use" => "operational_import",
             "model_acceptance_status" => "review_required",
             "model_id" => "live_analysis_model",
             "validation_level" => "analysis",
             "model_status" => "review_required",
             "model_reason" =>
               "analysis evidence requires operator review for operational_import",
             "required_operator_action" => "review_model_acceptance",
             "feedback_source" => "mission_state.source_model_acceptance_report.rows",
             "feedback_scope" => "model_acceptance",
             "feedback_key" => "live_analysis_model",
             "trust_boundary" => "mission_state_model_acceptance_report",
             "model_ids_by_status" => %{"review_required" => ["live_analysis_model"]},
             "model_ids_by_validation_level" => %{"analysis" => ["live_analysis_model"]},
             "model_ids_by_intended_use" => %{
               "operational_import" => ["live_analysis_model"]
             }
           } =
             Enum.find(
               explanation,
               &(&1["type"] == "risk_driver" and
                   &1["risk_type"] == "model_acceptance_pressure")
             )

    assert %{
             "type" => "risk_driver",
             "risk_type" => "schema_validation_pressure",
             "severity" => "high",
             "validation_status" => "fail",
             "validation_mode" => "artifact_file",
             "validated_contract" => "candidate_refresh.v1",
             "validated_artifact_family" => "candidate_refresh",
             "artifact_path" => "study_results/candidate_refresh.json",
             "issue_severity" => "error",
             "issue_path" => "$.candidate_plan.activities[0].id",
             "error_count" => 1,
             "warning_count" => 0,
             "remediation_count" => 1,
             "remediation_category" => "schema_contract",
             "remediation_action" => "regenerate_candidate_refresh",
             "required_operator_action" => "review_schema_validation",
             "feedback_source" => "mission_state.source_schema_validation_report.errors",
             "feedback_scope" => "schema_validation",
             "feedback_key" => "$.candidate_plan.activities[0].id",
             "trust_boundary" => "mission_state_schema_validation_report"
           } =
             Enum.find(
               explanation,
               &(&1["type"] == "risk_driver" and
                   &1["risk_type"] == "schema_validation_pressure")
             )

    assert %{
             "type" => "risk_driver",
             "risk_type" => "validation_safety_case_pressure",
             "severity" => "high",
             "report_id" => "validation_safety_case:live_ops",
             "validation_safety_case_status" => "blocked",
             "evidence_status" => "blocked",
             "input_contract" => "model_acceptance_report.v1",
             "input_contracts" => ["model_acceptance_report.v1", "quality_gate_report.v1"],
             "evidence_ref" => "model_acceptance_report.v1:model.blocked",
             "evidence_count" => 2,
             "accepted_evidence_count" => 0,
             "review_required_evidence_count" => 1,
             "blocked_evidence_count" => 1,
             "model_blocked_count" => 1,
             "quality_gate_review_count" => 1,
             "quality_gate_blocked_count" => 1,
             "schema_error_count" => 1,
             "schema_warning_count" => 2,
             "evidence_status_counts" => %{"blocked" => 1, "review_required" => 1},
             "evidence_refs_by_status" => %{
               "blocked" => ["model_acceptance_report.v1:model.blocked"],
               "review_required" => ["quality_gate_report.v1:gate.review"]
             },
             "evidence_refs_by_contract" => %{
               "model_acceptance_report.v1" => ["model_acceptance_report.v1:model.blocked"],
               "quality_gate_report.v1" => ["quality_gate_report.v1:gate.review"]
             },
             "required_operator_action" => "review_blocked_validation_safety_case",
             "feedback_source" => "mission_state.source_validation_safety_case_summary.evidence",
             "feedback_scope" => "validation_safety_case",
             "feedback_key" => "model_acceptance_report.v1:model.blocked",
             "trust_boundary" => "mission_state_validation_safety_case_summary"
           } =
             Enum.find(
               explanation,
               &(&1["type"] == "risk_driver" and
                   &1["risk_type"] == "validation_safety_case_pressure")
             )

    assert %{
             "type" => "risk_driver",
             "risk_type" => "refresh_budget_pressure",
             "severity" => "medium",
             "input_candidate_count" => 8,
             "kept_candidate_count" => 4,
             "dropped_candidate_count" => 4,
             "invalid_limit_count" => 0,
             "current_max_candidate_activities" => 4,
             "relaxed_max_candidate_activities" => 8,
             "candidate_limit_status" => "relaxed_required",
             "refresh_budget_status" => "review_required",
             "required_operator_action" => "review_refresh_budget",
             "feedback_source" => "mission_state.source_refresh_budget_report",
             "feedback_scope" => "refresh_budget",
             "feedback_key" => "refresh_budget:limit",
             "trust_boundary" => "mission_state_refresh_budget_report"
           } =
             Enum.find(
               explanation,
               &(&1["type"] == "risk_driver" and
                   &1["risk_type"] == "refresh_budget_pressure")
             )

    assert %{
             "type" => "risk_driver",
             "risk_type" => "refresh_freshness_pressure",
             "severity" => "medium",
             "freshness_status" => "stale",
             "state_quality_status" => "stale",
             "accepted_snapshot_age_s" => 3600.0,
             "horizon_start_offset_s" => 120.0,
             "max_snapshot_age_s" => 60.0,
             "max_horizon_start_offset_s" => 30.0,
             "stale_reasons" => [
               "accepted_snapshot_older_than_policy",
               "horizon_start_offset_exceeds_policy"
             ],
             "unknown_reasons" => [],
             "required_operator_action" => "review_refresh_freshness",
             "feedback_source" => "mission_state.source_freshness_report",
             "feedback_scope" => "refresh_freshness",
             "feedback_key" => "freshness:stale",
             "trust_boundary" => "mission_state_freshness_report"
           } =
             Enum.find(
               explanation,
               &(&1["type"] == "risk_driver" and
                   &1["risk_type"] == "refresh_freshness_pressure")
             )

    assert %{
             "type" => "operational_readiness_pressure",
             "recommended_branch_id" => "urgent",
             "report_id" => "operational_readiness:resource_projection_report.v1:live_ops",
             "source_artifact_type" => "resource_projection_report.v1",
             "source_artifact_id" => "live_ops",
             "readiness_level" => "operator_review",
             "import_classification" => "review_only",
             "operational_readiness_status" => "review_required",
             "readiness_gate_id" => "operator_training",
             "readiness_gate_status" => "review_required",
             "readiness_gate_classification" => "review_only",
             "readiness_gate_reason" => "operator training requires role-qualified review",
             "required_operator_action" => "review_operational_readiness",
             "feedback_source" => "mission_state.source_operational_readiness_report.gates",
             "feedback_scope" => "operational_readiness",
             "feedback_key" => "operator_training",
             "trust_boundary" => "mission_state_operational_readiness_report",
             "operator_training_requirement_count" => 2,
             "required_operator_roles" => ["contact_operator"],
             "reason" => "operator training requires role-qualified review"
           } =
             Enum.find(explanation, &(&1["type"] == "operational_readiness_pressure"))

    assert %{
             "type" => "quality_gate_pressure",
             "recommended_branch_id" => "urgent",
             "report_id" => "quality_gate:resource_projection_report.v1:live_ops",
             "source_artifact_type" => "resource_projection_report.v1",
             "source_artifact_id" => "live_ops",
             "source_readiness_report_id" =>
               "operational_readiness:resource_projection_report.v1:live_ops",
             "readiness_level" => "operator_review",
             "import_classification" => "review_only",
             "quality_gate_status" => "review_required",
             "gate_id" => "resource_availability",
             "gate_status" => "review_required",
             "gate_classification" => "review_only",
             "gate_reason" =>
               "resource availability evidence requires operator review before import",
             "required_operator_action" => "review_operational_readiness",
             "feedback_source" => "mission_state.source_quality_gate_report.rows",
             "feedback_scope" => "quality_gate",
             "feedback_key" => "resource_availability",
             "trust_boundary" => "mission_state_quality_gate_report",
             "resource_availability_pressure_count" => 2,
             "resource_availability_reason_ids" => [
               "antenna_unavailable",
               "payload_unavailable"
             ],
             "reason" => "resource availability evidence requires operator review before import"
           } =
             Enum.find(explanation, &(&1["type"] == "quality_gate_pressure"))
  end
end
