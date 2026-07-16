defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ResourceCollectionResultArtifactReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceCollectionResultArtifactEntries
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceCollectionResultArtifactFields
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceFilter
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceProjection

  def resource_projection_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    ResourceCollectionResultArtifactEntries.reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun,
      ResourceCollectionResultArtifactFields.resource_projection_fields(),
      fn entry_path, report ->
        ResourceProjection.entries(
          entry_path,
          report
        )
      end
    )
  end

  def resource_filter_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    ResourceCollectionResultArtifactEntries.reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun,
      ResourceCollectionResultArtifactFields.resource_filter_fields(),
      fn entry_path, report ->
        ResourceFilter.entries(entry_path, report)
      end
    )
  end
end
