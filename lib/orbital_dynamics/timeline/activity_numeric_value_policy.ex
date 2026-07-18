defmodule OrbitalDynamics.Timeline.ActivityNumericValuePolicy do
  @moduledoc false

  def numeric_triplet([x, y, z]) do
    triplet = Enum.map([x, y, z], &numeric_value/1)

    if Enum.all?(triplet, &is_number/1), do: triplet, else: nil
  end

  def numeric_triplet(_value), do: nil

  def numeric_value(value) when is_number(value), do: value

  def numeric_value(value) when is_binary(value) do
    case Float.parse(String.trim(value)) do
      {number, ""} -> number
      _other -> nil
    end
  end

  def numeric_value(_value), do: nil

  def vector_norm(nil), do: nil

  def vector_norm([x, y, z]) do
    :math.sqrt(x * x + y * y + z * z)
  end
end
