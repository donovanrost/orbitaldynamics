defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiffCollection do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiff
  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiffCollectionArtifactReports
  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiffCollectionEncoding
  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiffDirectReports

  def reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    refresh
    |> TimelineDiffDirectReports.reports()
    |> Kernel.++(
      TimelineDiffCollectionArtifactReports.reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      )
    )
    |> Enum.filter(fn {_path, report} -> TimelineDiff.report?(report) end)
    |> Enum.map(fn {path, report} -> {path, stringify_keys(report)} end)
  end

  defp stringify_keys(value), do: TimelineDiffCollectionEncoding.stringify_keys(value)
end
