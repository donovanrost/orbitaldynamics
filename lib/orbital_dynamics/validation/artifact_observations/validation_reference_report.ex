defmodule OrbitalDynamics.Validation.ArtifactObservations.ValidationReferenceReport do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    checks = map_rows(artifact, "checks")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "fixture_id" => Map.get(artifact, "fixture_id"),
      "model_id" => Map.get(artifact, "model_id"),
      "validation_level" => Map.get(artifact, "validation_level"),
      "status" => Map.get(artifact, "status"),
      "status_counts" => Map.get(artifact, "status_counts") || %{},
      "check_count" => length(checks),
      "pass_check_count" => Enum.count(checks, &(Map.get(&1, "status") == "pass")),
      "fail_check_count" => Enum.count(checks, &(Map.get(&1, "status") == "fail")),
      "check_field_order" =>
        checks
        |> Enum.map(&Map.get(&1, "field"))
        |> Enum.reject(&is_nil/1)
        |> Enum.join("|")
    }
  end

  defp map_rows(map, key) do
    case Map.get(map, key) do
      rows when is_list(rows) -> Enum.filter(rows, &is_map/1)
      _rows -> []
    end
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {to_string(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: value
end
