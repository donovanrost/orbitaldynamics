defmodule OrbitalDynamics.Validation.ArtifactObservations.ModelAcceptanceReport do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "intended_use" => Map.get(artifact, "intended_use"),
      "status" => Map.get(artifact, "status"),
      "model_count" => Map.get(artifact, "model_count"),
      "record_count" => count(artifact, "records"),
      "row_count" => count(artifact, "rows"),
      "accepted_count" => Map.get(artifact, "accepted_count"),
      "review_required_count" => Map.get(artifact, "review_required_count"),
      "blocked_count" => Map.get(artifact, "blocked_count"),
      "unknown_model_count" => Map.get(artifact, "unknown_model_count"),
      "status_counts" => Map.get(artifact, "status_counts") || %{},
      "validation_level_counts" => Map.get(artifact, "validation_level_counts") || %{},
      "model_ids_by_status" => Map.get(artifact, "model_ids_by_status") || %{},
      "model_ids_by_validation_level" =>
        Map.get(artifact, "model_ids_by_validation_level") || %{},
      "model_ids_by_intended_use" => Map.get(artifact, "model_ids_by_intended_use") || %{}
    }
  end

  defp count(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> length(values)
      _value -> 0
    end
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), stringify_keys(value)}
      {key, value} when is_binary(key) -> {key, stringify_keys(value)}
      {key, value} -> {key, stringify_keys(value)}
    end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)

  defp stringify_keys(value), do: value
end
