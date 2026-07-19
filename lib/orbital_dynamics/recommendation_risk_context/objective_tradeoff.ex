defmodule OrbitalDynamics.RecommendationRiskContext.ObjectiveTradeoff do
  @moduledoc false

  @context_keys [
    "objective_tradeoff_pressure_risk_types",
    "objective_tradeoff_pressure_objective_ids",
    "objective_tradeoff_pressure_objective_types",
    "objective_tradeoff_pressure_latency_objective_values",
    "objective_tradeoff_pressure_target_ids",
    "objective_tradeoff_pressure_scenario_ids",
    "objective_tradeoff_pressure_branch_ids",
    "objective_tradeoff_pressure_ground_station_ids",
    "objective_tradeoff_pressure_collection_ids",
    "objective_tradeoff_pressure_product_ids",
    "objective_tradeoff_pressure_payload_ids",
    "objective_tradeoff_pressure_instrument_ids",
    "objective_tradeoff_pressure_start_values_s",
    "objective_tradeoff_pressure_end_values_s",
    "objective_tradeoff_pressure_required_contact_values",
    "objective_tradeoff_pressure_planned_contact_values",
    "objective_tradeoff_pressure_required_downlink_values_mb",
    "objective_tradeoff_pressure_planned_downlink_values_mb",
    "objective_tradeoff_pressure_max_latency_values_s",
    "objective_tradeoff_pressure_planned_latency_values_s",
    "objective_tradeoff_pressure_required_observation_values",
    "objective_tradeoff_pressure_planned_observation_values",
    "objective_tradeoff_pressure_priorities",
    "objective_tradeoff_pressure_latitude_values_deg",
    "objective_tradeoff_pressure_longitude_values_deg",
    "objective_tradeoff_pressure_minimum_elevation_values_deg",
    "objective_tradeoff_pressure_source_activity_ids",
    "objective_tradeoff_pressure_score_values",
    "objective_tradeoff_pressure_score_delta_from_selected_values",
    "objective_tradeoff_pressure_score_term_maps",
    "objective_tradeoff_pressure_feedback_sources",
    "objective_tradeoff_pressure_feedback_scopes",
    "objective_tradeoff_pressure_trust_boundaries",
    "objective_tradeoff_pressure_derivation_reasons"
  ]

  def context_keys, do: @context_keys

  def context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)

    objective_tradeoff_risks =
      Enum.filter(risks, &objective_tradeoff_risk?/1)

    %{
      "objective_tradeoff_pressure_risk_types" =>
        risk_context_values(objective_tradeoff_risks, ["type", "risk_type"]),
      "objective_tradeoff_pressure_objective_ids" =>
        risk_context_values(objective_tradeoff_risks, "objective_id"),
      "objective_tradeoff_pressure_objective_types" =>
        risk_context_values(objective_tradeoff_risks, "objective_type"),
      "objective_tradeoff_pressure_latency_objective_values" =>
        risk_context_values(objective_tradeoff_risks, "latency_objective"),
      "objective_tradeoff_pressure_target_ids" =>
        risk_context_values(objective_tradeoff_risks, "target_id"),
      "objective_tradeoff_pressure_scenario_ids" =>
        risk_context_values(objective_tradeoff_risks, "scenario_id"),
      "objective_tradeoff_pressure_branch_ids" =>
        risk_context_values(objective_tradeoff_risks, "branch_id"),
      "objective_tradeoff_pressure_ground_station_ids" =>
        risk_context_values(objective_tradeoff_risks, "ground_station_id"),
      "objective_tradeoff_pressure_collection_ids" =>
        risk_context_values(objective_tradeoff_risks, ["collection_id", "collection_ids"]),
      "objective_tradeoff_pressure_product_ids" =>
        risk_context_values(objective_tradeoff_risks, ["product_id", "product_ids"]),
      "objective_tradeoff_pressure_payload_ids" =>
        risk_context_values(objective_tradeoff_risks, ["payload_id", "payload_ids"]),
      "objective_tradeoff_pressure_instrument_ids" =>
        risk_context_values(objective_tradeoff_risks, ["instrument_id", "instrument_ids"]),
      "objective_tradeoff_pressure_start_values_s" =>
        risk_context_values(objective_tradeoff_risks, "starts_at_s"),
      "objective_tradeoff_pressure_end_values_s" =>
        risk_context_values(objective_tradeoff_risks, "ends_at_s"),
      "objective_tradeoff_pressure_required_contact_values" =>
        risk_context_values(objective_tradeoff_risks, "required_contacts"),
      "objective_tradeoff_pressure_planned_contact_values" =>
        risk_context_values(objective_tradeoff_risks, "planned_contacts"),
      "objective_tradeoff_pressure_required_downlink_values_mb" =>
        risk_context_values(objective_tradeoff_risks, "required_downlink_mb"),
      "objective_tradeoff_pressure_planned_downlink_values_mb" =>
        risk_context_values(objective_tradeoff_risks, "planned_downlink_mb"),
      "objective_tradeoff_pressure_max_latency_values_s" =>
        risk_context_values(objective_tradeoff_risks, "max_latency_s"),
      "objective_tradeoff_pressure_planned_latency_values_s" =>
        risk_context_values(objective_tradeoff_risks, "planned_latency_s"),
      "objective_tradeoff_pressure_required_observation_values" =>
        risk_context_values(objective_tradeoff_risks, "required_observations"),
      "objective_tradeoff_pressure_planned_observation_values" =>
        risk_context_values(objective_tradeoff_risks, "planned_observations"),
      "objective_tradeoff_pressure_priorities" =>
        risk_context_values(objective_tradeoff_risks, "priority"),
      "objective_tradeoff_pressure_latitude_values_deg" =>
        risk_context_values(objective_tradeoff_risks, "latitude_deg"),
      "objective_tradeoff_pressure_longitude_values_deg" =>
        risk_context_values(objective_tradeoff_risks, "longitude_deg"),
      "objective_tradeoff_pressure_minimum_elevation_values_deg" =>
        risk_context_values(objective_tradeoff_risks, "minimum_elevation_deg"),
      "objective_tradeoff_pressure_source_activity_ids" =>
        risk_context_values(objective_tradeoff_risks, [
          "source_activity_id",
          "source_activity_ids"
        ]),
      "objective_tradeoff_pressure_score_values" =>
        risk_context_values(objective_tradeoff_risks, "score"),
      "objective_tradeoff_pressure_score_delta_from_selected_values" =>
        risk_context_values(objective_tradeoff_risks, "score_delta_from_selected"),
      "objective_tradeoff_pressure_score_term_maps" =>
        risk_context_values(objective_tradeoff_risks, "score_terms"),
      "objective_tradeoff_pressure_feedback_sources" =>
        risk_context_values(objective_tradeoff_risks, "feedback_source"),
      "objective_tradeoff_pressure_feedback_scopes" =>
        risk_context_values(objective_tradeoff_risks, "feedback_scope"),
      "objective_tradeoff_pressure_trust_boundaries" =>
        risk_context_values(objective_tradeoff_risks, "trust_boundary"),
      "objective_tradeoff_pressure_derivation_reasons" =>
        risk_context_values(objective_tradeoff_risks, ["derivation_reasons"])
    }
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def context(_risks), do: %{}

  defp objective_tradeoff_risk?(%{"feedback_scope" => "objective_tradeoff"}), do: true
  defp objective_tradeoff_risk?(_risk), do: false

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
