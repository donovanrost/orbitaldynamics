defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.DirectionRouting.RouteMap.Entry.FieldValues do
  @moduledoc false

  def for_direction(
        direction,
        resource_pressure_direction_counts,
        resource_pressure_activity_ids_by_direction
      ) do
    %{
      "pressure_count" => Map.get(resource_pressure_direction_counts, direction),
      "activity_ids" => Map.get(resource_pressure_activity_ids_by_direction, direction, [])
    }
  end
end
