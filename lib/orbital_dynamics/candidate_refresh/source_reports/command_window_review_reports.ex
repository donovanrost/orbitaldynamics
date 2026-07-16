defmodule OrbitalDynamics.CandidateRefresh.SourceReports.CommandWindowReviewReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.CommandWindowReviewEmbeddedReports
  alias OrbitalDynamics.CandidateRefresh.SourceReports.CommandWindowReviewReportRows
  alias OrbitalDynamics.CandidateRefresh.SourceReports.EntryFallbacks

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

  defp operator_review_package_report(path, %{} = package) do
    CommandWindowReviewEmbeddedReports.from_rows(
      "#{path}.rows.source_command_window",
      "operator_review_package.rows.source_command_window",
      CommandWindowReviewReportRows.operator_review_package_rows(package),
      package
    )
  end

  defp cadence_import_manifest_report(path, %{} = manifest) do
    CommandWindowReviewEmbeddedReports.from_rows(
      "#{path}.rows.source_command_window",
      "cadence_import_manifest.rows.source_command_window",
      CommandWindowReviewReportRows.cadence_import_manifest_rows(manifest),
      manifest
    )
  end

  defp stringify_keys(value), do: CommandWindowReviewReportRows.stringify_keys(value)
end
