defmodule OrbitalDynamics.MissionAnalysis.Resource.Model do
  @moduledoc """
  Mission-owned state evolution over a complete, ordered planning timeline.

  Sessions are opaque and prepared once. State is a JSON-safe map. Each step
  receives midpoint spacecraft state/pointing, explicit mode, scope and phase,
  plus duration in seconds. Its inputs are frozen over that interval. Return
  three-valued checks using Path.Result; unknown stops propagation. All declared
  discontinuities must be supplied by boundaries/1. No interpolation of resource
  state or implicit interpretation of units occurs in the runner.
  """
  @callback prepare(OrbitalDynamics.MissionAnalysis.Asset.t(), term(), map()) ::
              {:ok, term(), map()} | {:error, term()}
  @callback initial(term()) :: map()
  @callback boundaries(term()) :: [number()]
  @callback step(map(), map(), number(), term()) ::
              {:ok, map(), OrbitalDynamics.MissionAnalysis.Path.Result.t()} | {:error, term()}
end
