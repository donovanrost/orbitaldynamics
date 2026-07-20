defmodule OrbitalDynamics.Schema.PolicyCapabilityContext do
  @moduledoc false

  def policy_model_limits do
    OrbitalDynamics.Policy.capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end
end
