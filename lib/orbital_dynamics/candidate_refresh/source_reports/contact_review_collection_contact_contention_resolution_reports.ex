defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ContactReviewCollectionContactContentionResolutionReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactContentionResolution

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactReviewCollectionContactContentionResolutionArtifactReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactReviewCollectionContactContentionResolutionDirectReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactReviewCollectionContactContentionResolutionResultArtifactReports

  def reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    refresh
    |> ContactReviewCollectionContactContentionResolutionDirectReports.reports()
    |> Kernel.++(
      ContactReviewCollectionContactContentionResolutionResultArtifactReports.reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      )
    )
    |> Kernel.++(
      ContactReviewCollectionContactContentionResolutionArtifactReports.operator_review_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      )
    )
    |> Kernel.++(
      ContactReviewCollectionContactContentionResolutionArtifactReports.cadence_import_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      )
    )
    |> Enum.filter(fn {_path, report} ->
      ContactContentionResolution.report?(report)
    end)
    |> Enum.map(fn {path, report} -> {path, stringify_keys(report)} end)
  end

  defp stringify_keys(value) do
    ContactReviewCollectionContactContentionResolutionResultArtifactReports.stringify_keys(value)
  end
end
