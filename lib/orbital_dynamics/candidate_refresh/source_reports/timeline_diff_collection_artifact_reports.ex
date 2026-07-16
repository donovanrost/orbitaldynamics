defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiffCollectionArtifactReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiff

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiffCollectionReviewArtifactReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiffCollectionTransitionApplicationReports

  def reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    result_artifact_reports(refresh, source_result_artifacts_fun) ++
      TimelineDiffCollectionTransitionApplicationReports.reports(
        refresh,
        source_result_artifacts_fun
      ) ++
      TimelineDiffCollectionReviewArtifactReports.operator_review_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) ++
      TimelineDiffCollectionReviewArtifactReports.cadence_import_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      )
  end

  defp result_artifact_reports(refresh, source_result_artifacts_fun) do
    refresh
    |> source_result_artifacts_fun.()
    |> Enum.flat_map(fn {path, artifact} ->
      TimelineDiff.result_artifact_entries(path, artifact)
    end)
  end
end
