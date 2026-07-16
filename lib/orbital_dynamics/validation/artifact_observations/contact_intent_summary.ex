defmodule OrbitalDynamics.Validation.ArtifactObservations.ContactIntentSummary do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    model_limits = list_values(artifact, "model_limits")
    direction_routing = Map.get(artifact, "direction_routing") || %{}
    source_counts = Map.get(artifact, "required_capacity_fraction_source_counts") || %{}

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "source_artifact_type" => Map.get(artifact, "source_artifact_type"),
      "contact_intent_count" => Map.get(artifact, "contact_intent_count"),
      "capacity_pack_required_contact_count" =>
        Map.get(artifact, "capacity_pack_required_contact_count"),
      "capacity_pack_required_capacity_fraction" =>
        Map.get(artifact, "capacity_pack_required_capacity_fraction"),
      "capacity_pack_required_capacity_fraction_by_ground_station_id" =>
        Map.get(artifact, "capacity_pack_required_capacity_fraction_by_ground_station_id") ||
          %{},
      "capacity_pack_required_capacity_fraction_by_direction" =>
        Map.get(artifact, "capacity_pack_required_capacity_fraction_by_direction") || %{},
      "direction_counts" => Map.get(artifact, "direction_counts") || %{},
      "direction_keys" =>
        artifact
        |> list_values("directions")
        |> Enum.join("|"),
      "ground_station_keys" =>
        artifact
        |> list_values("ground_station_ids")
        |> Enum.join("|"),
      "contact_ids_by_ground_station_id" =>
        Map.get(artifact, "contact_ids_by_ground_station_id") || %{},
      "contact_ids_by_direction" => Map.get(artifact, "contact_ids_by_direction") || %{},
      "capacity_pack_contact_ids_by_direction" =>
        Map.get(artifact, "capacity_pack_contact_ids_by_direction") || %{},
      "required_capacity_fraction_source_counts" => source_counts,
      "required_capacity_fraction_source_keys" =>
        source_counts
        |> Map.keys()
        |> Enum.sort()
        |> Enum.join("|"),
      "direction_routing_count" => map_size(direction_routing),
      "model_limit_count" => length(model_limits),
      "execution_boundary" => get_in(artifact, ["assumptions", "execution_boundary"]),
      "assumption_source_artifact_type" =>
        get_in(artifact, ["assumptions", "source_artifact_type"]),
      "no_provider_reservation" => "no_provider_reservation" in model_limits,
      "no_schedule_mutation" => "no_schedule_mutation" in model_limits,
      "no_command_execution" => "no_command_execution" in model_limits
    }
  end

  defp list_values(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> values
      _values -> []
    end
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {to_string(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: value
end
