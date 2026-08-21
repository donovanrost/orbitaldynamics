Code.require_file("support.exs", __DIR__)

Code.require_file(
  "../../support/campaign_planner/strategy_recommendation_pressure_handoff_case.ex",
  __DIR__
)

defmodule OrbitalDynamics.CampaignPlanner.StrategyRecommendationPressureHandoffOperationalScoringStationTest do
  use OrbitalDynamics.CampaignPlanner.StrategyRecommendationPressureHandoffCase

  @operational_feedback_risk_types [
    "contact_success_rate_low",
    "observation_success_rate_low",
    "station_throughput_factor_low"
  ]
  @operational_feedback_context_contracts Enum.map(
                                            OrbitalDynamics.RecommendationRiskContext.OperationalFeedback.field_pairs(),
                                            fn {field, source_fields} ->
                                              legacy_mode =
                                                if field ==
                                                     "strategy_operational_feedback_risk_types",
                                                   do: :drop_risk,
                                                   else: :drop_field

                                              {field, source_fields, legacy_mode}
                                            end
                                          )

  for {field, source_fields, legacy_mode} <- @operational_feedback_context_contracts do
    test "operational-feedback #{field} remains source exact across handoffs", %{handoff: handoff} do
      artifact = handoff

      expected_value =
        artifact["operator_review_package"]["rows"]
        |> Enum.find(&(&1["review_type"] == "strategy_recommendation"))
        |> Map.fetch!(unquote(field))

      assert_risk_context_contract(
        artifact,
        unquote(field),
        {"type", unquote(@operational_feedback_risk_types)},
        unquote(Macro.escape(source_fields)),
        expected_value,
        stale_context_value(expected_value),
        unquote(legacy_mode)
      )
    end
  end

  test "link-capacity risk type remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "link_capacity_pressure_risk_types",
      {"ground_station_id", "equator_prime"},
      ["type", "risk_type"],
      ["downlink_completion_gap"],
      ["stale_link_capacity_risk"]
    )
  end

  test "link-capacity ground-station identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "link_capacity_pressure_ground_station_ids",
      {"ground_station_id", "equator_prime"},
      "ground_station_id",
      ["equator_prime"],
      ["stale_equator_prime"]
    )
  end

  test "link-capacity required-contact demand remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "link_capacity_pressure_required_contact_values",
      {"ground_station_id", "equator_prime"},
      "required_contacts",
      [1],
      [2]
    )
  end

  test "link-capacity planned-contact demand remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "link_capacity_pressure_planned_contact_values",
      {"ground_station_id", "equator_prime"},
      "planned_contacts",
      [0],
      [1]
    )
  end

  test "link-capacity required-downlink demand remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "link_capacity_pressure_required_downlink_values_mb",
      {"ground_station_id", "equator_prime"},
      "required_downlink_mb",
      [45.0],
      [46.0]
    )
  end

  test "link-capacity planned-downlink demand remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "link_capacity_pressure_planned_downlink_values_mb",
      {"ground_station_id", "equator_prime"},
      "planned_downlink_mb",
      [10.0],
      [11.0]
    )
  end

  test "link-capacity start bound remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "link_capacity_pressure_start_values_s",
      {"ground_station_id", "equator_prime"},
      "starts_at_s",
      [1_020.0],
      [1_019.0]
    )
  end

  test "link-capacity end bound remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "link_capacity_pressure_end_values_s",
      {"ground_station_id", "equator_prime"},
      "ends_at_s",
      [1_080.0],
      [1_081.0]
    )
  end

  test "link-capacity source-activity identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "link_capacity_pressure_source_activity_ids",
      {"ground_station_id", "equator_prime"},
      ["source_activity_ids"],
      ["dl_link_capacity_source"],
      ["stale_dl_link_capacity_source"]
    )
  end

  test "link-capacity source-window identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "link_capacity_pressure_source_window_ids",
      {"ground_station_id", "equator_prime"},
      ["source_window_id", "source_window_ids"],
      ["window_link_capacity", "window_link_capacity_backup"],
      ["stale_window_link_capacity"]
    )
  end

  test "link-capacity selected adjusted throughput remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "link_capacity_pressure_selected_capacity_adjusted_throughput_values_mb",
      {"ground_station_id", "equator_prime"},
      "selected_capacity_adjusted_throughput_mb",
      [10.0],
      [11.0]
    )
  end

  test "link-capacity selected shortfall remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "link_capacity_pressure_selected_downlink_shortfall_values_mb",
      {"ground_station_id", "equator_prime"},
      "selected_downlink_shortfall_mb",
      [35.0],
      [34.0]
    )
  end

  test "link-capacity actual throughput remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "link_capacity_pressure_actual_throughput_values_mb",
      {"ground_station_id", "equator_prime"},
      "actual_throughput_mb",
      [8.0],
      [9.0]
    )
  end

  test "link-capacity actual completion ratio remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "link_capacity_pressure_actual_downlink_completion_ratio_values",
      {"ground_station_id", "equator_prime"},
      "actual_downlink_completion_ratio",
      [0.22],
      [0.5]
    )
  end

  test "link-capacity actual shortfall remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "link_capacity_pressure_actual_downlink_shortfall_values_mb",
      {"ground_station_id", "equator_prime"},
      "actual_downlink_shortfall_mb",
      [37.0],
      [36.0]
    )
  end

  test "link-capacity requirement status remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "link_capacity_pressure_downlink_requirement_statuses",
      {"ground_station_id", "equator_prime"},
      "downlink_requirement_status",
      ["shortfall"],
      ["satisfied"]
    )
  end

  test "link-capacity actual requirement status remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "link_capacity_pressure_actual_downlink_requirement_statuses",
      {"ground_station_id", "equator_prime"},
      "actual_downlink_requirement_status",
      ["shortfall"],
      ["satisfied"]
    )
  end

  test "link-capacity downlink-demand source remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "link_capacity_pressure_downlink_demand_sources",
      {"ground_station_id", "equator_prime"},
      ["downlink_demand_sources"],
      ["mission_objective:relay_collection"],
      ["stale_link_capacity_demand_source"]
    )
  end

  test "link-capacity completion source remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "link_capacity_pressure_downlink_completion_sources",
      {"ground_station_id", "equator_prime"},
      ["downlink_completion_sources"],
      ["link_capacity_report:selected_contacts"],
      ["stale_link_capacity_completion_source"]
    )
  end

  test "link-capacity feedback source remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "link_capacity_pressure_feedback_sources",
      {"ground_station_id", "equator_prime"},
      "feedback_source",
      ["mission_state.source_link_capacity_report.rows"],
      ["stale_link_capacity_feedback_source"]
    )
  end

  test "link-capacity feedback scope remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "link_capacity_pressure_feedback_scopes",
      {"ground_station_id", "equator_prime"},
      "feedback_scope",
      ["link_capacity"],
      ["stale_link_capacity"]
    )
  end

  test "link-capacity trust boundary remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "link_capacity_pressure_trust_boundaries",
      {"ground_station_id", "equator_prime"},
      "trust_boundary",
      ["mission_state_link_capacity_report"],
      ["stale_link_capacity_boundary"]
    )
  end

  test "link-capacity derivation reasons remain source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "link_capacity_pressure_derivation_reasons",
      {"ground_station_id", "equator_prime"},
      ["derivation_reasons"],
      ["link_capacity_selected_downlink_shortfall"],
      ["stale_link_capacity_derivation"]
    )
  end

  test "score-term risk type remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "score_term_pressure_risk_types",
      {"feedback_scope", "score_term"},
      ["type", "risk_type"],
      ["downlink_completion_gap"],
      ["stale_score_term_risk"]
    )
  end

  test "score-term objective identity remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "score_term_pressure_objective_ids",
      {"feedback_scope", "score_term"},
      "objective_id",
      ["score_term:downlink_shortfall"],
      ["score_term:stale"]
    )
  end

  test "score-term objective type remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "score_term_pressure_objective_types",
      {"feedback_scope", "score_term"},
      "objective_type",
      ["score_term_gap"],
      ["stale_score_term_gap"]
    )
  end

  test "score-term latency-objective flag remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "score_term_pressure_latency_objective_values",
      {"feedback_scope", "score_term"},
      "latency_objective",
      [true],
      [false]
    )
  end

  test "score-term target identity remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "score_term_pressure_target_ids",
      {"feedback_scope", "score_term"},
      "target_id",
      ["target_score_term"],
      ["stale_target_score_term"]
    )
  end

  test "score-term scenario identity remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "score_term_pressure_scenario_ids",
      {"feedback_scope", "score_term"},
      "scenario_id",
      ["leo_1"],
      ["stale_leo_1"]
    )
  end

  test "score-term branch identity remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "score_term_pressure_branch_ids",
      {"feedback_scope", "score_term"},
      "branch_id",
      ["urgent"],
      ["stale_urgent"]
    )
  end

  test "score-term station identity remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "score_term_pressure_ground_station_ids",
      {"feedback_scope", "score_term"},
      "ground_station_id",
      ["polar_prime"],
      ["stale_polar_prime"]
    )
  end

  test "score-term collection identity remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "score_term_pressure_collection_ids",
      {"feedback_scope", "score_term"},
      ["collection_id", "collection_ids"],
      ["collection_score_alpha", "collection_score_beta"],
      ["stale_collection_score"]
    )
  end

  test "score-term product identity remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "score_term_pressure_product_ids",
      {"feedback_scope", "score_term"},
      ["product_id", "product_ids"],
      ["product_score_alpha", "product_score_beta"],
      ["stale_product_score"]
    )
  end

  test "score-term payload identity remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "score_term_pressure_payload_ids",
      {"feedback_scope", "score_term"},
      ["payload_id", "payload_ids"],
      ["payload_score_alpha", "payload_score_beta"],
      ["stale_payload_score"]
    )
  end

  test "score-term instrument identity remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "score_term_pressure_instrument_ids",
      {"feedback_scope", "score_term"},
      ["instrument_id", "instrument_ids"],
      ["instrument_score_alpha", "instrument_score_beta"],
      ["stale_instrument_score"]
    )
  end

  test "score-term start bound remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "score_term_pressure_start_values_s",
      {"feedback_scope", "score_term"},
      "starts_at_s",
      [1_240.0],
      [1_239.0]
    )
  end

  test "score-term end bound remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "score_term_pressure_end_values_s",
      {"feedback_scope", "score_term"},
      "ends_at_s",
      [1_360.0],
      [1_361.0]
    )
  end

  test "score-term required contact demand remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "score_term_pressure_required_contact_values",
      {"feedback_scope", "score_term"},
      "required_contacts",
      [2],
      [3]
    )
  end

  test "score-term planned contact demand remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "score_term_pressure_planned_contact_values",
      {"feedback_scope", "score_term"},
      "planned_contacts",
      [1],
      [0]
    )
  end

  test "score-term required downlink demand remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "score_term_pressure_required_downlink_values_mb",
      {"feedback_scope", "score_term"},
      "required_downlink_mb",
      [80.0],
      [81.0]
    )
  end

  test "score-term planned downlink demand remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "score_term_pressure_planned_downlink_values_mb",
      {"feedback_scope", "score_term"},
      "planned_downlink_mb",
      [35.0],
      [34.0]
    )
  end

  test "score-term maximum latency remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "score_term_pressure_max_latency_values_s",
      {"feedback_scope", "score_term"},
      "max_latency_s",
      [300.0],
      [301.0]
    )
  end

  test "score-term planned latency remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "score_term_pressure_planned_latency_values_s",
      {"feedback_scope", "score_term"},
      "planned_latency_s",
      [420.0],
      [419.0]
    )
  end

  test "score-term required observation demand remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "score_term_pressure_required_observation_values",
      {"feedback_scope", "score_term"},
      "required_observations",
      [2],
      [3]
    )
  end

  test "score-term planned observation demand remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "score_term_pressure_planned_observation_values",
      {"feedback_scope", "score_term"},
      "planned_observations",
      [1],
      [0]
    )
  end

  test "score-term priority remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "score_term_pressure_priorities",
      {"feedback_scope", "score_term"},
      "priority",
      [24.0],
      [23.0]
    )
  end

  test "score-term latitude remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "score_term_pressure_latitude_values_deg",
      {"feedback_scope", "score_term"},
      "latitude_deg",
      [34.1],
      [34.2]
    )
  end

  test "score-term longitude remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "score_term_pressure_longitude_values_deg",
      {"feedback_scope", "score_term"},
      "longitude_deg",
      [-118.2],
      [-118.1]
    )
  end

  test "score-term minimum elevation remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "score_term_pressure_minimum_elevation_values_deg",
      {"feedback_scope", "score_term"},
      "minimum_elevation_deg",
      [15.0],
      [16.0]
    )
  end

  test "score-term source activity remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "score_term_pressure_source_activity_ids",
      {"feedback_scope", "score_term"},
      ["source_activity_id", "source_activity_ids"],
      ["obs_score_source", "dl_score_source"],
      ["stale_score_source"]
    )
  end

  test "score-term key remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "score_term_pressure_keys",
      {"feedback_scope", "score_term"},
      "score_term_key",
      ["collection_latency_gap_s"],
      ["stale_score_term_key"]
    )
  end

  test "score-term value remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "score_term_pressure_values",
      {"feedback_scope", "score_term"},
      "score_term_value",
      [120.0],
      [121.0]
    )
  end

  test "score-term timeline score remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "score_term_pressure_timeline_score_values",
      {"feedback_scope", "score_term"},
      "timeline_score",
      [9.5],
      [9.6]
    )
  end

  test "score-term map remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "score_term_pressure_score_term_maps",
      {"feedback_scope", "score_term"},
      "score_terms",
      [
        %{
          "collection_latency_gap_s" => 120.0,
          "downlink_shortfall_mb" => 45.0
        }
      ],
      [%{"collection_latency_gap_s" => 121.0}]
    )
  end

  test "score-term downlink-demand source remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "score_term_pressure_downlink_demand_sources",
      {"feedback_scope", "score_term"},
      ["downlink_demand_sources"],
      ["score_term:score_term:downlink_shortfall:collection_latency_gap_s"],
      ["stale_score_term_demand_source"]
    )
  end

  test "score-term completion source remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "score_term_pressure_downlink_completion_sources",
      {"feedback_scope", "score_term"},
      ["downlink_completion_sources"],
      ["score_term:score_term:downlink_shortfall:collection_latency_gap_s"],
      ["stale_score_term_completion_source"]
    )
  end

  test "score-term feedback source remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "score_term_pressure_feedback_sources",
      {"feedback_scope", "score_term"},
      "feedback_source",
      ["mission_state.source_score_term_report.rows"],
      ["stale_score_term_feedback_source"]
    )
  end

  test "score-term feedback scope remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "score_term_pressure_feedback_scopes",
      {"feedback_scope", "score_term"},
      "feedback_scope",
      ["score_term"],
      ["stale_score_term"]
    )
  end

  test "score-term trust boundary remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "score_term_pressure_trust_boundaries",
      {"feedback_scope", "score_term"},
      "trust_boundary",
      ["mission_state_score_term_report"],
      ["stale_score_term_boundary"]
    )
  end

  test "score-term derivation reasons remain source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "score_term_pressure_derivation_reasons",
      {"feedback_scope", "score_term"},
      ["derivation_reasons"],
      [
        "collection_latency_gap",
        "score_term_collection_latency_gap",
        "score_term_collection_latency_gap_s"
      ],
      ["stale_score_term_derivation"]
    )
  end

  test "station conflict expiration risk context remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_expiration_context_contract(
      handoff,
      "station_reservation_conflict_expiration_statuses",
      {"contact_id", "dl_reservation_conflict"},
      "active"
    )
  end

  test "station conflict contact identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "station_reservation_conflict_contact_ids",
      {"contact_id", "dl_reservation_conflict"},
      "contact_id",
      ["dl_reservation_conflict"],
      ["stale_dl_reservation_conflict"]
    )
  end

  test "station conflict source activity identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "station_reservation_conflict_source_activity_ids",
      {"contact_id", "dl_reservation_conflict"},
      ["source_activity_id", "source_activity_ids"],
      ["dl_reservation_conflict"],
      ["stale_dl_reservation_conflict"]
    )
  end

  test "station conflict ground-station identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "station_reservation_conflict_ground_station_ids",
      {"contact_id", "dl_reservation_conflict"},
      "ground_station_id",
      ["equator_prime"],
      ["stale_equator_prime"]
    )
  end

  test "station conflict reservation identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "station_reservation_conflict_reservation_ids",
      {"contact_id", "dl_reservation_conflict"},
      "station_reservation_id",
      ["reservation_conflict_1"],
      ["stale_reservation_conflict_1"]
    )
  end

  test "station conflict reservation owner remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "station_reservation_conflict_reserved_by",
      {"contact_id", "dl_reservation_conflict"},
      "station_reserved_by",
      ["ops_team_b"],
      ["stale_ops_team_b"]
    )
  end

  test "station conflict reservation status remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "station_reservation_conflict_statuses",
      {"contact_id", "dl_reservation_conflict"},
      "station_reservation_status",
      ["confirmed"],
      ["cancelled"]
    )
  end

  test "station conflict match status remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "station_reservation_conflict_match_statuses",
      {"contact_id", "dl_reservation_conflict"},
      "station_reservation_match_status",
      ["overlap"],
      ["matched"]
    )
  end

  test "station conflict reservation deadline remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "station_reservation_conflict_expires_at_values_s",
      {"contact_id", "dl_reservation_conflict"},
      "station_reservation_expires_at_s",
      [360.0],
      [361.0]
    )
  end

  test "station conflict derivation reason remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "station_reservation_conflict_derivation_reasons",
      {"contact_id", "dl_reservation_conflict"},
      "derivation_reasons",
      ["contact_allocation_reservation_conflict"],
      ["stale_contact_allocation_reservation_conflict"]
    )
  end

  test "station conflict feedback source remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "station_reservation_conflict_feedback_sources",
      {"contact_id", "dl_reservation_conflict"},
      "feedback_source",
      ["mission_state.source_contact_allocation_reservation_conflict_summary"],
      ["stale.source_contact_allocation_reservation_conflict_summary"]
    )
  end

  test "station conflict feedback scope remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "station_reservation_conflict_feedback_scopes",
      {"contact_id", "dl_reservation_conflict"},
      "feedback_scope",
      ["contact_allocation"],
      ["stale_contact_allocation"]
    )
  end

  test "station conflict trust boundary remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "station_reservation_conflict_trust_boundaries",
      {"contact_id", "dl_reservation_conflict"},
      "trust_boundary",
      ["mission_state_reservation_conflict_summary"],
      ["stale_mission_state_reservation_conflict_summary"]
    )
  end

  test "station hold expiration risk context remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_expiration_context_contract(
      handoff,
      "station_reservation_hold_expiration_statuses",
      {"contact_id", "dl_hold_import_review"},
      "active"
    )
  end

  test "station hold identity remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "station_reservation_hold_ids",
      {"contact_id", "dl_hold_import_review"},
      "station_reservation_hold_ids",
      ["reservation_hold_active", "reservation_hold_missing"],
      ["stale_reservation_hold_active"]
    )
  end

  test "station hold identity routing by import status remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "station_reservation_hold_ids_by_import_status",
      {"contact_id", "dl_hold_import_review"},
      "station_reservation_hold_ids_by_import_status",
      [
        %{
          "review_required_before_import" => [
            "reservation_hold_active",
            "reservation_hold_missing"
          ]
        }
      ],
      [%{"review_required_before_import" => ["stale_reservation_hold"]}]
    )
  end

  test "station hold identity routing by required action remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "station_reservation_hold_ids_by_required_import_action",
      {"contact_id", "dl_hold_import_review"},
      "station_reservation_hold_ids_by_required_import_action",
      [
        %{
          "review_station_provider_contention" => ["reservation_hold_missing"],
          "review_station_reservation_overlap" => ["reservation_hold_active"]
        }
      ],
      [%{"review_station_provider_contention" => ["stale_reservation_hold"]}]
    )
  end

  test "station hold identity routing by direction remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "station_reservation_hold_ids_by_direction",
      {"contact_id", "dl_hold_import_review"},
      "station_reservation_hold_ids_by_direction",
      [
        %{
          "downlink" => ["reservation_hold_active"],
          "uplink" => ["reservation_hold_missing"]
        }
      ],
      [%{"downlink" => ["stale_reservation_hold"]}]
    )
  end

  test "station hold identity routing by direction and station remains source exact across handoffs",
       %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "station_reservation_hold_ids_by_direction_and_ground_station_id",
      {"contact_id", "dl_hold_import_review"},
      "station_reservation_hold_ids_by_direction_and_ground_station_id",
      [
        %{
          "downlink:equator_prime" => ["reservation_hold_active"],
          "uplink:equator_prime" => ["reservation_hold_missing"]
        }
      ],
      [%{"downlink:equator_prime" => ["stale_reservation_hold"]}]
    )
  end

  test "station hold contact identity remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "station_reservation_hold_contact_ids",
      {"contact_id", "dl_hold_import_review"},
      "contact_id",
      ["dl_hold_import_review"],
      ["stale_dl_hold_import_review"]
    )
  end

  test "station hold contact routing by import status remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "station_reservation_hold_contact_ids_by_import_status",
      {"contact_id", "dl_hold_import_review"},
      "station_reservation_hold_contact_ids_by_import_status",
      [%{"review_required_before_import" => ["dl_hold_import_review"]}],
      [%{"review_required_before_import" => ["stale_hold_contact"]}]
    )
  end

  test "station hold contact routing by expiration status remains source exact across handoffs",
       %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "station_reservation_hold_contact_ids_by_expiration_status",
      {"contact_id", "dl_hold_import_review"},
      "station_reservation_hold_contact_ids_by_expiration_status",
      [%{"active" => ["dl_hold_import_review"]}],
      [%{"active" => ["stale_hold_contact"]}]
    )
  end

  test "station hold contact routing by direction remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "station_reservation_hold_contact_ids_by_direction",
      {"contact_id", "dl_hold_import_review"},
      "station_reservation_hold_contact_ids_by_direction",
      [%{"downlink" => ["dl_hold_import_review"]}],
      [%{"downlink" => ["stale_hold_contact"]}]
    )
  end

  test "station hold contact routing by direction and station remains source exact across handoffs",
       %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "station_reservation_hold_contact_ids_by_direction_and_ground_station_id",
      {"contact_id", "dl_hold_import_review"},
      "station_reservation_hold_contact_ids_by_direction_and_ground_station_id",
      [%{"downlink:equator_prime" => ["dl_hold_import_review"]}],
      [%{"downlink:equator_prime" => ["stale_hold_contact"]}]
    )
  end

  test "station hold counts by import status remain source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "station_reservation_hold_import_status_count_maps",
      {"contact_id", "dl_hold_import_review"},
      "station_reservation_hold_import_status_counts",
      [%{"review_required_before_import" => 2}],
      [%{"review_required_before_import" => 3}]
    )
  end

  test "station hold counts by required action remain source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "station_reservation_hold_required_import_action_count_maps",
      {"contact_id", "dl_hold_import_review"},
      "station_reservation_hold_required_import_action_counts",
      [
        %{
          "review_station_provider_contention" => 1,
          "review_station_reservation_overlap" => 1
        }
      ],
      [%{"review_station_provider_contention" => 2}]
    )
  end

  test "station hold import execution boundary remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "station_reservation_hold_import_execution_boundaries",
      {"contact_id", "dl_hold_import_review"},
      "station_reservation_hold_import_execution_boundary",
      ["artifact_only_no_provider_or_cadence_writes"],
      ["provider_and_cadence_writes_allowed"]
    )
  end

  test "station hold provider-write boundary remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "station_reservation_hold_provider_write_values",
      {"contact_id", "dl_hold_import_review"},
      "station_reservation_hold_provider_write",
      ["not_performed_by_summary"],
      ["performed_by_summary"]
    )
  end

  test "station hold Cadence-write boundary remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "station_reservation_hold_cadence_write_values",
      {"contact_id", "dl_hold_import_review"},
      "station_reservation_hold_cadence_write",
      ["not_performed_by_summary"],
      ["performed_by_summary"]
    )
  end

  test "station hold reservation-acceptance boundary remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "station_reservation_hold_reservation_acceptance_values",
      {"contact_id", "dl_hold_import_review"},
      "station_reservation_hold_reservation_acceptance",
      ["not_performed_by_summary"],
      ["performed_by_summary"]
    )
  end

  test "station hold feedback source remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "station_reservation_hold_feedback_sources",
      {"contact_id", "dl_hold_import_review"},
      "feedback_source",
      ["mission_state.source_station_reservation_hold_import_readiness_summary"],
      ["mission_state.stale_station_reservation_hold_import_readiness_summary"]
    )
  end

  test "station hold feedback scope remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "station_reservation_hold_feedback_scopes",
      {"contact_id", "dl_hold_import_review"},
      "feedback_scope",
      ["station_reservation_hold_import_readiness"],
      ["stale_station_reservation_hold_import_readiness"]
    )
  end

  test "station hold trust boundary remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "station_reservation_hold_trust_boundaries",
      {"contact_id", "dl_hold_import_review"},
      "trust_boundary",
      ["mission_state_station_reservation_hold_import_readiness_summary"],
      ["mission_state_stale_station_reservation_hold_import_readiness_summary"]
    )
  end

  test "station hold source summary remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "source_station_reservation_hold_import_readiness_summaries",
      {"contact_id", "dl_hold_import_review"},
      "source_station_reservation_hold_import_readiness_summary",
      [
        %{
          "model" => "artifact_only_station_reservation_hold_import_readiness_summary",
          "source_artifact_type" => "station_reservation_report.v1",
          "source" => "station_calendar_report.reservation_evidence",
          "reservation_hold_count" => 2,
          "import_readiness_status" => "review_required",
          "import_classification" => "review_only"
        }
      ],
      [
        %{
          "model" => "artifact_only_station_reservation_hold_import_readiness_summary",
          "source_artifact_type" => "station_reservation_report.v1",
          "source" => "stale_station_calendar_report.reservation_evidence",
          "reservation_hold_count" => 2,
          "import_readiness_status" => "review_required",
          "import_classification" => "review_only"
        }
      ]
    )
  end

  test "station hold summary model remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "station_reservation_hold_import_readiness_summary_models",
      {"contact_id", "dl_hold_import_review"},
      "station_reservation_hold_import_readiness_summary_model",
      ["artifact_only_station_reservation_hold_import_readiness_summary"],
      ["stale_station_reservation_hold_import_readiness_summary"]
    )
  end

  test "station hold summary source remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "station_reservation_hold_import_readiness_sources",
      {"contact_id", "dl_hold_import_review"},
      "station_reservation_hold_import_readiness_source",
      ["station_calendar_report.reservation_evidence"],
      ["stale_station_calendar_report.reservation_evidence"]
    )
  end

  test "station hold summary source artifact type remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "station_reservation_hold_import_readiness_source_artifact_types",
      {"contact_id", "dl_hold_import_review"},
      "station_reservation_hold_import_readiness_source_artifact_type",
      ["station_reservation_report.v1"],
      ["stale_station_reservation_report.v1"]
    )
  end

  test "station hold import status remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "station_reservation_hold_import_statuses",
      {"contact_id", "dl_hold_import_review"},
      "station_reservation_hold_import_status",
      ["review_required_before_import"],
      ["ready_for_import"]
    )
  end

  test "station hold readiness status remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "station_reservation_hold_import_readiness_statuses",
      {"contact_id", "dl_hold_import_review"},
      "station_reservation_hold_import_readiness_status",
      ["review_required"],
      ["ready"]
    )
  end

  test "station hold import classification remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "station_reservation_hold_import_classifications",
      {"contact_id", "dl_hold_import_review"},
      "station_reservation_hold_import_classification",
      ["review_only"],
      ["auto_import"]
    )
  end

  test "station hold count remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "station_reservation_hold_count_values",
      {"contact_id", "dl_hold_import_review"},
      "station_reservation_hold_count",
      [2],
      [3]
    )
  end

  test "station calendar expiration risk context remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_expiration_context_contract(
      handoff,
      "station_calendar_pressure_station_reservation_expiration_statuses",
      {"station_reservation_id", "reservation_calendar_selected"},
      "active"
    )
  end

  test "station calendar reservation deadlines remain source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "station_calendar_pressure_station_reservation_expires_at_values_s",
      {"station_reservation_id", "reservation_calendar_selected"},
      "station_reservation_expires_at_s",
      [1_260.0],
      [0.0]
    )
  end

  test "station calendar reservation identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "station_calendar_pressure_station_reservation_ids",
      {"station_reservation_id", "reservation_calendar_selected"},
      "station_reservation_id",
      ["reservation_calendar_selected"],
      ["reservation_calendar_stale"]
    )
  end

  test "station calendar reservation ownership remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "station_calendar_pressure_station_reserved_by",
      {"station_reservation_id", "reservation_calendar_selected"},
      "station_reserved_by",
      ["partner_team"],
      ["stale_partner_team"]
    )
  end

  test "station calendar reservation status remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "station_calendar_pressure_station_reservation_statuses",
      {"station_reservation_id", "reservation_calendar_selected"},
      "station_reservation_status",
      ["confirmed"],
      ["stale_status"]
    )
  end

  test "station calendar reservation match status remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "station_calendar_pressure_station_reservation_match_statuses",
      {"station_reservation_id", "reservation_calendar_selected"},
      "station_reservation_match_status",
      ["overlap"],
      ["stale_match_status"]
    )
  end

  test "station calendar entry identity remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "station_calendar_pressure_station_calendar_entry_ids",
      {"station_reservation_id", "reservation_calendar_selected"},
      "station_calendar_entry_id",
      ["calendar_selected_reserved"],
      ["stale_calendar_entry"]
    )
  end

  test "station calendar provider identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "station_calendar_pressure_station_calendar_provider_ids",
      {"station_reservation_id", "reservation_calendar_selected"},
      "station_calendar_provider_id",
      ["partner_calendar"],
      ["stale_provider"]
    )
  end

  test "station calendar provider entry identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "station_calendar_pressure_station_calendar_provider_entry_ids",
      {"station_reservation_id", "reservation_calendar_selected"},
      "station_calendar_provider_entry_id",
      ["partner_entry_calendar_selected"],
      ["stale_provider_entry"]
    )
  end

  test "station calendar direction remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "station_calendar_pressure_station_calendar_directions",
      {"station_reservation_id", "reservation_calendar_selected"},
      "station_calendar_directions",
      ["downlink"],
      ["uplink"]
    )
  end

  test "station calendar status remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "station_calendar_pressure_station_calendar_statuses",
      {"station_reservation_id", "reservation_calendar_selected"},
      "station_calendar_status",
      ["reserved"],
      ["maintenance"]
    )
  end

  test "station calendar availability remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "station_calendar_pressure_station_availabilities",
      {"station_reservation_id", "reservation_calendar_selected"},
      "station_availability",
      ["reserved"],
      ["unavailable"]
    )
  end

  test "station calendar contention status remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "station_calendar_pressure_station_contention_statuses",
      {"station_reservation_id", "reservation_calendar_selected"},
      "station_contention_status",
      ["reserved_overlap"],
      ["available"]
    )
  end

  test "station calendar overlap count remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "station_calendar_pressure_station_calendar_overlap_count_values",
      {"station_reservation_id", "reservation_calendar_selected"},
      "station_calendar_overlap_count",
      [2],
      [99]
    )
  end

  test "station calendar overlap entry identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "station_calendar_pressure_station_calendar_overlap_entry_ids",
      {"station_reservation_id", "reservation_calendar_selected"},
      "station_calendar_overlap_entry_ids",
      ["calendar_selected_reserved", "calendar_selected_maintenance"],
      ["calendar_selected_reserved", "calendar_stale_maintenance"]
    )
  end

  test "station calendar overlap availability remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "station_calendar_pressure_station_calendar_overlap_availabilities",
      {"station_reservation_id", "reservation_calendar_selected"},
      "station_calendar_overlap_availabilities",
      ["reserved", "maintenance"],
      ["reserved", "available"]
    )
  end

  test "station calendar entry ambiguity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "station_calendar_pressure_station_calendar_entry_ambiguous_values",
      {"station_reservation_id", "reservation_calendar_selected"},
      "station_calendar_entry_ambiguous",
      [true],
      [false]
    )
  end

  test "station calendar ambiguous entry count remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "station_calendar_pressure_station_calendar_ambiguous_entry_count_values",
      {"station_reservation_id", "reservation_calendar_selected"},
      "station_calendar_ambiguous_entry_count",
      [2],
      [99]
    )
  end

  test "station calendar ambiguous entry identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "station_calendar_pressure_station_calendar_ambiguous_entry_ids",
      {"station_reservation_id", "reservation_calendar_selected"},
      "station_calendar_ambiguous_entry_ids",
      ["calendar_selected_reserved", "calendar_selected_backup"],
      ["calendar_selected_reserved", "calendar_stale_backup"]
    )
  end

  test "station calendar reservation overlap count remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "station_calendar_pressure_station_calendar_reservation_overlap_count_values",
      {"station_reservation_id", "reservation_calendar_selected"},
      "station_calendar_reservation_overlap_count",
      [1],
      [99]
    )
  end

  test "calendar-scoped reservation identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "station_calendar_pressure_station_calendar_reservation_ids",
      {"station_reservation_id", "reservation_calendar_selected"},
      "station_calendar_reservation_ids",
      ["reservation_calendar_selected"],
      ["reservation_calendar_stale"]
    )
  end

  test "calendar-scoped reservation ownership remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "station_calendar_pressure_station_calendar_reserved_by",
      {"station_reservation_id", "reservation_calendar_selected"},
      "station_calendar_reserved_by",
      ["partner_team"],
      ["stale_team"]
    )
  end

  test "calendar-scoped reservation status remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "station_calendar_pressure_station_calendar_reservation_statuses",
      {"station_reservation_id", "reservation_calendar_selected"},
      "station_calendar_reservation_statuses",
      ["confirmed"],
      ["cancelled"]
    )
  end

  test "station calendar trust-boundary status remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "station_calendar_pressure_station_calendar_trust_boundary_statuses",
      {"station_reservation_id", "reservation_calendar_selected"},
      "station_calendar_trust_boundary_status",
      ["declared"],
      ["undeclared"]
    )
  end

  test "provider calendar contention group remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "station_calendar_pressure_provider_calendar_contention_group_ids",
      {"station_reservation_id", "reservation_calendar_selected"},
      "provider_calendar_contention_group_id",
      ["provider_contention_selected"],
      ["provider_contention_stale"]
    )
  end

  test "provider calendar contention status remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "station_calendar_pressure_provider_calendar_contention_statuses",
      {"station_reservation_id", "reservation_calendar_selected"},
      "provider_calendar_contention_status",
      ["review_required"],
      ["resolved"]
    )
  end

  test "provider calendar contention entry identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "station_calendar_pressure_provider_calendar_contention_entry_ids",
      {"station_reservation_id", "reservation_calendar_selected"},
      "provider_calendar_contention_entry_ids",
      ["calendar_selected_reserved", "calendar_selected_maintenance"],
      ["calendar_selected_reserved", "calendar_stale_maintenance"]
    )
  end

  test "provider calendar contention provider identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "station_calendar_pressure_provider_calendar_contention_provider_ids",
      {"station_reservation_id", "reservation_calendar_selected"},
      "provider_calendar_contention_provider_ids",
      ["partner_calendar"],
      ["stale_partner_calendar"]
    )
  end

  test "provider calendar contention provider-entry identity remains source exact across handoffs",
       %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "station_calendar_pressure_provider_calendar_contention_provider_entry_ids",
      {"station_reservation_id", "reservation_calendar_selected"},
      "provider_calendar_contention_provider_entry_ids",
      ["partner_entry_calendar_selected", "partner_entry_calendar_maintenance"],
      ["partner_entry_calendar_selected", "stale_partner_entry_calendar_maintenance"]
    )
  end

  test "provider calendar contention availability remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "station_calendar_pressure_provider_calendar_contention_availabilities",
      {"station_reservation_id", "reservation_calendar_selected"},
      "provider_calendar_contention_availabilities",
      ["reserved", "maintenance"],
      ["reserved", "unavailable"]
    )
  end

  test "provider calendar contention direction remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "station_calendar_pressure_provider_calendar_contention_directions",
      {"station_reservation_id", "reservation_calendar_selected"},
      "provider_calendar_contention_directions",
      ["downlink"],
      ["uplink"]
    )
  end

  test "provider calendar contention reservation identity remains source exact across handoffs",
       %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "station_calendar_pressure_provider_calendar_contention_reservation_ids",
      {"station_reservation_id", "reservation_calendar_selected"},
      "provider_calendar_contention_reservation_ids",
      ["reservation_calendar_selected"],
      ["reservation_calendar_stale"]
    )
  end

  test "provider calendar contention reservation owner remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "station_calendar_pressure_provider_calendar_contention_reserved_by",
      {"station_reservation_id", "reservation_calendar_selected"},
      "provider_calendar_contention_reserved_by",
      ["partner_team"],
      ["stale_partner_team"]
    )
  end

  test "provider calendar contention reservation status remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "station_calendar_pressure_provider_calendar_contention_reservation_statuses",
      {"station_reservation_id", "reservation_calendar_selected"},
      "provider_calendar_contention_reservation_statuses",
      ["confirmed"],
      ["pending"]
    )
  end

  test "provider calendar contention trust-boundary status remains source exact across handoffs",
       %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "station_calendar_pressure_provider_calendar_contention_trust_boundary_statuses",
      {"station_reservation_id", "reservation_calendar_selected"},
      "provider_calendar_contention_trust_boundary_statuses",
      ["declared"],
      ["inferred"]
    )
  end

  test "provider calendar contention overlap pair remains source exact across handoffs", %{
    handoff: handoff
  } do
    expected_pair = %{
      "left_entry_id" => "calendar_selected_reserved",
      "right_entry_id" => "calendar_selected_maintenance",
      "overlap_starts_at_s" => 1_170.0,
      "overlap_ends_at_s" => 1_230.0,
      "overlap_duration_s" => 60.0
    }

    stale_pair = Map.put(expected_pair, "right_entry_id", "calendar_stale_maintenance")

    assert_risk_context_contract(
      handoff,
      "station_calendar_pressure_provider_calendar_contention_overlap_pairs",
      {"station_reservation_id", "reservation_calendar_selected"},
      "provider_calendar_contention_overlap_pairs",
      [expected_pair],
      [stale_pair]
    )
  end

  test "station calendar ground-station identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "station_calendar_pressure_ground_station_ids",
      {"station_reservation_id", "reservation_calendar_selected"},
      "ground_station_id",
      ["canberra"],
      ["stale_canberra"]
    )
  end

  test "station calendar start timing remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "station_calendar_pressure_start_values_s",
      {"station_reservation_id", "reservation_calendar_selected"},
      "starts_at_s",
      [1_170.0],
      [1_171.0]
    )
  end

  test "station calendar end timing remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "station_calendar_pressure_end_values_s",
      {"station_reservation_id", "reservation_calendar_selected"},
      "ends_at_s",
      [1_230.0],
      [1_231.0]
    )
  end

  test "station calendar capacity fraction remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "station_calendar_pressure_capacity_fraction_values",
      {"station_reservation_id", "reservation_calendar_selected"},
      "capacity_fraction",
      [0.4],
      [0.6]
    )
  end

  test "station calendar risk type remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "station_calendar_pressure_risk_types",
      {"station_reservation_id", "reservation_calendar_selected"},
      "type",
      ["ground_station_reserved"],
      ["ground_station_outage"],
      :drop_risk
    )
  end

  test "station calendar required action remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "station_calendar_pressure_required_operator_actions",
      {"station_reservation_id", "reservation_calendar_selected"},
      "required_operator_action",
      ["review_station_calendar"],
      ["review_stale_station_calendar"]
    )
  end

  test "station calendar feedback source remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "station_calendar_pressure_feedback_sources",
      {"station_reservation_id", "reservation_calendar_selected"},
      "feedback_source",
      ["mission_state.source_station_calendar_report.affected_contacts"],
      ["mission_state.stale_station_calendar_report.affected_contacts"]
    )
  end

  test "station calendar feedback scope remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "station_calendar_pressure_feedback_scopes",
      {"station_reservation_id", "reservation_calendar_selected"},
      "feedback_scope",
      ["station_calendar"],
      ["contact_intent"]
    )
  end

  test "station calendar trust boundary remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "station_calendar_pressure_trust_boundaries",
      {"station_reservation_id", "reservation_calendar_selected"},
      "trust_boundary",
      ["mission_state_station_calendar_report"],
      ["mission_state_stale_station_calendar_report"]
    )
  end

  test "station calendar derivation reasons remain source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "station_calendar_pressure_derivation_reasons",
      {"station_reservation_id", "reservation_calendar_selected"},
      "derivation_reasons",
      ["station_calendar_reserved", "reserved_overlap", "overlap"],
      ["station_calendar_reserved", "reserved_overlap", "stale_overlap"]
    )
  end
end
