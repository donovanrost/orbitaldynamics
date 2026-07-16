defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineTransitionApplicationCollection do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineTransitionApplication

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineTransitionApplicationCollectionArtifactReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineTransitionApplicationCollectionEncoding

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineTransitionApplicationDirectReports

  def reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    refresh
    |> TimelineTransitionApplicationDirectReports.reports()
    |> Kernel.++(
      TimelineTransitionApplicationCollectionArtifactReports.reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      )
    )
    |> Enum.filter(fn {_path, report} -> TimelineTransitionApplication.report?(report) end)
    |> Enum.map(fn {path, report} ->
      {path, TimelineTransitionApplicationCollectionEncoding.stringify_keys(report)}
    end)
  end
end
