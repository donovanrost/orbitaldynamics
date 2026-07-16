defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDependencyImpactCollection do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDependencyImpact

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDependencyImpactCollectionArtifactReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDependencyImpactCollectionDirectReports

  def reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    refresh
    |> TimelineDependencyImpactCollectionDirectReports.reports()
    |> Kernel.++(
      TimelineDependencyImpactCollectionArtifactReports.result_artifact_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      )
    )
    |> Kernel.++(
      TimelineDependencyImpactCollectionArtifactReports.operator_review_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      )
    )
    |> Kernel.++(
      TimelineDependencyImpactCollectionArtifactReports.cadence_import_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      )
    )
    |> Enum.filter(fn {_path, summary} -> TimelineDependencyImpact.summary?(summary) end)
    |> Enum.map(fn {path, summary} ->
      {path, TimelineDependencyImpactCollectionArtifactReports.stringify_keys(summary)}
    end)
  end
end
