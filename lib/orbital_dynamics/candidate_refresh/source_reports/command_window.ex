defmodule OrbitalDynamics.CandidateRefresh.SourceReports.CommandWindow do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.CommandWindowEncoding
  alias OrbitalDynamics.CandidateRefresh.SourceReports.CommandWindowReviewReports
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
    CommandWindowReviewReports.operator_review_entries(path, value)
  end

  def cadence_import_entries(path, value) do
    CommandWindowReviewReports.cadence_import_entries(path, value)
  end

  def report?(%{} = report) do
    rows = Map.get(report, "rows") || Map.get(report, :rows)
    schema_contract = Map.get(report, "schema_contract") || Map.get(report, :schema_contract)

    is_list(rows) and schema_contract in [nil, "command_window_report.v1"]
  end

  def report?(_report), do: false

  defp stringify_keys(value), do: CommandWindowEncoding.stringify_keys(value)
end
