defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ScoreTerm do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.EntryFallbacks
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ScoreTermEncoding
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ScoreTermReviewReports

  def entries(path, value) do
    EntryFallbacks.entries(path, value, fn entry_path, entry_value ->
      report = stringify_keys(entry_value)

      if report?(report) do
        {entry_path, report}
      end
    end)
  end

  def operator_review_entries(path, value) do
    ScoreTermReviewReports.operator_review_entries(path, value)
  end

  def cadence_import_entries(path, value) do
    ScoreTermReviewReports.cadence_import_entries(path, value)
  end

  def report?(%{} = report) do
    rows = Map.get(report, "rows") || Map.get(report, :rows)
    schema_contract = Map.get(report, "schema_contract") || Map.get(report, :schema_contract)

    is_list(rows) and schema_contract in [nil, "score_term_report.v1"]
  end

  def report?(_report), do: false

  defp stringify_keys(value), do: ScoreTermEncoding.stringify_keys(value)
end
