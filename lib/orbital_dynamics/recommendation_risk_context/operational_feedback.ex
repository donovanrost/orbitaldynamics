defmodule OrbitalDynamics.RecommendationRiskContext.OperationalFeedback do
  @moduledoc false

  @fields [
    {"strategy_operational_feedback_risk_types", ["type", "risk_type"]},
    {"strategy_operational_feedback_activity_ids", "activity_id"},
    {"strategy_operational_feedback_scenario_ids", "scenario_id"},
    {"strategy_operational_feedback_timeline_ids", "timeline_id"},
    {"strategy_operational_feedback_source_activity_ids",
     ["source_activity_id", "source_activity_ids"]},
    {"strategy_operational_feedback_replacement_activity_ids", "replacement_activity_id"},
    {"strategy_operational_feedback_contact_success_factor_values", "contact_success_factor"},
    {"strategy_operational_feedback_observation_success_factor_values",
     "observation_success_factor"},
    {"strategy_operational_feedback_station_throughput_factor_values",
     "station_throughput_factor"},
    {"strategy_operational_feedback_contact_results", "contact_result"},
    {"strategy_operational_feedback_observation_results", "observation_result"},
    {"strategy_operational_feedback_realized_statuses", "realized_status"},
    {"strategy_operational_feedback_ground_station_ids", "ground_station_id"},
    {"strategy_operational_feedback_planned_ground_station_ids", "planned_ground_station_id"},
    {"strategy_operational_feedback_realized_ground_station_ids", "realized_ground_station_id"},
    {"strategy_operational_feedback_ground_station_match_statuses",
     "ground_station_match_status"},
    {"strategy_operational_feedback_directions", "direction"},
    {"strategy_operational_feedback_planned_directions", "planned_direction"},
    {"strategy_operational_feedback_realized_directions", "realized_direction"},
    {"strategy_operational_feedback_direction_match_statuses", "direction_match_status"},
    {"strategy_operational_feedback_source_window_ids", "source_window_id"},
    {"strategy_operational_feedback_planned_source_window_ids", "planned_source_window_id"},
    {"strategy_operational_feedback_realized_source_window_ids", "realized_source_window_id"},
    {"strategy_operational_feedback_source_window_match_statuses", "source_window_match_status"},
    {"strategy_operational_feedback_contact_identity_mismatch_fields",
     ["contact_identity_mismatch_fields"]},
    {"strategy_operational_feedback_target_ids", "target_id"},
    {"strategy_operational_feedback_planned_target_ids", "planned_target_id"},
    {"strategy_operational_feedback_realized_target_ids", "realized_target_id"},
    {"strategy_operational_feedback_target_match_statuses", "target_match_status"},
    {"strategy_operational_feedback_collection_ids", ["collection_id", "collection_ids"]},
    {"strategy_operational_feedback_planned_collection_ids", "planned_collection_id"},
    {"strategy_operational_feedback_realized_collection_ids", "realized_collection_id"},
    {"strategy_operational_feedback_collection_match_statuses", "collection_match_status"},
    {"strategy_operational_feedback_product_ids", ["product_id", "product_ids"]},
    {"strategy_operational_feedback_planned_product_ids",
     ["planned_product_id", "planned_product_ids"]},
    {"strategy_operational_feedback_realized_product_ids",
     ["realized_product_id", "realized_product_ids"]},
    {"strategy_operational_feedback_product_match_statuses",
     ["product_match_status", "product_ids_match_status"]},
    {"strategy_operational_feedback_payload_ids", ["payload_id", "payload_ids"]},
    {"strategy_operational_feedback_planned_payload_ids", "planned_payload_id"},
    {"strategy_operational_feedback_realized_payload_ids", "realized_payload_id"},
    {"strategy_operational_feedback_payload_match_statuses", "payload_match_status"},
    {"strategy_operational_feedback_instrument_ids", ["instrument_id", "instrument_ids"]},
    {"strategy_operational_feedback_planned_instrument_ids", "planned_instrument_id"},
    {"strategy_operational_feedback_realized_instrument_ids", "realized_instrument_id"},
    {"strategy_operational_feedback_instrument_match_statuses", "instrument_match_status"},
    {"strategy_operational_feedback_observation_identity_mismatch_fields",
     ["observation_identity_mismatch_fields"]},
    {"strategy_operational_feedback_pointing_statuses", "pointing_status"},
    {"strategy_operational_feedback_pointing_error_values_deg", "pointing_error_deg"},
    {"strategy_operational_feedback_attitude_statuses", "attitude_status"},
    {"strategy_operational_feedback_attitude_error_values_deg", "attitude_error_deg"},
    {"strategy_operational_feedback_lighting_condition_match_statuses",
     "lighting_condition_match_status"},
    {"strategy_operational_feedback_planned_lighting_conditions", "planned_lighting_condition"},
    {"strategy_operational_feedback_realized_lighting_conditions", "realized_lighting_condition"},
    {"strategy_operational_feedback_lighting_condition_details", "lighting_condition_detail"},
    {"strategy_operational_feedback_lighting_confidence_values", "lighting_confidence"},
    {"strategy_operational_feedback_eclipse_overlap_fraction_values", "eclipse_overlap_fraction"},
    {"strategy_operational_feedback_image_quality_score_values", "image_quality_score"},
    {"strategy_operational_feedback_image_quality_statuses", "image_quality_status"},
    {"strategy_operational_feedback_image_quality_sources", "image_quality_source"},
    {"strategy_operational_feedback_cloud_cover_fraction_values", "cloud_cover_fraction"},
    {"strategy_operational_feedback_blur_score_values", "blur_score"},
    {"strategy_operational_feedback_actual_throughput_values_mb", "actual_throughput_mb"},
    {"strategy_operational_feedback_estimated_throughput_values_mb", "estimated_throughput_mb"},
    {"strategy_operational_feedback_start_values_s", "starts_at_s"},
    {"strategy_operational_feedback_end_values_s", "ends_at_s"},
    {"strategy_operational_feedback_changed_fields", ["changed_fields"]},
    {"strategy_operational_feedback_status_transition_maps", "status_transition"},
    {"strategy_operational_feedback_transition_types", "transition_type"},
    {"strategy_operational_feedback_transition_categories", "transition_category"},
    {"strategy_operational_feedback_transition_reasons", "transition_reason"},
    {"strategy_operational_feedback_required_operator_actions", "required_operator_action"},
    {"strategy_operational_feedback_requires_operator_review_values", "requires_operator_review"},
    {"strategy_operational_feedback_feedback_sources", "feedback_source"},
    {"strategy_operational_feedback_feedback_scopes", "feedback_scope"},
    {"strategy_operational_feedback_feedback_keys", "feedback_key"},
    {"strategy_operational_feedback_trust_boundaries", "trust_boundary"},
    {"strategy_operational_feedback_derivation_reasons", ["derivation_reasons"]}
  ]

  def field_pairs, do: @fields
  def context_keys, do: Enum.map(@fields, &elem(&1, 0))

  def context(risks) when is_list(risks) do
    operational_feedback_risks =
      risks
      |> Enum.map(&stringify_keys/1)
      |> Enum.filter(&operational_feedback_risk?/1)

    @fields
    |> Enum.map(fn {output_key, risk_keys} ->
      {output_key, risk_context_values(operational_feedback_risks, risk_keys)}
    end)
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def context(_risks), do: %{}

  defp operational_feedback_risk?(%{"type" => type}) when is_binary(type) do
    type in [
      "contact_success_rate_low",
      "observation_success_rate_low",
      "station_throughput_factor_low"
    ]
  end

  defp operational_feedback_risk?(%{"risk_type" => type}) when is_binary(type) do
    type in [
      "contact_success_rate_low",
      "observation_success_rate_low",
      "station_throughput_factor_low"
    ]
  end

  defp operational_feedback_risk?(_risk), do: false

  defp risk_context_values(risks, keys) when is_list(keys) do
    risks
    |> Enum.flat_map(fn risk ->
      Enum.flat_map(keys, fn key ->
        risk
        |> Map.get(key)
        |> List.wrap()
      end)
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp risk_context_values(risks, key) do
    risks
    |> Enum.map(&Map.get(&1, key))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), value}
      {key, value} -> {key, value}
    end)
  end

  defp stringify_keys(value), do: value
end
