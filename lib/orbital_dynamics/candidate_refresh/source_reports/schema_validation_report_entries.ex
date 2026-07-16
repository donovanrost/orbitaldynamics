defmodule OrbitalDynamics.CandidateRefresh.SourceReports.SchemaValidationReportEntries do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.EntryFallbacks
  alias OrbitalDynamics.CandidateRefresh.SourceReports.SchemaValidationBatchReports
  alias OrbitalDynamics.CandidateRefresh.SourceReports.SchemaValidationReportValues

  def entries(path, value) do
    EntryFallbacks.entries(path, value, fn entry_path, entry_value ->
      report = SchemaValidationReportValues.stringify_keys(entry_value)

      cond do
        report?(report) ->
          {entry_path, report}

        SchemaValidationBatchReports.report?(report) ->
          SchemaValidationBatchReports.entries(entry_path, report)

        true ->
          nil
      end
    end)
  end

  def build_entries(path, value, builder) do
    EntryFallbacks.entries(path, value, fn entry_path, entry_value ->
      builder.(entry_path, SchemaValidationReportValues.stringify_keys(entry_value))
    end)
  end

  def report?(%{} = report) do
    schema_contract = Map.get(report, "schema_contract") || Map.get(report, :schema_contract)
    status = Map.get(report, "status") || Map.get(report, :status)

    has_validation_counts? =
      Enum.any?(
        ["error_count", "warning_count", "remediation_count", "errors", "warnings"],
        &Map.has_key?(report, &1)
      )

    schema_contract in [nil, "schema_validation_report.v1"] and
      (status not in [nil, ""] or has_validation_counts?)
  end

  def report?(_report), do: false
end
