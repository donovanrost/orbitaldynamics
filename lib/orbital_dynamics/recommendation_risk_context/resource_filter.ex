defmodule OrbitalDynamics.RecommendationRiskContext.ResourceFilter do
  @moduledoc false

  @context_keys [
    "resource_filter_pressure_risk_types",
    "resource_filter_pressure_scenario_ids",
    "resource_filter_pressure_spacecraft_ids",
    "resource_filter_pressure_resource_fields",
    "resource_filter_pressure_available_values",
    "resource_filter_pressure_source_activity_ids",
    "resource_filter_pressure_start_values_s",
    "resource_filter_pressure_end_values_s",
    "resource_filter_pressure_suppressed_reasons",
    "resource_filter_pressure_source_quality_values",
    "resource_filter_pressure_resource_trust_boundary_statuses",
    "resource_filter_pressure_fuel_margin_values",
    "resource_filter_pressure_fuel_margin_threshold_values",
    "resource_filter_pressure_power_margin_values",
    "resource_filter_pressure_power_margin_threshold_values",
    "resource_filter_pressure_storage_margin_values",
    "resource_filter_pressure_storage_margin_threshold_values",
    "resource_filter_pressure_downlink_margin_values",
    "resource_filter_pressure_downlink_margin_threshold_values",
    "resource_filter_pressure_thermal_margin_values_c",
    "resource_filter_pressure_thermal_margin_threshold_values_c",
    "resource_filter_pressure_operator_training_requirement_count_values",
    "resource_filter_pressure_required_operator_roles",
    "resource_filter_pressure_feedback_sources",
    "resource_filter_pressure_feedback_scopes",
    "resource_filter_pressure_trust_boundaries",
    "resource_filter_pressure_derivation_reasons"
  ]

  def context_keys, do: @context_keys

  def context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)
    filter_risks = Enum.filter(risks, &filter_risk?/1)

    %{
      "resource_filter_pressure_risk_types" =>
        risk_context_values(filter_risks, ["type", "risk_type"]),
      "resource_filter_pressure_scenario_ids" => risk_context_values(filter_risks, "scenario_id"),
      "resource_filter_pressure_spacecraft_ids" =>
        risk_context_values(filter_risks, "spacecraft_id"),
      "resource_filter_pressure_resource_fields" =>
        risk_context_values(filter_risks, "resource_field"),
      "resource_filter_pressure_available_values" =>
        risk_context_values(filter_risks, ["available", "resource_availability_value"]),
      "resource_filter_pressure_source_activity_ids" =>
        risk_context_values(filter_risks, ["source_activity_id", "source_activity_ids"]),
      "resource_filter_pressure_start_values_s" =>
        risk_context_values(filter_risks, "starts_at_s"),
      "resource_filter_pressure_end_values_s" => risk_context_values(filter_risks, "ends_at_s"),
      "resource_filter_pressure_suppressed_reasons" =>
        risk_context_values(filter_risks, "suppressed_reason"),
      "resource_filter_pressure_source_quality_values" =>
        risk_context_values(filter_risks, "source_quality"),
      "resource_filter_pressure_resource_trust_boundary_statuses" =>
        risk_context_values(filter_risks, "resource_trust_boundary_status"),
      "resource_filter_pressure_fuel_margin_values" =>
        risk_context_values(filter_risks, "fuel_margin"),
      "resource_filter_pressure_fuel_margin_threshold_values" =>
        risk_context_values(filter_risks, "fuel_margin_threshold"),
      "resource_filter_pressure_power_margin_values" =>
        risk_context_values(filter_risks, "power_margin"),
      "resource_filter_pressure_power_margin_threshold_values" =>
        risk_context_values(filter_risks, "power_margin_threshold"),
      "resource_filter_pressure_storage_margin_values" =>
        risk_context_values(filter_risks, "storage_margin"),
      "resource_filter_pressure_storage_margin_threshold_values" =>
        risk_context_values(filter_risks, "storage_margin_threshold"),
      "resource_filter_pressure_downlink_margin_values" =>
        risk_context_values(filter_risks, "downlink_margin"),
      "resource_filter_pressure_downlink_margin_threshold_values" =>
        risk_context_values(filter_risks, "downlink_margin_threshold"),
      "resource_filter_pressure_thermal_margin_values_c" =>
        risk_context_values(filter_risks, "thermal_margin_c"),
      "resource_filter_pressure_thermal_margin_threshold_values_c" =>
        risk_context_values(filter_risks, "thermal_margin_c_threshold"),
      "resource_filter_pressure_operator_training_requirement_count_values" =>
        risk_context_values(filter_risks, "operator_training_requirement_count"),
      "resource_filter_pressure_required_operator_roles" =>
        risk_context_values(filter_risks, ["required_operator_roles"]),
      "resource_filter_pressure_feedback_sources" =>
        risk_context_values(filter_risks, "feedback_source"),
      "resource_filter_pressure_feedback_scopes" =>
        risk_context_values(filter_risks, "feedback_scope"),
      "resource_filter_pressure_trust_boundaries" =>
        risk_context_values(filter_risks, "trust_boundary"),
      "resource_filter_pressure_derivation_reasons" =>
        risk_context_values(filter_risks, ["derivation_reasons"])
    }
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def context(_risks), do: %{}

  defp filter_risk?(%{"feedback_scope" => "resource_filter"}), do: true
  defp filter_risk?(_risk), do: false

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
