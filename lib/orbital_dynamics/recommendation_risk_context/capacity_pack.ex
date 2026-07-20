defmodule OrbitalDynamics.RecommendationRiskContext.CapacityPack do
  @moduledoc false

  @context_keys [
    "capacity_pack_risk_contact_ids",
    "capacity_pack_risk_source_activity_ids",
    "capacity_pack_risk_ground_station_ids",
    "capacity_pack_risk_group_ids",
    "capacity_pack_risk_statuses",
    "capacity_pack_risk_capacity_fraction_values",
    "capacity_pack_risk_used_fraction_values",
    "capacity_pack_risk_unused_fraction_values",
    "capacity_pack_risk_required_capacity_fraction_values",
    "capacity_pack_risk_required_capacity_fraction_sources",
    "capacity_pack_risk_derivation_reasons",
    "capacity_pack_risk_feedback_sources",
    "capacity_pack_risk_feedback_scopes",
    "capacity_pack_risk_trust_boundaries"
  ]

  def context_keys, do: @context_keys

  def context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)

    capacity_pack_risks =
      Enum.filter(
        risks,
        &(Map.get(&1, "feedback_scope") == "contact_contention_resolution" or
            Map.has_key?(&1, "capacity_pack_group_id"))
      )

    %{
      "capacity_pack_risk_contact_ids" => risk_context_values(capacity_pack_risks, "contact_id"),
      "capacity_pack_risk_source_activity_ids" =>
        risk_context_values(capacity_pack_risks, ["source_activity_id", "source_activity_ids"]),
      "capacity_pack_risk_ground_station_ids" =>
        risk_context_values(capacity_pack_risks, "ground_station_id"),
      "capacity_pack_risk_group_ids" =>
        risk_context_values(capacity_pack_risks, "capacity_pack_group_id"),
      "capacity_pack_risk_statuses" =>
        risk_context_values(capacity_pack_risks, "capacity_pack_status"),
      "capacity_pack_risk_capacity_fraction_values" =>
        risk_context_values(capacity_pack_risks, "capacity_pack_capacity_fraction"),
      "capacity_pack_risk_used_fraction_values" =>
        risk_context_values(capacity_pack_risks, "capacity_pack_used_fraction"),
      "capacity_pack_risk_unused_fraction_values" =>
        risk_context_values(capacity_pack_risks, "capacity_pack_unused_fraction"),
      "capacity_pack_risk_required_capacity_fraction_values" =>
        risk_context_values(capacity_pack_risks, "required_capacity_fraction"),
      "capacity_pack_risk_required_capacity_fraction_sources" =>
        risk_context_values(capacity_pack_risks, "required_capacity_fraction_source"),
      "capacity_pack_risk_derivation_reasons" =>
        risk_context_values(capacity_pack_risks, ["derivation_reasons"]),
      "capacity_pack_risk_feedback_sources" =>
        risk_context_values(capacity_pack_risks, "feedback_source"),
      "capacity_pack_risk_feedback_scopes" =>
        risk_context_values(capacity_pack_risks, "feedback_scope"),
      "capacity_pack_risk_trust_boundaries" =>
        risk_context_values(capacity_pack_risks, "trust_boundary")
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
