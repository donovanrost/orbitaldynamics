defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ResourceFilter do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceFilterEntries
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceFilterReportClassification
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceFilterReviewReports

  def entries(path, value) do
    ResourceFilterEntries.entries(path, value)
  end

  def build_entries(path, value, builder) do
    ResourceFilterEntries.build_entries(path, value, builder)
  end

  def operator_review_package_report(path, %{} = package) do
    ResourceFilterReviewReports.operator_review_package_report(path, package)
  end

  def cadence_import_manifest_report(path, %{} = manifest) do
    ResourceFilterReviewReports.cadence_import_manifest_report(path, manifest)
  end

  def report?(report), do: ResourceFilterReportClassification.report?(report)
end
