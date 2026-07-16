defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ContactContentionResolution do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactContentionResolutionReviewReports
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactContentionResolutionValues
  alias OrbitalDynamics.CandidateRefresh.SourceReports.EntryFallbacks
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary

  def entries(path, value) do
    EntryFallbacks.entries(path, value, fn entry_path, entry_value ->
      report = stringify_keys(entry_value)

      cond do
        summary?(report) ->
          {entry_path,
           SourceReportSummary.ContactContentionResolution.report_from_summary(report)}

        report?(report) ->
          {entry_path, report}

        true ->
          nil
      end
    end)
  end

  def build_entries(path, value, builder) do
    EntryFallbacks.entries(path, value, fn entry_path, entry_value ->
      builder.(entry_path, stringify_keys(entry_value))
    end)
  end

  def operator_review_package_report(path, %{} = package) do
    ContactContentionResolutionReviewReports.operator_review_package_report(path, package)
  end

  def cadence_import_manifest_report(path, %{} = manifest) do
    ContactContentionResolutionReviewReports.cadence_import_manifest_report(path, manifest)
  end

  def report?(report), do: ContactContentionResolutionValues.report?(report)

  defp summary?(summary), do: ContactContentionResolutionValues.summary?(summary)

  defp stringify_keys(value), do: ContactContentionResolutionValues.stringify_keys(value)
end
