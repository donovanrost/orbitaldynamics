defmodule OrbitalDynamics.CandidateRefresh.SourceReports.RefreshBudget do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.EntryFallbacks
  alias OrbitalDynamics.CandidateRefresh.SourceReports.RefreshBudgetEncoding

  def entries(path, value) do
    EntryFallbacks.entries(path, value, fn entry_path, entry_value ->
      report = stringify_keys(entry_value)

      if report?(report) do
        {entry_path, report}
      end
    end)
  end

  def report?(%{} = report) do
    schema_contract = Map.get(report, "schema_contract") || Map.get(report, :schema_contract)

    has_budget_counts? =
      Enum.any?(
        [
          "input_candidate_count",
          "kept_candidate_count",
          "dropped_candidate_count",
          "max_candidate_activities"
        ],
        &Map.has_key?(report, &1)
      )

    has_budget_counts? and schema_contract in [nil, "refresh_budget_report.v1"]
  end

  def report?(_report), do: false

  defp stringify_keys(value), do: RefreshBudgetEncoding.stringify_keys(value)
end
