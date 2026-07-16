defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.CapacityFields.CapacityMaps.MapValues.CountMaps do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1
    ]

  def values(summaries, source_field) do
    summaries
    |> Enum.map(&Map.get(&1, source_field))
    |> merge_count_maps()
  end
end
