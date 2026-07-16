defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.DirectionRouting.RouteMap.RouteEntries.BuildMaps do
  @moduledoc false

  alias __MODULE__.InputValues

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.DirectionRouting.RouteMap.RouteEntries.RouteMaps

  def build(resource_pressure_direction_counts, resource_pressure_activity_ids_by_direction) do
    {directions, resource_pressure_direction_counts, resource_pressure_activity_ids_by_direction} =
      InputValues.from_inputs(
        resource_pressure_direction_counts,
        resource_pressure_activity_ids_by_direction
      )

    RouteMaps.from_inputs(
      directions,
      resource_pressure_direction_counts,
      resource_pressure_activity_ids_by_direction
    )
  end
end
