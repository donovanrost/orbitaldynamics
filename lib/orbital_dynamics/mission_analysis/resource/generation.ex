defmodule OrbitalDynamics.MissionAnalysis.Resource.Generation do
  @moduledoc """
  Replaceable bus-power source for the battery model. Prepared sessions are opaque
  and shared by all timeline replays. evaluate/2 receives Resource.Model's sampled
  input, including spacecraft state, full pointing, mode, scope and phase. Watts
  are nonnegative electrical power available at the bus, before battery charging
  losses. boundaries/1 declares known time discontinuities; sampled geometry can
  still contain unobserved crossings between epochs. Optional search_boundaries/2
  accepts the runtime state source for bounded geometric contact searches. Its
  evaluation budget is separate from resource midpoint stepping. Unknown is not
  zero power.
  """
  @callback prepare(OrbitalDynamics.MissionAnalysis.Asset.t() | nil, term(), map()) ::
              {:ok, term(), map()} | {:error, term()}
  @callback boundaries(term()) :: [number()]
  @callback search_boundaries(term(), OrbitalDynamics.EventSearch.Source.t()) ::
              {:ok, [number()], term()} | {:unknown, term()} | {:error, term()}
  @optional_callbacks search_boundaries: 2
  @callback evaluate(map(), term()) ::
              {:ok, number(), map()} | {:unknown, term()} | {:error, term()}
end
