defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.DirectionRouting.RouteMap.RouteEntries.DirectionKeys do
  @moduledoc false

  alias __MODULE__.KeyValues

  def values(resource_pressure_direction_counts, resource_pressure_activity_ids_by_direction) do
    KeyValues.from_maps(
      resource_pressure_direction_counts,
      resource_pressure_activity_ids_by_direction
    )
  end
end
