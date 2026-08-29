defmodule OrbitalDynamics.Timeline.StableIdentifierPolicy do
  @moduledoc false

  def valid?(id, stable_id_validation) when is_binary(id),
    do: stable_id_validation.valid?(id)
end
