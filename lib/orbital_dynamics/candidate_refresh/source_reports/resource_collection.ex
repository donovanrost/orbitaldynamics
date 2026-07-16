defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ResourceCollection do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceCollectionArtifactReports
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceCollectionDirectReports
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceCollectionEncoding
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceFilter
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceProjection

  def resource_projection_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    refresh
    |> ResourceCollectionDirectReports.resource_projection_reports()
    |> Kernel.++(
      ResourceCollectionArtifactReports.resource_projection_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      )
    )
    |> Enum.filter(fn {_path, report} -> ResourceProjection.report?(report) end)
    |> Enum.map(fn {path, report} ->
      {path, ResourceCollectionEncoding.stringify_keys(report)}
    end)
  end

  def resource_filter_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    refresh
    |> ResourceCollectionDirectReports.resource_filter_reports()
    |> Kernel.++(
      ResourceCollectionArtifactReports.resource_filter_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      )
    )
    |> Enum.filter(fn {_path, report} -> ResourceFilter.report?(report) end)
    |> Enum.map(fn {path, report} ->
      {path, ResourceCollectionEncoding.stringify_keys(report)}
    end)
  end
end
