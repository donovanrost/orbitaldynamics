Code.require_file("support.exs", __DIR__)

Code.require_file(
  "../../support/campaign_planner/strategy_recommendation_pressure_handoff_case.ex",
  __DIR__
)

defmodule OrbitalDynamics.CampaignPlanner.StrategyRecommendationPressureHandoffContactAllocationContextTest do
  use OrbitalDynamics.CampaignPlanner.StrategyRecommendationPressureHandoffCase,
    invalid_contact_intent: true

  test "contact allocation risk type remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "contact_allocation_pressure_risk_types",
      {"contact_id", "dl_reservation_conflict"},
      ["type", "risk_type"],
      ["downlink_completion_gap"],
      ["stale_downlink_completion_gap"]
    )
  end

  test "contact allocation contact identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_allocation_pressure_contact_ids",
      {"contact_id", "dl_reservation_conflict"},
      "contact_id",
      ["dl_reservation_conflict"],
      ["stale_dl_reservation_conflict"]
    )
  end

  test "contact allocation scenario identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_allocation_pressure_scenario_ids",
      {"contact_id", "dl_reservation_conflict"},
      "scenario_id",
      ["leo_1"],
      ["stale_leo_1"]
    )
  end

  test "contact allocation spacecraft identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_allocation_pressure_spacecraft_ids",
      {"contact_id", "dl_reservation_conflict"},
      "spacecraft_id",
      ["leo_1"],
      ["stale_leo_1"]
    )
  end

  test "contact allocation station identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_allocation_pressure_ground_station_ids",
      {"contact_id", "dl_reservation_conflict"},
      "ground_station_id",
      ["equator_prime"],
      ["stale_equator_prime"]
    )
  end

  test "contact allocation source activity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_allocation_pressure_source_activity_ids",
      {"contact_id", "dl_reservation_conflict"},
      ["source_activity_id", "source_activity_ids"],
      ["dl_reservation_conflict"],
      ["stale_dl_reservation_conflict"]
    )
  end

  test "contact allocation source window remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_allocation_pressure_source_window_ids",
      {"contact_id", "dl_reservation_conflict"},
      "source_window_id",
      ["window_allocation_deferred"],
      ["stale_window_allocation_deferred"]
    )
  end

  test "contact allocation required contact demand remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_allocation_pressure_required_contact_values",
      {"contact_id", "dl_reservation_conflict"},
      "required_contacts",
      [1],
      [2]
    )
  end

  test "contact allocation planned contact demand remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_allocation_pressure_planned_contact_values",
      {"contact_id", "dl_reservation_conflict"},
      "planned_contacts",
      [0],
      [1]
    )
  end

  test "contact allocation required downlink demand remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_allocation_pressure_required_downlink_values_mb",
      {"contact_id", "dl_reservation_conflict"},
      "required_downlink_mb",
      [43.0],
      [44.0]
    )
  end

  test "contact allocation planned downlink demand remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_allocation_pressure_planned_downlink_values_mb",
      {"contact_id", "dl_reservation_conflict"},
      "planned_downlink_mb",
      [0.0],
      [1.0]
    )
  end

  test "contact allocation start bound remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "contact_allocation_pressure_start_values_s",
      {"contact_id", "dl_reservation_conflict"},
      "starts_at_s",
      [1_620.0],
      [1_621.0]
    )
  end

  test "contact allocation end bound remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "contact_allocation_pressure_end_values_s",
      {"contact_id", "dl_reservation_conflict"},
      "ends_at_s",
      [1_680.0],
      [1_681.0]
    )
  end

  test "contact allocation realized status remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_allocation_pressure_realized_statuses",
      {"contact_id", "dl_reservation_conflict"},
      "realized_status",
      ["deferred"],
      ["selected"]
    )
  end

  test "contact allocation result remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "contact_allocation_pressure_contact_results",
      {"contact_id", "dl_reservation_conflict"},
      "contact_result",
      ["same_station_contention"],
      ["completed"]
    )
  end

  test "contact allocation status remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "contact_allocation_pressure_allocation_statuses",
      {"contact_id", "dl_reservation_conflict"},
      "allocation_status",
      ["deferred"],
      ["selected"]
    )
  end

  test "contact allocation effective status remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_allocation_pressure_effective_allocation_statuses",
      {"contact_id", "dl_reservation_conflict"},
      "effective_allocation_status",
      ["deferred"],
      ["selected"]
    )
  end

  test "contact allocation reason remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "contact_allocation_pressure_allocation_reasons",
      {"contact_id", "dl_reservation_conflict"},
      "allocation_reason",
      ["same_station_contention"],
      ["capacity_available"]
    )
  end

  test "contact allocation review status remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_allocation_pressure_review_statuses",
      {"contact_id", "dl_reservation_conflict"},
      "review_status",
      ["operator_review_required"],
      ["not_required"]
    )
  end

  test "contact allocation approval status remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_allocation_pressure_approval_statuses",
      {"contact_id", "dl_reservation_conflict"},
      "approval_status",
      ["operator_review_required"],
      ["approved"]
    )
  end

  test "contact allocation policy classification remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_allocation_pressure_policy_classifications",
      {"contact_id", "dl_reservation_conflict"},
      "policy_classification",
      ["review_only"],
      ["approved"]
    )
  end

  test "contact allocation policy bundle remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_allocation_pressure_policy_bundle_ids",
      {"contact_id", "dl_reservation_conflict"},
      "policy_bundle_id",
      ["contact_allocation_policy_v1"],
      ["stale_contact_allocation_policy_v1"]
    )
  end

  test "contact allocation reservation identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_allocation_pressure_station_reservation_ids",
      {"contact_id", "dl_reservation_conflict"},
      "station_reservation_id",
      ["reservation_conflict_1"],
      ["stale_reservation_conflict_1"]
    )
  end

  test "contact allocation reservation owner remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_allocation_pressure_station_reserved_by",
      {"contact_id", "dl_reservation_conflict"},
      "station_reserved_by",
      ["ops_team_b"],
      ["stale_ops_team_b"]
    )
  end

  test "contact allocation reservation status remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_allocation_pressure_station_reservation_statuses",
      {"contact_id", "dl_reservation_conflict"},
      "station_reservation_status",
      ["confirmed"],
      ["cancelled"]
    )
  end

  test "contact allocation reservation match remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_allocation_pressure_station_reservation_match_statuses",
      {"contact_id", "dl_reservation_conflict"},
      "station_reservation_match_status",
      ["overlap"],
      ["matched"]
    )
  end

  test "contact allocation calendar entry identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_allocation_pressure_station_calendar_entry_ids",
      {"contact_id", "dl_reservation_conflict"},
      "station_calendar_entry_id",
      ["calendar_allocation_deferred"],
      ["stale_calendar_allocation_deferred"]
    )
  end

  test "contact allocation calendar entry status remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_allocation_pressure_station_calendar_entry_statuses",
      {"contact_id", "dl_reservation_conflict"},
      "station_calendar_entry_status",
      ["reserved"],
      ["available"]
    )
  end

  test "contact allocation calendar direction remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_allocation_pressure_station_calendar_directions",
      {"contact_id", "dl_reservation_conflict"},
      "station_calendar_directions",
      ["downlink"],
      ["uplink"]
    )
  end

  test "contact allocation downlink demand source remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_allocation_pressure_downlink_demand_sources",
      {"contact_id", "dl_reservation_conflict"},
      "downlink_demand_sources",
      ["contact_allocation:dl_reservation_conflict"],
      ["stale_contact_allocation:dl_reservation_conflict"]
    )
  end

  test "contact allocation downlink completion source remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_allocation_pressure_downlink_completion_sources",
      {"contact_id", "dl_reservation_conflict"},
      "downlink_completion_sources",
      ["contact_allocation_report:selected_contacts"],
      ["stale_contact_allocation_report:selected_contacts"]
    )
  end

  test "contact allocation feedback source remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_allocation_pressure_feedback_sources",
      {"contact_id", "dl_reservation_conflict"},
      "feedback_source",
      ["mission_state.source_contact_allocation_reservation_conflict_summary"],
      ["stale.source_contact_allocation_reservation_conflict_summary"]
    )
  end

  test "contact allocation feedback scope remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_allocation_pressure_feedback_scopes",
      {"contact_id", "dl_reservation_conflict"},
      "feedback_scope",
      ["contact_allocation"],
      ["stale_contact_allocation"]
    )
  end

  test "contact allocation trust boundary remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_allocation_pressure_trust_boundaries",
      {"contact_id", "dl_reservation_conflict"},
      "trust_boundary",
      ["mission_state_reservation_conflict_summary"],
      ["stale_mission_state_reservation_conflict_summary"]
    )
  end

  test "contact allocation derivation reason remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_allocation_pressure_derivation_reasons",
      {"contact_id", "dl_reservation_conflict"},
      "derivation_reasons",
      ["contact_allocation_reservation_conflict"],
      ["stale_contact_allocation_reservation_conflict"]
    )
  end

  test "contact intent risk type remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "contact_intent_pressure_risk_types",
      {"contact_id", "contact_intent:selected_blocked"},
      ["type", "risk_type"],
      ["downlink_completion_gap"],
      ["stale_downlink_completion_gap"]
    )
  end

  test "contact intent contact identity remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "contact_intent_pressure_contact_ids",
      {"contact_id", "contact_intent:selected_blocked"},
      "contact_id",
      ["contact_intent:selected_blocked"],
      ["contact_intent:stale_blocked"]
    )
  end

  test "contact intent source activity identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_intent_pressure_source_activity_ids",
      {"contact_id", "contact_intent:selected_blocked"},
      ["source_activity_id", "source_activity_ids"],
      ["dl_contact_intent_selected"],
      ["dl_contact_intent_stale"]
    )
  end

  test "contact intent ground station identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_intent_pressure_ground_station_ids",
      {"contact_id", "contact_intent:selected_blocked"},
      "ground_station_id",
      ["deep_space_net"],
      ["stale_ground_station"]
    )
  end

  test "contact intent required contact demand remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_intent_pressure_required_contact_values",
      {"contact_id", "contact_intent:selected_blocked"},
      "required_contacts",
      [1],
      [2]
    )
  end

  test "contact intent planned contact demand remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_intent_pressure_planned_contact_values",
      {"contact_id", "contact_intent:selected_blocked"},
      "planned_contacts",
      [0],
      [1]
    )
  end

  test "contact intent required downlink demand remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_intent_pressure_required_downlink_values_mb",
      {"contact_id", "contact_intent:selected_blocked"},
      "required_downlink_mb",
      [42.0],
      [43.0]
    )
  end

  test "contact intent planned downlink demand remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_intent_pressure_planned_downlink_values_mb",
      {"contact_id", "contact_intent:selected_blocked"},
      "planned_downlink_mb",
      [0.0],
      [1.0]
    )
  end

  test "contact intent start bound remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "contact_intent_pressure_start_values_s",
      {"contact_id", "contact_intent:selected_blocked"},
      "starts_at_s",
      [1_100.0],
      [1_101.0]
    )
  end

  test "contact intent end bound remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "contact_intent_pressure_end_values_s",
      {"contact_id", "contact_intent:selected_blocked"},
      "ends_at_s",
      [1_160.0],
      [1_161.0]
    )
  end

  test "contact intent source window identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_intent_pressure_source_window_ids",
      {"contact_id", "contact_intent:selected_blocked"},
      "source_window_id",
      ["window_contact_intent_selected"],
      ["window_contact_intent_stale"]
    )
  end

  test "contact intent timeline identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_intent_pressure_timeline_ids",
      {"contact_id", "contact_intent:selected_blocked"},
      "timeline_id",
      ["timeline:contact_intent:selected_blocked"],
      ["timeline:contact_intent:stale_blocked"]
    )
  end

  test "contact intent approval status remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "contact_intent_pressure_approval_statuses",
      {"contact_id", "contact_intent:selected_blocked"},
      "approval_status",
      ["blocked_by_policy"],
      ["approved"]
    )
  end

  test "contact intent required action remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "contact_intent_pressure_required_operator_actions",
      {"contact_id", "contact_intent:selected_blocked"},
      "required_operator_action",
      ["review_contact_intent"],
      ["review_stale_contact_intent"]
    )
  end

  test "contact intent import status remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "contact_intent_pressure_cadence_import_statuses",
      {"contact_id", "contact_intent:selected_blocked"},
      "cadence_import_status",
      ["missing"],
      ["ready"]
    )
  end

  test "contact intent gate status remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "contact_intent_pressure_gate_statuses",
      {"contact_id", "contact_intent:selected_blocked"},
      "contact_intent_gate_status",
      ["blocked_by_policy"],
      ["approved"]
    )
  end

  test "contact intent policy classification remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_intent_pressure_policy_classifications",
      {"contact_id", "contact_intent:selected_blocked"},
      "policy_classification",
      ["blocked_by_policy"],
      ["approved"]
    )
  end

  test "contact intent policy bundle identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_intent_pressure_policy_bundle_ids",
      {"contact_id", "contact_intent:selected_blocked"},
      "policy_bundle_id",
      ["contact_command_review_v1"],
      ["stale_contact_command_review_v1"]
    )
  end

  test "contact intent invalid import flag remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_intent_pressure_invalid_cadence_import_values",
      {"contact_id", "contact_intent:selected_blocked"},
      "invalid_cadence_import",
      [true],
      [false]
    )
  end

  test "contact intent invalid import reason remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_intent_pressure_invalid_cadence_import_reasons",
      {"contact_id", "contact_intent:selected_blocked"},
      "invalid_cadence_import_reason",
      ["missing_cadence_import_row"],
      ["stale_cadence_import_reason"]
    )
  end

  test "contact intent activity validity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_intent_pressure_invalid_activity_input_values",
      {"contact_id", "contact_intent:selected_blocked"},
      "invalid_activity_input",
      [false],
      [true]
    )
  end

  test "invalid contact intent activity reason remains source exact across handoffs", %{
    invalid_contact_intent_handoff: invalid_contact_intent_handoff
  } do
    assert_risk_context_contract(
      invalid_contact_intent_handoff,
      "contact_intent_pressure_invalid_activity_input_reasons",
      {"contact_id", "contact_intent:selected_blocked"},
      "invalid_activity_input_reason",
      ["missing_activity_type"],
      ["stale_invalid_activity_input_reason"]
    )
  end

  test "contact intent station availability remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_intent_pressure_station_availabilities",
      {"contact_id", "contact_intent:selected_blocked"},
      "station_availability",
      ["reserved"],
      ["available"]
    )
  end

  test "contact intent station contention remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_intent_pressure_station_contention_statuses",
      {"contact_id", "contact_intent:selected_blocked"},
      "station_contention_status",
      ["operator_review_required"],
      ["clear"]
    )
  end

  test "contact intent station calendar entry identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_intent_pressure_station_calendar_entry_ids",
      {"contact_id", "contact_intent:selected_blocked"},
      "station_calendar_entry_id",
      ["intent_selected_calendar_entry"],
      ["stale_intent_selected_calendar_entry"]
    )
  end

  test "contact intent station calendar provider identity remains source exact across handoffs",
       %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "contact_intent_pressure_station_calendar_provider_ids",
      {"contact_id", "contact_intent:selected_blocked"},
      "station_calendar_provider_id",
      ["partner_calendar"],
      ["stale_partner_calendar"]
    )
  end

  test "contact intent station calendar provider entry remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_intent_pressure_station_calendar_provider_entry_ids",
      {"contact_id", "contact_intent:selected_blocked"},
      "station_calendar_provider_entry_id",
      ["partner_entry_selected"],
      ["stale_partner_entry_selected"]
    )
  end

  test "contact intent station calendar direction remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_intent_pressure_station_calendar_directions",
      {"contact_id", "contact_intent:selected_blocked"},
      "station_calendar_directions",
      ["downlink"],
      ["uplink"]
    )
  end

  test "contact intent station calendar status remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_intent_pressure_station_calendar_statuses",
      {"contact_id", "contact_intent:selected_blocked"},
      "station_calendar_status",
      ["reserved"],
      ["available"]
    )
  end

  test "contact intent calendar trust boundary remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_intent_pressure_station_calendar_trust_boundary_statuses",
      {"contact_id", "contact_intent:selected_blocked"},
      "station_calendar_trust_boundary_status",
      ["declared"],
      ["verified"]
    )
  end

  test "contact intent station reservation identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_intent_pressure_station_reservation_ids",
      {"contact_id", "contact_intent:selected_blocked"},
      "station_reservation_id",
      ["reservation_intent_selected"],
      ["stale_reservation_intent_selected"]
    )
  end

  test "contact intent station reservation owner remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_intent_pressure_station_reserved_by",
      {"contact_id", "contact_intent:selected_blocked"},
      "station_reserved_by",
      ["partner_team"],
      ["stale_partner_team"]
    )
  end

  test "contact intent station reservation status remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_intent_pressure_station_reservation_statuses",
      {"contact_id", "contact_intent:selected_blocked"},
      "station_reservation_status",
      ["confirmed"],
      ["cancelled"]
    )
  end

  test "contact intent station reservation match remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_intent_pressure_station_reservation_match_statuses",
      {"contact_id", "contact_intent:selected_blocked"},
      "station_reservation_match_status",
      ["unmatched_overlap"],
      ["matched"]
    )
  end

  test "contact intent feedback source remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "contact_intent_pressure_feedback_sources",
      {"contact_id", "contact_intent:selected_blocked"},
      "feedback_source",
      ["mission_state.source_contact_intent.rows"],
      ["mission_state.stale_contact_intent.rows"]
    )
  end

  test "contact intent feedback scope remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "contact_intent_pressure_feedback_scopes",
      {"contact_id", "contact_intent:selected_blocked"},
      "feedback_scope",
      ["contact_intent"],
      ["stale_contact_intent"]
    )
  end

  test "contact intent trust boundary remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "contact_intent_pressure_trust_boundaries",
      {"contact_id", "contact_intent:selected_blocked"},
      "trust_boundary",
      ["mission_state_contact_intent_review"],
      ["mission_state_stale_contact_intent_review"]
    )
  end

  test "contact intent derivation reasons remain source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_intent_pressure_derivation_reasons",
      {"contact_id", "contact_intent:selected_blocked"},
      "derivation_reasons",
      [
        "contact_intent_blocked_by_policy",
        "review_contact_intent",
        "reserved",
        "unmatched_overlap"
      ],
      ["stale_contact_intent_derivation"]
    )
  end
end
