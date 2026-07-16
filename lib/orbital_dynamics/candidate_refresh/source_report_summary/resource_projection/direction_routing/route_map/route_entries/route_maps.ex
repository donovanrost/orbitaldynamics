defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.DirectionRouting.RouteMap.RouteEntries.RouteMaps do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.DirectionRouting.RouteMap.RouteEntries.EntryMaps
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.ValueListMaps

  def from_inputs(
        directions,
        resource_pressure_direction_counts,
        resource_pressure_activity_ids_by_direction
      ) do
    directions
    |> List.wrap()
    |> EntryMaps.from_directions(
      resource_pressure_direction_counts,
      resource_pressure_activity_ids_by_direction
    )
    |> ValueListMaps.non_empty_map()
  end
end
