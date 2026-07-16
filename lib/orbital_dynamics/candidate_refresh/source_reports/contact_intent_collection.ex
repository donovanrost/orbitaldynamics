defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ContactIntentCollection do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactIntent
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactIntentCollectionArtifactReports
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactIntentCollectionDirectReports
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactIntentCollectionEncoding

  def reports(refresh, source_result_artifacts_fun, inherit_result_artifact_trust_boundary_fun) do
    refresh
    |> ContactIntentCollectionDirectReports.reports()
    |> Kernel.++(
      ContactIntentCollectionArtifactReports.result_artifact_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      )
    )
    |> Kernel.++(
      ContactIntentCollectionArtifactReports.operator_review_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      )
    )
    |> Kernel.++(
      ContactIntentCollectionArtifactReports.cadence_import_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      )
    )
    |> Enum.filter(fn {_path, intent} -> ContactIntent.source?(intent) end)
    |> Enum.map(fn {path, intent} ->
      {path, ContactIntentCollectionEncoding.stringify_keys(intent)}
    end)
  end
end
