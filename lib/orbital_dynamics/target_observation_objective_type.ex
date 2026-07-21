defmodule OrbitalDynamics.TargetObservationObjectiveType do
  @moduledoc false

  @aliases ["target_observation", "target_commitment"]

  def aliases, do: @aliases

  defguard is_supported(type) when type in @aliases

  def supported?(type), do: type in @aliases

  def canonical(type) when type in @aliases, do: "target_observation"
  def canonical(_type), do: nil
end
