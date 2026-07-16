defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ContactFilter do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactFilterReportValueEncoding
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactFilterReviewImportRows
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactFilterRowReports
  alias OrbitalDynamics.CandidateRefresh.SourceReports.EntryFallbacks

  def entries(path, value) do
    EntryFallbacks.entries(path, value, fn entry_path, entry_value ->
      report = stringify_keys(entry_value)

      if report?(report) do
        {entry_path, report}
      end
    end)
  end

  def build_entries(path, value, builder) do
    EntryFallbacks.entries(path, value, fn entry_path, entry_value ->
      builder.(entry_path, stringify_keys(entry_value))
    end)
  end

  def operator_review_package_report(path, %{} = package) do
    ContactFilterRowReports.from_rows(
      "#{path}.rows.source_contact_suppression",
      "operator_review_package.rows.source_contact_suppression",
      ContactFilterReviewImportRows.operator_review_package_rows(package),
      package
    )
  end

  def cadence_import_manifest_report(path, %{} = manifest) do
    ContactFilterRowReports.from_rows(
      "#{path}.rows.source_contact_suppression",
      "cadence_import_manifest.rows.source_contact_suppression",
      ContactFilterReviewImportRows.cadence_import_manifest_rows(manifest),
      manifest
    )
  end

  def report?(%{} = report) do
    rows = Map.get(report, "suppressed_candidates") || Map.get(report, :suppressed_candidates)
    schema_contract = Map.get(report, "schema_contract") || Map.get(report, :schema_contract)

    is_list(rows) and schema_contract in [nil, "contact_filter_report.v1"]
  end

  def report?(_report), do: false

  defp stringify_keys(value), do: ContactFilterReportValueEncoding.stringify_keys(value)
end
