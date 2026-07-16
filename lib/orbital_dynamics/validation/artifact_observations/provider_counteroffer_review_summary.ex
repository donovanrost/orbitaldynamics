defmodule OrbitalDynamics.Validation.ArtifactObservations.ProviderCounterofferReviewSummary do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    rows = map_rows(artifact, "rows")
    review_rows = map_rows(artifact, "review_rows")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "source" => Map.get(artifact, "source"),
      "source_artifact_id" => Map.get(artifact, "source_artifact_id"),
      "source_artifact_type" => Map.get(artifact, "source_artifact_type"),
      "source_counteroffer_artifact_type" =>
        Map.get(artifact, "source_counteroffer_artifact_type"),
      "counteroffer_count" => Map.get(artifact, "counteroffer_count"),
      "reviewable_count" => Map.get(artifact, "reviewable_count"),
      "row_derived_reviewable_count" => Enum.count(rows, &(&1["reviewable"] == true)),
      "counteroffer_review_status" => Map.get(artifact, "counteroffer_review_status"),
      "counteroffer_status_counts" => Map.get(artifact, "counteroffer_status_counts"),
      "counteroffer_negotiation_state_counts" =>
        Map.get(artifact, "counteroffer_negotiation_state_counts"),
      "counteroffer_lock_deadline_count" => Map.get(artifact, "counteroffer_lock_deadline_count"),
      "earliest_counteroffer_lock_deadline_s" =>
        Map.get(artifact, "earliest_counteroffer_lock_deadline_s"),
      "counteroffer_lock_deadline_status_counts" =>
        Map.get(artifact, "counteroffer_lock_deadline_status_counts"),
      "row_derived_counteroffer_lock_deadline_status_counts" =>
        count_rows_by_value(rows, "provider_counteroffer_lock_deadline_status"),
      "counteroffer_ids_by_lock_deadline_status" =>
        Map.get(artifact, "counteroffer_ids_by_lock_deadline_status"),
      "row_derived_counteroffer_ids_by_lock_deadline_status" =>
        rows
        |> group_row_ids_by_value(
          "provider_counteroffer_lock_deadline_status",
          "provider_counteroffer_id"
        )
        |> sort_grouped_values(),
      "expired_counteroffer_lock_deadline_count" =>
        Map.get(artifact, "expired_counteroffer_lock_deadline_count"),
      "active_counteroffer_lock_deadline_count" =>
        Map.get(artifact, "active_counteroffer_lock_deadline_count"),
      "missing_counteroffer_lock_deadline_count" =>
        Map.get(artifact, "missing_counteroffer_lock_deadline_count"),
      "review_counteroffer_ids" =>
        artifact
        |> list_values("review_counteroffer_ids")
        |> Enum.join("|"),
      "row_derived_review_counteroffer_ids" =>
        review_rows
        |> Enum.map(&Map.get(&1, "provider_counteroffer_id"))
        |> Enum.reject(&is_nil/1)
        |> Enum.join("|"),
      "row_count" => length(rows),
      "review_row_count" => length(review_rows),
      "execution_boundary" => get_in(artifact, ["assumptions", "execution_boundary"]),
      "operator_authority" => get_in(artifact, ["assumptions", "operator_authority"]),
      "deadline_evaluation" => get_in(artifact, ["assumptions", "deadline_evaluation"]),
      "now_s" => get_in(artifact, ["assumptions", "now_s"]),
      "assumption_source" => get_in(artifact, ["assumptions", "source"])
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

  defp sort_grouped_values(grouped_values) do
    Map.new(grouped_values, fn {key, values} -> {key, Enum.sort(values)} end)
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
