defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.DirectionRouting.RouteMap.RouteEntries.InputMaps do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.ValueListMaps

  def values(resource_pressure_direction_counts, resource_pressure_activity_ids_by_direction) do
    {
      direction_counts(resource_pressure_direction_counts),
      activity_ids_by_direction(resource_pressure_activity_ids_by_direction)
    }
  end

  def direction_counts(resource_pressure_direction_counts),
    do: resource_pressure_direction_counts || %{}

  def activity_ids_by_direction(resource_pressure_activity_ids_by_direction),
    do: ValueListMaps.map_value_lists(resource_pressure_activity_ids_by_direction) || %{}
end
