defmodule OrbitalDynamics.Schema.CollectionAggregation do
  @moduledoc false

  def stable_id_array_map_ids(values) when is_map(values) do
    values
    |> Map.values()
    |> Enum.flat_map(&list_or_empty/1)
    |> Enum.filter(&is_binary/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  def stable_id_array_map_ids(_values), do: nil

  def stable_id_array_map_value_count(values) when is_map(values) do
    values
    |> Map.values()
    |> Enum.reduce_while(0, fn
      ids, total when is_list(ids) -> {:cont, total + length(ids)}
      _ids, _total -> {:halt, nil}
    end)
  end

  def stable_id_array_map_value_count(_values), do: nil

  def non_negative_integer_map_value(counts, key) when is_map(counts) do
    case Map.get(counts, key, 0) do
      count when is_integer(count) and count >= 0 -> count
      _count -> nil
    end
  end

  def non_negative_integer_map_value(_counts, _key), do: nil

  def positive_count_map_keys(counts) when is_map(counts) do
    if Enum.all?(counts, fn {_key, count} -> is_integer(count) and count >= 0 end) do
      counts
      |> Enum.filter(fn {_key, count} -> count > 0 end)
      |> Enum.map(fn {key, _count} -> key end)
      |> Enum.sort()
    end
  end

  def positive_count_map_keys(_counts), do: nil

  def row_count_difference(report, field, subtract) do
    case Map.get(report, field) do
      value when is_number(value) -> value - subtract
      _value -> nil
    end
  end

  def integer_or_zero(value) when is_integer(value), do: value
  def integer_or_zero(_value), do: 0

  def numeric_delta(left, right) when is_number(left) and is_number(right), do: left - right
  def numeric_delta(_left, _right), do: nil

  def row_count_sum(report, fields) do
    values = Enum.map(fields, &Map.get(report, &1))

    if Enum.all?(values, &is_number/1) do
      Enum.sum(values)
    end
  end

  def list_count(map, field) do
    case Map.get(map, field) do
      values when is_list(values) -> length(values)
      _value -> nil
    end
  end

  def sum_row_numbers(rows, field) do
    Enum.reduce(rows, 0, fn row, total ->
      case Map.get(row, field) do
        value when is_number(value) -> total + value
        _value -> total
      end
    end)
  end

  def sorted_unique_binary_values(values) do
    values
    |> Enum.filter(&is_binary/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  def sorted_stable_values(values) do
    values
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  def stable_values_by_key(pairs) do
    pairs
    |> Enum.reject(fn {key, value} -> key in [nil, ""] or value in [nil, ""] end)
    |> Enum.group_by(fn {key, _value} -> key end, fn {_key, value} -> value end)
    |> Map.new(fn {key, values} -> {key, sorted_stable_values(values)} end)
  end

  def row_unique_values(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  def row_ids_by_field(rows, group_field, id_field) do
    rows
    |> Enum.filter(&is_map/1)
    |> Enum.group_by(&Map.get(&1, group_field), &Map.get(&1, id_field))
    |> Enum.reject(fn {group, ids} -> is_nil(group) or Enum.all?(ids, &is_nil/1) end)
    |> Map.new(fn {group, ids} ->
      {group, ids |> Enum.reject(&is_nil/1) |> Enum.uniq() |> Enum.sort()}
    end)
  end

  def row_ids_by_field_value(rows, field, value, id_field) do
    rows
    |> Enum.filter(&(is_map(&1) and Map.get(&1, field) == value))
    |> Enum.map(&Map.get(&1, id_field))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  def row_ids_by_string_field(rows, group_field, id_field) do
    rows
    |> row_ids_by_field(group_field, id_field)
    |> Map.new(fn {group, ids} -> {to_string(group), ids} end)
  end

  def row_ids_by_direction_and_ground_station(rows, id_field) do
    rows
    |> Enum.filter(&is_map/1)
    |> Enum.reduce(%{}, fn row, acc ->
      direction = Map.get(row, "direction")
      ground_station_id = Map.get(row, "ground_station_id")
      id = Map.get(row, id_field)

      if direction in [nil, ""] or ground_station_id in [nil, ""] or id in [nil, ""] do
        acc
      else
        Map.update(acc, direction, %{ground_station_id => [id]}, fn station_map ->
          Map.update(station_map, ground_station_id, [id], fn ids -> [id | ids] end)
        end)
      end
    end)
    |> Map.new(fn {direction, station_map} ->
      {direction,
       Map.new(station_map, fn {ground_station_id, ids} ->
         {ground_station_id, ids |> Enum.uniq() |> Enum.sort()}
       end)}
    end)
  end

  def id_array_count_map(id_arrays) when is_map(id_arrays) do
    Map.new(id_arrays, fn {group, ids} ->
      {group, length(Enum.filter(ids, &is_binary/1))}
    end)
  end

  def frequency_map(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
  end

  def nested_frequency_map(rows, field, nested_field) do
    rows
    |> Enum.map(&get_in(&1, [field, nested_field]))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
  end

  def changed_field_frequency_map(rows) do
    rows
    |> Enum.flat_map(fn row ->
      case Map.get(row, "changed_fields") do
        fields when is_list(fields) -> fields
        _fields -> []
      end
    end)
    |> Enum.frequencies()
  end

  defp list_or_empty(values) when is_list(values), do: values
  defp list_or_empty(_values), do: []
end
