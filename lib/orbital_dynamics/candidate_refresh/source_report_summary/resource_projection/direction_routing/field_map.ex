defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.DirectionRouting.FieldMap do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.DirectionRouting.RouteMap

  def fields(resource_pressure_direction_counts, resource_pressure_activity_ids_by_direction) do
    %{
      "resource_pressure_direction_counts" => resource_pressure_direction_counts,
      "resource_pressure_directions" =>
        RouteMap.direction_keys(
          resource_pressure_direction_counts,
          resource_pressure_activity_ids_by_direction
        ),
      "resource_pressure_activity_ids_by_direction" =>
        resource_pressure_activity_ids_by_direction,
      "resource_pressure_direction_routing" =>
        RouteMap.build(
          resource_pressure_direction_counts,
          resource_pressure_activity_ids_by_direction
        )
    }
  end
end
