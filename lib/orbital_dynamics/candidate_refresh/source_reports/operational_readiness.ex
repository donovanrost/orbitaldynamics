defmodule OrbitalDynamics.CandidateRefresh.SourceReports.OperationalReadiness do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.EntryFallbacks
  alias OrbitalDynamics.CandidateRefresh.SourceReports.OperationalReadinessReportPredicate
  alias OrbitalDynamics.CandidateRefresh.SourceReports.OperationalReadinessReviewReports
  alias OrbitalDynamics.CandidateRefresh.SourceReports.OperationalReadinessSummaryReports

  def entries(path, value) do
    EntryFallbacks.entries(path, value, fn entry_path, entry_value ->
      report = stringify_keys(entry_value)

      cond do
        OperationalReadinessSummaryReports.summary?(report) ->
          {entry_path, OperationalReadinessSummaryReports.report_from_summary(report)}

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
    OperationalReadinessReviewReports.operator_review_package_report(path, package)
  end

  def cadence_import_manifest_report(path, %{} = manifest) do
    OperationalReadinessReviewReports.cadence_import_manifest_report(path, manifest)
  end

  def report?(%{} = report) do
    OperationalReadinessReportPredicate.report?(report)
  end

  def report?(_report), do: false

  defp stringify_keys(value), do: OperationalReadinessReviewReports.stringify_keys(value)
end
