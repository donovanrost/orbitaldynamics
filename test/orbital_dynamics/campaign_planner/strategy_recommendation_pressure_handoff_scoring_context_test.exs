Code.require_file("support.exs", __DIR__)

Code.require_file(
  "../../support/campaign_planner/strategy_recommendation_pressure_handoff_case.ex",
  __DIR__
)

defmodule OrbitalDynamics.CampaignPlanner.StrategyRecommendationPressureHandoffScoringContextTest do
  use OrbitalDynamics.CampaignPlanner.StrategyRecommendationPressureHandoffCase

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
end
