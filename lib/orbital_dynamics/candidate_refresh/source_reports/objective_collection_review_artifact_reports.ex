defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ObjectiveCollectionReviewArtifactReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ObjectiveCollectionReviewArtifactTraversal
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ObjectiveSatisfaction
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ObjectiveTradeoff

  def operator_review_objective_satisfaction_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    ObjectiveCollectionReviewArtifactTraversal.reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun,
      &ObjectiveSatisfaction.operator_review_entries/2,
      "source_operator_review_package",
      "operator_review_package"
    )
  end

  def operator_review_objective_tradeoff_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    ObjectiveCollectionReviewArtifactTraversal.reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun,
      &ObjectiveTradeoff.operator_review_entries/2,
      "source_operator_review_package",
      "operator_review_package"
    )
  end

  def cadence_import_objective_satisfaction_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    ObjectiveCollectionReviewArtifactTraversal.reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun,
      &ObjectiveSatisfaction.cadence_import_entries/2,
      "source_cadence_import_manifest",
      "cadence_import_manifest"
    )
  end

  def cadence_import_objective_tradeoff_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    ObjectiveCollectionReviewArtifactTraversal.reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun,
      &ObjectiveTradeoff.cadence_import_entries/2,
      "source_cadence_import_manifest",
      "cadence_import_manifest"
    )
  end
end
