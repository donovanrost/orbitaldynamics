defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common do
  @moduledoc false

  def sum_report_count(reports, counter) do
    reports
    |> Enum.map(counter)
    |> Enum.map(&report_count/1)
    |> Enum.sum()
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

  def report_count(value) do
    case numeric_value(value) do
      value when is_number(value) and value > 0 -> ceil(value)
      _value -> 0
    end
  end

  def numeric_report_count(report, field), do: numeric_value(Map.get(report, field)) || 0

  def count_values(values) do
    values
    |> Enum.map(&encode_value/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.reduce(%{}, fn value, counts -> Map.update(counts, value, 1, &(&1 + 1)) end)
  end

  def count_source_report_values(values) do
    values
    |> Enum.map(&normalized_source_report_token/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.frequencies()
    |> case do
      counts when counts == %{} -> nil
      counts -> counts
    end
  end

  def count_report_field_values(reports, field) do
    reports
    |> Enum.map(&Map.get(&1, field))
    |> Enum.map(&normalized_source_report_token/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.frequencies()
    |> non_empty_map()
  end

  def sorted_string_values(values) when is_list(values) do
    values
    |> Enum.map(&encode_value/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  def sorted_string_values(_values), do: []

  def compact_map(map) when is_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  def source_report_trust_boundary_status(reports) do
    case source_report_trust_boundaries(reports) do
      [] -> "missing"
      _trust_boundaries -> "declared"
    end
  end

  def source_report_trust_boundaries(reports) do
    reports
    |> Enum.flat_map(fn report ->
      [
        Map.get(report, "trust_boundary"),
        get_in(report, ["provenance", "trust_boundary"]),
        get_in(report, ["metadata", "trust_boundary"])
        | List.wrap(Map.get(report, "trust_boundaries"))
      ]
    end)
    |> normalize_trust_boundaries()
  end

  def normalize_trust_boundaries(values) do
    values
    |> Enum.map(&encode_value/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
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

  def merge_nested_numeric_maps(numeric_maps) do
    numeric_maps
    |> Enum.reject(&(&1 in [nil, %{}]))
    |> Enum.reduce(%{}, fn numeric_map, acc ->
      Enum.reduce(numeric_map, acc, fn {outer_key, inner_map}, acc ->
        case inner_map do
          %{} ->
            merged_inner =
              merge_numeric_maps([Map.get(acc, to_string(outer_key), %{}), inner_map])

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

  def merge_string_lists(lists) do
    lists
    |> Enum.flat_map(&List.wrap/1)
    |> sorted_non_empty_values()
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

  defp list_value(values) when is_list(values), do: values
  defp list_value(_values), do: []

  defp normalize_number_list(nil), do: nil

  defp normalize_number_list(values) when is_list(values) do
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

  defp normalize_number_list(value), do: normalize_number_list([value])

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

  defp normalized_source_report_token(value) do
    value
    |> encode_value()
    |> case do
      nil ->
        nil

      value ->
        value
        |> String.trim()
        |> String.downcase()
        |> String.replace(~r/[\s-]+/, "_")
        |> String.trim("_")
    end
  end

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map

  defp numeric_value(value) when is_number(value), do: value * 1.0

  defp numeric_value(value) when is_binary(value) do
    case Float.parse(String.trim(value)) do
      {number, ""} -> number
      _error -> nil
    end
  end

  defp numeric_value(_value), do: nil

  defp encode_value(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), encode_value(value)} end)
  end

  defp encode_value(values) when is_list(values) do
    Enum.map(values, &encode_value/1)
  end

  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
