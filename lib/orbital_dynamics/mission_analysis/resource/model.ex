defmodule OrbitalDynamics.MissionAnalysis.Resource.Model do
  @moduledoc """
  Mission-owned state evolution over a complete, ordered planning timeline.

  Sessions are opaque and prepared once. State is bounded native map or struct data. JSON projection happens at report output. Each step
  receives midpoint spacecraft state/pointing, explicit mode, scope and phase,
  plus duration in seconds. Its inputs are frozen over that interval. Return
  three-valued checks using Path.Result; unknown stops propagation. All declared
  static discontinuities must be supplied by boundaries/1. Optional
  search_boundaries/2 discovers geometry-dependent boundaries on the checked
  runtime state source and retains its evidence under a separate explicit
  search budget; errors abort analysis and incomplete geometry stays unknown. No interpolation of resource
  state or implicit interpretation of units occurs in the runner.
  """
  @callback prepare(OrbitalDynamics.MissionAnalysis.Asset.t(), term(), map()) ::
              {:ok, term(), map()} | {:error, term()}
  @callback initial(term()) :: map()
  @callback boundaries(term()) :: [number()]
  @callback search_boundaries(term(), OrbitalDynamics.EventSearch.Source.t()) ::
              {:ok, [number()], term()} | {:unknown, term()} | {:error, term()}
  @optional_callbacks search_boundaries: 2
  @callback step(map(), map(), number(), term()) ::
              {:ok, map(), OrbitalDynamics.MissionAnalysis.Path.Result.t()} | {:error, term()}
end
