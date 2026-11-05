defmodule OrbitalDynamics.MissionAnalysis.Scheduling.Greedy do
  @moduledoc "Value-first greedy baseline; the controller supplies its canonical initial order."
  @behaviour OrbitalDynamics.MissionAnalysis.Scheduling.Strategy
  @impl true
  def propose(_, _, _, _), do: :done
end
