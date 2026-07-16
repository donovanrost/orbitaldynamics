defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ContactReviewCollectionContactContentionResolutionResultArtifactReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactContentionResolution

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactReviewCollectionContactContentionResultArtifactReports,
    as: ResultArtifactEncoding

  def reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    refresh
    |> source_result_artifacts_fun.()
    |> Enum.flat_map(fn {path, artifact} ->
      artifact = stringify_keys(artifact)

      [
        {"#{path}", artifact},
        {"#{path}.source_contact_contention_resolution_report",
         Map.get(artifact, "source_contact_contention_resolution_report")},
        {"#{path}.contact_contention_resolution_report",
         Map.get(artifact, "contact_contention_resolution_report")},
        {"#{path}.source_contact_contention_resolution_summary",
         Map.get(artifact, "source_contact_contention_resolution_summary")},
        {"#{path}.contact_contention_resolution_summary",
         Map.get(artifact, "contact_contention_resolution_summary")}
      ]
      |> Enum.flat_map(fn {entry_path, report} ->
        ContactContentionResolution.entries(
          entry_path,
          inherit_result_artifact_trust_boundary_fun.(report, artifact)
        )
      end)
    end)
  end

  def stringify_keys(value) do
    ResultArtifactEncoding.stringify_keys(value)
  end
end
