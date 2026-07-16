defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ProviderCounteroffer.SummaryFields.ReviewFields.ReviewSummaries.SummaryValues.DirectValues do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      count_values: 1,
      merge_count_maps: 1,
      sorted_string_values: 1
    ]

  def single_value_counts(summaries, value_field) do
    summaries
    |> Enum.map(&Map.get(&1, value_field))
    |> count_values()
  end

  def count_map(summaries, field) do
    summaries
    |> Enum.map(&Map.get(&1, field, %{}))
    |> merge_count_maps()
  end

  def sorted_string_list(summaries, field) do
    summaries
    |> Enum.flat_map(&Map.get(&1, field, []))
    |> sorted_string_values()
  end
end
