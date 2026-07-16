defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ProviderCounteroffer.SummaryFields.ImportReadiness.CounterofferIds.Aggregates do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ProviderCounteroffer.RowMetrics

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_string_list_maps: 1,
      sorted_string_values: 1
    ]

  def string_list_map(summaries, field) do
    summaries
    |> Enum.map(&Map.get(&1, field, %{}))
    |> merge_string_list_maps()
  end

  def string_list_map_with_row_fallback(summaries, ids_field, row_field) do
    summaries
    |> Enum.map(&map_or_row_ids(&1, ids_field, row_field))
    |> merge_string_list_maps()
  end

  def sorted_string_list(summaries, field) do
    summaries
    |> Enum.flat_map(&Map.get(&1, field, []))
    |> sorted_string_values()
  end

  defp map_or_row_ids(report, ids_field, row_field) do
    Map.get(report, ids_field) ||
      RowMetrics.ids_by_row_field(report, row_field)
  end
end
