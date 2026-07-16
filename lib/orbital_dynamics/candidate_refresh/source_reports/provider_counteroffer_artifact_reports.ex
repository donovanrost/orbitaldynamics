defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferArtifactReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferResultArtifactReports
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferReviewArtifactReports

  def reports(refresh, source_result_artifacts_fun, inherit_result_artifact_trust_boundary_fun) do
    ProviderCounterofferResultArtifactReports.reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun
    ) ++
      ProviderCounterofferReviewArtifactReports.operator_review_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) ++
      ProviderCounterofferReviewArtifactReports.cadence_import_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      )
  end
end
