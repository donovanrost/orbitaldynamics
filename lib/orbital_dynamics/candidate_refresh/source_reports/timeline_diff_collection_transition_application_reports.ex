defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiffCollectionTransitionApplicationReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiffCollectionTransitionApplicationDirectReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiffCollectionTransitionApplicationResultArtifactReports

  def reports(refresh, source_result_artifacts_fun) do
    TimelineDiffCollectionTransitionApplicationDirectReports.reports(refresh) ++
      TimelineDiffCollectionTransitionApplicationResultArtifactReports.reports(
        refresh,
        source_result_artifacts_fun
      )
  end
end
