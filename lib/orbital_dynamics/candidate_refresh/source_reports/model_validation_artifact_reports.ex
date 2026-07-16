defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ModelValidationArtifactReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ModelAcceptance
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ModelValidationArtifactTraversal
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ValidationSafetyCase

  def model_acceptance_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    ModelValidationArtifactTraversal.reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun,
      ["source_model_acceptance_report", "model_acceptance_report"],
      ModelAcceptance
    )
  end

  def validation_safety_case_summaries(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    ModelValidationArtifactTraversal.reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun,
      ["source_validation_safety_case_summary", "validation_safety_case_summary"],
      ValidationSafetyCase
    )
  end
end
