defmodule OrbitalDynamics.TimelineFeedback.ArtifactValue do
  @moduledoc false

  def present_string?(value), do: is_binary(value) and value != ""

  def stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_key(key), stringify_keys(value)} end)
  end

  def stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  def stringify_keys(nil), do: nil
  def stringify_keys(value) when is_boolean(value), do: value
  def stringify_keys(value) when is_atom(value), do: Atom.to_string(value)
  def stringify_keys(value), do: value

  def stringify_scalar(nil), do: nil
  def stringify_scalar(value) when is_binary(value), do: value
  def stringify_scalar(value) when is_atom(value), do: Atom.to_string(value)
  def stringify_scalar(value) when is_integer(value), do: Integer.to_string(value)
  def stringify_scalar(value) when is_float(value), do: Float.to_string(value)
  def stringify_scalar(_value), do: nil

  def truthy?(value) when is_boolean(value), do: value
  def truthy?(value) when is_number(value), do: value == 1

  def truthy?(value) when is_binary(value) do
    String.downcase(String.trim(value)) in ["true", "yes", "1"]
  end

  def truthy?(_value), do: false

  def boolean_value(value) when is_boolean(value), do: value

  def boolean_value(value) when is_number(value) do
    cond do
      value == 1 -> true
      value == 0 -> false
      true -> nil
    end
  end

  def boolean_value(value) when is_binary(value) do
    case String.downcase(String.trim(value)) do
      "true" -> true
      "yes" -> true
      "1" -> true
      "false" -> false
      "no" -> false
      "0" -> false
      _value -> nil
    end
  end

  def boolean_value(_value), do: nil

  def compact_map(map, omission_policy \\ nil)

  def compact_map(map, nil) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  def compact_map(map, :nil_and_empty_lists) do
    Map.reject(map, fn
      {_key, nil} -> true
      {_key, []} -> true
      _entry -> false
    end)
  end

  def maybe_put(map, _key, nil), do: map
  def maybe_put(map, _key, []), do: map
  def maybe_put(map, key, value), do: Map.put(map, key, value)

  defp encode_key(key) when is_atom(key), do: Atom.to_string(key)
  defp encode_key(key), do: key
end
