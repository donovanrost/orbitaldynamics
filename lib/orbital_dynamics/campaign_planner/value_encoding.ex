defmodule OrbitalDynamics.CampaignPlanner.ValueEncoding do
  @moduledoc false

  def get_key(nil, _key), do: nil

  def get_key(%{} = map, key) when is_atom(key),
    do: fetch_key_or_alias(map, key, Atom.to_string(key))

  def get_key(%{} = map, key), do: fetch_key_or_alias(map, key, String.to_atom(key))

  def stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  def stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  def stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  def stringify_keys(value), do: encode_value(value)

  def compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  def reject_empty_values(map) do
    map
    |> Enum.reject(fn {_key, value} -> value in [nil, "", []] end)
    |> Map.new()
  end

  def put_default_if_present(map, _field, value) when value in [nil, "", [], %{}], do: map

  def put_default_if_present(map, field, value) do
    case Map.get(map, field) do
      existing when existing in [nil, ""] -> Map.put(map, field, value)
      _existing -> map
    end
  end

  def branch_id_fragment(value) do
    value
    |> encode_value()
    |> to_string()
    |> String.replace(~r/[^A-Za-z0-9._:@-]+/, "_")
    |> String.trim("_")
    |> case do
      "" -> "unnamed"
      fragment -> fragment
    end
  end

  def encode_value(%_{} = struct), do: struct |> Map.from_struct() |> encode_value()

  def encode_value(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), encode_value(value)} end)
  end

  def encode_value(values) when is_list(values) do
    if Keyword.keyword?(values) do
      Map.new(values, fn {key, value} -> {encode_value(key), encode_value(value)} end)
    else
      Enum.map(values, &encode_value/1)
    end
  end

  def encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  def encode_value(nil), do: nil
  def encode_value(value) when is_boolean(value), do: value
  def encode_value(value) when is_atom(value), do: Atom.to_string(value)
  def encode_value(value), do: value

  defp fetch_key_or_alias(map, key, alias_key) do
    case Map.fetch(map, key) do
      {:ok, nil} -> Map.get(map, alias_key)
      {:ok, value} -> value
      :error -> Map.get(map, alias_key)
    end
  end
end
