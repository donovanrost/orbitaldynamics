defmodule OrbitalDynamics.RecommendationRiskContext.RelayDataPath do
  @moduledoc false

  @context_keys [
    "relay_data_path_risk_types",
    "relay_data_path_ground_station_ids",
    "relay_data_path_route_ids",
    "relay_data_path_source_spacecraft_ids",
    "relay_data_path_relay_spacecraft_ids",
    "relay_data_path_relay_chain_spacecraft_ids",
    "relay_data_path_relay_hop_count_values",
    "relay_data_path_ground_downlink_contact_ids",
    "relay_data_path_custody_statuses",
    "relay_data_path_latency_values_s",
    "relay_data_path_latency_limit_values_s",
    "relay_data_path_latency_statuses",
    "relay_data_path_risk_statuses",
    "relay_data_path_risk_reasons",
    "relay_data_path_product_ids",
    "relay_data_path_collection_ids",
    "relay_data_path_route_count_values",
    "relay_data_path_relay_route_count_values",
    "relay_data_path_direct_downlink_route_count_values",
    "relay_data_path_custody_status_count_maps",
    "relay_data_path_latency_status_count_maps",
    "relay_data_path_risk_status_count_maps",
    "relay_data_path_route_ids_by_custody_status",
    "relay_data_path_route_ids_by_latency_status",
    "relay_data_path_route_ids_by_risk_status",
    "relay_data_path_route_ids_by_ground_station_id",
    "relay_data_path_feedback_sources",
    "relay_data_path_feedback_scopes",
    "relay_data_path_feedback_keys",
    "relay_data_path_trust_boundaries",
    "relay_data_path_derivation_reasons",
    "relay_data_path_assumption_maps"
  ]

  def context_keys, do: @context_keys

  def context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)
    relay_data_path_risks = Enum.filter(risks, &risk?/1)

    %{
      "relay_data_path_risk_types" =>
        risk_context_values(relay_data_path_risks, ["type", "risk_type"]),
      "relay_data_path_ground_station_ids" =>
        risk_context_values(relay_data_path_risks, "ground_station_id"),
      "relay_data_path_route_ids" =>
        risk_context_values(relay_data_path_risks, ["route_id", "route_ids"]),
      "relay_data_path_source_spacecraft_ids" =>
        risk_context_values(relay_data_path_risks, [
          "source_spacecraft_id",
          "source_spacecraft_ids"
        ]),
      "relay_data_path_relay_spacecraft_ids" =>
        risk_context_values(relay_data_path_risks, ["relay_spacecraft_ids"]),
      "relay_data_path_relay_chain_spacecraft_ids" =>
        risk_context_values(relay_data_path_risks, ["relay_chain_spacecraft_ids"]),
      "relay_data_path_relay_hop_count_values" =>
        risk_context_values(relay_data_path_risks, "relay_hop_count"),
      "relay_data_path_ground_downlink_contact_ids" =>
        risk_context_values(relay_data_path_risks, [
          "ground_downlink_contact_id",
          "ground_downlink_contact_ids"
        ]),
      "relay_data_path_custody_statuses" =>
        risk_context_values(relay_data_path_risks, "custody_status"),
      "relay_data_path_latency_values_s" =>
        risk_context_values(relay_data_path_risks, "latency_s"),
      "relay_data_path_latency_limit_values_s" =>
        risk_context_values(relay_data_path_risks, "latency_limit_s"),
      "relay_data_path_latency_statuses" =>
        risk_context_values(relay_data_path_risks, "latency_status"),
      "relay_data_path_risk_statuses" =>
        risk_context_values(relay_data_path_risks, "risk_status"),
      "relay_data_path_risk_reasons" =>
        risk_context_values(relay_data_path_risks, ["risk_reasons"]),
      "relay_data_path_product_ids" =>
        risk_context_values(relay_data_path_risks, ["product_ids"]),
      "relay_data_path_collection_ids" =>
        risk_context_values(relay_data_path_risks, ["collection_ids"]),
      "relay_data_path_route_count_values" =>
        risk_context_values(relay_data_path_risks, "route_count"),
      "relay_data_path_relay_route_count_values" =>
        risk_context_values(relay_data_path_risks, "relay_route_count"),
      "relay_data_path_direct_downlink_route_count_values" =>
        risk_context_values(relay_data_path_risks, "direct_downlink_route_count"),
      "relay_data_path_custody_status_count_maps" =>
        risk_context_values(relay_data_path_risks, "custody_status_counts"),
      "relay_data_path_latency_status_count_maps" =>
        risk_context_values(relay_data_path_risks, "latency_status_counts"),
      "relay_data_path_risk_status_count_maps" =>
        risk_context_values(relay_data_path_risks, "risk_status_counts"),
      "relay_data_path_route_ids_by_custody_status" =>
        risk_context_values(relay_data_path_risks, "route_ids_by_custody_status"),
      "relay_data_path_route_ids_by_latency_status" =>
        risk_context_values(relay_data_path_risks, "route_ids_by_latency_status"),
      "relay_data_path_route_ids_by_risk_status" =>
        risk_context_values(relay_data_path_risks, "route_ids_by_risk_status"),
      "relay_data_path_route_ids_by_ground_station_id" =>
        risk_context_values(relay_data_path_risks, "route_ids_by_ground_station_id"),
      "relay_data_path_feedback_sources" =>
        risk_context_values(relay_data_path_risks, "feedback_source"),
      "relay_data_path_feedback_scopes" =>
        risk_context_values(relay_data_path_risks, "feedback_scope"),
      "relay_data_path_feedback_keys" =>
        risk_context_values(relay_data_path_risks, "feedback_key"),
      "relay_data_path_trust_boundaries" =>
        risk_context_values(relay_data_path_risks, "trust_boundary"),
      "relay_data_path_derivation_reasons" =>
        risk_context_values(relay_data_path_risks, ["derivation_reasons"]),
      "relay_data_path_assumption_maps" =>
        risk_context_values(relay_data_path_risks, "assumptions")
    }
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def context(_risks), do: %{}

  defp risk?(%{"type" => "relay_data_path_pressure"}), do: true
  defp risk?(%{"risk_type" => "relay_data_path_pressure"}), do: true
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
