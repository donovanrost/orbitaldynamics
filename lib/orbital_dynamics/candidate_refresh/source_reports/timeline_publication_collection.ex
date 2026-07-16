defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelinePublicationCollection do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelinePublication

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelinePublicationCollectionArtifactReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelinePublicationDirectReports

  def reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    refresh
    |> TimelinePublicationDirectReports.reports()
    |> Kernel.++(
      TimelinePublicationCollectionArtifactReports.result_artifact_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      )
    )
    |> Kernel.++(
      TimelinePublicationCollectionArtifactReports.operator_review_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      )
    )
    |> Kernel.++(
      TimelinePublicationCollectionArtifactReports.cadence_import_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      )
    )
    |> Enum.filter(fn {_path, summary} -> TimelinePublication.summary?(summary) end)
    |> Enum.map(fn {path, summary} ->
      {path, TimelinePublicationCollectionArtifactReports.stringify_keys(summary)}
    end)
  end
end
