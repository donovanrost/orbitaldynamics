defmodule OrbitalDynamics.MissionAnalysis.Models.SurfaceSupport do
  @moduledoc false
  alias OrbitalDynamics.{StateVector, Target}
  alias OrbitalDynamics.MissionAnalysis.{Input, SphericalScene}

  def fields!(map, fields, label) when is_map(map) do
    unless Enum.sort(Map.keys(map)) == Enum.sort(fields),
      do: raise(ArgumentError, "#{label} requires exactly #{inspect(fields)}")

    map
  end

  def number!(map, key, low, high), do: Input.number!(Map.fetch!(map, key), key, low, high)
  def positive!(map, key), do: Input.positive!(Map.fetch!(map, key), key)

  def check(id, passed, actual, limit),
    do: %{"id" => id, "passed" => passed, "actual" => actual, "limit" => limit}

  # Positive margin is headroom, negative is a violation, zero is a boundary.
  # The boolean result remains authoritative (strict comparisons can fail at zero).
  def check(id, passed, actual, limit, sense, unit) when sense in [:min, :strict_min, :max] do
    margin =
      if is_number(actual) and is_number(limit),
        do: if(sense == :max, do: limit - actual, else: actual - limit),
        else: nil

    Map.merge(check(id, passed, actual, limit), %{
      "margin" => margin,
      "margin_unit" => unit,
      "margin_comparison" => Atom.to_string(sense)
    })
  end

  def context!(request, %SphericalScene{} = scene) do
    unless match?(%Target{}, request.subject) and request.time_scale == scene.time_scale,
      do: raise(ArgumentError, "surface model requires a Target and matching scene time scale")

    SphericalScene.describe(scene, request.subject)
  end

  def rate(_state, nil, _session, _pointing_fun), do: {:ok, nil}

  def rate(%StateVector{} = state, previous, session, pointing_fun) do
    with {:ok, prior_scene} <- SphericalScene.at(session.scene, previous, session.target),
         {:ok, current_scene} <- SphericalScene.at(session.scene, state, session.target) do
      before = pointing_fun.(prior_scene)
      now = pointing_fun.(current_scene)

      if before == nil or now == nil do
        {:ok, nil}
      else
        {:ok,
         SphericalScene.tracking_rate(
           before,
           now,
           state.epoch.seconds_since_j2000,
           previous.epoch.seconds_since_j2000
         )}
      end
    end
  end
end
