defmodule OrbitalDynamics.Timeline.CollectionValuePolicy do
  @moduledoc false

  def list_value(value, key), do: Map.get(value, key) || []
end
