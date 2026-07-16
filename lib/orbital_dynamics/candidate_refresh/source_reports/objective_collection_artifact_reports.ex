defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ObjectiveCollectionArtifactReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ObjectiveCollectionResultArtifactReports
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ObjectiveCollectionReviewArtifactReports
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ObjectiveSatisfaction
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ObjectiveTradeoff

  def objective_satisfaction_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    ObjectiveCollectionResultArtifactReports.reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun,
      ObjectiveSatisfaction,
      [
        "source_objective_satisfaction_report",
        "objective_satisfaction_report"
      ]
    ) ++
      ObjectiveCollectionReviewArtifactReports.operator_review_objective_satisfaction_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) ++
      ObjectiveCollectionReviewArtifactReports.cadence_import_objective_satisfaction_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      )
  end

  def objective_tradeoff_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    ObjectiveCollectionResultArtifactReports.reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun,
      ObjectiveTradeoff,
      [
        "source_objective_tradeoff_report",
        "objective_tradeoff_report"
      ]
    ) ++
      ObjectiveCollectionReviewArtifactReports.operator_review_objective_tradeoff_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) ++
      ObjectiveCollectionReviewArtifactReports.cadence_import_objective_tradeoff_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      )
  end
end
