defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.DirectionRouting.RouteMap.RouteEntries.EntryMaps do
  @moduledoc false

  alias __MODULE__.EntryPairs

  def from_directions(
        directions,
        resource_pressure_direction_counts,
        resource_pressure_activity_ids_by_direction
      ) do
    Map.new(directions, fn direction ->
      EntryPairs.from_direction(
        direction,
        resource_pressure_direction_counts,
        resource_pressure_activity_ids_by_direction
      )
    end)
  end
end
