defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineLifecycleStateCollection do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineLifecycleStateCollectionTraversal

  def reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    TimelineLifecycleStateCollectionTraversal.reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun
    )
  end
end
