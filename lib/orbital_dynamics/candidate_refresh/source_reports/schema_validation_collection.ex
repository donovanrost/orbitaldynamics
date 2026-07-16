defmodule OrbitalDynamics.CandidateRefresh.SourceReports.SchemaValidationCollection do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.SchemaValidation
  alias OrbitalDynamics.CandidateRefresh.SourceReports.SchemaValidationCollectionArtifactReports
  alias OrbitalDynamics.CandidateRefresh.SourceReports.SchemaValidationDirectReports

  def reports(refresh, source_result_artifacts_fun, inherit_result_artifact_trust_boundary_fun) do
    refresh
    |> SchemaValidationDirectReports.reports()
    |> Kernel.++(
      SchemaValidationCollectionArtifactReports.result_artifact_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      )
    )
    |> Kernel.++(
      SchemaValidationCollectionArtifactReports.operator_review_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      )
    )
    |> Kernel.++(
      SchemaValidationCollectionArtifactReports.cadence_import_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      )
    )
    |> Enum.filter(fn {_path, report} -> SchemaValidation.report?(report) end)
    |> Enum.map(fn {path, report} ->
      {path, SchemaValidationCollectionArtifactReports.stringify_keys(report)}
    end)
  end
end
