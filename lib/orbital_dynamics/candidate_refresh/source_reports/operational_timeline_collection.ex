defmodule OrbitalDynamics.CandidateRefresh.SourceReports.OperationalTimelineCollection do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.OperationalTimeline

  alias OrbitalDynamics.CandidateRefresh.SourceReports.OperationalTimelineCollectionArtifactEncoding

  alias OrbitalDynamics.CandidateRefresh.SourceReports.OperationalTimelineCollectionArtifactReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.OperationalTimelineCollectionDirectReports

  def reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    refresh
    |> OperationalTimelineCollectionDirectReports.reports()
    |> Kernel.++(
      OperationalTimelineCollectionArtifactReports.reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      )
    )
    |> Enum.filter(fn {_path, report} -> OperationalTimeline.report?(report) end)
    |> Enum.map(fn {path, report} -> {path, stringify_keys(report)} end)
  end

  defp stringify_keys(value),
    do: OperationalTimelineCollectionArtifactEncoding.stringify_keys(value)
end
