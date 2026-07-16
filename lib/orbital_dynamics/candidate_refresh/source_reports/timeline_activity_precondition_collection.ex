defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityPreconditionCollection do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityPrecondition

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityPreconditionCollectionArtifactReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityPreconditionCollectionDirectReports

  def reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    refresh
    |> TimelineActivityPreconditionCollectionDirectReports.reports()
    |> Kernel.++(
      TimelineActivityPreconditionCollectionArtifactReports.result_artifact_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      )
    )
    |> Kernel.++(
      TimelineActivityPreconditionCollectionArtifactReports.operator_review_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      )
    )
    |> Kernel.++(
      TimelineActivityPreconditionCollectionArtifactReports.cadence_import_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      )
    )
    |> Enum.filter(fn {_path, summary} -> TimelineActivityPrecondition.summary?(summary) end)
    |> Enum.map(fn {path, summary} ->
      {path, TimelineActivityPreconditionCollectionArtifactReports.stringify_keys(summary)}
    end)
  end
end
