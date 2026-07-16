defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.DirectionReport.Rows.SummaryValues.GroupedIds do
  @moduledoc false

  def grouped_source_report_ids(pairs) do
    pairs
    |> Enum.reject(fn {key, value} -> key in [nil, ""] or value in [nil, ""] end)
    |> Enum.group_by(fn {key, _value} -> to_string(key) end, fn {_key, value} -> value end)
    |> Map.new(fn {key, values} -> {key, sorted_non_empty_values(values)} end)
    |> non_empty_map()
  end

  def grouped_source_report_id_counts(pairs) do
    pairs
    |> grouped_source_report_ids()
    |> case do
      nil -> nil
      ids_by_key -> Map.new(ids_by_key, fn {key, ids} -> {key, length(ids)} end)
    end
  end

  def non_empty_map(map) when map_size(map) == 0, do: nil
  def non_empty_map(map), do: map

  defp sorted_non_empty_values(values) do
    values
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      values -> values
    end
  end
end
