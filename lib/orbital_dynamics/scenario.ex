defmodule OrbitalDynamics.Scenario do
  @moduledoc """
  A deterministic mission analysis case.

  `duration_s` and `output_step_s` are seconds. The same scenario input should
  always produce the same trajectory for a given propagator and options.
  """

  alias OrbitalDynamics.{CentralBody, Frame, Spacecraft, StateVector}

  alias OrbitalDynamics.Maneuver.ImpulsiveBurn

  @enforce_keys [:id, :spacecraft, :initial_state, :duration_s, :output_step_s, :central_body]
  defstruct [
    :id,
    :spacecraft,
    :initial_state,
    :duration_s,
    :output_step_s,
    :central_body,
    metadata: %{},
    maneuvers: []
  ]

  @type t :: %__MODULE__{
          id: atom() | String.t(),
          spacecraft: Spacecraft.t(),
          initial_state: StateVector.t(),
          duration_s: number(),
          output_step_s: pos_integer() | float(),
          central_body: CentralBody.t(),
          metadata: map(),
          maneuvers: [ImpulsiveBurn.t()]
        }

  @doc """
  Creates a mission scenario.
  """
  def new!(id, %Spacecraft{} = spacecraft, %StateVector{} = initial_state, opts \\ []) do
    duration_s = Keyword.fetch!(opts, :duration_s)
    output_step_s = Keyword.get(opts, :output_step_s, duration_s)
    central_body = Keyword.get(opts, :central_body, CentralBody.earth())
    metadata = Keyword.get(opts, :metadata, %{})
    maneuvers = Keyword.get(opts, :maneuvers, [])

    cond do
      id in [nil, ""] ->
        raise ArgumentError, "scenario id is required"

      not non_negative_number?(duration_s) ->
        raise ArgumentError, "duration_s must be non-negative seconds"

      not positive_number?(output_step_s) ->
        raise ArgumentError, "output_step_s must be positive seconds"

      not match?(%CentralBody{}, central_body) ->
        raise ArgumentError, "central_body must be an OrbitalDynamics.CentralBody"

      not Frame.compatible_with_central_body?(initial_state.frame, central_body) ->
        raise ArgumentError, "initial_state frame center must match central_body"

      not is_map(metadata) ->
        raise ArgumentError, "metadata must be a map"

      not valid_maneuvers?(maneuvers) ->
        raise ArgumentError,
              "maneuvers must be a list of OrbitalDynamics.Maneuver.ImpulsiveBurn structs"

      true ->
        %__MODULE__{
          id: id,
          spacecraft: spacecraft,
          initial_state: initial_state,
          duration_s: duration_s,
          output_step_s: output_step_s,
          central_body: central_body,
          metadata: metadata,
          maneuvers: maneuvers
        }
    end
  end

  defp valid_maneuvers?(maneuvers) when is_list(maneuvers),
    do: Enum.all?(maneuvers, &match?(%ImpulsiveBurn{}, &1))

  defp valid_maneuvers?(_maneuvers), do: false

  defp positive_number?(value), do: (is_integer(value) or is_float(value)) and value > 0
  defp non_negative_number?(value), do: (is_integer(value) or is_float(value)) and value >= 0
end
