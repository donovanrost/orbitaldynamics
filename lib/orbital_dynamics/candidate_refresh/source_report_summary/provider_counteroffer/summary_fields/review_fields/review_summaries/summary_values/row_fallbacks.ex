defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ProviderCounteroffer.SummaryFields.ReviewFields.ReviewSummaries.SummaryValues.RowFallbacks do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ProviderCounteroffer.RowMetrics

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1,
      merge_string_list_maps: 1
    ]

  def counts(summaries, counts_field, row_field) do
    summaries
    |> Enum.map(fn report ->
      Map.get(report, counts_field) ||
        RowMetrics.row_counts(report, counts_field, row_field)
    end)
    |> merge_count_maps()
  end

  def string_list_map(summaries, ids_field, row_field) do
    summaries
    |> Enum.map(fn report ->
      Map.get(report, ids_field) ||
        RowMetrics.ids_by_row_field(report, row_field)
    end)
    |> merge_string_list_maps()
  end
end
