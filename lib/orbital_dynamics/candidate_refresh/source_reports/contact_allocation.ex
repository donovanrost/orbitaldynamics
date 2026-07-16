defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ContactAllocation do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactAllocationEncoding
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactAllocationReviewReports
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactAllocationSummarySources
  alias OrbitalDynamics.CandidateRefresh.SourceReports.EntryFallbacks

  def entries(path, value) do
    EntryFallbacks.entries(path, value, fn entry_path, entry_value ->
      report = ContactAllocationEncoding.stringify_keys(entry_value)

      if report?(report) do
        {entry_path, report}
      else
        case ContactAllocationSummarySources.report_from_summary_source(report) do
          nil -> nil
          summary_report -> {entry_path, summary_report}
        end
      end
    end)
  end

  def build_entries(path, value, builder) do
    EntryFallbacks.entries(path, value, fn entry_path, entry_value ->
      builder.(entry_path, ContactAllocationEncoding.stringify_keys(entry_value))
    end)
  end

  def operator_review_package_report(path, %{} = package) do
    ContactAllocationReviewReports.operator_review_package_report(path, package)
  end

  def cadence_import_manifest_report(path, %{} = manifest) do
    ContactAllocationReviewReports.cadence_import_manifest_report(path, manifest)
  end

  def report_from_embedded_rows(path, source, rows, artifact) do
    ContactAllocationReviewReports.report_from_embedded_rows(path, source, rows, artifact)
  end

  def report?(%{} = report) do
    rows = Map.get(report, "rows") || Map.get(report, :rows)
    schema_contract = Map.get(report, "schema_contract") || Map.get(report, :schema_contract)

    is_list(rows) and schema_contract in [nil, "contact_allocation_report.v1"]
  end

  def report?(_report), do: false
end
