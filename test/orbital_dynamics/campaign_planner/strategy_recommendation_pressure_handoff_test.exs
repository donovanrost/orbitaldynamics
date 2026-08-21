Code.require_file("support.exs", __DIR__)

Code.require_file(
  "../../support/campaign_planner/strategy_recommendation_pressure_handoff_case.ex",
  __DIR__
)

defmodule OrbitalDynamics.CampaignPlanner.StrategyRecommendationPressureHandoffTest do
  use OrbitalDynamics.CampaignPlanner.StrategyRecommendationPressureHandoffCase,
    expected_handoff: true,
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

  @approval_boundary_context_contracts [
    {"identity", "approval_boundary_ids", "approval_boundary", ["command_execution"],
     ["stale_command_execution"]},
    {"status", "approval_boundary_statuses", "approval_boundary_status",
     ["operator_review_required"], ["stale_operator_review_required"]},
    {"reason", "approval_boundary_reasons", "approval_boundary_reason",
     ["command execution requires flight director approval"], ["stale_approval_reason"]},
    {"automation boundary", "automation_boundaries", "automation_boundary",
     ["no_command_execution"], ["stale_automation_boundary"]},
    {"execution boundary", "execution_boundaries", "execution_boundary",
     ["flight_director_approval"], ["stale_execution_boundary"]},
    {"import classification", "approval_boundary_import_classifications", "import_classification",
     ["review_only"], ["stale_import_classification"]},
    {"required operator action", "approval_boundary_required_operator_actions",
     "required_operator_action", ["review_approval_boundary"], ["stale_operator_action"]},
    {"required authority", "approval_boundary_required_authorities", "required_authority",
     ["flight_director"], ["stale_authority"]},
    {"policy bundle", "approval_boundary_policy_bundle_ids", "policy_bundle_id",
     ["flight_rules_v3"], ["stale_policy_bundle"]},
    {"rule identity", "approval_boundary_rule_ids", "rule_id",
     ["no_unapproved_command_execution"], ["stale_rule"]},
    {"feedback source", "approval_boundary_feedback_sources", "feedback_source",
     ["mission_state.source_approval_boundary_policy.rules"],
     ["mission_state.stale_approval_boundary_policy.rules"]},
    {"feedback scope", "approval_boundary_feedback_scopes", "feedback_scope",
     ["approval_boundary"], ["stale_approval_boundary"]},
    {"feedback key", "approval_boundary_feedback_keys", "feedback_key",
     ["no_unapproved_command_execution"], ["stale_feedback_key"]},
    {"trust boundary", "approval_boundary_trust_boundaries", "trust_boundary",
     ["mission_state_approval_boundary_policy"], ["stale_approval_boundary_policy"]}
  ]

  for {description, field, source_field, expected_value, stale_value} <-
        @approval_boundary_context_contracts do
    test "approval-boundary #{description} remains source exact across handoffs", %{
      handoff: handoff
    } do
      assert_risk_context_contract(
        handoff,
        unquote(field),
        {"feedback_scope", "approval_boundary"},
        unquote(source_field),
        unquote(expected_value),
        unquote(stale_value)
      )
    end
  end

  test "provider request expiration risk context remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_expiration_context_contract(
      handoff,
      "provider_reservation_request_station_reservation_expiration_statuses",
      {"contact_id", "dl_provider_review"},
      "active"
    )
  end

  test "provider request contact identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "provider_reservation_request_contact_ids",
      {"contact_id", "dl_provider_review"},
      "contact_id",
      ["dl_provider_review"],
      ["stale_dl_provider_review"]
    )
  end

  test "provider request source activity identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "provider_reservation_request_source_activity_ids",
      {"contact_id", "dl_provider_review"},
      ["source_activity_id", "source_activity_ids"],
      ["dl_provider_review"],
      ["stale_dl_provider_review"]
    )
  end

  test "provider request ground-station identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "provider_reservation_request_ground_station_ids",
      {"contact_id", "dl_provider_review"},
      "ground_station_id",
      ["equator_prime"],
      ["stale_equator_prime"]
    )
  end

  test "provider request direction remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "provider_reservation_request_directions",
      {"contact_id", "dl_provider_review"},
      "direction",
      ["downlink"],
      ["uplink"]
    )
  end

  test "provider request reservation identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "provider_reservation_request_station_reservation_ids",
      {"contact_id", "dl_provider_review"},
      "station_reservation_id",
      ["provider_reservation_review"],
      ["stale_provider_reservation_review"]
    )
  end

  test "provider request reservation owner remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "provider_reservation_request_station_reserved_by",
      {"contact_id", "dl_provider_review"},
      "station_reserved_by",
      ["partner_calendar"],
      ["stale_partner_calendar"]
    )
  end

  test "provider request reservation status remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "provider_reservation_request_station_reservation_statuses",
      {"contact_id", "dl_provider_review"},
      "station_reservation_status",
      ["confirmed"],
      ["cancelled"]
    )
  end

  test "provider request reservation match remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "provider_reservation_request_station_reservation_match_statuses",
      {"contact_id", "dl_provider_review"},
      "station_reservation_match_status",
      ["overlap"],
      ["matched"]
    )
  end

  test "provider request status remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "provider_reservation_request_statuses",
      {"contact_id", "dl_provider_review"},
      "provider_reservation_request_status",
      ["review_required"],
      ["request_ready"]
    )
  end

  test "provider request row scope remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "provider_reservation_request_row_scopes",
      {"contact_id", "dl_provider_review"},
      "provider_reservation_row_scope",
      ["review"],
      ["request"]
    )
  end

  test "provider request required action remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "provider_reservation_request_required_operator_actions",
      {"contact_id", "dl_provider_review"},
      "required_operator_action",
      ["review_provider_reservation_request"],
      ["submit_provider_reservation_request"]
    )
  end

  test "provider request assumptions remain source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "provider_reservation_request_assumption_maps",
      {"contact_id", "dl_provider_review"},
      "assumptions",
      [
        %{
          "provider_reservation_execution" => "not_performed_by_strategy_branch",
          "schedule_mutation" => "not_performed_by_strategy_branch",
          "operator_authority" => "not_granted_by_strategy_branch"
        }
      ],
      [
        %{
          "provider_reservation_execution" => "performed_by_strategy_branch",
          "schedule_mutation" => "performed_by_strategy_branch",
          "operator_authority" => "granted_by_strategy_branch"
        }
      ]
    )
  end

  test "provider request feedback source remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "provider_reservation_request_feedback_sources",
      {"contact_id", "dl_provider_review"},
      "feedback_source",
      ["mission_state.source_contact_allocation_provider_reservation_request_summary"],
      ["stale.source_contact_allocation_provider_reservation_request_summary"]
    )
  end

  test "provider request feedback scope remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "provider_reservation_request_feedback_scopes",
      {"contact_id", "dl_provider_review"},
      "feedback_scope",
      ["contact_allocation_provider_reservation_request"],
      ["stale_contact_allocation_provider_reservation_request"]
    )
  end

  test "provider request trust boundary remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "provider_reservation_request_trust_boundaries",
      {"contact_id", "dl_provider_review"},
      "trust_boundary",
      ["mission_state_provider_reservation_request_summary"],
      ["stale_mission_state_provider_reservation_request_summary"]
    )
  end

  test "capacity-pack risk contact identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "capacity_pack_risk_contact_ids",
      {"contact_id", "dl_capacity_overflow"},
      "contact_id",
      ["dl_capacity_overflow"],
      ["stale_dl_capacity_overflow"]
    )
  end

  test "capacity-pack risk source activity identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "capacity_pack_risk_source_activity_ids",
      {"contact_id", "dl_capacity_overflow"},
      ["source_activity_id", "source_activity_ids"],
      ["dl_capacity_overflow"],
      ["stale_dl_capacity_overflow"]
    )
  end

  test "capacity-pack risk ground-station identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "capacity_pack_risk_ground_station_ids",
      {"contact_id", "dl_capacity_overflow"},
      "ground_station_id",
      ["equator_prime"],
      ["stale_equator_prime"]
    )
  end

  test "capacity-pack risk group identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "capacity_pack_risk_group_ids",
      {"contact_id", "dl_capacity_overflow"},
      "capacity_pack_group_id",
      ["capacity_pack_equator_prime"],
      ["stale_capacity_pack_equator_prime"]
    )
  end

  test "capacity-pack risk status remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "capacity_pack_risk_statuses",
      {"contact_id", "dl_capacity_overflow"},
      "capacity_pack_status",
      ["deferred_by_reduced_station_capacity_pack"],
      ["stale_capacity_pack_status"]
    )
  end

  test "capacity-pack risk capacity fraction remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "capacity_pack_risk_capacity_fraction_values",
      {"contact_id", "dl_capacity_overflow"},
      "capacity_pack_capacity_fraction",
      [0.5],
      [0.75]
    )
  end

  test "capacity-pack risk used fraction remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "capacity_pack_risk_used_fraction_values",
      {"contact_id", "dl_capacity_overflow"},
      "capacity_pack_used_fraction",
      [0.5],
      [0.75]
    )
  end

  test "capacity-pack risk unused fraction remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "capacity_pack_risk_unused_fraction_values",
      {"contact_id", "dl_capacity_overflow"},
      "capacity_pack_unused_fraction",
      [0.0],
      [0.25]
    )
  end

  test "capacity-pack risk required fraction remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "capacity_pack_risk_required_capacity_fraction_values",
      {"contact_id", "dl_capacity_overflow"},
      "required_capacity_fraction",
      [0.25],
      [0.5]
    )
  end

  test "capacity-pack risk required-fraction source remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "capacity_pack_risk_required_capacity_fraction_sources",
      {"contact_id", "dl_capacity_overflow"},
      "required_capacity_fraction_source",
      ["contact_required_capacity_fraction"],
      ["stale_required_capacity_fraction_source"]
    )
  end

  test "capacity-pack risk derivation reasons remain source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "capacity_pack_risk_derivation_reasons",
      {"contact_id", "dl_capacity_overflow"},
      "derivation_reasons",
      ["contact_contention_deferred", "deferred_by_reduced_station_capacity_pack"],
      ["stale_capacity_pack_derivation"]
    )
  end

  test "capacity-pack risk feedback source remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "capacity_pack_risk_feedback_sources",
      {"contact_id", "dl_capacity_overflow"},
      "feedback_source",
      ["mission_state.source_contact_allocation_capacity_pack_summary"],
      ["stale_capacity_pack_feedback_source"]
    )
  end

  test "capacity-pack risk feedback scope remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "capacity_pack_risk_feedback_scopes",
      {"contact_id", "dl_capacity_overflow"},
      "feedback_scope",
      ["contact_contention_resolution"],
      ["stale_contact_contention_resolution"]
    )
  end

  test "capacity-pack risk trust boundary remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "capacity_pack_risk_trust_boundaries",
      {"contact_id", "dl_capacity_overflow"},
      "trust_boundary",
      ["mission_state_capacity_pack_summary"],
      ["stale_mission_state_capacity_pack_summary"]
    )
  end

  test "contention-resolution risk type remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "contact_contention_resolution_pressure_risk_types",
      {"contact_id", "dl_capacity_overflow"},
      ["type", "risk_type"],
      ["downlink_completion_gap"],
      ["stale_contention_resolution_risk"]
    )
  end

  test "contention-resolution contact identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_contention_resolution_pressure_contact_ids",
      {"contact_id", "dl_capacity_overflow"},
      "contact_id",
      ["dl_capacity_overflow"],
      ["stale_dl_capacity_overflow"]
    )
  end

  test "contention-resolution selected-contact identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_contention_resolution_pressure_selected_contact_ids",
      {"contact_id", "dl_capacity_overflow"},
      "selected_contact_id",
      ["dl_capacity_selected"],
      ["stale_dl_capacity_selected"]
    )
  end

  test "contention-resolution scenario identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_contention_resolution_pressure_scenario_ids",
      {"contact_id", "dl_capacity_overflow"},
      "scenario_id",
      ["leo_1"],
      ["stale_leo_1"]
    )
  end

  test "contention-resolution spacecraft identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_contention_resolution_pressure_spacecraft_ids",
      {"contact_id", "dl_capacity_overflow"},
      "spacecraft_id",
      ["leo_1"],
      ["stale_leo_1"]
    )
  end

  test "contention-resolution ground-station identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_contention_resolution_pressure_ground_station_ids",
      {"contact_id", "dl_capacity_overflow"},
      "ground_station_id",
      ["equator_prime"],
      ["stale_equator_prime"]
    )
  end

  test "contention-resolution source-activity identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_contention_resolution_pressure_source_activity_ids",
      {"contact_id", "dl_capacity_overflow"},
      ["source_activity_id", "source_activity_ids"],
      ["dl_capacity_overflow"],
      ["stale_dl_capacity_overflow"]
    )
  end

  test "contention-resolution source-window identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_contention_resolution_pressure_source_window_ids",
      {"contact_id", "dl_capacity_overflow"},
      "source_window_id",
      ["window_capacity_overflow"],
      ["stale_window_capacity_overflow"]
    )
  end

  test "contention-resolution required-contact demand remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_contention_resolution_pressure_required_contact_values",
      {"contact_id", "dl_capacity_overflow"},
      "required_contacts",
      [1],
      [2]
    )
  end

  test "contention-resolution planned-contact demand remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_contention_resolution_pressure_planned_contact_values",
      {"contact_id", "dl_capacity_overflow"},
      "planned_contacts",
      [0],
      [1]
    )
  end

  test "contention-resolution required-downlink demand remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_contention_resolution_pressure_required_downlink_values_mb",
      {"contact_id", "dl_capacity_overflow"},
      "required_downlink_mb",
      [47.0],
      [48.0]
    )
  end

  test "contention-resolution planned-downlink demand remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_contention_resolution_pressure_planned_downlink_values_mb",
      {"contact_id", "dl_capacity_overflow"},
      "planned_downlink_mb",
      [0.0],
      [1.0]
    )
  end

  test "contention-resolution start bound remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_contention_resolution_pressure_start_values_s",
      {"contact_id", "dl_capacity_overflow"},
      "starts_at_s",
      [1_560.0],
      [1_559.0]
    )
  end

  test "contention-resolution end bound remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "contact_contention_resolution_pressure_end_values_s",
      {"contact_id", "dl_capacity_overflow"},
      "ends_at_s",
      [1_620.0],
      [1_621.0]
    )
  end

  test "contention-resolution selected priority source remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_contention_resolution_pressure_selected_priority_sources",
      {"contact_id", "dl_capacity_overflow"},
      "selected_priority_source",
      ["policy_contact_priority"],
      ["stale_contact_priority"]
    )
  end

  test "contention-resolution selection reason remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_contention_resolution_pressure_selection_reasons",
      {"contact_id", "dl_capacity_overflow"},
      "selection_reason",
      ["highest_priority_highest_score"],
      ["stale_selection_reason"]
    )
  end

  test "contention-resolution selection rule remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_contention_resolution_pressure_resolution_selection_rules",
      {"contact_id", "dl_capacity_overflow"},
      "resolution_selection_rule",
      ["highest_priority_highest_score"],
      ["stale_selection_rule"]
    )
  end

  test "contention-resolution priority override count remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_contention_resolution_pressure_priority_override_count_values",
      {"contact_id", "dl_capacity_overflow"},
      "resolution_priority_override_count",
      [2],
      [3]
    )
  end

  test "contention-resolution priority override contacts remain source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_contention_resolution_pressure_priority_override_contact_ids",
      {"contact_id", "dl_capacity_overflow"},
      "resolution_priority_override_contact_ids",
      ["dl_capacity_selected", "dl_capacity_overflow"],
      ["stale_dl_capacity_selected"]
    )
  end

  test "contention-resolution review status remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_contention_resolution_pressure_review_statuses",
      {"contact_id", "dl_capacity_overflow"},
      "review_status",
      ["operator_review_required"],
      ["stale_review_status"]
    )
  end

  test "contention-resolution demand source remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_contention_resolution_pressure_downlink_demand_sources",
      {"contact_id", "dl_capacity_overflow"},
      "downlink_demand_sources",
      ["contention_resolution.required_downlink:dl_capacity_overflow"],
      ["stale_contention_resolution_demand_source"]
    )
  end

  test "contention-resolution completion source remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_contention_resolution_pressure_downlink_completion_sources",
      {"contact_id", "dl_capacity_overflow"},
      "downlink_completion_sources",
      ["contact_contention_resolution_report:recommendations"],
      ["stale_contention_resolution_completion_source"]
    )
  end

  test "contention-resolution feedback source remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_contention_resolution_pressure_feedback_sources",
      {"contact_id", "dl_capacity_overflow"},
      "feedback_source",
      ["mission_state.source_contact_allocation_capacity_pack_summary"],
      ["stale_contention_resolution_feedback_source"]
    )
  end

  test "contention-resolution feedback scope remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_contention_resolution_pressure_feedback_scopes",
      {"contact_id", "dl_capacity_overflow"},
      "feedback_scope",
      ["contact_contention_resolution"],
      ["stale_contact_contention_resolution"]
    )
  end

  test "contention-resolution trust boundary remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_contention_resolution_pressure_trust_boundaries",
      {"contact_id", "dl_capacity_overflow"},
      "trust_boundary",
      ["mission_state_capacity_pack_summary"],
      ["stale_mission_state_capacity_pack_summary"]
    )
  end

  test "contention-resolution derivation reasons remain source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_contention_resolution_pressure_derivation_reasons",
      {"contact_id", "dl_capacity_overflow"},
      "derivation_reasons",
      ["contact_contention_deferred", "deferred_by_reduced_station_capacity_pack"],
      ["stale_contention_resolution_derivation"]
    )
  end

  test "contact-contention risk type remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "contact_contention_pressure_risk_types",
      {"contact_id", "dl_contention_conflict"},
      ["type", "risk_type"],
      ["downlink_completion_gap"],
      ["stale_contact_contention_risk"]
    )
  end

  test "contact-contention contact identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_contention_pressure_contact_ids",
      {"contact_id", "dl_contention_conflict"},
      "contact_id",
      ["dl_contention_conflict"],
      ["stale_dl_contention_conflict"]
    )
  end

  test "contact-contention scenario identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_contention_pressure_scenario_ids",
      {"contact_id", "dl_contention_conflict"},
      "scenario_id",
      ["leo_1"],
      ["stale_leo_1"]
    )
  end

  test "contact-contention spacecraft identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_contention_pressure_spacecraft_ids",
      {"contact_id", "dl_contention_conflict"},
      "spacecraft_id",
      ["leo_1"],
      ["stale_leo_1"]
    )
  end

  test "contact-contention ground-station identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_contention_pressure_ground_station_ids",
      {"contact_id", "dl_contention_conflict"},
      "ground_station_id",
      ["equator_prime"],
      ["stale_equator_prime"]
    )
  end

  test "contact-contention source-activity identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_contention_pressure_source_activity_ids",
      {"contact_id", "dl_contention_conflict"},
      ["source_activity_id", "source_activity_ids"],
      ["dl_contention_conflict"],
      ["stale_dl_contention_conflict"]
    )
  end

  test "contact-contention source-window identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_contention_pressure_source_window_ids",
      {"contact_id", "dl_contention_conflict"},
      ["source_window_id", "source_window_ids"],
      ["window_contention_conflict", "window_contention_primary"],
      ["stale_window_contention"]
    )
  end

  test "contact-contention required-contact demand remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_contention_pressure_required_contact_values",
      {"contact_id", "dl_contention_conflict"},
      "required_contacts",
      [1],
      [2]
    )
  end

  test "contact-contention planned-contact demand remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_contention_pressure_planned_contact_values",
      {"contact_id", "dl_contention_conflict"},
      "planned_contacts",
      [0],
      [1]
    )
  end

  test "contact-contention required-downlink demand remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_contention_pressure_required_downlink_values_mb",
      {"contact_id", "dl_contention_conflict"},
      "required_downlink_mb",
      [39.0],
      [40.0]
    )
  end

  test "contact-contention planned-downlink demand remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_contention_pressure_planned_downlink_values_mb",
      {"contact_id", "dl_contention_conflict"},
      "planned_downlink_mb",
      [0.0],
      [1.0]
    )
  end

  test "contact-contention start bound remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "contact_contention_pressure_start_values_s",
      {"contact_id", "dl_contention_conflict"},
      "starts_at_s",
      [1_580.0],
      [1_579.0]
    )
  end

  test "contact-contention end bound remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "contact_contention_pressure_end_values_s",
      {"contact_id", "dl_contention_conflict"},
      "ends_at_s",
      [1_640.0],
      [1_641.0]
    )
  end

  test "contact-contention group identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_contention_pressure_group_ids",
      {"contact_id", "dl_contention_conflict"},
      "contention_group_id",
      ["station:equator_prime:contention:selected"],
      ["station:equator_prime:contention:stale"]
    )
  end

  test "contact-contention resource scope remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_contention_pressure_resource_scopes",
      {"contact_id", "dl_contention_conflict"},
      "contention_resource_scope",
      ["ground_station"],
      ["spacecraft"]
    )
  end

  test "contact-contention contact set remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "contact_contention_pressure_contention_contact_ids",
      {"contact_id", "dl_contention_conflict"},
      ["contention_contact_ids"],
      ["dl_contention_primary", "dl_contention_conflict"],
      ["stale_dl_contention"]
    )
  end

  test "contact-contention required operator action remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_contention_pressure_required_operator_actions",
      {"contact_id", "dl_contention_conflict"},
      "required_operator_action",
      ["review_contact_contention"],
      ["accept_contact_contention"]
    )
  end

  test "contact-contention approval status remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_contention_pressure_approval_statuses",
      {"contact_id", "dl_contention_conflict"},
      "approval_status",
      ["operator_review_required"],
      ["approved"]
    )
  end

  test "contact-contention operator-action reason remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_contention_pressure_operator_action_reasons",
      {"contact_id", "dl_contention_conflict"},
      "operator_action_reason",
      ["same_station_overlapping_contact_windows"],
      ["stale_contention_reason"]
    )
  end

  test "contact-contention downlink-demand source remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_contention_pressure_downlink_demand_sources",
      {"contact_id", "dl_contention_conflict"},
      ["downlink_demand_sources"],
      ["contact_contention.required_downlink:dl_contention_conflict"],
      ["stale_contact_contention_demand"]
    )
  end

  test "contact-contention completion source remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_contention_pressure_downlink_completion_sources",
      {"contact_id", "dl_contention_conflict"},
      ["downlink_completion_sources"],
      ["contact_contention_report:conflict_groups"],
      ["stale_contact_contention_completion"]
    )
  end

  test "contact-contention feedback source remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_contention_pressure_feedback_sources",
      {"contact_id", "dl_contention_conflict"},
      "feedback_source",
      ["mission_state.source_contact_contention_report.conflict_groups"],
      ["stale_contact_contention_feedback"]
    )
  end

  test "contact-contention feedback scope remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_contention_pressure_feedback_scopes",
      {"contact_id", "dl_contention_conflict"},
      "feedback_scope",
      ["contact_contention"],
      ["stale_contact_contention"]
    )
  end

  test "contact-contention trust boundary remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_contention_pressure_trust_boundaries",
      {"contact_id", "dl_contention_conflict"},
      "trust_boundary",
      ["mission_state_contact_contention_report"],
      ["stale_contact_contention_boundary"]
    )
  end

  test "contact-contention derivation reasons remain source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_contention_pressure_derivation_reasons",
      {"contact_id", "dl_contention_conflict"},
      ["derivation_reasons"],
      [
        "contact_contention_conflict",
        "same_station_overlapping_contact_windows",
        "ground_station",
        "operator_review_required"
      ],
      ["stale_contact_contention_reason"]
    )
  end

  test "contact-filter risk type remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "contact_filter_pressure_risk_types",
      {"contact_id", "dl_contact_filter_suppressed"},
      ["type", "risk_type"],
      ["downlink_completion_gap"],
      ["stale_contact_filter_risk"]
    )
  end

  test "contact-filter contact identity remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "contact_filter_pressure_contact_ids",
      {"contact_id", "dl_contact_filter_suppressed"},
      "contact_id",
      ["dl_contact_filter_suppressed"],
      ["stale_dl_contact_filter_suppressed"]
    )
  end

  test "contact-filter scenario identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_filter_pressure_scenario_ids",
      {"contact_id", "dl_contact_filter_suppressed"},
      "scenario_id",
      ["leo_1"],
      ["stale_leo_1"]
    )
  end

  test "contact-filter spacecraft identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_filter_pressure_spacecraft_ids",
      {"contact_id", "dl_contact_filter_suppressed"},
      "spacecraft_id",
      ["leo_1"],
      ["stale_leo_1"]
    )
  end

  test "contact-filter ground-station identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_filter_pressure_ground_station_ids",
      {"contact_id", "dl_contact_filter_suppressed"},
      "ground_station_id",
      ["goldstone"],
      ["stale_goldstone"]
    )
  end

  test "contact-filter source-activity identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_filter_pressure_source_activity_ids",
      {"contact_id", "dl_contact_filter_suppressed"},
      ["source_activity_id", "source_activity_ids"],
      ["dl_contact_filter_suppressed"],
      ["stale_dl_contact_filter_suppressed"]
    )
  end

  test "contact-filter source-window identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_filter_pressure_source_window_ids",
      {"contact_id", "dl_contact_filter_suppressed"},
      "source_window_id",
      ["window_contact_filter_suppressed"],
      ["stale_window_contact_filter_suppressed"]
    )
  end

  test "contact-filter required-contact demand remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_filter_pressure_required_contact_values",
      {"contact_id", "dl_contact_filter_suppressed"},
      "required_contacts",
      [1],
      [2]
    )
  end

  test "contact-filter planned-contact demand remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_filter_pressure_planned_contact_values",
      {"contact_id", "dl_contact_filter_suppressed"},
      "planned_contacts",
      [0],
      [1]
    )
  end

  test "contact-filter required-downlink demand remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_filter_pressure_required_downlink_values_mb",
      {"contact_id", "dl_contact_filter_suppressed"},
      "required_downlink_mb",
      [38.0],
      [39.0]
    )
  end

  test "contact-filter planned-downlink demand remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_filter_pressure_planned_downlink_values_mb",
      {"contact_id", "dl_contact_filter_suppressed"},
      "planned_downlink_mb",
      [0.0],
      [1.0]
    )
  end

  test "contact-filter start bound remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "contact_filter_pressure_start_values_s",
      {"contact_id", "dl_contact_filter_suppressed"},
      "starts_at_s",
      [1_165.0],
      [1_164.0]
    )
  end

  test "contact-filter end bound remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "contact_filter_pressure_end_values_s",
      {"contact_id", "dl_contact_filter_suppressed"},
      "ends_at_s",
      [1_225.0],
      [1_226.0]
    )
  end

  test "contact-filter suppression reason remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_filter_pressure_suppressed_reasons",
      {"contact_id", "dl_contact_filter_suppressed"},
      "suppressed_reason",
      ["station_reserved"],
      ["stale_suppression_reason"]
    )
  end

  test "contact-filter review status remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "contact_filter_pressure_review_statuses",
      {"contact_id", "dl_contact_filter_suppressed"},
      "review_status",
      ["operator_review_required"],
      ["not_required"]
    )
  end

  test "contact-filter reservation identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_filter_pressure_station_reservation_ids",
      {"contact_id", "dl_contact_filter_suppressed"},
      "station_reservation_id",
      ["reservation_contact_filter"],
      ["stale_reservation_contact_filter"]
    )
  end

  test "contact-filter reservation owner remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_filter_pressure_station_reserved_by",
      {"contact_id", "dl_contact_filter_suppressed"},
      "station_reserved_by",
      ["partner_calendar"],
      ["stale_partner_calendar"]
    )
  end

  test "contact-filter reservation status remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_filter_pressure_station_reservation_statuses",
      {"contact_id", "dl_contact_filter_suppressed"},
      "station_reservation_status",
      ["confirmed"],
      ["cancelled"]
    )
  end

  test "contact-filter reservation match remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_filter_pressure_station_reservation_match_statuses",
      {"contact_id", "dl_contact_filter_suppressed"},
      "station_reservation_match_status",
      ["overlap"],
      ["matched"]
    )
  end

  test "contact-filter calendar-entry identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_filter_pressure_station_calendar_entry_ids",
      {"contact_id", "dl_contact_filter_suppressed"},
      "station_calendar_entry_id",
      ["calendar_contact_filter_suppressed"],
      ["stale_calendar_contact_filter_suppressed"]
    )
  end

  test "contact-filter calendar-entry status remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_filter_pressure_station_calendar_entry_statuses",
      {"contact_id", "dl_contact_filter_suppressed"},
      "station_calendar_entry_status",
      ["reserved"],
      ["available"]
    )
  end

  test "contact-filter downlink-demand source remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_filter_pressure_downlink_demand_sources",
      {"contact_id", "dl_contact_filter_suppressed"},
      ["downlink_demand_sources"],
      ["contact_filter:dl_contact_filter_suppressed"],
      ["stale_contact_filter_demand"]
    )
  end

  test "contact-filter completion source remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_filter_pressure_downlink_completion_sources",
      {"contact_id", "dl_contact_filter_suppressed"},
      ["downlink_completion_sources"],
      ["contact_filter_report:suppressed_candidates"],
      ["stale_contact_filter_completion"]
    )
  end

  test "contact-filter feedback source remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "contact_filter_pressure_feedback_sources",
      {"contact_id", "dl_contact_filter_suppressed"},
      "feedback_source",
      ["mission_state.source_contact_filter_report.suppressed_candidates"],
      ["stale_contact_filter_feedback"]
    )
  end

  test "contact-filter feedback scope remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "contact_filter_pressure_feedback_scopes",
      {"contact_id", "dl_contact_filter_suppressed"},
      "feedback_scope",
      ["contact_filter"],
      ["stale_contact_filter"]
    )
  end

  test "contact-filter trust boundary remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "contact_filter_pressure_trust_boundaries",
      {"contact_id", "dl_contact_filter_suppressed"},
      "trust_boundary",
      ["mission_state_contact_filter_report"],
      ["stale_contact_filter_boundary"]
    )
  end

  test "contact-filter derivation reasons remain source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "contact_filter_pressure_derivation_reasons",
      {"contact_id", "dl_contact_filter_suppressed"},
      ["derivation_reasons"],
      ["contact_filter_suppressed", "station_reserved"],
      ["stale_contact_filter_reason"]
    )
  end

  test "strategy recommendation pressure fields propagate through review and import handoffs", %{
    artifact: artifact,
    expected_handoff: expected_handoff,
    handoff: handoff
  } do
    source_window_context_fields = ~w(
      branch_source_window_ids
      branch_source_window_count
      branch_source_window_bounds
      branch_source_window_bound_count
      branch_untimed_source_window_ids
      branch_untimed_source_window_count
      branch_partially_timed_source_window_ids
      branch_partially_timed_source_window_count
      branch_source_window_timing_coverage_status
    )

    operational_event_fields = ~w(
      branch_feedback_sources
      branch_feedback_scopes
      branch_contact_results
      branch_contact_allocation_statuses
      branch_contact_allocation_effective_statuses
      branch_contact_allocation_reasons
      branch_contact_allocation_review_statuses
      branch_contact_allocation_approval_statuses
      branch_contact_allocation_policy_classifications
      branch_realized_statuses
      branch_transition_types
      branch_transition_categories
      branch_transition_reasons
      branch_requires_operator_review
      branch_requires_operator_review_count
      branch_source_activity_ids
    )

    execution_uncertainty_fields = ~w(
      branch_missed_downlink_activity_ids
      branch_maneuver_execution_uncertainty_activity_ids
      branch_maneuver_execution_uncertainty_timeline_ids
      branch_maneuver_execution_uncertainty_maneuver_ids
      branch_maneuver_execution_uncertainty_statuses
      branch_maneuver_execution_uncertainty_sources
      branch_maneuver_execution_uncertainty_max_timing_3sigma_s
      branch_maneuver_execution_uncertainty_max_delta_v_3sigma_magnitude_km_s
    )

    operational_readiness_fields = ~w(
      branch_operational_readiness_levels
      branch_operational_readiness_import_classifications
      branch_operational_readiness_statuses
      branch_operational_readiness_gate_ids
      branch_operational_readiness_gate_statuses
      branch_operational_readiness_gate_classifications
      branch_operational_readiness_review_required_gate_ids
      branch_operational_readiness_analysis_only_gate_ids
      branch_operational_readiness_blocked_gate_ids
      branch_operational_readiness_non_passed_gate_ids
    )

    feedback_detail_fields = ~w(
      image_quality_score
      image_quality_score_source
      image_quality_statuses
      image_quality_sources
      cloud_cover_fraction
      cloud_cover_fraction_source
      blur_score
      blur_score_source
      maneuver_success_factor
      maneuver_success_factor_source
      command_success_factor
      command_success_factor_source
      feedback_weight_sources
    )

    review_operational_event_fields =
      operational_event_fields --
        ~w(
          branch_contact_allocation_statuses
          branch_contact_allocation_effective_statuses
          branch_contact_allocation_reasons
          branch_contact_allocation_review_statuses
          branch_contact_allocation_approval_statuses
          branch_contact_allocation_policy_classifications
        )

    branch_context_fields =
      source_window_context_fields ++
        [
          "branch_earliest_starts_at_s",
          "branch_latest_ends_at_s",
          "branch_station_reservation_expiration_statuses",
          "branch_max_latency_s",
          "branch_planned_latency_s",
          "branch_required_contacts",
          "branch_planned_contacts",
          "branch_required_downlink_mb",
          "branch_planned_downlink_mb",
          "capacity_pack_group_ids",
          "capacity_pack_statuses",
          "capacity_pack_min_capacity_fraction",
          "capacity_pack_max_used_fraction",
          "capacity_pack_max_required_capacity_fraction",
          "capacity_pack_total_required_capacity_fraction",
          "capacity_pack_required_capacity_sources"
        ]

    capacity_pack_direction_fields = [
      "capacity_pack_contact_ids_by_direction",
      "capacity_pack_selected_contact_ids_by_direction",
      "capacity_pack_deferred_contact_ids_by_direction",
      "capacity_pack_required_capacity_fraction_by_direction",
      "capacity_pack_selected_required_capacity_fraction_by_direction",
      "capacity_pack_deferred_required_capacity_fraction_by_direction"
    ]

    expected_capacity_pack_direction_context = %{
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
      }
    }

    timeline_integrity_fields = ~w(
      branch_timeline_integrity_activity_ids
      branch_timeline_integrity_timeline_ids
      branch_missing_dependency_activity_ids
      branch_missing_dependency_timeline_ids
      branch_dependency_cycle_activity_ids
      branch_dependency_cycle_timeline_ids
      branch_dependency_order_violation_activity_ids
      branch_dependency_order_violation_timeline_ids
      branch_exclusivity_violation_activity_ids
      branch_exclusivity_violation_timeline_ids
      branch_exclusivity_violation_groups
    )

    expected_timeline_integrity_context = %{
      "branch_timeline_integrity_activity_ids" => ["cmd_integrity_review"],
      "branch_timeline_integrity_timeline_ids" => ["timeline:cmd_integrity_review"],
      "branch_missing_dependency_activity_ids" => ["cmd_power_on"],
      "branch_exclusivity_violation_activity_ids" => ["downlink_conflict"],
      "branch_exclusivity_violation_timeline_ids" => ["timeline:downlink_conflict"],
      "branch_exclusivity_violation_groups" => ["equator_prime"]
    }

    timeline_dependency_impact_fields = ~w(
      branch_timeline_dependency_impact_activity_ids
      branch_timeline_dependency_impact_timeline_ids
      branch_timeline_dependency_impact_scopes
      branch_impacted_dependency_activity_ids
      branch_impacted_dependency_timeline_ids
      branch_impacted_exclusive_with_activity_ids
      branch_impacted_exclusive_with_timeline_ids
    )

    expected_timeline_dependency_impact_context = %{
      "branch_timeline_dependency_impact_activity_ids" => ["cmd_dependency_review"],
      "branch_timeline_dependency_impact_timeline_ids" => [
        "timeline:cmd_dependency_review"
      ],
      "branch_timeline_dependency_impact_scopes" => ["source"],
      "branch_impacted_dependency_activity_ids" => ["health_check"],
      "branch_impacted_dependency_timeline_ids" => ["timeline:health_check"],
      "branch_impacted_exclusive_with_activity_ids" => ["downlink_conflict"],
      "branch_impacted_exclusive_with_timeline_ids" => ["timeline:downlink_conflict"]
    }

    timeline_publication_fields = ~w(
      branch_timeline_publication_ids
      branch_timeline_publication_statuses
      branch_timeline_publication_source_artifact_ids
      branch_timeline_publication_source_artifact_types
      branch_timeline_publication_downstream_invalidation_statuses
      branch_timeline_publication_invalidated_downstream_product_ids
      branch_timeline_publication_downstream_invalidation_reasons
      branch_timeline_publication_dependency_impact_statuses
      branch_timeline_publication_impacted_source_activity_ids
      branch_timeline_publication_impacted_source_timeline_ids
      branch_timeline_publication_dependent_activity_ids
      branch_timeline_publication_dependent_timeline_ids
      branch_timeline_publication_changed_fields
      branch_timeline_publication_changed_timeline_ids
      branch_timeline_publication_review_timeline_ids
    )

    expected_timeline_publication_context = %{
      "branch_timeline_publication_ids" => [
        "timeline_publication:9:timeline:selected_plan:v2:timeline:selected_plan:v1"
      ],
      "branch_timeline_publication_statuses" => [
        "published_with_downstream_invalidations"
      ],
      "branch_timeline_publication_source_artifact_ids" => ["timeline:selected_plan:v2"],
      "branch_timeline_publication_source_artifact_types" => [
        "operational_timeline_report.v1"
      ],
      "branch_timeline_publication_downstream_invalidation_statuses" => ["invalidated"],
      "branch_timeline_publication_invalidated_downstream_product_ids" => [
        "cadence_import:selected:v1",
        "operator_review:selected:v1"
      ],
      "branch_timeline_publication_downstream_invalidation_reasons" => [
        "dependency_impact_review_required"
      ],
      "branch_timeline_publication_dependency_impact_statuses" => ["review_required"],
      "branch_timeline_publication_changed_fields" => ["timeline_presence"],
      "branch_timeline_publication_changed_timeline_ids" => ["timeline:health_check:0.0"],
      "branch_timeline_publication_review_timeline_ids" => [
        "timeline:health_check:0.0",
        "timeline:health_check:5.0"
      ]
    }

    timeline_lifecycle_state_fields = ~w(
      branch_timeline_lifecycle_state_statuses
      branch_timeline_lifecycle_state_review_timeline_ids
      branch_timeline_lifecycle_state_review_activity_ids
      branch_timeline_lifecycle_state_invalid_activity_input_ids
      branch_timeline_lifecycle_state_required_operator_actions
      branch_timeline_lifecycle_state_import_actions
    )

    expected_timeline_lifecycle_state_context = %{
      "branch_timeline_lifecycle_state_statuses" => ["review_required"],
      "branch_timeline_lifecycle_state_review_timeline_ids" => [
        "timeline:invalid_activity_input:lifecycle_bad_missing_type",
        "timeline:lifecycle:cmd_pending",
        "timeline:lifecycle:dup"
      ],
      "branch_timeline_lifecycle_state_review_activity_ids" => [
        "lifecycle_cmd_pending",
        "lifecycle_dup_a",
        "lifecycle_dup_b",
        "timeline_row:4:lifecycle_bad_missing_type"
      ],
      "branch_timeline_lifecycle_state_invalid_activity_input_ids" => [
        "timeline_row:4:lifecycle_bad_missing_type"
      ],
      "branch_timeline_lifecycle_state_required_operator_actions" => [
        "review_activity_approval",
        "review_duplicate_timeline_identity",
        "review_invalid_activity_input"
      ],
      "branch_timeline_lifecycle_state_import_actions" => ["review_timeline_diff"]
    }

    timeline_activity_lifecycle_state_fields = ~w(
      branch_timeline_activity_lifecycle_state_activity_ids
      branch_timeline_activity_lifecycle_state_timeline_ids
      branch_timeline_activity_lifecycle_state_transition_decisions
      branch_timeline_activity_lifecycle_state_required_operator_actions
      branch_timeline_activity_lifecycle_state_import_actions
      branch_timeline_activity_lifecycle_state_invalid_activity_input_reasons
      branch_timeline_activity_lifecycle_state_status_transition_categories
      branch_timeline_activity_lifecycle_state_approval_transition_categories
    )

    expected_timeline_activity_lifecycle_state_context = %{
      "branch_timeline_activity_lifecycle_state_activity_ids" => [
        "activity_lifecycle_cmd_pending"
      ],
      "branch_timeline_activity_lifecycle_state_timeline_ids" => [
        "timeline:activity_lifecycle:cmd_pending"
      ],
      "branch_timeline_activity_lifecycle_state_transition_decisions" => ["review"],
      "branch_timeline_activity_lifecycle_state_required_operator_actions" => [
        "record_timeline_change",
        "review_activity_approval"
      ],
      "branch_timeline_activity_lifecycle_state_import_actions" => [
        "review_timeline_diff"
      ]
    }

    timeline_activity_precondition_fields = ~w(
      branch_timeline_activity_precondition_activity_ids
      branch_timeline_activity_precondition_timeline_ids
      branch_timeline_activity_precondition_statuses
      branch_timeline_activity_precondition_blocked_types
      branch_timeline_activity_precondition_review_types
      branch_timeline_activity_precondition_dependency_activity_ids
      branch_timeline_activity_precondition_dependency_timeline_ids
      branch_timeline_activity_precondition_exclusive_with_activity_ids
      branch_timeline_activity_precondition_exclusive_with_timeline_ids
      branch_timeline_activity_precondition_duplicate_dependency_activity_ids
      branch_timeline_activity_precondition_duplicate_dependency_timeline_ids
      branch_timeline_activity_precondition_duplicate_exclusivity_activity_ids
      branch_timeline_activity_precondition_duplicate_exclusivity_timeline_ids
      branch_timeline_activity_precondition_invalid_activity_input_reasons
    )

    expected_timeline_activity_precondition_context = %{
      "branch_timeline_activity_precondition_activity_ids" => ["cmd_precondition_review"],
      "branch_timeline_activity_precondition_timeline_ids" => [
        "timeline:cmd_precondition_review"
      ],
      "branch_timeline_activity_precondition_statuses" => ["blocked"],
      "branch_timeline_activity_precondition_blocked_types" => [
        "command_safety_failed",
        "payload_unavailable"
      ],
      "branch_timeline_activity_precondition_review_types" => [
        "command_authority_missing"
      ],
      "branch_timeline_activity_precondition_dependency_activity_ids" => ["health_check"],
      "branch_timeline_activity_precondition_dependency_timeline_ids" => [
        "timeline:health_check"
      ],
      "branch_timeline_activity_precondition_exclusive_with_activity_ids" => [
        "downlink_conflict"
      ],
      "branch_timeline_activity_precondition_exclusive_with_timeline_ids" => [
        "timeline:downlink_conflict"
      ],
      "branch_timeline_activity_precondition_duplicate_dependency_activity_ids" => [
        "health_check"
      ],
      "branch_timeline_activity_precondition_duplicate_dependency_timeline_ids" => [
        "timeline:health_check"
      ],
      "branch_timeline_activity_precondition_duplicate_exclusivity_activity_ids" => [
        "downlink_conflict"
      ],
      "branch_timeline_activity_precondition_duplicate_exclusivity_timeline_ids" => [
        "timeline:downlink_conflict"
      ]
    }

    timeline_preservation_fields = ~w(
      branch_timeline_preservation_activity_ids
      branch_timeline_preservation_timeline_ids
      branch_timeline_preservation_statuses
      branch_timeline_preservation_protection_decisions
      branch_timeline_preservation_protection_categories
      branch_timeline_preservation_protection_reasons
      branch_timeline_preservation_preserve_activity_ids
      branch_timeline_preservation_preserve_timeline_ids
      branch_timeline_preservation_review_change_activity_ids
      branch_timeline_preservation_review_change_timeline_ids
      branch_timeline_preservation_invalid_activity_input_reasons
    )

    expected_timeline_preservation_context = %{
      "branch_timeline_preservation_activity_ids" => ["contact_locked_review"],
      "branch_timeline_preservation_timeline_ids" => ["timeline:contact_locked_review"],
      "branch_timeline_preservation_statuses" => ["review_required"],
      "branch_timeline_preservation_protection_decisions" => ["preserve"],
      "branch_timeline_preservation_protection_categories" => ["locked_or_approved"],
      "branch_timeline_preservation_protection_reasons" => [
        "activity_locked_or_approved"
      ],
      "branch_timeline_preservation_preserve_activity_ids" => [
        "contact_locked_review",
        "obs_done_review"
      ],
      "branch_timeline_preservation_preserve_timeline_ids" => [
        "timeline:contact_locked_review",
        "timeline:obs_done_review"
      ],
      "branch_timeline_preservation_review_change_activity_ids" => [
        "bad_missing_type_review"
      ],
      "branch_timeline_preservation_review_change_timeline_ids" => [
        "timeline:bad_missing_type_review"
      ]
    }

    mission_identity_fields = ~w(
      branch_scenario_ids
      branch_target_ids
      branch_collection_ids
      branch_product_ids
      branch_payload_ids
      branch_instrument_ids
      branch_objective_ids
      branch_objective_types
      branch_objective_statuses
      branch_source_objective_statuses
    )

    expected_mission_identity_context = %{
      "branch_scenario_ids" => ["leo_1", "leo_projection_selected"],
      "branch_target_ids" => [
        "target_hot",
        "target_objective_quality",
        "target_score_term",
        "target_tradeoff"
      ],
      "branch_collection_ids" => [
        "collection_hot",
        "collection_objective_quality",
        "collection_objective_quality_backup",
        "collection_relay",
        "collection_score_alpha",
        "collection_score_beta",
        "collection_tradeoff_alpha",
        "collection_tradeoff_beta"
      ],
      "branch_product_ids" => [
        "product_hot",
        "product_objective_quality",
        "product_objective_quality_backup",
        "product_relay",
        "product_score_alpha",
        "product_score_beta",
        "product_tradeoff_alpha",
        "product_tradeoff_beta"
      ],
      "branch_payload_ids" => [
        "payload_nadir",
        "payload_objective_quality",
        "payload_objective_quality_backup",
        "payload_score_alpha",
        "payload_score_beta",
        "payload_tradeoff_alpha",
        "payload_tradeoff_beta"
      ],
      "branch_instrument_ids" => [
        "camera_nadir",
        "instrument_objective_quality",
        "instrument_objective_quality_backup",
        "instrument_score_alpha",
        "instrument_score_beta",
        "instrument_tradeoff_alpha",
        "instrument_tradeoff_beta"
      ],
      "branch_objective_ids" => [
        "objective:target_quality",
        "objective_tradeoff:latency_gap",
        "score_term:downlink_shortfall"
      ],
      "branch_objective_types" => [
        "collection_latency",
        "observation_quality",
        "score_term_gap"
      ],
      "branch_objective_statuses" => ["at_risk"],
      "branch_source_objective_statuses" => ["missed_quality_threshold"]
    }

    expected_operational_event_context = %{
      "branch_contact_results" => ["missed", "no-contact", "same_station_contention"],
      "branch_contact_allocation_statuses" => ["deferred"],
      "branch_contact_allocation_effective_statuses" => ["deferred"],
      "branch_contact_allocation_reasons" => ["same_station_contention"],
      "branch_contact_allocation_review_statuses" => ["operator_review_required"],
      "branch_contact_allocation_approval_statuses" => [
        "approved",
        "blocked_by_policy",
        "operator_review_required"
      ],
      "branch_contact_allocation_policy_classifications" => [
        "blocked_by_policy",
        "review_only"
      ],
      "branch_realized_statuses" => ["deferred", "degraded", "executed", "failed", "missed"],
      "branch_transition_types" => ["status_changed", "throughput_changed"],
      "branch_transition_categories" => [
        "capacity_exception",
        "planned_to_executed",
        "quality_exception",
        "terminal_exception"
      ],
      "branch_transition_reasons" => [
        "activity execution recorded",
        "command execution timed out",
        "contact was missed by provider report",
        "maneuver failed after acceptance",
        "observation quality degraded",
        "station throughput below plan"
      ],
      "branch_requires_operator_review" => true,
      "branch_requires_operator_review_count" => 11
    }

    expected_execution_uncertainty_context = %{
      "branch_missed_downlink_activity_ids" => [
        "dl_objective_missed",
        "dl_objective_selected"
      ],
      "branch_maneuver_execution_uncertainty_activity_ids" => ["burn_uncertain_review"],
      "branch_maneuver_execution_uncertainty_timeline_ids" => [
        "timeline:maneuver:burn_uncertain_review"
      ],
      "branch_maneuver_execution_uncertainty_maneuver_ids" => ["burn_uncertain_review"],
      "branch_maneuver_execution_uncertainty_statuses" => ["declared"],
      "branch_maneuver_execution_uncertainty_sources" => ["ops_covariance_review"],
      "branch_maneuver_execution_uncertainty_max_timing_3sigma_s" => 75.0,
      "branch_maneuver_execution_uncertainty_max_delta_v_3sigma_magnitude_km_s" => 0.005
    }

    expected_operational_readiness_context = %{
      "branch_operational_readiness_levels" => ["operator_review"],
      "branch_operational_readiness_import_classifications" => ["review_only"],
      "branch_operational_readiness_statuses" => ["review_required"],
      "branch_operational_readiness_gate_ids" => ["operator_training"],
      "branch_operational_readiness_gate_statuses" => ["review_required"],
      "branch_operational_readiness_gate_classifications" => ["review_only"]
    }

    expected_feedback_detail_context = %{
      "image_quality_score" => 0.435,
      "image_quality_score_source" => "operational_feedback.image_quality_score",
      "image_quality_statuses" => ["marginal"],
      "image_quality_sources" => ["provider_imagery_quality"],
      "cloud_cover_fraction" => 0.5850000000000001,
      "cloud_cover_fraction_source" => "operational_feedback.cloud_cover_fraction",
      "blur_score" => 0.28,
      "blur_score_source" => "operational_feedback.blur_score",
      "maneuver_success_factor" => 0.4,
      "maneuver_success_factor_source" => "operational_feedback.maneuver_success_rate"
    }

    expected_import_feedback_detail_context =
      Map.take(expected_feedback_detail_context, [
        "maneuver_success_factor",
        "maneuver_success_factor_source"
      ])

    recommendation_summary =
      artifact["recommendation"]["explanation"]
      |> Enum.find(&(&1["type"] == "branch_event_summary"))

    recommendation_branch_context = Map.take(recommendation_summary, branch_context_fields)

    assert %{
             "branch_earliest_starts_at_s" => 500.0,
             "branch_latest_ends_at_s" => 1_680.0,
             "branch_source_window_ids" => source_window_ids,
             "branch_source_window_count" => 11,
             "branch_source_window_bounds" => source_window_bounds,
             "branch_source_window_bound_count" => 10,
             "branch_untimed_source_window_ids" => ["equator_prime_rejected_window"],
             "branch_untimed_source_window_count" => 1,
             "branch_partially_timed_source_window_count" => 0,
             "branch_source_window_timing_coverage_status" => "partial",
             "branch_station_reservation_expiration_statuses" => ["active"],
             "branch_max_latency_s" => 300.0,
             "branch_planned_latency_s" => 480.0,
             "branch_required_contacts" => 3,
             "branch_planned_contacts" => 1,
             "branch_required_downlink_mb" => 120.0,
             "branch_planned_downlink_mb" => 70.0,
             "capacity_pack_group_ids" => ["capacity_pack_equator_prime"],
             "capacity_pack_statuses" => ["deferred_by_reduced_station_capacity_pack"],
             "capacity_pack_min_capacity_fraction" => 0.5,
             "capacity_pack_max_used_fraction" => 0.5,
             "capacity_pack_max_required_capacity_fraction" => 0.25,
             "capacity_pack_total_required_capacity_fraction" => 0.25,
             "capacity_pack_required_capacity_sources" => [
               "contact_required_capacity_fraction"
             ]
           } = recommendation_branch_context

    assert recommendation_summary["branch_actual_downlink_completion_ratio"] == 0.22

    assert Map.take(recommendation_summary, capacity_pack_direction_fields) ==
             expected_capacity_pack_direction_context

    assert Map.take(recommendation_summary, timeline_integrity_fields) ==
             expected_timeline_integrity_context

    assert Map.take(recommendation_summary, timeline_dependency_impact_fields) ==
             expected_timeline_dependency_impact_context

    assert Map.take(recommendation_summary, timeline_publication_fields) ==
             expected_timeline_publication_context

    assert Map.take(recommendation_summary, timeline_lifecycle_state_fields) ==
             expected_timeline_lifecycle_state_context

    assert Map.take(recommendation_summary, timeline_activity_lifecycle_state_fields) ==
             expected_timeline_activity_lifecycle_state_context

    assert Map.take(recommendation_summary, timeline_activity_precondition_fields) ==
             expected_timeline_activity_precondition_context

    assert Map.take(recommendation_summary, timeline_preservation_fields) ==
             expected_timeline_preservation_context

    assert Map.take(recommendation_summary, mission_identity_fields) ==
             expected_mission_identity_context

    recommendation_operational_event_context =
      Map.take(recommendation_summary, operational_event_fields)

    assert Map.take(
             recommendation_operational_event_context,
             Map.keys(expected_operational_event_context)
           ) == expected_operational_event_context

    for {field, expected_count} <- [
          {"branch_feedback_sources", 38},
          {"branch_feedback_scopes", 38},
          {"branch_source_activity_ids", 34}
        ] do
      values = recommendation_operational_event_context[field]
      assert length(values) == expected_count
      assert values == Enum.sort(values)
    end

    assert "mission_state.source_contact_allocation_capacity_pack_summary" in recommendation_operational_event_context[
             "branch_feedback_sources"
           ]

    assert "timeline_preservation" in recommendation_operational_event_context[
             "branch_feedback_scopes"
           ]

    assert "dl_capacity_overflow" in recommendation_operational_event_context[
             "branch_source_activity_ids"
           ]

    assert Map.take(recommendation_summary, execution_uncertainty_fields) ==
             expected_execution_uncertainty_context

    assert Map.take(recommendation_summary, operational_readiness_fields) ==
             expected_operational_readiness_context

    recommendation_feedback =
      artifact["recommendation"]["explanation"]
      |> Enum.find(&(&1["type"] == "operational_feedback_driver"))

    assert Map.take(recommendation_feedback, feedback_detail_fields) ==
             expected_feedback_detail_context

    comparison_downlink_context =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "urgent"))
      |> Map.take([
        "branch_max_latency_s",
        "branch_planned_latency_s",
        "branch_required_contacts",
        "branch_planned_contacts",
        "branch_required_downlink_mb",
        "branch_planned_downlink_mb",
        "branch_actual_downlink_completion_ratio"
      ])

    assert comparison_downlink_context == %{
             "branch_max_latency_s" => 300.0,
             "branch_planned_latency_s" => 480.0,
             "branch_required_contacts" => 3,
             "branch_planned_contacts" => 1,
             "branch_required_downlink_mb" => 120.0,
             "branch_planned_downlink_mb" => 70.0,
             "branch_actual_downlink_completion_ratio" => 0.22
           }

    comparison_capacity_pack_direction_context =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "urgent"))
      |> Map.take(capacity_pack_direction_fields)

    assert comparison_capacity_pack_direction_context ==
             expected_capacity_pack_direction_context

    comparison_timeline_integrity_context =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "urgent"))
      |> Map.take(timeline_integrity_fields)

    assert comparison_timeline_integrity_context == expected_timeline_integrity_context

    comparison_timeline_dependency_impact_context =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "urgent"))
      |> Map.take(timeline_dependency_impact_fields)

    assert comparison_timeline_dependency_impact_context ==
             expected_timeline_dependency_impact_context

    comparison_timeline_publication_context =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "urgent"))
      |> Map.take(timeline_publication_fields)

    assert comparison_timeline_publication_context == expected_timeline_publication_context

    comparison_timeline_lifecycle_state_context =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "urgent"))
      |> Map.take(timeline_lifecycle_state_fields)

    assert comparison_timeline_lifecycle_state_context ==
             expected_timeline_lifecycle_state_context

    comparison_timeline_activity_lifecycle_state_context =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "urgent"))
      |> Map.take(timeline_activity_lifecycle_state_fields)

    assert comparison_timeline_activity_lifecycle_state_context ==
             expected_timeline_activity_lifecycle_state_context

    comparison_timeline_activity_precondition_context =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "urgent"))
      |> Map.take(timeline_activity_precondition_fields)

    assert comparison_timeline_activity_precondition_context ==
             expected_timeline_activity_precondition_context

    comparison_timeline_preservation_context =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "urgent"))
      |> Map.take(timeline_preservation_fields)

    assert comparison_timeline_preservation_context == expected_timeline_preservation_context

    comparison_mission_identity_context =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "urgent"))
      |> Map.take(mission_identity_fields)

    assert comparison_mission_identity_context == expected_mission_identity_context

    comparison_operational_event_context =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "urgent"))
      |> Map.take(operational_event_fields)

    assert comparison_operational_event_context == recommendation_operational_event_context

    comparison_execution_uncertainty_context =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "urgent"))
      |> Map.take(execution_uncertainty_fields)

    assert comparison_execution_uncertainty_context == expected_execution_uncertainty_context

    comparison_operational_readiness_context =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "urgent"))
      |> Map.take(operational_readiness_fields)

    assert comparison_operational_readiness_context == expected_operational_readiness_context

    comparison_feedback_detail_context =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "urgent"))
      |> Map.take(feedback_detail_fields)

    assert comparison_feedback_detail_context == expected_feedback_detail_context

    assert source_window_ids == Enum.sort(source_window_ids)
    assert length(source_window_ids) == 11
    assert length(source_window_bounds) == 10
    assert "equator_prime_rejected_window" in source_window_ids

    refute Enum.any?(
             source_window_bounds,
             &(&1["source_window_id"] == "equator_prime_rejected_window")
           )

    assert Map.new(source_window_bounds, fn bound ->
             {bound["source_window_id"],
              {bound["earliest_starts_at_s"], bound["latest_ends_at_s"]}}
           end) == %{
             "window_allocation_deferred" => {1_620.0, 1_680.0},
             "window_capacity_overflow" => {1_560.0, 1_620.0},
             "window_contact_filter_suppressed" => {1_165.0, 1_225.0},
             "window_contact_intent_selected" => {1_100.0, 1_160.0},
             "window_contention_conflict" => {1_580.0, 1_640.0},
             "window_contention_primary" => {1_580.0, 1_640.0},
             "window_equator_command" => {700.0, 730.0},
             "window_equator_contact" => {790.0, 850.0},
             "window_link_capacity" => {1_020.0, 1_080.0},
             "window_link_capacity_backup" => {1_020.0, 1_080.0}
           }

    recommendation_review_row = handoff.recommendation_review_row

    emitted_expected_handoff = Map.take(expected_handoff, Map.keys(recommendation_review_row))

    assert Map.take(recommendation_review_row, Map.keys(emitted_expected_handoff)) ==
             emitted_expected_handoff

    assert Map.take(recommendation_review_row, branch_context_fields) ==
             recommendation_branch_context

    assert Map.take(recommendation_review_row, capacity_pack_direction_fields) == %{}

    assert Map.take(recommendation_review_row, timeline_integrity_fields) ==
             expected_timeline_integrity_context

    assert Map.take(recommendation_review_row, timeline_dependency_impact_fields) == %{}

    assert Map.take(recommendation_review_row, timeline_publication_fields) == %{}

    assert Map.take(recommendation_review_row, timeline_lifecycle_state_fields) == %{}

    assert Map.take(recommendation_review_row, timeline_activity_lifecycle_state_fields) == %{}

    assert Map.take(recommendation_review_row, timeline_activity_precondition_fields) == %{}

    assert Map.take(recommendation_review_row, timeline_preservation_fields) == %{}

    assert Map.take(recommendation_review_row, mission_identity_fields) ==
             expected_mission_identity_context

    assert Map.take(recommendation_review_row, operational_event_fields) ==
             Map.take(recommendation_operational_event_context, review_operational_event_fields)

    assert Map.take(recommendation_review_row, execution_uncertainty_fields) ==
             expected_execution_uncertainty_context

    assert Map.take(recommendation_review_row, operational_readiness_fields) == %{}

    assert Map.take(recommendation_review_row, feedback_detail_fields) == %{}

    assert recommendation_review_row["branch_station_reservation_expiration_statuses"] == [
             "active"
           ]

    selected_import_row = handoff.selected_import_row

    assert Map.take(selected_import_row, Map.keys(emitted_expected_handoff)) ==
             emitted_expected_handoff

    assert Map.take(selected_import_row, branch_context_fields) == recommendation_branch_context

    assert Map.take(selected_import_row, capacity_pack_direction_fields) ==
             expected_capacity_pack_direction_context

    assert Map.take(selected_import_row, timeline_integrity_fields) ==
             expected_timeline_integrity_context

    assert Map.take(selected_import_row, timeline_dependency_impact_fields) ==
             expected_timeline_dependency_impact_context

    assert Map.take(selected_import_row, timeline_publication_fields) ==
             expected_timeline_publication_context

    assert Map.take(selected_import_row, timeline_lifecycle_state_fields) ==
             expected_timeline_lifecycle_state_context

    assert Map.take(selected_import_row, timeline_activity_lifecycle_state_fields) ==
             expected_timeline_activity_lifecycle_state_context

    assert Map.take(selected_import_row, timeline_activity_precondition_fields) ==
             expected_timeline_activity_precondition_context

    assert Map.take(selected_import_row, timeline_preservation_fields) ==
             expected_timeline_preservation_context

    assert Map.take(selected_import_row, mission_identity_fields) ==
             expected_mission_identity_context

    assert Map.take(selected_import_row, operational_event_fields) ==
             recommendation_operational_event_context

    assert Map.take(selected_import_row, execution_uncertainty_fields) ==
             expected_execution_uncertainty_context

    assert Map.take(selected_import_row, operational_readiness_fields) ==
             expected_operational_readiness_context

    assert Map.take(selected_import_row, feedback_detail_fields) ==
             expected_import_feedback_detail_context

    assert selected_import_row["branch_station_reservation_expiration_statuses"] == ["active"]

    review_import = handoff.review_import
    review_import_row = handoff.review_import_row

    assert Map.take(review_import_row, Map.keys(emitted_expected_handoff)) ==
             emitted_expected_handoff

    assert Map.take(review_import_row, branch_context_fields) == recommendation_branch_context

    assert Map.take(review_import_row, capacity_pack_direction_fields) == %{}

    assert Map.take(review_import_row, timeline_integrity_fields) ==
             expected_timeline_integrity_context

    assert Map.take(review_import_row, timeline_dependency_impact_fields) == %{}

    assert Map.take(review_import_row, timeline_publication_fields) == %{}

    assert Map.take(review_import_row, timeline_lifecycle_state_fields) == %{}

    assert Map.take(review_import_row, timeline_activity_lifecycle_state_fields) == %{}

    assert Map.take(review_import_row, timeline_activity_precondition_fields) == %{}

    assert Map.take(review_import_row, timeline_preservation_fields) == %{}

    assert Map.take(review_import_row, mission_identity_fields) ==
             expected_mission_identity_context

    assert Map.take(review_import_row, operational_event_fields) ==
             Map.take(recommendation_operational_event_context, review_operational_event_fields)

    assert Map.take(review_import_row, execution_uncertainty_fields) ==
             expected_execution_uncertainty_context

    assert Map.take(review_import_row, operational_readiness_fields) == %{}

    assert Map.take(review_import_row, feedback_detail_fields) == %{}

    assert review_import_row["branch_station_reservation_expiration_statuses"] == ["active"]

    assert Map.take(review_import_row["source_review_row"], Map.keys(emitted_expected_handoff)) ==
             emitted_expected_handoff

    assert Map.take(review_import_row["source_review_row"], branch_context_fields) ==
             recommendation_branch_context

    assert Map.take(review_import_row["source_review_row"], capacity_pack_direction_fields) == %{}

    assert Map.take(review_import_row["source_review_row"], timeline_integrity_fields) ==
             expected_timeline_integrity_context

    assert Map.take(
             review_import_row["source_review_row"],
             timeline_dependency_impact_fields
           ) == %{}

    assert Map.take(review_import_row["source_review_row"], timeline_publication_fields) == %{}

    assert Map.take(review_import_row["source_review_row"], timeline_lifecycle_state_fields) ==
             %{}

    assert Map.take(
             review_import_row["source_review_row"],
             timeline_activity_lifecycle_state_fields
           ) == %{}

    assert Map.take(
             review_import_row["source_review_row"],
             timeline_activity_precondition_fields
           ) == %{}

    assert Map.take(review_import_row["source_review_row"], timeline_preservation_fields) == %{}

    assert Map.take(review_import_row["source_review_row"], mission_identity_fields) ==
             expected_mission_identity_context

    assert Map.take(review_import_row["source_review_row"], operational_event_fields) ==
             Map.take(recommendation_operational_event_context, review_operational_event_fields)

    assert Map.take(review_import_row["source_review_row"], execution_uncertainty_fields) ==
             expected_execution_uncertainty_context

    assert Map.take(review_import_row["source_review_row"], operational_readiness_fields) == %{}

    assert Map.take(review_import_row["source_review_row"], feedback_detail_fields) == %{}

    assert review_import_row["source_review_row"][
             "branch_station_reservation_expiration_statuses"
           ] == ["active"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)

    urgent_row_index =
      Enum.find_index(
        artifact["branch_comparison_report"]["rows"],
        &(&1["branch_id"] == "urgent")
      )

    downlink_context_invalid =
      put_in(
        artifact,
        [
          "branch_comparison_report",
          "rows",
          Access.at(urgent_row_index),
          "branch_required_downlink_mb"
        ],
        121.0
      )

    assert {:error, downlink_context_report} =
             Schema.validate_artifact(downlink_context_invalid)

    assert Enum.any?(
             downlink_context_report["errors"],
             &(&1["path"] ==
                 "$.branch_comparison_report.rows[#{urgent_row_index}].branch_required_downlink_mb")
           )

    capacity_pack_context_invalid =
      put_in(
        artifact,
        [
          "branch_comparison_report",
          "rows",
          Access.at(urgent_row_index),
          "capacity_pack_total_required_capacity_fraction"
        ],
        0.5
      )

    assert {:error, capacity_pack_context_report} =
             Schema.validate_artifact(capacity_pack_context_invalid)

    assert Enum.any?(
             capacity_pack_context_report["errors"],
             &(&1["path"] ==
                 "$.branch_comparison_report.rows[#{urgent_row_index}].capacity_pack_total_required_capacity_fraction")
           )

    capacity_pack_direction_invalid =
      put_in(
        artifact,
        [
          "branch_comparison_report",
          "rows",
          Access.at(urgent_row_index),
          "capacity_pack_required_capacity_fraction_by_direction"
        ],
        %{"downlink" => 0.5}
      )

    assert {:error, capacity_pack_direction_report} =
             Schema.validate_artifact(capacity_pack_direction_invalid)

    assert Enum.any?(
             capacity_pack_direction_report["errors"],
             &(&1["path"] ==
                 "$.branch_comparison_report.rows[#{urgent_row_index}].capacity_pack_required_capacity_fraction_by_direction")
           )

    timeline_integrity_invalid =
      put_in(
        artifact,
        [
          "branch_comparison_report",
          "rows",
          Access.at(urgent_row_index),
          "branch_exclusivity_violation_groups"
        ],
        ["stale_exclusivity_group"]
      )

    assert {:error, timeline_integrity_report} =
             Schema.validate_artifact(timeline_integrity_invalid)

    assert Enum.any?(
             timeline_integrity_report["errors"],
             &(&1["path"] ==
                 "$.branch_comparison_report.rows[#{urgent_row_index}].branch_exclusivity_violation_groups")
           )

    timeline_dependency_impact_invalid =
      put_in(
        artifact,
        [
          "branch_comparison_report",
          "rows",
          Access.at(urgent_row_index),
          "branch_timeline_dependency_impact_scopes"
        ],
        ["stale_dependency_impact_scope"]
      )

    assert {:error, timeline_dependency_impact_report} =
             Schema.validate_artifact(timeline_dependency_impact_invalid)

    assert Enum.any?(
             timeline_dependency_impact_report["errors"],
             &(&1["path"] ==
                 "$.branch_comparison_report.rows[#{urgent_row_index}].branch_timeline_dependency_impact_scopes")
           )

    timeline_publication_invalid =
      put_in(
        artifact,
        [
          "branch_comparison_report",
          "rows",
          Access.at(urgent_row_index),
          "branch_timeline_publication_statuses"
        ],
        ["stale_publication_status"]
      )

    assert {:error, timeline_publication_report} =
             Schema.validate_artifact(timeline_publication_invalid)

    assert Enum.any?(
             timeline_publication_report["errors"],
             &(&1["path"] ==
                 "$.branch_comparison_report.rows[#{urgent_row_index}].branch_timeline_publication_statuses")
           )

    timeline_lifecycle_state_invalid =
      put_in(
        artifact,
        [
          "branch_comparison_report",
          "rows",
          Access.at(urgent_row_index),
          "branch_timeline_lifecycle_state_statuses"
        ],
        ["stale_timeline_lifecycle_state_status"]
      )

    assert {:error, timeline_lifecycle_state_report} =
             Schema.validate_artifact(timeline_lifecycle_state_invalid)

    assert Enum.any?(
             timeline_lifecycle_state_report["errors"],
             &(&1["path"] ==
                 "$.branch_comparison_report.rows[#{urgent_row_index}].branch_timeline_lifecycle_state_statuses")
           )

    timeline_activity_lifecycle_state_invalid =
      put_in(
        artifact,
        [
          "branch_comparison_report",
          "rows",
          Access.at(urgent_row_index),
          "branch_timeline_activity_lifecycle_state_transition_decisions"
        ],
        ["stale_timeline_activity_lifecycle_state_transition"]
      )

    assert {:error, timeline_activity_lifecycle_state_report} =
             Schema.validate_artifact(timeline_activity_lifecycle_state_invalid)

    assert Enum.any?(
             timeline_activity_lifecycle_state_report["errors"],
             &(&1["path"] ==
                 "$.branch_comparison_report.rows[#{urgent_row_index}].branch_timeline_activity_lifecycle_state_transition_decisions")
           )

    timeline_activity_precondition_invalid =
      put_in(
        artifact,
        [
          "branch_comparison_report",
          "rows",
          Access.at(urgent_row_index),
          "branch_timeline_activity_precondition_statuses"
        ],
        ["stale_timeline_activity_precondition_status"]
      )

    assert {:error, timeline_activity_precondition_report} =
             Schema.validate_artifact(timeline_activity_precondition_invalid)

    assert Enum.any?(
             timeline_activity_precondition_report["errors"],
             &(&1["path"] ==
                 "$.branch_comparison_report.rows[#{urgent_row_index}].branch_timeline_activity_precondition_statuses")
           )

    timeline_preservation_invalid =
      put_in(
        artifact,
        [
          "branch_comparison_report",
          "rows",
          Access.at(urgent_row_index),
          "branch_timeline_preservation_statuses"
        ],
        ["stale_timeline_preservation_status"]
      )

    assert {:error, timeline_preservation_report} =
             Schema.validate_artifact(timeline_preservation_invalid)

    assert Enum.any?(
             timeline_preservation_report["errors"],
             &(&1["path"] ==
                 "$.branch_comparison_report.rows[#{urgent_row_index}].branch_timeline_preservation_statuses")
           )

    mission_identity_invalid =
      put_in(
        artifact,
        [
          "branch_comparison_report",
          "rows",
          Access.at(urgent_row_index),
          "branch_objective_statuses"
        ],
        ["stale_branch_objective_status"]
      )

    assert {:error, mission_identity_report} = Schema.validate_artifact(mission_identity_invalid)

    assert Enum.any?(
             mission_identity_report["errors"],
             &(&1["path"] ==
                 "$.branch_comparison_report.rows[#{urgent_row_index}].branch_objective_statuses")
           )

    invented_source_window_context = %{
      "branch_source_window_ids" => ["invented_source_window"],
      "branch_source_window_count" => 1,
      "branch_source_window_bounds" => [
        %{
          "source_window_id" => "invented_source_window",
          "earliest_starts_at_s" => 1.0,
          "latest_ends_at_s" => 2.0
        }
      ],
      "branch_source_window_bound_count" => 1,
      "branch_untimed_source_window_count" => 0,
      "branch_partially_timed_source_window_count" => 0,
      "branch_source_window_timing_coverage_status" => "complete"
    }

    source_window_context_invalid =
      update_in(
        artifact,
        ["branch_comparison_report", "rows", Access.at(urgent_row_index)],
        fn row ->
          row
          |> Map.drop(source_window_context_fields)
          |> Map.merge(invented_source_window_context)
        end
      )

    assert {:error, source_window_context_report} =
             Schema.validate_artifact(source_window_context_invalid)

    assert Enum.any?(
             source_window_context_report["errors"],
             &(&1["path"] ==
                 "$.branch_comparison_report.rows[#{urgent_row_index}].branch_source_window_ids" and
                 &1["message"] ==
                   "must match the enclosing branch source-window context")
           )

    operational_event_invalid =
      put_in(
        artifact,
        [
          "branch_comparison_report",
          "rows",
          Access.at(urgent_row_index),
          "branch_transition_types"
        ],
        ["stale_transition_type"]
      )

    assert {:error, operational_event_report} =
             Schema.validate_artifact(operational_event_invalid)

    assert Enum.any?(
             operational_event_report["errors"],
             &(&1["path"] ==
                 "$.branch_comparison_report.rows[#{urgent_row_index}].branch_transition_types" and
                 &1["message"] == "must match the enclosing branch transition values")
           )

    execution_uncertainty_invalid =
      put_in(
        artifact,
        [
          "branch_comparison_report",
          "rows",
          Access.at(urgent_row_index),
          "branch_maneuver_execution_uncertainty_max_timing_3sigma_s"
        ],
        76.0
      )

    assert {:error, execution_uncertainty_report} =
             Schema.validate_artifact(execution_uncertainty_invalid)

    assert Enum.any?(
             execution_uncertainty_report["errors"],
             &(&1["path"] ==
                 "$.branch_comparison_report.rows[#{urgent_row_index}].branch_maneuver_execution_uncertainty_max_timing_3sigma_s" and
                 &1["message"] ==
                   "must match the enclosing branch execution-uncertainty timing_3sigma_s maximum")
           )

    operational_readiness_invalid =
      put_in(
        artifact,
        [
          "branch_comparison_report",
          "rows",
          Access.at(urgent_row_index),
          "branch_operational_readiness_levels"
        ],
        ["stale_operational_readiness_level"]
      )

    assert {:error, operational_readiness_report} =
             Schema.validate_artifact(operational_readiness_invalid)

    assert Enum.any?(
             operational_readiness_report["errors"],
             &(&1["path"] ==
                 "$.branch_comparison_report.rows[#{urgent_row_index}].branch_operational_readiness_levels" and
                 &1["message"] ==
                   "must match the enclosing branch operational-readiness values")
           )

    feedback_detail_invalid =
      put_in(
        artifact,
        [
          "branch_comparison_report",
          "rows",
          Access.at(urgent_row_index),
          "image_quality_score_source"
        ],
        "stale_image_quality_score_source"
      )

    assert {:error, feedback_detail_report} = Schema.validate_artifact(feedback_detail_invalid)

    assert Enum.any?(
             feedback_detail_report["errors"],
             &(&1["path"] ==
                 "$.branch_comparison_report.rows[#{urgent_row_index}].image_quality_score_source" and
                 &1["message"] ==
                   "must match the enclosing branch feedback_adjustments.image_quality_score_source")
           )

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1", "status" => "pass"}} =
             Schema.validate_artifact(review_import)

    recommendation_review_index = handoff.recommendation_review_index

    missing_review_expiration =
      update_in(
        artifact["operator_review_package"],
        ["rows", Access.at(recommendation_review_index)],
        &Map.delete(&1, "branch_station_reservation_expiration_statuses")
      )

    assert {:error, missing_review_expiration_report} =
             Schema.validate_artifact(missing_review_expiration)

    assert Enum.any?(
             missing_review_expiration_report["errors"],
             &(&1["path"] ==
                 "$.rows[#{recommendation_review_index}].branch_station_reservation_expiration_statuses")
           )

    legacy_review_expiration =
      update_in(
        artifact["operator_review_package"],
        ["rows", Access.at(recommendation_review_index)],
        fn row ->
          row
          |> Map.delete("branch_station_reservation_expiration_statuses")
          |> update_in(["source_recommendation", "explanation"], fn explanation ->
            Enum.map(explanation, fn
              %{"type" => "branch_event_summary"} = summary ->
                Map.delete(summary, "branch_station_reservation_expiration_statuses")

              other ->
                other
            end)
          end)
        end
      )

    assert {:ok, _legacy_review_expiration} = Schema.validate_artifact(legacy_review_expiration)

    selected_import_index = handoff.selected_import_index

    stale_selected_expiration =
      update_in(
        artifact["cadence_import_manifest"],
        ["rows", Access.at(selected_import_index)],
        &Map.put(&1, "branch_station_reservation_expiration_statuses", ["expired"])
      )

    assert {:error, stale_selected_expiration_report} =
             Schema.validate_artifact(stale_selected_expiration)

    assert Enum.any?(
             stale_selected_expiration_report["errors"],
             &(&1["path"] ==
                 "$.rows[#{selected_import_index}].branch_station_reservation_expiration_statuses")
           )

    review_import_index = handoff.review_import_index

    missing_review_import_expiration =
      update_in(
        review_import,
        ["rows", Access.at(review_import_index)],
        &Map.delete(&1, "branch_station_reservation_expiration_statuses")
      )

    assert {:error, missing_review_import_expiration_report} =
             Schema.validate_artifact(missing_review_import_expiration)

    assert Enum.any?(
             missing_review_import_expiration_report["errors"],
             &(&1["path"] ==
                 "$.rows[#{review_import_index}].branch_station_reservation_expiration_statuses")
           )
  end

  @validation_refresh_unemitted_context_fields [
    "refresh_freshness_unknown_reason_ids"
  ]
  @validation_refresh_context_contracts OrbitalDynamics.RecommendationRiskContext.ValidationRefresh.field_specs()
                                        |> Enum.reject(fn {field, _source_fields, _feedback_scope} ->
                                          field in @validation_refresh_unemitted_context_fields
                                        end)

  for {field, source_fields, feedback_scope} <- @validation_refresh_context_contracts do
    test "validation-refresh #{field} remains source exact across handoffs", %{handoff: handoff} do
      artifact = handoff

      expected_value =
        artifact["operator_review_package"]["rows"]
        |> Enum.find(&(&1["review_type"] == "strategy_recommendation"))
        |> Map.fetch!(unquote(field))

      assert_risk_context_contract(
        artifact,
        unquote(field),
        {"feedback_scope", unquote(feedback_scope)},
        unquote(Macro.escape(source_fields)),
        expected_value,
        stale_context_value(expected_value)
      )
    end
  end
end
