defmodule OrbitalDynamics.Maneuver.ImpulsiveBurn do
  @moduledoc """
  Instantaneous velocity change at a declared epoch.

  The first maneuver model is deliberately frame-explicit and simple: `delta_v_km_s`
  is applied directly in the state vector frame by scalar propagators.
  """

  alias OrbitalDynamics.{Epoch, Frame, Vector3}

  @enforce_keys [:id, :epoch, :delta_v_km_s, :frame]
  defstruct [:id, :epoch, :delta_v_km_s, :frame]

  @type t :: %__MODULE__{
          id: atom() | String.t(),
          epoch: Epoch.t(),
          delta_v_km_s: Vector3.t(),
          frame: Frame.t()
        }

  @doc """
  Creates an impulsive burn.
  """
  def new!(id, %Epoch{} = epoch, delta_v_km_s, %Frame{} = frame) do
    cond do
      id in [nil, ""] ->
        raise ArgumentError, "maneuver id is required"

      not Vector3.valid?(delta_v_km_s) ->
        raise ArgumentError, "delta_v_km_s must be a numeric {x, y, z} tuple"

      true ->
        %__MODULE__{
          id: id,
          epoch: epoch,
          delta_v_km_s: delta_v_km_s,
          frame: frame
        }
    end
  end

  @doc """
  Metadata for trajectory assumptions and reports.
  """
  def assumptions(%__MODULE__{} = burn) do
    %{
      id: burn.id,
      type: :impulsive_burn,
      epoch_s: burn.epoch.seconds_since_j2000,
      epoch_scale: burn.epoch.scale,
      delta_v_km_s: burn.delta_v_km_s,
      delta_v_magnitude_km_s: Vector3.norm(burn.delta_v_km_s),
      frame: burn.frame.name
    }
  end
end
