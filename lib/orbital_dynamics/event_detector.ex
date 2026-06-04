defmodule OrbitalDynamics.EventDetector do
  @moduledoc """
  Contract for deterministic event detection over trajectory outputs.
  """

  alias OrbitalDynamics.{Epoch, Trajectory}

  @type capability_value ::
          atom()
          | number()
          | boolean()
          | String.t()
          | [capability_value()]
          | %{optional(atom()) => capability_value()}

  @type event :: %{
          required(:type) => atom(),
          required(:starts_at) => Epoch.t(),
          optional(:ends_at) => Epoch.t(),
          optional(:metadata) => map()
        }

  @callback detect(Trajectory.t(), keyword()) :: {:ok, [event()]} | {:error, term()}
  @callback capabilities() :: %{optional(atom()) => capability_value()}

  @optional_callbacks capabilities: 0
end
