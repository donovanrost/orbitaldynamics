defmodule OrbitalDynamics.RecommendationRiskContext.StationReservationHoldImportReadiness do
  @moduledoc false

  @context_keys [
    "station_reservation_hold_import_statuses",
    "station_reservation_hold_expiration_statuses",
    "station_reservation_hold_import_readiness_summary_models",
    "station_reservation_hold_import_readiness_sources",
    "station_reservation_hold_import_readiness_source_artifact_types",
    "station_reservation_hold_import_readiness_statuses",
    "station_reservation_hold_import_classifications",
    "station_reservation_hold_count_values",
    "station_reservation_hold_ids",
    "station_reservation_hold_ids_by_import_status",
    "station_reservation_hold_ids_by_required_import_action",
    "station_reservation_hold_ids_by_direction",
    "station_reservation_hold_ids_by_direction_and_ground_station_id",
    "station_reservation_hold_contact_ids",
    "station_reservation_hold_contact_ids_by_import_status",
    "station_reservation_hold_contact_ids_by_expiration_status",
    "station_reservation_hold_contact_ids_by_direction",
    "station_reservation_hold_contact_ids_by_direction_and_ground_station_id",
    "station_reservation_hold_import_status_count_maps",
    "station_reservation_hold_required_import_action_count_maps",
    "station_reservation_hold_import_execution_boundaries",
    "station_reservation_hold_provider_write_values",
    "station_reservation_hold_cadence_write_values",
    "station_reservation_hold_reservation_acceptance_values",
    "station_reservation_hold_feedback_sources",
    "station_reservation_hold_feedback_scopes",
    "station_reservation_hold_trust_boundaries",
    "source_station_reservation_hold_import_readiness_summaries"
  ]

  def context_keys, do: @context_keys

  def context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)

    station_reservation_hold_risks =
      Enum.filter(
        risks,
        &(Map.has_key?(&1, "station_reservation_hold_import_status") or
            Map.has_key?(&1, "station_reservation_hold_import_readiness_status") or
            Map.has_key?(&1, "source_station_reservation_hold_import_readiness_summary"))
      )

    %{
      "station_reservation_hold_import_statuses" =>
        risk_context_values(
          station_reservation_hold_risks,
          "station_reservation_hold_import_status"
        ),
      "station_reservation_hold_expiration_statuses" =>
        risk_context_values(
          station_reservation_hold_risks,
          "station_reservation_expiration_status"
        ),
      "station_reservation_hold_import_readiness_summary_models" =>
        risk_context_values(
          station_reservation_hold_risks,
          "station_reservation_hold_import_readiness_summary_model"
        ),
      "station_reservation_hold_import_readiness_sources" =>
        risk_context_values(
          station_reservation_hold_risks,
          "station_reservation_hold_import_readiness_source"
        ),
      "station_reservation_hold_import_readiness_source_artifact_types" =>
        risk_context_values(
          station_reservation_hold_risks,
          "station_reservation_hold_import_readiness_source_artifact_type"
        ),
      "station_reservation_hold_import_readiness_statuses" =>
        risk_context_values(
          station_reservation_hold_risks,
          "station_reservation_hold_import_readiness_status"
        ),
      "station_reservation_hold_import_classifications" =>
        risk_context_values(
          station_reservation_hold_risks,
          "station_reservation_hold_import_classification"
        ),
      "station_reservation_hold_count_values" =>
        risk_context_values(station_reservation_hold_risks, "station_reservation_hold_count"),
      "station_reservation_hold_ids" =>
        risk_context_values(station_reservation_hold_risks, [
          "station_reservation_hold_ids"
        ]),
      "station_reservation_hold_ids_by_import_status" =>
        risk_context_values(
          station_reservation_hold_risks,
          "station_reservation_hold_ids_by_import_status"
        ),
      "station_reservation_hold_ids_by_required_import_action" =>
        risk_context_values(
          station_reservation_hold_risks,
          "station_reservation_hold_ids_by_required_import_action"
        ),
      "station_reservation_hold_ids_by_direction" =>
        risk_context_values(
          station_reservation_hold_risks,
          "station_reservation_hold_ids_by_direction"
        ),
      "station_reservation_hold_ids_by_direction_and_ground_station_id" =>
        risk_context_values(
          station_reservation_hold_risks,
          "station_reservation_hold_ids_by_direction_and_ground_station_id"
        ),
      "station_reservation_hold_contact_ids" =>
        risk_context_values(station_reservation_hold_risks, "contact_id"),
      "station_reservation_hold_contact_ids_by_import_status" =>
        risk_context_values(
          station_reservation_hold_risks,
          "station_reservation_hold_contact_ids_by_import_status"
        ),
      "station_reservation_hold_contact_ids_by_expiration_status" =>
        risk_context_values(
          station_reservation_hold_risks,
          "station_reservation_hold_contact_ids_by_expiration_status"
        ),
      "station_reservation_hold_contact_ids_by_direction" =>
        risk_context_values(
          station_reservation_hold_risks,
          "station_reservation_hold_contact_ids_by_direction"
        ),
      "station_reservation_hold_contact_ids_by_direction_and_ground_station_id" =>
        risk_context_values(
          station_reservation_hold_risks,
          "station_reservation_hold_contact_ids_by_direction_and_ground_station_id"
        ),
      "station_reservation_hold_import_status_count_maps" =>
        risk_context_values(
          station_reservation_hold_risks,
          "station_reservation_hold_import_status_counts"
        ),
      "station_reservation_hold_required_import_action_count_maps" =>
        risk_context_values(
          station_reservation_hold_risks,
          "station_reservation_hold_required_import_action_counts"
        ),
      "station_reservation_hold_import_execution_boundaries" =>
        risk_context_values(
          station_reservation_hold_risks,
          "station_reservation_hold_import_execution_boundary"
        ),
      "station_reservation_hold_provider_write_values" =>
        risk_context_values(
          station_reservation_hold_risks,
          "station_reservation_hold_provider_write"
        ),
      "station_reservation_hold_cadence_write_values" =>
        risk_context_values(
          station_reservation_hold_risks,
          "station_reservation_hold_cadence_write"
        ),
      "station_reservation_hold_reservation_acceptance_values" =>
        risk_context_values(
          station_reservation_hold_risks,
          "station_reservation_hold_reservation_acceptance"
        ),
      "station_reservation_hold_feedback_sources" =>
        risk_context_values(station_reservation_hold_risks, "feedback_source"),
      "station_reservation_hold_feedback_scopes" =>
        risk_context_values(station_reservation_hold_risks, "feedback_scope"),
      "station_reservation_hold_trust_boundaries" =>
        risk_context_values(station_reservation_hold_risks, "trust_boundary"),
      "source_station_reservation_hold_import_readiness_summaries" =>
        risk_context_values(
          station_reservation_hold_risks,
          "source_station_reservation_hold_import_readiness_summary"
        )
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
