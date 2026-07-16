defmodule OrbitalDynamics.Validation.ArtifactObservations.ProviderCounterofferPlanImpactSummary do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    rows = map_rows(artifact, "impact_rows")

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
      "plan_impact_status" => Map.get(artifact, "plan_impact_status"),
      "timing_shift_counteroffer_count" => Map.get(artifact, "timing_shift_counteroffer_count"),
      "row_derived_timing_shift_counteroffer_count" => counteroffer_timing_shift_count(rows),
      "counteroffer_cost_delta_count" => Map.get(artifact, "counteroffer_cost_delta_count"),
      "row_derived_counteroffer_cost_delta_count" =>
        numeric_value_count(rows, "provider_counteroffer_cost_delta"),
      "counteroffer_cost_delta_total" => Map.get(artifact, "counteroffer_cost_delta_total"),
      "row_derived_counteroffer_cost_delta_total" =>
        sum_numeric(rows, "provider_counteroffer_cost_delta"),
      "counteroffer_lock_deadline_status_counts" =>
        Map.get(artifact, "counteroffer_lock_deadline_status_counts"),
      "row_derived_counteroffer_lock_deadline_status_counts" =>
        count_rows_by_value(rows, "provider_counteroffer_lock_deadline_status"),
      "affected_station_calendar_entry_ids" =>
        artifact
        |> list_values("affected_station_calendar_entry_ids")
        |> Enum.join("|"),
      "affected_provider_entry_ids" =>
        artifact
        |> list_values("affected_provider_entry_ids")
        |> Enum.join("|"),
      "impact_counteroffer_ids" =>
        artifact
        |> list_values("impact_counteroffer_ids")
        |> Enum.join("|"),
      "timing_shift_counteroffer_ids" =>
        artifact
        |> list_values("timing_shift_counteroffer_ids")
        |> Enum.join("|"),
      "cost_delta_counteroffer_ids" =>
        artifact
        |> list_values("cost_delta_counteroffer_ids")
        |> Enum.join("|"),
      "counteroffer_ids_by_lock_deadline_status" =>
        Map.get(artifact, "counteroffer_ids_by_lock_deadline_status"),
      "row_derived_counteroffer_ids_by_lock_deadline_status" =>
        rows
        |> group_row_ids_by_value(
          "provider_counteroffer_lock_deadline_status",
          "provider_counteroffer_id"
        )
        |> sort_grouped_values(),
      "impact_row_count" => length(rows),
      "provider_counteroffer_start_delta_s" =>
        rows |> List.first(%{}) |> provider_counteroffer_start_delta_s(),
      "provider_counteroffer_end_delta_s" =>
        rows |> List.first(%{}) |> provider_counteroffer_end_delta_s(),
      "provider_counteroffer_duration_delta_s" =>
        rows |> List.first(%{}) |> Map.get("provider_counteroffer_duration_delta_s"),
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

  defp sum_numeric(rows, key) do
    rows
    |> Enum.map(&Map.get(&1, key))
    |> Enum.filter(&is_number/1)
    |> Enum.sum()
  end

  defp numeric_value_count(rows, key) do
    Enum.count(rows, &is_number(Map.get(&1, key)))
  end

  defp counteroffer_timing_shift_count(rows) when is_list(rows) do
    Enum.count(rows, fn row ->
      Enum.any?(
        [
          provider_counteroffer_start_delta_s(row),
          provider_counteroffer_end_delta_s(row)
        ],
        fn value -> is_number(value) and value != 0.0 end
      )
    end)
  end

  defp provider_counteroffer_start_delta_s(row) when is_map(row) do
    numeric_delta(row["provider_counteroffer_starts_at_s"], row["starts_at_s"])
  end

  defp provider_counteroffer_start_delta_s(_row), do: nil

  defp provider_counteroffer_end_delta_s(row) when is_map(row) do
    numeric_delta(row["provider_counteroffer_ends_at_s"], row["ends_at_s"])
  end

  defp provider_counteroffer_end_delta_s(_row), do: nil

  defp numeric_delta(left, right) when is_number(left) and is_number(right), do: left - right
  defp numeric_delta(_left, _right), do: nil

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
