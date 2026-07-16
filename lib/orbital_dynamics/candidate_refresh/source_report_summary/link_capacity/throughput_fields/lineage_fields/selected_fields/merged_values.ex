defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.LinkCapacity.ThroughputFields.LineageFields.SelectedFields.MergedValues do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1,
      merge_string_lists: 1
    ]

  def count_map(reports, extractor) do
    reports
    |> Enum.map(extractor)
    |> merge_count_maps()
  end

  def string_list(reports, extractor) do
    reports
    |> Enum.map(extractor)
    |> merge_string_lists()
  end
end
