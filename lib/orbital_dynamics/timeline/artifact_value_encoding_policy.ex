defmodule OrbitalDynamics.Timeline.ArtifactValueEncodingPolicy do
  @moduledoc false

  def stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode(key), stringify_keys(value)} end)
  end

  def stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  def stringify_keys(value), do: encode(value)

  def encode(value) when is_boolean(value), do: value
  def encode(nil), do: nil
  def encode(value) when is_atom(value), do: Atom.to_string(value)
  def encode(value), do: value

  def compact(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
