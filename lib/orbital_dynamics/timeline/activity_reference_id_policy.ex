defmodule OrbitalDynamics.Timeline.ActivityReferenceIdPolicy do
  @moduledoc false

  def normalize(nil, _map_keys, _stable_activity_id?), do: nil

  def normalize(values, map_keys, stable_activity_id?) when is_list(values) do
    values
    |> Enum.flat_map(&id_values(&1, map_keys))
    |> normalize_scalar_ids(stable_activity_id?)
  end

  def normalize(value, map_keys, stable_activity_id?) do
    value
    |> id_values(map_keys)
    |> normalize_scalar_ids(stable_activity_id?)
  end

  def normalize_maps(nil, _map_keys, _stable_activity_id?), do: nil

  def normalize_maps(values, map_keys, stable_activity_id?) when is_list(values) do
    values
    |> Enum.filter(&is_map/1)
    |> Enum.flat_map(&id_values(&1, map_keys))
    |> normalize_scalar_ids(stable_activity_id?)
  end

  def normalize_maps(%{} = value, map_keys, stable_activity_id?) do
    value
    |> id_values(map_keys)
    |> normalize_scalar_ids(stable_activity_id?)
  end

  def normalize_maps(_value, _map_keys, _stable_activity_id?), do: nil

  def duplicates(nil, _map_keys, _stable_activity_id?), do: nil

  def duplicates(values, map_keys, stable_activity_id?) when is_list(values) do
    values
    |> Enum.flat_map(&id_values(&1, map_keys))
    |> duplicate_scalar_ids(stable_activity_id?)
  end

  def duplicates(value, map_keys, stable_activity_id?) do
    value
    |> id_values(map_keys)
    |> duplicate_scalar_ids(stable_activity_id?)
  end

  def duplicate_maps(nil, _map_keys, _stable_activity_id?), do: nil

  def duplicate_maps(values, map_keys, stable_activity_id?) when is_list(values) do
    values
    |> Enum.filter(&is_map/1)
    |> Enum.flat_map(&id_values(&1, map_keys))
    |> duplicate_scalar_ids(stable_activity_id?)
  end

  def duplicate_maps(%{} = value, map_keys, stable_activity_id?) do
    value
    |> id_values(map_keys)
    |> duplicate_scalar_ids(stable_activity_id?)
  end

  def duplicate_maps(_value, _map_keys, _stable_activity_id?), do: nil

  defp id_values(%{} = value, map_keys) do
    Enum.flat_map(map_keys, fn key ->
      case Map.get(value, key) do
        nil -> []
        nested when is_list(nested) -> nested
        nested -> [nested]
      end
    end)
  end

  defp id_values(value, _map_keys), do: [value]

  defp normalize_scalar_ids(values, stable_activity_id?) do
    values
    |> Enum.flat_map(&stable_id_value(&1, stable_activity_id?))
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      ids -> ids
    end
  end

  defp duplicate_scalar_ids(values, stable_activity_id?) do
    values
    |> Enum.flat_map(&stable_id_value(&1, stable_activity_id?))
    |> Enum.frequencies()
    |> Enum.filter(fn {_id, count} -> count > 1 end)
    |> Enum.map(fn {id, _count} -> id end)
    |> Enum.sort()
    |> case do
      [] -> nil
      ids -> ids
    end
  end

  def stable_id_value(nil, _stable_activity_id?), do: []
  def stable_id_value(value, _stable_activity_id?) when is_boolean(value), do: []

  def stable_id_value(value, stable_activity_id?) when is_atom(value) do
    value
    |> Atom.to_string()
    |> stable_id_value(stable_activity_id?)
  end

  def stable_id_value(value, stable_activity_id?) when is_binary(value) do
    value
    |> String.split(",", trim: false)
    |> Enum.map(&String.trim/1)
    |> Enum.filter(fn value ->
      value != "" and value != "nil" and stable_activity_id?.(value)
    end)
  end

  def stable_id_value(value, stable_activity_id?) when is_integer(value) do
    value
    |> Integer.to_string()
    |> stable_id_value(stable_activity_id?)
  end

  def stable_id_value(_value, _stable_activity_id?), do: []
end
