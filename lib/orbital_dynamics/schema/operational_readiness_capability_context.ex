defmodule OrbitalDynamics.Schema.OperationalReadinessCapabilityContext do
  @moduledoc false

  def operational_readiness_capabilities do
    OrbitalDynamics.OperationalReadiness.capabilities()
  end

  def operational_readiness_model_limits do
    operational_readiness_capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end
end
