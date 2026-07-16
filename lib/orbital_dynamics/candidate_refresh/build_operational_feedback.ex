defmodule OrbitalDynamics.CandidateRefresh.BuildOperationalFeedback do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback

  def maybe_put(artifact, refresh, operational_feedback) do
    feedback = operational_feedback.(refresh)

    if OperationalFeedback.data_keys(feedback) == [] do
      artifact
    else
      Map.put(artifact, "operational_feedback", feedback)
    end
  end
end
