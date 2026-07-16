defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.RowFallbackValues.ReportRows.AggregateValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.RowFallbackValues.ListValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1,
      merge_string_list_maps: 1,
      numeric_report_count: 2
    ]

  def count(rows, field) do
    rows
    |> Enum.map(&numeric_report_count(&1, field))
    |> Enum.sum()
  end

  def count_map(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> merge_count_maps()
  end

  def string_list(rows, field) do
    Enum.flat_map(rows, &ListValues.list(&1, field))
  end

  def string_list_map(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> merge_string_list_maps()
    |> case do
      nil -> %{}
      map -> map
    end
  end
end
