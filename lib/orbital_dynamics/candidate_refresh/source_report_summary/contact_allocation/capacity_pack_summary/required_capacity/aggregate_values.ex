defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.CapacityPackSummary.RequiredCapacity.AggregateValues do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1,
      merge_numeric_maps: 1,
      merge_string_list_maps: 1,
      sum_report_numeric_values: 2
    ]

  def count_map_merge(reports, extractor) do
    reports
    |> Enum.map(extractor)
    |> merge_count_maps()
  end

  def string_list_map_merge(reports, extractor) do
    reports
    |> Enum.map(extractor)
    |> merge_string_list_maps()
  end

  def numeric_map_merge(reports, extractor) do
    reports
    |> Enum.map(extractor)
    |> merge_numeric_maps()
  end

  def numeric_sum(reports, extractor) do
    sum_report_numeric_values(reports, extractor)
  end
end
