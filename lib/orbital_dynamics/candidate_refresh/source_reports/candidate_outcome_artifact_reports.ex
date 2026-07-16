defmodule OrbitalDynamics.CandidateRefresh.SourceReports.CandidateOutcomeArtifactReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.CandidateDiff
  alias OrbitalDynamics.CandidateRefresh.SourceReports.CandidateOutcomeArtifactTraversal
  alias OrbitalDynamics.CandidateRefresh.SourceReports.CandidateRejection

  def candidate_diff_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    CandidateOutcomeArtifactTraversal.reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun,
      ["source_candidate_diff_report", "candidate_diff_report"],
      CandidateDiff
    )
  end

  def candidate_rejection_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    CandidateOutcomeArtifactTraversal.reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun,
      ["source_candidate_rejection_report", "candidate_rejection_report"],
      CandidateRejection
    )
  end
end
