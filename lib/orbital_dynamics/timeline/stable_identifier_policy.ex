defmodule OrbitalDynamics.Timeline.StableIdentifierPolicy do
  @moduledoc false

  def valid?(id, stable_id_pattern) when is_binary(id),
    do: Regex.match?(stable_id_pattern, id)
end
