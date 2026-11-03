defmodule OrbitalDynamics.EventDetector do
  @moduledoc """
  Contract for deterministic event detection over trajectory outputs.

  Existing detectors retain their timing policies. Opt-in EventSearch provides
  shared scalar/root search over explicitly sampled or caller-provided sources;
  new Nodes and Apsides implement this contract without changing legacy defaults.
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

  @doc "Run an opt-in scalar event search with explicit source and numerical controls."
  def search(source, functions, opts),
    do: OrbitalDynamics.EventSearch.run(source, functions, opts)

  @optional_callbacks capabilities: 0
end
