defmodule OrbitalDynamics.RecommendationRiskContext.LinkCapacity do
  @moduledoc false

  @context_keys [
    "link_capacity_pressure_risk_types",
    "link_capacity_pressure_ground_station_ids",
    "link_capacity_pressure_required_contact_values",
    "link_capacity_pressure_planned_contact_values",
    "link_capacity_pressure_required_downlink_values_mb",
    "link_capacity_pressure_planned_downlink_values_mb",
    "link_capacity_pressure_start_values_s",
    "link_capacity_pressure_end_values_s",
    "link_capacity_pressure_source_activity_ids",
    "link_capacity_pressure_source_window_ids",
    "link_capacity_pressure_selected_capacity_adjusted_throughput_values_mb",
    "link_capacity_pressure_selected_downlink_shortfall_values_mb",
    "link_capacity_pressure_actual_throughput_values_mb",
    "link_capacity_pressure_actual_downlink_completion_ratio_values",
    "link_capacity_pressure_actual_downlink_shortfall_values_mb",
    "link_capacity_pressure_downlink_requirement_statuses",
    "link_capacity_pressure_actual_downlink_requirement_statuses",
    "link_capacity_pressure_downlink_demand_sources",
    "link_capacity_pressure_downlink_completion_sources",
    "link_capacity_pressure_feedback_sources",
    "link_capacity_pressure_feedback_scopes",
    "link_capacity_pressure_trust_boundaries",
    "link_capacity_pressure_derivation_reasons"
  ]

  def context_keys, do: @context_keys

  def context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)
    link_capacity_risks = Enum.filter(risks, &risk?/1)

    %{
      "link_capacity_pressure_risk_types" =>
        risk_context_values(link_capacity_risks, ["type", "risk_type"]),
      "link_capacity_pressure_ground_station_ids" =>
        risk_context_values(link_capacity_risks, "ground_station_id"),
      "link_capacity_pressure_required_contact_values" =>
        risk_context_values(link_capacity_risks, "required_contacts"),
      "link_capacity_pressure_planned_contact_values" =>
        risk_context_values(link_capacity_risks, "planned_contacts"),
      "link_capacity_pressure_required_downlink_values_mb" =>
        risk_context_values(link_capacity_risks, "required_downlink_mb"),
      "link_capacity_pressure_planned_downlink_values_mb" =>
        risk_context_values(link_capacity_risks, "planned_downlink_mb"),
      "link_capacity_pressure_start_values_s" =>
        risk_context_values(link_capacity_risks, "starts_at_s"),
      "link_capacity_pressure_end_values_s" =>
        risk_context_values(link_capacity_risks, "ends_at_s"),
      "link_capacity_pressure_source_activity_ids" =>
        risk_context_values(link_capacity_risks, ["source_activity_ids"]),
      "link_capacity_pressure_source_window_ids" =>
        risk_context_values(link_capacity_risks, ["source_window_id", "source_window_ids"]),
      "link_capacity_pressure_selected_capacity_adjusted_throughput_values_mb" =>
        risk_context_values(link_capacity_risks, "selected_capacity_adjusted_throughput_mb"),
      "link_capacity_pressure_selected_downlink_shortfall_values_mb" =>
        risk_context_values(link_capacity_risks, "selected_downlink_shortfall_mb"),
      "link_capacity_pressure_actual_throughput_values_mb" =>
        risk_context_values(link_capacity_risks, "actual_throughput_mb"),
      "link_capacity_pressure_actual_downlink_completion_ratio_values" =>
        risk_context_values(link_capacity_risks, "actual_downlink_completion_ratio"),
      "link_capacity_pressure_actual_downlink_shortfall_values_mb" =>
        risk_context_values(link_capacity_risks, "actual_downlink_shortfall_mb"),
      "link_capacity_pressure_downlink_requirement_statuses" =>
        risk_context_values(link_capacity_risks, "downlink_requirement_status"),
      "link_capacity_pressure_actual_downlink_requirement_statuses" =>
        risk_context_values(link_capacity_risks, "actual_downlink_requirement_status"),
      "link_capacity_pressure_downlink_demand_sources" =>
        risk_context_values(link_capacity_risks, ["downlink_demand_sources"]),
      "link_capacity_pressure_downlink_completion_sources" =>
        risk_context_values(link_capacity_risks, ["downlink_completion_sources"]),
      "link_capacity_pressure_feedback_sources" =>
        risk_context_values(link_capacity_risks, "feedback_source"),
      "link_capacity_pressure_feedback_scopes" =>
        risk_context_values(link_capacity_risks, "feedback_scope"),
      "link_capacity_pressure_trust_boundaries" =>
        risk_context_values(link_capacity_risks, "trust_boundary"),
      "link_capacity_pressure_derivation_reasons" =>
        risk_context_values(link_capacity_risks, ["derivation_reasons"])
    }
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def context(_risks), do: %{}

  defp risk?(%{"type" => "downlink_completion_gap", "feedback_scope" => scope})
       when scope == "link_capacity",
       do: true

  defp risk?(%{"risk_type" => "downlink_completion_gap", "feedback_scope" => scope})
       when scope == "link_capacity",
       do: true

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
