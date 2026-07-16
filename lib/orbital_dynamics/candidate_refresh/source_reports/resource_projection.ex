defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ResourceProjection do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.EntryFallbacks
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceProjectionEmbeddedReports
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceProjectionFlowSummaryReports
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceProjectionReportPredicate
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceProjectionReviewReports
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceProjectionReviewRows

  def entries(path, value) do
    EntryFallbacks.entries(path, value, fn entry_path, entry_value ->
      report = stringify_keys(entry_value)

      cond do
        report?(report) ->
          {entry_path, report}

        ResourceProjectionFlowSummaryReports.flow_summary?(report) ->
          {entry_path, ResourceProjectionFlowSummaryReports.report_from_flow_summary(report)}

        true ->
          nil
      end
    end)
  end

  def entries(path, value, builder) do
    EntryFallbacks.entries(path, value, fn entry_path, entry_value ->
      builder.(entry_path, stringify_keys(entry_value))
    end)
  end

  def operator_review_package_report(path, %{} = package) do
    ResourceProjectionReviewReports.operator_review_package_report(path, package)
  end

  def cadence_import_manifest_report(path, %{} = manifest) do
    ResourceProjectionReviewReports.cadence_import_manifest_report(path, manifest)
  end

  def report_from_embedded_rows(path, source, rows, artifact) do
    ResourceProjectionEmbeddedReports.from_rows(path, source, rows, artifact)
  end

  def report?(report), do: ResourceProjectionReportPredicate.report?(report)

  defp stringify_keys(value), do: ResourceProjectionReviewRows.stringify_keys(value)
end
