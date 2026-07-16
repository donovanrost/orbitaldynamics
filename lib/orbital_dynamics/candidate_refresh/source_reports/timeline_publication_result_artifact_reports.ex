defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelinePublicationResultArtifactReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelinePublicationResultArtifactEntries
  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelinePublicationResultArtifactEncoding

  def reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    refresh
    |> source_result_artifacts_fun.()
    |> Enum.flat_map(fn {path, artifact} ->
      TimelinePublicationResultArtifactEntries.entries(
        path,
        artifact,
        inherit_result_artifact_trust_boundary_fun
      )
    end)
  end

  def stringify_keys(value), do: TimelinePublicationResultArtifactEncoding.stringify_keys(value)
end
