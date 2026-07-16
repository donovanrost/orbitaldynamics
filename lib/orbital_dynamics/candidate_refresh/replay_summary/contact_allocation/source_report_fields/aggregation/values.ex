defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Aggregation.Values do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ValueEncoding

  def merge_count_maps(count_maps) do
    count_maps
    |> Enum.reject(&(&1 in [nil, %{}]))
    |> Enum.reduce(%{}, fn count_map, acc ->
      Enum.reduce(count_map, acc, fn {key, value}, acc ->
        Map.update(acc, to_string(key), value, fn
          current when is_integer(current) and is_integer(value) -> current + value
          current -> current
        end)
      end)
    end)
    |> non_empty_map()
  end

  def merge_numeric_maps(numeric_maps) do
    numeric_maps
    |> Enum.reject(&(&1 in [nil, %{}]))
    |> Enum.reduce(%{}, fn numeric_map, acc ->
      Enum.reduce(numeric_map, acc, fn {key, value}, acc ->
        case numeric_value(value) do
          value when is_number(value) -> Map.update(acc, key, value, &(&1 + value))
          _value -> acc
        end
      end)
    end)
    |> non_empty_map()
  end

  def merge_nested_string_list_maps(list_maps) do
    list_maps
    |> Enum.reject(&(&1 in [nil, %{}]))
    |> Enum.reduce(%{}, fn list_map, acc ->
      Enum.reduce(list_map, acc, fn {outer_key, inner_map}, acc ->
        case inner_map do
          %{} ->
            merged_inner =
              merge_string_list_maps([Map.get(acc, to_string(outer_key), %{}), inner_map])

            if is_nil(merged_inner) do
              acc
            else
              Map.put(acc, to_string(outer_key), merged_inner)
            end

          _inner_map ->
            acc
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

  def sorted_string_values(values) do
    values
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

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

  def numeric_report_count(report, field), do: numeric_value(Map.get(report, field)) || 0

  def report_count(value) do
    case numeric_value(value) do
      value when is_number(value) and value > 0 -> ceil(value)
      _value -> 0
    end
  end

  def numeric_value(value), do: ValueEncoding.numeric_value(value)

  defp list_value(values) when is_list(values), do: values
  defp list_value(_values), do: []

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
