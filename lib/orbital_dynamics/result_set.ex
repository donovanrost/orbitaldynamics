defmodule OrbitalDynamics.ResultSet do
  @moduledoc """
  Study-level mission analysis outputs.

  A result set keeps trajectories, events, and errors separated so downstream
  reporting can choose the products it needs without unpacking task internals.
  """

  @enforce_keys [:study_id, :trajectory_results, :event_results, :errors, :assumptions, :metadata]
  defstruct [:study_id, :trajectory_results, :event_results, :errors, :assumptions, :metadata]

  @type trajectory_result :: %{
          required(:scenario_id) => term(),
          required(:trajectory) => term(),
          optional(:node) => node()
        }

  @type event_result :: %{
          required(:scenario_id) => term(),
          required(:event_type) => atom(),
          required(:events) => [map()],
          optional(:source) => map()
        }

  @type error_result :: %{
          required(:scenario_id) => term(),
          required(:stage) => atom(),
          required(:error) => term()
        }

  @type t :: %__MODULE__{
          study_id: atom() | String.t(),
          trajectory_results: [trajectory_result()],
          event_results: [event_result()],
          errors: [error_result()],
          assumptions: map(),
          metadata: map()
        }

  @doc """
  Creates a result set.
  """
  def new!(attrs) when is_map(attrs) do
    %__MODULE__{
      study_id: Map.fetch!(attrs, :study_id),
      trajectory_results: list_field!(attrs, :trajectory_results),
      event_results: list_field!(attrs, :event_results),
      errors: list_field!(attrs, :errors),
      assumptions: map_field!(attrs, :assumptions),
      metadata: map_field!(attrs, :metadata)
    }
  end

  defp list_field!(attrs, key) do
    value = Map.get(attrs, key, [])
    if is_list(value), do: value, else: raise(ArgumentError, "#{key} must be a list")
  end

  defp map_field!(attrs, key) do
    value = Map.get(attrs, key, %{})
    if is_map(value), do: value, else: raise(ArgumentError, "#{key} must be a map")
  end
end
