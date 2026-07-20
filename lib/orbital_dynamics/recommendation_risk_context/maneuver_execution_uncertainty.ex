defmodule OrbitalDynamics.RecommendationRiskContext.ManeuverExecutionUncertainty do
  @moduledoc false

  @context_keys [
    "maneuver_execution_uncertainty_risk_types",
    "maneuver_execution_uncertainty_activity_ids",
    "maneuver_execution_uncertainty_timeline_ids",
    "maneuver_execution_uncertainty_maneuver_ids",
    "maneuver_execution_uncertainty_scenario_ids",
    "maneuver_execution_uncertainty_source_activity_ids",
    "maneuver_execution_uncertainty_replacement_activity_ids",
    "maneuver_execution_uncertainty_statuses",
    "maneuver_execution_uncertainty_sources",
    "maneuver_execution_uncertainty_maps",
    "maneuver_execution_uncertainty_timing_3sigma_values_s",
    "maneuver_execution_uncertainty_timing_3sigma_threshold_values_s",
    "maneuver_execution_uncertainty_delta_v_3sigma_vectors_km_s",
    "maneuver_execution_uncertainty_delta_v_3sigma_magnitude_values_km_s",
    "maneuver_execution_uncertainty_delta_v_3sigma_magnitude_threshold_values_km_s",
    "maneuver_execution_uncertainty_start_values_s",
    "maneuver_execution_uncertainty_end_values_s",
    "maneuver_execution_uncertainty_changed_fields",
    "maneuver_execution_uncertainty_required_operator_actions",
    "maneuver_execution_uncertainty_requires_operator_review_values",
    "maneuver_execution_uncertainty_feedback_sources",
    "maneuver_execution_uncertainty_feedback_scopes",
    "maneuver_execution_uncertainty_feedback_keys",
    "maneuver_execution_uncertainty_trust_boundaries",
    "maneuver_execution_uncertainty_derivation_reasons"
  ]

  def context_keys, do: @context_keys

  def context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)
    uncertainty_risks = Enum.filter(risks, &risk?/1)

    %{
      "maneuver_execution_uncertainty_risk_types" =>
        risk_context_values(uncertainty_risks, ["type", "risk_type"]),
      "maneuver_execution_uncertainty_activity_ids" =>
        risk_context_values(uncertainty_risks, "activity_id"),
      "maneuver_execution_uncertainty_timeline_ids" =>
        risk_context_values(uncertainty_risks, "timeline_id"),
      "maneuver_execution_uncertainty_maneuver_ids" =>
        risk_context_values(uncertainty_risks, "maneuver_id"),
      "maneuver_execution_uncertainty_scenario_ids" =>
        risk_context_values(uncertainty_risks, "scenario_id"),
      "maneuver_execution_uncertainty_source_activity_ids" =>
        risk_context_values(uncertainty_risks, ["source_activity_id", "source_activity_ids"]),
      "maneuver_execution_uncertainty_replacement_activity_ids" =>
        risk_context_values(uncertainty_risks, "replacement_activity_id"),
      "maneuver_execution_uncertainty_statuses" =>
        risk_context_values(uncertainty_risks, "execution_uncertainty_status"),
      "maneuver_execution_uncertainty_sources" =>
        risk_context_values(uncertainty_risks, "execution_uncertainty_source"),
      "maneuver_execution_uncertainty_maps" =>
        risk_context_values(uncertainty_risks, "execution_uncertainty"),
      "maneuver_execution_uncertainty_timing_3sigma_values_s" =>
        risk_context_values(uncertainty_risks, "timing_3sigma_s"),
      "maneuver_execution_uncertainty_timing_3sigma_threshold_values_s" =>
        risk_context_values(uncertainty_risks, "timing_3sigma_threshold_s"),
      "maneuver_execution_uncertainty_delta_v_3sigma_vectors_km_s" =>
        risk_context_values(uncertainty_risks, "delta_v_3sigma_km_s"),
      "maneuver_execution_uncertainty_delta_v_3sigma_magnitude_values_km_s" =>
        risk_context_values(uncertainty_risks, "delta_v_3sigma_magnitude_km_s"),
      "maneuver_execution_uncertainty_delta_v_3sigma_magnitude_threshold_values_km_s" =>
        risk_context_values(
          uncertainty_risks,
          "delta_v_3sigma_magnitude_threshold_km_s"
        ),
      "maneuver_execution_uncertainty_start_values_s" =>
        risk_context_values(uncertainty_risks, "starts_at_s"),
      "maneuver_execution_uncertainty_end_values_s" =>
        risk_context_values(uncertainty_risks, "ends_at_s"),
      "maneuver_execution_uncertainty_changed_fields" =>
        risk_context_values(uncertainty_risks, ["changed_fields"]),
      "maneuver_execution_uncertainty_required_operator_actions" =>
        risk_context_values(uncertainty_risks, "required_operator_action"),
      "maneuver_execution_uncertainty_requires_operator_review_values" =>
        risk_context_values(uncertainty_risks, "requires_operator_review"),
      "maneuver_execution_uncertainty_feedback_sources" =>
        risk_context_values(uncertainty_risks, "feedback_source"),
      "maneuver_execution_uncertainty_feedback_scopes" =>
        risk_context_values(uncertainty_risks, "feedback_scope"),
      "maneuver_execution_uncertainty_feedback_keys" =>
        risk_context_values(uncertainty_risks, "feedback_key"),
      "maneuver_execution_uncertainty_trust_boundaries" =>
        risk_context_values(uncertainty_risks, "trust_boundary"),
      "maneuver_execution_uncertainty_derivation_reasons" =>
        risk_context_values(uncertainty_risks, ["derivation_reasons"])
    }
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def context(_risks), do: %{}

  defp risk?(%{"type" => type}) when is_binary(type) do
    type in [
      "maneuver_execution_uncertainty_high",
      "maneuver_execution_uncertainty_missing"
    ]
  end

  defp risk?(%{"risk_type" => type}) when is_binary(type) do
    type in [
      "maneuver_execution_uncertainty_high",
      "maneuver_execution_uncertainty_missing"
    ]
  end

  defp risk?(%{"feedback_scope" => "maneuver_execution_uncertainty"}), do: true
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
