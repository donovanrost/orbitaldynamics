defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.QualityGate.SourceReportFields.Aggregation.Values do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ValueEncoding

  def numeric_report_count(report, field), do: numeric_value(Map.get(report, field)) || 0

  def report_count(value) do
    case numeric_value(value) do
      value when is_number(value) and value > 0 -> ceil(value)
      _value -> 0
    end
  end

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

  def merge_string_list_maps(list_maps) do
    list_maps
    |> Enum.reject(&(&1 in [nil, %{}]))
    |> Enum.reduce(%{}, fn list_map, acc ->
      Enum.reduce(list_map, acc, fn {key, values}, acc ->
        values =
          values
          |> list_value()
          |> Enum.reject(&(&1 in [nil, ""]))
          |> Enum.map(&to_string/1)

        Map.update(acc, to_string(key), values, fn current ->
          (current ++ values)
          |> Enum.uniq()
        end)
      end)
    end)
    |> non_empty_map()
  end

  def merge_string_lists(values) do
    values
    |> Enum.flat_map(&List.wrap/1)
    |> sorted_string_values()
    |> case do
      [] -> nil
      values -> values
    end
  end

  def compact_map(map) when is_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  def sorted_string_values(values) do
    values
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  def list_value(values) when is_list(values), do: values
  def list_value(_values), do: []

  defp numeric_value(value), do: ValueEncoding.numeric_value(value)

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
