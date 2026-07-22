defmodule OrbitalDynamics.RecommendationRiskContext.StationReservationConflict do
  @moduledoc false

  @context_keys [
    "station_reservation_conflict_contact_ids",
    "station_reservation_conflict_source_activity_ids",
    "station_reservation_conflict_ground_station_ids",
    "station_reservation_conflict_reservation_ids",
    "station_reservation_conflict_reserved_by",
    "station_reservation_conflict_statuses",
    "station_reservation_conflict_expiration_statuses",
    "station_reservation_conflict_match_statuses",
    "station_reservation_conflict_expires_at_values_s",
    "station_reservation_conflict_derivation_reasons",
    "station_reservation_conflict_feedback_sources",
    "station_reservation_conflict_feedback_scopes",
    "station_reservation_conflict_trust_boundaries"
  ]

  def context_keys, do: @context_keys

  def context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)

    station_reservation_conflict_risks =
      Enum.filter(
        risks,
        &(Map.get(&1, "feedback_scope") == "contact_allocation" and
            Map.has_key?(&1, "station_reservation_match_status"))
      )

    %{
      "station_reservation_conflict_contact_ids" =>
        risk_context_values(station_reservation_conflict_risks, "contact_id"),
      "station_reservation_conflict_source_activity_ids" =>
        risk_context_values(station_reservation_conflict_risks, [
          "source_activity_id",
          "source_activity_ids"
        ]),
      "station_reservation_conflict_ground_station_ids" =>
        risk_context_values(station_reservation_conflict_risks, "ground_station_id"),
      "station_reservation_conflict_reservation_ids" =>
        risk_context_values(station_reservation_conflict_risks, "station_reservation_id"),
      "station_reservation_conflict_reserved_by" =>
        risk_context_values(station_reservation_conflict_risks, "station_reserved_by"),
      "station_reservation_conflict_statuses" =>
        risk_context_values(station_reservation_conflict_risks, "station_reservation_status"),
      "station_reservation_conflict_expiration_statuses" =>
        risk_context_values(
          station_reservation_conflict_risks,
          "station_reservation_expiration_status"
        ),
      "station_reservation_conflict_match_statuses" =>
        risk_context_values(
          station_reservation_conflict_risks,
          "station_reservation_match_status"
        ),
      "station_reservation_conflict_expires_at_values_s" =>
        risk_context_values(
          station_reservation_conflict_risks,
          "station_reservation_expires_at_s"
        ),
      "station_reservation_conflict_derivation_reasons" =>
        risk_context_values(station_reservation_conflict_risks, ["derivation_reasons"]),
      "station_reservation_conflict_feedback_sources" =>
        risk_context_values(station_reservation_conflict_risks, "feedback_source"),
      "station_reservation_conflict_feedback_scopes" =>
        risk_context_values(station_reservation_conflict_risks, "feedback_scope"),
      "station_reservation_conflict_trust_boundaries" =>
        risk_context_values(station_reservation_conflict_risks, "trust_boundary")
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
