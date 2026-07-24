defmodule OrbitalDynamics.RecommendationRiskContext.ResourceProjection do
  @moduledoc false

  @context_keys [
    "resource_projection_pressure_risk_types",
    "resource_projection_pressure_scenario_ids",
    "resource_projection_pressure_spacecraft_ids",
    "resource_projection_pressure_ground_station_ids",
    "resource_projection_pressure_resource_fields",
    "resource_projection_pressure_source_activity_ids",
    "resource_projection_pressure_required_contact_values",
    "resource_projection_pressure_planned_contact_values",
    "resource_projection_pressure_required_downlink_values_mb",
    "resource_projection_pressure_planned_downlink_values_mb",
    "resource_projection_pressure_start_values_s",
    "resource_projection_pressure_end_values_s",
    "resource_projection_pressure_downlink_demand_sources",
    "resource_projection_pressure_downlink_completion_sources",
    "resource_projection_pressure_available_values",
    "resource_projection_pressure_degraded_values",
    "resource_projection_pressure_payload_available_values",
    "resource_projection_pressure_spacecraft_available_values",
    "resource_projection_pressure_antenna_available_values",
    "resource_projection_pressure_modes",
    "resource_projection_pressure_incompatible_activity_types",
    "resource_projection_pressure_storage_margin_values",
    "resource_projection_pressure_storage_margin_threshold_values",
    "resource_projection_pressure_projected_storage_overflow_values_mb",
    "resource_projection_pressure_downlink_margin_values",
    "resource_projection_pressure_downlink_margin_threshold_values",
    "resource_projection_pressure_projected_downlink_shortfall_values_mb",
    "resource_projection_pressure_power_margin_values",
    "resource_projection_pressure_power_margin_threshold_values",
    "resource_projection_pressure_projected_battery_overuse_values_wh",
    "resource_projection_pressure_thermal_margin_values_c",
    "resource_projection_pressure_thermal_margin_threshold_values_c",
    "resource_projection_pressure_source_quality_values",
    "resource_projection_pressure_feedback_sources",
    "resource_projection_pressure_feedback_scopes",
    "resource_projection_pressure_trust_boundaries",
    "resource_projection_pressure_derivation_reasons"
  ]

  def context_keys, do: @context_keys

  def context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)

    resource_projection_risks =
      Enum.filter(risks, &resource_projection_risk?/1)

    %{
      "resource_projection_pressure_risk_types" =>
        risk_context_values(resource_projection_risks, ["type", "risk_type"]),
      "resource_projection_pressure_scenario_ids" =>
        risk_context_values(resource_projection_risks, "scenario_id"),
      "resource_projection_pressure_spacecraft_ids" =>
        risk_context_values(resource_projection_risks, "spacecraft_id"),
      "resource_projection_pressure_ground_station_ids" =>
        risk_context_values(resource_projection_risks, "ground_station_id"),
      "resource_projection_pressure_resource_fields" =>
        risk_context_values(resource_projection_risks, "resource_field"),
      "resource_projection_pressure_source_activity_ids" =>
        risk_context_values(resource_projection_risks, [
          "source_activity_id",
          "source_activity_ids"
        ]),
      "resource_projection_pressure_required_contact_values" =>
        risk_context_values(resource_projection_risks, "required_contacts"),
      "resource_projection_pressure_planned_contact_values" =>
        risk_context_values(resource_projection_risks, "planned_contacts"),
      "resource_projection_pressure_required_downlink_values_mb" =>
        risk_context_values(resource_projection_risks, "required_downlink_mb"),
      "resource_projection_pressure_planned_downlink_values_mb" =>
        risk_context_values(resource_projection_risks, "planned_downlink_mb"),
      "resource_projection_pressure_start_values_s" =>
        risk_context_values(resource_projection_risks, "starts_at_s"),
      "resource_projection_pressure_end_values_s" =>
        risk_context_values(resource_projection_risks, "ends_at_s"),
      "resource_projection_pressure_downlink_demand_sources" =>
        risk_context_values(resource_projection_risks, ["downlink_demand_sources"]),
      "resource_projection_pressure_downlink_completion_sources" =>
        risk_context_values(resource_projection_risks, ["downlink_completion_sources"]),
      "resource_projection_pressure_available_values" =>
        risk_context_values(resource_projection_risks, [
          "available",
          "resource_availability_value"
        ]),
      "resource_projection_pressure_degraded_values" =>
        risk_context_values(resource_projection_risks, "degraded"),
      "resource_projection_pressure_payload_available_values" =>
        risk_context_values(resource_projection_risks, "payload_available"),
      "resource_projection_pressure_spacecraft_available_values" =>
        risk_context_values(resource_projection_risks, "spacecraft_available"),
      "resource_projection_pressure_antenna_available_values" =>
        risk_context_values(resource_projection_risks, "antenna_available"),
      "resource_projection_pressure_modes" =>
        risk_context_values(resource_projection_risks, "mode"),
      "resource_projection_pressure_incompatible_activity_types" =>
        risk_context_values(resource_projection_risks, ["incompatible_activity_types"]),
      "resource_projection_pressure_storage_margin_values" =>
        margin_context_values(resource_projection_risks, "storage_margin", :value),
      "resource_projection_pressure_storage_margin_threshold_values" =>
        margin_context_values(resource_projection_risks, "storage_margin", :threshold),
      "resource_projection_pressure_projected_storage_overflow_values_mb" =>
        risk_context_values(resource_projection_risks, "projected_storage_overflow_mb"),
      "resource_projection_pressure_downlink_margin_values" =>
        margin_context_values(resource_projection_risks, "downlink_margin", :value),
      "resource_projection_pressure_downlink_margin_threshold_values" =>
        margin_context_values(resource_projection_risks, "downlink_margin", :threshold),
      "resource_projection_pressure_projected_downlink_shortfall_values_mb" =>
        risk_context_values(resource_projection_risks, "projected_downlink_shortfall_mb"),
      "resource_projection_pressure_power_margin_values" =>
        margin_context_values(resource_projection_risks, "power_margin", :value),
      "resource_projection_pressure_power_margin_threshold_values" =>
        margin_context_values(resource_projection_risks, "power_margin", :threshold),
      "resource_projection_pressure_projected_battery_overuse_values_wh" =>
        risk_context_values(resource_projection_risks, "projected_battery_overuse_wh"),
      "resource_projection_pressure_thermal_margin_values_c" =>
        margin_context_values(resource_projection_risks, "thermal_margin_c", :value),
      "resource_projection_pressure_thermal_margin_threshold_values_c" =>
        margin_context_values(resource_projection_risks, "thermal_margin_c", :threshold),
      "resource_projection_pressure_source_quality_values" =>
        risk_context_values(resource_projection_risks, "source_quality"),
      "resource_projection_pressure_feedback_sources" =>
        risk_context_values(resource_projection_risks, "feedback_source"),
      "resource_projection_pressure_feedback_scopes" =>
        risk_context_values(resource_projection_risks, "feedback_scope"),
      "resource_projection_pressure_trust_boundaries" =>
        risk_context_values(resource_projection_risks, "trust_boundary"),
      "resource_projection_pressure_derivation_reasons" =>
        risk_context_values(resource_projection_risks, ["derivation_reasons"])
    }
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def context(_risks), do: %{}

  defp resource_projection_risk?(%{"feedback_scope" => "resource_projection"}), do: true
  defp resource_projection_risk?(_risk), do: false

  defp margin_context_values(risks, field, value_kind) do
    field_key = if value_kind == :value, do: field, else: "#{field}_threshold"

    normalized_key =
      if value_kind == :value,
        do: "resource_margin_value",
        else: "resource_margin_threshold"

    risks
    |> Enum.filter(&(Map.get(&1, "resource_field") == field))
    |> Enum.map(&(Map.get(&1, field_key) || Map.get(&1, normalized_key)))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

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
