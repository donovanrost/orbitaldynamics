defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineActivityPrecondition.SourceReportFields.Flattened.Values do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ValueEncoding

  def merge_count_maps(count_maps) do
    count_maps
    |> Enum.reject(&(&1 in [nil, %{}]))
    |> Enum.reduce(%{}, fn count_map, acc ->
      Enum.reduce(count_map, acc, fn {key, value}, acc ->
        Map.update(acc, key, value, fn
          current when is_integer(current) and is_integer(value) -> current + value
          current -> current
        end)
      end)
    end)
    |> non_empty_map()
  end

  def merge_string_lists(lists) do
    lists
    |> Enum.flat_map(&list_value/1)
    |> sorted_non_empty_values()
  end

  def numeric_report_count(report, field), do: numeric_value(Map.get(report, field)) || 0

  def report_count(value) do
    case numeric_value(value) do
      value when is_number(value) and value > 0 -> ceil(value)
      _value -> 0
    end
  end

  defp numeric_value(value), do: ValueEncoding.numeric_value(value)

  defp sorted_non_empty_values(values) do
    values
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&to_string/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      values -> values
    end
  end

  defp list_value(values) when is_list(values), do: values
  defp list_value(nil), do: []
  defp list_value(value), do: [value]

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
