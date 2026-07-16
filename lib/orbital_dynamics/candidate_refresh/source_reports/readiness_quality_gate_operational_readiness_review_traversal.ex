defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ReadinessQualityGateOperationalReadinessReviewTraversal do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.CollectionReviewArtifactDirectReports
  alias OrbitalDynamics.CandidateRefresh.SourceReports.OperationalReadiness

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ReadinessQualityGateOperationalReadinessEmbeddedReviewReports

  def reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun,
        builder,
        source_key,
        artifact_key
      ) do
    direct_reports =
      CollectionReviewArtifactDirectReports.reports(
        refresh,
        entries_with_builder(builder),
        source_key,
        artifact_key
      )

    direct_reports ++
      ReadinessQualityGateOperationalReadinessEmbeddedReviewReports.reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun,
        builder,
        artifact_key
      )
  end

  defp entries_with_builder(builder) do
    fn path, artifact_or_artifacts ->
      OperationalReadiness.build_entries(path, artifact_or_artifacts, builder)
    end
  end
end
