defmodule OrbitalDynamics.RecommendationRiskContext.ResourceMargin do
  @moduledoc false

  @context_keys [
    "resource_margin_risk_types",
    "resource_margin_spacecraft_ids",
    "resource_margin_scenario_ids",
    "resource_margin_timeline_ids",
    "resource_margin_source_activity_ids",
    "resource_margin_replacement_activity_ids",
    "resource_margin_fields",
    "resource_margin_values",
    "resource_margin_threshold_values",
    "resource_margin_field_value_maps",
    "resource_margin_source_quality_values",
    "resource_margin_start_values_s",
    "resource_margin_end_values_s",
    "resource_margin_diff_statuses",
    "resource_margin_changed_fields",
    "resource_margin_required_operator_actions",
    "resource_margin_requires_operator_review_values",
    "resource_margin_feedback_sources",
    "resource_margin_feedback_scopes",
    "resource_margin_feedback_keys",
    "resource_margin_trust_boundaries",
    "resource_margin_derivation_reasons"
  ]

  def context_keys, do: @context_keys

  def context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)
    resource_margin_risks = Enum.filter(risks, &risk?/1)

    %{
      "resource_margin_risk_types" =>
        risk_context_values(resource_margin_risks, "resource_margin_risk_type"),
      "resource_margin_spacecraft_ids" =>
        risk_context_values(resource_margin_risks, "spacecraft_id"),
      "resource_margin_scenario_ids" => risk_context_values(resource_margin_risks, "scenario_id"),
      "resource_margin_timeline_ids" => risk_context_values(resource_margin_risks, "timeline_id"),
      "resource_margin_source_activity_ids" =>
        risk_context_values(resource_margin_risks, [
          "source_activity_id",
          "source_activity_ids"
        ]),
      "resource_margin_replacement_activity_ids" =>
        risk_context_values(resource_margin_risks, "replacement_activity_id"),
      "resource_margin_fields" => risk_context_values(resource_margin_risks, "resource_field"),
      "resource_margin_values" =>
        risk_context_values(resource_margin_risks, "resource_margin_value"),
      "resource_margin_threshold_values" =>
        risk_context_values(resource_margin_risks, "resource_margin_threshold"),
      "resource_margin_field_value_maps" =>
        risk_context_values(resource_margin_risks, "resource_margin_field_value"),
      "resource_margin_source_quality_values" =>
        risk_context_values(resource_margin_risks, "source_quality"),
      "resource_margin_start_values_s" =>
        risk_context_values(resource_margin_risks, "starts_at_s"),
      "resource_margin_end_values_s" => risk_context_values(resource_margin_risks, "ends_at_s"),
      "resource_margin_diff_statuses" =>
        risk_context_values(resource_margin_risks, "diff_status"),
      "resource_margin_changed_fields" =>
        risk_context_values(resource_margin_risks, ["changed_fields"]),
      "resource_margin_required_operator_actions" =>
        risk_context_values(resource_margin_risks, "required_operator_action"),
      "resource_margin_requires_operator_review_values" =>
        risk_context_values(resource_margin_risks, "requires_operator_review"),
      "resource_margin_feedback_sources" =>
        risk_context_values(resource_margin_risks, "feedback_source"),
      "resource_margin_feedback_scopes" =>
        risk_context_values(resource_margin_risks, "feedback_scope"),
      "resource_margin_feedback_keys" =>
        risk_context_values(resource_margin_risks, "feedback_key"),
      "resource_margin_trust_boundaries" =>
        risk_context_values(resource_margin_risks, "trust_boundary"),
      "resource_margin_derivation_reasons" =>
        risk_context_values(resource_margin_risks, ["derivation_reasons"])
    }
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def context(_risks), do: %{}

  defp risk?(%{"resource_field" => field}) when is_binary(field) do
    field in [
      "fuel_margin",
      "power_margin",
      "storage_margin",
      "downlink_margin",
      "thermal_margin_c"
    ]
  end

  defp risk?(%{"type" => type}) when is_binary(type) do
    type in [
      "fuel_margin_low",
      "power_margin_low",
      "storage_margin_low",
      "downlink_margin_low",
      "thermal_margin_c_low"
    ]
  end

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
