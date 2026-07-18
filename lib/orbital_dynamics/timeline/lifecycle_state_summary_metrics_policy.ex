defmodule OrbitalDynamics.Timeline.LifecycleStateSummaryMetricsPolicy do
  @moduledoc false

  def duplicate_match_count(matches) when length(matches) > 1, do: length(matches)
  def duplicate_match_count(_matches), do: 0

  def lifecycle_state_match_activity_ids(matches, sorted_uniq) do
    matches
    |> Enum.map(&(Map.get(&1, "id") || Map.get(&1, "activity_id")))
    |> sorted_uniq.()
  end

  def lifecycle_state_operator_action_reason_counts(rows, list_value, sort_count_map) do
    rows
    |> Enum.flat_map(&list_value.(&1, "operator_action_reasons"))
    |> Enum.frequencies()
    |> sort_count_map.()
  end

  def lifecycle_state_timeline_ids(rows, predicate, sorted_uniq) do
    rows
    |> Enum.filter(predicate)
    |> Enum.map(& &1["timeline_id"])
    |> sorted_uniq.()
  end

  def lifecycle_state_activity_ids(rows, list_value, sorted_uniq) do
    rows
    |> Enum.flat_map(fn row ->
      [
        row["activity_id"],
        row["planned_activity_id"],
        row["realized_activity_id"]
        | list_value.(row, "planned_activity_ids") ++
            list_value.(row, "realized_activity_ids")
      ]
    end)
    |> sorted_uniq.()
  end
end
