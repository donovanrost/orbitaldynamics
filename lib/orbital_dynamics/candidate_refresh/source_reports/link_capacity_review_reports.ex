defmodule OrbitalDynamics.CandidateRefresh.SourceReports.LinkCapacityReviewReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.LinkCapacityReviewReportFields
  alias OrbitalDynamics.CandidateRefresh.SourceReports.LinkCapacityReviewReportRows

  def operator_review_package_report(path, %{} = package) do
    report_from_embedded_rows(
      "#{path}.rows.source_link_capacity",
      "operator_review_package.rows.source_link_capacity",
      LinkCapacityReviewReportRows.operator_review_package_rows(package),
      package
    )
  end

  def cadence_import_manifest_report(path, %{} = manifest) do
    report_from_embedded_rows(
      "#{path}.rows.source_link_capacity",
      "cadence_import_manifest.rows.source_link_capacity",
      LinkCapacityReviewReportRows.cadence_import_manifest_rows(manifest),
      manifest
    )
  end

  def report_from_embedded_rows(path, source, rows, artifact) do
    LinkCapacityReviewReportFields.report_from_embedded_rows(path, source, rows, artifact)
  end
end
