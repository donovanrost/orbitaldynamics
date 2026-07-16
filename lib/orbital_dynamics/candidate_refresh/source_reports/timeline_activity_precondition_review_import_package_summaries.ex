defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityPreconditionReviewImportPackageSummaries do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityPreconditionReviewImportRows

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityPreconditionReviewImportSummaries

  def operator_review_package_summary(path, package, summary?) do
    package = TimelineActivityPreconditionReviewImportSummaries.stringify_keys(package)

    rows =
      package
      |> Map.get("rows", [])
      |> TimelineActivityPreconditionReviewImportRows.operator_review_summaries(summary?)

    TimelineActivityPreconditionReviewImportSummaries.summary_from_embedded_rows(
      "#{path}.rows.source_timeline_activity_precondition_summary",
      "operator_review_package.rows.source_timeline_activity_precondition_summary",
      rows,
      package
    )
  end

  def cadence_import_manifest_summary(path, manifest, summary?) do
    manifest = TimelineActivityPreconditionReviewImportSummaries.stringify_keys(manifest)

    rows =
      manifest
      |> Map.get("rows", [])
      |> TimelineActivityPreconditionReviewImportRows.cadence_import_summaries(summary?)

    TimelineActivityPreconditionReviewImportSummaries.summary_from_embedded_rows(
      "#{path}.rows.source_review_row.source_timeline_activity_precondition_summary",
      "cadence_import_manifest.rows.source_review_row.source_timeline_activity_precondition_summary",
      rows,
      manifest
    )
  end
end
