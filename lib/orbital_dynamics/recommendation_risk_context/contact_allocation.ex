defmodule OrbitalDynamics.RecommendationRiskContext.ContactAllocation do
  @moduledoc false

  @context_keys [
    "contact_allocation_pressure_risk_types",
    "contact_allocation_pressure_contact_ids",
    "contact_allocation_pressure_scenario_ids",
    "contact_allocation_pressure_spacecraft_ids",
    "contact_allocation_pressure_ground_station_ids",
    "contact_allocation_pressure_source_activity_ids",
    "contact_allocation_pressure_source_window_ids",
    "contact_allocation_pressure_required_contact_values",
    "contact_allocation_pressure_planned_contact_values",
    "contact_allocation_pressure_required_downlink_values_mb",
    "contact_allocation_pressure_planned_downlink_values_mb",
    "contact_allocation_pressure_start_values_s",
    "contact_allocation_pressure_end_values_s",
    "contact_allocation_pressure_realized_statuses",
    "contact_allocation_pressure_contact_results",
    "contact_allocation_pressure_allocation_statuses",
    "contact_allocation_pressure_effective_allocation_statuses",
    "contact_allocation_pressure_allocation_reasons",
    "contact_allocation_pressure_review_statuses",
    "contact_allocation_pressure_approval_statuses",
    "contact_allocation_pressure_policy_classifications",
    "contact_allocation_pressure_policy_bundle_ids",
    "contact_allocation_pressure_station_reservation_ids",
    "contact_allocation_pressure_station_reserved_by",
    "contact_allocation_pressure_station_reservation_statuses",
    "contact_allocation_pressure_station_reservation_match_statuses",
    "contact_allocation_pressure_station_calendar_entry_ids",
    "contact_allocation_pressure_station_calendar_entry_statuses",
    "contact_allocation_pressure_station_calendar_directions",
    "contact_allocation_pressure_downlink_demand_sources",
    "contact_allocation_pressure_downlink_completion_sources",
    "contact_allocation_pressure_feedback_sources",
    "contact_allocation_pressure_feedback_scopes",
    "contact_allocation_pressure_trust_boundaries",
    "contact_allocation_pressure_derivation_reasons"
  ]

  def context_keys, do: @context_keys

  def context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)
    contact_allocation_risks = Enum.filter(risks, &contact_allocation_risk?/1)

    %{
      "contact_allocation_pressure_risk_types" =>
        risk_context_values(contact_allocation_risks, ["type", "risk_type"]),
      "contact_allocation_pressure_contact_ids" =>
        risk_context_values(contact_allocation_risks, "contact_id"),
      "contact_allocation_pressure_scenario_ids" =>
        risk_context_values(contact_allocation_risks, "scenario_id"),
      "contact_allocation_pressure_spacecraft_ids" =>
        risk_context_values(contact_allocation_risks, "spacecraft_id"),
      "contact_allocation_pressure_ground_station_ids" =>
        risk_context_values(contact_allocation_risks, "ground_station_id"),
      "contact_allocation_pressure_source_activity_ids" =>
        risk_context_values(contact_allocation_risks, [
          "source_activity_id",
          "source_activity_ids"
        ]),
      "contact_allocation_pressure_source_window_ids" =>
        risk_context_values(contact_allocation_risks, "source_window_id"),
      "contact_allocation_pressure_required_contact_values" =>
        risk_context_values(contact_allocation_risks, "required_contacts"),
      "contact_allocation_pressure_planned_contact_values" =>
        risk_context_values(contact_allocation_risks, "planned_contacts"),
      "contact_allocation_pressure_required_downlink_values_mb" =>
        risk_context_values(contact_allocation_risks, "required_downlink_mb"),
      "contact_allocation_pressure_planned_downlink_values_mb" =>
        risk_context_values(contact_allocation_risks, "planned_downlink_mb"),
      "contact_allocation_pressure_start_values_s" =>
        risk_context_values(contact_allocation_risks, "starts_at_s"),
      "contact_allocation_pressure_end_values_s" =>
        risk_context_values(contact_allocation_risks, "ends_at_s"),
      "contact_allocation_pressure_realized_statuses" =>
        risk_context_values(contact_allocation_risks, "realized_status"),
      "contact_allocation_pressure_contact_results" =>
        risk_context_values(contact_allocation_risks, "contact_result"),
      "contact_allocation_pressure_allocation_statuses" =>
        risk_context_values(contact_allocation_risks, "allocation_status"),
      "contact_allocation_pressure_effective_allocation_statuses" =>
        risk_context_values(contact_allocation_risks, "effective_allocation_status"),
      "contact_allocation_pressure_allocation_reasons" =>
        risk_context_values(contact_allocation_risks, "allocation_reason"),
      "contact_allocation_pressure_review_statuses" =>
        risk_context_values(contact_allocation_risks, "review_status"),
      "contact_allocation_pressure_approval_statuses" =>
        risk_context_values(contact_allocation_risks, "approval_status"),
      "contact_allocation_pressure_policy_classifications" =>
        risk_context_values(contact_allocation_risks, "policy_classification"),
      "contact_allocation_pressure_policy_bundle_ids" =>
        risk_context_values(contact_allocation_risks, "policy_bundle_id"),
      "contact_allocation_pressure_station_reservation_ids" =>
        risk_context_values(contact_allocation_risks, "station_reservation_id"),
      "contact_allocation_pressure_station_reserved_by" =>
        risk_context_values(contact_allocation_risks, "station_reserved_by"),
      "contact_allocation_pressure_station_reservation_statuses" =>
        risk_context_values(contact_allocation_risks, "station_reservation_status"),
      "contact_allocation_pressure_station_reservation_match_statuses" =>
        risk_context_values(contact_allocation_risks, "station_reservation_match_status"),
      "contact_allocation_pressure_station_calendar_entry_ids" =>
        risk_context_values(contact_allocation_risks, "station_calendar_entry_id"),
      "contact_allocation_pressure_station_calendar_entry_statuses" =>
        risk_context_values(contact_allocation_risks, "station_calendar_entry_status"),
      "contact_allocation_pressure_station_calendar_directions" =>
        risk_context_values(contact_allocation_risks, ["station_calendar_directions"]),
      "contact_allocation_pressure_downlink_demand_sources" =>
        risk_context_values(contact_allocation_risks, ["downlink_demand_sources"]),
      "contact_allocation_pressure_downlink_completion_sources" =>
        risk_context_values(contact_allocation_risks, ["downlink_completion_sources"]),
      "contact_allocation_pressure_feedback_sources" =>
        risk_context_values(contact_allocation_risks, "feedback_source"),
      "contact_allocation_pressure_feedback_scopes" =>
        risk_context_values(contact_allocation_risks, "feedback_scope"),
      "contact_allocation_pressure_trust_boundaries" =>
        risk_context_values(contact_allocation_risks, "trust_boundary"),
      "contact_allocation_pressure_derivation_reasons" =>
        risk_context_values(contact_allocation_risks, ["derivation_reasons"])
    }
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def context(_risks), do: %{}

  defp contact_allocation_risk?(%{"feedback_scope" => "contact_allocation"}), do: true
  defp contact_allocation_risk?(_risk), do: false

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
