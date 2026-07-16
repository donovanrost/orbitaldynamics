defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ContactReviewCollectionContactContentionResolutionArtifactReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactReviewCollectionContactContentionResolutionReviewArtifacts,
    as: ReviewArtifacts

  defdelegate operator_review_reports(
                refresh,
                source_result_artifacts_fun,
                inherit_result_artifact_trust_boundary_fun
              ),
              to: ReviewArtifacts

  defdelegate cadence_import_reports(
                refresh,
                source_result_artifacts_fun,
                inherit_result_artifact_trust_boundary_fun
              ),
              to: ReviewArtifacts
end
