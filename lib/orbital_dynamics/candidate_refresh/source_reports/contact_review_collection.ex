defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ContactReviewCollection do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactReviewCollectionContactAllocationReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactReviewCollectionContactContentionReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactReviewCollectionContactContentionResolutionReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactReviewCollectionContactFilterReports

  def contact_allocation_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    ContactReviewCollectionContactAllocationReports.contact_allocation_reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun
    )
  end

  def contact_filter_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    ContactReviewCollectionContactFilterReports.contact_filter_reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun
    )
  end

  def contact_contention_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    ContactReviewCollectionContactContentionReports.contact_contention_reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun
    )
  end

  def contact_contention_resolution_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    ContactReviewCollectionContactContentionResolutionReports.reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun
    )
  end
end
