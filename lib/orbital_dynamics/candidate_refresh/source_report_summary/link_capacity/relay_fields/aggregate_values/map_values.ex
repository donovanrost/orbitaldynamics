defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.LinkCapacity.RelayFields.AggregateValues.MapValues do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1,
      merge_string_list_maps: 1
    ]

  def string_list_map_merge(reports, extractor) do
    reports
    |> Enum.map(extractor)
    |> merge_string_list_maps()
  end

  def count_map_merge(reports, extractor) do
    reports
    |> Enum.map(extractor)
    |> merge_count_maps()
  end
end
