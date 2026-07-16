defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.CapacityFields.CapacityMaps.MapValues.StringListMaps do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_string_list_maps: 1
    ]

  def values(summaries, source_field) do
    summaries
    |> Enum.map(&Map.get(&1, source_field))
    |> merge_string_list_maps()
  end
end
