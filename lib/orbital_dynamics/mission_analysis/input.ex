defmodule OrbitalDynamics.MissionAnalysis.Input do
  @moduledoc false

  def number!(value, label, lower, upper) do
    unless is_number(value) and value >= lower and value <= upper do
      raise ArgumentError, "#{label} must be a finite number in [#{lower}, #{upper}]"
    end

    value * 1.0
  end

  def positive!(value, label) do
    value = number!(value, label, 0, 1.0e15)
    if value == 0, do: raise(ArgumentError, "#{label} must be positive")
    value
  end

  def id!(value) do
    unless is_binary(value) and byte_size(value) <= 256 and
             Regex.match?(~r/\A[A-Za-z0-9][A-Za-z0-9._:@-]*\z/, value) do
      raise ArgumentError, "mission identifiers must be stable ID strings"
    end

    value
  end

  def vector!([x, y, z], label), do: vector!({x, y, z}, label)

  def vector!({x, y, z}, label) do
    {number!(x, label, -1.0e15, 1.0e15), number!(y, label, -1.0e15, 1.0e15),
     number!(z, label, -1.0e15, 1.0e15)}
  end

  def vector!(_value, label), do: raise(ArgumentError, "#{label} must have three components")

  def unit!(value, label) do
    vector = vector!(value, label)
    norm = OrbitalDynamics.Vector3.norm(vector)
    if norm < 1.0e-12, do: raise(ArgumentError, "#{label} must be nonzero")
    OrbitalDynamics.Vector3.scale(vector, 1.0 / norm)
  end

  def budgets!(budgets) when is_map(budgets) do
    Map.new(budgets, fn {key, value} ->
      {id!(key), number!(value, key, 0, 1.0e15)}
    end)
  end

  def budgets!(_budgets), do: raise(ArgumentError, "resource budgets/costs must be maps")
end
