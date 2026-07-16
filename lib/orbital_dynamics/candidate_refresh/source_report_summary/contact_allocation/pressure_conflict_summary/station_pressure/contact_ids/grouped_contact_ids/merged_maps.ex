defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PressureConflictSummary.StationPressure.ContactIds.GroupedContactIds.MergedMaps do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_nested_string_list_maps: 1,
      merge_string_list_maps: 1
    ]

  def string_list(reports, extractor) do
    reports
    |> Enum.map(extractor)
    |> merge_string_list_maps()
  end

  def nested_string_list(reports, extractor) do
    reports
    |> Enum.map(extractor)
    |> merge_nested_string_list_maps()
  end
end
