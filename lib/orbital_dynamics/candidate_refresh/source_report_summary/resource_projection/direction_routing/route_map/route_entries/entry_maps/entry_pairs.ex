defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.DirectionRouting.RouteMap.RouteEntries.EntryMaps.EntryPairs do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.DirectionRouting.RouteMap.Entry

  def from_direction(
        direction,
        resource_pressure_direction_counts,
        resource_pressure_activity_ids_by_direction
      ) do
    {direction,
     Entry.build(
       direction,
       resource_pressure_direction_counts,
       resource_pressure_activity_ids_by_direction
     )}
  end
end
