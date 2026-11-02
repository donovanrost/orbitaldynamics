defmodule OrbitalDynamics.MissionAnalysis.Asset do
  @moduledoc """
  An asset with a sampled trajectory, declared model capabilities, and budgets.

  Capability keys are trusted Elixir model modules; their values are payload
  configurations interpreted by that model. Resource names carry their units
  (for example `energy_wh`); budgets are non-replenishing planning assumptions.
  """
  alias OrbitalDynamics.MissionAnalysis.Input
  alias OrbitalDynamics.Trajectory

  @enforce_keys [:id, :trajectory, :capabilities, :resource_budgets]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          id: String.t(),
          trajectory: Trajectory.t(),
          capabilities: map(),
          resource_budgets: map()
        }

  def new!(id, %Trajectory{} = trajectory, capabilities, resource_budgets)
      when is_map(capabilities) do
    unless Enum.all?(capabilities, fn {module, config} -> is_atom(module) and is_map(config) end),
      do: raise(ArgumentError, "capabilities must map model modules to configurations")

    %__MODULE__{
      id: Input.id!(id),
      trajectory: trajectory,
      capabilities: capabilities,
      resource_budgets: Input.budgets!(resource_budgets)
    }
  end
end
