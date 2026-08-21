Code.require_file("support.exs", __DIR__)

Code.require_file(
  "../../support/campaign_planner/strategy_recommendation_pressure_handoff_case.ex",
  __DIR__
)

defmodule OrbitalDynamics.CampaignPlanner.StrategyRecommendationPressureHandoffResourceContextTest do
  use OrbitalDynamics.CampaignPlanner.StrategyRecommendationPressureHandoffCase

  @resource_filter_availability_context_contracts [
    {"risk type", "resource_filter_pressure_risk_types", "type",
     [
       "downlink_margin_low",
       "fuel_margin_low",
       "payload_unavailable",
       "power_margin_low",
       "storage_margin_low",
       "thermal_margin_c_low"
     ], ["spacecraft_unavailable"]},
    {"scenario identity", "resource_filter_pressure_scenario_ids", "scenario_id", ["leo_1"],
     ["stale_scenario"]},
    {"spacecraft identity", "resource_filter_pressure_spacecraft_ids", "spacecraft_id", ["leo_1"],
     ["stale_spacecraft"]},
    {"resource field", "resource_filter_pressure_resource_fields", "resource_field",
     [
       "downlink_margin",
       "fuel_margin",
       "payload_available",
       "power_margin",
       "storage_margin",
       "thermal_margin_c"
     ], ["antenna_available"]},
    {"availability value", "resource_filter_pressure_available_values",
     ["available", "resource_availability_value"], [false], [true]},
    {"source activity identity", "resource_filter_pressure_source_activity_ids",
     ["source_activity_id", "source_activity_ids"],
     [
       "dl_resource_filter_downlink",
       "obs_resource_filter_fuel",
       "obs_resource_filter_suppressed",
       "obs_resource_filter_power",
       "obs_resource_filter_storage",
       "obs_resource_filter_thermal"
     ], ["stale_resource_filter_activity"]},
    {"start timing", "resource_filter_pressure_start_values_s", "starts_at_s",
     [1_510.0, 1_300.0, 1_230.0, 1_370.0, 1_440.0, 1_580.0], [1_231.0]},
    {"end timing", "resource_filter_pressure_end_values_s", "ends_at_s",
     [1_570.0, 1_360.0, 1_290.0, 1_430.0, 1_500.0, 1_640.0], [1_291.0]},
    {"suppression reason", "resource_filter_pressure_suppressed_reasons", "suppressed_reason",
     [
       "downlink_margin_below_policy",
       "fuel_margin_below_policy",
       "payload_unavailable",
       "power_margin_below_observe_policy",
       "storage_margin_below_observe_policy",
       "thermal_margin_below_policy"
     ], ["spacecraft_unavailable"]},
    {"source quality", "resource_filter_pressure_source_quality_values", "source_quality",
     ["operator_supplied"], ["stale_source_quality"]},
    {"resource trust status", "resource_filter_pressure_resource_trust_boundary_statuses",
     "resource_trust_boundary_status", ["declared"], ["unknown"]},
    {"feedback source", "resource_filter_pressure_feedback_sources", "feedback_source",
     ["mission_state.source_resource_filter_report.suppressed_candidates"],
     ["mission_state.stale_resource_filter_report.suppressed_candidates"]},
    {"feedback scope", "resource_filter_pressure_feedback_scopes", "feedback_scope",
     ["resource_filter"], ["stale_resource_filter"]},
    {"trust boundary", "resource_filter_pressure_trust_boundaries", "trust_boundary",
     ["mission_state_resource_filter_report"], ["stale_resource_filter_boundary"]},
    {"derivation reasons", "resource_filter_pressure_derivation_reasons", ["derivation_reasons"],
     [
       "resource_filter_suppressed",
       "downlink_margin_below_policy",
       "fuel_margin_below_policy",
       "payload_unavailable",
       "power_margin_below_observe_policy",
       "storage_margin_below_observe_policy",
       "thermal_margin_below_policy"
     ], ["stale_resource_filter_derivation"]}
  ]

  for {description, field, source_field, expected_value, stale_value} <-
        @resource_filter_availability_context_contracts do
    test "resource-filter #{description} remains source exact across handoffs", %{
      handoff: handoff
    } do
      assert_risk_context_contract(
        handoff,
        unquote(field),
        {"feedback_scope", "resource_filter"},
        unquote(Macro.escape(source_field)),
        unquote(Macro.escape(expected_value)),
        unquote(Macro.escape(stale_value))
      )
    end
  end

  @resource_filter_margin_context_contracts [
    {"fuel margin", "resource_filter_pressure_fuel_margin_values", "fuel_margin",
     ["fuel_margin", "resource_margin_value"], [0.05], [0.06]},
    {"fuel margin threshold", "resource_filter_pressure_fuel_margin_threshold_values",
     "fuel_margin", ["fuel_margin_threshold", "resource_margin_threshold"], [0.1], [0.11]},
    {"power margin", "resource_filter_pressure_power_margin_values", "power_margin",
     ["power_margin", "resource_margin_value"], [0.08], [0.09]},
    {"power margin threshold", "resource_filter_pressure_power_margin_threshold_values",
     "power_margin", ["power_margin_threshold", "resource_margin_threshold"], [0.2], [0.21]},
    {"storage margin", "resource_filter_pressure_storage_margin_values", "storage_margin",
     ["storage_margin", "resource_margin_value"], [12.0], [13.0]},
    {"storage margin threshold", "resource_filter_pressure_storage_margin_threshold_values",
     "storage_margin", ["storage_margin_threshold", "resource_margin_threshold"], [20.0], [21.0]},
    {"downlink margin", "resource_filter_pressure_downlink_margin_values", "downlink_margin",
     ["downlink_margin", "resource_margin_value"], [8.0], [9.0]},
    {"downlink margin threshold", "resource_filter_pressure_downlink_margin_threshold_values",
     "downlink_margin", ["downlink_margin_threshold", "resource_margin_threshold"], [15.0],
     [16.0]},
    {"thermal margin", "resource_filter_pressure_thermal_margin_values_c", "thermal_margin_c",
     ["thermal_margin_c", "resource_margin_value"], [2.0], [3.0]},
    {"thermal margin threshold", "resource_filter_pressure_thermal_margin_threshold_values_c",
     "thermal_margin_c", ["thermal_margin_c_threshold", "resource_margin_threshold"], [5.0],
     [6.0]},
    {"operator training count",
     "resource_filter_pressure_operator_training_requirement_count_values", "power_margin",
     "operator_training_requirement_count", [2], [3]},
    {"required operator roles", "resource_filter_pressure_required_operator_roles",
     "power_margin", ["required_operator_roles"], ["contact_operator", "resource_operator"],
     ["stale_operator_role"]}
  ]

  for {description, field, resource_field, source_field, expected_value, stale_value} <-
        @resource_filter_margin_context_contracts do
    test "resource-filter #{description} remains source exact across handoffs", %{
      handoff: handoff
    } do
      assert_risk_context_contract(
        handoff,
        unquote(field),
        {"resource_field", unquote(resource_field)},
        unquote(Macro.escape(source_field)),
        unquote(Macro.escape(expected_value)),
        unquote(Macro.escape(stale_value))
      )
    end
  end

  @resource_margin_context_contracts [
    {"risk type", "resource_margin_risk_types", "resource_margin_risk_type",
     [
       "downlink_margin_low",
       "fuel_margin_low",
       "power_margin_low",
       "storage_margin_low",
       "thermal_margin_c_low"
     ], ["stale_resource_margin_risk"]},
    {"spacecraft identity", "resource_margin_spacecraft_ids", "spacecraft_id",
     ["leo_1", "leo_projection_selected"], ["stale_spacecraft"]},
    {"scenario identity", "resource_margin_scenario_ids", "scenario_id",
     ["leo_1", "leo_projection_selected"], ["stale_scenario"]},
    {"timeline identity", "resource_margin_timeline_ids", "timeline_id",
     ["timeline:resource_margin:power"], ["timeline:stale_resource_margin"]},
    {"source activity identity", "resource_margin_source_activity_ids",
     ["source_activity_id", "source_activity_ids"],
     [
       "dl_resource_filter_downlink",
       "obs_projection_pressure",
       "obs_resource_filter_fuel",
       "obs_power_pressure",
       "obs_resource_filter_power",
       "obs_resource_filter_storage",
       "obs_resource_filter_thermal"
     ], ["stale_resource_margin_activity"]},
    {"replacement activity identity", "resource_margin_replacement_activity_ids",
     "replacement_activity_id", ["obs_power_pressure_replanned"],
     ["stale_resource_margin_replacement"]},
    {"resource field", "resource_margin_fields", "resource_field",
     [
       "downlink_margin",
       "fuel_margin",
       "power_margin",
       "storage_margin",
       "thermal_margin_c"
     ], ["stale_margin"]},
    {"margin value", "resource_margin_values", "resource_margin_value",
     [8.0, 0.0, 0.05, 0.08, 12.0, 2.0, -1.5], [999.0]},
    {"margin threshold", "resource_margin_threshold_values", "resource_margin_threshold",
     [15.0, 0.75, 0.1, 0.2, 20.0, 5.0, 0.0], [1_000.0]},
    {"field value map", "resource_margin_field_value_maps", "resource_margin_field_value",
     [
       %{"field" => "downlink_margin", "threshold" => 15.0, "value" => 8.0},
       %{"field" => "downlink_margin", "threshold" => 0.75, "value" => 0.0},
       %{"field" => "fuel_margin", "threshold" => 0.1, "value" => 0.05},
       %{"field" => "power_margin", "threshold" => 0.2, "value" => 0.08},
       %{"field" => "power_margin", "threshold" => 0.2, "value" => 0.0},
       %{"field" => "storage_margin", "threshold" => 20.0, "value" => 12.0},
       %{"field" => "storage_margin", "threshold" => 0.2, "value" => 0.0},
       %{"field" => "thermal_margin_c", "threshold" => 5.0, "value" => 2.0},
       %{"field" => "thermal_margin_c", "threshold" => 0.0, "value" => -1.5}
     ], [%{"field" => "stale_margin", "threshold" => 1_000.0, "value" => 999.0}]},
    {"source quality", "resource_margin_source_quality_values", "source_quality",
     ["operator_supplied", "declared"], ["stale_source_quality"]},
    {"start timing", "resource_margin_start_values_s", "starts_at_s",
     [1_510.0, 1_590.0, 1_300.0, 500.0, 1_370.0, 1_440.0, 1_580.0], [999.0]},
    {"end timing", "resource_margin_end_values_s", "ends_at_s",
     [1_570.0, 1_650.0, 1_360.0, 560.0, 1_430.0, 1_500.0, 1_640.0], [1_000.0]},
    {"diff status", "resource_margin_diff_statuses", "diff_status", ["changed"], ["unchanged"]},
    {"changed field", "resource_margin_changed_fields", ["changed_fields"], ["power_margin"],
     ["stale_margin"]},
    {"required operator action", "resource_margin_required_operator_actions",
     "required_operator_action", ["review_resource_margin"], ["stale_operator_action"]},
    {"operator review requirement", "resource_margin_requires_operator_review_values",
     "requires_operator_review", [true], [false]},
    {"feedback source", "resource_margin_feedback_sources", "feedback_source",
     [
       "mission_state.source_resource_filter_report.suppressed_candidates",
       "mission_state.source_resource_projection_report",
       "mission_state.source_resource_projection_report.rows"
     ], ["mission_state.stale_resource_margin_report.rows"]},
    {"feedback scope", "resource_margin_feedback_scopes", "feedback_scope",
     ["resource_filter", "resource_projection", "resource_margin"], ["stale_resource_margin"]},
    {"feedback key", "resource_margin_feedback_keys", "feedback_key", ["leo_1.power_margin"],
     ["stale_spacecraft.power_margin"]},
    {"trust boundary", "resource_margin_trust_boundaries", "trust_boundary",
     ["mission_state_resource_filter_report", "mission_state_resource_projection_report"],
     ["stale_resource_margin_boundary"]},
    {"derivation reason", "resource_margin_derivation_reasons", ["derivation_reasons"],
     [
       "resource_filter_suppressed",
       "downlink_margin_below_policy",
       "projected_downlink_shortfall",
       "fuel_margin_below_policy",
       "resource_projection_power_margin_low",
       "power_margin_below_observe_policy",
       "projected_battery_depletion",
       "storage_margin_below_observe_policy",
       "projected_storage_overflow",
       "thermal_margin_below_policy",
       "projected_thermal_margin_below_limit"
     ], ["stale_resource_margin_derivation"]}
  ]

  @resource_margin_risk_types [
    "downlink_margin_low",
    "fuel_margin_low",
    "power_margin_low",
    "storage_margin_low",
    "thermal_margin_c_low"
  ]

  for {description, field, source_field, expected_value, stale_value} <-
        @resource_margin_context_contracts do
    test "resource-margin #{description} remains source exact across handoffs", %{
      handoff: handoff
    } do
      assert_risk_context_contract(
        handoff,
        unquote(field),
        {"resource_margin_risk_type", @resource_margin_risk_types},
        unquote(Macro.escape(source_field)),
        unquote(Macro.escape(expected_value)),
        unquote(Macro.escape(stale_value))
      )
    end
  end

  @resource_projection_downlink_context_contracts [
    {"risk type", "resource_projection_pressure_risk_types", ["type", "risk_type"],
     [
       "activity_type_incompatible_with_resource_summary",
       "antenna_unavailable",
       "downlink_completion_gap",
       "downlink_margin_low",
       "power_margin_low",
       "spacecraft_degraded_payload_unavailable",
       "spacecraft_unavailable",
       "storage_margin_low",
       "thermal_margin_c_low"
     ], ["stale_resource_projection_risk"]},
    {"scenario identity", "resource_projection_pressure_scenario_ids", "scenario_id",
     ["leo_projection_selected"], ["stale_scenario"]},
    {"spacecraft identity", "resource_projection_pressure_spacecraft_ids", "spacecraft_id",
     ["leo_projection_selected"], ["stale_spacecraft"]},
    {"ground-station identity", "resource_projection_pressure_ground_station_ids",
     "ground_station_id", ["polar_prime"], ["stale_station"]},
    {"source activity identity", "resource_projection_pressure_source_activity_ids",
     ["source_activity_id", "source_activity_ids"], ["obs_projection_pressure"],
     ["stale_projection_activity"]},
    {"required contacts", "resource_projection_pressure_required_contact_values",
     "required_contacts", [1], [2]},
    {"planned contacts", "resource_projection_pressure_planned_contact_values",
     "planned_contacts", [0], [1]},
    {"required downlink", "resource_projection_pressure_required_downlink_values_mb",
     "required_downlink_mb", [52.0], [53.0]},
    {"planned downlink", "resource_projection_pressure_planned_downlink_values_mb",
     "planned_downlink_mb", [12.0], [13.0]},
    {"start timing", "resource_projection_pressure_start_values_s", "starts_at_s", [1_590.0],
     [1_591.0]},
    {"end timing", "resource_projection_pressure_end_values_s", "ends_at_s", [1_650.0],
     [1_651.0]},
    {"downlink demand source", "resource_projection_pressure_downlink_demand_sources",
     ["downlink_demand_sources"],
     ["resource_projection.projected_downlink_shortfall:obs_projection_pressure"],
     ["resource_projection.stale_downlink_demand:obs_projection_pressure"]},
    {"downlink completion source", "resource_projection_pressure_downlink_completion_sources",
     ["downlink_completion_sources"],
     ["resource_projection.projected_downlink_shortfall:obs_projection_pressure"],
     ["resource_projection.stale_downlink_completion:obs_projection_pressure"]},
    {"feedback source", "resource_projection_pressure_feedback_sources", "feedback_source",
     ["mission_state.source_resource_projection_report"],
     ["mission_state.stale_resource_projection_report"]},
    {"feedback scope", "resource_projection_pressure_feedback_scopes", "feedback_scope",
     ["resource_projection"], ["stale_resource_projection"]},
    {"trust boundary", "resource_projection_pressure_trust_boundaries", "trust_boundary",
     ["mission_state_resource_projection_report"], ["stale_resource_projection_boundary"]},
    {"derivation reason", "resource_projection_pressure_derivation_reasons",
     ["derivation_reasons"],
     [
       "projected_activity_type_incompatible_with_resource_summary",
       "projected_antenna_unavailable",
       "projected_downlink_shortfall",
       "projected_battery_depletion",
       "projected_spacecraft_degraded_payload_unavailable",
       "projected_spacecraft_unavailable",
       "projected_storage_overflow",
       "projected_thermal_margin_below_limit"
     ], ["stale_resource_projection_derivation"]}
  ]

  for {description, field, source_field, expected_value, stale_value} <-
        @resource_projection_downlink_context_contracts do
    test "resource-projection #{description} remains source exact across handoffs", %{
      handoff: handoff
    } do
      assert_risk_context_contract(
        handoff,
        unquote(field),
        {"feedback_scope", "resource_projection"},
        unquote(Macro.escape(source_field)),
        unquote(Macro.escape(expected_value)),
        unquote(Macro.escape(stale_value))
      )
    end
  end

  @resource_projection_resource_context_contracts [
    {"resource fields", "resource_projection_pressure_resource_fields", "resource_field",
     [
       "antenna_available",
       "downlink_margin",
       "power_margin",
       "payload_available",
       "spacecraft_available",
       "storage_margin",
       "thermal_margin_c"
     ], ["stale_resource_field"]},
    {"availability value", "resource_projection_pressure_available_values",
     ["available", "resource_availability_value"], [false], [true]},
    {"degraded value", "resource_projection_pressure_degraded_values", "degraded", [true],
     [false]},
    {"payload availability", "resource_projection_pressure_payload_available_values",
     "payload_available", [false], [true]},
    {"spacecraft availability", "resource_projection_pressure_spacecraft_available_values",
     "spacecraft_available", [false], [true]},
    {"antenna availability", "resource_projection_pressure_antenna_available_values",
     "antenna_available", [false], [true]},
    {"compatibility mode", "resource_projection_pressure_modes", "mode",
     ["resource_activity_type_constraint"], ["stale_resource_mode"]},
    {"incompatible activity types", "resource_projection_pressure_incompatible_activity_types",
     ["incompatible_activity_types"], ["downlink", "observe"], ["maneuver"]},
    {"storage margin", "resource_projection_pressure_storage_margin_values",
     ["storage_margin", "resource_margin_value"], [0.0], [1.0]},
    {"storage margin threshold", "resource_projection_pressure_storage_margin_threshold_values",
     ["storage_margin_threshold", "resource_margin_threshold"], [0.2], [0.3]},
    {"projected storage overflow",
     "resource_projection_pressure_projected_storage_overflow_values_mb",
     "projected_storage_overflow_mb", [25.0], [26.0]},
    {"downlink margin", "resource_projection_pressure_downlink_margin_values",
     ["downlink_margin", "resource_margin_value"], [0.0], [1.0]},
    {"downlink margin threshold", "resource_projection_pressure_downlink_margin_threshold_values",
     ["downlink_margin_threshold", "resource_margin_threshold"], [0.75], [0.8]},
    {"projected downlink shortfall",
     "resource_projection_pressure_projected_downlink_shortfall_values_mb",
     "projected_downlink_shortfall_mb", [10.0], [11.0]},
    {"power margin", "resource_projection_pressure_power_margin_values",
     ["power_margin", "resource_margin_value"], [0.0], [1.0]},
    {"power margin threshold", "resource_projection_pressure_power_margin_threshold_values",
     ["power_margin_threshold", "resource_margin_threshold"], [0.2], [0.3]},
    {"projected battery overuse",
     "resource_projection_pressure_projected_battery_overuse_values_wh",
     "projected_battery_overuse_wh", [5.0], [6.0]},
    {"thermal margin", "resource_projection_pressure_thermal_margin_values_c",
     ["thermal_margin_c", "resource_margin_value"], [-1.5], [-1.0]},
    {"thermal margin threshold", "resource_projection_pressure_thermal_margin_threshold_values_c",
     ["thermal_margin_c_threshold", "resource_margin_threshold"], [0.0], [1.0]},
    {"source quality", "resource_projection_pressure_source_quality_values", "source_quality",
     ["operator_supplied"], ["stale_source_quality"]}
  ]

  for {description, field, source_field, expected_value, stale_value} <-
        @resource_projection_resource_context_contracts do
    test "resource-projection #{description} remains source exact across handoffs", %{
      handoff: handoff
    } do
      assert_risk_context_contract(
        handoff,
        unquote(field),
        {"feedback_scope", "resource_projection"},
        unquote(Macro.escape(source_field)),
        unquote(Macro.escape(expected_value)),
        unquote(Macro.escape(stale_value))
      )
    end
  end
end
