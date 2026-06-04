defmodule OrbitalDynamics.BatchPropagator do
  @moduledoc """
  Contract for propagators that evaluate scenario batches directly.

  Batch propagators are useful for tensor or native backends where evaluating a
  homogeneous group together is materially different from running scalar
  propagation in concurrent BEAM tasks.
  """

  alias OrbitalDynamics.{Scenario, Trajectory}

  @callback propagate_many([Scenario.t()], keyword()) ::
              {:ok, [Trajectory.t()]} | {:error, term()}
end
