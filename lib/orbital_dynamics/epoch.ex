defmodule OrbitalDynamics.Epoch do
  @moduledoc """
  Mission analysis epoch expressed as seconds since J2000.

  `seconds_since_j2000` is a scalar offset from 2000-01-01T12:00:00 in the
  declared time scale. This avoids silently mixing wall-clock time with dynamical
  simulation time.
  """

  @enforce_keys [:scale, :seconds_since_j2000]
  defstruct [:scale, :seconds_since_j2000]

  @type scale :: :tdb | :tai | :utc
  @type t :: %__MODULE__{scale: scale(), seconds_since_j2000: number()}

  @doc """
  Creates an epoch.
  """
  def new!(seconds_since_j2000, scale \\ :tdb)

  def new!(seconds_since_j2000, scale)
      when scale in [:tdb, :tai, :utc] and
             (is_integer(seconds_since_j2000) or is_float(seconds_since_j2000)) do
    %__MODULE__{scale: scale, seconds_since_j2000: seconds_since_j2000}
  end

  def new!(_seconds_since_j2000, _scale) do
    raise ArgumentError,
          "epoch requires numeric seconds_since_j2000 and scale :tdb, :tai, or :utc"
  end

  @doc """
  Returns a new epoch shifted by `delta_seconds`.
  """
  def shift(%__MODULE__{} = epoch, delta_seconds)
      when is_integer(delta_seconds) or is_float(delta_seconds) do
    %{epoch | seconds_since_j2000: epoch.seconds_since_j2000 + delta_seconds}
  end
end
