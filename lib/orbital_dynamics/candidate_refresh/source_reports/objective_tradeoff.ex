defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ObjectiveTradeoff do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.EntryFallbacks
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ObjectiveTradeoffEncoding
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ObjectiveTradeoffReviewReports

  def entries(path, value) do
    EntryFallbacks.entries(path, value, fn entry_path, entry_value ->
      report = stringify_keys(entry_value)

      if report?(report) do
        {entry_path, report}
      end
    end)
  end

  def operator_review_entries(path, value) do
    ObjectiveTradeoffReviewReports.operator_review_entries(path, value)
  end

  def cadence_import_entries(path, value) do
    ObjectiveTradeoffReviewReports.cadence_import_entries(path, value)
  end

  def report?(%{} = report) do
    rows = Map.get(report, "tradeoffs") || Map.get(report, "rows") || Map.get(report, :tradeoffs)
    schema_contract = Map.get(report, "schema_contract") || Map.get(report, :schema_contract)

    is_list(rows) and schema_contract in [nil, "objective_tradeoff_report.v1"]
  end

  def report?(_report), do: false

  defp stringify_keys(value), do: ObjectiveTradeoffEncoding.stringify_keys(value)
end
