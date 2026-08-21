Code.require_file("support.exs", __DIR__)

Code.require_file(
  "../../support/campaign_planner/strategy_recommendation_pressure_handoff_case.ex",
  __DIR__
)

defmodule OrbitalDynamics.CampaignPlanner.StrategyRecommendationPressureHandoffObjectiveContextTest do
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
end
