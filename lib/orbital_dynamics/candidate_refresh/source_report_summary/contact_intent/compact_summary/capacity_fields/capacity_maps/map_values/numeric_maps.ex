defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.CapacityFields.CapacityMaps.MapValues.NumericMaps do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_numeric_maps: 1
    ]

  def values(summaries, source_field) do
    summaries
    |> Enum.map(&Map.get(&1, source_field))
    |> merge_numeric_maps()
  end
end
