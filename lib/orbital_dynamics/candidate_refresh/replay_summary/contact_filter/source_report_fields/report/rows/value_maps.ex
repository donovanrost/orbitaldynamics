defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactFilter.SourceReportFields.Report.Rows.ValueMaps do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ValueEncoding

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactFilter.SourceReportFields.Report.Rows.RowValues

  def grouped_ids(pairs) do
    pairs
    |> Enum.reject(fn {key, value} -> key in [nil, ""] or value in [nil, ""] end)
    |> Enum.group_by(fn {key, _value} -> to_string(key) end, fn {_key, value} -> value end)
    |> Map.new(fn {key, values} -> {key, sorted_string_values(values)} end)
    |> non_empty_map()
  end

  def grouped_id_counts(pairs) do
    pairs
    |> grouped_ids()
    |> case do
      nil -> nil
      ids_by_key -> Map.new(ids_by_key, fn {key, ids} -> {key, length(ids)} end)
    end
  end

  def map_value_lists(%{} = value_map) do
    value_map
    |> Enum.reduce(%{}, fn {key, values}, acc ->
      case sorted_string_values(List.wrap(values)) do
        nil -> acc
        values -> Map.put(acc, to_string(key), values)
      end
    end)
    |> non_empty_map()
  end

  def map_value_lists(_value), do: nil

  def normalize_direction_count_map(%{} = counts) do
    counts
    |> Enum.reduce(%{}, fn {direction, count}, acc ->
      case {RowValues.normalize_direction(direction), numeric_value(count)} do
        {nil, _count} -> acc
        {_direction, nil} -> acc
        {direction, count} -> Map.update(acc, direction, trunc(count), &(&1 + trunc(count)))
      end
    end)
    |> non_empty_map()
  end

  def normalize_direction_count_map(_counts), do: nil

  def sorted_string_values(values) do
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

  def numeric_report_count(report, field), do: numeric_value(Map.get(report, field)) || 0

  defp numeric_value(value), do: ValueEncoding.numeric_value(value)

  defp non_empty_map(nil), do: nil
  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
