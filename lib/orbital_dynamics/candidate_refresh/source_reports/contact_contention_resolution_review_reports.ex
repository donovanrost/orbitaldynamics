defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ContactContentionResolutionReviewReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactContentionResolutionRecommendationReports
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactContentionResolutionReviewRows

  def operator_review_package_report(path, %{} = package) do
    recommendations =
      ContactContentionResolutionReviewRows.operator_review_recommendations(package)

    ContactContentionResolutionRecommendationReports.from_recommendations(
      "#{path}.rows.source_recommendation",
      "operator_review_package.rows.source_recommendation",
      recommendations,
      package
    )
  end

  def cadence_import_manifest_report(path, %{} = manifest) do
    recommendations =
      ContactContentionResolutionReviewRows.cadence_import_recommendations(manifest)

    ContactContentionResolutionRecommendationReports.from_recommendations(
      "#{path}.rows.source_recommendation",
      "cadence_import_manifest.rows.source_recommendation",
      recommendations,
      manifest
    )
  end
end
