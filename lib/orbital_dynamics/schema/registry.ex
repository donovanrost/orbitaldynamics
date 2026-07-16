defmodule OrbitalDynamics.Schema.Registry do
  @moduledoc false

  def all(contracts) when is_map(contracts), do: contracts

  def fetch(contracts, name) when is_map(contracts) and is_binary(name),
    do: Map.fetch(contracts, name)

  def fetch!(contracts, name) when is_map(contracts) and is_binary(name),
    do: Map.fetch!(contracts, name)

  def names(contracts) when is_map(contracts),
    do: contracts |> Map.keys() |> Enum.sort()

  def known?(contracts, name) when is_map(contracts) and is_binary(name),
    do: Map.has_key?(contracts, name)

  def known?(_contracts, _name), do: false
end
