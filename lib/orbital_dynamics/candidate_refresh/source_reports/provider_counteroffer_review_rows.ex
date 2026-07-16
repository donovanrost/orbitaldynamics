defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferReviewRows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferReviewRowReports
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferReviewRowValues

  def operator_review_package_report(path, %{} = package) do
    ProviderCounterofferReviewRowReports.from_embedded_rows(
      "#{path}.rows.source_provider_counteroffer",
      "operator_review_package.rows.source_provider_counteroffer",
      ProviderCounterofferReviewRowValues.operator_review_rows(package),
      package
    )
  end

  def cadence_import_manifest_report(path, %{} = manifest) do
    ProviderCounterofferReviewRowReports.from_embedded_rows(
      "#{path}.rows.source_provider_counteroffer",
      "cadence_import_manifest.rows.source_provider_counteroffer",
      ProviderCounterofferReviewRowValues.cadence_import_rows(manifest),
      manifest
    )
  end
end
