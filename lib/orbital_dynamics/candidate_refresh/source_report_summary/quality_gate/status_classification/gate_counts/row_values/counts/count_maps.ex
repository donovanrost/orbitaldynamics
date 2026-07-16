defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.StatusClassification.GateCounts.RowValues.Counts.CountMaps do
  @moduledoc false

  alias __MODULE__.RowCounts

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.StatusClassification.GateCounts.RowValues.Counts

  def row_or_fallback(report, row_field, fallback_field) do
    case Counts.rows(report) do
      [] -> from_fallback(report, fallback_field)
      rows -> RowCounts.from_rows(rows, row_field) || %{}
    end
  end

  def non_empty_row_counts_or_fallback(report, row_field, fallback_field) do
    row_counts =
      report
      |> Counts.rows()
      |> RowCounts.from_rows(row_field)

    case row_counts do
      %{} = counts when map_size(counts) > 0 -> counts
      _counts -> from_fallback(report, fallback_field)
    end
  end

  def value_count(rows, row_field, value) do
    RowCounts.value_count(rows, row_field, value)
  end

  defp from_fallback(report, field) do
    case Map.get(report, field) do
      %{} = count_map -> count_map
      _value -> %{}
    end
  end
end
