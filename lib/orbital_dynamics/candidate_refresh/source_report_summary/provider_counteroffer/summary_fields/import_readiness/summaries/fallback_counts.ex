defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ProviderCounteroffer.SummaryFields.ImportReadiness.Summaries.FallbackCounts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ProviderCounteroffer.RowMetrics

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      count_values: 1,
      merge_count_maps: 1
    ]

  def single_value(summaries, counts_field, value_field) do
    summaries
    |> Enum.map(fn report ->
      Map.get(report, counts_field) ||
        count_values([Map.get(report, value_field)])
    end)
    |> merge_count_maps()
  end

  def rows(summaries, counts_field, row_field) do
    summaries
    |> Enum.map(fn report ->
      Map.get(report, counts_field) ||
        RowMetrics.row_counts(report, counts_field, row_field)
    end)
    |> merge_count_maps()
  end
end
