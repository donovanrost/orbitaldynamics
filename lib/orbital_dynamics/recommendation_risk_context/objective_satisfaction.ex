defmodule OrbitalDynamics.RecommendationRiskContext.ObjectiveSatisfaction do
  @moduledoc false

  @fields [
    {"objective_satisfaction_pressure_risk_types", ["type", "risk_type"]},
    {"objective_satisfaction_pressure_objective_ids", "objective_id"},
    {"objective_satisfaction_pressure_objective_types", "objective_type"},
    {"objective_satisfaction_pressure_objective_statuses", "objective_status"},
    {"objective_satisfaction_pressure_source_objective_statuses", "source_objective_status"},
    {"objective_satisfaction_pressure_latency_objective_values", "latency_objective"},
    {"objective_satisfaction_pressure_target_ids", "target_id"},
    {"objective_satisfaction_pressure_scenario_ids", "scenario_id"},
    {"objective_satisfaction_pressure_spacecraft_ids", "spacecraft_id"},
    {"objective_satisfaction_pressure_branch_ids", "branch_id"},
    {"objective_satisfaction_pressure_ground_station_ids", "ground_station_id"},
    {"objective_satisfaction_pressure_collection_ids", ["collection_id", "collection_ids"]},
    {"objective_satisfaction_pressure_product_ids", ["product_id", "product_ids"]},
    {"objective_satisfaction_pressure_payload_ids", ["payload_id", "payload_ids"]},
    {"objective_satisfaction_pressure_instrument_ids", ["instrument_id", "instrument_ids"]},
    {"objective_satisfaction_pressure_start_values_s", "starts_at_s"},
    {"objective_satisfaction_pressure_end_values_s", "ends_at_s"},
    {"objective_satisfaction_pressure_required_contact_values", "required_contacts"},
    {"objective_satisfaction_pressure_planned_contact_values", "planned_contacts"},
    {"objective_satisfaction_pressure_required_downlink_values_mb", "required_downlink_mb"},
    {"objective_satisfaction_pressure_planned_downlink_values_mb", "planned_downlink_mb"},
    {"objective_satisfaction_pressure_max_latency_values_s", "max_latency_s"},
    {"objective_satisfaction_pressure_planned_latency_values_s", "planned_latency_s"},
    {"objective_satisfaction_pressure_required_observation_values", "required_observations"},
    {"objective_satisfaction_pressure_planned_observation_values", "planned_observations"},
    {"objective_satisfaction_pressure_priorities", "priority"},
    {"objective_satisfaction_pressure_latitude_values_deg", "latitude_deg"},
    {"objective_satisfaction_pressure_longitude_values_deg", "longitude_deg"},
    {"objective_satisfaction_pressure_minimum_elevation_values_deg", "minimum_elevation_deg"},
    {"objective_satisfaction_pressure_source_activity_ids",
     ["source_activity_id", "source_activity_ids"]},
    {"objective_satisfaction_pressure_missed_downlink_activity_ids",
     ["missed_downlink_activity_id", "missed_downlink_activity_ids"]},
    {"objective_satisfaction_pressure_realized_statuses", "realized_status"},
    {"objective_satisfaction_pressure_contact_results", "contact_result"},
    {"objective_satisfaction_pressure_observation_success_factor_values",
     "observation_success_factor"},
    {"objective_satisfaction_pressure_image_quality_score_values", "image_quality_score"},
    {"objective_satisfaction_pressure_image_quality_statuses", "image_quality_status"},
    {"objective_satisfaction_pressure_image_quality_sources", "image_quality_source"},
    {"objective_satisfaction_pressure_cloud_cover_fraction_values", "cloud_cover_fraction"},
    {"objective_satisfaction_pressure_blur_score_values", "blur_score"},
    {"objective_satisfaction_pressure_quality_feedback_sources", "quality_feedback_source"},
    {"objective_satisfaction_pressure_candidate_window_maps", ["candidate_windows"]},
    {"objective_satisfaction_pressure_allowed_scenario_ids", ["allowed_scenario_ids"]},
    {"objective_satisfaction_pressure_spacecraft_constraint_maps", ["spacecraft_constraints"]},
    {"objective_satisfaction_pressure_coverage_objective_ids", "coverage_objective_id"},
    {"objective_satisfaction_pressure_downlink_demand_sources", ["downlink_demand_sources"]},
    {"objective_satisfaction_pressure_downlink_completion_sources",
     ["downlink_completion_sources"]},
    {"objective_satisfaction_pressure_feedback_sources", "feedback_source"},
    {"objective_satisfaction_pressure_feedback_scopes", "feedback_scope"},
    {"objective_satisfaction_pressure_trust_boundaries", "trust_boundary"},
    {"objective_satisfaction_pressure_derivation_reasons", ["derivation_reasons"]}
  ]

  def context_keys, do: Enum.map(@fields, &elem(&1, 0))

  def context(risks) when is_list(risks) do
    objective_satisfaction_risks =
      risks
      |> Enum.map(&stringify_keys/1)
      |> Enum.filter(&objective_satisfaction_risk?/1)

    @fields
    |> Enum.map(fn {output_key, risk_keys} ->
      {output_key, risk_context_values(objective_satisfaction_risks, risk_keys)}
    end)
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def context(_risks), do: %{}

  defp objective_satisfaction_risk?(%{"feedback_scope" => "objective_satisfaction"}), do: true
  defp objective_satisfaction_risk?(_risk), do: false

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
