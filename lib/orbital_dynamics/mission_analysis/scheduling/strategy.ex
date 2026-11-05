defmodule OrbitalDynamics.MissionAnalysis.Scheduling.Strategy do
  @moduledoc """
  Trusted search strategy over opportunity-order proposals. The controller owns
  trial bounds, validates permutations, evaluates proposals and accepts improvements.
  Incumbent carries :order and the evaluator's {:ok, activities, decisions,
  balances, attitude_report} result. History carries :tried_orders and :trials.
  The private strategy state starts as nil and survives accepted/rejected proposals.
  Future encodings with fixed activity times require an additional evaluator API.
  """
  @callback propose(map(), map(), map(), term()) ::
              :done | {:candidate, [map()], map(), term()}
end
