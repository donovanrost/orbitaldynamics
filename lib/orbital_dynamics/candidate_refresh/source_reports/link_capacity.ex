defmodule OrbitalDynamics.CandidateRefresh.SourceReports.LinkCapacity do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.LinkCapacityEntries
  alias OrbitalDynamics.CandidateRefresh.SourceReports.LinkCapacityReviewReports

  def entries(path, value) do
    LinkCapacityEntries.entries(path, value)
  end

  def entries(path, value, builder) do
    LinkCapacityEntries.entries(path, value, builder)
  end

  def operator_review_package_report(path, %{} = package) do
    LinkCapacityReviewReports.operator_review_package_report(path, package)
  end

  def cadence_import_manifest_report(path, %{} = manifest) do
    LinkCapacityReviewReports.cadence_import_manifest_report(path, manifest)
  end

  def report_from_embedded_rows(path, source, rows, artifact) do
    LinkCapacityReviewReports.report_from_embedded_rows(path, source, rows, artifact)
  end

  def report?(%{} = report) do
    LinkCapacityEntries.report?(report)
  end

  def report?(report), do: LinkCapacityEntries.report?(report)
end
