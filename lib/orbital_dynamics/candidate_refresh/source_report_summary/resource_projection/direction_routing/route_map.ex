defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.DirectionRouting.RouteMap do
  @moduledoc false

  alias __MODULE__.RouteEntries

  def build(resource_pressure_direction_counts, resource_pressure_activity_ids_by_direction) do
    RouteEntries.build(
      resource_pressure_direction_counts,
      resource_pressure_activity_ids_by_direction
    )
  end

  def direction_keys(
        resource_pressure_direction_counts,
        resource_pressure_activity_ids_by_direction
      ) do
    RouteEntries.direction_keys(
      resource_pressure_direction_counts,
      resource_pressure_activity_ids_by_direction
    )
  end
end
