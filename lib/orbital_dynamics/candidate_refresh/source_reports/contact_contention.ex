defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ContactContention do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.EntryFallbacks
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactContentionEncoding
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactContentionReviewRows

  def entries(path, value) do
    EntryFallbacks.entries(path, value, fn entry_path, entry_value ->
      report = stringify_keys(entry_value)

      if report?(report) do
        {entry_path, report}
      end
    end)
  end

  def entries(path, value, builder) do
    EntryFallbacks.entries(path, value, fn entry_path, entry_value ->
      builder.(entry_path, stringify_keys(entry_value))
    end)
  end

  def operator_review_package_report(path, %{} = package) do
    ContactContentionReviewRows.operator_review_package_report(path, package)
  end

  def cadence_import_manifest_report(path, %{} = manifest) do
    ContactContentionReviewRows.cadence_import_manifest_report(path, manifest)
  end

  def report?(%{} = report) do
    conflict_groups = Map.get(report, "conflict_groups") || Map.get(report, :conflict_groups)

    invalid_contact_inputs =
      Map.get(report, "invalid_contact_inputs") || Map.get(report, :invalid_contact_inputs)

    schema_contract = Map.get(report, "schema_contract") || Map.get(report, :schema_contract)

    (is_list(conflict_groups) or is_list(invalid_contact_inputs)) and
      schema_contract in [nil, "contact_contention_report.v1"]
  end

  def report?(_report), do: false

  defp stringify_keys(value), do: ContactContentionEncoding.stringify_keys(value)
end
