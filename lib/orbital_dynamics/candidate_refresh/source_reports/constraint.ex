defmodule OrbitalDynamics.CandidateRefresh.SourceReports.Constraint do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ConstraintEncoding
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ConstraintReviewRows
  alias OrbitalDynamics.CandidateRefresh.SourceReports.EntryFallbacks

  def entries(path, value) do
    EntryFallbacks.entries(path, value, fn entry_path, entry_value ->
      report = stringify_keys(entry_value)

      if report?(report) do
        {entry_path, report}
      end
    end)
  end

  def operator_review_entries(path, value) do
    EntryFallbacks.entries(path, value, fn entry_path, entry_value ->
      ConstraintReviewRows.operator_review_package_report(entry_path, stringify_keys(entry_value))
    end)
  end

  def cadence_import_entries(path, value) do
    EntryFallbacks.entries(path, value, fn entry_path, entry_value ->
      ConstraintReviewRows.cadence_import_manifest_report(entry_path, stringify_keys(entry_value))
    end)
  end

  def report?(%{} = report) do
    rows = Map.get(report, "rows") || Map.get(report, :rows)
    schema_contract = Map.get(report, "schema_contract") || Map.get(report, :schema_contract)

    is_list(rows) and schema_contract in [nil, "constraint_report.v1"]
  end

  def report?(_report), do: false
  defp stringify_keys(value), do: ConstraintEncoding.stringify_keys(value)
end
