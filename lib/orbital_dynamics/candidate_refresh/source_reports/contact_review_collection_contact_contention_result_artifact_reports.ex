defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ContactReviewCollectionContactContentionResultArtifactReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactContention

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactReviewCollectionContactContentionResultArtifactEncoding

  def reports(refresh, source_result_artifacts_fun, inherit_result_artifact_trust_boundary_fun) do
    refresh
    |> source_result_artifacts_fun.()
    |> Enum.flat_map(fn {path, artifact} ->
      artifact = stringify_keys(artifact)

      [
        {"#{path}", artifact},
        {"#{path}.source_contact_contention_report",
         Map.get(artifact, "source_contact_contention_report")},
        {"#{path}.contact_contention_report", Map.get(artifact, "contact_contention_report")},
        {"#{path}.contact_allocation_report.contact_contention_report",
         get_in(artifact, ["contact_allocation_report", "contact_contention_report"])}
      ]
      |> Enum.flat_map(fn {entry_path, report} ->
        ContactContention.entries(
          entry_path,
          inherit_result_artifact_trust_boundary_fun.(report, artifact)
        )
      end)
    end)
  end

  def stringify_keys(value),
    do: ContactReviewCollectionContactContentionResultArtifactEncoding.stringify_keys(value)
end
