defmodule OrbitalDynamics.RecommendationRiskContext.ContactContentionResolution do
  @moduledoc false

  @context_keys [
    "contact_contention_resolution_pressure_risk_types",
    "contact_contention_resolution_pressure_contact_ids",
    "contact_contention_resolution_pressure_selected_contact_ids",
    "contact_contention_resolution_pressure_scenario_ids",
    "contact_contention_resolution_pressure_spacecraft_ids",
    "contact_contention_resolution_pressure_ground_station_ids",
    "contact_contention_resolution_pressure_source_activity_ids",
    "contact_contention_resolution_pressure_source_window_ids",
    "contact_contention_resolution_pressure_required_contact_values",
    "contact_contention_resolution_pressure_planned_contact_values",
    "contact_contention_resolution_pressure_required_downlink_values_mb",
    "contact_contention_resolution_pressure_planned_downlink_values_mb",
    "contact_contention_resolution_pressure_start_values_s",
    "contact_contention_resolution_pressure_end_values_s",
    "contact_contention_resolution_pressure_selected_priority_sources",
    "contact_contention_resolution_pressure_selection_reasons",
    "contact_contention_resolution_pressure_resolution_selection_rules",
    "contact_contention_resolution_pressure_priority_override_count_values",
    "contact_contention_resolution_pressure_priority_override_contact_ids",
    "contact_contention_resolution_pressure_review_statuses",
    "contact_contention_resolution_pressure_downlink_demand_sources",
    "contact_contention_resolution_pressure_downlink_completion_sources",
    "contact_contention_resolution_pressure_feedback_sources",
    "contact_contention_resolution_pressure_feedback_scopes",
    "contact_contention_resolution_pressure_trust_boundaries",
    "contact_contention_resolution_pressure_derivation_reasons"
  ]

  def context_keys, do: @context_keys

  def context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)
    resolution_risks = Enum.filter(risks, &resolution_risk?/1)

    %{
      "contact_contention_resolution_pressure_risk_types" =>
        risk_context_values(resolution_risks, ["type", "risk_type"]),
      "contact_contention_resolution_pressure_contact_ids" =>
        risk_context_values(resolution_risks, "contact_id"),
      "contact_contention_resolution_pressure_selected_contact_ids" =>
        risk_context_values(resolution_risks, "selected_contact_id"),
      "contact_contention_resolution_pressure_scenario_ids" =>
        risk_context_values(resolution_risks, "scenario_id"),
      "contact_contention_resolution_pressure_spacecraft_ids" =>
        risk_context_values(resolution_risks, "spacecraft_id"),
      "contact_contention_resolution_pressure_ground_station_ids" =>
        risk_context_values(resolution_risks, "ground_station_id"),
      "contact_contention_resolution_pressure_source_activity_ids" =>
        risk_context_values(resolution_risks, ["source_activity_id", "source_activity_ids"]),
      "contact_contention_resolution_pressure_source_window_ids" =>
        risk_context_values(resolution_risks, "source_window_id"),
      "contact_contention_resolution_pressure_required_contact_values" =>
        risk_context_values(resolution_risks, "required_contacts"),
      "contact_contention_resolution_pressure_planned_contact_values" =>
        risk_context_values(resolution_risks, "planned_contacts"),
      "contact_contention_resolution_pressure_required_downlink_values_mb" =>
        risk_context_values(resolution_risks, "required_downlink_mb"),
      "contact_contention_resolution_pressure_planned_downlink_values_mb" =>
        risk_context_values(resolution_risks, "planned_downlink_mb"),
      "contact_contention_resolution_pressure_start_values_s" =>
        risk_context_values(resolution_risks, "starts_at_s"),
      "contact_contention_resolution_pressure_end_values_s" =>
        risk_context_values(resolution_risks, "ends_at_s"),
      "contact_contention_resolution_pressure_selected_priority_sources" =>
        risk_context_values(resolution_risks, "selected_priority_source"),
      "contact_contention_resolution_pressure_selection_reasons" =>
        risk_context_values(resolution_risks, "selection_reason"),
      "contact_contention_resolution_pressure_resolution_selection_rules" =>
        risk_context_values(resolution_risks, "resolution_selection_rule"),
      "contact_contention_resolution_pressure_priority_override_count_values" =>
        risk_context_values(resolution_risks, "resolution_priority_override_count"),
      "contact_contention_resolution_pressure_priority_override_contact_ids" =>
        risk_context_values(resolution_risks, ["resolution_priority_override_contact_ids"]),
      "contact_contention_resolution_pressure_review_statuses" =>
        risk_context_values(resolution_risks, "review_status"),
      "contact_contention_resolution_pressure_downlink_demand_sources" =>
        risk_context_values(resolution_risks, ["downlink_demand_sources"]),
      "contact_contention_resolution_pressure_downlink_completion_sources" =>
        risk_context_values(resolution_risks, ["downlink_completion_sources"]),
      "contact_contention_resolution_pressure_feedback_sources" =>
        risk_context_values(resolution_risks, "feedback_source"),
      "contact_contention_resolution_pressure_feedback_scopes" =>
        risk_context_values(resolution_risks, "feedback_scope"),
      "contact_contention_resolution_pressure_trust_boundaries" =>
        risk_context_values(resolution_risks, "trust_boundary"),
      "contact_contention_resolution_pressure_derivation_reasons" =>
        risk_context_values(resolution_risks, ["derivation_reasons"])
    }
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def context(_risks), do: %{}

  defp resolution_risk?(%{"feedback_scope" => "contact_contention_resolution"}), do: true
  defp resolution_risk?(_risk), do: false

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
