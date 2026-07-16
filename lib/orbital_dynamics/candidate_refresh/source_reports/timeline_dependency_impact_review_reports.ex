defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDependencyImpactReviewReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.EntryFallbacks
  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDependencyImpactReviewReportRows
  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDependencyImpactReviewSummaryFields
  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDependencyImpactRows

  def operator_review_entries(path, value) do
    EntryFallbacks.entries(path, value, fn entry_path, entry_value ->
      operator_review_package_summary(entry_path, stringify_keys(entry_value))
    end)
  end

  def cadence_import_entries(path, value) do
    EntryFallbacks.entries(path, value, fn entry_path, entry_value ->
      cadence_import_manifest_summary(entry_path, stringify_keys(entry_value))
    end)
  end

  defp operator_review_package_summary(path, %{} = package) do
    summary_from_embedded_rows(
      "#{path}.rows.source_timeline_dependency_impact",
      "operator_review_package.rows.source_timeline_dependency_impact",
      TimelineDependencyImpactReviewReportRows.operator_review_rows(package),
      package
    )
  end

  defp cadence_import_manifest_summary(path, %{} = manifest) do
    summary_from_embedded_rows(
      "#{path}.rows.source_review_row.source_timeline_dependency_impact",
      "cadence_import_manifest.rows.source_review_row.source_timeline_dependency_impact",
      TimelineDependencyImpactReviewReportRows.cadence_import_rows(manifest),
      manifest
    )
  end

  defp summary_from_embedded_rows(_path, _source, [], _artifact), do: nil

  defp summary_from_embedded_rows(path, source, rows, artifact) do
    {path, TimelineDependencyImpactReviewSummaryFields.summary(source, rows, artifact)}
  end

  defp stringify_keys(value), do: TimelineDependencyImpactRows.stringify_keys(value)
end
