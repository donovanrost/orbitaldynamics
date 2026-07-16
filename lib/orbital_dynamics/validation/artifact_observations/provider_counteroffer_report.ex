defmodule OrbitalDynamics.Validation.ArtifactObservations.ProviderCounterofferReport do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    rows = map_rows(artifact, "rows")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "source_artifact_type" => Map.get(artifact, "source_artifact_type"),
      "counteroffer_count" => Map.get(artifact, "counteroffer_count"),
      "row_derived_counteroffer_count" => length(rows),
      "reviewable_count" => Map.get(artifact, "reviewable_count"),
      "row_derived_reviewable_count" => Enum.count(rows, &(&1["reviewable"] == true)),
      "counteroffer_cost_delta_count" => Map.get(artifact, "counteroffer_cost_delta_count"),
      "row_derived_counteroffer_cost_delta_count" =>
        numeric_value_count(rows, "provider_counteroffer_cost_delta"),
      "counteroffer_cost_delta_total" => Map.get(artifact, "counteroffer_cost_delta_total"),
      "row_derived_counteroffer_cost_delta_total" =>
        sum_numeric(rows, "provider_counteroffer_cost_delta"),
      "counteroffer_lock_deadline_count" => Map.get(artifact, "counteroffer_lock_deadline_count"),
      "row_derived_counteroffer_lock_deadline_count" =>
        numeric_value_count(rows, "provider_counteroffer_lock_deadline_s"),
      "earliest_counteroffer_lock_deadline_s" =>
        Map.get(artifact, "earliest_counteroffer_lock_deadline_s"),
      "row_derived_earliest_counteroffer_lock_deadline_s" =>
        min_numeric(rows, "provider_counteroffer_lock_deadline_s"),
      "timing_shift_counteroffer_count" => counteroffer_timing_shift_count(rows),
      "row_derived_timing_shift_counteroffer_count" => counteroffer_timing_shift_count(rows),
      "provider_counteroffer_start_delta_s" =>
        rows |> List.first(%{}) |> provider_counteroffer_start_delta_s(),
      "provider_counteroffer_end_delta_s" =>
        rows |> List.first(%{}) |> provider_counteroffer_end_delta_s(),
      "required_operator_action_count" =>
        get_in(artifact, ["required_operator_action_counts", "review_provider_counteroffer"]) || 0,
      "row_derived_required_operator_action_count" =>
        count_rows_matching(rows, "required_operator_action", "review_provider_counteroffer"),
      "provider_write_boundary" => get_in(artifact, ["assumptions", "execution_boundary"])
    }
  end

  defp map_rows(map, key) do
    case Map.get(map, key) do
      rows when is_list(rows) -> Enum.filter(rows, &is_map/1)
      _rows -> []
    end
  end

  defp count_rows_matching(rows, key, value) do
    Enum.count(rows, &(Map.get(&1, key) == value))
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

  defp min_numeric(rows, key) do
    rows
    |> Enum.map(&Map.get(&1, key))
    |> Enum.filter(&is_number/1)
    |> case do
      [] -> nil
      values -> Enum.min(values)
    end
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
