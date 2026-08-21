Code.require_file("support.exs", __DIR__)

Code.require_file(
  "../../support/campaign_planner/strategy_recommendation_pressure_handoff_case.ex",
  __DIR__
)

defmodule OrbitalDynamics.CampaignPlanner.StrategyRecommendationPressureHandoffContactContextTest do
  use OrbitalDynamics.CampaignPlanner.StrategyRecommendationPressureHandoffCase

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
end
