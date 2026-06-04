defmodule OrbitalDynamics.StateVector do
  @moduledoc """
  Cartesian orbital state.

  Positions are kilometers and velocities are kilometers per second. Epoch and
  frame are required to make unit and reference assumptions explicit.
  """

  alias OrbitalDynamics.{Epoch, Frame, Vector3}

  @enforce_keys [:position_km, :velocity_km_s, :epoch, :frame]
  defstruct [:position_km, :velocity_km_s, :epoch, :frame]

  @type t :: %__MODULE__{
          position_km: Vector3.t(),
          velocity_km_s: Vector3.t(),
          epoch: Epoch.t(),
          frame: Frame.t()
        }

  @doc """
  Creates a state vector, raising when units-bearing fields are missing or malformed.
  """
  def new!(position_km, velocity_km_s, %Epoch{} = epoch, %Frame{} = frame) do
    unless Vector3.valid?(position_km) do
      raise ArgumentError, "position_km must be a numeric {x, y, z} tuple"
    end

    unless Vector3.valid?(velocity_km_s) do
      raise ArgumentError, "velocity_km_s must be a numeric {x, y, z} tuple"
    end

    %__MODULE__{
      position_km: position_km,
      velocity_km_s: velocity_km_s,
      epoch: epoch,
      frame: frame
    }
  end
end
