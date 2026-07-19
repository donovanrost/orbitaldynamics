defmodule OrbitalDynamics.TimelineFeedback.RealizedIdentity do
  @moduledoc false

  @identity_keys ~w(id realized_activity_id planned_activity_id activity_id timeline_id)

  def identifier(map, key, stable_id_pattern) do
    case Map.get(map, key) do
      nil ->
        nil

      value when is_binary(value) and value != "" ->
        if(stable?(value, stable_id_pattern), do: value)

      value when is_atom(value) ->
        value |> Atom.to_string() |> stable_value(stable_id_pattern)

      _value ->
        nil
    end
  end

  def input_identity(activity, stable_id_pattern) do
    Enum.find_value(@identity_keys, &identifier(activity, &1, stable_id_pattern))
  end

  def input_issue(activity, stable_id_pattern) do
    raw_identities =
      @identity_keys
      |> Enum.map(&raw_identifier(activity, &1))
      |> Kernel.++([get_in(activity, ["metadata", "timeline_id"])])
      |> Kernel.++(raw_context_identifiers(activity))
      |> Enum.reject(&is_nil/1)

    cond do
      Enum.any?(raw_identities, &(not stable?(&1, stable_id_pattern))) ->
        "invalid_realized_feedback_id"

      input_identity(activity, stable_id_pattern) in [nil, ""] ->
        "missing_realized_feedback_id"

      true ->
        nil
    end
  end

  def source_id(source_activity, stable_id_pattern) do
    identifier(source_activity, "id", stable_id_pattern) ||
      identifier(source_activity, "realized_activity_id", stable_id_pattern)
  end

  def invalid_planned_id(source_activity, stable_id_pattern) do
    identifier(source_activity, "planned_activity_id", stable_id_pattern) ||
      identifier(source_activity, "activity_id", stable_id_pattern) ||
      source_id(source_activity, stable_id_pattern)
  end

  def invalid_timeline_id(source_activity, stable_id_pattern) do
    identifier(source_activity, "timeline_id", stable_id_pattern) ||
      stable_value(get_in(source_activity, ["metadata", "timeline_id"]), stable_id_pattern)
  end

  def id!(activity, stable_id_pattern) do
    input_identity(activity, stable_id_pattern) || raise(ArgumentError, "id is required")
  end

  def stable_value(value, stable_id_pattern) when is_binary(value) do
    if stable?(value, stable_id_pattern), do: value
  end

  def stable_value(_value, _stable_id_pattern), do: nil

  def stable?(value, stable_id_pattern) when is_binary(value),
    do: Regex.match?(stable_id_pattern, value)

  def stable?(_value, _stable_id_pattern), do: false

  def first_identifier(map, keys, stable_id_pattern) do
    Enum.find_value(keys, fn key ->
      value = first_value(map, [key])

      case value do
        nil -> nil
        value when is_binary(value) and value != "" -> stable_value(value, stable_id_pattern)
        value when is_atom(value) -> value |> Atom.to_string() |> stable_value(stable_id_pattern)
        %{} = nested -> identifier(nested, "id", stable_id_pattern)
        _value -> nil
      end
    end)
  end

  def first_value(map, keys) do
    Enum.reduce_while(keys, nil, fn key, _value ->
      metadata = Map.get(map, "metadata") || Map.get(map, :metadata) || %{}

      case fetch_key_or_atom(map, key) do
        {:ok, nil} -> first_value_from_metadata(metadata, key)
        {:ok, value} -> {:halt, value}
        :error -> first_value_from_metadata(metadata, key)
      end
    end)
  end

  def normalize_list(nil, _map_keys, _stable_id_pattern), do: nil

  def normalize_list(values, map_keys, stable_id_pattern) when is_list(values) do
    values
    |> Enum.flat_map(&id_values(&1, map_keys))
    |> normalize_scalar_ids(stable_id_pattern)
  end

  def normalize_list(value, map_keys, stable_id_pattern) do
    value
    |> id_values(map_keys)
    |> normalize_scalar_ids(stable_id_pattern)
  end

  def required_id!(map, key) do
    case Map.get(map, key) do
      value when is_binary(value) and value != "" -> value
      value when is_atom(value) and not is_nil(value) -> Atom.to_string(value)
      _value -> raise ArgumentError, "#{key} is required"
    end
  end

  defp raw_identifier(activity, key) do
    case Map.get(activity, key) do
      nil -> nil
      value when is_binary(value) and value != "" -> value
      value when is_atom(value) -> Atom.to_string(value)
      _value -> nil
    end
  end

  defp raw_context_identifiers(activity) do
    [
      raw_identifier(activity, "ground_station_id"),
      raw_identifier(activity, "station_id"),
      raw_identifier(activity, "target_id"),
      raw_identifier(activity, "spacecraft_id"),
      raw_identifier(activity, "satellite_id"),
      raw_identifier(activity, "resource_id"),
      raw_identifier(activity, "source_window_id"),
      raw_identifier(activity, "scenario_id"),
      raw_value_identifier(get_in(activity, ["metadata", "ground_station_id"])),
      raw_value_identifier(get_in(activity, ["metadata", "station_id"])),
      raw_value_identifier(get_in(activity, ["metadata", "target_id"])),
      raw_value_identifier(get_in(activity, ["metadata", "spacecraft_id"])),
      raw_value_identifier(get_in(activity, ["metadata", "source_window_id"])),
      raw_nested_identifier(activity, "target", ["target_id", "id"]),
      raw_nested_identifier(activity, "ground_station", ["ground_station_id", "station_id", "id"]),
      raw_nested_identifier(activity, "station", ["station_id", "id"]),
      raw_nested_identifier(activity, "spacecraft", ["spacecraft_id", "id"]),
      raw_nested_identifier(activity, "satellite", ["satellite_id", "id"]),
      raw_nested_identifier(activity, "source_window", ["source_window_id", "id"])
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp raw_nested_identifier(activity, object_key, identity_keys) do
    case Map.get(activity, object_key) do
      %{} = object -> Enum.find_value(identity_keys, &raw_identifier(object, &1))
      _value -> nil
    end
  end

  defp raw_value_identifier(value) when is_binary(value) and value != "", do: value
  defp raw_value_identifier(value) when is_atom(value), do: Atom.to_string(value)
  defp raw_value_identifier(_value), do: nil

  defp first_value_from_metadata(metadata, key) do
    case fetch_key_or_atom(metadata, key) do
      {:ok, nil} -> {:cont, nil}
      {:ok, value} -> {:halt, value}
      :error -> {:cont, nil}
    end
  end

  defp fetch_key_or_atom(map, key) when is_map(map) do
    case Map.fetch(map, key) do
      {:ok, value} -> {:ok, value}
      :error when is_binary(key) -> fetch_existing_atom_key(map, key)
      :error -> :error
    end
  end

  defp fetch_key_or_atom(_map, _key), do: :error

  defp fetch_existing_atom_key(map, key) do
    atom_key = String.to_existing_atom(key)
    Map.fetch(map, atom_key)
  rescue
    ArgumentError -> :error
  end

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

  defp normalize_scalar_ids(values, stable_id_pattern) do
    values
    |> Enum.flat_map(&stable_id_values(&1, stable_id_pattern))
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      ids -> ids
    end
  end

  defp stable_id_values(nil, _stable_id_pattern), do: []
  defp stable_id_values(value, _stable_id_pattern) when is_boolean(value), do: []

  defp stable_id_values(value, stable_id_pattern) when is_atom(value) do
    value
    |> Atom.to_string()
    |> stable_id_values(stable_id_pattern)
  end

  defp stable_id_values("nil", _stable_id_pattern), do: []

  defp stable_id_values(value, stable_id_pattern) when is_binary(value) and value != "" do
    if stable?(value, stable_id_pattern), do: [value], else: []
  end

  defp stable_id_values(value, stable_id_pattern) when is_integer(value) do
    value
    |> Integer.to_string()
    |> stable_id_values(stable_id_pattern)
  end

  defp stable_id_values(_value, _stable_id_pattern), do: []
end
