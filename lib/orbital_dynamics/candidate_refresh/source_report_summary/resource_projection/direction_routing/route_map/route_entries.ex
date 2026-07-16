defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.DirectionRouting.RouteMap.RouteEntries do
  @moduledoc false

  alias __MODULE__.BuildMaps
  alias __MODULE__.DirectionKeys

  defdelegate build(
                resource_pressure_direction_counts,
                resource_pressure_activity_ids_by_direction
              ),
              to: BuildMaps

  def direction_keys(
        resource_pressure_direction_counts,
        resource_pressure_activity_ids_by_direction
      ) do
    DirectionKeys.values(
      resource_pressure_direction_counts,
      resource_pressure_activity_ids_by_direction
    )
  end
end
