defmodule OrbitalDynamics.CadenceImport.JsonNormalization do
  @moduledoc false

  def stringify_keys(%{} = map) do
    Map.new(map, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), stringify_keys(value)}
      {key, value} -> {key, stringify_keys(value)}
    end)
  end

  def stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  def stringify_keys(nil), do: nil
  def stringify_keys(:null), do: nil
  def stringify_keys(value), do: value

  def encode_json_value(%{} = map), do: stringify_keys(map)

  def encode_json_value(values) when is_list(values),
    do: Enum.map(values, &encode_json_value/1)

  def encode_json_value(value) when is_tuple(value),
    do: value |> Tuple.to_list() |> encode_json_value()

  def encode_json_value(nil), do: nil
  def encode_json_value(:null), do: nil
  def encode_json_value(value) when is_atom(value), do: Atom.to_string(value)
  def encode_json_value(value), do: value
end
