defmodule OrbitalDynamics.Validation.ArtifactObservations.TimelineActivityPreconditionSummary do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    rows = map_rows(artifact, "preconditions")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "validation_level" => Map.get(artifact, "validation_level"),
      "activity_id" => Map.get(artifact, "activity_id"),
      "timeline_id" => Map.get(artifact, "timeline_id"),
      "activity_type" => Map.get(artifact, "activity_type"),
      "precondition_status" => Map.get(artifact, "precondition_status"),
      "blocked_precondition_count" => Map.get(artifact, "blocked_precondition_count"),
      "review_precondition_count" => Map.get(artifact, "review_precondition_count"),
      "blocked_precondition_type_keys" =>
        artifact
        |> list_values("blocked_precondition_types")
        |> Enum.join("|"),
      "review_precondition_type_keys" =>
        artifact
        |> list_values("review_precondition_types")
        |> Enum.join("|"),
      "precondition_count" => length(rows),
      "row_derived_precondition_status_counts" => count_rows_by_value(rows, "status"),
      "row_derived_precondition_type_counts" => count_rows_by_value(rows, "type"),
      "timeline_identity_activity_id" => get_in(artifact, ["timeline_identity", "activity_id"]),
      "timeline_identity_timeline_id" => get_in(artifact, ["timeline_identity", "timeline_id"]),
      "execution_boundary" => get_in(artifact, ["assumptions", "execution_boundary"]),
      "operator_authority" => get_in(artifact, ["assumptions", "operator_authority"]),
      "resource_authority" => get_in(artifact, ["assumptions", "resource_authority"])
    }
  end

  defp map_rows(map, key) do
    case Map.get(map, key) do
      rows when is_list(rows) -> Enum.filter(rows, &is_map/1)
      _rows -> []
    end
  end

  defp list_values(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> values
      _values -> []
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
