defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.Aggregation.Values do
  @moduledoc false

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

  def merge_numeric_list_maps(list_maps) do
    list_maps
    |> Enum.reject(&(&1 in [nil, %{}]))
    |> Enum.reduce(%{}, fn list_map, acc ->
      Enum.reduce(list_map, acc, fn {key, values}, acc ->
        values =
          values
          |> List.wrap()
          |> normalize_number_list()
          |> case do
            nil -> []
            numbers -> numbers
          end

        if values == [] do
          acc
        else
          Map.update(acc, to_string(key), values, fn current ->
            (current ++ values)
            |> Enum.uniq()
            |> Enum.sort()
          end)
        end
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

  def numeric_report_count(report, field), do: numeric_value(Map.get(report, field)) || 0

  def report_count(value) do
    case numeric_value(value) do
      value when is_number(value) and value > 0 -> ceil(value)
      _value -> 0
    end
  end

  def numeric_value(value) when is_number(value), do: value * 1.0

  def numeric_value(value) when is_binary(value) do
    case Float.parse(String.trim(value)) do
      {number, ""} -> number
      _parse -> nil
    end
  end

  def numeric_value(_value), do: nil

  def normalize_number_list(nil), do: nil

  def normalize_number_list(values) when is_list(values) do
    values
    |> List.flatten()
    |> Enum.map(&numeric_value/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      numbers -> numbers
    end
  end

  def normalize_number_list(value), do: normalize_number_list([value])

  def sorted_string_values(values) do
    values
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp list_value(values) when is_list(values), do: values
  defp list_value(_values), do: []

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
