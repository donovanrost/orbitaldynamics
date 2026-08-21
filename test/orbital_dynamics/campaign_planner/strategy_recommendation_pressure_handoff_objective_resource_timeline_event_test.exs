Code.require_file("support.exs", __DIR__)

Code.require_file(
  "../../support/campaign_planner/strategy_recommendation_pressure_handoff_case.ex",
  __DIR__
)

defmodule OrbitalDynamics.CampaignPlanner.StrategyRecommendationPressureHandoffObjectiveResourceTimelineEventTest do
  use OrbitalDynamics.CampaignPlanner.StrategyRecommendationPressureHandoffCase

  test "objective-satisfaction risk type remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_satisfaction_pressure_risk_types",
      {"feedback_scope", "objective_satisfaction"},
      ["type", "risk_type"],
      ["downlink_completion_gap", "observation_success_rate_low"],
      ["stale_objective_satisfaction_risk"]
    )
  end

  test "objective-satisfaction objective identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_satisfaction_pressure_objective_ids",
      {"feedback_scope", "objective_satisfaction"},
      "objective_id",
      ["objective:target_quality"],
      ["objective:stale_target_quality"]
    )
  end

  test "objective-satisfaction objective type remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_satisfaction_pressure_objective_types",
      {"feedback_scope", "objective_satisfaction"},
      "objective_type",
      ["observation_quality"],
      ["stale_observation_quality"]
    )
  end

  test "objective-satisfaction objective status remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_satisfaction_pressure_objective_statuses",
      {"feedback_scope", "objective_satisfaction"},
      "objective_status",
      ["at_risk"],
      ["stale_at_risk"]
    )
  end

  test "objective-satisfaction source objective status remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_satisfaction_pressure_source_objective_statuses",
      {"feedback_scope", "objective_satisfaction"},
      "source_objective_status",
      ["missed_quality_threshold"],
      ["stale_quality_threshold"]
    )
  end

  test "objective-satisfaction target identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_satisfaction_pressure_target_ids",
      {"feedback_scope", "objective_satisfaction"},
      "target_id",
      ["target_objective_quality"],
      ["stale_target_objective_quality"]
    )
  end

  test "objective-satisfaction scenario identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_satisfaction_pressure_scenario_ids",
      {"feedback_scope", "objective_satisfaction"},
      "scenario_id",
      ["leo_1"],
      ["stale_leo_1"]
    )
  end

  test "objective-satisfaction spacecraft identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_satisfaction_pressure_spacecraft_ids",
      {"feedback_scope", "objective_satisfaction"},
      "spacecraft_id",
      ["leo_1"],
      ["stale_leo_1"]
    )
  end

  test "objective-satisfaction branch identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_satisfaction_pressure_branch_ids",
      {"feedback_scope", "objective_satisfaction"},
      "branch_id",
      ["urgent"],
      ["stale_urgent"]
    )
  end

  test "objective-satisfaction collection identities remain source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_satisfaction_pressure_collection_ids",
      {"feedback_scope", "objective_satisfaction"},
      ["collection_id", "collection_ids"],
      ["collection_objective_quality", "collection_objective_quality_backup"],
      ["stale_collection_objective_quality"]
    )
  end

  test "objective-satisfaction product identities remain source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_satisfaction_pressure_product_ids",
      {"feedback_scope", "objective_satisfaction"},
      ["product_id", "product_ids"],
      ["product_objective_quality", "product_objective_quality_backup"],
      ["stale_product_objective_quality"]
    )
  end

  test "objective-satisfaction payload identities remain source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_satisfaction_pressure_payload_ids",
      {"feedback_scope", "objective_satisfaction"},
      ["payload_id", "payload_ids"],
      ["payload_objective_quality", "payload_objective_quality_backup"],
      ["stale_payload_objective_quality"]
    )
  end

  test "objective-satisfaction instrument identities remain source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_satisfaction_pressure_instrument_ids",
      {"feedback_scope", "objective_satisfaction"},
      ["instrument_id", "instrument_ids"],
      ["instrument_objective_quality", "instrument_objective_quality_backup"],
      ["stale_instrument_objective_quality"]
    )
  end

  test "objective-satisfaction start timing remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_satisfaction_pressure_start_values_s",
      {"feedback_scope", "objective_satisfaction"},
      "starts_at_s",
      [1_380.0],
      [1_381.0]
    )
  end

  test "objective-satisfaction end timing remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_satisfaction_pressure_end_values_s",
      {"feedback_scope", "objective_satisfaction"},
      "ends_at_s",
      [1_440.0],
      [1_441.0]
    )
  end

  test "objective-satisfaction latency objective remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_satisfaction_pressure_latency_objective_values",
      {"feedback_scope", "objective_satisfaction"},
      "latency_objective",
      [true],
      [false]
    )
  end

  test "objective-satisfaction ground station remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_satisfaction_pressure_ground_station_ids",
      {"feedback_scope", "objective_satisfaction"},
      "ground_station_id",
      ["madrid_objective"],
      ["stale_objective_station"]
    )
  end

  test "objective-satisfaction required contacts remain source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_satisfaction_pressure_required_contact_values",
      {"feedback_scope", "objective_satisfaction"},
      "required_contacts",
      [3],
      [4]
    )
  end

  test "objective-satisfaction planned contacts remain source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_satisfaction_pressure_planned_contact_values",
      {"feedback_scope", "objective_satisfaction"},
      "planned_contacts",
      [1],
      [2]
    )
  end

  test "objective-satisfaction required downlink remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_satisfaction_pressure_required_downlink_values_mb",
      {"feedback_scope", "objective_satisfaction"},
      "required_downlink_mb",
      [120.0],
      [121.0]
    )
  end

  test "objective-satisfaction planned downlink remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_satisfaction_pressure_planned_downlink_values_mb",
      {"feedback_scope", "objective_satisfaction"},
      "planned_downlink_mb",
      [70.0],
      [71.0]
    )
  end

  test "objective-satisfaction maximum latency remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_satisfaction_pressure_max_latency_values_s",
      {"feedback_scope", "objective_satisfaction"},
      "max_latency_s",
      [300.0],
      [301.0]
    )
  end

  test "objective-satisfaction planned latency remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_satisfaction_pressure_planned_latency_values_s",
      {"feedback_scope", "objective_satisfaction"},
      "planned_latency_s",
      [480.0],
      [481.0]
    )
  end

  test "objective-satisfaction required observations remain source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_satisfaction_pressure_required_observation_values",
      {"feedback_scope", "objective_satisfaction"},
      "required_observations",
      [2],
      [3]
    )
  end

  test "objective-satisfaction planned observations remain source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_satisfaction_pressure_planned_observation_values",
      {"feedback_scope", "objective_satisfaction"},
      "planned_observations",
      [1],
      [2]
    )
  end

  test "objective-satisfaction priority remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "objective_satisfaction_pressure_priorities",
      {"feedback_scope", "objective_satisfaction"},
      "priority",
      [32.0],
      [33.0]
    )
  end

  test "objective-satisfaction latitude remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "objective_satisfaction_pressure_latitude_values_deg",
      {"feedback_scope", "objective_satisfaction"},
      "latitude_deg",
      [34.1],
      [34.2]
    )
  end

  test "objective-satisfaction longitude remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_satisfaction_pressure_longitude_values_deg",
      {"feedback_scope", "objective_satisfaction"},
      "longitude_deg",
      [-118.2],
      [-118.1]
    )
  end

  test "objective-satisfaction minimum elevation remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_satisfaction_pressure_minimum_elevation_values_deg",
      {"feedback_scope", "objective_satisfaction"},
      "minimum_elevation_deg",
      [15.0],
      [16.0]
    )
  end

  test "objective-satisfaction observation success remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_satisfaction_pressure_observation_success_factor_values",
      {"feedback_scope", "objective_satisfaction"},
      "observation_success_factor",
      [0.35],
      [0.36]
    )
  end

  test "objective-satisfaction image quality score remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_satisfaction_pressure_image_quality_score_values",
      {"feedback_scope", "objective_satisfaction"},
      "image_quality_score",
      [0.42],
      [0.43]
    )
  end

  test "objective-satisfaction image quality status remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_satisfaction_pressure_image_quality_statuses",
      {"feedback_scope", "objective_satisfaction"},
      "image_quality_status",
      ["marginal"],
      ["stale_quality_status"]
    )
  end

  test "objective-satisfaction image quality source remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_satisfaction_pressure_image_quality_sources",
      {"feedback_scope", "objective_satisfaction"},
      "image_quality_source",
      ["provider_imagery_quality"],
      ["stale_imagery_source"]
    )
  end

  test "objective-satisfaction cloud cover remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_satisfaction_pressure_cloud_cover_fraction_values",
      {"feedback_scope", "objective_satisfaction"},
      "cloud_cover_fraction",
      [0.62],
      [0.63]
    )
  end

  test "objective-satisfaction blur score remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_satisfaction_pressure_blur_score_values",
      {"feedback_scope", "objective_satisfaction"},
      "blur_score",
      [0.31],
      [0.32]
    )
  end

  test "objective-satisfaction quality feedback source remains exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_satisfaction_pressure_quality_feedback_sources",
      {"feedback_scope", "objective_satisfaction"},
      "quality_feedback_source",
      ["mission_state.source_imagery_quality.rows"],
      ["stale_quality_feedback_source"]
    )
  end

  test "objective-satisfaction source activity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_satisfaction_pressure_source_activity_ids",
      {"feedback_scope", "objective_satisfaction"},
      ["source_activity_id", "source_activity_ids"],
      ["obs_objective_quality_source", "obs_objective_quality_selected"],
      ["stale_objective_satisfaction_activity"]
    )
  end

  test "objective-satisfaction feedback source remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_satisfaction_pressure_feedback_sources",
      {"feedback_scope", "objective_satisfaction"},
      "feedback_source",
      ["mission_state.source_objective_satisfaction_report.rows"],
      ["stale_objective_satisfaction_source"]
    )
  end

  test "objective-satisfaction feedback scope remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_satisfaction_pressure_feedback_scopes",
      {"feedback_scope", "objective_satisfaction"},
      "feedback_scope",
      ["objective_satisfaction"],
      ["stale_objective_satisfaction_scope"]
    )
  end

  test "objective-satisfaction trust boundary remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_satisfaction_pressure_trust_boundaries",
      {"feedback_scope", "objective_satisfaction"},
      "trust_boundary",
      ["mission_state_objective_satisfaction_report"],
      ["stale_objective_satisfaction_boundary"]
    )
  end

  test "objective-satisfaction derivation reasons remain source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_satisfaction_pressure_derivation_reasons",
      {"feedback_scope", "objective_satisfaction"},
      ["derivation_reasons"],
      [
        "objective_satisfaction_observation_quality_gap",
        "objective_satisfaction_image_quality_marginal"
      ],
      ["stale_objective_satisfaction_derivation"]
    )
  end

  test "objective-satisfaction missed downlink activity remains exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_satisfaction_pressure_missed_downlink_activity_ids",
      {"feedback_scope", "objective_satisfaction"},
      ["missed_downlink_activity_id", "missed_downlink_activity_ids"],
      ["dl_objective_missed", "dl_objective_selected"],
      ["stale_objective_missed_downlink"]
    )
  end

  test "objective-satisfaction realized status remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_satisfaction_pressure_realized_statuses",
      {"feedback_scope", "objective_satisfaction"},
      "realized_status",
      ["missed"],
      ["stale_realized_status"]
    )
  end

  test "objective-satisfaction contact result remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_satisfaction_pressure_contact_results",
      {"feedback_scope", "objective_satisfaction"},
      "contact_result",
      ["missed"],
      ["stale_contact_result"]
    )
  end

  test "objective-satisfaction candidate windows remain source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_satisfaction_pressure_candidate_window_maps",
      {"feedback_scope", "objective_satisfaction"},
      ["candidate_windows"],
      [
        %{
          "id" => "window_objective_quality_primary",
          "scenario_id" => "leo_1",
          "starts_at_s" => 1_380.0,
          "ends_at_s" => 1_440.0
        }
      ],
      [%{"id" => "window_objective_quality_stale"}]
    )
  end

  test "objective-satisfaction allowed scenarios remain source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_satisfaction_pressure_allowed_scenario_ids",
      {"feedback_scope", "objective_satisfaction"},
      ["allowed_scenario_ids"],
      ["leo_1", "leo_2"],
      ["stale_objective_scenario"]
    )
  end

  test "objective-satisfaction spacecraft constraints remain exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_satisfaction_pressure_spacecraft_constraint_maps",
      {"feedback_scope", "objective_satisfaction"},
      ["spacecraft_constraints"],
      ["leo_1", "leo_2"],
      ["stale_objective_spacecraft"]
    )
  end

  test "objective-satisfaction coverage objective remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_satisfaction_pressure_coverage_objective_ids",
      {"feedback_scope", "objective_satisfaction"},
      "coverage_objective_id",
      ["coverage:target_quality"],
      ["coverage:stale_target_quality"]
    )
  end

  test "objective-satisfaction downlink demand source remains exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_satisfaction_pressure_downlink_demand_sources",
      {"feedback_scope", "objective_satisfaction"},
      ["downlink_demand_sources"],
      ["objective_satisfaction.required_downlink"],
      ["stale_objective_downlink_demand"]
    )
  end

  test "objective-satisfaction downlink completion source remains exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_satisfaction_pressure_downlink_completion_sources",
      {"feedback_scope", "objective_satisfaction"},
      ["downlink_completion_sources"],
      ["objective_satisfaction.realized_downlink"],
      ["stale_objective_downlink_completion"]
    )
  end

  test "objective-tradeoff risk type remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "objective_tradeoff_pressure_risk_types",
      {"feedback_scope", "objective_tradeoff"},
      ["type", "risk_type"],
      ["downlink_completion_gap"],
      ["stale_objective_tradeoff_risk"]
    )
  end

  test "objective-tradeoff objective identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_tradeoff_pressure_objective_ids",
      {"feedback_scope", "objective_tradeoff"},
      "objective_id",
      ["objective_tradeoff:latency_gap"],
      ["objective_tradeoff:stale"]
    )
  end

  test "objective-tradeoff objective type remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_tradeoff_pressure_objective_types",
      {"feedback_scope", "objective_tradeoff"},
      "objective_type",
      ["collection_latency"],
      ["stale_collection_latency"]
    )
  end

  test "objective-tradeoff latency-objective flag remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_tradeoff_pressure_latency_objective_values",
      {"feedback_scope", "objective_tradeoff"},
      "latency_objective",
      [true],
      [false]
    )
  end

  test "objective-tradeoff target identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_tradeoff_pressure_target_ids",
      {"feedback_scope", "objective_tradeoff"},
      "target_id",
      ["target_tradeoff"],
      ["stale_target_tradeoff"]
    )
  end

  test "objective-tradeoff scenario identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_tradeoff_pressure_scenario_ids",
      {"feedback_scope", "objective_tradeoff"},
      "scenario_id",
      ["leo_1"],
      ["stale_leo_1"]
    )
  end

  test "objective-tradeoff branch identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_tradeoff_pressure_branch_ids",
      {"feedback_scope", "objective_tradeoff"},
      "branch_id",
      ["urgent"],
      ["stale_urgent"]
    )
  end

  test "objective-tradeoff station identity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_tradeoff_pressure_ground_station_ids",
      {"feedback_scope", "objective_tradeoff"},
      "ground_station_id",
      ["madrid"],
      ["stale_madrid"]
    )
  end

  test "objective-tradeoff collection identities remain source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_tradeoff_pressure_collection_ids",
      {"feedback_scope", "objective_tradeoff"},
      ["collection_id", "collection_ids"],
      ["collection_tradeoff_alpha", "collection_tradeoff_beta"],
      ["stale_collection_tradeoff"]
    )
  end

  test "objective-tradeoff product identities remain source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_tradeoff_pressure_product_ids",
      {"feedback_scope", "objective_tradeoff"},
      ["product_id", "product_ids"],
      ["product_tradeoff_alpha", "product_tradeoff_beta"],
      ["stale_product_tradeoff"]
    )
  end

  test "objective-tradeoff payload identities remain source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_tradeoff_pressure_payload_ids",
      {"feedback_scope", "objective_tradeoff"},
      ["payload_id", "payload_ids"],
      ["payload_tradeoff_alpha", "payload_tradeoff_beta"],
      ["stale_payload_tradeoff"]
    )
  end

  test "objective-tradeoff instrument identities remain source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_tradeoff_pressure_instrument_ids",
      {"feedback_scope", "objective_tradeoff"},
      ["instrument_id", "instrument_ids"],
      ["instrument_tradeoff_alpha", "instrument_tradeoff_beta"],
      ["stale_instrument_tradeoff"]
    )
  end

  test "objective-tradeoff start timing remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "objective_tradeoff_pressure_start_values_s",
      {"feedback_scope", "objective_tradeoff"},
      "starts_at_s",
      [1_460.0],
      [1_461.0]
    )
  end

  test "objective-tradeoff end timing remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "objective_tradeoff_pressure_end_values_s",
      {"feedback_scope", "objective_tradeoff"},
      "ends_at_s",
      [1_580.0],
      [1_581.0]
    )
  end

  test "objective-tradeoff required contacts remain source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_tradeoff_pressure_required_contact_values",
      {"feedback_scope", "objective_tradeoff"},
      "required_contacts",
      [2],
      [3]
    )
  end

  test "objective-tradeoff planned contacts remain source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_tradeoff_pressure_planned_contact_values",
      {"feedback_scope", "objective_tradeoff"},
      "planned_contacts",
      [1],
      [2]
    )
  end

  test "objective-tradeoff required downlink remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_tradeoff_pressure_required_downlink_values_mb",
      {"feedback_scope", "objective_tradeoff"},
      "required_downlink_mb",
      [90.0],
      [91.0]
    )
  end

  test "objective-tradeoff planned downlink remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_tradeoff_pressure_planned_downlink_values_mb",
      {"feedback_scope", "objective_tradeoff"},
      "planned_downlink_mb",
      [45.0],
      [46.0]
    )
  end

  test "objective-tradeoff maximum latency remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_tradeoff_pressure_max_latency_values_s",
      {"feedback_scope", "objective_tradeoff"},
      "max_latency_s",
      [240.0],
      [241.0]
    )
  end

  test "objective-tradeoff planned latency remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_tradeoff_pressure_planned_latency_values_s",
      {"feedback_scope", "objective_tradeoff"},
      "planned_latency_s",
      [390.0],
      [391.0]
    )
  end

  test "objective-tradeoff source activity remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_tradeoff_pressure_source_activity_ids",
      {"feedback_scope", "objective_tradeoff"},
      ["source_activity_id", "source_activity_ids"],
      ["obs_tradeoff_source", "dl_tradeoff_selected"],
      ["stale_tradeoff_source"]
    )
  end

  test "objective-tradeoff score remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "objective_tradeoff_pressure_score_values",
      {"feedback_scope", "objective_tradeoff"},
      "score",
      [7.25],
      [7.5]
    )
  end

  test "objective-tradeoff score delta remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "objective_tradeoff_pressure_score_delta_from_selected_values",
      {"feedback_scope", "objective_tradeoff"},
      "score_delta_from_selected",
      [-2.75],
      [-2.5]
    )
  end

  test "objective-tradeoff score terms remain source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "objective_tradeoff_pressure_score_term_maps",
      {"feedback_scope", "objective_tradeoff"},
      "score_terms",
      [%{"collection_latency_gap_s" => 150.0, "downlink_shortfall_mb" => 45.0}],
      [%{"collection_latency_gap_s" => 151.0, "downlink_shortfall_mb" => 45.0}]
    )
  end

  test "objective-tradeoff required observations remain source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_tradeoff_pressure_required_observation_values",
      {"feedback_scope", "objective_tradeoff"},
      "required_observations",
      [2],
      [3]
    )
  end

  test "objective-tradeoff planned observations remain source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_tradeoff_pressure_planned_observation_values",
      {"feedback_scope", "objective_tradeoff"},
      "planned_observations",
      [1],
      [2]
    )
  end

  test "objective-tradeoff priority remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "objective_tradeoff_pressure_priorities",
      {"feedback_scope", "objective_tradeoff"},
      "priority",
      [24.0],
      [25.0]
    )
  end

  test "objective-tradeoff latitude remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "objective_tradeoff_pressure_latitude_values_deg",
      {"feedback_scope", "objective_tradeoff"},
      "latitude_deg",
      [34.1],
      [34.2]
    )
  end

  test "objective-tradeoff longitude remains source exact across handoffs", %{handoff: handoff} do
    assert_risk_context_contract(
      handoff,
      "objective_tradeoff_pressure_longitude_values_deg",
      {"feedback_scope", "objective_tradeoff"},
      "longitude_deg",
      [-118.2],
      [-118.1]
    )
  end

  test "objective-tradeoff minimum elevation remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_tradeoff_pressure_minimum_elevation_values_deg",
      {"feedback_scope", "objective_tradeoff"},
      "minimum_elevation_deg",
      [15.0],
      [16.0]
    )
  end

  test "objective-tradeoff feedback source remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_tradeoff_pressure_feedback_sources",
      {"feedback_scope", "objective_tradeoff"},
      "feedback_source",
      ["mission_state.source_objective_tradeoff_report.tradeoffs"],
      ["stale_objective_tradeoff_source"]
    )
  end

  test "objective-tradeoff feedback scope remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_tradeoff_pressure_feedback_scopes",
      {"feedback_scope", "objective_tradeoff"},
      "feedback_scope",
      ["objective_tradeoff"],
      ["stale_objective_tradeoff_scope"]
    )
  end

  test "objective-tradeoff trust boundary remains source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_tradeoff_pressure_trust_boundaries",
      {"feedback_scope", "objective_tradeoff"},
      "trust_boundary",
      ["mission_state_objective_tradeoff_report"],
      ["stale_objective_tradeoff_boundary"]
    )
  end

  test "objective-tradeoff derivation reasons remain source exact across handoffs", %{
    handoff: handoff
  } do
    assert_risk_context_contract(
      handoff,
      "objective_tradeoff_pressure_derivation_reasons",
      {"feedback_scope", "objective_tradeoff"},
      ["derivation_reasons"],
      [
        "objective_tradeoff_downlink_gap",
        "collection_latency_gap",
        "objective_tradeoff_latency_gap",
        "objective_tradeoff_unselected"
      ],
      ["stale_objective_tradeoff_derivation"]
    )
  end

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

  @timeline_publication_context_contracts [
    {"identity", "timeline_publication_ids", "publication_id",
     ["timeline_publication:9:timeline:selected_plan:v2:timeline:selected_plan:v1"],
     ["timeline_publication:stale"]},
    {"sequence", "timeline_publication_sequences", "publication_sequence", [9], [10]},
    {"status", "timeline_publication_statuses", "publication_status",
     ["published_with_downstream_invalidations"], ["stale_publication_status"]},
    {"downstream invalidation status", "timeline_publication_downstream_invalidation_statuses",
     "downstream_invalidation_status", ["invalidated"], ["stale_invalidation_status"]},
    {"dependency-impact status", "timeline_publication_dependency_impact_statuses",
     "dependency_impact_status", ["review_required"], ["stale_dependency_status"]},
    {"source-artifact identity", "timeline_publication_source_artifact_ids", "source_artifact_id",
     ["timeline:selected_plan:v2"], ["timeline:stale_plan"]},
    {"source-artifact type", "timeline_publication_source_artifact_types", "source_artifact_type",
     ["operational_timeline_report.v1"], ["stale_timeline_report.v1"]},
    {"authority", "timeline_publication_authorities", "publication_authority",
     ["mission_operations"], ["stale_authority"]},
    {"superseded artifact identities", "timeline_publication_supersedes_artifact_ids",
     ["supersedes_artifact_ids"], ["timeline:selected_plan:v1"], ["timeline:stale_plan"]},
    {"downstream product identities", "timeline_publication_downstream_product_ids",
     ["downstream_product_ids"], ["operator_review:selected:v1", "cadence_import:selected:v1"],
     ["stale_downstream_product"]},
    {"invalidated downstream product identities",
     "timeline_publication_invalidated_downstream_product_ids",
     ["invalidated_downstream_product_ids"],
     ["cadence_import:selected:v1", "operator_review:selected:v1"],
     ["stale_invalidated_product"]},
    {"downstream invalidation reason counts",
     "timeline_publication_downstream_invalidation_reason_count_maps",
     "downstream_invalidation_reason_counts", [%{"dependency_impact_review_required" => 2}],
     [%{"dependency_impact_review_required" => 3}]},
    {"downstream invalidation reasons", "timeline_publication_downstream_invalidation_reasons",
     ["downstream_invalidation_reasons"], ["dependency_impact_review_required"],
     ["stale_invalidation_reason"]},
    {"invalidated products by reason",
     "timeline_publication_invalidated_downstream_product_ids_by_reason",
     "invalidated_downstream_product_ids_by_reason",
     [
       %{
         "dependency_impact_review_required" => [
           "cadence_import:selected:v1",
           "operator_review:selected:v1"
         ]
       }
     ], [%{"dependency_impact_review_required" => ["stale_invalidated_product"]}]},
    {"dependency-impact row count", "timeline_publication_dependency_impact_row_count_values",
     "dependency_impact_row_count", [2], [3]},
    {"timeline-diff row count", "timeline_publication_timeline_diff_row_count_values",
     "timeline_diff_row_count", [3], [4]},
    {"timeline-diff changed count", "timeline_publication_timeline_diff_changed_count_values",
     "timeline_diff_changed_count", [2], [3]},
    {"timeline-diff review-required count",
     "timeline_publication_timeline_diff_review_required_count_values",
     "timeline_diff_review_required_count", [1], [2]},
    {"changed-field counts", "timeline_publication_changed_field_count_maps",
     "changed_field_counts", [%{"timeline_presence" => 2}], [%{"timeline_presence" => 3}]},
    {"changed fields", "timeline_publication_changed_fields", ["changed_fields"],
     ["timeline_presence"], ["stale_changed_field"]},
    {"changed timeline identities", "timeline_publication_changed_timeline_ids",
     ["changed_timeline_ids"], ["timeline:health_check:0.0"], ["timeline:stale_change"]},
    {"review timeline identities", "timeline_publication_review_timeline_ids",
     ["review_timeline_ids"], ["timeline:health_check:0.0", "timeline:health_check:5.0"],
     ["timeline:stale_review"]},
    {"timeline identities by changed field", "timeline_publication_timeline_ids_by_changed_field",
     "timeline_ids_by_changed_field",
     [
       %{
         "timeline_presence" => ["timeline:health_check:0.0", "timeline:health_check:5.0"]
       }
     ], [%{"timeline_presence" => ["timeline:stale_change"]}]},
    {"feedback source", "timeline_publication_feedback_sources", "feedback_source",
     ["mission_state.source_timeline_publication_summary"],
     ["mission_state.stale_timeline_publication_summary"]},
    {"feedback scope", "timeline_publication_feedback_scopes", "feedback_scope",
     ["timeline_publication"], ["stale_timeline_publication"]},
    {"feedback key", "timeline_publication_feedback_keys", "feedback_key",
     ["timeline_publication:9:timeline:selected_plan:v2:timeline:selected_plan:v1"],
     ["timeline_publication:stale"]},
    {"trust boundary", "timeline_publication_trust_boundaries", "trust_boundary",
     ["mission_state_timeline_publication_summary"], ["stale_publication_boundary"]},
    {"derivation reasons", "timeline_publication_derivation_reasons", ["derivation_reasons"],
     ["timeline_publication_summary_pressure"], ["stale_publication_derivation"]},
    {"safety assumptions", "timeline_publication_assumption_maps", "assumptions",
     [
       %{
         "import_approval" => "not_granted_by_strategy_branch",
         "notification_delivery" => "not_performed_by_strategy_branch",
         "operator_authority" => "not_granted_by_strategy_branch",
         "publication_execution" => "not_performed_by_strategy_branch"
       }
     ],
     [
       %{
         "import_approval" => "not_granted_by_strategy_branch",
         "notification_delivery" => "not_performed_by_strategy_branch",
         "operator_authority" => "not_granted_by_strategy_branch",
         "publication_execution" => "stale_publication_execution"
       }
     ]}
  ]

  for {description, field, source_field, expected_value, stale_value} <-
        @timeline_publication_context_contracts do
    test "timeline-publication #{description} remains source exact across handoffs", %{
      handoff: handoff
    } do
      assert_risk_context_contract(
        handoff,
        unquote(field),
        {"feedback_scope", "timeline_publication"},
        unquote(Macro.escape(source_field)),
        unquote(Macro.escape(expected_value)),
        unquote(Macro.escape(stale_value))
      )
    end
  end

  @timeline_lifecycle_state_context_contracts [
    {"status", "timeline_lifecycle_state_statuses", "timeline_lifecycle_state_status",
     ["review_required"], ["stale_lifecycle_status"]},
    {"planned-activity count", "timeline_lifecycle_state_planned_activity_count_values",
     "planned_activity_count", [4], [5]},
    {"realized-activity count", "timeline_lifecycle_state_realized_activity_count_values",
     "realized_activity_count", [1], [2]},
    {"row count", "timeline_lifecycle_state_row_count_values", "row_count", [4], [5]},
    {"recordable count", "timeline_lifecycle_state_recordable_count_values", "recordable_count",
     [3], [4]},
    {"preserved count", "timeline_lifecycle_state_preserved_count_values", "preserved_count", [1],
     [2]},
    {"review-required count", "timeline_lifecycle_state_review_required_count_values",
     "review_required_count", [3], [4]},
    {"duplicate-identity count", "timeline_lifecycle_state_duplicate_identity_count_values",
     "duplicate_timeline_identity_count", [1], [2]},
    {"invalid-activity-input count",
     "timeline_lifecycle_state_invalid_activity_input_count_values",
     "invalid_activity_input_count", [1], [2]},
    {"transition-decision counts", "timeline_lifecycle_state_transition_decision_count_maps",
     "transition_decision_counts", [%{"record" => 3, "none" => 1}],
     [%{"record" => 4, "none" => 1}]},
    {"required-operator-action counts",
     "timeline_lifecycle_state_required_operator_action_count_maps",
     "required_operator_action_counts",
     [
       %{
         "review_activity_approval" => 1,
         "review_duplicate_timeline_identity" => 1,
         "review_invalid_activity_input" => 1
       }
     ],
     [
       %{
         "review_activity_approval" => 2,
         "review_duplicate_timeline_identity" => 1,
         "review_invalid_activity_input" => 1
       }
     ]},
    {"operator-action-reason counts",
     "timeline_lifecycle_state_operator_action_reason_count_maps",
     "operator_action_reason_counts",
     [
       %{
         "activity_approval_pending" => 1,
         "duplicate_timeline_identity" => 1,
         "missing_activity_type" => 1
       }
     ],
     [
       %{
         "activity_approval_pending" => 2,
         "duplicate_timeline_identity" => 1,
         "missing_activity_type" => 1
       }
     ]},
    {"import-action counts", "timeline_lifecycle_state_import_action_count_maps",
     "import_action_counts", [%{"review_timeline_diff" => 3}], [%{"review_timeline_diff" => 4}]},
    {"planned-status-category counts",
     "timeline_lifecycle_state_planned_status_category_count_maps",
     "planned_status_category_counts", [%{"planned" => 4}], [%{"planned" => 5}]},
    {"realized-status-category counts",
     "timeline_lifecycle_state_realized_status_category_count_maps",
     "realized_status_category_counts", [%{"executed" => 1}], [%{"executed" => 2}]},
    {"status-transition-category counts",
     "timeline_lifecycle_state_status_transition_category_count_maps",
     "status_transition_category_counts", [%{"changed" => 1}], [%{"changed" => 2}]},
    {"approval-transition-category counts",
     "timeline_lifecycle_state_approval_transition_category_count_maps",
     "approval_transition_category_counts", [%{"changed" => 1}], [%{"changed" => 2}]},
    {"recordable timeline identities", "timeline_lifecycle_state_recordable_timeline_ids",
     ["recordable_timeline_ids"],
     [
       "timeline:lifecycle:cmd_pending",
       "timeline:lifecycle:dup",
       "timeline:invalid_activity_input:lifecycle_bad_missing_type"
     ], ["timeline:stale_recordable"]},
    {"preserved timeline identities", "timeline_lifecycle_state_preserved_timeline_ids",
     ["preserved_timeline_ids"], ["timeline:lifecycle:obs_preserved"],
     ["timeline:stale_preserved"]},
    {"review timeline identities", "timeline_lifecycle_state_review_timeline_ids",
     ["review_timeline_ids"],
     [
       "timeline:lifecycle:cmd_pending",
       "timeline:lifecycle:dup",
       "timeline:invalid_activity_input:lifecycle_bad_missing_type"
     ], ["timeline:stale_review"]},
    {"review activity identities", "timeline_lifecycle_state_review_activity_ids",
     ["review_activity_ids"],
     [
       "lifecycle_cmd_pending",
       "lifecycle_dup_a",
       "lifecycle_dup_b",
       "timeline_row:4:lifecycle_bad_missing_type"
     ], ["stale_review_activity"]},
    {"invalid-activity-input identities", "timeline_lifecycle_state_invalid_activity_input_ids",
     ["invalid_activity_input_ids"], ["timeline_row:4:lifecycle_bad_missing_type"],
     ["stale_invalid_activity_input"]},
    {"review timelines by required operator action",
     "timeline_lifecycle_state_review_timeline_ids_by_required_operator_action",
     "review_timeline_ids_by_required_operator_action",
     [
       %{
         "review_activity_approval" => ["timeline:lifecycle:cmd_pending"],
         "review_duplicate_timeline_identity" => ["timeline:lifecycle:dup"],
         "review_invalid_activity_input" => [
           "timeline:invalid_activity_input:lifecycle_bad_missing_type"
         ]
       }
     ], [%{"review_activity_approval" => ["timeline:stale_review"]}]},
    {"review timelines by operator-action reason",
     "timeline_lifecycle_state_review_timeline_ids_by_operator_action_reason",
     "review_timeline_ids_by_operator_action_reason",
     [
       %{
         "activity_approval_pending" => ["timeline:lifecycle:cmd_pending"],
         "duplicate_timeline_identity" => ["timeline:lifecycle:dup"],
         "missing_activity_type" => [
           "timeline:invalid_activity_input:lifecycle_bad_missing_type"
         ]
       }
     ], [%{"activity_approval_pending" => ["timeline:stale_review"]}]},
    {"review timelines by status-transition category",
     "timeline_lifecycle_state_review_timeline_ids_by_status_transition_category",
     "review_timeline_ids_by_status_transition_category",
     [%{"changed" => ["timeline:lifecycle:cmd_pending"]}],
     [%{"changed" => ["timeline:stale_review"]}]},
    {"review timelines by approval-transition category",
     "timeline_lifecycle_state_review_timeline_ids_by_approval_transition_category",
     "review_timeline_ids_by_approval_transition_category",
     [%{"changed" => ["timeline:lifecycle:cmd_pending"]}],
     [%{"changed" => ["timeline:stale_review"]}]},
    {"required operator actions", "timeline_lifecycle_state_required_operator_actions",
     "required_operator_action", ["review_timeline_lifecycle_state"], ["stale_operator_action"]},
    {"operator-review requirement", "timeline_lifecycle_state_requires_operator_review_values",
     "requires_operator_review", [true], [false]},
    {"feedback source", "timeline_lifecycle_state_feedback_sources", "feedback_source",
     ["mission_state.source_timeline_lifecycle_state_summary"],
     ["mission_state.stale_timeline_lifecycle_state_summary"]},
    {"feedback scope", "timeline_lifecycle_state_feedback_scopes", "feedback_scope",
     ["timeline_lifecycle_state"], ["stale_timeline_lifecycle_state"]},
    {"feedback key", "timeline_lifecycle_state_feedback_keys", "feedback_key",
     ["mission.lifecycle.summary"], ["stale.lifecycle.summary"]},
    {"trust boundary", "timeline_lifecycle_state_trust_boundaries", "trust_boundary",
     ["mission_state_timeline_lifecycle_state_summary"], ["stale_lifecycle_boundary"]},
    {"derivation reasons", "timeline_lifecycle_state_derivation_reasons", ["derivation_reasons"],
     ["timeline_lifecycle_state_summary_pressure"], ["stale_lifecycle_derivation"]},
    {"safety assumptions", "timeline_lifecycle_state_assumption_maps", "assumptions",
     [
       %{
         "cadence_import" => "not_performed_by_strategy_branch",
         "command_execution" => "not_performed_by_strategy_branch",
         "operator_authority" => "not_granted_by_strategy_branch",
         "timeline_lifecycle_application" => "not_performed_by_strategy_branch",
         "timeline_mutation" => "not_performed_by_strategy_branch"
       }
     ],
     [
       %{
         "cadence_import" => "not_performed_by_strategy_branch",
         "command_execution" => "not_performed_by_strategy_branch",
         "operator_authority" => "not_granted_by_strategy_branch",
         "timeline_lifecycle_application" => "stale_lifecycle_application",
         "timeline_mutation" => "not_performed_by_strategy_branch"
       }
     ]}
  ]

  for {description, field, source_field, expected_value, stale_value} <-
        @timeline_lifecycle_state_context_contracts do
    test "timeline-lifecycle-state #{description} remains source exact across handoffs", %{
      handoff: handoff
    } do
      assert_risk_context_contract(
        handoff,
        unquote(field),
        {"feedback_scope", "timeline_lifecycle_state"},
        unquote(Macro.escape(source_field)),
        unquote(Macro.escape(expected_value)),
        unquote(Macro.escape(stale_value))
      )
    end
  end
end
