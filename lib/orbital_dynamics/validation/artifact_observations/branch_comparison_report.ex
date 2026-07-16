defmodule OrbitalDynamics.Validation.ArtifactObservations.BranchComparisonReport do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    rows = map_rows(artifact, "rows")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "source" => Map.get(artifact, "source"),
      "branch_count" => Map.get(artifact, "branch_count"),
      "row_count" => length(rows),
      "recommended_branch_id" => Map.get(artifact, "recommended_branch_id"),
      "selected_count" => Enum.count(rows, &(Map.get(&1, "selected") == true)),
      "selected_branch_score" =>
        rows
        |> Enum.find(&(Map.get(&1, "selected") == true))
        |> then(&if(is_map(&1), do: Map.get(&1, "score"))),
      "max_rank" =>
        rows
        |> Enum.map(&Map.get(&1, "rank"))
        |> Enum.filter(&is_number/1)
        |> Enum.max(fn -> 0 end),
      "risk_count_total" => sum_numeric(rows, "risk_count"),
      "approval_requirement_count_total" => sum_numeric(rows, "approval_requirement_count"),
      "candidate_activity_count_total" => sum_numeric(rows, "candidate_activity_count"),
      "approval_status_counts" => count_rows_by_value(rows, "approval_status"),
      "selected_branch_ids_by_status" => branch_ids_by_selected_status(rows),
      "branch_ids_by_approval_status" =>
        rows
        |> group_row_ids_by_value("approval_status", "branch_id")
        |> sort_grouped_values(),
      "row_derived_branch_count" => length(rows),
      "row_derived_selected_count" => Enum.count(rows, &(Map.get(&1, "selected") == true)),
      "row_derived_risk_count_total" => sum_numeric(rows, "risk_count"),
      "row_derived_approval_requirement_count_total" =>
        sum_numeric(rows, "approval_requirement_count"),
      "row_derived_candidate_activity_count_total" =>
        sum_numeric(rows, "candidate_activity_count"),
      "row_derived_approval_status_counts" => count_rows_by_value(rows, "approval_status"),
      "row_derived_branch_ids_by_approval_status" =>
        rows
        |> group_row_ids_by_value("approval_status", "branch_id")
        |> sort_grouped_values(),
      "resource_risk_type_counts" =>
        rows
        |> Enum.flat_map(&list_values(&1, "resource_risk_types"))
        |> list_value_counts(),
      "row_derived_resource_risk_type_counts" =>
        rows
        |> Enum.flat_map(&list_values(&1, "resource_risk_types"))
        |> list_value_counts(),
      "branch_order" => get_in(artifact, ["assumptions", "branch_order"]),
      "model_limit_count" => count(artifact, "model_limits")
    }
  end

  defp branch_ids_by_selected_status(rows) do
    rows
    |> Enum.group_by(
      fn row -> if Map.get(row, "selected") == true, do: "true", else: "false" end,
      &Map.get(&1, "branch_id")
    )
    |> Map.new(fn {status, ids} ->
      {status, ids |> Enum.reject(&is_nil/1) |> Enum.sort()}
    end)
  end

  defp count(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> length(values)
      _value -> 0
    end
  end

  defp count_rows_by_value(rows, key) do
    rows
    |> Enum.map(&(Map.get(&1, key) || "unknown"))
    |> Enum.frequencies()
    |> Map.new(fn {value, count} -> {to_string(value), count} end)
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

  defp list_value_counts(values) when is_list(values) do
    values
    |> Enum.frequencies()
    |> Map.new(fn {value, count} -> {to_string(value), count} end)
  end

  defp list_value_counts(_values), do: %{}

  defp list_values(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> values
      _values -> []
    end
  end

  defp map_rows(map, key) do
    case Map.get(map, key) do
      rows when is_list(rows) -> Enum.filter(rows, &is_map/1)
      _rows -> []
    end
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
    Map.new(map, fn {key, value} -> {to_string(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: value
end
