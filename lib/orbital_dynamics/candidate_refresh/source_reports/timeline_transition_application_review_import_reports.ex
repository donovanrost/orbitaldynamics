defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineTransitionApplicationReviewImportReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.EntryFallbacks

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineTransitionApplicationReviewImportContexts

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineTransitionApplicationReviewImportReportFields

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineTransitionApplicationReviewImportRows

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
    {application_path, source, applications} =
      TimelineTransitionApplicationReviewImportContexts.operator_review_context(path, package)

    report_from_embedded_rows(application_path, source, applications, package)
  end

  defp cadence_import_manifest_report(path, %{} = manifest) do
    {application_path, source, applications} =
      TimelineTransitionApplicationReviewImportContexts.cadence_import_context(path, manifest)

    report_from_embedded_rows(application_path, source, applications, manifest)
  end

  defp report_from_embedded_rows(path, source, applications, artifact) do
    TimelineTransitionApplicationReviewImportReportFields.report_from_embedded_rows(
      path,
      source,
      applications,
      artifact
    )
  end

  defp stringify_keys(value),
    do: TimelineTransitionApplicationReviewImportRows.stringify_keys(value)
end
