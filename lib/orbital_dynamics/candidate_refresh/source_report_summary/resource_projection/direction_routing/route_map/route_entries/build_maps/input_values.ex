defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.DirectionRouting.RouteMap.RouteEntries.BuildMaps.InputValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.DirectionRouting.RouteMap.RouteEntries.DirectionKeys

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.DirectionRouting.RouteMap.RouteEntries.InputMaps

  def from_inputs(
        resource_pressure_direction_counts,
        resource_pressure_activity_ids_by_direction
      ) do
    {resource_pressure_direction_counts, resource_pressure_activity_ids_by_direction} =
      InputMaps.values(
        resource_pressure_direction_counts,
        resource_pressure_activity_ids_by_direction
      )

    {
      DirectionKeys.values(
        resource_pressure_direction_counts,
        resource_pressure_activity_ids_by_direction
      ),
      resource_pressure_direction_counts,
      resource_pressure_activity_ids_by_direction
    }
  end
end
