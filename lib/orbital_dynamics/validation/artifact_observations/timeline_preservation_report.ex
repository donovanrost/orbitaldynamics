defmodule OrbitalDynamics.Validation.ArtifactObservations.TimelinePreservationReport do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    rows = map_rows(artifact, "rows")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "source" => Map.get(artifact, "source"),
      "activity_count" => Map.get(artifact, "activity_count"),
      "row_count" => count_collection(artifact, "rows"),
      "row_derived_row_count" => length(rows),
      "mutable_activity_count" => Map.get(artifact, "mutable_activity_count"),
      "preserve_activity_count" => Map.get(artifact, "preserve_activity_count"),
      "row_derived_preserve_activity_count" =>
        count_rows_matching(rows, "protection_decision", "preserve"),
      "review_change_activity_count" => Map.get(artifact, "review_change_activity_count"),
      "row_derived_review_change_activity_count" =>
        count_rows_matching(rows, "protection_decision", "review_change"),
      "preservation_sensitive_activity_count" =>
        Map.get(artifact, "preservation_sensitive_activity_count"),
      "row_derived_preservation_sensitive_activity_count" => length(rows),
      "row_derived_invalid_activity_input_count" =>
        count_rows_matching(rows, "invalid_activity_input", true),
      "timeline_preservation_status" => Map.get(artifact, "timeline_preservation_status"),
      "protection_decision_counts" => Map.get(artifact, "protection_decision_counts"),
      "row_derived_protection_decision_counts" => row_value_counts(rows, "protection_decision"),
      "protection_category_counts" => Map.get(artifact, "protection_category_counts"),
      "row_derived_protection_category_counts" => row_value_counts(rows, "protection_category"),
      "protection_reason_counts" => Map.get(artifact, "protection_reason_counts"),
      "row_derived_protection_reason_counts" => row_value_counts(rows, "reason"),
      "preserve_activity_keys" =>
        artifact
        |> list_values("preserve_activity_ids")
        |> Enum.join("|"),
      "row_derived_preserve_activity_keys" =>
        rows
        |> joined_row_values("activity_id", &(&1["protection_decision"] == "preserve")),
      "review_change_activity_keys" =>
        artifact
        |> list_values("review_change_activity_ids")
        |> Enum.join("|"),
      "row_derived_review_change_activity_keys" =>
        rows
        |> joined_row_values("activity_id", &(&1["protection_decision"] == "review_change")),
      "mutable_activity_keys" =>
        artifact
        |> list_values("mutable_activity_ids")
        |> Enum.join("|"),
      "preservation_sensitive_activity_keys" =>
        artifact
        |> list_values("preservation_sensitive_activity_ids")
        |> Enum.join("|"),
      "row_derived_preservation_sensitive_activity_keys" =>
        joined_row_values(rows, "activity_id", fn _row -> true end),
      "preservation_sensitive_timeline_keys" =>
        artifact
        |> list_values("preservation_sensitive_timeline_ids")
        |> Enum.join("|"),
      "row_derived_preservation_sensitive_timeline_keys" =>
        joined_row_values(rows, "timeline_id", fn _row -> true end),
      "invalid_activity_input_keys" =>
        rows
        |> joined_row_values("activity_id", &(&1["invalid_activity_input"] == true)),
      "activity_id_sets_by_protection_decision" =>
        Map.get(artifact, "activity_id_sets_by_protection_decision"),
      "row_derived_activity_id_sets_by_protection_decision" =>
        rows
        |> group_row_ids_by_value("protection_decision", "activity_id")
        |> sort_grouped_values(),
      "timeline_id_sets_by_protection_decision" =>
        Map.get(artifact, "timeline_id_sets_by_protection_decision"),
      "row_derived_timeline_id_sets_by_protection_decision" =>
        rows
        |> group_row_ids_by_value("protection_decision", "timeline_id")
        |> sort_grouped_values(),
      "activity_id_sets_by_protection_category" =>
        Map.get(artifact, "activity_id_sets_by_protection_category"),
      "row_derived_activity_id_sets_by_protection_category" =>
        rows
        |> group_row_ids_by_value("protection_category", "activity_id")
        |> sort_grouped_values(),
      "timeline_id_sets_by_protection_reason" =>
        Map.get(artifact, "timeline_id_sets_by_protection_reason"),
      "row_derived_timeline_id_sets_by_protection_reason" =>
        rows
        |> group_row_ids_by_value("reason", "timeline_id")
        |> sort_grouped_values(),
      "execution_boundary" => get_in(artifact, ["assumptions", "execution_boundary"]),
      "scope" => get_in(artifact, ["assumptions", "scope"]),
      "assumption_source" => get_in(artifact, ["assumptions", "source"]),
      "model_limit_count" => count(artifact, "model_limits")
    }
  end

  defp count(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> length(values)
      _value -> 0
    end
  end

  defp count_collection(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> length(values)
      values when is_map(values) -> map_size(values)
      _value -> 0
    end
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

  defp joined_row_values(rows, key, predicate) when is_list(rows) do
    rows
    |> Enum.filter(predicate)
    |> Enum.map(&Map.get(&1, key))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> Enum.join("|")
  end

  defp row_value_counts(rows, key) when is_list(rows) do
    rows
    |> Enum.map(&Map.get(&1, key))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
    |> Map.new(fn {value, count} -> {to_string(value), count} end)
  end

  defp sort_grouped_values(grouped_values) do
    Map.new(grouped_values, fn {key, values} -> {key, Enum.sort(values)} end)
  end

  defp count_rows_matching(rows, key, value) do
    Enum.count(rows, &(Map.get(&1, key) == value))
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
