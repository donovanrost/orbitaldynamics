defmodule OrbitalDynamics.Timeline.ActivityMetricCalculationPolicy do
  @moduledoc false

  def delta(replacement, source) when is_number(replacement) and is_number(source),
    do: replacement - source

  def delta(_replacement, _source), do: nil

  def completion_fraction(actual, planned)
      when is_number(actual) and is_number(planned) and planned > 0.0 do
    actual / planned
  end

  def completion_fraction(_actual, _planned), do: nil
end
