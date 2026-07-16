defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ContactReviewCollectionContactFilterResultArtifactEntries do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactFilter

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactReviewCollectionContactFilterArtifactEncoding

  def entries(path, artifact, inherit_result_artifact_trust_boundary_fun) do
    artifact = stringify_keys(artifact)

    [
      {"#{path}", artifact},
      {"#{path}.source_contact_filter_report", Map.get(artifact, "source_contact_filter_report")},
      {"#{path}.contact_filter_report", Map.get(artifact, "contact_filter_report")}
    ]
    |> Enum.flat_map(fn {entry_path, report} ->
      ContactFilter.entries(
        entry_path,
        inherit_result_artifact_trust_boundary_fun.(report, artifact)
      )
    end)
  end

  defp stringify_keys(value),
    do: ContactReviewCollectionContactFilterArtifactEncoding.stringify_keys(value)
end
