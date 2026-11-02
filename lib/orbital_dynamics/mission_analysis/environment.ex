defmodule OrbitalDynamics.MissionAnalysis.Environment do
  @moduledoc """
  A replaceable, explicitly framed environment for spherical surface analysis.

  A sample carries the requested epoch and inertial frame, a direction toward
  the Sun, and the body's rotation angle about the inertial z axis. Models with
  different physical needs can use different context contracts entirely.
  """
  @callback at(OrbitalDynamics.Epoch.t(), term()) :: {:ok, map()} | {:error, term()}
  @callback describe(term()) :: map()
end
