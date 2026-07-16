defmodule OrbitalDynamics.CandidateRefresh.SourceReports.SchemaValidation do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.SchemaValidationReportEntries
  alias OrbitalDynamics.CandidateRefresh.SourceReports.SchemaValidationReviewRows

  def entries(path, value) do
    SchemaValidationReportEntries.entries(path, value)
  end

  def build_entries(path, value, builder) do
    SchemaValidationReportEntries.build_entries(path, value, builder)
  end

  def operator_review_package_report(path, %{} = package) do
    SchemaValidationReviewRows.operator_review_package_report(path, package)
  end

  def cadence_import_manifest_report(path, %{} = manifest) do
    SchemaValidationReviewRows.cadence_import_manifest_report(path, manifest)
  end

  def report?(%{} = report) do
    SchemaValidationReportEntries.report?(report)
  end

  def report?(_report), do: false
end
