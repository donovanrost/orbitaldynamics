defmodule OrbitalDynamics.Validation.ArtifactObservations.ManeuverExecutionDelta do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    delta_v = list_values(artifact, "delta_v_km_s")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "activity_id" => Map.get(artifact, "activity_id"),
      "status" => Map.get(artifact, "status"),
      "epoch_s" => Map.get(artifact, "epoch_s"),
      "delta_v_component_count" => length(delta_v),
      "delta_v_y_km_s" => Enum.at(delta_v, 1),
      "delta_v_magnitude_km_s" => vector_magnitude(delta_v),
      "quality_level" => get_in(artifact, ["quality", "level"]),
      "source_system" => get_in(artifact, ["source", "system"]),
      "source_id" => get_in(artifact, ["source", "source_id"]),
      "trust_boundary" => get_in(artifact, ["provenance", "trust_boundary"])
    }
  end

  defp list_values(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> values
      _values -> []
    end
  end

  defp vector_magnitude(values) when is_list(values) do
    values
    |> Enum.filter(&is_number/1)
    |> Enum.map(&(&1 * &1))
    |> Enum.sum()
    |> :math.sqrt()
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {to_string(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: value
end
