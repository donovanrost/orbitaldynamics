defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ObjectiveTradeoffReviewReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.EntryFallbacks
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ObjectiveTradeoffReviewReportFields
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ObjectiveTradeoffReviewReportRows

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
    ObjectiveTradeoffReviewReportFields.report_from_embedded_rows(
      "#{path}.rows.source_objective_tradeoff",
      "operator_review_package.rows.source_objective_tradeoff",
      ObjectiveTradeoffReviewReportRows.operator_review_package_rows(package),
      package
    )
  end

  defp cadence_import_manifest_report(path, %{} = manifest) do
    ObjectiveTradeoffReviewReportFields.report_from_embedded_rows(
      "#{path}.rows.source_objective_tradeoff",
      "cadence_import_manifest.rows.source_objective_tradeoff",
      ObjectiveTradeoffReviewReportRows.cadence_import_manifest_rows(manifest),
      manifest
    )
  end

  defp stringify_keys(value), do: ObjectiveTradeoffReviewReportRows.stringify_keys(value)
end
