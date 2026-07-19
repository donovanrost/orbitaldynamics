defmodule OrbitalDynamics.RecommendationRiskContext.ContactIntent do
  @moduledoc false

  @contact_intent_context_keys [
    "contact_intent_pressure_risk_types",
    "contact_intent_pressure_contact_ids",
    "contact_intent_pressure_source_activity_ids",
    "contact_intent_pressure_ground_station_ids",
    "contact_intent_pressure_required_contact_values",
    "contact_intent_pressure_planned_contact_values",
    "contact_intent_pressure_required_downlink_values_mb",
    "contact_intent_pressure_planned_downlink_values_mb",
    "contact_intent_pressure_start_values_s",
    "contact_intent_pressure_end_values_s",
    "contact_intent_pressure_source_window_ids",
    "contact_intent_pressure_timeline_ids",
    "contact_intent_pressure_approval_statuses",
    "contact_intent_pressure_required_operator_actions",
    "contact_intent_pressure_cadence_import_statuses",
    "contact_intent_pressure_invalid_cadence_import_values",
    "contact_intent_pressure_invalid_cadence_import_reasons",
    "contact_intent_pressure_invalid_activity_input_values",
    "contact_intent_pressure_invalid_activity_input_reasons",
    "contact_intent_pressure_gate_statuses",
    "contact_intent_pressure_policy_classifications",
    "contact_intent_pressure_policy_bundle_ids",
    "contact_intent_pressure_station_availabilities",
    "contact_intent_pressure_station_contention_statuses",
    "contact_intent_pressure_station_calendar_entry_ids",
    "contact_intent_pressure_station_calendar_provider_ids",
    "contact_intent_pressure_station_calendar_provider_entry_ids",
    "contact_intent_pressure_station_calendar_directions",
    "contact_intent_pressure_station_calendar_statuses",
    "contact_intent_pressure_station_calendar_trust_boundary_statuses",
    "contact_intent_pressure_station_reservation_ids",
    "contact_intent_pressure_station_reserved_by",
    "contact_intent_pressure_station_reservation_statuses",
    "contact_intent_pressure_station_reservation_match_statuses",
    "contact_intent_pressure_feedback_sources",
    "contact_intent_pressure_feedback_scopes",
    "contact_intent_pressure_trust_boundaries",
    "contact_intent_pressure_derivation_reasons"
  ]

  def context_keys, do: @contact_intent_context_keys

  def context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)

    contact_intent_risks =
      Enum.filter(risks, &contact_intent_risk?/1)

    %{
      "contact_intent_pressure_risk_types" =>
        risk_context_values(contact_intent_risks, ["type", "risk_type"]),
      "contact_intent_pressure_contact_ids" =>
        risk_context_values(contact_intent_risks, "contact_id"),
      "contact_intent_pressure_source_activity_ids" =>
        risk_context_values(contact_intent_risks, ["source_activity_id", "source_activity_ids"]),
      "contact_intent_pressure_ground_station_ids" =>
        risk_context_values(contact_intent_risks, "ground_station_id"),
      "contact_intent_pressure_required_contact_values" =>
        risk_context_values(contact_intent_risks, "required_contacts"),
      "contact_intent_pressure_planned_contact_values" =>
        risk_context_values(contact_intent_risks, "planned_contacts"),
      "contact_intent_pressure_required_downlink_values_mb" =>
        risk_context_values(contact_intent_risks, "required_downlink_mb"),
      "contact_intent_pressure_planned_downlink_values_mb" =>
        risk_context_values(contact_intent_risks, "planned_downlink_mb"),
      "contact_intent_pressure_start_values_s" =>
        risk_context_values(contact_intent_risks, "starts_at_s"),
      "contact_intent_pressure_end_values_s" =>
        risk_context_values(contact_intent_risks, "ends_at_s"),
      "contact_intent_pressure_source_window_ids" =>
        risk_context_values(contact_intent_risks, "source_window_id"),
      "contact_intent_pressure_timeline_ids" =>
        risk_context_values(contact_intent_risks, "timeline_id"),
      "contact_intent_pressure_approval_statuses" =>
        risk_context_values(contact_intent_risks, "approval_status"),
      "contact_intent_pressure_required_operator_actions" =>
        risk_context_values(contact_intent_risks, "required_operator_action"),
      "contact_intent_pressure_cadence_import_statuses" =>
        risk_context_values(contact_intent_risks, "cadence_import_status"),
      "contact_intent_pressure_invalid_cadence_import_values" =>
        risk_context_values(contact_intent_risks, "invalid_cadence_import"),
      "contact_intent_pressure_invalid_cadence_import_reasons" =>
        risk_context_values(contact_intent_risks, "invalid_cadence_import_reason"),
      "contact_intent_pressure_invalid_activity_input_values" =>
        risk_context_values(contact_intent_risks, "invalid_activity_input"),
      "contact_intent_pressure_invalid_activity_input_reasons" =>
        risk_context_values(contact_intent_risks, "invalid_activity_input_reason"),
      "contact_intent_pressure_gate_statuses" =>
        risk_context_values(contact_intent_risks, "contact_intent_gate_status"),
      "contact_intent_pressure_policy_classifications" =>
        risk_context_values(contact_intent_risks, "policy_classification"),
      "contact_intent_pressure_policy_bundle_ids" =>
        risk_context_values(contact_intent_risks, "policy_bundle_id"),
      "contact_intent_pressure_station_availabilities" =>
        risk_context_values(contact_intent_risks, "station_availability"),
      "contact_intent_pressure_station_contention_statuses" =>
        risk_context_values(contact_intent_risks, "station_contention_status"),
      "contact_intent_pressure_station_calendar_entry_ids" =>
        risk_context_values(contact_intent_risks, "station_calendar_entry_id"),
      "contact_intent_pressure_station_calendar_provider_ids" =>
        risk_context_values(contact_intent_risks, "station_calendar_provider_id"),
      "contact_intent_pressure_station_calendar_provider_entry_ids" =>
        risk_context_values(contact_intent_risks, "station_calendar_provider_entry_id"),
      "contact_intent_pressure_station_calendar_directions" =>
        risk_context_values(contact_intent_risks, ["station_calendar_directions"]),
      "contact_intent_pressure_station_calendar_statuses" =>
        risk_context_values(contact_intent_risks, "station_calendar_status"),
      "contact_intent_pressure_station_calendar_trust_boundary_statuses" =>
        risk_context_values(contact_intent_risks, "station_calendar_trust_boundary_status"),
      "contact_intent_pressure_station_reservation_ids" =>
        risk_context_values(contact_intent_risks, "station_reservation_id"),
      "contact_intent_pressure_station_reserved_by" =>
        risk_context_values(contact_intent_risks, "station_reserved_by"),
      "contact_intent_pressure_station_reservation_statuses" =>
        risk_context_values(contact_intent_risks, "station_reservation_status"),
      "contact_intent_pressure_station_reservation_match_statuses" =>
        risk_context_values(contact_intent_risks, "station_reservation_match_status"),
      "contact_intent_pressure_feedback_sources" =>
        risk_context_values(contact_intent_risks, "feedback_source"),
      "contact_intent_pressure_feedback_scopes" =>
        risk_context_values(contact_intent_risks, "feedback_scope"),
      "contact_intent_pressure_trust_boundaries" =>
        risk_context_values(contact_intent_risks, "trust_boundary"),
      "contact_intent_pressure_derivation_reasons" =>
        risk_context_values(contact_intent_risks, ["derivation_reasons"])
    }
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def context(_risks), do: %{}

  defp contact_intent_risk?(%{"type" => "downlink_completion_gap", "feedback_scope" => scope})
       when scope == "contact_intent",
       do: true

  defp contact_intent_risk?(%{
         "risk_type" => "downlink_completion_gap",
         "feedback_scope" => scope
       })
       when scope == "contact_intent",
       do: true

  defp contact_intent_risk?(_risk), do: false

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
