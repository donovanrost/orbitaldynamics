defmodule OrbitalDynamics.RecommendationRiskContext.ContactContention do
  @moduledoc false

  @context_keys [
    "contact_contention_pressure_risk_types",
    "contact_contention_pressure_contact_ids",
    "contact_contention_pressure_scenario_ids",
    "contact_contention_pressure_spacecraft_ids",
    "contact_contention_pressure_ground_station_ids",
    "contact_contention_pressure_source_activity_ids",
    "contact_contention_pressure_source_window_ids",
    "contact_contention_pressure_required_contact_values",
    "contact_contention_pressure_planned_contact_values",
    "contact_contention_pressure_required_downlink_values_mb",
    "contact_contention_pressure_planned_downlink_values_mb",
    "contact_contention_pressure_start_values_s",
    "contact_contention_pressure_end_values_s",
    "contact_contention_pressure_group_ids",
    "contact_contention_pressure_resource_scopes",
    "contact_contention_pressure_contention_contact_ids",
    "contact_contention_pressure_required_operator_actions",
    "contact_contention_pressure_approval_statuses",
    "contact_contention_pressure_operator_action_reasons",
    "contact_contention_pressure_downlink_demand_sources",
    "contact_contention_pressure_downlink_completion_sources",
    "contact_contention_pressure_feedback_sources",
    "contact_contention_pressure_feedback_scopes",
    "contact_contention_pressure_trust_boundaries",
    "contact_contention_pressure_derivation_reasons"
  ]

  def context_keys, do: @context_keys

  def context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)
    contact_contention_risks = Enum.filter(risks, &risk?/1)

    %{
      "contact_contention_pressure_risk_types" =>
        risk_context_values(contact_contention_risks, ["type", "risk_type"]),
      "contact_contention_pressure_contact_ids" =>
        risk_context_values(contact_contention_risks, "contact_id"),
      "contact_contention_pressure_scenario_ids" =>
        risk_context_values(contact_contention_risks, "scenario_id"),
      "contact_contention_pressure_spacecraft_ids" =>
        risk_context_values(contact_contention_risks, "spacecraft_id"),
      "contact_contention_pressure_ground_station_ids" =>
        risk_context_values(contact_contention_risks, "ground_station_id"),
      "contact_contention_pressure_source_activity_ids" =>
        risk_context_values(contact_contention_risks, [
          "source_activity_id",
          "source_activity_ids"
        ]),
      "contact_contention_pressure_source_window_ids" =>
        risk_context_values(contact_contention_risks, [
          "source_window_id",
          "source_window_ids"
        ]),
      "contact_contention_pressure_required_contact_values" =>
        risk_context_values(contact_contention_risks, "required_contacts"),
      "contact_contention_pressure_planned_contact_values" =>
        risk_context_values(contact_contention_risks, "planned_contacts"),
      "contact_contention_pressure_required_downlink_values_mb" =>
        risk_context_values(contact_contention_risks, "required_downlink_mb"),
      "contact_contention_pressure_planned_downlink_values_mb" =>
        risk_context_values(contact_contention_risks, "planned_downlink_mb"),
      "contact_contention_pressure_start_values_s" =>
        risk_context_values(contact_contention_risks, "starts_at_s"),
      "contact_contention_pressure_end_values_s" =>
        risk_context_values(contact_contention_risks, "ends_at_s"),
      "contact_contention_pressure_group_ids" =>
        risk_context_values(contact_contention_risks, "contention_group_id"),
      "contact_contention_pressure_resource_scopes" =>
        risk_context_values(contact_contention_risks, "contention_resource_scope"),
      "contact_contention_pressure_contention_contact_ids" =>
        risk_context_values(contact_contention_risks, ["contention_contact_ids"]),
      "contact_contention_pressure_required_operator_actions" =>
        risk_context_values(contact_contention_risks, "required_operator_action"),
      "contact_contention_pressure_approval_statuses" =>
        risk_context_values(contact_contention_risks, "approval_status"),
      "contact_contention_pressure_operator_action_reasons" =>
        risk_context_values(contact_contention_risks, "operator_action_reason"),
      "contact_contention_pressure_downlink_demand_sources" =>
        risk_context_values(contact_contention_risks, ["downlink_demand_sources"]),
      "contact_contention_pressure_downlink_completion_sources" =>
        risk_context_values(contact_contention_risks, ["downlink_completion_sources"]),
      "contact_contention_pressure_feedback_sources" =>
        risk_context_values(contact_contention_risks, "feedback_source"),
      "contact_contention_pressure_feedback_scopes" =>
        risk_context_values(contact_contention_risks, "feedback_scope"),
      "contact_contention_pressure_trust_boundaries" =>
        risk_context_values(contact_contention_risks, "trust_boundary"),
      "contact_contention_pressure_derivation_reasons" =>
        risk_context_values(contact_contention_risks, ["derivation_reasons"])
    }
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def context(_risks), do: %{}

  defp risk?(%{"feedback_scope" => "contact_contention"}), do: true
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
