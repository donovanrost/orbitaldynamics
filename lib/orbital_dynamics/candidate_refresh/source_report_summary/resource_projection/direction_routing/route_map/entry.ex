defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.DirectionRouting.RouteMap.Entry do
  @moduledoc false

  alias __MODULE__.FieldValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  def build(
        direction,
        resource_pressure_direction_counts,
        resource_pressure_activity_ids_by_direction
      ) do
    direction
    |> FieldValues.for_direction(
      resource_pressure_direction_counts,
      resource_pressure_activity_ids_by_direction
    )
    |> compact_map()
  end
end
