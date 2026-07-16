defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiffReviewImportReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.EntryFallbacks
  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiffReviewImportContexts
  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiffReviewImportReportFields
  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiffReviewImportRows

  def operator_review_entries(path, value) do
    EntryFallbacks.entries(path, value, fn entry_path, entry_value ->
      operator_review_package_report(entry_path, stringify_keys(entry_value))
    end)
  end

  def cadence_import_entries(path, value) do
    EntryFallbacks.entries(path, value, fn entry_path, entry_value ->
      cadence_import_manifest_report(entry_path, stringify_keys(entry_value))
    end)
  end

  def row_from_review_or_import_row(%{} = row) do
    TimelineDiffReviewImportRows.row_from_review_or_import_row(row)
  end

  def row_from_review_or_import_row(_row), do: nil

  defp operator_review_package_report(path, %{} = package) do
    {embedded_path, embedded_source, rows} =
      TimelineDiffReviewImportContexts.operator_review_context(path, package)

    TimelineDiffReviewImportReportFields.report_from_embedded_rows(
      embedded_path,
      embedded_source,
      rows,
      package
    )
  end

  defp cadence_import_manifest_report(path, %{} = manifest) do
    {embedded_path, embedded_source, rows} =
      TimelineDiffReviewImportContexts.cadence_import_context(path, manifest)

    TimelineDiffReviewImportReportFields.report_from_embedded_rows(
      embedded_path,
      embedded_source,
      rows,
      manifest
    )
  end

  defp stringify_keys(value), do: TimelineDiffReviewImportRows.stringify_keys(value)
end
