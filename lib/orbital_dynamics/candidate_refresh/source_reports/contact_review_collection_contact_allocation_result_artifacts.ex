defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ContactReviewCollectionContactAllocationResultArtifacts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactAllocation

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactReviewCollectionContactAllocationEncoding

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactReviewCollectionContactAllocationResultArtifactSources

  def result_artifact_contact_allocation_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    refresh
    |> source_result_artifacts_fun.()
    |> Enum.flat_map(fn {path, artifact} ->
      artifact = ContactReviewCollectionContactAllocationEncoding.stringify_keys(artifact)

      path
      |> ContactReviewCollectionContactAllocationResultArtifactSources.sources(artifact)
      |> Enum.flat_map(fn {entry_path, report} ->
        ContactAllocation.entries(
          entry_path,
          inherit_result_artifact_trust_boundary_fun.(report, artifact)
        )
      end)
    end)
  end
end
