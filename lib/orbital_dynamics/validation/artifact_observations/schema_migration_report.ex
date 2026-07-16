defmodule OrbitalDynamics.Validation.ArtifactObservations.SchemaMigrationReport do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    rows = map_rows(artifact, "rows")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "schema_version" => Map.get(artifact, "schema_version"),
      "model" => Map.get(artifact, "model"),
      "source" => Map.get(artifact, "source"),
      "status" => Map.get(artifact, "status"),
      "compatibility_policy_version" => Map.get(artifact, "compatibility_policy_version"),
      "compatible_change_rule_count" => Map.get(artifact, "compatible_change_rule_count"),
      "breaking_change_rule_count" => Map.get(artifact, "breaking_change_rule_count"),
      "contract_count" => Map.get(artifact, "contract_count"),
      "current_contract_count" => Map.get(artifact, "current_contract_count"),
      "deprecated_contract_count" => Map.get(artifact, "deprecated_contract_count"),
      "future_contract_count" => Map.get(artifact, "future_contract_count"),
      "migration_row_count" => Map.get(artifact, "migration_row_count"),
      "deprecation_warning_count" => Map.get(artifact, "deprecation_warning_count"),
      "row_derived_contract_count" => length(rows),
      "status_counts" => Map.get(artifact, "status_counts") || %{},
      "row_derived_status_counts" => count_rows_by_value(rows, "status"),
      "migration_action_counts" => Map.get(artifact, "migration_action_counts") || %{},
      "row_derived_migration_action_counts" => count_rows_by_value(rows, "migration_action"),
      "deprecated_contracts" =>
        rows
        |> Enum.filter(&(Map.get(&1, "status") == "deprecated"))
        |> Enum.map(&Map.get(&1, "schema_contract"))
        |> Enum.reject(&is_nil/1)
        |> Enum.sort()
        |> Enum.join("|"),
      "replacement_contracts" =>
        rows
        |> Enum.map(&Map.get(&1, "replacement_contract"))
        |> Enum.reject(&is_nil/1)
        |> Enum.sort()
        |> Enum.join("|"),
      "execution_boundary" => get_in(artifact, ["assumptions", "execution_boundary"]),
      "migration_authority" => get_in(artifact, ["assumptions", "migration_authority"]),
      "model_limit_count" => count(artifact, "model_limits")
    }
  end

  defp count(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> length(values)
      _value -> 0
    end
  end

  defp map_rows(map, key) do
    case Map.get(map, key) do
      rows when is_list(rows) -> Enum.filter(rows, &is_map/1)
      _rows -> []
    end
  end

  defp count_rows_by_value(rows, key) do
    rows
    |> Enum.map(&(Map.get(&1, key) || "unknown"))
    |> Enum.frequencies()
    |> Map.new(fn {value, count} -> {to_string(value), count} end)
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
