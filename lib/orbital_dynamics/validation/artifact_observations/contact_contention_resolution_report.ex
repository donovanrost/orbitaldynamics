defmodule OrbitalDynamics.Validation.ArtifactObservations.ContactContentionResolutionReport do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    recommendations = map_rows(artifact, "recommendations")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "conflict_group_count" => Map.get(artifact, "conflict_group_count"),
      "row_derived_conflict_group_count" => unique_value_count(recommendations, "group_id"),
      "recommendation_count" => Map.get(artifact, "recommendation_count"),
      "row_derived_recommendation_count" => length(recommendations),
      "recommendation_row_count" => length(recommendations),
      "candidate_count_total" => sum_numeric(recommendations, "candidate_count"),
      "selected_contact_count" =>
        Enum.count(recommendations, &Map.has_key?(&1, "selected_contact_id")),
      "row_derived_selected_contact_count" =>
        Enum.count(recommendations, &Map.has_key?(&1, "selected_contact_id")),
      "deferred_contact_count" =>
        recommendations
        |> Enum.map(&count(&1, "deferred_contact_ids"))
        |> Enum.sum(),
      "row_derived_deferred_contact_count" =>
        recommendations
        |> Enum.map(&count(&1, "deferred_contact_ids"))
        |> Enum.sum(),
      "review_required_recommendation_count" =>
        count_rows_by_value(recommendations, "review_status")
        |> Map.get("operator_review_required", 0),
      "row_derived_review_required_recommendation_count" =>
        count_rows_by_value(recommendations, "review_status")
        |> Map.get("operator_review_required", 0),
      "resource_scope_counts" => count_rows_by_value(recommendations, "resource_scope"),
      "action_counts" => count_rows_by_value(recommendations, "action"),
      "selection_reason_counts" => count_rows_by_value(recommendations, "selection_reason"),
      "selected_contact_ids_by_resource_scope" =>
        recommendations
        |> group_row_ids_by_value("resource_scope", "selected_contact_id")
        |> sort_grouped_values(),
      "resolution_boundary" => get_in(artifact, ["assumptions", "boundary"]),
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

  defp unique_value_count(rows, key) do
    rows
    |> Enum.map(&Map.get(&1, key))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> length()
  end

  defp group_row_ids_by_value(rows, value_key, id_key) do
    rows
    |> Enum.group_by(
      &(Map.get(&1, value_key) || "unknown"),
      &Map.get(&1, id_key)
    )
    |> Map.new(fn {value, ids} ->
      {to_string(value), Enum.reject(ids, &is_nil/1)}
    end)
  end

  defp count_rows_by_value(rows, key) do
    rows
    |> Enum.map(&(Map.get(&1, key) || "unknown"))
    |> Enum.frequencies()
    |> Map.new(fn {value, count} -> {to_string(value), count} end)
  end

  defp sort_grouped_values(grouped_values) do
    Map.new(grouped_values, fn {key, values} -> {key, Enum.sort(values)} end)
  end

  defp sum_numeric(rows, key) do
    rows
    |> Enum.map(&Map.get(&1, key))
    |> Enum.filter(&is_number/1)
    |> Enum.sum()
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
