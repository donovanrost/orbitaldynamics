defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.LinkCapacity.RelayFields.AggregateValues do
  @moduledoc false

  alias __MODULE__.MapValues
  alias __MODULE__.NormalizedValues

  def non_zero_count_sum(reports, counter) do
    NormalizedValues.non_zero_count_sum(reports, counter)
  end

  def string_list_map_merge(reports, extractor) do
    MapValues.string_list_map_merge(reports, extractor)
  end

  def count_map_merge(reports, extractor) do
    MapValues.count_map_merge(reports, extractor)
  end

  def sorted_list(reports, extractor) do
    NormalizedValues.sorted_list(reports, extractor)
  end
end
