defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.DirectionFields.Aggregates.MapValues.StationMaps.NestedNumericMaps do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_nested_numeric_maps: 1
    ]

  def values(summaries, field) do
    summaries
    |> Enum.map(&Map.get(&1, field))
    |> merge_nested_numeric_maps()
  end
end
