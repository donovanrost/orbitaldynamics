defmodule OrbitalDynamics.Vector3 do
  @moduledoc """
  Small tuple-based 3D vector helpers.

  Vectors are represented as `{x, y, z}` tuples. Unit meaning is provided by the
  owning struct, such as `StateVector.position_km` or `StateVector.velocity_km_s`.
  """

  @type t :: {number(), number(), number()}

  @doc """
  Validates a vector tuple.
  """
  def valid?({x, y, z}), do: number?(x) and number?(y) and number?(z)
  def valid?(_other), do: false

  def add({ax, ay, az}, {bx, by, bz}), do: {ax + bx, ay + by, az + bz}
  def subtract({ax, ay, az}, {bx, by, bz}), do: {ax - bx, ay - by, az - bz}
  def scale({x, y, z}, scalar), do: {x * scalar, y * scalar, z * scalar}
  def dot({ax, ay, az}, {bx, by, bz}), do: ax * bx + ay * by + az * bz

  def cross({ax, ay, az}, {bx, by, bz}) do
    {
      ay * bz - az * by,
      az * bx - ax * bz,
      ax * by - ay * bx
    }
  end

  def norm(vector), do: :math.sqrt(dot(vector, vector))

  defp number?(value), do: is_integer(value) or is_float(value)
end
