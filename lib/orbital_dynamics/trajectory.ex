defmodule OrbitalDynamics.Trajectory do
  @moduledoc """
  Propagation output for a scenario.
  """

  alias OrbitalDynamics.StateVector

  @enforce_keys [:scenario_id, :states, :assumptions]
  defstruct [:scenario_id, :states, :assumptions]

  @type t :: %__MODULE__{
          scenario_id: atom() | String.t(),
          states: [StateVector.t()],
          assumptions: map()
        }
end
