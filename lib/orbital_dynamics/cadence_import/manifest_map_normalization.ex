defmodule OrbitalDynamics.CadenceImport.ManifestMapNormalization do
  @moduledoc false

  def compact(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  def non_empty(%{} = map) when map_size(map) > 0, do: map
  def non_empty(_map), do: nil
end
