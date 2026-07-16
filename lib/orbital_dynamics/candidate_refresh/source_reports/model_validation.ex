defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ModelValidation do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ModelAcceptance
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ModelValidationArtifactReports
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ModelValidationDirectReports
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ModelValidationValueEncoding
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ValidationSafetyCase

  def model_acceptance_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    refresh
    |> ModelValidationDirectReports.model_acceptance_reports()
    |> Kernel.++(
      ModelValidationArtifactReports.model_acceptance_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      )
    )
    |> Enum.filter(fn {_path, report} -> ModelAcceptance.report?(report) end)
    |> Enum.map(fn {path, report} ->
      {path, ModelValidationValueEncoding.stringify_keys(report)}
    end)
  end

  def validation_safety_case_summaries(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    refresh
    |> ModelValidationDirectReports.validation_safety_case_summaries()
    |> Kernel.++(
      ModelValidationArtifactReports.validation_safety_case_summaries(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      )
    )
    |> Enum.filter(fn {_path, report} -> ValidationSafetyCase.report?(report) end)
    |> Enum.map(fn {path, report} ->
      {path, ModelValidationValueEncoding.stringify_keys(report)}
    end)
  end
end
