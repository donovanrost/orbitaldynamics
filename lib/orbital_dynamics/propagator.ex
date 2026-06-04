defmodule OrbitalDynamics.Propagator do
  @moduledoc """
  Contract for modules that advance a scenario into a trajectory.

  Propagators are numerical backends. They may be scalar Elixir, Nx/EXLA,
  native code, or remote service adapters, but callers should be able to rely on
  the same safe return shape and explicit capability metadata.
  """

  alias OrbitalDynamics.{Scenario, Trajectory}

  @type capability_value ::
          atom()
          | number()
          | boolean()
          | String.t()
          | [capability_value()]
          | %{optional(atom()) => capability_value()}

  @callback propagate(Scenario.t(), keyword()) :: {:ok, Trajectory.t()} | {:error, term()}
  @callback capabilities() :: %{optional(atom()) => capability_value()}
end
