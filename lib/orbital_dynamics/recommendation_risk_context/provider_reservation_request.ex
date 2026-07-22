defmodule OrbitalDynamics.RecommendationRiskContext.ProviderReservationRequest do
  @moduledoc false

  @context_keys [
    "provider_reservation_request_contact_ids",
    "provider_reservation_request_source_activity_ids",
    "provider_reservation_request_ground_station_ids",
    "provider_reservation_request_directions",
    "provider_reservation_request_station_reservation_ids",
    "provider_reservation_request_station_reserved_by",
    "provider_reservation_request_station_reservation_statuses",
    "provider_reservation_request_station_reservation_expiration_statuses",
    "provider_reservation_request_station_reservation_match_statuses",
    "provider_reservation_request_statuses",
    "provider_reservation_request_row_scopes",
    "provider_reservation_request_required_operator_actions",
    "provider_reservation_request_assumption_maps",
    "provider_reservation_request_feedback_sources",
    "provider_reservation_request_feedback_scopes",
    "provider_reservation_request_trust_boundaries"
  ]

  def context_keys, do: @context_keys

  def context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)

    provider_reservation_request_risks =
      Enum.filter(
        risks,
        &(Map.get(&1, "feedback_scope") == "contact_allocation_provider_reservation_request" or
            Map.get(&1, "type") == "provider_reservation_request_review")
      )

    %{
      "provider_reservation_request_contact_ids" =>
        risk_context_values(provider_reservation_request_risks, "contact_id"),
      "provider_reservation_request_source_activity_ids" =>
        risk_context_values(provider_reservation_request_risks, [
          "source_activity_id",
          "source_activity_ids"
        ]),
      "provider_reservation_request_ground_station_ids" =>
        risk_context_values(provider_reservation_request_risks, "ground_station_id"),
      "provider_reservation_request_directions" =>
        risk_context_values(provider_reservation_request_risks, "direction"),
      "provider_reservation_request_station_reservation_ids" =>
        risk_context_values(provider_reservation_request_risks, "station_reservation_id"),
      "provider_reservation_request_station_reserved_by" =>
        risk_context_values(provider_reservation_request_risks, "station_reserved_by"),
      "provider_reservation_request_station_reservation_statuses" =>
        risk_context_values(provider_reservation_request_risks, "station_reservation_status"),
      "provider_reservation_request_station_reservation_expiration_statuses" =>
        risk_context_values(
          provider_reservation_request_risks,
          "station_reservation_expiration_status"
        ),
      "provider_reservation_request_station_reservation_match_statuses" =>
        risk_context_values(
          provider_reservation_request_risks,
          "station_reservation_match_status"
        ),
      "provider_reservation_request_statuses" =>
        risk_context_values(
          provider_reservation_request_risks,
          "provider_reservation_request_status"
        ),
      "provider_reservation_request_row_scopes" =>
        risk_context_values(provider_reservation_request_risks, "provider_reservation_row_scope"),
      "provider_reservation_request_required_operator_actions" =>
        risk_context_values(provider_reservation_request_risks, "required_operator_action"),
      "provider_reservation_request_assumption_maps" =>
        risk_context_values(provider_reservation_request_risks, "assumptions"),
      "provider_reservation_request_feedback_sources" =>
        risk_context_values(provider_reservation_request_risks, "feedback_source"),
      "provider_reservation_request_feedback_scopes" =>
        risk_context_values(provider_reservation_request_risks, "feedback_scope"),
      "provider_reservation_request_trust_boundaries" =>
        risk_context_values(provider_reservation_request_risks, "trust_boundary")
    }
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def context(_risks), do: %{}

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
