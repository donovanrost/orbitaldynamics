defmodule OrbitalDynamics.CandidateRefresh.ValueEncoding do
  @moduledoc false

  @stable_id_pattern ~r/^[A-Za-z0-9][A-Za-z0-9._:@-]*$/

  def stable_id_or_nil(nil), do: nil
  def stable_id_or_nil("nil"), do: nil
  def stable_id_or_nil(value) when is_binary(value), do: if(stable_id?(value), do: value)

  def stable_id_or_nil(value) when is_atom(value),
    do: value |> Atom.to_string() |> stable_id_or_nil()

  def stable_id_or_nil(value) when is_integer(value),
    do: value |> Integer.to_string() |> stable_id_or_nil()

  def stable_id_or_nil(_value), do: nil

  def stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  def stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  def stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  def stringify_keys(value), do: encode_value(value)

  def numeric_value(value) when is_number(value), do: value * 1.0

  def numeric_value(value) when is_binary(value) do
    case Float.parse(String.trim(value)) do
      {number, ""} -> number
      _error -> nil
    end
  end

  def numeric_value(_value), do: nil

  def normalized_token(value) do
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

  def compact_nil_values(map) when is_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

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

  def stringify_keys_preserving_lists(%_struct{} = struct),
    do: struct |> Map.from_struct() |> stringify_keys_preserving_lists()

  def stringify_keys_preserving_lists(%{} = map) do
    Map.new(map, fn {key, value} ->
      {encode_value_preserving_lists(key), stringify_keys_preserving_lists(value)}
    end)
  end

  def stringify_keys_preserving_lists(values) when is_list(values),
    do: Enum.map(values, &stringify_keys_preserving_lists/1)

  def stringify_keys_preserving_lists(value), do: encode_value_preserving_lists(value)

  def encode_value_preserving_lists(%{} = map) do
    Map.new(map, fn {key, value} ->
      {encode_value_preserving_lists(key), encode_value_preserving_lists(value)}
    end)
  end

  def encode_value_preserving_lists(values) when is_list(values) do
    Enum.map(values, &encode_value_preserving_lists/1)
  end

  def encode_value_preserving_lists(value) when is_tuple(value),
    do: value |> Tuple.to_list() |> encode_value_preserving_lists()

  def encode_value_preserving_lists(nil), do: nil
  def encode_value_preserving_lists(value) when is_boolean(value), do: value
  def encode_value_preserving_lists(value) when is_atom(value), do: Atom.to_string(value)
  def encode_value_preserving_lists(value), do: value

  defp stable_id?(value), do: Regex.match?(@stable_id_pattern, value)
end
