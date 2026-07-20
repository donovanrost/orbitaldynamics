defmodule OrbitalDynamics.RecommendationRiskContext.ScoreTerm do
  @moduledoc false

  @context_keys [
    "score_term_pressure_risk_types",
    "score_term_pressure_objective_ids",
    "score_term_pressure_objective_types",
    "score_term_pressure_latency_objective_values",
    "score_term_pressure_target_ids",
    "score_term_pressure_scenario_ids",
    "score_term_pressure_branch_ids",
    "score_term_pressure_ground_station_ids",
    "score_term_pressure_collection_ids",
    "score_term_pressure_product_ids",
    "score_term_pressure_payload_ids",
    "score_term_pressure_instrument_ids",
    "score_term_pressure_start_values_s",
    "score_term_pressure_end_values_s",
    "score_term_pressure_required_contact_values",
    "score_term_pressure_planned_contact_values",
    "score_term_pressure_required_downlink_values_mb",
    "score_term_pressure_planned_downlink_values_mb",
    "score_term_pressure_max_latency_values_s",
    "score_term_pressure_planned_latency_values_s",
    "score_term_pressure_required_observation_values",
    "score_term_pressure_planned_observation_values",
    "score_term_pressure_priorities",
    "score_term_pressure_latitude_values_deg",
    "score_term_pressure_longitude_values_deg",
    "score_term_pressure_minimum_elevation_values_deg",
    "score_term_pressure_source_activity_ids",
    "score_term_pressure_keys",
    "score_term_pressure_values",
    "score_term_pressure_timeline_score_values",
    "score_term_pressure_score_term_maps",
    "score_term_pressure_downlink_demand_sources",
    "score_term_pressure_downlink_completion_sources",
    "score_term_pressure_feedback_sources",
    "score_term_pressure_feedback_scopes",
    "score_term_pressure_trust_boundaries",
    "score_term_pressure_derivation_reasons"
  ]

  def context_keys, do: @context_keys

  def context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)
    score_term_risks = Enum.filter(risks, &risk?/1)

    %{
      "score_term_pressure_risk_types" =>
        risk_context_values(score_term_risks, ["type", "risk_type"]),
      "score_term_pressure_objective_ids" =>
        risk_context_values(score_term_risks, "objective_id"),
      "score_term_pressure_objective_types" =>
        risk_context_values(score_term_risks, "objective_type"),
      "score_term_pressure_latency_objective_values" =>
        risk_context_values(score_term_risks, "latency_objective"),
      "score_term_pressure_target_ids" => risk_context_values(score_term_risks, "target_id"),
      "score_term_pressure_scenario_ids" => risk_context_values(score_term_risks, "scenario_id"),
      "score_term_pressure_branch_ids" => risk_context_values(score_term_risks, "branch_id"),
      "score_term_pressure_ground_station_ids" =>
        risk_context_values(score_term_risks, "ground_station_id"),
      "score_term_pressure_collection_ids" =>
        risk_context_values(score_term_risks, ["collection_id", "collection_ids"]),
      "score_term_pressure_product_ids" =>
        risk_context_values(score_term_risks, ["product_id", "product_ids"]),
      "score_term_pressure_payload_ids" =>
        risk_context_values(score_term_risks, ["payload_id", "payload_ids"]),
      "score_term_pressure_instrument_ids" =>
        risk_context_values(score_term_risks, ["instrument_id", "instrument_ids"]),
      "score_term_pressure_start_values_s" =>
        risk_context_values(score_term_risks, "starts_at_s"),
      "score_term_pressure_end_values_s" => risk_context_values(score_term_risks, "ends_at_s"),
      "score_term_pressure_required_contact_values" =>
        risk_context_values(score_term_risks, "required_contacts"),
      "score_term_pressure_planned_contact_values" =>
        risk_context_values(score_term_risks, "planned_contacts"),
      "score_term_pressure_required_downlink_values_mb" =>
        risk_context_values(score_term_risks, "required_downlink_mb"),
      "score_term_pressure_planned_downlink_values_mb" =>
        risk_context_values(score_term_risks, "planned_downlink_mb"),
      "score_term_pressure_max_latency_values_s" =>
        risk_context_values(score_term_risks, "max_latency_s"),
      "score_term_pressure_planned_latency_values_s" =>
        risk_context_values(score_term_risks, "planned_latency_s"),
      "score_term_pressure_required_observation_values" =>
        risk_context_values(score_term_risks, "required_observations"),
      "score_term_pressure_planned_observation_values" =>
        risk_context_values(score_term_risks, "planned_observations"),
      "score_term_pressure_priorities" => risk_context_values(score_term_risks, "priority"),
      "score_term_pressure_latitude_values_deg" =>
        risk_context_values(score_term_risks, "latitude_deg"),
      "score_term_pressure_longitude_values_deg" =>
        risk_context_values(score_term_risks, "longitude_deg"),
      "score_term_pressure_minimum_elevation_values_deg" =>
        risk_context_values(score_term_risks, "minimum_elevation_deg"),
      "score_term_pressure_source_activity_ids" =>
        risk_context_values(score_term_risks, ["source_activity_id", "source_activity_ids"]),
      "score_term_pressure_keys" => risk_context_values(score_term_risks, "score_term_key"),
      "score_term_pressure_values" => risk_context_values(score_term_risks, "score_term_value"),
      "score_term_pressure_timeline_score_values" =>
        risk_context_values(score_term_risks, "timeline_score"),
      "score_term_pressure_score_term_maps" =>
        risk_context_values(score_term_risks, "score_terms"),
      "score_term_pressure_downlink_demand_sources" =>
        risk_context_values(score_term_risks, ["downlink_demand_sources"]),
      "score_term_pressure_downlink_completion_sources" =>
        risk_context_values(score_term_risks, ["downlink_completion_sources"]),
      "score_term_pressure_feedback_sources" =>
        risk_context_values(score_term_risks, "feedback_source"),
      "score_term_pressure_feedback_scopes" =>
        risk_context_values(score_term_risks, "feedback_scope"),
      "score_term_pressure_trust_boundaries" =>
        risk_context_values(score_term_risks, "trust_boundary"),
      "score_term_pressure_derivation_reasons" =>
        risk_context_values(score_term_risks, ["derivation_reasons"])
    }
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def context(_risks), do: %{}

  defp risk?(%{"feedback_scope" => "score_term"}), do: true
  defp risk?(_risk), do: false

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
