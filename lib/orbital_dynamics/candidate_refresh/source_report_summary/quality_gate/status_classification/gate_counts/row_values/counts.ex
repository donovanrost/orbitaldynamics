defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.StatusClassification.GateCounts.RowValues.Counts do
  @moduledoc false

  alias __MODULE__.CountMaps

  def row_or_fallback(report, row_field, fallback_field) do
    CountMaps.row_or_fallback(report, row_field, fallback_field)
  end

  def non_empty_row_counts_or_fallback(report, row_field, fallback_field) do
    CountMaps.non_empty_row_counts_or_fallback(report, row_field, fallback_field)
  end

  def value_count(rows, row_field, value) do
    CountMaps.value_count(rows, row_field, value)
  end

  def gate_status_count_field("passed"), do: "passed_gate_count"
  def gate_status_count_field("review_required"), do: "review_gate_count"
  def gate_status_count_field("analysis_only"), do: "analysis_gate_count"
  def gate_status_count_field("blocked"), do: "blocked_gate_count"

  def rows(report) do
    report
    |> Map.get("rows", [])
    |> Enum.filter(&is_map/1)
  end
end
