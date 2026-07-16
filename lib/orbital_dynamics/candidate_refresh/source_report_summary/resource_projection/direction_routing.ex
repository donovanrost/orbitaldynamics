defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.DirectionRouting do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.DirectionRouting.FieldMap

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.DirectionRouting.PressureMaps

  def fields(reports) do
    resource_pressure_direction_counts = PressureMaps.direction_counts(reports)

    resource_pressure_activity_ids_by_direction = PressureMaps.activity_ids_by_direction(reports)

    FieldMap.fields(
      resource_pressure_direction_counts,
      resource_pressure_activity_ids_by_direction
    )
  end
end
