defmodule OrbitalDynamics.Constraint do
  @moduledoc """
  Contract for deterministic mission constraint evaluation.
  """

  @type capability_value ::
          atom()
          | number()
          | boolean()
          | String.t()
          | [capability_value()]
          | %{optional(atom()) => capability_value()}

  @type result :: %{
          required(:status) => :pass | :fail | :warning,
          optional(:score) => number(),
          optional(:metadata) => map()
        }

  @callback evaluate(term(), keyword()) :: {:ok, result()} | {:error, term()}
  @callback capabilities() :: %{optional(atom()) => capability_value()}

  @optional_callbacks capabilities: 0
end
