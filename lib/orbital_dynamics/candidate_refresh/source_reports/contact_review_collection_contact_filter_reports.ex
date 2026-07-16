defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ContactReviewCollectionContactFilterReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactFilter

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactReviewCollectionContactFilterArtifactReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactReviewCollectionContactFilterArtifactEncoding

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactReviewCollectionContactFilterDirectReports

  def contact_filter_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    refresh
    |> ContactReviewCollectionContactFilterDirectReports.reports()
    |> Kernel.++(
      ContactReviewCollectionContactFilterArtifactReports.result_artifact_contact_filter_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      )
    )
    |> Kernel.++(
      ContactReviewCollectionContactFilterArtifactReports.operator_review_contact_filter_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      )
    )
    |> Kernel.++(
      ContactReviewCollectionContactFilterArtifactReports.cadence_import_contact_filter_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      )
    )
    |> Enum.filter(fn {_path, report} -> ContactFilter.report?(report) end)
    |> Enum.map(fn {path, report} -> {path, stringify_keys(report)} end)
  end

  defp stringify_keys(value),
    do: ContactReviewCollectionContactFilterArtifactEncoding.stringify_keys(value)
end
